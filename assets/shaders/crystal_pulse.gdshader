shader_type canvas_item;
render_mode blend_add;
// 빛나는 타일(수정 등)의 느린 맥동 빛 번짐. 꼭짓점 색 rgb = 빛 색 × 세기, a = 칸마다 다른 위상(0~1).
// 값은 층 JSON art.pulse에서 넣는다(GlowChunk). 청크를 다시 그리지 않고 TIME으로만 움직인다.

uniform float period = 6.0;
uniform float depth = 0.35;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	float w = sin(TIME * 6.2831853 / period + tint.a * 6.2831853);
	float p = 1.0 - depth * 0.5 + depth * 0.5 * w;
	COLOR = vec4(tint.rgb, a * p);
}
