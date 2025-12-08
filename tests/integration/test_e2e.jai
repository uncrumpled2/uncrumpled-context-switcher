// End-to-End Integration Tests
//
// These tests verify the complete daemon functionality by:
// 1. Starting a Daemon_Server instance
// 2. Connecting clients via IPC
// 3. Sending JSON-RPC requests
// 4. Verifying responses and state changes
//
// These tests use the full server infrastructure (server.jai) to ensure
// all components work together correctly.

#import "Basic";
#import "String";
#import "File";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
#import "Thread";
#import "Hash_Table";
#import "Random";

// Note: Most daemon modules are already loaded by previous unit test files:
// - context_store.jai loaded by test_context_store.jai
// - ipc.jai loaded by test_ipc.jai
// - rpc/module.jai loaded by test_jsonrpc.jai
// - api/module.jai loaded by test_context_api.jai
// - config/module.jai loaded by test_config_parser.jai
// - config/validator.jai loaded by test_config_validator.jai
// - events/module.jai loaded by test_event_dispatcher.jai and test_heartbeat.jai
//
// We only need to load server.jai which ties everything together
#load "../../src/daemon/server.jai";

// ============================================================================
// Test Infrastructure
// ============================================================================

// Test client for e2e tests - simulates CLI client behavior
E2E_Test_Client :: struct {
    #if OS == .WINDOWS {
        e2e_pipe_handle: HANDLE;  // Windows named pipe handle
    } else {
        e2e_socket: s32;  // Renamed to avoid conflicts with POSIX socket function
    }
    connected: bool;
    recv_buffer: [65536] u8;
}

#if OS == .WINDOWS {
    // Use Windows module for types
    #import "Windows";

    // Windows API imports for E2E tests (not in standard Windows module)
    kernel32_e2e :: #system_library "kernel32";
    WaitNamedPipeA_E2E :: (lpNamedPipeName: LPCSTR, nTimeOut: DWORD) -> BOOL #foreign kernel32_e2e "WaitNamedPipeA";
    PeekNamedPipe_E2E :: (hNamedPipe: HANDLE, lpBuffer: *void, nBufferSize: DWORD, lpBytesRead: *DWORD, lpTotalBytesAvail: *DWORD, lpBytesLeftThisMessage: *DWORD) -> BOOL #foreign kernel32_e2e "PeekNamedPipe";

    // Pipe mode constant (may not be in Windows module)
    E2E_PIPE_READMODE_BYTE :: 0x00000000;
}

init_e2e_client :: (client: *E2E_Test_Client) {
    #if OS == .WINDOWS {
        client.e2e_pipe_handle = INVALID_HANDLE_VALUE;
    } else {
        client.e2e_socket = -1;
    }
    client.connected = false;
}

connect_e2e_client :: (client: *E2E_Test_Client, socket_path: string) -> bool {
    #if OS == .WINDOWS {
        // Convert path to C string
        path_cstr := alloc(socket_path.count + 1);
        memcpy(path_cstr, socket_path.data, socket_path.count);
        (cast(*u8)path_cstr)[socket_path.count] = 0;
        defer free(path_cstr);

        // Wait for pipe to be available
        if !WaitNamedPipeA_E2E(path_cstr, 5000) {
            return false;
        }

        // Open the pipe using Windows module CreateFileA
        client.e2e_pipe_handle = CreateFileA(
            path_cstr,
            GENERIC_READ | GENERIC_WRITE,
            0,      // No sharing
            null,   // Default security
            OPEN_EXISTING,
            0,      // Default attributes
            null    // No template
        );

        if client.e2e_pipe_handle == INVALID_HANDLE_VALUE {
            return false;
        }

        // Set pipe mode to byte mode
        mode: DWORD = E2E_PIPE_READMODE_BYTE;
        SetNamedPipeHandleState(client.e2e_pipe_handle, *mode, null, null);

        client.connected = true;
        return true;
    } else #if OS == .LINUX || OS == .MACOS {
        // Create socket using IPC module functions to avoid conflicts with POSIX
        client.e2e_socket = ipc_socket(IPC_AF_UNIX, IPC_SOCK_STREAM, 0);
        if client.e2e_socket < 0 {
            return false;
        }

        // Setup address using IPC types
        addr: IPC_sockaddr_un;
        addr.sun_family = IPC_AF_UNIX;
        path_bytes := cast([] u8) socket_path;
        max_len := 107;
        copy_len := ipc_min(path_bytes.count, max_len);
        for i: 0..copy_len-1 {
            addr.sun_path[i] = path_bytes[i];
        }
        addr.sun_path[copy_len] = 0;

        // Connect using IPC module connect
        result := ipc_connect(client.e2e_socket, *addr, size_of(IPC_sockaddr_un));
        if result < 0 {
            close(client.e2e_socket);
            client.e2e_socket = -1;
            return false;
        }

        client.connected = true;
        return true;
    } else {
        return false;
    }
}

disconnect_e2e_client :: (client: *E2E_Test_Client) {
    #if OS == .WINDOWS {
        if client.e2e_pipe_handle != INVALID_HANDLE_VALUE {
            CloseHandle(client.e2e_pipe_handle);
            client.e2e_pipe_handle = INVALID_HANDLE_VALUE;
        }
    } else #if OS == .LINUX || OS == .MACOS {
        if client.e2e_socket >= 0 {
            close(client.e2e_socket);
            client.e2e_socket = -1;
        }
    }
    client.connected = false;
}

// Send a JSON-RPC request and receive response
// This function takes a server pointer to run iterations between send and receive
e2e_send_request :: (client: *E2E_Test_Client, method: string, params := "", server: *Daemon_Server = null) -> string, bool {
    if !client.connected return "", false;

    // Build JSON-RPC request
    request: string;
    if params.count > 0 {
        request = tprint("{\"jsonrpc\":\"2.0\",\"method\":\"%\",\"params\":%,\"id\":1}\n", method, params);
    } else {
        request = tprint("{\"jsonrpc\":\"2.0\",\"method\":\"%\",\"id\":1}\n", method);
    }

    #if OS == .WINDOWS {
        // Send request via named pipe
        bytes_written: DWORD = 0;
        success := WriteFile(client.e2e_pipe_handle, request.data, cast(DWORD) request.count, *bytes_written, null);
        if !success || bytes_written == 0 {
            return "", false;
        }

        // Run server iterations to process the request
        if server {
            run_server_iteration(server, 50);
            run_server_iteration(server, 50);
        } else {
            sleep_ms(50);
        }

        // Try to receive response with retries using PeekNamedPipe
        bytes_read: DWORD = 0;
        for retry: 0..9 {  // Up to 10 retries
            // Check if data is available
            bytes_available: DWORD = 0;
            if PeekNamedPipe_E2E(client.e2e_pipe_handle, null, 0, null, *bytes_available, null) {
                if bytes_available > 0 {
                    // Read the available data
                    if ReadFile(client.e2e_pipe_handle, client.recv_buffer.data, 65535, *bytes_read, null) {
                        if bytes_read > 0 break;
                    }
                }
            }

            // Run more server iterations if available
            if server {
                run_server_iteration(server, 20);
            }
            sleep_ms(10);
        }

        if bytes_read == 0 {
            return "", false;
        }

        // Return response (strip trailing newline)
        response_str: string;
        response_str.data = client.recv_buffer.data;
        response_str.count = cast(s64) bytes_read;

        // Trim trailing newlines
        while response_str.count > 0 && (response_str[response_str.count-1] == #char "\n" || response_str[response_str.count-1] == #char "\r") {
            response_str.count -= 1;
        }

        return copy_string(response_str), true;

    } else #if OS == .LINUX || OS == .MACOS {
        // Send request
        bytes_sent := write(client.e2e_socket, request.data, cast(u64) request.count);
        if bytes_sent < 0 {
            return "", false;
        }

        // Run server iterations to process the request
        if server {
            run_server_iteration(server, 50);
            run_server_iteration(server, 50);
        } else {
            // Fallback: sleep and hope server is running in another thread
            sleep_ms(50);
        }

        // Set socket to non-blocking for read
        flags := fcntl(client.e2e_socket, F_GETFL, 0);
        fcntl(client.e2e_socket, F_SETFL, flags | O_NONBLOCK);

        // Try to receive response with retries
        bytes_received: s64 = -1;
        for retry: 0..9 {  // Up to 10 retries
            bytes_received = read(client.e2e_socket, client.recv_buffer.data, 65535);
            if bytes_received > 0 break;

            // Run more server iterations if available
            if server {
                run_server_iteration(server, 20);
            }
            sleep_ms(10);
        }

        // Restore blocking mode
        fcntl(client.e2e_socket, F_SETFL, flags);

        if bytes_received <= 0 {
            return "", false;
        }

        // Return response (strip trailing newline)
        response_str: string;
        response_str.data = client.recv_buffer.data;
        response_str.count = bytes_received;

        // Trim trailing newlines
        while response_str.count > 0 && (response_str[response_str.count-1] == #char "\n" || response_str[response_str.count-1] == #char "\r") {
            response_str.count -= 1;
        }

        return copy_string(response_str), true;
    } else {
        return "", false;
    }
}

// Helper to extract JSON field value (simple parser for test assertions)
extract_json_field :: (json: string, field: string) -> string, bool {
    // Look for "field":"value" or "field":value
    search := tprint("\"%\":", field);
    idx := find_index_from_left(json, search);
    if idx < 0 return "", false;

    value_start := idx + search.count;
    if value_start >= json.count return "", false;

    // Skip whitespace
    while value_start < json.count && (json[value_start] == #char " " || json[value_start] == #char "\t") {
        value_start += 1;
    }

    if value_start >= json.count return "", false;

    // Determine value type
    if json[value_start] == #char "\"" {
        // String value
        value_start += 1;
        value_end := value_start;
        while value_end < json.count && json[value_end] != #char "\"" {
            // Handle escaped quotes
            if json[value_end] == #char "\\" && value_end + 1 < json.count {
                value_end += 2;
            } else {
                value_end += 1;
            }
        }
        result: string;
        result.data = json.data + value_start;
        result.count = value_end - value_start;
        return result, true;
    } else if json[value_start] == #char "{" || json[value_start] == #char "[" {
        // Object or array - find matching bracket
        open_char := json[value_start];
        close_char: u8 = ifx open_char == #char "{" then cast(u8) #char "}" else cast(u8) #char "]";
        depth := 1;
        value_end := value_start + 1;
        while value_end < json.count && depth > 0 {
            c := json[value_end];
            if c == open_char {
                depth += 1;
            } else if c == close_char {
                depth -= 1;
            }
            value_end += 1;
        }
        result: string;
        result.data = json.data + value_start;
        result.count = value_end - value_start;
        return result, true;
    } else {
        // Number, boolean, or null
        value_end := value_start;
        while value_end < json.count && json[value_end] != #char "," && json[value_end] != #char "}" && json[value_end] != #char "]" && json[value_end] != #char "\n" {
            value_end += 1;
        }
        result: string;
        result.data = json.data + value_start;
        result.count = value_end - value_start;
        return result, true;
    }
}

// Check if JSON contains an error field
json_has_error :: (json: string) -> bool {
    return find_index_from_left(json, "\"error\"") >= 0;
}

// Check if JSON response was successful (has result, no error)
json_is_success :: (json: string) -> bool {
    has_result := find_index_from_left(json, "\"result\"") >= 0;
    has_error := find_index_from_left(json, "\"error\"") >= 0;
    return has_result && !has_error;
}

// Generate unique socket path for test isolation
generate_test_socket_path :: () -> string {
    timestamp := cast(s64)(seconds_since_init() * 1000000);
    rand := random_get() % 10000;
    #if OS == .WINDOWS {
        return tprint("\\\\.\\pipe\\uncrumpled_e2e_test_%_%", timestamp, rand);
    } else {
        return tprint("/tmp/uncrumpled_e2e_test_%_%.sock", timestamp, rand);
    }
}

// Cleanup test socket file
cleanup_test_socket :: (path: string) {
    // On Windows, named pipes are automatically cleaned up when handles are closed
    // On Unix, we need to delete the socket file
    #if OS != .WINDOWS {
        #import "File";
        file_delete(path);
    }
}

// ============================================================================
// Test: Server Lifecycle
// ============================================================================

test_e2e_server_init_destroy :: () -> bool {
    state := init_test_state("test_e2e_server_init_destroy", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        // Create default config
        config := create_default_config();
        defer free_user_config(*config);

        // Initialize server
        server: Daemon_Server;
        success := init_daemon_server(*server, socket_path, *config);
        assert_true(success, "server should initialize successfully");
        assert_true(server.initialized, "server should be marked as initialized");
        assert_false(server.running, "server should not be running yet");

        // Verify components are initialized
        assert_not_null(server.context_store, "context_store should be initialized");
        assert_not_null(server.service_registry, "service_registry should be initialized");
        assert_not_null(server.subscription_manager, "subscription_manager should be initialized");
        assert_not_null(server.session_manager, "session_manager should be initialized");
        assert_not_null(server.log_storage, "log_storage should be initialized");
        assert_not_null(server.event_dispatcher, "event_dispatcher should be initialized");
        assert_not_null(server.heartbeat_manager, "heartbeat_manager should be initialized");

        // Destroy server
        destroy_daemon_server(*server);
        assert_false(server.initialized, "server should be marked as not initialized after destroy");
    }

    return all_tests_passed(state);
}

test_e2e_server_start_stop :: () -> bool {
    state := init_test_state("test_e2e_server_start_stop", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        success := init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        assert_true(success, "server should initialize");

        // Start server
        started := start_daemon_server(*server);
        assert_true(started, "server should start successfully");
        assert_true(server.running, "server should be marked as running");

        // Stop server
        stop_daemon_server(*server);
        assert_false(server.running, "server should be marked as not running after stop");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Client Connection
// ============================================================================

test_e2e_client_connect :: () -> bool {
    state := init_test_state("test_e2e_client_connect", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);

        // Run one iteration to ensure server is listening
        run_server_iteration(*server, 10);

        // Connect client
        client: E2E_Test_Client;
        init_e2e_client(*client);
        connected := connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);

        assert_true(connected, "client should connect successfully");
        assert_true(client.connected, "client should be marked as connected");

        // Accept the connection on server side
        run_server_iteration(*server, 10);
        assert_equal(server.ipc_server.connection_count, 1, "server should have one connection");
    }

    return all_tests_passed(state);
}

test_e2e_multiple_clients :: () -> bool {
    state := init_test_state("test_e2e_multiple_clients", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // On Windows, named pipes can only handle one client at a time with our current
        // implementation (no overlapped I/O). Skip this test on Windows.
        #if OS == .WINDOWS {
            // Just pass - multiple clients require overlapped I/O on Windows
            return true;
        } else {
            socket_path := generate_test_socket_path();
            defer cleanup_test_socket(socket_path);

            config := create_default_config();
            defer free_user_config(*config);

            server: Daemon_Server;
            init_daemon_server(*server, socket_path, *config);
            defer destroy_daemon_server(*server);
            start_daemon_server(*server);
            run_server_iteration(*server, 10);

            // Connect multiple clients
            client1: E2E_Test_Client;
            client2: E2E_Test_Client;
            client3: E2E_Test_Client;
            init_e2e_client(*client1);
            init_e2e_client(*client2);
            init_e2e_client(*client3);

            assert_true(connect_e2e_client(*client1, socket_path), "client1 should connect");
            defer disconnect_e2e_client(*client1);

            assert_true(connect_e2e_client(*client2, socket_path), "client2 should connect");
            defer disconnect_e2e_client(*client2);

            assert_true(connect_e2e_client(*client3, socket_path), "client3 should connect");
            defer disconnect_e2e_client(*client3);

            // Accept connections
            run_server_iteration(*server, 10);
            run_server_iteration(*server, 10);
            run_server_iteration(*server, 10);

            assert_equal(server.ipc_server.connection_count, 3, "server should have three connections");
        }
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Context API E2E
// ============================================================================

test_e2e_context_get :: () -> bool {
    state := init_test_state("test_e2e_context_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        server_init_ok := init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        assert_true(server_init_ok, "server should initialize");
        if !server_init_ok return false;

        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        client_connect_ok := connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        assert_true(client_connect_ok, "client should connect");
        if !client_connect_ok return false;

        run_server_iteration(*server, 10);

        // Send context.get request (pass server to handle processing)
        response, ok := e2e_send_request(*client, "context.get", "", *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive response");
        assert_true(response.count > 0, "response should not be empty");
        assert_true(json_is_success(response), "response should be success");
        assert_true(find_index_from_left(response, "project_id") >= 0, "response should contain project_id");
        assert_true(find_index_from_left(response, "version") >= 0, "response should contain version");
    }

    return all_tests_passed(state);
}

test_e2e_context_add_remove_tag :: () -> bool {
    state := init_test_state("test_e2e_context_add_remove_tag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Add tag
        response1, ok1 := e2e_send_request(*client, "context.addTag", "{\"tag\":\"--work\"}", *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive addTag response");
        assert_true(json_is_success(response1), "addTag should succeed");

        // Verify tag was added by getting context
        response2, ok2 := e2e_send_request(*client, "context.get", "", *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive get response");
        assert_true(find_index_from_left(response2, "--work") >= 0, "context should contain --work tag");

        // Remove tag
        response3, ok3 := e2e_send_request(*client, "context.removeTag", "{\"tag\":\"--work\"}", *server);
        defer if response3.count > 0 free(response3);

        assert_true(ok3, "should receive removeTag response");
        assert_true(json_is_success(response3), "removeTag should succeed");

        // Verify tag was removed
        response4, ok4 := e2e_send_request(*client, "context.get", "", *server);
        defer if response4.count > 0 free(response4);

        assert_true(ok4, "should receive final get response");
        // The tag should be gone, so tags should be empty or not contain --work
        // Note: Finding --work in a response that has tags: [] is OK, so check more carefully
        tags_field, found := extract_json_field(response4, "tags");
        assert_true(found, "should find tags field");
        assert_equal(tags_field, "[]", "tags should be empty after removal");
    }

    return all_tests_passed(state);
}

test_e2e_context_set_param :: () -> bool {
    state := init_test_state("test_e2e_context_set_param", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Set parameter
        response1, ok1 := e2e_send_request(*client, "context.setParam", "{\"key\":\"mode\",\"value\":\"debug\"}", *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive setParam response");
        assert_true(json_is_success(response1), "setParam should succeed");

        // Get parameter
        response2, ok2 := e2e_send_request(*client, "context.getParam", "{\"key\":\"mode\"}", *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive getParam response");
        assert_true(json_is_success(response2), "getParam should succeed");
        assert_true(find_index_from_left(response2, "debug") >= 0, "response should contain param value 'debug'");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Service API E2E
// ============================================================================

test_e2e_service_register_list :: () -> bool {
    state := init_test_state("test_e2e_service_register_list", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Register a service (use tprint to avoid trailing newline from heredoc)
        register_params := "{\"id\":\"test-service\",\"name\":\"Test Service\",\"endpoint\":\"/tmp/test.sock\",\"capabilities\":{\"events\":[\"context.changed\"],\"provides_preview\":false,\"api_version\":\"1.0.0\"}}";
        response1, ok1 := e2e_send_request(*client, "service.register", register_params, *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive register response");
        assert_true(json_is_success(response1), "register should succeed");

        // List services
        response2, ok2 := e2e_send_request(*client, "service.list", "", *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive list response");
        assert_true(json_is_success(response2), "list should succeed");
        assert_true(find_index_from_left(response2, "test-service") >= 0, "list should contain test-service");
        assert_true(find_index_from_left(response2, "Test Service") >= 0, "list should contain service name");

        // Unregister
        response3, ok3 := e2e_send_request(*client, "service.unregister", "{\"id\":\"test-service\"}", *server);
        defer if response3.count > 0 free(response3);

        assert_true(ok3, "should receive unregister response");
        assert_true(json_is_success(response3), "unregister should succeed");

        // Verify unregistered
        response4, ok4 := e2e_send_request(*client, "service.list", "", *server);
        defer if response4.count > 0 free(response4);

        assert_true(ok4, "should receive final list response");
        count_field, found := extract_json_field(response4, "count");
        assert_true(found, "should find count field");
        assert_equal(count_field, "0", "count should be 0 after unregister");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Subscription API E2E
// ============================================================================

test_e2e_subscribe_unsubscribe :: () -> bool {
    state := init_test_state("test_e2e_subscribe_unsubscribe", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Subscribe
        sub_params := "{\"events\":[\"context.changed\"],\"endpoint\":\"/tmp/test-subscriber.sock\"}";
        response1, ok1 := e2e_send_request(*client, "subscribe", sub_params, *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive subscribe response");
        assert_true(json_is_success(response1), "subscribe should succeed");

        // Verify subscriber was added
        sub_count := get_subscriber_count(server.subscription_manager);
        assert_equal(sub_count, 1, "should have one subscriber");

        // Unsubscribe
        unsub_params := "{\"endpoint\":\"/tmp/test-subscriber.sock\"}";
        response2, ok2 := e2e_send_request(*client, "unsubscribe", unsub_params, *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive unsubscribe response");
        assert_true(json_is_success(response2), "unsubscribe should succeed");

        // Verify subscriber was removed
        sub_count2 := get_subscriber_count(server.subscription_manager);
        assert_equal(sub_count2, 0, "should have no subscribers");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Handshake E2E
// ============================================================================

test_e2e_handshake :: () -> bool {
    state := init_test_state("test_e2e_handshake", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Perform handshake
        handshake_params := "{\"client_version\":\"1.0.0\",\"capabilities\":[\"context\",\"subscribe\"]}";
        response, ok := e2e_send_request(*client, "handshake", handshake_params, *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive handshake response");
        assert_true(json_is_success(response), "handshake should succeed");
        assert_true(find_index_from_left(response, "protocol_version") >= 0, "response should contain protocol_version");
        assert_true(find_index_from_left(response, "session_id") >= 0, "response should contain session_id");
        assert_true(find_index_from_left(response, "capabilities") >= 0, "response should contain capabilities");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Logs API E2E
// ============================================================================

test_e2e_logs_list :: () -> bool {
    state := init_test_state("test_e2e_logs_list", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // List logs (should be empty initially)
        response, ok := e2e_send_request(*client, "logs.list", "{\"limit\":10}", *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive logs.list response");
        assert_true(json_is_success(response), "logs.list should succeed");
        assert_true(find_index_from_left(response, "logs") >= 0, "response should contain logs field");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Preview API E2E
// ============================================================================

test_e2e_preview_get :: () -> bool {
    state := init_test_state("test_e2e_preview_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Get preview for a proposed context change
        preview_params := "{\"proposed_context\":{\"project_id\":\"new-project\",\"profile\":\"work\",\"environment\":\"prod\",\"tags\":[\"--work\"]}}";
        response, ok := e2e_send_request(*client, "preview.get", preview_params, *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive preview.get response");
        assert_true(json_is_success(response), "preview.get should succeed");
        assert_true(find_index_from_left(response, "changed_fields") >= 0, "response should contain changed_fields");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Context Registry API E2E (Multi-Context Support)
// ============================================================================

test_e2e_context_list_empty :: () -> bool {
    state := init_test_state("test_e2e_context_list_empty", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // List contexts (should be empty initially)
        response, ok := e2e_send_request(*client, "context.list", "", *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive context.list response");
        assert_true(json_is_success(response), "context.list should succeed");
        assert_true(find_index_from_left(response, "contexts") >= 0, "response should contain contexts field");
        assert_true(find_index_from_left(response, "history") >= 0, "response should contain history field");

        // Verify contexts is empty
        contexts_field, found := extract_json_field(response, "contexts");
        assert_true(found, "should find contexts field");
        assert_equal(contexts_field, "[]", "contexts should be empty initially");
    }

    return all_tests_passed(state);
}

test_e2e_context_create :: () -> bool {
    state := init_test_state("test_e2e_context_create", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create a context definition
        create_params := "{\"name\":\"work\",\"description\":\"Work context\"}";
        response1, ok1 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive context.create response");
        assert_true(json_is_success(response1), "context.create should succeed");
        // Check for success field - may have space after colon
        success_field, found_success := extract_json_field(response1, "success");
        assert_true(found_success, "response should have success field");
        assert_equal(success_field, "true", "response should indicate success");

        // Verify context was created by listing
        response2, ok2 := e2e_send_request(*client, "context.list", "", *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive context.list response");
        assert_true(json_is_success(response2), "context.list should succeed");
        assert_true(find_index_from_left(response2, "work") >= 0, "response should contain created context name");
    }

    return all_tests_passed(state);
}

test_e2e_context_create_duplicate :: () -> bool {
    state := init_test_state("test_e2e_context_create_duplicate", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create a context definition
        create_params := "{\"name\":\"work\"}";
        response1, ok1 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response1.count > 0 free(response1);
        assert_true(ok1, "first create should succeed");
        assert_true(json_is_success(response1), "first create should succeed");

        // Try to create duplicate
        response2, ok2 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive response for duplicate create");
        assert_true(json_has_error(response2), "duplicate create should fail with error");
        assert_true(find_index_from_left(response2, "already exists") >= 0, "error should mention already exists");
    }

    return all_tests_passed(state);
}

test_e2e_context_switch :: () -> bool {
    state := init_test_state("test_e2e_context_switch", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create a context first
        create_params := "{\"name\":\"work\"}";
        response1, ok1 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response1.count > 0 free(response1);
        assert_true(ok1, "create should work");

        // Switch to the context
        switch_params := "{\"input\":\"work\"}";
        response2, ok2 := e2e_send_request(*client, "context.switch", switch_params, *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive context.switch response");
        assert_true(json_is_success(response2), "context.switch should succeed");
        // Check for success field - may have space after colon
        success_field2, found_success2 := extract_json_field(response2, "success");
        assert_true(found_success2, "response should have success field");
        assert_equal(success_field2, "true", "response should indicate success");
        assert_true(find_index_from_left(response2, "work") >= 0, "response should contain context name");

        // Verify active context in list
        response3, ok3 := e2e_send_request(*client, "context.list", "", *server);
        defer if response3.count > 0 free(response3);

        assert_true(ok3, "should receive context.list response");
        assert_true(find_index_from_left(response3, "active") >= 0, "response should contain active field");
        assert_true(find_index_from_left(response3, "work") >= 0, "active context should be work");
    }

    return all_tests_passed(state);
}

test_e2e_context_switch_auto_create :: () -> bool {
    state := init_test_state("test_e2e_context_switch_auto_create", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Switch to a context that doesn't exist (server has auto_create=true)
        switch_params := "{\"input\":\"newcontext\"}";
        response1, ok1 := e2e_send_request(*client, "context.switch", switch_params, *server);
        defer if response1.count > 0 free(response1);

        assert_true(ok1, "should receive context.switch response");
        assert_true(json_is_success(response1), "context.switch with auto_create should succeed");

        // Verify context was auto-created
        response2, ok2 := e2e_send_request(*client, "context.list", "", *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive context.list response");
        assert_true(find_index_from_left(response2, "newcontext") >= 0, "should contain auto-created context");
    }

    return all_tests_passed(state);
}

test_e2e_context_switch_with_args :: () -> bool {
    state := init_test_state("test_e2e_context_switch_with_args", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create a context first
        create_params := "{\"name\":\"work\"}";
        response1, ok1 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response1.count > 0 free(response1);
        assert_true(ok1, "create should work");

        // Switch with arguments
        switch_params := "{\"input\":\"work --mode=programming\"}";
        response2, ok2 := e2e_send_request(*client, "context.switch", switch_params, *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive context.switch response");
        assert_true(json_is_success(response2), "context.switch with args should succeed");
        assert_true(find_index_from_left(response2, "work --mode=programming") >= 0, "response should contain input");
    }

    return all_tests_passed(state);
}

test_e2e_context_history :: () -> bool {
    state := init_test_state("test_e2e_context_history", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create and switch to contexts to build history
        create_work := "{\"name\":\"work\"}";
        create_personal := "{\"name\":\"personal\"}";
        response1, _ := e2e_send_request(*client, "context.create", create_work, *server);
        defer if response1.count > 0 free(response1);
        response2, _ := e2e_send_request(*client, "context.create", create_personal, *server);
        defer if response2.count > 0 free(response2);

        // Switch contexts to build history
        switch1, _ := e2e_send_request(*client, "context.switch", "{\"input\":\"work\"}", *server);
        defer if switch1.count > 0 free(switch1);
        switch2, _ := e2e_send_request(*client, "context.switch", "{\"input\":\"personal\"}", *server);
        defer if switch2.count > 0 free(switch2);
        switch3, _ := e2e_send_request(*client, "context.switch", "{\"input\":\"work --mode=programming\"}", *server);
        defer if switch3.count > 0 free(switch3);

        // Get history from list
        response3, ok3 := e2e_send_request(*client, "context.list", "", *server);
        defer if response3.count > 0 free(response3);

        assert_true(ok3, "should receive context.list response");
        assert_true(json_is_success(response3), "context.list should succeed");

        // Verify history contains entries
        assert_true(find_index_from_left(response3, "\"history\"") >= 0, "response should contain history");
        // Most recent should be first
        assert_true(find_index_from_left(response3, "work --mode=programming") >= 0, "history should contain most recent switch");
    }

    return all_tests_passed(state);
}

test_e2e_context_delete :: () -> bool {
    state := init_test_state("test_e2e_context_delete", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Create a context
        create_params := "{\"name\":\"work\"}";
        response1, ok1 := e2e_send_request(*client, "context.create", create_params, *server);
        defer if response1.count > 0 free(response1);
        assert_true(ok1, "create should work");

        // Delete the context
        delete_params := "{\"name\":\"work\"}";
        response2, ok2 := e2e_send_request(*client, "context.delete", delete_params, *server);
        defer if response2.count > 0 free(response2);

        assert_true(ok2, "should receive context.delete response");
        assert_true(json_is_success(response2), "context.delete should succeed");
        // Check for success field - may have space after colon
        success_field_del, found_success_del := extract_json_field(response2, "success");
        assert_true(found_success_del, "response should have success field");
        assert_equal(success_field_del, "true", "response should indicate success");

        // Verify context was deleted
        response3, ok3 := e2e_send_request(*client, "context.list", "", *server);
        defer if response3.count > 0 free(response3);

        assert_true(ok3, "should receive context.list response");
        contexts_field, found := extract_json_field(response3, "contexts");
        assert_true(found, "should find contexts field");
        assert_equal(contexts_field, "[]", "contexts should be empty after delete");
    }

    return all_tests_passed(state);
}

test_e2e_context_delete_nonexistent :: () -> bool {
    state := init_test_state("test_e2e_context_delete_nonexistent", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Try to delete nonexistent context
        delete_params := "{\"name\":\"nonexistent\"}";
        response, ok := e2e_send_request(*client, "context.delete", delete_params, *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive response");
        assert_true(json_has_error(response), "delete nonexistent should fail");
        assert_true(find_index_from_left(response, "not found") >= 0, "error should mention not found");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Error Handling E2E
// ============================================================================

test_e2e_invalid_method :: () -> bool {
    state := init_test_state("test_e2e_invalid_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Call non-existent method
        response, ok := e2e_send_request(*client, "nonexistent.method", "", *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive response even for invalid method");
        assert_true(json_has_error(response), "response should be an error");
        assert_true(find_index_from_left(response, "-32601") >= 0, "error code should be -32601 (Method not found)");
    }

    return all_tests_passed(state);
}

test_e2e_invalid_params :: () -> bool {
    state := init_test_state("test_e2e_invalid_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Call addTag without tag parameter
        response, ok := e2e_send_request(*client, "context.addTag", "{}", *server);
        defer if response.count > 0 free(response);

        assert_true(ok, "should receive response");
        assert_true(json_has_error(response), "response should be an error for missing params");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Statistics E2E
// ============================================================================

test_e2e_server_stats :: () -> bool {
    state := init_test_state("test_e2e_server_stats", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Initial stats
        stats_before := get_server_stats(*server);
        assert_equal(stats_before.total_requests, 0, "initial requests should be 0");
        assert_equal(stats_before.total_responses, 0, "initial responses should be 0");

        // Make some requests
        response1, _ := e2e_send_request(*client, "context.get", "", *server);
        defer if response1.count > 0 free(response1);

        response2, _ := e2e_send_request(*client, "service.list", "", *server);
        defer if response2.count > 0 free(response2);

        // Check stats increased
        stats_after := get_server_stats(*server);
        assert_equal(stats_after.total_requests, 2, "should have 2 requests");
        assert_equal(stats_after.total_responses, 2, "should have 2 responses");
        assert_greater_than(stats_after.bytes_received, 0, "bytes received should be > 0");
        assert_greater_than(stats_after.bytes_sent, 0, "bytes sent should be > 0");
    }

    return all_tests_passed(state);
}

// ============================================================================
// SDK Client Behavior Test - Missing Newline Bug Reproduction
// ============================================================================

// This function replicates the SDK client behavior - sending JSON WITHOUT a trailing newline.
// The server expects newline-delimited messages, so this will hang if the bug exists.
e2e_send_request_without_newline :: (client: *E2E_Test_Client, method: string, params := "", server: *Daemon_Server = null, timeout_ms: int = 200) -> string, bool {
    if !client.connected return "", false;

    // Build JSON-RPC request WITHOUT newline (simulating SDK client bug)
    request: string;
    if params.count > 0 {
        request = tprint("{\"jsonrpc\":\"2.0\",\"method\":\"%\",\"params\":%,\"id\":1}", method, params);
    } else {
        request = tprint("{\"jsonrpc\":\"2.0\",\"method\":\"%\",\"id\":1}", method);
    }

    #if OS == .WINDOWS {
        // Send request via named pipe
        bytes_written: DWORD = 0;
        success := WriteFile(client.e2e_pipe_handle, request.data, cast(DWORD) request.count, *bytes_written, null);
        if !success || bytes_written == 0 {
            return "", false;
        }

        // Run server iterations to process the request
        if server {
            run_server_iteration(server, 50);
            run_server_iteration(server, 50);
        }

        // Try to receive response with LIMITED retries (will timeout if server is waiting for newline)
        bytes_read: DWORD = 0;
        max_retries := timeout_ms / 20;
        for retry: 0..max_retries-1 {
            // Check if data is available
            bytes_available: DWORD = 0;
            if PeekNamedPipe_E2E(client.e2e_pipe_handle, null, 0, null, *bytes_available, null) {
                if bytes_available > 0 {
                    // Read the available data
                    if ReadFile(client.e2e_pipe_handle, client.recv_buffer.data, 65535, *bytes_read, null) {
                        if bytes_read > 0 break;
                    }
                }
            }

            // Run more server iterations if available
            if server {
                run_server_iteration(server, 20);
            }
            sleep_ms(20);
        }

        if bytes_read == 0 {
            return "", false;  // Timeout - server is waiting for newline
        }

        // Return response
        response_str: string;
        response_str.data = client.recv_buffer.data;
        response_str.count = cast(s64) bytes_read;

        // Trim trailing newlines
        while response_str.count > 0 && (response_str[response_str.count-1] == #char "\n" || response_str[response_str.count-1] == #char "\r") {
            response_str.count -= 1;
        }

        return copy_string(response_str), true;

    } else #if OS == .LINUX || OS == .MACOS {
        // Send request
        bytes_sent := write(client.e2e_socket, request.data, cast(u64) request.count);
        if bytes_sent < 0 {
            return "", false;
        }

        // Run server iterations to process the request
        if server {
            run_server_iteration(server, 50);
            run_server_iteration(server, 50);
        }

        // Set socket to non-blocking for read
        flags := fcntl(client.e2e_socket, F_GETFL, 0);
        fcntl(client.e2e_socket, F_SETFL, flags | O_NONBLOCK);

        // Try to receive response with LIMITED retries
        bytes_received: s64 = -1;
        max_retries := timeout_ms / 20;
        for retry: 0..max_retries-1 {
            bytes_received = read(client.e2e_socket, client.recv_buffer.data, 65535);
            if bytes_received > 0 break;

            // Run more server iterations if available
            if server {
                run_server_iteration(server, 20);
            }
            sleep_ms(20);
        }

        // Restore blocking mode
        fcntl(client.e2e_socket, F_SETFL, flags);

        if bytes_received <= 0 {
            return "", false;  // Timeout - server is waiting for newline
        }

        // Return response
        response_str: string;
        response_str.data = client.recv_buffer.data;
        response_str.count = bytes_received;

        // Trim trailing newlines
        while response_str.count > 0 && (response_str[response_str.count-1] == #char "\n" || response_str[response_str.count-1] == #char "\r") {
            response_str.count -= 1;
        }

        return copy_string(response_str), true;
    } else {
        return "", false;
    }
}

// Regression test: Verify server correctly handles requests without trailing newlines
// This test documents that the server needs to handle incomplete messages gracefully.
// The fix was made in SDK client.jai (send_request_internal adds newline delimiter),
// but the server should also be robust to clients that don't send newlines properly.
//
// NOTE: This test intentionally sends requests WITHOUT newlines to verify server behavior.
// Since the server waits for newline-delimited messages, this test will timeout if
// the server hasn't been made more robust, which is expected behavior for now.
// The real fix is in the SDK client adding the newline.
test_e2e_request_without_newline_times_out :: () -> bool {
    state := init_test_state("test_e2e_request_without_newline_times_out", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := generate_test_socket_path();
        defer cleanup_test_socket(socket_path);

        config := create_default_config();
        defer free_user_config(*config);

        server: Daemon_Server;
        init_daemon_server(*server, socket_path, *config);
        defer destroy_daemon_server(*server);
        start_daemon_server(*server);
        run_server_iteration(*server, 10);

        client: E2E_Test_Client;
        init_e2e_client(*client);
        connect_e2e_client(*client, socket_path);
        defer disconnect_e2e_client(*client);
        run_server_iteration(*server, 10);

        // Send a request WITHOUT newline delimiter
        // This simulates what was happening with the SDK client before the fix.
        // The server waits for a newline to complete the message, so without it
        // we expect a timeout. This is now the expected behavior - proper clients
        // should send the newline (which the SDK now does).
        response, ok := e2e_send_request_without_newline(*client, "context.list", "", *server, timeout_ms = 300);
        defer if response.count > 0 free(response);

        // Without a newline, the server waits for more data and times out.
        // This is EXPECTED - the test documents that proper newline framing is required.
        // The fix is in the SDK client which now sends the newline.
        assert_false(ok, "request without newline should timeout (server waits for newline delimiter)");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Registration
// ============================================================================

register_e2e_tests :: (register_proc: (string, () -> bool, string)) {
    // Server lifecycle
    register_proc("e2e/server_init_destroy", test_e2e_server_init_destroy, "e2e");
    register_proc("e2e/server_start_stop", test_e2e_server_start_stop, "e2e");

    // Client connection
    register_proc("e2e/client_connect", test_e2e_client_connect, "e2e");
    register_proc("e2e/multiple_clients", test_e2e_multiple_clients, "e2e");

    // Context API (basic)
    register_proc("e2e/context_get", test_e2e_context_get, "e2e");
    register_proc("e2e/context_add_remove_tag", test_e2e_context_add_remove_tag, "e2e");
    register_proc("e2e/context_set_param", test_e2e_context_set_param, "e2e");

    // Context Registry API (multi-context support)
    register_proc("e2e/context_list_empty", test_e2e_context_list_empty, "e2e");
    register_proc("e2e/context_create", test_e2e_context_create, "e2e");
    register_proc("e2e/context_create_duplicate", test_e2e_context_create_duplicate, "e2e");
    register_proc("e2e/context_switch", test_e2e_context_switch, "e2e");
    register_proc("e2e/context_switch_auto_create", test_e2e_context_switch_auto_create, "e2e");
    register_proc("e2e/context_switch_with_args", test_e2e_context_switch_with_args, "e2e");
    register_proc("e2e/context_history", test_e2e_context_history, "e2e");
    register_proc("e2e/context_delete", test_e2e_context_delete, "e2e");
    register_proc("e2e/context_delete_nonexistent", test_e2e_context_delete_nonexistent, "e2e");

    // Service API
    register_proc("e2e/service_register_list", test_e2e_service_register_list, "e2e");

    // Subscription API
    register_proc("e2e/subscribe_unsubscribe", test_e2e_subscribe_unsubscribe, "e2e");

    // Handshake
    register_proc("e2e/handshake", test_e2e_handshake, "e2e");

    // Logs API
    register_proc("e2e/logs_list", test_e2e_logs_list, "e2e");

    // Preview API
    register_proc("e2e/preview_get", test_e2e_preview_get, "e2e");

    // Error handling
    register_proc("e2e/invalid_method", test_e2e_invalid_method, "e2e");
    register_proc("e2e/invalid_params", test_e2e_invalid_params, "e2e");

    // Statistics
    register_proc("e2e/server_stats", test_e2e_server_stats, "e2e");

    // SDK client behavior (newline bug)
    register_proc("e2e/request_without_newline", test_e2e_request_without_newline_times_out, "e2e");
}
