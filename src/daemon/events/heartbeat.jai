// Heartbeat Manager
//
// This module implements automatic heartbeat monitoring and cleanup for:
// - Subscribers: Clients that have subscribed to events
// - Services: Registered services that provide functionality
//
// The heartbeat system:
// - Tracks last_heartbeat timestamps for all subscribers and services
// - Identifies stale connections that haven't sent a heartbeat within the timeout
// - Provides cleanup functions to remove stale connections
// - Integrates with Event_Dispatcher to notify when connections are removed
//
// Usage:
// 1. Create a Heartbeat_Manager with init_heartbeat_manager()
// 2. Call run_heartbeat_check() periodically (e.g., every heartbeat_interval_seconds)
// 3. The manager will automatically clean up stale connections and dispatch events

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - api/subscription.jai (Subscription_Manager, Subscriber)
// - api/service.jai (Service_Registry, Registered_Service)
// - events/dispatcher.jai (Event_Dispatcher)

// ============================================================================
// Heartbeat Configuration
// ============================================================================

Heartbeat_Config :: struct {
    // How often to check for stale connections (in seconds)
    check_interval_seconds: s64;

    // How long before a subscriber is considered stale (in seconds)
    subscriber_timeout_seconds: s64;

    // How long before a service is considered stale (in seconds)
    service_timeout_seconds: s64;
}

// Create default heartbeat configuration
create_default_heartbeat_config :: () -> Heartbeat_Config {
    config: Heartbeat_Config;
    config.check_interval_seconds = 30;
    config.subscriber_timeout_seconds = 90;
    config.service_timeout_seconds = 90;
    return config;
}

// ============================================================================
// Stale Connection Types
// ============================================================================

// A subscriber that has gone stale
Stale_Subscriber :: struct {
    endpoint: string;
    last_heartbeat: Apollo_Time;
    seconds_since_heartbeat: s64;
}

// A service that has gone stale
Stale_Service :: struct {
    id: string;
    name: string;
    endpoint: string;
    last_heartbeat: Apollo_Time;
    seconds_since_heartbeat: s64;
}

// Result of a heartbeat check
Heartbeat_Check_Result :: struct {
    stale_subscribers: [..] Stale_Subscriber;
    stale_services: [..] Stale_Service;

    // Statistics
    total_subscribers_checked: int;
    total_services_checked: int;

    // Cleanup results (if cleanup was performed)
    subscribers_removed: int;
    services_removed: int;
}

// ============================================================================
// Heartbeat Manager
// ============================================================================

Heartbeat_Manager :: struct {
    config: Heartbeat_Config;

    // References to managers (not owned)
    subscription_manager: *Subscription_Manager;
    service_registry: *Service_Registry;
    dispatcher: *Event_Dispatcher;  // Optional - for dispatching removal events

    // Statistics
    stats: Heartbeat_Stats;
    stats_mutex: Mutex;

    // State
    last_check_time: Apollo_Time;
    initialized: bool;
}

Heartbeat_Stats :: struct {
    total_checks: int;
    total_stale_subscribers_found: int;
    total_stale_services_found: int;
    total_subscribers_cleaned: int;
    total_services_cleaned: int;
}

// Initialize the heartbeat manager
init_heartbeat_manager :: (manager: *Heartbeat_Manager,
                            config: Heartbeat_Config,
                            subscription_manager: *Subscription_Manager,
                            service_registry: *Service_Registry,
                            dispatcher: *Event_Dispatcher = null) {
    manager.config = config;
    manager.subscription_manager = subscription_manager;
    manager.service_registry = service_registry;
    manager.dispatcher = dispatcher;

    init(*manager.stats_mutex);

    manager.last_check_time = current_time_consensus();
    manager.initialized = true;
}

// Destroy the heartbeat manager
destroy_heartbeat_manager :: (manager: *Heartbeat_Manager) {
    if !manager.initialized return;

    destroy(*manager.stats_mutex);
    manager.initialized = false;
}

// ============================================================================
// Stale Connection Detection
// ============================================================================

// Check for stale subscribers (does not remove them)
// Returns an array of stale subscribers
check_stale_subscribers :: (manager: *Heartbeat_Manager) -> [..] Stale_Subscriber {
    result: [..] Stale_Subscriber;

    if manager.subscription_manager == null {
        return result;
    }

    now := current_time_consensus();
    timeout_apollo := seconds_to_apollo(manager.config.subscriber_timeout_seconds);

    // Get all subscribers
    subscribers := get_all_subscribers(manager.subscription_manager);
    defer free_subscribers_array(*subscribers);

    for *subscribers {
        // Calculate time since last heartbeat using Apollo_Time arithmetic
        elapsed := now - it.last_heartbeat;

        if compare_apollo_times(elapsed, timeout_apollo) > 0 {
            stale: Stale_Subscriber;
            stale.endpoint = copy_string(it.endpoint);
            stale.last_heartbeat = it.last_heartbeat;
            elapsed_seconds, _ := to_seconds(elapsed);
            stale.seconds_since_heartbeat = elapsed_seconds;

            array_add(*result, stale);
        }
    }

    return result;
}

// Check for stale services (does not remove them)
// Returns an array of stale services
check_stale_services :: (manager: *Heartbeat_Manager) -> [..] Stale_Service {
    result: [..] Stale_Service;

    if manager.service_registry == null {
        return result;
    }

    now := current_time_consensus();
    timeout_apollo := seconds_to_apollo(manager.config.service_timeout_seconds);

    // Get all services
    services := get_all_services(manager.service_registry);
    defer free_services_array(*services);

    for *services {
        // Calculate time since last heartbeat using Apollo_Time arithmetic
        elapsed := now - it.last_heartbeat;

        if compare_apollo_times(elapsed, timeout_apollo) > 0 {
            stale: Stale_Service;
            stale.id = copy_string(it.id);
            stale.name = copy_string(it.name);
            stale.endpoint = copy_string(it.endpoint);
            stale.last_heartbeat = it.last_heartbeat;
            elapsed_seconds, _ := to_seconds(elapsed);
            stale.seconds_since_heartbeat = elapsed_seconds;

            array_add(*result, stale);
        }
    }

    return result;
}

// ============================================================================
// Cleanup Functions
// ============================================================================

// Remove a stale subscriber
// Returns true if the subscriber was found and removed
remove_stale_subscriber :: (manager: *Heartbeat_Manager, endpoint: string) -> bool {
    if manager.subscription_manager == null {
        return false;
    }

    success := unsubscribe(manager.subscription_manager, endpoint);

    if success {
        // Dispatch event if we have a dispatcher
        if manager.dispatcher != null {
            dispatch_subscriber_removed(manager.dispatcher, endpoint);
        }

        // Update statistics
        lock(*manager.stats_mutex);
        manager.stats.total_subscribers_cleaned += 1;
        unlock(*manager.stats_mutex);
    }

    return success;
}

// Remove a stale service
// Returns true if the service was found and removed
remove_stale_service :: (manager: *Heartbeat_Manager, service_id: string) -> bool {
    if manager.service_registry == null {
        return false;
    }

    // Get service info for event dispatch before removal
    service, found := get_service(manager.service_registry, service_id);

    success := unregister_service(manager.service_registry, service_id);

    if success {
        // Dispatch event if we have a dispatcher
        if manager.dispatcher != null {
            result := dispatch_service_unregistered(manager.dispatcher, service_id);
            free_dispatch_result(*result);
        }
        if found {
            free_registered_service(*service);
        }

        // Update statistics
        lock(*manager.stats_mutex);
        manager.stats.total_services_cleaned += 1;
        unlock(*manager.stats_mutex);
    } else {
        if found {
            free_registered_service(*service);
        }
    }

    return success;
}

// Cleanup all stale subscribers
// Returns the number of subscribers removed
cleanup_stale_subscribers :: (manager: *Heartbeat_Manager) -> int {
    stale := check_stale_subscribers(manager);
    defer free_stale_subscribers_array(*stale);

    removed := 0;
    for *stale {
        if remove_stale_subscriber(manager, it.endpoint) {
            removed += 1;
        }
    }

    return removed;
}

// Cleanup all stale services
// Returns the number of services removed
cleanup_stale_services :: (manager: *Heartbeat_Manager) -> int {
    stale := check_stale_services(manager);
    defer free_stale_services_array(*stale);

    removed := 0;
    for *stale {
        if remove_stale_service(manager, it.id) {
            removed += 1;
        }
    }

    return removed;
}

// ============================================================================
// Main Heartbeat Check
// ============================================================================

// Run a full heartbeat check (detect and optionally cleanup stale connections)
// If cleanup is true, stale connections will be removed
// Returns a result struct with details about what was found/cleaned
run_heartbeat_check :: (manager: *Heartbeat_Manager, cleanup: bool = true) -> Heartbeat_Check_Result {
    result: Heartbeat_Check_Result;

    // Get counts before check
    result.total_subscribers_checked = get_subscriber_count(manager.subscription_manager);
    result.total_services_checked = get_service_count(manager.service_registry);

    // Check for stale connections
    result.stale_subscribers = check_stale_subscribers(manager);
    result.stale_services = check_stale_services(manager);

    // Update statistics
    lock(*manager.stats_mutex);
    manager.stats.total_checks += 1;
    manager.stats.total_stale_subscribers_found += result.stale_subscribers.count;
    manager.stats.total_stale_services_found += result.stale_services.count;
    unlock(*manager.stats_mutex);

    // Cleanup if requested
    if cleanup {
        // Remove stale subscribers
        for *result.stale_subscribers {
            if remove_stale_subscriber(manager, it.endpoint) {
                result.subscribers_removed += 1;
            }
        }

        // Remove stale services
        for *result.stale_services {
            if remove_stale_service(manager, it.id) {
                result.services_removed += 1;
            }
        }
    }

    // Update last check time
    manager.last_check_time = current_time_consensus();

    return result;
}

// Check if it's time to run a heartbeat check based on the check interval
should_run_heartbeat_check :: (manager: *Heartbeat_Manager) -> bool {
    now := current_time_consensus();
    elapsed := now - manager.last_check_time;
    interval_apollo := seconds_to_apollo(manager.config.check_interval_seconds);

    return compare_apollo_times(elapsed, interval_apollo) >= 0;
}

// ============================================================================
// Statistics
// ============================================================================

// Get a copy of the current heartbeat statistics
get_heartbeat_stats :: (manager: *Heartbeat_Manager) -> Heartbeat_Stats {
    lock(*manager.stats_mutex);
    defer unlock(*manager.stats_mutex);

    return manager.stats;
}

// Reset heartbeat statistics
reset_heartbeat_stats :: (manager: *Heartbeat_Manager) {
    lock(*manager.stats_mutex);
    defer unlock(*manager.stats_mutex);

    manager.stats = .{};
}

// ============================================================================
// Memory Management
// ============================================================================

// Free a Stale_Subscriber
free_stale_subscriber :: (stale: *Stale_Subscriber) {
    free(stale.endpoint);
}

// Free an array of Stale_Subscriber
free_stale_subscribers_array :: (stale: *[..] Stale_Subscriber) {
    for *stale.* {
        free_stale_subscriber(it);
    }
    array_free(stale.*);
}

// Free a Stale_Service
free_stale_service :: (stale: *Stale_Service) {
    free(stale.id);
    free(stale.name);
    free(stale.endpoint);
}

// Free an array of Stale_Service
free_stale_services_array :: (stale: *[..] Stale_Service) {
    for *stale.* {
        free_stale_service(it);
    }
    array_free(stale.*);
}

// Free a Heartbeat_Check_Result
free_heartbeat_check_result :: (result: *Heartbeat_Check_Result) {
    free_stale_subscribers_array(*result.stale_subscribers);
    free_stale_services_array(*result.stale_services);
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert Heartbeat_Stats to JSON
heartbeat_stats_to_json :: (stats: *Heartbeat_Stats) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("total_checks"), json_number(cast(float64) stats.total_checks));
    table_set(result.object, copy_string("total_stale_subscribers_found"), json_number(cast(float64) stats.total_stale_subscribers_found));
    table_set(result.object, copy_string("total_stale_services_found"), json_number(cast(float64) stats.total_stale_services_found));
    table_set(result.object, copy_string("total_subscribers_cleaned"), json_number(cast(float64) stats.total_subscribers_cleaned));
    table_set(result.object, copy_string("total_services_cleaned"), json_number(cast(float64) stats.total_services_cleaned));

    return result;
}

// Convert Stale_Subscriber to JSON
stale_subscriber_to_json :: (stale: *Stale_Subscriber) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("endpoint"), jason.json_value(copy_string(stale.endpoint)));
    table_set(result.object, copy_string("last_heartbeat"), json_number(cast(float64) stale.last_heartbeat.low));
    table_set(result.object, copy_string("seconds_since_heartbeat"), json_number(cast(float64) stale.seconds_since_heartbeat));

    return result;
}

// Convert Stale_Service to JSON
stale_service_to_json :: (stale: *Stale_Service) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("id"), jason.json_value(copy_string(stale.id)));
    table_set(result.object, copy_string("name"), jason.json_value(copy_string(stale.name)));
    table_set(result.object, copy_string("endpoint"), jason.json_value(copy_string(stale.endpoint)));
    table_set(result.object, copy_string("last_heartbeat"), json_number(cast(float64) stale.last_heartbeat.low));
    table_set(result.object, copy_string("seconds_since_heartbeat"), json_number(cast(float64) stale.seconds_since_heartbeat));

    return result;
}

// Convert Heartbeat_Check_Result to JSON
heartbeat_check_result_to_json :: (result: *Heartbeat_Check_Result) -> jason.JSON_Value {
    json := json_object();

    // Statistics
    table_set(json.object, copy_string("total_subscribers_checked"), json_number(cast(float64) result.total_subscribers_checked));
    table_set(json.object, copy_string("total_services_checked"), json_number(cast(float64) result.total_services_checked));
    table_set(json.object, copy_string("subscribers_removed"), json_number(cast(float64) result.subscribers_removed));
    table_set(json.object, copy_string("services_removed"), json_number(cast(float64) result.services_removed));

    // Stale subscribers array
    stale_subs: jason.JSON_Value;
    stale_subs.type = .ARRAY;
    stale_subs_dyn: [..] jason.JSON_Value;
    for *result.stale_subscribers {
        array_add(*stale_subs_dyn, stale_subscriber_to_json(it));
    }
    stale_subs.array = stale_subs_dyn;
    table_set(json.object, copy_string("stale_subscribers"), stale_subs);

    // Stale services array
    stale_svcs: jason.JSON_Value;
    stale_svcs.type = .ARRAY;
    stale_svcs_dyn: [..] jason.JSON_Value;
    for *result.stale_services {
        array_add(*stale_svcs_dyn, stale_service_to_json(it));
    }
    stale_svcs.array = stale_svcs_dyn;
    table_set(json.object, copy_string("stale_services"), stale_svcs);

    return json;
}

// Convert Heartbeat_Config to JSON
heartbeat_config_to_json :: (config: *Heartbeat_Config) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("check_interval_seconds"), json_number(cast(float64) config.check_interval_seconds));
    table_set(result.object, copy_string("subscriber_timeout_seconds"), json_number(cast(float64) config.subscriber_timeout_seconds));
    table_set(result.object, copy_string("service_timeout_seconds"), json_number(cast(float64) config.service_timeout_seconds));

    return result;
}
