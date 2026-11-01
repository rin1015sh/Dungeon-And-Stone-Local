extends RefCounted
## 시설 실내 입체 소품(사용자 2026-11-01 "건물 장식 입체감이 안 느껴지는 것 — 땅바닥에 붙은 것처럼 그린 것들 다시 그려", V27).
## 옛 그림은 정면 평면 도형(상자 = 네모 + X, 자루 = 육각 실루엣, 더미 = 납작한 조각, 걸상 = 타원 하나)이라 위에서 내려다본
## 실내(3/4)에서 바닥 무늬처럼 보였다 → 윗면·옆면·그늘이 있는 덩어리로(floor_art/Solid — 픽셀별 높이·법선 칠).
## 좌표: foot = 바닥에 닿는 앞 가운데, t = 칸 px.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Solid := preload("res://tools/floor_art/Solid.gd")

const WOOD := Color("#6a4a30")
const IRON := Color("#3a3a3c")


## 나무 궤짝: 판자 앞면(X자 덧댐) · 밝은 윗면 판자 · 어두운 옆면 · 모서리 띠.
static func crate(p: Paint, foot: Vector2, s: float, col: Color = WOOD) -> void:
	Solid.shadow(p, foot + Vector2(s * 0.1, -s * 0.05), s * 0.62, s * 0.2)
	var dd := s * 0.42
	var f: Dictionary = Solid.block(p, foot, s, dd, s * 0.7,
		Mat.planks(p, col.darkened(0.08), int(foot.x), 0, false, int(maxf(5.0, s / 4.0))),
		Mat.planks(p, col.lightened(0.22), int(foot.x), 0, false, int(maxf(5.0, s / 4.5))),
		p.flat(col.darkened(0.48), 0.1))
	var fr: PackedVector2Array = f["front"]
	Ink.line(p, fr[0] + Vector2(3, 3), fr[2] - Vector2(3, 3), 2.4, col.darkened(0.55), 0.95, 0.2)  # X 덧댐
	Ink.line(p, fr[1] + Vector2(-3, 3), fr[3] + Vector2(3, -3), 2.4, col.darkened(0.55), 0.95, 0.2)
	for v in fr:
		p.fill_rect(v.x - 2, v.y - 2, 4, 4, p.flat(IRON, 0.05))


## 곡식 자루: 아래가 퍼진 덩어리 + 묶은 목 + 끈.
static func sack(p: Paint, foot: Vector2, s: float, col: Color = Color("#8a7854")) -> void:
	Solid.shadow(p, foot + Vector2(s * 0.08, -s * 0.04), s * 0.55, s * 0.18)
	Solid.lump(p, foot, s * 0.48, s * 0.2, s * 0.62, col, 0.35, -0.2)
	var neck := foot + Vector2(-s * 0.06, -s * 0.78)
	Solid.lump(p, neck + Vector2(0, s * 0.08), s * 0.13, s * 0.06, s * 0.16, col.darkened(0.08), 0.3)
	Ink.line(p, neck + Vector2(-s * 0.12, s * 0.06), neck + Vector2(s * 0.12, s * 0.06), 2.0, Color("#3a2a18"), 0.9, 0.3)
	for k in 3:  # 주름
		var a := foot + Vector2(-s * 0.25 + k * s * 0.2, -s * 0.15)
		Ink.line(p, a, a + Vector2(s * 0.04, -s * 0.22), 1.0, col.darkened(0.45), 0.5, 0.5)


## 둥근 걸상: 다리 셋(앞 둘이 밝게) + 두께 있는 앉는 판(윗면 밝음).
static func stool(p: Paint, foot: Vector2, t: int, col: Color) -> void:
	Solid.shadow(p, foot + Vector2(2, -2), t * 0.26, t * 0.08)
	var top_y := foot.y - t * 0.38
	for lx: float in [-0.16, 0.16, 0.0]:
		var base := Vector2(foot.x + lx * t, foot.y - (0.06 * t if lx == 0.0 else 0.0))
		Ink.line(p, base, Vector2(foot.x + lx * t * 0.55, top_y), 3.4, col.darkened(0.45 if lx > 0.0 else 0.3), 1.0, 0.1)
	Solid.drum(p, Vector2(foot.x, top_y + t * 0.05), t * 0.24, t * 0.07, col.darkened(0.15), col.lightened(0.18))


## 장작 더미: 누운 통나무를 아래 셋 · 위 둘로(앞 끝 나이테).
static func logs(p: Paint, foot: Vector2, t: int) -> void:
	Solid.shadow(p, foot + Vector2(2, -2), t * 0.4, t * 0.1)
	var r := t * 0.1
	var bark := Color("#5a4028")
	var cut := Color("#c8a874")
	for row in 2:
		for k in 3 - row:
			var x := foot.x + (k - (2 - row) * 0.5) * r * 2.1
			var y := foot.y - r - row * r * 1.7
			Solid.log(p, Vector2(x + r * 0.8, y - r * 1.4), Vector2(x - r * 0.3, y), r, bark.lightened(0.05 * row), cut)


## 광석·석탄·잡석 더미(rect 바닥 영역): 둥근 덩어리를 뒤에서 앞으로 쌓아 가운데가 높게.
static func pile(p: Paint, area: Rect2, t: int, col: Color) -> void:
	var c := area.get_center()
	Solid.shadow(p, Vector2(c.x, area.end.y - t * 0.15), area.size.x * 0.48, area.size.y * 0.4)
	var n := int(clampf(area.size.x * area.size.y / float(t * t) * 9.0, 8.0, 48.0))
	var pts: Array = []
	for k in n:
		var q := Vector2(p.rng.randf_range(area.position.x + t * 0.2, area.end.x - t * 0.2), p.rng.randf_range(area.position.y + t * 0.3, area.end.y - t * 0.1))
		var mid := 1.0 - minf(1.0, Vector2((q.x - c.x) / (area.size.x * 0.5), (q.y - c.y) / (area.size.y * 0.5)).length())
		pts.append([q, mid])
	pts.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).y < (b[0] as Vector2).y)
	for e: Array in pts:
		var q: Vector2 = e[0]
		var mid: float = e[1]
		var r := p.rng.randf_range(t * 0.15, t * 0.24)
		Solid.lump(p, q - Vector2(0, mid * t * 0.45), r, r * 0.5, r * (0.75 + mid * 0.7), col.lightened(p.rng.randf_range(-0.12, 0.14)), 0.55)


## 단지·항아리(유골 단지 등): 아래가 좁고 배가 부른 몸 + 목 + 입 테(윗면 어둡게).
static func urn(p: Paint, foot: Vector2, t: int, col: Color) -> void:
	Solid.shadow(p, foot + Vector2(2, -2), t * 0.3, t * 0.09)
	Solid.lump(p, foot, t * 0.3, t * 0.12, t * 0.62, col, 0.15)
	var neck := Vector2(foot.x, foot.y - t * 0.72)
	Solid.drum(p, neck + Vector2(0, t * 0.08), t * 0.13, t * 0.14, col.darkened(0.1), col.darkened(0.55))


## 숫돌: 나무 받침 틀에 세운 둥근 돌 바퀴(두께 · 축) + 아래 물받이.
static func grindstone(p: Paint, foot: Vector2, t: int, col: Color) -> void:
	Solid.shadow(p, foot + Vector2(2, -2), t * 0.4, t * 0.1)
	Solid.block(p, foot, t * 0.7, t * 0.22, t * 0.16, p.flat(Color("#4a3424"), 0.1), p.flat(Color("#6a4a30"), 0.1), p.flat(Color("#2e2016"), 0.1))  # 물받이 틀
	var c := Vector2(foot.x, foot.y - t * 0.52)
	var r := t * 0.32
	p.fill_poly(Solid._ellipse(c + Vector2(t * 0.07, -t * 0.02), r * 0.98, r), p.flat(col.darkened(0.5), 0.08))  # 바퀴 두께(뒤 면)
	p.fill_poly(Solid._ellipse(c, r * 0.98, r), func(x: int, y: int) -> Color:
		var d := Vector2(x - c.x + r * 0.35, y - c.y + r * 0.35).length() / (r * 1.6)
		return p.vary(col.lightened(0.18).lerp(col.darkened(0.35), clampf(d, 0.0, 1.0)), x, y, 0.08))
	Ink.path(p, Solid._ellipse(c, r * 0.98, r), 1.6, true, Ink.INK, 0.9, 0.3)
	Solid.drum(p, c + Vector2(0, r * 0.12), t * 0.05, t * 0.06, Color("#3a3a3c"), Color("#6a6a6c"))  # 축
	for s: float in [-1.0, 1.0]:  # 틀 기둥
		Ink.line(p, Vector2(foot.x + s * t * 0.3, foot.y - t * 0.16), Vector2(foot.x + s * t * 0.3, c.y), 4.0, Color("#4a3424"), 1.0, 0.1)


## 큰 솥·항아리(바닥에 놓인): 배부른 몸 + 어두운 입.
static func pot(p: Paint, foot: Vector2, t: int, col: Color) -> void:
	Solid.shadow(p, foot + Vector2(2, -2), t * 0.4, t * 0.1)
	Solid.lump(p, foot, t * 0.36, t * 0.16, t * 0.4, col, 0.15)
	var mouth := Solid._ellipse(Vector2(foot.x, foot.y - t * 0.44), t * 0.24, t * 0.08)
	p.fill_poly(mouth, p.flat(Color("#2a1e14"), 0.1))
	Ink.path(p, mouth, 1.4, true, Ink.INK, 0.85, 0.2)
