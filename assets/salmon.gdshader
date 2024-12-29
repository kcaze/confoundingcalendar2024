shader_type canvas_item;

uniform bool in_water;
uniform int rotation;
uniform int frames;
uniform bool flip_v;

void fragment() {
	if (in_water) {
		vec2 uv = mod(UV * vec2(float(frames), float(1)), 1);
		if (
			(rotation == 0 && uv.y > 0.75) ||
			(rotation == 90 && !flip_v && uv.x < 0.25) ||
			(rotation == 90 && flip_v && uv.x > 0.75)
		) {
			uv = UV / TEXTURE_PIXEL_SIZE;
			float dither1 = mod(uv.x + uv.y,2);
			if (dither1 < 1.0) {
				COLOR = vec4(0,0,0,0);
			}
			if (COLOR.r <= 0.2 && COLOR.g <= 0.2 && COLOR.b <= 0.2) {
				COLOR = vec4(0,0,0,0);
			}
		}
		else if (
			(rotation == 0 && uv.y > 0.5) ||
			(rotation == 90 && !flip_v && uv.x < 0.5) ||
			(rotation == 90 && flip_v && uv.x > 0.5)
		) {
			uv = UV / TEXTURE_PIXEL_SIZE;
			float dither = mod(uv.x + uv.y,2);
			if (dither < 1.0) {
				COLOR = vec4(0,0,0,0);
			}
			if (COLOR.r <= 0.2 && COLOR.g <= 0.2 && COLOR.b <= 0.2) {
				COLOR = vec4(0,0,0,0);
			}
		}

	}
	// Called for every pixel the material is visible on.
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
