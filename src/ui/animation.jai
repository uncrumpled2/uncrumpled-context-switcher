#import "Basic";
#import "Math";

Animation_State :: enum {
    IDLE;
    OPENING;
    CLOSING;
}

Animation :: struct {
    start_val: float;
    end_val:   float;
    current:   float;
    
    start_time: float64;
    duration:   float64;
    
    running: bool;
}

start_animation :: (anim: *Animation, start: float, end: float, duration: float64) {
    anim.start_val = start;
    anim.end_val = end;
    anim.current = start;
    anim.start_time = seconds_since_init();
    anim.duration = duration;
    anim.running = true;
}

update_animation :: (anim: *Animation) -> bool { // returns true if still running
    if !anim.running return false;
    
    now := seconds_since_init();
    t := (now - anim.start_time) / anim.duration;
    
    if t >= 1.0 {
        anim.current = anim.end_val;
        anim.running = false;
        return false;
    }
    
    // Ease Out Cubic
    t = t - 1;
    ease := t * t * t + 1;
    
    anim.current = lerp(anim.start_val, anim.end_val, cast(float)ease);
    return true;
}

// Utils

lerp_float :: (a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
}

lerp_color :: (a: Color, b: Color, t: float) -> Color {
    c: Color;
    c.r = lerp_float(a.r, b.r, t);
    c.g = lerp_float(a.g, b.g, t);
    c.b = lerp_float(a.b, b.b, t);
    c.a = lerp_float(a.a, b.a, t);
    return c;
}
