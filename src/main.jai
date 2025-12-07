#import "Basic";
#import "SDL";
#import "String";
skia :: #import "skia";

#if OS == .WINDOWS {
    #import "Windows";
}

#load "util/types.jai";
#load "util/fuzzy.jai";
#load "ui/window.jai";
#load "ui/renderer.jai";
#load "ui/theme.jai";
#load "ui/animation.jai";
#load "ui/widgets.jai";
#load "ui/search_box.jai";
#load "ui/results_list.jai";
#load "ui/history.jai";
#load "ui/dialog.jai";
#load "hotkey/hotkey_manager.jai";
#load "sdk/client.jai";

// Global data for UI
search_items: [..]Search_Item;
history_manager: *History_Manager;

// Global SDK client for daemon communication
sdk_client: Service_Client;
sdk_connected: bool = false;

// Daemon executable name
#if OS == .WINDOWS {
    DAEMON_EXECUTABLE :: "uncrumpled-context-switcher-daemon.exe";

    // Windows constants not in Jai's Windows module
    STARTF_USESHOWWINDOW : s32 : 0x00000001;
} else {
    DAEMON_EXECUTABLE :: "uncrumpled-context-switcher-daemon";
}

// Try to connect to daemon, spawning it if necessary
// Returns true if connected successfully, false otherwise
connect_to_daemon :: () -> bool {
    // Initialize SDK client
    if !init_service_client(*sdk_client) {
        print("Failed to initialize SDK client\n");
        return false;
    }

    // Try to connect
    if connect(*sdk_client) {
        print("Connected to daemon\n");
        return true;
    }

    print("Daemon not running, attempting to start...\n");

    // Spawn daemon process
    if !spawn_daemon() {
        print("Failed to spawn daemon\n");
        return false;
    }

    // Retry connection with timeout (2 seconds, 10 attempts at 200ms each)
    MAX_RETRIES :: 10;
    RETRY_DELAY_MS :: 200;

    for attempt: 0..MAX_RETRIES-1 {
        sleep_milliseconds(RETRY_DELAY_MS);

        if connect(*sdk_client) {
            print("Connected to daemon after % attempts\n", attempt + 1);
            return true;
        }
    }

    print("Failed to connect to daemon after % attempts\n", MAX_RETRIES);
    return false;
}

// Spawn the daemon process
spawn_daemon :: () -> bool {
    // Get path to daemon executable (same directory as UI executable)
    daemon_path := get_daemon_path();
    defer free(daemon_path);

    if daemon_path.count == 0 {
        print("Could not determine daemon path\n");
        return false;
    }

    print("Spawning daemon: %\n", daemon_path);

    #if OS == .WINDOWS {
        // Use CreateProcess on Windows
        startup_info: STARTUPINFOA;
        startup_info.cb = size_of(STARTUPINFOA);
        startup_info.dwFlags = STARTF_USESHOWWINDOW;
        startup_info.wShowWindow = SW_HIDE;  // Hide the daemon window

        process_info: PROCESS_INFORMATION;

        path_cstr := to_c_string(daemon_path);
        defer free(path_cstr);

        success := CreateProcessA(
            path_cstr,      // Application name
            null,           // Command line
            null,           // Process security attributes
            null,           // Thread security attributes
            .FALSE,         // Inherit handles
            .CREATE_NEW_PROCESS_GROUP | .DETACHED_PROCESS,  // Creation flags
            null,           // Environment
            null,           // Current directory
            *startup_info,
            *process_info
        );

        if !success {
            error_code := GetLastError();
            print("CreateProcess failed with error: %\n", error_code);
            return false;
        }

        // Close handles - we don't need to track the process
        CloseHandle(process_info.hProcess);
        CloseHandle(process_info.hThread);

        return true;
    } else {
        // Use fork/exec on Unix
        // For now, use system() as a simple fallback
        // In production, would use fork() + execv()
        command := tprint("% &", daemon_path);
        result := system(temp_c_string(command));
        return result == 0;
    }
}

// Get path to daemon executable
get_daemon_path :: () -> string {
    #if OS == .WINDOWS {
        // Get path of current executable
        buffer: [MAX_PATH] u8;
        length := GetModuleFileNameA(null, buffer.data, MAX_PATH);

        if length == 0 {
            return "";
        }

        exe_path := string.{cast(s64) length, buffer.data};

        // Find last backslash to get directory
        last_sep := -1;
        for i: 0..exe_path.count-1 {
            if exe_path[i] == #char "\\" {
                last_sep = i;
            }
        }

        if last_sep < 0 {
            return copy_string(DAEMON_EXECUTABLE);
        }

        // Build daemon path
        dir := slice(exe_path, 0, last_sep + 1);
        return tprint("%0%", dir, DAEMON_EXECUTABLE);
    } else {
        // On Unix, use /proc/self/exe or similar
        // For now, assume daemon is in same directory
        return copy_string(DAEMON_EXECUTABLE);
    }
}

// Cached context definitions from daemon
context_names: [..] string;

// Display mode for the UI
Display_Mode :: enum {
    CONTEXTS;           // Show defined context names only
    CONTEXTS_WITH_ARGS; // Show contexts with their valid arg combinations
    HISTORY;            // Show recent command strings from history only
    ALL;                // Show contexts + history merged (default)
}

current_display_mode: Display_Mode = .ALL;

// Parse display mode string to enum
parse_display_mode :: (mode_str: string) -> Display_Mode {
    if mode_str == "contexts" return .CONTEXTS;
    if mode_str == "contexts_with_args" return .CONTEXTS_WITH_ARGS;
    if mode_str == "history" return .HISTORY;
    return .ALL;  // Default
}

// Load display mode from config file
load_display_mode_config :: () {
    config_path := get_config_path();
    defer free(config_path);

    // Import config parser (already loaded via hotkey_manager)
    config_parser :: #import,dir "daemon/config";

    user_config, success := config_parser.parse_config_file(config_path);
    defer config_parser.free_user_config(*user_config);

    if success && user_config.ui.display_mode.count > 0 {
        current_display_mode = parse_display_mode(user_config.ui.display_mode);
        print("Loaded display mode from config: %\n", current_display_mode);
    } else {
        print("Using default display mode: ALL\n");
    }
}

// Initialize search items from history
init_search_items :: () {
    // Load history entries (most recently used first)
    if history_manager != null {
        history_entries := get_history_entries(history_manager);
        for entry: history_entries {
            item: Search_Item;
            item.text = entry.text;
            item.icon = entry.icon;
            array_add(*search_items, item);
        }
    }
    // No default items - only show what the user has actually used
}

// Refresh search items after history changes
refresh_search_items :: () {
    array_reset(*search_items);
    init_search_items();
}

// Fetch contexts from daemon and refresh search items
// This is called every time the window is shown
refresh_from_daemon :: () {
    if !sdk_connected return;

    // Fetch context list from daemon
    response, success := list_contexts(*sdk_client);
    defer free(response);

    if !success {
        print("Failed to fetch contexts from daemon\n");
        return;
    }

    // Parse context names from JSON response
    // Response format: {"jsonrpc":"2.0","id":N,"result":{"contexts":[{"name":"work",...},...],"history":[...]}}
    parse_context_names_from_response(response);

    // Refresh search items combining contexts and history
    refresh_search_items_with_contexts();
}

// Parse context names from the daemon's JSON response
parse_context_names_from_response :: (response: string) {
    // Clear existing context names
    for context_names {
        free(it);
    }
    array_reset(*context_names);

    // Simple JSON parsing to extract context names
    // Look for "contexts":[...] and extract "name":"value" pairs
    contexts_start := find_index_from_left(response, "\"contexts\":");
    if contexts_start < 0 return;

    // Find the array start
    array_start := find_index_from_left(response, "[", contexts_start);
    if array_start < 0 return;

    // Find matching array end
    bracket_depth := 1;
    pos := array_start + 1;
    while pos < response.count && bracket_depth > 0 {
        if response[pos] == #char "[" {
            bracket_depth += 1;
        } else if response[pos] == #char "]" {
            bracket_depth -= 1;
        }
        pos += 1;
    }
    array_end := pos - 1;

    // Extract the contexts array content
    contexts_content := slice(response, array_start + 1, array_end - array_start - 1);

    // Find all "name":"..." patterns within the contexts array
    search_pos := 0;
    while search_pos < contexts_content.count {
        name_key := find_index_from_left(contexts_content, "\"name\":", search_pos);
        if name_key < 0 break;

        // Find the opening quote of the value
        value_start := find_index_from_left(contexts_content, "\"", name_key + 7);
        if value_start < 0 break;

        // Find the closing quote of the value
        value_end := find_index_from_left(contexts_content, "\"", value_start + 1);
        if value_end < 0 break;

        // Extract the name
        name := slice(contexts_content, value_start + 1, value_end - value_start - 1);
        if name.count > 0 {
            array_add(*context_names, copy_string(name));
        }

        search_pos = value_end + 1;
    }

    print("Loaded % context definitions from daemon\n", context_names.count);
}

// Refresh search items combining context definitions and history
// Respects the current_display_mode setting
refresh_search_items_with_contexts :: () {
    array_reset(*search_items);

    // Track which items we've already added (to avoid duplicates)
    added_items: [..] string;
    defer array_free(added_items);

    if current_display_mode == {
        case .CONTEXTS;
            // Show only context definitions (no history)
            for context_name: context_names {
                item: Search_Item;
                item.text = context_name;
                item.icon = "";
                array_add(*search_items, item);
            }

        case .CONTEXTS_WITH_ARGS;
            // Show context definitions (future: expand with arg combinations)
            // For now, same as CONTEXTS
            for context_name: context_names {
                item: Search_Item;
                item.text = context_name;
                item.icon = "";
                array_add(*search_items, item);
            }

        case .HISTORY;
            // Show only history entries (no context definitions)
            if history_manager != null {
                history_entries := get_history_entries(history_manager);
                for entry: history_entries {
                    item: Search_Item;
                    item.text = entry.text;
                    item.icon = entry.icon;
                    array_add(*search_items, item);
                }
            }

        case .ALL;
            // Show history first, then context definitions not in history
            // (This is the default merged view)

            // First, add history entries (most recently used first)
            if history_manager != null {
                history_entries := get_history_entries(history_manager);
                for entry: history_entries {
                    item: Search_Item;
                    item.text = entry.text;
                    item.icon = entry.icon;
                    array_add(*search_items, item);
                    array_add(*added_items, entry.text);
                }
            }

            // Then add context definitions that aren't already in history
            for context_name: context_names {
                already_added := false;
                for added: added_items {
                    // Check if this context name matches the start of any history entry
                    // (history entries may have args like "work --mode=programming")
                    if begins_with(added, context_name) {
                        // Check if it's exactly the context name or followed by a space
                        if added.count == context_name.count || (added.count > context_name.count && added[context_name.count] == #char " ") {
                            already_added = true;
                            break;
                        }
                    }
                    if added == context_name {
                        already_added = true;
                        break;
                    }
                }

                if !already_added {
                    item: Search_Item;
                    item.text = context_name;
                    item.icon = "";  // Default icon for context definitions
                    array_add(*search_items, item);
                }
            }
    }

    print("Display mode: %, items: %\n", current_display_mode, search_items.count);
}

main :: () {
    // Initialize history manager first (loads from disk)
    history_manager = init_history_manager();
    if history_manager == null {
        print("Warning: Failed to create history manager\n");
    }
    defer if history_manager != null deinit_history_manager(history_manager);

    // Connect to daemon (spawns daemon if not running)
    sdk_connected = connect_to_daemon();
    if !sdk_connected {
        error_msg := "Failed to connect to the Uncrumpled daemon.\n\nPlease ensure the daemon is installed and try again.";
        print("Error: %\n", error_msg);
        #if OS == .WINDOWS {
            MessageBoxA(null, error_msg.data, "Daemon Connection Failed", MB_OK | MB_ICONERROR);
        }
        return;
    }
    defer deinit_service_client(*sdk_client);

    // Initialize search items (uses history)
    init_search_items();
    defer array_free(search_items);

    // Initialize hotkey manager
    hotkey_manager := init_hotkey_manager();
    if hotkey_manager == null {
        print("Warning: Failed to create hotkey manager\n");
    }
    defer if hotkey_manager != null deinit_hotkey_manager(hotkey_manager);

    // Load hotkey configuration
    if hotkey_manager != null {
        load_hotkey_config(hotkey_manager);
        hotkey_display := get_hotkey_display_string(hotkey_manager);
        defer free(hotkey_display);
        print("Hotkey: %\n", hotkey_display);
    }

    // Load display mode configuration
    load_display_mode_config();

    window_state := create_app_window();
    if !window_state return;
    defer destroy_app_window(window_state);

    // Register global hotkey after window is created
    if hotkey_manager != null && hotkey_manager.config.enabled {
        if !register_ui_hotkey(hotkey_manager) {
            error_msg := get_hotkey_error(hotkey_manager);
            config_path := get_config_path();
            defer free(config_path);
            full_msg := tprint("%\n\nTo change the hotkey, edit:\n%", error_msg, config_path);
            print("Error: %\n", full_msg);
            #if OS == .WINDOWS {
                MessageBoxA(null, to_c_string(full_msg), "Hotkey Registration Failed", MB_OK | MB_ICONERROR);
            }
            return;
        } else {
            print("Global hotkey registered successfully.\n");
        }
    }

    renderer := init_renderer(window_state.sdl_window);
    if !renderer return;
    defer destroy_renderer(renderer);

    // UI State
    set_theme(true); // Dark mode default

    search_box: Search_Box;
    init_search_box(*search_box, 50, 50, 700);

    results_list: Results_List;
    init_results_list(*results_list, 50, 120, 700, 400);
    update_results(*results_list, search_items, search_box.text); // Populate initial results

    // Fade in animation
    fade_anim: Animation;
    start_animation(*fade_anim, 0.0, 1.0, 0.4);

    quit := false;
    last_time := seconds_since_init();

    while !quit {
        current_time := seconds_since_init();
        dt := cast(float)(current_time - last_time);
        last_time = current_time;

        // Poll for global hotkey events
        if hotkey_manager != null {
            poll_hotkey_events(hotkey_manager);

            // Check if hotkey toggle was requested
            if check_toggle_requested(hotkey_manager) {
                toggle_window_visibility(window_state);

                // Reset fade animation and refresh data when showing
                if window_state.is_visible {
                    start_animation(*fade_anim, 0.0, 1.0, 0.4);

                    // Refresh contexts from daemon
                    refresh_from_daemon();

                    // Update the results list with new data
                    update_results(*results_list, search_items, search_box.text);
                }
            }
        }

        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == SDL_QUIT {
                quit = true;
            }

            if event.type == SDL_KEYDOWN {
                sym := event.key.keysym.sym;
                handled := false;

                // Check if dialog is visible - it takes priority
                if is_dialog_visible() {
                    dialog_handled, confirmed := handle_dialog_input(sym, event.key.keysym.mod);
                    if dialog_handled {
                        if confirmed {
                            // User confirmed - perform the action
                            action, ctx_name, full_input := get_dialog_action();
                            if action == .CREATE_AND_SWITCH {
                                print("Creating context: %\n", ctx_name);

                                create_response, create_success := create_context(*sdk_client, ctx_name);
                                defer free(create_response);

                                if create_success {
                                    // Now switch to the newly created context
                                    switch_response, switch_success := switch_context(*sdk_client, full_input);
                                    defer free(switch_response);

                                    if switch_success {
                                        print("Created and switched to context: %\n", full_input);

                                        // Add to history
                                        if history_manager != null {
                                            add_to_history(history_manager, full_input, "");
                                        }
                                    }
                                }

                                // Clear and hide
                                search_box.text = "";
                                hide_confirmation_dialog();
                                hide_window(window_state);
                            }
                        }
                        handled = true;
                    }
                }
                else if sym == SDLK_ESCAPE {
                    // Escape hides the window instead of quitting
                    hide_window(window_state);
                    handled = true;
                }
                else if sym == SDLK_DOWN || (sym == SDLK_n && (event.key.keysym.mod & KMOD_CTRL)) {
                    move_selection(*results_list, 1);
                    handled = true;
                }
                else if sym == SDLK_UP || (sym == SDLK_p && (event.key.keysym.mod & KMOD_CTRL)) {
                    move_selection(*results_list, -1);
                    handled = true;
                }
                else if sym == SDLK_RETURN {
                    // Determine what to switch to:
                    // - If search box has text, use that
                    // - Otherwise use selected item from list
                    input_text: string;

                    if search_box.text.count > 0 {
                        input_text = search_box.text;
                    } else if results_list.items.count > 0 {
                        input_text = results_list.items[results_list.selected_index].text;
                    }

                    if input_text.count > 0 {
                        print("Switching to context: %\n", input_text);

                        // Try to switch context via daemon
                        if sdk_connected {
                            response, success := switch_context(*sdk_client, input_text);
                            defer free(response);

                            if success {
                                // Check if switch was successful or if context needs to be created
                                if contains(response, "\"success\":true") || contains(response, "\"success\": true") {
                                    print("Context switch successful\n");

                                    // Add to history
                                    if history_manager != null {
                                        add_to_history(history_manager, input_text, "");
                                    }

                                    // Clear search box for next time
                                    search_box.text = "";

                                    // Hide window after selection
                                    hide_window(window_state);
                                } else if contains(response, "not found") || contains(response, "does not exist") {
                                    // Context doesn't exist - show confirmation dialog
                                    print("Context doesn't exist, showing dialog\n");

                                    // Extract context name from input (before any args)
                                    context_name := input_text;
                                    space_pos := find_index_from_left(input_text, " ");
                                    if space_pos > 0 {
                                        context_name = slice(input_text, 0, space_pos);
                                    }

                                    // Show confirmation dialog
                                    show_confirmation_dialog(
                                        "Create new context?",
                                        context_name,
                                        input_text,
                                        .CREATE_AND_SWITCH
                                    );
                                } else {
                                    print("Context switch response: %\n", response);

                                    // Still add to history even if there was an issue
                                    if history_manager != null {
                                        add_to_history(history_manager, input_text, "");
                                    }

                                    // Clear search box for next time
                                    search_box.text = "";

                                    // Hide window after selection
                                    hide_window(window_state);
                                }
                            } else {
                                print("Failed to send context switch request\n");
                            }
                        }
                    }
                    handled = true;
                }
                else if sym == SDLK_t && (event.key.keysym.mod & KMOD_CTRL) {
                    // Toggle Theme
                    is_dark := current_theme == *THEME_DARK;
                    set_theme(!is_dark);
                    handled = true;
                }
                else if sym == SDLK_TAB {
                    // Tab completion: fill search box with selected item
                    if results_list.items.count > 0 {
                        search_box.text = results_list.items[results_list.selected_index].text;
                        update_results(*results_list, search_items, search_box.text);
                    }
                    handled = true;
                }
                else if sym == SDLK_q && (event.key.keysym.mod & KMOD_CTRL) {
                    // Ctrl+Q to quit the application
                    quit = true;
                    handled = true;
                }

                // Only pass to search box if not a navigation/action key
                if !handled {
                    handle_text_input(*search_box, event);
                    update_results(*results_list, search_items, search_box.text);
                }
            }
            else if event.type == SDL_TEXTINPUT {
                 handle_text_input(*search_box, event);
                 update_results(*results_list, search_items, search_box.text);
            }
        }

        // Update
        update_animation(*fade_anim);
        update_dialog(dt);

        // Only render if visible (save CPU when hidden)
        if window_state.is_visible {
            // Render
            renderer_begin_frame(renderer);

            // Draw Main Panel
            // Center X, Y roughly
            panel_rect := make_rect(40, 40, 720, 520); // simplified layout

            // Apply Fade opacity
            bg_color := current_theme.background;
            bg_color.a *= fade_anim.current;

            // Draw Window Body
            // Note: In transparent window, we clear to transparent, then draw the rounded rect.
            // But we need to erase previous frame content if we aren't clearing to transparent?
            // SDL GL Clear does that.

            // Draw Shadow (simulated)
            shadow_rect := panel_rect;
            shadow_rect.y += 10;
            draw_rect_rounded(renderer, shadow_rect, current_theme.shadow, 12.0);

            draw_rect_rounded(renderer, panel_rect, bg_color, 12.0);

            render_search_box(*search_box, renderer);
            render_results_list(*results_list, renderer);

            // Render confirmation dialog on top (if visible)
            render_confirmation_dialog(renderer);

            renderer_end_frame(renderer);
        } else {
            // When hidden, sleep to reduce CPU usage
            sleep_milliseconds(50);
        }
    }
}
