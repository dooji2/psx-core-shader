#version 120

#include "/settings.glsl"
#include "/lib/psx_vertex.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

varying vec4 vertexColor;
varying vec2 baseUV;

void main() {
    vec3 viewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 worldPosition = (gbufferModelViewInverse * vec4(viewPosition, 1.0)).xyz;
    worldPosition = QuantizeWorld(worldPosition, psx_snap_world_near, psx_snap_world_far, psx_snap_curve, psx_snap_jitter, psx_snap_depth_ref);
    vec4 viewSnapped = gbufferModelView * vec4(worldPosition, 1.0);
    gl_Position = gl_ProjectionMatrix * viewSnapped;
    gl_FogFragCoord = length(worldPosition);
    vec3 viewNormal = gl_NormalMatrix * gl_Normal;
    vec3 worldNormal = (gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz;

    vec3 n2 = worldNormal * worldNormal;
    float lightFactor = min(
        dot(n2, vec3(0.62, 0.72, 0.82)) + n2.y * worldNormal.y * 0.23,
        1.0
    );

    lightFactor = QuantizeLight(lightFactor, psx_light_steps);
    vertexColor = vec4(gl_Color.rgb * lightFactor, gl_Color.a);
    baseUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}