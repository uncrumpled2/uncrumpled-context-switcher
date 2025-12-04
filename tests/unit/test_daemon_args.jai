// Unit tests for daemon command-line argument parsing
//
// Tests the parse_arguments function and related configuration logic.

// Include daemon types and functions (config module only, not main)
#load "../../src/daemon/config.jai";

test_default_config :: () -> bool {
    state := init_test_state("test_default_config", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config := init_default_config();

        assert_false(config.run_as_daemon, "default should not run as daemon");
        assert_false(config.stay_in_foreground, "default should not have foreground flag");
        assert_false(config.show_help, "default should not show help");
        assert_false(config.show_version, "default should not show version");
        assert_false(config.verbose, "default should not be verbose");
        assert_false(config.has_error, "default should not have errors");

        assert_string_equal(config.socket_path, DEFAULT_SOCKET_PATH, "default socket path");
        assert_string_equal(config.pid_file, DEFAULT_PID_FILE, "default pid file");
        assert_string_equal(config.config_path, DEFAULT_CONFIG_PATH, "default config path");
    }

    return all_tests_passed(state);
}

test_parse_help_flag :: () -> bool {
    state := init_test_state("test_parse_help_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --help
        args1 := string.["program", "--help"];
        config1 := parse_arguments(args1);
        assert_true(config1.show_help, "--help should set show_help");
        assert_false(config1.has_error, "--help should not produce error");

        // Test -h
        args2 := string.["program", "-h"];
        config2 := parse_arguments(args2);
        assert_true(config2.show_help, "-h should set show_help");
        assert_false(config2.has_error, "-h should not produce error");
    }

    return all_tests_passed(state);
}

test_parse_version_flag :: () -> bool {
    state := init_test_state("test_parse_version_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --version
        args1 := string.["program", "--version"];
        config1 := parse_arguments(args1);
        assert_true(config1.show_version, "--version should set show_version");
        assert_false(config1.has_error, "--version should not produce error");

        // Test -v
        args2 := string.["program", "-v"];
        config2 := parse_arguments(args2);
        assert_true(config2.show_version, "-v should set show_version");
        assert_false(config2.has_error, "-v should not produce error");
    }

    return all_tests_passed(state);
}

test_parse_daemon_flag :: () -> bool {
    state := init_test_state("test_parse_daemon_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --daemon
        args1 := string.["program", "--daemon"];
        config1 := parse_arguments(args1);
        assert_true(config1.run_as_daemon, "--daemon should set run_as_daemon");
        assert_false(config1.has_error, "--daemon should not produce error");

        // Test -d
        args2 := string.["program", "-d"];
        config2 := parse_arguments(args2);
        assert_true(config2.run_as_daemon, "-d should set run_as_daemon");
        assert_false(config2.has_error, "-d should not produce error");
    }

    return all_tests_passed(state);
}

test_parse_foreground_flag :: () -> bool {
    state := init_test_state("test_parse_foreground_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --foreground
        args1 := string.["program", "--foreground"];
        config1 := parse_arguments(args1);
        assert_true(config1.stay_in_foreground, "--foreground should set stay_in_foreground");
        assert_false(config1.has_error, "--foreground should not produce error");

        // Test -f
        args2 := string.["program", "-f"];
        config2 := parse_arguments(args2);
        assert_true(config2.stay_in_foreground, "-f should set stay_in_foreground");
        assert_false(config2.has_error, "-f should not produce error");
    }

    return all_tests_passed(state);
}

test_parse_verbose_flag :: () -> bool {
    state := init_test_state("test_parse_verbose_flag", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --verbose
        args1 := string.["program", "--verbose"];
        config1 := parse_arguments(args1);
        assert_true(config1.verbose, "--verbose should set verbose");
        assert_false(config1.has_error, "--verbose should not produce error");

        // Test -V
        args2 := string.["program", "-V"];
        config2 := parse_arguments(args2);
        assert_true(config2.verbose, "-V should set verbose");
        assert_false(config2.has_error, "-V should not produce error");
    }

    return all_tests_passed(state);
}

test_parse_config_option :: () -> bool {
    state := init_test_state("test_parse_config_option", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --config with value
        args1 := string.["program", "--config", "/etc/uncrumpled.toml"];
        config1 := parse_arguments(args1);
        assert_string_equal(config1.config_path, "/etc/uncrumpled.toml", "--config should set config_path");
        assert_false(config1.has_error, "--config with value should not produce error");

        // Test --config without value (error)
        args2 := string.["program", "--config"];
        config2 := parse_arguments(args2);
        assert_true(config2.has_error, "--config without value should produce error");
    }

    return all_tests_passed(state);
}

test_parse_socket_path_option :: () -> bool {
    state := init_test_state("test_parse_socket_path_option", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --socket-path with value
        args1 := string.["program", "--socket-path", "/var/run/test.sock"];
        config1 := parse_arguments(args1);
        assert_string_equal(config1.socket_path, "/var/run/test.sock", "--socket-path should set socket_path");
        assert_false(config1.has_error, "--socket-path with value should not produce error");

        // Test --socket-path without value (error)
        args2 := string.["program", "--socket-path"];
        config2 := parse_arguments(args2);
        assert_true(config2.has_error, "--socket-path without value should produce error");
    }

    return all_tests_passed(state);
}

test_parse_pid_file_option :: () -> bool {
    state := init_test_state("test_parse_pid_file_option", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test --pid-file with value
        args1 := string.["program", "--pid-file", "/var/run/test.pid"];
        config1 := parse_arguments(args1);
        assert_string_equal(config1.pid_file, "/var/run/test.pid", "--pid-file should set pid_file");
        assert_false(config1.has_error, "--pid-file with value should not produce error");

        // Test --pid-file without value (error)
        args2 := string.["program", "--pid-file"];
        config2 := parse_arguments(args2);
        assert_true(config2.has_error, "--pid-file without value should produce error");
    }

    return all_tests_passed(state);
}

test_parse_unknown_option :: () -> bool {
    state := init_test_state("test_parse_unknown_option", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test unknown option
        args := string.["program", "--unknown-option"];
        config := parse_arguments(args);
        assert_true(config.has_error, "unknown option should produce error");
        assert_string_contains(config.error_message, "--unknown-option", "error should mention the option");
    }

    return all_tests_passed(state);
}

test_parse_multiple_flags :: () -> bool {
    state := init_test_state("test_parse_multiple_flags", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test multiple flags together
        args := string.["program", "-d", "-V", "--config", "/etc/custom.toml", "--socket-path", "/tmp/custom.sock"];
        config := parse_arguments(args);

        assert_false(config.has_error, "valid flags combination should not produce error");
        assert_true(config.run_as_daemon, "should be daemon mode");
        assert_true(config.verbose, "should be verbose");
        assert_string_equal(config.config_path, "/etc/custom.toml", "config path should be set");
        assert_string_equal(config.socket_path, "/tmp/custom.sock", "socket path should be set");
    }

    return all_tests_passed(state);
}

test_parse_empty_args :: () -> bool {
    state := init_test_state("test_parse_empty_args", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test with just program name (no arguments)
        args := string.["program"];
        config := parse_arguments(args);

        assert_false(config.has_error, "no arguments should not produce error");
        assert_false(config.run_as_daemon, "should not run as daemon by default");
        assert_false(config.show_help, "should not show help by default");
        assert_false(config.show_version, "should not show version by default");
    }

    return all_tests_passed(state);
}

// Register all daemon argument parsing tests
register_daemon_args_tests :: () {
    register_test("daemon/args/default_config", test_default_config);
    register_test("daemon/args/help_flag", test_parse_help_flag);
    register_test("daemon/args/version_flag", test_parse_version_flag);
    register_test("daemon/args/daemon_flag", test_parse_daemon_flag);
    register_test("daemon/args/foreground_flag", test_parse_foreground_flag);
    register_test("daemon/args/verbose_flag", test_parse_verbose_flag);
    register_test("daemon/args/config_option", test_parse_config_option);
    register_test("daemon/args/socket_path_option", test_parse_socket_path_option);
    register_test("daemon/args/pid_file_option", test_parse_pid_file_option);
    register_test("daemon/args/unknown_option", test_parse_unknown_option);
    register_test("daemon/args/multiple_flags", test_parse_multiple_flags);
    register_test("daemon/args/empty_args", test_parse_empty_args);
}
