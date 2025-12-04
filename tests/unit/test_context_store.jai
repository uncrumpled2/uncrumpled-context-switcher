// Unit tests for Context State Store
//
// Tests the context store functionality including:
// - Basic CRUD operations
// - Thread-safe access
// - Version tracking
// - Tag management
// - User parameters

// Include context store module
#load "../../src/daemon/context_store.jai";

test_context_store_init :: () -> bool {
    state := init_test_state("test_context_store_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        assert_true(store.initialized, "store should be initialized");
        assert_equal(store.ctx_data.version, cast(u64) 0, "initial version should be 0");
        assert_string_equal(store.ctx_data.profile, "default", "default profile");
        assert_string_equal(store.ctx_data.environment, "dev", "default environment");
    }

    return all_tests_passed(state);
}

test_context_store_get_set :: () -> bool {
    state := init_test_state("test_context_store_get_set", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Create new context
        new_ctx: Context;
        new_ctx.project_id = "test-project";
        new_ctx.profile = "work";
        new_ctx.environment = "prod";

        // Set it
        new_version, change := set_context(*store, *new_ctx);

        assert_equal(new_version, cast(u64) 1, "version should be 1 after first set");
        assert_greater_than(change.changed_fields.count, 0, "should have changed fields");

        // Get and verify
        retrieved := get_context(*store);
        defer free_context(*retrieved);

        assert_string_equal(retrieved.project_id, "test-project", "project_id should match");
        assert_string_equal(retrieved.profile, "work", "profile should match");
        assert_string_equal(retrieved.environment, "prod", "environment should match");
        assert_equal(retrieved.version, cast(u64) 1, "retrieved version should be 1");
    }

    return all_tests_passed(state);
}

test_context_store_update :: () -> bool {
    state := init_test_state("test_context_store_update", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set initial context
        initial: Context;
        initial.project_id = "project-1";
        initial.profile = "default";
        initial.environment = "dev";
        set_context(*store, *initial);

        // Update only profile
        update: Context;
        update.profile = "work";
        new_version, change := update_context(*store, *update);

        assert_equal(new_version, cast(u64) 2, "version should increment");
        assert_equal(change.changed_fields.count, 1, "only profile should change");

        // Verify other fields unchanged
        retrieved := get_context(*store);
        defer free_context(*retrieved);

        assert_string_equal(retrieved.project_id, "project-1", "project_id unchanged");
        assert_string_equal(retrieved.profile, "work", "profile updated");
        assert_string_equal(retrieved.environment, "dev", "environment unchanged");
    }

    return all_tests_passed(state);
}

test_context_store_version_tracking :: () -> bool {
    state := init_test_state("test_context_store_version_tracking", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Initial version
        v0 := get_version(*store);
        assert_equal(v0, cast(u64) 0, "initial version should be 0");

        // Add a tag
        added1, v1 := add_tag(*store, "--work");
        assert_true(added1, "tag should be added");
        assert_equal(v1, cast(u64) 1, "version after first tag");

        // Add another tag
        added2, v2 := add_tag(*store, "--debug");
        assert_true(added2, "second tag should be added");
        assert_equal(v2, cast(u64) 2, "version after second tag");

        // Remove a tag
        removed, v3 := remove_tag(*store, "--work");
        assert_true(removed, "tag should be removed");
        assert_equal(v3, cast(u64) 3, "version after removal");

        // Final version check
        final_version := get_version(*store);
        assert_equal(final_version, cast(u64) 3, "final version should be 3");
    }

    return all_tests_passed(state);
}

test_context_store_tags :: () -> bool {
    state := init_test_state("test_context_store_tags", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Add tags
        add_tag(*store, "--work");
        add_tag(*store, "--important");
        add_tag(*store, "--debug");

        // Check has_tag
        assert_true(has_tag(*store, "--work"), "should have --work");
        assert_true(has_tag(*store, "--important"), "should have --important");
        assert_true(has_tag(*store, "--debug"), "should have --debug");
        assert_false(has_tag(*store, "--missing"), "should not have --missing");

        // Get all tags
        tags := get_tags(*store);
        defer {
            for tags free(it);
            array_free(tags);
        }
        assert_equal(tags.count, 3, "should have 3 tags");

        // Try to add duplicate
        added, _ := add_tag(*store, "--work");
        assert_false(added, "duplicate tag should not be added");

        // Remove tag
        removed, _ := remove_tag(*store, "--debug");
        assert_true(removed, "tag should be removed");
        assert_false(has_tag(*store, "--debug"), "should no longer have --debug");

        // Remove non-existent tag
        removed2, _ := remove_tag(*store, "--not-there");
        assert_false(removed2, "non-existent tag removal should return false");
    }

    return all_tests_passed(state);
}

test_context_store_user_params :: () -> bool {
    state := init_test_state("test_context_store_user_params", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        initial_version := get_version(*store);

        // Set a parameter
        v1 := set_user_param(*store, "mode", "debug");
        assert_greater_than(v1, initial_version, "version should increase");

        // Get parameter
        value, found := get_user_param(*store, "mode");
        defer free(value);
        assert_true(found, "parameter should be found");
        assert_string_equal(value, "debug", "value should match");

        // Update parameter
        v2 := set_user_param(*store, "mode", "release");
        assert_greater_than(v2, v1, "version should increase on update");

        value2, found2 := get_user_param(*store, "mode");
        defer free(value2);
        assert_true(found2, "updated param should be found");
        assert_string_equal(value2, "release", "updated value should match");

        // Get non-existent parameter
        _, found3 := get_user_param(*store, "missing");
        assert_false(found3, "missing param should not be found");

        // Set same value (should not increment version)
        v3 := set_user_param(*store, "mode", "release");
        assert_equal(v3, v2, "version should not change for same value");

        // Remove parameter
        removed, v4 := remove_user_param(*store, "mode");
        assert_true(removed, "param should be removed");
        assert_greater_than(v4, v3, "version should increase on removal");

        // Remove non-existent
        removed2, _ := remove_user_param(*store, "missing");
        assert_false(removed2, "removing non-existent should return false");
    }

    return all_tests_passed(state);
}

test_context_store_workspace_metadata :: () -> bool {
    state := init_test_state("test_context_store_workspace_metadata", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        // Set metadata
        v1 := set_workspace_metadata(*store, "cwd", "/home/user/project");
        assert_greater_than(v1, cast(u64) 0, "version should increase");

        // Get metadata
        value, found := get_workspace_metadata(*store, "cwd");
        defer free(value);
        assert_true(found, "metadata should be found");
        assert_string_equal(value, "/home/user/project", "value should match");

        // Get non-existent
        _, found2 := get_workspace_metadata(*store, "missing");
        assert_false(found2, "missing metadata should not be found");
    }

    return all_tests_passed(state);
}

test_context_store_change_detection :: () -> bool {
    state := init_test_state("test_context_store_change_detection", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        store: Context_Store;
        init_context_store(*store);
        defer destroy_context_store(*store);

        v0 := get_version(*store);  // Should be 0

        // Set initial context - need copy_string for proper strings
        initial: Context;
        initial.project_id = copy_string("proj-1");
        initial.profile = copy_string("default");
        initial.environment = copy_string("dev");
        v1, _ := set_context(*store, *initial);

        // Change multiple fields
        new_ctx: Context;
        new_ctx.project_id = copy_string("proj-2");   // Changed
        new_ctx.profile = copy_string("work");        // Changed
        new_ctx.environment = copy_string("dev");     // Same

        version, change := set_context(*store, *new_ctx);

        // Check change record
        assert_equal(change.previous_version, v1, "previous version should match first set");
        assert_equal(version, v1 + 1, "new version should be incremented");

        // Verify changed_fields contains the right items
        has_project := false;
        has_profile := false;
        has_env := false;
        for change.changed_fields {
            if it == "project_id" has_project = true;
            if it == "profile" has_profile = true;
            if it == "environment" has_env = true;
        }

        assert_true(has_project, "should detect project_id change");
        assert_true(has_profile, "should detect profile change");
        assert_false(has_env, "should not detect environment change");

        // Cleanup
        array_free(change.changed_fields);
    }

    return all_tests_passed(state);
}

test_context_copy :: () -> bool {
    state := init_test_state("test_context_copy", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Create original context - use copy_string for freeable strings
        original: Context;
        original.project_id = copy_string("original-project");
        original.profile = copy_string("original-profile");
        original.environment = copy_string("prod");
        original.version = 42;
        array_add(*original.tags, copy_string("tag1"));
        array_add(*original.tags, copy_string("tag2"));
        table_set(*original.user_params, copy_string("key1"), copy_string("value1"));

        // Copy it
        copied := copy_context(*original);
        defer free_context(*copied);

        // Verify copy is independent
        assert_string_equal(copied.project_id, "original-project", "project_id copied");
        assert_string_equal(copied.profile, "original-profile", "profile copied");
        assert_equal(copied.version, cast(u64) 42, "version copied");
        assert_equal(copied.tags.count, 2, "tags copied");

        // Cleanup original
        free_context_data(*original);

        // Verify copy is still valid after original is freed
        assert_string_equal(copied.project_id, "original-project", "copy should be independent after free");
    }

    return all_tests_passed(state);
}

// Register all context store tests
register_context_store_tests :: () {
    register_test("context_store/init", test_context_store_init);
    register_test("context_store/get_set", test_context_store_get_set);
    register_test("context_store/update", test_context_store_update);
    register_test("context_store/version_tracking", test_context_store_version_tracking);
    register_test("context_store/tags", test_context_store_tags);
    register_test("context_store/user_params", test_context_store_user_params);
    register_test("context_store/workspace_metadata", test_context_store_workspace_metadata);
    register_test("context_store/change_detection", test_context_store_change_detection);
    register_test("context_store/copy", test_context_copy);
}
