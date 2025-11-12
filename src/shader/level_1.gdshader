shader_type canvas_item;

void fragment() {
    // Nhân với màu tùy chỉnh
    COLOR = texture(TEXTURE, UV) * vec4(1, 1, 1, 1);
}
