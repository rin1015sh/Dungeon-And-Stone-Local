extends RefCounted
## 핏빛성채 서 있는 소품 0~15(bf.gd가 부른다): 말뚝 울타리·창살·연회 탁자·무기 걸이·갑옷 받침·통·궤짝·부서진 수레·천막·
## 가시 방책·화로·교수대·우물·좌판·철의 처녀·석상. 줄로 늘어서는 것은 좌우 끝이 칸 가장자리(발 ± w/4)에 닿는다.
## 발 = (w/2, h - w·0.14). 빛은 왼쪽 위 — 왼쪽 면 밝게, 오른쪽 아래 어둡게, 잉크 윤곽.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const K := preload("res://tools/floor_art/rift/bf_kit.gd")


static func paint(p: Paint, tile: String) -> bool:
	var u := p.w / 128.0
	var f := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	var l := f.x - 32.0 * u  # 칸 왼쪽 끝
	match tile:
		"bf_palisade":
			Kit.shadow(p, f + Vector2(0, 1), 38 * u, 7 * u, 0.4)
			var n := 6
			var sw := 64.0 * u / n
			for k in n:
				var cx := l + sw * (k + 0.5)
				var hgt := (70.0 + Paint.hash01(k, 1, 5) * 22.0) * u
				var b := f + Vector2(cx - f.x, (k % 2) * 1.5 * u)
				var col := K.WOOD.lerp(Color("#5a4630"), Paint.hash01(k, 2, 5))
				Kit.post(p, b, b + Vector2(0, -hgt + 10 * u), sw + 0.6, col)
				Kit.cone(p, b + Vector2(0, -hgt + 10 * u), sw * 0.5, 14 * u, col, (Paint.hash01(k, 3, 5) - 0.5) * 0.15)
				for g in 3:  # 나무껍질 결
					var gx := cx + (g - 1) * 2.5 * u
					Ink.line(p, Vector2(gx, b.y - 6 * u - g * 7 * u), Vector2(gx + 0.5, b.y - hgt * 0.6), 0.6 * u, K.WOOD_DARK, 0.45, 0.6)
			for ry: float in [22.0, 54.0]:  # 묶은 밧줄
				var y := f.y - ry * u
				Ink.line(p, Vector2(l, y), Vector2(l + 64 * u, y + 1), 3.4 * u, K.INK, 0.9, 0.4)
				Ink.line(p, Vector2(l, y - 0.5), Vector2(l + 64 * u, y + 0.5), 2.2 * u, Color("#8a7450"), 1.0, 0.4)
				for k in 6:
					var x := l + (k + 0.5) * 64.0 * u / 6.0
					Ink.line(p, Vector2(x - 2 * u, y - 2 * u), Vector2(x + 2 * u, y + 2 * u), 1.0 * u, K.INK, 0.6, 0.2)
		"bf_bars":
			Kit.shadow(p, f + Vector2(0, 1), 36 * u, 5 * u, 0.35)
			var top := f.y - 92.0 * u
			for k in 8:
				var x := l + (k + 0.5) * 8.0 * u
				Kit.post(p, Vector2(x, f.y), Vector2(x, top), 3.4 * u, K.IRON.lerp(K.RUST, Paint.hash01(k, 1, 7) * 0.6))
			for y: float in [top, f.y - 46.0 * u, f.y - 4.0 * u]:
				var rail := Paint.rect_poly(l, y - 3.0 * u, 64.0 * u, 6.0 * u)
				p.fill_poly(rail, func(x: int, yy: int) -> Color: return p.vary(K.IRON.lightened(0.15 if yy < y else -0.1), x, yy, 0.1))
				Ink.line(p, Vector2(l, y - 3.0 * u), Vector2(l + 64 * u, y - 3.0 * u), 0.9 * u, K.LIT, 0.35, 0.2)
				Ink.line(p, Vector2(l, y + 3.0 * u), Vector2(l + 64 * u, y + 3.0 * u), 1.3 * u, K.INK, 0.85, 0.2)
				for k in 8:
					Cave._dot(p, Vector2(l + (k + 0.5) * 8.0 * u, y), 1.4 * u, Color("#8a8890"), 0.9)
			Decals._blob(p, f + Vector2(10, -30) * u, 6 * u, K.RUST, 0.35, 0.4)
		"bf_table":
			_table(p, f, l, u)
		"bf_rack":
			_rack(p, f, u)
		"bf_armor":
			_armor(p, f, u)
		"bf_barrel":
			Kit.shadow(p, f, 24 * u, 8 * u)
			Kit.cyl(p, f, 19 * u, 42 * u, Color("#6a4a2e"), 3, Color("#2e2a28"))
			for k in 5:  # 통 널
				var x := f.x + (-14.0 + k * 7.0) * u
				Ink.line(p, Vector2(x, f.y - 40 * u), Vector2(x, f.y + 1 * u), 0.7 * u, K.WOOD_DARK, 0.5, 0.3)
			for k in 3:  # 뚜껑 판자
				Ink.line(p, f + Vector2(-17 + k * 11, -42 - 3) * u, f + Vector2(-13 + k * 11, -42 + 4) * u, 0.7 * u, K.WOOD_DARK, 0.5, 0.3)
			K.stain(p, f + Vector2(8, -6) * u, 4 * u, 0.4)
		"bf_crate":
			Kit.shadow(p, f, 28 * u, 9 * u)
			var bx := Kit.box(p, f, 44 * u, 40 * u, 34 * u, Color("#7a5a36"))
			Kit.planks(p, bx["front"], 4, Color("#7a5a36"))
			var fr: PackedVector2Array = bx["front"]
			Ink.line(p, fr[3] + Vector2(2, -2) * u, fr[1] + Vector2(-2, 2) * u, 3.0 * u, Color("#4a3420"), 0.95, 0.3)
			Ink.line(p, fr[3] + Vector2(2, -2) * u, fr[1] + Vector2(-2, 2) * u, 1.0 * u, K.INK, 0.6, 0.3)
			for q: Vector2 in [fr[0], fr[1], fr[2], fr[3]]:
				Cave._dot(p, q + (f + Vector2(0, -17 * u) - q).normalized() * 3.0 * u, 1.0 * u, Color("#9a9aa0"), 0.9)
			Kit.box(p, f + Vector2(-4, -34) * u + Vector2(4, -4) * u, 22 * u, 20 * u, 14 * u, Color("#6a4c2e"))
		"bf_wagon":
			_wagon(p, f, u)
		"bf_tent":
			_tent(p, f, u)
		"bf_barricade":
			Kit.shadow(p, f + Vector2(0, 1), 36 * u, 8 * u, 0.4)
			for k in 3:  # 엇갈린 말뚝(뒤쪽)
				var x := l + (k + 0.5) * 64.0 * u / 3.0
				_sharp(p, Vector2(x + 12 * u, f.y), Vector2(x - 12 * u, f.y - 48 * u), 4.4 * u, K.WOOD.darkened(0.15))
			var y := f.y - 18.0 * u  # 가로 통나무
			var log := Paint.rect_poly(l, y - 6.0 * u, 64.0 * u, 12.0 * u)
			p.fill_poly(log, func(x: int, yy: int) -> Color:
				var t := (yy - (y - 6.0 * u)) / (12.0 * u)
				return p.vary(Color("#5a4230").lightened(0.2 - t * 0.5), x, yy, 0.1))
			Ink.line(p, Vector2(l, y - 6 * u), Vector2(l + 64 * u, y - 6 * u), 1.2 * u, K.INK, 0.8, 0.5)
			Ink.line(p, Vector2(l, y + 6 * u), Vector2(l + 64 * u, y + 6 * u), 1.5 * u, K.INK, 0.9, 0.5)
			for k in 3:
				Ink.line(p, Vector2(l + (k * 21 + 4) * u, y - 2 * u), Vector2(l + (k * 21 + 16) * u, y - 1 * u), 0.7 * u, K.WOOD_DARK, 0.5, 0.6)
			for k in 3:  # 엇갈린 말뚝(앞쪽)
				var x := l + (k + 0.5) * 64.0 * u / 3.0
				_sharp(p, Vector2(x - 12 * u, f.y + 2 * u), Vector2(x + 13 * u, f.y - 46 * u), 4.8 * u, K.WOOD)
		"bf_brazier":
			Kit.shadow(p, f, 20 * u, 7 * u)
			var bowl := f + Vector2(0, -36 * u)
			for dx: float in [-14.0, 0.0, 14.0]:
				Kit.post(p, bowl + Vector2(dx * 0.6, 4) * u, f + Vector2(dx, -1 + (4 if dx == 0.0 else 0)) * u, 2.6 * u, K.IRON)
			Kit.cyl(p, bowl + Vector2(0, 8 * u), 18 * u, 10 * u, Color("#3a3634"), 1, Color("#1a1818"))
			p.fill_poly(Cave._ellipse(bowl + Vector2(0, -2 * u), 16 * u, 5.5 * u, 20), func(x: int, y: int) -> Color:
				return Color("#5a1408").lerp(Color("#ff8a2a"), clampf(p.nz("mid", x, y) * 1.4 - 0.3, 0.0, 1.0)))
			for k in 7:
				Cave._dot(p, bowl + Vector2(p.rng.randf_range(-12, 12), p.rng.randf_range(-4, 2)) * u, 1.6 * u, Color("#ffc060"), 0.9)
			Kit.flame(p, bowl + Vector2(-3, -2) * u, 13 * u)
			Kit.flame(p, bowl + Vector2(6, -1) * u, 8 * u)
			K.halo(p, bowl + Vector2(0, -12 * u), 46 * u, Color("#ff7a2a"), 0.35)
		"bf_gallows":
			_gallows(p, f, u)
		"bf_well":
			_well(p, f, u)
		"bf_stall":
			_stall(p, f, u)
		"bf_torture":
			_maiden(p, f, u)
		"bf_statue":
			_statue(p, f, u, Color("#7a7470"), false)
		_:
			return false
	return true


## 끝을 깎은 말뚝(a = 밑, b = 끝).
static func _sharp(p: Paint, a: Vector2, b: Vector2, wd: float, col: Color) -> void:
	var d := (b - a).normalized()
	Kit.post(p, a, b - d * wd * 2.2, wd, col)
	var n := Vector2(-d.y, d.x) * wd * 0.5
	var base := b - d * wd * 2.2
	var tip := PackedVector2Array([base + n, b, base - n])
	p.fill_poly(tip, func(x: int, y: int) -> Color: return p.vary(Color("#9a8060"), x, y, 0.08))
	Ink.path(p, tip, 1.0 * p.w / 128.0, false, K.INK, 0.8, 0.2)


## 연회 탁자(줄 — 좌우 끝이 칸 가장자리): 상판 + 앞 테 + 다리, 얼룩진 식탁보, 썩은 음식·잔·촛농.
static func _table(p: Paint, f: Vector2, l: float, u: float) -> void:
	var r := l + 64.0 * u
	var ty := f.y - 30.0 * u  # 상판 앞 모서리
	var dd := 24.0 * u
	Kit.shadow(p, f + Vector2(0, -6 * u), 38 * u, 10 * u, 0.45)
	for x: float in [l + 10 * u, r - 10 * u]:  # 다리(X자 받침)
		Kit.post(p, Vector2(x - 6 * u, f.y), Vector2(x + 6 * u, ty + 2 * u), 4.0 * u, K.WOOD.darkened(0.2))
		Kit.post(p, Vector2(x + 6 * u, f.y), Vector2(x - 6 * u, ty + 2 * u), 4.0 * u, K.WOOD.darkened(0.1))
	var top := PackedVector2Array([Vector2(l, ty - dd), Vector2(r, ty - dd), Vector2(r, ty), Vector2(l, ty)])
	p.fill_poly(top, func(x: int, y: int) -> Color:
		var g := sin(y * 1.1 + p.nz("mid", x, y) * 6.0) * 0.5 + 0.5
		return p.vary(Color("#5a4028").lightened(g * 0.1), x, y, 0.1))
	for k in 3:  # 판자 이음
		var y := ty - dd + (k + 1) * dd / 4.0
		Ink.line(p, Vector2(l, y), Vector2(r, y), 0.7 * u, K.WOOD_DARK, 0.6, 0.3)
	var apron := PackedVector2Array([Vector2(l, ty), Vector2(r, ty), Vector2(r, ty + 6 * u), Vector2(l, ty + 6 * u)])
	p.fill_poly(apron, func(x: int, y: int) -> Color: return p.vary(K.WOOD.darkened(0.25), x, y, 0.1))
	# 식탁보(가운데 줄 — 앞으로 늘어져 들쭉날쭉)
	var cloth := PackedVector2Array([Vector2(l, ty - dd * 0.75), Vector2(r, ty - dd * 0.75), Vector2(r, ty + 10 * u)])
	for k in 9:
		var x := r - k * 8.0 * u
		cloth.append(Vector2(x - 4 * u, ty + (8.0 + Paint.hash01(k, 4, 2) * 8.0) * u))
	cloth.append(Vector2(l, ty + 9 * u))
	p.fill_poly(cloth, func(x: int, y: int) -> Color:
		var c := Color("#8a7c68").darkened(0.25 if y > ty else 0.0)
		return p.vary(c, x, y, 0.14))
	Ink.path(p, cloth, 1.0 * u, true, K.INK, 0.7, 0.6)
	Ink.line(p, Vector2(l, ty), Vector2(r, ty), 1.0 * u, K.INK, 0.5, 0.3)
	Decals._blob(p, Vector2(f.x + 10 * u, ty - 8 * u), 7 * u, Color("#4a0a0c"), 0.6, 0.4)  # 포도주 얼룩
	Decals._blob(p, Vector2(f.x - 18 * u, ty + 6 * u), 4 * u, Color("#4a0a0c"), 0.5, 0.4)
	Ink.path(p, PackedVector2Array([Vector2(l, ty - dd), Vector2(r, ty - dd)]), 1.0 * u, false, K.INK, 0.6, 0.3)
	Ink.line(p, Vector2(l, ty + 6 * u), Vector2(r, ty + 6 * u), 1.3 * u, K.INK, 0.85, 0.3)
	# 접시·썩은 음식·잔·초
	var plate := Vector2(f.x - 14 * u, ty - 12 * u)
	p.fill_poly(Cave._ellipse(plate, 8 * u, 3.6 * u, 18), func(x: int, y: int) -> Color: return p.vary(Color("#8a8478"), x, y, 0.1))
	Ink.path(p, Cave._ellipse(plate, 8 * u, 3.6 * u, 18), 0.9 * u, true, K.INK, 0.7, 0.2)
	Cave._stone(p, plate + Vector2(0, -1.5) * u, 5 * u, 2.4 * u, Color("#4a4a2a"))  # 썩은 고기
	K.bone(p, plate + Vector2(-2, -2) * u, plate + Vector2(6, -4) * u, 0.7 * u)
	var gob := Vector2(f.x + 4 * u, ty - 6 * u)
	Kit.cyl(p, gob, 2.2 * u, 7 * u, K.GOLD, 0)
	Kit.post(p, gob + Vector2(0, 3) * u, gob, 1.4 * u, K.GOLD.darkened(0.2))
	p.fill_poly(Cave._ellipse(Vector2(f.x + 22 * u, ty - 9 * u), 3 * u, 4.5 * u, 12), func(x: int, y: int) -> Color: return p.vary(Color("#4a5a30"), x, y, 0.15))  # 곰팡이 빵
	var cd := Vector2(f.x - 26 * u, ty - 14 * u)
	Kit.cyl(p, cd, 2.2 * u, 8 * u, Color("#c8bca0"), 0)
	Kit.flame(p, cd + Vector2(0, -9 * u), 3.5 * u)
	K.halo(p, cd + Vector2(0, -11 * u), 14 * u, Color("#ffa040"), 0.3)


## 무기 걸이: 두 기둥 + 가로대, 기대 세운 창·검·도끼.
static func _rack(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 30 * u, 8 * u)
	for x: float in [-24.0, 24.0]:
		Kit.post(p, f + Vector2(x, 0) * u, f + Vector2(x, -64) * u, 5.0 * u, K.WOOD)
		Kit.post(p, f + Vector2(x - 6, 0) * u, f + Vector2(x + 6, 0) * u, 3.0 * u, K.WOOD.darkened(0.2))
	for y: float in [-58.0, -16.0]:
		Kit.post(p, f + Vector2(-27, y) * u, f + Vector2(27, y) * u, 4.0 * u, K.WOOD.lightened(0.05))
	var steel := Color("#8a8c94")
	for k in 3:  # 창
		var b := f + Vector2(-16 + k * 9, -2) * u
		var t := b + Vector2(-4 + k * 1.5, -96 - k * 4) * u
		Kit.post(p, b, t, 2.2 * u, Color("#5a4632"))
		var d := (t - b).normalized()
		var n := Vector2(-d.y, d.x)
		var blade := PackedVector2Array([t - n * 2.6 * u, t + d * 13 * u, t + n * 2.6 * u])
		p.fill_poly(blade, func(x: int, y: int) -> Color: return p.vary(steel, x, y, 0.1))
		Ink.path(p, blade, 1.0 * u, true, K.INK, 0.8, 0.2)
	for k in 2:  # 검(칼끝이 아래)
		var b := f + Vector2(6 + k * 9, -4) * u
		var t := b + Vector2(-3, -50) * u
		var bl := PackedVector2Array([b, t + Vector2(-2.6, 0) * u, t + Vector2(2.6, 0) * u])
		p.fill_poly(bl, func(x: int, y: int) -> Color: return p.vary(steel.lightened(0.1 if x < b.x else -0.15), x, y, 0.08))
		Ink.path(p, bl, 1.0 * u, true, K.INK, 0.8, 0.2)
		Kit.post(p, t + Vector2(-6, 0) * u, t + Vector2(6, 0) * u, 2.4 * u, K.GOLD.darkened(0.3))
		Kit.post(p, t, t + Vector2(0, -10) * u, 2.4 * u, Color("#3a2a20"))
		Cave._dot(p, t + Vector2(0, -11) * u, 2.0 * u, K.GOLD, 0.95)
	var ah := f + Vector2(22, -6) * u  # 도끼
	Kit.post(p, ah, ah + Vector2(4, -56) * u, 2.6 * u, Color("#5a4632"))
	var head := PackedVector2Array([ah + Vector2(4, -50) * u, ah + Vector2(14, -58) * u, ah + Vector2(16, -44) * u, ah + Vector2(4, -42) * u])
	p.fill_poly(head, func(x: int, y: int) -> Color: return p.vary(steel.darkened(0.15), x, y, 0.1))
	Ink.path(p, head, 1.1 * u, true, K.INK, 0.85, 0.3)


## 갑옷 받침: 십자 받침 나무 + 찌그러진 판금(투구·어깨·가슴판·허리 판).
static func _armor(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 22 * u, 7 * u)
	Kit.post(p, f + Vector2(-14, 0) * u, f + Vector2(14, 0) * u, 3.4 * u, K.WOOD.darkened(0.2))
	Kit.post(p, f, f + Vector2(0, -98) * u, 4.0 * u, K.WOOD)
	var m := Color("#7a7c84")
	var sh := f + Vector2(0, -78) * u
	for sx: float in [-1.0, 1.0]:  # 어깨 판
		Cave._stone(p, sh + Vector2(sx * 15, 2) * u, 8 * u, 6 * u, m.darkened(0.1 if sx > 0 else -0.05))
	var chest := PackedVector2Array([sh + Vector2(-13, -3) * u, sh + Vector2(13, -3) * u, sh + Vector2(11, 26) * u, sh + Vector2(0, 30) * u, sh + Vector2(-11, 26) * u])
	p.fill_poly(chest, func(x: int, y: int) -> Color:
		var t := (x - sh.x) / (13.0 * u)
		return p.vary(m.lightened(0.25 - t * 0.35 - absf(t) * 0.1), x, y, 0.06))
	Ink.path(p, chest, 1.4 * u, true, K.INK, 0.9, 0.3)
	Ink.line(p, sh + Vector2(0, -2) * u, sh + Vector2(0, 28) * u, 0.9 * u, K.INK, 0.4, 0.3)
	Ink.line(p, sh + Vector2(-9, 0) * u, sh + Vector2(-5, 14) * u, 1.0 * u, Color("#e0e0e8"), 0.45, 0.4)
	Cave._pit(p, sh + Vector2(6, 12) * u, 3.2 * u)  # 찌그러진 자국
	Ink.line(p, sh + Vector2(2, 18) * u, sh + Vector2(9, 22) * u, 0.8 * u, K.INK, 0.6, 0.4)
	for k in 3:  # 허리 판
		var y := 31.0 + k * 6.0
		var band := PackedVector2Array([sh + Vector2(-12 - k, y) * u, sh + Vector2(12 + k, y) * u, sh + Vector2(12 + k, y + 6) * u, sh + Vector2(-12 - k, y + 6) * u])
		p.fill_poly(band, func(x: int, yy: int) -> Color: return p.vary(m.darkened(0.1 + k * 0.05).lightened(0.2 if x < sh.x - 4 * u else 0.0), x, yy, 0.06))
		Ink.path(p, band, 1.0 * u, true, K.INK, 0.8, 0.2)
	var hm := sh + Vector2(0, -14) * u  # 통 투구
	var helm := PackedVector2Array([hm + Vector2(-8, 8) * u, hm + Vector2(-8, -6) * u, hm + Vector2(-5, -11) * u, hm + Vector2(5, -11) * u, hm + Vector2(8, -6) * u, hm + Vector2(8, 8) * u])
	p.fill_poly(helm, func(x: int, y: int) -> Color: return p.vary(m.lightened(0.15 - (x - hm.x) / (8.0 * u) * 0.3), x, y, 0.06))
	Ink.path(p, helm, 1.3 * u, true, K.INK, 0.9, 0.2)
	Ink.line(p, hm + Vector2(-7, -2) * u, hm + Vector2(7, -2) * u, 1.6 * u, K.INK, 0.95, 0.1)  # 눈 틈
	for k in 3:
		Cave._dot(p, hm + Vector2(-3 + k * 3, 3) * u, 0.7 * u, K.INK, 0.9)
	K.stain(p, sh + Vector2(-4, 22) * u, 3 * u, 0.5)


## 부서진 수레: 기울어진 짐칸 + 바퀴 하나(살), 빠진 바퀴는 바닥에, 끌채는 땅에.
static func _wagon(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f + Vector2(0, -4) * u, 42 * u, 12 * u, 0.45)
	_wheel(p, f + Vector2(16, -6) * u, 13 * u, 7 * u, u, true)  # 빠져 누운 바퀴
	Kit.post(p, f + Vector2(14, -18) * u, f + Vector2(44, -6) * u, 3.0 * u, K.WOOD.darkened(0.1))  # 끌채
	Kit.post(p, f + Vector2(12, -26) * u, f + Vector2(44, -14) * u, 3.0 * u, K.WOOD)
	var bed := PackedVector2Array([f + Vector2(-38, -30) * u, f + Vector2(14, -22) * u, f + Vector2(14, -6) * u, f + Vector2(-38, -10) * u])
	var bed_top := PackedVector2Array([f + Vector2(-38, -30) * u, f + Vector2(14, -22) * u, f + Vector2(18, -38) * u, f + Vector2(-32, -46) * u])
	p.fill_poly(bed_top, func(x: int, y: int) -> Color: return p.vary(Color("#3a2a1c"), x, y, 0.1))  # 짐칸 안(어둠)
	for k in 3:
		Ink.line(p, f + Vector2(-36 + k * 2, -34 - k * 4) * u, f + Vector2(15 + k, -26 - k * 4) * u, 0.7 * u, K.INK, 0.5, 0.3)
	p.fill_poly(bed, func(x: int, y: int) -> Color: return p.vary(Color("#6e5032"), x, y, 0.1))
	Kit.planks(p, bed, 3, Color("#6e5032"))
	Ink.path(p, bed, 1.4 * u, true, K.INK, 0.9, 0.3)
	Ink.path(p, PackedVector2Array([bed_top[0], bed_top[3], bed_top[2], bed_top[1]]), 1.2 * u, false, K.INK, 0.85, 0.3)
	Ink.line(p, f + Vector2(-8, -27) * u, f + Vector2(-4, -8) * u, 1.6 * u, K.INK, 0.9, 1.2)  # 쪼개진 판
	_wheel(p, f + Vector2(-26, -14) * u, 15 * u, 15 * u, u, false)
	Cave._stone(p, f + Vector2(-14, -40) * u, 6 * u, 4 * u, Color("#7a6a50"))  # 짐 자루


## 수레바퀴(테 + 살 + 바퀴통). flat = 바닥에 누운 것(납작한 타원).
static func _wheel(p: Paint, c: Vector2, rx: float, ry: float, u: float, flat: bool) -> void:
	var rim := Cave._ellipse(c, rx, ry, 28)
	Ink.path(p, rim, 4.4 * u, true, K.INK, 0.9, 0.2)
	Ink.path(p, rim, 3.0 * u, true, Color("#5a4028"), 1.0, 0.2)
	var n := 8 if not flat else 6
	for k in n:
		var a := TAU * k / n + 0.2
		if flat and k == 2:
			continue  # 부러진 살
		Ink.line(p, c, c + Vector2(cos(a) * rx, sin(a) * ry) * 0.92, 2.0 * u, Color("#4a3422"), 0.95, 0.2)
	Cave._stone(p, c, 3.2 * u, 3.2 * u * ry / rx, Color("#4a4440"))


## 군용 천막: 앞 삼각면 + 지붕 두 비탈 + 어두운 입구·젖힌 자락, 기둥 끝 · 버팀줄 · 말뚝.
static func _tent(p: Paint, f: Vector2, u: float) -> void:
	var canvas := Color("#6e604e")
	var a := f + Vector2(0, -62) * u
	var dd := 24.0 * u
	var b := a + Vector2(0, -dd)
	var bl := f + Vector2(-34, 0) * u
	var br := f + Vector2(34, 0) * u
	Kit.shadow(p, f + Vector2(0, -8 * u), 42 * u, 14 * u, 0.45)
	var left := PackedVector2Array([a, b, bl + Vector2(0, -dd), bl])
	var right := PackedVector2Array([a, b, br + Vector2(0, -dd), br])
	p.fill_poly(right, func(x: int, y: int) -> Color: return p.vary(canvas.darkened(0.35), x, y, 0.12))
	p.fill_poly(left, func(x: int, y: int) -> Color: return p.vary(canvas.lightened(0.1), x, y, 0.12))
	Ink.path(p, PackedVector2Array([bl, bl + Vector2(0, -dd), b, br + Vector2(0, -dd), br]), 1.3 * u, false, K.INK, 0.85, 0.5)
	var front := PackedVector2Array([bl, a, br])
	p.fill_poly(front, func(x: int, y: int) -> Color: return p.vary(canvas.darkened(0.12), x, y, 0.12))
	for k in 3:  # 천 주름
		Ink.line(p, a + Vector2(-2 - k * 4, 6) * u, bl + Vector2(10 + k * 8, -2) * u, 0.7 * u, K.INK, 0.35, 0.8)
	var door := PackedVector2Array([f + Vector2(-12, 0) * u, a + Vector2(0, 14) * u, f + Vector2(12, 0) * u])
	p.fill_poly(door, func(_x: int, _y: int) -> Color: return Color("#120c0a"))
	var flap := PackedVector2Array([a + Vector2(0, 14) * u, f + Vector2(12, 0) * u, f + Vector2(22, -2) * u])
	p.fill_poly(flap, func(x: int, y: int) -> Color: return p.vary(canvas.lightened(0.05), x, y, 0.12))
	Ink.path(p, flap, 1.0 * u, true, K.INK, 0.8, 0.4)
	Ink.path(p, front, 1.5 * u, true, K.INK, 0.9, 0.4)
	p.fill_poly(Cave._ellipse(f + Vector2(-20, -24) * u, 4 * u, 3 * u, 10), func(x: int, y: int) -> Color: return p.vary(Color("#5a4a3a"), x, y, 0.1))  # 기운 조각
	Kit.post(p, a + Vector2(0, 2 * u), a + Vector2(0, -9 * u), 2.4 * u, K.WOOD)
	for e: Vector2 in [f + Vector2(-46, -6) * u, f + Vector2(46, -4) * u]:  # 버팀줄 + 말뚝
		Ink.line(p, a + Vector2(0, -6 * u), e, 0.8 * u, Color("#8a7a5a"), 0.8, 0.3)
		Kit.post(p, e + Vector2(0, 2 * u), e + Vector2(0, -4 * u), 2.0 * u, K.WOOD)


## 교수대: 기둥 + 가로대 + 버팀대, 매듭 진 올가미, 넘어진 의자.
static func _gallows(p: Paint, f: Vector2, u: float) -> void:
	var px := f.x - 20.0 * u
	var top := f.y - 152.0 * u
	Kit.shadow(p, f + Vector2(4, 0) * u, 34 * u, 8 * u)
	for k in 3:  # 기둥 밑 돌
		Cave._stone(p, Vector2(px + (k - 1) * 7 * u, f.y - 1 * u), 5 * u, 3.5 * u, Color("#5a5450"))
	Kit.post(p, Vector2(px, f.y), Vector2(px, top - 4 * u), 7.0 * u, Color("#4a3624"))
	Kit.post(p, Vector2(px - 4 * u, top), Vector2(f.x + 38 * u, top), 6.0 * u, Color("#523c28"))
	Kit.post(p, Vector2(px, top + 34 * u), Vector2(px + 30 * u, top), 4.0 * u, Color("#46321f"))
	var rx := f.x + 28.0 * u
	Ink.line(p, Vector2(rx, top + 2 * u), Vector2(rx, top + 50 * u), 2.4 * u, K.INK, 0.8, 0.3)
	Ink.line(p, Vector2(rx, top + 2 * u), Vector2(rx, top + 50 * u), 1.6 * u, Color("#8a7450"), 1.0, 0.3)
	for k in 4:  # 매듭
		Ink.line(p, Vector2(rx - 2.4 * u, top + (50 + k * 2.2) * u), Vector2(rx + 2.4 * u, top + (50 + k * 2.2) * u), 2.0 * u, Color("#7a6444"), 1.0, 0.2)
	var loop := Cave._ellipse(Vector2(rx, top + 66 * u), 6 * u, 8 * u, 18)
	Ink.path(p, loop, 3.0 * u, true, K.INK, 0.85, 0.2)
	Ink.path(p, loop, 1.8 * u, true, Color("#8a7450"), 1.0, 0.2)
	var st := f + Vector2(28, -4) * u  # 넘어진 의자
	Kit.post(p, st + Vector2(-8, 0) * u, st + Vector2(8, -6) * u, 4.0 * u, K.WOOD)
	Kit.post(p, st + Vector2(-6, -2) * u, st + Vector2(-12, -10) * u, 2.0 * u, K.WOOD.darkened(0.2))
	Kit.post(p, st + Vector2(6, -6) * u, st + Vector2(2, -14) * u, 2.0 * u, K.WOOD.darkened(0.2))


## 돌 우물: 둥근 돌 둘레(돌 줄눈) + 검은 물, 두 기둥 위 작은 박공 지붕, 감개 + 두레박.
static func _well(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 30 * u, 9 * u)
	var stone := Color("#5e5a60")
	Kit.cyl(p, f, 24 * u, 24 * u, stone, 0)
	for k in 2:  # 돌 줄눈
		var y := -8.0 - k * 8.0
		var pts := PackedVector2Array()
		for j in 13:
			var a := PI * j / 12.0
			pts.append(f + Vector2(cos(a) * 24, y + sin(a) * 24 * Kit.DEPTH * 0.6) * u)
		Ink.path(p, pts, 0.9 * u, false, K.INK, 0.55, 0.3)
		for j in 5:
			var a := PI * (j + 0.5 + k * 0.5) / 5.5
			var q := f + Vector2(cos(a) * 24, y + sin(a) * 24 * Kit.DEPTH * 0.6) * u
			Ink.line(p, q, q + Vector2(0, 8 * u), 0.8 * u, K.INK, 0.5, 0.2)
	p.fill_poly(Cave._ellipse(f + Vector2(0, -24 * u), 19 * u, 6 * u, 22), func(_x: int, _y: int) -> Color: return Color("#08080c"))
	for x: float in [-22.0, 22.0]:
		Kit.post(p, f + Vector2(x, -18) * u, f + Vector2(x, -82) * u, 4.0 * u, K.WOOD)
	var ry := f.y - 82.0 * u  # 박공 지붕(앞에서 본 두 비탈)
	var roof_l := PackedVector2Array([Vector2(f.x - 30 * u, ry + 6 * u), Vector2(f.x, ry - 18 * u), Vector2(f.x, ry - 30 * u), Vector2(f.x - 30 * u, ry - 6 * u)])
	var roof_r := PackedVector2Array([Vector2(f.x + 30 * u, ry + 6 * u), Vector2(f.x, ry - 18 * u), Vector2(f.x, ry - 30 * u), Vector2(f.x + 30 * u, ry - 6 * u)])
	p.fill_poly(roof_r, func(x: int, y: int) -> Color: return p.vary(Color("#3a2a20"), x, y, 0.12))
	p.fill_poly(roof_l, func(x: int, y: int) -> Color: return p.vary(Color("#5a4230"), x, y, 0.12))
	for k in 3:
		Ink.line(p, Vector2(f.x - (8 + k * 8) * u, ry - (14 - k * 6) * u), Vector2(f.x - (8 + k * 8) * u, ry - (26 - k * 6) * u), 0.7 * u, K.INK, 0.5, 0.3)
	Ink.path(p, roof_l, 1.3 * u, true, K.INK, 0.85, 0.3)
	Ink.path(p, roof_r, 1.3 * u, true, K.INK, 0.85, 0.3)
	var ax := f.y - 58.0 * u  # 감개
	Kit.post(p, Vector2(f.x - 24 * u, ax), Vector2(f.x + 30 * u, ax), 4.0 * u, Color("#5a4230"))
	Kit.post(p, Vector2(f.x + 30 * u, ax), Vector2(f.x + 30 * u, ax + 10 * u), 2.0 * u, K.IRON)
	Ink.line(p, Vector2(f.x + 2 * u, ax), Vector2(f.x + 2 * u, ax + 22 * u), 1.0 * u, Color("#8a7450"), 0.95, 0.2)
	Kit.cyl(p, Vector2(f.x + 2 * u, ax + 30 * u), 4.5 * u, 7 * u, Color("#5a4230"), 1)


## 시장 좌판: 진열대 + 네 기둥 + 해진 줄무늬 차양, 항아리·양배추·빵.
static func _stall(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 34 * u, 10 * u)
	var bx := Kit.box(p, f, 58 * u, 30 * u, 26 * u, Color("#6a4c30"))
	Kit.planks(p, bx["front"], 3, Color("#6a4c30"))
	var tp: PackedVector2Array = bx["top"]
	for x: float in [-28.0, 28.0]:
		Kit.post(p, f + Vector2(x, 0) * u, f + Vector2(x, -80) * u, 3.4 * u, K.WOOD)
	for k in 3:  # 항아리
		Kit.cyl(p, tp[0] + Vector2(8 + k * 8, -4) * u, 3.2 * u, 7 * u, Color("#7a4a30").lightened(k * 0.06), 0)
	for k in 3:  # 양배추
		Cave._stone(p, tp[0] + Vector2(36 + k * 6, -6 + (k % 2) * 3) * u, 3.4 * u, 3.0 * u, Color("#4a5a34"))
	Cave._stone(p, tp[0] + Vector2(46, -2) * u, 4.5 * u, 2.4 * u, Color("#8a6a3a"))  # 빵
	var ay := f.y - 80.0 * u  # 차양(뒤에서 앞으로 내려오는 천)
	var aw := PackedVector2Array([Vector2(f.x - 34 * u, ay - 12 * u), Vector2(f.x + 36 * u, ay - 12 * u), Vector2(f.x + 36 * u, ay + 8 * u)])
	for k in 8:  # 해진 앞단(물결 자락)
		var x := f.x + 36 * u - (k + 1) * 70.0 * u / 8.0
		aw.append(Vector2(x + 4 * u, ay + (14.0 + Paint.hash01(k, 3, 9) * 6.0) * u))
		aw.append(Vector2(x, ay + 8 * u))
	p.fill_poly(aw, func(x: int, y: int) -> Color:
		var stripe := int((x - (f.x - 34 * u)) / (10.0 * u)) % 2
		var c := Color("#7a2a22") if stripe == 0 else Color("#8a7a5a")
		return p.vary(c.darkened(clampf((y - ay) / (20.0 * u), 0.0, 1.0) * 0.3), x, y, 0.14))
	Ink.path(p, aw, 1.2 * u, true, K.INK, 0.85, 0.5)
	Cave._pit(p, Vector2(f.x + 8 * u, ay - 2 * u), 2.5 * u)  # 구멍


## 철의 처녀: 사람 꼴 철관(가면 새김) + 오른쪽으로 열린 문(안쪽 가시), 발치에 핏자국.
static func _maiden(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 30 * u, 8 * u)
	K.pool(p, f + Vector2(2, -2) * u, 14 * u, 0.8, 0.0)
	var m := Color("#4e4a4c")
	var c := f + Vector2(-6, 0) * u
	var body := PackedVector2Array([c + Vector2(-15, 0) * u, c + Vector2(-17, -60) * u, c + Vector2(-13, -82) * u, c + Vector2(-6, -94) * u,
		c + Vector2(6, -94) * u, c + Vector2(13, -82) * u, c + Vector2(17, -60) * u, c + Vector2(15, 0) * u])
	p.fill_poly(body, func(x: int, y: int) -> Color:
		var t := (x - c.x) / (17.0 * u)
		return p.vary(m.lightened(0.18 - t * 0.3).lerp(K.RUST, clampf(p.nz("lo", x, y) - 0.45, 0.0, 0.4)), x, y, 0.1))
	p.fill_poly(PackedVector2Array([c + Vector2(-10, -4) * u, c + Vector2(-11, -60) * u, c + Vector2(-8, -78) * u, c + Vector2(8, -78) * u, c + Vector2(11, -60) * u, c + Vector2(10, -4) * u]),
		func(_x: int, _y: int) -> Color: return Color("#0e0808"))  # 열린 안쪽
	for k in 6:  # 안쪽 가시
		for sx: float in [-1.0, 1.0]:
			var b := c + Vector2(sx * 10, -12 - k * 11) * u
			var tip := PackedVector2Array([b + Vector2(0, -2) * u, b + Vector2(-sx * 6, 0) * u, b + Vector2(0, 2) * u])
			p.fill_poly(tip, func(_x: int, _y: int) -> Color: return Color("#8a8a90"))
	Ink.path(p, body, 1.6 * u, true, K.INK, 0.9, 0.3)
	var door := PackedVector2Array([c + Vector2(15, -2) * u, c + Vector2(17, -60) * u, c + Vector2(14, -82) * u, c + Vector2(30, -78) * u, c + Vector2(34, -58) * u, c + Vector2(32, 2) * u])
	p.fill_poly(door, func(x: int, y: int) -> Color: return p.vary(m.darkened(0.35), x, y, 0.1))
	for k in 5:  # 문 안쪽 가시
		var b := c + Vector2(24, -10 - k * 13) * u
		var tip := PackedVector2Array([b + Vector2(-2, -1.5) * u, b + Vector2(-8, 0) * u, b + Vector2(-2, 1.5) * u])
		p.fill_poly(tip, func(_x: int, _y: int) -> Color: return Color("#9a9aa0"))
		Ink.path(p, tip, 0.6 * u, true, K.INK, 0.6, 0.1)
	Ink.path(p, door, 1.4 * u, true, K.INK, 0.9, 0.3)
	var face := c + Vector2(0, -86) * u  # 가면 얼굴(이마 테)
	Ink.line(p, face + Vector2(-5, 0) * u, face + Vector2(5, 0) * u, 1.0 * u, K.INK, 0.6, 0.3)
	Ink.line(p, c + Vector2(-9, -4) * u, c + Vector2(-9, -30) * u, 1.6 * u, Color("#4a0608"), 0.7, 0.5)  # 흘러내린 피


## 석상: 받침돌 + 두건 쓴 옷자락 인물(손 모음), 풍화 금·이끼. weep = 우는 여신(분수대용 — 고개 숙이고 손을 얼굴에).
static func _statue(p: Paint, f: Vector2, u: float, stone: Color, weep: bool) -> void:
	var base := f
	if not weep:
		Kit.shadow(p, f, 26 * u, 8 * u)
		Kit.box(p, f, 40 * u, 32 * u, 24 * u, stone.darkened(0.2))
		base = f + Vector2(2, -30) * u
	var hgt := 86.0 * u if not weep else 56.0 * u
	var wd := 15.0 * u if not weep else 10.0 * u
	var robe := PackedVector2Array([base + Vector2(-wd * 1.25, 0), base + Vector2(-wd * 0.95, -hgt * 0.5), base + Vector2(-wd * 0.8, -hgt * 0.78),
		base + Vector2(-wd * 0.5, -hgt * 0.9), base + Vector2(0, -hgt), base + Vector2(wd * 0.55, -hgt * 0.9), base + Vector2(wd * 0.85, -hgt * 0.76),
		base + Vector2(wd, -hgt * 0.5), base + Vector2(wd * 1.25, 0)])
	p.fill_poly(robe, func(x: int, y: int) -> Color:
		var t := (x - base.x) / (wd * 1.2)
		var fold := sin((x - base.x) / u * 0.7 + (y - base.y) / u * 0.05) * 0.06
		return p.vary(stone.lightened(0.2 - t * 0.35 + fold), x, y, 0.08))
	for k in 4:  # 옷 주름
		var x := base.x + (-wd * 0.8 + k * wd * 0.5)
		Ink.line(p, Vector2(x, base.y - hgt * 0.55), Vector2(x - (k - 1.5) * 2.0 * u, base.y - 2 * u), 0.8 * u, K.INK, 0.45, 0.8)
	var hd := base + Vector2(0, -hgt * 0.82)  # 두건 속 얼굴 그늘
	p.fill_poly(Cave._ellipse(hd + Vector2(0, 2 * u), wd * 0.38, wd * 0.42, 14), func(_x: int, _y: int) -> Color: return stone.darkened(0.6))
	var hands := base + Vector2(0, -hgt * (0.55 if not weep else 0.74))
	Cave._stone(p, hands, wd * 0.45, wd * 0.3, stone.lightened(0.1))
	if weep:
		Kit.post(p, hands + Vector2(-wd * 0.6, wd * 0.5), hands, 2.6 * u, stone.lightened(0.05))
	Ink.path(p, robe, 1.5 * u, true, K.INK, 0.9, 0.4)
	Cave._crack(p, base + Vector2(-wd * 0.4, -hgt * 0.4), 3, 6.0 * u, Vector2(0.3, 1.0))
	if not weep:
		Decals._blob(p, base + Vector2(-wd * 0.8, -4 * u), 5 * u, Color("#2e3a24"), 0.6, 0.4)  # 이끼
