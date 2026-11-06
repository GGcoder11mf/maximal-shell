#version 300 es
// Extra saturation that protects already-saturated colours
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;
void main() {
    vec4 c = texture(tex, v_texcoord);
    float l = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
    float amt = 0.45 * (1.0 - (mx - mn));
    fragColor = vec4(mix(vec3(l), c.rgb, 1.0 + amt), c.a);
}
