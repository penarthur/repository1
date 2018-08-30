#version 450 core

layout (location = 0) in vec3 Position;
layout (location = 1) in vec3 Normal;
layout (location = 2) in vec2 TexCoord;

uniform float AR;
uniform float SR;
uniform float CR;

out vec2 t;

void main(void)
{
  vec3 Rotated;

  Rotated.x = (Position.x - 0.5) * CR - (Position.y - 0.5) * SR;
  Rotated.y = (Position.y - 0.5) * CR + (Position.x - 0.5) * SR;
  Rotated.z = Position.z;

  gl_Position = vec4(0.86 + (0.25 * Rotated.x) / AR, -0.82 + 0.25 * Rotated.y, Rotated.z, 1.0);

  t = TexCoord;
}


