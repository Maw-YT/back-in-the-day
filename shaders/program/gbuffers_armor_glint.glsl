#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;
varying vec2 texCoord;

#include "/lib/psx/vertexSnap.glsl"

void main() {
    gl_Position = psxTransformVertex(gl_Vertex, vec2(0.0, 0.9333));

    color = gl_Color;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"
#include "/lib/psx/alphaQuantize.glsl"

varying vec4 color;
varying vec2 texCoord;

uniform sampler2D texture;

/* DRAWBUFFERS:0 */

void main() {
    vec4 outColor = texture2D(texture, texCoord) * color;
    outColor.rgb = psxApplyFog(outColor.rgb, gl_FogFragCoord);
    psxWriteFragData(outColor);
}

#endif
