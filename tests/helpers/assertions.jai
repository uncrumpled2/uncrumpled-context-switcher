// Test assertion helpers for the Uncrumpled Context Switcher test suite
//
// Provides assertion macros and helper functions for writing unit and integration tests.
// Uses the context system to track test state and provide detailed failure messages.

#import "Basic";

// Test result tracking
Test_Result :: struct {
    passed: bool;
    message: string;
    file: string;
    line: s64;
}

// Global test state - tracks all assertions in current test
Test_State :: struct {
    test_name: string;
    assertions_passed: int;
    assertions_failed: int;
    failure_messages: [..] Test_Result;
    verbose: bool;
}

// Thread-local test state
#add_context test_state: *Test_State;

// Initialize test state for a new test
init_test_state :: (name: string, verbose := false) -> *Test_State {
    state := New(Test_State);
    state.test_name = name;
    state.assertions_passed = 0;
    state.assertions_failed = 0;
    state.verbose = verbose;
    return state;
}

// Clean up test state
cleanup_test_state :: (state: *Test_State) {
    if state == null return;

    for state.failure_messages {
        // Messages are allocated with tprint, no need to free
    }
    array_free(state.failure_messages);
    free(state);
}

// Core assertion implementation
assert_impl :: (condition: bool, message: string, file: string, line: s64) -> bool {
    state := context.test_state;

    if condition {
        if state != null {
            state.assertions_passed += 1;
            if state.verbose {
                print("  [PASS] %\n", message);
            }
        }
        return true;
    } else {
        if state != null {
            state.assertions_failed += 1;
            result: Test_Result;
            result.passed = false;
            result.message = message;
            result.file = file;
            result.line = line;
            array_add(*state.failure_messages, result);
        }
        print("  [FAIL] % (at %:%)\n", message, file, line);
        return false;
    }
}

// Assert that a condition is true
assert_true :: (condition: bool, message := "Expected true", loc := #caller_location) -> bool {
    return assert_impl(condition, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a condition is false
assert_false :: (condition: bool, message := "Expected false", loc := #caller_location) -> bool {
    return assert_impl(!condition, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert equality for any comparable type
assert_equal :: (actual: $T, expected: T, message := "", loc := #caller_location) -> bool {
    result := actual == expected;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (expected: %, actual: %)", message, expected, actual);
    } else {
        msg = tprint("Expected % but got %", expected, actual);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert inequality
assert_not_equal :: (actual: $T, expected: T, message := "", loc := #caller_location) -> bool {
    result := actual != expected;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (value should not be %)", message, expected);
    } else {
        msg = tprint("Value should not equal %", expected);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a pointer is null
assert_null :: (ptr: *$T, message := "Expected null", loc := #caller_location) -> bool {
    return assert_impl(ptr == null, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a pointer is not null
assert_not_null :: (ptr: *$T, message := "Expected non-null", loc := #caller_location) -> bool {
    return assert_impl(ptr != null, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a value is greater than another
assert_greater_than :: (actual: $T, threshold: T, message := "", loc := #caller_location) -> bool {
    result := actual > threshold;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (% should be > %)", message, actual, threshold);
    } else {
        msg = tprint("Expected % > %", actual, threshold);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a value is less than another
assert_less_than :: (actual: $T, threshold: T, message := "", loc := #caller_location) -> bool {
    result := actual < threshold;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (% should be < %)", message, actual, threshold);
    } else {
        msg = tprint("Expected % < %", actual, threshold);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a value is greater than or equal to another
assert_greater_or_equal :: (actual: $T, threshold: T, message := "", loc := #caller_location) -> bool {
    result := actual >= threshold;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (% should be >= %)", message, actual, threshold);
    } else {
        msg = tprint("Expected % >= %", actual, threshold);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert that a value is less than or equal to another
assert_less_or_equal :: (actual: $T, threshold: T, message := "", loc := #caller_location) -> bool {
    result := actual <= threshold;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (% should be <= %)", message, actual, threshold);
    } else {
        msg = tprint("Expected % <= %", actual, threshold);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert string equality (case-sensitive)
assert_string_equal :: (actual: string, expected: string, message := "", loc := #caller_location) -> bool {
    result := actual == expected;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (expected: \"%\", actual: \"%\")", message, expected, actual);
    } else {
        msg = tprint("Expected string \"%\" but got \"%\"", expected, actual);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert string contains substring
assert_string_contains :: (haystack: string, needle: string, message := "", loc := #caller_location) -> bool {
    #import "String";
    result := contains(haystack, needle);
    msg: string;
    if message.count > 0 {
        msg = tprint("% (string should contain \"%\")", message, needle);
    } else {
        msg = tprint("String \"%\" should contain \"%\"", haystack, needle);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert array/dynamic array length
assert_array_length :: (arr: [] $T, expected_length: int, message := "", loc := #caller_location) -> bool {
    result := arr.count == expected_length;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (expected length: %, actual: %)", message, expected_length, arr.count);
    } else {
        msg = tprint("Expected array length % but got %", expected_length, arr.count);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert array is empty
assert_array_empty :: (arr: [] $T, message := "Expected empty array", loc := #caller_location) -> bool {
    return assert_impl(arr.count == 0, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert array is not empty
assert_array_not_empty :: (arr: [] $T, message := "Expected non-empty array", loc := #caller_location) -> bool {
    return assert_impl(arr.count > 0, message, loc.fully_pathed_filename, loc.line_number);
}

// Assert value is within a range (inclusive)
assert_in_range :: (value: $T, min_val: T, max_val: T, message := "", loc := #caller_location) -> bool {
    result := value >= min_val && value <= max_val;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (% should be in [%, %])", message, value, min_val, max_val);
    } else {
        msg = tprint("Value % should be in range [%, %]", value, min_val, max_val);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Assert float approximately equal (with epsilon tolerance)
assert_float_equal :: (actual: float64, expected: float64, epsilon := 0.0001, message := "", loc := #caller_location) -> bool {
    diff := actual - expected;
    if diff < 0 diff = -diff;
    result := diff <= epsilon;
    msg: string;
    if message.count > 0 {
        msg = tprint("% (expected: %, actual: %, epsilon: %)", message, expected, actual, epsilon);
    } else {
        msg = tprint("Expected ~% but got % (epsilon: %)", expected, actual, epsilon);
    }
    return assert_impl(result, msg, loc.fully_pathed_filename, loc.line_number);
}

// Print test summary
print_test_summary :: (state: *Test_State) {
    if state == null {
        print("No test state available\n");
        return;
    }

    total := state.assertions_passed + state.assertions_failed;
    print("\n");
    print("=== Test Summary: % ===\n", state.test_name);
    print("  Total assertions: %\n", total);
    print("  Passed: %\n", state.assertions_passed);
    print("  Failed: %\n", state.assertions_failed);

    if state.assertions_failed > 0 {
        print("\n  Failures:\n");
        for state.failure_messages {
            print("    - % (at %:%)\n", it.message, it.file, it.line);
        }
    }

    if state.assertions_failed == 0 {
        print("\n  Result: ALL TESTS PASSED\n");
    } else {
        print("\n  Result: SOME TESTS FAILED\n");
    }
    print("\n");
}

// Check if all tests passed
all_tests_passed :: (state: *Test_State) -> bool {
    if state == null return false;
    return state.assertions_failed == 0;
}

// Convenience macro to run a test with automatic state management
run_test :: (name: string, test_proc: () -> void, verbose := false) -> bool {
    state := init_test_state(name, verbose);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;
    push_context ctx {
        print("Running test: %\n", name);
        test_proc();
        print_test_summary(state);
    }

    return all_tests_passed(state);
}
