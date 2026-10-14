shader_type canvas_item;
// 도시 거리의 시설 건물 강조: 밝기(brighten)·흐리게(dim, 채도도 뺀다)·바깥 윤곽(outline px, 그림의 투명 경계 둘레).

uniform float brighten = 0.0;
uniform float dim = 0.0;
uniform float outline = 0.0;
uniform vec4 outline_color : source_color = vec4(0.88, 0.75, 0.44, 0.9);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (outline > 0.0 && c.a < 0.5) {
		vec2 px = TEXTURE_PIXEL_SIZE * outline;
		float m = 0.0;
		for (int i = 0; i < 8; i++) {
			float a = float(i) * 0.785398;
			m = max(m, texture(TEXTURE, UV + vec2(cos(a), sin(a)) * px).a);
		}
		c = mix(c, vec4(outline_color.rgb, outline_color.a * m), step(0.01, m));
	} else {
		float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		c.rgb = mix(c.rgb, vec3(g), dim * 0.6) * (1.0 - dim * 0.45) * (1.0 + brighten);
	}
	COLOR = c;
}
