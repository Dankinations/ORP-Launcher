shader_type canvas_item;

uniform float iris_size : hint_range(0.0, 2.0) = 0.0; // The expanding transparent hole
uniform float aspect_ratio = 1.7778; // Set to your project aspect (e.g., 16/9)

void fragment() {
	// Adjust for screen resolution and aspect ratio
	vec2 st = UV;
	st.x *= aspect_ratio;
	st.x -= (aspect_ratio - 1.0) / 2.0;

	// Calculate distance from center (0.5, 0.5)
	vec2 center = vec2(0.5);
	float dist = distance(st, center);

	// Make everything INSIDE the circular area transparent
	// This reveals the background behind the ColorRect mask
	if (dist < iris_size * 0.5) {
		COLOR.a = 0.0; // Perfect transparency in the hole
	}
}