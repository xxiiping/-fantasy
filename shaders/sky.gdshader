shader_type canvas_item;

// 夜空 + 海面。零贴图，纯渐变与柔光。
// 灯塔位置的暖光由 glow_pos / glow_strength 控制，成功结局时会调亮。

uniform vec3 top_color : source_color = vec3(0.020, 0.043, 0.078);
uniform vec3 mid_color : source_color = vec3(0.043, 0.094, 0.129);
uniform vec3 sea_color : source_color = vec3(0.027, 0.063, 0.086);
uniform vec3 glow_color : source_color = vec3(0.36, 0.47, 0.42);
uniform vec2 glow_pos = vec2(0.80, 0.62);
uniform float glow_strength = 0.35;
uniform float horizon : hint_range(0.0, 1.0) = 0.64;

void fragment() {
	vec2 uv = UV;

	vec3 sky = mix(top_color, mid_color, smoothstep(0.0, horizon, uv.y));
	vec3 col = mix(sky, sea_color, smoothstep(horizon - 0.006, horizon + 0.020, uv.y));

	// 灯塔处的柔光（椭圆衰减，避免正圆看起来像贴纸）
	vec2 d = (uv - glow_pos) * vec2(1.0, 1.7);
	col += glow_color * glow_strength * exp(-dot(d, d) * 20.0);

	// 海面微波纹，越远越淡
	if (uv.y > horizon) {
		float depth = smoothstep(horizon, horizon + 0.34, uv.y);
		float wave = sin(uv.x * 190.0 + uv.y * 70.0) * 0.5 + 0.5;
		float wave2 = sin(uv.x * 97.0 - uv.y * 41.0) * 0.5 + 0.5;
		col += vec3(0.018, 0.030, 0.036) * (wave * 0.6 + wave2 * 0.4) * depth;
	}

	COLOR = vec4(col, 1.0);
}
