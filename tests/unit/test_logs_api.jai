// Unit tests for Execution Log API
//
// Tests the logs.list, logs.get, and logs.byService API handlers,
// Log_Storage, and related data structures.
//
// Note: All necessary modules are loaded by earlier test files:
// - test_jsonrpc.jai loads rpc/module.jai which loads protocol.jai
// - test_context_api.jai loads api/module.jai which now includes logs.jai

// ============================================================================
// Log Storage Tests
// ============================================================================

test_log_storage_init :: () -> bool {
    state := init_test_state("log_storage_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;

        init_log_storage(*storage, 100);

        assert_true(storage.initialized, "storage should be initialized");
        assert_equal(storage.max_entries, 100, "max_entries should be 100");
        assert_equal(storage.next_id, 1, "next_id should start at 1");
        assert_equal(storage.logs.count, 0, "should have no logs initially");

        destroy_log_storage(*storage);
        assert_false(storage.initialized, "storage should be destroyed");
    }

    return all_tests_passed(state);
}

test_log_storage_create_log :: () -> bool {
    state := init_test_state("log_storage_create_log", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create a context change
        change: Context_Change;
        change.previous_version = 1;
        change.new_version = 2;
        change.timestamp = current_time_consensus();
        array_add(*change.changed_fields, copy_string("project_id"));
        defer free_context_change(*change);

        // Create execution log
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        assert_string_contains(log_id, "exec-", "log ID should start with exec-");
        assert_equal(get_log_count(*storage), 1, "should have 1 log");

        // Retrieve the log
        log, found := get_execution_log(*storage, log_id);
        defer if found free_execution_log(*log);

        assert_true(found, "log should be found");
        assert_string_equal(log.id, log_id, "log ID should match");
        assert_equal(log.context_change.previous_version, 1, "previous version should match");
        assert_equal(log.context_change.new_version, 2, "new version should match");
        assert_equal(log.status, Execution_Status.PENDING, "status should be PENDING");
    }

    return all_tests_passed(state);
}

test_log_storage_pruning :: () -> bool {
    state := init_test_state("log_storage_pruning", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 5);  // Small max for testing
        defer destroy_log_storage(*storage);

        // Create 7 logs (should trigger pruning)
        change: Context_Change;
        change.previous_version = 0;
        change.new_version = 1;

        for i: 0..6 {
            change.previous_version = cast(u64) i;
            change.new_version = cast(u64) (i + 1);
            log_id := create_execution_log(*storage, *change);
            free(log_id);
        }

        // Should only have 5 logs (pruned 2)
        assert_equal(get_log_count(*storage), 5, "should have max 5 logs after pruning");

        // The most recent logs should be kept
        logs := get_recent_logs(*storage, 10);
        defer free_logs_array(*logs);

        assert_equal(logs.count, 5, "should return 5 logs");
        // Most recent should have highest version
        assert_equal(logs[0].context_change.new_version, 7, "most recent log should have version 7");
    }

    return all_tests_passed(state);
}

test_log_storage_add_steps :: () -> bool {
    state := init_test_state("log_storage_add_steps", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create a log
        change: Context_Change;
        change.previous_version = 1;
        change.new_version = 2;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        // Add a step
        step: Execution_Step;
        step.service_id = copy_string("test-service");
        step.service_name = copy_string("Test Service");
        step.action = copy_string("Switching context");
        step.status = .PENDING;
        defer free_execution_step(*step);

        success := add_execution_step(*storage, log_id, *step);
        assert_true(success, "adding step should succeed");

        // Verify the step was added
        log, found := get_execution_log(*storage, log_id);
        defer if found free_execution_log(*log);

        assert_true(found, "log should be found");
        assert_equal(log.steps.count, 1, "should have 1 step");
        assert_string_equal(log.steps[0].service_id, "test-service", "service_id should match");
    }

    return all_tests_passed(state);
}

test_log_storage_update_step_status :: () -> bool {
    state := init_test_state("log_storage_update_step_status", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create a log with a step
        change: Context_Change;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        step: Execution_Step;
        step.service_id = copy_string("test-service");
        step.service_name = copy_string("Test Service");
        step.action = copy_string("Test action");
        step.status = .PENDING;
        defer free_execution_step(*step);

        add_execution_step(*storage, log_id, *step);

        // Update step to RUNNING
        success := update_step_status(*storage, log_id, "test-service", .RUNNING);
        assert_true(success, "updating to RUNNING should succeed");

        // Verify
        log1, found1 := get_execution_log(*storage, log_id);
        defer if found1 free_execution_log(*log1);
        assert_equal(log1.steps[0].status, Step_Status.RUNNING, "step should be RUNNING");

        // Update to COMPLETED
        success = update_step_status(*storage, log_id, "test-service", .COMPLETED);
        assert_true(success, "updating to COMPLETED should succeed");

        log2, found2 := get_execution_log(*storage, log_id);
        defer if found2 free_execution_log(*log2);
        assert_equal(log2.steps[0].status, Step_Status.COMPLETED, "step should be COMPLETED");

        // Update to FAILED with error
        step2: Execution_Step;
        step2.service_id = copy_string("test-service-2");
        step2.service_name = copy_string("Test Service 2");
        step2.action = copy_string("Test action 2");
        step2.status = .PENDING;
        defer free_execution_step(*step2);
        add_execution_step(*storage, log_id, *step2);

        success = update_step_status(*storage, log_id, "test-service-2", .FAILED, "Connection refused");
        assert_true(success, "updating to FAILED with error should succeed");

        log3, found3 := get_execution_log(*storage, log_id);
        defer if found3 free_execution_log(*log3);
        assert_equal(log3.steps[1].status, Step_Status.FAILED, "step should be FAILED");
        assert_string_equal(log3.steps[1].error, "Connection refused", "error should match");
    }

    return all_tests_passed(state);
}

test_log_storage_add_log_entries :: () -> bool {
    state := init_test_state("log_storage_add_log_entries", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create a log with a step
        change: Context_Change;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        step: Execution_Step;
        step.service_id = copy_string("test-service");
        step.service_name = copy_string("Test Service");
        step.action = copy_string("Test action");
        step.status = .RUNNING;
        defer free_execution_step(*step);
        add_execution_step(*storage, log_id, *step);

        // Add log entries
        success := add_log_entry(*storage, log_id, "test-service", .INFO, "Starting operation");
        assert_true(success, "adding INFO log should succeed");

        success = add_log_entry(*storage, log_id, "test-service", .DEBUG, "Loading config");
        assert_true(success, "adding DEBUG log should succeed");

        success = add_log_entry(*storage, log_id, "test-service", .WARN, "Deprecated API used");
        assert_true(success, "adding WARN log should succeed");

        // Verify
        log, found := get_execution_log(*storage, log_id);
        defer if found free_execution_log(*log);

        assert_equal(log.steps[0].logs.count, 3, "step should have 3 log entries");
        assert_equal(log.steps[0].logs[0].level, Log_Level.INFO, "first entry should be INFO");
        assert_string_equal(log.steps[0].logs[0].message, "Starting operation", "message should match");
    }

    return all_tests_passed(state);
}

test_log_storage_get_by_service :: () -> bool {
    state := init_test_state("log_storage_get_by_service", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create multiple logs with different services
        change: Context_Change;

        // Log 1 with service-a
        log_id1 := create_execution_log(*storage, *change);
        defer free(log_id1);
        step1: Execution_Step;
        step1.service_id = copy_string("service-a");
        step1.service_name = copy_string("Service A");
        step1.action = copy_string("Action 1");
        defer free_execution_step(*step1);
        add_execution_step(*storage, log_id1, *step1);

        // Log 2 with service-b
        log_id2 := create_execution_log(*storage, *change);
        defer free(log_id2);
        step2: Execution_Step;
        step2.service_id = copy_string("service-b");
        step2.service_name = copy_string("Service B");
        step2.action = copy_string("Action 2");
        defer free_execution_step(*step2);
        add_execution_step(*storage, log_id2, *step2);

        // Log 3 with service-a (again)
        log_id3 := create_execution_log(*storage, *change);
        defer free(log_id3);
        step3: Execution_Step;
        step3.service_id = copy_string("service-a");
        step3.service_name = copy_string("Service A");
        step3.action = copy_string("Action 3");
        defer free_execution_step(*step3);
        add_execution_step(*storage, log_id3, *step3);

        // Query by service-a
        logs_a := get_logs_by_service(*storage, "service-a", 10);
        defer free_logs_array(*logs_a);

        assert_equal(logs_a.count, 2, "should find 2 logs for service-a");

        // Query by service-b
        logs_b := get_logs_by_service(*storage, "service-b", 10);
        defer free_logs_array(*logs_b);

        assert_equal(logs_b.count, 1, "should find 1 log for service-b");

        // Query by non-existent service
        logs_c := get_logs_by_service(*storage, "service-c", 10);
        defer free_logs_array(*logs_c);

        assert_equal(logs_c.count, 0, "should find 0 logs for service-c");
    }

    return all_tests_passed(state);
}

test_log_storage_status_update :: () -> bool {
    state := init_test_state("log_storage_status_update", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        change: Context_Change;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        // Start execution
        start_execution_log(*storage, log_id);

        log1, found1 := get_execution_log(*storage, log_id);
        defer if found1 free_execution_log(*log1);
        assert_equal(log1.status, Execution_Status.RUNNING, "status should be RUNNING after start");

        // Add two steps
        step1: Execution_Step;
        step1.service_id = copy_string("service-1");
        step1.service_name = copy_string("Service 1");
        step1.status = .PENDING;
        defer free_execution_step(*step1);
        add_execution_step(*storage, log_id, *step1);

        step2: Execution_Step;
        step2.service_id = copy_string("service-2");
        step2.service_name = copy_string("Service 2");
        step2.status = .PENDING;
        defer free_execution_step(*step2);
        add_execution_step(*storage, log_id, *step2);

        // Complete first step
        update_step_status(*storage, log_id, "service-1", .COMPLETED);

        log2, found2 := get_execution_log(*storage, log_id);
        defer if found2 free_execution_log(*log2);
        assert_equal(log2.status, Execution_Status.RUNNING, "status should still be RUNNING with pending step");

        // Complete second step
        update_step_status(*storage, log_id, "service-2", .COMPLETED);

        log3, found3 := get_execution_log(*storage, log_id);
        defer if found3 free_execution_log(*log3);
        assert_equal(log3.status, Execution_Status.COMPLETED, "status should be COMPLETED when all steps done");
    }

    return all_tests_passed(state);
}

test_log_storage_partial_status :: () -> bool {
    state := init_test_state("log_storage_partial_status", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        change: Context_Change;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        // Add two steps
        step1: Execution_Step;
        step1.service_id = copy_string("service-1");
        step1.status = .PENDING;
        defer free_execution_step(*step1);
        add_execution_step(*storage, log_id, *step1);

        step2: Execution_Step;
        step2.service_id = copy_string("service-2");
        step2.status = .PENDING;
        defer free_execution_step(*step2);
        add_execution_step(*storage, log_id, *step2);

        // Complete first, fail second
        update_step_status(*storage, log_id, "service-1", .COMPLETED);
        update_step_status(*storage, log_id, "service-2", .FAILED, "Error occurred");

        log, found := get_execution_log(*storage, log_id);
        defer if found free_execution_log(*log);
        assert_equal(log.status, Execution_Status.PARTIAL, "status should be PARTIAL when some steps failed");
    }

    return all_tests_passed(state);
}

// ============================================================================
// String Conversion Tests
// ============================================================================

test_log_level_string_conversion :: () -> bool {
    state := init_test_state("log_level_string_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test to_string
        assert_string_equal(log_level_to_string(.DEBUG), "debug", "DEBUG should convert to 'debug'");
        assert_string_equal(log_level_to_string(.INFO), "info", "INFO should convert to 'info'");
        assert_string_equal(log_level_to_string(.WARN), "warn", "WARN should convert to 'warn'");
        assert_string_equal(log_level_to_string(.ERROR), "error", "ERROR should convert to 'error'");

        // Test from_string
        level, ok := string_to_log_level("debug");
        assert_true(ok, "parsing 'debug' should succeed");
        assert_equal(level, Log_Level.DEBUG, "should parse to DEBUG");

        level, ok = string_to_log_level("info");
        assert_true(ok, "parsing 'info' should succeed");
        assert_equal(level, Log_Level.INFO, "should parse to INFO");

        level, ok = string_to_log_level("invalid");
        assert_false(ok, "parsing 'invalid' should fail");
    }

    return all_tests_passed(state);
}

test_step_status_string_conversion :: () -> bool {
    state := init_test_state("step_status_string_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test to_string
        assert_string_equal(step_status_to_string(.PENDING), "pending", "PENDING should convert to 'pending'");
        assert_string_equal(step_status_to_string(.RUNNING), "running", "RUNNING should convert to 'running'");
        assert_string_equal(step_status_to_string(.COMPLETED), "completed", "COMPLETED should convert to 'completed'");
        assert_string_equal(step_status_to_string(.FAILED), "failed", "FAILED should convert to 'failed'");
        assert_string_equal(step_status_to_string(.SKIPPED), "skipped", "SKIPPED should convert to 'skipped'");

        // Test from_string
        status, ok := string_to_step_status("completed");
        assert_true(ok, "parsing 'completed' should succeed");
        assert_equal(status, Step_Status.COMPLETED, "should parse to COMPLETED");
    }

    return all_tests_passed(state);
}

test_execution_status_string_conversion :: () -> bool {
    state := init_test_state("execution_status_string_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test to_string
        assert_string_equal(execution_status_to_string(.PENDING), "pending", "PENDING should convert");
        assert_string_equal(execution_status_to_string(.RUNNING), "running", "RUNNING should convert");
        assert_string_equal(execution_status_to_string(.COMPLETED), "completed", "COMPLETED should convert");
        assert_string_equal(execution_status_to_string(.FAILED), "failed", "FAILED should convert");
        assert_string_equal(execution_status_to_string(.PARTIAL), "partial", "PARTIAL should convert");

        // Test from_string
        status, ok := string_to_execution_status("partial");
        assert_true(ok, "parsing 'partial' should succeed");
        assert_equal(status, Execution_Status.PARTIAL, "should parse to PARTIAL");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_log_entry_json_conversion :: () -> bool {
    state := init_test_state("log_entry_json_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        entry: Log_Entry;
        entry.timestamp = current_time_consensus();
        entry.level = .INFO;
        entry.message = copy_string("Test message");
        defer free_log_entry(*entry);

        json := log_entry_to_json(*entry);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        // Check fields
        found_level, level_val := table_find(json.object, "level");
        assert_true(found_level, "should have 'level' field");
        assert_string_equal(level_val.str, "info", "level should be 'info'");

        found_msg, msg_val := table_find(json.object, "message");
        assert_true(found_msg, "should have 'message' field");
        assert_string_equal(msg_val.str, "Test message", "message should match");
    }

    return all_tests_passed(state);
}

test_execution_step_json_conversion :: () -> bool {
    state := init_test_state("execution_step_json_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        step: Execution_Step;
        step.service_id = copy_string("test-service");
        step.service_name = copy_string("Test Service");
        step.action = copy_string("Test action");
        step.status = .COMPLETED;
        step.error = copy_string("");

        // Add a log entry
        entry: Log_Entry;
        entry.level = .INFO;
        entry.message = copy_string("Log message");
        array_add(*step.logs, entry);

        defer free_execution_step(*step);

        json := execution_step_to_json(*step);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        found_id, id_val := table_find(json.object, "service_id");
        assert_true(found_id, "should have 'service_id' field");
        assert_string_equal(id_val.str, "test-service", "service_id should match");

        found_status, status_val := table_find(json.object, "status");
        assert_true(found_status, "should have 'status' field");
        assert_string_equal(status_val.str, "completed", "status should be 'completed'");

        found_logs, logs_val := table_find(json.object, "logs");
        assert_true(found_logs, "should have 'logs' field");
        assert_equal(logs_val.type, jason.JSON_Type.ARRAY, "logs should be an array");
        assert_equal(logs_val.array.count, 1, "should have 1 log entry");
    }

    return all_tests_passed(state);
}

test_execution_log_json_conversion :: () -> bool {
    state := init_test_state("execution_log_json_conversion", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        log: Execution_Log;
        log.id = copy_string("exec-123");
        log.context_change.previous_version = 5;
        log.context_change.new_version = 6;
        array_add(*log.context_change.changed_fields, copy_string("profile"));
        log.status = .COMPLETED;
        defer free_execution_log(*log);

        json := execution_log_to_json(*log);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        found_id, id_val := table_find(json.object, "id");
        assert_true(found_id, "should have 'id' field");
        assert_string_equal(id_val.str, "exec-123", "id should match");

        found_change, change_val := table_find(json.object, "context_change");
        assert_true(found_change, "should have 'context_change' field");
        assert_equal(change_val.type, jason.JSON_Type.OBJECT, "context_change should be an object");

        found_steps, steps_val := table_find(json.object, "steps");
        assert_true(found_steps, "should have 'steps' field");
        assert_equal(steps_val.type, jason.JSON_Type.ARRAY, "steps should be an array");
    }

    return all_tests_passed(state);
}

// ============================================================================
// API Handler Tests
// ============================================================================

test_handle_logs_list :: () -> bool {
    state := init_test_state("handle_logs_list", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create some logs
        change: Context_Change;
        for i: 0..4 {
            log_id := create_execution_log(*storage, *change);
            free(log_id);
        }

        // Create request by parsing JSON
        json := #string END
{"jsonrpc": "2.0", "method": "logs.list", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_logs_list(*storage, *msg.request);
        defer free(result.response);

        assert_true(result.success, "logs.list should succeed");
        assert_string_contains(result.response, "\"count\":", "response should contain count");
        assert_string_contains(result.response, "\"logs\":", "response should contain logs");
    }

    return all_tests_passed(state);
}

test_handle_logs_list_with_limit :: () -> bool {
    state := init_test_state("handle_logs_list_with_limit", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create 10 logs
        change: Context_Change;
        for i: 0..9 {
            log_id := create_execution_log(*storage, *change);
            free(log_id);
        }

        // Request with limit=3
        json := #string END
{"jsonrpc": "2.0", "method": "logs.list", "params": {"limit": 3}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_logs_list(*storage, *msg.request);
        defer free(result.response);

        assert_true(result.success, "logs.list with limit should succeed");
        // Parse response to verify count (JSON output has space after colon: "count": 3)
        assert_string_contains(result.response, "\"count\":", "response should have count field");
        // The count should be 3
        assert_string_contains(result.response, "\"count\": 3", "count should be 3");
    }

    return all_tests_passed(state);
}

test_handle_logs_get :: () -> bool {
    state := init_test_state("handle_logs_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create a log
        change: Context_Change;
        change.previous_version = 10;
        change.new_version = 11;
        log_id := create_execution_log(*storage, *change);
        defer free(log_id);

        // Request to get the log - need to construct JSON with dynamic log_id
        json := tprint("{\"jsonrpc\": \"2.0\", \"method\": \"logs.get\", \"params\": {\"id\": \"%\"}, \"id\": 1}", log_id);
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_logs_get(*storage, *msg.request);
        defer free(result.response);

        assert_true(result.success, "logs.get should succeed");
        assert_string_contains(result.response, log_id, "response should contain log ID");
        // JSON output has space after colon
        assert_string_contains(result.response, "\"previous_version\": 10", "should have previous version");
    }

    return all_tests_passed(state);
}

test_handle_logs_get_not_found :: () -> bool {
    state := init_test_state("handle_logs_get_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Request non-existent log
        json := #string END
{"jsonrpc": "2.0", "method": "logs.get", "params": {"id": "exec-nonexistent"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_logs_get(*storage, *msg.request);
        defer free(result.response);

        assert_false(result.success, "logs.get should fail for non-existent log");
        assert_string_contains(result.response, "error", "response should contain error");
        assert_string_contains(result.response, "not found", "error should mention not found");
    }

    return all_tests_passed(state);
}

test_handle_logs_by_service :: () -> bool {
    state := init_test_state("handle_logs_by_service", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Create logs with steps
        change: Context_Change;

        log_id1 := create_execution_log(*storage, *change);
        defer free(log_id1);
        step1: Execution_Step;
        step1.service_id = copy_string("my-service");
        step1.service_name = copy_string("My Service");
        defer free_execution_step(*step1);
        add_execution_step(*storage, log_id1, *step1);

        log_id2 := create_execution_log(*storage, *change);
        defer free(log_id2);
        step2: Execution_Step;
        step2.service_id = copy_string("other-service");
        step2.service_name = copy_string("Other Service");
        defer free_execution_step(*step2);
        add_execution_step(*storage, log_id2, *step2);

        // Request logs for my-service
        json := #string END
{"jsonrpc": "2.0", "method": "logs.byService", "params": {"service_id": "my-service"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_logs_by_service(*storage, *msg.request);
        defer free(result.response);

        assert_true(result.success, "logs.byService should succeed");
        // JSON output has space after colon
        assert_string_contains(result.response, "\"count\": 1", "should find 1 log");
        assert_string_contains(result.response, "my-service", "response should contain service ID");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Router Tests
// ============================================================================

test_route_logs_method :: () -> bool {
    state := init_test_state("route_logs_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        storage: Log_Storage;
        init_log_storage(*storage, 100);
        defer destroy_log_storage(*storage);

        // Test logs.list routing
        json1 := #string END
{"jsonrpc": "2.0", "method": "logs.list", "id": 1}
END;
        msg1 := parse_jsonrpc_message(json1);
        defer free_jsonrpc_message(*msg1);

        result1 := route_logs_method(*storage, *msg1.request);
        defer free(result1.response);
        assert_true(result1.success, "logs.list should be routed correctly");

        // Test unknown method
        json2 := #string END
{"jsonrpc": "2.0", "method": "logs.unknown", "id": 2}
END;
        msg2 := parse_jsonrpc_message(json2);
        defer free_jsonrpc_message(*msg2);

        result2 := route_logs_method(*storage, *msg2.request);
        defer free(result2.response);
        assert_false(result2.success, "unknown method should fail");
        assert_string_contains(result2.response, "Unknown method", "error should mention unknown method");
    }

    return all_tests_passed(state);
}

test_is_logs_method :: () -> bool {
    state := init_test_state("is_logs_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_logs_method("logs.list"), "logs.list should be a logs method");
        assert_true(is_logs_method("logs.get"), "logs.get should be a logs method");
        assert_true(is_logs_method("logs.byService"), "logs.byService should be a logs method");
        assert_false(is_logs_method("context.get"), "context.get should not be a logs method");
        assert_false(is_logs_method("service.list"), "service.list should not be a logs method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Memory Management Tests
// ============================================================================

test_copy_and_free_log_entry :: () -> bool {
    state := init_test_state("copy_and_free_log_entry", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        original: Log_Entry;
        original.timestamp = current_time_consensus();
        original.level = .WARN;
        original.message = copy_string("Original message");

        copy := copy_log_entry(*original);

        assert_equal(copy.level, original.level, "level should match");
        assert_string_equal(copy.message, original.message, "message should match");

        // Verify they are independent copies
        free_log_entry(*original);
        // Copy should still be valid
        assert_string_equal(copy.message, "Original message", "copy should still be valid after freeing original");

        free_log_entry(*copy);
    }

    return all_tests_passed(state);
}

test_copy_and_free_execution_step :: () -> bool {
    state := init_test_state("copy_and_free_execution_step", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        original: Execution_Step;
        original.service_id = copy_string("test-svc");
        original.service_name = copy_string("Test Service");
        original.action = copy_string("Test action");
        original.status = .RUNNING;
        original.error = copy_string("Some error");

        entry: Log_Entry;
        entry.level = .INFO;
        entry.message = copy_string("Log msg");
        array_add(*original.logs, entry);

        copy := copy_execution_step(*original);

        assert_string_equal(copy.service_id, "test-svc", "service_id should match");
        assert_equal(copy.logs.count, 1, "should have 1 log entry");

        free_execution_step(*original);
        // Copy should still be valid
        assert_string_equal(copy.service_name, "Test Service", "copy should still be valid");

        free_execution_step(*copy);
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_logs_api_tests :: (register: (string, () -> bool, string)) {
    register("logs_api/storage_init", test_log_storage_init, "unit");
    register("logs_api/storage_create_log", test_log_storage_create_log, "unit");
    register("logs_api/storage_pruning", test_log_storage_pruning, "unit");
    register("logs_api/storage_add_steps", test_log_storage_add_steps, "unit");
    register("logs_api/storage_update_step_status", test_log_storage_update_step_status, "unit");
    register("logs_api/storage_add_log_entries", test_log_storage_add_log_entries, "unit");
    register("logs_api/storage_get_by_service", test_log_storage_get_by_service, "unit");
    register("logs_api/storage_status_update", test_log_storage_status_update, "unit");
    register("logs_api/storage_partial_status", test_log_storage_partial_status, "unit");
    register("logs_api/log_level_string", test_log_level_string_conversion, "unit");
    register("logs_api/step_status_string", test_step_status_string_conversion, "unit");
    register("logs_api/execution_status_string", test_execution_status_string_conversion, "unit");
    register("logs_api/log_entry_json", test_log_entry_json_conversion, "unit");
    register("logs_api/execution_step_json", test_execution_step_json_conversion, "unit");
    register("logs_api/execution_log_json", test_execution_log_json_conversion, "unit");
    register("logs_api/handle_logs_list", test_handle_logs_list, "unit");
    register("logs_api/handle_logs_list_limit", test_handle_logs_list_with_limit, "unit");
    register("logs_api/handle_logs_get", test_handle_logs_get, "unit");
    register("logs_api/handle_logs_get_not_found", test_handle_logs_get_not_found, "unit");
    register("logs_api/handle_logs_by_service", test_handle_logs_by_service, "unit");
    register("logs_api/route_logs_method", test_route_logs_method, "unit");
    register("logs_api/is_logs_method", test_is_logs_method, "unit");
    register("logs_api/copy_free_log_entry", test_copy_and_free_log_entry, "unit");
    register("logs_api/copy_free_step", test_copy_and_free_execution_step, "unit");
}
