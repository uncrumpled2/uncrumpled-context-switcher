// Linux Platform Specifics
//
// This module provides Linux-specific functionality:
// - XDG Base Directory paths
// - systemd socket activation detection
// - Runtime directory management

#import "Basic";
#import "String";
#import "POSIX";

// Socket constants not in POSIX module
LINUX_AF_UNIX :: 1;
LINUX_SOCK_DGRAM :: 2;

// XDG Base Directory Specification paths
// https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

// Get XDG_CONFIG_HOME (~/.config by default)
get_xdg_config_home :: () -> string {
    xdg_config := get_env("XDG_CONFIG_HOME");
    if xdg_config.count > 0 {
        return copy_string(xdg_config);
    }

    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/.config", home);
    }

    return copy_string("~/.config");
}

// Get XDG_DATA_HOME (~/.local/share by default)
get_xdg_data_home :: () -> string {
    xdg_data := get_env("XDG_DATA_HOME");
    if xdg_data.count > 0 {
        return copy_string(xdg_data);
    }

    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/.local/share", home);
    }

    return copy_string("~/.local/share");
}

// Get XDG_STATE_HOME (~/.local/state by default)
get_xdg_state_home :: () -> string {
    xdg_state := get_env("XDG_STATE_HOME");
    if xdg_state.count > 0 {
        return copy_string(xdg_state);
    }

    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/.local/state", home);
    }

    return copy_string("~/.local/state");
}

// Get XDG_CACHE_HOME (~/.cache by default)
get_xdg_cache_home :: () -> string {
    xdg_cache := get_env("XDG_CACHE_HOME");
    if xdg_cache.count > 0 {
        return copy_string(xdg_cache);
    }

    home := get_env("HOME");
    if home.count > 0 {
        return tprint("%/.cache", home);
    }

    return copy_string("~/.cache");
}

// Get XDG_RUNTIME_DIR (typically /run/user/<uid>)
// Returns empty string if not set (caller should fallback to /tmp)
get_xdg_runtime_dir :: () -> string {
    xdg_runtime := get_env("XDG_RUNTIME_DIR");
    if xdg_runtime.count > 0 {
        return copy_string(xdg_runtime);
    }
    return "";  // Not set - caller should fallback
}

// Get the uncrumpled config directory path
get_uncrumpled_config_dir :: () -> string {
    config_home := get_xdg_config_home();
    defer free(config_home);
    return tprint("%/uncrumpled", config_home);
}

// Get the uncrumpled config file path
get_uncrumpled_config_path :: () -> string {
    config_dir := get_uncrumpled_config_dir();
    defer free(config_dir);
    return tprint("%/config.toml", config_dir);
}

// Get the uncrumpled data directory path
get_uncrumpled_data_dir :: () -> string {
    data_home := get_xdg_data_home();
    defer free(data_home);
    return tprint("%/uncrumpled", data_home);
}

// Get the uncrumpled state directory path (for logs, state files)
get_uncrumpled_state_dir :: () -> string {
    state_home := get_xdg_state_home();
    defer free(state_home);
    return tprint("%/uncrumpled", state_home);
}

// Get the uncrumpled cache directory path
get_uncrumpled_cache_dir :: () -> string {
    cache_home := get_xdg_cache_home();
    defer free(cache_home);
    return tprint("%/uncrumpled", cache_home);
}

// Get the preferred socket path (XDG_RUNTIME_DIR or /tmp fallback)
get_uncrumpled_socket_path :: () -> string {
    runtime_dir := get_xdg_runtime_dir();
    if runtime_dir.count > 0 {
        defer free(runtime_dir);
        return tprint("%/uncrumpled/uncrumpled.sock", runtime_dir);
    }

    // Fallback to /tmp
    return copy_string("/tmp/uncrumpled.sock");
}

// Get the PID file path
get_uncrumpled_pid_path :: () -> string {
    runtime_dir := get_xdg_runtime_dir();
    if runtime_dir.count > 0 {
        defer free(runtime_dir);
        return tprint("%/uncrumpled/uncrumpled.pid", runtime_dir);
    }

    // Fallback to /tmp
    return copy_string("/tmp/uncrumpled.pid");
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

// Check if running under systemd socket activation
// Returns the number of passed file descriptors (0 if not socket-activated)
is_systemd_socket_activated :: () -> int {
    // Check LISTEN_FDS environment variable
    listen_fds := get_env("LISTEN_FDS");
    if listen_fds.count == 0 {
        return 0;
    }

    // Parse the count
    count, ok := string_to_int(listen_fds);
    if !ok || count <= 0 {
        return 0;
    }

    // Verify LISTEN_PID matches our PID
    listen_pid := get_env("LISTEN_PID");
    if listen_pid.count == 0 {
        return 0;
    }

    pid, pid_ok := string_to_int(listen_pid);
    if !pid_ok {
        return 0;
    }

    our_pid := getpid();
    if pid != our_pid {
        return 0;
    }

    return count;
}

// Get the socket FD passed by systemd (if socket-activated)
// Returns -1 if not socket-activated
// File descriptor 3 is the first passed FD (SD_LISTEN_FDS_START)
SD_LISTEN_FDS_START :: 3;

get_systemd_socket_fd :: () -> s32 {
    fd_count := is_systemd_socket_activated();
    if fd_count > 0 {
        return SD_LISTEN_FDS_START;  // First passed FD
    }
    return -1;
}

// Clear systemd socket activation environment variables
// (recommended after accepting them to prevent child processes from reusing)
clear_systemd_listen_vars :: () {
    unsetenv(temp_c_string("LISTEN_FDS"));
    unsetenv(temp_c_string("LISTEN_PID"));
    unsetenv(temp_c_string("LISTEN_FDNAMES"));
}

// Notify systemd that the daemon is ready (for Type=notify services)
// Returns true if notification was sent successfully
notify_systemd_ready :: () -> bool {
    return send_systemd_notification("READY=1");
}

// Notify systemd of reload complete
notify_systemd_reloading :: () -> bool {
    return send_systemd_notification("RELOADING=1");
}

// Notify systemd of stopping
notify_systemd_stopping :: () -> bool {
    return send_systemd_notification("STOPPING=1");
}

// Notify systemd with custom status
notify_systemd_status :: (status: string) -> bool {
    return send_systemd_notification(tprint("STATUS=%", status));
}

// Generic systemd notification (legacy name for compatibility)
notify_systemd :: (message: string) -> bool {
    return send_systemd_notification(message);
}

// Internal: Send a notification to systemd's notify socket
send_systemd_notification :: (message: string) -> bool {
    notify_socket := get_env("NOTIFY_SOCKET");
    if notify_socket.count == 0 {
        return false;
    }

    sock := linux_socket(LINUX_AF_UNIX, LINUX_SOCK_DGRAM, 0);
    if sock < 0 {
        return false;
    }

    addr: Linux_sockaddr_un;
    addr.sun_family = cast(u16) LINUX_AF_UNIX;

    socket_path := notify_socket;
    if socket_path.count > 0 && socket_path[0] == #char "@" {
        // Abstract socket - replace @ with null byte
        socket_path.data += 1;
        socket_path.count -= 1;
        addr.sun_path[0] = 0;
        path_len := min(socket_path.count, cast(s64) addr.sun_path.count - 2);
        memcpy(addr.sun_path.data + 1, socket_path.data, path_len);
    } else {
        // Regular path socket
        path_len := min(socket_path.count, cast(s64) addr.sun_path.count - 1);
        memcpy(addr.sun_path.data, socket_path.data, path_len);
        addr.sun_path[path_len] = 0;
    }

    result := linux_sendto(sock, message.data, cast(size_t) message.count, 0,
                           *addr, size_of(Linux_sockaddr_un));

    linux_close(sock);
    return result >= 0;
}

// Ensure a directory exists with proper permissions
// 448 = 0o700 (rwx for owner only)
ensure_directory :: (path: string, mode: mode_t = 448) -> bool {
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

// Low-level socket functions for systemd notification
linux_socket :: (domain: s32, type: s32, protocol: s32) -> s32 #foreign libc "socket";
linux_close :: (fd: s32) -> s32 #foreign libc "close";
linux_sendto :: (sockfd: s32, buf: *void, len: size_t, flags: s32,
                 dest_addr: *void, addrlen: u32) -> ssize_t #foreign libc "sendto";

// sockaddr_un structure for Unix domain sockets
Linux_sockaddr_un :: struct {
    sun_family: u16;
    sun_path: [108] u8;
}

#scope_file
libc :: #system_library "libc";
