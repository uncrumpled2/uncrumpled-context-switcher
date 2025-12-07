#import "Basic";
#import "SDL";

Window_State :: struct {
    sdl_window: *SDL_Window;

    width:  s32 = 800;
    height: s32 = 600;

    is_open: bool;
    is_visible: bool;
}

create_app_window :: () -> *Window_State {
    if SDL_Init(SDL_INIT_VIDEO) < 0 {
        print("SDL Init Failed: %\n", to_string(SDL_GetError()));
        return null;
    }

    state := New(Window_State);
    state.is_open = true;

    // NOTE: Window positioning doesn't work reliably on WSLg due to Wayland/Weston
    // compositor limitations. SDL_WINDOWPOS_CENTERED is a hint that may be ignored.
    // This works correctly on native Linux with X11 window managers.
    flags : SDL_WindowFlags = SDL_WINDOW_SHOWN | SDL_WINDOW_BORDERLESS | SDL_WINDOW_ALWAYS_ON_TOP;

    state.sdl_window = SDL_CreateWindow("Uncrumpled Context Switcher",
                             SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                             state.width, state.height,
                             flags);

    if !state.sdl_window {
        print("Window Creation Failed: %\n", to_string(SDL_GetError()));
        free(state);
        return null;
    }

    state.is_visible = true;
    return state;
}

// Show the window
show_window :: (state: *Window_State) {
    if state == null || state.sdl_window == null return;
    if state.is_visible return;

    SDL_ShowWindow(state.sdl_window);
    SDL_RaiseWindow(state.sdl_window);

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
