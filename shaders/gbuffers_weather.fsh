#version 120

#include "/settings.glsl"

uniform sampler2D texture;

varying vec2 baseUV;
varying vec4 vertexColor;

void main() {
    vec4 texel = texture2D(texture, baseUV) * vertexColor;

    if (texel.a <= 0.01) {
        discard;
    }

    float isSnow = (texel.r > 0.8) ? 1.0 : 0.0;
    float brightness = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(brightness);

    /* DRAWBUFFERS:07 */
    gl_FragData[0] = vec4(grayscale, texel.a);
    gl_FragData[1] = vec4(texel.a, isSnow, 0.0, 1.0);
}