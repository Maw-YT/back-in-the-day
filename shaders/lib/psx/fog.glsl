#ifndef PSX_FOG_GLSL
#define PSX_FOG_GLSL

#include "/lib/settings.glsl"
#include "/lib/psx/colorQuantize.glsl"

#ifdef FSH

uniform vec3 fogColor;
uniform vec3 cameraPosition;
uniform int isEyeInWater;

varying float psxFogWorldY;

#ifndef SKY_FOG_STRENGTH
#define SKY_FOG_STRENGTH 0.50
#endif

float psxCaveFogBlend(float worldY) {
    if (CAVE_FOG_ENABLE < 0.5) return 0.0;

    float depth = clamp((CAVE_FOG_HEIGHT - worldY) / max(CAVE_FOG_DEPTH, 1.0), 0.0, 1.0);
    return depth * CAVE_FOG_STRENGTH;
}

float psxFogFactor(float viewDistance, float worldY) {
#if defined(FOG_ENABLE) && FOG_ENABLE > 0.5
    float dist = max(viewDistance, 0.0);

    if (isEyeInWater > 0) {
        return clamp(1.0 - exp(-dist * FOG_DENSITY * 2.5), 0.0, 1.0);
    }

    float expFog = 1.0 - exp(-dist * FOG_DENSITY);
    float linearFog = clamp((dist - FOG_DISTANCE * 0.15) / max(FOG_DISTANCE * 0.85, 1.0), 0.0, 1.0);
    float fogAmount = clamp(max(expFog, linearFog * 0.9), 0.0, 1.0);

    float cave = psxCaveFogBlend(worldY);
    fogAmount = min(fogAmount * (1.0 + cave * 0.45) + cave * 0.18, 1.0);
    return fogAmount;
#else
    return 0.0;
#endif
}

vec3 psxFogColorForWorld(float worldY) {
    vec3 fogCol = psxQuantizeColor(fogColor, 0.5);
    float cave = psxCaveFogBlend(worldY);
    if (cave > 0.001) {
        vec3 darkFog = fogCol * (1.0 - cave * 0.85);
        fogCol = mix(fogCol, darkFog, cave);
    }
    return fogCol;
}

vec3 psxQuantizeFog(vec3 color) {
    return psxQuantizeColor(color, 0.5);
}

vec3 psxApplyFog(vec3 color, float viewDistance) {
    float fogAmount = psxFogFactor(viewDistance, psxFogWorldY);
    if (fogAmount <= 0.001) {
        return color;
    }

    vec3 fogCol = psxFogColorForWorld(psxFogWorldY);
    return mix(color, fogCol, fogAmount);
}

vec3 psxApplySkyFog(vec3 color, float viewDistance) {
#if defined(FOG_ENABLE) && FOG_ENABLE > 0.5
    float dist = max(viewDistance, FOG_DISTANCE * 2.0);
    float fogAmount = psxFogFactor(dist, psxFogWorldY) * SKY_FOG_STRENGTH;
    if (fogAmount <= 0.001) {
        return color;
    }

    vec3 fogCol = psxQuantizeFog(fogColor);
    return mix(color, fogCol, fogAmount);
#else
    return color;
#endif
}

#endif

#endif
