#import "Basic";
// renderer.jai, theme.jai, types.jai loaded from main.jai

// Generic Input Widget
draw_text_input :: (ctx: *Renderer_Context, rect: Rect, text: string, focused: bool, placeholder: string = "") {
    // Background
    bg_color := current_theme.background; 
    // Slightly darker for input
    // bg_color.r *= 0.9; bg_color.g *= 0.9; bg_color.b *= 0.9;
    
    draw_rect_rounded(ctx, rect, bg_color, 8.0);
    
    if focused {
        // Draw border or glow
        // draw_rect_stroke(ctx, rect, current_theme.accent, 2.0);
    }
    
    text_x := rect.x + 16.0;
    text_y := rect.y + rect.h / 2.0 + 6.0; // Vertically center approx
    
    if text.count == 0 && placeholder.count > 0 {
        c := current_theme.text;
        c.a = 0.4;
        draw_text(ctx, placeholder, text_x, text_y, c);
    } else {
        draw_text(ctx, text, text_x, text_y, current_theme.text);
    }
    
    // Cursor (caret)
    if focused {
        // blink logic could go here
        caret_x := text_x + 10.0 * text.count; // simplified width calc
        cursor_rect := make_rect(caret_x, rect.y + 10, 2, rect.h - 20);
        draw_rect_rounded(ctx, cursor_rect, current_theme.accent, 1.0);
    }
}

draw_result_row :: (ctx: *Renderer_Context, rect: Rect, item: Search_Item, selected: bool, highlights: []int) {
    if selected {
        draw_rect_rounded(ctx, rect, current_theme.selection, 6.0);
    }
    
    // Text
    text_x := rect.x + 12.0;
    text_y := rect.y + rect.h / 2.0 + 5.0;
    
    if highlights.count > 0 {
        draw_highlight_text(ctx, item.text, text_x, text_y, current_theme.text, current_theme.accent, highlights);
    } else {
        draw_text(ctx, item.text, text_x, text_y, current_theme.text);
    }
}
