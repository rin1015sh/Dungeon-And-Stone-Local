extends RefCounted
## 시설 실내 방 소품 그림 2(탑뷰 3/4 — RoomProps와 같은 규칙: 투명 바탕, 그림 아래 가운데 = rect 아래 가운데, 윗면 + 앞면 띠로 높이).
## 크기는 rect(칸 수 size)에 맞춘다. 계산대(counter)는 variant로 위에 놓인 것이 다르다 — inn 잔·술병 · shop 저울·단지 · guild 장부·종 · bank 놋쇠 창살·동전.
## 낮은 소품(통·궤짝·자루·허수아비·무기 걸이)은 도시 소품(Props — 옆에서 본 그림)을 줄여 세운다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Bits := preload("res://tools/city_art/InteriorBits.gd")
const Props := preload("res://tools/city_art/Props.gd")
const RoomArt := preload("res://tools/city_art/RoomArt.gd")
const RoomProps := preload("res://tools/city_art/RoomProps.gd")

const PAD := 10


## 계산대(rect w×1): 앞을 막은 판자 계산대 + 위에 놓인 것(variant).
static func counter(t: int, seed_value: int, size: Vector2i, variant: String) -> Paint:
	var lift := int(t * 0.62)
	var p := Paint.new(size.x * t + PAD * 2, t + lift + 90, seed_value)
	var top := Rect2(PAD + 2, p.h - t - lift + 8, size.x * t - 4, t - 14)
	var dark := Color("#2e2016") if variant != "bank" else Color("#3a2c22")
	RoomProps._slab(p, top, lift - 2, Mat.planks(p, Color("#4e3725"), 0, 0, false, 13), func(x: int, y: int) -> Color:
		var c := dark
		if posmod(x - PAD, int(t * 0.8)) < 4:
			c = dark.darkened(0.4)  # 앞판 칸막이
		return p.vary(c.darkened(absf(p.nz("vs", x, y) - 0.5) * 0.4), x, y, 0.15))
	var lights: Array = []
	var lamp := Vector2(top.position.x + 26, top.position.y + top.size.y * 0.35)
	match variant:
		"inn":
			for k in 4:
				Bits.mug(p, top.position.x + top.size.x * (0.3 + k * 0.14), top.position.y + top.size.y * (0.55 + (k % 2) * 0.2))
			_bottles(p, Vector2(top.end.x - 40, top.position.y + top.size.y * 0.5), 3)
		"shop":
			Bits.scale(p, Vector2(top.position.x + top.size.x * 0.55, top.position.y + top.size.y * 0.1))
			_bottles(p, Vector2(top.end.x - 50, top.position.y + top.size.y * 0.6), 4)
			RoomProps._book_stack(p, Vector2(top.position.x + top.size.x * 0.3, top.position.y + top.size.y * 0.75), 2)
		"guild":
			Bits.open_book(p, Vector2(top.position.x + top.size.x * 0.5, top.position.y + top.size.y * 0.25), 18)
			RoomProps._inkwell(p, Vector2(top.position.x + top.size.x * 0.68, top.position.y + top.size.y * 0.7))
			_papers(p, Rect2(top.position.x + top.size.x * 0.76, top.position.y + 6, 44, top.size.y - 12))
			_bell(p, Vector2(top.position.x + top.size.x * 0.32, top.position.y + top.size.y * 0.7))
		"bank":
			_grille(p, top, lift)
			for k in 3:
				Bits.coins(p, Vector2(top.position.x + top.size.x * (0.25 + k * 0.25), top.position.y + top.size.y * 0.7))
			lamp = Vector2(top.end.x - 26, top.position.y + top.size.y * 0.35)
	RoomProps._oil_lamp(p, lamp)
	lights.append([lamp, 2.2 * t, RoomArt.WARM, 0.8])
	return _done(p, lights, lamp)


## 제단(rect w×1): 돌 단 + 흰 제단보 + 초 둘 + 펼친 경전.
static func altar(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var lift := int(t * 0.7)
	var p := Paint.new(size.x * t + PAD * 2, t + lift + 70, seed_value)
	var top := Rect2(PAD + 6, p.h - t - lift + 10, size.x * t - 12, t - 18)
	RoomProps._slab(p, top, lift - 4, Mat.ashlar(p, Color("#77705f"), 0, 0, 30, 14), Mat.ashlar(p, Color("#5e584c"), 0, 0, 44, 20))
	Bits.altar_cloth(p, top.position.x + top.size.x * 0.2, top.end.y - 2, top.size.x * 0.6)
	Bits.open_book(p, Vector2(top.position.x + top.size.x * 0.5, top.position.y + top.size.y * 0.3), 16)
	var lights: Array = []
	for fx: float in [0.12, 0.88]:
		var c := Vector2(top.position.x + top.size.x * fx, top.position.y + top.size.y * 0.6)
		RoomProps._candle(p, c, 26)
		lights.append([c + Vector2(0, -30), 1.6 * t, RoomArt.WARM, 0.7])
	return _done(p, lights, lights[0][0])


## 봉헌 촛대(rect 2×1): 쇠 받침 세 단 + 초 여럿.
static func candles(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(size.x * t + PAD * 2, t + 80, seed_value)
	var g := p.h - t * 0.3
	var w := size.x * t - 20.0
	for row in 3:
		var y := g - 10 - row * 18
		var bar := Paint.rect_poly(PAD + 10 + row * 10, y, w - row * 20, 5)
		p.fill_poly(bar, p.flat(Color("#3a342c"), 0.1))
		Ink.path(p, bar, 1.2)
		for k in 5 - row:
			Props.candle(p, PAD + 18 + row * 10 + k * (w - row * 20 - 16) / maxf(1.0, 4.0 - row), y, 10.0 + p.rng.randf() * 8.0)
	for lx: float in [PAD + 12, PAD + w + 6]:
		Ink.line(p, Vector2(lx, g), Vector2(lx, g - 50), 3.0, Color("#26221e"), 1.0, 0.2)
	var c := Vector2(p.w * 0.5, g - 40)
	return _done(p, [[c, 1.8 * t, RoomArt.WARM, 0.9]], c)


## 긴 의자(rect w×1, 예배당 — 앉는 이는 제단(위)을 보니 등받이는 앞(아래) 쪽).
static func pew(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var lift := int(t * 0.42)
	var p := Paint.new(size.x * t + PAD * 2, t + lift + 40, seed_value)
	var seat := Rect2(PAD + 6, p.h - t * 0.7 - lift, size.x * t - 12, t * 0.36)
	RoomProps._legs(p, seat, lift, Color("#2a1d14"), 6.0)
	RoomProps._slab(p, seat, 6, Mat.planks(p, Color("#45311f"), 0, 0, false, 10), p.flat(Color("#2e2016"), 0.1))
	var back := Paint.rect_poly(seat.position.x, seat.end.y - 4, seat.size.x, lift + 10)
	p.fill_poly(back, Mat.planks(p, Color("#3a281b"), 0, 0, false, 9))
	Ink.shade(p, back, Vector2(0, seat.end.y), Vector2(0, seat.end.y + lift), 0.1, 0.45)
	Ink.path(p, back, 1.8)
	return _done(p, [], Vector2.ZERO)


## 모루(rect 2×1): 그루터기 위 검은 쇠 모루 + 망치·집게.
static func anvil(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(size.x * t + PAD * 2, t + 70, seed_value)
	var cx := p.w * 0.5
	var g := p.h - t * 0.3
	var stump := Paint.rect_poly(cx - 24, g - 34, 48, 34)
	p.fill_poly(stump, Mat.planks(p, Color("#4a3423"), 0, 0, true, 7))
	Ink.path(p, stump, 1.8)
	var body := Paint.poly([Vector2(cx - 50, g - 52), Vector2(cx + 40, g - 52), Vector2(cx + 58, g - 46), Vector2(cx + 30, g - 42), Vector2(cx + 16, g - 34), Vector2(cx - 16, g - 34), Vector2(cx - 26, g - 42), Vector2(cx - 50, g - 44)])
	p.fill_poly(body, func(x: int, y: int) -> Color: return p.vary(Color("#3a3c40").lightened(clampf((g - 50 - y) / 10.0, 0.0, 0.3)), x, y, 0.1))
	Ink.path(p, body, 2.0)
	Ink.line(p, Vector2(cx - 44, g - 51), Vector2(cx + 36, g - 51), 1.4, Color("#9aa0a8"), 0.7, 0.1)
	Ink.line(p, Vector2(cx + 2, g - 58), Vector2(cx + 34, g - 70), 4.0, Color("#4a3423"), 1.0, 0.2)  # 망치 자루
	p.fill_rect(cx + 28, g - 78, 14, 10, p.flat(Color("#4a4c50"), 0.1))
	return _done(p, [], Vector2.ZERO)


## 무기 걸이(rect 2×1).
static func rack(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(size.x * t + PAD * 2, t + 90, seed_value)
	Props.weapon_rack(p, p.w * 0.5, p.h - t * 0.3)
	return _done(p, [], Vector2.ZERO)


## 긴 걸상(rect w×1).
static func bench(t: int, seed_value: int, size: Vector2i, _variant: String) -> Paint:
	var lift := int(t * 0.4)
	var p := Paint.new(size.x * t + PAD * 2, t + lift + 20, seed_value)
	var seat := Rect2(PAD + 8, p.h - t * 0.66 - lift, size.x * t - 16, t * 0.3)
	RoomProps._legs(p, seat, lift, Color("#2a1d14"), 5.0)
	RoomProps._slab(p, seat, 6, Mat.planks(p, Color("#4a3423"), 0, 0, false, 10), p.flat(Color("#2e2016"), 0.1))
	return _done(p, [], Vector2.ZERO)


## 허수아비(rect 1×1).
static func dummy(t: int, seed_value: int, _size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(t + PAD * 2 + 40, t + 100, seed_value)
	Props.dummy(p, p.w * 0.5, p.h - t * 0.35, 0.62)
	return _done(p, [], Vector2.ZERO)


## 통(rect 1×1) — variant water = 물 담금 통(위에 물).
static func barrel(t: int, seed_value: int, _size: Vector2i, variant: String) -> Paint:
	var p := Paint.new(t + PAD * 2, t + 60, seed_value)
	var g := p.h - t * 0.3
	Props.barrel(p, p.w * 0.5, g, t * 0.62, t * 0.78)
	var lid := Paint.poly([Vector2(p.w * 0.5 - t * 0.31, g - t * 0.78), Vector2(p.w * 0.5 + t * 0.31, g - t * 0.78), Vector2(p.w * 0.5 + t * 0.27, g - t * 0.9), Vector2(p.w * 0.5 - t * 0.27, g - t * 0.9)])
	p.fill_poly(lid, p.flat(Color("#26343a") if variant == "water" else Color("#4a3423"), 0.15))
	Ink.path(p, lid, 1.6)
	return _done(p, [], Vector2.ZERO)


static func crate(t: int, seed_value: int, _size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(t + PAD * 2, t + 50, seed_value)
	Props.crate(p, p.w * 0.5, p.h - t * 0.3, t * 0.7)
	return _done(p, [], Vector2.ZERO)


static func sack(t: int, seed_value: int, _size: Vector2i, _variant: String) -> Paint:
	var p := Paint.new(t + PAD * 2, t + 40, seed_value)
	Props.sack(p, p.w * 0.5, p.h - t * 0.3, t * 0.6)
	return _done(p, [], Vector2.ZERO)


## 빛·색 보정·그레인(RoomArt와 같은 식). glow = 불꽃 둘레 번짐(없으면 Vector2.ZERO).
static func _done(p: Paint, lights: Array, glow: Vector2) -> Paint:
	RoomArt.light(p, lights, 0.66)
	if glow != Vector2.ZERO:
		Ink.glow(p, glow.x, glow.y - 12, 22, RoomArt.WARM, 0.45)
	Ink.grade(p, 0.24, 1.12)
	Ink.finish(p, 0.04, 0.0)
	return p


static func _bottles(p: Paint, base: Vector2, n: int) -> void:
	for k in n:
		var x := base.x + k * 9
		var bh := p.rng.randf_range(16, 24)
		var b := Paint.poly([Vector2(x, base.y), Vector2(x, base.y - bh * 0.6), Vector2(x + 2, base.y - bh), Vector2(x + 5, base.y - bh), Vector2(x + 7, base.y - bh * 0.6), Vector2(x + 7, base.y)])
		p.fill_poly(b, p.flat([Color("#2f4430"), Color("#4e2a1c"), Color("#2b3138")][k % 3], 0.2))
		Ink.path(p, b, 1.0)


static func _papers(p: Paint, r: Rect2) -> void:
	for k in 3:
		var sheet := Paint.rect_poly(r.position.x + k * 3, r.position.y + k * 4, r.size.x * 0.8, r.size.y * 0.6)
		p.fill_poly(sheet, p.flat(Color("#bfb391"), 0.12))
		Ink.path(p, sheet, 1.0)


static func _bell(p: Paint, c: Vector2) -> void:
	var dome := Paint.poly([c + Vector2(-7, 0), c + Vector2(-5, -8), c + Vector2(0, -11), c + Vector2(5, -8), c + Vector2(7, 0)])
	p.fill_poly(dome, p.flat(Color("#9a7a38"), 0.1))
	Ink.path(p, dome, 1.0)


## 은행 창구 놋쇠 창살: 계산대 뒤 끝에서 솟은 살 + 위 가로대, 창구마다 빈 틈.
static func _grille(p: Paint, top: Rect2, lift: int) -> void:
	var y0 := top.position.y + 4
	var h := float(lift) + 26.0
	Ink.line(p, Vector2(top.position.x, y0 - h), Vector2(top.end.x, y0 - h), 4.0, Color("#8a6a2a"), 1.0, 0.1)
	var x := top.position.x + 6
	var k := 0
	while x < top.end.x:
		if k % 9 >= 6:  # 창구 틈
			x += 8
			k += 1
			continue
		Ink.line(p, Vector2(x, y0), Vector2(x, y0 - h), 2.0, Color("#9a7a38"), 1.0, 0.05)
		x += 8
		k += 1
