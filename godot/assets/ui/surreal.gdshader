shader_type canvas_item;
// Late-game dread. Driven by `amount` (Yoshiko's rhythm / the Narrator's haze /
// Furufue's drift). At 0 it is a clean pass-through of the screen below; as it
// rises the world desaturates, takes a cold purple cast, and starts to breathe.

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;

	// A slow, seasick wobble that only shows up as the dread grows.
	float t = TIME;
	uv.x += sin(uv.y * 18.0 + t * 1.4) * 0.004 * amount;
	uv.y += cos(uv.x * 16.0 + t * 1.1) * 0.004 * amount;

	vec3 col = texture(screen_tex, uv).rgb;

	// Desaturate toward luminance.
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 desat = mix(col, vec3(g), amount * 0.85);

	// Cold purple cast, strongest in the shadows.
	vec3 tint = desat * mix(vec3(1.0), vec3(0.70, 0.64, 0.95), amount * 0.65);

	// A faint vignette that closes in at full dread.
	float d = distance(SCREEN_UV, vec2(0.5));
	tint *= 1.0 - smoothstep(0.35, 0.85, d) * amount * 0.5;

	COLOR = vec4(tint, 1.0);
}
