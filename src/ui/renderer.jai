#import "Basic";
#import "SDL";
// skia and types.jai loaded from main.jai

// SDL_PIXELFORMAT_ABGR8888 for little-endian (same as RGBA32)
SDL_PIXELFORMAT_ABGR8888 :: 0x16762004;

// Font configuration
FONT_SIZE :: 16.0;

Renderer_Context :: struct {
    window:     *SDL_Window;

    // Skia raster surface
    surface:    *skia.SkSurface;
    canvas:     *skia.SkCanvas;
    pixels:     *void;
    row_bytes:  u64;

    width:      s32;
    height:     s32;

    // SDL texture for blitting
    sdl_renderer: *SDL_Renderer;
    sdl_texture:  *SDL_Texture;

    // Cached paints
    paint_fill:   skia.SkPaint;
    paint_stroke: skia.SkPaint;

    // Font resources
    font_mgr:   skia.sk_sp(skia.SkFontMgr);
    typeface:   skia.sk_sp(skia.SkTypeface);
    font:       skia.SkFont;
    font_loaded: bool;
}

init_renderer :: (window: *SDL_Window) -> *Renderer_Context {
    ctx := New(Renderer_Context);
    ctx.window = window;

    SDL_GetWindowSize(window, *ctx.width, *ctx.height);

    // Create SDL renderer for blitting our pixel buffer
    ctx.sdl_renderer = SDL_CreateRenderer(window, -1, .ACCELERATED);
    if !ctx.sdl_renderer {
        print("Failed to create SDL renderer: %\n", to_string(SDL_GetError()));
        free(ctx);
        return null;
    }

    // Create SDL texture to upload our pixels to
    ctx.sdl_texture = SDL_CreateTexture(
        ctx.sdl_renderer,
        SDL_PIXELFORMAT_ABGR8888,
        xx SDL_TextureAccess.STREAMING,
        ctx.width,
        ctx.height
    );
    if !ctx.sdl_texture {
        print("Failed to create SDL texture: %\n", to_string(SDL_GetError()));
        SDL_DestroyRenderer(ctx.sdl_renderer);
        free(ctx);
        return null;
    }

    // Allocate pixel buffer for Skia raster surface
    ctx.row_bytes = cast(u64)(ctx.width * 4);  // RGBA = 4 bytes per pixel
    pixel_size := cast(u64)ctx.height * ctx.row_bytes;
    ctx.pixels = alloc(cast(s64)pixel_size);
    memset(ctx.pixels, 0, cast(s64)pixel_size);

    // Create SkImageInfo
    info := skia.SkImageInfo.Make(ctx.width, ctx.height, .RGBA_8888_SkColorType, .Premul_SkAlphaType);

    // Create Skia raster surface wrapping our pixel buffer
    sp_surface := skia.SkSurfaces.WrapPixels(info, ctx.pixels, ctx.row_bytes, null);
    ctx.surface = sp_surface.fPtr;

    if !ctx.surface {
        print("Failed to create Skia surface\n");
        free(ctx.pixels);
        SDL_DestroyTexture(ctx.sdl_texture);
        SDL_DestroyRenderer(ctx.sdl_renderer);
        free(ctx);
        return null;
    }

    ctx.canvas = skia.SkSurface.getCanvas(ctx.surface);

    // Initialize paints
    skia.SkPaint.Constructor(*ctx.paint_fill);
    skia.SkPaint.setStyle(*ctx.paint_fill, .Fill_Style);

    skia.SkPaint.Constructor(*ctx.paint_stroke);
    skia.SkPaint.setStyle(*ctx.paint_stroke, .Stroke_Style);

    // Initialize font
    init_font(ctx);

    return ctx;
}

init_font :: (ctx: *Renderer_Context) {
    // SkFontStyle for normal weight (400), normal width (5), upright (0)
    // Packed as: weight | (width << 16) | (slant << 24)
    normal_style: skia.SkFontStyle;
    normal_style.fValue = 400 | (5 << 16) | (0 << 24);

    // Try loading from fonts directory first using directory-based font manager
    ctx.font_mgr = skia.SkFontMgr_New_Custom_Directory("fonts".data);

    if ctx.font_mgr.fPtr {
        // Try to match "Source Code Pro" family
        ctx.typeface = skia.SkFontMgr.matchFamilyStyle(ctx.font_mgr.fPtr, "Source Code Pro".data, normal_style);
        if ctx.typeface.fPtr {
            print("Loaded font: Source Code Pro from fonts/\n");
        }
    }

    // Fallback: try system font directories
    if !ctx.typeface.fPtr {
        SYSTEM_FONT_DIRS :: string.[
            "/usr/share/fonts/truetype/ubuntu",
            "/usr/share/fonts/truetype/dejavu",
            "/usr/share/fonts/truetype",
        ];

        for dir: SYSTEM_FONT_DIRS {
            font_mgr := skia.SkFontMgr_New_Custom_Directory(dir.data);
            if font_mgr.fPtr {
                // Try common monospace fonts
                ctx.typeface = skia.SkFontMgr.matchFamilyStyle(font_mgr.fPtr, "Ubuntu Mono".data, normal_style);
                if !ctx.typeface.fPtr {
                    ctx.typeface = skia.SkFontMgr.matchFamilyStyle(font_mgr.fPtr, "DejaVu Sans Mono".data, normal_style);
                }
                if ctx.typeface.fPtr {
                    ctx.font_mgr = font_mgr;
                    print("Loaded fallback font from: %\n", dir);
                    break;
                }
            }
        }
    }

    if !ctx.typeface.fPtr {
        print("Warning: Could not load any font. Text will not render.\n");
        print("Please place SourceCodePro-Regular.ttf in the 'fonts' directory.\n");
        ctx.font_loaded = false;
        return;
    }

    // Create font using upstream safe wrapper (avoids sk_sp by-value ABI issues)
    ctx.font = skia.SkFont_make(ctx.typeface.fPtr, FONT_SIZE);
    skia.SkFont.setSubpixel(*ctx.font, true);
    skia.SkFont.setEdging(*ctx.font, .SubpixelAntiAlias);

    ctx.font_loaded = true;
    print("Font initialized: Source Code Pro, size: %\n", FONT_SIZE);
}

destroy_renderer :: (ctx: *Renderer_Context) {
    if !ctx return;

    skia.SkPaint.Destructor(*ctx.paint_fill);
    skia.SkPaint.Destructor(*ctx.paint_stroke);
    skia.SkFont_destroy(*ctx.font);  // Clean up font's typeface refcount

    if ctx.pixels free(ctx.pixels);
    if ctx.sdl_texture SDL_DestroyTexture(ctx.sdl_texture);
    if ctx.sdl_renderer SDL_DestroyRenderer(ctx.sdl_renderer);

    free(ctx);
}

renderer_begin_frame :: (ctx: *Renderer_Context) {
    // Clear to transparent
    transparent: skia.SkColor4f;
    transparent.fR = 0;
    transparent.fG = 0;
    transparent.fB = 0;
    transparent.fA = 0;
    skia.SkCanvas.drawColor(ctx.canvas, transparent, .Src);
}

renderer_end_frame :: (ctx: *Renderer_Context) {
    // Upload pixels to SDL texture and present
    SDL_UpdateTexture(ctx.sdl_texture, null, ctx.pixels, cast(s32)ctx.row_bytes);
    SDL_RenderClear(ctx.sdl_renderer);
    SDL_RenderCopy(ctx.sdl_renderer, ctx.sdl_texture, null, null);
    SDL_RenderPresent(ctx.sdl_renderer);
}

// Helper to convert our Color type to SkColor (ARGB u32)
color_to_skcolor :: (c: Color) -> skia.SkColor {
    a := cast(u32)(c.a * 255.0);
    r := cast(u32)(c.r * 255.0);
    g := cast(u32)(c.g * 255.0);
    b := cast(u32)(c.b * 255.0);
    return (a << 24) | (r << 16) | (g << 8) | b;
}

// Helper to convert our Color to SkColor4f
color_to_skcolor4f :: (c: Color) -> skia.SkColor4f {
    result: skia.SkColor4f;
    result.fR = c.r;
    result.fG = c.g;
    result.fB = c.b;
    result.fA = c.a;
    return result;
}

// Helper to convert our Rect to SkRect
rect_to_skrect :: (r: Rect) -> skia.SkRect {
    result: skia.SkRect;
    result.fLeft = r.x;
    result.fTop = r.y;
    result.fRight = r.x + r.w;
    result.fBottom = r.y + r.h;
    return result;
}

// Drawing Primitives

draw_rect :: (ctx: *Renderer_Context, rect: Rect, color: Color) {
    sk_rect := rect_to_skrect(rect);
    skia.SkPaint.setColor(*ctx.paint_fill, color_to_skcolor(color));
    skia.SkCanvas.drawRect(ctx.canvas, sk_rect, ctx.paint_fill);
}

draw_rect_rounded :: (ctx: *Renderer_Context, rect: Rect, color: Color, radius: float) {
    sk_rect := rect_to_skrect(rect);
    skia.SkPaint.setColor(*ctx.paint_fill, color_to_skcolor(color));
    skia.SkCanvas.drawRoundRect(ctx.canvas, sk_rect, radius, radius, ctx.paint_fill);
}

draw_rect_shadow :: (ctx: *Renderer_Context, rect: Rect, color: Color, blur: float) {
    // Simple shadow approximation: draw multiple offset rounded rects with decreasing opacity
    shadow_color := color;
    shadow_rect := rect;

    layers :: 4;
    for i: 0..layers-1 {
        alpha_factor := 1.0 - (cast(float)i / cast(float)layers);
        shadow_color.a = color.a * alpha_factor * 0.3;
        offset := cast(float)i * 1.5;
        shadow_rect.x = rect.x + offset * 0.5;
        shadow_rect.y = rect.y + offset;
        draw_rect_rounded(ctx, shadow_rect, shadow_color, 12.0);
    }
}

draw_text :: (ctx: *Renderer_Context, text: string, x: float, y: float, color: Color) {
    if !ctx.font_loaded || text.count == 0 return;

    skia.SkPaint.setColor(*ctx.paint_fill, color_to_skcolor(color));

    skia.SkCanvas.drawSimpleText(
        ctx.canvas,
        text.data,
        cast(u64)text.count,
        .UTF8,
        x, y,
        ctx.font,
        ctx.paint_fill
    );
}

draw_highlight_text :: (ctx: *Renderer_Context, text: string, x: float, y: float, base_color: Color, highlight_color: Color, highlights: []int) {
    if !ctx.font_loaded || text.count == 0 return;

    // For highlighted text, we need to draw character by character
    // Get approximate character width (for monospace font)
    char_width := FONT_SIZE * 0.6;  // Approximate for monospace

    is_highlighted :: (index: int, highlights: []int) -> bool {
        for highlights {
            if it == index return true;
        }
        return false;
    }

    current_x := x;
    for i: 0..text.count-1 {
        c := ifx is_highlighted(i, highlights) then highlight_color else base_color;
        skia.SkPaint.setColor(*ctx.paint_fill, color_to_skcolor(c));

        // Draw single character
        char_str: [1]u8;
        char_str[0] = text[i];

        skia.SkCanvas.drawSimpleText(
            ctx.canvas,
            char_str.data,
            1,
            .UTF8,
            current_x, y,
            ctx.font,
            ctx.paint_fill
        );

        current_x += char_width;
    }
}
