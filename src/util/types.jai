#import "Basic";
#import "Math";

Rect :: struct {
    x, y, w, h: float;
}

Color :: struct {
    r, g, b, a: float;
}

// Common colors
WHITE       :: Color.{1, 1, 1, 1};
BLACK       :: Color.{0, 0, 0, 1};
TRANSPARENT :: Color.{0, 0, 0, 0};

Theme :: struct {
    background: Color;
    text:       Color;
    accent:     Color;
    selection:  Color;
    shadow:     Color;
}

// Search Result item
Search_Item :: struct {
    text: string;
    icon: string; // Placeholder for now
}

make_rect :: (x: float, y: float, w: float, h: float) -> Rect {
    r: Rect;
    r.x = x;
    r.y = y;
    r.w = w;
    r.h = h;
    return r;
}

make_color :: (r: float, g: float, b: float, a: float = 1.0) -> Color {
    c: Color;
    c.r = r;
    c.g = g;
    c.b = b;
    c.a = a;
    return c;
}
