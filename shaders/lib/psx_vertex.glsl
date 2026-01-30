#ifndef PSX_VERTEX_GLSL
#define PSX_VERTEX_GLSL

uniform float viewWidth;
uniform float viewHeight;

vec3 QuantizeWorld(vec3 worldPos, float snapNear, float snapFar, float snapCurve, float snapJitter, float depthRef) {
    float depth = length(worldPos);
    float t = pow(clamp(depth / max(depthRef, 1e-3), 0.0, 1.0), snapCurve);
    float stepWorld = mix(snapNear, snapFar, t);

    vec3 cell = floor(worldPos);
    float hash = fract(sin(dot(cell.xy, vec2(12.9898, 78.233)) + cell.z * 37.0) * 43758.5453);
    vec3 offset = vec3(hash - 0.5) * 0.2;

    vec3 snapped = floor(worldPos / stepWorld + 0.5 + offset) * stepWorld;
    if (snapJitter > 0.0) {
        float j = (fract(sin(dot(worldPos.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5) * snapJitter * stepWorld;
        snapped.xy += vec2(j);
    }

    return snapped;
}

float QuantizeLight(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

#endif