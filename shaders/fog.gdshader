shader_type canvas_item;

// 流动迷雾。三条可调量：
//   density    —— 整体浓度，判错时上调（"雾从边缘收拢"）
//   edge_pull  —— 边缘额外浓度，收拢感主要靠它
//   coverage   —— 雾在画面中占的比例
// 全部程序化，无贴图。

uniform vec3 fog_color : source_color = vec3(0.58, 0.68, 0.72);
uniform float density : hint_range(0.0, 1.8) = 0.85;
uniform float edge_pull : hint_range(0.0, 1.0) = 0.0;
uniform float coverage : hint_range(0.0, 1.0) = 0.55;
uniform float speed = 0.035;
uniform float band_top : hint_range(0.0, 1.0) = 0.08;
uniform float band_bottom : hint_range(0.0, 1.0) = 0.82;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * value_noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec2 p = uv * vec2(3.2, 1.7) + vec2(TIME * speed, TIME * speed * 0.4);
	float n = fbm(p);

	// 雾集中在中段，天空顶部与底部留清
	float band = smoothstep(band_top, band_top + 0.22, uv.y)
		* (1.0 - smoothstep(band_bottom - 0.30, band_bottom, uv.y));

	float alpha = n * coverage * density * band;

	// 边缘收拢：四边向内压
	float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, 0.42, edge_dist);
	alpha += edge * edge_pull * 0.42;

	alpha = clamp(alpha, 0.0, 0.80);
	COLOR = vec4(fog_color, alpha);
}
