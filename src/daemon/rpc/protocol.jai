// JSON-RPC 2.0 Protocol Implementation
//
// This module implements the JSON-RPC 2.0 specification for the daemon's API.
// It provides:
// - Request/Response/Notification/Error type definitions
// - Parsing JSON-RPC messages from raw JSON
// - Serializing JSON-RPC messages to JSON strings
// - Standard error codes per specification
//
// See: https://www.jsonrpc.org/specification

#import "Basic";
#import "String";
#import "Hash_Table";
jason :: #import,dir "../../../modules/jason";

// JSON-RPC 2.0 Protocol Version
JSONRPC_VERSION :: "2.0";

// ============================================================================
// Standard JSON-RPC 2.0 Error Codes
// ============================================================================

// Parse error: Invalid JSON was received by the server
JSONRPC_PARSE_ERROR :: -32700;

// Invalid Request: The JSON sent is not a valid Request object
JSONRPC_INVALID_REQUEST :: -32600;

// Method not found: The method does not exist / is not available
JSONRPC_METHOD_NOT_FOUND :: -32601;

// Invalid params: Invalid method parameter(s)
JSONRPC_INVALID_PARAMS :: -32602;

// Internal error: Internal JSON-RPC error
JSONRPC_INTERNAL_ERROR :: -32603;

// Server error range: -32000 to -32099 (reserved for implementation-defined server errors)
JSONRPC_SERVER_ERROR_MIN :: -32099;
JSONRPC_SERVER_ERROR_MAX :: -32000;

// Application-specific error codes (above -32000)
JSONRPC_CONTEXT_NOT_FOUND :: -1001;
JSONRPC_SERVICE_NOT_FOUND :: -1002;
JSONRPC_SUBSCRIPTION_EXISTS :: -1003;
JSONRPC_INVALID_CONTEXT :: -1004;
JSONRPC_UNAUTHORIZED :: -1005;

// ============================================================================
// Core Types
// ============================================================================

// Request ID can be a string, number, or null
Request_ID :: struct {
    is_null: bool;
    is_string: bool;
    union {
        str_value: string;
        num_value: s64;
    }
}

// JSON-RPC Request
JSONRPC_Request :: struct {
    jsonrpc: string;         // Must be "2.0"
    method: string;          // Method name
    params: jason.JSON_Value; // Parameters (optional, can be object or array)
    id: Request_ID;          // Request ID (absent for notifications)
    has_id: bool;            // True if id was present in request
}

// JSON-RPC Response (success)
JSONRPC_Response :: struct {
    jsonrpc: string;         // "2.0"
    result: jason.JSON_Value; // Result value
    id: Request_ID;          // Same ID as request
}

// JSON-RPC Error object
JSONRPC_Error_Data :: struct {
    code: s32;               // Error code
    message: string;         // Error message
    data: jason.JSON_Value;  // Optional additional data
    has_data: bool;
}

// JSON-RPC Error Response
JSONRPC_Error_Response :: struct {
    jsonrpc: string;         // "2.0"
    error: JSONRPC_Error_Data;
    id: Request_ID;          // Same ID as request, or null if parse error
}

// Notification (request without id - no response expected)
JSONRPC_Notification :: struct {
    jsonrpc: string;         // "2.0"
    method: string;          // Method name
    params: jason.JSON_Value; // Parameters (optional)
}

// Parsed message types
Message_Type :: enum {
    INVALID;
    REQUEST;
    NOTIFICATION;
    RESPONSE;
    ERROR_RESPONSE;
    BATCH;
}

// Union for parsed messages
JSONRPC_Message :: struct {
    type: Message_Type;
    union {
        request: JSONRPC_Request;
        notification: JSONRPC_Notification;
        response: JSONRPC_Response;
        error_response: JSONRPC_Error_Response;
        batch: [..] JSONRPC_Message;
    }
    parse_error: string;     // Set if parsing failed
}

// ============================================================================
// Parsing Functions
// ============================================================================

// Parse a JSON-RPC message from a string
parse_jsonrpc_message :: (json_str: string) -> JSONRPC_Message {
    result: JSONRPC_Message;
    result.type = .INVALID;

    if json_str.count == 0 {
        result.parse_error = copy_string("Empty message");
        return result;
    }

    // Parse JSON
    success, json_value := jason.json_parse_string(json_str);
    if !success {
        result.parse_error = copy_string("Invalid JSON");
        return result;
    }
    defer if result.type == .INVALID then jason.json_free(json_value);

    // Check if it's a batch (array)
    if json_value.type == .ARRAY {
        return parse_batch(json_value);
    }

    // Must be an object
    if json_value.type != .OBJECT {
        result.parse_error = copy_string("Message must be an object or array");
        jason.json_free(json_value);
        return result;
    }

    return parse_single_message(json_value);
}

// Parse a single JSON-RPC message (not a batch)
parse_single_message :: (json_value: jason.JSON_Value) -> JSONRPC_Message {
    result: JSONRPC_Message;
    result.type = .INVALID;

    obj := json_value.object;

    // Check for jsonrpc field
    found_version, version_val := table_find(obj, "jsonrpc");
    if !found_version || version_val.type != .STRING {
        result.parse_error = copy_string("Missing or invalid 'jsonrpc' field");
        return result;
    }

    if version_val.str != JSONRPC_VERSION {
        result.parse_error = copy_string("Unsupported JSON-RPC version");
        return result;
    }

    // Check for method field (request or notification)
    found_method, method_val := table_find(obj, "method");

    // Check for result field (response)
    found_result, result_val := table_find(obj, "result");

    // Check for error field (error response)
    found_error, error_val := table_find(obj, "error");

    // Check for id field
    found_id, id_val := table_find(obj, "id");

    // Determine message type
    if found_method {
        // Request or Notification
        if method_val.type != .STRING {
            result.parse_error = copy_string("Method must be a string");
            return result;
        }

        // Get params if present
        found_params, params_val := table_find(obj, "params");

        if found_id {
            // It's a request
            result.type = .REQUEST;
            result.request.jsonrpc = copy_string(JSONRPC_VERSION);
            result.request.method = copy_string(method_val.str);
            result.request.has_id = true;
            result.request.id = parse_request_id(id_val);

            if found_params {
                result.request.params = params_val;
                // Don't free the params - they're now owned by the request
                // Remove from object so json_free doesn't double-free
                table_remove(obj, "params");
            } else {
                result.request.params.type = .NULL;
            }
        } else {
            // It's a notification
            result.type = .NOTIFICATION;
            result.notification.jsonrpc = copy_string(JSONRPC_VERSION);
            result.notification.method = copy_string(method_val.str);

            if found_params {
                result.notification.params = params_val;
                table_remove(obj, "params");
            } else {
                result.notification.params.type = .NULL;
            }
        }
    } else if found_result && !found_error {
        // Success response
        if !found_id {
            result.parse_error = copy_string("Response must have an id");
            return result;
        }

        result.type = .RESPONSE;
        result.response.jsonrpc = copy_string(JSONRPC_VERSION);
        result.response.id = parse_request_id(id_val);
        result.response.result = result_val;
        table_remove(obj, "result");
    } else if found_error {
        // Error response
        result.type = .ERROR_RESPONSE;
        result.error_response.jsonrpc = copy_string(JSONRPC_VERSION);

        if found_id {
            result.error_response.id = parse_request_id(id_val);
        } else {
            result.error_response.id.is_null = true;
        }

        // Parse error object
        if error_val.type != .OBJECT {
            result.parse_error = copy_string("Error must be an object");
            result.type = .INVALID;
            return result;
        }

        err_obj := error_val.object;

        // Get code (required)
        found_code, code_val := table_find(err_obj, "code");
        if !found_code || code_val.type != .NUMBER {
            result.parse_error = copy_string("Error code must be a number");
            result.type = .INVALID;
            return result;
        }
        result.error_response.error.code = cast(s32) code_val.number;

        // Get message (required)
        found_msg, msg_val := table_find(err_obj, "message");
        if !found_msg || msg_val.type != .STRING {
            result.parse_error = copy_string("Error message must be a string");
            result.type = .INVALID;
            return result;
        }
        result.error_response.error.message = copy_string(msg_val.str);

        // Get data (optional)
        found_data, data_val := table_find(err_obj, "data");
        if found_data {
            result.error_response.error.has_data = true;
            result.error_response.error.data = data_val;
            table_remove(err_obj, "data");
        }
    } else {
        result.parse_error = copy_string("Invalid message: must have 'method', 'result', or 'error'");
        return result;
    }

    return result;
}

// Parse a batch of JSON-RPC messages
parse_batch :: (json_value: jason.JSON_Value) -> JSONRPC_Message {
    result: JSONRPC_Message;
    result.type = .BATCH;

    if json_value.array.count == 0 {
        result.type = .INVALID;
        result.parse_error = copy_string("Empty batch array");
        return result;
    }

    for json_value.array {
        msg := parse_single_message(it);
        array_add(*result.batch, msg);
    }

    return result;
}

// Parse a request ID from a JSON value
parse_request_id :: (val: jason.JSON_Value) -> Request_ID {
    id: Request_ID;

    if val.type == .NULL {
        id.is_null = true;
    } else if val.type == .STRING {
        id.is_string = true;
        id.str_value = copy_string(val.str);
    } else if val.type == .NUMBER {
        id.is_string = false;
        id.num_value = cast(s64) val.number;
    } else {
        // Invalid ID type - treat as null
        id.is_null = true;
    }

    return id;
}

// ============================================================================
// Serialization Functions
// ============================================================================

// Create a JSON-RPC success response
create_response :: (id: Request_ID, result: jason.JSON_Value) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    append(*builder, "{\"jsonrpc\":\"2.0\",\"result\":");
    jason.json_append_value(*builder, result, "");  // No indentation
    append(*builder, ",\"id\":");
    append_request_id(*builder, id);
    append(*builder, "}");

    return builder_to_string(*builder);
}

// Create a JSON-RPC error response
create_error_response :: (id: Request_ID, code: s32, message: string, data: jason.JSON_Value = .{}) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    append(*builder, "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":");
    print_to_builder(*builder, "%", code);
    append(*builder, ",\"message\":");
    jason.json_append_value(*builder, jason.json_value(message), "");

    if data.type != .NULL {
        append(*builder, ",\"data\":");
        jason.json_append_value(*builder, data, "");
    }

    append(*builder, "},\"id\":");
    append_request_id(*builder, id);
    append(*builder, "}");

    return builder_to_string(*builder);
}

// Create a JSON-RPC notification
create_notification :: (method: string, params: jason.JSON_Value = .{}) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    append(*builder, "{\"jsonrpc\":\"2.0\",\"method\":");
    jason.json_append_value(*builder, jason.json_value(method), "");

    if params.type != .NULL {
        append(*builder, ",\"params\":");
        jason.json_append_value(*builder, params, "");
    }

    append(*builder, "}");

    return builder_to_string(*builder);
}

// Create a JSON-RPC request
create_request :: (id: Request_ID, method: string, params: jason.JSON_Value = .{}) -> string {
    builder: String_Builder;
    defer free_buffers(*builder);

    append(*builder, "{\"jsonrpc\":\"2.0\",\"method\":");
    jason.json_append_value(*builder, jason.json_value(method), "");

    if params.type != .NULL {
        append(*builder, ",\"params\":");
        jason.json_append_value(*builder, params, "");
    }

    append(*builder, ",\"id\":");
    append_request_id(*builder, id);
    append(*builder, "}");

    return builder_to_string(*builder);
}

// Helper to append request ID to a string builder
append_request_id :: (builder: *String_Builder, id: Request_ID) {
    if id.is_null {
        append(builder, "null");
    } else if id.is_string {
        jason.json_append_value(builder, jason.json_value(id.str_value), "");
    } else {
        print_to_builder(builder, "%", id.num_value);
    }
}

// ============================================================================
// Convenience Functions
// ============================================================================

// Create a Request_ID from an integer
make_request_id :: (num: s64) -> Request_ID {
    id: Request_ID;
    id.is_null = false;
    id.is_string = false;
    id.num_value = num;
    return id;
}

// Create a Request_ID from a string
make_request_id :: (str: string) -> Request_ID {
    id: Request_ID;
    id.is_null = false;
    id.is_string = true;
    id.str_value = copy_string(str);
    return id;
}

// Create a null Request_ID
make_null_request_id :: () -> Request_ID {
    id: Request_ID;
    id.is_null = true;
    return id;
}

// Get a string description for an error code
get_error_message :: (code: s32) -> string {
    if code == JSONRPC_PARSE_ERROR return "Parse error";
    if code == JSONRPC_INVALID_REQUEST return "Invalid Request";
    if code == JSONRPC_METHOD_NOT_FOUND return "Method not found";
    if code == JSONRPC_INVALID_PARAMS return "Invalid params";
    if code == JSONRPC_INTERNAL_ERROR return "Internal error";
    if code == JSONRPC_CONTEXT_NOT_FOUND return "Context not found";
    if code == JSONRPC_SERVICE_NOT_FOUND return "Service not found";
    if code == JSONRPC_SUBSCRIPTION_EXISTS return "Subscription already exists";
    if code == JSONRPC_INVALID_CONTEXT return "Invalid context data";
    if code == JSONRPC_UNAUTHORIZED return "Unauthorized";
    if code >= JSONRPC_SERVER_ERROR_MIN && code <= JSONRPC_SERVER_ERROR_MAX {
        return "Server error";
    }
    return "Unknown error";
}

// Check if an error code is in the standard error range
is_standard_error :: (code: s32) -> bool {
    return code == JSONRPC_PARSE_ERROR ||
           code == JSONRPC_INVALID_REQUEST ||
           code == JSONRPC_METHOD_NOT_FOUND ||
           code == JSONRPC_INVALID_PARAMS ||
           code == JSONRPC_INTERNAL_ERROR ||
           (code >= JSONRPC_SERVER_ERROR_MIN && code <= JSONRPC_SERVER_ERROR_MAX);
}

// ============================================================================
// Cleanup Functions
// ============================================================================

// Free a JSONRPC_Message and its contents
free_jsonrpc_message :: (msg: *JSONRPC_Message) {
    if msg.parse_error.count > 0 {
        free(msg.parse_error);
    }

    if msg.type == {
        case .REQUEST;
            free(msg.request.jsonrpc);
            free(msg.request.method);
            if msg.request.id.is_string {
                free(msg.request.id.str_value);
            }
            if msg.request.params.type != .NULL {
                jason.json_free(msg.request.params);
            }

        case .NOTIFICATION;
            free(msg.notification.jsonrpc);
            free(msg.notification.method);
            if msg.notification.params.type != .NULL {
                jason.json_free(msg.notification.params);
            }

        case .RESPONSE;
            free(msg.response.jsonrpc);
            if msg.response.id.is_string {
                free(msg.response.id.str_value);
            }
            if msg.response.result.type != .NULL {
                jason.json_free(msg.response.result);
            }

        case .ERROR_RESPONSE;
            free(msg.error_response.jsonrpc);
            if msg.error_response.id.is_string {
                free(msg.error_response.id.str_value);
            }
            free(msg.error_response.error.message);
            if msg.error_response.error.has_data {
                jason.json_free(msg.error_response.error.data);
            }

        case .BATCH;
            for *msg.batch {
                free_jsonrpc_message(it);
            }
            array_free(msg.batch);

        case .INVALID;
            // Nothing to free
    }
}

// Free a Request_ID if it contains allocated memory
free_request_id :: (id: *Request_ID) {
    if id.is_string && id.str_value.count > 0 {
        free(id.str_value);
        id.str_value = "";
    }
}
