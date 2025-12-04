// Event Dispatcher Tests
//
// Tests for the event dispatching system.
// Tests event type helpers, dispatch results, context change params,
// statistics, and JSON conversion.
//
// Note: Modules are loaded by the test runner in proper order.
// This file loads the event dispatcher module which depends on:
// - context_store.jai (already loaded)
// - ipc.jai (already loaded)
// - rpc/protocol.jai (already loaded)
// - api/context.jai (already loaded)
// - api/subscription.jai (already loaded)

#load "../../src/daemon/events/dispatcher.jai";

// Registration function for test framework
register_event_dispatcher_tests :: (register: (name: string, proc: () -> bool, category: string)) {
    // Initialization tests
    register("dispatcher/init", test_dispatcher_init, "unit");
    register("dispatcher/default_config", test_dispatcher_default_config, "unit");
    register("dispatcher/destroy", test_dispatcher_destroy, "unit");

    // Event type helper tests
    register("dispatcher/event_type_to_name", test_event_type_to_name, "unit");
    register("dispatcher/name_to_event_type", test_name_to_event_type, "unit");
    register("dispatcher/notification_method", test_event_type_to_notification_method, "unit");

    // Dispatch result tests
    register("dispatcher/no_subscribers", test_dispatch_result_no_subscribers, "unit");
    register("dispatcher/unavailable_subscriber", test_dispatch_result_with_unavailable_subscriber, "unit");
    register("dispatcher/matching_subscribers", test_dispatch_only_to_matching_subscribers, "unit");

    // Context changed params tests
    register("dispatcher/context_changed_params", test_build_context_changed_params, "unit");

    // Statistics tests
    register("dispatcher/stats_initial", test_dispatcher_stats_initial, "unit");
    register("dispatcher/stats_after_dispatch", test_dispatcher_stats_after_dispatch, "unit");
    register("dispatcher/stats_reset", test_dispatcher_stats_reset, "unit");

    // Delivery status tests
    register("dispatcher/delivery_status_string", test_delivery_status_to_string, "unit");
    register("dispatcher/string_delivery_status", test_string_to_delivery_status, "unit");

    // JSON conversion tests
    register("dispatcher/stats_to_json", test_dispatcher_stats_to_json, "unit");
    register("dispatcher/result_to_json", test_dispatch_result_to_json, "unit");
    register("dispatcher/delivery_to_json", test_delivery_result_to_json, "unit");

    // Memory management tests
    register("dispatcher/free_dispatch_result", test_free_dispatch_result, "unit");
    register("dispatcher/free_delivery_result", test_free_delivery_result, "unit");
}

// ============================================================================
// Test State Helper
// ============================================================================

Dispatcher_Test_State :: struct {
    passed: int;
    failed: int;
}

dispatcher_assert :: (state: *Dispatcher_Test_State, condition: bool, message: string) {
    if condition {
        state.passed += 1;
    } else {
        state.failed += 1;
        print("  ASSERTION FAILED: %\n", message);
    }
}

// ============================================================================
// Dispatcher Initialization Tests
// ============================================================================

test_dispatcher_init :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    dispatcher_assert(*state, dispatcher.initialized, "Dispatcher should be initialized");
    dispatcher_assert(*state, dispatcher.subscription_manager == *sub_manager, "Subscription manager pointer should be set");

    return state.failed == 0;
}

test_dispatcher_default_config :: () -> bool {
    state: Dispatcher_Test_State;

    config := create_default_dispatcher_config();

    dispatcher_assert(*state, config.connect_timeout_ms == 1000, "Default connect timeout should be 1000ms");
    dispatcher_assert(*state, config.send_timeout_ms == 5000, "Default send timeout should be 5000ms");
    dispatcher_assert(*state, !config.retry_on_failure, "Default retry_on_failure should be false");
    dispatcher_assert(*state, !config.async_dispatch, "Default async_dispatch should be false");

    return state.failed == 0;
}

test_dispatcher_destroy :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    init_event_dispatcher(*dispatcher, *sub_manager);

    destroy_event_dispatcher(*dispatcher);

    dispatcher_assert(*state, !dispatcher.initialized, "Dispatcher should not be initialized after destroy");

    destroy_subscription_manager(*sub_manager);
    return state.failed == 0;
}

// ============================================================================
// Event Type Helper Tests
// ============================================================================

test_event_type_to_name :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher_assert(*state, event_type_to_name(.CONTEXT_CHANGED) == "context.changed", "CONTEXT_CHANGED");
    dispatcher_assert(*state, event_type_to_name(.SERVICE_REGISTERED) == "service.registered", "SERVICE_REGISTERED");
    dispatcher_assert(*state, event_type_to_name(.SERVICE_UNREGISTERED) == "service.unregistered", "SERVICE_UNREGISTERED");
    dispatcher_assert(*state, event_type_to_name(.SUBSCRIBER_ADDED) == "subscriber.added", "SUBSCRIBER_ADDED");
    dispatcher_assert(*state, event_type_to_name(.SUBSCRIBER_REMOVED) == "subscriber.removed", "SUBSCRIBER_REMOVED");
    dispatcher_assert(*state, event_type_to_name(.DAEMON_STARTING) == "daemon.starting", "DAEMON_STARTING");
    dispatcher_assert(*state, event_type_to_name(.DAEMON_STOPPING) == "daemon.stopping", "DAEMON_STOPPING");
    dispatcher_assert(*state, event_type_to_name(.UNKNOWN) == "unknown", "UNKNOWN");

    return state.failed == 0;
}

test_name_to_event_type :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher_assert(*state, name_to_event_type("context.changed") == .CONTEXT_CHANGED, "context.changed");
    dispatcher_assert(*state, name_to_event_type("service.registered") == .SERVICE_REGISTERED, "service.registered");
    dispatcher_assert(*state, name_to_event_type("service.unregistered") == .SERVICE_UNREGISTERED, "service.unregistered");
    dispatcher_assert(*state, name_to_event_type("invalid.event") == .UNKNOWN, "invalid.event");

    return state.failed == 0;
}

test_event_type_to_notification_method :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher_assert(*state, event_type_to_notification_method(.CONTEXT_CHANGED) == "notify.contextChanged", "CONTEXT_CHANGED method");
    dispatcher_assert(*state, event_type_to_notification_method(.SERVICE_REGISTERED) == "notify.serviceRegistered", "SERVICE_REGISTERED method");

    return state.failed == 0;
}

// ============================================================================
// Dispatch Result Tests
// ============================================================================

test_dispatch_result_no_subscribers :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    // Dispatch with no subscribers
    params := json_object();
    defer jason.json_free(params);

    result := dispatch_event(*dispatcher, .CONTEXT_CHANGED, params);
    defer free_dispatch_result(*result);

    dispatcher_assert(*state, result.total_subscribers == 0, "Should have 0 subscribers");
    dispatcher_assert(*state, result.successful_deliveries == 0, "Should have 0 successful deliveries");
    dispatcher_assert(*state, result.failed_deliveries == 0, "Should have 0 failed deliveries");

    return state.failed == 0;
}

test_dispatch_result_with_unavailable_subscriber :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    // Add a subscriber with a non-existent endpoint
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/nonexistent_test_socket.sock", events);

    // Dispatch
    params := json_object();
    defer jason.json_free(params);

    result := dispatch_event(*dispatcher, .CONTEXT_CHANGED, params);
    defer free_dispatch_result(*result);

    dispatcher_assert(*state, result.total_subscribers == 1, "Should have 1 subscriber");
    dispatcher_assert(*state, result.successful_deliveries == 0, "Should have 0 successful deliveries");
    dispatcher_assert(*state, result.failed_deliveries == 1, "Should have 1 failed delivery");
    dispatcher_assert(*state, result.results.count == 1, "Should have 1 result");
    dispatcher_assert(*state, result.results[0].status == .ENDPOINT_UNAVAILABLE, "Status should be ENDPOINT_UNAVAILABLE");

    return state.failed == 0;
}

test_dispatch_only_to_matching_subscribers :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    // Add subscribers for different events
    context_events: [1] string;
    context_events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/context_sub.sock", context_events);

    service_events: [1] string;
    service_events[0] = "service.registered";
    subscribe(*sub_manager, "/tmp/service_sub.sock", service_events);

    // Dispatch context.changed - only context subscriber should be hit
    params := json_object();
    defer jason.json_free(params);

    result := dispatch_event(*dispatcher, .CONTEXT_CHANGED, params);
    defer free_dispatch_result(*result);

    dispatcher_assert(*state, result.total_subscribers == 1, tprint("Should have 1 matching subscriber, got %", result.total_subscribers));

    return state.failed == 0;
}

// ============================================================================
// Context Changed Params Tests
// ============================================================================

test_build_context_changed_params :: () -> bool {
    state: Dispatcher_Test_State;

    prev: Context;
    prev.project_id = "old-project";
    prev.profile = "default";
    prev.environment = "dev";
    prev.version = 1;

    curr: Context;
    curr.project_id = "new-project";
    curr.profile = "default";
    curr.environment = "prod";
    curr.version = 2;

    change: Context_Change;
    change.previous_version = 1;
    change.new_version = 2;
    array_add(*change.changed_fields, "project_id");
    array_add(*change.changed_fields, "environment");
    defer array_free(change.changed_fields);

    params := build_context_changed_params(*prev, *curr, *change);
    defer jason.json_free(params);

    // Verify params structure
    dispatcher_assert(*state, params.type == .OBJECT, "Params should be an object");

    {
        // Check previous context
        found, prev_val := table_find(params.object, "previous");
        dispatcher_assert(*state, found, "Should have 'previous' field");
        dispatcher_assert(*state, prev_val.type == .OBJECT, "'previous' should be an object");
    }

    {
        // Check current context
        found, curr_val := table_find(params.object, "current");
        dispatcher_assert(*state, found, "Should have 'current' field");
        dispatcher_assert(*state, curr_val.type == .OBJECT, "'current' should be an object");
    }

    {
        // Check changed_fields
        found, changed_val := table_find(params.object, "changed_fields");
        dispatcher_assert(*state, found, "Should have 'changed_fields' field");
        dispatcher_assert(*state, changed_val.type == .ARRAY, "'changed_fields' should be an array");
        dispatcher_assert(*state, changed_val.array.count == 2, tprint("'changed_fields' should have 2 items, got %", changed_val.array.count));
    }

    {
        // Check version
        found, version_val := table_find(params.object, "version");
        dispatcher_assert(*state, found, "Should have 'version' field");
        dispatcher_assert(*state, version_val.type == .NUMBER, "'version' should be a number");
        dispatcher_assert(*state, cast(int) version_val.number == 2, tprint("'version' should be 2, got %", cast(int) version_val.number));
    }

    return state.failed == 0;
}

// ============================================================================
// Dispatcher Statistics Tests
// ============================================================================

test_dispatcher_stats_initial :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    stats := get_dispatcher_stats(*dispatcher);

    dispatcher_assert(*state, stats.total_events_dispatched == 0, "Initial total_events_dispatched should be 0");
    dispatcher_assert(*state, stats.total_deliveries_attempted == 0, "Initial total_deliveries_attempted should be 0");
    dispatcher_assert(*state, stats.success_rate == 0.0, "Initial success_rate should be 0.0");

    return state.failed == 0;
}

test_dispatcher_stats_after_dispatch :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    // Add a subscriber (will fail to connect)
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/test_stats.sock", events);

    // Dispatch event
    params := json_object();
    defer jason.json_free(params);

    result := dispatch_event(*dispatcher, .CONTEXT_CHANGED, params);
    defer free_dispatch_result(*result);

    stats := get_dispatcher_stats(*dispatcher);

    dispatcher_assert(*state, stats.total_events_dispatched == 1, "total_events_dispatched should be 1");
    dispatcher_assert(*state, stats.total_deliveries_attempted == 1, "total_deliveries_attempted should be 1");
    dispatcher_assert(*state, stats.total_deliveries_failed == 1, "total_deliveries_failed should be 1");

    return state.failed == 0;
}

test_dispatcher_stats_reset :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher: Event_Dispatcher;
    sub_manager: Subscription_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_event_dispatcher(*dispatcher, *sub_manager);
    defer destroy_event_dispatcher(*dispatcher);

    // Add a subscriber and dispatch
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/test_reset.sock", events);

    params := json_object();
    result := dispatch_event(*dispatcher, .CONTEXT_CHANGED, params);
    jason.json_free(params);
    free_dispatch_result(*result);

    // Reset stats
    reset_dispatcher_stats(*dispatcher);

    stats := get_dispatcher_stats(*dispatcher);

    dispatcher_assert(*state, stats.total_events_dispatched == 0, "total_events_dispatched should be 0 after reset");
    dispatcher_assert(*state, stats.total_deliveries_attempted == 0, "total_deliveries_attempted should be 0 after reset");

    return state.failed == 0;
}

// ============================================================================
// Delivery Status Tests
// ============================================================================

test_delivery_status_to_string :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher_assert(*state, delivery_status_to_string(.PENDING) == "pending", "PENDING");
    dispatcher_assert(*state, delivery_status_to_string(.DELIVERED) == "delivered", "DELIVERED");
    dispatcher_assert(*state, delivery_status_to_string(.FAILED) == "failed", "FAILED");
    dispatcher_assert(*state, delivery_status_to_string(.TIMEOUT) == "timeout", "TIMEOUT");
    dispatcher_assert(*state, delivery_status_to_string(.ENDPOINT_UNAVAILABLE) == "endpoint_unavailable", "ENDPOINT_UNAVAILABLE");

    return state.failed == 0;
}

test_string_to_delivery_status :: () -> bool {
    state: Dispatcher_Test_State;

    dispatcher_assert(*state, string_to_delivery_status("pending") == .PENDING, "pending");
    dispatcher_assert(*state, string_to_delivery_status("delivered") == .DELIVERED, "delivered");
    dispatcher_assert(*state, string_to_delivery_status("failed") == .FAILED, "failed");
    dispatcher_assert(*state, string_to_delivery_status("invalid") == .PENDING, "invalid should map to PENDING");

    return state.failed == 0;
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_dispatcher_stats_to_json :: () -> bool {
    state: Dispatcher_Test_State;

    stats: Dispatcher_Stats;
    stats.total_events_dispatched = 100;
    stats.total_deliveries_attempted = 150;
    stats.total_deliveries_successful = 140;
    stats.total_deliveries_failed = 10;
    stats.success_rate = 0.933;

    json := dispatcher_stats_to_json(*stats);
    defer jason.json_free(json);

    dispatcher_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "total_events_dispatched");
    dispatcher_assert(*state, found && cast(int) val.number == 100, "total_events_dispatched should be 100");

    found, val = table_find(json.object, "success_rate");
    dispatcher_assert(*state, found, "Should have success_rate field");

    return state.failed == 0;
}

test_dispatch_result_to_json :: () -> bool {
    state: Dispatcher_Test_State;

    result: Dispatch_Result;
    result.event_name = "context.changed";
    result.total_subscribers = 2;
    result.successful_deliveries = 1;
    result.failed_deliveries = 1;

    delivery1: Delivery_Result;
    delivery1.endpoint = "/tmp/sub1.sock";
    delivery1.status = .DELIVERED;
    array_add(*result.results, delivery1);

    delivery2: Delivery_Result;
    delivery2.endpoint = "/tmp/sub2.sock";
    delivery2.status = .FAILED;
    delivery2.error_message = "Connection refused";
    array_add(*result.results, delivery2);

    json := dispatch_result_to_json(*result);
    defer jason.json_free(json);
    defer array_free(result.results);  // Don't free strings since they're literals

    dispatcher_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "event_name");
    dispatcher_assert(*state, found && val.str == "context.changed", "event_name should be 'context.changed'");

    found, val = table_find(json.object, "results");
    dispatcher_assert(*state, found && val.type == .ARRAY && val.array.count == 2, "Should have results array with 2 items");

    return state.failed == 0;
}

test_delivery_result_to_json :: () -> bool {
    state: Dispatcher_Test_State;

    result: Delivery_Result;
    result.endpoint = "/tmp/test.sock";
    result.status = .FAILED;
    result.error_message = "Connection refused";
    result.latency_ms = 12.5;

    json := delivery_result_to_json(*result);
    defer jason.json_free(json);

    dispatcher_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "endpoint");
    dispatcher_assert(*state, found && val.str == "/tmp/test.sock", "endpoint should be '/tmp/test.sock'");

    found, val = table_find(json.object, "status");
    dispatcher_assert(*state, found && val.str == "failed", "status should be 'failed'");

    found, val = table_find(json.object, "error_message");
    dispatcher_assert(*state, found && val.str == "Connection refused", "error_message should be 'Connection refused'");

    return state.failed == 0;
}

// ============================================================================
// Memory Management Tests
// ============================================================================

test_free_dispatch_result :: () -> bool {
    state: Dispatcher_Test_State;

    result: Dispatch_Result;
    result.event_name = copy_string("test.event");
    result.total_subscribers = 1;

    delivery: Delivery_Result;
    delivery.endpoint = copy_string("/tmp/test.sock");
    delivery.status = .FAILED;
    delivery.error_message = copy_string("Test error");
    array_add(*result.results, delivery);

    // Should not crash
    free_dispatch_result(*result);

    dispatcher_assert(*state, true, "Should not crash freeing dispatch result");
    return state.failed == 0;
}

test_free_delivery_result :: () -> bool {
    state: Dispatcher_Test_State;

    result: Delivery_Result;
    result.endpoint = copy_string("/tmp/test.sock");
    result.status = .DELIVERED;
    result.error_message = "";  // Empty string - should not crash

    // Should not crash
    free_delivery_result(*result);

    dispatcher_assert(*state, true, "Should not crash freeing delivery result");
    return state.failed == 0;
}
