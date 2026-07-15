#ifndef PSX_VERTEX_GLSL
#define PSX_VERTEX_GLSL

uniform float viewWidth;
uniform float viewHeight;

vec4 QuantizeScreen(vec4 clipPos, float snapRes) {
    if (psx_enable_vertex_snap < 0.5) return clipPos;

    float aspectRatio = viewWidth / max(viewHeight, 1.0);
    vec2 screenRes = vec2(snapRes * aspectRatio, snapRes);
    vec2 ndc = clipPos.xy / clipPos.w;
    vec2 ndcGrid = max(screenRes * 0.5, vec2(1.0));
    vec2 snappedNdc = floor(ndc * ndcGrid + 0.5) / ndcGrid;

    clipPos.xy = snappedNdc * clipPos.w;
    return clipPos;
}

float QuantizeLight(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

#endif