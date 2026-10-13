shader_type canvas_item;

// Only the two cloth blues change. Skin, steel, outlines and gold stay intact.
uniform bool red_team = false;
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	if (red_team) {
		if (distance(source.rgb, vec3(64.0, 88.0, 192.0) / 255.0) < 0.01) {
			source.rgb = vec3(154.0, 49.0, 54.0) / 255.0;
		} else if (distance(source.rgb, vec3(96.0, 152.0, 232.0) / 255.0) < 0.01) {
			source.rgb = vec3(228.0, 99.0, 88.0) / 255.0;
		}
	}
	COLOR = source * tint;
}
