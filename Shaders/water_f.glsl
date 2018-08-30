#version 450

uniform vec4 Colour;
uniform int Textures;
uniform sampler2D Tex0;

in vec4 v;
in vec3 n;
in vec2 t;
in float d;
in float originalY;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;

out vec4 finalColor;

void main(void)
{
  if (Textures != 0)
  {
    float sd = clamp(d, 0, 200) / 200;
    vec4 t0 = mix(texture(Tex0, vec2(t.x, t.y)), texture(Tex0, vec2(0, 0)), sd);

    finalColor = t0 * (0.05 + 0.95 * dot(vec3(0, -1, 0), n));

    float t = clamp(abs(originalY - v.y) * 10, 0, 1);
    finalColor = mix(vec4(1.0, 1.0, 1.0, 0.9), finalColor, t);
  }
  else
    finalColor = Colour * (0.05 + 0.95 * dot(vec3(0, -1, 0), n));
}

