// Unit tests for platform-specific modules
//
// Tests the platform abstraction layer (Linux/macOS path helpers, etc.)
// On Linux, tests Linux-specific functionality.
// On macOS, tests macOS-specific functionality.

#import "Basic";
#import "String";
#import "POSIX";

// Load platform-specific code
#load "../../src/daemon/platform/module.jai";

// Note: These tests run on the current platform only

#if OS == .LINUX {

test_get_env_helper :: () -> bool {
    state := init_test_state("test_get_env_helper", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // HOME should always be set on Linux
        home := get_env("HOME");
        assert_true(home.count > 0, "HOME should be set");
        assert_true(home[0] == #char "/", "HOME should start with /");

        // Non-existent var should return empty
        nonexistent := get_env("UNCRUMPLED_TEST_NONEXISTENT_VAR_12345");
        assert_string_equal(nonexistent, "", "non-existent var should return empty");
    }

    return all_tests_passed(state);
}

test_xdg_config_home :: () -> bool {
    state := init_test_state("test_xdg_config_home", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Note: These functions use tprint for default paths, so don't free
        config_home := get_xdg_config_home();

        assert_true(config_home.count > 0, "config home should not be empty");
        // Should end with .config if HOME-based
        if !contains(config_home, "XDG") {
            assert_true(ends_with(config_home, ".config"), "should end with .config");
        }
    }

    return all_tests_passed(state);
}

test_xdg_data_home :: () -> bool {
    state := init_test_state("test_xdg_data_home", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        data_home := get_xdg_data_home();

        assert_true(data_home.count > 0, "data home should not be empty");
    }

    return all_tests_passed(state);
}

test_xdg_cache_home :: () -> bool {
    state := init_test_state("test_xdg_cache_home", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        cache_home := get_xdg_cache_home();

        assert_true(cache_home.count > 0, "cache home should not be empty");
    }

    return all_tests_passed(state);
}

test_uncrumpled_config_dir :: () -> bool {
    state := init_test_state("test_uncrumpled_config_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config_dir := get_uncrumpled_config_dir();

        assert_true(config_dir.count > 0, "config dir should not be empty");
        assert_true(ends_with(config_dir, "/uncrumpled"), "should end with /uncrumpled");
    }

    return all_tests_passed(state);
}

test_uncrumpled_socket_path :: () -> bool {
    state := init_test_state("test_uncrumpled_socket_path", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := get_uncrumpled_socket_path();

        assert_true(socket_path.count > 0, "socket path should not be empty");
        assert_true(ends_with(socket_path, ".sock"), "should end with .sock");
    }

    return all_tests_passed(state);
}

test_ensure_directory :: () -> bool {
    state := init_test_state("test_ensure_directory", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test creating a temp directory
        test_dir := "/tmp/uncrumpled_test_dir_platform";

        // Clean up first if exists
        rmdir(temp_c_string(test_dir));

        // Create it
        result := ensure_directory(test_dir);
        assert_true(result, "should create directory successfully");

        // Creating again should succeed (already exists)
        result2 := ensure_directory(test_dir);
        assert_true(result2, "should succeed when directory exists");

        // Clean up
        rmdir(temp_c_string(test_dir));
    }

    return all_tests_passed(state);
}

test_systemd_not_activated :: () -> bool {
    state := init_test_state("test_systemd_not_activated", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // In test environment, we're not socket-activated
        fd_count := is_systemd_socket_activated();
        assert_equal(fd_count, 0, "should not be socket activated in tests");

        fd := get_systemd_socket_fd();
        assert_equal(fd, cast(s32) -1, "should return -1 when not socket activated");
    }

    return all_tests_passed(state);
}

test_sd_listen_fds_start :: () -> bool {
    state := init_test_state("test_sd_listen_fds_start", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Verify the constant is correct
        assert_equal(SD_LISTEN_FDS_START, 3, "SD_LISTEN_FDS_START should be 3");
    }

    return all_tests_passed(state);
}

register_platform_tests :: () {
    register_test("platform_get_env_helper", test_get_env_helper);
    register_test("platform_xdg_config_home", test_xdg_config_home);
    register_test("platform_xdg_data_home", test_xdg_data_home);
    register_test("platform_xdg_cache_home", test_xdg_cache_home);
    register_test("platform_uncrumpled_config_dir", test_uncrumpled_config_dir);
    register_test("platform_uncrumpled_socket_path", test_uncrumpled_socket_path);
    register_test("platform_ensure_directory", test_ensure_directory);
    register_test("platform_systemd_not_activated", test_systemd_not_activated);
    register_test("platform_sd_listen_fds_start", test_sd_listen_fds_start);
}

} // end #if OS == .LINUX

#if OS == .MACOS {

test_get_env_helper :: () -> bool {
    state := init_test_state("test_get_env_helper", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // HOME should always be set on macOS
        home := get_env("HOME");
        assert_true(home.count > 0, "HOME should be set");
        assert_true(begins_with(home, "/Users") || begins_with(home, "/var"), "HOME should be /Users or /var path");

        // Non-existent var should return empty
        nonexistent := get_env("UNCRUMPLED_TEST_NONEXISTENT_VAR_12345");
        assert_string_equal(nonexistent, "", "non-existent var should return empty");
    }

    return all_tests_passed(state);
}

test_application_support_dir :: () -> bool {
    state := init_test_state("test_application_support_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Note: These functions use tprint for default paths, so don't free
        app_support := get_application_support_dir();

        assert_true(app_support.count > 0, "app support should not be empty");
        assert_true(ends_with(app_support, "Library/Application Support"), "should end with Library/Application Support");
    }

    return all_tests_passed(state);
}

test_caches_dir :: () -> bool {
    state := init_test_state("test_caches_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        caches := get_caches_dir();

        assert_true(caches.count > 0, "caches should not be empty");
        assert_true(ends_with(caches, "Library/Caches"), "should end with Library/Caches");
    }

    return all_tests_passed(state);
}

test_logs_dir :: () -> bool {
    state := init_test_state("test_logs_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        logs := get_logs_dir();

        assert_true(logs.count > 0, "logs should not be empty");
        assert_true(ends_with(logs, "Library/Logs"), "should end with Library/Logs");
    }

    return all_tests_passed(state);
}

test_uncrumpled_config_dir :: () -> bool {
    state := init_test_state("test_uncrumpled_config_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        config_dir := get_uncrumpled_config_dir();

        assert_true(config_dir.count > 0, "config dir should not be empty");
        assert_true(ends_with(config_dir, "/uncrumpled"), "should end with /uncrumpled");
        assert_true(contains(config_dir, "Application Support"), "should contain Application Support");
    }

    return all_tests_passed(state);
}

test_uncrumpled_socket_path :: () -> bool {
    state := init_test_state("test_uncrumpled_socket_path", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        socket_path := get_uncrumpled_socket_path();

        assert_true(socket_path.count > 0, "socket path should not be empty");
        assert_true(ends_with(socket_path, ".sock"), "should end with .sock");
    }

    return all_tests_passed(state);
}

test_launchd_service_label :: () -> bool {
    state := init_test_state("test_launchd_service_label", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        label := get_launchd_service_label();
        defer free(label);

        assert_string_equal(label, "com.uncrumpled.daemon", "label should match");
    }

    return all_tests_passed(state);
}

test_launchd_not_activated :: () -> bool {
    state := init_test_state("test_launchd_not_activated", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // In test environment, we're not socket-activated
        activated := is_launchd_socket_activated();
        assert_false(activated, "should not be socket activated in tests");

        fd := get_launchd_socket_fd();
        assert_equal(fd, cast(s32) -1, "should return -1 when not socket activated");
    }

    return all_tests_passed(state);
}

test_ensure_directory :: () -> bool {
    state := init_test_state("test_ensure_directory", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // Test creating a temp directory
        test_dir := "/tmp/uncrumpled_test_dir_platform";

        // Clean up first if exists
        rmdir(temp_c_string(test_dir));

        // Create it
        result := ensure_directory(test_dir);
        assert_true(result, "should create directory successfully");

        // Creating again should succeed (already exists)
        result2 := ensure_directory(test_dir);
        assert_true(result2, "should succeed when directory exists");

        // Clean up
        rmdir(temp_c_string(test_dir));
    }

    return all_tests_passed(state);
}

register_platform_tests :: () {
    register_test("platform_get_env_helper", test_get_env_helper);
    register_test("platform_application_support_dir", test_application_support_dir);
    register_test("platform_caches_dir", test_caches_dir);
    register_test("platform_logs_dir", test_logs_dir);
    register_test("platform_uncrumpled_config_dir", test_uncrumpled_config_dir);
    register_test("platform_uncrumpled_socket_path", test_uncrumpled_socket_path);
    register_test("platform_launchd_service_label", test_launchd_service_label);
    register_test("platform_launchd_not_activated", test_launchd_not_activated);
    register_test("platform_ensure_directory", test_ensure_directory);
}

} // end #if OS == .MACOS
