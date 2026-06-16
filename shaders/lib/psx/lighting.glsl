#ifndef PSX_LIGHTING_GLSL
#define PSX_LIGHTING_GLSL

#include "/lib/settings.glsl"

#ifndef LIGHT_LEVEL_STEPS
#define LIGHT_LEVEL_STEPS 16.0
#endif

#ifndef LIGHT_SHADE_STEPS
#define LIGHT_SHADE_STEPS 4.0
#endif

#ifndef LIGHT_AMBIENT
#define LIGHT_AMBIENT 0.35
#endif

#ifndef LIGHT_SKY_SHADE_FLOOR
#define LIGHT_SKY_SHADE_FLOOR 0.40
#endif

uniform vec3 shadowLightDir;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float sunAngle;

#define PSX_LM_OFFSET 0.03125
#define PSX_LM_SPAN   0.9375

float psxBlockLight(vec2 lmCoord) {
    return clamp(lmCoord.x, 0.0, 1.0);
}

float psxSkyLight(vec2 lmCoord) {
    return clamp(lmCoord.y, 0.0, 1.0);
}

float psxQuantizeLight(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

vec2 psxLightToTexel(vec2 light) {
    vec2 coord = clamp(light, vec2(0.0), vec2(1.0)) * PSX_LM_SPAN + PSX_LM_OFFSET;
    return (floor(coord * 16.0) + 0.5) / 16.0;
}

vec3 psxViewLightDir() {
    if (length(shadowLightPosition) > 1.0) {
        return normalize(shadowLightPosition);
    }

    vec3 celestial = sunAngle < 0.5 ? sunPosition : moonPosition;
    if (length(celestial) > 1.0) {
        return normalize(celestial);
    }

    if (dot(shadowLightDir, shadowLightDir) > 1e-6) {
        return normalize(shadowLightDir);
    }

    return normalize(vec3(0.2, 1.0, 0.3));
}

float psxCalibratedNdl(vec3 viewNormal, vec3 viewLight) {
    float ndl = dot(viewNormal, viewLight);

    if (length(upPosition) > 1.0) {
        float upNdl = dot(normalize(upPosition), viewLight);
        if (upNdl < 0.0) {
            ndl = -ndl;
        }
    }

    return ndl;
}

float psxDirectionalBand(vec3 viewNormal) {
    vec3 viewN = normalize(viewNormal);
    vec3 viewL = psxViewLightDir();
    float ndl = psxCalibratedNdl(viewN, viewL);
    return psxQuantizeLight(clamp(ndl * 0.5 + 0.5, 0.0, 1.0), LIGHT_SHADE_STEPS);
}

float psxDirectionalWeight(float skyLight, float blockLight) {
    float fromSky = smoothstep(0.02, 0.14, skyLight);
    float fromBlock = smoothstep(0.08, 0.45, blockLight) * 0.35;

    return clamp(fromSky + fromBlock, 0.0, 1.0) * (1.0 - blockLight * 0.45);
}

#ifdef VSH

varying vec2 psxLmCoord;
varying vec3 psxNormal;

vec2 psxReadLightmapCoord() {
    vec2 raw = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    return clamp((raw - PSX_LM_OFFSET) / PSX_LM_SPAN, vec2(0.0), vec2(1.0));
}

void psxWriteVertexLight(vec2 lmCoord, vec3 normal) {
    psxLmCoord = lmCoord;
    psxNormal = normal;
}

#endif

#ifdef FSH

uniform sampler2D lightmap;

#include "/lib/psx/handLight.glsl"

varying vec2 psxLmCoord;
varying vec3 psxNormal;
varying vec3 psxWorldPos;

vec3 psxSampleLightmap(vec2 lmCoord) {
    return texture2D(lightmap, psxLightToTexel(lmCoord)).rgb;
}

vec3 psxSampleBandedLightmap(vec2 lmCoord) {
    float steps = max(LIGHT_LEVEL_STEPS, 1.0);
    vec2 banded = (floor(clamp(lmCoord, vec2(0.0), vec2(1.0)) * steps) + 0.5) / steps;
    return texture2D(lightmap, psxLightToTexel(banded)).rgb;
}

vec3 psxComputeLighting(vec2 lmCoord, vec3 viewNormal) {
    if (PSX_LIGHTING < 0.5) {
        return psxSampleLightmap(lmCoord);
    }

    float skyLight = psxSkyLight(lmCoord);
    float blockLight = psxBlockLight(lmCoord);
    vec3 lightColor = psxSampleBandedLightmap(lmCoord);

    if (skyLight < 0.05 && blockLight < 0.05) {
        return max(lightColor * LIGHT_AMBIENT, vec3(0.04));
    }

    if (skyLight < 0.05) {
        return max(lightColor, vec3(0.04));
    }

    float dirBand = psxDirectionalBand(viewNormal);
    float dirWeight = psxDirectionalWeight(skyLight, blockLight);
    float faceLight = mix(LIGHT_AMBIENT, 1.0, dirBand);
    faceLight = mix(LIGHT_AMBIENT, faceLight, dirWeight);

    float skyShade = mix(LIGHT_SKY_SHADE_FLOOR, 1.0, skyLight);
    skyShade = mix(skyShade, 1.0, blockLight);

    return max(lightColor * faceLight * skyShade, vec3(0.04));
}

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
