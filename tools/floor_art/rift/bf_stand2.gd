extends RefCounted
## 핏빛성채 서 있는 소품 16~30(bf.gd가 부른다): 제단·책장·성당 의자·쇠 우리·마른 나무·짚 침상·촛대·바위·꼬챙이 시체·무덤·
## 찢긴 깃발·곡식 자루·말뚝·마른 분수대 여신상(푸른 눈물)·무너진 책장(초록빛 사령서).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Cave := preload("res://tools/floor_art/Cave.gd")
const Decals := preload("res://tools/floor_art/Decals.gd")
const Kit := preload("res://tools/floor_art/rift/Kit.gd")
const K := preload("res://tools/floor_art/rift/bf_kit.gd")
const S1 := preload("res://tools/floor_art/rift/bf_stand.gd")

const BOOKS := [Color("#5a1a1a"), Color("#4a3a24"), Color("#2e3a2a"), Color("#6a5232"), Color("#3a2a30"), Color("#7a6a4a")]


static func paint(p: Paint, tile: String) -> bool:
	var u := p.w / 128.0
	var f := Vector2(p.w * 0.5, p.h - p.w * 0.14)
	var l := f.x - 32.0 * u
	match tile:
		"bf_altar":
			_altar(p, f, u)
		"bf_bookcase":
			_bookcase(p, f, u, false)
		"bf_pew":
			Kit.shadow(p, f + Vector2(0, -4 * u), 36 * u, 9 * u, 0.4)
			var ty := f.y - 42.0 * u
			var back := PackedVector2Array([Vector2(l, f.y), Vector2(l + 64 * u, f.y), Vector2(l + 64 * u, ty), Vector2(l, ty)])
			p.fill_poly(back, func(x: int, y: int) -> Color:
				var g := sin(y * 0.9 + p.nz("mid", x, y) * 5.0) * 0.04
				return p.vary(Color("#5a3e2a").darkened(clampf((y - ty) / (42.0 * u), 0.0, 1.0) * 0.35 - g), x, y, 0.08))
			for k in 4:  # 판넬 테
				var x0 := l + k * 16.0 * u + 2 * u
				var pan := Paint.rect_poly(x0, ty + 10 * u, 12 * u, 26 * u)
				Ink.path(p, pan, 0.9 * u, true, K.INK, 0.55, 0.3)
				Ink.line(p, Vector2(x0 + 0.5, ty + 10 * u), Vector2(x0 + 0.5, ty + 36 * u), 0.6 * u, K.LIT, 0.25, 0.3)
			var rail := Paint.rect_poly(l, ty - 5 * u, 64 * u, 6 * u)  # 둥근 등받이 위 테
			p.fill_poly(rail, func(x: int, y: int) -> Color: return p.vary(Color("#6a4a32").lightened(0.15 if y < ty - 2 * u else 0.0), x, y, 0.08))
			Ink.line(p, Vector2(l, ty - 5 * u), Vector2(l + 64 * u, ty - 5 * u), 1.2 * u, K.INK, 0.85, 0.3)
			Ink.line(p, Vector2(l, ty + 1 * u), Vector2(l + 64 * u, ty + 1 * u), 1.2 * u, K.INK, 0.85, 0.3)
			Ink.line(p, Vector2(l, f.y), Vector2(l + 64 * u, f.y), 1.4 * u, K.INK, 0.9, 0.3)
			Cave._dot(p, Vector2(f.x + 12 * u, ty - 2 * u), 2.0 * u, Color("#c8b890"), 0.7)  # 촛농
		"bf_cage":
			_cage(p, f, u)
		"bf_deadtree":
			Kit.shadow(p, f, 22 * u, 7 * u)
			for k in 4:  # 뿌리
				var a := PI + PI * (k + 0.5) / 4.0 * -1.0
				S1._sharp(p, f + Vector2(0, -6) * u, f + Vector2(cos(a) * 18, 2 + sin(a) * -3) * u, 4.0 * u, Color("#2a221e"))
			_branch(p, f, Vector2(0, -1), 46.0 * u, 11.0 * u, 0, u)
		"bf_bed":
			Kit.shadow(p, f + Vector2(0, -6 * u), 34 * u, 12 * u)
			var bx := Kit.box(p, f, 56 * u, 54 * u, 12 * u, Color("#5a4430"))
			var tp: PackedVector2Array = bx["top"]
			var mid := (tp[0] + tp[2]) * 0.5
			p.fill_poly(Cave._ellipse(mid, 24 * u, 11 * u, 24, p.rng), func(x: int, y: int) -> Color: return p.vary(Color("#8a7448"), x, y, 0.15))  # 짚 요
			for k in 30:
				var q := mid + Vector2(p.rng.randf_range(-22, 22), p.rng.randf_range(-9, 9)) * u
				Ink.line(p, q, q + Vector2.from_angle(p.rng.randf_range(-0.5, 0.5)) * 5 * u, 0.7 * u, Color("#b09a60") if k % 3 else Color("#4a3a24"), 0.8, 0.4)
			var blank := PackedVector2Array([mid + Vector2(-4, -11) * u, mid + Vector2(22, -10) * u, mid + Vector2(26, 10) * u, mid + Vector2(28, 16) * u, mid + Vector2(-2, 14) * u])
			p.fill_poly(blank, func(x: int, y: int) -> Color: return p.vary(Color("#5a524a"), x, y, 0.14))  # 해진 담요
			Ink.path(p, blank, 1.1 * u, true, K.INK, 0.8, 0.8)
			K.stain(p, mid + Vector2(10, 2) * u, 3.5 * u, 0.45)
		"bf_candles":
			Kit.shadow(p, f, 16 * u, 5 * u)
			for dx: float in [-10.0, 0.0, 10.0]:
				Kit.post(p, f + Vector2(0, -8) * u, f + Vector2(dx, 0) * u, 2.4 * u, Color("#3a3634"))
			Kit.post(p, f + Vector2(0, -6) * u, f + Vector2(0, -98) * u, 3.0 * u, Color("#3e3a38"))
			for k in 3:  # 줄기 마디
				Cave._stone(p, f + Vector2(0, -30 - k * 24) * u, 3.2 * u, 2.0 * u, Color("#4a4644"))
			var arm := f.y - 94.0 * u
			for sx: float in [-1.0, 1.0]:
				Ink.line(p, Vector2(f.x, arm), Vector2(f.x + sx * 12 * u, arm - 6 * u), 2.4 * u, K.INK, 0.9, 0.2)
				Ink.line(p, Vector2(f.x + sx * 12 * u, arm - 6 * u), Vector2(f.x + sx * 16 * u, arm - 14 * u), 2.4 * u, K.INK, 0.9, 0.2)
				Ink.line(p, Vector2(f.x, arm - 1), Vector2(f.x + sx * 16 * u, arm - 14 * u), 1.0 * u, Color("#6a6460"), 0.6, 0.2)
			for cx: float in [-16.0, 0.0, 16.0]:
				var cy := arm - (14.0 if cx != 0.0 else 6.0) * u
				var cb := Vector2(f.x + cx * u, cy)
				p.fill_poly(Cave._ellipse(cb, 4 * u, 1.6 * u, 10), func(_x: int, _y: int) -> Color: return Color("#2a2624"))
				var ch := 9.0 * u if cx != 0.0 else 13.0 * u
				Kit.cyl(p, cb, 2.0 * u, ch, Color("#d8ccb0"), 0)
				Ink.line(p, cb + Vector2(1.4, -ch + 2 * u), cb + Vector2(1.6, -ch * 0.4), 1.0 * u, Color("#f0e8d0"), 0.8, 0.3)  # 촛농
				Kit.flame(p, cb + Vector2(0, -ch - 1 * u), 4.0 * u)
			K.halo(p, Vector2(f.x, arm - 24 * u), 40 * u, Color("#ffa040"), 0.32)
		"bf_rock":
			Kit.shadow(p, f + Vector2(0, -6 * u), 32 * u, 10 * u)
			Kit.blob(p, f + Vector2(-4, -20) * u, 26 * u, 21 * u, Color("#6a6262"))
			Kit.blob(p, f + Vector2(16, -8) * u, 13 * u, 9 * u, Color("#5e5656"))
			Cave._crack(p, f + Vector2(-10, -34) * u, 3, 7.0 * u, Vector2(0.4, 1.0))
			Decals._blob(p, f + Vector2(-16, -10) * u, 5 * u, Color("#3a3a2a"), 0.5, 0.4)
		"bf_stake":
			_impaled(p, f, u)
		"bf_grave":
			Kit.shadow(p, f + Vector2(0, -6 * u), 26 * u, 9 * u)
			Cave._stone(p, f + Vector2(0, -2) * u, 18 * u, 8 * u, Color("#4a3a2c"))  # 흙 둔덕
			for k in 6:
				Cave._dot(p, f + Vector2(p.rng.randf_range(-14, 14), p.rng.randf_range(-6, 2)) * u, 1.2 * u, Color("#2a2018"), 0.6)
			var b := f + Vector2(2, -10) * u
			var lean := 0.14
			var pts := PackedVector2Array()
			for q: Vector2 in [Vector2(-12, 0), Vector2(-12, -34), Vector2(-9, -42), Vector2(0, -46), Vector2(9, -42), Vector2(12, -34), Vector2(12, 0)]:
				pts.append(b + Vector2(q.x + (-q.y) * lean, q.y) * u)
			var side := PackedVector2Array([pts[6], pts[5], pts[5] + Vector2(4, -3) * u, pts[6] + Vector2(4, -3) * u])
			p.fill_poly(side, func(x: int, y: int) -> Color: return p.vary(Color("#4a4644"), x, y, 0.08))
			p.fill_poly(pts, func(x: int, y: int) -> Color: return p.vary(Color("#7a7470").lightened(0.1 - (x - b.x) / (12.0 * u) * 0.15), x, y, 0.1))
			Ink.path(p, pts, 1.5 * u, true, K.INK, 0.9, 0.4)
			var cx := b + Vector2(0 + 22 * lean, -22) * u  # 새긴 십자
			Ink.line(p, cx + Vector2(1.4, -8) * u, cx + Vector2(-1.2, 8) * u, 1.6 * u, K.INK, 0.7, 0.2)
			Ink.line(p, cx + Vector2(-5, -2.5) * u, cx + Vector2(5, -2.5) * u, 1.6 * u, K.INK, 0.7, 0.2)
			Decals._blob(p, b + Vector2(-4, -6) * u, 4 * u, Color("#2e3a24"), 0.55, 0.4)
		"bf_flag":
			_banner(p, f, u)
		"bf_sack":
			Kit.shadow(p, f + Vector2(0, -4 * u), 30 * u, 9 * u)
			for q: Vector3 in [Vector3(-12, -12, 14), Vector3(13, -10, 13), Vector3(0, -2, 15)]:
				var c := f + Vector2(q.x, q.y) * u
				var r := q.z * u
				Cave._stone(p, c, r, r * 0.85, Color("#8a7656"))
				Ink.hatch(p, Cave._ellipse(c, r * 0.8, r * 0.65, 14), 2.4 * u, 70.0, 0.2, 0.6 * u)
				Cave._stone(p, c + Vector2(r * 0.15, -r * 0.85), r * 0.3, r * 0.25, Color("#7a6648"))  # 묶은 목
				Ink.line(p, c + Vector2(-r * 0.15, -r * 0.65), c + Vector2(r * 0.45, -r * 0.62), 1.2 * u, Color("#4a3a24"), 0.9, 0.3)
		"bf_post":
			Kit.shadow(p, f, 12 * u, 4 * u)
			Kit.cyl(p, f, 5.5 * u, 46 * u, Color("#5a4430"), 0)
			Ink.path(p, Cave._ellipse(f + Vector2(7, -30) * u, 3.5 * u, 4.5 * u, 14), 1.8 * u, true, Color("#5a5658"), 0.95, 0.2)
			Ink.line(p, f + Vector2(9, -27) * u, f + Vector2(14, -10) * u, 1.6 * u, Color("#8a7450"), 0.95, 0.6)  # 끊긴 밧줄
			for k in 3:
				Ink.line(p, f + Vector2(14, -10) * u, f + Vector2(13 + k * 1.5, -6) * u, 0.7 * u, Color("#8a7450"), 0.8, 0.3)
		"fountain_statue":
			_fountain(p, f, u)
		"bookshelf":
			_bookcase(p, f, u, true)
		_:
			return false
	return true


## 검은 돌 제단: 상판에 해골·피 그릇, 앞면으로 흘러내린 피, 네 귀퉁이 붉은 초(붉은 빛).
static func _altar(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 34 * u, 10 * u)
	K.pool(p, f + Vector2(4, 0) * u, 16 * u, 1.0, 0.3)
	var bx := Kit.box(p, f, 58 * u, 34 * u, 30 * u, Color("#2a2224"))
	var fr: PackedVector2Array = bx["front"]
	var tp: PackedVector2Array = bx["top"]
	Ink.line(p, fr[0] + Vector2(0, 6 * u), fr[1] + Vector2(0, 6 * u), 1.0 * u, K.INK, 0.6, 0.3)  # 새긴 띠
	for k in 4:
		var q := fr[0] + Vector2((10 + k * 13) * u, 12 * u)
		Ink.path(p, Cave._ellipse(q, 3 * u, 3 * u, 10), 0.8 * u, true, Color("#5a3a3a"), 0.6, 0.2)
	for k in 5:  # 흘러내린 피
		var x := fr[0].x + (8 + k * 10 + Paint.hash01(k, 1, 3) * 4) * u
		var ln := (8.0 + Paint.hash01(k, 2, 3) * 20.0) * u
		Ink.line(p, Vector2(x, fr[0].y), Vector2(x, fr[0].y + ln), 2.4 * u, Color("#5a0608"), 0.9, 0.3)
		Ink.line(p, Vector2(x - 0.6, fr[0].y), Vector2(x - 0.6, fr[0].y + ln * 0.8), 0.7 * u, K.BLOOD_LIT, 0.6, 0.3)
		Cave._dot(p, Vector2(x, fr[0].y + ln), 1.8 * u, Color("#5a0608"), 0.9)
	var mid := (tp[0] + tp[2]) * 0.5
	Decals._blob(p, mid + Vector2(4, 2) * u, 9 * u, Color("#5a0608"), 0.75, 0.3)
	K.skull(p, mid + Vector2(-6, -1) * u, u * 1.4, K.BONE.darkened(0.1))
	Kit.cyl(p, mid + Vector2(10, 2) * u, 4.5 * u, 4 * u, K.GOLD.darkened(0.2), 0)  # 피 그릇
	p.fill_poly(Cave._ellipse(mid + Vector2(10, -2) * u, 3.6 * u, 1.4 * u, 10), func(_x: int, _y: int) -> Color: return K.BLOOD_LIT)
	for c: Vector2 in [tp[3] + Vector2(4, 3) * u, tp[2] + Vector2(-4, 3) * u, tp[0] + Vector2(4, -2) * u, tp[1] + Vector2(-4, -2) * u]:
		Kit.cyl(p, c, 2.2 * u, 10 * u, Color("#8a1a1a"), 0)
		Ink.line(p, c + Vector2(1.2, -9 * u), c + Vector2(1.4, -3 * u), 0.9 * u, Color("#c03030"), 0.7, 0.3)
		Kit.flame(p, c + Vector2(0, -11 * u), 3.6 * u)
		K.halo(p, c + Vector2(0, -13 * u), 16 * u, Color("#ff5030"), 0.28)
	K.halo(p, mid + Vector2(0, -6 * u), 44 * u, Color("#d02818"), 0.18)


## 높은 책장(broken = 무너진 책장 — 기울고 선반이 부러져 책이 쏟아졌으며 책 하나가 병든 초록빛).
static func _bookcase(p: Paint, f: Vector2, u: float, broken: bool) -> void:
	Kit.shadow(p, f + Vector2(0, -4 * u), 32 * u, 8 * u)
	var wd := 54.0 * u
	var ht := 112.0 * u if not broken else 104.0 * u
	var lean := 0.0 if not broken else 0.12
	var bl := f + Vector2(-wd * 0.5, 0)
	var corner := func(x: float, y: float) -> Vector2: return bl + Vector2(x + y * lean, -y)
	var frame := PackedVector2Array([corner.call(0, 0), corner.call(wd, 0), corner.call(wd, ht), corner.call(0, ht)])
	var top := PackedVector2Array([corner.call(0, ht), corner.call(wd, ht), corner.call(wd, ht) + Vector2(4, -9) * u, corner.call(0, ht) + Vector2(4, -9) * u])
	var wood := Color("#4a3424") if not broken else Color("#3e3224")
	p.fill_poly(frame, func(x: int, y: int) -> Color: return p.vary(wood, x, y, 0.12))
	p.fill_poly(top, func(x: int, y: int) -> Color: return p.vary(wood.lightened(0.2), x, y, 0.1))
	var rows := 5
	var inset := 4.0 * u
	var green := Vector2.ZERO
	var rowh := (ht - inset * 2.0) / rows
	for r in rows:
		var yb := inset + r * rowh  # 선반(책이 서는 곳)
		var yt := yb + rowh - 2.5 * u
		var back := PackedVector2Array([corner.call(inset, yb), corner.call(wd - inset, yb), corner.call(wd - inset, yt), corner.call(inset, yt)])
		p.fill_poly(back, func(_x: int, _y: int) -> Color: return Color("#120c0a"))
		var x := inset + 1.0 * u
		var k := 0
		var gap := broken and r == 2
		while x < wd - inset - 3.0 * u:
			var bw := (3.0 + Paint.hash01(r, k, 11) * 3.5) * u
			var bh := (yt - yb) * (0.6 + Paint.hash01(k, r, 12) * 0.35)
			var tilt := 0.0
			if Paint.hash01(r, k, 13) > 0.85 or (broken and Paint.hash01(r, k, 14) > 0.5):
				tilt = 0.25
			if gap and x > wd * 0.35:
				break
			if Paint.hash01(r, k, 17) > 0.9:  # 빈자리
				x += bw * 1.5
				k += 1
				continue
			var col: Color = BOOKS[int(Paint.hash01(r, k, 15) * BOOKS.size()) % BOOKS.size()]
			if broken:
				col = col.lerp(Color("#3a3428"), 0.35)
			var b0: Vector2 = corner.call(x, yb)
			var book := PackedVector2Array([b0, b0 + Vector2(bw, 0), b0 + Vector2(bw + bh * tilt, -bh), b0 + Vector2(bh * tilt, -bh)])
			p.fill_poly(book, func(xx: int, yy: int) -> Color: return p.vary(col.lightened(0.12 if xx < b0.x + bw * 0.4 else -0.05), xx, yy, 0.1))
			Ink.path(p, book, 0.7 * u, true, K.INK, 0.6, 0.1)
			if Paint.hash01(r, k, 16) > 0.6:
				Ink.line(p, b0 + Vector2(bh * tilt * 0.3, -bh * 0.3), b0 + Vector2(bw + bh * tilt * 0.3, -bh * 0.3), 0.6 * u, K.GOLD, 0.6, 0.1)
			if broken and r == 3 and k == 2:
				green = b0 + Vector2(bw * 0.5, -bh * 0.5)
			x += bw + 0.6 * u
			k += 1
		var shelf_l: Vector2 = corner.call(inset, yb)
		var shelf_r: Vector2 = corner.call(wd - inset, yb)
		if gap:  # 부러진 선반
			shelf_r = shelf_l.lerp(shelf_r, 0.5) + Vector2(4, 10) * u
		Kit.post(p, shelf_l + Vector2(0, 1.2 * u), shelf_r + Vector2(0, 1.2 * u), 2.6 * u, wood.lightened(0.1))
	Ink.path(p, frame, 1.6 * u, true, K.INK, 0.9, 0.3)
	Ink.path(p, top, 1.2 * u, true, K.INK, 0.8, 0.3)
	if broken:
		Ink.line(p, corner.call(wd * 0.7, ht), corner.call(wd * 0.55, ht * 0.6), 1.6 * u, K.INK, 0.9, 1.0)  # 쪼개진 옆판
		for k in 5:  # 쏟아진 책
			var q := f + Vector2(p.rng.randf_range(-24, 26), p.rng.randf_range(-6, 6)) * u
			var bk := Paint.rect_poly(q.x - 4 * u, q.y - 3 * u, 8 * u, 5 * u)
			var col: Color = BOOKS[k % BOOKS.size()]
			p.fill_poly(bk, func(x: int, y: int) -> Color: return p.vary(col.lerp(Color("#3a3428"), 0.3), x, y, 0.1))
			Ink.path(p, bk, 0.8 * u, true, K.INK, 0.7, 0.3)
		Decals._blob(p, corner.call(wd * 0.3, ht * 0.85), 6 * u, Color("#3a4a30"), 0.45, 0.4)  # 곰팡이
		if green != Vector2.ZERO:  # 사령서의 병든 초록빛
			Cave._dot(p, green, 2.6 * u, Color("#b0ff90"), 0.8)
			K.halo(p, green, 22 * u, Color("#7aff6a"), 0.4)


## 쇠 우리: 둥근 바닥판 + 세로 살 + 둥근 지붕 고리, 안에 웅크린 해골.
static func _cage(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 26 * u, 8 * u)
	var r := 22.0 * u
	var ry := r * Kit.DEPTH * 0.6
	var top := f.y - 84.0 * u
	p.fill_poly(Cave._ellipse(f, r, ry, 24), func(x: int, y: int) -> Color: return p.vary(Color("#2e2c2e"), x, y, 0.1))
	var iron := Color("#4a4648")
	for k in 7:  # 뒤쪽 살
		var a := PI + PI * (k + 0.5) / 7.0
		var b := f + Vector2(cos(a) * r, sin(a) * ry)
		Ink.line(p, b, Vector2(f.x + cos(a) * r * 0.9, top + sin(a) * ry * 0.9), 2.0 * u, iron.darkened(0.4), 0.9, 0.2)
	var sk := f + Vector2(-4, -10) * u  # 웅크린 해골
	K.ribs(p, sk + Vector2(0, -10) * u, -PI * 0.5, u * 1.6)
	K.skull(p, sk + Vector2(2, -26) * u, u * 1.5, K.BONE.darkened(0.2))
	K.bone(p, sk + Vector2(-8, 0) * u, sk + Vector2(10, -4) * u, u * 1.4, K.BONE.darkened(0.25))
	for k in 8:  # 앞쪽 살
		var a := PI * (k + 0.5) / 8.0
		var b := f + Vector2(cos(a) * r, sin(a) * ry)
		var t := Vector2(f.x + cos(a) * r * 0.9, top + sin(a) * ry * 0.9)
		Kit.post(p, b, t, 2.6 * u, iron.lerp(K.RUST, Paint.hash01(k, 2, 4) * 0.5))
	for y: float in [f.y, top + (f.y - top) * 0.5]:  # 테
		var pts := PackedVector2Array()
		for j in 13:
			var a := PI * j / 12.0
			pts.append(Vector2(f.x + cos(a) * r * (1.0 if y == f.y else 0.95), y + sin(a) * ry))
		Ink.path(p, pts, 3.4 * u, false, K.INK, 0.85, 0.2)
		Ink.path(p, pts, 2.2 * u, false, iron.lightened(0.1), 1.0, 0.2)
	var dome := PackedVector2Array()
	for j in 17:
		var a := PI + PI * j / 16.0
		dome.append(Vector2(f.x + cos(a) * r * 0.9, top + sin(a) * 20 * u))
	Ink.path(p, dome, 3.0 * u, false, iron, 0.95, 0.2)
	Ink.line(p, Vector2(f.x, top - 20 * u), Vector2(f.x, top), 2.4 * u, iron, 0.95, 0.2)
	Ink.path(p, Cave._ellipse(Vector2(f.x, top - 24 * u), 3.5 * u, 4.5 * u, 12), 1.8 * u, true, iron.lightened(0.15), 0.95, 0.2)
	for k in 4:  # 늘어진 사슬
		Ink.path(p, Cave._ellipse(Vector2(f.x, top - 32 * u - k * 5 * u), 1.6 * u, 2.6 * u, 8), 1.2 * u, true, iron.lightened(0.1), 0.9, 0.2)


## 마른 나무 가지(재귀 — 갈라질수록 가늘고 비틀린다).
static func _branch(p: Paint, a: Vector2, dir: Vector2, ln: float, wd: float, depth: int, u: float) -> void:
	var d := dir.rotated(p.rng.randf_range(-0.35, 0.35)).normalized()
	var m := a + d * ln * 0.5 + Vector2(-d.y, d.x) * p.rng.randf_range(-4, 4) * u
	var b := a + d * ln
	for seg: Array in [[a, m, wd], [m, b, wd * 0.82]]:
		var s0: Vector2 = seg[0]
		var s1: Vector2 = seg[1]
		var sw: float = seg[2]
		Ink.line(p, s0, s1, sw + 1.6 * u, K.INK, 0.95, 0.5)
		Ink.line(p, s0, s1, sw, Color("#2e2622"), 1.0, 0.5)
		Ink.line(p, s0 - Vector2(sw * 0.25, 0), s1 - Vector2(sw * 0.2, 0), maxf(0.6, sw * 0.25), Color("#5a4e46"), 0.6, 0.5)
	if depth >= 4 or wd < 1.4 * u:
		return
	var n := 2 if depth > 0 else 3
	for k in n:
		var nd := d.rotated(p.rng.randf_range(0.35, 0.8) * (1.0 if k % 2 == 0 else -1.0))
		if nd.y > 0.2:
			nd = Vector2(nd.x, -0.2).normalized()
		_branch(p, b if k < 2 else m, nd, ln * p.rng.randf_range(0.55, 0.75), wd * 0.6, depth + 1, u)


## 꼬챙이에 꿰인 시체: 높은 말뚝 + 앞으로 꺾여 늘어진 몸·머리·팔다리, 말뚝을 타고 흐른 피, 쪼인 구멍.
static func _impaled(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 22 * u, 6 * u)
	K.pool(p, f + Vector2(2, -1) * u, 9 * u, 0.6, 0.0)
	var top := f + Vector2(2, -156) * u
	S1._sharp(p, f, top, 5.0 * u, Color("#4a3624"))
	Ink.line(p, f + Vector2(-0.5, -96) * u, f + Vector2(0.5, -4) * u, 2.6 * u, Color("#4a0608"), 0.8, 0.5)  # 피 줄기
	var skin := Color("#7a7468")
	var hip := f + Vector2(1, -108) * u
	var chest := hip + Vector2(10, -16) * u
	for sx: float in [-1.0, 1.0]:  # 늘어진 다리
		var knee := hip + Vector2(sx * 6 + 3, 18) * u
		Kit.post(p, hip + Vector2(sx * 3, 0) * u, knee, 6.0 * u, Color("#4a4034"))
		Kit.post(p, knee, knee + Vector2(sx * 2, 22) * u, 5.0 * u, skin.darkened(0.15))
	var torso := PackedVector2Array([hip + Vector2(-7, 2) * u, hip + Vector2(8, 4) * u, chest + Vector2(10, 4) * u, chest + Vector2(6, -6) * u, chest + Vector2(-8, -4) * u])
	p.fill_poly(torso, func(x: int, y: int) -> Color: return p.vary(skin.lightened(0.05 - (x - hip.x) / (16.0 * u) * 0.3), x, y, 0.1))
	p.fill_poly(PackedVector2Array([hip + Vector2(-7, 2) * u, hip + Vector2(8, 4) * u, hip + Vector2(6, -6) * u, hip + Vector2(-6, -8) * u]), func(x: int, y: int) -> Color: return p.vary(Color("#4a4034"), x, y, 0.12))  # 누더기
	Ink.path(p, torso, 1.4 * u, true, K.INK, 0.9, 0.4)
	for k in 3:  # 갈비 그늘
		Ink.line(p, chest + Vector2(-4, 2 + k * 3) * u, chest + Vector2(5, 3 + k * 3) * u, 0.8 * u, K.INK, 0.45, 0.3)
	var head := chest + Vector2(12, 8) * u  # 앞으로 꺾인 머리
	Cave._stone(p, head, 6 * u, 6.5 * u, skin)
	Decals._blob(p, head + Vector2(-1, -3) * u, 5 * u, Color("#2a2420"), 0.85, 0.3)  # 머리카락
	Cave._dot(p, head + Vector2(2, 2) * u, 1.6 * u, K.INK, 0.95)
	for sx: float in [-1.0, 1.0]:  # 늘어진 팔
		var sh := chest + Vector2(sx * 7 + 2, 0) * u
		var el := sh + Vector2(sx * 3 + 2, 16) * u
		Kit.post(p, sh, el, 4.0 * u, skin.darkened(0.1))
		Kit.post(p, el, el + Vector2(1, 16) * u, 3.4 * u, skin.darkened(0.2))
	Cave._dot(p, chest + Vector2(0, 4) * u, 2.0 * u, Color("#3a0606"), 0.9)  # 까마귀가 쪼은 구멍
	Cave._dot(p, hip + Vector2(4, -4) * u, 1.6 * u, Color("#3a0606"), 0.9)
	Kit.cone(p, top + Vector2(0, 10) * u, 2.6 * u, 10 * u, Color("#6a3a2a"))  # 몸을 뚫고 나온 끝(핏빛)


## 찢긴 붉은 전쟁 깃발: 높은 장대 + 가로대, 아래가 갈기갈기 찢긴 긴 깃발(바랜 금빛 문장).
static func _banner(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 14 * u, 5 * u)
	for k in 4:
		Cave._stone(p, f + Vector2(-8 + k * 5, -1) * u, 4 * u, 3 * u, Color("#5a5450"))
	var top := f.y - 164.0 * u
	Kit.post(p, f, Vector2(f.x, top), 4.0 * u, Color("#4a3624"))
	Kit.post(p, Vector2(f.x - 18 * u, top + 6 * u), Vector2(f.x + 18 * u, top + 6 * u), 3.0 * u, Color("#523c28"))
	Kit.cone(p, Vector2(f.x, top), 3 * u, 8 * u, K.GOLD.darkened(0.2))
	var y0 := top + 8.0 * u
	var flag := PackedVector2Array([Vector2(f.x - 17 * u, y0), Vector2(f.x + 17 * u, y0)])
	var n := 7
	for k in n + 1:  # 찢긴 아래 끝(오른쪽 → 왼쪽)
		var x := f.x + 17 * u - k * 34.0 * u / n
		var ln := (64.0 + Paint.hash01(k, 1, 21) * 22.0) * u if k % 2 == 0 else (50.0 + Paint.hash01(k, 2, 21) * 12.0) * u
		flag.append(Vector2(x + sin(k * 1.7) * 2 * u, y0 + ln))
	p.fill_poly(flag, func(x: int, y: int) -> Color:
		var fold := sin((x - f.x) / u * 0.45) * 0.5 + 0.5
		var c := Color("#7a1418").darkened(0.35 - fold * 0.35 + clampf((y - y0) / (90.0 * u), 0.0, 1.0) * 0.2)
		return p.vary(c, x, y, 0.12))
	var em := Vector2(f.x, y0 + 26 * u)  # 바랜 문장(탑과 고리)
	Ink.path(p, Cave._ellipse(em, 10 * u, 10 * u, 20), 1.6 * u, true, K.GOLD.darkened(0.15), 0.6, 0.4)
	var tower := PackedVector2Array([em + Vector2(-4, 6) * u, em + Vector2(-4, -4) * u, em + Vector2(-2, -4) * u, em + Vector2(-2, -6) * u, em + Vector2(2, -6) * u, em + Vector2(2, -4) * u, em + Vector2(4, -4) * u, em + Vector2(4, 6) * u])
	p.fill_poly(tower, func(_x: int, _y: int) -> Color: return Color(0.55, 0.42, 0.22, 0.55))
	for k in 3:  # 구멍
		var q := Vector2(f.x + p.rng.randf_range(-11, 11) * u, y0 + p.rng.randf_range(36, 56) * u)
		p.fill_poly(Cave._ellipse(q, 2.2 * u, 3 * u, 10, p.rng), func(_x: int, _y: int) -> Color: return Color(0, 0, 0, 0), 1.0)
		Cave._dot(p, q, 2.4 * u, Color("#1a0606"), 0.9)
	for k in 4:  # 주름 그늘
		var x := f.x + (-12 + k * 8) * u
		Ink.line(p, Vector2(x, y0 + 2 * u), Vector2(x + 1, y0 + 50 * u), 0.8 * u, K.INK, 0.35, 0.8)
	Ink.path(p, flag, 1.3 * u, true, K.INK, 0.85, 0.5)


## 마른 분수대: 넓은 돌 수반(마른 바닥 · 낙엽) + 가운데 받침 위 우는 여신상(차가운 푸른 눈물 빛).
static func _fountain(p: Paint, f: Vector2, u: float) -> void:
	Kit.shadow(p, f, 44 * u, 12 * u)
	var stone := Color("#7a7c80")
	Kit.cyl(p, f, 40 * u, 14 * u, stone.darkened(0.15), 0)
	p.fill_poly(Cave._ellipse(f + Vector2(0, -14 * u), 34 * u, 10 * u, 28), func(x: int, y: int) -> Color: return p.vary(Color("#3a3634"), x, y, 0.12))
	Cave._crack(p, f + Vector2(-20, -14) * u, 3, 7.0 * u, Vector2(1, 0.2))
	for k in 6:  # 낙엽
		Cave._dot(p, f + Vector2(p.rng.randf_range(-28, 28), p.rng.randf_range(-20, -9)) * u, 1.8 * u, Color("#5a3a22"), 0.85)
	Kit.cyl(p, f + Vector2(0, -12 * u), 8 * u, 16 * u, stone.darkened(0.05), 0)  # 받침
	var base := f + Vector2(0, -28 * u)
	S1._statue(p, base, u, Color("#8a9098"), true)
	var eye := base + Vector2(1, -46) * u  # 푸른 눈물
	Cave._dot(p, eye, 1.6 * u, Color("#d8f0ff"), 1.0)
	Ink.line(p, eye, eye + Vector2(0.4, 6) * u, 1.0 * u, Color("#a8d8ff"), 0.8, 0.2)
	K.halo(p, eye, 16 * u, Color("#7ab8ff"), 0.35)
