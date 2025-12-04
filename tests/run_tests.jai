// Main test runner for the Uncrumpled Context Switcher
//
// Runs all unit and integration tests and reports results.
// Usage: Build and run this file directly.
//
// Build: jai tests/run_tests.jai
// Run: ./tests/run_tests

#import "Basic";
#import "String";

#load "helpers/assertions.jai";
#load "helpers/test_utils.jai";

// Unit tests
#load "unit/test_daemon_args.jai";
#load "unit/test_context_store.jai";
#load "unit/test_ipc.jai";

// Test registry - each test module registers itself here
Test_Entry :: struct {
    name: string;
    test_proc: () -> bool;  // Returns true if all assertions passed
    category: string;       // "unit", "integration", "e2e"
}

test_registry: [..] Test_Entry;

// Register a test
register_test :: (name: string, proc: () -> bool, category := "unit") {
    entry: Test_Entry;
    entry.name = name;
    entry.test_proc = proc;
    entry.category = category;
    array_add(*test_registry, entry);
}

// Run all registered tests
run_all_tests :: (filter_category := "") -> int, int, int {
    passed := 0;
    failed := 0;
    skipped := 0;

    print("\n");
    print("================================================================================\n");
    print("                    UNCRUMPLED CONTEXT SWITCHER TEST SUITE                      \n");
    print("================================================================================\n");
    print("\n");

    for test_registry {
        // Filter by category if specified
        if filter_category.count > 0 && it.category != filter_category {
            skipped += 1;
            continue;
        }

        print("--------------------------------------------------------------------------------\n");
        print("[%] %\n", it.category, it.name);
        print("--------------------------------------------------------------------------------\n");

        // Run the test
        success := it.test_proc();

        if success {
            passed += 1;
            print("[PASS] %\n\n", it.name);
        } else {
            failed += 1;
            print("[FAIL] %\n\n", it.name);
        }
    }

    return passed, failed, skipped;
}

// Print final summary
print_final_summary :: (passed: int, failed: int, skipped: int) {
    total := passed + failed;

    print("\n");
    print("================================================================================\n");
    print("                              FINAL TEST SUMMARY                                \n");
    print("================================================================================\n");
    print("\n");
    print("  Total tests run: %\n", total);
    print("  Passed:          % (\%%)\n", passed, ifx total > 0 then (passed * 100 / total) else 0);
    print("  Failed:          % (\%%)\n", failed, ifx total > 0 then (failed * 100 / total) else 0);
    if skipped > 0 {
        print("  Skipped:         %\n", skipped);
    }
    print("\n");

    if failed == 0 {
        print("  ========================================\n");
        print("  =         ALL TESTS PASSED!           =\n");
        print("  ========================================\n");
    } else {
        print("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        print("  !       SOME TESTS FAILED!            !\n");
        print("  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    }
    print("\n");
}

//
// ============================================================================
// SELF-TESTS FOR TEST INFRASTRUCTURE
// ============================================================================
//
// These tests verify that the test framework itself works correctly.
//

test_assertions_basic :: () -> bool {
    state := init_test_state("test_assertions_basic", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test assert_true
        assert_true(true, "true should be true");
        assert_true(1 == 1, "1 should equal 1");
        assert_true(5 > 3, "5 should be greater than 3");

        // Test assert_false
        assert_false(false, "false should be false");
        assert_false(1 == 2, "1 should not equal 2");

        // Test assert_equal with different types
        assert_equal(42, 42, "integers should be equal");
        assert_equal("hello", "hello", "strings should be equal");
        assert_equal(3.14, 3.14, "floats should be equal");

        // Test assert_not_equal
        assert_not_equal(1, 2, "1 and 2 should not be equal");
        assert_not_equal("foo", "bar", "different strings should not be equal");

        // Test numeric comparisons
        assert_greater_than(10, 5, "10 should be greater than 5");
        assert_less_than(3, 7, "3 should be less than 7");
        assert_greater_or_equal(5, 5, "5 should be >= 5");
        assert_greater_or_equal(6, 5, "6 should be >= 5");
        assert_less_or_equal(5, 5, "5 should be <= 5");
        assert_less_or_equal(4, 5, "4 should be <= 5");

        // Test range check
        assert_in_range(5, 1, 10, "5 should be in range [1, 10]");
        assert_in_range(1, 1, 10, "1 should be in range [1, 10] (boundary)");
        assert_in_range(10, 1, 10, "10 should be in range [1, 10] (boundary)");
    }

    return all_tests_passed(state);
}

test_assertions_pointers :: () -> bool {
    state := init_test_state("test_assertions_pointers", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        x := 42;
        ptr: *int = *x;
        null_ptr: *int = null;

        assert_not_null(ptr, "ptr should not be null");
        assert_null(null_ptr, "null_ptr should be null");
    }

    return all_tests_passed(state);
}

test_assertions_strings :: () -> bool {
    state := init_test_state("test_assertions_strings", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_string_equal("hello", "hello", "identical strings should be equal");
        assert_string_contains("hello world", "world", "string should contain substring");
        assert_string_contains("hello world", "hello", "string should contain prefix");
        assert_string_contains("testing", "sting", "string should contain substring in middle");
    }

    return all_tests_passed(state);
}

test_assertions_arrays :: () -> bool {
    state := init_test_state("test_assertions_arrays", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        arr := int.[1, 2, 3, 4, 5];
        empty_arr: []int;

        assert_array_length(arr, 5, "array should have 5 elements");
        assert_array_not_empty(arr, "array should not be empty");
        assert_array_empty(empty_arr, "empty array should be empty");
        assert_array_length(empty_arr, 0, "empty array should have 0 elements");
    }

    return all_tests_passed(state);
}

test_assertions_floats :: () -> bool {
    state := init_test_state("test_assertions_floats", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_float_equal(3.14159, 3.14159, 0.00001, "PI should equal itself");
        assert_float_equal(1.0/3.0 * 3.0, 1.0, 0.0001, "1/3 * 3 should approximately equal 1");
        assert_float_equal(0.1 + 0.2, 0.3, 0.0001, "0.1 + 0.2 should approximately equal 0.3");
    }

    return all_tests_passed(state);
}

test_utils_random_string :: () -> bool {
    state := init_test_state("test_utils_random_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Generate strings of various lengths
        s1 := generate_random_string(10);
        defer free(s1);
        assert_equal(s1.count, 10, "generated string should have requested length");

        s2 := generate_random_string(0);
        defer free(s2);
        assert_equal(s2.count, 0, "empty string request should return empty string");

        s3 := generate_random_string(100);
        defer free(s3);
        assert_equal(s3.count, 100, "100-char string should have 100 chars");

        // Test custom charset
        s4 := generate_random_string(20, "ABC");
        defer free(s4);
        assert_equal(s4.count, 20, "custom charset string should have correct length");

        // Verify characters are from charset
        valid := true;
        for 0..s4.count-1 {
            c := s4[it];
            if c != #char "A" && c != #char "B" && c != #char "C" {
                valid = false;
                break;
            }
        }
        assert_true(valid, "all characters should be from specified charset");
    }

    return all_tests_passed(state);
}

test_utils_random_int :: () -> bool {
    state := init_test_state("test_utils_random_int", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Generate many random integers and verify they're in range
        min_val := 10;
        max_val := 20;

        for 0..99 {
            val := random_int_range(min_val, max_val);
            assert_in_range(val, min_val, max_val, "random int should be in range");
        }

        // Edge case: min == max
        val := random_int_range(5, 5);
        assert_equal(val, 5, "when min == max, result should equal min");
    }

    return all_tests_passed(state);
}

test_utils_timer :: () -> bool {
    state := init_test_state("test_utils_timer", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        timer: Test_Timer;
        start_timer(*timer);

        // Sleep for a small duration
        sleep_ms(50);

        stop_timer(*timer);

        elapsed := get_elapsed_ms(*timer);

        // Should be at least 50ms, but allow some tolerance
        assert_greater_or_equal(elapsed, 40.0, "elapsed time should be at least ~50ms");
        // Should not be too long (less than 200ms for a 50ms sleep)
        assert_less_than(elapsed, 200.0, "elapsed time should be reasonable");
    }

    return all_tests_passed(state);
}

test_utils_temp_file :: () -> bool {
    state := init_test_state("test_utils_temp_file", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        test_content := "Hello, this is test content!\nLine 2\nLine 3";

        path, success := create_temp_file(test_content, ".txt");
        defer {
            if path.count > 0 {
                delete_temp_file(path);
                free(path);
            }
        }

        assert_true(success, "temp file creation should succeed");
        assert_true(path.count > 0, "temp file path should not be empty");

        // Verify file exists and has correct content
        content, read_success := read_entire_file(path);
        defer free(content);

        assert_true(read_success, "should be able to read temp file");
        assert_string_equal(content, test_content, "file content should match");
    }

    return all_tests_passed(state);
}

test_utils_json_generator :: () -> bool {
    state := init_test_state("test_utils_json_generator", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        json := generate_test_json(3);
        defer free(json);

        assert_true(json.count > 0, "generated JSON should not be empty");
        assert_string_contains(json, "{", "JSON should start with {");
        assert_string_contains(json, "}", "JSON should end with }");
        assert_string_contains(json, "field0", "JSON should contain field0");
        assert_string_contains(json, "field1", "JSON should contain field1");
        assert_string_contains(json, "field2", "JSON should contain field2");
    }

    return all_tests_passed(state);
}

test_utils_context_generator :: () -> bool {
    state := init_test_state("test_utils_context_generator", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        test_ctx := generate_test_context();
        defer free_test_context(*test_ctx);

        assert_true(test_ctx.project_id.count > 0, "project_id should not be empty");
        assert_true(test_ctx.profile.count > 0, "profile should not be empty");
        assert_true(test_ctx.environment.count > 0, "environment should not be empty");
        // Tags can be 0-3, so just verify it's a reasonable number
        assert_less_or_equal(test_ctx.tags.count, 3, "tags should be <= 3");
    }

    return all_tests_passed(state);
}

// Register all infrastructure self-tests
register_infrastructure_tests :: () {
    register_test("assertions/basic", test_assertions_basic);
    register_test("assertions/pointers", test_assertions_pointers);
    register_test("assertions/strings", test_assertions_strings);
    register_test("assertions/arrays", test_assertions_arrays);
    register_test("assertions/floats", test_assertions_floats);
    register_test("utils/random_string", test_utils_random_string);
    register_test("utils/random_int", test_utils_random_int);
    register_test("utils/timer", test_utils_timer);
    register_test("utils/temp_file", test_utils_temp_file);
    register_test("utils/json_generator", test_utils_json_generator);
    register_test("utils/context_generator", test_utils_context_generator);
}

//
// ============================================================================
// MAIN ENTRY POINT
// ============================================================================
//

main :: () {
    // Initialize random number generator with current time for variety
    random_seed(cast(u64)(seconds_since_init() * 1000000));

    print("\n");
    print("Initializing test suite...\n");

    // Register all tests
    register_infrastructure_tests();

    // Load and register unit tests
    register_daemon_args_tests();
    register_context_store_tests();
    register_ipc_tests();

    print("Registered % tests\n", test_registry.count);

    // Run all tests (or filter by command line args in the future)
    passed, failed, skipped := run_all_tests();

    // Print summary
    print_final_summary(passed, failed, skipped);

    // Exit with appropriate code
    if failed > 0 {
        exit(1);
    }
}
