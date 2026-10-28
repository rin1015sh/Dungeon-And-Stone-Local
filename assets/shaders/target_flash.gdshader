shader_type canvas_item;
// 대상으로 고른 적: 그 그림의 모양(알파)대로 흰빛을 얹는다(피어 앤 헝거식 — 노란 고리 대신, UI40). amount = 흰빛 세기(BattlerView가 숨 쉬듯 오르내린다).
uniform float amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	COLOR = vec4(1.0, 1.0, 1.0, t.a * amount);
}
