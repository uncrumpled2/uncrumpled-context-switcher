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
#import "POSIX";
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

// Destroy IPC server
destroy_ipc_server :: (server: *IPC_Server) {
    if !server.initialized return;

    lock(*server.mutex);
    defer unlock(*server.mutex);

    // Close all client connections
    for *conn: server.connections {
        if conn.state != .DISCONNECTED {
            close_connection_locked(server, conn);
        }
    }

    // Close server socket
    if server.server_fd >= 0 {
        close(server.server_fd);
        server.server_fd = -1;
    }

    // Remove socket file
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
    } else {
        // Windows named pipes - TODO
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

    #if OS == .LINUX || OS == .MACOS {
        result := write(conn.fd, data_ptr, cast(u64) remaining);
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
    } else {
        return -1;
    }
}

// Close a connection
close_connection :: (server: *IPC_Server, conn: *IPC_Connection) {
    lock(*server.mutex);
    defer unlock(*server.mutex);

    close_connection_locked(server, conn);
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
