extends RefCounted
## 여관 요리 그림 한 장(사용자 요청 2026-10-23 "식사하면 여관 테이블이 화면을 꽉 채우고 그 위에 음식이 보이게 — 이벤트 일러스트처럼
## 우리 화풍 그대로, 먹음직스럽고 다채롭게"): 960×540, 앉아서 내려다본 여관 탁자 + 가운데 요리 + 둘레 소품(초·잔·빵·도구).
## 칠하는 순서: 탁자(붓결 나무판·얼룩·빛 웅덩이) → 놓인 것들의 그림자 → 요리·소품을 3D 덩어리로 빚어(Clay) 몬스터 그림과 같은
## 붓 칠·잉크·빗금(Render) → 김·뿌린 가루·촛불 빛 → 색 보정(음식은 채도를 덜 빼고 따뜻하게)·그레인·비네트.
## 요리마다 그리는 함수 = Dishes1·2·3(DISHES). tools/paint_meals.gd 전용.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Clay := preload("res://tools/monster_art/Clay.gd")
const Render := preload("res://tools/monster_art/Render.gd")
const Kit := preload("res://tools/meal_art/Kit.gd")
const D1 := preload("res://tools/meal_art/Dishes1.gd")
const D2 := preload("res://tools/meal_art/Dishes2.gd")
const D3 := preload("res://tools/meal_art/Dishes3.gd")

const W := 960
const H := 540
const HORIZON := 58.0  ## 탁자 먼 끝(그 위는 어두운 여관 안)
const VANISH := Vector2(480, -700)  ## 널판이 모이는 점
const CENTER := Vector2(480, 300)  ## 요리 자리

## 요리 id → [부품 스크립트, 함수]. 새 요리는 여기와 Dishes 파일에 한 함수.
const DISHES := {
	"squid_ink_fry": [D1, "squid_ink_fry"], "boar_rib_grill": [D1, "boar_rib_grill"], "honey_quail": [D1, "honey_quail"],
	"goat_cheese_soup": [D1, "goat_cheese_soup"], "black_mushroom_risotto": [D1, "black_mushroom_risotto"],
	"mugwort_dumpling": [D1, "mugwort_dumpling"], "smoked_eel_rice": [D1, "smoked_eel_rice"], "ginger_rye": [D1, "ginger_rye"],
	"grilled_sweetfish": [D2, "grilled_sweetfish"], "salted_herring": [D2, "salted_herring"], "blood_sausage": [D2, "blood_sausage"],
	"bitter_herb_gukbap": [D2, "bitter_herb_gukbap"], "garlic_lamb_skewer": [D2, "garlic_lamb_skewer"],
	"chili_oil_noodle": [D2, "chili_oil_noodle"], "mint_sherbet": [D2, "mint_sherbet"], "roast_carrot_stew": [D2, "roast_carrot_stew"],
	"barley_porridge": [D3, "barley_porridge"], "bean_porridge": [D3, "bean_porridge"], "drake_tail_steak": [D3, "drake_tail_steak"],
	"butter_salmon": [D3, "butter_salmon"], "moonberry_tart": [D3, "moonberry_tart"], "whole_pig_roast": [D3, "whole_pig_roast"],
	"royal_herb_hotpot": [D3, "royal_herb_hotpot"], "cave_truffle_soup": [D3, "cave_truffle_soup"],
}


static func has(id: String) -> bool:
	return DISHES.has(id)


static func paint(id: String, seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cl := Clay.new(W, H)
	var ctx := {"cl": cl, "p": p, "rng": rng, "mats": {}, "shadows": [], "steam": [], "dots": [], "glows": [], "rims": [], "table": Color("#5a3a22")}
	var d: Array = DISHES[id]
	(d[0] as Script).call(str(d[1]), ctx)
	table(p, rng, ctx["table"])
	for s: Array in ctx["shadows"]:
		_shadow(p, s[0], s[1], s[2], s[3])
	Render.render(cl, p, 420.0)
	for rm: Array in ctx["rims"]:  # 접시 테 무늬
		Ink.path(p, Kit.oval(rm[0], rm[1], rm[2], 64), 2.6, true, rm[3], 0.55, 0.4)
	for st: Array in ctx["steam"]:
		steam(p, rng, st[0], st[1])
	for dt: Array in ctx["dots"]:
		_dots(p, rng, dt)
	for gl: Array in ctx["glows"]:
		var gp: Vector2 = gl[0]
		Ink.glow(p, gp.x, gp.y, gl[1], gl[2], gl[3], false)
	Ink.glow(p, CENTER.x - 40, CENTER.y - 20, 440.0, Color("#ffb060"), 0.13, false, 0.65)  # 요리 위에 떨어진 따뜻한 빛
	Ink.grade(p, 0.04, 1.06, Color("#120a06"), Color("#ffe6bc"), 0.1)
	Ink.finish(p, 0.028, 0.62)
	return p


## 탁자: 먼 끝 위는 어두운 여관 안(벽 · 화롯불 번짐), 아래는 앞으로 넓어지는 널판(결 · 틈 · 옹이 · 잔 자국 · 긁힌 자국).
static func table(p: Paint, rng: RandomNumberGenerator, wood: Color) -> void:
	p.fill_rect(0, 0, W, HORIZON + 2, func(x: int, y: int) -> Color:
		return p.vary(Color("#1a120c").lerp(Color("#2a1a10"), float(y) / HORIZON), x, y, 0.2))
	for k in 5:  # 멀리 흐린 불빛
		var bx := rng.randf_range(40, W - 40)
		Ink.glow(p, bx, rng.randf_range(10, HORIZON - 10), rng.randf_range(30, 70), Color("#ff9a40"), rng.randf_range(0.12, 0.25), true, 0.6)
	var n := 11
	var xs: Array[float] = []
	for k in n + 1:
		xs.append(-260.0 + (W + 520.0) * k / n + rng.randf_range(-14, 14))
	for k in n:
		var c := wood.lerp(Color("#6e4a2c") if k % 3 == 0 else Color("#4a2e1a"), rng.randf_range(0.0, 0.5))
		var b0 := Vector2(xs[k], H + 2)
		var b1 := Vector2(xs[k + 1], H + 2)
		var t0 := _toward(b0, HORIZON)
		var t1 := _toward(b1, HORIZON)
		var poly := Paint.poly([t0, t1, b1, b0])
		p.fill_poly(poly, func(x: int, y: int) -> Color:
			var g := p.nz("vs", int(x * 0.6), y) * 0.6 + p.nz("hi", x, y) * 0.4
			var cc := c.lerp(Color("#2a180c"), clampf((g - 0.5) * 0.9, 0.0, 0.5)).lerp(c.lightened(0.18), clampf((0.5 - g) * 0.9, 0.0, 0.4))
			return p.vary(cc, x, y, 0.1))
		for j in 7:  # 결 줄(널판 방향)
			var u := rng.randf_range(0.08, 0.92)
			var a := t0.lerp(t1, u)
			var b := b0.lerp(b1, u)
			var s0 := rng.randf_range(0.0, 0.5)
			Ink.line(p, a.lerp(b, s0), a.lerp(b, minf(1.0, s0 + rng.randf_range(0.2, 0.6))), rng.randf_range(0.8, 1.6), Color("#24140a"), 0.35, 1.2)
		Ink.line(p, t0, b0, 2.4, Color("#0e0805"), 0.85, 0.5)  # 널판 틈
		if rng.randf() < 0.6:  # 옹이
			var kp := t0.lerp(t1, 0.5).lerp(b0.lerp(b1, 0.5), rng.randf_range(0.3, 0.95))
			var kr := rng.randf_range(5, 11)
			p.fill_poly(Kit.oval(kp, kr * 0.7, kr, 14), p.flat(Color("#2a170a"), 0.1))
			Ink.path(p, Kit.oval(kp, kr * 1.4, kr * 2.0, 16), 1.0, true, Color("#2a170a"), 0.4)
	for k in 3:  # 잔 자국(둥근 얼룩)
		var c := Vector2(rng.randf_range(80, W - 80), rng.randf_range(HORIZON + 60, H - 30))
		var r := rng.randf_range(24, 40)
		Ink.path(p, Kit.oval(c, r, r * Kit.SQ, 30), 3.0, true, Color("#20120a"), 0.25, 2.0)
	for k in 14:  # 긁힌 자국
		var a := Vector2(rng.randf_range(0, W), rng.randf_range(HORIZON + 20, H))
		Ink.line(p, a, a + Vector2.from_angle(rng.randf_range(-0.4, 0.4)) * rng.randf_range(20, 70), 1.0, Color("#c0905a"), 0.18, 0.4)
	Ink.glow(p, CENTER.x, CENTER.y + 10, 520.0, Color("#ff9a48"), 0.16, true, 0.6)  # 요리 둘레 따뜻한 빛 웅덩이
	Ink.line(p, Vector2(0, HORIZON), Vector2(W, HORIZON), 3.0, Color("#0a0604"), 0.9, 0.6)  # 탁자 먼 끝
	Ink.shade(p, Paint.rect_poly(0, HORIZON, W, H - HORIZON), Vector2(0, HORIZON), Vector2(0, HORIZON + 140), 0.45, 0.0)


## 화면 아래 점 b에서 소실점 쪽으로 y까지.
static func _toward(b: Vector2, y: float) -> Vector2:
	var t := (b.y - y) / (b.y - VANISH.y)
	return b.lerp(VANISH, t)


static func _shadow(p: Paint, c: Vector2, rx: float, ry: float, k: float) -> void:
	p.fill_poly(Kit.oval(c, rx, ry, 40), func(x: int, y: int) -> Color:
		var d := Vector2((x - c.x) / rx, (y - c.y) / ry).length()
		return Color(0.04, 0.02, 0.01, k * smoothstep(1.0, 0.35, d)), 1.0, true)


## 김(따뜻한 국물·차 위로 피어오르는 흰 줄기 서너 개).
static func steam(p: Paint, rng: RandomNumberGenerator, at: Vector2, width: float) -> void:
	for k in 4:
		var x0 := at.x + rng.randf_range(-width * 0.5, width * 0.5)
		var ph := rng.randf() * TAU
		var tall := rng.randf_range(110, 190)
		var prev := Vector2(x0, at.y)
		for i in range(1, 25):
			var t := i / 24.0
			var q := Vector2(x0 + sin(t * 5.0 + ph) * 16.0 * t + t * 10.0, at.y - tall * t)
			Ink.line(p, prev, q, lerpf(10.0, 22.0, t), Color("#f4ead8"), 0.11 * sin(t * PI), 0.3)
			prev = q


## 뿌린 가루·후추·깨(그림 위에 점): [가운데, rx, ry, 개수, 색, 크기].
static func _dots(p: Paint, rng: RandomNumberGenerator, dt: Array) -> void:
	var c: Vector2 = dt[0]
	for k in int(dt[3]):
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var q := c + Vector2(cos(a) * float(dt[1]) * r, sin(a) * float(dt[2]) * r)
		var s := float(dt[5]) * rng.randf_range(0.6, 1.3)
		p.fill_poly(Kit.oval(q, s, s * 0.7, 8), p.flat(dt[4] as Color, 0.1))
