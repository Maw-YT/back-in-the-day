#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;

#include "/lib/psx/vertexSnap.glsl"

void main() {
    gl_Position = psxTransformVertex(gl_Vertex, vec2(0.0, 1.0));

    color = gl_Color;
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"
#include "/lib/psx/alphaQuantize.glsl"

varying vec4 color;

/* DRAWBUFFERS:0 */

void main() {
    vec4 outColor = color;
    outColor.rgb = psxApplyFog(outColor.rgb, gl_FogFragCoord);
    psxWriteFragData(outColor);
}

#endif
