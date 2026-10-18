shader_type canvas_item;
// 낭떠러지 너머 뒷배경(Backdrop·VoidChunk): 화면에 고정된 그림을 카메라 이동의 drift 비율만큼만 따라 움직여 먼 곳처럼 보이게.
// 꼭짓점 색 = 안개(보임 1 · 기억 어둡게) — 그림에 곱한다.
uniform sampler2D backdrop : filter_linear, repeat_enable;
uniform float drift = 0.12;
uniform vec2 scale = vec2(1.0, 1.0);
varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 size = vec2(textureSize(backdrop, 0));
	vec2 uv = SCREEN_UV * scale + world * drift / size;
	uv.y = clamp(uv.y, 0.002, 0.998);
	vec4 c = texture(backdrop, uv);
	COLOR = vec4(c.rgb * COLOR.rgb, 1.0);
}
