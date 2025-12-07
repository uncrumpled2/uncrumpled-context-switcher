#import "Basic";
#import "SDL";
skia :: #import "skia";

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
#load "hotkey/hotkey_manager.jai";

// Global data for UI
search_items: [..]Search_Item;
history_manager: *History_Manager;

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

main :: () {
    // Initialize history manager first (loads from disk)
    history_manager = init_history_manager();
    if history_manager == null {
        print("Warning: Failed to create history manager\n");
    }
    defer if history_manager != null deinit_history_manager(history_manager);

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

    window_state := create_app_window();
    if !window_state return;
    defer destroy_app_window(window_state);

    // Register global hotkey after window is created
    if hotkey_manager != null && hotkey_manager.config.enabled {
        if !register_ui_hotkey(hotkey_manager) {
            error_msg := get_hotkey_error(hotkey_manager);
            print("Warning: %\n", error_msg);
            print("The application will still work, but the global hotkey won't be available.\n");
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

                // Reset fade animation when showing
                if window_state.is_visible {
                    start_animation(*fade_anim, 0.0, 1.0, 0.4);
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

                if sym == SDLK_ESCAPE {
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
                    if results_list.items.count > 0 {
                        selected_item := results_list.items[results_list.selected_index];
                        print("Selected: %\n", selected_item.text);

                        // Add to history
                        if history_manager != null {
                            add_to_history(history_manager, selected_item.text, selected_item.icon);
                            // Refresh search items to reflect new history order
                            refresh_search_items();
                        }

                        // Clear search box for next time
                        search_box.text = "";

                        // Hide window after selection
                        hide_window(window_state);
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

            renderer_end_frame(renderer);
        } else {
            // When hidden, sleep to reduce CPU usage
            sleep_milliseconds(50);
        }
    }
}
