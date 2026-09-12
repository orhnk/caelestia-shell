#version 440

layout(location = 0) in vec2 v_uv;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    float qt_Opacity;
    vec2 texel;
    float radius;
    vec4 topColor;
    vec4 bottomColor;
};

layout(binding = 1) uniform sampler2D srcTex;

// Rings walked outwards while looking for the nearest inked pixel.
const int RINGS = 8;
// Width of the antialiased falloff just outside the outline.
const float AA = 0.75;
const float DIAG = 0.70710678;

float coverage(vec2 uv) {
    return texture(srcTex, uv).a;
}

// Largest coverage of the eight neighbours sitting `t` logical pixels away.
float ringCoverage(vec2 uv, float t) {
    vec2 o = texel * t;
    float m = coverage(uv + vec2(o.x, 0.0));
    m = max(m, coverage(uv - vec2(o.x, 0.0)));
    m = max(m, coverage(uv + vec2(0.0, o.y)));
    m = max(m, coverage(uv - vec2(0.0, o.y)));
    vec2 d = o * DIAG;
    m = max(m, coverage(uv + vec2(d.x, d.y)));
    m = max(m, coverage(uv + vec2(d.x, -d.y)));
    m = max(m, coverage(uv - vec2(d.x, d.y)));
    m = max(m, coverage(uv - vec2(d.x, -d.y)));
    return m;
}

// Distance, in logical pixels, from uv to the closest inked pixel, capped at
// maxDist. Walking the rings outwards lets pixels next to a glyph stop early.
float distToInk(vec2 uv, float maxDist) {
    for (int i = 1; i <= RINGS; ++i) {
        float t = maxDist * float(i) / float(RINGS);
        if (ringCoverage(uv, t) > 0.5)
            return t;
    }
    return maxDist;
}

void main() {
    float base = coverage(v_uv);
    float dist = base > 0.5 ? 0.0 : distToInk(v_uv, radius + AA);

    // Opaque out to `radius`, then faded over the last AA pixels.
    float ring = 1.0 - smoothstep(radius - AA, radius + AA, dist);
    // Leave the glyph itself alone so the text keeps its own colour.
    float alpha = clamp(ring - smoothstep(0.3, 0.7, base), 0.0, 1.0);
    if (alpha <= 0.001)
        discard;

    float a = alpha * qt_Opacity;
    // Qt composites ShaderEffect output as premultiplied alpha.
    fragColor = vec4(mix(topColor.rgb, bottomColor.rgb, clamp(v_uv.y, 0.0, 1.0)) * a, a);
}
