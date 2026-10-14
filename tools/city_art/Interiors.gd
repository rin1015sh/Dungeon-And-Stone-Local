extends RefCounted
## 시설 내부 배경 일러스트(427×240, 화면에서 3배 확대). 정면에서 본 방: 뒷벽 + 바닥 + 가구. tools/paint_city.gd 전용.

const Px := preload("res://tools/city_art/Px.gd")
const Props := preload("res://tools/city_art/Props.gd")

const W := 427
const H := 240
const FLOOR_Y := 168
const WOOD := Color("#6a4d35")
const BEAM := Color("#3b2a1d")


static func paint(id: String, seed_value: int) -> Px:
	var p := Px.new(W, H, seed_value)
	match id:
		"inn":
			_inn(p)
		"library":
			_library(p)
		"temple":
			_temple(p)
		"shop":
			_shop(p)
		"bank":
			_bank(p)
		"training":
			_training(p)
	_vignette(p)
	return p


## 판자 바닥(앞으로 올수록 넓어지는 줄).
static func _floor_planks(p: Px, base: Color) -> void:
	var y := FLOOR_Y
	var hgt := 4
	while y < H:
		p.planks_h(0, y, W, hgt, base.lightened((y - FLOOR_Y) / 600.0), hgt)
		y += hgt
		hgt += 1
	p.shade_grad(0, FLOOR_Y, W, 10, -0.4, 0.0)


static func _floor_stone(p: Px, base: Color) -> void:
	p.stones(0, FLOOR_Y, W, H - FLOOR_Y, base, base.darkened(0.55), 10, 18)
	p.shade_grad(0, FLOOR_Y, W, 10, -0.4, 0.0)


## 따뜻한 빛 번짐(촛불·난로).
static func _glow(p: Px, cx: int, cy: int, radius: int, c: Color, strength: float) -> void:
	for yy in range(-radius, radius + 1):
		for xx in range(-radius, radius + 1):
			var d := Vector2(xx, yy).length()
			if d <= radius:
				p.px(cx + xx, cy + yy, Color(c.r, c.g, c.b, strength * (1.0 - d / radius)))


static func _vignette(p: Px) -> void:
	for yy in H:
		for xx in W:
			var d := Vector2((xx - W / 2.0) / (W / 2.0), (yy - H / 2.0) / (H / 2.0)).length()
			if d > 0.75:
				p.px(xx, yy, Color(0.03, 0.02, 0.02, clampf((d - 0.75) * 0.9, 0.0, 0.55)))


static func _table(p: Px, x: int, y: int, tw: int) -> void:
	p.planks_h(x, y, tw, 4, Color("#7a5b3c"), 2)
	p.rect(x, y + 4, tw, 1, BEAM)
	p.rect(x + 3, y + 5, 3, 16, BEAM)
	p.rect(x + tw - 6, y + 5, 3, 16, BEAM)


static func _bookshelf(p: Px, x: int, y: int, sw: int, sh: int) -> void:
	p.planks_v(x, y, sw, sh, Color("#4a3526"), 6)
	var cols := [Color("#7a2c28"), Color("#3e5a7a"), Color("#5a6a32"), Color("#8a6d3b"), Color("#5a3a5a"), Color("#a08a62"), Color("#2e3f35")]
	var sy := y + 4
	while sy + 14 < y + sh:
		var bx := x + 3
		while bx < x + sw - 4:
			var bw := p.rng.randi_range(2, 4)
			var bh := p.rng.randi_range(9, 13)
			var c: Color = cols[p.rng.randi_range(0, cols.size() - 1)]
			p.rect(bx, sy + 13 - bh, bw, bh, p.jit(c, 0.08))
			p.px(bx, sy + 13 - bh + 2, Color("#c9a24a"))
			p.rect(bx + bw - 1, sy + 13 - bh, 1, bh, c.darkened(0.35))
			bx += bw + (1 if p.rng.randf() < 0.15 else 0)
		p.rect(x + 2, sy + 13, sw - 4, 2, Color("#2c2119"))
		sy += 16


static func _inn(p: Px) -> void:
	p.planks_v(0, 0, W, FLOOR_Y, Color("#5a4230"), 7)
	for bx in [0, 104, 214, 324, 420]:
		p.rect(bx, 0, 7, FLOOR_Y, BEAM)
	p.rect(0, 22, W, 6, BEAM)
	_floor_planks(p, Color("#5e4632"))
	p.stones(150, 70, 80, 98, Color("#4f514d"), Color("#232421"), 6, 10)  # 벽난로
	p.rect(166, 112, 48, 56, Color("#140e0b"))
	for i in 40:
		var fx := 172 + p.rng.randi_range(0, 36)
		var fh := p.rng.randi_range(6, 22)
		p.line(Vector2i(fx, 166), Vector2i(fx + p.rng.randi_range(-2, 2), 166 - fh), [Color("#f2c46c"), Color("#e07a2a"), Color("#b8401f")][i % 3])
	p.noisy_rect(146, 66, 88, 6, Color("#6a5a48"), 0.05)
	_glow(p, 190, 150, 90, Color(1.0, 0.6, 0.25), 0.22)
	for wx in [40, 340]:
		p.window(wx, 60, 30, 34, false)
	p.planks_v(250, 120, 18, 48, WOOD, 3)  # 계단 난간
	for i in 6:
		p.planks_h(270 + i * 9, 160 - i * 14, 40, 4, WOOD, 4)
	p.planks_h(320, 128, 90, 12, Color("#6d4a3a"), 4)  # 침대
	p.noisy_rect(324, 118, 80, 10, Color("#a89a7c"), 0.05)
	p.noisy_rect(326, 112, 20, 8, Color("#d8d0bc"), 0.04)
	p.rect(320, 104, 4, 40, BEAM)
	p.rect(406, 104, 4, 40, BEAM)
	for t in [[40, 180, 70], [250, 186, 64]]:
		_table(p, t[0], t[1], t[2])
		for m in 3:
			Props.barrel(p, t[0] + 14 + m * 18, t[1], 4, 5)
	for lx in [96, 300]:
		p.rect(lx, 28, 1, 22, Color("#2b2522"))
		p.rect(lx - 3, 50, 7, 7, Color("#f2c46c"))
		_glow(p, lx, 53, 30, Color(1.0, 0.75, 0.4), 0.18)


static func _library(p: Px) -> void:
	p.stones(0, 0, W, FLOOR_Y, Color("#6e675c"), Color("#2e2a25"), 12, 20)
	_floor_planks(p, Color("#4e3a2a"))
	for sx in [6, 76, 300, 370]:
		_bookshelf(p, sx, 20, 60, 148)
	p.window(170, 30, 86, 110, false, Color("#2c2119"), true)
	for yy in range(30, 168):
		for xx in range(0, 70):
			var bx := 180 + xx + (yy - 30) / 2
			if (xx / 12) % 2 == 0:
				p.px(bx, yy, Color(1.0, 0.92, 0.7, 0.05))
	_table(p, 160, 176, 110)
	p.noisy_rect(196, 168, 30, 8, Color("#e2d8bc"), 0.03)  # 펼친 책
	p.rect(210, 168, 1, 8, Color("#8a7a5a"))
	Props.candle(p, 180, 170)
	_glow(p, 180, 168, 50, Color(1.0, 0.75, 0.4), 0.2)
	p.line(Vector2i(140, 30), Vector2i(150, 168), WOOD)  # 사다리
	p.line(Vector2i(156, 30), Vector2i(166, 168), WOOD)
	for i in 10:
		p.line(Vector2i(141 + i, 40 + i * 13), Vector2i(157 + i, 40 + i * 13), WOOD.darkened(0.2))


static func _temple(p: Px) -> void:
	p.stones(0, 0, W, FLOOR_Y, Color("#8f8778"), Color("#4a453c"), 12, 20)
	_floor_stone(p, Color("#77705f"))
	for cx in [70, 357]:  # 기둥
		p.noisy_rect(cx - 10, 0, 20, FLOOR_Y, Color("#a69e8b"), 0.04)
		p.rect(cx + 6, 0, 4, FLOOR_Y, Color("#6e675a"))
	p.rect(150, 10, 127, 130, Color("#3c3730"))
	for yy in 120:  # 색유리 큰 창
		for xx in 100:
			var d := Vector2(xx - 50, yy - 50).length()
			if yy < 50 and d > 50:
				continue
			var cols := [Color("#a33a35"), Color("#3f5f9b"), Color("#c9a24a"), Color("#4f7a45"), Color("#6a4a8a")]
			var c: Color = cols[((xx / 10) * 3 + (yy / 12)) % cols.size()]
			if xx % 10 == 0 or yy % 12 == 0:
				c = Color("#1e1712")
			p.px(164 + xx, 16 + yy, p.jit(c, 0.07))
	_glow(p, 214, 80, 120, Color(1.0, 0.9, 0.7), 0.12)
	p.noisy_rect(160, 140, 108, 30, Color("#b8ad95"), 0.03)  # 제단
	p.noisy_rect(166, 136, 96, 10, Color("#e8e0cc"), 0.03)
	p.rect(206, 146, 16, 24, Color("#8a2f2a"))
	for cx in [172, 184, 244, 256]:
		Props.candle(p, cx, 130)
	for row in 3:  # 의자
		var y := 186 + row * 18
		for side in [[20, 170], [257, 170]]:
			p.planks_h(side[0] - row * 8, y, side[1] + row * 6, 6, Color("#5a4230"), 3)
			p.rect(side[0] - row * 8, y + 6, side[1] + row * 6, 2, BEAM)
	for bx in [100, 314]:
		Props.banner(p, bx, 120, Color("#8a2f2a"))


static func _shop(p: Px) -> void:
	p.planks_v(0, 0, W, FLOOR_Y, Color("#5e4632"), 6)
	_floor_planks(p, Color("#5a4230"))
	var cols := [Color("#9b2a2a"), Color("#2f5a9b"), Color("#4f7a45"), Color("#c9a24a"), Color("#7a5a8a")]
	for row in 4:  # 선반 + 병
		var sy := 30 + row * 30
		p.planks_h(20, sy + 18, 387, 4, WOOD, 4)
		var x := 26
		while x < 400:
			if p.rng.randf() < 0.7:
				var c: Color = cols[p.rng.randi_range(0, cols.size() - 1)]
				var bh := p.rng.randi_range(8, 14)
				p.rect(x, sy + 18 - bh, 6, bh, p.jit(c, 0.08))
				p.rect(x + 2, sy + 18 - bh - 2, 2, 2, Color("#8a7a5a"))
				p.px(x + 1, sy + 20 - bh, c.lightened(0.4))
			x += p.rng.randi_range(8, 14)
	for hx in range(40, 400, 36):  # 매단 약초
		p.rect(hx, 0, 1, 14, Color("#2b2522"))
		p.blob(hx, 18, 4, Color("#5a6a32"))
	p.planks_h(60, 160, 300, 30, Color("#6e5238"), 5)  # 판매대
	p.rect(60, 158, 300, 3, Color("#8a6d4a"))
	p.rect(196, 140, 2, 18, Color("#8a7a5a"))  # 저울
	p.rect(184, 140, 26, 1, Color("#8a7a5a"))
	p.rect(182, 146, 8, 2, Color("#c9a24a"))
	p.rect(204, 146, 8, 2, Color("#c9a24a"))
	for i in 3:
		Props.sack(p, 20 + i * 10, 230)
	Props.barrel(p, 390, 232, 16, 20)
	Props.crate(p, 370, 232, 14)


static func _bank(p: Px) -> void:
	p.stones(0, 0, W, FLOOR_Y, Color("#5b5f62"), Color("#24272a"), 16, 24)
	_floor_stone(p, Color("#4f5355"))
	for yy in range(-46, 47):  # 금고 문
		for xx in range(-46, 47):
			var d := Vector2(xx, yy).length()
			if d <= 46:
				var c := Color("#6a6e72") if d < 40 else Color("#3a3d40")
				if d < 8:
					c = Color("#c9a24a")
				elif absi(xx) < 2 or absi(yy) < 2:
					c = Color("#4a4d50")
				p.px(330 + xx, 84 + yy, p.jit(c, 0.04))
	p.noisy_rect(20, 120, 260, 70, Color("#4a3526"), 0.04)  # 창구
	p.rect(20, 118, 260, 4, Color("#8a6d4a"))
	for bx in range(24, 280, 6):
		p.rect(bx, 40, 1, 78, Color("#1d1d20"))
	p.rect(20, 40, 260, 3, Color("#2b2b2e"))
	for i in 5:
		for k in p.rng.randi_range(2, 5):
			p.rect(60 + i * 40, 114 - k * 2, 8, 2, Color("#c9a24a").darkened(0.1 * (k % 2)))
	p.noisy_rect(180, 108, 28, 10, Color("#d8cfb4"), 0.03)
	for lx in [40, 260]:
		p.rect(lx, 10, 1, 20, Color("#2b2522"))
		p.rect(lx - 3, 30, 7, 7, Color("#f2c46c"))
		_glow(p, lx, 33, 34, Color(1.0, 0.75, 0.4), 0.16)


static func _training(p: Px) -> void:
	p.gradient_v(0, 0, W, 110, Color("#56636d"), Color("#a6a796"))
	for x in range(0, W, 7):  # 통나무 울타리
		var top := 70 + p.rng.randi_range(0, 6)
		p.planks_v(x, top, 7, FLOOR_Y - top, Color("#5e4632"), 7)
		p.px(x + 3, top - 1, Color("#5e4632"))
	p.rect(0, 96, W, 3, Color("#3a2a1e"))
	p.rect(0, 140, W, 3, Color("#3a2a1e"))
	p.noisy_rect(0, FLOOR_Y - 20, W, H - FLOOR_Y + 20, Color("#8a7656"), 0.07)
	for i in 120:
		p.px(p.rng.randi_range(0, W - 1), p.rng.randi_range(FLOOR_Y - 18, H - 1), Color("#6d5d44"))
	for x in [70, 150, 330]:
		Props.dummy(p, x, 200)
	Props.weapon_rack(p, 250, 186)
	Props.weapon_rack(p, 270, 186)
	for r in [14, 10, 6, 2]:  # 과녁
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if xx * xx + yy * yy <= r * r:
					p.px(390 + xx, 150 + yy, Color("#d8cfb4") if r % 8 == 6 or r == 14 else Color("#9b2a2a"))
	p.rect(389, 164, 2, 30, WOOD)
	Props.banner(p, 20, 200, Color("#8a2f2a"))
	Props.banner(p, 404, 210, Color("#3f5f9b"))
