#ifndef PSX_COLOR_QUANTIZE_GLSL
#define PSX_COLOR_QUANTIZE_GLSL

#include "/lib/settings.glsl"

#ifdef FSH

// PSX framebuffer: 15-bit RGB555 (32 levels per channel) stored in 16-bit pixels.
vec3 psxQuantizeColor(vec3 color, float threshold) {
#if defined(COLOR_16BIT) && COLOR_16BIT > 0.5
    return clamp(floor(color * 31.0 + threshold) / 31.0, 0.0, 1.0);
#else
    float steps = max(COLOR_STEPS, 2.0);
    return clamp(floor(color * steps + threshold) / steps, 0.0, 1.0);
#endif
}

#endif

#endif
