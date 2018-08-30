#version 450

uniform vec4 Colour;

in vec4 sv;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;

out vec4 finalColor;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

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
    float a = 0.75 + 0.25 * (cos(7 * RT + 7 * rand(sv.yx) * rand(sv.xz)));
    finalColor = vec4(a * rand(sv.xy), a * rand(sv.yz), a * rand(sv.zx), 1.0);
  }
}
