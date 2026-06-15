#ifndef PSX_LIT_TEXTURED_FSH
#define PSX_LIT_TEXTURED_FSH

#include "/lib/psx/affineTex.glsl"
#include "/lib/psx/lighting.glsl"

uniform sampler2D texture;

vec4 sampleLitTextured(vec4 color, vec2 texCoord) {
    vec2 uv = psxResolveTexCoord(texCoord);
    vec4 albedo = texture2D(texture, uv) * color;
    albedo.rgb = psxApplyVertexLighting(albedo.rgb);
    return albedo;
}

#endif
