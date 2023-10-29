shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float boil = 0.0;

const float boilpixel = 1.0;

void vertex() {
	vec2 screenpos = (SCREEN_MATRIX * vec4(VERTEX, 1.0, 1.0)).xy;
	vec4 noiseSample = texture( noise, (screenpos)+(vec2(boil)) );
	vec2 noiseColor = vec2(TEXTURE_PIXEL_SIZE.x* (boilpixel*2.0) *noiseSample.r,TEXTURE_PIXEL_SIZE.y* (boilpixel*2.0) *noiseSample.g) - (TEXTURE_PIXEL_SIZE * vec2(boilpixel, boilpixel));
	
	UV = UV + noiseColor;
}

void fragment() {
	COLOR.a = floor(COLOR.a + 0.9);
}
