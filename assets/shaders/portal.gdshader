// 차원광장 포탈: 돌 고리 안쪽 타원에 그린다(ColorRect의 UV 0~1 = 타원 상자).
// open 0 → 1: 가운데 한 점에서 번져 고리를 채운다. flare: 들어갈 때 하얗게 타오름.
shader_type canvas_item;

uniform float open : hint_range(0.0, 1.0) = 0.0;
uniform float flare : hint_range(0.0, 1.0) = 0.0;
uniform vec4 core : source_color = vec4(0.85, 0.94, 1.0, 1.0);
uniform vec4 edge : source_color = vec4(0.48, 0.35, 0.85, 1.0);
uniform vec4 deep : source_color = vec4(0.07, 0.04, 0.15, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float ang = atan(p.y, p.x);
	float radius = open * 1.02;
	float swirl = ang + (1.0 - r) * 4.5 - TIME * 0.9;
	vec2 q = vec2(cos(swirl), sin(swirl)) * (r * 2.2 + 0.3);
	float n = fbm(q * 2.0 + vec2(TIME * 0.15, -TIME * 0.1));
	float streak = smoothstep(0.55, 0.95, fbm(vec2(swirl * 1.6, r * 6.0 - TIME * 1.4)));
	vec3 col = mix(deep.rgb, edge.rgb, n * 1.1);
	col += edge.rgb * streak * 0.6;
	col = mix(col, core.rgb, pow(max(0.0, 1.0 - r), 2.6) * (0.55 + 0.25 * sin(TIME * 2.1)));
	float inside = 1.0 - smoothstep(radius - 0.06, radius, r);
	float rim = smoothstep(radius - 0.22, radius - 0.02, r) * inside;
	col += mix(edge.rgb, core.rgb, 0.4) * rim * 1.3;
	col = mix(col, vec3(1.0, 0.98, 0.94), flare);
	COLOR = vec4(col, inside * clamp(open * 3.0, 0.0, 1.0));
}
