// 포탈 빛 번짐(더하기): 둘레 돌·단상·사람에 보랏빛이 비친다. strength = 열린 정도 × 세기.
shader_type canvas_item;
render_mode blend_add;

uniform float strength = 0.0;
uniform vec4 tint : source_color = vec4(0.48, 0.35, 0.85, 1.0);

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float f = pow(max(0.0, 1.0 - r), 2.2) * (0.9 + 0.1 * sin(TIME * 1.7));
	COLOR = vec4(tint.rgb * f * strength, 1.0);
}
