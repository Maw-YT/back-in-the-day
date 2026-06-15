#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;
varying vec2 texCoord;

void main() {
    gl_Position = ftransform();
    color = gl_Color;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif

#ifdef FSH

varying vec4 color;
varying vec2 texCoord;

uniform sampler2D texture;

/* DRAWBUFFERS:0 */

void main() {
    gl_FragData[0] = texture2D(texture, texCoord) * color;
}

#endif
