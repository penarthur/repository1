#version 450

uniform vec4 Colour;
uniform int Textures;
uniform sampler2D Tex0;
uniform sampler2D Tex1;
uniform sampler2D Tex2;

in vec4 v;
in vec3 n;
in vec2 t;
in float d;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;
uniform float ET;

out vec4 finalColor;

void main(void)
{
   float delta = 1.0 / 16.0;

   vec4 p = texture(Tex0, vec2(t.x, t.y));

   float distance = (p.r + p.g + p.b) / 3.0;

   float alpha = smoothstep(0.5 - delta, 0.5 + delta, distance);

   finalColor = vec4(Colour.r, Colour.g, Colour.b, alpha);
}
