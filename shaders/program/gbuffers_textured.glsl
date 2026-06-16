#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;
varying vec2 texCoord;
varying vec2 lmCoord;
varying vec3 normal;

#include "/lib/psx/vertexSnap.glsl"
#include "/lib/psx/affineTex.glsl"
#include "/lib/psx/lighting.glsl"

void main() {
    lmCoord = psxReadLightmapCoord();
    gl_Position = psxTransformVertex(gl_Vertex, lmCoord);

    color = gl_Color;
    texCoord = psxPassTexCoord((gl_TextureMatrix[0] * gl_MultiTexCoord0).xy, gl_Position);
    normal = normalize(gl_NormalMatrix * gl_Normal);
    psxWriteVertexLight(lmCoord, normal);
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"
#include "/lib/psx/litTextured.glsl"
#include "/lib/psx/alphaQuantize.glsl"

varying vec4 color;
varying vec2 texCoord;

/* DRAWBUFFERS:0 */

void main() {
    vec4 albedo = sampleLitTextured(color, texCoord);
    albedo.rgb = psxApplyFog(albedo.rgb, gl_FogFragCoord);

    psxWriteFragData(albedo);
}

#endif
