shader_type canvas_item;
render_mode unshaded;

#define MAXCOLORS 16

// Godot 4 screen texture
uniform sampler2D screen_tex : hint_screen_texture;

uniform bool enabled = true;
uniform bool dithering = true;
uniform int colors : hint_range(1, MAXCOLORS) = 12;
uniform int dither_size : hint_range(1, 8) = 1;

float dithering_pattern(ivec2 fragcoord) {
	const float pattern[] = {
		0.00, 0.50, 0.10, 0.65, 
		0.75, 0.25, 0.90, 0.35, 
		0.20, 0.70, 0.05, 0.50, 
		0.95, 0.40, 0.80, 0.30
	};

	int x = fragcoord.x % 4;
	int y = fragcoord.y % 4;
	return pattern[y * 4 + x];
}

float reduce_color(float raw, float dither, int depth) {
	float div = 1.0 / float(depth);
	int i = 0;

	while (i <= MAXCOLORS) {
		if (raw > div * float(i + 1)) {
			i++;
			continue;
		}

		if (raw * float(depth) - float(i) <= dither * 0.999) {
			return div * float(i);
		} else {
			return div * float(i + 1);
		}
	}
	return 0.0;
}

void fragment() {
	vec4 raw = texture(screen_tex, SCREEN_UV);
	ivec2 uv = ivec2(FRAGCOORD.xy / float(dither_size));

	if (enabled) {
		float d = 1.0;
		if (dithering) {
			d = dithering_pattern(uv);
		}

		COLOR.r = reduce_color(raw.r, (d - 0.5) * d + 0.5, colors - 1);
		COLOR.g = reduce_color(raw.g, (d - 0.5) * d + 0.5, colors - 1);
		COLOR.b = reduce_color(raw.b, (d - 0.5) * d + 0.5, colors - 1);
		COLOR.a = raw.a;
	} else {
		COLOR = raw;
	}
}
