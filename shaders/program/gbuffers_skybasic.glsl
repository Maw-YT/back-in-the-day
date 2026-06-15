#include "/lib/settings.glsl"

#ifdef VSH

varying vec4 color;
varying float psxFogWorldY;
varying vec3 psxWorldPos;

void main() {
    gl_Position = ftransform();
    gl_FogFragCoord = length((gl_ModelViewMatrix * gl_Vertex).xyz);
    psxFogWorldY = 256.0;
    psxWorldPos = vec3(0.0);
    color = gl_Color;
}

#endif

#ifdef FSH

#include "/lib/psx/fog.glsl"

varying vec4 color;

/* DRAWBUFFERS:0 */

void main() {
    vec4 outColor = color;
    outColor.rgb = psxApplySkyFog(outColor.rgb, gl_FogFragCoord);
    gl_FragData[0] = outColor;
}

#endif
