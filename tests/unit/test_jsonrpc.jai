// Unit tests for JSON-RPC protocol implementation

// Note: Basic and String are imported by run_tests.jai
// assertions.jai is loaded by run_tests.jai
#load "../../src/daemon/rpc/module.jai";

// ============================================================================
// Request Parsing Tests
// ============================================================================

test_parse_simple_request :: () -> bool {
    state := init_test_state("test_parse_simple_request", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "subtract", "params": [42, 23], "id": 1}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Message type should be REQUEST");
        assert_string_equal(msg.request.method, "subtract", "Method should be 'subtract'");
        assert_true(msg.request.has_id, "Request should have an ID");
        assert_false(msg.request.id.is_null, "ID should not be null");
        assert_false(msg.request.id.is_string, "ID should be numeric");
        assert_equal(msg.request.id.num_value, cast(s64) 1, "ID should be 1");
        assert_equal(msg.request.params.type, jason.JSON_Type.ARRAY, "Params should be an array");
    }

    return all_tests_passed(state);
}

test_parse_request_with_object_params :: () -> bool {
    state := init_test_state("test_parse_request_with_object_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "context.set", "params": {"project_id": "test", "environment": "dev"}, "id": "req-1"}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Message type should be REQUEST");
        assert_string_equal(msg.request.method, "context.set", "Method should be 'context.set'");
        assert_true(msg.request.id.is_string, "ID should be a string");
        assert_string_equal(msg.request.id.str_value, "req-1", "ID should be 'req-1'");
        assert_equal(msg.request.params.type, jason.JSON_Type.OBJECT, "Params should be an object");
    }

    return all_tests_passed(state);
}

test_parse_request_no_params :: () -> bool {
    state := init_test_state("test_parse_request_no_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "context.get", "id": 5}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Message type should be REQUEST");
        assert_string_equal(msg.request.method, "context.get", "Method should be 'context.get'");
        assert_equal(msg.request.params.type, jason.JSON_Type.NULL, "Params should be null when absent");
    }

    return all_tests_passed(state);
}

test_parse_request_null_id :: () -> bool {
    state := init_test_state("test_parse_request_null_id", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "test", "id": null}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Message type should be REQUEST");
        assert_true(msg.request.has_id, "Request should have an ID");
        assert_true(msg.request.id.is_null, "ID should be null");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Notification Parsing Tests
// ============================================================================

test_parse_notification :: () -> bool {
    state := init_test_state("test_parse_notification", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "notify.contextChanged", "params": {"version": 42}}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.NOTIFICATION, "Message type should be NOTIFICATION");
        assert_string_equal(msg.notification.method, "notify.contextChanged", "Method should be 'notify.contextChanged'");
        assert_equal(msg.notification.params.type, jason.JSON_Type.OBJECT, "Params should be an object");
    }

    return all_tests_passed(state);
}

test_parse_notification_no_params :: () -> bool {
    state := init_test_state("test_parse_notification_no_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "method": "shutdown"}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.NOTIFICATION, "Message type should be NOTIFICATION");
        assert_string_equal(msg.notification.method, "shutdown", "Method should be 'shutdown'");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Response Parsing Tests
// ============================================================================

test_parse_success_response :: () -> bool {
    state := init_test_state("test_parse_success_response", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "result": 19, "id": 1}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.RESPONSE, "Message type should be RESPONSE");
        assert_equal(msg.response.result.type, jason.JSON_Type.NUMBER, "Result should be a number");
        assert_equal(msg.response.id.num_value, cast(s64) 1, "ID should be 1");
    }

    return all_tests_passed(state);
}

test_parse_success_response_object_result :: () -> bool {
    state := init_test_state("test_parse_success_response_object_result", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "result": {"project_id": "test", "version": 5}, "id": "abc"}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.RESPONSE, "Message type should be RESPONSE");
        assert_equal(msg.response.result.type, jason.JSON_Type.OBJECT, "Result should be an object");
        assert_true(msg.response.id.is_string, "ID should be a string");
        assert_string_equal(msg.response.id.str_value, "abc", "ID should be 'abc'");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Error Response Parsing Tests
// ============================================================================

test_parse_error_response :: () -> bool {
    state := init_test_state("test_parse_error_response", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": 1}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.ERROR_RESPONSE, "Message type should be ERROR_RESPONSE");
        assert_equal(msg.error_response.error.code, JSONRPC_METHOD_NOT_FOUND, "Error code should be -32601");
        assert_string_equal(msg.error_response.error.message, "Method not found", "Error message should match");
        assert_equal(msg.error_response.id.num_value, cast(s64) 1, "ID should be 1");
    }

    return all_tests_passed(state);
}

test_parse_error_response_with_data :: () -> bool {
    state := init_test_state("test_parse_error_response_with_data", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "error": {"code": -32602, "message": "Invalid params", "data": {"field": "project_id"}}, "id": 2}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.ERROR_RESPONSE, "Message type should be ERROR_RESPONSE");
        assert_equal(msg.error_response.error.code, JSONRPC_INVALID_PARAMS, "Error code should be -32602");
        assert_true(msg.error_response.error.has_data, "Error should have data");
        assert_equal(msg.error_response.error.data.type, jason.JSON_Type.OBJECT, "Error data should be an object");
    }

    return all_tests_passed(state);
}

test_parse_error_response_null_id :: () -> bool {
    state := init_test_state("test_parse_error_response_null_id", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "2.0", "error": {"code": -32700, "message": "Parse error"}, "id": null}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.ERROR_RESPONSE, "Message type should be ERROR_RESPONSE");
        assert_equal(msg.error_response.error.code, JSONRPC_PARSE_ERROR, "Error code should be -32700");
        assert_true(msg.error_response.id.is_null, "ID should be null");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Batch Parsing Tests
// ============================================================================

test_parse_batch_request :: () -> bool {
    state := init_test_state("test_parse_batch_request", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
[
    {"jsonrpc": "2.0", "method": "sum", "params": [1, 2], "id": 1},
    {"jsonrpc": "2.0", "method": "subtract", "params": [5, 3], "id": 2}
]
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.BATCH, "Message type should be BATCH");
        assert_equal(msg.batch.count, cast(s64) 2, "Batch should have 2 messages");
        assert_equal(msg.batch[0].type, Message_Type.REQUEST, "First message should be REQUEST");
        assert_equal(msg.batch[1].type, Message_Type.REQUEST, "Second message should be REQUEST");
    }

    return all_tests_passed(state);
}

test_parse_batch_mixed :: () -> bool {
    state := init_test_state("test_parse_batch_mixed", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
[
    {"jsonrpc": "2.0", "method": "notify.update"},
    {"jsonrpc": "2.0", "method": "get", "id": 1}
]
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.BATCH, "Message type should be BATCH");
        assert_equal(msg.batch.count, cast(s64) 2, "Batch should have 2 messages");
        assert_equal(msg.batch[0].type, Message_Type.NOTIFICATION, "First message should be NOTIFICATION");
        assert_equal(msg.batch[1].type, Message_Type.REQUEST, "Second message should be REQUEST");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Error Handling Tests
// ============================================================================

test_parse_empty_message :: () -> bool {
    state := init_test_state("test_parse_empty_message", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        msg := parse_jsonrpc_message("");
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.INVALID, "Empty message should be INVALID");
        assert_true(msg.parse_error.count > 0, "Should have parse error");
    }

    return all_tests_passed(state);
}

test_parse_invalid_json :: () -> bool {
    state := init_test_state("test_parse_invalid_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        msg := parse_jsonrpc_message("{invalid json}");
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.INVALID, "Invalid JSON should be INVALID");
        assert_true(msg.parse_error.count > 0, "Should have parse error");
    }

    return all_tests_passed(state);
}

test_parse_missing_jsonrpc :: () -> bool {
    state := init_test_state("test_parse_missing_jsonrpc", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"method": "test", "id": 1}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.INVALID, "Missing jsonrpc should be INVALID");
    }

    return all_tests_passed(state);
}

test_parse_wrong_version :: () -> bool {
    state := init_test_state("test_parse_wrong_version", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := #string END
{"jsonrpc": "1.0", "method": "test", "id": 1}
END;

        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.INVALID, "Wrong version should be INVALID");
    }

    return all_tests_passed(state);
}

test_parse_empty_batch :: () -> bool {
    state := init_test_state("test_parse_empty_batch", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        msg := parse_jsonrpc_message("[]");
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.INVALID, "Empty batch should be INVALID");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Serialization Tests
// ============================================================================

test_create_response :: () -> bool {
    state := init_test_state("test_create_response", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        id := make_request_id(cast(s64) 42);
        defer free_request_id(*id);

        result_val: jason.JSON_Value;
        result_val.type = .NUMBER;
        result_val.number = 19;

        response := create_response(id, result_val);
        defer free(response);

        // Parse back to verify
        msg := parse_jsonrpc_message(response);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.RESPONSE, "Should parse as RESPONSE");
        assert_equal(msg.response.id.num_value, cast(s64) 42, "ID should be 42");
    }

    return all_tests_passed(state);
}

test_create_error_response :: () -> bool {
    state := init_test_state("test_create_error_response", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        id := make_request_id("test-id");
        defer free_request_id(*id);

        response := create_error_response(id, JSONRPC_METHOD_NOT_FOUND, "Method not found");
        defer free(response);

        // Parse back to verify
        msg := parse_jsonrpc_message(response);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.ERROR_RESPONSE, "Should parse as ERROR_RESPONSE");
        assert_equal(msg.error_response.error.code, JSONRPC_METHOD_NOT_FOUND, "Error code should match");
        assert_string_equal(msg.error_response.id.str_value, "test-id", "ID should be 'test-id'");
    }

    return all_tests_passed(state);
}

test_create_notification :: () -> bool {
    state := init_test_state("test_create_notification", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        notif := create_notification("test.event");
        defer free(notif);

        // Parse back to verify
        msg := parse_jsonrpc_message(notif);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.NOTIFICATION, "Should parse as NOTIFICATION");
        assert_string_equal(msg.notification.method, "test.event", "Method should be 'test.event'");
    }

    return all_tests_passed(state);
}

test_create_request :: () -> bool {
    state := init_test_state("test_create_request", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        id := make_request_id(cast(s64) 99);
        defer free_request_id(*id);

        req := create_request(id, "context.get");
        defer free(req);

        // Parse back to verify
        msg := parse_jsonrpc_message(req);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Should parse as REQUEST");
        assert_string_equal(msg.request.method, "context.get", "Method should be 'context.get'");
        assert_equal(msg.request.id.num_value, cast(s64) 99, "ID should be 99");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Error Code Tests
// ============================================================================

test_error_messages :: () -> bool {
    state := init_test_state("test_error_messages", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_string_equal(get_error_message(JSONRPC_PARSE_ERROR), "Parse error", "Parse error message");
        assert_string_equal(get_error_message(JSONRPC_INVALID_REQUEST), "Invalid Request", "Invalid request message");
        assert_string_equal(get_error_message(JSONRPC_METHOD_NOT_FOUND), "Method not found", "Method not found message");
        assert_string_equal(get_error_message(JSONRPC_INVALID_PARAMS), "Invalid params", "Invalid params message");
        assert_string_equal(get_error_message(JSONRPC_INTERNAL_ERROR), "Internal error", "Internal error message");
    }

    return all_tests_passed(state);
}

test_is_standard_error :: () -> bool {
    state := init_test_state("test_is_standard_error", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_standard_error(JSONRPC_PARSE_ERROR), "Parse error should be standard");
        assert_true(is_standard_error(JSONRPC_INVALID_REQUEST), "Invalid request should be standard");
        assert_true(is_standard_error(JSONRPC_METHOD_NOT_FOUND), "Method not found should be standard");
        assert_true(is_standard_error(JSONRPC_INVALID_PARAMS), "Invalid params should be standard");
        assert_true(is_standard_error(JSONRPC_INTERNAL_ERROR), "Internal error should be standard");
        assert_true(is_standard_error(-32050), "Server error should be standard");
        assert_false(is_standard_error(-1001), "App error should not be standard");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_jsonrpc_tests :: (register: (name: string, test: () -> bool, category: string)) {
    // Request parsing
    register("jsonrpc/parse_simple_request", test_parse_simple_request, "unit");
    register("jsonrpc/parse_request_object_params", test_parse_request_with_object_params, "unit");
    register("jsonrpc/parse_request_no_params", test_parse_request_no_params, "unit");
    register("jsonrpc/parse_request_null_id", test_parse_request_null_id, "unit");

    // Notification parsing
    register("jsonrpc/parse_notification", test_parse_notification, "unit");
    register("jsonrpc/parse_notification_no_params", test_parse_notification_no_params, "unit");

    // Response parsing
    register("jsonrpc/parse_success_response", test_parse_success_response, "unit");
    register("jsonrpc/parse_success_response_object", test_parse_success_response_object_result, "unit");

    // Error response parsing
    register("jsonrpc/parse_error_response", test_parse_error_response, "unit");
    register("jsonrpc/parse_error_response_data", test_parse_error_response_with_data, "unit");
    register("jsonrpc/parse_error_response_null_id", test_parse_error_response_null_id, "unit");

    // Batch parsing
    register("jsonrpc/parse_batch_request", test_parse_batch_request, "unit");
    register("jsonrpc/parse_batch_mixed", test_parse_batch_mixed, "unit");

    // Error handling
    register("jsonrpc/parse_empty_message", test_parse_empty_message, "unit");
    register("jsonrpc/parse_invalid_json", test_parse_invalid_json, "unit");
    register("jsonrpc/parse_missing_jsonrpc", test_parse_missing_jsonrpc, "unit");
    register("jsonrpc/parse_wrong_version", test_parse_wrong_version, "unit");
    register("jsonrpc/parse_empty_batch", test_parse_empty_batch, "unit");

    // Serialization
    register("jsonrpc/create_response", test_create_response, "unit");
    register("jsonrpc/create_error_response", test_create_error_response, "unit");
    register("jsonrpc/create_notification", test_create_notification, "unit");
    register("jsonrpc/create_request", test_create_request, "unit");

    // Error codes
    register("jsonrpc/error_messages", test_error_messages, "unit");
    register("jsonrpc/is_standard_error", test_is_standard_error, "unit");
}
