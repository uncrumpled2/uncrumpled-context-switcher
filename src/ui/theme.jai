// types.jai loaded from main.jai

THEME_DARK :: Theme.{
    background = .{0.1, 0.1, 0.12, 0.95}, // Dark grey, slight blue tint, transparent
    text       = .{0.9, 0.9, 0.9, 1.0},
    accent     = .{0.0, 0.6, 1.0, 1.0}, // Neon blue
    selection  = .{1.0, 1.0, 1.0, 0.1}, // White overlay
    shadow     = .{0.0, 0.0, 0.0, 0.5},
};

THEME_LIGHT :: Theme.{
    background = .{0.95, 0.95, 0.97, 0.95}, // Off-white
    text       = .{0.1, 0.1, 0.1, 1.0},
    accent     = .{0.2, 0.4, 0.8, 1.0}, // Muted blue
    selection  = .{0.0, 0.0, 0.0, 0.05}, // Black overlay
    shadow     = .{0.0, 0.0, 0.0, 0.2},
};

current_theme: *Theme;

set_theme :: (is_dark: bool) {
    if is_dark {
        current_theme = *THEME_DARK;
    } else {
        current_theme = *THEME_LIGHT;
    }
}
