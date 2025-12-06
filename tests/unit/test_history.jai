// Tests for UI History Manager
//
// Tests cover:
// - Manager initialization and cleanup
// - Adding entries to history
// - Entry movement to front on reuse
// - History pruning
// - JSON serialization

#import "Basic";
#import "String";

// ============================================================================
// Types (matching history.jai)
// ============================================================================

Test_History_Entry :: struct {
    text: string;
    icon: string;
    timestamp: s64;
    use_count: s32;
}

Test_History_Config :: struct {
    max_entries: s32 = 100;
    auto_save: bool = true;
}

Test_History_Manager :: struct {
    config: Test_History_Config;
    entries: [..]Test_History_Entry;
    history_path: string;
    dirty: bool;
    initialized: bool;
}

// ============================================================================
// Simplified Manager Functions (for testing without file I/O)
// ============================================================================

create_test_manager :: (config: Test_History_Config = .{}) -> *Test_History_Manager {
    manager := New(Test_History_Manager);
    manager.config = config;
    manager.history_path = copy_string("/tmp/test_history.json");
    manager.initialized = true;
    return manager;
}

destroy_test_manager :: (manager: *Test_History_Manager) {
    if manager == null return;

    for *manager.entries {
        if it.text.count > 0 free(it.text);
        if it.icon.count > 0 free(it.icon);
    }
    array_free(manager.entries);

    if manager.history_path.count > 0 free(manager.history_path);
    free(manager);
}

test_add_entry :: (manager: *Test_History_Manager, text: string, icon: string = "") {
    if manager == null || !manager.initialized return;

    // Check for existing
    for *entry, idx: manager.entries {
        if entry.text == text {
            entry.timestamp = 12345;  // Mock timestamp
            entry.use_count += 1;

            if idx > 0 {
                temp := <<entry;
                i := idx;
                while i > 0 {
                    manager.entries[i] = manager.entries[i - 1];
                    i -= 1;
                }
                manager.entries[0] = temp;
            }
            manager.dirty = true;
            return;
        }
    }

    // New entry
    new_entry: Test_History_Entry;
    new_entry.text = copy_string(text);
    new_entry.icon = copy_string(icon);
    new_entry.timestamp = 12345;
    new_entry.use_count = 1;

    array_insert_at(*manager.entries, new_entry, 0);

    // Prune
    while manager.entries.count > manager.config.max_entries {
        entry := *manager.entries[manager.entries.count - 1];
        if entry.text.count > 0 free(entry.text);
        if entry.icon.count > 0 free(entry.icon);
        array_ordered_remove_by_index(*manager.entries, manager.entries.count - 1);
    }

    manager.dirty = true;
}

test_remove_entry :: (manager: *Test_History_Manager, text: string) -> bool {
    if manager == null return false;

    for *entry, idx: manager.entries {
        if entry.text == text {
            if entry.text.count > 0 free(entry.text);
            if entry.icon.count > 0 free(entry.icon);
            array_ordered_remove_by_index(*manager.entries, idx);
            manager.dirty = true;
            return true;
        }
    }
    return false;
}

test_clear_entries :: (manager: *Test_History_Manager) {
    if manager == null return;

    for *manager.entries {
        if it.text.count > 0 free(it.text);
        if it.icon.count > 0 free(it.icon);
    }
    array_reset_keeping_memory(*manager.entries);
    manager.dirty = true;
}

// ============================================================================
// JSON Escape Function (same as in history.jai)
// ============================================================================

test_escape_json :: (s: string) -> string {
    builder: String_Builder;

    for i: 0..s.count-1 {
        c := s[i];
        if c == {
            case #char "\""; append(*builder, "\\\"");
            case #char "\\"; append(*builder, "\\\\");
            case #char "\n"; append(*builder, "\\n");
            case #char "\r"; append(*builder, "\\r");
            case #char "\t"; append(*builder, "\\t");
            case;
                if c < 32 {
                    append(*builder, tprint("\\u%", formatInt(c, base=16, minimum_digits=4)));
                } else {
                    append(*builder, c);
                }
        }
    }

    return builder_to_string(*builder);
}

// ============================================================================
// Test: Manager initialization
// ============================================================================

test_history_manager_init :: () -> bool {
    state := init_test_state("test_history_manager_init", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager := create_test_manager();
        defer destroy_test_manager(manager);

        assert_not_null(manager, "History manager should be created");
        assert_true(manager.initialized, "Manager should be initialized");
        assert_equal(manager.config.max_entries, 100, "Default max_entries should be 100");
        assert_true(manager.config.auto_save, "Default auto_save should be true");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Manager initialization with custom config
// ============================================================================

test_history_manager_init_with_config :: () -> bool {
    state := init_test_state("test_history_manager_init_with_config", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.max_entries = 50;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        assert_not_null(manager, "History manager should be created");
        assert_equal(manager.config.max_entries, 50, "max_entries should be 50");
        assert_false(manager.config.auto_save, "auto_save should be false");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Manager cleanup
// ============================================================================

test_history_manager_deinit :: () -> bool {
    state := init_test_state("test_history_manager_deinit", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        manager := create_test_manager();
        test_add_entry(manager, "Test 1");
        test_add_entry(manager, "Test 2");

        // This should not crash
        destroy_test_manager(manager);

        // Also test null handling
        destroy_test_manager(null);

        assert_true(true, "Deinit completed without crash");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Add single entry
// ============================================================================

test_add_to_history_single :: () -> bool {
    state := init_test_state("test_add_to_history_single", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");

        assert_equal(manager.entries.count, 1, "Should have 1 entry");
        assert_string_equal(manager.entries[0].text, "Chrome", "Entry text should match");
        assert_equal(manager.entries[0].use_count, 1, "Use count should be 1");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Add multiple entries
// ============================================================================

test_add_to_history_multiple :: () -> bool {
    state := init_test_state("test_add_to_history_multiple", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        test_add_entry(manager, "Firefox");
        test_add_entry(manager, "Safari");

        assert_equal(manager.entries.count, 3, "Should have 3 entries");
        // Most recent should be first
        assert_string_equal(manager.entries[0].text, "Safari", "First entry should be Safari");
        assert_string_equal(manager.entries[1].text, "Firefox", "Second entry should be Firefox");
        assert_string_equal(manager.entries[2].text, "Chrome", "Third entry should be Chrome");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Duplicate entry moves to front
// ============================================================================

test_add_to_history_duplicate_moves_to_front :: () -> bool {
    state := init_test_state("test_add_to_history_duplicate_moves_to_front", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        test_add_entry(manager, "Firefox");
        test_add_entry(manager, "Safari");
        test_add_entry(manager, "Chrome");  // Re-add

        assert_equal(manager.entries.count, 3, "Should still have 3 entries");
        assert_string_equal(manager.entries[0].text, "Chrome", "Chrome should be first after re-add");
        assert_equal(manager.entries[0].use_count, 2, "Chrome use count should be 2");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Add entry with icon
// ============================================================================

test_add_to_history_with_icon :: () -> bool {
    state := init_test_state("test_add_to_history_with_icon", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome", "chrome-icon");

        assert_equal(manager.entries.count, 1, "Should have 1 entry");
        assert_string_equal(manager.entries[0].icon, "chrome-icon", "Icon should match");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: History pruning
// ============================================================================

test_history_pruning :: () -> bool {
    state := init_test_state("test_history_pruning", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.max_entries = 3;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Item 1");
        test_add_entry(manager, "Item 2");
        test_add_entry(manager, "Item 3");
        test_add_entry(manager, "Item 4");  // Should cause pruning

        assert_equal(manager.entries.count, 3, "Should have max 3 entries");
        assert_string_equal(manager.entries[0].text, "Item 4", "First should be Item 4");
        assert_string_equal(manager.entries[1].text, "Item 3", "Second should be Item 3");
        assert_string_equal(manager.entries[2].text, "Item 2", "Third should be Item 2");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Remove entry
// ============================================================================

test_remove_from_history :: () -> bool {
    state := init_test_state("test_remove_from_history", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        test_add_entry(manager, "Firefox");
        test_add_entry(manager, "Safari");

        result := test_remove_entry(manager, "Firefox");
        assert_true(result, "Remove should succeed");

        assert_equal(manager.entries.count, 2, "Should have 2 entries");
        assert_string_equal(manager.entries[0].text, "Safari", "First should be Safari");
        assert_string_equal(manager.entries[1].text, "Chrome", "Second should be Chrome");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Remove entry not found
// ============================================================================

test_remove_from_history_not_found :: () -> bool {
    state := init_test_state("test_remove_from_history_not_found", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");

        result := test_remove_entry(manager, "NonExistent");
        assert_false(result, "Remove should fail for non-existent entry");

        assert_equal(manager.entries.count, 1, "Should still have 1 entry");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Clear history
// ============================================================================

test_clear_history :: () -> bool {
    state := init_test_state("test_clear_history", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        test_add_entry(manager, "Firefox");
        test_add_entry(manager, "Safari");

        test_clear_entries(manager);

        assert_equal(manager.entries.count, 0, "Should have 0 entries after clear");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: JSON escape simple string
// ============================================================================

test_escape_json_string :: () -> bool {
    state := init_test_state("test_escape_json_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        result := test_escape_json("hello");
        defer free(result);
        assert_string_equal(result, "hello", "Simple string should be unchanged");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: JSON escape with quotes
// ============================================================================

test_escape_json_string_with_quotes :: () -> bool {
    state := init_test_state("test_escape_json_string_with_quotes", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        result := test_escape_json("hello \"world\"");
        defer free(result);
        assert_string_equal(result, "hello \\\"world\\\"", "Quotes should be escaped");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: JSON escape with newlines
// ============================================================================

test_escape_json_string_with_newlines :: () -> bool {
    state := init_test_state("test_escape_json_string_with_newlines", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        result := test_escape_json("line1\nline2");
        defer free(result);
        assert_string_equal(result, "line1\\nline2", "Newlines should be escaped");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: JSON escape with backslash
// ============================================================================

test_escape_json_string_with_backslash :: () -> bool {
    state := init_test_state("test_escape_json_string_with_backslash", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        result := test_escape_json("path\\to\\file");
        defer free(result);
        assert_string_equal(result, "path\\\\to\\\\file", "Backslashes should be escaped");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Dirty flag on add
// ============================================================================

test_dirty_flag_on_add :: () -> bool {
    state := init_test_state("test_dirty_flag_on_add", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        assert_false(manager.dirty, "Dirty should be false initially");

        test_add_entry(manager, "Chrome");

        assert_true(manager.dirty, "Dirty should be true after add");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Dirty flag on remove
// ============================================================================

test_dirty_flag_on_remove :: () -> bool {
    state := init_test_state("test_dirty_flag_on_remove", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        manager.dirty = false;  // Reset manually

        test_remove_entry(manager, "Chrome");

        assert_true(manager.dirty, "Dirty should be true after remove");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Test: Dirty flag on clear
// ============================================================================

test_dirty_flag_on_clear :: () -> bool {
    state := init_test_state("test_dirty_flag_on_clear", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config: Test_History_Config;
        config.auto_save = false;

        manager := create_test_manager(config);
        defer destroy_test_manager(manager);

        test_add_entry(manager, "Chrome");
        manager.dirty = false;  // Reset manually

        test_clear_entries(manager);

        assert_true(manager.dirty, "Dirty should be true after clear");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Registration
// ============================================================================

register_history_tests :: () {
    register_test("history/manager_init", test_history_manager_init);
    register_test("history/manager_init_with_config", test_history_manager_init_with_config);
    register_test("history/manager_deinit", test_history_manager_deinit);
    register_test("history/add_single", test_add_to_history_single);
    register_test("history/add_multiple", test_add_to_history_multiple);
    register_test("history/add_duplicate_moves_to_front", test_add_to_history_duplicate_moves_to_front);
    register_test("history/add_with_icon", test_add_to_history_with_icon);
    register_test("history/pruning", test_history_pruning);
    register_test("history/remove", test_remove_from_history);
    register_test("history/remove_not_found", test_remove_from_history_not_found);
    register_test("history/clear", test_clear_history);
    register_test("history/escape_json", test_escape_json_string);
    register_test("history/escape_json_quotes", test_escape_json_string_with_quotes);
    register_test("history/escape_json_newlines", test_escape_json_string_with_newlines);
    register_test("history/escape_json_backslash", test_escape_json_string_with_backslash);
    register_test("history/dirty_on_add", test_dirty_flag_on_add);
    register_test("history/dirty_on_remove", test_dirty_flag_on_remove);
    register_test("history/dirty_on_clear", test_dirty_flag_on_clear);
}
