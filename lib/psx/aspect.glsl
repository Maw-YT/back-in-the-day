#ifndef PSX_ASPECT_GLSL
#define PSX_ASPECT_GLSL

#include "/lib/settings.glsl"

#ifdef VSH

uniform float viewWidth;
uniform float viewHeight;
#ifdef IS_IRIS
uniform bool isRightHanded;
#endif

float psxTargetAspect() {
    if (ASPECT_MODE < 0.5) return -1.0;
    if (ASPECT_MODE < 1.5) return 4.0 / 3.0;
    return 16.0 / 9.0;
}

float psxHandAspectOffsetX() {
    if (HAND_ASPECT_OFFSET < 0.001) return 0.0;

    float targetAspect = psxTargetAspect();
    if (targetAspect < 0.0) return 0.0;

    float viewAspect = viewWidth / max(viewHeight, 1.0);
    if (viewAspect <= targetAspect + 0.0001) return 0.0;

    float displayWidth = targetAspect / viewAspect;
    float marginX = (1.0 - displayWidth) * 0.5;
    return marginX * 2.0 * HAND_ASPECT_OFFSET;
}

float psxHandAspectSide(vec4 clipPos) {
#ifdef IS_IRIS
    return clipPos.x * (isRightHanded ? 1.0 : -1.0) > 0.0 ? 1.0 : -1.0;
#else
    return clipPos.x > 0.0 ? 1.0 : -1.0;
#endif
}

vec4 psxApplyHandAspectOffset(vec4 clipPos) {
    float ndcShift = psxHandAspectOffsetX();
    if (ndcShift > 0.001) {
        clipPos.x -= clipPos.w * ndcShift * psxHandAspectSide(clipPos);
    }
    return clipPos;
}

#endif

#ifdef FSH

#include "/lib/psx/lowRes.glsl"

float psxTargetAspect() {
    if (ASPECT_MODE < 0.5) return -1.0;
    if (ASPECT_MODE < 1.5) return 4.0 / 3.0;
    return 16.0 / 9.0;
}

vec4 psxAspectGetBounds() {
    float targetAspect = psxTargetAspect();
    if (targetAspect < 0.0) {
        return vec4(-1.0, 1.0, 0.0, 0.0);
    }

    float viewAspect = viewWidth / max(viewHeight, 1.0);
    float marginX = 0.0;
    float marginY = 0.0;
    float sourceCrop = 0.0;
    float sourceUsed = 1.0;
    float cropAxis = 0.0;

    if (viewAspect > targetAspect + 0.0001) {
        float displayWidth = targetAspect / viewAspect;
        marginX = (1.0 - displayWidth) * 0.5;
        sourceUsed = displayWidth;
        sourceCrop = (1.0 - sourceUsed) * 0.5;
        cropAxis = 1.0;
    } else if (viewAspect + 0.0001 < targetAspect) {
        float displayHeight = viewAspect / targetAspect;
        marginY = (1.0 - displayHeight) * 0.5;
        sourceUsed = displayHeight;
        sourceCrop = (1.0 - sourceUsed) * 0.5;
        cropAxis = 2.0;
    }

    return vec4(marginX, marginY, sourceCrop, sourceUsed);
}

bool psxAspectIsActive(vec4 bounds) {
    return bounds.x >= 0.0;
}

vec2 psxAspectMapUV(vec2 screenUV, out bool outside) {
    outside = false;
    vec4 bounds = psxAspectGetBounds();
    if (!psxAspectIsActive(bounds)) return screenUV;

    float marginX = bounds.x;
    float marginY = bounds.y;
    float sourceCrop = bounds.z;
    float sourceUsed = bounds.w;
    vec2 displayUV = screenUV;

    if (marginX > 0.0) {
        if (screenUV.x < marginX || screenUV.x > 1.0 - marginX) {
            outside = true;
            return screenUV;
        }
        displayUV.x = (screenUV.x - marginX) / (1.0 - marginX * 2.0);
    } else if (marginY > 0.0) {
        if (screenUV.y < marginY || screenUV.y > 1.0 - marginY) {
            outside = true;
            return screenUV;
        }
        displayUV.y = (screenUV.y - marginY) / (1.0 - marginY * 2.0);
    }

    if (marginX > 0.0) {
        return vec2(sourceCrop + displayUV.x * sourceUsed, displayUV.y);
    }

    if (marginY > 0.0) {
        return vec2(displayUV.x, sourceCrop + displayUV.y * sourceUsed);
    }

    return displayUV;
}

#endif

#endif
