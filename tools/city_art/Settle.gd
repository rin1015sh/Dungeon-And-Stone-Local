extends RefCounted
## 귀환 정산 일러스트(사용자 2026-10-28 "차원광장 공터에 천막, 천막 안에 저울, 탐험가 길드 직원 — 마석 환전소 같은 일러스트 한 장, 화면 가득", CT58).
## 960×540(요리 그림과 같은 크기 — 화면을 덮게 늘린다). 칠: 장면을 다 칠한 뒤 Interiors.light로
## 어둡게 내리고 광원만 밝힌 다음 색 보정·그레인.
##   뒤 = 저녁 하늘 · 뿌연 반원 열주 회랑 · 왼쪽 먼 곳에 차원광장 돌 고리 · 판석 공터
##   가운데 = 천 천막(기둥 둘, 걷어 묶은 앞자락, 길드 방패 간판, 매단 등) — 안쪽 어둠 속 선반(장부·마석 상자)
##   천막 앞 = 판자 계산대: 큰 놋쇠 저울(한쪽 접시에 마석) · 마석 쟁반 · 펼친 장부 · 스톤 꾸러미 — 그 뒤 길드 직원(안경·깃·소매 덧댄 외투)
##   앞 = 왼쪽에 등을 보인 탐험가(짐) · 오른쪽 상자·자루·화로.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Props := preload("res://tools/city_art/Props.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Interiors := preload("res://tools/city_art/Interiors.gd")
const K := preload("res://tools/city_art/EventKit.gd")

const W := K.W
const H := K.H
const HOR := 250.0                 ## 지평선
const GROUND := 400.0              ## 천막 기둥·계산대가 서는 바닥 y
const CANVAS := Color("#8a7a5c")   ## 천막 천(바랜 아마포)
const CANVAS_IN := Color("#3a3226")
const BRASS := Color("#a88a4a")
const STONE := K.STONE
const LAMP := Color("#ffc070")


static func paint(seed_value: int) -> Paint:
	var p := Paint.new(W, H, seed_value)
	var lights: Array = []
	K.sky(p, HOR, Color("#232a30"), Color("#6a6250"))
	_colonnade(p)
	_ring(p, 120.0, 150.0)
	_flagstones(p)
	_haze(p)
	for f: Array in [[812.0, 300.0, 58.0, 1], [846.0, 304.0, 62.0, 3], [905.0, 296.0, 52.0, 0], [212.0, 296.0, 50.0, 4], [930.0, 318.0, 70.0, 5]]:  # 광장 먼 사람들
		K.person(p, float(f[0]), float(f[1]), float(f[2]), K.hazed(K.crowd_look(int(f[3])), 0.55))
	_tent_back(p)
	_shelves(p)
	K.person(p, 530, 400, 236, {"body": "male", "top": Color("#3e4a44"), "bottom": Color("#2e2a24"), "collar": Color("#c8bc98"),
		"stole": Color("#6a2a22"), "arms": "counter", "hands_v": 0.5, "hair": "short", "hair_c": Color("#4a4038"), "glasses": true,
		"beard": "mustache", "old": true, "light": 1.0, "keep": 0.5})
	_counter(p, 300, 690, 326)
	_scale(p, Vector2(370, 322), 1.3)
	_ledger(p, Vector2(520, 320))
	_tray(p, Vector2(628, 320))
	_pouch(p, Vector2(690, 318))
	_tent_front(p)
	_sign(p, Vector2(486, 62))
	var lamp := Vector2(486, 120)
	_lamp(p, lamp)
	K.brazier(p, 820, 512, 1.15)
	Props.crate(p, 742, 520, 46)
	Props.sack(p, 704, 528, 34)
	Props.barrel(p, 905, 530, 56, 78)
	K.person(p, 150, 640, 470, {"body": "male", "top": Color("#4e4434"), "bottom": Color("#34302a"), "back": true,
		"pack": Color("#6a5236"), "hair": "short", "hair_c": Color("#2a2018"), "light": 1.0, "keep": 0.3})
	lights.append([lamp + Vector2(0, 30), 330.0, LAMP, 0.9])
	lights.append([Vector2(628, 310), 160.0, STONE, 0.45])
	lights.append([Vector2(820, 420), 230.0, K.FIRE, 0.6])
	lights.append([Vector2(250, 380), 260.0, LAMP, 0.3])  # 천막에서 새어 나온 빛이 앞 탐험가 등에
	lights.append([Vector2(120, 150), 170.0, Color("#9a86d8"), 0.3])
	lights.append([Vector2(480, -120), 560.0, Color("#b8b49a"), 0.42])  # 저녁 하늘빛 — 먼 광장이 어둠에 묻히지 않게
	Interiors.light(p, lights, 0.64)
	Ink.glow(p, 628, 312, 46, STONE, 0.5, false)
	Ink.grade(p, 0.24, 1.1)
	Ink.finish(p, 0.04, 0.35)
	return p


## 뒤: 하늘 아래 뿌연 반원 열주 회랑(기둥 줄 + 위 처마).
static func _colonnade(p: Paint) -> void:
	var stone := Color("#5e5c54")
	var top := HOR - 96.0
	var eave := Paint.rect_poly(0, top - 14, W, 18)
	p.fill_poly(eave, Mat.ashlar(p, stone.darkened(0.15), 0, int(top), 40, 9))
	Ink.path(p, eave, 1.4, true, Ink.INK, 0.5)
	var x := 10.0
	while x < W:
		var col := Paint.rect_poly(x, top + 4, 16, HOR - top + 6)
		p.fill_poly(col, func(px: int, py: int) -> Color:
			var t := (px - x) / 16.0
			return p.vary(stone.lightened(0.15 * (1.0 - t)).darkened(0.25 * t), px, py, 0.06))
		Ink.path(p, col, 1.0, true, Ink.INK, 0.4)
		x += 46.0
	Ink.shade(p, Paint.rect_poly(0, top - 20, W, HOR - top + 30), Vector2(0, top - 20), Vector2(0, HOR + 10), 0.25, 0.05, Color("#7a7e74"))


## 먼 곳 안개(천막·사람을 그리기 전에): 하늘·회랑·고리와 먼 바닥을 저녁 안개 색으로 — 지평선이 가장 옅고 앞으로 올수록 걷힌다.
## 불을 밝히면(Interiors.light) 다 같이 어두워지므로 밝은 색으로 넉넉히.
static func _haze(p: Paint) -> void:
	var fog := Color("#a8a89a")
	for y in int(HOR + 150):
		var a := 0.55 * clampf(y / HOR, 0.0, 1.0) if y <= HOR else 0.55 * pow(1.0 - (y - HOR) / 150.0, 1.6)
		if a <= 0.01:
			continue
		for x in W:
			p.blend(x, y, fog, a)


## 왼쪽 먼 곳 돌 고리(차원광장 포탈 — 닫혀 비었다, 안은 희미한 보랏빛).
static func _ring(p: Paint, cx: float, r: float) -> void:
	var cy := HOR - r * 0.55
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		outer.append(Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.62)
		inner.append(Vector2(cx, cy) + Vector2(cos(a), sin(a)) * r * 0.48)
	p.fill_poly(outer, p.flat(Color("#6a665c"), 0.12))
	p.fill_poly(inner, p.flat(Color("#5a5466"), 0.1))
	Ink.glow(p, cx, cy, r * 0.5, Color("#9a86d8"), 0.25)
	Ink.path(p, outer, 1.6, true, Ink.INK, 0.6)
	Ink.path(p, inner, 1.2, true, Ink.INK, 0.5)
	var dais := Paint.poly([Vector2(cx - r * 0.75, cy + r * 0.55), Vector2(cx + r * 0.75, cy + r * 0.55), Vector2(cx + r * 0.9, HOR + 6), Vector2(cx - r * 0.9, HOR + 6)])
	p.fill_poly(dais, Mat.ashlar(p, Color("#5a564e"), 0, 0, 30, 10))
	Ink.path(p, dais, 1.2, true, Ink.INK, 0.5)
	Ink.shade(p, Paint.rect_poly(cx - r, cy - r, r * 2.0, r * 2.0), Vector2(cx, cy - r), Vector2(cx, cy + r), 0.15, 0.0, Color("#8a8e86"))


## 판석 공터: 지평선에서 앞으로 갈수록 큰 판석(원근 줄).
static func _flagstones(p: Paint) -> void:
	p.fill_rect(0, HOR, W, H - HOR, p.flat(Color("#3a3832"), 0.2))
	var y := HOR
	var rh := 6.0
	var row := 0
	while y < H:
		var x := -fmod(row * 37.0, rh * 4.0)
		while x < W:
			var sw := rh * p.rng.randf_range(5.0, 8.0)
			var slab := Paint.poly([Vector2(x + 1, y + 1), Vector2(x + sw - 1, y + 1), Vector2(x + sw - 1, y + rh - 1), Vector2(x + 1, y + rh - 1)])
			p.fill_poly(slab, p.flat(Color("#5a574c").darkened(p.rng.randf_range(0.0, 0.22)), 0.12))
			Ink.line(p, Vector2(x, y), Vector2(x + sw, y), maxf(0.6, rh * 0.05), Color("#1a1814"), 0.18, 0.4)
			x += sw
		y += rh
		rh *= 1.2
		row += 1
	var vp := Vector2(W * 0.5, HOR - 40.0)  # 판석 이음매가 소실점으로 모인다(바닥으로 읽히게)
	for i in 31:
		var bx := -W * 0.6 + i * W * 2.2 / 30.0
		var a := vp.lerp(Vector2(bx, H), (HOR + 2.0 - vp.y) / (H - vp.y))
		Ink.line(p, a, Vector2(bx, H), 1.0, Color("#1a1814"), 0.3, 0.6)
	Ink.shade(p, Paint.rect_poly(0, HOR, W, H - HOR), Vector2(0, HOR), Vector2(0, H), 0.3, 0.05)


## 천막 안쪽(뒤 천벽 + 그늘) — 직원·계산대보다 먼저.
static func _tent_back(p: Paint) -> void:
	var back := Paint.poly([Vector2(250, 130), Vector2(722, 130), Vector2(712, 336), Vector2(260, 336)])
	p.fill_poly(back, func(x: int, y: int) -> Color:
		var fold := 0.5 + 0.5 * sin(x * 0.07)
		return p.vary(CANVAS_IN.darkened(0.25 * fold), x, y, 0.1))
	Ink.shade(p, back, Vector2(0, 130), Vector2(0, 336), 0.35, 0.1)
	for i in 9:
		var fx := 268.0 + i * 52.0
		Ink.line(p, Vector2(fx, 132), Vector2(fx + 6, 334), 2.0, Color("#1a1610"), 0.35, 1.2)


## 천막 안 선반: 장부 더미 · 마석 상자 · 자루.
static func _shelves(p: Paint) -> void:
	for sy: float in [200.0, 252.0]:
		var board := Paint.rect_poly(570, sy, 130, 8)
		p.fill_poly(board, Mat.planks(p, Color("#4a3624"), 0, 0, false, 8))
		Ink.path(p, board, 1.4)
	Bits.book_pile(p, 590, 200, 4)
	for i in 3:
		var bx := 612.0 + i * 26.0
		var box := Paint.rect_poly(bx, 234, 22, 18)
		p.fill_poly(box, Mat.planks(p, Color("#5a4430"), 0, 0, true, 6))
		Ink.path(p, box, 1.2)
		Ink.glow(p, bx + 11, 234, 12, STONE, 0.25, false)
	Props.sack(p, 300, 336, 30)
	Props.crate(p, 342, 336, 34)


## 판자 계산대(x0..x1, 윗면 y): 앞판 + 윗판 + 덧댄 쇠띠.
static func _counter(p: Paint, x0: float, x1: float, top: float) -> void:
	var front := Paint.rect_poly(x0, top, x1 - x0, GROUND - top)
	p.fill_poly(front, Mat.planks(p, Color("#4a3624"), int(x0), int(top), true, 20))
	Ink.shade(p, front, Vector2(0, top), Vector2(0, GROUND), 0.1, 0.55)
	Ink.path(p, front, 2.2)
	for bx: float in [x0 + 40, x1 - 40]:
		Ink.line(p, Vector2(bx, top + 8), Vector2(bx, GROUND - 4), 5.0, Color("#2a2622"), 0.9, 0.2)
	var board := Paint.poly([Vector2(x0 - 12, top - 12), Vector2(x1 + 12, top - 12), Vector2(x1 + 4, top + 2), Vector2(x0 - 4, top + 2)])
	p.fill_poly(board, Mat.planks(p, Color("#6a5034"), 0, 0, false, 10))
	Ink.path(p, board, 2.0)
	Ink.grime(p, x0, GROUND - 30, x1 - x0, 26, 0.5)


## 큰 놋쇠 저울(받침 c, 크기 s): 기둥 · 기운 들보(오른쪽 접시에 마석 — 무거워 내려갔다) · 사슬 · 접시.
static func _scale(p: Paint, c: Vector2, s: float) -> void:
	var foot := Paint.poly([c + Vector2(-26, 0) * s, c + Vector2(26, 0) * s, c + Vector2(16, -8) * s, c + Vector2(-16, -8) * s])
	p.fill_poly(foot, p.flat(BRASS.darkened(0.35), 0.12))
	Ink.path(p, foot, 1.6)
	var post_top := c + Vector2(0, -78) * s
	Ink.line(p, c + Vector2(0, -6) * s, post_top, 5.0 * s, BRASS.darkened(0.2), 1.0, 0.1)
	Ink.line(p, c + Vector2(1.5, -6) * s, post_top + Vector2(1.5, 0), 1.2 * s, BRASS.lightened(0.3), 0.7, 0.1)
	var tilt := Vector2(0, 7) * s
	var left := post_top + Vector2(-52, 0) * s - tilt
	var right := post_top + Vector2(52, 0) * s + tilt
	Ink.line(p, left, right, 4.0 * s, BRASS, 1.0, 0.1)
	p.fill_poly(Paint.poly([post_top + Vector2(-5, -9) * s, post_top + Vector2(5, -9) * s, post_top + Vector2(0, 4) * s]), p.flat(BRASS.lightened(0.15), 0.1))
	for side: Array in [[left, false], [right, true]]:
		var top: Vector2 = side[0]
		var pan_y := 40.0 * s
		var pan_c := top + Vector2(0, pan_y)
		for dx: float in [-14.0, 0.0, 14.0]:
			Ink.line(p, top, pan_c + Vector2(dx, 0) * s, 1.0 * s, BRASS.darkened(0.1), 0.85, 0.2)
		var pan := Paint.poly([pan_c + Vector2(-20, 0) * s, pan_c + Vector2(20, 0) * s, pan_c + Vector2(13, 7) * s, pan_c + Vector2(-13, 7) * s])
		p.fill_poly(pan, p.flat(BRASS, 0.16))
		Ink.shade(p, pan, pan_c, pan_c + Vector2(0, 7) * s, 0.0, 0.4)
		Ink.path(p, pan, 1.4)
		if side[1]:
			K.stones(p, pan_c.x, pan_c.y - 1.0, 12.0 * s, 9)
		else:  # 추
			var wt := Paint.rect_poly(pan_c.x - 6 * s, pan_c.y - 9 * s, 12 * s, 9 * s)
			p.fill_poly(wt, p.flat(Color("#4a4a46"), 0.1))
			Ink.path(p, wt, 1.2)


## 펼친 장부(가죽 표지 위 누런 두 쪽 + 글 줄 + 깃펜).
static func _ledger(p: Paint, c: Vector2) -> void:
	var cover := Paint.poly([c + Vector2(-44, -4), c + Vector2(44, -4), c + Vector2(50, 6), c + Vector2(-50, 6)])
	p.fill_poly(cover, p.flat(Color("#4a2a20"), 0.12))
	Ink.path(p, cover, 1.4)
	for s: float in [-1.0, 1.0]:
		var page := Paint.poly([c + Vector2(0, -6), c + Vector2(s * 40, -9), c + Vector2(s * 44, 2), c + Vector2(0, 3)])
		p.fill_poly(page, p.flat(K.PAPER.darkened(0.08), 0.14))
		Ink.path(p, page, 1.0, true, Ink.INK, 0.6)
		for k in 3:
			var ly := -6.0 + k * 3.0
			Ink.line(p, c + Vector2(s * 6, ly), c + Vector2(s * 34, ly - 1.5), 0.8, Color("#3a2e22"), 0.6, 0.4)
	Ink.line(p, c + Vector2(30, -4), c + Vector2(54, -34), 1.4, Color("#d8d0b8"), 0.9, 0.3)  # 깃펜
	Ink.line(p, c + Vector2(46, -24), c + Vector2(58, -38), 3.0, Color("#c8c0a8"), 0.7, 0.6)


## 마석 쟁반: 얕은 나무 쟁반 위 수북한 마석(빛).
static func _tray(p: Paint, c: Vector2) -> void:
	var tray := Paint.poly([c + Vector2(-50, -6), c + Vector2(50, -6), c + Vector2(44, 4), c + Vector2(-44, 4)])
	p.fill_poly(tray, Mat.planks(p, Color("#5a4430"), 0, 0, false, 6))
	Ink.path(p, tray, 1.6)
	K.stones(p, c.x, c.y - 6, 40, 46)


## 스톤 꾸러미(묶은 가죽 주머니 + 앞에 흘린 동전 몇 닢).
static func _pouch(p: Paint, c: Vector2) -> void:
	var bag := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		bag.append(c + Vector2(cos(a) * 16, sin(a) * 13 - 12))
	p.fill_poly(bag, p.flat(Color("#6a4a2c"), 0.16))
	Ink.shade(p, bag, c + Vector2(-16, -24), c + Vector2(16, 0), 0.0, 0.45)
	Ink.path(p, bag, 1.6)
	Ink.line(p, c + Vector2(-6, -24), c + Vector2(6, -24), 3.0, Color("#3a2a1a"), 1.0, 0.2)
	Bits.coins(p, c + Vector2(22, 2))


## 천막 앞: 처마 천(박공) · 양쪽 기둥 · 걷어 묶은 앞자락 · 처마 술.
static func _tent_front(p: Paint) -> void:
	var roof := Paint.poly([Vector2(486, 14), Vector2(790, 134), Vector2(770, 156), Vector2(486, 60), Vector2(202, 156), Vector2(182, 134)])
	p.fill_poly(roof, func(x: int, y: int) -> Color:
		var seam := 0.5 + 0.5 * sin((x - 486) * 0.05 + y * 0.01)
		return p.vary(CANVAS.darkened(0.2 * seam), x, y, 0.1))
	Ink.shade(p, roof, Vector2(486, 14), Vector2(486, 156), 0.0, 0.3)
	Ink.path(p, roof, 2.4)
	var valance := Paint.poly([Vector2(202, 156), Vector2(486, 60), Vector2(770, 156), Vector2(770, 176), Vector2(486, 82), Vector2(202, 176)])
	p.fill_poly(valance, p.flat(Color("#6a2a22"), 0.12))
	Ink.path(p, valance, 1.6)
	for i in 14:
		var t := (i + 0.5) / 14.0
		var q := Vector2(202, 176).lerp(Vector2(486, 82), t * 2.0) if t < 0.5 else Vector2(486, 82).lerp(Vector2(770, 176), (t - 0.5) * 2.0)
		Ink.line(p, q, q + Vector2(0, 9), 2.0, Color("#b8954a"), 0.8, 0.3)
	for side: float in [-1.0, 1.0]:
		var px := 486.0 + side * 262.0
		var pole := Paint.rect_poly(px - 7, 120, 14, GROUND - 120)
		p.fill_poly(pole, Mat.beam(p, Color("#3a2a1c")))
		Ink.path(p, pole, 1.8)
		var flap := Paint.poly([Vector2(px - side * 4, 150), Vector2(px - side * 62, 168), Vector2(px - side * 40, 270),
			Vector2(px - side * 12, 296), Vector2(px - side * 4, 296)])
		p.fill_poly(flap, func(x: int, y: int) -> Color:
			return p.vary(CANVAS.darkened(0.1 + 0.15 * sin(y * 0.09)), x, y, 0.1))
		Ink.shade(p, flap, Vector2(px - side * 60, 154), Vector2(px, 296), 0.05, 0.4)
		Ink.path(p, flap, 2.0)
		for k in 3:
			var fy := 186.0 + k * 30.0
			Ink.line(p, Vector2(px - side * 44, fy), Vector2(px - side * 8, fy + 20), 1.4, Color("#3a3226"), 0.5, 1.0)
		Ink.line(p, Vector2(px - side * 30, 278), Vector2(px + side * 2, 274), 3.0, Color("#3a2a1a"), 1.0, 0.3)  # 묶은 끈
		Ink.line(p, Vector2(px, GROUND - 120), Vector2(px + side * 70, GROUND + 6), 1.2, Color("#2a241c"), 0.7, 0.4)  # 버팀줄
		Ink.line(p, Vector2(px + side * 70, GROUND + 6), Vector2(px + side * 70, GROUND - 8), 3.0, Color("#2a2018"), 1.0, 0.2)  # 말뚝


## 길드 간판: 박공 아래 매단 방패(초록 바탕 + 갈래 길 문양) — 탐험가 길드 표시.
static func _sign(p: Paint, c: Vector2) -> void:
	for dx: float in [-14.0, 14.0]:
		Ink.line(p, c + Vector2(dx, -18), c + Vector2(dx, 6), 1.2, Color("#2a2018"), 0.9, 0.2)
	var sh := Paint.poly([c + Vector2(-22, 6), c + Vector2(22, 6), c + Vector2(22, 30), c + Vector2(0, 50), c + Vector2(-22, 30)])
	p.fill_poly(sh, p.flat(Color("#3a5242"), 0.14))
	Ink.shade(p, sh, c + Vector2(-22, 6), c + Vector2(22, 50), 0.0, 0.35)
	Ink.path(p, sh, 2.0)
	Ink.line(p, c + Vector2(0, 44), c + Vector2(0, 24), 3.0, Color("#c8b070"), 0.9, 0.2)
	for s: float in [-1.0, 1.0]:
		Ink.line(p, c + Vector2(0, 24), c + Vector2(s * 12, 12), 3.0, Color("#c8b070"), 0.9, 0.2)


## 천막 안에 매단 등(사슬 + 쇠틀 + 불빛).
static func _lamp(p: Paint, c: Vector2) -> void:
	Ink.line(p, c + Vector2(0, -60), c, 1.4, Color("#2a2622"), 0.9, 0.2)
	var cage := Paint.poly([c + Vector2(-10, 0), c + Vector2(10, 0), c + Vector2(13, 22), c + Vector2(-13, 22)])
	p.fill_poly(cage, p.flat(LAMP.darkened(0.1), 0.1))
	Ink.path(p, cage, 1.6)
	for dx: float in [-5.0, 5.0]:
		Ink.line(p, c + Vector2(dx, 1), c + Vector2(dx * 1.3, 21), 1.2, Color("#2a2622"), 0.9, 0.1)
	Ink.glow(p, c.x, c.y + 11, 40, LAMP, 0.6, false)
