// Unit tests for IPC Abstraction Layer
//
// Tests the IPC functionality including:
// - Server initialization and cleanup
// - Connection handling
// - Read/write operations
// - Buffer management

#load "../../src/daemon/ipc.jai";

// Helper to get platform-appropriate socket/pipe path
get_test_ipc_path :: (name: string) -> string {
    #if OS == .WINDOWS {
        return tprint("\\\\.\\pipe\\%", name);
    } else {
        return tprint("/tmp/%.sock", name);
    }
}

test_ipc_server_init :: () -> bool {
    state := init_test_state("test_ipc_server_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;

        // Test initialization
        success := init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_ipc"));
        defer destroy_ipc_server(*server);

        assert_true(success, "server init should succeed");
        assert_true(server.initialized, "server should be initialized");
        assert_false(server.running, "server should not be running yet");
        assert_equal(server.connection_count, cast(s32) 0, "initial connection count should be 0");
        assert_equal(server.server_fd, cast(s32) -1, "server fd should be -1 before start");
    }

    return all_tests_passed(state);
}

test_ipc_server_double_init :: () -> bool {
    state := init_test_state("test_ipc_server_double_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;

        success1 := init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_ipc"));
        defer destroy_ipc_server(*server);

        assert_true(success1, "first init should succeed");

        // Second init should fail
        success2 := init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_ipc2"));
        assert_false(success2, "second init should fail");
    }

    return all_tests_passed(state);
}

test_ipc_server_start_stop :: () -> bool {
    state := init_test_state("test_ipc_server_start_stop", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_start_stop"));
        defer destroy_ipc_server(*server);

        // Start server
        success := start_server(*server);
        assert_true(success, "server start should succeed");
        assert_true(server.running, "server should be running");
        assert_greater_or_equal(server.server_fd, 0, "server fd should be valid");

        // Stop server
        stop_server(*server);
        assert_false(server.running, "server should not be running after stop");
    }

    return all_tests_passed(state);
}

test_ipc_connection_buffer :: () -> bool {
    state := init_test_state("test_ipc_connection_buffer", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create a mock connection for buffer testing
        conn: IPC_Connection;
        conn.id = 1;
        conn.fd = 100;  // Fake fd for testing
        conn.state = .CONNECTED;
        conn.write_buffer_len = 0;
        conn.write_buffer_offset = 0;

        // Test queue_write
        test_data := "Hello, World!";
        data_bytes := cast([] u8) test_data;
        success := queue_write(*conn, data_bytes);

        assert_true(success, "queue_write should succeed");
        assert_equal(conn.write_buffer_len, cast(s64) test_data.count, "buffer length should match data");

        // Queue more data
        success2 := queue_write(*conn, data_bytes);
        assert_true(success2, "second queue_write should succeed");
        assert_equal(conn.write_buffer_len, cast(s64) (test_data.count * 2), "buffer length should be doubled");

        // Test disconnected connection
        conn.state = .DISCONNECTED;
        success3 := queue_write(*conn, data_bytes);
        assert_false(success3, "queue_write on disconnected should fail");
    }

    return all_tests_passed(state);
}

test_ipc_stats :: () -> bool {
    state := init_test_state("test_ipc_stats", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_stats"));
        defer destroy_ipc_server(*server);

        // Get initial stats
        stats := get_stats(*server);
        assert_equal(stats.active_connections, cast(s32) 0, "initial active connections should be 0");
        assert_equal(stats.total_connections, cast(u64) 0, "initial total connections should be 0");
        assert_equal(stats.bytes_received, cast(u64) 0, "initial bytes received should be 0");
        assert_equal(stats.bytes_sent, cast(u64) 0, "initial bytes sent should be 0");
    }

    return all_tests_passed(state);
}

test_ipc_get_connection :: () -> bool {
    state := init_test_state("test_ipc_get_connection", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_get_conn"));
        defer destroy_ipc_server(*server);

        // Get non-existent connection
        conn := get_connection(*server, 999);
        assert_null(conn, "non-existent connection should return null");

        // Manually add a connection for testing
        server.connections[0].id = 42;
        server.connections[0].fd = 100;
        server.connections[0].state = .CONNECTED;
        server.connection_count = 1;

        // Get existing connection
        conn2 := get_connection(*server, 42);
        assert_not_null(conn2, "existing connection should be found");
        assert_equal(conn2.id, cast(u32) 42, "connection id should match");

        // Get by wrong id
        conn3 := get_connection(*server, 43);
        assert_null(conn3, "wrong id should return null");
    }

    return all_tests_passed(state);
}

test_ipc_connection_count :: () -> bool {
    state := init_test_state("test_ipc_connection_count", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_count"));
        defer destroy_ipc_server(*server);

        // Initial count
        count := get_connection_count(*server);
        assert_equal(count, cast(s32) 0, "initial connection count should be 0");

        // Simulate adding connections
        server.connection_count = 5;
        count2 := get_connection_count(*server);
        assert_equal(count2, cast(s32) 5, "connection count should be 5");
    }

    return all_tests_passed(state);
}

test_ipc_poll_not_running :: () -> bool {
    state := init_test_state("test_ipc_poll_not_running", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_poll"));
        defer destroy_ipc_server(*server);

        // Poll without starting should return -1
        result := poll_events(*server, 0);
        assert_equal(result, cast(s32) -1, "poll on non-running server should return -1");
    }

    return all_tests_passed(state);
}

test_ipc_accept_not_running :: () -> bool {
    state := init_test_state("test_ipc_accept_not_running", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;
        init_ipc_server(*server, get_test_ipc_path("test_uncrumpled_accept"));
        defer destroy_ipc_server(*server);

        // Accept without starting should return 0
        result := accept_connections(*server);
        assert_equal(result, cast(s32) 0, "accept on non-running server should return 0");
    }

    return all_tests_passed(state);
}

// ============================================================================
// IPC CLIENT TESTS
// ============================================================================

test_ipc_client_init :: () -> bool {
    state := init_test_state("test_ipc_client_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        client: IPC_Client;

        // Test initialization
        success := init_ipc_client(*client, get_test_ipc_path("test_client"));
        defer destroy_ipc_client(*client);

        assert_true(success, "client init should succeed");
        assert_true(client.initialized, "client should be initialized");
        assert_equal(client.state, Connection_State.DISCONNECTED, "client should be disconnected initially");
        assert_equal(client.fd, cast(s32) -1, "client fd should be -1 before connect");
    }

    return all_tests_passed(state);
}

test_ipc_client_double_init :: () -> bool {
    state := init_test_state("test_ipc_client_double_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        client: IPC_Client;

        success1 := init_ipc_client(*client, get_test_ipc_path("test_client"));
        defer destroy_ipc_client(*client);

        assert_true(success1, "first init should succeed");

        // Second init should fail
        success2 := init_ipc_client(*client, get_test_ipc_path("test_client2"));
        assert_false(success2, "second init should fail");
    }

    return all_tests_passed(state);
}

test_ipc_client_connect_no_server :: () -> bool {
    state := init_test_state("test_ipc_client_connect_no_server", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        client: IPC_Client;

        init_ipc_client(*client, get_test_ipc_path("test_nonexistent"));
        defer destroy_ipc_client(*client);

        // Connect should fail when no server
        success := connect_client(*client);
        assert_false(success, "connect should fail when no server");
        assert_equal(client.state, Connection_State.ERROR, "client state should be ERROR");
    }

    return all_tests_passed(state);
}

test_ipc_client_is_connected :: () -> bool {
    state := init_test_state("test_ipc_client_is_connected", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        client: IPC_Client;

        // Uninitialized client
        assert_false(client_is_connected(*client), "uninitialized client should not be connected");

        init_ipc_client(*client, get_test_ipc_path("test_client"));
        defer destroy_ipc_client(*client);

        // Initialized but disconnected
        assert_false(client_is_connected(*client), "initialized but disconnected client should not be connected");

        // Simulate connected state (normally set by connect_client)
        client.state = .CONNECTED;
        assert_true(client_is_connected(*client), "connected client should report connected");
    }

    return all_tests_passed(state);
}

test_ipc_client_stats :: () -> bool {
    state := init_test_state("test_ipc_client_stats", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        client: IPC_Client;

        init_ipc_client(*client, get_test_ipc_path("test_client"));
        defer destroy_ipc_client(*client);

        // Check initial stats
        stats := get_client_stats(*client);
        assert_equal(stats.bytes_received, cast(u64) 0, "initial bytes received should be 0");
        assert_equal(stats.bytes_sent, cast(u64) 0, "initial bytes sent should be 0");

        // Simulate some traffic
        client.bytes_received = 100;
        client.bytes_sent = 50;

        stats2 := get_client_stats(*client);
        assert_equal(stats2.bytes_received, cast(u64) 100, "bytes received should be 100");
        assert_equal(stats2.bytes_sent, cast(u64) 50, "bytes sent should be 50");
    }

    return all_tests_passed(state);
}

// ============================================================================
// IPC ROUNDTRIP TEST (Client <-> Server)
// ============================================================================

test_ipc_client_server_roundtrip :: () -> bool {
    state := init_test_state("test_ipc_client_server_roundtrip", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := get_test_ipc_path("test_roundtrip");

        // Create and start server
        server: IPC_Server;
        init_success := init_ipc_server(*server, socket_path);
        defer destroy_ipc_server(*server);

        assert_true(init_success, "server init should succeed");

        start_success := start_server(*server);
        assert_true(start_success, "server start should succeed");
        assert_true(server.running, "server should be running");

        // Create client and connect
        client: IPC_Client;
        client_init := init_ipc_client(*client, socket_path);
        defer destroy_ipc_client(*client);

        assert_true(client_init, "client init should succeed");

        connect_success := connect_client(*client);
        assert_true(connect_success, "client connect should succeed");
        assert_true(client_is_connected(*client), "client should be connected");

        // Server should accept the connection
        poll_result := poll_events(*server, 100);
        assert_greater_or_equal(poll_result, 0, "poll should not error");

        accepted := accept_connections(*server);
        assert_equal(accepted, cast(s32) 1, "server should accept 1 connection");
        assert_equal(server.connection_count, cast(s32) 1, "server should have 1 connection");

        // Send data from client to server
        test_message := "Hello, Server!";
        message_bytes := cast([] u8) test_message;
        sent := client_send(*client, message_bytes);
        assert_equal(sent, cast(s64) test_message.count, "client should send full message");

        // Server receives data
        // First poll for readable data
        poll_result2 := poll_events(*server, 100);
        assert_greater_than(poll_result2, cast(s32) 0, "poll should indicate readable data");

        // Find the connected client
        server_conn: *IPC_Connection = null;
        for *conn: server.connections {
            if conn.state == .CONNECTED {
                server_conn = conn;
                break;
            }
        }
        assert_not_null(server_conn, "should find server connection");

        // Read data
        recv_buffer: [256] u8;
        bytes_read := read_connection(*server, server_conn, recv_buffer);
        assert_equal(bytes_read, cast(s64) test_message.count, "server should receive full message");

        // Verify message content
        received_str: string;
        received_str.data = recv_buffer.data;
        received_str.count = bytes_read;
        assert_equal(received_str, test_message, "message content should match");

        // Send response from server to client
        response := "Hello, Client!";
        response_bytes := cast([] u8) response;
        server_sent := write_connection(*server, server_conn, response_bytes);
        assert_equal(server_sent, cast(s64) response.count, "server should send full response");

        // Client receives response
        poll_client := client_poll(*client, 100);
        assert_equal(poll_client, cast(s32) 1, "client poll should indicate readable data");

        client_recv_buffer: [256] u8;
        client_bytes_read := client_receive(*client, client_recv_buffer);
        assert_equal(client_bytes_read, cast(s64) response.count, "client should receive full response");

        // Verify response content
        client_received_str: string;
        client_received_str.data = client_recv_buffer.data;
        client_received_str.count = client_bytes_read;
        assert_equal(client_received_str, response, "response content should match");

        // Verify stats
        client_stats := get_client_stats(*client);
        assert_equal(client_stats.bytes_sent, cast(u64) test_message.count, "client bytes sent should match");
        assert_equal(client_stats.bytes_received, cast(u64) response.count, "client bytes received should match");

        server_stats := get_stats(*server);
        assert_equal(server_stats.bytes_received, cast(u64) test_message.count, "server bytes received should match");
        assert_equal(server_stats.bytes_sent, cast(u64) response.count, "server bytes sent should match");

        // Disconnect client
        disconnect_client(*client);
        assert_false(client_is_connected(*client), "client should be disconnected");
    }

    return all_tests_passed(state);
}

test_ipc_multiple_clients :: () -> bool {
    state := init_test_state("test_ipc_multiple_clients", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := get_test_ipc_path("test_multi_clients");

        // Create and start server
        server: IPC_Server;
        init_ipc_server(*server, socket_path);
        defer destroy_ipc_server(*server);

        start_server(*server);

        // Create and connect multiple clients
        NUM_CLIENTS :: 3;
        clients: [NUM_CLIENTS] IPC_Client;

        for i: 0..NUM_CLIENTS-1 {
            init_ipc_client(*clients[i], socket_path);
            connect_success := connect_client(*clients[i]);
            assert_true(connect_success, "client connect should succeed");
        }
        defer {
            for i: 0..NUM_CLIENTS-1 {
                destroy_ipc_client(*clients[i]);
            }
        }

        // Server accepts all connections
        poll_events(*server, 100);
        accepted := accept_connections(*server);
        assert_equal(accepted, cast(s32) NUM_CLIENTS, "server should accept all clients");
        assert_equal(server.connection_count, cast(s32) NUM_CLIENTS, "server should have all connections");

        // Each client sends a unique message
        for i: 0..NUM_CLIENTS-1 {
            msg := tprint("Message from client %", i);
            msg_bytes := cast([] u8) msg;
            sent := client_send(*clients[i], msg_bytes);
            assert_greater_than(sent, cast(s64) 0, "client should send message");
        }

        // Give time for messages to arrive
        poll_events(*server, 100);

        // Verify stats
        stats := get_stats(*server);
        assert_equal(stats.active_connections, cast(s32) NUM_CLIENTS, "should have 3 active connections");
        assert_equal(stats.total_connections, cast(u64) NUM_CLIENTS, "should have 3 total connections");
    }

    return all_tests_passed(state);
}

// Register all IPC tests
register_ipc_tests :: () {
    // Server tests
    register_test("ipc/server_init", test_ipc_server_init);
    register_test("ipc/server_double_init", test_ipc_server_double_init);
    register_test("ipc/server_start_stop", test_ipc_server_start_stop);
    register_test("ipc/connection_buffer", test_ipc_connection_buffer);
    register_test("ipc/stats", test_ipc_stats);
    register_test("ipc/get_connection", test_ipc_get_connection);
    register_test("ipc/connection_count", test_ipc_connection_count);
    register_test("ipc/poll_not_running", test_ipc_poll_not_running);
    register_test("ipc/accept_not_running", test_ipc_accept_not_running);

    // Client tests
    register_test("ipc/client_init", test_ipc_client_init);
    register_test("ipc/client_double_init", test_ipc_client_double_init);
    register_test("ipc/client_connect_no_server", test_ipc_client_connect_no_server);
    register_test("ipc/client_is_connected", test_ipc_client_is_connected);
    register_test("ipc/client_stats", test_ipc_client_stats);

    // Integration tests
    register_test("ipc/client_server_roundtrip", test_ipc_client_server_roundtrip);
    register_test("ipc/multiple_clients", test_ipc_multiple_clients);
}
