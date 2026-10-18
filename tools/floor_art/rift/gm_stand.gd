extends RefCounted
## 녹색 탄광 소품 1(버팀목·결정·광차·통·궤짝·랜턴·비계·버섯). 칸 = 바닥 2 × 3칸, 발 = (w/2, h - w×0.14).
## 빛은 왼쪽 위, 잉크 윤곽 + 붓 결. 빛나는 것(결정·랜턴·버섯)만 빛 번짐을 굽는다. 처리한 소품이면 true(나머지는 gm_stand2).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const K := preload("res://tools/floor_art/rift/gm_kit.gd")


static func paint(p: Paint, tile: String) -> bool:
	var u := p.w / 128.0
	var foot := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	match tile:
		"gm_support":
			_support(p, foot, u)
		"gm_crystal":
			_crystal(p, foot, u)
		"gm_cart":
			_cart(p, foot, u)
		"gm_barrel":
			_barrel(p, foot, u)
		"gm_crate":
			_crate(p, foot, u)
		"gm_lantern":
			_lantern_post(p, foot, u)
		"gm_scaffold":
			_scaffold(p, foot, u)
		"gm_mushroom":
			_mushrooms(p, foot, u)
		_:
			return false
	return true


## 갱도 버팀목: 네모 기둥 + 위 받침 들보 + 까치발 두 개 + 쇠 띠·못 + 밑동 쐐기돌.
static func _support(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(4, 0) * u, 24 * u, 8 * u)
	var post := Kit.box(p, foot, 15 * u, 12 * u, 128 * u, K.WOOD)
	K.wood(p, post["front"], K.WOOD.darkened(0.05), true, 0.0)
	Ink.path(p, post["front"], 1.5 * u, true, Ink.INK, 0.85, 0.3)
	var cap := Kit.box(p, foot + Vector2(0, -128) * u, 64 * u, 16 * u, 13 * u, K.WOOD.darkened(0.08))
	K.wood_box(p, cap, K.WOOD.darkened(0.08), 1)
	for e: float in [-1.0, 1.0]:  # 까치발
		var a := foot + Vector2(e * 6.5, -92) * u
		var b := foot + Vector2(e * 26.0, -126) * u
		K.beam(p, a, b, 6.5 * u, K.WOOD.darkened(0.1))
	for y: float in [-40.0, -100.0]:  # 쇠 띠
		var r := Rect2(foot.x - 7.5 * u, foot.y + (y - 3.0) * u, 15 * u, 5 * u)
		p.fill_rect(r.position.x, r.position.y, r.size.x, r.size.y, func(x: int, yy: int) -> Color: return p.vary(K.IRON.lerp(K.RUST, 0.35), x, yy, 0.12))
		Ink.path(p, Paint.rect_poly(r.position.x, r.position.y, r.size.x, r.size.y), 1.0 * u, true, Ink.INK, 0.8, 0.2)
		K.nail(p, r.get_center() + Vector2(-3.5, 0) * u, 1.1 * u)
		K.nail(p, r.get_center() + Vector2(3.5, 0) * u, 1.1 * u)
	for e: float in [-24.0, 24.0]:
		K.nail(p, foot + Vector2(e, -121) * u, 1.2 * u)
	Ink.grime(p, foot.x - 7 * u, foot.y - 30 * u, 15 * u, 26 * u, 0.4)
	for k in 3:  # 쐐기돌
		Cave._stone(p, foot + Vector2(p.rng.randf_range(-16, 16), p.rng.randf_range(-2, 4)) * u, p.rng.randf_range(4, 7) * u, 3.5 * u, K.ROCK)


## 큰 라임빛 결정 무리: 바위 받침에서 솟은 기둥 5~6개 + 작은 결정들 + 큰 빛 번짐.
static func _crystal(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 30 * u, 9 * u, 0.5)
	K.halo(p, foot + Vector2(0, -52) * u, 64 * u, K.LIME_GLOW, 0.32)
	K.crystals(p, foot + Vector2(-2, -6) * u, 104 * u, 5, 0.18)
	K.crystals(p, foot + Vector2(-22, 0) * u, 40 * u, 3, 0.15)
	K.crystals(p, foot + Vector2(22, 2) * u, 34 * u, 2, 0.15)
	for k in 5:  # 뿌리를 덮은 바위
		var q := foot + Vector2(p.rng.randf_range(-26, 26), p.rng.randf_range(-3, 5)) * u
		Cave._stone(p, q, p.rng.randf_range(6, 10) * u, p.rng.randf_range(4, 6) * u, K.ROCK_VIOLET.lerp(K.ROCK, p.rng.randf()))
	Ink.glow(p, foot.x - 4 * u, foot.y - 36 * u, 26 * u, K.LIME_LIGHT, 0.18, true)


## 광차: 녹슨 쇠 상자(위가 넓은 사다리꼴) + 리벳 + 수레바퀴 + 녹색 빛이 도는 광석 더미.
static func _cart(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot + Vector2(0, -6) * u, 38 * u, 10 * u, 0.5)
	var dd := Vector2(8, -16) * u
	var base_y := foot.y - 12 * u
	for e: float in [-19.0, 19.0]:  # 뒷바퀴
		_wheel(p, Vector2(foot.x + e * u, foot.y - 5 * u) + dd, 7.5 * u, true)
	var bl := Vector2(foot.x - 29 * u, base_y)
	var br := Vector2(foot.x + 29 * u, base_y)
	var tl := Vector2(foot.x - 36 * u, base_y - 36 * u)
	var tr := Vector2(foot.x + 36 * u, base_y - 36 * u)
	var side := PackedVector2Array([br, tr, tr + dd, br + dd])
	p.fill_poly(side, func(x: int, y: int) -> Color: return p.vary(K.IRON.darkened(0.45), x, y, 0.1))
	var inner := PackedVector2Array([tl, tr, tr + dd, tl + dd])
	p.fill_poly(inner, func(x: int, y: int) -> Color: return p.vary(K.IRON.darkened(0.6), x, y, 0.1))
	# 광석 더미(테두리 위로 솟음)
	for k in 16:
		var t := p.rng.randf()
		var q := tl.lerp(tr, t) + dd * p.rng.randf_range(0.15, 0.85) + Vector2(0, -p.rng.randf_range(0, 9) * u * sin(t * PI))
		var r := p.rng.randf_range(4.5, 7.5) * u
		Cave._stone(p, q, r, r * 0.75, Color("#3e3c46").lerp(K.ROCK, p.rng.randf()))
	for k in 3:
		var q := tl.lerp(tr, p.rng.randf_range(0.2, 0.8)) + dd * 0.5 + Vector2(0, -6) * u
		K.glint(p, q, 2.2 * u)
	var front := PackedVector2Array([tl, tr, br, bl])
	p.fill_poly(front, func(x: int, y: int) -> Color:
		var t := clampf((y - tl.y) / (base_y - tl.y), 0.0, 1.0)
		var c := K.IRON.lerp(K.RUST, clampf(p.nz("mid", x, y) * 1.4 - 0.4, 0.0, 0.7))
		return p.vary(c.darkened(0.05 + t * 0.3), x, y, 0.12))
	for y: float in [0.18, 0.82]:  # 테 띠
		var a := tl.lerp(bl, y)
		var b := tr.lerp(br, y)
		Ink.line(p, a, b, 4.0 * u, K.IRON.darkened(0.3), 1.0, 0.2)
		Ink.line(p, a + Vector2(0, -1.4) * u, b + Vector2(0, -1.4) * u, 1.0 * u, Color("#b0aaa0"), 0.4, 0.2)
		for k in 7:
			K.nail(p, a.lerp(b, (k + 0.5) / 7.0), 1.2 * u)
	Ink.line(p, tl, tr, 1.6 * u, Color("#c0b8a8"), 0.45, 0.2)  # 테 위 빛
	Ink.grime(p, bl.x + 4 * u, tl.y + 12 * u, 46 * u, 18 * u, 0.35, Color("#3a2010"))
	Ink.path(p, PackedVector2Array([bl, tl, tl + dd, tr + dd, br + dd, br]), 1.8 * u, false, Ink.INK, 0.9, 0.4)
	Ink.path(p, front, 1.6 * u, true, Ink.INK, 0.9, 0.3)
	for e: float in [-19.0, 19.0]:  # 앞바퀴
		_wheel(p, Vector2(foot.x + e * u, foot.y - 5 * u), 8.0 * u, false)


static func _wheel(p: Paint, c: Vector2, r: float, back: bool) -> void:
	var col := K.IRON.darkened(0.5 if back else 0.2)
	p.fill_poly(Cave._ellipse(c, r, r, 20), func(x: int, y: int) -> Color: return p.vary(col, x, y, 0.1))
	Ink.path(p, Cave._ellipse(c, r, r, 20), 1.4, true, Ink.INK, 0.9, 0.2)
	Ink.path(p, Cave._ellipse(c, r * 0.55, r * 0.55, 16), 1.0, true, Ink.INK, 0.6, 0.2)
	Ink.line(p, c + Vector2(-r * 0.7, -r * 0.7), c + Vector2(-r * 0.2, -r * 0.95), 1.0, Color("#b8b0a4"), 0.4, 0.2)
	Cave._dot(p, c, r * 0.22, Color("#1a1614"), 0.9)


## 나무 통: 세로 널 + 쇠테 2줄 + 뚜껑 널 + 녹·때.
static func _barrel(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 26 * u, 8 * u)
	var r := 21 * u
	var hh := 48 * u
	Kit.cyl(p, foot, r, hh, K.WOOD, 2, K.IRON.darkened(0.2))
	var ry := r * Kit.DEPTH * 0.6
	for k in range(1, 7):  # 널 이음
		var a := PI * k / 7.0
		var x := foot.x - r * cos(a)
		var bulge := sin(a) * ry
		Ink.line(p, Vector2(x, foot.y - hh + bulge), Vector2(x, foot.y + bulge * 0.9), 0.9 * u, Ink.INK, 0.45, 0.4)
	for k in range(1, 4):  # 뚜껑 널
		var y := foot.y - hh - ry + 2.0 * ry * k / 4.0
		var half := r * sqrt(maxf(0.0, 1.0 - pow((y - (foot.y - hh)) / ry, 2.0)))
		Ink.line(p, Vector2(foot.x - half + 1, y), Vector2(foot.x + half - 1, y), 0.8 * u, Ink.INK, 0.5, 0.3)
	Ink.grime(p, foot.x + 2 * u, foot.y - 40 * u, 10 * u, 22 * u, 0.3, K.RUST.darkened(0.3))
	Ink.grime(p, foot.x - r * 0.8, foot.y - 18 * u, r * 1.6, 14 * u, 0.3)
	Cave._stone(p, foot + Vector2(22, 2) * u, 4 * u, 3 * u, K.ROCK)


## 나무 궤짝 두 개(큰 것 위에 작은 것): 가로 널 + 테 판 + 빗장 + 못 + 바랜 표식.
static func _crate(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 32 * u, 9 * u)
	var big := Kit.box(p, foot, 52 * u, 40 * u, 38 * u, K.WOOD)
	K.wood_box(p, big, K.WOOD, 3)
	_crate_frame(p, big["front"], u)
	var small_foot := foot + Vector2(-5, -38 - 8) * u
	var small := Kit.box(p, small_foot, 34 * u, 26 * u, 26 * u, K.WOOD_PALE.darkened(0.15))
	K.wood_box(p, small, K.WOOD_PALE.darkened(0.15), 2)
	_crate_frame(p, small["front"], u)
	var f: PackedVector2Array = big["front"]
	var c := (f[0] + f[2]) * 0.5
	Ink.path(p, Cave._ellipse(c, 7 * u, 7 * u, 16), 1.6 * u, true, Color("#c8bca0"), 0.3, 0.6)  # 바랜 표식
	Ink.line(p, c + Vector2(-5, 5) * u, c + Vector2(5, -5) * u, 1.6 * u, Color("#c8bca0"), 0.3, 0.6)


static func _crate_frame(p: Paint, front: PackedVector2Array, u: float) -> void:
	var r := Paint.bounds(front)
	var t := 4.0 * u
	for bar: Rect2 in [Rect2(r.position.x, r.position.y, t, r.size.y), Rect2(r.end.x - t, r.position.y, t, r.size.y)]:
		K.board(p, bar, K.WOOD.darkened(0.2), true, 0.0)
	K.beam(p, Vector2(r.position.x + t, r.end.y - 2 * u), Vector2(r.end.x - t, r.position.y + 2 * u), 3.5 * u, K.WOOD.darkened(0.15), false)
	for q: Vector2 in [r.position + Vector2(t * 0.5, 3 * u), Vector2(r.end.x - t * 0.5, r.position.y + 3 * u), Vector2(r.position.x + t * 0.5, r.end.y - 3 * u), r.end - Vector2(t * 0.5, 3 * u)]:
		K.nail(p, q, 1.0 * u)


## 랜턴 기둥: 네모 말뚝 + 가로 팔 + 까치발 + 사슬에 매단 광부 랜턴(따뜻한 불빛).
static func _lantern_post(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 18 * u, 6 * u)
	var post := Kit.box(p, foot + Vector2(-8, 0) * u, 9 * u, 8 * u, 124 * u, K.WOOD.darkened(0.05))
	K.wood(p, post["front"], K.WOOD.darkened(0.05), true, 0.0)
	Ink.path(p, post["front"], 1.3 * u, true, Ink.INK, 0.85, 0.3)
	var arm_a := foot + Vector2(-8, -118) * u
	var arm_b := foot + Vector2(22, -118) * u
	K.beam(p, arm_a, arm_b, 6 * u, K.WOOD)
	K.beam(p, foot + Vector2(-5, -96) * u, foot + Vector2(10, -116) * u, 4 * u, K.WOOD.darkened(0.1))
	var lamp := foot + Vector2(18, -90) * u
	for k in 4:  # 사슬
		var q := arm_b + Vector2(-4, 5 + k * 4.5) * u
		Ink.path(p, Cave._ellipse(q, (1.4 if k % 2 == 0 else 0.6) * u, 2.4 * u, 10), 1.0 * u, true, K.IRON.lightened(0.2), 0.9, 0.1)
	K.halo(p, lamp, 50 * u, K.LAMP, 0.45)
	_lamp(p, lamp, u)
	for k in 3:
		Cave._stone(p, foot + Vector2(p.rng.randf_range(-20, 8), p.rng.randf_range(-2, 4)) * u, p.rng.randf_range(3.5, 5.5) * u, 3 * u, K.ROCK)


## 광부 랜턴 한 개(중심 c = 유리 가운데): 쇠 뚜껑·받침 + 창살 + 불꽃.
static func _lamp(p: Paint, c: Vector2, u: float) -> void:
	var glass := PackedVector2Array([c + Vector2(-6, -8) * u, c + Vector2(6, -8) * u, c + Vector2(7, 7) * u, c + Vector2(-7, 7) * u])
	p.fill_poly(glass, func(x: int, y: int) -> Color:
		var d := Vector2(x - c.x, (y - c.y) * 0.8).length() / (9.0 * u)
		return Color("#fff0c0").lerp(Color("#d06a28"), clampf(d, 0.0, 1.0)))
	Kit.flame(p, c + Vector2(0, 3) * u, 4.5 * u)
	for e: float in [-3.0, 3.0]:
		Ink.line(p, c + Vector2(e, -8) * u, c + Vector2(e * 1.15, 7) * u, 1.0 * u, Ink.INK, 0.8, 0.1)
	var cap := PackedVector2Array([c + Vector2(-8, -8) * u, c + Vector2(-3, -14) * u, c + Vector2(3, -14) * u, c + Vector2(8, -8) * u])
	p.fill_poly(cap, func(x: int, y: int) -> Color: return p.vary(K.IRON.lerp(K.RUST, 0.3), x, y, 0.1))
	Ink.path(p, cap, 1.2 * u, true, Ink.INK, 0.9, 0.2)
	var bot := Paint.rect_poly(c.x - 8 * u, c.y + 7 * u, 16 * u, 4 * u)
	p.fill_poly(bot, func(x: int, y: int) -> Color: return p.vary(K.IRON.darkened(0.2), x, y, 0.1))
	Ink.path(p, bot, 1.2 * u, true, Ink.INK, 0.9, 0.2)
	Ink.path(p, glass, 1.2 * u, true, Ink.INK, 0.85, 0.2)
	Ink.path(p, Cave._ellipse(c + Vector2(0, -16) * u, 3 * u, 2.4 * u, 10), 1.1 * u, true, K.IRON, 0.9, 0.1)


## 비계(줄로 이어짐): 칸 가장자리(발 ± 32)에 앞 기둥, 뒤 기둥은 깊이만큼 위·오른쪽. 가로대 3단 + 위 발판 + 아래 칸 X자 빗장.
static func _scaffold(p: Paint, foot: Vector2, u: float) -> void:
	var dd := Vector2(6, -14) * u
	var col := K.WOOD.darkened(0.05)
	Kit.shadow(p, foot + Vector2(0, -6) * u, 40 * u, 9 * u, 0.35)
	var hts := [52.0, 104.0, 148.0]
	for e: float in [-32.0, 32.0]:  # 뒤 기둥
		K.beam(p, foot + Vector2(e, 0) * u + dd, foot + Vector2(e, -150) * u + dd, 6 * u, col.darkened(0.35), false)
	for y: float in hts:  # 뒤 가로대
		K.beam(p, foot + Vector2(-36, -y) * u + dd, foot + Vector2(36, -y) * u + dd, 4.5 * u, col.darkened(0.35), false)
	# 위 발판(널판 — 위에서 보임)
	var top := foot + Vector2(0, -148) * u
	var deck := PackedVector2Array([top + Vector2(-36, 0) * u, top + Vector2(36, 0) * u, top + Vector2(36, 0) * u + dd, top + Vector2(-36, 0) * u + dd])
	K.wood(p, deck, col.lightened(0.1), true, 0.0)
	for k in range(1, 9):
		var x := -36.0 + 72.0 * k / 9.0
		Ink.line(p, top + Vector2(x, 0) * u, top + Vector2(x, 0) * u + dd, 0.8 * u, Ink.INK, 0.5, 0.2)
	var deck_front := Paint.rect_poly(top.x - 36 * u, top.y, 72 * u, 4 * u)
	K.wood(p, deck_front, col.darkened(0.2), false, 0.0)
	Ink.path(p, deck_front, 1.1 * u, true, Ink.INK, 0.8, 0.2)
	# 아래 칸 X자 빗장
	K.beam(p, foot + Vector2(-30, -4) * u, foot + Vector2(30, -50) * u, 4 * u, col.darkened(0.1))
	K.beam(p, foot + Vector2(30, -4) * u, foot + Vector2(-30, -50) * u, 4 * u, col.darkened(0.15))
	K.beam(p, foot + Vector2(-30, -56) * u, foot + Vector2(30, -100) * u, 4 * u, col.darkened(0.1))
	for y: float in hts:  # 앞 가로대(칸 끝까지)
		K.beam(p, foot + Vector2(-36, -y) * u, foot + Vector2(36, -y) * u, 5.5 * u, col)
	for e: float in [-32.0, 32.0]:  # 앞 기둥(이웃 칸과 같은 자리 — 겹쳐 하나)
		K.beam(p, foot + Vector2(e, 2) * u, foot + Vector2(e, -152) * u, 7 * u, col)
		for y: float in hts:
			Ink.line(p, foot + Vector2(e - 3.5, -y + 1) * u, foot + Vector2(e + 3.5, -y + 3) * u, 1.6 * u, Color("#8a7a5a"), 0.9, 0.2)  # 묶은 밧줄
	Ink.line(p, foot + Vector2(10, -104) * u, foot + Vector2(12, -70) * u, 1.6 * u, Color("#7a6a4a"), 0.85, 0.6)  # 늘어진 밧줄


## 붉은 갈색 동굴 버섯 무리(은은한 빛): 큰 것 뒤, 작은 것 앞.
static func _mushrooms(p: Paint, foot: Vector2, u: float) -> void:
	Kit.shadow(p, foot, 30 * u, 8 * u)
	K.halo(p, foot + Vector2(0, -30) * u, 46 * u, Color("#ff9a78"), 0.14)
	var list := [[Vector2(-6, -4), 21.0, 44.0], [Vector2(16, -1), 14.0, 28.0], [Vector2(-22, 2), 11.0, 20.0], [Vector2(6, 4), 8.0, 13.0], [Vector2(24, 5), 6.0, 9.0]]
	for e: Array in list:
		var base := foot + (e[0] as Vector2) * u
		_mushroom(p, base, float(e[1]) * u, float(e[2]) * u)


static func _mushroom(p: Paint, base: Vector2, r: float, hh: float) -> void:
	var u := p.w / 128.0
	var top := base + Vector2(r * 0.08, -hh)
	var stem := PackedVector2Array([base + Vector2(-r * 0.3, 0), top + Vector2(-r * 0.2, 0), top + Vector2(r * 0.2, 0), base + Vector2(r * 0.32, 0)])
	p.fill_poly(stem, func(x: int, y: int) -> Color:
		var t := clampf((x - (base.x - r * 0.3)) / (r * 0.62), 0.0, 1.0)
		return p.vary(Color("#d8c8b0").darkened(0.1 + t * 0.35), x, y, 0.06))
	Ink.path(p, stem, 1.0 * u, true, Ink.INK, 0.7, 0.3)
	var ry := r * 0.42
	var under := Cave._ellipse(top + Vector2(0, ry * 0.25), r * 0.95, ry * 0.75, 24)
	p.fill_poly(under, func(x: int, y: int) -> Color:
		var g := 0.5 + 0.5 * sin((x - top.x) * 1.6 / u)
		return Color("#e0c8a8").darkened(0.15 + g * 0.2))  # 주름
	var cap := PackedVector2Array()
	for k in 25:
		var a := PI + PI * k / 24.0
		cap.append(top + Vector2(cos(a) * r, sin(a) * ry * 1.6))
	for k in range(1, 12):
		var a := PI * k / 12.0
		cap.append(top + Vector2(cos(a) * r, sin(a) * ry * 0.35))
	p.fill_poly(cap, func(x: int, y: int) -> Color:
		var d := Vector2((x - top.x) / r, (y - (top.y - ry)) / (ry * 1.6))
		var t := clampf(0.7 - d.x * 0.35 - d.y * 0.6, 0.0, 1.0)
		return p.vary(Color("#5a2a22").lerp(Color("#c88a6e"), t), x, y, 0.08))
	for k in int(r / (8.0 * u)):  # 옅은 점
		var q := top + Vector2(p.rng.randf_range(-0.7, 0.6) * r, -p.rng.randf_range(0.3, 1.2) * ry)
		Cave._dot(p, q, p.rng.randf_range(0.8, 1.4) * u, Color("#c89a80"), 0.4)
	Ink.line(p, top + Vector2(-r * 0.7, -ry * 1.1), top + Vector2(-r * 0.2, -ry * 1.5), 1.2 * u, Color("#f0d0b8"), 0.45, 0.4)
	Ink.path(p, cap, 1.3 * u, true, Color("#1e0e0a"), 0.85, 0.3)
	Ink.glow(p, top.x, top.y, r * 1.2, Color("#ffb090"), 0.12, true)
