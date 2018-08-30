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

out vec4 finalColor;

void main(void)
{
  if (selmode)
  {
    float r = id1 / 255.0;
    float g = id2 / 255.0;
    float b = id3 / 255.0;

    finalColor = vec4(r, g, b, 1.0);
  }
  else
  {
    if (Textures > 0)
    {
      finalColor = texture(Tex0, vec2(t.x, t.y));
//      finalColor = finalColor * (0.5 + 0.5 * dot(vec3(0, -1, 0), n));
    }
    else
    {
      finalColor = Colour;
//      finalColor = finalColor * (0.95 + 0.05 * dot(vec3(-0.7, -0.7, 0), n));
    }
  }
}
