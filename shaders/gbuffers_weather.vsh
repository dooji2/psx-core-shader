#version 120

varying vec2 baseUV;
varying vec4 vertexColor;

void main() {
    gl_Position = ftransform();
    baseUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vertexColor = gl_Color;
}