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

dummy_data: [..]Search_Item;

init_data :: () {
    items := string.[ 
        "Chrome", "Firefox", "Spotify", "Slack", "Discord", 
        "Visual Studio Code", "Terminal", "Settings", "Calculator", 
        "Calendar", "Notes", "Figma", "Zoom", "Obsidian", 
        "Docker Desktop", "Postman", "TablePlus", "Sublime Text", 
        "VLC Media Player", "System Monitor", "Screenshot", 
        "Lock Screen", "Log Out", "Shutdown", "Restart"
    ];
    
    for items {
        item: Search_Item;
        item.text = it;
        array_add(*dummy_data, item);
    }
}

main :: () {
    init_data();
    
    window_state := create_app_window();
    if !window_state return;
    defer destroy_app_window(window_state);

    renderer := init_renderer(window_state.sdl_window);
    if !renderer return;
    defer destroy_renderer(renderer);
    
    // UI State
    set_theme(true); // Dark mode default
    
    search_box: Search_Box;
    init_search_box(*search_box, 50, 50, 700);
    
    results_list: Results_List;
    init_results_list(*results_list, 50, 120, 700, 400);
    
    // Fade in animation
    fade_anim: Animation;
    start_animation(*fade_anim, 0.0, 1.0, 0.4);
    
    quit := false;
    last_time := seconds_since_init();
    
    while !quit {
        current_time := seconds_since_init();
        dt := cast(float)(current_time - last_time);
        last_time = current_time;
        
        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == SDL_QUIT {
                quit = true;
            }
            
            if event.type == SDL_KEYDOWN {
                sym := event.key.keysym.sym;
                
                if sym == SDLK_ESCAPE {
                    quit = true;
                }
                else if sym == SDLK_DOWN || (sym == SDLK_n && (event.key.keysym.mod & KMOD_CTRL)) {
                    move_selection(*results_list, 1);
                }
                else if sym == SDLK_UP || (sym == SDLK_p && (event.key.keysym.mod & KMOD_CTRL)) {
                    move_selection(*results_list, -1);
                }
                else if sym == SDLK_RETURN {
                    if results_list.items.count > 0 {
                        print("Selected: %\n", results_list.items[results_list.selected_index].text);
                        // quit = true; // Or hide window
                    }
                }
                else if sym == SDLK_t && (event.key.keysym.mod & KMOD_CTRL) {
                    // Toggle Theme
                    is_dark := current_theme == *THEME_DARK;
                    set_theme(!is_dark);
                }
                
                // Pass to Search Box
                handle_text_input(*search_box, event);
                // Update results on keypress (naive)
                update_results(*results_list, dummy_data, search_box.text);
            }
            else if event.type == SDL_TEXTINPUT {
                 handle_text_input(*search_box, event);
                 update_results(*results_list, dummy_data, search_box.text);
            }
        }
        
        // Update
        update_animation(*fade_anim);
        
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
    }
}
