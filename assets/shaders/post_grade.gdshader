shader_type canvas_item;
// 탐험 화면 후처리: 채도 낮추기 + 비네트 + 필름 그레인. 값은 data/render.json의 lighting에서 넣는다.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float saturation = 0.72;
uniform float vignette_strength = 0.55;
uniform float vignette_radius = 0.45;
uniform float grain_strength = 0.045;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	float d = length(UV - vec2(0.5)) * 1.41421;
	c *= 1.0 - smoothstep(vignette_radius, 1.0, d) * vignette_strength;
	float g = hash(floor(FRAGCOORD.xy) + vec2(fract(TIME * 7.0) * 113.0, fract(TIME * 3.0) * 71.0)) - 0.5;
	c += g * grain_strength;
	COLOR = vec4(c, 1.0);
}
