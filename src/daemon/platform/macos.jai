// macOS Platform Specifics
//
// This module provides macOS-specific functionality:
// - Application Support and Library directory paths
// - launchd integration
// - Runtime directory management

#import "Basic";
#import "String";
#import "POSIX";

// macOS uses different standard paths than Linux
// - Config: ~/Library/Application Support/uncrumpled-context-switcher/config.toml
// - Data: ~/Library/Application Support/uncrumpled-context-switcher/
// - Cache: ~/Library/Caches/uncrumpled-context-switcher/
// - Logs: ~/Library/Logs/uncrumpled-context-switcher/
// - Runtime: /tmp or ~/Library/Caches/uncrumpled-context-switcher/

// Get the Application Support directory path
get_application_support_dir :: () -> string {
    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/Library/Application Support", home);
    }
    return copy_string("~/Library/Application Support");
}

// Get the Library/Caches directory path
get_caches_dir :: () -> string {
    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/Library/Caches", home);
    }
    return copy_string("~/Library/Caches");
}

// Get the Library/Logs directory path
get_logs_dir :: () -> string {
    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/Library/Logs", home);
    }
    return copy_string("~/Library/Logs");
}

// Get the Library/LaunchAgents directory path
get_launch_agents_dir :: () -> string {
    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/Library/LaunchAgents", home);
    }
    return copy_string("~/Library/LaunchAgents");
}

// Get the Library/Preferences directory path
get_preferences_dir :: () -> string {
    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/Library/Preferences", home);
    }
    return copy_string("~/Library/Preferences");
}

// Get the uncrumpled config directory path
get_uncrumpled_config_dir :: () -> string {
    app_support := get_application_support_dir();
    // Note: app_support is from tprint so we don't free it
    return tprint("%/uncrumpled-context-switcher", app_support);
}

// Get the uncrumpled config file path
get_uncrumpled_config_path :: () -> string {
    config_dir := get_uncrumpled_config_dir();
    // Note: config_dir is from tprint so we don't free it
    return tprint("%/config.toml", config_dir);
}

// Get the uncrumpled data directory path (same as config on macOS)
get_uncrumpled_data_dir :: () -> string {
    return get_uncrumpled_config_dir();
}

// Get the uncrumpled state directory path (for state files)
get_uncrumpled_state_dir :: () -> string {
    return get_uncrumpled_config_dir();
}

// Get the uncrumpled cache directory path
get_uncrumpled_cache_dir :: () -> string {
    caches := get_caches_dir();
    // Note: caches is from tprint so we don't free it
    return tprint("%/uncrumpled-context-switcher", caches);
}

// Get the uncrumpled logs directory path
get_uncrumpled_logs_dir :: () -> string {
    logs := get_logs_dir();
    // Note: logs is from tprint so we don't free it
    return tprint("%/uncrumpled-context-switcher", logs);
}

// Get the preferred socket path
// macOS doesn't have XDG_RUNTIME_DIR, use /tmp or cache dir
get_uncrumpled_socket_path :: () -> string {
    // Check for custom TMPDIR (common on macOS)
    tmpdir := get_env("TMPDIR");
    if tmpdir.count > 0 {
        return tprint("%/uncrumpled-context-switcher.sock", tmpdir);
    }

    // Fallback to /tmp
    return copy_string("/tmp/uncrumpled-context-switcher.sock");
}

// Get the PID file path
get_uncrumpled_pid_path :: () -> string {
    tmpdir := get_env("TMPDIR");
    if tmpdir.count > 0 {
        return tprint("%/uncrumpled-context-switcher.pid", tmpdir);
    }

    return copy_string("/tmp/uncrumpled-context-switcher.pid");
}

// Helper to get environment variable
get_env :: (name: string) -> string {
    name_cstr := temp_c_string(name);
    value := getenv(name_cstr);
    if value == null {
        return "";
    }
    return to_string(value);
}

// launchd support
// launchd uses environment variables for socket activation similar to systemd
// but with different variable names

// Check if running under launchd socket activation
// launchd passes sockets via LAUNCH_DAEMON_SOCKET_NAME
is_launchd_socket_activated :: () -> bool {
    // Check for launchd-specific environment
    socket_name := get_env("LAUNCH_DAEMON_SOCKET_NAME");
    return socket_name.count > 0;
}

// Get the socket FD passed by launchd
// launchd uses a different mechanism - sockets are passed directly
// This function uses the launch_activate_socket() API via helper
// Returns -1 if not socket-activated or on error
get_launchd_socket_fd :: () -> s32 {
    // launchd socket activation requires linking against launch framework
    // For now, return -1 to indicate we fall back to creating our own socket
    // Full implementation would use launch_activate_socket()
    return -1;
}

// Check if we're running as a launchd daemon (LaunchDaemon or LaunchAgent)
is_running_under_launchd :: () -> bool {
    // Check for LAUNCHD_SOCKET or other launchd indicators
    launchd_socket := get_env("LAUNCHD_SOCKET");
    if launchd_socket.count > 0 {
        return true;
    }

    // Check if our parent is launchd (PID 1)
    ppid := getppid();
    return ppid == 1;
}

// Get the launchd service label for this daemon
get_launchd_service_label :: () -> string {
    return copy_string("com.uncrumpled-context-switcher.daemon");
}

// Get the launchd plist path for the current user
get_launchd_plist_path :: () -> string {
    agents_dir := get_launch_agents_dir();
    defer free(agents_dir);
    return tprint("%/com.uncrumpled-context-switcher.daemon.plist", agents_dir);
}

// Ensure a directory exists with proper permissions
// 493 = 0o755 (rwxr-xr-x, more permissive than Linux for macOS conventions)
ensure_directory :: (path: string, mode: mode_t = 493) -> bool {
    path_cstr := temp_c_string(path);

    // Try to create the directory
    result := mkdir(path_cstr, mode);
    if result == 0 {
        return true;  // Created successfully
    }

    // Check if it already exists
    err := errno();
    if err == EEXIST {
        // Directory already exists - verify it's a directory
        stat_buf: stat_t;
        if stat(path_cstr, *stat_buf) == 0 {
            return S_ISDIR(stat_buf.st_mode);
        }
    }

    return false;
}

// Create parent directories for a path (like mkdir -p)
ensure_parent_directories :: (path: string) -> bool {
    // Find the last path separator
    last_sep := -1;
    for i: 0..path.count-1 {
        if path[i] == #char "/" {
            last_sep = i;
        }
    }

    if last_sep <= 0 {
        return true;  // No parent to create or root
    }

    parent: string;
    parent.data = path.data;
    parent.count = last_sep;

    // Recursively ensure parent exists
    if !ensure_parent_directories(parent) {
        return false;
    }

    return ensure_directory(parent);
}

// Load/unload the launchd service using launchctl
// Note: These functions spawn launchctl as a subprocess

// Load the launchd plist (equivalent to launchctl load)
load_launchd_service :: () -> bool {
    plist_path := get_launchd_plist_path();
    defer free(plist_path);

    // Build launchctl command
    // launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.uncrumpled.daemon.plist
    // Or for older macOS: launchctl load ~/Library/LaunchAgents/com.uncrumpled.daemon.plist

    // For simplicity, use the legacy load command which still works
    cmd := tprint("launchctl load -w \"%\"", plist_path);

    result := macos_system(temp_c_string(cmd));
    return result == 0;
}

// Unload the launchd plist (equivalent to launchctl unload)
unload_launchd_service :: () -> bool {
    plist_path := get_launchd_plist_path();
    defer free(plist_path);

    cmd := tprint("launchctl unload \"%\"", plist_path);

    result := macos_system(temp_c_string(cmd));
    return result == 0;
}

// Check if the launchd service is loaded
is_launchd_service_loaded :: () -> bool {
    label := get_launchd_service_label();
    defer free(label);

    cmd := tprint("launchctl list \"%\" >/dev/null 2>&1", label);

    result := macos_system(temp_c_string(cmd));
    return result == 0;
}

// External C function
macos_system :: (command: *u8) -> s32 #foreign libc "system";

#scope_file
libc :: #system_library "libc";
