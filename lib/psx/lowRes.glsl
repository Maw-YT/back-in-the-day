#ifndef PSX_LOWRES_GLSL
#define PSX_LOWRES_GLSL

#include "/lib/settings.glsl"

#ifdef FSH

uniform float viewWidth;
uniform float viewHeight;

vec2 psxLowResUV(vec2 screenUV) {
    vec2 targetRes = vec2(RENDER_WIDTH, RENDER_HEIGHT);
    return floor(screenUV * targetRes + 0.5) / targetRes;
}

vec2 psxScreenUV() {
    return gl_FragCoord.xy / vec2(viewWidth, viewHeight);
}

#endif

#endif
