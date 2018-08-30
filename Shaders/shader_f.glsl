#version 450

uniform int Textures;
uniform sampler2D Tex0;
uniform sampler2D Tex1;
uniform sampler2D Tex2;
uniform int UseEffect;

struct TLight {
   vec4 Position;
   vec4 Colour;
};

layout(std140, binding = 1) uniform EffectBlock
{
    vec3 Position;
    vec4 Ambient;
    vec4 Diffuse;
    vec4 Specular;
    vec4 Transparent;

    float Transparency;
    float IOR;
    float Shininess;
    float Spare;
} Effect;

layout(std140, binding = 3) uniform LightBlock
{
  TLight Lights[16];
} Lighting;

in vec4 v;
in vec3 l;
in vec3 n;
in vec2 t;
in float d;
in vec4 c;

uniform int id1, id2, id3;
uniform bool selmode;
uniform float RT;
uniform float ET;
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
  if (selmode)
  {
    float r = id1 / 255.0;
    float g = id2 / 255.0;
    float b = id3 / 255.0;

    finalColor = vec4(r, g, b, 1.0);
  }
  else
  {
    vec4 DiffC;

    if (UseEffect == 1)
    {
      if (Textures > 0)
        DiffC = texture(Tex0, vec2(t.x, t.y));
      else
        DiffC = Effect.Diffuse;

      dolights(Effect.Ambient, DiffC, Effect.Specular);

      vec4 T = (Tambient + Tdiffuse + Tspecular) / Lights;
      finalColor = vec4(T.r, T.g, T.b, Effect.Transparency);
    }
    else
    {
      if (Textures > 0)
        DiffC = texture(Tex0, vec2(t.x, t.y));
      else
        DiffC = c;

      dolights(c, DiffC, c);

      vec4 T = (Tambient + Tdiffuse + Tspecular) / Lights;
      finalColor = vec4(T.r, T.g, T.b, c.a);
    }
  }
}
