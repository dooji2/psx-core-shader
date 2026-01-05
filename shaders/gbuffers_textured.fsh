#version 120

#include "/settings.glsl"

#ifndef psx_warp_limit
#define psx_warp_limit 1.0
#endif

#ifndef psx_enable_dither
#define psx_enable_dither 1.0
#endif
#ifndef psx_dither_strength
#define psx_dither_strength 1.5
#endif
#ifndef psx_pattern_scale
#define psx_pattern_scale 1.0
#endif

#ifndef psx_color_steps
#define psx_color_steps 31.0
#endif

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform vec4 entityColor;
uniform float blindness;
uniform int isEyeInWater;

varying vec4 vertexColor;
varying vec2 texcoord;
varying vec2 affineUV;
varying vec2 lightmapUV;
varying float affineW;
varying vec4 tileBounds;

const int BAYER_4X4[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

float bayer(vec2 pos) {
    vec2 scaled = floor(pos / psx_pattern_scale);
    int xi = int(scaled.x) & 3;
    int yi = int(scaled.y) & 3;
    return float(BAYER_4X4[yi * 4 + xi]) / 16.0;
}

vec3 quantize(vec3 color) {
    return floor(color * psx_color_steps) / psx_color_steps;
}

vec4 quantize(vec4 color) {
    return floor(color * psx_color_steps) / psx_color_steps;
}

vec3 applyOrderedDither(vec3 color, vec2 fragCoord) {
    if (psx_enable_dither < 0.5) return color;

    float threshold = bayer(fragCoord) * psx_dither_strength;
    color = floor(color * psx_color_steps + threshold);
    return color / psx_color_steps;
}

float computeFogFactor() {
    float fog = isEyeInWater > 0
        ? 1.0 - exp(-gl_FogFragCoord * gl_Fog.density)
        : clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
    return fog;
}

void main() {
    vec2 rawWarp = affineUV / max(affineW, 0.001);
    vec2 tileSize = tileBounds.zw - tileBounds.xy;
    vec2 limit = tileSize * 0.125 * psx_warp_limit;
    vec2 delta = rawWarp - texcoord;

    delta = clamp(delta, -limit, limit);
    vec2 finalUV = texcoord + delta;
    finalUV = clamp(finalUV, tileBounds.xy, tileBounds.zw);

    vec3 lightRaw = texture2D(lightmap, lightmapUV).rgb;
    vec3 smoothLit = (1.0 - blindness) * lightRaw;
    vec3 bandedLit = quantize(smoothLit);
    vec4 bandedVertexColor = quantize(vertexColor);

    vec4 texSample = texture2D(texture, finalUV);
    texSample.rgb = quantize(texSample.rgb);

    vec4 shadedColor = bandedVertexColor * vec4(bandedLit, 1.0) * texSample;
    shadedColor.rgb = quantize(shadedColor.rgb);

    shadedColor.rgb = mix(shadedColor.rgb, entityColor.rgb, entityColor.a);
    shadedColor.rgb = applyOrderedDither(shadedColor.rgb, gl_FragCoord.xy);

    float fogFactor = computeFogFactor();
    vec3 fogColor = quantize(gl_Fog.color.rgb);
    shadedColor.rgb = mix(shadedColor.rgb, fogColor, fogFactor);

    gl_FragData[0] = shadedColor;
}