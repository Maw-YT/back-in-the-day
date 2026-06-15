#ifdef VSH

varying vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif

#ifdef FSH

varying vec2 texCoord;

uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */

void main() {
    gl_FragData[0] = texture2D(colortex0, texCoord);
}

#endif
