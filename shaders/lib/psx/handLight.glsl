#ifndef PSX_HAND_LIGHT_GLSL
#define PSX_HAND_LIGHT_GLSL

#include "/lib/settings.glsl"

#ifdef FSH

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform vec3 relativeEyePosition;

float psxHandLightAt(vec3 worldPos, float heldLight, vec3 handOffset) {
    if (heldLight < 0.5) return 0.0;

    vec3 heldLightPos = worldPos + relativeEyePosition + handOffset;
    float dist = length(heldLightPos) * HAND_LIGHT_RANGE;
    return clamp((heldLight * HAND_LIGHT_STRENGTH - 2.0 * dist) / 15.0, 0.0, 0.9333);
}

float psxMergeBlockLight(float baseLight, float addedLight) {
    if (addedLight <= baseLight) return baseLight;
    return log2(exp2(clamp(baseLight, 0.0, 0.9333) * 32.0) + exp2(addedLight * 32.0)) / 32.0;
}

vec2 psxApplyHandLight(vec2 lmCoord, vec3 worldPos) {
    if (HAND_LIGHT_ENABLE < 0.5) return lmCoord;

    float mainLight = psxHandLightAt(worldPos, float(heldBlockLightValue), vec3(0.35, 0.4, 0.0));
    float offLight = psxHandLightAt(worldPos, float(heldBlockLightValue2), vec3(-0.35, 0.4, 0.0));
    float handLight = max(mainLight, offLight);

    if (handLight < 0.001) return lmCoord;

    vec2 result = lmCoord;
    result.x = psxMergeBlockLight(result.x, handLight);
    return clamp(result, vec2(0.0), vec2(0.9333));
}

vec2 psxApplyHandLightHeld(vec2 lmCoord) {
    if (HAND_LIGHT_ENABLE < 0.5) return lmCoord;

    float heldLight = max(float(heldBlockLightValue), float(heldBlockLightValue2)) * HAND_LIGHT_STRENGTH;
    if (heldLight < 0.5) return lmCoord;

    vec2 result = lmCoord;
    result.x = psxMergeBlockLight(result.x, min(heldLight / 15.0, 0.9333));
    return clamp(result, vec2(0.0), vec2(0.9333));
}

#endif

#endif
