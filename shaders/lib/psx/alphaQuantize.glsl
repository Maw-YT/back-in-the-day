#ifndef PSX_ALPHA_QUANTIZE_GLSL
#define PSX_ALPHA_QUANTIZE_GLSL

#ifdef FSH

float psxQuantizeAlpha(float alpha) {
    alpha = clamp(alpha, 0.0, 1.0);
    if (alpha < 0.25) {
        return 0.0;
    }
    if (alpha < 0.75) {
        return 0.5;
    }
    return 1.0;
}

vec4 psxQuantizeFragColor(vec4 color) {
    color.a = psxQuantizeAlpha(color.a);
    return color;
}

void psxWriteFragData(vec4 color) {
    color = psxQuantizeFragColor(color);
    if (color.a <= 0.0) {
        discard;
    }
    gl_FragData[0] = color;
}

#endif

#endif
