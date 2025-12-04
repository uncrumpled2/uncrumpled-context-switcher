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
        assert_true(ends_with(config_dir, "/uncrumpled-context-switcher"), "should end with /uncrumpled-context-switcher");
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
        assert_true(ends_with(config_dir, "/uncrumpled-context-switcher"), "should end with /uncrumpled-context-switcher");
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

        assert_string_equal(label, "com.uncrumpled-context-switcher.daemon", "label should match");
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

#if OS == .WINDOWS {

test_get_env_helper :: () -> bool {
    state := init_test_state("test_get_env_helper", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // USERPROFILE should always be set on Windows
        userprofile := get_env("USERPROFILE");
        assert_true(userprofile.count > 0, "USERPROFILE should be set");
        assert_true(contains(userprofile, "Users"), "USERPROFILE should contain Users");

        // Non-existent var should return empty
        nonexistent := get_env("UNCRUMPLED_TEST_NONEXISTENT_VAR_12345");
        assert_string_equal(nonexistent, "", "non-existent var should return empty");
    }

    return all_tests_passed(state);
}

test_appdata_dir :: () -> bool {
    state := init_test_state("test_appdata_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        appdata := get_appdata_dir();
        defer free(appdata);

        assert_true(appdata.count > 0, "APPDATA should not be empty");
        assert_true(contains(appdata, "AppData"), "should contain AppData");
        assert_true(contains(appdata, "Roaming"), "should contain Roaming");
    }

    return all_tests_passed(state);
}

test_local_appdata_dir :: () -> bool {
    state := init_test_state("test_local_appdata_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        local_appdata := get_local_appdata_dir();
        defer free(local_appdata);

        assert_true(local_appdata.count > 0, "LOCALAPPDATA should not be empty");
        assert_true(contains(local_appdata, "AppData"), "should contain AppData");
        assert_true(contains(local_appdata, "Local"), "should contain Local");
    }

    return all_tests_passed(state);
}

test_temp_dir :: () -> bool {
    state := init_test_state("test_temp_dir", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        temp := get_temp_dir();
        defer free(temp);

        assert_true(temp.count > 0, "TEMP should not be empty");
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
        // Note: config_dir is from tprint so we don't free it

        assert_true(config_dir.count > 0, "config dir should not be empty");
        assert_true(ends_with(config_dir, "\\uncrumpled-context-switcher"), "should end with \\uncrumpled-context-switcher");
        assert_true(contains(config_dir, "AppData"), "should contain AppData");
    }

    return all_tests_passed(state);
}

test_uncrumpled_pipe_path :: () -> bool {
    state := init_test_state("test_uncrumpled_pipe_path", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        pipe_path := get_uncrumpled_pipe_path();
        defer free(pipe_path);

        assert_true(pipe_path.count > 0, "pipe path should not be empty");
        assert_true(begins_with(pipe_path, "\\\\.\\pipe\\"), "should start with named pipe prefix");
        assert_true(contains(pipe_path, "uncrumpled"), "should contain uncrumpled");
    }

    return all_tests_passed(state);
}

test_uncrumpled_socket_path_alias :: () -> bool {
    state := init_test_state("test_uncrumpled_socket_path_alias", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        // On Windows, socket_path should return the named pipe path
        socket_path := get_uncrumpled_socket_path();
        defer free(socket_path);

        assert_true(socket_path.count > 0, "socket path should not be empty");
        assert_true(begins_with(socket_path, "\\\\.\\pipe\\"), "should be a named pipe path");
    }

    return all_tests_passed(state);
}

test_windows_service_name :: () -> bool {
    state := init_test_state("test_windows_service_name", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        service_name := get_windows_service_name();
        defer free(service_name);

        assert_string_equal(service_name, "UncrumpledContextSwitcherDaemon", "service name should match");
    }

    return all_tests_passed(state);
}

test_service_state_to_string :: () -> bool {
    state := init_test_state("test_service_state_to_string", verbose = false);
    defer cleanup_test_state(state);

    ctx := context;
    ctx.test_state = state;

    push_context ctx {
        assert_string_equal(service_state_to_string(.NOT_INSTALLED), "not_installed", "NOT_INSTALLED string");
        assert_string_equal(service_state_to_string(.STOPPED), "stopped", "STOPPED string");
        assert_string_equal(service_state_to_string(.RUNNING), "running", "RUNNING string");
        assert_string_equal(service_state_to_string(.UNKNOWN), "unknown", "UNKNOWN string");
    }

    return all_tests_passed(state);
}

register_platform_tests :: () {
    register_test("platform_get_env_helper", test_get_env_helper);
    register_test("platform_appdata_dir", test_appdata_dir);
    register_test("platform_local_appdata_dir", test_local_appdata_dir);
    register_test("platform_temp_dir", test_temp_dir);
    register_test("platform_uncrumpled_config_dir", test_uncrumpled_config_dir);
    register_test("platform_uncrumpled_pipe_path", test_uncrumpled_pipe_path);
    register_test("platform_uncrumpled_socket_path_alias", test_uncrumpled_socket_path_alias);
    register_test("platform_windows_service_name", test_windows_service_name);
    register_test("platform_service_state_to_string", test_service_state_to_string);
}

} // end #if OS == .WINDOWS
