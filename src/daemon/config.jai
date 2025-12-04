// Daemon Configuration and Argument Parsing
//
// This module handles:
// - Command-line argument parsing
// - Configuration file loading (TODO)
// - Default values for all settings
// - Configuration validation

#import "Basic";
#import "String";
#import "File";

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
