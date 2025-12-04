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
#import "POSIX";
#import "Thread";
#import "Hash_Table";

// Load daemon modules (they import their own dependencies like jason, jai-toml-c)
#load "context_store.jai";
#load "ipc.jai";
#load "rpc/module.jai";
#load "api/module.jai";
#load "config/module.jai";
#load "config/validator.jai";
#load "events/module.jai";
#load "server.jai";

// Version information
VERSION_MAJOR :: 0;
VERSION_MINOR :: 1;
VERSION_PATCH :: 0;
VERSION_STRING :: "0.1.0";
PROTOCOL_VERSION :: "1.0.0";

// Default paths
#if OS == .LINUX || OS == .MACOS {
    DEFAULT_SOCKET_PATH :: "/tmp/uncrumpled.sock";
    DEFAULT_PID_FILE :: "/tmp/uncrumpled.pid";
    DEFAULT_CONFIG_PATH :: "~/.config/uncrumpled/config.toml";
} else {
    // Windows defaults
    DEFAULT_SOCKET_PATH :: "\\\\.\\pipe\\uncrumpled-context";
    DEFAULT_PID_FILE :: "";  // Windows uses named mutex instead
    DEFAULT_CONFIG_PATH :: "%APPDATA%\\uncrumpled\\config.toml";
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
    config.config_path = DEFAULT_CONFIG_PATH;
    config.socket_path = DEFAULT_SOCKET_PATH;
    config.pid_file = DEFAULT_PID_FILE;
    config.show_help = false;
    config.show_version = false;
    config.verbose = false;
    config.has_error = false;
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

Usage: uncrumpled-daemon [OPTIONS]

A cross-platform context management daemon that acts as a central hub for
application state, allowing services to discover, register, query, and
subscribe to context changes.

Options:
  -d, --daemon         Run as a background daemon
  -f, --foreground     Stay in foreground (don't daemonize even if --daemon)
  -h, --help           Show this help message
  -v, --version        Show version information
  -V, --verbose        Enable verbose logging

  --config FILE        Path to configuration file
                       (default: ~/.config/uncrumpled/config.toml)

  --socket-path PATH   Path to Unix domain socket
                       (default: /tmp/uncrumpled.sock)

  --pid-file PATH      Path to PID file
                       (default: /tmp/uncrumpled.pid)

Examples:
  uncrumpled-daemon                    Run in foreground with defaults
  uncrumpled-daemon -d                 Run as a background daemon
  uncrumpled-daemon -d -V              Daemonize with verbose logging
  uncrumpled-daemon --socket-path /var/run/uncrumpled.sock

For more information, visit: https://github.com/uncrumpled/context-switcher
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
    pid := getpid();
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
    result := kill(cast(s32) pid, 0);  // Signal 0 just checks existence
    if result == 0 {
        return true;  // Process exists
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

    // Setup signal handlers
    setup_signal_handlers();

    // Write PID file
    if config.pid_file.count > 0 {
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
    if !init_daemon_server(*daemon_server, config.socket_path, *user_config) {
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
    } else {
        // Windows would use Sleep()
    }
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
        print("Try 'uncrumpled-daemon --help' for more information.\n");
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
