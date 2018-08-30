#version 450

uniform vec4 Colour;
uniform int Textures;
uniform sampler2D Tex0;
uniform sampler2D Tex1;
uniform sampler2D Tex2;

struct TLight {
   vec4 Position;
   vec4 Colour;
};

layout(std140, binding = 3) uniform LightBlock
{
  TLight Lights[16];
} Lighting;

in vec4 v;
in vec3 n;
in vec2 t;
in float d;
in float ex;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;
uniform int Lights;

out vec4 finalColor;

vec4 Tambient = vec4(0, 0, 0, 0);
vec4 Tdiffuse = vec4(0, 0, 0, 0);
vec4 Tspecular = vec4(0, 0, 0, 0);

vec3 normVec = normalize(n);

void dolights(vec4 camb, vec4 cdiff, vec4 cspec)
{
  Tambient = camb * Lighting.Lights[0].Colour;

  if (Lights > 1)
  {
    for (int i = 1; i < Lights; i ++)
    {
      vec3 lightDir = normalize(Lighting.Lights[i].Position.xyz - v.xyz);
      float d = dot(normVec, lightDir);

      if (d > 0.0f)
      {
        Tdiffuse = Tdiffuse + d * cdiff * Lighting.Lights[i].Colour;
        float spec = pow(max(d, 0.0), 32);
        Tspecular = Tspecular + cspec * spec * Lighting.Lights[i].Colour;
      }
    }
  }
}

void main(void)
{
  if (Textures != 0)
  {
           float sd = clamp(d, 0, 200) / 200;

           vec4 t0 = mix(texture(Tex0, vec2(t.x, t.y)), texture(Tex0, vec2(0, 0)), sd);
           vec4 t1 = mix(texture(Tex1, vec2(t.x, t.y)), texture(Tex1, vec2(0, 0)), sd);
           vec4 t2 = mix(texture(Tex2, vec2(t.x, t.y)), texture(Tex2, vec2(0, 0)), sd);

           float w = clamp(v.y - 1.0, 0, 1) * 1.0;
           finalColor = mix(t0, t1, w);

           w = clamp(v.y + 2.0, -2, 0) * -0.5;
           finalColor = mix(finalColor, t2, w);
  }
  else
           finalColor = Colour;

  // override colour depending on Extra value - makes ground go orange/red etc.
  finalColor = mix(finalColor, vec4(ex, 1 - 0.75 * ex, 0.0, 1.0), ex);

  dolights(finalColor, finalColor, finalColor);
  vec4 T = (Tambient + Tdiffuse + Tspecular) / Lights;

  finalColor = vec4(T.r, T.g, T.b, 1.0);
}
