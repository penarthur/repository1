#version 450

uniform vec4 Colour;
uniform int Textures;
uniform sampler2D Tex0;
uniform sampler2D Tex1;
uniform sampler2D Tex2;

in vec4 v;
in vec3 n;
in vec2 t;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;
uniform float ET;

out vec4 finalColor;

void main(void)
{
  finalColor = mix(vec4(1.0, 1.0, 0.0, 1.0), vec4(1.0, 0.0, 0.0, 1.0), ET / 2.5);
}
