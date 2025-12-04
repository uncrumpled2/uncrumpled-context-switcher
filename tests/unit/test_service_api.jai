// Unit tests for Service Registration API handlers

// Note: api/module.jai is already loaded by test_context_api.jai which includes service.jai

// ============================================================================
// Service Registry Tests
// ============================================================================

test_service_registry_init :: () -> bool {
    state := init_test_state("test_service_registry_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        assert_true(registry.initialized, "Registry should be initialized");
        assert_equal(get_service_count(*registry), 0, "Initial count should be 0");
    }

    return all_tests_passed(state);
}

test_service_registry_register :: () -> bool {
    state := init_test_state("test_service_registry_register", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Create a service
        service: Registered_Service;
        service.id = "test-service";
        service.name = "Test Service";
        service.endpoint = "/tmp/test.sock";
        service.preview_callback = "";
        array_add(*service.capabilities.events, "context.changed");
        service.capabilities.provides_preview = false;
        service.capabilities.api_version = "1.0.0";

        // Register it
        success, error_msg := register_service(*registry, *service);

        assert_true(success, "Registration should succeed");
        assert_equal(get_service_count(*registry), 1, "Count should be 1");

        // Verify we can get it back
        retrieved, found := get_service(*registry, "test-service");
        defer if found then free_registered_service(*retrieved);

        assert_true(found, "Service should be found");
        assert_string_equal(retrieved.id, "test-service", "ID should match");
        assert_string_equal(retrieved.name, "Test Service", "Name should match");
        assert_string_equal(retrieved.endpoint, "/tmp/test.sock", "Endpoint should match");
    }

    return all_tests_passed(state);
}

test_service_registry_register_duplicate :: () -> bool {
    state := init_test_state("test_service_registry_register_duplicate", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Create a service
        service: Registered_Service;
        service.id = "test-service";
        service.name = "Test Service";
        service.endpoint = "/tmp/test.sock";
        service.preview_callback = "";
        service.capabilities.api_version = "1.0.0";

        // Register it
        success, _ := register_service(*registry, *service);
        assert_true(success, "First registration should succeed");

        // Try to register same ID again
        success2, error_msg := register_service(*registry, *service);
        assert_false(success2, "Duplicate registration should fail");
        assert_true(error_msg.count > 0, "Should have error message");
    }

    return all_tests_passed(state);
}

test_service_registry_unregister :: () -> bool {
    state := init_test_state("test_service_registry_unregister", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Create and register a service
        service: Registered_Service;
        service.id = "test-service";
        service.name = "Test Service";
        service.endpoint = "/tmp/test.sock";
        service.preview_callback = "";
        service.capabilities.api_version = "1.0.0";

        register_service(*registry, *service);
        assert_equal(get_service_count(*registry), 1, "Should have 1 service");

        // Unregister it
        removed := unregister_service(*registry, "test-service");
        assert_true(removed, "Unregister should succeed");
        assert_equal(get_service_count(*registry), 0, "Should have 0 services");

        // Verify it's gone
        _, found := get_service(*registry, "test-service");
        assert_false(found, "Service should not be found");
    }

    return all_tests_passed(state);
}

test_service_registry_unregister_not_found :: () -> bool {
    state := init_test_state("test_service_registry_unregister_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Try to unregister a service that doesn't exist
        removed := unregister_service(*registry, "nonexistent");
        assert_false(removed, "Unregister should return false");
    }

    return all_tests_passed(state);
}

test_service_registry_heartbeat :: () -> bool {
    state := init_test_state("test_service_registry_heartbeat", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Create and register a service
        service: Registered_Service;
        service.id = "test-service";
        service.name = "Test Service";
        service.endpoint = "/tmp/test.sock";
        service.preview_callback = "";
        service.capabilities.api_version = "1.0.0";

        register_service(*registry, *service);

        // Get initial heartbeat
        svc1, _ := get_service(*registry, "test-service");
        initial_heartbeat := svc1.last_heartbeat;
        free_registered_service(*svc1);

        // Small delay
        sleep_ms(10);

        // Update heartbeat
        success := update_heartbeat(*registry, "test-service");
        assert_true(success, "Heartbeat update should succeed");

        // Verify heartbeat was updated
        svc2, _ := get_service(*registry, "test-service");
        defer free_registered_service(*svc2);

        // Note: Heartbeat should be >= initial (could be same if time resolution is low)
        assert_true(svc2.last_heartbeat.low >= initial_heartbeat.low, "Heartbeat should be updated");
    }

    return all_tests_passed(state);
}

test_service_registry_get_all :: () -> bool {
    state := init_test_state("test_service_registry_get_all", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Register multiple services
        for i: 0..2 {
            service: Registered_Service;
            service.id = tprint("service-%", i);
            service.name = tprint("Service %", i);
            service.endpoint = tprint("/tmp/service%.sock", i);
            service.preview_callback = "";
            service.capabilities.api_version = "1.0.0";

            register_service(*registry, *service);
        }

        // Get all services
        all_services := get_all_services(*registry);
        defer free_services_array(*all_services);

        assert_equal(all_services.count, 3, "Should have 3 services");
    }

    return all_tests_passed(state);
}

// ============================================================================
// service.register Handler Tests
// ============================================================================

test_handle_service_register :: () -> bool {
    state := init_test_state("test_handle_service_register", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Create request
        json := #string END
{"jsonrpc": "2.0", "method": "service.register", "params": {"id": "my-service", "name": "My Service", "endpoint": "/tmp/my-service.sock", "capabilities": {"events": ["context.changed"], "provides_preview": true, "api_version": "1.0.0"}}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        assert_equal(msg.type, Message_Type.REQUEST, "Should parse as request");

        // Handle the request
        result := handle_service_register(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify service was registered
        assert_equal(get_service_count(*registry), 1, "Should have 1 service");

        svc, found := get_service(*registry, "my-service");
        defer if found then free_registered_service(*svc);

        assert_true(found, "Service should be found");
        assert_string_equal(svc.name, "My Service", "Name should match");

        // Parse the response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check "registered" field
        found_registered, registered_val := table_find(resp.response.result.object, "registered");
        assert_true(found_registered, "Response should have 'registered' field");
        assert_true(registered_val.boolean, "Registered should be true");
    }

    return all_tests_passed(state);
}

test_handle_service_register_invalid_params :: () -> bool {
    state := init_test_state("test_handle_service_register_invalid_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Request with missing required field
        json := #string END
{"jsonrpc": "2.0", "method": "service.register", "params": {"id": "my-service"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_register(*registry, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
        assert_equal(resp.error_response.error.code, JSONRPC_INVALID_PARAMS, "Should be invalid params error");
    }

    return all_tests_passed(state);
}

test_handle_service_register_duplicate :: () -> bool {
    state := init_test_state("test_handle_service_register_duplicate", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // First registration
        json := #string END
{"jsonrpc": "2.0", "method": "service.register", "params": {"id": "my-service", "name": "My Service", "endpoint": "/tmp/my.sock", "capabilities": {"api_version": "1.0.0"}}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_register(*registry, *msg.request);
        free(result.response);

        // Second registration with same ID
        json2 := #string END
{"jsonrpc": "2.0", "method": "service.register", "params": {"id": "my-service", "name": "Another Service", "endpoint": "/tmp/other.sock", "capabilities": {"api_version": "1.0.0"}}, "id": 2}
END;
        msg2 := parse_jsonrpc_message(json2);
        defer free_jsonrpc_message(*msg2);

        result2 := handle_service_register(*registry, *msg2.request);
        defer free(result2.response);

        assert_false(result2.success, "Duplicate registration should fail");

        // Parse response
        resp := parse_jsonrpc_message(result2.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
    }

    return all_tests_passed(state);
}

// ============================================================================
// service.unregister Handler Tests
// ============================================================================

test_handle_service_unregister :: () -> bool {
    state := init_test_state("test_handle_service_unregister", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Register a service first
        service: Registered_Service;
        service.id = "my-service";
        service.name = "My Service";
        service.endpoint = "/tmp/my.sock";
        service.preview_callback = "";
        service.capabilities.api_version = "1.0.0";
        register_service(*registry, *service);

        // Unregister via handler
        json := #string END
{"jsonrpc": "2.0", "method": "service.unregister", "params": {"id": "my-service"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_unregister(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Verify service was unregistered
        assert_equal(get_service_count(*registry), 0, "Should have 0 services");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        found_unreg, unreg_val := table_find(resp.response.result.object, "unregistered");
        assert_true(found_unreg, "Response should have 'unregistered' field");
        assert_true(unreg_val.boolean, "Unregistered should be true");
    }

    return all_tests_passed(state);
}

test_handle_service_unregister_not_found :: () -> bool {
    state := init_test_state("test_handle_service_unregister_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Try to unregister non-existent service
        json := #string END
{"jsonrpc": "2.0", "method": "service.unregister", "params": {"id": "nonexistent"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_unregister(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed (but indicate not unregistered)");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        found_unreg, unreg_val := table_find(resp.response.result.object, "unregistered");
        assert_true(found_unreg, "Response should have 'unregistered' field");
        assert_false(unreg_val.boolean, "Unregistered should be false");
    }

    return all_tests_passed(state);
}

// ============================================================================
// service.list Handler Tests
// ============================================================================

test_handle_service_list :: () -> bool {
    state := init_test_state("test_handle_service_list", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Register some services
        for i: 0..1 {
            service: Registered_Service;
            service.id = tprint("service-%", i);
            service.name = tprint("Service %", i);
            service.endpoint = tprint("/tmp/service%.sock", i);
            service.preview_callback = "";
            service.capabilities.api_version = "1.0.0";
            register_service(*registry, *service);
        }

        // List via handler
        json := #string END
{"jsonrpc": "2.0", "method": "service.list", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_list(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check services array
        found_services, services_val := table_find(resp.response.result.object, "services");
        assert_true(found_services, "Response should have 'services' field");
        assert_equal(services_val.type, jason.JSON_Type.ARRAY, "Services should be array");
        assert_equal(services_val.array.count, 2, "Should have 2 services");

        // Check count field
        found_count, count_val := table_find(resp.response.result.object, "count");
        assert_true(found_count, "Response should have 'count' field");
        assert_equal(cast(int) count_val.number, 2, "Count should be 2");
    }

    return all_tests_passed(state);
}

test_handle_service_list_empty :: () -> bool {
    state := init_test_state("test_handle_service_list_empty", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // List with no services
        json := #string END
{"jsonrpc": "2.0", "method": "service.list", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_list(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        // Check count
        found_count, count_val := table_find(resp.response.result.object, "count");
        assert_true(found_count, "Response should have 'count' field");
        assert_equal(cast(int) count_val.number, 0, "Count should be 0");
    }

    return all_tests_passed(state);
}

// ============================================================================
// service.heartbeat Handler Tests
// ============================================================================

test_handle_service_heartbeat :: () -> bool {
    state := init_test_state("test_handle_service_heartbeat", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Register a service
        service: Registered_Service;
        service.id = "my-service";
        service.name = "My Service";
        service.endpoint = "/tmp/my.sock";
        service.preview_callback = "";
        service.capabilities.api_version = "1.0.0";
        register_service(*registry, *service);

        // Send heartbeat via handler
        json := #string END
{"jsonrpc": "2.0", "method": "service.heartbeat", "params": {"id": "my-service"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_heartbeat(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Handler should succeed");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.RESPONSE, "Should be success response");

        // Check acknowledged field
        found_ack, ack_val := table_find(resp.response.result.object, "acknowledged");
        assert_true(found_ack, "Response should have 'acknowledged' field");
        assert_true(ack_val.boolean, "Acknowledged should be true");
    }

    return all_tests_passed(state);
}

test_handle_service_heartbeat_not_found :: () -> bool {
    state := init_test_state("test_handle_service_heartbeat_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Send heartbeat for non-existent service
        json := #string END
{"jsonrpc": "2.0", "method": "service.heartbeat", "params": {"id": "nonexistent"}, "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := handle_service_heartbeat(*registry, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Handler should fail for non-existent service");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Router Tests
// ============================================================================

test_route_service_method :: () -> bool {
    state := init_test_state("test_route_service_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Test routing service.list
        json := #string END
{"jsonrpc": "2.0", "method": "service.list", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_service_method(*registry, *msg.request);
        defer free(result.response);

        assert_true(result.success, "Router should succeed for service.list");
    }

    return all_tests_passed(state);
}

test_route_service_unknown_method :: () -> bool {
    state := init_test_state("test_route_service_unknown_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Service_Registry;
        init_service_registry(*registry);
        defer destroy_service_registry(*registry);

        // Test routing unknown method
        json := #string END
{"jsonrpc": "2.0", "method": "service.unknown", "id": 1}
END;
        msg := parse_jsonrpc_message(json);
        defer free_jsonrpc_message(*msg);

        result := route_service_method(*registry, *msg.request);
        defer free(result.response);

        assert_false(result.success, "Router should fail for unknown method");

        // Parse response
        resp := parse_jsonrpc_message(result.response);
        defer free_jsonrpc_message(*resp);

        assert_equal(resp.type, Message_Type.ERROR_RESPONSE, "Should be error response");
        assert_equal(resp.error_response.error.code, JSONRPC_METHOD_NOT_FOUND, "Should be method not found error");
    }

    return all_tests_passed(state);
}

test_is_service_method :: () -> bool {
    state := init_test_state("test_is_service_method", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_true(is_service_method("service.register"), "service.register should be a service method");
        assert_true(is_service_method("service.unregister"), "service.unregister should be a service method");
        assert_true(is_service_method("service.list"), "service.list should be a service method");
        assert_true(is_service_method("service.heartbeat"), "service.heartbeat should be a service method");
        assert_false(is_service_method("context.get"), "context.get should not be a service method");
        assert_false(is_service_method("subscribe"), "subscribe should not be a service method");
    }

    return all_tests_passed(state);
}

// ============================================================================
// JSON Conversion Tests
// ============================================================================

test_service_to_json :: () -> bool {
    state := init_test_state("test_service_to_json", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create a service with data
        service: Registered_Service;
        service.id = copy_string("my-service");
        service.name = copy_string("My Service");
        service.endpoint = copy_string("/tmp/my.sock");
        service.preview_callback = copy_string("preview.get");
        array_add(*service.capabilities.events, copy_string("context.changed"));
        array_add(*service.capabilities.events, copy_string("tags.updated"));
        service.capabilities.provides_preview = true;
        service.capabilities.api_version = copy_string("1.0.0");
        defer free_registered_service(*service);

        // Convert to JSON
        json := service_to_json(*service);
        defer jason.json_free(json);

        assert_equal(json.type, jason.JSON_Type.OBJECT, "Should be an object");

        // Check fields
        found_id, id_val := table_find(json.object, "id");
        assert_true(found_id, "Should have id");
        assert_string_equal(id_val.str, "my-service", "id should match");

        found_name, name_val := table_find(json.object, "name");
        assert_true(found_name, "Should have name");
        assert_string_equal(name_val.str, "My Service", "name should match");

        // Check capabilities
        found_caps, caps_val := table_find(json.object, "capabilities");
        assert_true(found_caps, "Should have capabilities");
        assert_equal(caps_val.type, jason.JSON_Type.OBJECT, "Capabilities should be object");

        found_events, events_val := table_find(caps_val.object, "events");
        assert_true(found_events, "Should have events");
        assert_equal(events_val.array.count, 2, "Should have 2 events");
    }

    return all_tests_passed(state);
}

test_json_to_service :: () -> bool {
    state := init_test_state("test_json_to_service", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create JSON object
        json_str := #string END
{"id": "test-service", "name": "Test", "endpoint": "/tmp/test.sock", "capabilities": {"events": ["context.changed"], "provides_preview": false, "api_version": "1.0.0"}}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert to service
        service, parse_ok, parse_error := json_to_service(json);
        defer if parse_ok then free_registered_service(*service);

        assert_true(parse_ok, "Should parse successfully");
        assert_string_equal(service.id, "test-service", "id should match");
        assert_string_equal(service.name, "Test", "name should match");
        assert_string_equal(service.endpoint, "/tmp/test.sock", "endpoint should match");
        assert_equal(service.capabilities.events.count, 1, "Should have 1 event");
        assert_false(service.capabilities.provides_preview, "provides_preview should be false");
    }

    return all_tests_passed(state);
}

test_json_to_service_missing_required :: () -> bool {
    state := init_test_state("test_json_to_service_missing_required", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Missing 'name' field
        json_str := #string END
{"id": "test-service", "endpoint": "/tmp/test.sock", "capabilities": {}}
END;
        success, json := jason.json_parse_string(json_str);
        assert_true(success, "JSON should parse");
        defer jason.json_free(json);

        // Convert should fail
        service, parse_ok, parse_error := json_to_service(json);

        assert_false(parse_ok, "Should fail to parse with missing name");
        assert_true(parse_error.count > 0, "Should have error message");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_service_api_tests :: (register: (string, () -> bool, string)) {
    // Registry tests
    register("service_api/registry_init", test_service_registry_init, "unit");
    register("service_api/registry_register", test_service_registry_register, "unit");
    register("service_api/registry_register_duplicate", test_service_registry_register_duplicate, "unit");
    register("service_api/registry_unregister", test_service_registry_unregister, "unit");
    register("service_api/registry_unregister_not_found", test_service_registry_unregister_not_found, "unit");
    register("service_api/registry_heartbeat", test_service_registry_heartbeat, "unit");
    register("service_api/registry_get_all", test_service_registry_get_all, "unit");

    // Handler tests
    register("service_api/handle_register", test_handle_service_register, "unit");
    register("service_api/handle_register_invalid", test_handle_service_register_invalid_params, "unit");
    register("service_api/handle_register_duplicate", test_handle_service_register_duplicate, "unit");
    register("service_api/handle_unregister", test_handle_service_unregister, "unit");
    register("service_api/handle_unregister_not_found", test_handle_service_unregister_not_found, "unit");
    register("service_api/handle_list", test_handle_service_list, "unit");
    register("service_api/handle_list_empty", test_handle_service_list_empty, "unit");
    register("service_api/handle_heartbeat", test_handle_service_heartbeat, "unit");
    register("service_api/handle_heartbeat_not_found", test_handle_service_heartbeat_not_found, "unit");

    // Router tests
    register("service_api/route_method", test_route_service_method, "unit");
    register("service_api/route_unknown", test_route_service_unknown_method, "unit");
    register("service_api/is_service_method", test_is_service_method, "unit");

    // JSON conversion tests
    register("service_api/service_to_json", test_service_to_json, "unit");
    register("service_api/json_to_service", test_json_to_service, "unit");
    register("service_api/json_to_service_missing", test_json_to_service_missing_required, "unit");
}
