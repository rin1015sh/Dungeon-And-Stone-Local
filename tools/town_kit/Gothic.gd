extends RefCounted
## 고딕 성당 면 그림(신전 — CT109, 사용자 2026-11-04 "세부적인 요소들을 넣어서 건물을 다시 그려 — 신전 같은 것들 그냥 흰 벽돌 쌓아 놓은 것처럼만 보인다").
## Kit.face의 painter(p, poly_px, size)를 돌려준다(칸당 Facade.P px, y = 아래로).
##   front = 서쪽 정면(겹친 뾰족 아치 정문 · 문간 조각상 · 팀파눔 부조 · 왕의 회랑 벽감 · 장미창 · 돌림띠)
##   gable = 정면 박공(장식 아치 · 잎 장식 · 꼭대기 십자) · tower = 종탑(모서리 돌 · 쌍 첨두창 · 종루 덧창 · 아치 띠 · 홈통 괴물)
##   nave = 본당 옆면(버팀 기둥 사이 트레이서리 창 · 처마 아치 띠 · 뚫린 난간) · spire = 첨탑(점판암 + 모서리 잎 장식)

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")
const Parts := preload("res://tools/city_art/Parts.gd")
const F := preload("res://tools/town_kit/Facade.gd")

const STONE := Color("#9c968a")
const STONE_L := Color("#b4ae9f")
const STONE_D := Color("#6e695f")
const DEEP := Color("#2a2622")
const WOOD := Color("#3a281c")
const IRON := Color("#22201d")
const GLASS := [Color("#26304a"), Color("#4a2224"), Color("#26403a"), Color("#5a4a2a"), Color("#3a2a40")]  ## 바랜 색유리(채도 낮게)


static func _ashlar(p: Paint) -> Callable:
	return Mat.ashlar(p, STONE, 0, 0, int(F.P * 0.34), int(F.P * 0.16))


## 뾰족 아치 테두리 점(아래 왼쪽 → 위 → 아래 오른쪽): 가운데 cx, 밑 base, 폭 w, 높이 h(반지름 = 폭인 두 호).
static func arch_pts(cx: float, base: float, w: float, h: float, n: int = 16) -> PackedVector2Array:
	var r := w
	var rise := w * sqrt(3.0) * 0.5
	var spring := base - maxf(0.0, h - rise)
	var out := PackedVector2Array([Vector2(cx - w * 0.5, base)])
	for i in n + 1:
		var d := -w * 0.5 + w * float(i) / n
		var yy := sqrt(maxf(0.0, r * r - (absf(d) + w * 0.5) ** 2))
		out.append(Vector2(cx + d, spring - yy))
	out.append(Vector2(cx + w * 0.5, base))
	return out


static func circle(c: Vector2, r: float, n: int = 28) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		out.append(c + Vector2.from_angle(TAU * i / n) * r)
	return out


## 겹친 아치 띠(바깥 → 안 — 띠마다 밝고 어둡게 번갈아, 홍예돌 줄).
static func archivolts(p: Paint, cx: float, base: float, w0: float, h0: float, w1: float, h1: float, bands: int) -> void:
	for b in bands:
		var t := float(b) / bands
		var w := lerpf(w0, w1, t)
		var h := lerpf(h0, h1, t)
		var pts := arch_pts(cx, base, w, h)
		p.fill_poly(pts, p.flat(STONE_L if b % 2 == 0 else STONE.darkened(0.12), 0.08))
		Ink.shade(p, pts, Vector2(cx - w * 0.5, 0), Vector2(cx + w * 0.5, 0), 0.0, 0.28)
		var inner := arch_pts(cx, base, lerpf(w0, w1, (b + 1.0) / bands), lerpf(h0, h1, (b + 1.0) / bands))
		for i in range(1, pts.size() - 1, 2):
			Ink.line(p, pts[i], inner[i], 1.0, Color("#2a2420"), 0.5, 0.2)  # 홍예돌 줄
		Ink.path(p, pts, 1.6, false)


## 서 있는 조각상(돌 — 머리 · 긴 옷 · 주름 · 머리 위 닫집).
static func figure(p: Paint, cx: float, foot: float, h: float, canopy: bool = true) -> void:
	var w := h * 0.2
	var body := Paint.poly([Vector2(cx - w * 0.62, foot), Vector2(cx - w * 0.5, foot - h * 0.55), Vector2(cx - w * 0.36, foot - h * 0.8),
		Vector2(cx + w * 0.36, foot - h * 0.8), Vector2(cx + w * 0.5, foot - h * 0.55), Vector2(cx + w * 0.62, foot)])
	p.fill_poly(body, p.flat(STONE_L.lightened(0.05), 0.08))
	Ink.shade(p, body, Vector2(cx - w * 0.6, 0), Vector2(cx + w * 0.6, 0), 0.0, 0.35)
	for k in 3:
		var fx := cx + (k - 1) * w * 0.28
		Ink.line(p, Vector2(fx, foot - h * 0.7), Vector2(fx + (k - 1) * w * 0.1, foot - 1), 0.9, Color("#3a342c"), 0.6, 0.3)
	Ink.path(p, body, 1.2)
	var head := circle(Vector2(cx, foot - h * 0.88), w * 0.3, 14)
	p.fill_poly(head, p.flat(STONE_L.lightened(0.08), 0.05))
	Ink.path(p, head, 1.0)
	if canopy:
		var c := arch_pts(cx, foot - h * 1.02, w * 1.5, w * 1.1, 8)
		p.fill_poly(c, p.flat(STONE.darkened(0.05), 0.06))
		Ink.path(p, c, 1.2, false)
	var plinth := Paint.rect_poly(cx - w * 0.7, foot, w * 1.4, h * 0.08)
	p.fill_poly(plinth, p.flat(STONE_D, 0.05))
	Ink.path(p, plinth, 1.0)


## 첨두창 + 트레이서리(두 갈래 창 + 위 네잎 원) + 색유리. lit = 안쪽 불빛.
static func tracery_window(p: Paint, cx: float, base: float, w: float, h: float, lit: bool, seed_i: int = 0) -> void:
	var frame := arch_pts(cx, base, w + 8, h + 6)
	p.fill_poly(frame, p.flat(STONE_D, 0.06))
	Ink.path(p, frame, 1.6)
	var glass := arch_pts(cx, base, w, h)
	p.fill_poly(glass, func(x: int, y: int) -> Color:
		var k := int(Paint.hash01(x / 5, y / 6, seed_i) * GLASS.size()) % GLASS.size()
		var c: Color = GLASS[k]
		c = c.lerp(Color("#b8924a"), 0.35) if lit else c
		c = c.lightened(0.12 * (1.0 - clampf((y - (base - h)) / h, 0.0, 1.0)))  # 위가 하늘빛을 조금 받는다
		if posmod(x, 5) == 0 or posmod(y, 6) == 0:
			c = Color("#141210")
		return c)
	if lit:
		Ink.glow(p, cx, base - h * 0.5, w * 1.2, Color("#e8b860"), 0.25)
	var mid := base - h * 0.42
	Ink.line(p, Vector2(cx, base), Vector2(cx, mid), 2.2, STONE_D, 1.0, 0.1)  # 가운데 창살 기둥
	for s: float in [-1.0, 1.0]:
		var sub := arch_pts(cx + s * w * 0.25, mid, w * 0.5, h * 0.2, 8)
		Ink.path(p, sub, 2.0, false, STONE_D, 1.0, 0.1)
	var ring := circle(Vector2(cx, mid - h * 0.2), w * 0.2, 16)
	Ink.path(p, ring, 2.0, true, STONE_D, 1.0, 0.1)
	for k in 4:  # 네잎
		var a := TAU * k / 4.0 + PI * 0.25
		Ink.path(p, circle(Vector2(cx, mid - h * 0.2) + Vector2.from_angle(a) * w * 0.08, w * 0.07, 10), 1.2, true, STONE_D, 0.9, 0.1)
	Ink.path(p, glass, 1.4)
	var sill := Paint.rect_poly(cx - w * 0.5 - 6, base, w + 12, 5)
	p.fill_poly(sill, p.flat(STONE_L, 0.06))
	Ink.path(p, sill, 1.0)


## 장미창(바깥 돌 고리 · 잎 홈 · 열두 살 · 안 고리 · 색유리).
static func rose(p: Paint, c: Vector2, r: float, lit: bool) -> void:
	var outer := circle(c, r * 1.14, 40)
	p.fill_poly(outer, p.flat(STONE_L, 0.06))
	Ink.shade(p, outer, c - Vector2(r, r), c + Vector2(r, r), 0.0, 0.3)
	Ink.path(p, outer, 1.8)
	for k in 24:  # 고리의 잎 홈
		var a := TAU * k / 24.0
		Ink.path(p, circle(c + Vector2.from_angle(a) * r * 1.07, r * 0.045, 8), 1.0, true, STONE_D, 0.8, 0.1)
	var glass := circle(c, r, 40)
	p.fill_poly(glass, func(x: int, y: int) -> Color:
		var d := (Vector2(x, y) - c)
		var ang := fposmod(d.angle(), TAU)
		var ring := int(d.length() / (r * 0.22))
		var k := (int(ang / (TAU / 12.0)) + ring) % GLASS.size()
		var col: Color = GLASS[k]
		return col.lerp(Color("#b8924a"), 0.14) if lit else col)
	for k in 12:
		var a := TAU * k / 12.0
		Ink.line(p, c + Vector2.from_angle(a) * r * 0.24, c + Vector2.from_angle(a) * r, 2.6, STONE_D, 1.0, 0.1)
		Ink.path(p, circle(c + Vector2.from_angle(a + TAU / 24.0) * r * 0.72, r * 0.14, 12), 1.6, true, STONE_D, 1.0, 0.1)
	var hub := circle(c, r * 0.24, 20)
	p.fill_poly(hub, p.flat(STONE_L, 0.05))
	Ink.path(p, hub, 1.6)
	Ink.path(p, circle(c, r * 0.1, 12), 1.2, true, STONE_D)
	if lit:
		Ink.glow(p, c.x, c.y, r * 1.2, Color("#e8b860"), 0.1)
	Ink.path(p, glass, 1.6)


## 돌림띠(위 그늘 · 아래 작은 아치 띠).
static func course(p: Paint, x: float, y: float, w: float, corbels: bool) -> void:
	var band := Paint.rect_poly(x, y, w, 7)
	p.fill_poly(band, p.flat(STONE_L, 0.06))
	Ink.path(p, band, 1.2)
	Ink.shade(p, Paint.rect_poly(x, y + 7, w, 9), Vector2(0, y + 7), Vector2(0, y + 16), 0.4, 0.0)
	if corbels:
		var step := F.P * 0.18
		var xx := x + step * 0.5
		while xx < x + w - step * 0.4:
			var a := arch_pts(xx, y + 16, step * 0.8, step * 0.5, 6)
			Ink.path(p, a, 1.0, false, Color("#3a342c"), 0.8, 0.1)
			xx += step


## 모서리 돌(긴 돌 · 짧은 돌 번갈아 — 탑 · 정면 끝).
static func quoins(p: Paint, r: Rect2) -> void:
	var bh := F.P * 0.16
	var y := r.end.y
	var k := 0
	while y > r.position.y + bh:
		for side: float in [0.0, 1.0]:
			var bw := F.P * (0.34 if k % 2 == 0 else 0.2)
			var x := r.position.x if side == 0.0 else r.end.x - bw
			var q := Paint.rect_poly(x, y - bh, bw, bh - 1)
			p.fill_poly(q, p.flat(STONE_L.lightened(0.04), 0.06))
			Ink.path(p, q, 1.0)
		y -= bh
		k += 1


## 서쪽 정면(정문 · 왕의 회랑 · 장미창).
static func front() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		var P := F.P
		Parts.wall(p, poly, _ashlar(p))
		quoins(p, r)
		var cx := r.get_center().x
		var g := r.end.y
		# 정문: 바깥 아치 폭 2.4칸 → 안 1.15칸, 띠 다섯 · 문간 조각상 셋씩
		var pw := minf(r.size.x * 0.62, P * 2.4)
		var ph := P * 2.7
		var dw := P * 1.0
		var dh := P * 1.55
		var porch := arch_pts(cx, g, pw + 10, ph + 8)
		p.fill_poly(porch, p.flat(DEEP, 0.04))
		archivolts(p, cx, g - P * 0.0, pw, ph, dw + P * 0.2, dh + P * 0.6, 5)
		for s: float in [-1.0, 1.0]:
			for k in 3:
				var fx := cx + s * (dw * 0.5 + P * 0.18 + k * (pw - dw) * 0.15)
				figure(p, fx, g - P * 0.22, P * 0.95)
		var tym := arch_pts(cx, g - dh, dw + P * 0.2, dh * 0.0 + P * 0.62, 12)
		p.fill_poly(tym, p.flat(STONE_L, 0.06))
		Ink.path(p, tym, 1.4, false)
		var mand := Paint.poly([Vector2(cx, g - dh - P * 0.58), Vector2(cx + P * 0.16, g - dh - P * 0.3), Vector2(cx, g - dh - P * 0.04), Vector2(cx - P * 0.16, g - dh - P * 0.3)])
		p.fill_poly(mand, p.flat(Color("#c8b47a"), 0.06))
		Ink.path(p, mand, 1.0)
		figure(p, cx, g - dh - P * 0.08, P * 0.42, false)
		for s: float in [-1.0, 1.0]:
			for k in 2:
				figure(p, cx + s * P * (0.26 + k * 0.14), g - dh - P * 0.06, P * 0.26 - k * P * 0.04, false)
		var lintel := Paint.rect_poly(cx - dw * 0.55, g - dh - 6, dw * 1.1, 8)
		p.fill_poly(lintel, p.flat(STONE_D, 0.05))
		Ink.path(p, lintel, 1.2)
		for s: float in [-1.0, 1.0]:  # 문짝 둘(판자 · 쇠 소용돌이 경첩)
			var leaf := Paint.rect_poly(cx + (0.0 if s > 0 else -dw * 0.5), g - dh, dw * 0.5, dh)
			p.fill_poly(leaf, Mat.planks(p, WOOD, int(cx), 0, true, int(P * 0.08)))
			Ink.shade(p, leaf, Vector2(0, g - dh), Vector2(0, g), 0.45, 0.1)
			for hy: float in [0.22, 0.62]:
				var y0 := g - dh + dh * hy
				var xa := cx + s * dw * 0.48
				Ink.line(p, Vector2(xa, y0), Vector2(cx + s * dw * 0.06, y0), 3.0, IRON, 1.0, 0.2)
				Ink.path(p, circle(Vector2(cx + s * dw * 0.14, y0 - 6), 6, 10), 1.6, false, IRON)
				Ink.path(p, circle(Vector2(cx + s * dw * 0.24, y0 + 6), 5, 10), 1.6, false, IRON)
			Ink.path(p, leaf, 1.2)
		var trumeau := Paint.rect_poly(cx - 4, g - dh, 8, dh)
		p.fill_poly(trumeau, p.flat(STONE_L, 0.05))
		Ink.path(p, trumeau, 1.0)
		Ink.glow(p, cx, g - 4, P * 0.5, Color("#ffb45c"), 0.25)
		# 왕의 회랑: 작은 아치 벽감 + 조각상
		var gy := g - ph - P * 0.42
		course(p, r.position.x, gy + P * 0.06, r.size.x, true)
		var n := maxi(5, int(r.size.x / (P * 0.42)))
		for k in n:
			var nx := r.position.x + r.size.x * (k + 0.5) / n
			var niche := arch_pts(nx, gy, P * 0.3, P * 0.62, 8)
			p.fill_poly(niche, p.flat(DEEP.lightened(0.08), 0.05))
			Ink.path(p, niche, 1.2, false)
			figure(p, nx, gy - P * 0.04, P * 0.5, false)
		course(p, r.position.x, gy - P * 0.72, r.size.x, false)
		# 장미창 + 양옆 첨두창
		var rr := minf(r.size.x * 0.2, P * 0.78)
		var rc := Vector2(cx, gy - P * 0.74 - rr * 1.18)
		if rc.y - rr > r.position.y + P * 0.2:
			rose(p, rc, rr, true)
			for s: float in [-1.0, 1.0]:
				tracery_window(p, cx + s * (rr + P * 0.55), rc.y + rr, P * 0.42, rr * 1.8, false, int(s + 3))
		course(p, r.position.x, r.position.y + P * 0.12, r.size.x, true)


## 정면 박공(삼각 — rose면 가운데 장미창, 아니면 장식 아치 셋 · 빗변 잎 장식 · 꼭대기 십자).
static func gable(with_rose: bool = false) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		var P := F.P
		Parts.wall(p, poly, _ashlar(p))
		var cx := r.get_center().x
		if with_rose:
			var rr := minf(r.size.y * 0.36, r.size.x * 0.17)
			rose(p, Vector2(cx, r.end.y - rr * 1.25), rr, true)
		else:
			for k in 3:
				var w := r.size.x * 0.13
				var x := cx + (k - 1) * w * 1.3
				var h := r.size.y * (0.55 if k == 1 else 0.38)
				var a := arch_pts(x, r.end.y - P * 0.1, w, h, 10)
				p.fill_poly(a, p.flat(DEEP.lightened(0.1), 0.05))
				Ink.path(p, a, 1.4, false)
				Ink.line(p, Vector2(x, r.end.y - P * 0.1), Vector2(x, r.end.y - P * 0.1 - h * 0.6), 1.6, STONE_D, 1.0, 0.1)
		for i in poly.size():  # 빗변의 잎 장식(작은 둥근 혹)
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if absf(a.y - b.y) < 4.0:
				continue
			var L := a.distance_to(b)
			var m := int(L / (P * 0.3))
			for j in range(1, m):
				var q := a.lerp(b, float(j) / m)
				var leaf := circle(q + Vector2(0, -4), 6, 8)
				p.fill_poly(leaf, p.flat(STONE_L, 0.06))
				Ink.path(p, leaf, 1.0)
		var top := Vector2(cx, r.position.y + 6)
		Ink.line(p, top, top + Vector2(0, 26), 4.0, STONE_D, 1.0, 0.1)
		Ink.line(p, top + Vector2(-9, 9), top + Vector2(9, 9), 4.0, STONE_D, 1.0, 0.1)


## 종탑 면: 모서리 돌 · 층마다 돌림띠 · 쌍 첨두창 · 맨 위 종루 덧창 · 홈통 괴물.
static func tower(floors: int, lit_i: int = 0) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		var P := F.P
		Parts.wall(p, poly, _ashlar(p))
		quoins(p, r)
		var fh := F.storey * P
		var cx := r.get_center().x
		var y := r.end.y
		var fl := 0
		while y - fh * 1.6 > r.position.y:
			var hh := fh * 1.6
			var top := y - hh
			if y - hh * 2.0 <= r.position.y:  # 맨 위 = 종루(길쭉한 덧창 둘)
				for s: float in [-1.0, 1.0]:
					var bw := r.size.x * 0.22
					var bx := cx + s * bw * 0.65
					var o := arch_pts(bx, y - P * 0.15, bw, hh * 0.85, 10)
					p.fill_poly(o, p.flat(DEEP, 0.04))
					var slat := y - P * 0.25
					while slat > y - hh * 0.62:
						Ink.line(p, Vector2(bx - bw * 0.45, slat), Vector2(bx + bw * 0.45, slat - 3), 3.0, Color("#4a3a2a"), 1.0, 0.1)
						slat -= 9.0
					Ink.path(p, o, 1.6)
			elif fl > 0:
				for s: float in [-1.0, 1.0]:
					tracery_window(p, cx + s * r.size.x * 0.18, y - P * 0.2, r.size.x * 0.2, hh * 0.7, (fl + lit_i) % 3 == 0, fl * 7 + int(s + 2))
			else:  # 맨 아래 = 막힌 아치 줄(벽에 새긴 아치)
				var m := 4
				for k in m:
					var ax := r.position.x + r.size.x * (k + 0.5) / m
					var a := arch_pts(ax, y - P * 0.12, r.size.x / m * 0.7, hh * 0.72, 10)
					p.fill_poly(a, p.flat(STONE.darkened(0.18), 0.06))
					Ink.shade(p, a, Vector2(0, y - hh * 0.8), Vector2(0, y), 0.35, 0.0)
					Ink.path(p, a, 1.2, false)
			course(p, r.position.x, top, r.size.x, true)
			y = top
			fl += 1
		for s: float in [0.0, 1.0]:  # 홈통 괴물(맨 위 모서리)
			var gx := r.position.x + (P * 0.1 if s == 0.0 else r.size.x - P * 0.1)
			var gp := Paint.poly([Vector2(gx - 8, r.position.y + P * 0.3), Vector2(gx + 8, r.position.y + P * 0.3), Vector2(gx + 4, r.position.y + P * 0.5), Vector2(gx - 4, r.position.y + P * 0.5)])
			p.fill_poly(gp, p.flat(STONE_D, 0.05))
			Ink.path(p, gp, 1.0)


## 본당 · 옆 회랑 옆면: 버팀 기둥 · 기둥 사이 트레이서리 창 · 처마 아치 띠 · 뚫린 난간.
static func nave(tall: bool) -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		var r := Paint.bounds(poly)
		var P := F.P
		Parts.wall(p, poly, _ashlar(p))
		var bay := P * 1.3
		var n := maxi(1, int(r.size.x / bay))
		var bw := r.size.x / n
		for k in n + 1:
			var x := r.position.x + k * bw
			var pil := Paint.rect_poly(x - P * 0.09, r.position.y + P * 0.2, P * 0.18, r.size.y - P * 0.2)
			p.fill_poly(pil, p.flat(STONE_L, 0.06))
			Ink.shade(p, pil, Vector2(x - P * 0.09, 0), Vector2(x + P * 0.09, 0), 0.0, 0.35)
			Ink.path(p, pil, 1.2)
		for k in n:
			var cx := r.position.x + (k + 0.5) * bw
			var h := r.size.y * (0.62 if tall else 0.55)
			tracery_window(p, cx, r.end.y - r.size.y * 0.16, minf(bw * 0.5, P * 0.6), h, k % 2 == 0, k + (5 if tall else 9))
		course(p, r.position.x, r.position.y + P * 0.16, r.size.x, true)
		var q := r.position.x + P * 0.15  # 뚫린 난간(네잎 구멍 줄)
		while q < r.end.x - P * 0.1:
			Ink.path(p, circle(Vector2(q, r.position.y + P * 0.07), P * 0.05, 10), 1.0, true, DEEP)
			q += P * 0.17


## 첨탑 면(점판암 + 가운데 줄 · 모서리 잎 장식).
static func spire() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, Mat.slate(p, Color("#4a4c52"), 0, 0, int(F.P * 0.12), int(F.P * 0.08), 0.15))
		var r := Paint.bounds(poly)
		Ink.shade(p, poly, r.position, Vector2(r.end.x, r.position.y), 0.0, 0.25)
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if absf(a.y - b.y) < 4.0:
				continue
			var m := int(a.distance_to(b) / (F.P * 0.34))
			for j in range(1, m):
				var leaf := circle(a.lerp(b, float(j) / m), 3.5, 7)
				p.fill_poly(leaf, p.flat(Color("#5e5a54"), 0.06))
				Ink.path(p, leaf, 0.8)
		Ink.path(p, poly, 1.6)
