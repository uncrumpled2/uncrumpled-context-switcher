// Unit tests for Context API handlers

// Note: Basic and String are imported by run_tests.jai
// assertions.jai is loaded by run_tests.jai
// test_jsonrpc.jai already loads rpc/module.jai which loads protocol.jai
// test_context_store.jai already loads context_store.jai
// So we just need to load the api/module.jai
#load "../../src/daemon/api/module.jai";

// ============================================================================
// context.get Tests
// ============================================================================

test_context_get :: () -> bool {
    state := init_test_state("test_context_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Initialize store
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set some data
        set_user_param(*store, "mode", "debug");
        add_tag(*store, "--work");

        // Create request
        json := #string END
{"jsonrpc": "2.0", "method": "context.get", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Should parse as request");

        // Handle the request
        result := handle_context_get(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse the response and verify structure
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Response should be a success response");

        // Verify the result contains expected fields
        result_obj := resp.response.result;
        assert_equal(result_obj.type, jason.JSON_Type.OBJECT, "Result should be an object");

        // Check for profile field (should be "default")
        found_profile, profile_val := table_find(result_obj.object, "profile");
        assert_true(found_profile, "Result should have profile field");
        assert_string_equal(profile_val.str, "default", "Profile should be 'default'");

        // Check for tags
        found_tags, tags_val := table_find(result_obj.object, "tags");
        assert_true(found_tags, "Result should have tags field");
        assert_equal(tags_val.type, jason.JSON_Type.ARRAY, "Tags should be an array");
        assert_equal(tags_val.array.count, 1, "Should have 1 tag");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.set Tests
// ============================================================================

test_context_set :: () -> bool {
    state := init_test_state("test_context_set", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Create request to set context
        json := #string END
{"jsonrpc": "2.0", "method": "context.set", "params": {"project_id": "myproject", "profile": "work", "environment": "staging", "tags": ["--work", "--test"]}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        // Handle the request
        result := handle_context_set(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify context was updated
        current := get_context(*store);
        defer free_context(*current);

        assert_string_equal(current.project_id, "myproject", "Project ID should be set");
        assert_string_equal(current.profile, "work", "Profile should be set");
        assert_string_equal(current.environment, "staging", "Environment should be set");
        assert_equal(current.tags.count, 2, "Should have 2 tags");
    }

    return all_tests_passed(state);
}

test_context_set_invalid_params :: () -> bool {
    state := init_test_state("test_context_set_invalid_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Create request with array params (should fail)
        json := #string END
{"jsonrpc": "2.0", "method": "context.set", "params": ["invalid"], "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_set(*store, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail with array params");

        // Verify error response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
        assert_equal(resp.error_response.error.code, JSONRPC_INVALID_PARAMS, "Should be invalid params error");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.update Tests
// ============================================================================

test_context_update :: () -> bool {
    state := init_test_state("test_context_update", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // First set some initial values
        update_json := #string END
{"jsonrpc": "2.0", "method": "context.set", "params": {"project_id": "initial", "profile": "default"}, "id": 1}
END;
        set_msg := parse_jsonrpc_message(update_json);
        defer free_jsonrpc_message(*set_msg);

        set_result := handle_context_set(*store, *set_msg.request);
        free(set_result.response);

        // Now update just the profile
        json := #string END
{"jsonrpc": "2.0", "method": "context.update", "params": {"profile": "work"}, "id": 2}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_update(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify only profile changed
        current := get_context(*store);
        defer free_context(*current);

        assert_string_equal(current.project_id, "initial", "Project ID should be unchanged");
        assert_string_equal(current.profile, "work", "Profile should be updated");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.addTag Tests
// ============================================================================

test_context_add_tag :: () -> bool {
    state := init_test_state("test_context_add_tag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Add a tag
        json := #string END
{"jsonrpc": "2.0", "method": "context.addTag", "params": {"tag": "--work"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_add_tag(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify tag was added
        assert_true(has_tag(*store, "--work"), "Tag should be added");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check "added" field
        found_added, added_val := table_find(resp.response.result.object, "added");
        assert_true(found_added, "Response should have 'added' field");
        assert_equal(added_val.type, jason.JSON_Type.BOOLEAN, "Added should be boolean");
        assert_true(added_val.boolean, "Added should be true");
    }

    return all_tests_passed(state);
}

test_context_add_tag_duplicate :: () -> bool {
    state := init_test_state("test_context_add_tag_duplicate", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Add a tag first
        add_tag(*store, "--work");

        // Try to add the same tag again
        json := #string END
{"jsonrpc": "2.0", "method": "context.addTag", "params": {"tag": "--work"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_add_tag(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed (but indicate not added)");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check "added" field - should be false
        found_added, added_val := table_find(resp.response.result.object, "added");
        assert_true(found_added, "Response should have 'added' field");
        assert_false(added_val.boolean, "Added should be false for duplicate");
    }

    return all_tests_passed(state);
}

test_context_add_tag_missing_param :: () -> bool {
    state := init_test_state("test_context_add_tag_missing_param", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Request without "tag" field
        json := #string END
{"jsonrpc": "2.0", "method": "context.addTag", "params": {"wrong_field": "value"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_add_tag(*store, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
        assert_equal(resp.error_response.error.code, JSONRPC_INVALID_PARAMS, "Should be invalid params error");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.removeTag Tests
// ============================================================================

test_context_remove_tag :: () -> bool {
    state := init_test_state("test_context_remove_tag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Add a tag first
        add_tag(*store, "--work");
        assert_true(has_tag(*store, "--work"), "Tag should exist");

        // Remove the tag
        json := #string END
{"jsonrpc": "2.0", "method": "context.removeTag", "params": {"tag": "--work"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_remove_tag(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify tag was removed
        assert_false(has_tag(*store, "--work"), "Tag should be removed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check "removed" field
        found_removed, removed_val := table_find(resp.response.result.object, "removed");
        assert_true(found_removed, "Response should have 'removed' field");
        assert_true(removed_val.boolean, "Removed should be true");
    }

    return all_tests_passed(state);
}

test_context_remove_tag_not_found :: () -> bool {
    state := init_test_state("test_context_remove_tag_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Try to remove a tag that doesn't exist
        json := #string END
{"jsonrpc": "2.0", "method": "context.removeTag", "params": {"tag": "--nonexistent"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_remove_tag(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed (but indicate not removed)");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check "removed" field - should be false
        found_removed, removed_val := table_find(resp.response.result.object, "removed");
        assert_true(found_removed, "Response should have 'removed' field");
        assert_false(removed_val.boolean, "Removed should be false");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.setParam Tests
// ============================================================================

test_context_set_param :: () -> bool {
    state := init_test_state("test_context_set_param", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set a parameter
        json := #string END
{"jsonrpc": "2.0", "method": "context.setParam", "params": {"key": "mode", "value": "debug"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_set_param(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify param was set
        value, found := get_user_param(*store, "mode");
        assert_true(found, "Param should be found");
        assert_string_equal(value, "debug", "Param value should match");
        if found then free(value);
    }

    return all_tests_passed(state);
}

test_context_set_param_missing_key :: () -> bool {
    state := init_test_state("test_context_set_param_missing_key", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Request without "key" field
        json := #string END
{"jsonrpc": "2.0", "method": "context.setParam", "params": {"value": "debug"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_set_param(*store, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.getParam Tests
// ============================================================================

test_context_get_param :: () -> bool {
    state := init_test_state("test_context_get_param", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set a parameter first
        set_user_param(*store, "mode", "debug");

        // Get the parameter
        json := #string END
{"jsonrpc": "2.0", "method": "context.getParam", "params": {"key": "mode"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_get_param(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check value
        found_value, value_val := table_find(resp.response.result.object, "value");
        assert_true(found_value, "Response should have 'value' field");
        assert_string_equal(value_val.str, "debug", "Value should match");

        // Check found
        found_flag, found_val := table_find(resp.response.result.object, "found");
        assert_true(found_flag, "Response should have 'found' field");
        assert_true(found_val.boolean, "Found should be true");
    }

    return all_tests_passed(state);
}

test_context_get_param_not_found :: () -> bool {
    state := init_test_state("test_context_get_param_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Get a parameter that doesn't exist
        json := #string END
{"jsonrpc": "2.0", "method": "context.getParam", "params": {"key": "nonexistent"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_get_param(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check found - should be false
        found_flag, found_val := table_find(resp.response.result.object, "found");
        assert_true(found_flag, "Response should have 'found' field");
        assert_false(found_val.boolean, "Found should be false");
    }

    return all_tests_passed(state);
}

// ============================================================================
// context.removeParam Tests
// ============================================================================

test_context_remove_param :: () -> bool {
    state := init_test_state("test_context_remove_param", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set a parameter first
        set_user_param(*store, "mode", "debug");

        // Remove the parameter
        json := #string END
{"jsonrpc": "2.0", "method": "context.removeParam", "params": {"key": "mode"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_context_remove_param(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify param was removed
        _, found := get_user_param(*store, "mode");
        assert_false(found, "Param should be removed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check "removed" field
        found_removed, removed_val := table_find(resp.response.result.object, "removed");
        assert_true(found_removed, "Response should have 'removed' field");
        assert_true(removed_val.boolean, "Removed should be true");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Router Tests
// ============================================================================

test_route_context_method :: () -> bool {
    state := init_test_state("test_route_context_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Test routing context.get
        json := #string END
{"jsonrpc": "2.0", "method": "context.get", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_context_method(*store, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Router should succeed for context.get");
    }

    return all_tests_passed(state);
}

test_route_unknown_method :: () -> bool {
    state := init_test_state("test_route_unknown_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Test routing unknown method
        json := #string END
{"jsonrpc": "2.0", "method": "context.unknown", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_context_method(*store, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Router should fail for unknown method");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
        assert_equal(resp.error_response.error.code, JSONRPC_METHOD_NOT_FOUND, "Should be method not found error");
    }

    return all_tests_passed(state);
}

test_is_context_method :: () -> bool {
    state := init_test_state("test_is_context_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_context_method("context.get"), "context.get should be a context method");
        assert_true(is_context_method("context.set"), "context.set should be a context method");
        assert_true(is_context_method("context.addTag"), "context.addTag should be a context method");
        assert_false(is_context_method("service.register"), "service.register should not be a context method");
        assert_false(is_context_method("subscribe"), "subscribe should not be a context method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_context_to_json :: () -> bool {
    state := init_test_state("test_context_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create a context with data
        test_ctx: Context;
        test_ctx.project_id = copy_string("myproject");
        test_ctx.profile = copy_string("work");
        test_ctx.environment = copy_string("prod");
        test_ctx.version = 42;
        array_add(*test_ctx.tags, copy_string("--work"));
        array_add(*test_ctx.tags, copy_string("--test"));
        table_set(*test_ctx.user_params, copy_string("mode"), copy_string("debug"));
        defer free_context(*test_ctx);

        // Convert to JSON
        json := context_to_json(*test_ctx);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "Should be an object");

        // Check fields
        found_project, project_val := table_find(json.object, "project_id");
        assert_true(found_project, "Should have project_id");
        assert_string_equal(project_val.str, "myproject", "project_id should match");

        found_profile, profile_val := table_find(json.object, "profile");
        assert_true(found_profile, "Should have profile");
        assert_string_equal(profile_val.str, "work", "profile should match");

        found_tags, tags_val := table_find(json.object, "tags");
        assert_true(found_tags, "Should have tags");
        assert_equal(tags_val.array.count, 2, "Should have 2 tags");
    }

    return all_tests_passed(state);
}

test_json_to_context :: () -> bool {
    state := init_test_state("test_json_to_context", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create JSON object
        json_str := #string END
{"project_id": "test", "profile": "dev", "environment": "staging", "tags": ["--work"]}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert to context
        test_ctx, parse_ok, parse_error := json_to_context(json);
        defer if parse_ok then free_context(*test_ctx);

        assert_true(parse_ok, "Should parse successfully");
        assert_string_equal(test_ctx.project_id, "test", "project_id should match");
        assert_string_equal(test_ctx.profile, "dev", "profile should match");
        assert_string_equal(test_ctx.environment, "staging", "environment should match");
        assert_equal(test_ctx.tags.count, 1, "Should have 1 tag");
    }

    return all_tests_passed(state);
}

test_json_to_context_invalid_tags :: () -> bool {
    state := init_test_state("test_json_to_context_invalid_tags", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create JSON with invalid tags (number instead of string)
        json_str := #string END
{"project_id": "test", "tags": [123]}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert should fail
        test_ctx, parse_ok, parse_error := json_to_context(json);

        assert_false(parse_ok, "Should fail to parse invalid tags");
        assert_true(parse_error.count > 0, "Should have error message");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_context_api_tests :: (register: (string, () -> bool, string)) {
    register("context_api/get", test_context_get, "unit");
    register("context_api/set", test_context_set, "unit");
    register("context_api/set_invalid_params", test_context_set_invalid_params, "unit");
    register("context_api/update", test_context_update, "unit");
    register("context_api/add_tag", test_context_add_tag, "unit");
    register("context_api/add_tag_duplicate", test_context_add_tag_duplicate, "unit");
    register("context_api/add_tag_missing_param", test_context_add_tag_missing_param, "unit");
    register("context_api/remove_tag", test_context_remove_tag, "unit");
    register("context_api/remove_tag_not_found", test_context_remove_tag_not_found, "unit");
    register("context_api/set_param", test_context_set_param, "unit");
    register("context_api/set_param_missing_key", test_context_set_param_missing_key, "unit");
    register("context_api/get_param", test_context_get_param, "unit");
    register("context_api/get_param_not_found", test_context_get_param_not_found, "unit");
    register("context_api/remove_param", test_context_remove_param, "unit");
    register("context_api/route_method", test_route_context_method, "unit");
    register("context_api/route_unknown", test_route_unknown_method, "unit");
    register("context_api/is_context_method", test_is_context_method, "unit");
    register("context_api/context_to_json", test_context_to_json, "unit");
    register("context_api/json_to_context", test_json_to_context, "unit");
    register("context_api/json_to_context_invalid", test_json_to_context_invalid_tags, "unit");
}
