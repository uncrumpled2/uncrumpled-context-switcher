// Service Registration API Handlers
//
// This module implements JSON-RPC API handlers for service registration:
// - service.register   - Register a new service
// - service.unregister - Unregister a service
// - service.list       - List all registered services
// - service.heartbeat  - Update service heartbeat timestamp
//
// All handlers take a JSON-RPC request and return a JSON response string.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)
// - api/context.jai (for json_object, json_number, json_bool, API_Result)

// ============================================================================
// Service Data Structures
// ============================================================================

// Capability manifest for a registered service
Capability_Manifest :: struct {
    events: [..] string;       // Events this service cares about
    provides_preview: bool;     // Whether this service can provide previews
    api_version: string;        // API version the service supports
}

// Registered service information
Registered_Service :: struct {
    id: string;                  // Unique service identifier
    name: string;                // Human-readable name
    endpoint: string;            // Socket path or pipe name
    capabilities: Capability_Manifest;
    preview_callback: string;    // Optional RPC method for preview
    last_heartbeat: Apollo_Time;
    registered_at: Apollo_Time;
}

// Thread-safe registry of services
Service_Registry :: struct {
    services: Table(string, Registered_Service);  // Keyed by service id
    mutex: Mutex;
    initialized: bool;
}

// ============================================================================
// Service Registry Operations
// ============================================================================

// Initialize a new service registry
init_service_registry :: (registry: *Service_Registry) {
    init(*registry.mutex);
    registry.initialized = true;
}

// Destroy a service registry
destroy_service_registry :: (registry: *Service_Registry) {
    if !registry.initialized return;

    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    // Free all registered services
    for *registry.services {
        free_registered_service(it);
    }
    deinit(*registry.services);

    destroy(*registry.mutex);
    registry.initialized = false;
}

// Register a new service (thread-safe)
// Returns: success, error_message
register_service :: (registry: *Service_Registry, service: *Registered_Service) -> bool, string {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    // Check if service already exists
    existing := table_find_pointer(*registry.services, service.id);
    if existing != null {
        return false, "Service with this ID already registered";
    }

    // Copy and add the service
    new_service := copy_registered_service(service);
    new_service.registered_at = current_time_consensus();
    new_service.last_heartbeat = new_service.registered_at;

    table_set(*registry.services, copy_string(service.id), new_service);

    return true, "";
}

// Unregister a service by ID (thread-safe)
// Returns: success (true if service was found and removed)
unregister_service :: (registry: *Service_Registry, service_id: string) -> bool {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    // Find and remove the service
    found, service := table_find(*registry.services, service_id);
    if !found {
        return false;
    }

    // Free the service data
    free_registered_service(*service);

    // Remove from table
    table_remove(*registry.services, service_id);

    return true;
}

// Get a copy of a service by ID (thread-safe)
get_service :: (registry: *Service_Registry, service_id: string) -> Registered_Service, bool {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    found, service := table_find(*registry.services, service_id);
    if !found {
        result: Registered_Service;
        return result, false;
    }

    return copy_registered_service(*service), true;
}

// Get all services (thread-safe, returns copies)
get_all_services :: (registry: *Service_Registry) -> [..] Registered_Service {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    result: [..] Registered_Service;
    for *registry.services {
        array_add(*result, copy_registered_service(it));
    }

    return result;
}

// Get count of registered services (thread-safe)
get_service_count :: (registry: *Service_Registry) -> int {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    return registry.services.count;
}

// Update heartbeat timestamp for a service (thread-safe)
// Returns: success (true if service was found and updated)
update_heartbeat :: (registry: *Service_Registry, service_id: string) -> bool {
    lock(*registry.mutex);
    defer unlock(*registry.mutex);

    service := table_find_pointer(*registry.services, service_id);
    if service == null {
        return false;
    }

    service.last_heartbeat = current_time_consensus();
    return true;
}

// ============================================================================
// Helper Functions
// ============================================================================

// Deep copy a registered service
copy_registered_service :: (src: *Registered_Service) -> Registered_Service {
    dst: Registered_Service;

    dst.id = copy_string(src.id);
    dst.name = copy_string(src.name);
    dst.endpoint = copy_string(src.endpoint);
    dst.preview_callback = copy_string(src.preview_callback);
    dst.last_heartbeat = src.last_heartbeat;
    dst.registered_at = src.registered_at;

    // Copy capabilities
    for src.capabilities.events {
        array_add(*dst.capabilities.events, copy_string(it));
    }
    dst.capabilities.provides_preview = src.capabilities.provides_preview;
    dst.capabilities.api_version = copy_string(src.capabilities.api_version);

    return dst;
}

// Free a registered service's resources
free_registered_service :: (service: *Registered_Service) {
    free(service.id);
    free(service.name);
    free(service.endpoint);
    free(service.preview_callback);

    for service.capabilities.events {
        free(it);
    }
    array_free(service.capabilities.events);
    free(service.capabilities.api_version);
}

// Free an array of services
free_services_array :: (services: *[..] Registered_Service) {
    for *services.* {
        free_registered_service(it);
    }
    array_free(services.*);
}

// ============================================================================
// Service API Handlers
// ============================================================================

// Handle service.register request
// Params: { "id": string, "name": string, "endpoint": string, "capabilities": {...}, "preview_callback"?: string }
handle_service_register :: (registry: *Service_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "service.register requires an object parameter"
        );
        return result;
    }

    // Parse service from params
    service, parse_ok, parse_error := json_to_service(request.params);
    if !parse_ok {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            parse_error
        );
        return result;
    }
    defer free_registered_service(*service);

    // Register the service
    success, error_msg := register_service(registry, *service);
    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            error_msg
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("registered"), json_bool(true));
    table_set(response_obj.object, copy_string("id"), jason.json_value(copy_string(service.id)));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle service.unregister request
// Params: { "id": string }
handle_service_unregister :: (registry: *Service_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "service.unregister requires an object parameter"
        );
        return result;
    }

    // Get id from params
    found_id, id_val := table_find(request.params.object, "id");
    if !found_id || id_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "service.unregister requires an 'id' string parameter"
        );
        return result;
    }

    // Unregister the service
    removed := unregister_service(registry, id_val.str);

    // Build response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("unregistered"), json_bool(removed));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle service.list request
// Params: none
handle_service_list :: (registry: *Service_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Get all services
    services := get_all_services(registry);
    defer free_services_array(*services);

    // Convert to JSON array
    services_array: jason.JSON_Value;
    services_array.type = .ARRAY;
    services_dyn: [..] jason.JSON_Value;

    for *services {
        array_add(*services_dyn, service_to_json(it));
    }
    services_array.array = services_dyn;

    // Build response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("services"), services_array);
    table_set(response_obj.object, copy_string("count"), json_number(cast(float64) services.count));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle service.heartbeat request
// Params: { "id": string }
handle_service_heartbeat :: (registry: *Service_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "service.heartbeat requires an object parameter"
        );
        return result;
    }

    // Get id from params
    found_id, id_val := table_find(request.params.object, "id");
    if !found_id || id_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "service.heartbeat requires an 'id' string parameter"
        );
        return result;
    }

    // Update heartbeat
    success := update_heartbeat(registry, id_val.str);

    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "Service not found"
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("acknowledged"), json_bool(true));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a service.* method to the appropriate handler
route_service_method :: (registry: *Service_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Check for service.* methods
    if request.method == {
        case "service.register";
            return handle_service_register(registry, request);
        case "service.unregister";
            return handle_service_unregister(registry, request);
        case "service.list";
            return handle_service_list(registry, request);
        case "service.heartbeat";
            return handle_service_heartbeat(registry, request);
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

// Check if a method is a service.* method
is_service_method :: (method: string) -> bool {
    return begins_with(method, "service.");
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert a Registered_Service to a JSON_Value object
service_to_json :: (service: *Registered_Service) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("id"), jason.json_value(copy_string(service.id)));
    table_set(result.object, copy_string("name"), jason.json_value(copy_string(service.name)));
    table_set(result.object, copy_string("endpoint"), jason.json_value(copy_string(service.endpoint)));
    table_set(result.object, copy_string("preview_callback"), jason.json_value(copy_string(service.preview_callback)));

    // Add capabilities object
    caps := json_object();

    // Add events array
    events_array: jason.JSON_Value;
    events_array.type = .ARRAY;
    events_dyn: [..] jason.JSON_Value;
    for service.capabilities.events {
        array_add(*events_dyn, jason.json_value(copy_string(it)));
    }
    events_array.array = events_dyn;
    table_set(caps.object, copy_string("events"), events_array);

    table_set(caps.object, copy_string("provides_preview"), json_bool(service.capabilities.provides_preview));
    table_set(caps.object, copy_string("api_version"), jason.json_value(copy_string(service.capabilities.api_version)));

    table_set(result.object, copy_string("capabilities"), caps);

    // Add timestamps as numbers (Apollo_Time is a u64)
    table_set(result.object, copy_string("last_heartbeat"), json_number(cast(float64) service.last_heartbeat.low));
    table_set(result.object, copy_string("registered_at"), json_number(cast(float64) service.registered_at.low));

    return result;
}

// Parse a Registered_Service from a JSON_Value object
// Returns: service, success, error message
json_to_service :: (json: jason.JSON_Value) -> Registered_Service, bool, string {
    service: Registered_Service;

    if json.type != .OBJECT {
        return service, false, "Expected object";
    }

    obj := json.object;

    // Parse required fields

    // id (required)
    found, val := table_find(obj, "id");
    if !found || val.type != .STRING {
        return service, false, "Missing or invalid 'id' field";
    }
    service.id = copy_string(val.str);

    // name (required)
    found, val = table_find(obj, "name");
    if !found || val.type != .STRING {
        free(service.id);
        return service, false, "Missing or invalid 'name' field";
    }
    service.name = copy_string(val.str);

    // endpoint (required)
    found, val = table_find(obj, "endpoint");
    if !found || val.type != .STRING {
        free(service.id);
        free(service.name);
        return service, false, "Missing or invalid 'endpoint' field";
    }
    service.endpoint = copy_string(val.str);

    // capabilities (required)
    found, val = table_find(obj, "capabilities");
    if !found || val.type != .OBJECT {
        free(service.id);
        free(service.name);
        free(service.endpoint);
        return service, false, "Missing or invalid 'capabilities' field";
    }

    // Parse capabilities
    caps_obj := val.object;

    // capabilities.events (optional array)
    found, val = table_find(caps_obj, "events");
    if found {
        if val.type != .ARRAY {
            free(service.id);
            free(service.name);
            free(service.endpoint);
            return service, false, "capabilities.events must be an array";
        }
        for val.array {
            if it.type != .STRING {
                free_registered_service(*service);
                return service, false, "capabilities.events must contain only strings";
            }
            array_add(*service.capabilities.events, copy_string(it.str));
        }
    }

    // capabilities.provides_preview (optional bool)
    found, val = table_find(caps_obj, "provides_preview");
    if found {
        if val.type != .BOOLEAN {
            free_registered_service(*service);
            return service, false, "capabilities.provides_preview must be a boolean";
        }
        service.capabilities.provides_preview = val.boolean;
    }

    // capabilities.api_version (optional string)
    found, val = table_find(caps_obj, "api_version");
    if found {
        if val.type != .STRING {
            free_registered_service(*service);
            return service, false, "capabilities.api_version must be a string";
        }
        service.capabilities.api_version = copy_string(val.str);
    } else {
        service.capabilities.api_version = copy_string("1.0.0");  // Default
    }

    // preview_callback (optional)
    found, val = table_find(obj, "preview_callback");
    if found {
        if val.type != .STRING {
            free_registered_service(*service);
            return service, false, "preview_callback must be a string";
        }
        service.preview_callback = copy_string(val.str);
    } else {
        service.preview_callback = copy_string("");
    }

    return service, true, "";
}
