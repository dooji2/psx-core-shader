#version 120

#include "/settings.glsl"
#include "/lib/psx_vertex.glsl"

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

varying vec4 vertexColor;

void main() {
    vec3 viewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vec3 worldPosition = (gbufferModelViewInverse * vec4(viewPosition, 1.0)).xyz;
    worldPosition = QuantizeWorld(worldPosition, psx_snap_world_near, psx_snap_world_far, psx_snap_curve, psx_snap_jitter, psx_snap_depth_ref);
    vec4 viewSnapped = gbufferModelView * vec4(worldPosition, 1.0);
    gl_Position = gl_ProjectionMatrix * viewSnapped;
    gl_FogFragCoord = length(worldPosition);
    vertexColor = gl_Color;
}