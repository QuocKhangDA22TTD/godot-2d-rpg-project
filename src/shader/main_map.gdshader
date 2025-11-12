shader_type canvas_item;

void fragment() {
    COLOR = texture(TEXTURE, UV) * vec4(1, 0.9, 1, 1);
}
