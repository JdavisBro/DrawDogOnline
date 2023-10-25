shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float boil = 0;

void vertex() {
	vec2 canvaspos = (CANVAS_MATRIX * vec4(UV, 0.0, 1.0)).xy * vec2(2.0);
	vec4 noiseSample = texture( noise, (canvaspos)+(vec2(boil)) );
	vec2 noiseColor = vec2(TEXTURE_PIXEL_SIZE.x*2.0*noiseSample.r,TEXTURE_PIXEL_SIZE.y*2.0*noiseSample.g) - TEXTURE_PIXEL_SIZE;
	
	UV = UV + noiseColor;
}

void fragment() {
	COLOR.a = floor(COLOR.a + 0.5);
}
