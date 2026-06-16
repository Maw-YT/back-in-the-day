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

// Lowest brightness a fully sky-occluded (but not pitch-black) surface keeps.
// Drives how strongly canopy / overhang shade darkens relative to open sky.
#ifndef LIGHT_SKY_SHADE_FLOOR
#define LIGHT_SKY_SHADE_FLOOR 0.40
#endif

uniform sampler2D lightmap;
uniform vec3 shadowLightDir;

// --- Lightmap coordinate handling (version-independent) ---------------------
// The vanilla lightmap is a 16x16 texture sampled at texel centers, so a valid
// lightmap coordinate spans [0.5/16, 15.5/16] = [0.03125, 0.96875]. Across the
// 1.21.x line, Iris/Sodium hand the raw lightmap attribute to shaders with
// different offsets: some builds clamp the dark end up by half a texel, shifting
// the usable range to ~[0.0625, 1.0] (see Iris issues #2487 and #2810). Relying
// on a single hard-coded offset/scale therefore only lines up on one build.
//
// To stay correct on every 1.21.x build we never bake assumptions into the
// stored coordinate. Instead:
//   1. psxReadLightmapCoord() normalizes the incoming raw coord to a clean
//      [0,1] block/sky brightness (tolerant of the half-texel offset), and
//   2. psxLightToTexel() rebuilds a real texel-center coordinate from that
//      brightness before sampling, so the lightmap color always lands on a
//      valid texel regardless of how the raw attribute was delivered.
#define PSX_LM_OFFSET 0.03125   // 0.5 / 16  (texel 0 center / texture-matrix offset)
#define PSX_LM_SPAN   0.9375    // 15  / 16  (span from texel 0 to texel 15 center)

float psxBlockLight(vec2 lmCoord) {
    return clamp(lmCoord.x, 0.0, 1.0);
}

float psxSkyLight(vec2 lmCoord) {
    return clamp(lmCoord.y, 0.0, 1.0);
}

float psxQuantizeLight(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

// Rebuild a texel-center lightmap coordinate from normalized [0,1] brightness.
vec2 psxLightToTexel(vec2 light) {
    vec2 coord = clamp(light, vec2(0.0), vec2(1.0)) * PSX_LM_SPAN + PSX_LM_OFFSET;
    return (floor(coord * 16.0) + 0.5) / 16.0;
}

vec3 psxSampleLightmap(vec2 lmCoord) {
    return texture2D(lightmap, psxLightToTexel(lmCoord)).rgb;
}

vec3 psxSampleBandedLightmap(vec2 lmCoord) {
    float steps = max(LIGHT_LEVEL_STEPS, 1.0);
    vec2 banded = (floor(clamp(lmCoord, vec2(0.0), vec2(1.0)) * steps) + 0.5) / steps;
    return texture2D(lightmap, psxLightToTexel(banded)).rgb;
}

#ifdef VSH

varying vec2 psxLmCoord;
varying vec3 psxNormal;

// Read the lightmap attribute and normalize it to [0,1] for both block (x) and
// sky (y) light. Works across all 1.21.x lightmap-range conventions; the
// half-texel offset variance only nudges fully-dark light to ~0.033, which is
// below the cave detection threshold and invisible after band quantization.
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

#include "/lib/psx/handLight.glsl"

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float sunAngle;

varying vec2 psxLmCoord;
varying vec3 psxNormal;
varying vec3 psxWorldPos;

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
    // Use the continuous light values here. Quantizing them first makes the
    // per-block lightmap variation snap across band edges and shimmer; the
    // smoothsteps already gate the directional term softly.
    float fromSky = smoothstep(0.02, 0.14, skyLight);
    float fromBlock = smoothstep(0.08, 0.45, blockLight) * 0.35;

    return clamp(fromSky + fromBlock, 0.0, 1.0) * (1.0 - blockLight * 0.45);
}

vec3 psxComputeLighting(vec2 lmCoord, vec3 viewNormal) {
    if (PSX_LIGHTING < 0.5) {
        return psxSampleLightmap(lmCoord);
    }

    float skyLight = psxSkyLight(lmCoord);
    float blockLight = psxBlockLight(lmCoord);

    // Quantize the lightmap to LIGHT_LEVEL_STEPS levels. The default (16) matches
    // the lightmap's native granularity, so the smoothly-interpolated per-block
    // light is preserved and flat ground stays clean. Lowering the setting crushes
    // it into a few coarse bands for a chunkier retro look, at the cost of some
    // checkerboard shimmer where neighbouring blocks straddle a band edge. The
    // baseline PSX "flatness" comes from the per-face directional shading (stable
    // within a face) and the RGB555 color quantization in the final pass.
    vec3 lightColor = psxSampleBandedLightmap(lmCoord);

    if (skyLight < 0.05 && blockLight < 0.05) {
        return max(lightColor * LIGHT_AMBIENT, vec3(0.04));
    }

    if (skyLight < 0.05) {
        return max(lightColor, vec3(0.04));
    }

    // Per-face flat shading: quantized by surface normal, so it is constant
    // across a face and never produces per-block noise.
    float dirBand = psxDirectionalBand(viewNormal);
    float dirWeight = psxDirectionalWeight(skyLight, blockLight);
    float faceLight = mix(LIGHT_AMBIENT, 1.0, dirBand);
    faceLight = mix(LIGHT_AMBIENT, faceLight, dirWeight);

    // Continuous sky-occlusion shade so canopy / overhang shadow darkens cleanly
    // without banding. Block light fills shaded spots back in.
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
