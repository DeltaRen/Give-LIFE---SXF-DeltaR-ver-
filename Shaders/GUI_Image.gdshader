shader_type canvas_item;

// The source image to sample bar heights from
uniform sampler2D SOURCE_IMAGE : source_color, filter_linear, repeat_enable;

uniform float SCANLINE_COUNT     : hint_range(10.0, 300.0) = 70.0;
uniform float BAR_MIN            : hint_range(0.0,  1.0)   = 0.1;
uniform float BAR_MAX            : hint_range(0.0,  4.0)   = 1.8;

// Scroll speed (scanlines per second, downward)
uniform float SCROLL_SPEED       : hint_range(0.0,  8.0)   = 0.6;

// Per-scanline random flicker on bar height (0=locked to image, 1=wild jitter)
uniform float NOISE_DENSITY      : hint_range(0.0,  1.0)   = 0.3;

// Image brightness multiplier: 0=image drives nothing (all bars at BAR_MIN),
// 1=full image influence (bright pixels = tall bar, dark pixels = short bar)
uniform float IMAGE_BRIGHTNESS   : hint_range(0.0,  1.0)   = 1.0;

uniform vec4  COLOR_FG           : source_color             = vec4(0.93, 0.95, 0.0, 1.0);
uniform vec4  COLOR_BG           : source_color             = vec4(0.0,  0.0,  0.0,  1.0);

float hash2(vec2 p) {
    uvec2 q = uvec2(ivec2(floor(p)));
    q.x ^= q.y * 2747636419u;
    q.x *= 2654435761u;
    q.x ^= q.x >> 16u;
    q.x *= 2246822519u;
    q.x ^= q.x >> 13u;
    return float(q.x) * (1.0 / 4294967296.0);
}

void fragment() {
    vec2 uv = UV;

    // Scanline band
    float y_f      = uv.y * SCANLINE_COUNT + TIME * SCROLL_SPEED;
    float row      = floor(y_f);
    float band_frc = fract(y_f);

    // Sample the image at the center of this scanline row's Y,
    // using the same X as the current pixel.
    // row_uv.y snaps to the vertical center of the scanline so every pixel
    // in a row reads the same image value → consistent bar height across X.
    float row_center_y = (row + 0.5) / SCANLINE_COUNT;
    vec2 img_uv = vec2(uv.x, row_center_y);

    vec4 img_sample = texture(SOURCE_IMAGE, img_uv);

    // Convert to luminance (perceived brightness)
    float luma = dot(img_sample.rgb, vec3(0.299, 0.587, 0.114));

    // IMAGE_BRIGHTNESS slides the luma from 0 (no influence) to full luma
    float driven_luma = luma * IMAGE_BRIGHTNESS;

    // Bright image pixel → tall black bar (more occluded)
    // Dark image pixel  → short black bar (more bright gap showing)
    float n = clamp(driven_luma, 0.0, 1.0);

    // Per-row flicker jitter
    float jitter_t = floor(TIME * 15.0);
    float jitter = hash2(vec2(row, jitter_t)) * 2.0 - 1.0;
    n = clamp(n + jitter * NOISE_DENSITY * 0.5, 0.0, 1.0);

    float bar_h = mix(BAR_MIN, BAR_MAX, n);

    float lit = step(bar_h, band_frc);

    COLOR = mix(COLOR_BG, COLOR_FG, lit);
}
