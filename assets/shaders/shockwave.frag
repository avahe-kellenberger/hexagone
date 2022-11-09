#version 140

uniform sampler2D tex;

uniform sampler2D screen_texture;

varying vec2 vertex;
varying vec4 color;
varying vec2 texCoord;

uniform float time;
uniform vec2 resolution;

uniform float force = 0.0;
uniform float size = 0.0;
uniform float thickness = 0.0;
uniform vec2 center = vec2(0.5, 0.5);

void main(void) {
  float ratio = resolution.y / resolution.x;
  float distFromCenter = length(texCoord - center);
  float mask =
    (1.0 - smoothstep(size - 0.1, size, distFromCenter)) *
    smoothstep(size - thickness - 0.1, size - thickness, distFromCenter);

  vec2 displacement = normalize(texCoord - center) * force * mask;
  gl_FragColor = texture(screen_texture, texCoord - displacement);
}

