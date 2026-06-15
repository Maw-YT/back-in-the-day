#ifndef PSX_ENTITY_TINT_GLSL
#define PSX_ENTITY_TINT_GLSL

#ifdef FSH

#include "/lib/psx/alphaQuantize.glsl"

uniform vec4 entityColor;

vec3 psxApplyEntityColor(vec3 color) {
    return mix(color, entityColor.rgb, psxQuantizeAlpha(entityColor.a));
}

#endif

#endif
