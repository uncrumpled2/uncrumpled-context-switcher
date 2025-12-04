// Event Dispatcher
//
// This module handles dispatching events to subscribed services.
// It integrates with the Subscription_Manager to find subscribers
// and uses IPC to send JSON-RPC notifications to their endpoints.
//
// Events:
// - context.changed: Context state has changed
// - service.registered: A new service registered
// - service.unregistered: A service unregistered
// - subscriber.added: A new subscriber added
// - subscriber.removed: A subscriber removed

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - rpc/protocol.jai (for create_notification, etc.)
// - api/context.jai (for context_to_json, json_object, etc.)
// - api/subscription.jai (for Subscription_Manager, Subscriber)
// - context_store.jai (for Context, Context_Change)
// - ipc.jai (for IPC_Client)

// ============================================================================
// Event Types
// ============================================================================

// Event type enum for categorization
Event_Type :: enum {
    UNKNOWN;

    // Context events
    CONTEXT_CHANGED;

    // Service events
    SERVICE_REGISTERED;
    SERVICE_UNREGISTERED;

    // Subscriber events
    SUBSCRIBER_ADDED;
    SUBSCRIBER_REMOVED;

    // System events
    DAEMON_STARTING;
    DAEMON_STOPPING;
}

// Event delivery status
Delivery_Status :: enum {
    PENDING;
    DELIVERED;
    FAILED;
    TIMEOUT;
    ENDPOINT_UNAVAILABLE;
}

// Result of delivering a single event to a subscriber
Delivery_Result :: struct {
    endpoint: string;
    status: Delivery_Status;
    error_message: string;
    latency_ms: float64;
}

// Result of dispatching an event to all subscribers
Dispatch_Result :: struct {
    event_name: string;
    total_subscribers: int;
    successful_deliveries: int;
    failed_deliveries: int;
    results: [..] Delivery_Result;
}

// Configuration for the dispatcher
Dispatcher_Config :: struct {
    // Timeout for connecting to a subscriber endpoint (milliseconds)
    connect_timeout_ms: s32;

    // Timeout for sending data to a subscriber (milliseconds)
    send_timeout_ms: s32;

    // Whether to retry failed deliveries
    retry_on_failure: bool;

    // Number of retry attempts
    max_retries: int;

    // Whether to dispatch asynchronously (fire and forget)
    async_dispatch: bool;
}

// Event Dispatcher
Event_Dispatcher :: struct {
    subscription_manager: *Subscription_Manager;
    config: Dispatcher_Config;

    // Statistics
    total_events_dispatched: u64;
    total_deliveries_attempted: u64;
    total_deliveries_successful: u64;
    total_deliveries_failed: u64;

    // Thread safety
    mutex: Mutex;
    initialized: bool;
}

// ============================================================================
// Dispatcher Initialization
// ============================================================================

// Create default dispatcher config
create_default_dispatcher_config :: () -> Dispatcher_Config {
    config: Dispatcher_Config;
    config.connect_timeout_ms = 1000;   // 1 second
    config.send_timeout_ms = 5000;      // 5 seconds
    config.retry_on_failure = false;    // No retries by default
    config.max_retries = 0;
    config.async_dispatch = false;      // Synchronous by default
    return config;
}

// Initialize the event dispatcher
init_event_dispatcher :: (dispatcher: *Event_Dispatcher, sub_manager: *Subscription_Manager, config: Dispatcher_Config = .{}) {
    init(*dispatcher.mutex);
    dispatcher.subscription_manager = sub_manager;
    dispatcher.config = config;

    // Use default config if not specified
    if dispatcher.config.connect_timeout_ms == 0 {
        dispatcher.config = create_default_dispatcher_config();
    }

    dispatcher.total_events_dispatched = 0;
    dispatcher.total_deliveries_attempted = 0;
    dispatcher.total_deliveries_successful = 0;
    dispatcher.total_deliveries_failed = 0;
    dispatcher.initialized = true;
}

// Destroy the event dispatcher
destroy_event_dispatcher :: (dispatcher: *Event_Dispatcher) {
    if !dispatcher.initialized return;

    lock(*dispatcher.mutex);
    defer unlock(*dispatcher.mutex);

    destroy(*dispatcher.mutex);
    dispatcher.initialized = false;
}

// ============================================================================
// Event Name Helpers
// ============================================================================

// Get the event name string for an event type
event_type_to_name :: (type: Event_Type) -> string {
    if type == {
        case .CONTEXT_CHANGED;       return "context.changed";
        case .SERVICE_REGISTERED;    return "service.registered";
        case .SERVICE_UNREGISTERED;  return "service.unregistered";
        case .SUBSCRIBER_ADDED;      return "subscriber.added";
        case .SUBSCRIBER_REMOVED;    return "subscriber.removed";
        case .DAEMON_STARTING;       return "daemon.starting";
        case .DAEMON_STOPPING;       return "daemon.stopping";
        case;                        return "unknown";
    }
}

// Get the event type from a name string
name_to_event_type :: (name: string) -> Event_Type {
    if name == "context.changed"       return .CONTEXT_CHANGED;
    if name == "service.registered"    return .SERVICE_REGISTERED;
    if name == "service.unregistered"  return .SERVICE_UNREGISTERED;
    if name == "subscriber.added"      return .SUBSCRIBER_ADDED;
    if name == "subscriber.removed"    return .SUBSCRIBER_REMOVED;
    if name == "daemon.starting"       return .DAEMON_STARTING;
    if name == "daemon.stopping"       return .DAEMON_STOPPING;
    return .UNKNOWN;
}

// Get the notification method name for an event type
event_type_to_notification_method :: (type: Event_Type) -> string {
    if type == {
        case .CONTEXT_CHANGED;       return "notify.contextChanged";
        case .SERVICE_REGISTERED;    return "notify.serviceRegistered";
        case .SERVICE_UNREGISTERED;  return "notify.serviceUnregistered";
        case .SUBSCRIBER_ADDED;      return "notify.subscriberAdded";
        case .SUBSCRIBER_REMOVED;    return "notify.subscriberRemoved";
        case .DAEMON_STARTING;       return "notify.daemonStarting";
        case .DAEMON_STOPPING;       return "notify.daemonStopping";
        case;                        return "notify.unknown";
    }
}

// ============================================================================
// Event Dispatch Functions
// ============================================================================

// Dispatch a context changed event
dispatch_context_changed :: (
    dispatcher: *Event_Dispatcher,
    previous: *Context,
    current: *Context,
    change: *Context_Change
) -> Dispatch_Result {
    // Build notification params
    params := build_context_changed_params(previous, current, change);
    defer jason.json_free(params);

    return dispatch_event(dispatcher, .CONTEXT_CHANGED, params);
}

// Dispatch a service registered event
dispatch_service_registered :: (
    dispatcher: *Event_Dispatcher,
    service_id: string,
    service_name: string,
    endpoint: string
) -> Dispatch_Result {
    // Build notification params
    params := json_object();
    table_set(params.object, copy_string("service_id"), jason.json_value(copy_string(service_id)));
    table_set(params.object, copy_string("service_name"), jason.json_value(copy_string(service_name)));
    table_set(params.object, copy_string("endpoint"), jason.json_value(copy_string(endpoint)));
    defer jason.json_free(params);

    return dispatch_event(dispatcher, .SERVICE_REGISTERED, params);
}

// Dispatch a service unregistered event
dispatch_service_unregistered :: (
    dispatcher: *Event_Dispatcher,
    service_id: string
) -> Dispatch_Result {
    params := json_object();
    table_set(params.object, copy_string("service_id"), jason.json_value(copy_string(service_id)));
    defer jason.json_free(params);

    return dispatch_event(dispatcher, .SERVICE_UNREGISTERED, params);
}

// Dispatch a subscriber added event
dispatch_subscriber_added :: (
    dispatcher: *Event_Dispatcher,
    endpoint: string,
    events: [] string
) -> Dispatch_Result {
    params := json_object();
    table_set(params.object, copy_string("endpoint"), jason.json_value(copy_string(endpoint)));

    // Add events array
    events_array: jason.JSON_Value;
    events_array.type = .ARRAY;
    events_dyn: [..] jason.JSON_Value;
    for events {
        array_add(*events_dyn, jason.json_value(copy_string(it)));
    }
    events_array.array = events_dyn;
    table_set(params.object, copy_string("events"), events_array);
    defer jason.json_free(params);

    return dispatch_event(dispatcher, .SUBSCRIBER_ADDED, params);
}

// Dispatch a subscriber removed event
dispatch_subscriber_removed :: (
    dispatcher: *Event_Dispatcher,
    endpoint: string
) -> Dispatch_Result {
    params := json_object();
    table_set(params.object, copy_string("endpoint"), jason.json_value(copy_string(endpoint)));
    defer jason.json_free(params);

    return dispatch_event(dispatcher, .SUBSCRIBER_REMOVED, params);
}

// Core dispatch function - dispatches an event to all matching subscribers
dispatch_event :: (
    dispatcher: *Event_Dispatcher,
    event_type: Event_Type,
    params: jason.JSON_Value
) -> Dispatch_Result {
    result: Dispatch_Result;
    event_name := event_type_to_name(event_type);
    result.event_name = copy_string(event_name);

    if !dispatcher.initialized {
        return result;
    }

    // Get subscribers for this event
    subscribers := get_subscribers_for_event(dispatcher.subscription_manager, event_name);
    defer free_subscribers_array(*subscribers);

    result.total_subscribers = subscribers.count;

    // Create the JSON-RPC notification
    notification_method := event_type_to_notification_method(event_type);
    notification := create_notification(notification_method, params);
    defer free(notification);

    // Update stats
    lock(*dispatcher.mutex);
    dispatcher.total_events_dispatched += 1;
    unlock(*dispatcher.mutex);

    // Dispatch to each subscriber
    for *sub: subscribers {
        delivery := deliver_to_subscriber(dispatcher, sub.endpoint, notification);
        array_add(*result.results, delivery);

        if delivery.status == .DELIVERED {
            result.successful_deliveries += 1;
        } else {
            result.failed_deliveries += 1;
        }
    }

    return result;
}

// Deliver a notification to a single subscriber endpoint
deliver_to_subscriber :: (
    dispatcher: *Event_Dispatcher,
    endpoint: string,
    notification: string
) -> Delivery_Result {
    result: Delivery_Result;
    result.endpoint = copy_string(endpoint);
    result.status = .PENDING;

    // Update stats
    lock(*dispatcher.mutex);
    dispatcher.total_deliveries_attempted += 1;
    unlock(*dispatcher.mutex);

    // Try to connect and send
    client: IPC_Client;
    if !init_ipc_client(*client, endpoint) {
        result.status = .FAILED;
        result.error_message = copy_string("Failed to initialize client");
        update_failed_stat(dispatcher);
        return result;
    }
    defer destroy_ipc_client(*client);

    if !connect_client(*client) {
        result.status = .ENDPOINT_UNAVAILABLE;
        result.error_message = copy_string("Failed to connect to endpoint");
        update_failed_stat(dispatcher);
        return result;
    }

    // Send the notification
    data := cast([] u8) notification;
    bytes_sent := client_send(*client, data);

    if bytes_sent < 0 {
        result.status = .FAILED;
        result.error_message = copy_string("Failed to send notification");
        update_failed_stat(dispatcher);
        return result;
    }

    if bytes_sent < data.count {
        result.status = .FAILED;
        result.error_message = copy_string("Partial send");
        update_failed_stat(dispatcher);
        return result;
    }

    // Success!
    result.status = .DELIVERED;

    lock(*dispatcher.mutex);
    dispatcher.total_deliveries_successful += 1;
    unlock(*dispatcher.mutex);

    return result;
}

// Helper to update failed delivery stat
update_failed_stat :: (dispatcher: *Event_Dispatcher) {
    lock(*dispatcher.mutex);
    dispatcher.total_deliveries_failed += 1;
    unlock(*dispatcher.mutex);
}

// ============================================================================
// Context Changed Event Builder
// ============================================================================

// Build params for a context.changed notification
build_context_changed_params :: (
    previous: *Context,
    current: *Context,
    change: *Context_Change
) -> jason.JSON_Value {
    params := json_object();

    // Add previous context
    prev_json := context_to_json(previous);
    table_set(params.object, copy_string("previous"), prev_json);

    // Add current context
    curr_json := context_to_json(current);
    table_set(params.object, copy_string("current"), curr_json);

    // Add changed fields array
    changed_array: jason.JSON_Value;
    changed_array.type = .ARRAY;
    changed_dyn: [..] jason.JSON_Value;
    for change.changed_fields {
        array_add(*changed_dyn, jason.json_value(copy_string(it)));
    }
    changed_array.array = changed_dyn;
    table_set(params.object, copy_string("changed_fields"), changed_array);

    // Add version
    table_set(params.object, copy_string("version"), json_number(cast(float64) current.version));

    return params;
}

// ============================================================================
// Statistics and Query Functions
// ============================================================================

// Dispatcher statistics
Dispatcher_Stats :: struct {
    total_events_dispatched: u64;
    total_deliveries_attempted: u64;
    total_deliveries_successful: u64;
    total_deliveries_failed: u64;
    success_rate: float64;
}

// Get dispatcher statistics
get_dispatcher_stats :: (dispatcher: *Event_Dispatcher) -> Dispatcher_Stats {
    lock(*dispatcher.mutex);
    defer unlock(*dispatcher.mutex);

    stats: Dispatcher_Stats;
    stats.total_events_dispatched = dispatcher.total_events_dispatched;
    stats.total_deliveries_attempted = dispatcher.total_deliveries_attempted;
    stats.total_deliveries_successful = dispatcher.total_deliveries_successful;
    stats.total_deliveries_failed = dispatcher.total_deliveries_failed;

    if stats.total_deliveries_attempted > 0 {
        stats.success_rate = cast(float64) stats.total_deliveries_successful / cast(float64) stats.total_deliveries_attempted;
    }

    return stats;
}

// Reset dispatcher statistics
reset_dispatcher_stats :: (dispatcher: *Event_Dispatcher) {
    lock(*dispatcher.mutex);
    defer unlock(*dispatcher.mutex);

    dispatcher.total_events_dispatched = 0;
    dispatcher.total_deliveries_attempted = 0;
    dispatcher.total_deliveries_successful = 0;
    dispatcher.total_deliveries_failed = 0;
}

// ============================================================================
// Memory Management
// ============================================================================

// Free a delivery result
free_delivery_result :: (result: *Delivery_Result) {
    free(result.endpoint);
    if result.error_message.count > 0 {
        free(result.error_message);
    }
}

// Free a dispatch result
free_dispatch_result :: (result: *Dispatch_Result) {
    free(result.event_name);
    for *result.results {
        free_delivery_result(it);
    }
    array_free(result.results);
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert Dispatcher_Stats to JSON
dispatcher_stats_to_json :: (stats: *Dispatcher_Stats) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("total_events_dispatched"), json_number(cast(float64) stats.total_events_dispatched));
    table_set(result.object, copy_string("total_deliveries_attempted"), json_number(cast(float64) stats.total_deliveries_attempted));
    table_set(result.object, copy_string("total_deliveries_successful"), json_number(cast(float64) stats.total_deliveries_successful));
    table_set(result.object, copy_string("total_deliveries_failed"), json_number(cast(float64) stats.total_deliveries_failed));
    table_set(result.object, copy_string("success_rate"), json_number(stats.success_rate));

    return result;
}

// Convert Dispatch_Result to JSON
dispatch_result_to_json :: (result: *Dispatch_Result) -> jason.JSON_Value {
    json := json_object();

    table_set(json.object, copy_string("event_name"), jason.json_value(copy_string(result.event_name)));
    table_set(json.object, copy_string("total_subscribers"), json_number(cast(float64) result.total_subscribers));
    table_set(json.object, copy_string("successful_deliveries"), json_number(cast(float64) result.successful_deliveries));
    table_set(json.object, copy_string("failed_deliveries"), json_number(cast(float64) result.failed_deliveries));

    // Add results array
    results_array: jason.JSON_Value;
    results_array.type = .ARRAY;
    results_dyn: [..] jason.JSON_Value;
    for *result.results {
        array_add(*results_dyn, delivery_result_to_json(it));
    }
    results_array.array = results_dyn;
    table_set(json.object, copy_string("results"), results_array);

    return json;
}

// Convert Delivery_Result to JSON
delivery_result_to_json :: (result: *Delivery_Result) -> jason.JSON_Value {
    json := json_object();

    table_set(json.object, copy_string("endpoint"), jason.json_value(copy_string(result.endpoint)));
    table_set(json.object, copy_string("status"), jason.json_value(copy_string(delivery_status_to_string(result.status))));

    if result.error_message.count > 0 {
        table_set(json.object, copy_string("error_message"), jason.json_value(copy_string(result.error_message)));
    }

    table_set(json.object, copy_string("latency_ms"), json_number(result.latency_ms));

    return json;
}

// Convert delivery status to string
delivery_status_to_string :: (status: Delivery_Status) -> string {
    if status == {
        case .PENDING;              return "pending";
        case .DELIVERED;            return "delivered";
        case .FAILED;               return "failed";
        case .TIMEOUT;              return "timeout";
        case .ENDPOINT_UNAVAILABLE; return "endpoint_unavailable";
        case;                       return "unknown";
    }
}

// Parse delivery status from string
string_to_delivery_status :: (s: string) -> Delivery_Status {
    if s == "pending"              return .PENDING;
    if s == "delivered"            return .DELIVERED;
    if s == "failed"               return .FAILED;
    if s == "timeout"              return .TIMEOUT;
    if s == "endpoint_unavailable" return .ENDPOINT_UNAVAILABLE;
    return .PENDING;
}
