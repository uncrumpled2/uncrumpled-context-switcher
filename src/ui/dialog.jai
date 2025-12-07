// Confirmation Dialog
//
// A simple modal dialog for confirming actions like creating new contexts.
// Supports keyboard navigation: Y/Enter to confirm, N/Escape to cancel.

// Dialog state
Confirmation_Dialog :: struct {
    visible: bool;
    message: string;
    context_name: string;  // The context name being created
    full_input: string;    // The full input string (with args)

    // Callback info - what to do on confirm
    on_confirm_action: Dialog_Action;

    // Animation
    fade_in: float;
}

Dialog_Action :: enum {
    NONE;
    CREATE_AND_SWITCH;
}

// Global dialog instance
confirmation_dialog: Confirmation_Dialog;

// Show the confirmation dialog
show_confirmation_dialog :: (message: string, context_name: string, full_input: string, action: Dialog_Action) {
    confirmation_dialog.visible = true;
    confirmation_dialog.message = message;
    confirmation_dialog.context_name = context_name;
    confirmation_dialog.full_input = full_input;
    confirmation_dialog.on_confirm_action = action;
    confirmation_dialog.fade_in = 0.0;
}

// Hide the confirmation dialog
hide_confirmation_dialog :: () {
    confirmation_dialog.visible = false;
    confirmation_dialog.message = "";
    confirmation_dialog.context_name = "";
    confirmation_dialog.full_input = "";
    confirmation_dialog.on_confirm_action = .NONE;
}

// Check if dialog is visible
is_dialog_visible :: () -> bool {
    return confirmation_dialog.visible;
}

// Handle keyboard input for the dialog
// Returns true if the event was handled
handle_dialog_input :: (sym: SDL_Keycode, mod: SDL_Keymod) -> bool, bool {  // handled, confirmed
    if !confirmation_dialog.visible {
        return false, false;
    }

    // Y or Enter = confirm
    if sym == SDLK_y || sym == SDLK_RETURN {
        return true, true;
    }

    // N or Escape = cancel
    if sym == SDLK_n || sym == SDLK_ESCAPE {
        hide_confirmation_dialog();
        return true, false;
    }

    // Any other key is absorbed but not acted upon
    return true, false;
}

// Get the pending action details
get_dialog_action :: () -> Dialog_Action, string, string {
    return confirmation_dialog.on_confirm_action,
           confirmation_dialog.context_name,
           confirmation_dialog.full_input;
}

// Update dialog animation
update_dialog :: (dt: float) {
    if confirmation_dialog.visible {
        confirmation_dialog.fade_in += dt * 5.0;  // Fast fade in
        if confirmation_dialog.fade_in > 1.0 {
            confirmation_dialog.fade_in = 1.0;
        }
    }
}

// Render the confirmation dialog
render_confirmation_dialog :: (renderer: *Renderer_Context) {
    if !confirmation_dialog.visible return;

    alpha := confirmation_dialog.fade_in;

    // Semi-transparent overlay
    overlay_color := make_color(0.0, 0.0, 0.0, 0.5 * alpha);
    overlay_rect := make_rect(0, 0, 800, 600);
    draw_rect(renderer, overlay_rect, overlay_color);

    // Dialog box
    dialog_width: float = 400;
    dialog_height: float = 150;
    dialog_x: float = (800 - dialog_width) / 2;
    dialog_y: float = (600 - dialog_height) / 2;

    dialog_rect := make_rect(dialog_x, dialog_y, dialog_width, dialog_height);

    // Dialog background with theme
    bg_color := current_theme.background;
    bg_color.a *= alpha;
    draw_rect_rounded(renderer, dialog_rect, bg_color, 12.0);

    // Title/Message
    text_color := current_theme.text;
    text_color.a *= alpha;

    // Draw message text
    message_y := dialog_y + 40;
    draw_text(renderer, confirmation_dialog.message,
              dialog_x + 20, message_y,
              text_color);

    // Draw context name (highlighted)
    name_y := dialog_y + 70;
    accent_color := current_theme.accent;
    accent_color.a *= alpha;
    draw_text(renderer, confirmation_dialog.context_name,
              dialog_x + 20, name_y,
              accent_color);

    // Draw instructions (use dimmer text color)
    hint_color := current_theme.text;
    hint_color.a *= alpha * 0.7;  // Slightly dimmer
    hint_y := dialog_y + dialog_height - 35;
    draw_text(renderer, "[Y/Enter] Create   [N/Esc] Cancel",
              dialog_x + 20, hint_y,
              hint_color);
}
