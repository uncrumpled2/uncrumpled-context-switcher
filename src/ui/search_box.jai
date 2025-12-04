#import "Basic";
#import "SDL";
// widgets.jai loaded from main.jai

Search_Box :: struct {
    text: string;
    rect: Rect;
    focused: bool = true;
}

init_search_box :: (box: *Search_Box, x: float, y: float, w: float) {
    box.rect = make_rect(x, y, w, 60.0); // Fixed height
    box.text = "";
}

handle_text_input :: (box: *Search_Box, event: SDL_Event) {
    if event.type == SDL_TEXTINPUT {
        // Append text
        // Note: In a real app, handle UTF-8 properly with a buffer
        // Here assuming simple ASCII/partial for skeleton
        input_str := to_string(cast(*u8)event.text.text.data);
        new_text := sprint("%1%2", box.text, input_str); 
        // Warning: sprint allocates, need to manage memory in real app or use a Builder
        // For this skeleton, we'll let it leak or assume global allocator handles it briefly
        box.text = new_text;
    } else if event.type == SDL_KEYDOWN {
        sym := event.key.keysym.sym;
        if sym == SDLK_BACKSPACE && box.text.count > 0 {
            box.text.count -= 1; // Simple byte removal, unsafe for multi-byte chars
        }
    }
}

render_search_box :: (box: *Search_Box, ctx: *Renderer_Context) {
    draw_text_input(ctx, box.rect, box.text, box.focused, "Type to search...");
}
