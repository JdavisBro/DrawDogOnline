shader_type canvas_item;

uniform sampler2D noise : repeat_enable;
uniform float boil = 0.0;

const float boilpixel = 1.0;
const vec2 imsize = vec2(1./1920., 1./1080.);

uniform sampler2D paint_tex: filter_nearest, repeat_disable;
const float xsz = 1. / 162.;
const float ysz = 1. / 91.;

void fragment() {
	vec4 noiseSample = texture( noise, UV+vec2(boil) );
	vec2 noiseColor = vec2(imsize.x* (boilpixel*2.0) *noiseSample.r, imsize.y* (boilpixel*2.0) *noiseSample.g) - (imsize * vec2(boilpixel, boilpixel));
	vec2 new_UV = UV + noiseColor;

	vec4 v[] = {
		texture(TEXTURE, new_UV),
		texture(TEXTURE, vec2(new_UV.x+xsz, new_UV.y)),
		texture(TEXTURE, vec2(new_UV.x+xsz, new_UV.y+ysz)),
		texture(TEXTURE, vec2(new_UV.x, new_UV.y+ysz))
	};
	COLOR = vec4(1);
	for (int i = 0; i < 4; i++) {
		vec4 col = v[i];
		if (col.a == 0.) {
			continue;
		}
		int val = int(v[0] == col) + (int(v[1] == col) << 1) + (int(v[2] == col) << 2) + (int(v[3] == col) << 3);
		vec2 uv_pos = vec2(162. * new_UV.x, 91. * new_UV.y);
		vec2 offset = uv_pos - floor(uv_pos);
		offset.x = (offset.x + float(val))*0.0625;
		vec4 col_res = texture(paint_tex, offset);
		if (col_res.a > 0.) {
			COLOR = col_res * col;
			break;
		}
	}
}
