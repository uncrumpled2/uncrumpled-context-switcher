// Uncrumpled Context Switcher CLI Client
//
// A command-line interface for interacting with the daemon.
// This client sends JSON-RPC requests to the daemon and displays the responses.
//
// Usage:
//   uncrumpled-context-switcher-cli [OPTIONS] COMMAND [ARGS]
//
// Commands:
//   context get          Get current context
//   context set          Set full context
//   context add-tag      Add a tag
//   context remove-tag   Remove a tag
//   context set-param    Set a parameter
//   context get-param    Get a parameter
//   service list         List registered services
//   logs list            List recent execution logs
//   status               Show daemon status
//   ping                 Check if daemon is running
//
// Options:
//   --socket PATH        Socket path (default: /tmp/uncrumpled-context-switcher.sock)
//   --json               Output raw JSON responses
//   --help, -h           Show help message
//   --version, -v        Show version information

#import "Basic";
#import "String";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
#import "File";

// ============================================================================
// Socket FFI Bindings
// ============================================================================
// Using direct libc bindings to avoid conflicts with POSIX module

#if OS == .LINUX || OS == .MACOS {

libc :: #library,system "libc";

// Socket structures
cli_sockaddr_un :: struct {
    sun_family: u16;
    sun_path: [108] u8;
}

// Socket constants
CLI_AF_UNIX :: 1;
CLI_SOCK_STREAM :: 1;

// Socket functions
cli_socket :: (domain: s32, type: s32, protocol: s32) -> s32 #foreign libc "socket";
cli_connect :: (sockfd: s32, addr: *void, addrlen: u32) -> s32 #foreign libc "connect";

} // OS == .LINUX || OS == .MACOS

#if OS == .WINDOWS {

kernel32 :: #system_library "kernel32";

// Windows type aliases
HANDLE :: *void;
DWORD :: u32;
BOOL :: s32;
LPCSTR :: *u8;
LPVOID :: *void;

// Windows constants
INVALID_HANDLE_VALUE :: cast(HANDLE) -1;
GENERIC_READ :: 0x80000000;
GENERIC_WRITE :: 0x40000000;
OPEN_EXISTING :: 3;
ERROR_PIPE_BUSY :: 231;
NMPWAIT_WAIT_FOREVER :: 0xFFFFFFFF;

// Windows API functions
CreateFileA :: (
    lpFileName: LPCSTR,
    dwDesiredAccess: DWORD,
    dwShareMode: DWORD,
    lpSecurityAttributes: LPVOID,
    dwCreationDisposition: DWORD,
    dwFlagsAndAttributes: DWORD,
    hTemplateFile: HANDLE
) -> HANDLE #foreign kernel32;

ReadFile :: (
    hFile: HANDLE,
    lpBuffer: LPVOID,
    nNumberOfBytesToRead: DWORD,
    lpNumberOfBytesRead: *DWORD,
    lpOverlapped: LPVOID
) -> BOOL #foreign kernel32;

WriteFile :: (
    hFile: HANDLE,
    lpBuffer: LPVOID,
    nNumberOfBytesToWrite: DWORD,
    lpNumberOfBytesWritten: *DWORD,
    lpOverlapped: LPVOID
) -> BOOL #foreign kernel32;

CloseHandle :: (hObject: HANDLE) -> BOOL #foreign kernel32;
GetLastError :: () -> DWORD #foreign kernel32;
WaitNamedPipeA :: (lpNamedPipeName: LPCSTR, nTimeOut: DWORD) -> BOOL #foreign kernel32;

} // OS == .WINDOWS

// Version info
CLI_VERSION :: "0.1.0";

// Default socket path
#if OS == .LINUX || OS == .MACOS {
    DEFAULT_SOCKET_PATH :: "/tmp/uncrumpled-context-switcher.sock";
} else {
    DEFAULT_SOCKET_PATH :: "\\\\.\\pipe\\uncrumpled-context-switcher";
}

// Buffer sizes
RECV_BUFFER_SIZE :: 65536;

// CLI configuration
CLI_Config :: struct {
    socket_path: string;
    output_json: bool;
    show_help: bool;
    show_version: bool;
    command: string;
    args: [..] string;
    has_error: bool;
    error_message: string;
}

// Initialize default config
init_cli_config :: () -> CLI_Config {
    config: CLI_Config;
    config.socket_path = DEFAULT_SOCKET_PATH;
    config.output_json = false;
    config.show_help = false;
    config.show_version = false;
    return config;
}

// Parse command line arguments
parse_cli_arguments :: (args: [] string) -> CLI_Config {
    config := init_cli_config();

    i := 1;  // Skip program name
    while i < args.count {
        arg := args[i];

        if arg == "--help" || arg == "-h" {
            config.show_help = true;
        } else if arg == "--version" || arg == "-v" {
            config.show_version = true;
        } else if arg == "--json" {
            config.output_json = true;
        } else if arg == "--socket" {
            if i + 1 < args.count {
                i += 1;
                config.socket_path = args[i];
            } else {
                config.has_error = true;
                config.error_message = "--socket requires a path argument";
            }
        } else if begins_with(arg, "-") {
            config.has_error = true;
            config.error_message = tprint("Unknown option: %", arg);
        } else {
            // First non-option is the command
            if config.command.count == 0 {
                config.command = arg;
            } else {
                array_add(*config.args, arg);
            }
        }

        i += 1;
    }

    return config;
}

// Print help message
print_cli_help :: () {
    help_text :: #string END
Uncrumpled Context Switcher CLI Client

Usage: uncrumpled-context-switcher-cli [OPTIONS] COMMAND [ARGS]

Commands:
  context get            Get current context
  context add-tag TAG    Add a tag to the context
  context remove-tag TAG Remove a tag from the context
  context set-param K V  Set a user parameter
  context get-param KEY  Get a user parameter

  service list           List registered services
  service heartbeat ID   Send heartbeat for a service

  logs list [LIMIT]      List recent execution logs
  logs get ID            Get details of an execution log

  status                 Show daemon status (services, subscribers, config)
  ping                   Check if daemon is running

  subscribe EVENTS       Subscribe to events (for testing)

Options:
  --socket PATH          Socket path (default: /tmp/uncrumpled-context-switcher.sock)
  --json                 Output raw JSON responses
  -h, --help             Show this help message
  -v, --version          Show version information

Examples:
  uncrumpled-context-switcher-cli context get
  uncrumpled-context-switcher-cli context add-tag --work
  uncrumpled-context-switcher-cli context set-param mode debug
  uncrumpled-context-switcher-cli service list
  uncrumpled-context-switcher-cli ping
  uncrumpled-context-switcher-cli --json context get

END
    print(help_text);
}

// Print version
print_cli_version :: () {
    print("Uncrumpled Context Switcher CLI Client v%\n", CLI_VERSION);
}

// ============================================================================
// Socket Communication
// ============================================================================

// Helper: convert Jai string to C string
cli_to_c_string :: (s: string) -> *u8 {
    if s.count == 0 return null;
    result := alloc(s.count + 1);
    memcpy(result, s.data, s.count);
    (cast(*u8) result)[s.count] = 0;
    return result;
}

// Close socket/handle (cross-platform)
cli_close :: (sock: s32) {
    #if OS == .LINUX || OS == .MACOS {
        close(sock);
    } else #if OS == .WINDOWS {
        CloseHandle(cast(HANDLE) cast(u64) sock);
    }
}

// Connect to daemon socket
connect_to_daemon :: (socket_path: string) -> s32, bool {
    #if OS == .LINUX || OS == .MACOS {
        // Create socket using our FFI bindings
        sock := cli_socket(CLI_AF_UNIX, CLI_SOCK_STREAM, 0);
        if sock < 0 {
            return -1, false;
        }

        // Setup address
        addr: cli_sockaddr_un;
        addr.sun_family = CLI_AF_UNIX;

        // Copy socket path to sun_path
        path_bytes := cast([] u8) socket_path;
        max_len := 108 - 1;  // sun_path is typically 108 bytes
        copy_len := min(path_bytes.count, max_len);
        memcpy(addr.sun_path.data, path_bytes.data, copy_len);
        addr.sun_path[copy_len] = 0;

        // Connect
        result := cli_connect(sock, *addr, size_of(cli_sockaddr_un));
        if result < 0 {
            close(sock);
            return -1, false;
        }

        return sock, true;
    } else #if OS == .WINDOWS {
        // Create null-terminated path
        c_path := cli_to_c_string(socket_path);
        defer free(c_path);

        // Wait for the pipe to be available
        if !WaitNamedPipeA(c_path, 5000) {  // 5 second timeout
            return -1, false;
        }

        // Open the pipe
        handle := CreateFileA(
            c_path,
            GENERIC_READ | GENERIC_WRITE,
            0,  // No sharing
            null,
            OPEN_EXISTING,
            0,
            null
        );

        if handle == INVALID_HANDLE_VALUE {
            return -1, false;
        }

        // Store handle as s32 (we'll cast back when using it)
        return cast(s32) cast(u64) handle, true;
    } else {
        return -1, false;
    }
}

// Send a JSON-RPC request and receive response
send_request :: (sock: s32, method: string, params: string = "") -> string, bool {
    // Build JSON-RPC request
    request: string;
    if params.count > 0 {
        request = tprint(#string END
{"jsonrpc":"2.0","method":"%","params":%,"id":1}
END
        , method, params);
    } else {
        request = tprint(#string END
{"jsonrpc":"2.0","method":"%","id":1}
END
        , method);
    }

    // Send request
    #if OS == .LINUX || OS == .MACOS {
        bytes_sent := write(sock, request.data, cast(u64) request.count);
        if bytes_sent < 0 {
            return "", false;
        }
    } else #if OS == .WINDOWS {
        bytes_written: DWORD = 0;
        if !WriteFile(cast(HANDLE) cast(u64) sock, request.data, cast(DWORD) request.count, *bytes_written, null) {
            return "", false;
        }
    }

    // Receive response
    buffer: [RECV_BUFFER_SIZE] u8;
    bytes_received: s64 = 0;

    #if OS == .LINUX || OS == .MACOS {
        bytes_received = read(sock, buffer.data, RECV_BUFFER_SIZE - 1);
        if bytes_received <= 0 {
            return "", false;
        }
    } else #if OS == .WINDOWS {
        bytes_read: DWORD = 0;
        if !ReadFile(cast(HANDLE) cast(u64) sock, buffer.data, cast(DWORD) (RECV_BUFFER_SIZE - 1), *bytes_read, null) {
            return "", false;
        }
        bytes_received = cast(s64) bytes_read;
        if bytes_received <= 0 {
            return "", false;
        }
    }

    // Null-terminate and return
    buffer[bytes_received] = 0;
    response := copy_string(string.{bytes_received, buffer.data});

    return response, true;
}

// ============================================================================
// Command Handlers
// ============================================================================

// Handle context get
handle_context_get :: (config: *CLI_Config) -> bool {
    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    response, ok := send_request(sock, "context.get");
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        // Pretty print the context
        print_context_response(response);
    }

    return true;
}

// Handle context list
handle_context_list :: (config: *CLI_Config) -> bool {
    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    response, ok := send_request(sock, "context.list");
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        print("Context List:\n");
        print("  %\n", response);
    }

    return true;
}

// Handle context add-tag
handle_context_add_tag :: (config: *CLI_Config) -> bool {
    if config.args.count < 1 {
        print("Error: context add-tag requires a TAG argument\n");
        return false;
    }

    tag := config.args[0];

    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    params := tprint("{\"tag\":\"%\"}", tag);
    response, ok := send_request(sock, "context.addTag", params);
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        print("Tag '%' added.\n", tag);
    }

    return true;
}

// Handle context remove-tag
handle_context_remove_tag :: (config: *CLI_Config) -> bool {
    if config.args.count < 1 {
        print("Error: context remove-tag requires a TAG argument\n");
        return false;
    }

    tag := config.args[0];

    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    params := tprint("{\"tag\":\"%\"}", tag);
    response, ok := send_request(sock, "context.removeTag", params);
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        print("Tag '%' removed.\n", tag);
    }

    return true;
}

// Handle service list
handle_service_list :: (config: *CLI_Config) -> bool {
    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    response, ok := send_request(sock, "service.list");
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        print_service_list_response(response);
    }

    return true;
}

// Handle logs list
handle_logs_list :: (config: *CLI_Config) -> bool {
    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        return false;
    }
    defer cli_close(sock);

    limit := "50";
    if config.args.count > 0 {
        limit = config.args[0];
    }

    params := tprint("{\"limit\":%}", limit);
    response, ok := send_request(sock, "logs.list", params);
    if !ok {
        print("Error: Failed to receive response\n");
        return false;
    }
    defer free(response);

    if config.output_json {
        print("%\n", response);
    } else {
        print_logs_list_response(response);
    }

    return true;
}

// Handle ping
handle_ping :: (config: *CLI_Config) -> bool {
    sock, success := connect_to_daemon(config.socket_path);
    if !success {
        print("Error: Could not connect to daemon at %\n", config.socket_path);
        print("Daemon is NOT running or socket is unavailable.\n");
        return false;
    }
    defer cli_close(sock);

    // Try to get context as a simple ping
    response, ok := send_request(sock, "context.get");
    if !ok {
        print("Error: Daemon not responding\n");
        return false;
    }
    defer free(response);

    print("Daemon is running at %\n", config.socket_path);
    return true;
}

// ============================================================================
// Response Formatting
// ============================================================================

// Pretty print a context response
print_context_response :: (json_response: string) {
    // For now, just print the raw response with some basic formatting
    // A full implementation would parse the JSON properly
    print("Context:\n");
    print("  %\n", json_response);
}

// Pretty print service list response
print_service_list_response :: (json_response: string) {
    print("Registered Services:\n");
    print("  %\n", json_response);
}

// Pretty print logs list response
print_logs_list_response :: (json_response: string) {
    print("Execution Logs:\n");
    print("  %\n", json_response);
}

// ============================================================================
// Main Entry Point
// ============================================================================

main :: () {
    args := get_command_line_arguments();
    config := parse_cli_arguments(args);

    // Handle errors
    if config.has_error {
        print("Error: %\n", config.error_message);
        print("Try 'uncrumpled-context-switcher-cli --help' for more information.\n");
        exit(1);
    }

    // Handle --help
    if config.show_help {
        print_cli_help();
        exit(0);
    }

    // Handle --version
    if config.show_version {
        print_cli_version();
        exit(0);
    }

    // Require a command
    if config.command.count == 0 {
        print("Error: No command specified\n");
        print("Try 'uncrumpled-context-switcher-cli --help' for more information.\n");
        exit(1);
    }

    // Route to command handler
    success := false;

    if config.command == "ping" {
        success = handle_ping(*config);
    } else if config.command == "context" {
        if config.args.count > 0 {
            subcommand := config.args[0];
            array_ordered_remove_by_index(*config.args, 0);  // Remove subcommand from args

            if subcommand == "get" {
                success = handle_context_get(*config);
            } else if subcommand == "list" {
                success = handle_context_list(*config);
            } else if subcommand == "add-tag" {
                success = handle_context_add_tag(*config);
            } else if subcommand == "remove-tag" {
                success = handle_context_remove_tag(*config);
            } else {
                print("Error: Unknown context subcommand: %\n", subcommand);
                exit(1);
            }
        } else {
            print("Error: context requires a subcommand (get, add-tag, remove-tag, ...)\n");
            exit(1);
        }
    } else if config.command == "service" {
        if config.args.count > 0 {
            subcommand := config.args[0];
            array_ordered_remove_by_index(*config.args, 0);

            if subcommand == "list" {
                success = handle_service_list(*config);
            } else {
                print("Error: Unknown service subcommand: %\n", subcommand);
                exit(1);
            }
        } else {
            print("Error: service requires a subcommand (list, heartbeat, ...)\n");
            exit(1);
        }
    } else if config.command == "logs" {
        if config.args.count > 0 {
            subcommand := config.args[0];
            array_ordered_remove_by_index(*config.args, 0);

            if subcommand == "list" {
                success = handle_logs_list(*config);
            } else {
                print("Error: Unknown logs subcommand: %\n", subcommand);
                exit(1);
            }
        } else {
            print("Error: logs requires a subcommand (list, get, ...)\n");
            exit(1);
        }
    } else {
        print("Error: Unknown command: %\n", config.command);
        print("Try 'uncrumpled-context-switcher-cli --help' for available commands.\n");
        exit(1);
    }

    if !success {
        exit(1);
    }
}
