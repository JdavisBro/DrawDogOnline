shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	float alpha = texture( TEXTURE, UV ).a;
	COLOR = texture( screen_texture, SCREEN_UV );
	COLOR = vec4(1.0 - COLOR.r, 1.0 - COLOR.g, 1.0 - COLOR.b, alpha);
}
