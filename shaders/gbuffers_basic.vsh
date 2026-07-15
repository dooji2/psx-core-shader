#version 120

#include "/settings.glsl"
#include "/lib/psx_vertex.glsl"

uniform mat4 gbufferModelViewInverse;

varying vec4 vertexColor;

void main() {
    vec3 viewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;
    gl_Position = QuantizeScreen(gl_ProjectionMatrix * vec4(viewPosition, 1.0), psx_vertex_resolution);
    gl_FogFragCoord = length(viewPosition);
    vec3 viewNormal = gl_NormalMatrix * gl_Normal;
    vec3 worldNormal = (gbufferModelViewInverse * vec4(viewNormal, 0.0)).xyz;

    vec3 n2 = worldNormal * worldNormal;
    float lightFactor = min(
        dot(n2, vec3(0.62, 0.72, 0.82)) + n2.y * worldNormal.y * 0.23,
        1.0
    );

    lightFactor = QuantizeLight(lightFactor, psx_light_steps);
    vertexColor = vec4(gl_Color.rgb * lightFactor, gl_Color.a);
}