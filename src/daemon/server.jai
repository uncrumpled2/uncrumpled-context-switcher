// Uncrumpled Daemon Server
//
// This module integrates IPC, JSON-RPC, and all API handlers into a cohesive
// server that handles incoming client connections and routes requests to
// appropriate handlers.
//
// Architecture:
// 1. IPC_Server handles low-level socket/pipe connections
// 2. Incoming data is parsed as JSON-RPC messages
// 3. Requests are routed to appropriate API handlers
// 4. Responses are serialized and sent back
// 5. Events are dispatched to subscribers

#import "Basic";
#import "String";
#import "Thread";
#import "Hash_Table";

// Message framing uses newline-delimited JSON
// Each JSON-RPC message is a single line terminated by \n
MESSAGE_DELIMITER :: #char "\n";

// Maximum message size (64KB)
MAX_MESSAGE_SIZE :: 65536;

// ============================================================================
// Server State
// ============================================================================

// Daemon server state
Daemon_Server :: struct {
    // IPC layer
    ipc_server: IPC_Server;

    // State stores
    context_store: *Context_Store;
    service_registry: *Service_Registry;
    subscription_manager: *Subscription_Manager;
    session_manager: *Session_Manager;
    log_storage: *Log_Storage;

    // Event dispatch
    event_dispatcher: *Event_Dispatcher;
    heartbeat_manager: *Heartbeat_Manager;

    // Configuration
    user_config: *User_Config;

    // Message buffers per connection (for partial message handling)
    connection_buffers: Table(u32, Message_Buffer);

    // Server state
    initialized: bool;
    running: bool;

    // Statistics
    total_requests: u64;
    total_responses: u64;
    total_errors: u64;

    // Mutex for thread-safety
    mutex: Mutex;
}

// Buffer for accumulating partial messages
Message_Buffer :: struct {
    data: [MAX_MESSAGE_SIZE] u8;
    length: s64;
}

// ============================================================================
// Server Lifecycle
// ============================================================================

// Initialize the daemon server with all components
// systemd_fd: Pass >= 0 if using systemd socket activation, -1 otherwise
init_daemon_server :: (server: *Daemon_Server, socket_path: string, config: *User_Config, systemd_fd: s32 = -1) -> bool {
    if server.initialized return false;

    init(*server.mutex);

    // Initialize IPC server
    if systemd_fd >= 0 {
        // Use systemd-passed socket
        if !init_ipc_server_with_fd(*server.ipc_server, systemd_fd, socket_path) {
            destroy(*server.mutex);
            return false;
        }
    } else {
        // Create our own socket
        if !init_ipc_server(*server.ipc_server, socket_path) {
            destroy(*server.mutex);
            return false;
        }
    }

    // Initialize state stores
    server.context_store = New(Context_Store);
    init_context_store(server.context_store);

    server.service_registry = New(Service_Registry);
    init_service_registry(server.service_registry);

    server.subscription_manager = New(Subscription_Manager);
    init_subscription_manager(server.subscription_manager);

    server.session_manager = New(Session_Manager);
    init_session_manager(server.session_manager);

    server.log_storage = New(Log_Storage);
    init_log_storage(server.log_storage, 1000);  // Default max entries

    // Initialize event dispatch
    dispatcher_config: Dispatcher_Config;
    dispatcher_config.connect_timeout_ms = 5000;
    dispatcher_config.send_timeout_ms = 5000;
    dispatcher_config.retry_on_failure = true;
    dispatcher_config.max_retries = 3;

    server.event_dispatcher = New(Event_Dispatcher);
    init_event_dispatcher(server.event_dispatcher, server.subscription_manager, *dispatcher_config);

    heartbeat_config: Heartbeat_Config;
    heartbeat_config.check_interval_seconds = 30;
    heartbeat_config.subscriber_timeout_seconds = 90;
    heartbeat_config.service_timeout_seconds = 90;

    server.heartbeat_manager = New(Heartbeat_Manager);
    init_heartbeat_manager(
        server.heartbeat_manager,
        heartbeat_config,
        server.subscription_manager,
        server.service_registry,
        server.event_dispatcher
    );

    // Store configuration
    server.user_config = config;

    // Initialize connection buffers table
    init(*server.connection_buffers);

    server.initialized = true;
    server.running = false;
    server.total_requests = 0;
    server.total_responses = 0;
    server.total_errors = 0;

    return true;
}

// Destroy the daemon server and release all resources
destroy_daemon_server :: (server: *Daemon_Server) {
    if !server.initialized return;

    lock(*server.mutex);

    server.running = false;

    // Destroy IPC server
    destroy_ipc_server(*server.ipc_server);

    // Destroy state stores
    if server.context_store {
        destroy_context_store(server.context_store);
        free(server.context_store);
    }

    if server.service_registry {
        destroy_service_registry(server.service_registry);
        free(server.service_registry);
    }

    if server.subscription_manager {
        destroy_subscription_manager(server.subscription_manager);
        free(server.subscription_manager);
    }

    if server.session_manager {
        destroy_session_manager(server.session_manager);
        free(server.session_manager);
    }

    if server.log_storage {
        destroy_log_storage(server.log_storage);
        free(server.log_storage);
    }

    // Destroy event dispatch
    if server.event_dispatcher {
        destroy_event_dispatcher(server.event_dispatcher);
        free(server.event_dispatcher);
    }

    if server.heartbeat_manager {
        destroy_heartbeat_manager(server.heartbeat_manager);
        free(server.heartbeat_manager);
    }

    // Clean up connection buffers
    deinit(*server.connection_buffers);

    server.initialized = false;

    unlock(*server.mutex);
    destroy(*server.mutex);
}

// Start the server (begin listening)
start_daemon_server :: (server: *Daemon_Server) -> bool {
    if !server.initialized return false;

    if !start_server(*server.ipc_server) {
        return false;
    }

    server.running = true;
    return true;
}

// Stop the server
stop_daemon_server :: (server: *Daemon_Server) {
    if !server.initialized return;

    server.running = false;
    stop_server(*server.ipc_server);
}

// ============================================================================
// Main Server Loop
// ============================================================================

// Run a single iteration of the server loop
// Returns false if server should stop
run_server_iteration :: (server: *Daemon_Server, timeout_ms: s32) -> bool {
    if !server.initialized || !server.running return false;

    // Poll for IPC events
    activity := poll_events(*server.ipc_server, timeout_ms);
    if activity < 0 {
        // Error polling - but might just be interrupted
        return server.running;
    }

    // Accept any pending connections
    new_connections := accept_connections(*server.ipc_server);
    for i: 0..new_connections-1 {
        // Find the new connection and initialize its buffer
        for *conn: server.ipc_server.connections {
            if conn.state == .CONNECTED {
                ptr := table_find_pointer(*server.connection_buffers, conn.id);
                if !ptr {
                    buffer: Message_Buffer;
                    buffer.length = 0;
                    table_add(*server.connection_buffers, conn.id, buffer);
                }
            }
        }
    }

    // Process data from active connections
    for *conn: server.ipc_server.connections {
        if conn.state == .CONNECTED {
            process_connection_data(server, conn);
        }
    }

    // Run heartbeat check if needed
    if should_run_heartbeat_check(server.heartbeat_manager) {
        run_heartbeat_check(server.heartbeat_manager, cleanup=true);
    }

    return server.running;
}

// Process incoming data from a connection
process_connection_data :: (server: *Daemon_Server, conn: *IPC_Connection) {
    // Read available data
    read_buffer: [4096] u8;
    bytes_read := read_connection(*server.ipc_server, conn, read_buffer);

    if bytes_read <= 0 {
        if bytes_read == 0 {
            // Connection closed
            handle_connection_close(server, conn);
        }
        // bytes_read < 0 is likely EAGAIN/EWOULDBLOCK for non-blocking
        return;
    }

    // Get or create message buffer for this connection
    buffer := table_find_pointer(*server.connection_buffers, conn.id);
    if !buffer {
        new_buffer: Message_Buffer;
        new_buffer.length = 0;
        table_add(*server.connection_buffers, conn.id, new_buffer);
        buffer = table_find_pointer(*server.connection_buffers, conn.id);
    }

    // Append data to buffer
    if buffer.length + bytes_read > MAX_MESSAGE_SIZE {
        // Buffer overflow - send error and reset
        send_error_response(server, conn, null, JSONRPC_PARSE_ERROR, "Message too large");
        buffer.length = 0;
        return;
    }

    memcpy(buffer.data.data + buffer.length, read_buffer.data, bytes_read);
    buffer.length += bytes_read;

    // Process complete messages (newline-delimited)
    process_buffered_messages(server, conn, buffer);
}

// Process complete messages from buffer
process_buffered_messages :: (server: *Daemon_Server, conn: *IPC_Connection, buffer: *Message_Buffer) {
    start := 0;

    while start < buffer.length {
        // Find newline delimiter
        newline_pos := -1;
        for i: start..buffer.length-1 {
            if buffer.data[i] == MESSAGE_DELIMITER {
                newline_pos = i;
                break;
            }
        }

        if newline_pos < 0 {
            // No complete message yet - shift remaining data to start
            if start > 0 {
                remaining := buffer.length - start;
                if remaining > 0 {
                    memcpy(buffer.data.data, buffer.data.data + start, remaining);
                }
                buffer.length = remaining;
            }
            return;
        }

        // Extract complete message
        message_len := newline_pos - start;
        if message_len > 0 {
            message_str: string;
            message_str.data = buffer.data.data + start;
            message_str.count = message_len;

            // Process the JSON-RPC message
            handle_jsonrpc_message(server, conn, message_str);
        }

        start = newline_pos + 1;
    }

    // All data processed
    buffer.length = 0;
}

// ============================================================================
// JSON-RPC Message Handling
// ============================================================================

// Handle a complete JSON-RPC message
handle_jsonrpc_message :: (server: *Daemon_Server, conn: *IPC_Connection, message: string) {
    server.total_requests += 1;

    // Parse the JSON-RPC message
    parsed := parse_jsonrpc_message(message);
    defer free_jsonrpc_message(*parsed);

    if parsed.type == .INVALID {
        server.total_errors += 1;
        error_msg := ifx parsed.parse_error.count > 0 then parsed.parse_error else "Failed to parse JSON-RPC message";
        send_error_response(server, conn, null, JSONRPC_PARSE_ERROR, error_msg);
        return;
    }

    // Handle based on message type
    if parsed.type == {
        case .BATCH;
            handle_batch_request(server, conn, *parsed);
        case .REQUEST;
            handle_request(server, conn, *parsed.request);
        case .NOTIFICATION;
            handle_notification(server, conn, *parsed.request);
        case;
            // Response or error_response - we're a server, shouldn't receive these
            server.total_errors += 1;
            send_error_response(server, conn, null, JSONRPC_INVALID_REQUEST, "Server received a response message");
    }
}

// Handle a single JSON-RPC request
handle_request :: (server: *Daemon_Server, conn: *IPC_Connection, request: *JSONRPC_Request) {
    response_json := route_request(server, request);
    defer free(response_json);

    send_raw(server, conn, response_json);
    server.total_responses += 1;
}

// Handle a notification (no response)
handle_notification :: (server: *Daemon_Server, conn: *IPC_Connection, request: *JSONRPC_Request) {
    // Process but don't send response
    response_json := route_request(server, request);
    free(response_json);
}

// Handle a batch request
handle_batch_request :: (server: *Daemon_Server, conn: *IPC_Connection, parsed: *JSONRPC_Message) {
    responses: [..] string;

    for i: 0..parsed.batch.count-1 {
        batch_msg := *parsed.batch[i];
        if batch_msg.type == .REQUEST {
            response_json := route_request(server, *batch_msg.request);
            array_add(*responses, response_json);
            server.total_responses += 1;
        } else if batch_msg.type == .NOTIFICATION {
            // Notification in batch - process but no response
            response_json := route_request(server, *batch_msg.request);
            free(response_json);
        }
        // Skip responses/errors in batch (shouldn't happen, but ignore if they do)
    }

    // Send batch response
    if responses.count > 0 {
        batch_json := build_batch_response(responses);
        send_raw(server, conn, batch_json);
        free(batch_json);
    }

    for str: responses free(str);
    array_free(responses);
}

// Route a request to the appropriate handler
// Returns the response as a JSON string (caller must free)
route_request :: (server: *Daemon_Server, request: *JSONRPC_Request) -> string {
    method := request.method;

    // Route to appropriate API handler
    if is_context_method(method) {
        api_result := route_context_method(server.context_store, request);
        return api_result.response;
    }

    if is_service_method(method) {
        api_result := route_service_method(server.service_registry, request);
        return api_result.response;
    }

    if is_subscription_method(method) {
        api_result := route_subscription_method(server.subscription_manager, request);
        return api_result.response;
    }

    if is_handshake_method(method) {
        api_result := route_handshake_method(server.session_manager, request);
        return api_result.response;
    }

    if is_preview_method(method) {
        preview_manager: Preview_Manager;
        init_preview_manager(*preview_manager, server.service_registry, server.context_store);
        defer destroy_preview_manager(*preview_manager);
        api_result := route_preview_method(*preview_manager, request);
        return api_result.response;
    }

    if is_logs_method(method) {
        api_result := route_logs_method(server.log_storage, request);
        return api_result.response;
    }

    // Method not found
    return create_error_response(request.id, JSONRPC_METHOD_NOT_FOUND, tprint("Method not found: %", method));
}

// ============================================================================
// Response Sending
// ============================================================================

// Send an error response directly
send_error_response :: (server: *Daemon_Server, conn: *IPC_Connection, id: *Request_ID, code: s32, message: string) {
    response_json: string;
    if id {
        response_json = create_error_response(<<id, code, message);
    } else {
        null_id: Request_ID;
        null_id.is_null = true;
        response_json = create_error_response(null_id, code, message);
    }
    defer free(response_json);

    send_raw(server, conn, response_json);
    server.total_errors += 1;
}

// Send raw data (with newline delimiter)
send_raw :: (server: *Daemon_Server, conn: *IPC_Connection, data: string) {
    // Add newline delimiter
    with_newline := tprint("%\n", data);
    write_connection(*server.ipc_server, conn, cast([] u8) with_newline);
}

// Build a batch response JSON array
build_batch_response :: (responses: [] string) -> string {
    builder: String_Builder;

    append(*builder, "[");
    for resp, idx: responses {
        if idx > 0 append(*builder, ",");
        append(*builder, resp);
    }
    append(*builder, "]");

    return builder_to_string(*builder);
}

// ============================================================================
// Connection Lifecycle
// ============================================================================

// Handle connection close
handle_connection_close :: (server: *Daemon_Server, conn: *IPC_Connection) {
    // Remove connection buffer
    table_remove(*server.connection_buffers, conn.id);

    // Remove any session associated with this connection
    // (Session manager tracks by endpoint, need to find matching session)

    // Close the connection
    close_connection(*server.ipc_server, conn);
}


// ============================================================================
// Statistics
// ============================================================================

// Get server statistics
get_server_stats :: (server: *Daemon_Server) -> Server_Stats {
    stats: Server_Stats;
    stats.total_requests = server.total_requests;
    stats.total_responses = server.total_responses;
    stats.total_errors = server.total_errors;
    stats.active_connections = server.ipc_server.connection_count;
    stats.total_connections = server.ipc_server.total_connections;
    stats.bytes_received = server.ipc_server.total_bytes_received;
    stats.bytes_sent = server.ipc_server.total_bytes_sent;
    return stats;
}

// Server statistics
Server_Stats :: struct {
    total_requests: u64;
    total_responses: u64;
    total_errors: u64;
    active_connections: s32;
    total_connections: u64;
    bytes_received: u64;
    bytes_sent: u64;
}

// Convert server stats to JSON
server_stats_to_json :: (stats: *Server_Stats) -> string {
    return tprint(
        #string END
{"total_requests":%,"total_responses":%,"total_errors":%,"active_connections":%,"total_connections":%,"bytes_received":%,"bytes_sent":%}
END
        ,
        stats.total_requests,
        stats.total_responses,
        stats.total_errors,
        stats.active_connections,
        stats.total_connections,
        stats.bytes_received,
        stats.bytes_sent
    );
}
