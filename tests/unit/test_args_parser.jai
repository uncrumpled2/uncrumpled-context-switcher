// Unit tests for Context Input Argument Parser
//
// Tests the POSIX-style argument parser for context input strings like:
//   work --mode=programming -v --debug
//   gaming --profile=competitive
//   personal

#load "../../src/daemon/args_parser.jai";

// ============================================================================
// Basic Parsing Tests
// ============================================================================

test_parse_name_only :: () -> bool {
    state := init_test_state("test_parse_name_only", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_string_equal(parsed.name, "work", "context name should be 'work'");
        assert_equal(parsed.args.count, 0, "should have no arguments");
    }

    return all_tests_passed(state);
}

test_parse_empty_input :: () -> bool {
    state := init_test_state("test_parse_empty_input", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("");
        defer free_parsed_input(*parsed);

        assert_false(parsed.success, "parsing empty input should fail");
        assert_true(parsed.error.count > 0, "should have error message");
    }

    return all_tests_passed(state);
}

test_parse_whitespace_only :: () -> bool {
    state := init_test_state("test_parse_whitespace_only", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("   \t\n  ");
        defer free_parsed_input(*parsed);

        assert_false(parsed.success, "parsing whitespace-only input should fail");
    }

    return all_tests_passed(state);
}

test_parse_no_name_error :: () -> bool {
    state := init_test_state("test_parse_no_name_error", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Starting with an option should be an error
        parsed := parse_context_input("--mode=programming");
        defer free_parsed_input(*parsed);

        assert_false(parsed.success, "starting with option should fail");
        assert_string_contains(parsed.error, "name required", "error should mention name required");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Long Option Tests
// ============================================================================

test_parse_long_option_equals :: () -> bool {
    state := init_test_state("test_parse_long_option_equals", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --mode=programming");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_string_equal(parsed.name, "work", "context name should be 'work'");

        value, found := get_arg(*parsed, "mode");
        assert_true(found, "should have 'mode' argument");
        assert_string_equal(value, "programming", "mode value should be 'programming'");
        assert_false(is_flag(*parsed, "mode"), "mode should not be a flag");
    }

    return all_tests_passed(state);
}

test_parse_long_option_space :: () -> bool {
    state := init_test_state("test_parse_long_option_space", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --mode programming");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "mode");
        assert_true(found, "should have 'mode' argument");
        assert_string_equal(value, "programming", "mode value should be 'programming'");
    }

    return all_tests_passed(state);
}

test_parse_long_flag :: () -> bool {
    state := init_test_state("test_parse_long_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --verbose --debug");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_true(has_arg(*parsed, "verbose"), "should have 'verbose' flag");
        assert_true(has_arg(*parsed, "debug"), "should have 'debug' flag");
        assert_true(is_flag(*parsed, "verbose"), "verbose should be a flag");
        assert_true(is_flag(*parsed, "debug"), "debug should be a flag");
    }

    return all_tests_passed(state);
}

test_parse_long_option_empty_value :: () -> bool {
    state := init_test_state("test_parse_long_option_empty_value", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --mode=");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "mode");
        assert_true(found, "should have 'mode' argument");
        assert_string_equal(value, "", "mode value should be empty");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Short Option Tests
// ============================================================================

test_parse_short_flag :: () -> bool {
    state := init_test_state("test_parse_short_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work -v");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_true(has_arg(*parsed, "v"), "should have 'v' flag");
        assert_true(is_flag(*parsed, "v"), "v should be a flag");
    }

    return all_tests_passed(state);
}

test_parse_combined_short_flags :: () -> bool {
    state := init_test_state("test_parse_combined_short_flags", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work -abc");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_true(has_arg(*parsed, "a"), "should have 'a' flag");
        assert_true(has_arg(*parsed, "b"), "should have 'b' flag");
        assert_true(has_arg(*parsed, "c"), "should have 'c' flag");
        assert_true(is_flag(*parsed, "a"), "a should be a flag");
        assert_true(is_flag(*parsed, "b"), "b should be a flag");
        assert_true(is_flag(*parsed, "c"), "c should be a flag");
    }

    return all_tests_passed(state);
}

test_parse_short_option_with_value :: () -> bool {
    state := init_test_state("test_parse_short_option_with_value", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work -m programming");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "m");
        assert_true(found, "should have 'm' argument");
        assert_string_equal(value, "programming", "m value should be 'programming'");
        assert_false(is_flag(*parsed, "m"), "m should not be a flag");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Quoted Value Tests
// ============================================================================

test_parse_quoted_value_double :: () -> bool {
    state := init_test_state("test_parse_quoted_value_double", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --msg=\"hello world\"");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "msg");
        assert_true(found, "should have 'msg' argument");
        assert_string_equal(value, "hello world", "msg value should be 'hello world'");
    }

    return all_tests_passed(state);
}

test_parse_quoted_value_single :: () -> bool {
    state := init_test_state("test_parse_quoted_value_single", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --msg='hello world'");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "msg");
        assert_true(found, "should have 'msg' argument");
        assert_string_equal(value, "hello world", "msg value should be 'hello world'");
    }

    return all_tests_passed(state);
}

test_parse_standalone_quoted_value :: () -> bool {
    state := init_test_state("test_parse_standalone_quoted_value", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --msg \"hello world\"");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");

        value, found := get_arg(*parsed, "msg");
        assert_true(found, "should have 'msg' argument");
        assert_string_equal(value, "hello world", "msg value should be 'hello world'");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Mixed Arguments Tests
// ============================================================================

test_parse_mixed_arguments :: () -> bool {
    state := init_test_state("test_parse_mixed_arguments", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --mode=programming -v --debug");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_string_equal(parsed.name, "work", "context name should be 'work'");

        mode_val, mode_found := get_arg(*parsed, "mode");
        assert_true(mode_found, "should have 'mode' argument");
        assert_string_equal(mode_val, "programming", "mode value should be 'programming'");

        assert_true(has_arg(*parsed, "v"), "should have 'v' flag");
        assert_true(has_arg(*parsed, "debug"), "should have 'debug' flag");
    }

    return all_tests_passed(state);
}

test_parse_complex_input :: () -> bool {
    state := init_test_state("test_parse_complex_input", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("gaming --profile=competitive -abc --level 5 --name=\"Pro Gamer\"");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_string_equal(parsed.name, "gaming", "context name should be 'gaming'");

        profile_val, profile_found := get_arg(*parsed, "profile");
        assert_true(profile_found, "should have 'profile' argument");
        assert_string_equal(profile_val, "competitive", "profile value should be 'competitive'");

        assert_true(has_arg(*parsed, "a"), "should have 'a' flag");
        assert_true(has_arg(*parsed, "b"), "should have 'b' flag");
        assert_true(has_arg(*parsed, "c"), "should have 'c' flag");

        level_val, level_found := get_arg(*parsed, "level");
        assert_true(level_found, "should have 'level' argument");
        assert_string_equal(level_val, "5", "level value should be '5'");

        name_val, name_found := get_arg(*parsed, "name");
        assert_true(name_found, "should have 'name' argument");
        assert_string_equal(name_val, "Pro Gamer", "name value should be 'Pro Gamer'");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Edge Cases
// ============================================================================

test_parse_name_with_spaces :: () -> bool {
    state := init_test_state("test_parse_name_with_spaces", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("  work  --mode=test  ");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed with extra spaces");
        assert_string_equal(parsed.name, "work", "context name should be 'work'");
    }

    return all_tests_passed(state);
}

test_parse_dangling_option :: () -> bool {
    state := init_test_state("test_parse_dangling_option", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // --mode at end without value should be treated as flag
        parsed := parse_context_input("work --mode");
        defer free_parsed_input(*parsed);

        assert_true(parsed.success, "parsing should succeed");
        assert_true(has_arg(*parsed, "mode"), "should have 'mode' argument");
        assert_true(is_flag(*parsed, "mode"), "mode should be a flag when no value");
    }

    return all_tests_passed(state);
}

test_parse_double_dash_only :: () -> bool {
    state := init_test_state("test_parse_double_dash_only", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work --");
        defer free_parsed_input(*parsed);

        assert_false(parsed.success, "parsing '--' alone should fail");
    }

    return all_tests_passed(state);
}

test_parse_single_dash_only :: () -> bool {
    state := init_test_state("test_parse_single_dash_only", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        parsed := parse_context_input("work -");
        defer free_parsed_input(*parsed);

        assert_false(parsed.success, "parsing '-' alone should fail");
    }

    return all_tests_passed(state);
}

// ============================================================================
// Registration
// ============================================================================

register_args_parser_tests :: () {
    register_test("args_parser/name_only", test_parse_name_only);
    register_test("args_parser/empty_input", test_parse_empty_input);
    register_test("args_parser/whitespace_only", test_parse_whitespace_only);
    register_test("args_parser/no_name_error", test_parse_no_name_error);
    register_test("args_parser/long_option_equals", test_parse_long_option_equals);
    register_test("args_parser/long_option_space", test_parse_long_option_space);
    register_test("args_parser/long_flag", test_parse_long_flag);
    register_test("args_parser/long_option_empty_value", test_parse_long_option_empty_value);
    register_test("args_parser/short_flag", test_parse_short_flag);
    register_test("args_parser/combined_short_flags", test_parse_combined_short_flags);
    register_test("args_parser/short_option_with_value", test_parse_short_option_with_value);
    register_test("args_parser/quoted_value_double", test_parse_quoted_value_double);
    register_test("args_parser/quoted_value_single", test_parse_quoted_value_single);
    register_test("args_parser/standalone_quoted_value", test_parse_standalone_quoted_value);
    register_test("args_parser/mixed_arguments", test_parse_mixed_arguments);
    register_test("args_parser/complex_input", test_parse_complex_input);
    register_test("args_parser/name_with_spaces", test_parse_name_with_spaces);
    register_test("args_parser/dangling_option", test_parse_dangling_option);
    register_test("args_parser/double_dash_only", test_parse_double_dash_only);
    register_test("args_parser/single_dash_only", test_parse_single_dash_only);
}
