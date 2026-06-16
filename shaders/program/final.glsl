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
#include "/lib/psx/crt.glsl"
#include "/lib/psx/dither.glsl"

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

    vec3 raw = psxCrtSampleScene(colortex0, contentUV);
    vec2 ditherCoord = floor(contentUV * vec2(RENDER_WIDTH, RENDER_HEIGHT));
    float lum = dot(raw, vec3(0.299, 0.587, 0.114));
    // Fade the ordered dither out smoothly toward brighter tones instead of a
    // hard cutoff. The old cliff made mid-tone lit surfaces straddle the
    // threshold and speckle; this keeps dithering in the shadows where it reads
    // as PSX banding and leaves lit areas clean.
    float ditherFade = 1.0 - smoothstep(0.32, 0.6, lum);
    vec3 color = mix(psxQuantizeColor(raw, 0.5), psxDitherColor(raw, ditherCoord), ditherFade);
    color = psxCrtGlow(colortex0, contentUV, color);
    color = psxCrtPost(colortex0, contentUV, color);
    gl_FragData[0] = vec4(color, 1.0);
}

#endif
