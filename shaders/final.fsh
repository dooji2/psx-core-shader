#version 120

#include "/settings.glsl"

#ifndef psx_enable_dither
#define psx_enable_dither 1.0
#endif
#ifndef psx_dither_strength
#define psx_dither_strength 2.5
#endif
#ifndef psx_pattern_scale
#define psx_pattern_scale 2.0
#endif
#ifndef psx_color_steps
#define psx_color_steps 31.0
#endif
#ifndef psx_post_scale
#define psx_post_scale 1.0
#endif
#ifndef psx_post_contrast
#define psx_post_contrast 0.0
#endif
#ifndef psx_fog_enable
#define psx_fog_enable 1.0
#endif

#ifndef psx_fog_distance
#define psx_fog_distance 120.0
#endif
#ifndef psx_fog_noise
#define psx_fog_noise 0.1
#endif
#ifndef psx_fog_density
#define psx_fog_density 1.0
#endif

uniform sampler2D texture;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gaux4;

uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;

uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;

varying vec4 vertexColor;
varying vec2 baseUV;

const int BAYER_4X4[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

float bayer(vec2 pos) {
    vec2 scaled = floor(pos / psx_pattern_scale);
    int xi = int(scaled.x) & 3;
    int yi = int(scaled.y) & 3;
    return float(BAYER_4X4[yi * 4 + xi]) / 16.0;
}

float getLinearDepth(float depth) {
    return (2.0 * near * far) / (far + near - (depth * 2.0 - 1.0) * (far - near));
}

vec3 applyPS1ColorDepth(vec3 color, vec2 fragCoord) {
    float dither = 0.0;
    if (psx_enable_dither > 0.5) {
        dither = bayer(fragCoord) * psx_dither_strength;
    }

    color = floor(color * psx_color_steps + dither);
    return color / psx_color_steps;
}

vec3 applyContrast(vec3 color) {
    if (psx_post_contrast <= 0.0) return color;
    return clamp((color - 0.5) * (1.0 + psx_post_contrast) + 0.5, 0.0, 1.0);
}

float psxFogFactor(float depth, vec2 fragCoord) {
    if (psx_fog_enable < 0.5) return 0.0;

    float linearZ = getLinearDepth(depth);
    float density = psx_fog_density / psx_fog_distance;
    float fogT = 1.0 - exp(-pow(linearZ * density, 2.0));

    fogT = clamp(fogT + (bayer(fragCoord) - 0.5) * psx_fog_noise, 0.0, 1.0);
    return fogT;
}

void main() {
    vec2 screenRes = vec2(viewWidth, viewHeight);
    vec2 targetRes = max(screenRes * max(psx_post_scale, 0.01), vec2(1.0));
    vec2 screenUV = gl_FragCoord.xy / screenRes;

    vec2 quantizedUV = floor(screenUV * targetRes + 0.5) / targetRes;

    vec3 col = texture2D(texture, quantizedUV).rgb;

    float depth;
    if (isEyeInWater > 0) {
        depth = texture2D(depthtex1, quantizedUV).r;
    } else {
        depth = texture2D(depthtex0, quantizedUV).r;
    }

    vec4 weatherData = texture2D(gaux4, quantizedUV);
    float weatherMask = weatherData.r;
    float isSnow = weatherData.g;

    col = applyContrast(col);
    float fogT = psxFogFactor(depth, gl_FragCoord.xy);

    float pierce = 0.0;
    if (depth > 0.9999) {
        float luma = dot(col, vec3(0.299, 0.587, 0.114));
        pierce = smoothstep(0.92, 1.0, luma);
    }

    float caveFactor = float(eyeBrightnessSmooth.y) / 240.0;
    caveFactor = pow(caveFactor, 1.5);

    vec3 atmosphericColor = gl_Fog.color.rgb * caveFactor;

    fogT = clamp(fogT - pierce, 0.0, 1.0);
    if (psx_fog_enable > 0.5) {
        col = mix(col, atmosphericColor, fogT);
    }

    if (weatherMask > 0.01) {
        vec3 targetColor;
        float opacity;

        if (isSnow > 0.5) {
            targetColor = vec3(1.0) * (0.2 + 0.8 * caveFactor);
            opacity = 0.5;
        } else {
            vec3 rainGray = vec3(0.25, 0.3, 0.35);
            targetColor = rainGray * caveFactor;
            opacity = 0.2;
        }

        col = mix(col, targetColor, weatherMask * opacity);
    }

    if (isEyeInWater == 2) {
        vec2 lavaRes = max(screenRes * 0.35, vec2(1.0));
        vec2 lavaUV = floor(screenUV * lavaRes + 0.5) / lavaRes;

        vec3 lavaScene = texture2D(texture, lavaUV).rgb;

        float linearZ = getLinearDepth(depth);
        float lavaT = 1.0 - exp(-linearZ * 1.8);
        lavaT = clamp(lavaT, 0.0, 1.0);

        float base = 0.78;
        float n = (bayer(gl_FragCoord.xy) - 0.5) * 0.08;
        lavaT = clamp(max(lavaT, base) + n, 0.0, 1.0);

        vec3 lavaCol = vec3(0.90, 0.28, 0.04);

        float l = dot(lavaScene, vec3(0.299, 0.587, 0.114));
        lavaScene = mix(lavaScene, vec3(l), 0.85);

        col = mix(lavaScene, lavaCol, lavaT);
    }

    col = applyPS1ColorDepth(col, gl_FragCoord.xy);
    gl_FragData[0] = vec4(col, 1.0);
}