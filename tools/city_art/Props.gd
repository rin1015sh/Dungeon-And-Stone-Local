extends RefCounted
## 도시 그림 소품(통·상자·자루·나무·덤불·울타리·등불·간판·허수아비·무기걸이·수레·우물·촛불).
## 모두 (p: Px, 발 위치 x, 바닥 y) 기준 — 아래쪽 가운데가 땅에 닿는다. tools/paint_city.gd 전용.

const Px := preload("res://tools/city_art/Px.gd")

const WOOD := Color("#6b4f36")
const WOOD_D := Color("#3e2c1f")
const IRON := Color("#3a3a3e")
const LEAF := Color("#4a6a2a")
const APPLE := Color("#b0352a")

## 간판 그림(7×7). 글자 → 색은 SIGN_COLORS.
const ICONS := {
	"mug": ["..www..", ".wwwww.", "ybbbbby", "ybbbbbbb", "ybbbbby", "ybbbbby", ".yyyyy."],
	"book": ["rrrrrr.", "rwwwwr.", "rwwwwr.", "rwwwwr.", "rwwwwr.", "rrrrrr.", "......."],
	"sun": ["...y...", ".y.y.y.", "..yyy..", "yyyyyyy", "..yyy..", ".y.y.y.", "...y..."],
	"bag": ["..bb...", ".b..b..", "..yy...", ".yyyy..", "yyyyyy.", "yyyyyy.", ".yyyy.."],
	"key": [".yyy...", "y...y..", "y...y..", ".yyy...", "..y....", "..yy...", "..yyy.."],
	"swords": ["s.....s", ".s...s.", "..s.s..", "...s...", "..s.s..", ".b...b.", "b.....b"],
}
const SIGN_COLORS := {"w": Color("#e8e2d0"), "y": Color("#c9a24a"), "b": Color("#6b4a2c"), "r": Color("#8a2f2a"), "s": Color("#b8bcc4")}


static func barrel(p: Px, x: int, ground: int, bw: int = 9, bh: int = 11) -> void:
	var top := ground - bh
	for yy in bh:
		var bulge := 1 if (yy > 1 and yy < bh - 2) else 0
		for xx in range(-bulge, bw + bulge):
			var c := WOOD
			if (xx + 1) % 3 == 0:
				c = WOOD_D
			if xx <= 0:
				c = c.lightened(0.1)
			elif xx >= bw - 1:
				c = c.darkened(0.3)
			p.px(x - bw / 2 + xx, top + yy, p.jit(c, 0.05))
	for hy in [top + 2, ground - 3]:
		for xx in range(-1, bw + 1):
			p.px(x - bw / 2 + xx, hy, IRON.lightened(0.15) if xx < bw / 2 else IRON)
	p.rect(x - bw / 2, top, bw, 1, WOOD.lightened(0.15))


static func crate(p: Px, x: int, ground: int, s: int = 9) -> void:
	var x0 := x - s / 2
	var y0 := ground - s
	p.planks_h(x0, y0, s, s, Color("#7a5b3c"), 3)
	p.rect(x0, y0, s, 1, WOOD_D)
	p.rect(x0, ground - 1, s, 1, WOOD_D)
	p.rect(x0, y0, 1, s, WOOD_D)
	p.rect(x0 + s - 1, y0, 1, s, WOOD_D)
	p.line(Vector2i(x0 + 1, y0 + 1), Vector2i(x0 + s - 2, ground - 2), WOOD_D.lightened(0.1))


static func sack(p: Px, x: int, ground: int) -> void:
	var c := Color("#a08a62")
	for yy in 8:
		var half := 2 + mini(yy, 3)
		for xx in range(-half, half + 1):
			p.px(x + xx, ground - 8 + yy, p.jit(c.darkened(0.2) if xx > half - 2 else c, 0.05))
	p.rect(x - 1, ground - 9, 3, 1, Color("#6d5a3c"))


## 사과나무(레퍼런스의 붉은 열매 나무). size 1 = 보통.
static func tree(p: Px, x: int, ground: int, size: float = 1.0, apples: bool = true) -> void:
	var th := int(22 * size)
	for yy in th:
		var tw := 3 if yy < th - 4 else 4 + (yy - th + 4)
		for xx in tw:
			p.px(x - tw / 2 + xx, ground - th + yy, p.jit(Color("#4b3626") if xx < tw - 1 else Color("#33241a"), 0.06))
	p.line(Vector2i(x, ground - th + 4), Vector2i(x - int(7 * size), ground - th - 2), Color("#4b3626"))
	p.line(Vector2i(x, ground - th + 6), Vector2i(x + int(8 * size), ground - th), Color("#4b3626"))
	var cy := ground - th - int(6 * size)
	for i in int(14 * size):
		var bx := x + p.rng.randi_range(int(-13 * size), int(13 * size))
		var by := cy + p.rng.randi_range(int(-8 * size), int(6 * size))
		p.blob(bx, by, p.rng.randi_range(4, 7), LEAF.darkened(0.15) if by > cy else LEAF, PackedVector2Array(), 0.9)
	for i in int(10 * size):
		var bx := x + p.rng.randi_range(int(-12 * size), int(12 * size))
		var by := cy + p.rng.randi_range(int(-10 * size), int(-2 * size))
		p.blob(bx, by, 2, LEAF.lightened(0.15), PackedVector2Array(), 0.6)
	if apples:
		for i in int(12 * size):
			var ax := x + p.rng.randi_range(int(-12 * size), int(12 * size))
			var ay := cy + p.rng.randi_range(int(-8 * size), int(6 * size))
			if p.opaque(ax, ay):
				p.px(ax, ay, APPLE)
				p.px(ax + 1, ay, APPLE.darkened(0.3))


static func bush(p: Px, x: int, ground: int, rw: int = 10) -> void:
	for i in rw / 2:
		p.blob(x + p.rng.randi_range(-rw / 2, rw / 2), ground - p.rng.randi_range(2, 5), p.rng.randi_range(2, 4), LEAF.darkened(0.1))


static func grass_tufts(p: Px, x: int, ground: int, rw: int, count: int) -> void:
	for i in count:
		var gx := x + p.rng.randi_range(0, rw)
		for k in p.rng.randi_range(1, 3):
			p.px(gx + k - 1, ground - p.rng.randi_range(1, 3), LEAF.lightened(p.rng.randf_range(0.0, 0.25)))


static func fence(p: Px, x0: int, x1: int, ground: int, fh: int = 9) -> void:
	for x in range(x0, x1 + 1, 6):
		p.rect(x, ground - fh, 2, fh, WOOD)
		p.px(x, ground - fh, WOOD.lightened(0.15))
		p.rect(x + 1, ground - fh, 1, fh, WOOD_D)
	for ry in [ground - fh + 2, ground - fh + 5]:
		for x in range(x0, x1 + 2):
			p.px(x, ry, p.jit(WOOD.lightened(0.05), 0.08))
			p.px(x, ry + 1, WOOD_D)


## 등불 기둥(따뜻한 빛 번짐 포함).
static func lamp_post(p: Px, x: int, ground: int) -> void:
	p.rect(x, ground - 26, 2, 26, Color("#2b2522"))
	p.rect(x - 1, ground - 2, 4, 2, Color("#2b2522"))
	p.rect(x - 2, ground - 30, 6, 5, Color("#2b2522"))
	p.rect(x - 1, ground - 29, 4, 3, Color("#f2c46c"))
	for r in range(6, 1, -1):
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if xx * xx + yy * yy <= r * r:
					p.px(x + 1 + xx, ground - 28 + yy, Color(1.0, 0.75, 0.4, 0.05))


## 매달린 간판: 벽에서 튀어나온 쇠 팔 + 판 + 그림(ICONS).
static func sign(p: Px, x: int, y: int, icon: String, facing_right: bool = true) -> void:
	var dir := 1 if facing_right else -1
	for i in 10:
		p.px(x + i * dir, y, IRON)
	p.px(x + 1 * dir, y + 1, IRON)
	var bx := x + (2 if facing_right else -11)
	p.px(bx + 1, y + 1, IRON)
	p.px(bx + 8, y + 1, IRON)
	p.rect(bx, y + 2, 10, 10, Color("#2a1e15"))
	p.noisy_rect(bx + 1, y + 3, 8, 8, Color("#5e4430"), 0.06)
	var rows: Array = ICONS.get(icon, [])
	p.sprite(bx + 1, y + 4, PackedStringArray(rows), SIGN_COLORS)


static func dummy(p: Px, x: int, ground: int) -> void:
	p.rect(x, ground - 22, 2, 22, WOOD)
	p.rect(x - 5, ground - 18, 12, 2, WOOD)
	for yy in 9:
		for xx in range(-3, 5):
			p.px(x + xx, ground - 17 + yy, p.jit(Color("#b89a55"), 0.08))
	for yy in 5:
		for xx in range(-1, 3):
			p.px(x + xx, ground - 25 + yy, p.jit(Color("#a08a62"), 0.06))
	p.rect(x - 3, ground - 13, 8, 1, Color("#6d5a3c"))
	p.px(x, ground - 23, Color("#2a1e15"))
	p.px(x + 1, ground - 23, Color("#2a1e15"))


static func weapon_rack(p: Px, x: int, ground: int) -> void:
	p.rect(x - 7, ground - 14, 2, 14, WOOD)
	p.rect(x + 6, ground - 14, 2, 14, WOOD)
	p.rect(x - 7, ground - 12, 15, 1, WOOD_D)
	p.rect(x - 7, ground - 4, 15, 1, WOOD_D)
	for i in 4:
		var wx := x - 4 + i * 3
		p.rect(wx, ground - 17 + (i % 2) * 2, 1, 14, Color("#b8bcc4") if i % 2 == 0 else Color("#6b4f36"))
		p.px(wx, ground - 18 + (i % 2) * 2, Color("#e0e2e6"))


static func banner(p: Px, x: int, ground: int, c: Color) -> void:
	p.rect(x, ground - 34, 1, 34, Color("#2b2522"))
	for yy in 14:
		var ww := 7 - (1 if yy > 10 else 0)
		for xx in ww:
			if yy > 11 and xx == ww / 2:
				continue
			p.px(x + 1 + xx, ground - 33 + yy, p.jit(c.darkened(0.2) if xx > ww - 3 else c, 0.05))


static func cart(p: Px, x: int, ground: int) -> void:
	p.planks_h(x - 10, ground - 12, 20, 6, Color("#6e5238"), 3)
	p.rect(x - 10, ground - 6, 20, 1, WOOD_D)
	p.line(Vector2i(x + 10, ground - 9), Vector2i(x + 20, ground - 4), WOOD)
	for wx in [x - 6, x + 6]:
		for yy in range(-4, 5):
			for xx in range(-4, 5):
				var d := Vector2(xx, yy).length()
				if d <= 4.2 and d >= 3.0:
					p.px(wx + xx, ground - 4 + yy, WOOD_D)
				elif d < 1.2:
					p.px(wx + xx, ground - 4 + yy, IRON)


static func well(p: Px, x: int, ground: int) -> void:
	p.stones(x - 9, ground - 8, 18, 8, Color("#5d625e"), Color("#2b2e2c"), 3, 5)
	p.rect(x - 8, ground - 22, 2, 14, WOOD)
	p.rect(x + 6, ground - 22, 2, 14, WOOD)
	p.shingles(PackedVector2Array([Vector2(x - 12, ground - 21), Vector2(x, ground - 29), Vector2(x + 12, ground - 21)]), Color("#5b4535"), 3, 2)
	p.rect(x - 6, ground - 17, 12, 1, WOOD_D)
	p.rect(x - 1, ground - 16, 1, 5, Color("#8a7a5a"))
	barrel(p, x, ground - 9, 4, 4)


static func candle(p: Px, x: int, y: int) -> void:
	p.rect(x, y, 1, 3, Color("#e8e0c8"))
	p.px(x, y - 1, Color("#ffd27a"))
	for r in [3, 2]:
		for yy in range(-r, r + 1):
			for xx in range(-r, r + 1):
				if xx * xx + yy * yy <= r * r:
					p.px(x + xx, y - 1 + yy, Color(1.0, 0.8, 0.45, 0.08))
