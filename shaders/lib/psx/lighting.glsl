#ifndef PSX_LIGHTING_GLSL
#define PSX_LIGHTING_GLSL

#include "/lib/settings.glsl"

#ifndef LIGHT_LEVEL_STEPS
#define LIGHT_LEVEL_STEPS 4.0
#endif

#ifndef LIGHT_SHADE_STEPS
#define LIGHT_SHADE_STEPS 4.0
#endif

#ifndef LIGHT_AMBIENT
#define LIGHT_AMBIENT 0.35
#endif

uniform sampler2D lightmap;
uniform vec3 shadowLightDir;

float psxSkyLight(vec2 lmCoord) {
    return clamp(lmCoord.y / 0.9333, 0.0, 1.0);
}

float psxQuantizeLight(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

vec2 psxSnapLightmapCoord(vec2 lmCoord) {
    vec2 coord = clamp(lmCoord, vec2(0.0), vec2(0.9333));
    return (floor(coord * vec2(16.0, 16.0)) + 0.5) / vec2(16.0, 16.0);
}

vec2 psxPsxLightmapCoord(vec2 lmCoord) {
    float steps = max(LIGHT_LEVEL_STEPS, 1.0);
    vec2 norm = clamp(lmCoord / 0.9333, vec2(0.0), vec2(1.0));
    norm = (floor(norm * steps) + 0.5) / steps;
    return norm * 0.9333;
}

vec3 psxSampleLightmap(vec2 lmCoord) {
    return texture2D(lightmap, psxSnapLightmapCoord(lmCoord)).rgb;
}

vec3 psxComputeLighting(vec2 lmCoord, vec3 normal) {
    if (PSX_LIGHTING < 0.5) {
        return psxSampleLightmap(lmCoord);
    }

    float skyLight = psxSkyLight(lmCoord);
    if (skyLight < 0.12) {
        return max(psxSampleLightmap(lmCoord) * LIGHT_AMBIENT, vec3(0.04));
    }

    vec3 lightColor = texture2D(lightmap, psxPsxLightmapCoord(lmCoord)).rgb;

    vec3 lightDir = shadowLightDir;
    if (dot(lightDir, lightDir) < 1e-6) {
        lightDir = vec3(0.2, 1.0, 0.3);
    }
    lightDir = normalize(lightDir);
    float ndl = dot(normalize(normal), lightDir);
    float shade = psxQuantizeLight(clamp(ndl * 0.5 + 0.5, 0.0, 1.0), LIGHT_SHADE_STEPS);

    float shadeInfluence = smoothstep(0.02, 0.18, skyLight);
    float faceLight = mix(LIGHT_AMBIENT, 1.0, shade);
    faceLight = mix(LIGHT_AMBIENT, faceLight, shadeInfluence);

    return max(lightColor * faceLight, vec3(0.04));
}

#ifdef VSH

varying vec2 psxLmCoord;
varying vec3 psxNormal;

void psxWriteVertexLight(vec2 lmCoord, vec3 normal) {
    psxLmCoord = lmCoord;
    psxNormal = normal;
}

#endif

#ifdef FSH

#include "/lib/psx/handLight.glsl"

varying vec2 psxLmCoord;
varying vec3 psxNormal;
varying vec3 psxWorldPos;

vec3 psxApplyVertexLighting(vec3 albedo) {
    vec2 lmCoord = psxApplyHandLight(psxLmCoord, psxWorldPos);
    return albedo * psxComputeLighting(lmCoord, psxNormal);
}

vec3 psxApplyHandPassLighting(vec3 albedo) {
    vec2 lmCoord = psxApplyHandLightHeld(psxLmCoord);
    return albedo * psxComputeLighting(lmCoord, psxNormal);
}

#endif

#endif
