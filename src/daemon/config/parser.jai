// Configuration File Parser
//
// This module parses the TOML configuration file for the Uncrumpled daemon.
// The config file defines allowed values, tag definitions, parameter schemas,
// and daemon settings.
//
// Config file location: ~/.config/uncrumpled-context-switcher/config.toml

#import "Basic";
#import "String";
#import "File";
#if OS == .LINUX || OS == .MACOS {
    #import "POSIX";
}
toml :: #import,dir "../../../modules/jai-toml-c";

// ============================================================================
// Configuration Data Structures
// ============================================================================

// Root configuration structure
User_Config :: struct {
    // Context validation settings
    context_rules: Context_Config;

    // Tag definitions
    tags: Tags_Config;

    // Parameter definitions
    params: Params_Config;

    // Daemon settings
    daemon: Daemon_Settings;

    // Hotkey settings
    hotkey: Hotkey_Config;

    // Parsing state
    has_error: bool;
    error_message: string;
    source_path: string;  // Path to the config file that was loaded
}

// Context validation configuration
Context_Config :: struct {
    allowed_projects:     [..] string;  // Regex patterns for valid project IDs
    allowed_profiles:     [..] string;  // List of valid profile names
    allowed_environments: [..] string;  // List of valid environment names
}

// Tags configuration section
Tags_Config :: struct {
    definitions: [..] Tag_Definition;
}

// A single tag definition
Tag_Definition :: struct {
    name:           string;       // Tag name (e.g., "--work")
    description:    string;       // Human-readable description
    conflicts_with: [..] string;  // Tags that conflict with this one
}

// Parameters configuration section
Params_Config :: struct {
    definitions: [..] Param_Definition;
}

// Parameter type enum
Param_Type :: enum {
    STRING;
    INT;
    BOOL;
    FLOAT;
    ENUM;
}

// A single parameter definition
Param_Definition :: struct {
    name:          string;        // Parameter name
    param_type:    Param_Type;    // Type of the parameter
    description:   string;        // Human-readable description
    default_value: string;        // Default value as string
    values:        [..] string;   // For enum type: allowed values
    required:      bool;          // Whether the parameter is required
}

// Daemon runtime settings
Daemon_Settings :: struct {
    socket_path:               string;
    heartbeat_interval_seconds: s64;
    subscriber_timeout_seconds: s64;
    max_log_entries:           s64;
    log_level:                 string;  // "debug", "info", "warn", "error"
}

// Hotkey configuration
Hotkey_Config :: struct {
    enabled:   bool;    // Whether hotkey is enabled
    key:       string;  // Key name (e.g., "P", "Space", "F12")
    modifiers: string;  // Modifier string (e.g., "Ctrl+Alt", "Ctrl+Shift")
}

// Preset hotkey options for install scripts
Hotkey_Preset :: enum {
    NONE;              // No hotkey
    CTRL_ALT_P;        // Ctrl+Alt+P (default)
    CTRL_SHIFT_SPACE;  // Ctrl+Shift+Space
    SUPER_P;           // Super/Windows+P
    F12;               // F12 key alone
    CUSTOM;            // Custom user-defined
}

// ============================================================================
// Default Configuration
// ============================================================================

// Create a configuration with sensible defaults
create_default_config :: () -> User_Config {
    config: User_Config;

    // Default context settings - allow everything
    array_add(*config.context_rules.allowed_projects, copy_string(".*"));
    array_add(*config.context_rules.allowed_profiles, copy_string("default"));
    array_add(*config.context_rules.allowed_environments, copy_string("dev"));
    array_add(*config.context_rules.allowed_environments, copy_string("staging"));
    array_add(*config.context_rules.allowed_environments, copy_string("prod"));
    array_add(*config.context_rules.allowed_environments, copy_string("local"));

    // Default daemon settings
    #if OS == .LINUX || OS == .MACOS {
        config.daemon.socket_path = copy_string("/tmp/uncrumpled.sock");
    } else {
        config.daemon.socket_path = copy_string("\\\\.\\pipe\\uncrumpled-context");
    }
    config.daemon.heartbeat_interval_seconds = 30;
    config.daemon.subscriber_timeout_seconds = 90;
    config.daemon.max_log_entries = 1000;
    config.daemon.log_level = copy_string("info");

    // Default hotkey settings - Ctrl+Alt+P
    config.hotkey.enabled = true;
    config.hotkey.key = copy_string("P");
    config.hotkey.modifiers = copy_string("Ctrl+Alt");

    return config;
}

// ============================================================================
// TOML Parsing
// ============================================================================

// Parse a configuration file from a path
parse_config_file :: (path: string) -> User_Config, bool {
    config := create_default_config();
    config.source_path = copy_string(path);

    // Expand ~ to home directory
    expanded_path := expand_path(path);
    defer if expanded_path.data != path.data free(expanded_path);

    // Read file contents
    contents, success := read_entire_file(expanded_path);
    if !success {
        config.has_error = true;
        config.error_message = copy_string(tprint("Failed to read config file: %", expanded_path));
        return config, false;
    }
    defer free(contents);

    result, success2 := parse_config_string(contents, config);
    return result, success2;
}

// Parse configuration from a TOML string
parse_config_string :: (toml_content: string, config: User_Config = .{}) -> User_Config, bool {
    result := config;

    // Parse TOML
    table, success, error := toml.parse(toml_content);
    if !success {
        result.has_error = true;
        result.error_message = copy_string(tprint("TOML parse error: %", error));
        return result, false;
    }
    defer toml.free_table(table);

    // Parse [context] section
    parse_context_section(table, *result);

    // Parse [tags] section
    parse_tags_section(table, *result);

    // Parse [params] section
    parse_params_section(table, *result);

    // Parse [daemon] section
    parse_daemon_section(table, *result);

    // Parse [hotkey] section
    parse_hotkey_section(table, *result);

    return result, !result.has_error;
}

// ============================================================================
// Section Parsers
// ============================================================================

#scope_file

parse_context_section :: (root: *toml.Toml_Table, config: *User_Config) {
    ctx := toml.get_table(root, "context");
    if ctx == null return;

    // Parse allowed_projects array
    projects := toml.get_array(ctx, "allowed_projects");
    if projects != null {
        // Clear defaults if config provides values
        array_reset(*config.context_rules.allowed_projects);

        len := toml.array_len(projects);
        for i: 0..len-1 {
            val, ok := toml.array_get_string(projects, i);
            if ok {
                array_add(*config.context_rules.allowed_projects, copy_string(val));
            }
        }
    }

    // Parse allowed_profiles array
    profiles := toml.get_array(ctx, "allowed_profiles");
    if profiles != null {
        array_reset(*config.context_rules.allowed_profiles);

        len := toml.array_len(profiles);
        for i: 0..len-1 {
            val, ok := toml.array_get_string(profiles, i);
            if ok {
                array_add(*config.context_rules.allowed_profiles, copy_string(val));
            }
        }
    }

    // Parse allowed_environments array
    envs := toml.get_array(ctx, "allowed_environments");
    if envs != null {
        array_reset(*config.context_rules.allowed_environments);

        len := toml.array_len(envs);
        for i: 0..len-1 {
            val, ok := toml.array_get_string(envs, i);
            if ok {
                array_add(*config.context_rules.allowed_environments, copy_string(val));
            }
        }
    }
}

parse_tags_section :: (root: *toml.Toml_Table, config: *User_Config) {
    tags_table := toml.get_table(root, "tags");
    if tags_table == null return;

    // Parse [[tags.definitions]] array of tables
    definitions := toml.get_array(tags_table, "definitions");
    if definitions == null return;

    len := toml.array_len(definitions);
    for i: 0..len-1 {
        def_table := toml.array_get_table(definitions, i);
        if def_table == null continue;

        tag_def: Tag_Definition;

        name, name_ok := toml.get_string(def_table, "name");
        if name_ok {
            tag_def.name = copy_string(name);
        }

        desc, desc_ok := toml.get_string(def_table, "description");
        if desc_ok {
            tag_def.description = copy_string(desc);
        }

        // Parse conflicts_with array
        conflicts := toml.get_array(def_table, "conflicts_with");
        if conflicts != null {
            conflict_len := toml.array_len(conflicts);
            for j: 0..conflict_len-1 {
                conflict, ok := toml.array_get_string(conflicts, j);
                if ok {
                    array_add(*tag_def.conflicts_with, copy_string(conflict));
                }
            }
        }

        array_add(*config.tags.definitions, tag_def);
    }
}

parse_params_section :: (root: *toml.Toml_Table, config: *User_Config) {
    params_table := toml.get_table(root, "params");
    if params_table == null return;

    // Parse [[params.definitions]] array of tables
    definitions := toml.get_array(params_table, "definitions");
    if definitions == null return;

    len := toml.array_len(definitions);
    for i: 0..len-1 {
        def_table := toml.array_get_table(definitions, i);
        if def_table == null continue;

        param_def: Param_Definition;

        name, name_ok := toml.get_string(def_table, "name");
        if name_ok {
            param_def.name = copy_string(name);
        }

        desc, desc_ok := toml.get_string(def_table, "description");
        if desc_ok {
            param_def.description = copy_string(desc);
        }

        // Parse type
        type_str, type_ok := toml.get_string(def_table, "type");
        if type_ok {
            param_def.param_type = string_to_param_type(type_str);
        }

        // Parse default value (can be string, bool, or int)
        default_str, default_str_ok := toml.get_string(def_table, "default");
        if default_str_ok {
            param_def.default_value = copy_string(default_str);
        } else {
            default_bool, default_bool_ok := toml.get_bool(def_table, "default");
            if default_bool_ok {
                param_def.default_value = copy_string(ifx default_bool then "true" else "false");
            } else {
                default_int, default_int_ok := toml.get_int(def_table, "default");
                if default_int_ok {
                    param_def.default_value = copy_string(tprint("%", default_int));
                }
            }
        }

        // Parse required flag
        required, required_ok := toml.get_bool(def_table, "required");
        if required_ok {
            param_def.required = required;
        }

        // Parse enum values array
        values := toml.get_array(def_table, "values");
        if values != null {
            values_len := toml.array_len(values);
            for j: 0..values_len-1 {
                val, ok := toml.array_get_string(values, j);
                if ok {
                    array_add(*param_def.values, copy_string(val));
                }
            }
        }

        array_add(*config.params.definitions, param_def);
    }
}

parse_daemon_section :: (root: *toml.Toml_Table, config: *User_Config) {
    daemon := toml.get_table(root, "daemon");
    if daemon == null return;

    socket, socket_ok := toml.get_string(daemon, "socket_path");
    if socket_ok {
        free(config.daemon.socket_path);
        config.daemon.socket_path = copy_string(socket);
    }

    heartbeat, heartbeat_ok := toml.get_int(daemon, "heartbeat_interval_seconds");
    if heartbeat_ok {
        config.daemon.heartbeat_interval_seconds = heartbeat;
    }

    timeout, timeout_ok := toml.get_int(daemon, "subscriber_timeout_seconds");
    if timeout_ok {
        config.daemon.subscriber_timeout_seconds = timeout;
    }

    max_logs, max_logs_ok := toml.get_int(daemon, "max_log_entries");
    if max_logs_ok {
        config.daemon.max_log_entries = max_logs;
    }

    log_level, log_level_ok := toml.get_string(daemon, "log_level");
    if log_level_ok {
        free(config.daemon.log_level);
        config.daemon.log_level = copy_string(log_level);
    }
}

parse_hotkey_section :: (root: *toml.Toml_Table, config: *User_Config) {
    hotkey := toml.get_table(root, "hotkey");
    if hotkey == null return;

    enabled, enabled_ok := toml.get_bool(hotkey, "enabled");
    if enabled_ok {
        config.hotkey.enabled = enabled;
    }

    key, key_ok := toml.get_string(hotkey, "key");
    if key_ok {
        free(config.hotkey.key);
        config.hotkey.key = copy_string(key);
    }

    modifiers, modifiers_ok := toml.get_string(hotkey, "modifiers");
    if modifiers_ok {
        free(config.hotkey.modifiers);
        config.hotkey.modifiers = copy_string(modifiers);
    }
}

// ============================================================================
// Utility Functions
// ============================================================================

string_to_param_type :: (s: string) -> Param_Type {
    if s == "string" return .STRING;
    if s == "int"    return .INT;
    if s == "bool"   return .BOOL;
    if s == "float"  return .FLOAT;
    if s == "enum"   return .ENUM;
    return .STRING;  // Default
}

#scope_export

param_type_to_string :: (t: Param_Type) -> string {
    if t == {
        case .STRING; return "string";
        case .INT;    return "int";
        case .BOOL;   return "bool";
        case .FLOAT;  return "float";
        case .ENUM;   return "enum";
    }
    return "string";
}

expand_path :: (path: string) -> string {
    if path.count == 0 return path;

    // Expand ~ to home directory
    if path[0] == #char "~" {
        home := get_home_directory();
        if home.count > 0 {
            if path.count == 1 {
                return copy_string(home);
            } else if path[1] == #char "/" {
                return copy_string(tprint("%/%", home, advance(path, 2)));
            }
        }
    }

    #if OS == .WINDOWS {
        // Expand Windows environment variables like %APPDATA%
        if path.count > 2 && path[0] == #char "%" {
            // Find closing %
            end_idx := -1;
            for i: 1..path.count-1 {
                if path[i] == #char "%" {
                    end_idx = i;
                    break;
                }
            }
            if end_idx > 1 {
                var_name: string;
                var_name.data = path.data + 1;
                var_name.count = end_idx - 1;

                var_value := get_env_windows(var_name);
                if var_value.count > 0 {
                    defer free(var_value);
                    rest := advance(path, end_idx + 1);
                    return copy_string(tprint("%1%2", var_value, rest));
                }
            }
        }
    }

    return copy_string(path);
}

get_home_directory :: () -> string {
    #if OS == .LINUX || OS == .MACOS {
        home_ptr := getenv("HOME");
        if home_ptr != null {
            return to_string(home_ptr);
        }
        return "";
    } else {
        // Windows - use USERPROFILE
        return get_env_windows("USERPROFILE");
    }
}

#if OS == .WINDOWS {
    #scope_file
    kernel32_config :: #system_library "kernel32";
    GetEnvironmentVariableA :: (lpName: *u8, lpBuffer: *u8, nSize: u32) -> u32 #foreign kernel32_config;
    #scope_export

    get_env_windows :: (name: string) -> string {
        name_cstr := to_c_string(name);
        defer free(name_cstr);

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
}


// ============================================================================
// Memory Management
// ============================================================================

free_tag_definition :: (tag: *Tag_Definition) {
    free(tag.name);
    free(tag.description);
    for tag.conflicts_with free(it);
    array_free(tag.conflicts_with);
}

free_param_definition :: (param: *Param_Definition) {
    free(param.name);
    free(param.description);
    free(param.default_value);
    for param.values free(it);
    array_free(param.values);
}

free_user_config :: (config: *User_Config) {
    // Free context arrays
    for config.context_rules.allowed_projects free(it);
    array_free(config.context_rules.allowed_projects);

    for config.context_rules.allowed_profiles free(it);
    array_free(config.context_rules.allowed_profiles);

    for config.context_rules.allowed_environments free(it);
    array_free(config.context_rules.allowed_environments);

    // Free tag definitions
    for *config.tags.definitions {
        free_tag_definition(it);
    }
    array_free(config.tags.definitions);

    // Free param definitions
    for *config.params.definitions {
        free_param_definition(it);
    }
    array_free(config.params.definitions);

    // Free daemon settings
    if config.daemon.socket_path.count > 0 free(config.daemon.socket_path);
    if config.daemon.log_level.count > 0 free(config.daemon.log_level);

    // Free hotkey settings
    if config.hotkey.key.count > 0 free(config.hotkey.key);
    if config.hotkey.modifiers.count > 0 free(config.hotkey.modifiers);

    // Free error message and source path
    if config.error_message.count > 0 free(config.error_message);
    if config.source_path.count > 0 free(config.source_path);
}

// ============================================================================
// Validation Helpers
// ============================================================================

// Check if a profile is allowed by the configuration
is_profile_allowed :: (config: *User_Config, profile: string) -> bool {
    if config.context_rules.allowed_profiles.count == 0 return true;

    for config.context_rules.allowed_profiles {
        if it == profile return true;
    }
    return false;
}

// Check if an environment is allowed by the configuration
is_environment_allowed :: (config: *User_Config, env: string) -> bool {
    if config.context_rules.allowed_environments.count == 0 return true;

    for config.context_rules.allowed_environments {
        if it == env return true;
    }
    return false;
}

// Check if two tags conflict
tags_conflict :: (config: *User_Config, tag1: string, tag2: string) -> bool {
    for *config.tags.definitions {
        if it.name == tag1 {
            for it.conflicts_with {
                if it == tag2 return true;
            }
        }
        if it.name == tag2 {
            for it.conflicts_with {
                if it == tag1 return true;
            }
        }
    }
    return false;
}

// Get a tag definition by name
get_tag_definition :: (config: *User_Config, name: string) -> *Tag_Definition {
    for *config.tags.definitions {
        if it.name == name return it;
    }
    return null;
}

// Get a param definition by name
get_param_definition :: (config: *User_Config, name: string) -> *Param_Definition {
    for *config.params.definitions {
        if it.name == name return it;
    }
    return null;
}

// Validate a parameter value against its definition
validate_param_value :: (config: *User_Config, name: string, value: string) -> bool, string {
    def := get_param_definition(config, name);
    if def == null return true, "";  // Unknown params are allowed

    if def.param_type == {
        case .BOOL;
            if value != "true" && value != "false" {
                return false, tprint("Parameter '%' must be 'true' or 'false', got '%'", name, value);
            }

        case .INT;
            // Try to parse as int
            val, success, _ := string_to_int(value);
            if !success {
                return false, tprint("Parameter '%' must be an integer, got '%'", name, value);
            }

        case .FLOAT;
            // Try to parse as float
            val, success, _ := string_to_float(value);
            if !success {
                return false, tprint("Parameter '%' must be a number, got '%'", name, value);
            }

        case .ENUM;
            if def.values.count > 0 {
                found := false;
                for def.values {
                    if it == value {
                        found = true;
                        break;
                    }
                }
                if !found {
                    return false, tprint("Parameter '%' must be one of %, got '%'", name, def.values, value);
                }
            }

        case .STRING;
            // Strings are always valid
    }

    return true, "";
}

// ============================================================================
// File Loading Helpers
// ============================================================================

// Load user config from the default location
load_user_config :: () -> User_Config, bool {
    #if OS == .LINUX || OS == .MACOS {
        default_path :: "~/.config/uncrumpled-context-switcher/config.toml";
    } else {
        default_path :: "%APPDATA%\\uncrumpled-context-switcher\\config.toml";
    }

    config, success := parse_config_file(default_path);
    return config, success;
}

// Load config from a specific path, falling back to defaults if not found
load_config_or_default :: (path: string) -> User_Config {
    config, success := parse_config_file(path);
    if success return config;

    // If file doesn't exist, return defaults without error
    if begins_with(config.error_message, "Failed to read config file") {
        free_user_config(*config);
        return create_default_config();
    }

    // For other errors (like parse errors), keep the error
    return config;
}

// ============================================================================
// Hotkey Preset Helpers
// ============================================================================

// Get hotkey config from a preset
get_hotkey_from_preset :: (preset: Hotkey_Preset) -> Hotkey_Config {
    config: Hotkey_Config;

    if preset == {
        case .NONE;
            config.enabled = false;
            config.key = copy_string("");
            config.modifiers = copy_string("");

        case .CTRL_ALT_P;
            config.enabled = true;
            config.key = copy_string("P");
            config.modifiers = copy_string("Ctrl+Alt");

        case .CTRL_SHIFT_SPACE;
            config.enabled = true;
            config.key = copy_string("Space");
            config.modifiers = copy_string("Ctrl+Shift");

        case .SUPER_P;
            config.enabled = true;
            config.key = copy_string("P");
            config.modifiers = copy_string("Super");

        case .F12;
            config.enabled = true;
            config.key = copy_string("F12");
            config.modifiers = copy_string("");

        case .CUSTOM;
            // Custom requires manual configuration
            config.enabled = true;
            config.key = copy_string("");
            config.modifiers = copy_string("");
    }

    return config;
}

// Convert a preset to a display string (for install script prompts)
hotkey_preset_to_display :: (preset: Hotkey_Preset) -> string {
    if preset == {
        case .NONE;              return "None (disable hotkey)";
        case .CTRL_ALT_P;        return "Ctrl+Alt+P";
        case .CTRL_SHIFT_SPACE;  return "Ctrl+Shift+Space";
        case .SUPER_P;           return "Super+P (Windows/Command+P)";
        case .F12;               return "F12";
        case .CUSTOM;            return "Custom (configure in config.toml)";
    }
    return "Unknown";
}

// Convert a display string to preset enum
display_to_hotkey_preset :: (display: string) -> Hotkey_Preset {
    if display == "None (disable hotkey)"           return .NONE;
    if display == "Ctrl+Alt+P"                      return .CTRL_ALT_P;
    if display == "Ctrl+Shift+Space"                return .CTRL_SHIFT_SPACE;
    if display == "Super+P (Windows/Command+P)"     return .SUPER_P;
    if display == "F12"                             return .F12;
    if display == "Custom (configure in config.toml)" return .CUSTOM;
    return .CTRL_ALT_P;  // Default
}

// Get hotkey config as TOML section string (for config file generation)
hotkey_config_to_toml :: (config: *Hotkey_Config) -> string {
    if !config.enabled {
        return copy_string("[hotkey]\nenabled = false\n");
    }

    return copy_string(tprint(#string END
[hotkey]
enabled = true
key = "%"
modifiers = "%"
END
        , config.key, config.modifiers));
}

// Get the full hotkey as a human-readable string
hotkey_config_to_string :: (config: *Hotkey_Config) -> string {
    if !config.enabled return copy_string("(disabled)");
    if config.modifiers.count == 0 return copy_string(config.key);
    return copy_string(tprint("%+%", config.modifiers, config.key));
}
