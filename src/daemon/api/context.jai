// Context API Handlers
//
// This module implements JSON-RPC API handlers for context operations:
// - context.get     - Get current context
// - context.set     - Set full context (replaces all fields)
// - context.update  - Update specific context fields
// - context.addTag  - Add a tag to the context
// - context.removeTag - Remove a tag from the context
// - context.setParam  - Set a user parameter
// - context.getParam  - Get a user parameter
// - context.removeParam - Remove a user parameter
// - context.list    - List all contexts with schemas (NEW)
// - context.switch  - Switch to a context by input string (NEW)
// - context.create  - Create a new context definition (NEW)
// - context.delete  - Delete a context definition (NEW)
//
// All handlers take a JSON-RPC request and return a JSON response string.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table
// - jason module (as jason::)
// - context_store.jai (for Context, Context_Store, Context_Registry, etc.)
// - args_parser.jai (for parse_context_input, Parsed_Input, etc.)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)

// ============================================================================
// JSON Value Helpers
// ============================================================================

// Create a JSON_Value for a number
json_number :: (val: float64) -> jason.JSON_Value {
    result: jason.JSON_Value;
    result.type = .NUMBER;
    result.number = val;
    return result;
}

// Create a JSON_Value for a boolean
json_bool :: (val: bool) -> jason.JSON_Value {
    result: jason.JSON_Value;
    result.type = .BOOLEAN;
    result.boolean = val;
    return result;
}

// Create an empty JSON object value
json_object :: () -> jason.JSON_Value {
    result: jason.JSON_Value;
    result.type = .OBJECT;
    // Allocate and zero-initialize like the jason module does
    result.object = cast(*jason.JSON_Object) alloc(size_of(jason.JSON_Object));
    memset(result.object, 0, size_of(jason.JSON_Object));
    return result;
}

// ============================================================================
// API Result Type
// ============================================================================

// Result of processing an API request
API_Result :: struct {
    success: bool;
    response: string;  // JSON-RPC response string (owned, must be freed by caller)
}

// ============================================================================
// Context API Handlers
// ============================================================================

// Handle context.get request
// Returns the current context as JSON
handle_context_get :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Get the current context
    ctx := get_context(store);
    defer free_context(*ctx);

    // Convert context to JSON value
    ctx_json := context_to_json(*ctx);
    defer jason.json_free(ctx_json);

    // Create success response
    result.success = true;
    result.response = create_response(request.id, ctx_json);

    return result;
}

// Handle context.set request
// Replaces the entire context with the provided data
// Params: full context object
handle_context_set :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.set requires an object parameter"
        );
        return result;
    }

    // Parse context from params
    new_ctx, parse_ok, parse_error := json_to_context(request.params);
    if !parse_ok {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            parse_error
        );
        return result;
    }
    defer free_context(*new_ctx);

    // Set the context
    new_version, change := set_context(store, *new_ctx);
    defer array_free(change.changed_fields);

    // Build response with version and changed fields
    response_obj := build_set_response(new_version, *change);
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.update request
// Updates specific fields without replacing the entire context
// Params: object with fields to update
handle_context_update :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.update requires an object parameter"
        );
        return result;
    }

    // Parse update from params (only provided fields will be set)
    update_ctx, parse_ok, parse_error := json_to_context(request.params);
    if !parse_ok {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            parse_error
        );
        return result;
    }
    defer free_context(*update_ctx);

    // Update the context
    new_version, change := update_context(store, *update_ctx);
    defer array_free(change.changed_fields);

    // Build response
    response_obj := build_set_response(new_version, *change);
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.addTag request
// Params: { "tag": string }
handle_context_add_tag :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.addTag requires an object parameter"
        );
        return result;
    }

    // Get tag from params
    found_tag, tag_val := table_find(request.params.object, "tag");
    if !found_tag || tag_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.addTag requires a 'tag' string parameter"
        );
        return result;
    }

    // Add the tag
    added, new_version := add_tag(store, tag_val.str);

    // Build response
    response_obj := build_tag_response(new_version, added, "added");
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.removeTag request
// Params: { "tag": string }
handle_context_remove_tag :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.removeTag requires an object parameter"
        );
        return result;
    }

    // Get tag from params
    found_tag, tag_val := table_find(request.params.object, "tag");
    if !found_tag || tag_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.removeTag requires a 'tag' string parameter"
        );
        return result;
    }

    // Remove the tag
    removed, new_version := remove_tag(store, tag_val.str);

    // Build response
    response_obj := build_tag_response(new_version, removed, "removed");
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.setParam request
// Params: { "key": string, "value": string }
handle_context_set_param :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.setParam requires an object parameter"
        );
        return result;
    }

    // Get key from params
    found_key, key_val := table_find(request.params.object, "key");
    if !found_key || key_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.setParam requires a 'key' string parameter"
        );
        return result;
    }

    // Get value from params
    found_value, value_val := table_find(request.params.object, "value");
    if !found_value || value_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.setParam requires a 'value' string parameter"
        );
        return result;
    }

    // Set the parameter
    new_version := set_user_param(store, key_val.str, value_val.str);

    // Build response
    response_obj := build_param_response(new_version);
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.getParam request
// Params: { "key": string }
handle_context_get_param :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.getParam requires an object parameter"
        );
        return result;
    }

    // Get key from params
    found_key, key_val := table_find(request.params.object, "key");
    if !found_key || key_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.getParam requires a 'key' string parameter"
        );
        return result;
    }

    // Get the parameter
    value, found := get_user_param(store, key_val.str);
    // Note: value is already allocated by get_user_param, we pass it directly
    // to json_value which stores the reference, then json_free will free it

    // Build response
    response_obj := json_object();

    if found {
        // Pass value directly - json_free will take ownership and free it
        table_set(response_obj.object, copy_string("value"), jason.json_value(value));
        table_set(response_obj.object, copy_string("found"), json_bool(true));
    } else {
        table_set(response_obj.object, copy_string("value"), jason.JSON_Value.{type = .NULL});
        table_set(response_obj.object, copy_string("found"), json_bool(false));
    }
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.removeParam request
// Params: { "key": string }
handle_context_remove_param :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.removeParam requires an object parameter"
        );
        return result;
    }

    // Get key from params
    found_key, key_val := table_find(request.params.object, "key");
    if !found_key || key_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.removeParam requires a 'key' string parameter"
        );
        return result;
    }

    // Remove the parameter
    removed, new_version := remove_user_param(store, key_val.str);

    // Build response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("version"), json_number(cast(float64) new_version));
    table_set(response_obj.object, copy_string("removed"), json_bool(removed));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a context.* method to the appropriate handler
route_context_method :: (store: *Context_Store, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Check for context.* methods
    if request.method == {
        case "context.get";
            return handle_context_get(store, request);
        case "context.set";
            return handle_context_set(store, request);
        case "context.update";
            return handle_context_update(store, request);
        case "context.addTag";
            return handle_context_add_tag(store, request);
        case "context.removeTag";
            return handle_context_remove_tag(store, request);
        case "context.setParam";
            return handle_context_set_param(store, request);
        case "context.getParam";
            return handle_context_get_param(store, request);
        case "context.removeParam";
            return handle_context_remove_param(store, request);
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

// Check if a method is a context.* method
is_context_method :: (method: string) -> bool {
    return begins_with(method, "context.");
}

// Route a context.* method to multi-context registry handlers
// Use this for context.list, context.switch, context.create, context.delete
route_context_registry_method :: (registry: *Context_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    if request.method == {
        case "context.list";
            return handle_context_list(registry, request);
        case "context.switch";
            return handle_context_switch(registry, request);
        case "context.create";
            return handle_context_create(registry, request);
        case "context.delete";
            return handle_context_delete(registry, request);
        case;
            result.success = false;
            result.response = create_error_response(
                request.id,
                JSONRPC_METHOD_NOT_FOUND,
                tprint("Unknown registry method: %", request.method)
            );
            return result;
    }
}

// Check if a method is a context registry method (uses Context_Registry instead of Context_Store)
is_context_registry_method :: (method: string) -> bool {
    return method == "context.list" ||
           method == "context.switch" ||
           method == "context.create" ||
           method == "context.delete";
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert a Context to a JSON_Value object
// All strings are copied so the result can be safely freed
context_to_json :: (ctx: *Context) -> jason.JSON_Value {
    result := json_object();

    // Add simple fields - copy all strings since json_value stores references
    table_set(result.object, copy_string("project_id"), jason.json_value(copy_string(ctx.project_id)));
    table_set(result.object, copy_string("profile"), jason.json_value(copy_string(ctx.profile)));
    table_set(result.object, copy_string("environment"), jason.json_value(copy_string(ctx.environment)));
    table_set(result.object, copy_string("version"), json_number(cast(float64) ctx.version));

    // Add tags array
    tags_array: jason.JSON_Value;
    tags_array.type = .ARRAY;
    tags_dyn: [..] jason.JSON_Value;
    for ctx.tags {
        array_add(*tags_dyn, jason.json_value(copy_string(it)));
    }
    tags_array.array = tags_dyn;
    table_set(result.object, copy_string("tags"), tags_array);

    // Add workspace_metadata object
    ws_meta := json_object();
    for ctx.workspace_metadata {
        table_set(ws_meta.object, copy_string(it_index), jason.json_value(copy_string(it)));
    }
    table_set(result.object, copy_string("workspace_metadata"), ws_meta);

    // Add user_params object
    user_params := json_object();
    for ctx.user_params {
        table_set(user_params.object, copy_string(it_index), jason.json_value(copy_string(it)));
    }
    table_set(result.object, copy_string("user_params"), user_params);

    return result;
}

// Parse a Context from a JSON_Value object
// Returns: context, success, error message
json_to_context :: (json: jason.JSON_Value) -> Context, bool, string {
    ctx: Context;

    if json.type != .OBJECT {
        return ctx, false, "Expected object";
    }

    obj := json.object;

    // Parse project_id
    found, val := table_find(obj, "project_id");
    if found {
        if val.type != .STRING {
            return ctx, false, "project_id must be a string";
        }
        ctx.project_id = copy_string(val.str);
    } else {
        ctx.project_id = copy_string("");
    }

    // Parse profile
    found, val = table_find(obj, "profile");
    if found {
        if val.type != .STRING {
            free(ctx.project_id);
            return ctx, false, "profile must be a string";
        }
        ctx.profile = copy_string(val.str);
    } else {
        ctx.profile = copy_string("");
    }

    // Parse environment
    found, val = table_find(obj, "environment");
    if found {
        if val.type != .STRING {
            free(ctx.project_id);
            free(ctx.profile);
            return ctx, false, "environment must be a string";
        }
        ctx.environment = copy_string(val.str);
    } else {
        ctx.environment = copy_string("");
    }

    // Parse tags
    found, val = table_find(obj, "tags");
    if found {
        if val.type != .ARRAY {
            free(ctx.project_id);
            free(ctx.profile);
            free(ctx.environment);
            return ctx, false, "tags must be an array";
        }
        for val.array {
            if it.type != .STRING {
                // Cleanup on error
                for ctx.tags free(it);
                array_free(ctx.tags);
                free(ctx.project_id);
                free(ctx.profile);
                free(ctx.environment);
                return ctx, false, "tags must contain only strings";
            }
            array_add(*ctx.tags, copy_string(it.str));
        }
    }

    // Parse workspace_metadata
    found, val = table_find(obj, "workspace_metadata");
    if found {
        if val.type != .OBJECT {
            free_context(*ctx);
            return ctx, false, "workspace_metadata must be an object";
        }
        for val.object {
            if it.type != .STRING {
                free_context(*ctx);
                return ctx, false, "workspace_metadata values must be strings";
            }
            table_set(*ctx.workspace_metadata, copy_string(it_index), copy_string(it.str));
        }
    }

    // Parse user_params
    found, val = table_find(obj, "user_params");
    if found {
        if val.type != .OBJECT {
            free_context(*ctx);
            return ctx, false, "user_params must be an object";
        }
        for val.object {
            if it.type != .STRING {
                free_context(*ctx);
                return ctx, false, "user_params values must be strings";
            }
            table_set(*ctx.user_params, copy_string(it_index), copy_string(it.str));
        }
    }

    return ctx, true, "";
}

// Build a response object for set/update operations
build_set_response :: (version: u64, change: *Context_Change) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("version"), json_number(cast(float64) version));

    // Add changed_fields array
    changed: jason.JSON_Value;
    changed.type = .ARRAY;
    changed_dyn: [..] jason.JSON_Value;
    for change.changed_fields {
        // Copy the string since json_value stores a reference
        array_add(*changed_dyn, jason.json_value(copy_string(it)));
    }
    changed.array = changed_dyn;
    table_set(result.object, copy_string("changed_fields"), changed);

    return result;
}

// Build a response for tag operations
build_tag_response :: (version: u64, success: bool, operation: string) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("version"), json_number(cast(float64) version));
    table_set(result.object, copy_string(operation), json_bool(success));

    return result;
}

// Build a response for param set operations
build_param_response :: (version: u64) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("version"), json_number(cast(float64) version));

    return result;
}

// ============================================================================
// Multi-Context API Handlers (New)
// ============================================================================

// Handle context.list request
// Returns all defined contexts with their argument schemas
handle_context_list :: (registry: *Context_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Get all context definitions
    definitions := list_context_definitions(registry);
    defer {
        for *definitions free_context_definition(it);
        array_free(definitions);
    }

    // Get history
    history := get_history(registry);
    defer {
        for history free(it);
        array_free(history);
    }

    // Build response object
    response_obj := json_object();
    defer jason.json_free(response_obj);

    // Add contexts array
    contexts_array: jason.JSON_Value;
    contexts_array.type = .ARRAY;
    contexts_dyn: [..] jason.JSON_Value;

    for *definitions {
        ctx_json := context_definition_to_json(it);
        array_add(*contexts_dyn, ctx_json);
    }
    contexts_array.array = contexts_dyn;
    table_set(response_obj.object, copy_string("contexts"), contexts_array);

    // Add history array
    history_array: jason.JSON_Value;
    history_array.type = .ARRAY;
    history_dyn: [..] jason.JSON_Value;

    for history {
        array_add(*history_dyn, jason.json_value(copy_string(it)));
    }
    history_array.array = history_dyn;
    table_set(response_obj.object, copy_string("history"), history_array);

    // Add active context info
    active, has_active := get_active_context(registry);
    if has_active {
        defer free_active_context(*active);
        active_json := json_object();
        table_set(active_json.object, copy_string("name"), jason.json_value(copy_string(active.name)));
        table_set(active_json.object, copy_string("raw_input"), jason.json_value(copy_string(active.raw_input)));
        table_set(response_obj.object, copy_string("active"), active_json);
    } else {
        null_val: jason.JSON_Value;
        null_val.type = .NULL;
        table_set(response_obj.object, copy_string("active"), null_val);
    }

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.switch request
// Params: { input: "work --mode=programming" }
handle_context_switch :: (registry: *Context_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.switch requires an object parameter"
        );
        return result;
    }

    // Get input string
    found_input, input_val := table_find(request.params.object, "input");
    if !found_input || input_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.switch requires an 'input' string parameter"
        );
        return result;
    }

    input := input_val.str;

    // Parse the input
    parsed := parse_context_input(input);
    defer free_parsed_input(*parsed);

    if !parsed.success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            tprint("Failed to parse input: %", parsed.error)
        );
        return result;
    }

    // Build args and flags tables from parsed input
    args: Table(string, string);
    flags: Table(string, bool);
    defer {
        for args { free(it); free(it_index); }
        deinit(*args);
        for flags { free(it_index); }
        deinit(*flags);
    }

    for parsed.args {
        if it.is_flag {
            table_set(*flags, copy_string(it_index), true);
        } else {
            table_set(*args, copy_string(it_index), copy_string(it.value));
        }
    }

    // Switch context
    success, err := switch_context_by_input(registry, parsed.name, *args, *flags, input);

    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            -1001,  // Context not found / validation error
            err
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    defer jason.json_free(response_obj);

    table_set(response_obj.object, copy_string("success"), json_bool(true));
    table_set(response_obj.object, copy_string("name"), jason.json_value(copy_string(parsed.name)));
    table_set(response_obj.object, copy_string("input"), jason.json_value(copy_string(input)));

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.create request
// Params: { name: "work", description?: "...", args?: [...] }
handle_context_create :: (registry: *Context_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.create requires an object parameter"
        );
        return result;
    }

    // Get name
    found_name, name_val := table_find(request.params.object, "name");
    if !found_name || name_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.create requires a 'name' string parameter"
        );
        return result;
    }

    // Build context definition
    def: Context_Definition;
    def.name = copy_string(name_val.str);

    // Parse optional description
    found_desc, desc_val := table_find(request.params.object, "description");
    if found_desc && desc_val.type == .STRING {
        def.description = copy_string(desc_val.str);
    }

    // TODO: Parse args array if provided

    // Add to registry
    success := add_context_definition(registry, *def);
    free_context_definition(*def);

    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            -1002,  // Context already exists
            tprint("Context '%' already exists", name_val.str)
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    defer jason.json_free(response_obj);

    table_set(response_obj.object, copy_string("success"), json_bool(true));
    table_set(response_obj.object, copy_string("name"), jason.json_value(copy_string(name_val.str)));

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Handle context.delete request
// Params: { name: "work" }
handle_context_delete :: (registry: *Context_Registry, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.delete requires an object parameter"
        );
        return result;
    }

    // Get name
    found_name, name_val := table_find(request.params.object, "name");
    if !found_name || name_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "context.delete requires a 'name' string parameter"
        );
        return result;
    }

    // Remove from registry
    success := remove_context_definition(registry, name_val.str);

    if !success {
        result.success = false;
        result.response = create_error_response(
            request.id,
            -1001,  // Context not found
            tprint("Context '%' not found", name_val.str)
        );
        return result;
    }

    // Build success response
    response_obj := json_object();
    defer jason.json_free(response_obj);

    table_set(response_obj.object, copy_string("success"), json_bool(true));
    table_set(response_obj.object, copy_string("name"), jason.json_value(copy_string(name_val.str)));

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// Convert Context_Definition to JSON
context_definition_to_json :: (def: *Context_Definition) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("name"), jason.json_value(copy_string(def.name)));
    table_set(result.object, copy_string("description"), jason.json_value(copy_string(def.description)));

    // Add args array
    args_array: jason.JSON_Value;
    args_array.type = .ARRAY;
    args_dyn: [..] jason.JSON_Value;

    for *def.args {
        arg_json := arg_definition_to_json(it);
        array_add(*args_dyn, arg_json);
    }
    args_array.array = args_dyn;
    table_set(result.object, copy_string("args"), args_array);

    return result;
}

// Convert Arg_Definition to JSON
arg_definition_to_json :: (arg: *Arg_Definition) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("name"), jason.json_value(copy_string(arg.name)));
    table_set(result.object, copy_string("short"), jason.json_value(copy_string(arg.short)));
    table_set(result.object, copy_string("type"), jason.json_value(copy_string(arg_type_to_string(arg.arg_type))));
    table_set(result.object, copy_string("default"), jason.json_value(copy_string(arg.default_value)));
    table_set(result.object, copy_string("required"), json_bool(arg.required));
    table_set(result.object, copy_string("description"), jason.json_value(copy_string(arg.description)));

    // Add values array for enums
    values_array: jason.JSON_Value;
    values_array.type = .ARRAY;
    values_dyn: [..] jason.JSON_Value;

    for arg.values {
        array_add(*values_dyn, jason.json_value(copy_string(it)));
    }
    values_array.array = values_dyn;
    table_set(result.object, copy_string("values"), values_array);

    return result;
}

// Convert Arg_Type to string
arg_type_to_string :: (t: Arg_Type) -> string {
    if t == {
        case .STRING; return "string";
        case .FLAG;   return "flag";
        case .ENUM;   return "enum";
        case .INT;    return "int";
        case .FLOAT;  return "float";
    }
    return "string";
}
