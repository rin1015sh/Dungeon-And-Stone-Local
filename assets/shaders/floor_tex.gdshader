shader_type canvas_item;
// 탐험 맵 재질 그림(FloorChunk·WallRow): 꼭짓점 색 rgb = 빛 배율(FloorView.vertex_mul), a = 보이는 비율.
// 기억(안 보이는 곳)일수록 그림을 탈색한다 — 색칠한 칸(그림 없음)은 a = 1이라 그대로.
// fragment의 COLOR는 이미 그림 색이 곱해져 있어 꼭짓점 색은 vertex()에서 따로 받는다.

uniform float memory_desat = 0.65;

varying vec4 vcol;

void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float l = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	vec3 c = mix(t.rgb, vec3(l), (1.0 - vcol.a) * memory_desat);
	COLOR = vec4(c * vcol.rgb, t.a);
}
