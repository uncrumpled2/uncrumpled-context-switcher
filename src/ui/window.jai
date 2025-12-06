#import "Basic";
#import "SDL";
// types.jai loaded from main.jai

Window_State :: struct {
    sdl_window: *SDL_Window;

    width:  s32 = 800;
    height: s32 = 600;

    is_open: bool;
    is_visible: bool;  // Track visibility for show/hide toggle
}

create_app_window :: () -> *Window_State {
    if SDL_Init(SDL_INIT_VIDEO) < 0 {
        print("SDL Init Failed: %\n", to_string(SDL_GetError()));
        return null;
    }

    // Window Flags - no OpenGL, using SDL_Renderer with Skia raster surface
    flags : SDL_WindowFlags = SDL_WINDOW_SHOWN | SDL_WINDOW_BORDERLESS | SDL_WINDOW_ALWAYS_ON_TOP;

    // Center initially
    display_mode: SDL_DisplayMode;
    SDL_GetCurrentDisplayMode(0, *display_mode);

    start_x := (display_mode.w - 800) / 2;
    start_y := (display_mode.h - 600) / 3; // Slightly higher than center looks better

    window := SDL_CreateWindow("Uncrumpled Context Switcher",
                             start_x, start_y,
                             800, 600,
                             flags);

    if !window {
        print("Window Creation Failed: %\n", to_string(SDL_GetError()));
        return null;
    }

    state := New(Window_State);
    state.sdl_window = window;
    state.is_open = true;
    state.is_visible = true;

    return state;
}

// Show the window and give it focus
show_window :: (state: *Window_State) {
    if state == null || state.sdl_window == null return;
    if state.is_visible return;

    SDL_ShowWindow(state.sdl_window);
    SDL_RaiseWindow(state.sdl_window);
    // Note: SDL_RaiseWindow should also give keyboard focus
    state.is_visible = true;
}

// Hide the window
hide_window :: (state: *Window_State) {
    if state == null || state.sdl_window == null return;
    if !state.is_visible return;

    SDL_HideWindow(state.sdl_window);
    state.is_visible = false;
}

// Toggle window visibility
toggle_window_visibility :: (state: *Window_State) {
    if state == null return;

    if state.is_visible {
        hide_window(state);
    } else {
        show_window(state);
    }
}

destroy_app_window :: (state: *Window_State) {
    if state.sdl_window SDL_DestroyWindow(state.sdl_window);
    SDL_Quit();
    free(state);
}
