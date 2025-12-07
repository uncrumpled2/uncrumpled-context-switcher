// Uncrumpled Service SDK - Client Library
//
// This library provides an easy-to-use interface for services to:
// - Connect to the Uncrumpled daemon
// - Register as a service
// - Subscribe to context change events
// - Send heartbeats
// - Receive event notifications
//
// Example usage:
//
//   client: Service_Client;
//   if !init_service_client(*client) { /* handle error */ }
//   defer deinit_service_client(*client);
//
//   if !connect(*client, "/tmp/uncrumpled.sock") { /* handle error */ }
//
//   // Register this service
//   reg := make_registration("my-service", "My Service", "/tmp/my-service.sock");
//   array_add(*reg.capabilities.events, "context.changed");
//   if !register_service(*client, *reg) { /* handle error */ }
//
//   // Main loop
//   while running {
//       // Send heartbeat periodically
//       if should_send_heartbeat(*client) {
//           send_heartbeat(*client);
//       }
//
//       // Check for events (non-blocking)
//       if has_pending_events(*client) {
//           event := receive_event(*client);
//           if event.valid {
//               // Handle the event
//           }
//       }
//
//       // Do other work...
//   }

#import "Basic";
#import "String";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
#import "Thread";

// ============================================================================
// Socket Helper Functions
// ============================================================================
// Use POSIX module directly for socket operations

// ============================================================================
// SDK Version and Configuration
// ============================================================================

SDK_VERSION :: "1.0.0";

// Default configuration values
SDK_DEFAULT_SOCKET_PATH :: "/tmp/uncrumpled.sock";
SDK_DEFAULT_HEARTBEAT_INTERVAL :: 30;  // seconds
SDK_DEFAULT_RECV_BUFFER_SIZE :: 65536;
SDK_DEFAULT_SEND_BUFFER_SIZE :: 8192;

// ============================================================================
// Client Configuration
// ============================================================================

Service_Client_Config :: struct {
    socket_path: string;              // Daemon socket path
    heartbeat_interval_seconds: int;  // How often to send heartbeats
    recv_buffer_size: int;            // Receive buffer size
    send_buffer_size: int;            // Send buffer size
    auto_reconnect: bool;             // Automatically reconnect on disconnect
    reconnect_delay_ms: int;          // Delay between reconnection attempts
}

init_sdk_client_config :: () -> Service_Client_Config {
    config: Service_Client_Config;
    config.socket_path = SDK_DEFAULT_SOCKET_PATH;
    config.heartbeat_interval_seconds = SDK_DEFAULT_HEARTBEAT_INTERVAL;
    config.recv_buffer_size = SDK_DEFAULT_RECV_BUFFER_SIZE;
    config.send_buffer_size = SDK_DEFAULT_SEND_BUFFER_SIZE;
    config.auto_reconnect = true;
    config.reconnect_delay_ms = 1000;
    return config;
}

// ============================================================================
// Service Registration
// ============================================================================

// Information to register a service with the daemon
Service_Registration :: struct {
    id: string;
    name: string;
    endpoint: string;              // Where daemon should send notifications to this service
    capabilities: SDK_Capability_Manifest;
    preview_callback: string;      // Optional RPC method for preview
}

// Capability manifest for the service
SDK_Capability_Manifest :: struct {
    events: [..] string;           // Events this service cares about
    provides_preview: bool;        // Whether this service can provide previews
    api_version: string;           // API version supported (default: "1.0.0")
}

// Create a new service registration
make_registration :: (id: string, name: string, endpoint: string) -> Service_Registration {
    reg: Service_Registration;
    reg.id = copy_string(id);
    reg.name = copy_string(name);
    reg.endpoint = copy_string(endpoint);
    reg.capabilities.api_version = copy_string("1.0.0");
    reg.capabilities.provides_preview = false;
    return reg;
}

// Free a service registration
free_registration :: (reg: *Service_Registration) {
    free(reg.id);
    free(reg.name);
    free(reg.endpoint);
    free(reg.preview_callback);
    for reg.capabilities.events {
        free(it);
    }
    array_free(reg.capabilities.events);
    free(reg.capabilities.api_version);
}

// ============================================================================
// Event Types
// ============================================================================

// Event types the SDK can receive
SDK_Event_Type :: enum {
    UNKNOWN;
    CONTEXT_CHANGED;
    SERVICE_REGISTERED;
    SERVICE_UNREGISTERED;
    HEARTBEAT_ACK;
    ERROR;
}

// An event received from the daemon
SDK_Event :: struct {
    valid: bool;
    event_type: SDK_Event_Type;
    raw_json: string;              // Raw JSON for custom parsing
    // For CONTEXT_CHANGED events:
    changed_fields: [..] string;   // Which fields changed
    // Error information (if event_type == ERROR)
    error_message: string;
}

// Create an empty/invalid event
make_empty_event :: () -> SDK_Event {
    event: SDK_Event;
    event.valid = false;
    event.event_type = .UNKNOWN;
    return event;
}

// Free an event's resources
free_sdk_event :: (event: *SDK_Event) {
    free(event.raw_json);
    for event.changed_fields {
        free(it);
    }
    array_free(event.changed_fields);
    free(event.error_message);
}

// ============================================================================
// Service Client State
// ============================================================================

SDK_Client_State :: enum {
    DISCONNECTED;
    CONNECTING;
    CONNECTED;
    REGISTERED;
    ERROR;
}

// Statistics for the client
SDK_Client_Stats :: struct {
    requests_sent: u64;
    responses_received: u64;
    events_received: u64;
    heartbeats_sent: u64;
    errors: u64;
    bytes_sent: u64;
    bytes_received: u64;
    connected_at: Apollo_Time;
    last_heartbeat_sent: Apollo_Time;
    last_event_received: Apollo_Time;
}

// The main service client
Service_Client :: struct {
    // Configuration
    config: Service_Client_Config;

    // Connection state
    state: SDK_Client_State;
    socket_fd: s32;
    daemon_socket_path: string;

    // Registration info (if registered)
    registration: Service_Registration;
    is_registered: bool;
    session_id: string;

    // Listener socket (for receiving notifications)
    listener_fd: s32;
    listener_path: string;
    listener_active: bool;

    // Buffers
    recv_buffer: [..] u8;
    send_buffer: [..] u8;

    // Request ID counter
    next_request_id: u64;

    // Statistics
    stats: SDK_Client_Stats;

    // Thread safety
    mutex: Mutex;
    initialized: bool;
}

// ============================================================================
// Client Lifecycle
// ============================================================================

// Initialize a service client with default configuration
init_service_client :: (client: *Service_Client) -> bool {
    return init_service_client_with_config(client, init_sdk_client_config());
}

// Initialize a service client with custom configuration
init_service_client_with_config :: (client: *Service_Client, config: Service_Client_Config) -> bool {
    if client.initialized {
        return false;  // Already initialized
    }

    client.config = config;
    client.state = .DISCONNECTED;
    client.socket_fd = -1;
    client.listener_fd = -1;
    client.is_registered = false;
    client.listener_active = false;
    client.next_request_id = 1;

    // Initialize buffers
    array_reserve(*client.recv_buffer, config.recv_buffer_size);
    array_reserve(*client.send_buffer, config.send_buffer_size);

    // Initialize mutex
    init(*client.mutex);

    client.initialized = true;
    return true;
}

// Deinitialize a service client
deinit_service_client :: (client: *Service_Client) {
    if !client.initialized return;

    lock(*client.mutex);

    // Disconnect if connected
    if client.state != .DISCONNECTED {
        disconnect_internal(client);
    }

    // Stop listener if active
    if client.listener_active {
        stop_listener_internal(client);
    }

    // Free registration if registered
    if client.is_registered {
        free_registration(*client.registration);
        client.is_registered = false;
    }

    // Free buffers
    array_free(client.recv_buffer);
    array_free(client.send_buffer);

    // Free strings
    free(client.daemon_socket_path);
    free(client.session_id);
    free(client.listener_path);

    client.initialized = false;

    unlock(*client.mutex);
    destroy(*client.mutex);
}

// ============================================================================
// Connection Management
// ============================================================================

// Connect to the daemon
connect :: (client: *Service_Client, socket_path: string = "") -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if client.state != .DISCONNECTED {
        return false;  // Already connected or connecting
    }

    path := socket_path;
    if path.count == 0 {
        path = client.config.socket_path;
    }

    client.state = .CONNECTING;

    #if OS == .LINUX || OS == .MACOS {
        // Create socket
        client.socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if client.socket_fd < 0 {
            client.state = .ERROR;
            client.stats.errors += 1;
            return false;
        }

        // Setup address
        addr: sockaddr_un;
        addr.sun_family = AF_UNIX;

        // Copy socket path to sun_path
        path_bytes := cast([] u8) path;
        max_len := addr.sun_path.count - 1;
        copy_len := min(path_bytes.count, max_len);
        memcpy(addr.sun_path.data, path_bytes.data, copy_len);
        addr.sun_path[copy_len] = 0;

        // Connect
        result := connect(client.socket_fd, cast(*sockaddr) *addr, size_of(sockaddr_un));
        if result < 0 {
            close(client.socket_fd);
            client.socket_fd = -1;
            client.state = .ERROR;
            client.stats.errors += 1;
            return false;
        }

        // Store the path
        client.daemon_socket_path = copy_string(path);
        client.state = .CONNECTED;
        client.stats.connected_at = current_time_consensus();

        return true;
    } else {
        client.state = .ERROR;
        return false;
    }
}

// Disconnect from the daemon
disconnect :: (client: *Service_Client) {
    if !client.initialized return;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    disconnect_internal(client);
}

// Internal disconnect (must hold mutex)
disconnect_internal :: (client: *Service_Client) {
    if client.socket_fd >= 0 {
        close(client.socket_fd);
        client.socket_fd = -1;
    }

    free(client.daemon_socket_path);
    client.daemon_socket_path = "";
    client.state = .DISCONNECTED;
}

// Check if connected
is_connected :: (client: *Service_Client) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    return client.state == .CONNECTED || client.state == .REGISTERED;
}

// Get current state
get_state :: (client: *Service_Client) -> SDK_Client_State {
    if !client.initialized return .DISCONNECTED;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    return client.state;
}

// ============================================================================
// Service Registration
// ============================================================================

// Register this service with the daemon
register_service :: (client: *Service_Client, reg: *Service_Registration) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if client.state != .CONNECTED {
        return false;  // Must be connected first
    }

    // Build registration JSON
    json := build_registration_json(reg, client.next_request_id);
    client.next_request_id += 1;

    // Send request
    success := send_request_internal(client, json);
    free(json);

    if !success {
        return false;
    }

    // Receive response
    response := receive_response_internal(client);
    defer free(response);

    if response.count == 0 {
        return false;
    }

    // Check for success in response (simplified check)
    if contains(response, "\"registered\":true") || contains(response, "\"registered\": true") {
        // Copy registration info
        if client.is_registered {
            free_registration(*client.registration);
        }
        client.registration = copy_registration(reg);
        client.is_registered = true;
        client.state = .REGISTERED;
        return true;
    }

    return false;
}

// Unregister this service from the daemon
unregister_service :: (client: *Service_Client) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if !client.is_registered {
        return false;
    }

    // Build unregister JSON
    json := tprint("{\"jsonrpc\":\"2.0\",\"method\":\"service.unregister\",\"params\":{\"id\":\"%\"},\"id\":%}",
                   client.registration.id, client.next_request_id);
    client.next_request_id += 1;

    // Send request
    success := send_request_internal(client, json);
    if !success {
        return false;
    }

    // Receive response
    response := receive_response_internal(client);
    defer free(response);

    if response.count == 0 {
        return false;
    }

    // Check for success
    if contains(response, "\"unregistered\":true") || contains(response, "\"unregistered\": true") {
        free_registration(*client.registration);
        client.is_registered = false;
        client.state = .CONNECTED;
        return true;
    }

    return false;
}

// Send a heartbeat to the daemon
send_heartbeat :: (client: *Service_Client) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if !client.is_registered {
        return false;
    }

    // Build heartbeat JSON
    json := tprint("{\"jsonrpc\":\"2.0\",\"method\":\"service.heartbeat\",\"params\":{\"id\":\"%\"},\"id\":%}",
                   client.registration.id, client.next_request_id);
    client.next_request_id += 1;

    // Send request
    success := send_request_internal(client, json);
    if !success {
        return false;
    }

    // Receive response
    response := receive_response_internal(client);
    defer free(response);

    if response.count == 0 {
        return false;
    }

    // Check for acknowledgment
    if contains(response, "\"acknowledged\":true") || contains(response, "\"acknowledged\": true") {
        client.stats.heartbeats_sent += 1;
        client.stats.last_heartbeat_sent = current_time_consensus();
        return true;
    }

    return false;
}

// Check if it's time to send a heartbeat
should_send_heartbeat :: (client: *Service_Client) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if !client.is_registered {
        return false;
    }

    // Calculate seconds since last heartbeat
    now := current_time_consensus();
    interval_apollo := seconds_to_apollo(cast(s64) client.config.heartbeat_interval_seconds);

    return now >= client.stats.last_heartbeat_sent + interval_apollo;
}

// ============================================================================
// Event Listener
// ============================================================================

// Start a listener for incoming events from the daemon
// The listener creates a Unix socket at the specified path
start_listener :: (client: *Service_Client, listener_path: string) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if client.listener_active {
        return false;  // Already listening
    }

    #if OS == .LINUX || OS == .MACOS {
        // Remove any existing socket file
        unlink(temp_c_string(listener_path));

        // Create listener socket
        client.listener_fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if client.listener_fd < 0 {
            return false;
        }

        // Setup address
        addr: sockaddr_un;
        addr.sun_family = AF_UNIX;

        path_bytes := cast([] u8) listener_path;
        max_len := addr.sun_path.count - 1;
        copy_len := min(path_bytes.count, max_len);
        memcpy(addr.sun_path.data, path_bytes.data, copy_len);
        addr.sun_path[copy_len] = 0;

        // Bind
        result := bind(client.listener_fd, cast(*sockaddr) *addr, size_of(sockaddr_un));
        if result < 0 {
            close(client.listener_fd);
            client.listener_fd = -1;
            return false;
        }

        // Listen
        result = listen(client.listener_fd, 5);
        if result < 0 {
            close(client.listener_fd);
            client.listener_fd = -1;
            return false;
        }

        // Set non-blocking
        flags := fcntl(client.listener_fd, F_GETFL);
        fcntl(client.listener_fd, F_SETFL, flags | O_NONBLOCK);

        client.listener_path = copy_string(listener_path);
        client.listener_active = true;

        return true;
    } else {
        return false;
    }
}

// Stop the event listener
stop_listener :: (client: *Service_Client) {
    if !client.initialized return;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    stop_listener_internal(client);
}

// Internal stop listener (must hold mutex)
stop_listener_internal :: (client: *Service_Client) {
    if !client.listener_active return;

    #if OS == .LINUX || OS == .MACOS {
        if client.listener_fd >= 0 {
            close(client.listener_fd);
            client.listener_fd = -1;
        }

        // Remove socket file
        if client.listener_path.count > 0 {
            unlink(temp_c_string(client.listener_path));
            free(client.listener_path);
            client.listener_path = "";
        }

        client.listener_active = false;
    }
}

// Check if there are pending events (non-blocking)
has_pending_events :: (client: *Service_Client) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if !client.listener_active {
        return false;
    }

    #if OS == .LINUX || OS == .MACOS {
        // Try to accept a connection (non-blocking)
        // In a real implementation, we'd use select/poll/epoll
        // For simplicity, we just check if accept would succeed
        addr_len: u32 = size_of(sockaddr_un);
        addr: sockaddr_un;

        conn_fd := accept(client.listener_fd, cast(*sockaddr) *addr, *addr_len);
        if conn_fd >= 0 {
            // We got a connection - read the data and close
            buffer: [4096] u8;
            bytes_read := read(conn_fd, buffer.data, 4095);
            close(conn_fd);

            if bytes_read > 0 {
                // There's pending data - we'd store this for receive_event
                // For now, just indicate there was an event
                return true;
            }
        }

        return false;
    } else {
        return false;
    }
}

// Receive an event (blocks briefly for incoming connection)
receive_event :: (client: *Service_Client) -> SDK_Event {
    event := make_empty_event();

    if !client.initialized return event;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if !client.listener_active {
        return event;
    }

    #if OS == .LINUX || OS == .MACOS {
        // Accept a connection
        addr_len: u32 = size_of(sockaddr_un);
        addr: sockaddr_un;

        conn_fd := accept(client.listener_fd, cast(*sockaddr) *addr, *addr_len);
        if conn_fd < 0 {
            return event;  // No connection available
        }
        defer close(conn_fd);

        // Read the event data
        buffer: [4096] u8;
        bytes_read := read(conn_fd, buffer.data, 4095);

        if bytes_read <= 0 {
            return event;
        }

        buffer[bytes_read] = 0;
        event.raw_json = copy_string(string.{bytes_read, buffer.data});
        event.valid = true;

        // Parse event type from JSON
        if contains(event.raw_json, "notify.contextChanged") {
            event.event_type = .CONTEXT_CHANGED;
            // Parse changed_fields if present
            // (simplified parsing - in production use a proper JSON parser)
        } else if contains(event.raw_json, "notify.serviceRegistered") {
            event.event_type = .SERVICE_REGISTERED;
        } else if contains(event.raw_json, "notify.serviceUnregistered") {
            event.event_type = .SERVICE_UNREGISTERED;
        } else {
            event.event_type = .UNKNOWN;
        }

        client.stats.events_received += 1;
        client.stats.last_event_received = current_time_consensus();

        return event;
    } else {
        return event;
    }
}

// ============================================================================
// Context Operations (Convenience Wrappers)
// ============================================================================

// Get current context from the daemon
get_context :: (client: *Service_Client) -> string, bool {
    if !client.initialized return "", false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if client.state != .CONNECTED && client.state != .REGISTERED {
        return "", false;
    }

    json := tprint("{\"jsonrpc\":\"2.0\",\"method\":\"context.get\",\"id\":%}", client.next_request_id);
    client.next_request_id += 1;

    success := send_request_internal(client, json);
    if !success {
        return "", false;
    }

    response := receive_response_internal(client);
    if response.count == 0 {
        return "", false;
    }

    return response, true;
}

// Subscribe to events
subscribe_to_events :: (client: *Service_Client, events: [] string) -> bool {
    if !client.initialized return false;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    if client.state != .CONNECTED && client.state != .REGISTERED {
        return false;
    }

    if !client.listener_active {
        return false;  // Need a listener to receive events
    }

    // Build events array JSON
    events_json: String_Builder;
    init_string_builder(*events_json);
    defer free_buffers(*events_json);

    append(*events_json, "[");
    for event, idx: events {
        if idx > 0 {
            append(*events_json, ",");
        }
        print_to_builder(*events_json, "\"%\"", event);
    }
    append(*events_json, "]");

    events_str := builder_to_string(*events_json);
    defer free(events_str);

    json := tprint("{\"jsonrpc\":\"2.0\",\"method\":\"subscribe\",\"params\":{\"endpoint\":\"%\",\"events\":%},\"id\":%}",
                   client.listener_path, events_str, client.next_request_id);
    client.next_request_id += 1;

    success := send_request_internal(client, json);
    if !success {
        return false;
    }

    response := receive_response_internal(client);
    defer free(response);

    if response.count == 0 {
        return false;
    }

    return contains(response, "\"subscribed\":true") || contains(response, "\"subscribed\": true");
}

// ============================================================================
// Statistics
// ============================================================================

// Get client statistics
get_stats :: (client: *Service_Client) -> SDK_Client_Stats {
    stats: SDK_Client_Stats;

    if !client.initialized return stats;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    return client.stats;
}

// Reset statistics
reset_stats :: (client: *Service_Client) {
    if !client.initialized return;

    lock(*client.mutex);
    defer unlock(*client.mutex);

    client.stats = SDK_Client_Stats.{};
}

// ============================================================================
// Internal Helpers
// ============================================================================

// Send a request to the daemon (internal, must hold mutex)
send_request_internal :: (client: *Service_Client, json: string) -> bool {
    if client.socket_fd < 0 {
        return false;
    }

    bytes_sent := write(client.socket_fd, json.data, cast(u64) json.count);
    if bytes_sent < 0 {
        client.stats.errors += 1;
        return false;
    }

    client.stats.requests_sent += 1;
    client.stats.bytes_sent += cast(u64) bytes_sent;

    return true;
}

// Receive a response from the daemon (internal, must hold mutex)
receive_response_internal :: (client: *Service_Client) -> string {
    if client.socket_fd < 0 {
        return "";
    }

    buffer: [8192] u8;
    bytes_read := read(client.socket_fd, buffer.data, 8191);

    if bytes_read <= 0 {
        return "";
    }

    buffer[bytes_read] = 0;
    response := copy_string(string.{bytes_read, buffer.data});

    client.stats.responses_received += 1;
    client.stats.bytes_received += cast(u64) bytes_read;

    return response;
}

// Build registration JSON
build_registration_json :: (reg: *Service_Registration, request_id: u64) -> string {
    // Build events array
    events_json: String_Builder;
    init_string_builder(*events_json);
    defer free_buffers(*events_json);

    append(*events_json, "[");
    for event, idx: reg.capabilities.events {
        if idx > 0 {
            append(*events_json, ",");
        }
        print_to_builder(*events_json, "\"%\"", event);
    }
    append(*events_json, "]");

    events_str := builder_to_string(*events_json);
    defer free(events_str);

    preview_callback := ifx reg.preview_callback.count > 0 then reg.preview_callback else "";

    return tprint(#string END
{"jsonrpc":"2.0","method":"service.register","params":{"id":"%","name":"%","endpoint":"%","preview_callback":"%","capabilities":{"events":%,"provides_preview":%,"api_version":"%"}},"id":%}
END
        , reg.id, reg.name, reg.endpoint, preview_callback, events_str,
          ifx reg.capabilities.provides_preview then "true" else "false",
          reg.capabilities.api_version, request_id);
}

// Copy a service registration
copy_registration :: (src: *Service_Registration) -> Service_Registration {
    dst: Service_Registration;
    dst.id = copy_string(src.id);
    dst.name = copy_string(src.name);
    dst.endpoint = copy_string(src.endpoint);
    dst.preview_callback = copy_string(src.preview_callback);
    dst.capabilities.provides_preview = src.capabilities.provides_preview;
    dst.capabilities.api_version = copy_string(src.capabilities.api_version);
    for src.capabilities.events {
        array_add(*dst.capabilities.events, copy_string(it));
    }
    return dst;
}
