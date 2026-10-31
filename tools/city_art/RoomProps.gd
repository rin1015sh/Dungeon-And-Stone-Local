extends RefCounted
## 시설 실내 방 소품 그림(탑뷰 3/4 — RoomArt와 짝, tools/paint_rooms.gd 전용). 투명 바탕, 그림 아래 가운데 = 소품 rect 아래 가운데(발).
## 높이가 있는 것은 위로 끌어올려 그린다: 윗면(위에서 본 판) + 앞면(옆에서 본 띠) — 탐험 맵 벽(벽 턱)과 같은 눌린 시점.
## 칠한 뒤 RoomArt와 같은 빛(어둡게 내리고 촛불 둘레만) · Ink.grade · Ink.finish.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")

const PAD := 10  ## 좌우 여백(px)


## 독서 탁자(rect 3×2): 뒤 칸 = 탁자(윗면에 펼친 책·초·책 더미·잉크병), 앞 칸 = 긴 의자.
## variant: "" 도서관(펼친 책·책 더미·잉크병) · inn 주점(잔·접시·빵) · guild 길드(지도·종이).
static func table(t: int, seed_value: int, _size: Vector2i = Vector2i.ONE, variant: String = "") -> Paint:
	var lift := int(t * 0.55)
	var p := Paint.new(3 * t + PAD * 2, 2 * t + lift + 30, seed_value)
	var ox := float(PAD)
	var floor_y := float(p.h)  # rect 아래 끝
	var top := Rect2(ox + 6, floor_y - 2 * t - lift + 14, 3 * t - 12, t - 14)
	_legs(p, top, lift, Color("#2a1d14"))
	_slab(p, top, 9, Mat.planks(p, Color("#4e3725"), 0, 0, false, 14), Mat.planks(p, Color("#3a281b"), 0, 0, false, 7))
	match variant:
		"inn":
			for k in 4:
				Bits.mug(p, top.position.x + top.size.x * (0.36 + k * 0.15), top.position.y + top.size.y * (0.5 + (k % 2) * 0.25))
			var plate := Paint.rect_poly(top.position.x + top.size.x * 0.62, top.position.y + 6, 30, 12)
			p.fill_poly(plate, p.flat(Color("#9a9080"), 0.1))
			Ink.path(p, plate, 1.0)
			p.fill_rect(top.position.x + top.size.x * 0.64, top.position.y + 4, 18, 9, p.flat(Color("#8a6a3a"), 0.15))  # 빵
		"guild":
			var map := Paint.rect_poly(top.position.x + top.size.x * 0.3, top.position.y + 4, top.size.x * 0.4, top.size.y - 10)
			p.fill_poly(map, p.flat(Color("#b8a47c"), 0.15))
			Ink.path(p, map, 1.0)
			for k in 5:
				var a := Vector2(top.position.x + top.size.x * (0.33 + k * 0.07), top.position.y + 10 + (k % 2) * 10)
				Ink.line(p, a, a + Vector2(14, 8), 1.0, Color("#5a2a1a"), 0.6, 0.6)
			_inkwell(p, Vector2(top.position.x + top.size.x * 0.8, top.position.y + top.size.y * 0.72))
		_:
			Bits.open_book(p, Vector2(top.position.x + top.size.x * 0.42, top.position.y + top.size.y * 0.3), 15)
			Bits.open_book(p, Vector2(top.position.x + top.size.x * 0.8, top.position.y + top.size.y * 0.34), 12)
			_book_stack(p, Vector2(top.position.x + 14, top.position.y + top.size.y * 0.66), 3)
			_inkwell(p, Vector2(top.position.x + top.size.x * 0.6, top.position.y + top.size.y * 0.72))
	var candle := Vector2(top.position.x + top.size.x * 0.2, top.position.y + top.size.y * 0.42)
	_candle(p, candle, 18)
	var seat_lift := lift * 0.5
	var bench := Rect2(ox + 22, floor_y - t * 0.62 - seat_lift, 3 * t - 44, t * 0.2)
	_legs(p, bench, seat_lift, Color("#24180f"), 4.0)
	_slab(p, bench, 5, Mat.planks(p, Color("#3e2b1c"), 0, 0, true, 9), p.flat(Color("#291c13"), 0.12))
	RoomArt.light(p, [[candle, 2.2 * t, RoomArt.WARM, 0.8]], 0.62)
	Ink.glow(p, candle.x, candle.y - 12, 22, RoomArt.WARM, 0.5)
	Ink.grade(p, 0.24, 1.12)
	Ink.finish(p, 0.04, 0.0)
	return p


## 사서 책상(rect 3×1): 앞을 막은 무거운 책상 · 펼친 장부 · 기름 등 · 깃펜과 잉크 · 책 더미 · 두루마리.
static func desk(t: int, seed_value: int, _size: Vector2i = Vector2i.ONE, _variant: String = "") -> Paint:
	var lift := int(t * 0.62)
	var p := Paint.new(3 * t + PAD * 2, t + lift + 60, seed_value)
	var ox := float(PAD)
	var floor_y := float(p.h)
	var top := Rect2(ox + 2, floor_y - t - lift + 6, 3 * t - 4, t - 10)
	_slab(p, top, lift - 2, Mat.planks(p, Color("#4a3322"), 0, 0, false, 13), func(x: int, y: int) -> Color:
		var c := Color("#33231a")
		if posmod(x - int(ox), int(t * 0.75)) < 4:
			c = Color("#21170f")  # 앞판 칸막이
		return p.vary(c.darkened(absf(p.nz("vs", x, y) - 0.5) * 0.4), x, y, 0.15))
	var ledger := Vector2(top.position.x + top.size.x * 0.52, top.position.y + top.size.y * 0.3)
	Bits.open_book(p, ledger, 20)
	_book_stack(p, Vector2(top.position.x + top.size.x * 0.82, top.position.y + top.size.y * 0.75), 4)
	_inkwell(p, Vector2(top.position.x + top.size.x * 0.7, top.position.y + top.size.y * 0.66))
	for k in 2:  # 두루마리
		var a := Vector2(top.position.x + 18 + k * 6, top.position.y + top.size.y * (0.62 + k * 0.16))
		Ink.line(p, a, a + Vector2(34, -4), 7.0, Color("#b8a882"), 1.0, 0.2)
		Ink.line(p, a + Vector2(0, 3), a + Vector2(34, -1), 1.0, Ink.INK, 0.5, 0.2)
	var lamp := Vector2(top.position.x + top.size.x * 0.16, top.position.y + top.size.y * 0.32)
	_oil_lamp(p, lamp)
	RoomArt.light(p, [[lamp, 2.4 * t, RoomArt.WARM, 0.85]], 0.62)
	Ink.glow(p, lamp.x, lamp.y - 16, 28, RoomArt.WARM, 0.55)
	Ink.grade(p, 0.24, 1.12)
	Ink.finish(p, 0.04, 0.0)
	return p


## 희귀서 독서대(rect 1×1, 이번 순 '희귀서 입고'에만): 기둥 하나 · 기운 받침 · 쇠사슬 묶인 큰 책 · 곁의 초.
static func lectern(t: int, seed_value: int, _size: Vector2i = Vector2i.ONE, _variant: String = "") -> Paint:
	var p := Paint.new(t + PAD * 2 + 20, t + 96, seed_value)
	var cx := p.w * 0.5
	var floor_y := float(p.h)
	var foot := Paint.rect_poly(cx - 18, floor_y - t * 0.5 - 8, 36, 12)
	p.fill_poly(foot, p.flat(Color("#2e2016"), 0.1))
	Ink.path(p, foot, 1.6)
	var post := Paint.rect_poly(cx - 6, floor_y - t * 0.5 - 62, 12, 58)
	p.fill_poly(post, Mat.planks(p, Color("#3e2b1d"), 0, 0, true, 6))
	Ink.path(p, post, 1.6)
	var board := Paint.poly([Vector2(cx - 30, floor_y - t * 0.5 - 70), Vector2(cx + 30, floor_y - t * 0.5 - 70), Vector2(cx + 26, floor_y - t * 0.5 - 98), Vector2(cx - 26, floor_y - t * 0.5 - 98)])
	p.fill_poly(board, Mat.planks(p, Color("#4a3423"), 0, 0, false, 8))
	Ink.path(p, board, 1.8)
	Bits.open_book(p, Vector2(cx, floor_y - t * 0.5 - 94), 22)
	for k in 6:  # 쇠사슬(책 → 기둥)
		var a := Vector2(cx + 20 - k * 3, floor_y - t * 0.5 - 74 + k * 9)
		Ink.path(p, Paint.rect_poly(a.x - 2, a.y, 5, 7), 1.4, true, Color("#6a6e72"), 0.9)
	var candle := Vector2(cx + 34, floor_y - t * 0.5 - 6)
	_candle(p, candle, 34)
	RoomArt.light(p, [[candle + Vector2(0, -34), 1.6 * t, RoomArt.WARM, 0.8]], 0.66)
	Ink.glow(p, candle.x, candle.y - 44, 20, RoomArt.WARM, 0.5)
	Ink.grade(p, 0.24, 1.12)
	Ink.finish(p, 0.04, 0.0)
	return p


## 판(윗면) + 앞면 띠(두께 depth px). 윗면 = r(위에서 본 판).
static func _slab(p: Paint, r: Rect2, depth: float, top_sh: Callable, front_sh: Callable) -> void:
	var front := Paint.rect_poly(r.position.x, r.end.y, r.size.x, depth)
	p.fill_poly(front, front_sh)
	Ink.shade(p, front, Vector2(0, r.end.y), Vector2(0, r.end.y + depth), 0.1, 0.5)
	Ink.path(p, front, 2.0)
	var top := Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y)
	p.fill_poly(top, top_sh)
	Ink.shade(p, top, Vector2(0, r.position.y), Vector2(0, r.end.y), 0.0, 0.2)
	Ink.path(p, top, 2.0)


## 다리 넷(뒤 둘은 짧게 보인다) — 판 아래에서 바닥(판 앞면 아래 lift)까지.
static func _legs(p: Paint, r: Rect2, lift: float, c: Color, lw: float = 7.0) -> void:
	for lx: float in [r.position.x + 6, r.end.x - 6 - lw]:
		p.fill_rect(lx, r.position.y + 6, lw - 1, r.size.y - 6 + lift * 0.3, p.flat(c.darkened(0.3), 0.1))  # 뒷다리
		var leg := Paint.rect_poly(lx, r.end.y, lw, lift)
		p.fill_poly(leg, p.flat(c, 0.12))
		Ink.path(p, leg, 1.4)


static func _book_stack(p: Paint, base: Vector2, n: int) -> void:
	var y := base.y
	for i in n:
		var bw := p.rng.randf_range(20, 28)
		var b := Paint.rect_poly(base.x + p.rng.randf_range(-3, 3), y - 6, bw, 6)
		p.fill_poly(b, p.flat(Bits.BOOK_COLORS[p.rng.randi() % Bits.BOOK_COLORS.size()], 0.2))
		Ink.path(p, b, 1.1)
		y -= 6


static func _inkwell(p: Paint, c: Vector2) -> void:
	var pot := Paint.rect_poly(c.x - 4, c.y - 7, 8, 7)
	p.fill_poly(pot, p.flat(Color("#1a1a20"), 0.1))
	Ink.path(p, pot, 1.0)
	Ink.line(p, c + Vector2(1, -6), c + Vector2(12, -22), 1.6, Color("#d8d0b8"), 0.9, 0.2)  # 깃펜


static func _candle(p: Paint, base: Vector2, ch: float) -> void:
	var dish := Paint.rect_poly(base.x - 7, base.y - 3, 14, 4)
	p.fill_poly(dish, p.flat(Color("#4a4238"), 0.1))
	var body := Paint.rect_poly(base.x - 3, base.y - 3 - ch, 6, ch)
	p.fill_poly(body, p.flat(Color("#d8cfb4"), 0.1))
	Ink.path(p, body, 1.0)
	RoomArt._flame(p, Vector2(base.x, base.y - 4 - ch), 1.0)


static func _oil_lamp(p: Paint, base: Vector2) -> void:
	var bowl := Paint.poly([base + Vector2(-10, 0), base + Vector2(10, 0), base + Vector2(7, -8), base + Vector2(-7, -8)])
	p.fill_poly(bowl, p.flat(Color("#7a6238"), 0.12))
	Ink.path(p, bowl, 1.2)
	var chimney := Paint.rect_poly(base.x - 5, base.y - 26, 10, 18)
	p.fill_poly(chimney, p.flat(Color("#c8b890"), 0.1), 0.55)
	Ink.path(p, chimney, 1.0, true, Ink.INK, 0.6)
	RoomArt._flame(p, base + Vector2(0, -10), 0.9)
