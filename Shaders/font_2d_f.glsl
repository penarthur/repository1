#version 450

uniform vec4 Colour;
uniform sampler2D Tex0;

in vec2 t;

out vec4 finalColor;

void main1(void)
{
   float delta = 1.0 / 16.0;

   vec4 p = texture(Tex0, vec2(t.x, t.y));

   float distance = (p.r + p.g + p.b) / 3.0;

   float alpha = smoothstep(0.5 - delta, 0.5 + delta, distance);
   finalColor = vec4(Colour.r, Colour.g, Colour.b, alpha);

}

void main(void)
{
   float s = texture(Tex0, vec2(t.x, t.y)).r;

      // Use fwidth() to figure out the scale factor between the encoded
      // distance and screen pixels. This uses finite differences with
      // neighboring fragment shaders to see how fast "sample" is changing.
      // This transform gives us signed distance in screen space.
//      float scale = 1.0 / fwidth(s);
      float scale = 1.0 / 0.5;
      float signedDistance = (s - 0.5) * scale;

      // Use two different distance thresholds to get dynamically stroked text
      float color = clamp(signedDistance + 0.5, 0.0, 1.0);
      float alpha = clamp(signedDistance + 0.5 + scale * 0.125, 0.0, 1.0);

      finalColor = vec4(color, color, color, 1.0) * alpha;
}
