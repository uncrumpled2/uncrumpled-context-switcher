// Hotkey Manager
//
// This module handles global system hotkey registration for the UI.
// It loads configuration from the TOML config file and registers
// hotkeys using the jai-system-hotkey module.

// Note: Basic is already imported by main.jai
#import "String";
system_hotkey :: #import "jai-system-hotkey";

// Import config parser for loading hotkey settings
config_parser :: #import,dir "../daemon/config";

// ============================================================================
// Hotkey Manager Types
// ============================================================================

Hotkey_Manager :: struct {
    // System hotkey context from jai-system-hotkey
    hotkey_ctx: *system_hotkey.System_Hotkey_Context;

    // Currently registered hotkey (if any)
    registered_hotkey: system_hotkey.Hotkey;
    hotkey_registered: bool;

    // Configuration
    config: config_parser.Hotkey_Config;
    config_loaded: bool;

    // State
    toggle_requested: bool;  // Set to true when hotkey is pressed

    // Error tracking
    last_error: string;
    has_error: bool;
}

// ============================================================================
// Initialization and Cleanup
// ============================================================================

// Initialize the hotkey manager
init_hotkey_manager :: () -> *Hotkey_Manager {
    manager := New(Hotkey_Manager);

    // Initialize the system hotkey context
    manager.hotkey_ctx = system_hotkey.init(verbose = false);
    if manager.hotkey_ctx == null {
        manager.has_error = true;
        manager.last_error = copy_string("Failed to initialize system hotkey context");
        return manager;
    }

    return manager;
}

// Shutdown the hotkey manager
deinit_hotkey_manager :: (manager: *Hotkey_Manager) {
    if manager == null return;

    // Unregister any registered hotkey
    if manager.hotkey_registered {
        unregister_ui_hotkey(manager);
    }

    // Shutdown the system hotkey context
    if manager.hotkey_ctx != null {
        system_hotkey.shutdown(manager.hotkey_ctx);
    }

    // Free config strings
    if manager.config.key.count > 0 free(manager.config.key);
    if manager.config.modifiers.count > 0 free(manager.config.modifiers);
    if manager.last_error.count > 0 free(manager.last_error);

    free(manager);
}

// ============================================================================
// Configuration Loading
// ============================================================================

// Load hotkey configuration from the default config file
load_hotkey_config :: (manager: *Hotkey_Manager) -> bool {
    if manager == null return false;

    // Determine config path based on platform
    config_path := get_config_path();
    defer free(config_path);

    // Try to load config file
    user_config, success := config_parser.parse_config_file(config_path);
    defer config_parser.free_user_config(*user_config);

    if !success {
        // No config file or parse error - use defaults
        manager.config.enabled = true;
        manager.config.key = copy_string("P");
        manager.config.modifiers = copy_string("Ctrl+Alt");
        manager.config_loaded = true;
        return true;
    }

    // Copy hotkey config
    manager.config.enabled = user_config.hotkey.enabled;
    manager.config.key = copy_string(user_config.hotkey.key);
    manager.config.modifiers = copy_string(user_config.hotkey.modifiers);
    manager.config_loaded = true;

    return true;
}

// Get the config file path based on platform
get_config_path :: () -> string {
    #if OS == .LINUX {
        // Follow XDG Base Directory specification
        xdg_config_home := config_parser.get_home_directory();
        if xdg_config_home.count > 0 {
            return copy_string(tprint("%/.config/uncrumpled/config.toml", xdg_config_home));
        }
        return copy_string("~/.config/uncrumpled/config.toml");
    } else #if OS == .MACOS {
        // Use ~/Library/Application Support/uncrumpled/
        home := config_parser.get_home_directory();
        if home.count > 0 {
            return copy_string(tprint("%/Library/Application Support/uncrumpled/config.toml", home));
        }
        return copy_string("~/Library/Application Support/uncrumpled/config.toml");
    } else #if OS == .WINDOWS {
        // Use %APPDATA%\uncrumpled\
        // For now, fallback to home directory approach
        return copy_string("%APPDATA%\\uncrumpled\\config.toml");
    } else {
        return copy_string("~/.config/uncrumpled/config.toml");
    }
}

// ============================================================================
// Hotkey Registration
// ============================================================================

// Register the UI toggle hotkey
register_ui_hotkey :: (manager: *Hotkey_Manager) -> bool {
    if manager == null return false;
    if manager.hotkey_ctx == null return false;
    if !manager.config.enabled return true;  // Disabled is not an error

    // Parse the hotkey configuration
    hotkey, success := parse_hotkey_config(*manager.config);
    if !success {
        manager.has_error = true;
        manager.last_error = copy_string(tprint("Failed to parse hotkey: %+%",
                                                 manager.config.modifiers, manager.config.key));
        return false;
    }

    // Try to register the hotkey
    if !system_hotkey.register_hotkey(manager.hotkey_ctx, hotkey, hotkey_callback, manager) {
        manager.has_error = true;
        manager.last_error = copy_string(tprint("Failed to register hotkey: %+% (may be in use by another application)",
                                                 manager.config.modifiers, manager.config.key));
        return false;
    }

    manager.registered_hotkey = hotkey;
    manager.hotkey_registered = true;
    manager.has_error = false;

    return true;
}

// Unregister the UI toggle hotkey
unregister_ui_hotkey :: (manager: *Hotkey_Manager) -> bool {
    if manager == null return false;
    if manager.hotkey_ctx == null return false;
    if !manager.hotkey_registered return true;

    if !system_hotkey.unregister_hotkey(manager.hotkey_ctx, manager.registered_hotkey) {
        return false;
    }

    manager.hotkey_registered = false;
    return true;
}

// Callback function called when the hotkey is pressed
hotkey_callback :: (hotkey: system_hotkey.Hotkey, user_data: *void) {
    manager := cast(*Hotkey_Manager) user_data;
    if manager != null {
        manager.toggle_requested = true;
    }
}

// ============================================================================
// Event Polling
// ============================================================================

// Poll for hotkey events (call this in the main loop)
poll_hotkey_events :: (manager: *Hotkey_Manager) {
    if manager == null return;
    if manager.hotkey_ctx == null return;

    system_hotkey.poll_events(manager.hotkey_ctx);
}

// Check if a toggle was requested (and clear the flag)
check_toggle_requested :: (manager: *Hotkey_Manager) -> bool {
    if manager == null return false;

    if manager.toggle_requested {
        manager.toggle_requested = false;
        return true;
    }
    return false;
}

// ============================================================================
// Utility Functions
// ============================================================================

// Parse hotkey configuration into a Hotkey struct
parse_hotkey_config :: (config: *config_parser.Hotkey_Config) -> system_hotkey.Hotkey, bool {
    hotkey: system_hotkey.Hotkey;

    // Parse modifiers
    hotkey.modifiers = parse_modifiers(config.modifiers);

    // Parse key
    key, success := parse_key(config.key);
    if !success {
        return hotkey, false;
    }
    hotkey.key = key;

    return hotkey, true;
}

// Parse modifier string (e.g., "Ctrl+Alt", "Ctrl+Shift", "Super")
parse_modifiers :: (modifiers_str: string) -> system_hotkey.Hotkey_Modifier {
    result: system_hotkey.Hotkey_Modifier = .NONE;

    if modifiers_str.count == 0 return result;

    // Split by + and parse each modifier
    upper := to_upper_copy(modifiers_str);
    defer free(upper);

    if contains(upper, "CTRL") || contains(upper, "CONTROL") {
        result |= .CONTROL;
    }
    if contains(upper, "SHIFT") {
        result |= .SHIFT;
    }
    if contains(upper, "ALT") {
        result |= .ALT;
    }
    if contains(upper, "SUPER") || contains(upper, "WIN") || contains(upper, "CMD") || contains(upper, "COMMAND") || contains(upper, "META") {
        result |= .SUPER;
    }

    return result;
}

// Parse key name to Key enum
parse_key :: (key_str: string) -> system_hotkey.Key, bool {
    if key_str.count == 0 return .A, false;

    upper := to_upper_copy(key_str);
    defer free(upper);

    // Single letter keys
    if upper.count == 1 {
        c := upper[0];
        if c >= #char "A" && c <= #char "Z" {
            // Map 'A' to Key.A, 'B' to Key.B, etc.
            offset := c - #char "A";
            return cast(system_hotkey.Key) offset, true;
        }
        if c >= #char "0" && c <= #char "9" {
            // Map '0' to Key.NUM_0, etc.
            offset := c - #char "0";
            return cast(system_hotkey.Key) (cast(s32) system_hotkey.Key.NUM_0 + offset), true;
        }
    }

    // Named keys
    if upper == "SPACE"  return .SPACE, true;
    if upper == "ENTER"  return .ENTER, true;
    if upper == "RETURN" return .ENTER, true;
    if upper == "ESCAPE" return .ESCAPE, true;
    if upper == "ESC"    return .ESCAPE, true;
    if upper == "TAB"    return .TAB, true;
    if upper == "UP"     return .UP, true;
    if upper == "DOWN"   return .DOWN, true;
    if upper == "LEFT"   return .LEFT, true;
    if upper == "RIGHT"  return .RIGHT, true;

    // Function keys
    if upper == "F1"  return .F1, true;
    if upper == "F2"  return .F2, true;
    if upper == "F3"  return .F3, true;
    if upper == "F4"  return .F4, true;
    if upper == "F5"  return .F5, true;
    if upper == "F6"  return .F6, true;
    if upper == "F7"  return .F7, true;
    if upper == "F8"  return .F8, true;
    if upper == "F9"  return .F9, true;
    if upper == "F10" return .F10, true;
    if upper == "F11" return .F11, true;
    if upper == "F12" return .F12, true;

    return .A, false;
}

// Get the current hotkey as a display string
get_hotkey_display_string :: (manager: *Hotkey_Manager) -> string {
    if manager == null return copy_string("(not configured)");
    if !manager.config.enabled return copy_string("(disabled)");
    if manager.config.modifiers.count == 0 return copy_string(manager.config.key);
    return copy_string(tprint("%+%", manager.config.modifiers, manager.config.key));
}

// Check if there's an error
has_hotkey_error :: (manager: *Hotkey_Manager) -> bool {
    if manager == null return true;
    return manager.has_error;
}

// Get the last error message
get_hotkey_error :: (manager: *Hotkey_Manager) -> string {
    if manager == null return "Hotkey manager is null";
    if !manager.has_error return "";
    return manager.last_error;
}
