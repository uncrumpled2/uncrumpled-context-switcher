// Unit tests for Context Registry (Multi-Context Support)
//
// Tests the new multi-context functionality including:
// - Context definition management
// - Active context switching
// - Argument validation
// - History management

// Context store is already loaded by test_context_store.jai
// Args parser is loaded by test_args_parser.jai

// Helper function to switch context from raw input string
switch_context_from_input :: (registry: *Context_Registry, input: string) -> bool, string {
    parsed := parse_context_input(input);
    defer free_parsed_input(*parsed);

    if !parsed.success {
        return false, parsed.error;
    }

    // Convert Table(string, Arg_Value) to separate args and flags tables
    args_table: Table(string, string);
    flags_table: Table(string, bool);
    defer deinit(*args_table);
    defer deinit(*flags_table);

    for parsed.args {
        if it.is_flag {
            table_set(*flags_table, it_index, true);
        } else {
            table_set(*args_table, it_index, it.value);
        }
    }

    success, err := switch_context_by_input(registry, parsed.name, *args_table, *flags_table, parsed.raw);
    return success, err;
}

// ============================================================================
// Context Registry Initialization Tests
// ============================================================================

test_context_registry_init :: () -> bool {
    state := init_test_state("test_context_registry_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, auto_create = false, max_history = 10);
        defer destroy_context_registry(*registry);

        assert_true(registry.initialized, "registry should be initialized");
        assert_false(registry.auto_create, "auto_create should be false");
        assert_equal(registry.max_history, cast(s32) 10, "max_history should be 10");
    }

    return all_tests_passed(state);
}

test_context_registry_auto_create :: () -> bool {
    state := init_test_state("test_context_registry_auto_create", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, auto_create = true);
        defer destroy_context_registry(*registry);

        assert_true(registry.auto_create, "auto_create should be true");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Context Definition Tests
// ============================================================================

test_add_context_definition :: () -> bool {
    state := init_test_state("test_add_context_definition", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Create a simple context definition
        def: Context_Definition;
        def.name = copy_string("work");
        def.description = copy_string("Work context");

        success := add_context_definition(*registry, *def);
        assert_true(success, "should add context definition");

        // Check it exists
        definitions := list_context_definitions(*registry);
        defer {
            for *definitions free_context_definition(it);
            array_free(definitions);
        }

        assert_equal(definitions.count, 1, "should have 1 definition");
        assert_string_equal(definitions[0].name, "work", "name should match");
    }

    return all_tests_passed(state);
}

test_add_context_definition_with_args :: () -> bool {
    state := init_test_state("test_add_context_definition_with_args", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Create context with argument schema
        def: Context_Definition;
        def.name = copy_string("work");

        // Add an enum argument
        arg: Arg_Definition;
        arg.name = copy_string("mode");
        arg.short = copy_string("m");
        arg.arg_type = .ENUM;
        array_add(*arg.values, copy_string("programming"));
        array_add(*arg.values, copy_string("meetings"));
        arg.default_value = copy_string("programming");

        array_add(*def.args, arg);

        success := add_context_definition(*registry, *def);
        assert_true(success, "should add context with args");

        // Verify
        definitions := list_context_definitions(*registry);
        defer {
            for *definitions free_context_definition(it);
            array_free(definitions);
        }

        assert_equal(definitions[0].args.count, 1, "should have 1 arg definition");
        assert_string_equal(definitions[0].args[0].name, "mode", "arg name should match");
        assert_equal(definitions[0].args[0].arg_type, Arg_Type.ENUM, "arg type should be ENUM");
    }

    return all_tests_passed(state);
}

test_add_duplicate_context_definition :: () -> bool {
    state := init_test_state("test_add_duplicate_context_definition", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        def1: Context_Definition;
        def1.name = copy_string("work");

        def2: Context_Definition;
        def2.name = copy_string("work");

        success1 := add_context_definition(*registry, *def1);
        assert_true(success1, "first add should succeed");

        success2 := add_context_definition(*registry, *def2);
        assert_false(success2, "duplicate add should fail");

        // Should still have only 1
        definitions := list_context_definitions(*registry);
        defer {
            for *definitions free_context_definition(it);
            array_free(definitions);
        }
        assert_equal(definitions.count, 1, "should still have 1 definition");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Context Switch Tests
// ============================================================================

test_switch_context_simple :: () -> bool {
    state := init_test_state("test_switch_context_simple", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Add a context
        def: Context_Definition;
        def.name = copy_string("work");
        add_context_definition(*registry, *def);

        // Switch to it
        success, error := switch_context_from_input(*registry, "work");
        assert_true(success, "switch should succeed");

        // Verify active context
        active, has_active := get_active_context(*registry);
        defer if has_active free_active_context(*active);

        assert_true(has_active, "should have active context");
        assert_string_equal(active.name, "work", "active name should be work");
    }

    return all_tests_passed(state);
}

test_switch_context_with_args :: () -> bool {
    state := init_test_state("test_switch_context_with_args", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Add context with args
        def: Context_Definition;
        def.name = copy_string("work");

        arg: Arg_Definition;
        arg.name = copy_string("mode");
        arg.arg_type = .STRING;
        array_add(*def.args, arg);

        add_context_definition(*registry, *def);

        // Switch with argument
        success, error := switch_context_from_input(*registry, "work --mode=programming");
        assert_true(success, "switch with args should succeed");

        // Verify active context has the argument
        active, has_active := get_active_context(*registry);
        defer if has_active free_active_context(*active);

        assert_true(has_active, "should have active context");
        assert_string_equal(active.raw_input, "work --mode=programming", "raw input should match");
    }

    return all_tests_passed(state);
}

test_switch_context_nonexistent :: () -> bool {
    state := init_test_state("test_switch_context_nonexistent", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, auto_create = false);
        defer destroy_context_registry(*registry);

        // Try to switch to nonexistent context
        success, error := switch_context_from_input(*registry, "nonexistent");
        assert_false(success, "switch to nonexistent should fail");
        assert_true(error.count > 0, "should have error message");
    }

    return all_tests_passed(state);
}

test_switch_context_auto_create :: () -> bool {
    state := init_test_state("test_switch_context_auto_create", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, auto_create = true);
        defer destroy_context_registry(*registry);

        // Switch to nonexistent context with auto_create enabled
        success, error := switch_context_from_input(*registry, "newcontext");
        assert_true(success, "switch with auto_create should succeed");

        // Verify it was created
        definitions := list_context_definitions(*registry);
        defer {
            for *definitions free_context_definition(it);
            array_free(definitions);
        }
        assert_equal(definitions.count, 1, "should have auto-created definition");
    }

    return all_tests_passed(state);
}

// ============================================================================
// History Tests
// ============================================================================

test_context_history :: () -> bool {
    state := init_test_state("test_context_history", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, max_history = 5);
        defer destroy_context_registry(*registry);

        // Add context and switch to it multiple times
        def: Context_Definition;
        def.name = copy_string("work");
        add_context_definition(*registry, *def);

        switch_context_from_input(*registry, "work --mode=a");
        switch_context_from_input(*registry, "work --mode=b");
        switch_context_from_input(*registry, "work --mode=c");

        // Get history
        history := get_history(*registry);
        defer {
            for history free(it);
            array_free(history);
        }

        assert_equal(history.count, 3, "should have 3 history entries");
        // Most recent first
        assert_string_equal(history[0], "work --mode=c", "most recent should be last switch");
    }

    return all_tests_passed(state);
}

test_context_history_limit :: () -> bool {
    state := init_test_state("test_context_history_limit", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry, max_history = 3);
        defer destroy_context_registry(*registry);

        def: Context_Definition;
        def.name = copy_string("work");
        add_context_definition(*registry, *def);

        // Switch more times than history limit
        switch_context_from_input(*registry, "work --n=1");
        switch_context_from_input(*registry, "work --n=2");
        switch_context_from_input(*registry, "work --n=3");
        switch_context_from_input(*registry, "work --n=4");
        switch_context_from_input(*registry, "work --n=5");

        history := get_history(*registry);
        defer {
            for history free(it);
            array_free(history);
        }

        assert_equal(history.count, 3, "history should be limited to max");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Argument Validation Tests
// ============================================================================

test_validate_enum_arg :: () -> bool {
    state := init_test_state("test_validate_enum_arg", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Create context with enum argument
        def: Context_Definition;
        def.name = copy_string("work");

        arg: Arg_Definition;
        arg.name = copy_string("mode");
        arg.arg_type = .ENUM;
        array_add(*arg.values, copy_string("programming"));
        array_add(*arg.values, copy_string("meetings"));
        array_add(*def.args, arg);

        add_context_definition(*registry, *def);

        // Valid enum value
        success1, _ := switch_context_from_input(*registry, "work --mode=programming");
        assert_true(success1, "valid enum value should succeed");

        // Invalid enum value
        success2, error := switch_context_from_input(*registry, "work --mode=invalid");
        assert_false(success2, "invalid enum value should fail");
    }

    return all_tests_passed(state);
}

test_validate_required_arg :: () -> bool {
    state := init_test_state("test_validate_required_arg", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Create context with required argument
        def: Context_Definition;
        def.name = copy_string("work");

        arg: Arg_Definition;
        arg.name = copy_string("project");
        arg.arg_type = .STRING;
        arg.required = true;
        array_add(*def.args, arg);

        add_context_definition(*registry, *def);

        // Without required arg should fail
        success1, error := switch_context_from_input(*registry, "work");
        assert_false(success1, "missing required arg should fail");

        // With required arg should succeed
        success2, _ := switch_context_from_input(*registry, "work --project=myproject");
        assert_true(success2, "with required arg should succeed");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Delete Context Tests
// ============================================================================

test_remove_context_definition :: () -> bool {
    state := init_test_state("test_remove_context_definition", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        // Add a context
        def: Context_Definition;
        def.name = copy_string("work");
        add_context_definition(*registry, *def);

        // Verify it exists
        definitions := list_context_definitions(*registry);
        assert_equal(definitions.count, 1, "should have 1 definition");
        for *definitions free_context_definition(it);
        array_free(definitions);

        // Delete it
        deleted := remove_context_definition(*registry, "work");
        assert_true(deleted, "delete should succeed");

        // Verify it's gone
        definitions2 := list_context_definitions(*registry);
        defer {
            for *definitions2 free_context_definition(it);
            array_free(definitions2);
        }
        assert_equal(definitions2.count, 0, "should have 0 definitions after delete");
    }

    return all_tests_passed(state);
}

test_delete_nonexistent_context :: () -> bool {
    state := init_test_state("test_delete_nonexistent_context", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        registry: Context_Registry;
        init_context_registry(*registry);
        defer destroy_context_registry(*registry);

        deleted := remove_context_definition(*registry, "nonexistent");
        assert_false(deleted, "delete nonexistent should return false");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test Registration
// ============================================================================

register_context_registry_tests :: () {
    register_test("context_registry/init", test_context_registry_init);
    register_test("context_registry/auto_create", test_context_registry_auto_create);
    register_test("context_registry/add_definition", test_add_context_definition);
    register_test("context_registry/add_definition_with_args", test_add_context_definition_with_args);
    register_test("context_registry/add_duplicate", test_add_duplicate_context_definition);
    register_test("context_registry/switch_simple", test_switch_context_simple);
    register_test("context_registry/switch_with_args", test_switch_context_with_args);
    register_test("context_registry/switch_nonexistent", test_switch_context_nonexistent);
    register_test("context_registry/switch_auto_create", test_switch_context_auto_create);
    register_test("context_registry/history", test_context_history);
    register_test("context_registry/history_limit", test_context_history_limit);
    register_test("context_registry/validate_enum", test_validate_enum_arg);
    register_test("context_registry/validate_required", test_validate_required_arg);
    register_test("context_registry/delete", test_remove_context_definition);
    register_test("context_registry/delete_nonexistent", test_delete_nonexistent_context);
}
