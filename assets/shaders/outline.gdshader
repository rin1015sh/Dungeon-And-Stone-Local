shader_type canvas_item;
// 상호작용 대상 검은 테두리(사용자 2026-11-01 — UI 강조선이 아니라 그림 둘레 검은 선, CT77): 그림이 비어 있는 픽셀 중
// width 텍셀 안에 그림이 있으면 검게. 그림 칸 안쪽에서만 그려지므로 그림 둘레에 여백이 있어야 한다(가구 PAD · 사람 칸 여백).
// 중심 판정은 그림 알파(TEXTURE)로 — 꼭짓점 색 알파(그림자 등)는 건드리지 않는다.

uniform vec4 line_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width = 1.5;

void fragment() {
	float here = texture(TEXTURE, UV).a;
	if (here < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE * width;
		float a = 0.0;
		a = max(a, texture(TEXTURE, UV + vec2(px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV - vec2(px.x, 0.0)).a);
		a = max(a, texture(TEXTURE, UV + vec2(0.0, px.y)).a);
		a = max(a, texture(TEXTURE, UV - vec2(0.0, px.y)).a);
		a = max(a, texture(TEXTURE, UV + px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV - px * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2(px.x, -px.y) * 0.7071).a);
		a = max(a, texture(TEXTURE, UV + vec2(-px.x, px.y) * 0.7071).a);
		float k = smoothstep(0.3, 0.7, a) * line_color.a;
		COLOR = vec4(mix(COLOR.rgb, line_color.rgb, k), max(COLOR.a, k));
	}
}
