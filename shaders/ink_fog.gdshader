shader_type canvas_item;

// 水墨雾。
//
// 和原来的冷色薄雾不同，这里的雾是"墨在水里化开"：
//   - 用 fbm 造团块，再用 smoothstep 压成水墨的浓淡分层（不是均匀的灰）
//   - 边缘带一点飞白（高频噪声削弱 alpha）
//   - 判错时 density 上调、edge_pull 拉高，雾从四边压进来

uniform vec3 ink_color : source_color = vec3(0.12, 0.13, 0.15);
uniform vec3 wash_color : source_color = vec3(0.42, 0.46, 0.48);

uniform float density : hint_range(0.0, 1.8) = 0.95;
uniform float edge_pull : hint_range(0.0, 1.0) = 0.0;
uniform float coverage : hint_range(0.0, 1.0) = 1.0;
uniform float speed = 0.030;
uniform float band_top : hint_range(0.0, 1.0) = 0.20;
uniform float band_bottom : hint_range(0.0, 1.0) = 0.80;

// 墨色的浓淡分层：把连续噪声压成几档，才像墨不像烟
uniform float steps : hint_range(2.0, 12.0) = 7.0;

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
	vec2 p = uv * vec2(2.6, 1.5) + vec2(TIME * speed, TIME * speed * 0.35);

	float n = fbm(p);

	// 压成墨的层次：让浓淡有台阶感，像墨在纸上分几次积上去
	float layered = floor(n * steps) / steps;
	layered = mix(n, layered, 0.15);

	// 墨分两层：
	//   墨心 —— 浓、边缘紧，是笔画落纸的那一下
	//   淡晕 —— 宽、软，是墨在湿纸上洇开的部分
	// 只用一层阈值会变成"等高线"，两层叠起来才像墨。
	float core = smoothstep(0.52, 0.74, layered);
	float halo = smoothstep(0.34, 0.64, layered);

	float band = smoothstep(band_top, band_top + 0.22, uv.y)
		* (1.0 - smoothstep(band_bottom - 0.28, band_bottom, uv.y));

	float alpha = (core * 0.80 + halo * 0.42) * band * density * coverage;

	// 四边压进来
	float edge_dist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float edge = 1.0 - smoothstep(0.0, 0.40, edge_dist);
	alpha += edge * edge_pull * 0.45;

	// 飞白：高频噪声啃掉一点边
	float fly = value_noise(uv * 340.0);
	alpha *= 0.78 + fly * 0.34;

	alpha = clamp(alpha, 0.0, 0.88);

	// 浓处偏墨、薄处偏淡墨
	vec3 color = mix(wash_color, ink_color, smoothstep(0.50, 0.90, layered));
	COLOR = vec4(color, alpha);
}
