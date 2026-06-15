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
    lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
    gl_Position = psxTransformVertex(gl_Vertex, lmCoord);

    color = gl_Color;
    texCoord = psxPassTexCoord((gl_TextureMatrix[0] * gl_MultiTexCoord0).xy, gl_Position);
    normal = normalize(gl_NormalMatrix * gl_Normal);
    psxWriteVertexLight(lmCoord, normal);
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"
#include "/lib/psx/affineTex.glsl"
#include "/lib/psx/lighting.glsl"
#include "/lib/psx/alphaQuantize.glsl"

varying vec4 color;
varying vec2 texCoord;

uniform sampler2D texture;

/* DRAWBUFFERS:0 */

void main() {
    vec4 albedo = texture2D(texture, psxResolveTexCoord(texCoord)) * color;
    albedo.rgb = psxApplyVertexLighting(albedo.rgb);
    albedo.rgb = psxApplyFog(albedo.rgb, gl_FogFragCoord);

    psxWriteFragData(albedo);
}

#endif
