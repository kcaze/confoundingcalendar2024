shader_type canvas_item;

uniform float t;

void fragment() {
	float row = floor(UV.y / TEXTURE_PIXEL_SIZE.y);
	if (mod(row,8.0f) < 4.0f) {
		if (UV.x > t) {
			COLOR = vec4(0,0,0,0);
		}
	}
	else {
		if (1.0f-UV.x > t) {
			COLOR = vec4(0,0,0,0);
		}
	}
}