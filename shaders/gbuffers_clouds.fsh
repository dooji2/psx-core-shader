#version 120

#include "/settings.glsl"

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
uniform float blindness;
uniform int isEyeInWater;

varying vec4 vertexColor;
varying vec2 baseUV;

const int BAYER_4X4[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

float bayer(vec2 pos) {
    vec2 scaled = floor(pos / psx_pattern_scale);
    int xi = int(scaled.x) & 3;
    int yi = int(scaled.y) & 3;
    return float(BAYER_4X4[yi * 4 + xi]) / 16.0;
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
    vec3 visibility = vec3(1.0 - blindness);
    vec4 shadedColor = vertexColor * vec4(visibility, 1.0) * texture2D(texture, baseUV);
    shadedColor.rgb = applyOrderedDither(shadedColor.rgb, gl_FragCoord.xy);
    float fogFactor = computeFogFactor();
    shadedColor.rgb = mix(shadedColor.rgb, gl_Fog.color.rgb, fogFactor);
    gl_FragData[0] = shadedColor;
}