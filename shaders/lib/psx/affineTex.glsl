#ifndef PSX_AFFINE_TEX_GLSL
#define PSX_AFFINE_TEX_GLSL

#include "/lib/settings.glsl"

#if defined(TEXTURE_WARP) && TEXTURE_WARP > 0.5

float psxGetWarpW(float w) {
    return max(abs(w), TEXTURE_WARP_CAP);
}

#ifdef VSH

varying float psxClipW;

vec2 psxPassTexCoord(vec2 uv, vec4 clipPos) {
    psxClipW = psxGetWarpW(clipPos.w);
    return uv * psxClipW;
}

#endif

#ifdef FSH

varying float psxClipW;

vec2 psxResolveTexCoord(vec2 warpedCoord) {
    return warpedCoord / max(abs(psxClipW), 1e-6);
}

#endif

#else

#ifdef VSH

vec2 psxPassTexCoord(vec2 uv, vec4 clipPos) {
    return uv;
}

#endif

#ifdef FSH

vec2 psxResolveTexCoord(vec2 warpedCoord) {
    return warpedCoord;
}

#endif

#endif

#endif
