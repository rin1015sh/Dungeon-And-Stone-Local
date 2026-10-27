extends RefCounted
## 거주 구역 색(사용자 2026-10-27 「밝고 고급지게」, CT54 — tools/paint_city.gd 전용): 같은 시드로 그린 그림을 구역답게 다시 칠한다.
##   1 라비기온 13구역 = 그대로(때 낀 회색 돌·젖은 길) · 2 7구역 = 조금 밝고 따뜻하게 ·
##   3 컴멜비 5구역 = 꿀빛 사암 벽 + 푸른 점판암 지붕 · 4 3구역 = 상아빛 석회암 벽 + 청동빛 푸른 지붕(가장 밝다).
## 채도가 낮은 곳(돌·회벽·지붕·쇠)만 구역 색으로 옮기고(따뜻한 회색 → 벽 색, 차가운 회색 → 지붕 색), 채도가 높은 곳(불빛·깃발·색유리)은 밝기만.
## 아주 어두운 곳(잉크 윤곽)은 거의 건드리지 않는다. 밝기는 감마로 올린다(어두운 곳을 더 많이).

const Paint := preload("res://tools/city_art/Paint.gd")

## 등급 → [감마, 벽 색, 벽 섞기, 지붕 색, 지붕 섞기, 채도 배율, 벽 밝기 배율]
const LOOK := {
	2: [0.86, Color("#b9a27c"), 0.35, Color("#4f5f70"), 0.3, 1.1, 1.05],
	3: [0.72, Color("#dcb57a"), 0.62, Color("#3d5f8f"), 0.65, 1.25, 1.12],
	4: [0.6, Color("#f4e4c1"), 0.8, Color("#2f7f86"), 0.75, 1.25, 1.3],
}


## kind: building(건물·거리 담) · backdrop(먼 도시 — 섞기를 줄인다) · interior(실내 — 섞기를 줄이고 밝기만 조금 더)
static func look(p: Paint, tier: int, kind: String = "building") -> void:
	if not LOOK.has(tier):
		return
	var v: Array = LOOK[tier]
	var gamma: float = v[0]
	var wall: Color = v[1]
	var roof: Color = v[3]
	var k_mix := 0.55 if kind == "backdrop" else (0.35 if kind == "interior" else 1.0)
	var wall_mix: float = v[2] * k_mix
	var roof_mix: float = v[4] * k_mix
	var sat_k: float = v[5]
	var gain: float = lerpf(1.0, v[6], k_mix)
	var wall_l := maxf(0.05, wall.get_luminance())
	var roof_l := maxf(0.05, roof.get_luminance())
	var buf: PackedFloat32Array = p.buf
	for i in p.w * p.h:
		var k := i * 4
		if buf[k + 3] <= 0.0:
			continue
		var c := Color(buf[k], buf[k + 1], buf[k + 2])
		var l := maxf(0.001, c.get_luminance())
		var l2 := pow(l, gamma)
		var lit := c * (l2 / l)  # 같은 색, 더 밝게
		var sat := c.s
		var neutral := 1.0 - smoothstep(0.22, 0.5, sat)
		var ink := smoothstep(0.05, 0.2, l)  # 잉크 윤곽은 그대로
		var cool := smoothstep(-0.01, 0.04, c.b - c.r)
		var target := (wall * (l2 * gain / wall_l)).lerp(roof * (l2 / roof_l), cool)
		var m := lerpf(wall_mix, roof_mix, cool) * neutral * ink
		var out := lit.lerp(target, m)
		if sat_k != 1.0:
			var g := out.get_luminance()
			out = Color(g, g, g).lerp(out, sat_k)
		buf[k] = clampf(out.r, 0.0, 1.0)
		buf[k + 1] = clampf(out.g, 0.0, 1.0)
		buf[k + 2] = clampf(out.b, 0.0, 1.0)
	p.buf = buf
