// Preview API Handlers
//
// This module implements JSON-RPC API handlers for preview operations:
// - preview.get       - Get what would change with a proposed context
// - preview.getVisual - Get a formatted visual preview (text/ansi)
//
// The preview system queries registered services that have provides_preview=true
// and aggregates their responses to show what would happen before activating
// a context change.
//
// All handlers take a JSON-RPC request and return a JSON response string.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - context_store.jai (for Context, Context_Store, etc.)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)
// - api/context.jai (for json_object, json_number, json_bool, API_Result)
// - api/service.jai (for Service_Registry, Registered_Service, etc.)

// ============================================================================
// Preview Data Structures
// ============================================================================

// Status of a service preview request
Preview_Status :: enum {
    PENDING;      // Not yet collected
    SUCCESS;      // Preview collected successfully
    ERROR;        // Service returned an error
    TIMEOUT;      // Service did not respond in time
    UNAVAILABLE;  // Service not reachable
    NO_PREVIEW;   // Service doesn't provide preview capability
}

// A single action that a service would perform
Preview_Action :: struct {
    action_type: string;     // e.g., "create", "modify", "delete", "execute"
    target: string;          // What the action targets (file path, setting name, etc.)
    description: string;     // Human-readable description
    severity: string;        // "info", "warning", "destructive"
    reversible: bool;        // Whether this action can be undone
}

// Preview response from a single service
Service_Preview :: struct {
    service_id: string;
    service_name: string;
    status: Preview_Status;
    error_message: string;   // Set if status is ERROR
    actions: [..] Preview_Action;
    summary: string;         // Short summary of what this service would do
    estimated_duration_ms: u32;  // Estimated time to execute (0 if unknown)
}

// Full preview response aggregating all services
Preview_Response :: struct {
    proposed_context: Context;    // The context that was proposed
    current_context: Context;     // The current context for comparison
    changed_fields: [..] string;  // Fields that would change
    services: [..] Service_Preview;
    total_actions: u32;
    has_destructive_actions: bool;
    has_warnings: bool;
    overall_summary: string;      // Combined summary
}

// Visual format options
Visual_Format :: enum {
    TEXT;     // Plain text
    ANSI;     // ANSI colored text
    MARKDOWN; // Markdown format
}

// ============================================================================
// Preview Manager
// ============================================================================

// Thread-safe manager for collecting previews
Preview_Manager :: struct {
    service_registry: *Service_Registry;  // Reference to service registry
    context_store: *Context_Store;        // Reference to context store
    default_timeout_ms: u32;              // Default timeout for preview requests
    initialized: bool;
}

// Initialize preview manager
init_preview_manager :: (manager: *Preview_Manager, service_registry: *Service_Registry, context_store: *Context_Store) {
    manager.service_registry = service_registry;
    manager.context_store = context_store;
    manager.default_timeout_ms = 5000;  // 5 second default timeout
    manager.initialized = true;
}

// Destroy preview manager
destroy_preview_manager :: (manager: *Preview_Manager) {
    if !manager.initialized return;
    manager.initialized = false;
}

// Collect preview from all services that provide previews
// This is a synchronous version - for real implementation, this would
// make async calls to services and aggregate responses
collect_preview :: (manager: *Preview_Manager, proposed_context: *Context) -> Preview_Response {
    response: Preview_Response;

    // Copy proposed and current contexts
    response.proposed_context = copy_context(proposed_context);
    response.current_context = get_context(manager.context_store);

    // Determine what would change
    detect_changed_fields(*response);

    // Get all services that provide previews
    services := get_all_services(manager.service_registry);
    defer free_services_array(*services);

    for *services {
        if it.capabilities.provides_preview {
            // Collect preview from this service
            preview := collect_service_preview(manager, it, proposed_context);
            array_add(*response.services, preview);

            // Update aggregate stats
            response.total_actions += cast(u32) preview.actions.count;
            for *preview.actions {
                if it.severity == "destructive" response.has_destructive_actions = true;
                if it.severity == "warning" response.has_warnings = true;
            }
        }
    }

    // Generate overall summary
    response.overall_summary = generate_overall_summary(*response);

    return response;
}

// Collect preview from a single service
// In a full implementation, this would make an IPC call to the service
// For now, returns a placeholder indicating the service would be queried
collect_service_preview :: (manager: *Preview_Manager, service: *Registered_Service, proposed_context: *Context) -> Service_Preview {
    preview: Service_Preview;

    preview.service_id = copy_string(service.id);
    preview.service_name = copy_string(service.name);

    // Check if service has a preview callback defined
    if service.preview_callback.count == 0 {
        preview.status = .NO_PREVIEW;
        preview.summary = copy_string("Service registered for previews but no callback defined");
        return preview;
    }

    // In a full implementation, we would:
    // 1. Connect to service.endpoint
    // 2. Send JSON-RPC request to service.preview_callback
    // 3. Parse response and populate actions
    // For now, mark as pending (would be collected asynchronously)
    preview.status = .PENDING;
    preview.summary = copy_string(tprint("Would query % at %", service.preview_callback, service.endpoint));

    return preview;
}

// Detect which fields would change between current and proposed context
detect_changed_fields :: (response: *Preview_Response) {
    curr := *response.current_context;
    prop := *response.proposed_context;

    if curr.project_id != prop.project_id {
        array_add(*response.changed_fields, copy_string("project_id"));
    }
    if curr.profile != prop.profile {
        array_add(*response.changed_fields, copy_string("profile"));
    }
    if curr.environment != prop.environment {
        array_add(*response.changed_fields, copy_string("environment"));
    }
    if !arrays_equal(curr.tags, prop.tags) {
        array_add(*response.changed_fields, copy_string("tags"));
    }
    // Note: workspace_metadata and user_params comparison would need
    // table comparison which is more complex - skipping for now
}

// Generate an overall summary from all service previews
generate_overall_summary :: (response: *Preview_Response) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    // Report on field changes
    if response.changed_fields.count > 0 {
        append(*builder, tprint("% field(s) would change. ", response.changed_fields.count));
    } else {
        append(*builder, "No fields would change. ");
    }

    // Report on services
    if response.services.count == 0 {
        append(*builder, "No services registered for preview.");
    } else {
        pending_count := 0;
        success_count := 0;
        error_count := 0;

        for *response.services {
            if it.status == {
                case .PENDING; pending_count += 1;
                case .SUCCESS; success_count += 1;
                case .ERROR; #through;
                case .TIMEOUT; #through;
                case .UNAVAILABLE; error_count += 1;
            }
        }

        append(*builder, tprint("% service(s) queried", response.services.count));

        if response.has_destructive_actions {
            append(*builder, " (contains destructive actions!)");
        } else if response.has_warnings {
            append(*builder, " (contains warnings)");
        }

        append(*builder, ".");
    }

    return builder_to_string(*builder);
}

// ============================================================================
// Memory Management
// ============================================================================

// Free a preview action
free_preview_action :: (action: *Preview_Action) {
    free(action.action_type);
    free(action.target);
    free(action.description);
    free(action.severity);
}

// Free a service preview
free_service_preview :: (preview: *Service_Preview) {
    free(preview.service_id);
    free(preview.service_name);
    free(preview.error_message);
    free(preview.summary);
    for *preview.actions {
        free_preview_action(it);
    }
    array_free(preview.actions);
}

// Free a preview response
free_preview_response :: (response: *Preview_Response) {
    free_context(*response.proposed_context);
    free_context(*response.current_context);
    for response.changed_fields free(it);
    array_free(response.changed_fields);
    for *response.services {
        free_service_preview(it);
    }
    array_free(response.services);
    free(response.overall_summary);
}

// ============================================================================
// Preview API Handlers
// ============================================================================

// Handle preview.get request
// Params: { "proposed_context": {...} }
// Returns: Preview_Response with all service previews
handle_preview_get :: (manager: *Preview_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "preview.get requires an object parameter"
        );
        return result;
    }

    // Get proposed_context from params
    found, ctx_val := table_find(request.params.object, "proposed_context");
    if !found || ctx_val.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "preview.get requires a 'proposed_context' object parameter"
        );
        return result;
    }

    // Parse proposed context
    proposed, parse_ok, parse_error := json_to_context(ctx_val);
    if !parse_ok {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            parse_error
        );
        return result;
    }
    defer free_context(*proposed);

    // Collect preview
    preview := collect_preview(manager, *proposed);
    defer free_preview_response(*preview);

    // Convert to JSON
    preview_json := preview_response_to_json(*preview);
    defer jason.json_free(preview_json);

    result.success = true;
    result.response = create_response(request.id, preview_json);

    return result;
}

// Handle preview.getVisual request
// Params: { "proposed_context": {...}, "format": "text"|"ansi"|"markdown" }
// Returns: { "preview": "formatted string", "format": "text" }
handle_preview_get_visual :: (manager: *Preview_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "preview.getVisual requires an object parameter"
        );
        return result;
    }

    // Get proposed_context from params
    found, ctx_val := table_find(request.params.object, "proposed_context");
    if !found || ctx_val.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "preview.getVisual requires a 'proposed_context' object parameter"
        );
        return result;
    }

    // Get optional format parameter (default to TEXT)
    format := Visual_Format.TEXT;
    found_fmt, fmt_val := table_find(request.params.object, "format");
    if found_fmt && fmt_val.type == .STRING {
        if fmt_val.str == "ansi" {
            format = .ANSI;
        } else if fmt_val.str == "markdown" {
            format = .MARKDOWN;
        }
        // else default TEXT
    }

    // Parse proposed context
    proposed, parse_ok, parse_error := json_to_context(ctx_val);
    if !parse_ok {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            parse_error
        );
        return result;
    }
    defer free_context(*proposed);

    // Collect preview
    preview := collect_preview(manager, *proposed);
    defer free_preview_response(*preview);

    // Format the preview
    formatted := format_preview(*preview, format);
    defer free(formatted);

    // Build response
    response_obj := json_object();
    table_set(response_obj.object, copy_string("preview"), jason.json_value(copy_string(formatted)));

    format_str := ifx format == .ANSI then "ansi" else ifx format == .MARKDOWN then "markdown" else "text";
    table_set(response_obj.object, copy_string("format"), jason.json_value(copy_string(format_str)));
    defer jason.json_free(response_obj);

    result.success = true;
    result.response = create_response(request.id, response_obj);

    return result;
}

// ============================================================================
// Visual Formatting
// ============================================================================

// Format a preview response for visual display
format_preview :: (preview: *Preview_Response, format: Visual_Format) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    // Header
    if format == .MARKDOWN {
        append(*builder, "# Context Change Preview\n\n");
    } else if format == .ANSI {
        append(*builder, "\x1b[1;36m=== Context Change Preview ===\x1b[0m\n\n");
    } else {
        append(*builder, "=== Context Change Preview ===\n\n");
    }

    // Changed fields section
    if preview.changed_fields.count > 0 {
        if format == .MARKDOWN {
            append(*builder, "## Changes\n\n");
        } else if format == .ANSI {
            append(*builder, "\x1b[1mChanges:\x1b[0m\n");
        } else {
            append(*builder, "Changes:\n");
        }

        for preview.changed_fields {
            if format == .MARKDOWN {
                append(*builder, tprint("- **%**\n", it));
            } else if format == .ANSI {
                append(*builder, tprint("  \x1b[33m•\x1b[0m %\n", it));
            } else {
                append(*builder, tprint("  • %\n", it));
            }
        }
        append(*builder, "\n");
    } else {
        append(*builder, "No context fields would change.\n\n");
    }

    // Services section
    if preview.services.count > 0 {
        if format == .MARKDOWN {
            append(*builder, "## Service Actions\n\n");
        } else if format == .ANSI {
            append(*builder, "\x1b[1mService Actions:\x1b[0m\n");
        } else {
            append(*builder, "Service Actions:\n");
        }

        for *preview.services {
            format_service_preview(*builder, it, format);
        }
    } else {
        append(*builder, "No services registered for preview.\n");
    }

    // Summary
    append(*builder, "\n");
    if format == .MARKDOWN {
        append(*builder, tprint("**Summary:** %\n", preview.overall_summary));
    } else if format == .ANSI {
        if preview.has_destructive_actions {
            append(*builder, tprint("\x1b[1;31mSummary: %\x1b[0m\n", preview.overall_summary));
        } else if preview.has_warnings {
            append(*builder, tprint("\x1b[1;33mSummary: %\x1b[0m\n", preview.overall_summary));
        } else {
            append(*builder, tprint("\x1b[1mSummary:\x1b[0m %\n", preview.overall_summary));
        }
    } else {
        append(*builder, tprint("Summary: %\n", preview.overall_summary));
    }

    return builder_to_string(*builder);
}

// Format a single service preview
format_service_preview :: (builder: *String_Builder, preview: *Service_Preview, format: Visual_Format) {
    // Service header
    status_str := get_status_string(preview.status);

    if format == .MARKDOWN {
        append(builder, tprint("### % (%)\n\n", preview.service_name, status_str));
    } else if format == .ANSI {
        status_color := get_status_color(preview.status);
        append(builder, tprint("\n  \x1b[1m%\x1b[0m [\x1b[%m%\x1b[0m]\n", preview.service_name, status_color, status_str));
    } else {
        append(builder, tprint("\n  % [%]\n", preview.service_name, status_str));
    }

    // Summary
    if preview.summary.count > 0 {
        if format == .MARKDOWN {
            append(builder, tprint("%\n\n", preview.summary));
        } else {
            append(builder, tprint("    %\n", preview.summary));
        }
    }

    // Actions
    for *preview.actions {
        format_preview_action(builder, it, format);
    }

    // Error message if any
    if preview.error_message.count > 0 {
        if format == .ANSI {
            append(builder, tprint("    \x1b[31mError: %\x1b[0m\n", preview.error_message));
        } else {
            append(builder, tprint("    Error: %\n", preview.error_message));
        }
    }
}

// Format a single preview action
format_preview_action :: (builder: *String_Builder, action: *Preview_Action, format: Visual_Format) {
    severity_indicator := get_severity_indicator(action.severity, format);

    if format == .MARKDOWN {
        append(builder, tprint("- %**%** `%`: %\n",
            severity_indicator,
            action.action_type,
            action.target,
            action.description
        ));
    } else {
        append(builder, tprint("      %[%] %: %\n",
            severity_indicator,
            action.action_type,
            action.target,
            action.description
        ));
    }
}

// Get string representation of status
get_status_string :: (status: Preview_Status) -> string {
    if status == {
        case .PENDING;     return "pending";
        case .SUCCESS;     return "success";
        case .ERROR;       return "error";
        case .TIMEOUT;     return "timeout";
        case .UNAVAILABLE; return "unavailable";
        case .NO_PREVIEW;  return "no-preview";
    }
    return "unknown";
}

// Get ANSI color code for status
get_status_color :: (status: Preview_Status) -> string {
    if status == {
        case .PENDING;     return "33";  // yellow
        case .SUCCESS;     return "32";  // green
        case .ERROR;       return "31";  // red
        case .TIMEOUT;     return "31";  // red
        case .UNAVAILABLE; return "31";  // red
        case .NO_PREVIEW;  return "90";  // gray
    }
    return "0";
}

// Get severity indicator for actions
get_severity_indicator :: (severity: string, format: Visual_Format) -> string {
    if format == .ANSI {
        if severity == "destructive" return "\x1b[31m⚠ \x1b[0m";
        if severity == "warning" return "\x1b[33m! \x1b[0m";
        return "";
    } else if format == .MARKDOWN {
        if severity == "destructive" return "⚠️ ";
        if severity == "warning" return "⚠ ";
        return "";
    } else {
        if severity == "destructive" return "[!] ";
        if severity == "warning" return "[!] ";
        return "";
    }
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert Preview_Response to JSON
preview_response_to_json :: (response: *Preview_Response) -> jason.JSON_Value {
    result := json_object();

    // Add proposed and current context
    table_set(result.object, copy_string("proposed_context"), context_to_json(*response.proposed_context));
    table_set(result.object, copy_string("current_context"), context_to_json(*response.current_context));

    // Add changed fields array
    changed_array: jason.JSON_Value;
    changed_array.type = .ARRAY;
    changed_dyn: [..] jason.JSON_Value;
    for response.changed_fields {
        array_add(*changed_dyn, jason.json_value(copy_string(it)));
    }
    changed_array.array = changed_dyn;
    table_set(result.object, copy_string("changed_fields"), changed_array);

    // Add services array
    services_array: jason.JSON_Value;
    services_array.type = .ARRAY;
    services_dyn: [..] jason.JSON_Value;
    for *response.services {
        array_add(*services_dyn, service_preview_to_json(it));
    }
    services_array.array = services_dyn;
    table_set(result.object, copy_string("services"), services_array);

    // Add aggregate stats
    table_set(result.object, copy_string("total_actions"), json_number(cast(float64) response.total_actions));
    table_set(result.object, copy_string("has_destructive_actions"), json_bool(response.has_destructive_actions));
    table_set(result.object, copy_string("has_warnings"), json_bool(response.has_warnings));
    table_set(result.object, copy_string("overall_summary"), jason.json_value(copy_string(response.overall_summary)));

    return result;
}

// Convert Service_Preview to JSON
service_preview_to_json :: (preview: *Service_Preview) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("service_id"), jason.json_value(copy_string(preview.service_id)));
    table_set(result.object, copy_string("service_name"), jason.json_value(copy_string(preview.service_name)));
    table_set(result.object, copy_string("status"), jason.json_value(copy_string(get_status_string(preview.status))));
    table_set(result.object, copy_string("error_message"), jason.json_value(copy_string(preview.error_message)));
    table_set(result.object, copy_string("summary"), jason.json_value(copy_string(preview.summary)));
    table_set(result.object, copy_string("estimated_duration_ms"), json_number(cast(float64) preview.estimated_duration_ms));

    // Add actions array
    actions_array: jason.JSON_Value;
    actions_array.type = .ARRAY;
    actions_dyn: [..] jason.JSON_Value;
    for *preview.actions {
        array_add(*actions_dyn, preview_action_to_json(it));
    }
    actions_array.array = actions_dyn;
    table_set(result.object, copy_string("actions"), actions_array);

    return result;
}

// Convert Preview_Action to JSON
preview_action_to_json :: (action: *Preview_Action) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("action_type"), jason.json_value(copy_string(action.action_type)));
    table_set(result.object, copy_string("target"), jason.json_value(copy_string(action.target)));
    table_set(result.object, copy_string("description"), jason.json_value(copy_string(action.description)));
    table_set(result.object, copy_string("severity"), jason.json_value(copy_string(action.severity)));
    table_set(result.object, copy_string("reversible"), json_bool(action.reversible));

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a preview.* method to the appropriate handler
route_preview_method :: (manager: *Preview_Manager, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    if request.method == {
        case "preview.get";
            return handle_preview_get(manager, request);
        case "preview.getVisual";
            return handle_preview_get_visual(manager, request);
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

// Check if a method is a preview.* method
is_preview_method :: (method: string) -> bool {
    return begins_with(method, "preview.");
}
