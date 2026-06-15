#ifndef PSX_DITHER_GLSL
#define PSX_DITHER_GLSL

#include "/lib/settings.glsl"
#include "/lib/psx/colorQuantize.glsl"

#ifdef FSH

float psxBayer(vec2 fragCoord) {
    vec2 p = floor(fragCoord / max(DITHER_SCALE, 1.0));
    int x = int(mod(p.x, 4.0));
    int y = int(mod(p.y, 4.0));

    // 4x4 Bayer matrix, flattened row-major.
    if (y == 0) {
        if (x == 0) return 0.0 / 16.0;
        if (x == 1) return 8.0 / 16.0;
        if (x == 2) return 2.0 / 16.0;
        return 10.0 / 16.0;
    }
    if (y == 1) {
        if (x == 0) return 12.0 / 16.0;
        if (x == 1) return 4.0 / 16.0;
        if (x == 2) return 14.0 / 16.0;
        return 6.0 / 16.0;
    }
    if (y == 2) {
        if (x == 0) return 3.0 / 16.0;
        if (x == 1) return 11.0 / 16.0;
        if (x == 2) return 1.0 / 16.0;
        return 9.0 / 16.0;
    }
    if (x == 0) return 15.0 / 16.0;
    if (x == 1) return 7.0 / 16.0;
    if (x == 2) return 13.0 / 16.0;
    return 5.0 / 16.0;
}

vec3 psxDitherColor(vec3 color, vec2 fragCoord) {
#if defined(DITHER_ENABLE) && DITHER_ENABLE > 0.5
    float threshold = psxBayer(fragCoord) * DITHER_STRENGTH;
    return psxQuantizeColor(color, threshold);
#else
    return psxQuantizeColor(color, 0.5);
#endif
}

#endif

#endif
