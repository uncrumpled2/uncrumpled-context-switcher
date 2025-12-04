// Windows Platform Specifics
//
// This module provides Windows-specific functionality:
// - Standard Windows directory paths (APPDATA, LOCALAPPDATA)
// - Windows Service integration
// - Named pipe support
// - Runtime directory management

#import "Basic";
#import "String";

// Windows uses different standard paths than Unix:
// - Config: %APPDATA%\uncrumpled\config.toml
// - Data: %LOCALAPPDATA%\uncrumpled\
// - Cache: %LOCALAPPDATA%\uncrumpled\cache\
// - Logs: %LOCALAPPDATA%\uncrumpled\logs\

// Standard Windows named pipe path
WINDOWS_PIPE_NAME :: "\\\\.\\pipe\\uncrumpled-context";

// Get the APPDATA directory path (%APPDATA%)
// Typically C:\Users\<username>\AppData\Roaming
get_appdata_dir :: () -> string {
    appdata := get_env("APPDATA");
    if appdata.count > 0 {
        return copy_string(appdata);
    }

    // Fallback to USERPROFILE\AppData\Roaming
    userprofile := get_env("USERPROFILE");
    if userprofile.count > 0 {
        return tprint("%\\AppData\\Roaming", userprofile);
    }

    return copy_string("C:\\Users\\Public\\AppData\\Roaming");
}

// Get the LOCALAPPDATA directory path (%LOCALAPPDATA%)
// Typically C:\Users\<username>\AppData\Local
get_local_appdata_dir :: () -> string {
    local_appdata := get_env("LOCALAPPDATA");
    if local_appdata.count > 0 {
        return copy_string(local_appdata);
    }

    // Fallback to USERPROFILE\AppData\Local
    userprofile := get_env("USERPROFILE");
    if userprofile.count > 0 {
        return tprint("%\\AppData\\Local", userprofile);
    }

    return copy_string("C:\\Users\\Public\\AppData\\Local");
}

// Get the PROGRAMDATA directory path (%PROGRAMDATA%)
// Typically C:\ProgramData - for system-wide config
get_programdata_dir :: () -> string {
    programdata := get_env("PROGRAMDATA");
    if programdata.count > 0 {
        return copy_string(programdata);
    }

    return copy_string("C:\\ProgramData");
}

// Get the TEMP directory path (%TEMP% or %TMP%)
get_temp_dir :: () -> string {
    temp := get_env("TEMP");
    if temp.count > 0 {
        return copy_string(temp);
    }

    tmp := get_env("TMP");
    if tmp.count > 0 {
        return copy_string(tmp);
    }

    return copy_string("C:\\Windows\\Temp");
}

// Get the uncrumpled config directory path (roaming - follows user)
get_uncrumpled_config_dir :: () -> string {
    appdata := get_appdata_dir();
    defer free(appdata);
    return tprint("%\\uncrumpled", appdata);
}

// Get the uncrumpled config file path
get_uncrumpled_config_path :: () -> string {
    config_dir := get_uncrumpled_config_dir();
    // Note: config_dir is from tprint so we don't free it
    return tprint("%\\config.toml", config_dir);
}

// Get the uncrumpled data directory path (local)
get_uncrumpled_data_dir :: () -> string {
    local_appdata := get_local_appdata_dir();
    defer free(local_appdata);
    return tprint("%\\uncrumpled", local_appdata);
}

// Get the uncrumpled state directory path
get_uncrumpled_state_dir :: () -> string {
    return get_uncrumpled_data_dir();
}

// Get the uncrumpled cache directory path
get_uncrumpled_cache_dir :: () -> string {
    data_dir := get_uncrumpled_data_dir();
    // Note: data_dir is from tprint so we don't free it
    return tprint("%\\cache", data_dir);
}

// Get the uncrumpled logs directory path
get_uncrumpled_logs_dir :: () -> string {
    data_dir := get_uncrumpled_data_dir();
    // Note: data_dir is from tprint so we don't free it
    return tprint("%\\logs", data_dir);
}

// Get the preferred named pipe path
get_uncrumpled_pipe_path :: () -> string {
    return copy_string(WINDOWS_PIPE_NAME);
}

// For API compatibility with Unix - socket path returns named pipe path on Windows
get_uncrumpled_socket_path :: () -> string {
    return get_uncrumpled_pipe_path();
}

// Get the PID file path (Windows doesn't use PID files normally, but we support it)
// Uses a file in temp or data directory
get_uncrumpled_pid_path :: () -> string {
    data_dir := get_uncrumpled_data_dir();
    // Note: data_dir is from tprint so we don't free it
    return tprint("%\\uncrumpled.pid", data_dir);
}

// Helper to get environment variable
get_env :: (name: string) -> string {
    // Use Windows API to get environment variable
    name_cstr := temp_c_string(name);

    // First call to get required buffer size
    required_size := GetEnvironmentVariableA(name_cstr, null, 0);
    if required_size == 0 {
        return "";
    }

    // Allocate buffer and get value
    buffer := cast(*u8) alloc(required_size);
    actual_size := GetEnvironmentVariableA(name_cstr, buffer, required_size);

    if actual_size == 0 {
        free(buffer);
        return "";
    }

    result: string;
    result.data = buffer;
    result.count = cast(s64) actual_size;
    return result;
}

// Windows Service support
//
// Windows services are managed through the Service Control Manager (SCM).
// Unlike Unix daemons that fork, Windows services register with the SCM
// and receive control events.

// Service states
Windows_Service_State :: enum {
    NOT_INSTALLED;
    STOPPED;
    START_PENDING;
    STOP_PENDING;
    RUNNING;
    CONTINUE_PENDING;
    PAUSE_PENDING;
    PAUSED;
    UNKNOWN;
}

// Get the service name for registration
get_windows_service_name :: () -> string {
    return copy_string("UncrumpledDaemon");
}

// Get the service display name
get_windows_service_display_name :: () -> string {
    return copy_string("Uncrumpled Context Switcher");
}

// Get the service description
get_windows_service_description :: () -> string {
    return copy_string("A context management daemon that acts as a central hub for application state");
}

// Check if running as a Windows service
// Services are started by SCM and have a parent process of services.exe
is_running_as_service :: () -> bool {
    // Check if we have a console - services typically don't
    console_window := GetConsoleWindow();
    if console_window == null {
        return true;  // No console, likely a service
    }

    // Additional check: services.exe as parent
    // For simplicity, we check for a command-line flag instead
    // The actual service mode is detected via SERVICE_TABLE_ENTRY

    return false;
}

// Check if the service is installed
is_service_installed :: () -> bool {
    scm_handle := OpenSCManagerA(null, null, SC_MANAGER_CONNECT);
    if scm_handle == null {
        return false;
    }
    defer CloseServiceHandle(scm_handle);

    service_name := get_windows_service_name();
    defer free(service_name);
    service_name_cstr := temp_c_string(service_name);

    service_handle := OpenServiceA(scm_handle, service_name_cstr, SERVICE_QUERY_STATUS);
    if service_handle == null {
        return false;
    }

    CloseServiceHandle(service_handle);
    return true;
}

// Get current service state
get_service_state :: () -> Windows_Service_State {
    scm_handle := OpenSCManagerA(null, null, SC_MANAGER_CONNECT);
    if scm_handle == null {
        return .NOT_INSTALLED;
    }
    defer CloseServiceHandle(scm_handle);

    service_name := get_windows_service_name();
    defer free(service_name);
    service_name_cstr := temp_c_string(service_name);

    service_handle := OpenServiceA(scm_handle, service_name_cstr, SERVICE_QUERY_STATUS);
    if service_handle == null {
        return .NOT_INSTALLED;
    }
    defer CloseServiceHandle(service_handle);

    status: SERVICE_STATUS;
    if !QueryServiceStatus(service_handle, *status) {
        return .UNKNOWN;
    }

    if status.dwCurrentState == {
        case SERVICE_STOPPED;          return .STOPPED;
        case SERVICE_START_PENDING;    return .START_PENDING;
        case SERVICE_STOP_PENDING;     return .STOP_PENDING;
        case SERVICE_RUNNING;          return .RUNNING;
        case SERVICE_CONTINUE_PENDING; return .CONTINUE_PENDING;
        case SERVICE_PAUSE_PENDING;    return .PAUSE_PENDING;
        case SERVICE_PAUSED;           return .PAUSED;
        case;                          return .UNKNOWN;
    }
}

// Service state to string
service_state_to_string :: (state: Windows_Service_State) -> string {
    if state == {
        case .NOT_INSTALLED;    return "not_installed";
        case .STOPPED;          return "stopped";
        case .START_PENDING;    return "start_pending";
        case .STOP_PENDING;     return "stop_pending";
        case .RUNNING;          return "running";
        case .CONTINUE_PENDING; return "continue_pending";
        case .PAUSE_PENDING;    return "pause_pending";
        case .PAUSED;           return "paused";
        case .UNKNOWN;          return "unknown";
        case;                   return "unknown";
    }
}

// Directory management

// Ensure a directory exists
// Returns true if directory exists or was created successfully
ensure_directory :: (path: string) -> bool {
    path_cstr := temp_c_string(path);

    // Check if directory already exists
    attrs := GetFileAttributesA(path_cstr);
    if attrs != INVALID_FILE_ATTRIBUTES {
        // Path exists - check if it's a directory
        return (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
    }

    // Try to create the directory
    if CreateDirectoryA(path_cstr, null) {
        return true;
    }

    // Check if it was created by another process
    attrs = GetFileAttributesA(path_cstr);
    return attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
}

// Create parent directories for a path (like mkdir -p)
ensure_parent_directories :: (path: string) -> bool {
    // Find the last path separator
    last_sep := -1;
    for i: 0..path.count-1 {
        if path[i] == #char "\\" || path[i] == #char "/" {
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

// Named Mutex for single instance check (Windows-specific)
// More reliable than PID files on Windows

Windows_Single_Instance :: struct {
    mutex_handle: HANDLE;
    is_first_instance: bool;
}

// Try to acquire single instance lock
// Returns true if this is the first instance
acquire_single_instance :: () -> Windows_Single_Instance {
    result: Windows_Single_Instance;
    result.is_first_instance = false;
    result.mutex_handle = null;

    // Create a named mutex
    mutex_name := "Global\\UncrumpledContextSwitcherMutex";
    result.mutex_handle = CreateMutexA(null, 1, mutex_name.data);  // 1 = bInitialOwner

    if result.mutex_handle != null {
        last_error := GetLastError();
        if last_error == ERROR_ALREADY_EXISTS {
            // Another instance owns the mutex
            CloseHandle(result.mutex_handle);
            result.mutex_handle = null;
            result.is_first_instance = false;
        } else {
            // We got the mutex
            result.is_first_instance = true;
        }
    }

    return result;
}

// Release single instance lock
release_single_instance :: (instance: *Windows_Single_Instance) {
    if instance.mutex_handle != null {
        ReleaseMutex(instance.mutex_handle);
        CloseHandle(instance.mutex_handle);
        instance.mutex_handle = null;
    }
    instance.is_first_instance = false;
}

// Windows API type definitions and function declarations

#scope_file

// Windows type aliases
HANDLE :: *void;
DWORD :: u32;
BOOL :: s32;
LPSTR :: *u8;
LPCSTR :: *u8;

// Constants
INVALID_FILE_ATTRIBUTES :: cast(DWORD) 0xFFFFFFFF;
FILE_ATTRIBUTE_DIRECTORY :: cast(DWORD) 0x10;
ERROR_ALREADY_EXISTS :: 183;

// Service Control Manager constants
SC_MANAGER_CONNECT :: 0x0001;
SC_MANAGER_CREATE_SERVICE :: 0x0002;
SC_MANAGER_ALL_ACCESS :: 0xF003F;

SERVICE_QUERY_STATUS :: 0x0004;
SERVICE_START :: 0x0010;
SERVICE_STOP :: 0x0020;
SERVICE_ALL_ACCESS :: 0xF01FF;

// Service states
SERVICE_STOPPED :: 1;
SERVICE_START_PENDING :: 2;
SERVICE_STOP_PENDING :: 3;
SERVICE_RUNNING :: 4;
SERVICE_CONTINUE_PENDING :: 5;
SERVICE_PAUSE_PENDING :: 6;
SERVICE_PAUSED :: 7;

// SERVICE_STATUS structure
SERVICE_STATUS :: struct {
    dwServiceType: DWORD;
    dwCurrentState: DWORD;
    dwControlsAccepted: DWORD;
    dwWin32ExitCode: DWORD;
    dwServiceSpecificExitCode: DWORD;
    dwCheckPoint: DWORD;
    dwWaitHint: DWORD;
}

// Windows API functions
kernel32 :: #system_library "kernel32";
advapi32 :: #system_library "advapi32";
user32 :: #system_library "user32";

GetEnvironmentVariableA :: (lpName: LPCSTR, lpBuffer: LPSTR, nSize: DWORD) -> DWORD #foreign kernel32;
GetFileAttributesA :: (lpFileName: LPCSTR) -> DWORD #foreign kernel32;
CreateDirectoryA :: (lpPathName: LPCSTR, lpSecurityAttributes: *void) -> BOOL #foreign kernel32;
GetLastError :: () -> DWORD #foreign kernel32;
CreateMutexA :: (lpMutexAttributes: *void, bInitialOwner: BOOL, lpName: LPCSTR) -> HANDLE #foreign kernel32;
ReleaseMutex :: (hMutex: HANDLE) -> BOOL #foreign kernel32;
CloseHandle :: (hObject: HANDLE) -> BOOL #foreign kernel32;

GetConsoleWindow :: () -> HANDLE #foreign kernel32;

OpenSCManagerA :: (lpMachineName: LPCSTR, lpDatabaseName: LPCSTR, dwDesiredAccess: DWORD) -> HANDLE #foreign advapi32;
OpenServiceA :: (hSCManager: HANDLE, lpServiceName: LPCSTR, dwDesiredAccess: DWORD) -> HANDLE #foreign advapi32;
CloseServiceHandle :: (hSCObject: HANDLE) -> BOOL #foreign advapi32;
QueryServiceStatus :: (hService: HANDLE, lpServiceStatus: *SERVICE_STATUS) -> BOOL #foreign advapi32;
