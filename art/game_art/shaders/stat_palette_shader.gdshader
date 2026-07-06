shader_type canvas_item;

uniform sampler2D gradient : source_color;

void fragment() {
    vec4 src = texture(TEXTURE, UV);
    float luma = dot(src.rgb, vec3(0.299, 0.587, 0.114));
    vec3 mapped = texture(gradient, vec2(luma, 0.0)).rgb;
    COLOR = vec4(mapped, src.a);
}