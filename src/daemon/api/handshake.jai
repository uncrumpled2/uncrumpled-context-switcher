// Handshake & Version Negotiation API
//
// This module implements the JSON-RPC handshake method for:
// - Client version negotiation
// - Capability exchange
// - Session establishment
//
// Protocol: Client sends handshake with their version and capabilities.
// Server responds with its version, supported capabilities, and session info.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)
// - api/context.jai (for json_object, json_number, json_bool, API_Result)

// ============================================================================
// Constants
// ============================================================================

// PROTOCOL_VERSION is defined in config.jai

// All capabilities that the server supports
SUPPORTED_CAPABILITIES :: string.["context", "subscribe", "service", "preview", "logs"];

// Minimum client version that is compatible
MIN_CLIENT_VERSION :: "1.0.0";

// ============================================================================
// Client Session Data Structures
// ============================================================================

// Represents a connected client session after handshake
Client_Session :: struct {
    session_id: string;             // Unique session identifier
    client_version: string;         // Client's protocol version
    capabilities: [..] string;      // Capabilities the client requested
    endpoint: string;               // Client's endpoint (if provided)
    established_at: Apollo_Time;    // When the session was established
    last_activity: Apollo_Time;     // Last activity timestamp
}

// Thread-safe manager for client sessions
Session_Manager :: struct {
    sessions: Table(string, Client_Session);  // Keyed by session_id
    mutex: Mutex;
    initialized: bool;
    next_session_id: u64;
}

// ============================================================================
// Session Manager Operations
// ============================================================================

// Initialize a new session manager
init_session_manager :: (manager: *Session_Manager) {
    init(*manager.mutex);
    manager.initialized = true;
    manager.next_session_id = 1;
}

// Destroy a session manager
destroy_session_manager :: (manager: *Session_Manager) {
    if !manager.initialized return;

    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    // Free all sessions
    for *manager.sessions {
        free_session(it);
    }
    deinit(*manager.sessions);

    destroy(*manager.mutex);
    manager.initialized = false;
}

// Generate a new unique session ID (thread-safe)
generate_session_id :: (manager: *Session_Manager) -> string {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    id := manager.next_session_id;
    manager.next_session_id += 1;

    return copy_string(tprint("session-%", id));
}

// Create a new session (thread-safe)
// Returns: session_id, success
create_session :: (manager: *Session_Manager, client_version: string, capabilities: [] string, endpoint: string) -> string, bool {
    session_id := generate_session_id(manager);

    session: Client_Session;
    session.session_id = copy_string(session_id);
    session.client_version = copy_string(client_version);
    session.endpoint = copy_string(endpoint);
    session.established_at = current_time_consensus();
    session.last_activity = session.established_at;

    for capabilities {
        array_add(*session.capabilities, copy_string(it));
    }

    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    table_set(*manager.sessions, copy_string(session_id), session);

    return session_id, true;
}

// Get a session by ID (thread-safe, returns a copy)
get_session :: (manager: *Session_Manager, session_id: string) -> Client_Session, bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    found, session := table_find(*manager.sessions, session_id);
    if !found {
        result: Client_Session;
        return result, false;
    }

    return copy_session(*session), true;
}

// Remove a session (thread-safe)
// Returns: true if session was found and removed
remove_session :: (manager: *Session_Manager, session_id: string) -> bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    found, session := table_find(*manager.sessions, session_id);
    if !found {
        return false;
    }

    free_session(*session);
    table_remove(*manager.sessions, session_id);

    return true;
}

// Get count of active sessions (thread-safe)
get_session_count :: (manager: *Session_Manager) -> int {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    return manager.sessions.count;
}

// Update last activity timestamp for a session (thread-safe)
// Returns: true if session was found and updated
update_session_activity :: (manager: *Session_Manager, session_id: string) -> bool {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    session := table_find_pointer(*manager.sessions, session_id);
    if session == null {
        return false;
    }

    session.last_activity = current_time_consensus();
    return true;
}

// Get all sessions (thread-safe, returns copies)
get_all_sessions :: (manager: *Session_Manager) -> [..] Client_Session {
    lock(*manager.mutex);
    defer unlock(*manager.mutex);

    result: [..] Client_Session;
    for *manager.sessions {
        array_add(*result, copy_session(it));
    }

    return result;
}

// ============================================================================
// Helper Functions
// ============================================================================

// Deep copy a session
copy_session :: (src: *Client_Session) -> Client_Session {
    dst: Client_Session;

    dst.session_id = copy_string(src.session_id);
    dst.client_version = copy_string(src.client_version);
    dst.endpoint = copy_string(src.endpoint);
    dst.established_at = src.established_at;
    dst.last_activity = src.last_activity;

    for src.capabilities {
        array_add(*dst.capabilities, copy_string(it));
    }

    return dst;
}

// Free a session's resources
free_session :: (session: *Client_Session) {
    free(session.session_id);
    free(session.client_version);
    free(session.endpoint);
    for session.capabilities {
        free(it);
    }
    array_free(session.capabilities);
}

// Free an array of sessions
free_sessions_array :: (sessions: *[..] Client_Session) {
    for *sessions.* {
        free_session(it);
    }
    array_free(sessions.*);
}

// ============================================================================
// Version Negotiation
// ============================================================================

// Semantic version struct
Semver :: struct {
    major: int;
    minor: int;
    patch: int;
}

// Parse a semver string (e.g., "1.2.3")
// Returns: version, success
parse_semver :: (version_str: string) -> Semver, bool {
    result: Semver;

    if version_str.count == 0 {
        return result, false;
    }

    // Find first dot
    first_dot := -1;
    for 0..version_str.count-1 {
        if version_str[it] == #char "." {
            first_dot = it;
            break;
        }
    }

    if first_dot < 0 {
        return result, false;
    }

    // Find second dot
    second_dot := -1;
    for first_dot+1..version_str.count-1 {
        if version_str[it] == #char "." {
            second_dot = it;
            break;
        }
    }

    if second_dot < 0 {
        return result, false;
    }

    // Parse major
    major_str := slice(version_str, 0, first_dot);
    major, ok_major := string_to_int(major_str);
    if !ok_major return result, false;

    // Parse minor
    minor_str := slice(version_str, first_dot + 1, second_dot - first_dot - 1);
    minor, ok_minor := string_to_int(minor_str);
    if !ok_minor return result, false;

    // Parse patch
    patch_str := slice(version_str, second_dot + 1, version_str.count - second_dot - 1);
    // Verify patch_str contains only digits (no pre-release suffix like "-beta")
    if patch_str.count == 0 return result, false;
    for 0..patch_str.count-1 {
        c := patch_str[it];
        if c < #char "0" || c > #char "9" {
            return result, false;  // Contains non-digit character
        }
    }
    patch, ok_patch := string_to_int(patch_str);
    if !ok_patch return result, false;

    result.major = major;
    result.minor = minor;
    result.patch = patch;

    return result, true;
}

// Compare two semvers
// Returns: -1 if a < b, 0 if a == b, 1 if a > b
compare_semver :: (a: Semver, b: Semver) -> int {
    if a.major < b.major return -1;
    if a.major > b.major return 1;
    if a.minor < b.minor return -1;
    if a.minor > b.minor return 1;
    if a.patch < b.patch return -1;
    if a.patch > b.patch return 1;
    return 0;
}

// Check if a client version is compatible with the server
// Returns: compatible, error message
check_version_compatibility :: (client_version: string) -> bool, string {
    client_semver, ok := parse_semver(client_version);
    if !ok {
        return false, "Invalid client version format (expected semver like '1.0.0')";
    }

    min_semver, _ := parse_semver(MIN_CLIENT_VERSION);

    if compare_semver(client_semver, min_semver) < 0 {
        return false, tprint("Client version % is too old. Minimum required: %", client_version, MIN_CLIENT_VERSION);
    }

    // For now, just check minimum version
    // In the future, could also check for maximum version or specific incompatibilities

    return true, "";
}

// Check which of the requested capabilities are supported
// Returns: list of supported capabilities that were requested
filter_supported_capabilities :: (requested: [] string) -> [..] string {
    result: [..] string;

    for req: requested {
        for supported: SUPPORTED_CAPABILITIES {
            if req == supported {
                array_add(*result, copy_string(req));
                break;
            }
        }
    }

    return result;
}

// ============================================================================
// Handshake API Handler
// ============================================================================

// Handle handshake request
// Params: { "client_version": "1.0.0", "capabilities": ["context", "subscribe"], "endpoint": "/tmp/client.sock" }
// endpoint is optional
handle_handshake :: (manager: *Session_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "handshake requires an object parameter"
        );
        return result;
    }

    // Get client_version (required)
    found_version, version_val := table_find(request.params.object, "client_version");
    if !found_version || version_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "handshake requires a 'client_version' string parameter"
        );
        return result;
    }

    // Check version compatibility
    compatible, version_error := check_version_compatibility(version_val.str);
    if !compatible {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            version_error
        );
        return result;
    }

    // Get capabilities (required)
    found_caps, caps_val := table_find(request.params.object, "capabilities");
    if !found_caps || caps_val.type != .ARRAY {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "handshake requires a 'capabilities' array parameter"
        );
        return result;
    }

    // Parse capabilities array
    requested_caps: [..] string;
    defer {
        for requested_caps { free(it); }
        array_free(requested_caps);
    }

    for caps_val.array {
        if it.type != .STRING {
            result.success = false;
            result.response = create_error_response(
                request.id,
                JSONRPC_INVALID_PARAMS,
                "capabilities array must contain only strings"
            );
            return result;
        }
        array_add(*requested_caps, copy_string(it.str));
    }

    // Filter to supported capabilities
    granted_caps := filter_supported_capabilities(requested_caps);
    defer {
        for granted_caps { free(it); }
        array_free(granted_caps);
    }

    // Get optional endpoint
    endpoint := "";
    found_endpoint, endpoint_val := table_find(request.params.object, "endpoint");
    if found_endpoint && endpoint_val.type == .STRING {
        endpoint = endpoint_val.str;
    }

    // Create session
    session_id, session_created := create_session(manager, version_val.str, granted_caps, endpoint);
    defer free(session_id);

    if !session_created {
        result.success = false;
        result.response = create_error_response(
            request.id,
            -32000,  // Server error
            "Failed to create session"
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    defer jason.json_free(response_obj);

    table_set(response_obj.object, copy_string("success"), json_bool(true));
    table_set(response_obj.object, copy_string("protocol_version"), jason.json_value(copy_string(PROTOCOL_VERSION)));
    table_set(response_obj.object, copy_string("session_id"), jason.json_value(copy_string(session_id)));

    // Add granted capabilities array
    caps_array: jason.JSON_Value;
    caps_array.type = .ARRAY;
    caps_dyn: [..] jason.JSON_Value;
    for granted_caps {
        array_add(*caps_dyn, jason.json_value(copy_string(it)));
    }
    caps_array.array = caps_dyn;
    table_set(response_obj.object, copy_string("capabilities"), caps_array);

    // Add server capabilities array
    server_caps_array: jason.JSON_Value;
    server_caps_array.type = .ARRAY;
    server_caps_dyn: [..] jason.JSON_Value;
    for SUPPORTED_CAPABILITIES {
        array_add(*server_caps_dyn, jason.json_value(copy_string(it)));
    }
    server_caps_array.array = server_caps_dyn;
    table_set(response_obj.object, copy_string("server_capabilities"), server_caps_array);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a handshake method to the appropriate handler
route_handshake_method :: (manager: *Session_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    if request.method == {
        case "handshake";
            return handle_handshake(manager, request);
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

// Check if a method is the handshake method
is_handshake_method :: (method: string) -> bool {
    return method == "handshake";
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert a Client_Session to a JSON_Value object
session_to_json :: (session: *Client_Session) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("session_id"), jason.json_value(copy_string(session.session_id)));
    table_set(result.object, copy_string("client_version"), jason.json_value(copy_string(session.client_version)));
    table_set(result.object, copy_string("endpoint"), jason.json_value(copy_string(session.endpoint)));

    // Add capabilities array
    caps_array: jason.JSON_Value;
    caps_array.type = .ARRAY;
    caps_dyn: [..] jason.JSON_Value;
    for session.capabilities {
        array_add(*caps_dyn, jason.json_value(copy_string(it)));
    }
    caps_array.array = caps_dyn;
    table_set(result.object, copy_string("capabilities"), caps_array);

    // Add timestamps as numbers
    table_set(result.object, copy_string("established_at"), json_number(cast(float64) session.established_at.low));
    table_set(result.object, copy_string("last_activity"), json_number(cast(float64) session.last_activity.low));

    return result;
}

// Parse a Client_Session from a JSON_Value object
// Returns: session, success, error message
json_to_session :: (json: jason.JSON_Value) -> Client_Session, bool, string {
    session: Client_Session;

    if json.type != .OBJECT {
        return session, false, "Expected object";
    }

    obj := json.object;

    // session_id (required)
    found, val := table_find(obj, "session_id");
    if !found || val.type != .STRING {
        return session, false, "Missing or invalid 'session_id' field";
    }
    session.session_id = copy_string(val.str);

    // client_version (required)
    found, val = table_find(obj, "client_version");
    if !found || val.type != .STRING {
        free(session.session_id);
        return session, false, "Missing or invalid 'client_version' field";
    }
    session.client_version = copy_string(val.str);

    // endpoint (optional, default empty)
    found, val = table_find(obj, "endpoint");
    if found && val.type == .STRING {
        session.endpoint = copy_string(val.str);
    } else {
        session.endpoint = copy_string("");
    }

    // capabilities (required)
    found, val = table_find(obj, "capabilities");
    if !found || val.type != .ARRAY {
        free_session(*session);
        return session, false, "Missing or invalid 'capabilities' field";
    }
    for val.array {
        if it.type != .STRING {
            free_session(*session);
            return session, false, "capabilities must contain only strings";
        }
        array_add(*session.capabilities, copy_string(it.str));
    }

    return session, true, "";
}
