shader_type canvas_item;

uniform float SCANLINE_COUNT     : hint_range(10.0, 300.0) = 70.0;
uniform float BAR_MIN            : hint_range(0.0,  1.0)   = 0.1;
uniform float BAR_MAX            : hint_range(0.0,  4.0)   = 1.8;
uniform float NOISE_SCALE_X      : hint_range(0.1, 16.0)   = 3.5;
uniform float NOISE_SCALE_Y      : hint_range(0.1, 16.0)   = 2.5;
uniform float SCROLL_SPEED       : hint_range(0.0,  8.0)   = 0.6;
uniform float DRIFT_SPEED        : hint_range(0.0,  4.0)   = 0.15;
uniform float NOISE_CONTRAST     : hint_range(0.5,  6.0)   = 2.2;
// How much random per-scanline jitter is added to the bar height (0=none, 1=wild)
uniform float NOISE_DENSITY      : hint_range(0.0,  1.0)   = 0.3;
uniform vec4  COLOR_FG           : source_color             = vec4(0.93, 0.95, 0.0, 1.0);
uniform vec4  COLOR_BG           : source_color             = vec4(0.0,  0.0,  0.0,  1.0);

// ── SEAMLESS HASH using integer bit-mixing ────────────────────────────────
// Avoids the fract()*fract() pattern that causes visible grid discontinuities.
float hash2(vec2 p) {
    uvec2 q = uvec2(ivec2(floor(p)));
    q.x ^= q.y * 2747636419u;
    q.x *= 2654435761u;
    q.x ^= q.x >> 16u;
    q.x *= 2246822519u;
    q.x ^= q.x >> 13u;
    return float(q.x) * (1.0 / 4294967296.0);
}

// Bilinear value noise using the seamless hash
float vnoise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash2(i),                hash2(i + vec2(1,0)), u.x),
        mix(hash2(i + vec2(0,1)),    hash2(i + vec2(1,1)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float v  = vnoise2(p)                           * 0.65;
          v += vnoise2(p * 2.1 + vec2(3.7, 1.4))   * 0.25;
          v += vnoise2(p * 4.3 + vec2(1.1, 5.2))   * 0.10;
    return v;
}

void fragment() {
    vec2 uv = UV;

    // Scanline band
    float y_f      = uv.y * SCANLINE_COUNT + TIME * SCROLL_SPEED;
    float row      = floor(y_f);
    float band_frc = fract(y_f);

    // Sample smooth noise field for this (x, row)
    vec2 noise_uv = vec2(
        uv.x  * NOISE_SCALE_X + TIME * DRIFT_SPEED,
        row   / NOISE_SCALE_Y + TIME * SCROLL_SPEED * 0.05
    );
    float n = pow(clamp(fbm(noise_uv), 0.0, 1.0), NOISE_CONTRAST);

    // Per-scanline-per-frame jitter: random offset added to bar height.
    // Uses row + time so it flickers each frame, and is consistent across X.
    float jitter_t = floor(TIME * 15.0);
    float jitter = hash2(vec2(row, jitter_t)) * 2.0 - 1.0; // -1..1
    n = clamp(n + jitter * NOISE_DENSITY * 0.5, 0.0, 1.0);

    float bar_h = mix(BAR_MIN, BAR_MAX, n);

    // Black bar at top of band, bright gap at bottom
    float lit = step(bar_h, band_frc);

    COLOR = mix(COLOR_BG, COLOR_FG, lit);
}
