#ifndef PSX_SKY_GLSL
#define PSX_SKY_GLSL

#include "/lib/settings.glsl"
#include "/lib/psx/colorQuantize.glsl"

#ifdef FSH

#ifndef SKY_QUANTIZE
#define SKY_QUANTIZE 1.0
#endif

#ifndef SKY_BANDS
#define SKY_BANDS 8.0
#endif

vec3 psxQuantizeSkyColor(vec3 color) {
#if defined(SKY_QUANTIZE) && SKY_QUANTIZE > 0.5
    color = psxQuantizeColor(color, 0.5);

    float steps = max(SKY_BANDS, 2.0);
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float bandLuma = floor(luma * steps + 0.5) / steps;
    color = mix(color, vec3(bandLuma), 0.55);
#endif
    return color;
}

vec4 psxProcessSkyTexColor(vec4 texColor) {
    texColor.rgb = psxQuantizeSkyColor(texColor.rgb);
    return texColor;
}

#endif

#endif
