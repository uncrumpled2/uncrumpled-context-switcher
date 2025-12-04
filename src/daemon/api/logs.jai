// Execution Log API Handlers
//
// This module implements JSON-RPC API handlers for execution log operations:
// - logs.list       - List recent execution logs
// - logs.get        - Get a specific execution log by ID
// - logs.byService  - Get logs filtered by service ID
//
// The execution log system tracks step-by-step execution history for each
// context change, similar to CI/CD systems like CircleCI. Each context change
// creates an execution log that records what each service did.
//
// All handlers take a JSON-RPC request and return a JSON response string.

// Note: This file expects the following to already be imported/loaded:
// - Basic, String, Hash_Table, Thread
// - jason module (as jason::)
// - context_store.jai (for Context, Context_Change, etc.)
// - rpc/protocol.jai (for JSONRPC_*, parse_*, create_*, etc.)
// - api/context.jai (for json_object, json_number, json_bool, API_Result)

// ============================================================================
// Execution Log Data Structures
// ============================================================================

// Log level for individual log entries
Log_Level :: enum u8 {
    DEBUG :: 0;
    INFO  :: 1;
    WARN  :: 2;
    ERROR :: 3;
}

// A single log entry within an execution step
Log_Entry :: struct {
    timestamp: Apollo_Time;
    level: Log_Level;
    message: string;
}

// Status of an execution step
Step_Status :: enum u8 {
    PENDING   :: 0;  // Step not yet started
    RUNNING   :: 1;  // Step currently executing
    COMPLETED :: 2;  // Step finished successfully
    FAILED    :: 3;  // Step finished with error
    SKIPPED   :: 4;  // Step was skipped (e.g., service unavailable)
}

// A single step within an execution log (one per service)
Execution_Step :: struct {
    service_id: string;
    service_name: string;
    action: string;              // Description of what this step does
    started_at: Apollo_Time;
    completed_at: Apollo_Time;
    status: Step_Status;
    logs: [..] Log_Entry;        // Log entries from this step
    error: string;               // Error message if status is FAILED
}

// Overall status of an execution log
Execution_Status :: enum u8 {
    PENDING   :: 0;  // Execution not yet started
    RUNNING   :: 1;  // Execution in progress
    COMPLETED :: 2;  // All steps completed successfully
    FAILED    :: 3;  // One or more steps failed
    PARTIAL   :: 4;  // Some steps completed, some skipped/failed
}

// A complete execution log for a context change
Execution_Log :: struct {
    id: string;                  // Unique identifier (e.g., "exec-12345")
    context_change: Context_Change;  // The change that triggered this execution
    steps: [..] Execution_Step;  // Steps executed for each service
    started_at: Apollo_Time;
    completed_at: Apollo_Time;
    status: Execution_Status;
}

// ============================================================================
// Log Storage
// ============================================================================

// Thread-safe storage for execution logs
Log_Storage :: struct {
    logs: [..] Execution_Log;    // All stored logs (most recent first)
    logs_by_id: Table(string, *Execution_Log);  // Index by ID for fast lookup
    mutex: Mutex;
    initialized: bool;
    max_entries: u32;            // Maximum logs to keep (oldest pruned)
    next_id: u64;                // Counter for generating unique IDs
}

// Initialize log storage
init_log_storage :: (storage: *Log_Storage, max_entries: u32 = 1000) {
    init(*storage.mutex);
    storage.max_entries = max_entries;
    storage.next_id = 1;
    storage.initialized = true;
}

// Destroy log storage
destroy_log_storage :: (storage: *Log_Storage) {
    if !storage.initialized return;

    lock(*storage.mutex);

    // Free all logs
    for *storage.logs {
        free_execution_log(it);
    }
    array_free(storage.logs);
    deinit(*storage.logs_by_id);

    unlock(*storage.mutex);
    destroy(*storage.mutex);
    storage.initialized = false;
}

// Generate a new unique log ID
generate_log_id :: (storage: *Log_Storage) -> string {
    // Note: Caller must hold mutex
    id := storage.next_id;
    storage.next_id += 1;
    return copy_string(tprint("exec-%", id));
}

// Create a new execution log for a context change
// Returns the ID of the created log
create_execution_log :: (storage: *Log_Storage, change: *Context_Change) -> string {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    log: Execution_Log;
    log.id = generate_log_id(storage);
    log.context_change = copy_context_change(change);
    log.started_at = current_time_consensus();
    log.status = .PENDING;

    // Prune oldest logs if at capacity
    while storage.logs.count >= storage.max_entries && storage.logs.count > 0 {
        // Remove oldest (last in array since we prepend new logs)
        oldest := pop(*storage.logs);
        table_remove(*storage.logs_by_id, oldest.id);
        free_execution_log(*oldest);
    }

    // Add new log at the beginning (most recent first)
    array_insert_at(*storage.logs, log, 0);

    // Update index
    table_set(*storage.logs_by_id, copy_string(log.id), *storage.logs[0]);

    return copy_string(log.id);
}

// Get a log by ID
// Returns a copy of the log, or null if not found
get_execution_log :: (storage: *Log_Storage, id: string) -> Execution_Log, bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, id);
    if found {
        return copy_execution_log(log_ptr), true;
    }

    empty: Execution_Log;
    return empty, false;
}

// Get recent logs
// Returns copies of the most recent logs (up to limit)
get_recent_logs :: (storage: *Log_Storage, limit: u32 = 50) -> [..] Execution_Log {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    result: [..] Execution_Log;
    count := min(cast(s64) limit, storage.logs.count);

    for i: 0..count-1 {
        array_add(*result, copy_execution_log(*storage.logs[i]));
    }

    return result;
}

// Get logs by service ID
// Returns copies of logs that have steps for the given service
get_logs_by_service :: (storage: *Log_Storage, service_id: string, limit: u32 = 20) -> [..] Execution_Log {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    result: [..] Execution_Log;

    for *storage.logs {
        // Check if this log has a step for the service
        has_service := false;
        for *it.steps {
            if it.service_id == service_id {
                has_service = true;
                break;
            }
        }

        if has_service {
            array_add(*result, copy_execution_log(it));
            if result.count >= limit break;
        }
    }

    return result;
}

// Add a step to an execution log
add_execution_step :: (storage: *Log_Storage, log_id: string, step: *Execution_Step) -> bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, log_id);
    if !found return false;

    // Copy and add the step
    array_add(*log_ptr.steps, copy_execution_step(step));

    // Update overall status
    update_log_status(log_ptr);

    return true;
}

// Start an execution log (set status to RUNNING)
start_execution_log :: (storage: *Log_Storage, log_id: string) -> bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, log_id);
    if !found return false;

    log_ptr.status = .RUNNING;
    log_ptr.started_at = current_time_consensus();

    return true;
}

// Complete an execution log
complete_execution_log :: (storage: *Log_Storage, log_id: string) -> bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, log_id);
    if !found return false;

    log_ptr.completed_at = current_time_consensus();
    update_log_status(log_ptr);

    return true;
}

// Update step status
update_step_status :: (storage: *Log_Storage, log_id: string, service_id: string, status: Step_Status, error_msg := "") -> bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, log_id);
    if !found return false;

    // Find the step
    for *log_ptr.steps {
        if it.service_id == service_id {
            it.status = status;
            if status == .RUNNING {
                it.started_at = current_time_consensus();
            } else if status == .COMPLETED || status == .FAILED || status == .SKIPPED {
                it.completed_at = current_time_consensus();
            }
            if error_msg.count > 0 {
                free(it.error);
                it.error = copy_string(error_msg);
            }
            update_log_status(log_ptr);
            return true;
        }
    }

    return false;
}

// Add a log entry to a step
add_log_entry :: (storage: *Log_Storage, log_id: string, service_id: string, level: Log_Level, message: string) -> bool {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);

    found, log_ptr := table_find(*storage.logs_by_id, log_id);
    if !found return false;

    // Find the step
    for *log_ptr.steps {
        if it.service_id == service_id {
            entry: Log_Entry;
            entry.timestamp = current_time_consensus();
            entry.level = level;
            entry.message = copy_string(message);
            array_add(*it.logs, entry);
            return true;
        }
    }

    return false;
}

// Get count of logs
get_log_count :: (storage: *Log_Storage) -> s64 {
    lock(*storage.mutex);
    defer unlock(*storage.mutex);
    return storage.logs.count;
}

// Update the overall status of a log based on its steps
update_log_status :: (log: *Execution_Log) {
    if log.steps.count == 0 {
        // No steps yet, keep current status
        return;
    }

    has_running := false;
    has_pending := false;
    has_failed := false;
    has_completed := false;
    has_skipped := false;

    for *log.steps {
        if it.status == {
            case .RUNNING;   has_running = true;
            case .PENDING;   has_pending = true;
            case .FAILED;    has_failed = true;
            case .COMPLETED; has_completed = true;
            case .SKIPPED;   has_skipped = true;
        }
    }

    if has_running || has_pending {
        log.status = .RUNNING;
    } else if has_failed && has_completed {
        log.status = .PARTIAL;
    } else if has_failed {
        log.status = .FAILED;
    } else if has_completed {
        log.status = .COMPLETED;
    } else if has_skipped {
        log.status = .PARTIAL;
    }
}

// ============================================================================
// Memory Management
// ============================================================================

// Copy a log entry
copy_log_entry :: (entry: *Log_Entry) -> Log_Entry {
    result: Log_Entry;
    result.timestamp = entry.timestamp;
    result.level = entry.level;
    result.message = copy_string(entry.message);
    return result;
}

// Free a log entry
free_log_entry :: (entry: *Log_Entry) {
    free(entry.message);
}

// Copy an execution step
copy_execution_step :: (step: *Execution_Step) -> Execution_Step {
    result: Execution_Step;
    result.service_id = copy_string(step.service_id);
    result.service_name = copy_string(step.service_name);
    result.action = copy_string(step.action);
    result.started_at = step.started_at;
    result.completed_at = step.completed_at;
    result.status = step.status;
    result.error = copy_string(step.error);

    for *step.logs {
        array_add(*result.logs, copy_log_entry(it));
    }

    return result;
}

// Free an execution step
free_execution_step :: (step: *Execution_Step) {
    free(step.service_id);
    free(step.service_name);
    free(step.action);
    free(step.error);
    for *step.logs {
        free_log_entry(it);
    }
    array_free(step.logs);
}

// Copy a context change
copy_context_change :: (change: *Context_Change) -> Context_Change {
    result: Context_Change;
    result.previous_version = change.previous_version;
    result.new_version = change.new_version;
    result.timestamp = change.timestamp;

    for change.changed_fields {
        array_add(*result.changed_fields, copy_string(it));
    }

    return result;
}

// Free a context change
free_context_change :: (change: *Context_Change) {
    for change.changed_fields free(it);
    array_free(change.changed_fields);
}

// Copy an execution log
copy_execution_log :: (log: *Execution_Log) -> Execution_Log {
    result: Execution_Log;
    result.id = copy_string(log.id);
    result.context_change = copy_context_change(*log.context_change);
    result.started_at = log.started_at;
    result.completed_at = log.completed_at;
    result.status = log.status;

    for *log.steps {
        array_add(*result.steps, copy_execution_step(it));
    }

    return result;
}

// Free an execution log
free_execution_log :: (log: *Execution_Log) {
    free(log.id);
    free_context_change(*log.context_change);
    for *log.steps {
        free_execution_step(it);
    }
    array_free(log.steps);
}

// Free an array of execution logs
free_logs_array :: (logs: *[..] Execution_Log) {
    for *logs.* {
        free_execution_log(it);
    }
    array_free(logs.*);
}

// ============================================================================
// String Conversion Helpers
// ============================================================================

// Get string representation of log level
log_level_to_string :: (level: Log_Level) -> string {
    if level == {
        case .DEBUG; return "debug";
        case .INFO;  return "info";
        case .WARN;  return "warn";
        case .ERROR; return "error";
    }
    return "unknown";
}

// Parse log level from string
string_to_log_level :: (str: string) -> Log_Level, bool {
    if str == "debug" return .DEBUG, true;
    if str == "info"  return .INFO, true;
    if str == "warn"  return .WARN, true;
    if str == "error" return .ERROR, true;
    return .INFO, false;
}

// Get string representation of step status
step_status_to_string :: (status: Step_Status) -> string {
    if status == {
        case .PENDING;   return "pending";
        case .RUNNING;   return "running";
        case .COMPLETED; return "completed";
        case .FAILED;    return "failed";
        case .SKIPPED;   return "skipped";
    }
    return "unknown";
}

// Parse step status from string
string_to_step_status :: (str: string) -> Step_Status, bool {
    if str == "pending"   return .PENDING, true;
    if str == "running"   return .RUNNING, true;
    if str == "completed" return .COMPLETED, true;
    if str == "failed"    return .FAILED, true;
    if str == "skipped"   return .SKIPPED, true;
    return .PENDING, false;
}

// Get string representation of execution status
execution_status_to_string :: (status: Execution_Status) -> string {
    if status == {
        case .PENDING;   return "pending";
        case .RUNNING;   return "running";
        case .COMPLETED; return "completed";
        case .FAILED;    return "failed";
        case .PARTIAL;   return "partial";
    }
    return "unknown";
}

// Parse execution status from string
string_to_execution_status :: (str: string) -> Execution_Status, bool {
    if str == "pending"   return .PENDING, true;
    if str == "running"   return .RUNNING, true;
    if str == "completed" return .COMPLETED, true;
    if str == "failed"    return .FAILED, true;
    if str == "partial"   return .PARTIAL, true;
    return .PENDING, false;
}

// ============================================================================
// JSON Conversion Helpers
// ============================================================================

// Convert Log_Entry to JSON
log_entry_to_json :: (entry: *Log_Entry) -> jason.JSON_Value {
    result := json_object();

    // Convert timestamp to float (seconds since epoch)
    ts_seconds := cast(float64) to_seconds(entry.timestamp);
    table_set(result.object, copy_string("timestamp"), json_number(ts_seconds));
    table_set(result.object, copy_string("level"), jason.json_value(copy_string(log_level_to_string(entry.level))));
    table_set(result.object, copy_string("message"), jason.json_value(copy_string(entry.message)));

    return result;
}

// Convert Execution_Step to JSON
execution_step_to_json :: (step: *Execution_Step) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("service_id"), jason.json_value(copy_string(step.service_id)));
    table_set(result.object, copy_string("service_name"), jason.json_value(copy_string(step.service_name)));
    table_set(result.object, copy_string("action"), jason.json_value(copy_string(step.action)));
    table_set(result.object, copy_string("started_at"), json_number(cast(float64) to_seconds(step.started_at)));
    table_set(result.object, copy_string("completed_at"), json_number(cast(float64) to_seconds(step.completed_at)));
    table_set(result.object, copy_string("status"), jason.json_value(copy_string(step_status_to_string(step.status))));
    table_set(result.object, copy_string("error"), jason.json_value(copy_string(step.error)));

    // Add logs array
    logs_array: jason.JSON_Value;
    logs_array.type = .ARRAY;
    logs_dyn: [..] jason.JSON_Value;
    for *step.logs {
        array_add(*logs_dyn, log_entry_to_json(it));
    }
    logs_array.array = logs_dyn;
    table_set(result.object, copy_string("logs"), logs_array);

    return result;
}

// Convert Context_Change to JSON
context_change_to_json :: (change: *Context_Change) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("previous_version"), json_number(cast(float64) change.previous_version));
    table_set(result.object, copy_string("new_version"), json_number(cast(float64) change.new_version));
    table_set(result.object, copy_string("timestamp"), json_number(cast(float64) to_seconds(change.timestamp)));

    // Add changed_fields array
    fields_array: jason.JSON_Value;
    fields_array.type = .ARRAY;
    fields_dyn: [..] jason.JSON_Value;
    for change.changed_fields {
        array_add(*fields_dyn, jason.json_value(copy_string(it)));
    }
    fields_array.array = fields_dyn;
    table_set(result.object, copy_string("changed_fields"), fields_array);

    return result;
}

// Convert Execution_Log to JSON
execution_log_to_json :: (log: *Execution_Log) -> jason.JSON_Value {
    result := json_object();

    table_set(result.object, copy_string("id"), jason.json_value(copy_string(log.id)));
    table_set(result.object, copy_string("context_change"), context_change_to_json(*log.context_change));
    table_set(result.object, copy_string("started_at"), json_number(cast(float64) to_seconds(log.started_at)));
    table_set(result.object, copy_string("completed_at"), json_number(cast(float64) to_seconds(log.completed_at)));
    table_set(result.object, copy_string("status"), jason.json_value(copy_string(execution_status_to_string(log.status))));

    // Add steps array
    steps_array: jason.JSON_Value;
    steps_array.type = .ARRAY;
    steps_dyn: [..] jason.JSON_Value;
    for *log.steps {
        array_add(*steps_dyn, execution_step_to_json(it));
    }
    steps_array.array = steps_dyn;
    table_set(result.object, copy_string("steps"), steps_array);

    return result;
}

// ============================================================================
// Log API Handlers
// ============================================================================

// Handle logs.list request
// Params: { "limit": 50 } (optional, default 50)
// Returns: { "logs": [...], "count": N }
handle_logs_list :: (storage: *Log_Storage, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Get optional limit parameter
    limit: u32 = 50;
    if request.params.type == .OBJECT {
        found, limit_val := table_find(request.params.object, "limit");
        if found && limit_val.type == .NUMBER {
            limit = cast(u32) limit_val.number;
            if limit > 1000 limit = 1000;  // Cap at 1000
        }
    }

    // Get recent logs
    logs := get_recent_logs(storage, limit);
    defer free_logs_array(*logs);

    // Build response
    response := json_object();

    // Add logs array
    logs_array: jason.JSON_Value;
    logs_array.type = .ARRAY;
    logs_dyn: [..] jason.JSON_Value;
    for *logs {
        array_add(*logs_dyn, execution_log_to_json(it));
    }
    logs_array.array = logs_dyn;
    table_set(response.object, copy_string("logs"), logs_array);
    table_set(response.object, copy_string("count"), json_number(cast(float64) logs.count));
    defer jason.json_free(response);

    result.success = true;
    result.response = create_response(request.id, response);

    return result;
}

// Handle logs.get request
// Params: { "id": "exec-123" }
// Returns: The execution log or error if not found
handle_logs_get :: (storage: *Log_Storage, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "logs.get requires an object parameter"
        );
        return result;
    }

    // Get id parameter
    found, id_val := table_find(request.params.object, "id");
    if !found || id_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "logs.get requires an 'id' string parameter"
        );
        return result;
    }

    // Get the log
    log, found_log := get_execution_log(storage, id_val.str);
    if !found_log {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            tprint("Log not found: %", id_val.str)
        );
        return result;
    }
    defer free_execution_log(*log);

    // Convert to JSON
    log_json := execution_log_to_json(*log);
    defer jason.json_free(log_json);

    result.success = true;
    result.response = create_response(request.id, log_json);

    return result;
}

// Handle logs.byService request
// Params: { "service_id": "my-service", "limit": 20 }
// Returns: { "logs": [...], "count": N }
handle_logs_by_service :: (storage: *Log_Storage, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    // Validate params
    if request.params.type != .OBJECT {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "logs.byService requires an object parameter"
        );
        return result;
    }

    // Get service_id parameter
    found, service_id_val := table_find(request.params.object, "service_id");
    if !found || service_id_val.type != .STRING {
        result.success = false;
        result.response = create_error_response(
            request.id,
            JSONRPC_INVALID_PARAMS,
            "logs.byService requires a 'service_id' string parameter"
        );
        return result;
    }

    // Get optional limit parameter
    limit: u32 = 20;
    found_limit, limit_val := table_find(request.params.object, "limit");
    if found_limit && limit_val.type == .NUMBER {
        limit = cast(u32) limit_val.number;
        if limit > 1000 limit = 1000;  // Cap at 1000
    }

    // Get logs for service
    logs := get_logs_by_service(storage, service_id_val.str, limit);
    defer free_logs_array(*logs);

    // Build response
    response := json_object();

    // Add logs array
    logs_array: jason.JSON_Value;
    logs_array.type = .ARRAY;
    logs_dyn: [..] jason.JSON_Value;
    for *logs {
        array_add(*logs_dyn, execution_log_to_json(it));
    }
    logs_array.array = logs_dyn;
    table_set(response.object, copy_string("logs"), logs_array);
    table_set(response.object, copy_string("count"), json_number(cast(float64) logs.count));
    defer jason.json_free(response);

    result.success = true;
    result.response = create_response(request.id, response);

    return result;
}

// ============================================================================
// Method Router
// ============================================================================

// Route a logs.* method to the appropriate handler
route_logs_method :: (storage: *Log_Storage, request: *JSONRPC_Request) -> API_Result {
    result: API_Result;

    if request.method == {
        case "logs.list";
            return handle_logs_list(storage, request);
        case "logs.get";
            return handle_logs_get(storage, request);
        case "logs.byService";
            return handle_logs_by_service(storage, request);
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

// Check if a method is a logs.* method
is_logs_method :: (method: string) -> bool {
    return begins_with(method, "logs.");
}
