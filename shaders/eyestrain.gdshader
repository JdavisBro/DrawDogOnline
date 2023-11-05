shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 mult = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 add = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
        COLOR = textureLod(screen_texture, SCREEN_UV, 0.0) * mult + add;
}
