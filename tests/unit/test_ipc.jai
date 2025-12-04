// Unit tests for IPC Abstraction Layer
//
// Tests the IPC functionality including:
// - Server initialization and cleanup
// - Connection handling
// - Read/write operations
// - Buffer management

#load "../../src/daemon/ipc.jai";

test_ipc_server_init :: () -> bool {
    state := init_test_state("test_ipc_server_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        server: IPC_Server;

        // Test initialization
        success := init_ipc_server(*server, "/tmp/test_uncrumpled_ipc.sock");
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

        success1 := init_ipc_server(*server, "/tmp/test_uncrumpled_ipc.sock");
        defer destroy_ipc_server(*server);

        assert_true(success1, "first init should succeed");

        // Second init should fail
        success2 := init_ipc_server(*server, "/tmp/test_uncrumpled_ipc2.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_start_stop.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_stats.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_get_conn.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_count.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_poll.sock");
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
        init_ipc_server(*server, "/tmp/test_uncrumpled_accept.sock");
        defer destroy_ipc_server(*server);

        // Accept without starting should return 0
        result := accept_connections(*server);
        assert_equal(result, cast(s32) 0, "accept on non-running server should return 0");
    }

    return all_tests_passed(state);
}

// Register all IPC tests
register_ipc_tests :: () {
    register_test("ipc/server_init", test_ipc_server_init);
    register_test("ipc/server_double_init", test_ipc_server_double_init);
    register_test("ipc/server_start_stop", test_ipc_server_start_stop);
    register_test("ipc/connection_buffer", test_ipc_connection_buffer);
    register_test("ipc/stats", test_ipc_stats);
    register_test("ipc/get_connection", test_ipc_get_connection);
    register_test("ipc/connection_count", test_ipc_connection_count);
    register_test("ipc/poll_not_running", test_ipc_poll_not_running);
    register_test("ipc/accept_not_running", test_ipc_accept_not_running);
}
