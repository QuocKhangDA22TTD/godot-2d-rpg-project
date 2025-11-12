shader_type canvas_item;

uniform vec4 hit_flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool hit_flash_on = false;

void fragment() {
	// Lấy màu gốc từ texture (TEXTURE có sẵn trong Godot)
	vec4 tex_color = texture(TEXTURE, UV);

	vec3 final_rgb = hit_flash_on ? hit_flash_color.rgb : tex_color.rgb;

	// Nhân với màu tùy chỉnh
	COLOR = vec4(final_rgb, tex_color.a);
}
