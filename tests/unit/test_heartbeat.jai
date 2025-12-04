// Heartbeat Manager Tests
//
// Tests for the heartbeat monitoring system.
// Tests stale connection detection, cleanup functions, statistics,
// and JSON conversion.
//
// Note: This file loads the heartbeat module which depends on:
// - context_store.jai (already loaded)
// - ipc.jai (already loaded)
// - rpc/protocol.jai (already loaded)
// - api/context.jai (already loaded)
// - api/subscription.jai (already loaded)
// - api/service.jai (already loaded)
// - events/dispatcher.jai (already loaded)

#load "../../src/daemon/events/heartbeat.jai";

// Registration function for test framework
register_heartbeat_tests :: (register: (name: string, proc: () -> bool, category: string)) {
    // Configuration tests
    register("heartbeat/default_config", test_heartbeat_default_config, "unit");
    register("heartbeat/config_to_json", test_heartbeat_config_to_json, "unit");

    // Manager initialization tests
    register("heartbeat/init", test_heartbeat_manager_init, "unit");
    register("heartbeat/destroy", test_heartbeat_manager_destroy, "unit");

    // Stale subscriber detection tests
    register("heartbeat/no_stale_subscribers", test_no_stale_subscribers, "unit");
    register("heartbeat/detect_stale_subscriber", test_detect_stale_subscriber, "unit");
    register("heartbeat/multiple_stale_subscribers", test_multiple_stale_subscribers, "unit");

    // Stale service detection tests
    register("heartbeat/no_stale_services", test_no_stale_services, "unit");
    register("heartbeat/detect_stale_service", test_detect_stale_service, "unit");

    // Cleanup tests
    register("heartbeat/cleanup_stale_subscriber", test_cleanup_stale_subscriber, "unit");
    register("heartbeat/cleanup_stale_service", test_cleanup_stale_service, "unit");
    register("heartbeat/run_heartbeat_check", test_run_heartbeat_check, "unit");
    register("heartbeat/run_check_no_cleanup", test_run_heartbeat_check_no_cleanup, "unit");

    // Statistics tests
    register("heartbeat/stats_initial", test_heartbeat_stats_initial, "unit");
    register("heartbeat/stats_after_cleanup", test_heartbeat_stats_after_cleanup, "unit");
    register("heartbeat/stats_reset", test_heartbeat_stats_reset, "unit");

    // Should run check tests
    register("heartbeat/should_run_check_false", test_should_run_check_false, "unit");

    // JSON conversion tests
    register("heartbeat/stats_to_json", test_heartbeat_stats_to_json, "unit");
    register("heartbeat/stale_subscriber_to_json", test_stale_subscriber_to_json, "unit");
    register("heartbeat/stale_service_to_json", test_stale_service_to_json, "unit");
    register("heartbeat/check_result_to_json", test_heartbeat_check_result_to_json, "unit");

    // Memory management tests
    register("heartbeat/free_stale_subscriber", test_free_stale_subscriber, "unit");
    register("heartbeat/free_stale_service", test_free_stale_service, "unit");
    register("heartbeat/free_check_result", test_free_heartbeat_check_result, "unit");
}

// ============================================================================
// Test State Helper
// ============================================================================

Heartbeat_Test_State :: struct {
    passed: int;
    failed: int;
}

heartbeat_assert :: (state: *Heartbeat_Test_State, condition: bool, message: string) {
    if condition {
        state.passed += 1;
    } else {
        state.failed += 1;
        print("  ASSERTION FAILED: %\n", message);
    }
}

// ============================================================================
// Configuration Tests
// ============================================================================

test_heartbeat_default_config :: () -> bool {
    state: Heartbeat_Test_State;

    config := create_default_heartbeat_config();

    heartbeat_assert(*state, config.check_interval_seconds == 30, "Default check interval should be 30s");
    heartbeat_assert(*state, config.subscriber_timeout_seconds == 90, "Default subscriber timeout should be 90s");
    heartbeat_assert(*state, config.service_timeout_seconds == 90, "Default service timeout should be 90s");

    return state.failed == 0;
}

test_heartbeat_config_to_json :: () -> bool {
    state: Heartbeat_Test_State;

    config: Heartbeat_Config;
    config.check_interval_seconds = 60;
    config.subscriber_timeout_seconds = 120;
    config.service_timeout_seconds = 180;

    json := heartbeat_config_to_json(*config);
    defer jason.json_free(json);

    heartbeat_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "check_interval_seconds");
    heartbeat_assert(*state, found && cast(int) val.number == 60, "check_interval_seconds should be 60");

    found, val = table_find(json.object, "subscriber_timeout_seconds");
    heartbeat_assert(*state, found && cast(int) val.number == 120, "subscriber_timeout_seconds should be 120");

    found, val = table_find(json.object, "service_timeout_seconds");
    heartbeat_assert(*state, found && cast(int) val.number == 180, "service_timeout_seconds should be 180");

    return state.failed == 0;
}

// ============================================================================
// Manager Initialization Tests
// ============================================================================

test_heartbeat_manager_init :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config := create_default_heartbeat_config();
    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    heartbeat_assert(*state, heartbeat_manager.initialized, "Manager should be initialized");
    heartbeat_assert(*state, heartbeat_manager.subscription_manager == *sub_manager, "Subscription manager pointer should be set");
    heartbeat_assert(*state, heartbeat_manager.service_registry == *service_registry, "Service registry pointer should be set");
    heartbeat_assert(*state, heartbeat_manager.dispatcher == null, "Dispatcher should be null when not provided");

    return state.failed == 0;
}

test_heartbeat_manager_destroy :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    init_service_registry(*service_registry);

    config := create_default_heartbeat_config();
    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);

    destroy_heartbeat_manager(*heartbeat_manager);

    heartbeat_assert(*state, !heartbeat_manager.initialized, "Manager should not be initialized after destroy");

    destroy_service_registry(*service_registry);
    destroy_subscription_manager(*sub_manager);

    return state.failed == 0;
}

// ============================================================================
// Stale Subscriber Detection Tests
// ============================================================================

test_no_stale_subscribers :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config := create_default_heartbeat_config();
    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a fresh subscriber (just registered, so not stale)
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/fresh_subscriber.sock", events);

    stale := check_stale_subscribers(*heartbeat_manager);
    defer free_stale_subscribers_array(*stale);

    heartbeat_assert(*state, stale.count == 0, "Should have no stale subscribers");

    return state.failed == 0;
}

test_detect_stale_subscriber :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    // Use a very short timeout for testing (1 microsecond)
    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;  // 0 seconds = immediate timeout
    config.service_timeout_seconds = 90;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a subscriber
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/stale_subscriber.sock", events);

    // Subscriber should be immediately stale with 0s timeout
    stale := check_stale_subscribers(*heartbeat_manager);
    defer free_stale_subscribers_array(*stale);

    heartbeat_assert(*state, stale.count == 1, tprint("Should have 1 stale subscriber, got %", stale.count));
    if stale.count > 0 {
        heartbeat_assert(*state, stale[0].endpoint == "/tmp/stale_subscriber.sock", "Endpoint should match");
    }

    return state.failed == 0;
}

test_multiple_stale_subscribers :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    // Use 0s timeout for immediate stale detection
    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 90;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add multiple subscribers
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/stale1.sock", events);
    subscribe(*sub_manager, "/tmp/stale2.sock", events);
    subscribe(*sub_manager, "/tmp/stale3.sock", events);

    stale := check_stale_subscribers(*heartbeat_manager);
    defer free_stale_subscribers_array(*stale);

    heartbeat_assert(*state, stale.count == 3, tprint("Should have 3 stale subscribers, got %", stale.count));

    return state.failed == 0;
}

// ============================================================================
// Stale Service Detection Tests
// ============================================================================

test_no_stale_services :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config := create_default_heartbeat_config();
    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a fresh service
    service: Registered_Service;
    service.id = "fresh-service";
    service.name = "Fresh Service";
    service.endpoint = "/tmp/fresh.sock";
    service.capabilities.api_version = "1.0.0";

    register_service(*service_registry, *service);

    stale := check_stale_services(*heartbeat_manager);
    defer free_stale_services_array(*stale);

    heartbeat_assert(*state, stale.count == 0, "Should have no stale services");

    return state.failed == 0;
}

test_detect_stale_service :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    // Use 0s timeout for immediate stale detection
    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 90;
    config.service_timeout_seconds = 0;  // Immediate timeout

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a service
    service: Registered_Service;
    service.id = "stale-service";
    service.name = "Stale Service";
    service.endpoint = "/tmp/stale.sock";
    service.capabilities.api_version = "1.0.0";

    register_service(*service_registry, *service);

    stale := check_stale_services(*heartbeat_manager);
    defer free_stale_services_array(*stale);

    heartbeat_assert(*state, stale.count == 1, tprint("Should have 1 stale service, got %", stale.count));
    if stale.count > 0 {
        heartbeat_assert(*state, stale[0].id == "stale-service", "ID should match");
        heartbeat_assert(*state, stale[0].name == "Stale Service", "Name should match");
    }

    return state.failed == 0;
}

// ============================================================================
// Cleanup Tests
// ============================================================================

test_cleanup_stale_subscriber :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 90;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a subscriber
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/to_cleanup.sock", events);

    heartbeat_assert(*state, get_subscriber_count(*sub_manager) == 1, "Should have 1 subscriber before cleanup");

    // Cleanup
    cleaned := cleanup_stale_subscribers(*heartbeat_manager);

    heartbeat_assert(*state, cleaned == 1, tprint("Should have cleaned 1 subscriber, got %", cleaned));
    heartbeat_assert(*state, get_subscriber_count(*sub_manager) == 0, "Should have 0 subscribers after cleanup");

    return state.failed == 0;
}

test_cleanup_stale_service :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 90;
    config.service_timeout_seconds = 0;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a service
    service: Registered_Service;
    service.id = "to-cleanup";
    service.name = "To Cleanup";
    service.endpoint = "/tmp/cleanup.sock";
    service.capabilities.api_version = "1.0.0";

    register_service(*service_registry, *service);

    heartbeat_assert(*state, get_service_count(*service_registry) == 1, "Should have 1 service before cleanup");

    // Cleanup
    cleaned := cleanup_stale_services(*heartbeat_manager);

    heartbeat_assert(*state, cleaned == 1, tprint("Should have cleaned 1 service, got %", cleaned));
    heartbeat_assert(*state, get_service_count(*service_registry) == 0, "Should have 0 services after cleanup");

    return state.failed == 0;
}

test_run_heartbeat_check :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 0;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a subscriber and service
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/check_sub.sock", events);

    service: Registered_Service;
    service.id = "check-service";
    service.name = "Check Service";
    service.endpoint = "/tmp/check.sock";
    service.capabilities.api_version = "1.0.0";
    register_service(*service_registry, *service);

    // Run check with cleanup
    result := run_heartbeat_check(*heartbeat_manager, cleanup=true);
    defer free_heartbeat_check_result(*result);

    heartbeat_assert(*state, result.total_subscribers_checked == 1, "Should have checked 1 subscriber");
    heartbeat_assert(*state, result.total_services_checked == 1, "Should have checked 1 service");
    heartbeat_assert(*state, result.stale_subscribers.count == 1, "Should have found 1 stale subscriber");
    heartbeat_assert(*state, result.stale_services.count == 1, "Should have found 1 stale service");
    heartbeat_assert(*state, result.subscribers_removed == 1, "Should have removed 1 subscriber");
    heartbeat_assert(*state, result.services_removed == 1, "Should have removed 1 service");

    // Verify they were actually removed
    heartbeat_assert(*state, get_subscriber_count(*sub_manager) == 0, "Should have 0 subscribers after check");
    heartbeat_assert(*state, get_service_count(*service_registry) == 0, "Should have 0 services after check");

    return state.failed == 0;
}

test_run_heartbeat_check_no_cleanup :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 0;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a subscriber
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/no_cleanup.sock", events);

    // Run check WITHOUT cleanup
    result := run_heartbeat_check(*heartbeat_manager, cleanup=false);
    defer free_heartbeat_check_result(*result);

    heartbeat_assert(*state, result.stale_subscribers.count == 1, "Should have found 1 stale subscriber");
    heartbeat_assert(*state, result.subscribers_removed == 0, "Should NOT have removed any subscribers");
    heartbeat_assert(*state, get_subscriber_count(*sub_manager) == 1, "Subscriber should still exist");

    return state.failed == 0;
}

// ============================================================================
// Statistics Tests
// ============================================================================

test_heartbeat_stats_initial :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config := create_default_heartbeat_config();
    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    stats := get_heartbeat_stats(*heartbeat_manager);

    heartbeat_assert(*state, stats.total_checks == 0, "Initial total_checks should be 0");
    heartbeat_assert(*state, stats.total_stale_subscribers_found == 0, "Initial stale subscribers found should be 0");
    heartbeat_assert(*state, stats.total_stale_services_found == 0, "Initial stale services found should be 0");
    heartbeat_assert(*state, stats.total_subscribers_cleaned == 0, "Initial subscribers cleaned should be 0");
    heartbeat_assert(*state, stats.total_services_cleaned == 0, "Initial services cleaned should be 0");

    return state.failed == 0;
}

test_heartbeat_stats_after_cleanup :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 0;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add a subscriber
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/stats_test.sock", events);

    // Run check with cleanup
    result := run_heartbeat_check(*heartbeat_manager, cleanup=true);
    free_heartbeat_check_result(*result);

    stats := get_heartbeat_stats(*heartbeat_manager);

    heartbeat_assert(*state, stats.total_checks == 1, "total_checks should be 1");
    heartbeat_assert(*state, stats.total_stale_subscribers_found == 1, "total_stale_subscribers_found should be 1");
    heartbeat_assert(*state, stats.total_subscribers_cleaned == 1, "total_subscribers_cleaned should be 1");

    return state.failed == 0;
}

test_heartbeat_stats_reset :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 1;
    config.subscriber_timeout_seconds = 0;
    config.service_timeout_seconds = 0;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Add and cleanup a subscriber
    events: [1] string;
    events[0] = "context.changed";
    subscribe(*sub_manager, "/tmp/reset_test.sock", events);

    result := run_heartbeat_check(*heartbeat_manager, cleanup=true);
    free_heartbeat_check_result(*result);

    // Reset stats
    reset_heartbeat_stats(*heartbeat_manager);

    stats := get_heartbeat_stats(*heartbeat_manager);

    heartbeat_assert(*state, stats.total_checks == 0, "total_checks should be 0 after reset");
    heartbeat_assert(*state, stats.total_stale_subscribers_found == 0, "total_stale_subscribers_found should be 0 after reset");

    return state.failed == 0;
}

// ============================================================================
// Should Run Check Tests
// ============================================================================

test_should_run_check_false :: () -> bool {
    state: Heartbeat_Test_State;

    sub_manager: Subscription_Manager;
    service_registry: Service_Registry;
    heartbeat_manager: Heartbeat_Manager;

    init_subscription_manager(*sub_manager);
    defer destroy_subscription_manager(*sub_manager);

    init_service_registry(*service_registry);
    defer destroy_service_registry(*service_registry);

    config: Heartbeat_Config;
    config.check_interval_seconds = 60;  // Long interval
    config.subscriber_timeout_seconds = 90;
    config.service_timeout_seconds = 90;

    init_heartbeat_manager(*heartbeat_manager, config, *sub_manager, *service_registry);
    defer destroy_heartbeat_manager(*heartbeat_manager);

    // Check immediately after init - should not need to run yet
    // (The manager was just initialized, so not enough time has passed)
    should_run := should_run_heartbeat_check(*heartbeat_manager);

    heartbeat_assert(*state, !should_run, "Should not need to run check immediately after init");

    return state.failed == 0;
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_heartbeat_stats_to_json :: () -> bool {
    state: Heartbeat_Test_State;

    stats: Heartbeat_Stats;
    stats.total_checks = 10;
    stats.total_stale_subscribers_found = 5;
    stats.total_stale_services_found = 3;
    stats.total_subscribers_cleaned = 4;
    stats.total_services_cleaned = 2;

    json := heartbeat_stats_to_json(*stats);
    defer jason.json_free(json);

    heartbeat_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "total_checks");
    heartbeat_assert(*state, found && cast(int) val.number == 10, "total_checks should be 10");

    found, val = table_find(json.object, "total_stale_subscribers_found");
    heartbeat_assert(*state, found && cast(int) val.number == 5, "total_stale_subscribers_found should be 5");

    found, val = table_find(json.object, "total_services_cleaned");
    heartbeat_assert(*state, found && cast(int) val.number == 2, "total_services_cleaned should be 2");

    return state.failed == 0;
}

test_stale_subscriber_to_json :: () -> bool {
    state: Heartbeat_Test_State;

    stale: Stale_Subscriber;
    stale.endpoint = "/tmp/stale.sock";
    stale.seconds_since_heartbeat = 120;

    json := stale_subscriber_to_json(*stale);
    defer jason.json_free(json);

    heartbeat_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "endpoint");
    heartbeat_assert(*state, found && val.str == "/tmp/stale.sock", "endpoint should match");

    found, val = table_find(json.object, "seconds_since_heartbeat");
    heartbeat_assert(*state, found && cast(int) val.number == 120, "seconds_since_heartbeat should be 120");

    return state.failed == 0;
}

test_stale_service_to_json :: () -> bool {
    state: Heartbeat_Test_State;

    stale: Stale_Service;
    stale.id = "stale-svc";
    stale.name = "Stale Service";
    stale.endpoint = "/tmp/stale_svc.sock";
    stale.seconds_since_heartbeat = 300;

    json := stale_service_to_json(*stale);
    defer jason.json_free(json);

    heartbeat_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "id");
    heartbeat_assert(*state, found && val.str == "stale-svc", "id should match");

    found, val = table_find(json.object, "name");
    heartbeat_assert(*state, found && val.str == "Stale Service", "name should match");

    found, val = table_find(json.object, "endpoint");
    heartbeat_assert(*state, found && val.str == "/tmp/stale_svc.sock", "endpoint should match");

    return state.failed == 0;
}

test_heartbeat_check_result_to_json :: () -> bool {
    state: Heartbeat_Test_State;

    result: Heartbeat_Check_Result;
    result.total_subscribers_checked = 5;
    result.total_services_checked = 3;
    result.subscribers_removed = 2;
    result.services_removed = 1;

    // Add a stale subscriber
    stale_sub: Stale_Subscriber;
    stale_sub.endpoint = copy_string("/tmp/stale.sock");
    stale_sub.seconds_since_heartbeat = 100;
    array_add(*result.stale_subscribers, stale_sub);

    json := heartbeat_check_result_to_json(*result);
    defer jason.json_free(json);
    defer free_heartbeat_check_result(*result);

    heartbeat_assert(*state, json.type == .OBJECT, "Should return an object");

    found, val := table_find(json.object, "total_subscribers_checked");
    heartbeat_assert(*state, found && cast(int) val.number == 5, "total_subscribers_checked should be 5");

    found, val = table_find(json.object, "stale_subscribers");
    heartbeat_assert(*state, found && val.type == .ARRAY && val.array.count == 1, "stale_subscribers should have 1 entry");

    return state.failed == 0;
}

// ============================================================================
// Memory Management Tests
// ============================================================================

test_free_stale_subscriber :: () -> bool {
    state: Heartbeat_Test_State;

    stale: Stale_Subscriber;
    stale.endpoint = copy_string("/tmp/to_free.sock");
    stale.seconds_since_heartbeat = 60;

    free_stale_subscriber(*stale);

    heartbeat_assert(*state, true, "Should not crash freeing stale subscriber");
    return state.failed == 0;
}

test_free_stale_service :: () -> bool {
    state: Heartbeat_Test_State;

    stale: Stale_Service;
    stale.id = copy_string("to-free");
    stale.name = copy_string("To Free");
    stale.endpoint = copy_string("/tmp/to_free.sock");
    stale.seconds_since_heartbeat = 60;

    free_stale_service(*stale);

    heartbeat_assert(*state, true, "Should not crash freeing stale service");
    return state.failed == 0;
}

test_free_heartbeat_check_result :: () -> bool {
    state: Heartbeat_Test_State;

    result: Heartbeat_Check_Result;
    result.total_subscribers_checked = 1;

    // Add stale entries with allocated strings
    stale_sub: Stale_Subscriber;
    stale_sub.endpoint = copy_string("/tmp/result_free.sock");
    array_add(*result.stale_subscribers, stale_sub);

    stale_svc: Stale_Service;
    stale_svc.id = copy_string("result-free");
    stale_svc.name = copy_string("Result Free");
    stale_svc.endpoint = copy_string("/tmp/result_svc.sock");
    array_add(*result.stale_services, stale_svc);

    free_heartbeat_check_result(*result);

    heartbeat_assert(*state, true, "Should not crash freeing check result");
    return state.failed == 0;
}
