#version 120

varying vec4 vertexColor;
varying vec2 baseUV;

void main() {
    gl_Position = ftransform();
    vertexColor = gl_Color;
    baseUV = gl_MultiTexCoord0.xy;
}