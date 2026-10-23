shader_type canvas_item;

// 宣纸底。
//
// 水墨风格的地基：不是"白色背景"，是"有纤维、有厚度、会吸墨的纸"。
// 所以这里做三件事：
//   1. 纸色（偏暖的米白，不是纯白）
//   2. 纸纤维噪声（细密、低频，模拟帘纹与纤维）
//   3. 四边墨晕（纸吸水后边缘自然变深）

uniform vec3 paper_color : source_color = vec3(0.914, 0.886, 0.835);
uniform vec3 fiber_color : source_color = vec3(0.847, 0.812, 0.753);
uniform vec3 edge_ink : source_color = vec3(0.09, 0.09, 0.11);

uniform float fiber_strength : hint_range(0.0, 1.0) = 0.35;
uniform float edge_strength : hint_range(0.0, 1.0) = 0.34;
uniform float edge_width : hint_range(0.0, 1.0) = 0.42;
uniform float grain : hint_range(0.0, 0.2) = 0.045;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	vec2 uv = UV;

	// 帘纹：横向的细密纤维
	float threads = noise(vec2(uv.x * 420.0, uv.y * 8.0));
	// 纤维：低频斑块
	float blotch = noise(vec2(uv.x * 26.0, uv.y * 34.0));
	float fiber = threads * 0.55 + blotch * 0.45;

	vec3 color = mix(paper_color, fiber_color, fiber * fiber_strength);

	// 四边墨晕：越靠边越深
	float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, edge_width, edge_dist);
	color = mix(color, edge_ink, edge * edge * edge_strength);

	// 纸面颗粒
	float g = hash(floor(uv * 900.0));
	color -= g * grain;

	COLOR = vec4(color, 1.0);
}
