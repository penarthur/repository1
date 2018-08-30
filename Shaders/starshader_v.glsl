#version 450 core

layout (location = 0) in vec3 Position;
layout (location = 1) in vec3 Normal;
layout (location = 2) in vec2 TexCoord;

uniform vec4 Scale;
uniform mat4 Model;
uniform mat4 View;
uniform mat4 Projection;
uniform float RT;

out vec4 sv;
out vec3 n;
out vec2 t;
out float d;

void main(void)
{
  vec4 ScaledVec = vec4(Position, 1.0) * Scale; // scale individual model vertices
  vec4 ModelVec = Model * ScaledVec;            // reposition model in world space
  vec4 ViewVec = View * ModelVec;               // transform to view space
  gl_Position = Projection * ViewVec;           // project onto screen

//  sv = gl_Position;
  sv = ModelVec;
}

