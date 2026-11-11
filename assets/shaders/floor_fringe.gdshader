shader_type canvas_item;
// 바닥 재질 번짐 띠(FloorFringe): TEXTURE = 스며드는 재질의 넓은 그림(세계 좌표로 되풀이해 깐다 — 옆 칸과 이어진다),
// UV = 띠 모양 그림(mask)의 칸. mask.r = 덮는 정도, mask.g = 가장자리 그늘.
// 꼭짓점 색은 floor_tex와 같다: rgb = 빛 배율, a = 보이는 비율(기억일수록 탈색).

uniform sampler2D mask : filter_linear, repeat_disable;
uniform float span_px = 128.0;
uniform float memory_desat = 0.65;
uniform float rim_dark = 0.3;

varying vec4 vcol;
varying vec2 wuv;

void vertex() {
	vcol = COLOR;
	wuv = VERTEX / span_px;
}

void fragment() {
	vec4 m = texture(mask, UV);
	vec3 t = texture(TEXTURE, wuv).rgb * (1.0 - m.g * rim_dark);
	float l = dot(t, vec3(0.299, 0.587, 0.114));
	vec3 c = mix(t, vec3(l), (1.0 - vcol.a) * memory_desat);
	COLOR = vec4(c * vcol.rgb, m.r);
}
