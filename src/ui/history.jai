// History Manager - UI State Persistence
//
// This module manages the history of recent context selections.
// History is persisted to a JSON file in the platform-specific data directory:
// - Linux: XDG_DATA_HOME/uncrumpled-context-switcher/history.json
// - macOS: ~/Library/Application Support/uncrumpled-context-switcher/history.json
// - Windows: %LOCALAPPDATA%/uncrumpled-context-switcher/history.json

#import "Basic";
#import "String";
#import "File";
#import "Hash_Table";

// Import jason for JSON handling (uses module search paths from build.jai)
jason :: #import "jason";

// ============================================================================
// Types
// ============================================================================

// History entry representing a past context selection
History_Entry :: struct {
    // The display text shown in the UI
    text: string;

    // Optional icon identifier
    icon: string;

    // Timestamp of when this was last used (Unix epoch seconds)
    timestamp: s64;

    // How many times this has been selected
    use_count: s32;
}

// History manager configuration
History_Config :: struct {
    // Maximum number of entries to keep
    max_entries: s32 = 100;

    // Auto-save after each selection
    auto_save: bool = true;
}

// History manager state
History_Manager :: struct {
    config: History_Config;

    // List of history entries (most recent first)
    entries: [..]History_Entry;

    // Path to the history file
    history_path: string;

    // Whether changes need to be saved
    dirty: bool;

    // Whether the manager is initialized
    initialized: bool;
}

// ============================================================================
// Platform-specific paths
// ============================================================================

#if OS == .LINUX {
    #import "POSIX";

    get_env :: (name: string) -> string {
        name_z := to_c_string(name);
        defer free(name_z);
        result := getenv(name_z);
        if result == null return "";
        return to_string(result);
    }

    get_history_dir :: () -> string {
        // XDG_DATA_HOME or ~/.local/share
        xdg_data := get_env("XDG_DATA_HOME");
        if xdg_data.count > 0 {
            return tprint("%/uncrumpled-context-switcher", xdg_data);
        }

        home := get_env("HOME");
        if home.count > 0 {
            return tprint("%/.local/share/uncrumpled-context-switcher", home);
        }

        return "/tmp/uncrumpled-context-switcher";
    }
}

#if OS == .MACOS {
    #import "POSIX";

    get_env :: (name: string) -> string {
        name_z := to_c_string(name);
        defer free(name_z);
        result := getenv(name_z);
        if result == null return "";
        return to_string(result);
    }

    get_history_dir :: () -> string {
        home := get_env("HOME");
        if home.count > 0 {
            return tprint("%/Library/Application Support/uncrumpled-context-switcher", home);
        }

        return "/tmp/uncrumpled-context-switcher";
    }
}

#if OS == .WINDOWS {
    kernel32 :: #system_library "kernel32";
    GetEnvironmentVariableA :: (name: *u8, buffer: *u8, size: u32) -> u32 #foreign kernel32;

    get_env :: (name: string) -> string {
        name_z := to_c_string(name);
        defer free(name_z);

        buffer: [512]u8;
        len := GetEnvironmentVariableA(name_z, buffer.data, 512);
        if len == 0 return "";

        result: string;
        result.data = buffer.data;
        result.count = cast(s64)len;
        return copy_string(result);
    }

    get_history_dir :: () -> string {
        local_appdata := get_env("LOCALAPPDATA");
        if local_appdata.count > 0 {
            defer free(local_appdata);
            return tprint("%\\uncrumpled-context-switcher", local_appdata);
        }

        appdata := get_env("APPDATA");
        if appdata.count > 0 {
            defer free(appdata);
            return tprint("%\\uncrumpled-context-switcher", appdata);
        }

        return "C:\\ProgramData\\uncrumpled-context-switcher";
    }
}

get_history_path :: () -> string {
    dir := get_history_dir();
    // Note: dir is from tprint() or a literal, so don't free it
    #if OS == .WINDOWS {
        return tprint("%\\history.json", dir);
    } else {
        return tprint("%/history.json", dir);
    }
}

// ============================================================================
// Initialization
// ============================================================================

init_history_manager :: (config: History_Config = .{}) -> *History_Manager {
    manager := New(History_Manager);
    manager.config = config;
    manager.history_path = copy_string(get_history_path());
    manager.initialized = true;

    // Try to load existing history
    load_history(manager);

    return manager;
}

deinit_history_manager :: (manager: *History_Manager) {
    if manager == null return;

    // Save if dirty
    if manager.dirty {
        save_history(manager);
    }

    // Free entries
    for *manager.entries {
        free_history_entry(it);
    }
    array_free(manager.entries);

    // Free path
    if manager.history_path.count > 0 {
        free(manager.history_path);
    }

    free(manager);
}

free_history_entry :: (entry: *History_Entry) {
    if entry.text.count > 0 free(entry.text);
    if entry.icon.count > 0 free(entry.icon);
}

// ============================================================================
// History Operations
// ============================================================================

// Add or update an entry in the history
add_to_history :: (manager: *History_Manager, text: string, icon: string = "") {
    if manager == null || !manager.initialized return;

    // Check if entry already exists
    for *entry, idx: manager.entries {
        if entry.text == text {
            // Update existing entry
            entry.timestamp = get_current_timestamp();
            entry.use_count += 1;

            // Move to front if not already there
            if idx > 0 {
                // Shift entries down
                temp := <<entry;
                i := idx;
                while i > 0 {
                    manager.entries[i] = manager.entries[i - 1];
                    i -= 1;
                }
                manager.entries[0] = temp;
            }

            manager.dirty = true;

            if manager.config.auto_save {
                save_history(manager);
            }
            return;
        }
    }

    // Create new entry
    new_entry: History_Entry;
    new_entry.text = copy_string(text);
    new_entry.icon = copy_string(icon);
    new_entry.timestamp = get_current_timestamp();
    new_entry.use_count = 1;

    // Insert at front
    array_insert_at(*manager.entries, new_entry, 0);

    // Prune if over limit
    prune_history(manager);

    manager.dirty = true;

    if manager.config.auto_save {
        save_history(manager);
    }
}

// Remove an entry from history
remove_from_history :: (manager: *History_Manager, text: string) -> bool {
    if manager == null || !manager.initialized return false;

    for *entry, idx: manager.entries {
        if entry.text == text {
            free_history_entry(entry);
            array_ordered_remove_by_index(*manager.entries, idx);
            manager.dirty = true;

            if manager.config.auto_save {
                save_history(manager);
            }
            return true;
        }
    }

    return false;
}

// Get all history entries
get_history_entries :: (manager: *History_Manager) -> []History_Entry {
    if manager == null return .[];
    return manager.entries;
}

// Get the most recent N entries
get_recent_entries :: (manager: *History_Manager, limit: s32 = 10) -> []History_Entry {
    if manager == null return .[];

    count := min(cast(s64)limit, manager.entries.count);
    result: []History_Entry;
    result.data = manager.entries.data;
    result.count = count;
    return result;
}

// Clear all history
clear_history :: (manager: *History_Manager) {
    if manager == null return;

    for *manager.entries {
        free_history_entry(it);
    }
    array_reset_keeping_memory(*manager.entries);
    manager.dirty = true;

    if manager.config.auto_save {
        save_history(manager);
    }
}

// Prune history to max_entries
prune_history :: (manager: *History_Manager) {
    if manager == null return;

    while manager.entries.count > manager.config.max_entries {
        // Remove oldest (last) entry
        entry := *manager.entries[manager.entries.count - 1];
        free_history_entry(entry);
        array_ordered_remove_by_index(*manager.entries, manager.entries.count - 1);
    }
}

// ============================================================================
// Persistence
// ============================================================================

// Ensure the history directory exists
ensure_history_dir :: (manager: *History_Manager) -> bool {
    if manager == null return false;

    dir := get_history_dir();
    // Note: dir is from tprint(), so don't free it

    // Use make_directory_if_it_does_not_exist from File module
    return make_directory_if_it_does_not_exist(dir, recursive = true);
}

// Save history to JSON file
save_history :: (manager: *History_Manager) -> bool {
    if manager == null || !manager.initialized return false;

    // Ensure directory exists
    if !ensure_history_dir(manager) {
        print("Warning: Could not create history directory\n");
        return false;
    }

    // Build JSON string manually (simple format)
    builder: String_Builder;
    defer free_buffers(*builder);

    append(*builder, "{\n");
    append(*builder, "  \"version\": \"1.0.0\",\n");
    append(*builder, "  \"entries\": [\n");

    for entry, idx: manager.entries {
        append(*builder, "    {\n");
        append(*builder, tprint("      \"text\": \"%\",\n", escape_json_string(entry.text)));
        append(*builder, tprint("      \"icon\": \"%\",\n", escape_json_string(entry.icon)));
        append(*builder, tprint("      \"timestamp\": %,\n", entry.timestamp));
        append(*builder, tprint("      \"use_count\": %\n", entry.use_count));
        append(*builder, "    }");

        if idx < manager.entries.count - 1 {
            append(*builder, ",");
        }
        append(*builder, "\n");
    }

    append(*builder, "  ]\n");
    append(*builder, "}\n");

    json_str := builder_to_string(*builder);
    defer free(json_str);

    // Write to file
    success := write_entire_file(manager.history_path, json_str);
    if success {
        manager.dirty = false;
    } else {
        print("Warning: Could not save history to %\n", manager.history_path);
    }

    return success;
}

// Helper to get a value from a JSON object by key
get_json_value :: (obj: *jason.JSON_Object, key: string) -> *jason.JSON_Value {
    found, val := table_find(obj, key);
    if found {
        return *val;
    }
    return null;
}

// Load history from JSON file
load_history :: (manager: *History_Manager) -> bool {
    if manager == null return false;

    // Read file contents (log_errors = false because file may not exist on first run)
    contents, success := read_entire_file(manager.history_path, log_errors = false);
    if !success {
        // File doesn't exist yet - not an error
        return true;
    }
    defer free(contents);

    // Parse JSON using jason module
    parse_success, parse_result := jason.json_parse_string(contents);
    if !parse_success {
        print("Warning: Could not parse history file\n");
        return false;
    }
    defer jason.json_free(parse_result);

    // Extract entries array
    if parse_result.type != .OBJECT return false;

    entries_ptr := get_json_value(parse_result.object, "entries");
    if entries_ptr == null || entries_ptr.type != .ARRAY return false;

    // Clear existing entries
    for *manager.entries {
        free_history_entry(it);
    }
    array_reset_keeping_memory(*manager.entries);

    // Load entries
    for elem: entries_ptr.array {
        if elem.type != .OBJECT continue;

        entry: History_Entry;

        text_ptr := get_json_value(elem.object, "text");
        if text_ptr != null && text_ptr.type == .STRING {
            entry.text = copy_string(text_ptr.str);
        }

        icon_ptr := get_json_value(elem.object, "icon");
        if icon_ptr != null && icon_ptr.type == .STRING {
            entry.icon = copy_string(icon_ptr.str);
        }

        timestamp_ptr := get_json_value(elem.object, "timestamp");
        if timestamp_ptr != null && timestamp_ptr.type == .NUMBER {
            entry.timestamp = cast(s64)timestamp_ptr.number;
        }

        use_count_ptr := get_json_value(elem.object, "use_count");
        if use_count_ptr != null && use_count_ptr.type == .NUMBER {
            entry.use_count = cast(s32)use_count_ptr.number;
        }

        array_add(*manager.entries, entry);
    }

    manager.dirty = false;
    return true;
}

// ============================================================================
// Utility Functions
// ============================================================================

// Get current Unix timestamp
#if OS == .LINUX || OS == .MACOS {
    #scope_file
    libc :: #system_library "libc";
    time :: (tloc: *s64) -> s64 #foreign libc;
    #scope_export
}

#if OS == .WINDOWS {
    #scope_file
    FILETIME :: struct {
        dwLowDateTime: u32;
        dwHighDateTime: u32;
    }
    GetSystemTimeAsFileTime :: (lpSystemTimeAsFileTime: *FILETIME) #foreign kernel32;
    #scope_export
}

get_current_timestamp :: () -> s64 {
    #if OS == .LINUX || OS == .MACOS {
        return cast(s64)time(null);
    }

    #if OS == .WINDOWS {
        ft: FILETIME;
        GetSystemTimeAsFileTime(*ft);

        // Convert FILETIME to Unix timestamp
        // FILETIME is 100-nanosecond intervals since January 1, 1601
        // Unix timestamp is seconds since January 1, 1970
        li: s64 = (cast(s64)ft.dwHighDateTime << 32) | cast(s64)ft.dwLowDateTime;
        return (li - 116444736000000000) / 10000000;
    }
}

// Escape a string for JSON output
escape_json_string :: (s: string) -> string {
    builder: String_Builder;

    for i: 0..s.count-1 {
        c := s[i];
        if c == {
            case #char "\""; append(*builder, "\\\"");
            case #char "\\"; append(*builder, "\\\\");
            case #char "\n"; append(*builder, "\\n");
            case #char "\r"; append(*builder, "\\r");
            case #char "\t"; append(*builder, "\\t");
            case;
                if c < 32 {
                    // Control character - escape as \uXXXX
                    append(*builder, tprint("\\u%", formatInt(c, base=16, minimum_digits=4)));
                } else {
                    append(*builder, c);
                }
        }
    }

    return builder_to_string(*builder);
}

// Convert history entries to Search_Item array for UI display
// Caller must free the returned array
history_to_search_items :: (manager: *History_Manager) -> [..]Search_Item {
    items: [..]Search_Item;

    if manager == null return items;

    for entry: manager.entries {
        item: Search_Item;
        item.text = entry.text;  // Note: not copying - caller should not free individual items
        item.icon = entry.icon;
        array_add(*items, item);
    }

    return items;
}
