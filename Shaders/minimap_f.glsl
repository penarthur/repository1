#version 450

uniform vec4 Colour;
uniform int Textures;
uniform sampler2D Tex0;
uniform sampler2D Tex1;
uniform sampler2D Tex2;

in vec2 t;

out vec4 finalColor;

void main(void)
{
   if (Textures == 0)
     finalColor = Colour;
   else
     finalColor = texture(Tex0, vec2(t.x, t.y));
}
