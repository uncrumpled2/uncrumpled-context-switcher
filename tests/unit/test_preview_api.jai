// Unit tests for Preview API
//
// Tests the preview.get and preview.getVisual API handlers,
// Preview_Manager, and visual formatting.
//
// Note: All necessary modules are loaded by earlier test files:
// - test_jsonrpc.jai loads rpc/module.jai which loads protocol.jai
// - test_context_api.jai loads api/module.jai which now includes preview.jai

// ============================================================================
// Preview Manager Tests
// ============================================================================

test_preview_manager_init :: () -> bool {
    state := init_test_state("preview_manager_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);

        init_preview_manager(*manager, *service_registry, *context_store);

        assert_true(manager.initialized, "manager should be initialized");
        assert_equal(manager.default_timeout_ms, 5000, "default timeout should be 5000ms");
        assert_not_null(manager.service_registry, "service registry should be set");
        assert_not_null(manager.context_store, "context store should be set");

        destroy_preview_manager(*manager);
        assert_false(manager.initialized, "manager should be destroyed");
    }

    return all_tests_passed(state);
}

test_preview_collect_no_services :: () -> bool {
    state := init_test_state("preview_collect_no_services", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Create a proposed context
        proposed: Context;
        proposed.project_id = copy_string("test-project");
        proposed.profile = copy_string("work");
        proposed.environment = copy_string("prod");
        defer free_context(*proposed);

        // Collect preview
        preview := collect_preview(*manager, *proposed);
        defer free_preview_response(*preview);

        assert_equal(preview.services.count, 0, "should have no service previews");
        assert_string_contains(preview.overall_summary, "No services registered", "summary should indicate no services");
    }

    return all_tests_passed(state);
}

test_preview_detect_changed_fields :: () -> bool {
    state := init_test_state("preview_detect_changed_fields", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Set initial context
        initial: Context;
        initial.project_id = copy_string("project-a");
        initial.profile = copy_string("default");
        initial.environment = copy_string("dev");
        set_context(*context_store, *initial);
        free_context(*initial);

        // Create proposed context that changes all fields
        proposed: Context;
        proposed.project_id = copy_string("project-b");
        proposed.profile = copy_string("work");
        proposed.environment = copy_string("prod");
        defer free_context(*proposed);

        preview := collect_preview(*manager, *proposed);
        defer free_preview_response(*preview);

        // Check that all changed fields are detected
        assert_equal(preview.changed_fields.count, 3, "should detect 3 changed fields");

        found_project := false;
        found_profile := false;
        found_env := false;
        for preview.changed_fields {
            if it == "project_id" found_project = true;
            if it == "profile" found_profile = true;
            if it == "environment" found_env = true;
        }
        assert_true(found_project, "should detect project_id change");
        assert_true(found_profile, "should detect profile change");
        assert_true(found_env, "should detect environment change");
    }

    return all_tests_passed(state);
}

test_preview_no_changes :: () -> bool {
    state := init_test_state("preview_no_changes", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Set initial context
        initial: Context;
        initial.project_id = copy_string("same-project");
        initial.profile = copy_string("same-profile");
        initial.environment = copy_string("same-env");
        set_context(*context_store, *initial);
        free_context(*initial);

        // Propose same context
        proposed: Context;
        proposed.project_id = copy_string("same-project");
        proposed.profile = copy_string("same-profile");
        proposed.environment = copy_string("same-env");
        defer free_context(*proposed);

        preview := collect_preview(*manager, *proposed);
        defer free_preview_response(*preview);

        assert_equal(preview.changed_fields.count, 0, "should detect no changes");
        assert_string_contains(preview.overall_summary, "No fields would change", "summary should indicate no changes");
    }

    return all_tests_passed(state);
}

test_preview_with_service :: () -> bool {
    state := init_test_state("preview_with_service", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Register a service with preview capability
        service: Registered_Service;
        service.id = copy_string("test-service");
        service.name = copy_string("Test Service");
        service.endpoint = copy_string("/tmp/test.sock");
        service.preview_callback = copy_string("preview.execute");
        service.capabilities.provides_preview = true;
        service.capabilities.api_version = copy_string("1.0.0");
        register_service(*service_registry, *service);
        free_registered_service(*service);

        // Collect preview
        proposed: Context;
        proposed.project_id = copy_string("new-project");
        proposed.profile = copy_string("default");
        proposed.environment = copy_string("dev");
        defer free_context(*proposed);

        preview := collect_preview(*manager, *proposed);
        defer free_preview_response(*preview);

        assert_equal(preview.services.count, 1, "should have one service preview");
        assert_string_equal(preview.services[0].service_id, "test-service", "service id should match");
        assert_string_equal(preview.services[0].service_name, "Test Service", "service name should match");
        // Status should be PENDING since we're not actually connecting
        assert_equal(preview.services[0].status, .PENDING, "status should be pending");
    }

    return all_tests_passed(state);
}

test_preview_service_no_callback :: () -> bool {
    state := init_test_state("preview_service_no_callback", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Register service with provides_preview but no callback
        service: Registered_Service;
        service.id = copy_string("no-callback-service");
        service.name = copy_string("No Callback Service");
        service.endpoint = copy_string("/tmp/no-callback.sock");
        service.preview_callback = copy_string("");  // No callback
        service.capabilities.provides_preview = true;
        service.capabilities.api_version = copy_string("1.0.0");
        register_service(*service_registry, *service);
        free_registered_service(*service);

        proposed: Context;
        proposed.project_id = copy_string("project");
        proposed.profile = copy_string("default");
        proposed.environment = copy_string("dev");
        defer free_context(*proposed);

        preview := collect_preview(*manager, *proposed);
        defer free_preview_response(*preview);

        assert_equal(preview.services.count, 1, "should have one service preview");
        assert_equal(preview.services[0].status, .NO_PREVIEW, "status should be NO_PREVIEW");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Preview Status String Tests
// ============================================================================

test_status_strings :: () -> bool {
    state := init_test_state("status_strings", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_string_equal(get_status_string(.PENDING), "pending", "PENDING string");
        assert_string_equal(get_status_string(.SUCCESS), "success", "SUCCESS string");
        assert_string_equal(get_status_string(.ERROR), "error", "ERROR string");
        assert_string_equal(get_status_string(.TIMEOUT), "timeout", "TIMEOUT string");
        assert_string_equal(get_status_string(.UNAVAILABLE), "unavailable", "UNAVAILABLE string");
        assert_string_equal(get_status_string(.NO_PREVIEW), "no-preview", "NO_PREVIEW string");
    }

    return all_tests_passed(state);
}

test_status_colors :: () -> bool {
    state := init_test_state("status_colors", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Yellow for pending
        assert_string_equal(get_status_color(.PENDING), "33", "PENDING color");
        // Green for success
        assert_string_equal(get_status_color(.SUCCESS), "32", "SUCCESS color");
        // Red for errors
        assert_string_equal(get_status_color(.ERROR), "31", "ERROR color");
        assert_string_equal(get_status_color(.TIMEOUT), "31", "TIMEOUT color");
        assert_string_equal(get_status_color(.UNAVAILABLE), "31", "UNAVAILABLE color");
        // Gray for no preview
        assert_string_equal(get_status_color(.NO_PREVIEW), "90", "NO_PREVIEW color");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Visual Formatting Tests
// ============================================================================

test_format_preview_text :: () -> bool {
    state := init_test_state("format_preview_text", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        preview: Preview_Response;
        preview.proposed_context.project_id = copy_string("new-project");
        preview.proposed_context.profile = copy_string("default");
        preview.proposed_context.environment = copy_string("dev");
        preview.current_context.project_id = copy_string("old-project");
        preview.current_context.profile = copy_string("default");
        preview.current_context.environment = copy_string("dev");
        array_add(*preview.changed_fields, copy_string("project_id"));
        preview.overall_summary = copy_string("1 field(s) would change. 0 service(s) queried.");
        defer free_preview_response(*preview);

        formatted := format_preview(*preview, .TEXT);
        defer free(formatted);

        assert_string_contains(formatted, "Context Change Preview", "should have title");
        assert_string_contains(formatted, "project_id", "should show changed field");
        assert_string_contains(formatted, "Summary:", "should have summary section");
    }

    return all_tests_passed(state);
}

test_format_preview_markdown :: () -> bool {
    state := init_test_state("format_preview_markdown", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        preview: Preview_Response;
        preview.proposed_context.project_id = copy_string("new-project");
        preview.proposed_context.profile = copy_string("default");
        preview.proposed_context.environment = copy_string("dev");
        preview.current_context.project_id = copy_string("old-project");
        preview.current_context.profile = copy_string("default");
        preview.current_context.environment = copy_string("dev");
        array_add(*preview.changed_fields, copy_string("project_id"));
        preview.overall_summary = copy_string("Test summary");
        defer free_preview_response(*preview);

        formatted := format_preview(*preview, .MARKDOWN);
        defer free(formatted);

        assert_string_contains(formatted, "# Context Change Preview", "should have markdown title");
        assert_string_contains(formatted, "## Changes", "should have changes section");
        assert_string_contains(formatted, "**project_id**", "should format field as bold");
    }

    return all_tests_passed(state);
}

test_format_preview_ansi :: () -> bool {
    state := init_test_state("format_preview_ansi", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        preview: Preview_Response;
        preview.proposed_context.project_id = copy_string("new-project");
        preview.proposed_context.profile = copy_string("default");
        preview.proposed_context.environment = copy_string("dev");
        preview.current_context.project_id = copy_string("old-project");
        preview.current_context.profile = copy_string("default");
        preview.current_context.environment = copy_string("dev");
        array_add(*preview.changed_fields, copy_string("project_id"));
        preview.overall_summary = copy_string("Test summary");
        defer free_preview_response(*preview);

        formatted := format_preview(*preview, .ANSI);
        defer free(formatted);

        // Check for ANSI escape codes
        assert_string_contains(formatted, "\x1b[", "should contain ANSI escape codes");
        assert_string_contains(formatted, "project_id", "should show changed field");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_preview_action_to_json :: () -> bool {
    state := init_test_state("preview_action_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        action: Preview_Action;
        action.action_type = copy_string("create");
        action.target = copy_string("/path/to/file");
        action.description = copy_string("Creates a new config file");
        action.severity = copy_string("info");
        action.reversible = true;
        defer free_preview_action(*action);

        json := preview_action_to_json(*action);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        found, val := table_find(json.object, "action_type");
        assert_true(found, "should have action_type");
        assert_string_equal(val.str, "create", "action_type should be 'create'");

        found, val = table_find(json.object, "target");
        assert_true(found, "should have target");
        assert_string_equal(val.str, "/path/to/file", "target should match");

        found, val = table_find(json.object, "reversible");
        assert_true(found, "should have reversible");
        assert_true(val.boolean, "reversible should be true");
    }

    return all_tests_passed(state);
}

test_service_preview_to_json :: () -> bool {
    state := init_test_state("service_preview_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        preview: Service_Preview;
        preview.service_id = copy_string("test-svc");
        preview.service_name = copy_string("Test Service");
        preview.status = .SUCCESS;
        preview.summary = copy_string("Would update config");
        preview.error_message = copy_string("");
        preview.estimated_duration_ms = 100;
        defer free_service_preview(*preview);

        json := service_preview_to_json(*preview);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        found, val := table_find(json.object, "service_id");
        assert_true(found, "should have service_id");
        assert_string_equal(val.str, "test-svc", "service_id should match");

        found, val = table_find(json.object, "status");
        assert_true(found, "should have status");
        assert_string_equal(val.str, "success", "status should be 'success'");

        found, val = table_find(json.object, "estimated_duration_ms");
        assert_true(found, "should have estimated_duration_ms");
        assert_float_equal(val.number, 100.0, 0.001, "duration should be 100");
    }

    return all_tests_passed(state);
}

test_preview_response_to_json :: () -> bool {
    state := init_test_state("preview_response_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        response: Preview_Response;
        response.proposed_context.project_id = copy_string("new-proj");
        response.proposed_context.profile = copy_string("default");
        response.proposed_context.environment = copy_string("dev");
        response.current_context.project_id = copy_string("old-proj");
        response.current_context.profile = copy_string("default");
        response.current_context.environment = copy_string("dev");
        array_add(*response.changed_fields, copy_string("project_id"));
        response.total_actions = 5;
        response.has_destructive_actions = true;
        response.has_warnings = false;
        response.overall_summary = copy_string("Test summary");
        defer free_preview_response(*response);

        json := preview_response_to_json(*response);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "should be an object");

        found, val := table_find(json.object, "total_actions");
        assert_true(found, "should have total_actions");
        assert_float_equal(val.number, 5.0, 0.001, "total_actions should be 5");

        found, val = table_find(json.object, "has_destructive_actions");
        assert_true(found, "should have has_destructive_actions");
        assert_true(val.boolean, "has_destructive_actions should be true");

        found, val = table_find(json.object, "changed_fields");
        assert_true(found, "should have changed_fields");
        assert_equal(val.type, jason.JSON_Type.ARRAY, "changed_fields should be array");
        assert_equal(val.array.count, 1, "should have 1 changed field");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Preview API Handler Tests
// ============================================================================

test_handle_preview_get_success :: () -> bool {
    state := init_test_state("handle_preview_get_success", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Parse a valid request
        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.get", "params": {"proposed_context": {"project_id": "new-proj", "profile": "work", "environment": "prod"}}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse request");
        defer free_jsonrpc_message(*msg);

        result := handle_preview_get(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "handler should succeed");
        assert_string_contains(result.response, "\"result\"", "should have result field");
        assert_string_contains(result.response, "proposed_context", "should have proposed_context");
        assert_string_contains(result.response, "current_context", "should have current_context");
    }

    return all_tests_passed(state);
}

test_handle_preview_get_missing_params :: () -> bool {
    state := init_test_state("handle_preview_get_missing_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        // Request with missing proposed_context
        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.get", "params": {}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse request");
        defer free_jsonrpc_message(*msg);

        result := handle_preview_get(*manager, *msg.request);
        defer free(result.response);

        assert_false(result.success, "handler should fail");
        assert_string_contains(result.response, "error", "should have error");
        assert_string_contains(result.response, "proposed_context", "error should mention proposed_context");
    }

    return all_tests_passed(state);
}

test_handle_preview_get_visual_text :: () -> bool {
    state := init_test_state("handle_preview_get_visual_text", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.getVisual", "params": {"proposed_context": {"project_id": "proj", "profile": "default", "environment": "dev"}, "format": "text"}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse request");
        defer free_jsonrpc_message(*msg);

        result := handle_preview_get_visual(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "handler should succeed");
        assert_string_contains(result.response, "preview", "should have preview field");
        assert_string_contains(result.response, "\"format\"", "should have format field");
        assert_string_contains(result.response, "\"text\"", "format should be text");
    }

    return all_tests_passed(state);
}

test_handle_preview_get_visual_ansi :: () -> bool {
    state := init_test_state("handle_preview_get_visual_ansi", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.getVisual", "params": {"proposed_context": {"project_id": "proj", "profile": "default", "environment": "dev"}, "format": "ansi"}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse request");
        defer free_jsonrpc_message(*msg);

        result := handle_preview_get_visual(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "handler should succeed");
        assert_string_contains(result.response, "\"ansi\"", "format should be ansi");
    }

    return all_tests_passed(state);
}

test_handle_preview_get_visual_markdown :: () -> bool {
    state := init_test_state("handle_preview_get_visual_markdown", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.getVisual", "params": {"proposed_context": {"project_id": "proj", "profile": "default", "environment": "dev"}, "format": "markdown"}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse request");
        defer free_jsonrpc_message(*msg);

        result := handle_preview_get_visual(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "handler should succeed");
        assert_string_contains(result.response, "\"markdown\"", "format should be markdown");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Router Tests
// ============================================================================

test_route_preview_method_get :: () -> bool {
    state := init_test_state("route_preview_method_get", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.get", "params": {"proposed_context": {"project_id": "test", "profile": "default", "environment": "dev"}}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse");
        defer free_jsonrpc_message(*msg);

        result := route_preview_method(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "should route successfully");
        assert_string_contains(result.response, "result", "should have result");
    }

    return all_tests_passed(state);
}

test_route_preview_method_get_visual :: () -> bool {
    state := init_test_state("route_preview_method_get_visual", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.getVisual", "params": {"proposed_context": {"project_id": "test", "profile": "default", "environment": "dev"}}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse");
        defer free_jsonrpc_message(*msg);

        result := route_preview_method(*manager, *msg.request);
        defer free(result.response);

        assert_true(result.success, "should route successfully");
        assert_string_contains(result.response, "preview", "should have preview");
    }

    return all_tests_passed(state);
}

test_route_preview_method_unknown :: () -> bool {
    state := init_test_state("route_preview_method_unknown", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_registry: Service_Registry;
        context_store: Context_Store;
        manager: Preview_Manager;

        init_service_registry(*service_registry);
        init_context_store(*context_store);
        init_preview_manager(*manager, *service_registry, *context_store);
        defer destroy_service_registry(*service_registry);
        defer destroy_context_store(*context_store);
        defer destroy_preview_manager(*manager);

        json := #string DONE
{"jsonrpc": "2.0", "method": "preview.unknown", "params": {}, "id": 1}
DONE;
        msg := parse_jsonrpc_message(json);
        assert_true(msg.type != .INVALID, "should parse");
        defer free_jsonrpc_message(*msg);

        result := route_preview_method(*manager, *msg.request);
        defer free(result.response);

        assert_false(result.success, "should fail for unknown method");
        assert_string_contains(result.response, "error", "should have error");
        assert_string_contains(result.response, "-32601", "should be method not found error");
    }

    return all_tests_passed(state);
}

test_is_preview_method :: () -> bool {
    state := init_test_state("is_preview_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_preview_method("preview.get"), "preview.get is preview method");
        assert_true(is_preview_method("preview.getVisual"), "preview.getVisual is preview method");
        assert_true(is_preview_method("preview.foo"), "preview.foo is preview method");
        assert_false(is_preview_method("context.get"), "context.get is not preview method");
        assert_false(is_preview_method("service.list"), "service.list is not preview method");
        assert_false(is_preview_method(""), "empty is not preview method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Memory Management Tests
// ============================================================================

test_free_preview_action :: () -> bool {
    state := init_test_state("free_preview_action", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        action: Preview_Action;
        action.action_type = copy_string("test-type");
        action.target = copy_string("test-target");
        action.description = copy_string("test description");
        action.severity = copy_string("info");
        action.reversible = true;

        // Should not crash
        free_preview_action(*action);
        assert_true(true, "free_preview_action should not crash");
    }

    return all_tests_passed(state);
}

test_free_service_preview :: () -> bool {
    state := init_test_state("free_service_preview", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        preview: Service_Preview;
        preview.service_id = copy_string("svc-id");
        preview.service_name = copy_string("Service Name");
        preview.status = .SUCCESS;
        preview.error_message = copy_string("");
        preview.summary = copy_string("Summary");

        // Add an action
        action: Preview_Action;
        action.action_type = copy_string("create");
        action.target = copy_string("/path");
        action.description = copy_string("desc");
        action.severity = copy_string("info");
        array_add(*preview.actions, action);

        // Should not crash
        free_service_preview(*preview);
        assert_true(true, "free_service_preview should not crash");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_preview_api_tests :: (register: (string, () -> bool, string)) {
    // Manager tests
    register("preview_api/manager_init", test_preview_manager_init, "unit");
    register("preview_api/collect_no_services", test_preview_collect_no_services, "unit");
    register("preview_api/detect_changed_fields", test_preview_detect_changed_fields, "unit");
    register("preview_api/no_changes", test_preview_no_changes, "unit");
    register("preview_api/with_service", test_preview_with_service, "unit");
    register("preview_api/service_no_callback", test_preview_service_no_callback, "unit");

    // Status tests
    register("preview_api/status_strings", test_status_strings, "unit");
    register("preview_api/status_colors", test_status_colors, "unit");

    // Formatting tests
    register("preview_api/format_text", test_format_preview_text, "unit");
    register("preview_api/format_markdown", test_format_preview_markdown, "unit");
    register("preview_api/format_ansi", test_format_preview_ansi, "unit");

    // JSON conversion tests
    register("preview_api/action_to_json", test_preview_action_to_json, "unit");
    register("preview_api/service_preview_to_json", test_service_preview_to_json, "unit");
    register("preview_api/response_to_json", test_preview_response_to_json, "unit");

    // Handler tests
    register("preview_api/handle_get_success", test_handle_preview_get_success, "unit");
    register("preview_api/handle_get_missing_params", test_handle_preview_get_missing_params, "unit");
    register("preview_api/handle_get_visual_text", test_handle_preview_get_visual_text, "unit");
    register("preview_api/handle_get_visual_ansi", test_handle_preview_get_visual_ansi, "unit");
    register("preview_api/handle_get_visual_markdown", test_handle_preview_get_visual_markdown, "unit");

    // Router tests
    register("preview_api/route_get", test_route_preview_method_get, "unit");
    register("preview_api/route_get_visual", test_route_preview_method_get_visual, "unit");
    register("preview_api/route_unknown", test_route_preview_method_unknown, "unit");
    register("preview_api/is_preview_method", test_is_preview_method, "unit");

    // Memory tests
    register("preview_api/free_action", test_free_preview_action, "unit");
    register("preview_api/free_service_preview", test_free_service_preview, "unit");
}
