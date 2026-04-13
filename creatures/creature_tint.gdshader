shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.85;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float brightness = (tex.r + tex.g + tex.b) / 3.0;
    float tint_strength = 1.0 - smoothstep(highlight_threshold, 1.0, brightness);
    tex.rgb *= mix(vec3(1.0), tint_color.rgb, tint_strength);
    COLOR = tex;
}