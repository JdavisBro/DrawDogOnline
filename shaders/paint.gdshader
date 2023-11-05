shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float boil = 0.0;

const float boilpixel = 1.0;

void fragment() {
	vec4 noiseSample = texture( noise, UV+vec2(boil) );
	vec2 noiseColor = vec2(TEXTURE_PIXEL_SIZE.x* (boilpixel*2.0) *noiseSample.r, TEXTURE_PIXEL_SIZE.y* (boilpixel*2.0) *noiseSample.g) - (TEXTURE_PIXEL_SIZE * vec2(boilpixel, boilpixel));
	COLOR = texture( TEXTURE, UV+noiseColor );
	COLOR.a = min(1.0, COLOR.a+0.5);
}
