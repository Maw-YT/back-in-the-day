#include "/lib/settings.glsl"

#ifdef VSH

varying vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}

#endif

#ifdef FSH

#include "/lib/psx/aspect.glsl"
#include "/lib/psx/colorQuantize.glsl"
#include "/lib/psx/lowRes.glsl"

uniform sampler2D colortex0;

/* DRAWBUFFERS:0 */

void main() {
    vec2 screenUV = psxScreenUV();
    bool outsideAspect;
    vec2 contentUV = psxAspectMapUV(screenUV, outsideAspect);

    if (outsideAspect) {
        gl_FragData[0] = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

#if defined(COMPOSITE_LOWRES) && COMPOSITE_LOWRES > 0.5
    contentUV = psxLowResUV(contentUV);
#endif

    vec3 color = texture2D(colortex0, contentUV).rgb;

#if defined(COMPOSITE_QUANTIZE) && COMPOSITE_QUANTIZE > 0.5
    color = psxQuantizeColor(color, 0.5);
#endif

    gl_FragData[0] = vec4(color, 1.0);
}

#endif
