#ifndef PSX_CRT_GLSL
#define PSX_CRT_GLSL

#include "/lib/settings.glsl"
#include "/lib/psx/lowRes.glsl"

#ifdef FSH

uniform float frameTimeCounter;

vec2 psxCrtCurvedUV(vec2 contentUV) {
    if (CRT_ENABLE > 0.5 && CRT_CURVATURE > 0.001) {
        vec2 centered = contentUV - 0.5;
        float radius2 = dot(centered, centered);
        centered *= 1.0 + radius2 * CRT_CURVATURE * 0.18;
        contentUV = centered + 0.5;
    }
    return clamp(contentUV, 0.0, 1.0);
}

vec2 psxCrtSampleUV(vec2 contentUV) {
    return psxLowResUV(psxCrtCurvedUV(contentUV));
}

vec3 psxCrtSampleScene(sampler2D tex, vec2 contentUV) {
    if (CRT_ENABLE > 0.5 && CRT_CHROMATIC > 0.001) {
        vec2 centered = contentUV - 0.5;
        centered.x *= viewWidth / max(viewHeight, 1.0);
        float dist = length(centered);
        vec2 direction = dist > 0.0001 ? centered / dist : vec2(0.0);
        vec2 offset = direction * dist * dist * CRT_CHROMATIC * 0.012;

        vec2 uvR = psxCrtSampleUV(contentUV - offset);
        vec2 uvG = psxCrtSampleUV(contentUV);
        vec2 uvB = psxCrtSampleUV(contentUV + offset);

        return vec3(
            texture2D(tex, uvR).r,
            texture2D(tex, uvG).g,
            texture2D(tex, uvB).b
        );
    }

    return texture2D(tex, psxCrtSampleUV(contentUV)).rgb;
}

vec3 psxCrtGlowTap(sampler2D tex, vec2 contentUV, vec2 offset, float weight) {
    vec3 sampleColor = texture2D(tex, psxCrtSampleUV(contentUV + offset)).rgb;
    float lum = dot(sampleColor, vec3(0.299, 0.587, 0.114));
    float bright = pow(max(lum - 0.20, 0.0), 1.8);
    return sampleColor * bright * weight;
}

vec3 psxCrtGlow(sampler2D tex, vec2 contentUV, vec3 color) {
    if (CRT_ENABLE < 0.5 || CRT_GLOW < 0.001) return color;

    vec2 px = vec2(1.0 / viewWidth, 1.0 / viewHeight) * (2.0 + CRT_GLOW * 6.0);
    vec3 glow = vec3(0.0);

    glow += psxCrtGlowTap(tex, contentUV, vec2(0.0), 3.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(px.x, 0.0), 2.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(-px.x, 0.0), 2.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(0.0, px.y), 2.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(0.0, -px.y), 2.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(px.x, px.y), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(-px.x, px.y), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(px.x, -px.y), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(-px.x, -px.y), 1.0);

    vec2 px2 = px * 2.0;
    glow += psxCrtGlowTap(tex, contentUV, vec2(px2.x, 0.0), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(-px2.x, 0.0), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(0.0, px2.y), 1.0);
    glow += psxCrtGlowTap(tex, contentUV, vec2(0.0, -px2.y), 1.0);

    glow /= 14.0;
    glow *= vec3(0.88, 1.0, 0.82);
    return color + glow * CRT_GLOW * 0.85;
}

vec3 psxCrtBleed(sampler2D tex, vec2 contentUV, vec3 color) {
    if (CRT_ENABLE < 0.5 || CRT_BLEED < 0.001) return color;

    vec2 px = vec2(1.0 / viewWidth, 0.0) * (1.0 + CRT_BLEED * 5.0);
    vec3 bleed = texture2D(tex, psxCrtSampleUV(contentUV - px * 2.0)).rgb;
    bleed += texture2D(tex, psxCrtSampleUV(contentUV - px)).rgb;
    bleed += texture2D(tex, psxCrtSampleUV(contentUV + px)).rgb;
    bleed += texture2D(tex, psxCrtSampleUV(contentUV + px * 2.0)).rgb;
    bleed *= 0.25;

    float lum = dot(color, vec3(0.299, 0.587, 0.114));
    float bright = smoothstep(0.12, 0.45, lum);
    return mix(color, max(color, bleed * 1.15), bright * CRT_BLEED * 0.55);
}

float psxCrtHash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 psxCrtMask() {
    if (CRT_ENABLE < 0.5 || CRT_MASK < 0.001) return vec3(1.0);

    float phase = gl_FragCoord.x * 3.14159265 * 0.5;
    vec3 mask = vec3(
        sin(phase) * 0.5 + 0.5,
        sin(phase + 2.094395) * 0.5 + 0.5,
        sin(phase + 4.188790) * 0.5 + 0.5
    );
    return mix(vec3(1.0), mask * 1.12, CRT_MASK * 0.42);
}

vec3 psxCrtNoise(vec3 color) {
    if (CRT_ENABLE < 0.5 || CRT_NOISE < 0.001) return color;

    float grain = psxCrtHash(gl_FragCoord.xy + floor(frameTimeCounter * 24.0)) - 0.5;
    return color + grain * CRT_NOISE * 0.07;
}

vec3 psxCrtPost(sampler2D tex, vec2 contentUV, vec3 color) {
    if (CRT_ENABLE > 0.5) {
        color = psxCrtBleed(tex, contentUV, color);

        if (CRT_SCANLINE > 0.001) {
            float scanline = sin(gl_FragCoord.y * 3.14159265) * 0.5 + 0.5;
            scanline = mix(1.0, scanline * 0.40 + 0.60, CRT_SCANLINE);
            color *= scanline;
        }

        color *= psxCrtMask();

        if (CRT_VIGNETTE > 0.001) {
            vec2 centered = contentUV - 0.5;
            centered.x *= viewWidth / max(viewHeight, 1.0);
            float vignette = 1.0 - dot(centered, centered) * CRT_VIGNETTE * 1.8;
            color *= clamp(vignette, 0.0, 1.0);
        }

        color = psxCrtNoise(color);
    }

    return color;
}

#endif

#endif
