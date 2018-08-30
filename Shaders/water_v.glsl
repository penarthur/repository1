#version 450 core

layout (location = 0) in vec3 Position;
layout (location = 1) in vec3 Normal;
layout (location = 2) in vec2 TexCoord;

uniform vec3 Eye;
uniform vec4 Scale;
uniform mat4 Model;
uniform mat4 View;
uniform mat4 Projection;
uniform float RT;

out vec4 v;
out vec3 n;
out vec2 t;
out float d;
out float originalY;

void main(void)
{
  float TWOPI = 6.28318531;

  vec4 ScaledVec = vec4(Position, 1.0) * Scale;                 // scale individual model vertices
  vec4 ModelVec = Model * ScaledVec;                            // reposition model in world space
  originalY = ModelVec.y;

  if (distance(Eye, ScaledVec.xyz) < 100)
  {
        float SwellF = TWOPI * (RT / 16.0 + ModelVec.z / 16.0);          // period = 16s, wavelength = 16m
        float Swell = 0.5 * sin(SwellF);        // 1m amplitude

        float RippleF = TWOPI * (RT / 4.0 + (ModelVec.x + ModelVec.z) / 4.0);          // period = 4s, wavelength = 4m
        float Ripple = 0.1 * sin(RippleF);      // .1m amplitude

        ModelVec.y = Swell + Ripple;

// https://www.khanacademy.org/math/multivariable-calculus/integrating-multivariable-functions/line-integrals-in-vector-fields-articles/a/constructing-a-unit-normal-vector-to-curve

//  d/dx a.sin(b.x) = a.b.cos(b.x)

        float a = - (0.5 * TWOPI / 16.0) * cos(SwellF);              // z axis part of normal to sin() is - cos()
        float ma = sqrt(a * a + 1);
        n.x = 0.0;
        n.y = 1.0 / ma;
        n.z = a / ma;

        float b = - (0.1 * TWOPI / 4.0) * cos(RippleF);             // z axis part of normal to sin() is - cos(), relative amplitutde = 2
        float mb = sqrt(2 * b * b + 1);
        n.x += b / mb;
        n.y += 1.0 / mb;
        n.z += b / mb;
        n = - n / 2.0;                                            // halve it because there are two unit normals???
  }
  else
  {
        n = vec3(0, -1, 0);
        ModelVec.y = 0;
  }

  vec4 ViewVec = View * ModelVec;               // transform to view space
  gl_Position = Projection * ViewVec;           // project onto screen

  v = ModelVec;
  t = TexCoord;
  d = distance(Eye, ModelVec.xyz);
}
