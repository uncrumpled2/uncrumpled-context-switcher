// IPC Abstraction Layer
//
// Provides a cross-platform abstraction for inter-process communication:
// - Unix domain sockets on Linux/macOS
// - Named pipes on Windows
//
// This module handles:
// - Server socket creation and binding
// - Client connections
// - Non-blocking I/O with polling
// - Connection lifecycle management

#import "Basic";
#import "String";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
#import "Thread";

// Maximum number of concurrent client connections
MAX_CLIENTS :: 16;

// Buffer size for read/write operations
IPC_BUFFER_SIZE :: 4096;

// Connection states
Connection_State :: enum {
    DISCONNECTED;
    CONNECTING;
    CONNECTED;
    ERROR;
}

// Client connection handle
IPC_Connection :: struct {
    id: u32;                    // Unique connection identifier
    fd: s32;                    // File descriptor (Unix) or handle (Windows)
    state: Connection_State;
    remote_address: string;     // For debugging/logging
    read_buffer: [IPC_BUFFER_SIZE] u8;
    read_buffer_len: s64;
    write_buffer: [IPC_BUFFER_SIZE] u8;
    write_buffer_len: s64;
    write_buffer_offset: s64;   // How much has been written
    last_activity: Apollo_Time;
    user_data: *void;           // Application-specific data
}

// IPC Server
IPC_Server :: struct {
    socket_path: string;
    server_fd: s32;
    initialized: bool;
    running: bool;

    // Client connections
    connections: [MAX_CLIENTS] IPC_Connection;
    connection_count: s32;
    next_connection_id: u32;

    // Poll file descriptors for select/poll
    #if OS == .LINUX || OS == .MACOS {
        poll_fds: [MAX_CLIENTS + 1] pollfd;  // +1 for server socket
    }

    // Statistics
    total_connections: u64;
    total_bytes_received: u64;
    total_bytes_sent: u64;

    // Mutex for thread safety
    mutex: Mutex;
}

// Callback types for server events
On_Connect_Callback :: #type (server: *IPC_Server, conn: *IPC_Connection) -> void;
On_Disconnect_Callback :: #type (server: *IPC_Server, conn: *IPC_Connection) -> void;
On_Message_Callback :: #type (server: *IPC_Server, conn: *IPC_Connection, data: [] u8) -> void;
On_Error_Callback :: #type (server: *IPC_Server, conn: *IPC_Connection, error: string) -> void;

// Server callbacks container
IPC_Callbacks :: struct {
    on_connect: On_Connect_Callback;
    on_disconnect: On_Disconnect_Callback;
    on_message: On_Message_Callback;
    on_error: On_Error_Callback;
}

// Initialize IPC server
init_ipc_server :: (server: *IPC_Server, socket_path: string) -> bool {
    if server.initialized {
        return false;  // Already initialized
    }

    init(*server.mutex);

    server.socket_path = copy_string(socket_path);
    server.server_fd = -1;
    server.initialized = true;
    server.running = false;
    server.connection_count = 0;
    server.next_connection_id = 1;
    server.total_connections = 0;
    server.total_bytes_received = 0;
    server.total_bytes_sent = 0;

    // Initialize all connections as disconnected
    for *conn: server.connections {
        conn.id = 0;
        conn.fd = -1;
        conn.state = .DISCONNECTED;
    }

    return true;
}

// Initialize IPC server with a pre-existing file descriptor (for systemd socket activation)
init_ipc_server_with_fd :: (server: *IPC_Server, fd: s32, socket_path: string) -> bool {
    if server.initialized {
        return false;  // Already initialized
    }

    init(*server.mutex);

    server.socket_path = copy_string(socket_path);
    server.server_fd = fd;  // Use the passed-in fd
    server.initialized = true;
    server.running = false;
    server.connection_count = 0;
    server.next_connection_id = 1;
    server.total_connections = 0;
    server.total_bytes_received = 0;
    server.total_bytes_sent = 0;

    // Initialize all connections as disconnected
    for *conn: server.connections {
        conn.id = 0;
        conn.fd = -1;
        conn.state = .DISCONNECTED;
    }

    return true;
}

// Destroy IPC server
destroy_ipc_server :: (server: *IPC_Server) {
    if !server.initialized return;

    lock(*server.mutex);
    defer unlock(*server.mutex);

    // Close all client connections
    for *conn: server.connections {
        if conn.state != .DISCONNECTED {
            #if OS == .LINUX || OS == .MACOS {
                close_connection_locked(server, conn);
            } else #if OS == .WINDOWS {
                close_windows_connection(server, conn);
            }
        }
    }

    // Close server socket/handle
    if server.server_fd >= 0 {
        #if OS == .LINUX || OS == .MACOS {
            close(server.server_fd);
        } else #if OS == .WINDOWS {
            CloseHandle(cast(HANDLE) cast(u64) server.server_fd);
        }
        server.server_fd = -1;
    }

    // Remove socket file (Unix only)
    #if OS == .LINUX || OS == .MACOS {
        if server.socket_path.count > 0 {
            unlink(ipc_to_c_string(server.socket_path));
        }
    }

    free(server.socket_path);
    destroy(*server.mutex);
    server.initialized = false;
}

// Start listening for connections
start_server :: (server: *IPC_Server) -> bool {
    if !server.initialized return false;

    lock(*server.mutex);
    defer unlock(*server.mutex);

    #if OS == .LINUX || OS == .MACOS {
        return start_unix_server(server);
    } else #if OS == .WINDOWS {
        return start_windows_server(server);
    } else {
        return false;
    }
}

// Stop the server
stop_server :: (server: *IPC_Server) {
    lock(*server.mutex);
    defer unlock(*server.mutex);

    server.running = false;

    // Close server socket to wake up any blocking operations
    #if OS == .LINUX || OS == .MACOS {
        if server.server_fd >= 0 {
            ipc_shutdown(server.server_fd, IPC_SHUT_RDWR);
        }
    }
}

// Poll for events (non-blocking)
// Returns number of connections with activity, or -1 on error
poll_events :: (server: *IPC_Server, timeout_ms: s32) -> s32 {
    if !server.initialized || !server.running return -1;

    #if OS == .LINUX || OS == .MACOS {
        return poll_unix_events(server, timeout_ms);
    } else #if OS == .WINDOWS {
        return poll_windows_events(server, timeout_ms);
    } else {
        return -1;
    }
}

// Accept pending connections
// Returns number of new connections accepted
accept_connections :: (server: *IPC_Server) -> s32 {
    if !server.initialized || !server.running return 0;

    lock(*server.mutex);
    defer unlock(*server.mutex);

    #if OS == .LINUX || OS == .MACOS {
        return accept_unix_connections(server);
    } else #if OS == .WINDOWS {
        return accept_windows_connections(server);
    } else {
        return 0;
    }
}

// Read data from a connection
// Returns bytes read, 0 on EOF, -1 on error
read_connection :: (server: *IPC_Server, conn: *IPC_Connection, buffer: [] u8) -> s64 {
    if conn.state != .CONNECTED return -1;

    #if OS == .LINUX || OS == .MACOS {
        result := read(conn.fd, buffer.data, cast(u64) buffer.count);
        if result > 0 {
            server.total_bytes_received += cast(u64) result;
            conn.last_activity = current_time_consensus();
        }
        return result;
    } else #if OS == .WINDOWS {
        return read_windows_connection(server, conn, buffer);
    } else {
        return -1;
    }
}

// Write data to a connection
// Returns bytes written, or -1 on error
write_connection :: (server: *IPC_Server, conn: *IPC_Connection, data: [] u8) -> s64 {
    if conn.state != .CONNECTED return -1;

    #if OS == .LINUX || OS == .MACOS {
        result := write(conn.fd, data.data, cast(u64) data.count);
        if result > 0 {
            server.total_bytes_sent += cast(u64) result;
            conn.last_activity = current_time_consensus();
        }
        return result;
    } else #if OS == .WINDOWS {
        return write_windows_connection(server, conn, data);
    } else {
        return -1;
    }
}

// Queue data for writing (buffered)
queue_write :: (conn: *IPC_Connection, data: [] u8) -> bool {
    if conn.state != .CONNECTED return false;

    // Check if there's room in the buffer
    remaining := IPC_BUFFER_SIZE - conn.write_buffer_len;
    if data.count > remaining {
        return false;  // Buffer full
    }

    // Copy data to buffer
    memcpy(conn.write_buffer.data + conn.write_buffer_len, data.data, data.count);
    conn.write_buffer_len += data.count;

    return true;
}

// Flush write buffer
// Returns bytes written, or -1 on error
flush_write_buffer :: (server: *IPC_Server, conn: *IPC_Connection) -> s64 {
    if conn.state != .CONNECTED return -1;
    if conn.write_buffer_len == 0 return 0;

    remaining := conn.write_buffer_len - conn.write_buffer_offset;
    if remaining <= 0 {
        conn.write_buffer_len = 0;
        conn.write_buffer_offset = 0;
        return 0;
    }

    data_ptr := conn.write_buffer.data + conn.write_buffer_offset;

    result: s64 = -1;

    #if OS == .LINUX || OS == .MACOS {
        result = write(conn.fd, data_ptr, cast(u64) remaining);
    } else #if OS == .WINDOWS {
        data_slice: [] u8;
        data_slice.data = data_ptr;
        data_slice.count = remaining;
        result = write_windows_connection(server, conn, data_slice);
    }

    if result > 0 {
        conn.write_buffer_offset += result;
        server.total_bytes_sent += cast(u64) result;
        conn.last_activity = current_time_consensus();

        // If fully written, reset buffer
        if conn.write_buffer_offset >= conn.write_buffer_len {
            conn.write_buffer_len = 0;
            conn.write_buffer_offset = 0;
        }
    }
    return result;
}

// Close a connection
close_connection :: (server: *IPC_Server, conn: *IPC_Connection) {
    lock(*server.mutex);
    defer unlock(*server.mutex);

    #if OS == .LINUX || OS == .MACOS {
        close_connection_locked(server, conn);
    } else #if OS == .WINDOWS {
        close_windows_connection(server, conn);
    }
}

// Get connection by ID
get_connection :: (server: *IPC_Server, id: u32) -> *IPC_Connection {
    for *conn: server.connections {
        if conn.id == id && conn.state != .DISCONNECTED {
            return conn;
        }
    }
    return null;
}

// Get number of active connections
get_connection_count :: (server: *IPC_Server) -> s32 {
    return server.connection_count;
}

// Get server statistics
IPC_Stats :: struct {
    active_connections: s32;
    total_connections: u64;
    bytes_received: u64;
    bytes_sent: u64;
}

get_stats :: (server: *IPC_Server) -> IPC_Stats {
    stats: IPC_Stats;
    stats.active_connections = server.connection_count;
    stats.total_connections = server.total_connections;
    stats.bytes_received = server.total_bytes_received;
    stats.bytes_sent = server.total_bytes_sent;
    return stats;
}

//
// ============================================================================
// UNIX-SPECIFIC IMPLEMENTATION
// ============================================================================
//

#if OS == .LINUX || OS == .MACOS {

// Unix socket address structure - custom since POSIX may not have this exact layout
IPC_sockaddr_un :: struct {
    sun_family: u16;
    sun_path: [108] u8;
}

// Constants not always in POSIX module or that we want to namespace
IPC_AF_UNIX :: 1;
IPC_SOCK_STREAM :: 1;
IPC_SOL_SOCKET :: 1;
IPC_SO_REUSEADDR :: 2;
IPC_SHUT_RD :: 0;
IPC_SHUT_WR :: 1;
IPC_SHUT_RDWR :: 2;

// Use POSIX module's fcntl via wrapper to avoid overload ambiguity
ipc_fcntl_get :: (fd: s32, cmd: s32) -> s32 {
    return fcntl(fd, cmd);
}

ipc_fcntl_set :: (fd: s32, cmd: s32, arg: s32) -> s32 {
    return fcntl(fd, cmd, arg);
}

// Socket functions - use libc directly since POSIX may have conflicting signatures
libc :: #library,system "libc";
ipc_socket :: (domain: s32, type: s32, protocol: s32) -> s32 #foreign libc "socket";
ipc_bind :: (sockfd: s32, addr: *void, addrlen: u32) -> s32 #foreign libc "bind";
ipc_listen :: (sockfd: s32, backlog: s32) -> s32 #foreign libc "listen";
ipc_accept :: (sockfd: s32, addr: *void, addrlen: *u32) -> s32 #foreign libc "accept";
ipc_shutdown :: (sockfd: s32, how: s32) -> s32 #foreign libc "shutdown";
ipc_setsockopt :: (sockfd: s32, level: s32, optname: s32, optval: *void, optlen: u32) -> s32 #foreign libc "setsockopt";
ipc_poll :: (fds: *pollfd, nfds: u64, timeout: s32) -> s32 #foreign libc "poll";

// Start Unix domain socket server
start_unix_server :: (server: *IPC_Server) -> bool {
    // Check if we already have a socket fd (from systemd socket activation)
    if server.server_fd >= 0 {
        // Socket already exists - just set non-blocking and start running
        flags := ipc_fcntl_get(server.server_fd, F_GETFL);
        ipc_fcntl_set(server.server_fd, F_SETFL, flags | O_NONBLOCK);
        server.running = true;
        return true;
    }

    // Remove existing socket file if present
    unlink(ipc_to_c_string(server.socket_path));

    // Create socket
    server.server_fd = ipc_socket(IPC_AF_UNIX, IPC_SOCK_STREAM, 0);
    if server.server_fd < 0 {
        return false;
    }

    // Set socket options
    opt: s32 = 1;
    ipc_setsockopt(server.server_fd, IPC_SOL_SOCKET, IPC_SO_REUSEADDR, *opt, size_of(s32));

    // Set non-blocking
    flags := ipc_fcntl_get(server.server_fd, F_GETFL);
    ipc_fcntl_set(server.server_fd, F_SETFL, flags | O_NONBLOCK);

    // Prepare address
    addr: IPC_sockaddr_un;
    addr.sun_family = IPC_AF_UNIX;

    // Copy path to sun_path
    path_bytes := cast([] u8) server.socket_path;
    for i: 0..ipc_min(path_bytes.count, 107) - 1 {
        addr.sun_path[i] = path_bytes[i];
    }
    addr.sun_path[ipc_min(path_bytes.count, 107)] = 0;

    // Bind
    if ipc_bind(server.server_fd, *addr, size_of(IPC_sockaddr_un)) < 0 {
        close(server.server_fd);
        server.server_fd = -1;
        return false;
    }

    // Listen
    if ipc_listen(server.server_fd, 16) < 0 {
        close(server.server_fd);
        server.server_fd = -1;
        return false;
    }

    server.running = true;
    return true;
}

// Poll for events on Unix
poll_unix_events :: (server: *IPC_Server, timeout_ms: s32) -> s32 {
    // Build poll fd array
    nfds: u64 = 0;

    // Add server socket
    server.poll_fds[0].fd = server.server_fd;
    server.poll_fds[0].events = POLLIN;
    server.poll_fds[0].revents = 0;
    nfds = 1;

    // Add client sockets
    for *conn: server.connections {
        if conn.state == .CONNECTED && nfds < MAX_CLIENTS + 1 {
            server.poll_fds[nfds].fd = conn.fd;
            server.poll_fds[nfds].events = POLLIN;
            if conn.write_buffer_len > 0 {
                server.poll_fds[nfds].events |= POLLOUT;
            }
            server.poll_fds[nfds].revents = 0;
            nfds += 1;
        }
    }

    // Poll
    result := ipc_poll(server.poll_fds.data, nfds, timeout_ms);
    return result;
}

// Accept connections on Unix
accept_unix_connections :: (server: *IPC_Server) -> s32 {
    accepted := 0;

    while true {
        // Find a free connection slot
        free_slot: *IPC_Connection = null;
        for *conn: server.connections {
            if conn.state == .DISCONNECTED {
                free_slot = conn;
                break;
            }
        }

        if free_slot == null {
            break;  // No free slots
        }

        // Accept connection
        client_fd := ipc_accept(server.server_fd, null, null);
        if client_fd < 0 {
            break;  // No more connections to accept (would block)
        }

        // Set non-blocking
        flags := ipc_fcntl_get(client_fd, F_GETFL);
        ipc_fcntl_set(client_fd, F_SETFL, flags | O_NONBLOCK);

        // Initialize connection
        free_slot.id = server.next_connection_id;
        server.next_connection_id += 1;
        free_slot.fd = client_fd;
        free_slot.state = .CONNECTED;
        free_slot.read_buffer_len = 0;
        free_slot.write_buffer_len = 0;
        free_slot.write_buffer_offset = 0;
        free_slot.last_activity = current_time_consensus();
        free_slot.user_data = null;

        server.connection_count += 1;
        server.total_connections += 1;
        accepted += 1;
    }

    return cast(s32) accepted;
}

// Close connection (must be called with mutex held)
close_connection_locked :: (server: *IPC_Server, conn: *IPC_Connection) {
    if conn.state == .DISCONNECTED return;

    if conn.fd >= 0 {
        close(conn.fd);
        conn.fd = -1;
    }

    conn.id = 0;
    conn.state = .DISCONNECTED;
    conn.read_buffer_len = 0;
    conn.write_buffer_len = 0;
    conn.write_buffer_offset = 0;

    if server.connection_count > 0 {
        server.connection_count -= 1;
    }
}

} // #if OS == .LINUX || OS == .MACOS

//
// ============================================================================
// IPC CLIENT IMPLEMENTATION
// ============================================================================
//

// IPC Client for connecting to a server
IPC_Client :: struct {
    socket_path: string;
    fd: s32;
    state: Connection_State;
    initialized: bool;

    // Buffers for read/write operations
    read_buffer: [IPC_BUFFER_SIZE] u8;
    read_buffer_len: s64;
    write_buffer: [IPC_BUFFER_SIZE] u8;
    write_buffer_len: s64;
    write_buffer_offset: s64;

    last_activity: Apollo_Time;

    // Statistics
    bytes_received: u64;
    bytes_sent: u64;
}

// Initialize IPC client
init_ipc_client :: (client: *IPC_Client, socket_path: string) -> bool {
    if client.initialized {
        return false;  // Already initialized
    }

    client.socket_path = copy_string(socket_path);
    client.fd = -1;
    client.state = .DISCONNECTED;
    client.initialized = true;
    client.read_buffer_len = 0;
    client.write_buffer_len = 0;
    client.write_buffer_offset = 0;
    client.bytes_received = 0;
    client.bytes_sent = 0;

    return true;
}

// Destroy IPC client
destroy_ipc_client :: (client: *IPC_Client) {
    if !client.initialized return;

    disconnect_client(client);
    free(client.socket_path);
    client.initialized = false;
}

// Connect to server
connect_client :: (client: *IPC_Client) -> bool {
    if !client.initialized return false;
    if client.state == .CONNECTED return true;  // Already connected

    #if OS == .LINUX || OS == .MACOS {
        return connect_unix_client(client);
    } else #if OS == .WINDOWS {
        return connect_windows_client(client);
    } else {
        return false;
    }
}

// Disconnect from server
disconnect_client :: (client: *IPC_Client) {
    if !client.initialized return;
    if client.state == .DISCONNECTED return;

    #if OS == .LINUX || OS == .MACOS {
        if client.fd >= 0 {
            close(client.fd);
            client.fd = -1;
        }
    } else #if OS == .WINDOWS {
        disconnect_windows_client(client);
        return;  // Windows function handles state reset
    }

    client.state = .DISCONNECTED;
    client.read_buffer_len = 0;
    client.write_buffer_len = 0;
    client.write_buffer_offset = 0;
}

// Send data to server
client_send :: (client: *IPC_Client, data: [] u8) -> s64 {
    if client.state != .CONNECTED return -1;
    if data.count == 0 return 0;

    #if OS == .LINUX || OS == .MACOS {
        result := write(client.fd, data.data, cast(u64) data.count);
        if result > 0 {
            client.bytes_sent += cast(u64) result;
            client.last_activity = current_time_consensus();
        }
        return result;
    } else #if OS == .WINDOWS {
        return client_send_windows(client, data);
    } else {
        return -1;
    }
}

// Receive data from server
// Returns bytes read, 0 on EOF (server closed), -1 on error
client_receive :: (client: *IPC_Client, buffer: [] u8) -> s64 {
    if client.state != .CONNECTED return -1;
    if buffer.count == 0 return 0;

    #if OS == .LINUX || OS == .MACOS {
        result := read(client.fd, buffer.data, cast(u64) buffer.count);
        if result > 0 {
            client.bytes_received += cast(u64) result;
            client.last_activity = current_time_consensus();
        } else if result == 0 {
            // Server closed connection
            client.state = .DISCONNECTED;
        }
        return result;
    } else #if OS == .WINDOWS {
        return client_receive_windows(client, buffer);
    } else {
        return -1;
    }
}

// Check if client has data available to read (non-blocking)
// Returns: 1 if data available, 0 if no data, -1 on error
client_poll :: (client: *IPC_Client, timeout_ms: s32) -> s32 {
    if client.state != .CONNECTED return -1;

    #if OS == .LINUX || OS == .MACOS {
        pfd: pollfd;
        pfd.fd = client.fd;
        pfd.events = POLLIN;
        pfd.revents = 0;

        result := ipc_poll(*pfd, 1, timeout_ms);
        if result > 0 {
            if pfd.revents & POLLIN {
                return 1;  // Data available
            }
            if pfd.revents & (POLLHUP | POLLERR) {
                client.state = .ERROR;
                return -1;  // Error or hangup
            }
        }
        return result;
    } else #if OS == .WINDOWS {
        return client_poll_windows(client, timeout_ms);
    } else {
        return -1;
    }
}

// Get client state
client_is_connected :: (client: *IPC_Client) -> bool {
    return client.initialized && client.state == .CONNECTED;
}

// Get client stats
IPC_Client_Stats :: struct {
    bytes_received: u64;
    bytes_sent: u64;
}

get_client_stats :: (client: *IPC_Client) -> IPC_Client_Stats {
    stats: IPC_Client_Stats;
    stats.bytes_received = client.bytes_received;
    stats.bytes_sent = client.bytes_sent;
    return stats;
}

#if OS == .LINUX || OS == .MACOS {

// Import connect from libc
ipc_connect :: (sockfd: s32, addr: *void, addrlen: u32) -> s32 #foreign libc "connect";

// Connect to Unix domain socket server
connect_unix_client :: (client: *IPC_Client) -> bool {
    // Create socket
    client.fd = ipc_socket(IPC_AF_UNIX, IPC_SOCK_STREAM, 0);
    if client.fd < 0 {
        client.state = .ERROR;
        return false;
    }

    // Prepare address
    addr: IPC_sockaddr_un;
    addr.sun_family = IPC_AF_UNIX;

    // Copy path to sun_path
    path_bytes := cast([] u8) client.socket_path;
    for i: 0..ipc_min(path_bytes.count, 107) - 1 {
        addr.sun_path[i] = path_bytes[i];
    }
    addr.sun_path[ipc_min(path_bytes.count, 107)] = 0;

    // Connect
    if ipc_connect(client.fd, *addr, size_of(IPC_sockaddr_un)) < 0 {
        close(client.fd);
        client.fd = -1;
        client.state = .ERROR;
        return false;
    }

    client.state = .CONNECTED;
    client.last_activity = current_time_consensus();
    return true;
}

} // #if OS == .LINUX || OS == .MACOS

// Helper: Convert Jai string to C string (local version)
ipc_to_c_string :: (s: string) -> *u8 {
    if s.count == 0 return null;

    result := alloc(s.count + 1);
    memcpy(result, s.data, s.count);
    (cast(*u8) result)[s.count] = 0;
    return result;
}

// Helper: minimum of two values (local version)
ipc_min :: inline (a: $T, b: T) -> T {
    return ifx a < b then a else b;
}

//
// ============================================================================
// WINDOWS NAMED PIPE IMPLEMENTATION
// ============================================================================
//

#if OS == .WINDOWS {

#scope_file

// Windows type aliases (scoped to this file to avoid conflicts with Windows module)
HANDLE :: *void;
DWORD :: u32;
BOOL :: s32;
LPCSTR :: *u8;
LPVOID :: *void;

// Windows constants
INVALID_HANDLE_VALUE :: cast(HANDLE) -1;
PIPE_ACCESS_DUPLEX :: 0x00000003;
PIPE_TYPE_BYTE :: 0x00000000;
PIPE_READMODE_BYTE :: 0x00000000;
PIPE_WAIT :: 0x00000000;
PIPE_NOWAIT :: 0x00000001;
PIPE_UNLIMITED_INSTANCES :: 255;
GENERIC_READ :: 0x80000000;
GENERIC_WRITE :: 0x40000000;
OPEN_EXISTING :: 3;
FILE_FLAG_OVERLAPPED :: 0x40000000;
ERROR_IO_PENDING :: 997;
ERROR_PIPE_LISTENING :: 536;
ERROR_PIPE_BUSY :: 231;
ERROR_PIPE_CONNECTED :: 535;
ERROR_NO_DATA :: 232;
ERROR_BROKEN_PIPE :: 109;
NMPWAIT_USE_DEFAULT_WAIT :: 0;
NMPWAIT_WAIT_FOREVER :: 0xFFFFFFFF;

// Windows API functions
kernel32 :: #system_library "kernel32";

CreateNamedPipeA :: (
    lpName: LPCSTR,
    dwOpenMode: DWORD,
    dwPipeMode: DWORD,
    nMaxInstances: DWORD,
    nOutBufferSize: DWORD,
    nInBufferSize: DWORD,
    nDefaultTimeOut: DWORD,
    lpSecurityAttributes: LPVOID
) -> HANDLE #foreign kernel32;

ConnectNamedPipe :: (hNamedPipe: HANDLE, lpOverlapped: LPVOID) -> BOOL #foreign kernel32;
DisconnectNamedPipe :: (hNamedPipe: HANDLE) -> BOOL #foreign kernel32;
CreateFileA :: (
    lpFileName: LPCSTR,
    dwDesiredAccess: DWORD,
    dwShareMode: DWORD,
    lpSecurityAttributes: LPVOID,
    dwCreationDisposition: DWORD,
    dwFlagsAndAttributes: DWORD,
    hTemplateFile: HANDLE
) -> HANDLE #foreign kernel32;

ReadFile :: (
    hFile: HANDLE,
    lpBuffer: LPVOID,
    nNumberOfBytesToRead: DWORD,
    lpNumberOfBytesRead: *DWORD,
    lpOverlapped: LPVOID
) -> BOOL #foreign kernel32;

WriteFile :: (
    hFile: HANDLE,
    lpBuffer: LPVOID,
    nNumberOfBytesToWrite: DWORD,
    lpNumberOfBytesWritten: *DWORD,
    lpOverlapped: LPVOID
) -> BOOL #foreign kernel32;

CloseHandle :: (hObject: HANDLE) -> BOOL #foreign kernel32;
GetLastError :: () -> DWORD #foreign kernel32;
WaitNamedPipeA :: (lpNamedPipeName: LPCSTR, nTimeOut: DWORD) -> BOOL #foreign kernel32;
PeekNamedPipe :: (
    hNamedPipe: HANDLE,
    lpBuffer: LPVOID,
    nBufferSize: DWORD,
    lpBytesRead: *DWORD,
    lpTotalBytesAvail: *DWORD,
    lpBytesLeftThisMessage: *DWORD
) -> BOOL #foreign kernel32;

SetNamedPipeHandleState :: (
    hNamedPipe: HANDLE,
    lpMode: *DWORD,
    lpMaxCollectionCount: *DWORD,
    lpCollectDataTimeout: *DWORD
) -> BOOL #foreign kernel32;

#scope_export  // Re-export the IPC functions

// Start Windows named pipe server
start_windows_server :: (server: *IPC_Server) -> bool {
    // Create the named pipe
    // The pipe name should be in the form \\.\pipe\pipename
    pipe_name := ipc_to_c_string(server.socket_path);
    defer free(pipe_name);

    // Use PIPE_NOWAIT for non-blocking ConnectNamedPipe
    pipe_handle := CreateNamedPipeA(
        pipe_name,
        PIPE_ACCESS_DUPLEX,
        PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_NOWAIT,
        PIPE_UNLIMITED_INSTANCES,
        cast(DWORD) IPC_BUFFER_SIZE,
        cast(DWORD) IPC_BUFFER_SIZE,
        0,  // Default timeout
        null
    );

    if pipe_handle == INVALID_HANDLE_VALUE {
        server.server_fd = -1;
        return false;
    }

    server.server_fd = cast(s32) cast(u64) pipe_handle;

    server.running = true;
    return true;
}

// Poll for events on Windows (check for pending connections and data)
poll_windows_events :: (server: *IPC_Server, timeout_ms: s32) -> s32 {
    events_found: s32 = 0;

    // Check each connected client for available data
    for *conn: server.connections {
        if conn.state == .CONNECTED {
            bytes_available: DWORD = 0;
            if PeekNamedPipe(cast(HANDLE) cast(u64) conn.fd, null, 0, null, *bytes_available, null) {
                if bytes_available > 0 {
                    events_found += 1;
                }
            } else {
                // Pipe error - client may have disconnected
                err := GetLastError();
                if err == ERROR_BROKEN_PIPE || err == ERROR_NO_DATA {
                    conn.state = .ERROR;
                    events_found += 1;  // Signal that this connection needs attention
                }
            }
        }
    }

    // Check if server pipe is ready for a new connection
    // This is a simplified check - in production, use overlapped I/O
    if server.connection_count < MAX_CLIENTS {
        // Attempt a non-blocking connection check
        // For now, we signal that connections might be pending
        events_found += 1;
    }

    return events_found;
}

// Accept connections on Windows
accept_windows_connections :: (server: *IPC_Server) -> s32 {
    accepted: s32 = 0;

    // Find a free connection slot
    free_slot: *IPC_Connection = null;
    for *conn: server.connections {
        if conn.state == .DISCONNECTED {
            free_slot = conn;
            break;
        }
    }

    if free_slot == null {
        return 0;  // No free slots
    }

    // For named pipes with PIPE_NOWAIT, ConnectNamedPipe returns immediately
    pipe_name := ipc_to_c_string(server.socket_path);
    defer free(pipe_name);

    // The current server_fd becomes the client connection
    // We create a new server pipe for future connections
    if server.server_fd >= 0 {
        // Try to connect a client to the existing pipe (non-blocking with PIPE_NOWAIT)
        result := ConnectNamedPipe(cast(HANDLE) cast(u64) server.server_fd, null);
        err := GetLastError();

        // With PIPE_NOWAIT:
        // - result=TRUE: connection completed (rare)
        // - result=FALSE with ERROR_PIPE_CONNECTED: client already connected
        // - result=FALSE with ERROR_PIPE_LISTENING: no client yet (non-blocking return)
        // - result=FALSE with other error: actual error

        client_connected := result || err == ERROR_PIPE_CONNECTED;

        if client_connected {
            // Client connected
            free_slot.id = server.next_connection_id;
            server.next_connection_id += 1;
            free_slot.fd = server.server_fd;
            free_slot.state = .CONNECTED;
            free_slot.read_buffer_len = 0;
            free_slot.write_buffer_len = 0;
            free_slot.write_buffer_offset = 0;
            free_slot.last_activity = current_time_consensus();
            free_slot.user_data = null;

            server.connection_count += 1;
            server.total_connections += 1;
            accepted += 1;

            // Create a new pipe for the next client (with PIPE_NOWAIT for non-blocking)
            new_pipe := CreateNamedPipeA(
                pipe_name,
                PIPE_ACCESS_DUPLEX,
                PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_NOWAIT,
                PIPE_UNLIMITED_INSTANCES,
                cast(DWORD) IPC_BUFFER_SIZE,
                cast(DWORD) IPC_BUFFER_SIZE,
                0,
                null
            );

            if new_pipe == INVALID_HANDLE_VALUE {
                server.server_fd = -1;
            } else {
                server.server_fd = cast(s32) cast(u64) new_pipe;
            }
        }
        // If ERROR_PIPE_LISTENING, no client yet - just return and try again next iteration
    }

    return accepted;
}

// Close connection on Windows
close_windows_connection :: (server: *IPC_Server, conn: *IPC_Connection) {
    if conn.state == .DISCONNECTED return;

    if conn.fd >= 0 {
        // Disconnect the named pipe
        DisconnectNamedPipe(cast(HANDLE) cast(u64) conn.fd);
        CloseHandle(cast(HANDLE) cast(u64) conn.fd);
        conn.fd = -1;
    }

    conn.id = 0;
    conn.state = .DISCONNECTED;
    conn.read_buffer_len = 0;
    conn.write_buffer_len = 0;
    conn.write_buffer_offset = 0;

    if server.connection_count > 0 {
        server.connection_count -= 1;
    }
}

// Read from Windows named pipe connection
read_windows_connection :: (server: *IPC_Server, conn: *IPC_Connection, buffer: [] u8) -> s64 {
    if conn.state != .CONNECTED return -1;

    bytes_read: DWORD = 0;
    if ReadFile(
        cast(HANDLE) cast(u64) conn.fd,
        buffer.data,
        cast(DWORD) buffer.count,
        *bytes_read,
        null
    ) {
        if bytes_read > 0 {
            server.total_bytes_received += cast(u64) bytes_read;
            conn.last_activity = current_time_consensus();
        }
        return cast(s64) bytes_read;
    }

    err := GetLastError();
    if err == ERROR_BROKEN_PIPE {
        return 0;  // EOF - client disconnected
    }

    return -1;  // Error
}

// Write to Windows named pipe connection
write_windows_connection :: (server: *IPC_Server, conn: *IPC_Connection, data: [] u8) -> s64 {
    if conn.state != .CONNECTED return -1;

    bytes_written: DWORD = 0;
    if WriteFile(
        cast(HANDLE) cast(u64) conn.fd,
        data.data,
        cast(DWORD) data.count,
        *bytes_written,
        null
    ) {
        if bytes_written > 0 {
            server.total_bytes_sent += cast(u64) bytes_written;
            conn.last_activity = current_time_consensus();
        }
        return cast(s64) bytes_written;
    }

    return -1;  // Error
}

// Connect Windows named pipe client
connect_windows_client :: (client: *IPC_Client) -> bool {
    pipe_name := ipc_to_c_string(client.socket_path);
    defer free(pipe_name);

    // Wait for the pipe to be available (with timeout)
    if !WaitNamedPipeA(pipe_name, 5000) {  // 5 second timeout
        err := GetLastError();
        if err == ERROR_PIPE_BUSY {
            client.state = .ERROR;
            return false;
        }
        // Pipe doesn't exist or error
        client.state = .ERROR;
        return false;
    }

    // Open the pipe
    handle := CreateFileA(
        pipe_name,
        GENERIC_READ | GENERIC_WRITE,
        0,  // No sharing
        null,
        OPEN_EXISTING,
        0,
        null
    );

    if handle == INVALID_HANDLE_VALUE {
        client.state = .ERROR;
        return false;
    }

    client.fd = cast(s32) cast(u64) handle;
    client.state = .CONNECTED;
    client.last_activity = current_time_consensus();

    return true;
}

// Disconnect Windows named pipe client
disconnect_windows_client :: (client: *IPC_Client) {
    if client.fd >= 0 {
        CloseHandle(cast(HANDLE) cast(u64) client.fd);
        client.fd = -1;
    }

    client.state = .DISCONNECTED;
    client.read_buffer_len = 0;
    client.write_buffer_len = 0;
    client.write_buffer_offset = 0;
}

// Send data via Windows named pipe client
client_send_windows :: (client: *IPC_Client, data: [] u8) -> s64 {
    if client.state != .CONNECTED return -1;
    if data.count == 0 return 0;

    bytes_written: DWORD = 0;
    if WriteFile(
        cast(HANDLE) cast(u64) client.fd,
        data.data,
        cast(DWORD) data.count,
        *bytes_written,
        null
    ) {
        if bytes_written > 0 {
            client.bytes_sent += cast(u64) bytes_written;
            client.last_activity = current_time_consensus();
        }
        return cast(s64) bytes_written;
    }

    return -1;
}

// Receive data via Windows named pipe client
client_receive_windows :: (client: *IPC_Client, buffer: [] u8) -> s64 {
    if client.state != .CONNECTED return -1;
    if buffer.count == 0 return 0;

    bytes_read: DWORD = 0;
    if ReadFile(
        cast(HANDLE) cast(u64) client.fd,
        buffer.data,
        cast(DWORD) buffer.count,
        *bytes_read,
        null
    ) {
        if bytes_read > 0 {
            client.bytes_received += cast(u64) bytes_read;
            client.last_activity = current_time_consensus();
        } else if bytes_read == 0 {
            client.state = .DISCONNECTED;
        }
        return cast(s64) bytes_read;
    }

    err := GetLastError();
    if err == ERROR_BROKEN_PIPE {
        client.state = .DISCONNECTED;
        return 0;
    }

    return -1;
}

// Poll for data on Windows named pipe client
client_poll_windows :: (client: *IPC_Client, timeout_ms: s32) -> s32 {
    if client.state != .CONNECTED return -1;

    bytes_available: DWORD = 0;
    if PeekNamedPipe(cast(HANDLE) cast(u64) client.fd, null, 0, null, *bytes_available, null) {
        if bytes_available > 0 {
            return 1;  // Data available
        }
        return 0;  // No data
    }

    err := GetLastError();
    if err == ERROR_BROKEN_PIPE {
        client.state = .DISCONNECTED;
    }

    return -1;  // Error
}

} // #if OS == .WINDOWS
