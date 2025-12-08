// Uncrumpled Context Switcher - Daemon Entry Point
//
// This is the main entry point for the background service/daemon.
// It handles:
// - Command-line argument parsing
// - Daemonization (fork, setsid on Unix)
// - PID file management
// - Signal handlers (SIGTERM, SIGHUP)
// - Main event loop
//
// Usage:
//   uncrumpled-daemon [OPTIONS]
//
// Options:
//   --daemon, -d       Run as a background daemon
//   --config FILE      Path to configuration file
//   --socket-path PATH Path to Unix domain socket
//   --pid-file PATH    Path to PID file
//   --foreground, -f   Stay in foreground (don't daemonize even if --daemon)
//   --help, -h         Show help message
//   --version, -v      Show version information

#import "Basic";
#import "String";
#import "File";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
#import "Thread";
#import "Hash_Table";

// Windows API imports for process management
#if OS == .WINDOWS {
    kernel32_main :: #system_library "kernel32";
    GetCurrentProcessId :: () -> u32 #foreign kernel32_main;
    OpenProcess :: (dwDesiredAccess: u32, bInheritHandle: s32, dwProcessId: u32) -> *void #foreign kernel32_main;
    CloseHandle :: (hObject: *void) -> s32 #foreign kernel32_main;
}

// Load daemon modules (they import their own dependencies like jason, jai-toml-c)
#load "args_parser.jai";
#load "context_store.jai";
#load "ipc.jai";
#load "rpc/module.jai";
#load "api/module.jai";
#load "config/module.jai";
#load "config/validator.jai";
#load "events/module.jai";
#load "server.jai";
#load "platform/module.jai";

// Version information
VERSION_MAJOR :: 0;
VERSION_MINOR :: 1;
VERSION_PATCH :: 0;
VERSION_STRING :: "0.1.0";
PROTOCOL_VERSION :: "1.0.0";

// Default paths
#if OS == .LINUX || OS == .MACOS {
    DEFAULT_SOCKET_PATH :: "/tmp/uncrumpled-context-switcher.sock";
    DEFAULT_PID_FILE :: "/tmp/uncrumpled-context-switcher.pid";
    DEFAULT_CONFIG_PATH :: "~/.config/uncrumpled-context-switcher/config.toml";
} else {
    // Windows defaults
    DEFAULT_SOCKET_PATH :: "\\\\.\\pipe\\uncrumpled-context-switcher";
    DEFAULT_PID_FILE :: "";  // Windows uses named mutex instead
    DEFAULT_CONFIG_PATH :: "%APPDATA%\\uncrumpled-context-switcher\\config.toml";
}

// Command-line configuration
Daemon_Config :: struct {
    run_as_daemon: bool;
    stay_in_foreground: bool;
    config_path: string;
    socket_path: string;
    pid_file: string;
    show_help: bool;
    show_version: bool;
    verbose: bool;
    systemd_socket: bool;  // Use systemd socket activation (Linux)
    launchd_socket: bool;  // Use launchd socket activation (macOS)

    // Parsed state
    has_error: bool;
    error_message: string;
}

// Global state for signal handling
daemon_state: struct {
    running: bool;
    reload_requested: bool;
    pid_file_path: string;
    socket_path: string;
};

// Initialize default configuration
init_default_config :: () -> Daemon_Config {
    config: Daemon_Config;
    config.run_as_daemon = false;
    config.stay_in_foreground = false;
    config.show_help = false;
    config.show_version = false;
    config.verbose = false;
    config.systemd_socket = false;
    config.launchd_socket = false;
    config.has_error = false;

    // Use platform-specific paths
    #if OS == .LINUX {
        // XDG-compliant paths
        config.config_path = get_uncrumpled_config_path();
        config.socket_path = get_uncrumpled_socket_path();
        config.pid_file = get_uncrumpled_pid_path();
    } else #if OS == .MACOS {
        // macOS Library paths
        config.config_path = get_uncrumpled_config_path();
        config.socket_path = get_uncrumpled_socket_path();
        config.pid_file = get_uncrumpled_pid_path();
    } else #if OS == .WINDOWS {
        // Windows AppData paths
        config.config_path = get_uncrumpled_config_path();
        config.socket_path = get_uncrumpled_socket_path();  // Returns named pipe path
        config.pid_file = get_uncrumpled_pid_path();
    } else {
        config.config_path = DEFAULT_CONFIG_PATH;
        config.socket_path = DEFAULT_SOCKET_PATH;
        config.pid_file = DEFAULT_PID_FILE;
    }

    return config;
}

// Parse command-line arguments
parse_arguments :: (args: [] string) -> Daemon_Config {
    config := init_default_config();

    i := 1;  // Skip program name
    while i < args.count {
        arg := args[i];

        if arg == "--daemon" || arg == "-d" {
            config.run_as_daemon = true;
        } else if arg == "--foreground" || arg == "-f" {
            config.stay_in_foreground = true;
        } else if arg == "--help" || arg == "-h" {
            config.show_help = true;
        } else if arg == "--version" || arg == "-v" {
            config.show_version = true;
        } else if arg == "--verbose" || arg == "-V" {
            config.verbose = true;
        } else if arg == "--config" {
            if i + 1 < args.count {
                i += 1;
                config.config_path = args[i];
            } else {
                config.has_error = true;
                config.error_message = "--config requires a file path argument";
            }
        } else if arg == "--socket-path" {
            if i + 1 < args.count {
                i += 1;
                config.socket_path = args[i];
            } else {
                config.has_error = true;
                config.error_message = "--socket-path requires a path argument";
            }
        } else if arg == "--pid-file" {
            if i + 1 < args.count {
                i += 1;
                config.pid_file = args[i];
            } else {
                config.has_error = true;
                config.error_message = "--pid-file requires a path argument";
            }
        } else if arg == "--systemd-socket" {
            config.systemd_socket = true;
        } else if arg == "--launchd-socket" {
            config.launchd_socket = true;
        } else if begins_with(arg, "-") {
            config.has_error = true;
            config.error_message = tprint("Unknown option: %", arg);
        }
        // Ignore positional arguments for now

        i += 1;
    }

    return config;
}

// Print help message
print_help :: () {
    help_text :: #string END
Uncrumpled Context Switcher Daemon

Usage: uncrumpled-context-switcher-daemon [OPTIONS]

A cross-platform context management daemon that acts as a central hub for
application state, allowing services to discover, register, query, and
subscribe to context changes.

Options:
  -d, --daemon         Run as a background daemon (Unix only)
  -f, --foreground     Stay in foreground (don't daemonize even if --daemon)
  -h, --help           Show this help message
  -v, --version        Show version information
  -V, --verbose        Enable verbose logging

  --config FILE        Path to configuration file
                       Linux:   $XDG_CONFIG_HOME/uncrumpled-context-switcher/config.toml
                       macOS:   ~/Library/Application Support/uncrumpled-context-switcher/config.toml
                       Windows: %APPDATA%\uncrumpled-context-switcher\config.toml

  --socket-path PATH   Path to IPC endpoint
                       Linux:   $XDG_RUNTIME_DIR/uncrumpled-context-switcher/uncrumpled-context-switcher.sock (Unix socket)
                       macOS:   $TMPDIR/uncrumpled-context-switcher.sock (Unix socket)
                       Windows: \\.\pipe\uncrumpled-context-switcher (Named pipe)

  --pid-file PATH      Path to PID file
                       Linux:   $XDG_RUNTIME_DIR/uncrumpled-context-switcher/uncrumpled-context-switcher.pid
                       macOS:   $TMPDIR/uncrumpled-context-switcher.pid
                       Windows: %LOCALAPPDATA%\uncrumpled-context-switcher\uncrumpled-context-switcher.pid

  --systemd-socket     Use socket passed by systemd socket activation
                       (Linux only, for use with systemd socket units)

  --launchd-socket     Use socket passed by launchd socket activation
                       (macOS only, for use with launchd socket plist)

Examples:
  uncrumpled-context-switcher-daemon                    Run in foreground with defaults
  uncrumpled-context-switcher-daemon -d                 Run as a background daemon
  uncrumpled-context-switcher-daemon -d -V              Daemonize with verbose logging
  uncrumpled-context-switcher-daemon --socket-path /var/run/uncrumpled-context-switcher.sock

Linux (systemd):
  To run as a systemd user service:
    systemctl --user enable uncrumpled-context-switcher
    systemctl --user start uncrumpled-context-switcher

  To view logs:
    journalctl --user -u uncrumpled-context-switcher -f

macOS (launchd):
  To run as a launchd user agent:
    launchctl load ~/Library/LaunchAgents/com.uncrumpled-context-switcher.daemon.plist

  To view logs:
    tail -f ~/Library/Logs/uncrumpled-context-switcher/daemon.log

Windows:
  To install as a startup application:
    deploy\windows\install.bat --startup

  To install as a Windows service (requires Admin):
    deploy\windows\install.bat --service

  Configuration: %APPDATA%\uncrumpled-context-switcher\config.toml
  Logs: %LOCALAPPDATA%\uncrumpled-context-switcher\logs\

For more information, visit: https://github.com/uncrumpled/uncrumpled-context-switcher
END
    print(help_text);
}

// Print version information
print_version :: () {
    print("Uncrumpled Context Switcher Daemon v%\n", VERSION_STRING);
    print("Protocol Version: %\n", PROTOCOL_VERSION);
    #if OS == .LINUX {
        print("Platform: Linux\n");
    } else #if OS == .MACOS {
        print("Platform: macOS\n");
    } else #if OS == .WINDOWS {
        print("Platform: Windows\n");
    } else {
        print("Platform: Unknown\n");
    }
}

// Write PID to file
write_pid_file :: (path: string) -> bool {
    #if OS == .LINUX || OS == .MACOS {
        pid := getpid();
    } else #if OS == .WINDOWS {
        pid := GetCurrentProcessId();
    }
    content := tprint("%\n", pid);
    success := write_entire_file(path, content);
    if success {
        log("Wrote PID % to %", pid, path);
    } else {
        log_error("Failed to write PID file: %", path);
    }
    return success;
}

// Remove PID file
remove_pid_file :: (path: string) {
    if path.count > 0 {
        file_delete(path);
        log("Removed PID file: %", path);
    }
}

// Check if another instance is running by checking PID file
check_existing_instance :: (pid_file: string) -> bool {
    contents, success := read_entire_file(pid_file);
    if !success {
        return false;  // No PID file, no existing instance
    }
    defer free(contents);

    // Parse PID from file
    trimmed := trim(contents);
    pid, parse_ok := string_to_int(trimmed);
    if !parse_ok {
        log("Warning: Invalid PID file contents, will overwrite");
        return false;
    }

    // Check if process is still running
    #if OS == .LINUX || OS == .MACOS {
        result := kill(cast(s32) pid, 0);  // Signal 0 just checks existence
        if result == 0 {
            return true;  // Process exists
        }
    } else #if OS == .WINDOWS {
        // On Windows, try to open the process to check if it exists
        PROCESS_QUERY_LIMITED_INFORMATION :: 0x1000;
        handle := OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, cast(u32) pid);
        if handle != null {
            CloseHandle(handle);
            return true;  // Process exists
        }
    }

    // Process doesn't exist, stale PID file
    log("Found stale PID file, cleaning up");
    return false;
}

// Log helper (simple implementation, will be expanded later)
log :: (format: string, args: .. Any) {
    timestamp := seconds_since_init();
    msg := tprint(format, ..args);
    print("[%] %\n", format_timestamp(timestamp), msg);
}

log_error :: (format: string, args: .. Any) {
    timestamp := seconds_since_init();
    msg := tprint(format, ..args);
    print("[%] ERROR: %\n", format_timestamp(timestamp), msg);
}

log_warning :: (format: string, args: .. Any) {
    timestamp := seconds_since_init();
    msg := tprint(format, ..args);
    print("[%] WARN: %\n", format_timestamp(timestamp), msg);
}

format_timestamp :: (seconds: float64) -> string {
    total_ms := cast(int)(seconds * 1000);
    mins := total_ms / 60000;
    secs := (total_ms % 60000) / 1000;
    ms := total_ms % 1000;
    // Jai's print doesn't support %02d style padding, so we format manually
    secs_str := ifx secs < 10 then tprint("0%", secs) else tprint("%", secs);
    ms_str := ifx ms < 10 then tprint("00%", ms) else ifx ms < 100 then tprint("0%", ms) else tprint("%", ms);
    return tprint("%:%.%", mins, secs_str, ms_str);
}

// Signal handler for SIGTERM and SIGINT (graceful shutdown)
signal_handler_shutdown :: (sig: s32) #c_call {
    // In C callback context, minimal operations only
    daemon_state.running = false;
}

// Signal handler for SIGHUP (reload configuration)
signal_handler_reload :: (sig: s32) #c_call {
    daemon_state.reload_requested = true;
}

// Setup signal handlers
setup_signal_handlers :: () {
    #if OS == .LINUX || OS == .MACOS {
        // Setup SIGTERM handler
        action_term: sigaction_t;
        action_term.__sigaction_handler.sa_handler = signal_handler_shutdown;
        sigemptyset(*action_term.sa_mask);
        action_term.sa_flags = 0;
        sigaction(SIGTERM, *action_term, null);

        // Setup SIGINT handler (Ctrl+C)
        sigaction(SIGINT, *action_term, null);

        // Setup SIGHUP handler (reload)
        action_hup: sigaction_t;
        action_hup.__sigaction_handler.sa_handler = signal_handler_reload;
        sigemptyset(*action_hup.sa_mask);
        action_hup.sa_flags = 0;
        sigaction(SIGHUP, *action_hup, null);

        log("Signal handlers installed");
    }
}

// Daemonize the process (Unix only)
daemonize :: () -> bool {
    #if OS == .LINUX || OS == .MACOS {
        // First fork
        pid := fork();
        if pid < 0 {
            log_error("First fork failed");
            return false;
        }
        if pid > 0 {
            // Parent process - exit
            exit(0);
        }

        // Child process continues
        // Create new session
        if setsid() < 0 {
            log_error("setsid failed");
            return false;
        }

        // Second fork to prevent acquiring a controlling terminal
        pid = fork();
        if pid < 0 {
            log_error("Second fork failed");
            return false;
        }
        if pid > 0 {
            // First child exits
            exit(0);
        }

        // Grandchild continues as daemon

        // Change working directory to root to avoid holding directories open
        chdir("/");

        // Close standard file descriptors
        // In production, would redirect to /dev/null or log file
        // For now, leave them as-is for debugging

        log("Daemonized successfully, PID: %", getpid());
        return true;
    } else {
        // Windows - daemonization is different
        log_warning("Daemonization not supported on this platform");
        return false;
    }
}

// Helper to extract parent directory from a path
get_socket_directory :: (path: string) -> string {
    // Find the last path separator
    last_sep := -1;
    for i: 0..path.count-1 {
        if path[i] == #char "/" {
            last_sep = i;
        }
    }

    if last_sep <= 0 {
        return "";
    }

    result: string;
    result.data = path.data;
    result.count = last_sep;
    return result;
}

// Global daemon server instance
daemon_server: Daemon_Server;

// Main daemon loop
run_daemon :: (config: *Daemon_Config) {
    daemon_state.running = true;
    daemon_state.socket_path = config.socket_path;
    daemon_state.pid_file_path = config.pid_file;

    log("Starting daemon...");
    log("Socket path: %", config.socket_path);
    log("Config path: %", config.config_path);

    // Check for socket activation (platform-specific)
    service_fd: s32 = -1;

    #if OS == .LINUX {
        // Check for systemd socket activation (Linux only)
        if config.systemd_socket {
            service_fd = get_systemd_socket_fd();
            if service_fd >= 0 {
                log("Using systemd socket activation (fd=%)", service_fd);
                clear_systemd_listen_vars();
            } else {
                log_warning("--systemd-socket specified but no socket passed by systemd");
            }
        } else {
            // Auto-detect socket activation even without flag
            fd_count := is_systemd_socket_activated();
            if fd_count > 0 {
                service_fd = SD_LISTEN_FDS_START;
                log("Auto-detected systemd socket activation (fd=%)", service_fd);
                clear_systemd_listen_vars();
            }
        }
    }

    #if OS == .MACOS {
        // Check for launchd socket activation (macOS only)
        if config.launchd_socket {
            service_fd = get_launchd_socket_fd();
            if service_fd >= 0 {
                log("Using launchd socket activation (fd=%)", service_fd);
            } else {
                log_warning("--launchd-socket specified but no socket passed by launchd");
            }
        } else {
            // Auto-detect launchd socket activation
            if is_launchd_socket_activated() {
                service_fd = get_launchd_socket_fd();
                if service_fd >= 0 {
                    log("Auto-detected launchd socket activation (fd=%)", service_fd);
                }
            }
        }
    }

    // Ensure runtime directory exists for socket (platform-specific)
    #if OS == .LINUX {
        if service_fd < 0 {  // Only if not using systemd socket
            socket_dir := get_socket_directory(config.socket_path);
            if socket_dir.count > 0 {
                if !ensure_directory(socket_dir) {
                    log_warning("Could not create socket directory: %", socket_dir);
                }
            }
        }
    }

    #if OS == .MACOS {
        if service_fd < 0 {  // Only if not using launchd socket
            // Ensure log directory exists
            logs_dir := get_uncrumpled_logs_dir();
            defer free(logs_dir);
            if !ensure_directory(logs_dir) {
                log_warning("Could not create logs directory: %", logs_dir);
            }

            // Ensure config directory exists
            config_dir := get_uncrumpled_config_dir();
            defer free(config_dir);
            if !ensure_directory(config_dir) {
                log_warning("Could not create config directory: %", config_dir);
            }
        }
    }

    #if OS == .WINDOWS {
        // Ensure directories exist on Windows
        config_dir := get_uncrumpled_config_dir();
        if !ensure_directory(config_dir) {
            log_warning("Could not create config directory: %", config_dir);
        }

        data_dir := get_uncrumpled_data_dir();
        if !ensure_directory(data_dir) {
            log_warning("Could not create data directory: %", data_dir);
        }

        logs_dir := get_uncrumpled_logs_dir();
        if !ensure_directory(logs_dir) {
            log_warning("Could not create logs directory: %", logs_dir);
        }
    }

    // Setup signal handlers
    setup_signal_handlers();

    // Write PID file
    if config.pid_file.count > 0 {
        // Ensure PID file directory exists
        #if OS == .LINUX {
            pid_dir := get_socket_directory(config.pid_file);
            if pid_dir.count > 0 {
                ensure_directory(pid_dir);
            }
        }
        if !write_pid_file(config.pid_file) {
            log_error("Failed to write PID file, continuing anyway");
        }
    }

    // Load configuration file
    expanded_config_path := expand_path(config.config_path);
    defer free(expanded_config_path);

    user_config, config_loaded := parse_config_file(expanded_config_path);
    if !config_loaded {
        log_warning("Could not load config file '%', using defaults", config.config_path);
        user_config = create_default_config();
    } else {
        log("Loaded configuration from %", config.config_path);
    }

    // Initialize the daemon server
    if !init_daemon_server(*daemon_server, config.socket_path, *user_config, service_fd) {
        log_error("Failed to initialize daemon server");
        if config_loaded free_user_config(*user_config);
        return;
    }

    // Start listening for connections
    if !start_daemon_server(*daemon_server) {
        log_error("Failed to start daemon server");
        destroy_daemon_server(*daemon_server);
        if config_loaded free_user_config(*user_config);
        return;
    }

    log("Daemon initialized, listening on %", config.socket_path);

    // Notify systemd we're ready (Linux only)
    #if OS == .LINUX {
        if notify_systemd_ready() {
            log("Notified systemd: READY");
        }
    }

    log("Entering main loop...");

    // Main event loop
    while daemon_state.running {
        // Check for reload request
        if daemon_state.reload_requested {
            log("Reload requested, reloading configuration...");
            // Reload config file
            new_config, reload_success := parse_config_file(expanded_config_path);
            if reload_success {
                if config_loaded free_user_config(*user_config);
                user_config = new_config;
                config_loaded = true;
                log("Configuration reloaded successfully");
            } else {
                free_user_config(*new_config);
                log_warning("Failed to reload config, keeping existing");
            }
            daemon_state.reload_requested = false;
        }

        // Run one iteration of the server loop (100ms timeout)
        if !run_server_iteration(*daemon_server, 100) {
            break;
        }
    }

    log("Shutdown signal received");

    // Print final statistics
    stats := get_server_stats(*daemon_server);
    log("Final stats: % requests, % responses, % errors", stats.total_requests, stats.total_responses, stats.total_errors);
    log("Network: % bytes received, % bytes sent", stats.bytes_received, stats.bytes_sent);

    // Cleanup server
    stop_daemon_server(*daemon_server);
    destroy_daemon_server(*daemon_server);

    // Free config
    if config_loaded free_user_config(*user_config);

    // Cleanup remaining resources
    cleanup(config);
}

// Sleep helper (platform-independent)
sleep_milliseconds :: (ms: int) {
    #if OS == .LINUX || OS == .MACOS {
        spec: timespec;
        spec.tv_sec = ms / 1000;
        spec.tv_nsec = (ms % 1000) * 1_000_000;
        nanosleep(*spec, null);
    } else #if OS == .WINDOWS {
        windows_Sleep(cast(u32) ms);
    }
}

#if OS == .WINDOWS {
    windows_kernel32 :: #system_library "kernel32";
    windows_Sleep :: (dwMilliseconds: u32) #foreign windows_kernel32 "Sleep";
}

// Cleanup resources
cleanup :: (config: *Daemon_Config) {
    log("Cleaning up...");

    // TODO: Close IPC connections
    // TODO: Save state if needed

    // Remove PID file
    if config.pid_file.count > 0 {
        remove_pid_file(config.pid_file);
    }

    // TODO: Remove socket file

    log("Cleanup complete");
}

// Main entry point
main :: () {
    // Get command line arguments
    args := get_command_line_arguments();

    // Parse arguments
    config := parse_arguments(args);

    // Handle errors
    if config.has_error {
        print("Error: %\n", config.error_message);
        print("Try 'uncrumpled-context-switcher-daemon --help' for more information.\n");
        exit(1);
    }

    // Handle --help
    if config.show_help {
        print_help();
        exit(0);
    }

    // Handle --version
    if config.show_version {
        print_version();
        exit(0);
    }

    // Check for existing instance
    if config.pid_file.count > 0 {
        if check_existing_instance(config.pid_file) {
            log_error("Another instance is already running (check %)", config.pid_file);
            exit(1);
        }
    }

    // Daemonize if requested
    if config.run_as_daemon && !config.stay_in_foreground {
        log("Daemonizing...");
        if !daemonize() {
            log_error("Failed to daemonize");
            exit(1);
        }
    }

    // Print startup banner
    log("==============================================");
    log("  Uncrumpled Context Switcher Daemon v%", VERSION_STRING);
    log("  Protocol Version: %", PROTOCOL_VERSION);
    log("==============================================");

    // Run the daemon
    run_daemon(*config);

    log("Daemon terminated");
}
