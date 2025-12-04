// Unit tests for Subscription Manager API handlers

// Note: api/module.jai is already loaded by test_context_api.jai which includes subscription.jai

// ============================================================================
// Subscription Manager Tests
// ============================================================================

test_subscription_manager_init :: () -> bool {
    state := init_test_state("test_subscription_manager_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        assert_true(manager.initialized, "Manager should be initialized");
        assert_equal(get_subscriber_count(*manager), 0, "Initial count should be 0");
    }

    return all_tests_passed(state);
}

test_subscription_manager_subscribe :: () -> bool {
    state := init_test_state("test_subscription_manager_subscribe", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe
        events := string.["context.changed", "tags.updated"];
        success, was_new := subscribe(*manager, "/tmp/client.sock", events);

        assert_true(success, "Subscribe should succeed");
        assert_true(was_new, "Should be new subscriber");
        assert_equal(get_subscriber_count(*manager), 1, "Count should be 1");

        // Verify we can get it back
        sub, found := get_subscriber(*manager, "/tmp/client.sock");
        defer if found then free_subscriber(*sub);

        assert_true(found, "Subscriber should be found");
        assert_string_equal(sub.endpoint, "/tmp/client.sock", "Endpoint should match");
        assert_equal(sub.events.count, 2, "Should have 2 events");
    }

    return all_tests_passed(state);
}

test_subscription_manager_subscribe_update :: () -> bool {
    state := init_test_state("test_subscription_manager_subscribe_update", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // First subscription
        events1 := string.["context.changed"];
        success1, was_new1 := subscribe(*manager, "/tmp/client.sock", events1);
        assert_true(success1, "First subscribe should succeed");
        assert_true(was_new1, "Should be new subscriber");

        // Update subscription with different events
        events2 := string.["tags.updated", "service.registered"];
        success2, was_new2 := subscribe(*manager, "/tmp/client.sock", events2);
        assert_true(success2, "Update should succeed");
        assert_false(was_new2, "Should not be new (update)");

        // Verify events were updated
        sub, found := get_subscriber(*manager, "/tmp/client.sock");
        defer if found then free_subscriber(*sub);

        assert_true(found, "Subscriber should be found");
        assert_equal(sub.events.count, 2, "Should have 2 events");

        // Verify the new events
        has_tags := false;
        has_service := false;
        for sub.events {
            if it == "tags.updated" then has_tags = true;
            if it == "service.registered" then has_service = true;
        }
        assert_true(has_tags, "Should have tags.updated event");
        assert_true(has_service, "Should have service.registered event");

        // Count should still be 1
        assert_equal(get_subscriber_count(*manager), 1, "Count should still be 1");
    }

    return all_tests_passed(state);
}

test_subscription_manager_subscribe_empty_endpoint :: () -> bool {
    state := init_test_state("test_subscription_manager_subscribe_empty_endpoint", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe with empty endpoint
        events := string.["context.changed"];
        success, _ := subscribe(*manager, "", events);

        assert_false(success, "Subscribe with empty endpoint should fail");
        assert_equal(get_subscriber_count(*manager), 0, "Count should be 0");
    }

    return all_tests_passed(state);
}

test_subscription_manager_unsubscribe :: () -> bool {
    state := init_test_state("test_subscription_manager_unsubscribe", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe first
        events := string.["context.changed"];
        subscribe(*manager, "/tmp/client.sock", events);
        assert_equal(get_subscriber_count(*manager), 1, "Should have 1 subscriber");

        // Unsubscribe
        removed := unsubscribe(*manager, "/tmp/client.sock");
        assert_true(removed, "Unsubscribe should succeed");
        assert_equal(get_subscriber_count(*manager), 0, "Should have 0 subscribers");

        // Verify it's gone
        _, found := get_subscriber(*manager, "/tmp/client.sock");
        assert_false(found, "Subscriber should not be found");
    }

    return all_tests_passed(state);
}

test_subscription_manager_unsubscribe_not_found :: () -> bool {
    state := init_test_state("test_subscription_manager_unsubscribe_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Try to unsubscribe non-existent
        removed := unsubscribe(*manager, "/tmp/nonexistent.sock");
        assert_false(removed, "Unsubscribe should return false");
    }

    return all_tests_passed(state);
}

test_subscription_manager_get_all :: () -> bool {
    state := init_test_state("test_subscription_manager_get_all", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe multiple
        events := string.["context.changed"];
        for i: 0..2 {
            endpoint := tprint("/tmp/client%.sock", i);
            subscribe(*manager, endpoint, events);
        }

        // Get all
        all_subs := get_all_subscribers(*manager);
        defer free_subscribers_array(*all_subs);

        assert_equal(all_subs.count, 3, "Should have 3 subscribers");
    }

    return all_tests_passed(state);
}

test_subscription_manager_get_for_event :: () -> bool {
    state := init_test_state("test_subscription_manager_get_for_event", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe different clients to different events
        events1 := string.["context.changed"];
        events2 := string.["tags.updated"];
        events3 := string.["context.changed", "tags.updated"];

        subscribe(*manager, "/tmp/client1.sock", events1);
        subscribe(*manager, "/tmp/client2.sock", events2);
        subscribe(*manager, "/tmp/client3.sock", events3);

        // Get subscribers for context.changed
        context_subs := get_subscribers_for_event(*manager, "context.changed");
        defer free_subscribers_array(*context_subs);

        assert_equal(context_subs.count, 2, "Should have 2 subscribers for context.changed");

        // Get subscribers for tags.updated
        tags_subs := get_subscribers_for_event(*manager, "tags.updated");
        defer free_subscribers_array(*tags_subs);

        assert_equal(tags_subs.count, 2, "Should have 2 subscribers for tags.updated");

        // Get subscribers for unknown event
        unknown_subs := get_subscribers_for_event(*manager, "unknown.event");
        defer free_subscribers_array(*unknown_subs);

        assert_equal(unknown_subs.count, 0, "Should have 0 subscribers for unknown event");
    }

    return all_tests_passed(state);
}

test_subscription_manager_wildcard_matching :: () -> bool {
    state := init_test_state("test_subscription_manager_wildcard_matching", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe with wildcard
        wildcard_events := string.["context.*"];
        subscribe(*manager, "/tmp/wildcard.sock", wildcard_events);

        // Subscribe with specific event
        specific_events := string.["context.changed"];
        subscribe(*manager, "/tmp/specific.sock", specific_events);

        // Get subscribers for context.changed - should match both
        subs := get_subscribers_for_event(*manager, "context.changed");
        defer free_subscribers_array(*subs);

        assert_equal(subs.count, 2, "Should have 2 subscribers (wildcard + specific)");

        // Get subscribers for context.reset - should match only wildcard
        reset_subs := get_subscribers_for_event(*manager, "context.reset");
        defer free_subscribers_array(*reset_subs);

        assert_equal(reset_subs.count, 1, "Should have 1 subscriber for context.reset");
    }

    return all_tests_passed(state);
}

test_subscription_manager_heartbeat :: () -> bool {
    state := init_test_state("test_subscription_manager_heartbeat", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe
        events := string.["context.changed"];
        subscribe(*manager, "/tmp/client.sock", events);

        // Get initial heartbeat
        sub1, _ := get_subscriber(*manager, "/tmp/client.sock");
        initial_heartbeat := sub1.last_heartbeat;
        free_subscriber(*sub1);

        // Small delay
        sleep_ms(10);

        // Update heartbeat
        success := update_subscriber_heartbeat(*manager, "/tmp/client.sock");
        assert_true(success, "Heartbeat update should succeed");

        // Verify heartbeat was updated
        sub2, _ := get_subscriber(*manager, "/tmp/client.sock");
        defer free_subscriber(*sub2);

        assert_true(sub2.last_heartbeat.low >= initial_heartbeat.low, "Heartbeat should be updated");
    }

    return all_tests_passed(state);
}

// ============================================================================
// subscribe Handler Tests
// ============================================================================

test_handle_subscribe :: () -> bool {
    state := init_test_state("test_handle_subscribe", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Create request
        json := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/client.sock", "events": ["context.changed", "tags.updated"]}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Should parse as request");

        // Handle the request
        result := handle_subscribe(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify subscriber was added
        assert_equal(get_subscriber_count(*manager), 1, "Should have 1 subscriber");

        sub, found := get_subscriber(*manager, "/tmp/client.sock");
        defer if found then free_subscriber(*sub);

        assert_true(found, "Subscriber should be found");
        assert_equal(sub.events.count, 2, "Should have 2 events");

        // Parse the response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check "subscribed" field
        found_sub, sub_val := table_find(resp.response.result.object, "subscribed");
        assert_true(found_sub, "Response should have 'subscribed' field");
        assert_true(sub_val.boolean, "Subscribed should be true");

        // Check "new" field
        found_new, new_val := table_find(resp.response.result.object, "new");
        assert_true(found_new, "Response should have 'new' field");
        assert_true(new_val.boolean, "New should be true");
    }

    return all_tests_passed(state);
}

test_handle_subscribe_update :: () -> bool {
    state := init_test_state("test_handle_subscribe_update", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // First subscription
        json1 := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/client.sock", "events": ["context.changed"]}, "id": 1}
END;
        msg1 := parse_jsonrpc_message(json1);
        defer free_jsonrpc_message(*msg1);

        result1 := handle_subscribe(*manager, *msg1.request);
        free(result1.response);

        // Update subscription
        json2 := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/client.sock", "events": ["tags.updated"]}, "id": 2}
END;
        msg2 := parse_jsonrpc_message(json2);
        defer free_jsonrpc_message(*msg2);

        result2 := handle_subscribe(*manager, *msg2.request);
        defer free(result2.response);

        assert_true(result2.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result2.response);
        defer free_jsonrpc_message(*resp);

        // Check "new" field should be false
        found_new, new_val := table_find(resp.response.result.object, "new");
        assert_true(found_new, "Response should have 'new' field");
        assert_false(new_val.boolean, "New should be false for update");
    }

    return all_tests_passed(state);
}

test_handle_subscribe_missing_endpoint :: () -> bool {
    state := init_test_state("test_handle_subscribe_missing_endpoint", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Request with missing endpoint
        json := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"events": ["context.changed"]}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_subscribe(*manager, *msg.request);
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

test_handle_subscribe_missing_events :: () -> bool {
    state := init_test_state("test_handle_subscribe_missing_events", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Request with missing events
        json := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/client.sock"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_subscribe(*manager, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
    }

    return all_tests_passed(state);
}

test_handle_subscribe_invalid_events :: () -> bool {
    state := init_test_state("test_handle_subscribe_invalid_events", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Request with non-string in events array
        json := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/client.sock", "events": [123]}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_subscribe(*manager, *msg.request);
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
// unsubscribe Handler Tests
// ============================================================================

test_handle_unsubscribe :: () -> bool {
    state := init_test_state("test_handle_unsubscribe", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Subscribe first
        events := string.["context.changed"];
        subscribe(*manager, "/tmp/client.sock", events);

        // Unsubscribe via handler
        json := #string END
{"jsonrpc": "2.0", "method": "unsubscribe", "params": {"endpoint": "/tmp/client.sock"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_unsubscribe(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify subscriber was removed
        assert_equal(get_subscriber_count(*manager), 0, "Should have 0 subscribers");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        found_unsub, unsub_val := table_find(resp.response.result.object, "unsubscribed");
        assert_true(found_unsub, "Response should have 'unsubscribed' field");
        assert_true(unsub_val.boolean, "Unsubscribed should be true");
    }

    return all_tests_passed(state);
}

test_handle_unsubscribe_not_found :: () -> bool {
    state := init_test_state("test_handle_unsubscribe_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Try to unsubscribe non-existent endpoint
        json := #string END
{"jsonrpc": "2.0", "method": "unsubscribe", "params": {"endpoint": "/tmp/nonexistent.sock"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_unsubscribe(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed (but indicate not unsubscribed)");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        found_unsub, unsub_val := table_find(resp.response.result.object, "unsubscribed");
        assert_true(found_unsub, "Response should have 'unsubscribed' field");
        assert_false(unsub_val.boolean, "Unsubscribed should be false");
    }

    return all_tests_passed(state);
}

test_handle_unsubscribe_missing_endpoint :: () -> bool {
    state := init_test_state("test_handle_unsubscribe_missing_endpoint", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Request with missing endpoint
        json := #string END
{"jsonrpc": "2.0", "method": "unsubscribe", "params": {}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_unsubscribe(*manager, *msg.request);
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
// Router Tests
// ============================================================================

test_route_subscription_method :: () -> bool {
    state := init_test_state("test_route_subscription_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Test routing subscribe
        json := #string END
{"jsonrpc": "2.0", "method": "subscribe", "params": {"endpoint": "/tmp/test.sock", "events": ["context.changed"]}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_subscription_method(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Router should succeed for subscribe");
    }

    return all_tests_passed(state);
}

test_route_subscription_unknown_method :: () -> bool {
    state := init_test_state("test_route_subscription_unknown_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager: Subscription_Manager;
        init_subscription_manager(*manager);
        defer destroy_subscription_manager(*manager);

        // Test routing unknown method
        json := #string END
{"jsonrpc": "2.0", "method": "subscription.list", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_subscription_method(*manager, *msg.request);
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

test_is_subscription_method :: () -> bool {
    state := init_test_state("test_is_subscription_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_subscription_method("subscribe"), "subscribe should be a subscription method");
        assert_true(is_subscription_method("unsubscribe"), "unsubscribe should be a subscription method");
        assert_false(is_subscription_method("context.get"), "context.get should not be a subscription method");
        assert_false(is_subscription_method("service.register"), "service.register should not be a subscription method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_subscriber_to_json :: () -> bool {
    state := init_test_state("test_subscriber_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create a subscriber
        sub: Subscriber;
        sub.endpoint = copy_string("/tmp/client.sock");
        array_add(*sub.events, copy_string("context.changed"));
        array_add(*sub.events, copy_string("tags.updated"));
        defer free_subscriber(*sub);

        // Convert to JSON
        json := subscriber_to_json(*sub);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "Should be an object");

        // Check fields
        found_ep, ep_val := table_find(json.object, "endpoint");
        assert_true(found_ep, "Should have endpoint");
        assert_string_equal(ep_val.str, "/tmp/client.sock", "endpoint should match");

        // Check events
        found_events, events_val := table_find(json.object, "events");
        assert_true(found_events, "Should have events");
        assert_equal(events_val.array.count, 2, "Should have 2 events");
    }

    return all_tests_passed(state);
}

test_json_to_subscriber :: () -> bool {
    state := init_test_state("test_json_to_subscriber", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create JSON object
        json_str := #string END
{"endpoint": "/tmp/test.sock", "events": ["context.changed", "tags.updated"]}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert to subscriber
        sub, parse_ok, parse_error := json_to_subscriber(json);
        defer if parse_ok then free_subscriber(*sub);

        assert_true(parse_ok, "Should parse successfully");
        assert_string_equal(sub.endpoint, "/tmp/test.sock", "endpoint should match");
        assert_equal(sub.events.count, 2, "Should have 2 events");
    }

    return all_tests_passed(state);
}

test_json_to_subscriber_missing_required :: () -> bool {
    state := init_test_state("test_json_to_subscriber_missing_required", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Missing 'events' field
        json_str := #string END
{"endpoint": "/tmp/test.sock"}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert should fail
        sub, parse_ok, parse_error := json_to_subscriber(json);

        assert_false(parse_ok, "Should fail to parse with missing events");
        assert_true(parse_error.count > 0, "Should have error message");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_subscription_api_tests :: (register: (string, () -> bool, string)) {
    // Manager tests
    register("subscription_api/manager_init", test_subscription_manager_init, "unit");
    register("subscription_api/manager_subscribe", test_subscription_manager_subscribe, "unit");
    register("subscription_api/manager_subscribe_update", test_subscription_manager_subscribe_update, "unit");
    register("subscription_api/manager_subscribe_empty_endpoint", test_subscription_manager_subscribe_empty_endpoint, "unit");
    register("subscription_api/manager_unsubscribe", test_subscription_manager_unsubscribe, "unit");
    register("subscription_api/manager_unsubscribe_not_found", test_subscription_manager_unsubscribe_not_found, "unit");
    register("subscription_api/manager_get_all", test_subscription_manager_get_all, "unit");
    register("subscription_api/manager_get_for_event", test_subscription_manager_get_for_event, "unit");
    register("subscription_api/manager_wildcard", test_subscription_manager_wildcard_matching, "unit");
    register("subscription_api/manager_heartbeat", test_subscription_manager_heartbeat, "unit");

    // Handler tests
    register("subscription_api/handle_subscribe", test_handle_subscribe, "unit");
    register("subscription_api/handle_subscribe_update", test_handle_subscribe_update, "unit");
    register("subscription_api/handle_subscribe_missing_endpoint", test_handle_subscribe_missing_endpoint, "unit");
    register("subscription_api/handle_subscribe_missing_events", test_handle_subscribe_missing_events, "unit");
    register("subscription_api/handle_subscribe_invalid_events", test_handle_subscribe_invalid_events, "unit");
    register("subscription_api/handle_unsubscribe", test_handle_unsubscribe, "unit");
    register("subscription_api/handle_unsubscribe_not_found", test_handle_unsubscribe_not_found, "unit");
    register("subscription_api/handle_unsubscribe_missing", test_handle_unsubscribe_missing_endpoint, "unit");

    // Router tests
    register("subscription_api/route_method", test_route_subscription_method, "unit");
    register("subscription_api/route_unknown", test_route_subscription_unknown_method, "unit");
    register("subscription_api/is_subscription_method", test_is_subscription_method, "unit");

    // JSON conversion tests
    register("subscription_api/subscriber_to_json", test_subscriber_to_json, "unit");
    register("subscription_api/json_to_subscriber", test_json_to_subscriber, "unit");
    register("subscription_api/json_to_subscriber_missing", test_json_to_subscriber_missing_required, "unit");
}
