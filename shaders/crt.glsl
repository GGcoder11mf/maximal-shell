#version 300 es
// Retro CRT: scanlines + vignette + slight chromatic aberration
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec2 uv = v_texcoord;
    vec2 d = (uv - 0.5) * 0.0025;
    vec3 c = vec3(texture(tex, uv + d).r, texture(tex, uv).g, texture(tex, uv - d).b);
    float scan = 0.88 + 0.12 * sin(uv.y * 1080.0 * 3.14159);
    float vig = smoothstep(0.95, 0.35, length(uv - 0.5));
    fragColor = vec4(c * scan * mix(0.75, 1.0, vig), 1.0);
}
