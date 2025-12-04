// Unit tests for Handshake API
//
// Tests the handshake method for version negotiation and session management.
//
// Note: All necessary modules are loaded by earlier test files:
// - test_jsonrpc.jai loads rpc/module.jai which loads protocol.jai
// - test_context_api.jai loads api/module.jai which now includes handshake.jai

// ============================================================================
// Semver Parsing Tests
// ============================================================================

test_parse_semver_valid :: () -> bool {
    state := init_test_state("parse_semver_valid", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test valid versions
        ver, ok := parse_semver("1.0.0");
        assert_true(ok, "should parse 1.0.0");
        assert_equal(ver.major, 1, "major should be 1");
        assert_equal(ver.minor, 0, "minor should be 0");
        assert_equal(ver.patch, 0, "patch should be 0");

        ver, ok = parse_semver("2.3.4");
        assert_true(ok, "should parse 2.3.4");
        assert_equal(ver.major, 2, "major should be 2");
        assert_equal(ver.minor, 3, "minor should be 3");
        assert_equal(ver.patch, 4, "patch should be 4");

        ver, ok = parse_semver("10.20.30");
        assert_true(ok, "should parse 10.20.30");
        assert_equal(ver.major, 10, "major should be 10");
        assert_equal(ver.minor, 20, "minor should be 20");
        assert_equal(ver.patch, 30, "patch should be 30");

        ver, ok = parse_semver("0.0.1");
        assert_true(ok, "should parse 0.0.1");
        assert_equal(ver.major, 0, "major should be 0");
        assert_equal(ver.minor, 0, "minor should be 0");
        assert_equal(ver.patch, 1, "patch should be 1");
    }

    return all_tests_passed(state);
}

test_parse_semver_invalid :: () -> bool {
    state := init_test_state("parse_semver_invalid", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test invalid versions
        ver, ok := parse_semver("");
        assert_false(ok, "should reject empty string");

        ver, ok = parse_semver("1");
        assert_false(ok, "should reject single number");

        ver, ok = parse_semver("1.2");
        assert_false(ok, "should reject two numbers");

        ver, ok = parse_semver("v1.0.0");
        assert_false(ok, "should reject leading 'v'");

        ver, ok = parse_semver("1.0.0-beta");
        assert_false(ok, "should reject pre-release suffix (for now)");
    }

    return all_tests_passed(state);
}

test_compare_semver :: () -> bool {
    state := init_test_state("compare_semver", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        v1 := Semver.{1, 0, 0};
        v2 := Semver.{2, 0, 0};
        v1_1 := Semver.{1, 1, 0};
        v1_0_1 := Semver.{1, 0, 1};

        // Same version
        assert_equal(compare_semver(v1, v1), 0, "same version should be equal");

        // Major difference
        assert_equal(compare_semver(v1, v2), -1, "1.0.0 < 2.0.0");
        assert_equal(compare_semver(v2, v1), 1, "2.0.0 > 1.0.0");

        // Minor difference
        assert_equal(compare_semver(v1, v1_1), -1, "1.0.0 < 1.1.0");
        assert_equal(compare_semver(v1_1, v1), 1, "1.1.0 > 1.0.0");

        // Patch difference
        assert_equal(compare_semver(v1, v1_0_1), -1, "1.0.0 < 1.0.1");
        assert_equal(compare_semver(v1_0_1, v1), 1, "1.0.1 > 1.0.0");
    }

    return all_tests_passed(state);
}

test_version_compatibility :: () -> bool {
    state := init_test_state("version_compatibility", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Compatible versions (>= MIN_CLIENT_VERSION which is 1.0.0)
        compat, _ := check_version_compatibility("1.0.0");
        assert_true(compat, "1.0.0 should be compatible");

        compat, _ = check_version_compatibility("1.0.1");
        assert_true(compat, "1.0.1 should be compatible");

        compat, _ = check_version_compatibility("1.1.0");
        assert_true(compat, "1.1.0 should be compatible");

        compat, _ = check_version_compatibility("2.0.0");
        assert_true(compat, "2.0.0 should be compatible");

        // Incompatible versions (< 1.0.0)
        compat, _ = check_version_compatibility("0.9.0");
        assert_false(compat, "0.9.0 should be incompatible");

        compat, _ = check_version_compatibility("0.0.1");
        assert_false(compat, "0.0.1 should be incompatible");

        // Invalid version string
        err: string;
        compat, err = check_version_compatibility("invalid");
        assert_false(compat, "invalid version should be incompatible");
        assert_true(err.count > 0, "should have error message");
    }

    return all_tests_passed(state);
}

test_filter_capabilities :: () -> bool {
    state := init_test_state("filter_capabilities", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Request supported capabilities
        requested1 := string.["context", "subscribe"];
        granted1 := filter_supported_capabilities(requested1);
        defer {
            for granted1 { free(it); }
            array_free(granted1);
        }
        assert_equal(granted1.count, 2, "should grant both capabilities");

        // Request mix of supported and unsupported
        requested2 := string.["context", "unsupported_cap", "logs"];
        granted2 := filter_supported_capabilities(requested2);
        defer {
            for granted2 { free(it); }
            array_free(granted2);
        }
        assert_equal(granted2.count, 2, "should only grant supported capabilities");

        // Request only unsupported
        requested3 := string.["foo", "bar", "baz"];
        granted3 := filter_supported_capabilities(requested3);
        defer array_free(granted3);
        assert_equal(granted3.count, 0, "should grant no capabilities");

        // Request all supported
        granted4 := filter_supported_capabilities(SUPPORTED_CAPABILITIES);
        defer {
            for granted4 { free(it); }
            array_free(granted4);
        }
        assert_equal(granted4.count, SUPPORTED_CAPABILITIES.count, "should grant all requested supported");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Session Manager Tests
// ============================================================================

test_session_manager_init :: () -> bool {
    state := init_test_state("session_manager_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        assert_true(manager.initialized, "manager should be initialized");
        assert_equal(get_session_count(*manager), 0, "should have no sessions");
    }

    return all_tests_passed(state);
}

test_session_create_and_get :: () -> bool {
    state := init_test_state("session_create_and_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        caps := string.["context", "subscribe"];
        session_id, ok := create_session(*manager, "1.0.0", caps, "/tmp/client.sock");
        defer free(session_id);

        assert_true(ok, "session creation should succeed");
        assert_true(session_id.count > 0, "session_id should not be empty");
        assert_equal(get_session_count(*manager), 1, "should have 1 session");

        // Get the session
        session, found := get_session(*manager, session_id);
        defer free_session(*session);

        assert_true(found, "session should be found");
        assert_string_equal(session.session_id, session_id, "session_id should match");
        assert_string_equal(session.client_version, "1.0.0", "client_version should match");
        assert_string_equal(session.endpoint, "/tmp/client.sock", "endpoint should match");
        assert_equal(session.capabilities.count, 2, "should have 2 capabilities");
    }

    return all_tests_passed(state);
}

test_session_remove :: () -> bool {
    state := init_test_state("session_remove", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        caps := string.["context"];
        session_id, _ := create_session(*manager, "1.0.0", caps, "");
        defer free(session_id);

        assert_equal(get_session_count(*manager), 1, "should have 1 session");

        // Remove the session
        removed := remove_session(*manager, session_id);
        assert_true(removed, "removal should succeed");
        assert_equal(get_session_count(*manager), 0, "should have 0 sessions");

        // Try to get removed session
        _, found := get_session(*manager, session_id);
        assert_false(found, "removed session should not be found");

        // Try to remove again
        removed = remove_session(*manager, session_id);
        assert_false(removed, "second removal should fail");
    }

    return all_tests_passed(state);
}

test_session_id_generation :: () -> bool {
    state := init_test_state("session_id_generation", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        caps: [..] string;

        // Create multiple sessions and verify unique IDs
        id1, _ := create_session(*manager, "1.0.0", caps, "");
        defer free(id1);
        id2, _ := create_session(*manager, "1.0.0", caps, "");
        defer free(id2);
        id3, _ := create_session(*manager, "1.0.0", caps, "");
        defer free(id3);

        assert_true(id1 != id2, "session IDs should be unique");
        assert_true(id2 != id3, "session IDs should be unique");
        assert_true(id1 != id3, "session IDs should be unique");

        assert_equal(get_session_count(*manager), 3, "should have 3 sessions");
    }

    return all_tests_passed(state);
}

test_session_update_activity :: () -> bool {
    state := init_test_state("session_update_activity", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        caps: [..] string;
        session_id, _ := create_session(*manager, "1.0.0", caps, "");
        defer free(session_id);

        // Update activity
        updated := update_session_activity(*manager, session_id);
        assert_true(updated, "activity update should succeed");

        // Try on non-existent session
        updated = update_session_activity(*manager, "fake-session");
        assert_false(updated, "activity update on fake session should fail");
    }

    return all_tests_passed(state);
}

test_get_all_sessions :: () -> bool {
    state := init_test_state("get_all_sessions", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        caps: [..] string;
        id1, _ := create_session(*manager, "1.0.0", caps, "/tmp/a.sock");
        defer free(id1);
        id2, _ := create_session(*manager, "1.1.0", caps, "/tmp/b.sock");
        defer free(id2);

        sessions := get_all_sessions(*manager);
        defer free_sessions_array(*sessions);

        assert_equal(sessions.count, 2, "should return 2 sessions");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Handshake Handler Tests
// ============================================================================

test_handle_handshake_success :: () -> bool {
    state := init_test_state("handle_handshake_success", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Create a valid handshake request
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"1.0.0\",\"capabilities\":[\"context\",\"subscribe\"]},\"id\":1}";

        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        assert_true(parsed.type == .REQUEST, "should parse as request");

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_true(result.success, "handshake should succeed");
        assert_true(result.response.count > 0, "should have response");

        // Parse response and verify
        parse_ok, val := jason.json_parse_string(result.response);
        defer jason.json_free(val);
        assert_true(parse_ok, "response should be valid JSON");

        found_result, result_val := table_find(val.object, "result");
        assert_true(found_result, "should have result field");

        found_success, success_val := table_find(result_val.object, "success");
        assert_true(found_success, "result should have success field");
        assert_true(success_val.boolean, "success should be true");

        found_session, session_val := table_find(result_val.object, "session_id");
        assert_true(found_session, "result should have session_id");
        assert_true(session_val.str.count > 0, "session_id should not be empty");

        found_version, version_val := table_find(result_val.object, "protocol_version");
        assert_true(found_version, "result should have protocol_version");
        assert_string_equal(version_val.str, PROTOCOL_VERSION, "protocol_version should match");

        // Verify session was created
        assert_equal(get_session_count(*manager), 1, "should have created 1 session");
    }

    return all_tests_passed(state);
}

test_handle_handshake_with_endpoint :: () -> bool {
    state := init_test_state("handle_handshake_with_endpoint", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Handshake with endpoint
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"1.0.0\",\"capabilities\":[\"context\"],\"endpoint\":\"/tmp/my-client.sock\"},\"id\":1}";

        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_true(result.success, "handshake should succeed");

        // Verify session has endpoint
        sessions := get_all_sessions(*manager);
        defer free_sessions_array(*sessions);

        assert_equal(sessions.count, 1, "should have 1 session");
        assert_string_equal(sessions[0].endpoint, "/tmp/my-client.sock", "endpoint should be stored");
    }

    return all_tests_passed(state);
}

test_handle_handshake_invalid_params :: () -> bool {
    state := init_test_state("handle_handshake_invalid_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // No params object
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "should fail without params");
        assert_string_contains(result.response, "error", "response should contain error");

        // Verify no session created
        assert_equal(get_session_count(*manager), 0, "should not create session on error");
    }

    return all_tests_passed(state);
}

test_handle_handshake_missing_version :: () -> bool {
    state := init_test_state("handle_handshake_missing_version", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Missing client_version
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"capabilities\":[\"context\"]},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "should fail without client_version");
        assert_string_contains(result.response, "client_version", "error should mention client_version");
    }

    return all_tests_passed(state);
}

test_handle_handshake_missing_capabilities :: () -> bool {
    state := init_test_state("handle_handshake_missing_capabilities", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Missing capabilities
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"1.0.0\"},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "should fail without capabilities");
        assert_string_contains(result.response, "capabilities", "error should mention capabilities");
    }

    return all_tests_passed(state);
}

test_handle_handshake_incompatible_version :: () -> bool {
    state := init_test_state("handle_handshake_incompatible_version", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Old version
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"0.5.0\",\"capabilities\":[\"context\"]},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "should fail with old version");
        assert_string_contains(result.response, "too old", "error should mention too old");
    }

    return all_tests_passed(state);
}

test_handle_handshake_invalid_version_format :: () -> bool {
    state := init_test_state("handle_handshake_invalid_version_format", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Invalid version format
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"not-a-version\",\"capabilities\":[\"context\"]},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "should fail with invalid version format");
        assert_string_contains(result.response, "Invalid", "error should mention invalid");
    }

    return all_tests_passed(state);
}

test_handle_handshake_unsupported_capabilities :: () -> bool {
    state := init_test_state("handle_handshake_unsupported_capabilities", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Request unsupported capabilities
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"1.0.0\",\"capabilities\":[\"context\",\"unsupported_feature\",\"subscribe\"]},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := handle_handshake(*manager, *parsed.request);
        defer free(result.response);

        assert_true(result.success, "handshake should succeed even with unsupported caps");

        // Parse response and check capabilities
        parse_ok, val := jason.json_parse_string(result.response);
        defer jason.json_free(val);

        found_result, result_val := table_find(val.object, "result");
        found_caps, caps_val := table_find(result_val.object, "capabilities");
        assert_true(found_caps, "result should have capabilities");

        // Should only have the supported capabilities (context, subscribe)
        assert_equal(caps_val.array.count, 2, "should grant 2 capabilities");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Method Router Tests
// ============================================================================

test_route_handshake_method :: () -> bool {
    state := init_test_state("route_handshake_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Route handshake method
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"handshake\",\"params\":{\"client_version\":\"1.0.0\",\"capabilities\":[\"context\"]},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := route_handshake_method(*manager, *parsed.request);
        defer free(result.response);

        assert_true(result.success, "routing should succeed");
    }

    return all_tests_passed(state);
}

test_handshake_route_unknown_method :: () -> bool {
    state := init_test_state("handshake_route_unknown_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Session_Manager;
        init_session_manager(*manager);
        defer destroy_session_manager(*manager);

        // Route unknown method
        request_json := "{\"jsonrpc\":\"2.0\",\"method\":\"unknown.method\",\"params\":{},\"id\":1}";
        parsed := parse_jsonrpc_message(request_json);
        defer free_jsonrpc_message(*parsed);

        result := route_handshake_method(*manager, *parsed.request);
        defer free(result.response);

        assert_false(result.success, "routing unknown method should fail");
        assert_string_contains(result.response, "Unknown method", "should mention unknown method");
    }

    return all_tests_passed(state);
}

test_is_handshake_method :: () -> bool {
    state := init_test_state("is_handshake_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_handshake_method("handshake"), "handshake should be a handshake method");
        assert_false(is_handshake_method("subscribe"), "subscribe should not be a handshake method");
        assert_false(is_handshake_method("context.get"), "context.get should not be a handshake method");
        assert_false(is_handshake_method(""), "empty string should not be a handshake method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_session_to_json :: () -> bool {
    state := init_test_state("session_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        session: Client_Session;
        session.session_id = copy_string("test-session-1");
        session.client_version = copy_string("1.2.3");
        session.endpoint = copy_string("/tmp/test.sock");
        array_add(*session.capabilities, copy_string("context"));
        array_add(*session.capabilities, copy_string("subscribe"));
        defer free_session(*session);

        json := session_to_json(*session);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be object");

        found_id, id_val := table_find(json.object, "session_id");
        assert_true(found_id, "should have session_id");
        assert_string_equal(id_val.str, "test-session-1", "session_id should match");

        found_ver, ver_val := table_find(json.object, "client_version");
        assert_true(found_ver, "should have client_version");
        assert_string_equal(ver_val.str, "1.2.3", "version should match");

        found_ep, ep_val := table_find(json.object, "endpoint");
        assert_true(found_ep, "should have endpoint");
        assert_string_equal(ep_val.str, "/tmp/test.sock", "endpoint should match");

        found_caps, caps_val := table_find(json.object, "capabilities");
        assert_true(found_caps, "should have capabilities");
        assert_equal(caps_val.array.count, 2, "should have 2 capabilities");
    }

    return all_tests_passed(state);
}

test_json_to_session :: () -> bool {
    state := init_test_state("json_to_session", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json_str := "{\"session_id\":\"sess-42\",\"client_version\":\"2.0.0\",\"endpoint\":\"/tmp/x.sock\",\"capabilities\":[\"logs\"]}";
        parse_ok, val := jason.json_parse_string(json_str);
        defer jason.json_free(val);
        assert_true(parse_ok, "should parse JSON");

        session, success, err := json_to_session(val);
        defer if success then free_session(*session);

        assert_true(success, "conversion should succeed");
        assert_string_equal(session.session_id, "sess-42", "session_id should match");
        assert_string_equal(session.client_version, "2.0.0", "client_version should match");
        assert_string_equal(session.endpoint, "/tmp/x.sock", "endpoint should match");
        assert_equal(session.capabilities.count, 1, "should have 1 capability");
        assert_string_equal(session.capabilities[0], "logs", "capability should match");
    }

    return all_tests_passed(state);
}

test_json_to_session_missing_fields :: () -> bool {
    state := init_test_state("json_to_session_missing_fields", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Missing session_id
        json_str := "{\"client_version\":\"1.0.0\",\"capabilities\":[]}";
        _, val := jason.json_parse_string(json_str);
        defer jason.json_free(val);

        _, success, err := json_to_session(val);
        assert_false(success, "should fail without session_id");
        assert_string_contains(err, "session_id", "error should mention session_id");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_handshake_api_tests :: (register: (string, () -> bool, string)) {
    // Semver tests
    register("handshake_api/parse_semver_valid", test_parse_semver_valid, "unit");
    register("handshake_api/parse_semver_invalid", test_parse_semver_invalid, "unit");
    register("handshake_api/compare_semver", test_compare_semver, "unit");
    register("handshake_api/version_compatibility", test_version_compatibility, "unit");
    register("handshake_api/filter_capabilities", test_filter_capabilities, "unit");

    // Session manager tests
    register("handshake_api/session_manager_init", test_session_manager_init, "unit");
    register("handshake_api/session_create_and_get", test_session_create_and_get, "unit");
    register("handshake_api/session_remove", test_session_remove, "unit");
    register("handshake_api/session_id_generation", test_session_id_generation, "unit");
    register("handshake_api/session_update_activity", test_session_update_activity, "unit");
    register("handshake_api/get_all_sessions", test_get_all_sessions, "unit");

    // Handler tests
    register("handshake_api/handle_handshake_success", test_handle_handshake_success, "unit");
    register("handshake_api/handle_handshake_with_endpoint", test_handle_handshake_with_endpoint, "unit");
    register("handshake_api/handle_handshake_invalid_params", test_handle_handshake_invalid_params, "unit");
    register("handshake_api/handle_handshake_missing_version", test_handle_handshake_missing_version, "unit");
    register("handshake_api/handle_handshake_missing_capabilities", test_handle_handshake_missing_capabilities, "unit");
    register("handshake_api/handle_handshake_incompatible_version", test_handle_handshake_incompatible_version, "unit");
    register("handshake_api/handle_handshake_invalid_version_format", test_handle_handshake_invalid_version_format, "unit");
    register("handshake_api/handle_handshake_unsupported_capabilities", test_handle_handshake_unsupported_capabilities, "unit");

    // Router tests
    register("handshake_api/route_handshake_method", test_route_handshake_method, "unit");
    register("handshake_api/route_unknown_method", test_handshake_route_unknown_method, "unit");
    register("handshake_api/is_handshake_method", test_is_handshake_method, "unit");

    // JSON conversion tests
    register("handshake_api/session_to_json", test_session_to_json, "unit");
    register("handshake_api/json_to_session", test_json_to_session, "unit");
    register("handshake_api/json_to_session_missing_fields", test_json_to_session_missing_fields, "unit");
}
