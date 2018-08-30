#version 450 core

layout (location = 0) in vec3 Position;
layout (location = 1) in vec3 Normal;
layout (location = 2) in vec2 TexCoord;
layout (location = 3) in float Extra;

uniform vec3 Eye;
uniform vec4 Scale;
uniform mat4 Model;
uniform mat4 View;
uniform mat4 Projection;
uniform float ET;

out vec4 v;
out vec3 n;
out vec2 t;

void main(void)
{
  vec4 ScaledVec = vec4(Position, 1.0) * Scale; // scale individual model vertices

  ScaledVec.x = ScaledVec.x * 0.5 * ET;
  ScaledVec.y = abs(ScaledVec.y) * 0.5 * ET - 0.25 * 10 * ET * ET;
  ScaledVec.z = ScaledVec.z * 0.5 * ET;

  vec4 ModelVec = Model * ScaledVec;            // reposition model in world space
  vec4 ViewVec = View * ModelVec;               // transform to view space
  gl_Position = Projection * ViewVec;           // project onto screen

  gl_PointSize = Extra;

  v = vec4(Position, 1.0);
  n = Normal;
  t = TexCoord;
}


