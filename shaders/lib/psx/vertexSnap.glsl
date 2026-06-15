#ifndef PSX_VERTEX_SNAP_GLSL
#define PSX_VERTEX_SNAP_GLSL

#include "/lib/settings.glsl"

#ifdef VSH

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

varying float psxFogWorldY;
varying vec3 psxWorldPos;

#ifndef VERTEX_SNAP_DEPTH
#define VERTEX_SNAP_DEPTH 96.0
#endif

#ifndef VERTEX_SNAP_CURVE
#define VERTEX_SNAP_CURVE 1.0
#endif

float psxSkyLightFactor(vec2 lmCoord) {
    return smoothstep(0.0, 0.14, clamp(lmCoord.y / 0.9333, 0.0, 1.0));
}

vec3 psxVertexBreathingOffset(vec3 pos, float step, float strength) {
    if (strength < 0.001) return vec3(0.0);

    float speed = 1.5 + strength * 2.5;
    float time = frameTimeCounter * speed;
    float phase = dot(pos, vec3(0.17, 0.23, 0.31));
    float wave = sin(time + phase * 6.28318) * cos(time * 0.73 + phase * 3.14159);
    vec3 axis = vec3(
        sin(phase * 1.7),
        cos(phase * 2.3),
        sin(phase * 1.1)
    );

    return normalize(axis + vec3(0.001)) * wave * step * strength * 0.45;
}

float psxVertexBreathingStepScale(vec3 pos, float strength) {
    if (strength < 0.001) return 1.0;

    float speed = 1.2 + strength * 2.0;
    float time = frameTimeCounter * speed;
    float phase = dot(pos, vec3(0.31, 0.43, 0.17));
    return 1.0 + sin(time + phase * 6.28318) * strength * 0.18;
}

vec3 quantizeWorldPosition(vec3 worldPos, vec3 viewPos, float breathScale) {
#if defined(VERTEX_SNAP) && VERTEX_SNAP > 0.5
    float depth = length(viewPos);
    float t = pow(clamp(depth / VERTEX_SNAP_DEPTH, 0.0, 1.0), VERTEX_SNAP_CURVE);

    float stepNear = 480.0 / max(VERTEX_SNAP_RES, 64.0) * 0.0125;
    float stepFar = stepNear * 2.0;
    float step = max(mix(stepNear, stepFar, t), 0.001);
    float breath = VERTEX_BREATHING * breathScale;
    step *= psxVertexBreathingStepScale(worldPos, breath);
    worldPos += psxVertexBreathingOffset(worldPos, step, breath);

    return floor(worldPos / step + 0.5) * step;
#else
    return worldPos;
#endif
}

vec4 psxTransformVertex(vec4 vertex, vec2 lmCoord) {
    gl_FogFragCoord = length((gl_ModelViewMatrix * vertex).xyz);

    vec3 viewPos = (gl_ModelViewMatrix * vertex).xyz;
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    psxFogWorldY = worldPos.y + cameraPosition.y;
    psxWorldPos = worldPos;
    worldPos = quantizeWorldPosition(worldPos, viewPos, psxSkyLightFactor(lmCoord));
    return gl_ProjectionMatrix * gbufferModelView * vec4(worldPos, 1.0);
}

// Held items sit inches from the camera — use a finer grid and lighter snap.
vec4 psxTransformHandVertex(vec4 vertex) {
    gl_FogFragCoord = length((gl_ModelViewMatrix * vertex).xyz);
    psxFogWorldY = cameraPosition.y;
    psxWorldPos = vec3(0.0);

    float handBreath = VERTEX_BREATHING * HAND_BREATH_MUL;
    bool useHandSnap = HAND_VERTEX_SNAP > 0.001;
    bool useHandBreath = handBreath > 0.001;

    if (!useHandSnap && !useHandBreath) {
        return ftransform();
    }

    vec3 viewPos = (gl_ModelViewMatrix * vertex).xyz;
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

    float handRes = max(VERTEX_SNAP_RES * 6.0, 480.0);
    float step = max(480.0 / handRes * 0.004, 0.00025);

    if (useHandBreath) {
        step *= psxVertexBreathingStepScale(worldPos, handBreath);
        worldPos += psxVertexBreathingOffset(worldPos, step, handBreath);
    }

    if (useHandSnap) {
        vec3 snapped = floor(worldPos / step + 0.5) * step;
        worldPos = mix(worldPos, snapped, clamp(HAND_VERTEX_SNAP, 0.0, 5.0));
    }

    return gl_ProjectionMatrix * gbufferModelView * vec4(worldPos, 1.0);
}

// View-space snap for clouds — stable wobble without clip-space tearing.
vec4 psxTransformCloudVertex(vec4 vertex) {
    vec3 viewPos = (gl_ModelViewMatrix * vertex).xyz;
    gl_FogFragCoord = length(viewPos);
    psxFogWorldY = ((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition).y;
    psxWorldPos = vec3(0.0);

#if defined(VERTEX_SNAP) && VERTEX_SNAP > 0.5
    float depth = max(length(viewPos), 16.0);
    float step = depth * 0.006 * (240.0 / max(VERTEX_SNAP_RES, 64.0));
    step *= psxVertexBreathingStepScale(viewPos, VERTEX_BREATHING);
    viewPos += psxVertexBreathingOffset(viewPos, step, VERTEX_BREATHING);
    viewPos = floor(viewPos / step + 0.5) * step;
#endif

    return gl_ProjectionMatrix * vec4(viewPos, 1.0);
}

vec4 psxTransformSkyVertex(vec4 vertex) {
    gl_FogFragCoord = length((gl_ModelViewMatrix * vertex).xyz);
    return ftransform();
}

#endif

#endif
