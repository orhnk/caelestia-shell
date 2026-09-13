#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fillColor;
    vec4 radii; // xy: outline uv radius, zw: aura uv radius
    vec4 misc; // x: aura strength
};
layout(binding = 1) uniform sampler2D maskTex;
layout(binding = 2) uniform sampler2D gradTex;
void main() {
    vec2 uv = qt_TexCoord0;
    float m = texture(maskTex, uv).a;
    vec2 o = radii.xy;
    vec2 a = radii.zw;
    float ring = m;
    ring = max(ring, texture(maskTex, uv + vec2(o.x, 0.0)).a);
    ring = max(ring, texture(maskTex, uv - vec2(o.x, 0.0)).a);
    ring = max(ring, texture(maskTex, uv + vec2(0.0, o.y)).a);
    ring = max(ring, texture(maskTex, uv - vec2(0.0, o.y)).a);
    ring = max(ring, texture(maskTex, uv + o * 0.7071).a);
    ring = max(ring, texture(maskTex, uv - o * 0.7071).a);
    ring = max(ring, texture(maskTex, uv + vec2(o.x, -o.y) * 0.7071).a);
    ring = max(ring, texture(maskTex, uv + vec2(-o.x, o.y) * 0.7071).a);
    float halo = 0.0;
    halo += texture(maskTex, uv + vec2(a.x, 0.0)).a;
    halo += texture(maskTex, uv - vec2(a.x, 0.0)).a;
    halo += texture(maskTex, uv + vec2(0.0, a.y)).a;
    halo += texture(maskTex, uv - vec2(0.0, a.y)).a;
    halo += texture(maskTex, uv + a * 0.7071).a;
    halo += texture(maskTex, uv - a * 0.7071).a;
    halo += texture(maskTex, uv + vec2(a.x, -a.y) * 0.7071).a;
    halo += texture(maskTex, uv + vec2(-a.x, a.y) * 0.7071).a;
    halo *= 0.125 * misc.x;
    float outline = clamp(ring - m, 0.0, 1.0);
    float aura = clamp(halo - max(m, outline), 0.0, 1.0);
    vec3 g = texture(gradTex, uv).rgb;
    vec3 col = fillColor.rgb * m + g * (outline + aura);
    float alpha = max(m * fillColor.a, max(outline, aura));
    fragColor = vec4(col, alpha) * qt_Opacity;
}
