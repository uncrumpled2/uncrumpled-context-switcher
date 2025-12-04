// Subscription Manager API Handlers
//
// This module implements JSON-RPC API handlers for subscription management:
// - subscribe     - Subscribe to events (context.changed, etc.)
// - unsubscribe   - Unsubscribe from events
//
// All handlers take a JSON-RPC request and return a JSON response string.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)
// - api/context.jai (for json_object, json_number, json_bool, API_Result)

// ============================================================================
// Subscription Data Structures
// ============================================================================

// A subscriber registered for events
Subscriber :: struct {
    endpoint: string;              // Socket path or pipe name where to send notifications
    events: [..] string;           // Events this subscriber wants (e.g., "context.changed")
    last_heartbeat: Apollo_Time;   // Last heartbeat timestamp
    registered_at: Apollo_Time;    // When the subscriber registered
}

// Thread-safe manager for subscriptions
Subscription_Manager :: struct {
    subscribers: Table(string, Subscriber);  // Keyed by endpoint
    mutex: Mutex;
    initialized: bool;
}

// ============================================================================
// Subscription Manager Operations
// ============================================================================

// Initialize a new subscription manager
init_subscription_manager :: (manager: *Subscription_Manager) {
    init(*manager.mutex);
    manager.initialized = true;
}

// Destroy a subscription manager
destroy_subscription_manager :: (manager: *Subscription_Manager) {
    if !manager.initialized return;

    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    // Free all subscribers
    for *manager.subscribers {
        free_subscriber(it);
    }
    deinit(*manager.subscribers);

    destroy(*manager.mutex);
    manager.initialized = false;
}

// Add or update a subscription (thread-safe)
// If the endpoint already exists, updates the events list
// Returns: success, was_new (true if this was a new subscriber, false if updated)
subscribe :: (manager: *Subscription_Manager, endpoint: string, events: [] string) -> bool, bool {
    if endpoint.count == 0 {
        return false, false;
    }

    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    // Check if subscriber already exists
    existing := table_find_pointer(*manager.subscribers, endpoint);
    if existing != null {
        // Update existing subscriber
        // Clear old events
        for existing.events {
            free(it);
        }
        array_reset(*existing.events);

        // Add new events
        for events {
            array_add(*existing.events, copy_string(it));
        }
        existing.last_heartbeat = current_time_consensus();

        return true, false;  // Updated existing
    }

    // Create new subscriber
    sub: Subscriber;
    sub.endpoint = copy_string(endpoint);
    for events {
        array_add(*sub.events, copy_string(it));
    }
    sub.registered_at = current_time_consensus();
    sub.last_heartbeat = sub.registered_at;

    table_set(*manager.subscribers, copy_string(endpoint), sub);

    return true, true;  // New subscriber
}

// Remove a subscription (thread-safe)
// Returns: success (true if subscriber was found and removed)
unsubscribe :: (manager: *Subscription_Manager, endpoint: string) -> bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    // Find and remove the subscriber
    found, sub := table_find(*manager.subscribers, endpoint);
    if !found {
        return false;
    }

    // Free the subscriber data
    free_subscriber(*sub);

    // Remove from table
    table_remove(*manager.subscribers, endpoint);

    return true;
}

// Get a copy of a subscriber by endpoint (thread-safe)
get_subscriber :: (manager: *Subscription_Manager, endpoint: string) -> Subscriber, bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    found, sub := table_find(*manager.subscribers, endpoint);
    if !found {
        result: Subscriber;
        return result, false;
    }

    return copy_subscriber(*sub), true;
}

// Get all subscribers (thread-safe, returns copies)
get_all_subscribers :: (manager: *Subscription_Manager) -> [..] Subscriber {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    result: [..] Subscriber;
    for *manager.subscribers {
        array_add(*result, copy_subscriber(it));
    }

    return result;
}

// Get subscribers for a specific event (thread-safe, returns copies)
get_subscribers_for_event :: (manager: *Subscription_Manager, event: string) -> [..] Subscriber {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    result: [..] Subscriber;
    for *manager.subscribers {
        if subscriber_matches_event(it, event) {
            array_add(*result, copy_subscriber(it));
        }
    }

    return result;
}

// Get count of subscribers (thread-safe)
get_subscriber_count :: (manager: *Subscription_Manager) -> int {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    return manager.subscribers.count;
}

// Update heartbeat timestamp for a subscriber (thread-safe)
// Returns: success (true if subscriber was found and updated)
update_subscriber_heartbeat :: (manager: *Subscription_Manager, endpoint: string) -> bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    sub := table_find_pointer(*manager.subscribers, endpoint);
    if sub == null {
        return false;
    }

    sub.last_heartbeat = current_time_consensus();
    return true;
}

// Check if a subscriber is interested in a specific event
subscriber_matches_event :: (sub: *Subscriber, event: string) -> bool {
    for sub.events {
        if it == event {
            return true;
        }
        // Support wildcard matching (e.g., "context.*" matches "context.changed")
        if ends_with(it, ".*") {
            prefix := slice(it, 0, it.count - 2);  // Remove ".*"
            if begins_with(event, prefix) {
                return true;
            }
        }
    }
    return false;
}

// ============================================================================
// Helper Functions
// ============================================================================

// Deep copy a subscriber
copy_subscriber :: (src: *Subscriber) -> Subscriber {
    dst: Subscriber;

    dst.endpoint = copy_string(src.endpoint);
    dst.last_heartbeat = src.last_heartbeat;
    dst.registered_at = src.registered_at;

    for src.events {
        array_add(*dst.events, copy_string(it));
    }

    return dst;
}

// Free a subscriber's resources
free_subscriber :: (sub: *Subscriber) {
    free(sub.endpoint);
    for sub.events {
        free(it);
    }
    array_free(sub.events);
}

// Free an array of subscribers
free_subscribers_array :: (subscribers: *[..] Subscriber) {
    for *subscribers.* {
        free_subscriber(it);
    }
    array_free(subscribers.*);
}

// ============================================================================
// Subscription API Handlers
// ============================================================================

// Handle subscribe request
// Params: { "events": ["context.changed", ...], "endpoint": "/tmp/client.sock" }
handle_subscribe :: (manager: *Subscription_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "subscribe requires an object parameter"
        );
        return result;
    }

    // Get endpoint from params (required)
    found_endpoint, endpoint_val := table_find(request.params.object, "endpoint");
    if !found_endpoint || endpoint_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "subscribe requires an 'endpoint' string parameter"
        );
        return result;
    }

    // Get events from params (required)
    found_events, events_val := table_find(request.params.object, "events");
    if !found_events || events_val.type != .ARRAY {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "subscribe requires an 'events' array parameter"
        );
        return result;
    }

    // Parse events array
    events: [..] string;
    defer {
        for events { free(it); }
        array_free(events);
    }

    for events_val.array {
        if it.type != .STRING {
            result.success = false;
            result.response = create_error_response(
                request.id,
                JSONRPC_INVALID_PARAMS,
                "events array must contain only strings"
            );
            return result;
        }
        array_add(*events, copy_string(it.str));
    }

    // Perform subscription
    success, was_new := subscribe(manager, endpoint_val.str, events);

    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "Invalid endpoint"
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("subscribed"), json_bool(true));
    table_set(response_obj.object, copy_string("new"), json_bool(was_new));
    table_set(response_obj.object, copy_string("endpoint"), jason.json_value(copy_string(endpoint_val.str)));
    table_set(response_obj.object, copy_string("event_count"), json_number(cast(float64) events.count));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle unsubscribe request
// Params: { "endpoint": "/tmp/client.sock" }
handle_unsubscribe :: (manager: *Subscription_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "unsubscribe requires an object parameter"
        );
        return result;
    }

    // Get endpoint from params
    found_endpoint, endpoint_val := table_find(request.params.object, "endpoint");
    if !found_endpoint || endpoint_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "unsubscribe requires an 'endpoint' string parameter"
        );
        return result;
    }

    // Unsubscribe
    removed := unsubscribe(manager, endpoint_val.str);

    // Build response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("unsubscribed"), json_bool(removed));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a subscription method to the appropriate handler
route_subscription_method :: (manager: *Subscription_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    if request.method == {
        case "subscribe";
            return handle_subscribe(manager, request);
        case "unsubscribe";
            return handle_unsubscribe(manager, request);
        case;
            result.success = false;
            result.response = create_error_response(
                request.id,
                JSONRPC_METHOD_NOT_FOUND,
                tprint("Unknown method: %", request.method)
            );
            return result;
    }
}

// Check if a method is a subscription method
is_subscription_method :: (method: string) -> bool {
    return method == "subscribe" || method == "unsubscribe";
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert a Subscriber to a JSON_Value object
subscriber_to_json :: (sub: *Subscriber) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("endpoint"), jason.json_value(copy_string(sub.endpoint)));

    // Add events array
    events_array: jason.JSON_Value;
    events_array.type = .ARRAY;
    events_dyn: [..] jason.JSON_Value;
    for sub.events {
        array_add(*events_dyn, jason.json_value(copy_string(it)));
    }
    events_array.array = events_dyn;
    table_set(result.object, copy_string("events"), events_array);

    // Add timestamps as numbers
    table_set(result.object, copy_string("last_heartbeat"), json_number(cast(float64) sub.last_heartbeat.low));
    table_set(result.object, copy_string("registered_at"), json_number(cast(float64) sub.registered_at.low));

    return result;
}

// Parse a Subscriber from a JSON_Value object
// Returns: subscriber, success, error message
json_to_subscriber :: (json: jason.JSON_Value) -> Subscriber, bool, string {
    sub: Subscriber;

    if json.type != .OBJECT {
        return sub, false, "Expected object";
    }

    obj := json.object;

    // endpoint (required)
    found, val := table_find(obj, "endpoint");
    if !found || val.type != .STRING {
        return sub, false, "Missing or invalid 'endpoint' field";
    }
    sub.endpoint = copy_string(val.str);

    // events (required)
    found, val = table_find(obj, "events");
    if !found || val.type != .ARRAY {
        free(sub.endpoint);
        return sub, false, "Missing or invalid 'events' field";
    }
    for val.array {
        if it.type != .STRING {
            free_subscriber(*sub);
            return sub, false, "events must contain only strings";
        }
        array_add(*sub.events, copy_string(it.str));
    }

    return sub, true, "";
}
