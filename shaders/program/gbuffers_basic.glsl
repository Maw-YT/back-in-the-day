#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;
varying vec2 lmCoord;

#include "/lib/psx/vertexSnap.glsl"
#include "/lib/psx/lighting.glsl"

void main() {
    lmCoord = psxReadLightmapCoord();
    gl_Position = psxTransformVertex(gl_Vertex, lmCoord);

    color = gl_Color;
    psxWriteVertexLight(lmCoord, vec3(0.0, 1.0, 0.0));
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"
#include "/lib/psx/lighting.glsl"
#include "/lib/psx/alphaQuantize.glsl"

varying vec4 color;

/* DRAWBUFFERS:0 */

void main() {
    vec4 albedo = color;
    albedo.rgb = psxApplyVertexLighting(albedo.rgb);
    albedo.rgb = psxApplyFog(albedo.rgb, gl_FogFragCoord);

    psxWriteFragData(albedo);
}

#endif
