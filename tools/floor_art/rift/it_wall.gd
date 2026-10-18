extends RefCounted
## 강철의 묘 벽 바탕(it.gd가 부른다): 부조 강철벽 · 깃발 벽 · 감실 벽 · 거대 원기둥 · 강철 문 · 거대 강철 관 · 금 상감 벽화.
## 윗면(top) = 위에서 본 벽 머리, 앞면(face) = 남쪽을 보는 면(아래 skirt px는 들쭉날쭉 투명하게 끝난다).
## 바탕은 좌표 함수 + 주기 잡음만(시드와 무관한 구조) — 변형끼리 가장자리가 맞는다.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Seam := preload("res://tools/floor_art/Seam.gd")
const Common := preload("res://tools/floor_art/rift/Common.gd")
const L := preload("res://tools/floor_art/rift/it_lib.gd")

const SIGIL := Color("#170606")
const HEM := Color("#8a7038")


static func base(p: Paint, style: String, part: String, col: Color, s: int) -> void:
	if part == "top":
		_top(p, style, col, s)
	else:
		_face(p, style, col, s)


# ── 앞면 ────────────────────────────────────────────────

static func _face(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var sk := Common.skirt
	var main := float(h - sk)
	var hf := Seam.field(w, h, s, 0.06, 3)
	var fine := Seam.field(w, h, s + 1, 0.25, 2)
	var st := Seam.field(w, h, s + 2, 0.05, 3)
	var jag := Seam.field(w, 8, s + 9, 0.12, 3)
	for y in h:
		for x in w:
			var foot := L.foot_y(main, sk, jag[x])
			if y >= foot:
				continue
			var i := y * w + x
			var fx := x + 0.5
			var fy := y + 0.5
			var tex := (hf[i] - 0.5) * 0.55 + Seam.relief(hf, w, h, x, y, 4.0) * 0.35 + (fine[i] - 0.5) * 0.16
			var c: Color
			match style:
				"muralwall", "mural", "bannerwall":
					c = _steel_wall(style, col, fx, fy, w, u, tex)
				"niche":
					c = _niche(col, fx, fy, w, u, tex)
				"pillar":
					c = _pillar(col, fx, fy, w, u, tex)
				"steeldoor":
					c = _door(col, fx, fy, w, u, tex)
				"coffin":
					c = _coffin_side(col, fx, fy, w, u, tex)
				_:
					c = col
			if st[i] > 0.62 and style != "bannerwall":  # 흘러내린 때
				c = c.lerp(Color("#121418"), (st[i] - 0.62) * 1.1)
			c = c.darkened(smoothstep(main * 0.6, foot, fy) * 0.3)  # 바닥 쪽 그늘
			if fy >= main:
				c = c.darkened(0.2)
			if foot - fy < 1.6 and sk > 0:
				c = c.lerp(Ink.INK, 0.65)
			p.blend(x, y, c, 1.0)


## 강철벽 공통 틀: 윗 턱 · 리벳 줄 · 새긴 가로선 둘 · 아래 굽도리. mural은 가운데 금빛 판, bannerwall은 깃발.
static func _steel_wall(style: String, col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var steel := col
	if style == "mural":
		steel = L.STEEL.lerp(col, 0.35)
	elif style == "bannerwall":
		steel = Color("#3a3c42")
	var streak := sin((fx + tex * 8.0) * 1.4 / u) * 0.03
	var c := steel.darkened(0.35).lerp(steel.lightened(0.18), clampf(0.5 + tex + streak, 0.0, 1.0))
	if fy < 4.0 * u:  # 윗 턱(빛 받는 모서리)
		c = c.lightened(0.18 + (0.15 if fy < 1.5 * u else 0.0))
	elif fy < 5.0 * u:
		c = c.lerp(Ink.INK, 0.75)
	elif fy < 8.0 * u:
		c = c.darkened(0.3 * (1.0 - (fy - 5.0 * u) / (3.0 * u)))
	c = L.groove(c, fy - 13.0 * u, 1.2 * u, 0.9)
	c = L.groove(c, fy - 37.0 * u, 1.2 * u, 0.9)
	if fy > 41.0 * u:  # 굽도리
		c = c.darkened(0.15)
		if fy < 42.0 * u:
			c = c.lerp(Ink.INK, 0.6)
		elif fy < 43.5 * u:
			c = c.lightened(0.2)
	if fx < 1.0 * u or fx > w - 1.0 * u:  # 판 이음매
		c = c.lerp(Ink.INK, 0.55)
	for rx: float in [8.0, 24.0, 40.0, 56.0]:
		c = L.rivet(c, int(fx), int(fy), Vector2(rx, 9.0) * u, 1.7 * u)
		c = L.rivet(c, int(fx), int(fy), Vector2(rx, 45.5) * u, 1.5 * u)
	if style == "mural":
		var a := 6.0 * u
		var b := w - 6.0 * u
		if fx > a and fx < b and fy > 15.0 * u and fy < 35.5 * u:
			var g := col.darkened(0.35).lerp(col.lightened(0.05), clampf(0.5 + tex * 0.8, 0.0, 1.0))
			g = g.lerp(Color("#3a4a3a"), clampf(tex * -1.2, 0.0, 0.35))  # 녹청
			c = L.recess(g, fx - a, fy - 15.0 * u, b - fx, 35.5 * u - fy, 2.5 * u)
	if style == "bannerwall":
		c = _banner(c, col, fx, fy, w, u, tex)
	return c


## 깃발: 막대 + 제비꼬리 천 + 금실 단 + 추상 문장(고리를 꿰뚫은 칼 + 두 날개).
static func _banner(c: Color, col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var x0 := 9.0 * u
	var x1 := w - 9.0 * u
	var cx := w * 0.5
	var ax := absf(fx - cx)
	var bottom := 47.0 * u - 6.0 * u * absf(ax - 11.5 * u) / (11.5 * u)
	if fy > 3.0 * u and fy < 6.0 * u and fx > 4.0 * u and fx < w - 4.0 * u:  # 쇠 막대
		var t := (fy - 3.0 * u) / (3.0 * u)
		return Color("#2a2a2e").lerp(Color("#8a8a90"), clampf(0.8 - t, 0.0, 1.0)).lerp(Ink.INK, 0.5 if t > 0.85 else 0.0)
	for kx: float in [5.5, 58.5]:
		var d := Vector2(fx - kx * u, fy - 4.5 * u).length()
		if d < 2.4 * u:
			var n := (Vector2(fx - kx * u, fy - 4.5 * u)) / (2.4 * u)
			return HEM.darkened(0.4).lerp(Color("#d8c080"), clampf(0.5 - n.x * 0.5 - n.y * 0.5, 0.0, 1.0))
	if fx > x1 and fx < x1 + 2.5 * u and fy > 6.0 * u and fy < bottom + 1.0 * u:  # 천이 드리운 그늘
		return c.darkened(0.45)
	if fx < x0 or fx > x1 or fy < 6.0 * u or fy > bottom:
		return c
	var fold := sin((fx - x0) / (x1 - x0) * TAU * 2.5 + 0.4)
	var t := 0.5 + fold * 0.18 + tex * 0.5 - (fy / (bottom)) * 0.12
	var cl := col.darkened(0.45).lerp(col.lightened(0.15), clampf(t, 0.0, 1.0))
	if fy < 9.0 * u:  # 윗단 금실
		cl = HEM.darkened(0.25).lerp(HEM.lightened(0.1), clampf(0.5 + fold * 0.3, 0.0, 1.0))
	if absf(fx - (x0 + 2.2 * u)) < 0.7 * u or absf(fx - (x1 - 2.2 * u)) < 0.7 * u:
		cl = cl.lerp(HEM, 0.55)
	if absf(fy - (bottom - 2.2 * u)) < 0.7 * u:
		cl = cl.lerp(HEM, 0.5)
	cl = cl.lerp(SIGIL, _sigil(fx - cx, fy - 25.0 * u, u) * 0.85)
	var edge := minf(minf(fx - x0, x1 - fx), bottom - fy)
	if edge < 0.9 * u:
		cl = cl.lerp(Ink.INK, 0.7)
	return cl


## 문장 덮임(0~1): 고리 + 세로 칼(칼자루·가로막이) + 아래로 벌린 두 날개.
static func _sigil(dx: float, dy: float, u: float) -> float:
	var r := Vector2(dx, dy).length()
	var cov := clampf(1.6 * u - absf(r - 6.5 * u), 0.0, 1.0)
	cov = maxf(cov, _seg(Vector2(dx, dy), Vector2(0, -12) * u, Vector2(0, 11) * u, 1.0 * u))
	cov = maxf(cov, _seg(Vector2(dx, dy), Vector2(-4, -8) * u, Vector2(4, -8) * u, 0.9 * u))
	for sgn: float in [-1.0, 1.0]:
		cov = maxf(cov, _seg(Vector2(dx, dy), Vector2(sgn * 5.5, 5) * u, Vector2(sgn * 13, -2) * u, 1.0 * u))
		cov = maxf(cov, _seg(Vector2(dx, dy), Vector2(sgn * 6.5, 8) * u, Vector2(sgn * 13, 3) * u, 0.8 * u))
	return cov


static func _seg(q: Vector2, a: Vector2, b: Vector2, r: float) -> float:
	var ab := b - a
	var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return clampf(r + 0.5 - q.distance_to(a + ab * t), 0.0, 1.0)


## 감실 벽: 마름돌 쌓기 + 가운데 둥근 아치 감실(안은 깊은 그늘, 오른쪽 안벽이 빛을 받음) + 빛 받는 문턱.
static func _niche(col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var c := col.darkened(0.35).lerp(col.lightened(0.25), clampf(0.5 + tex, 0.0, 1.0))
	if fy < 5.0 * u:
		c = c.lightened(0.15 if fy > 1.5 * u else 0.3)
		if fy > 4.0 * u:
			c = c.lerp(Ink.INK, 0.7)
		return c
	var rows: Array[float] = [5.0, 17.0, 29.0, 41.0, 48.0]
	var k := 0
	while k < 3 and fy >= rows[k + 1] * u:
		k += 1
	var y0 := rows[k] * u
	var y1 := rows[k + 1] * u
	var span := 32.0 * u
	var lx := fposmod(fx - (0.0 if k % 2 == 0 else 16.0) * u, span)
	c = L.bevel(c, lx, fy - y0, span - lx, y1 - fy, 2.0 * u, 0.9 * u)
	# 감실
	var cx := w * 0.5
	var ac := Vector2(cx, 21.0 * u)
	var rr := 12.0 * u
	var inside := absf(fx - cx) < rr and fy < 38.0 * u and (fy > ac.y or Vector2(fx, fy).distance_to(ac) < rr)
	var ring := absf(fx - cx) < rr + 3.0 * u and fy < 38.0 * u and (fy > ac.y or Vector2(fx, fy).distance_to(ac) < rr + 3.0 * u)
	if inside:
		var g := (fx - (cx - rr)) / (2.0 * rr)
		var ic := Color("#08090b").lerp(col.darkened(0.3), pow(g, 2.5) * 0.7)
		if fy < ac.y + 4.0 * u:
			ic = ic.darkened(0.3)
		var d := minf(rr - absf(fx - cx), (rr - Vector2(fx, fy).distance_to(ac)) if fy < ac.y else 99.0)
		if d < 1.0 * u:
			ic = ic.lerp(Ink.INK, 0.8)
		return ic
	if ring:
		c = col.lightened(0.05).lerp(col.lightened(0.3), clampf(0.5 + tex, 0.0, 1.0))
		var od := minf(rr + 3.0 * u - absf(fx - cx), (rr + 3.0 * u - Vector2(fx, fy).distance_to(ac)) if fy < ac.y else 99.0)
		if od < 0.9 * u:
			c = c.lerp(Ink.INK, 0.7)
	if fy > 38.0 * u and fy < 41.0 * u and absf(fx - cx) < rr + 3.0 * u:  # 문턱
		c = col.lightened(0.3).lerp(c, 0.3)
		if fy > 40.2 * u:
			c = c.lerp(Ink.INK, 0.6)
	return c


## 거대 원기둥(칸 하나 = 기둥 몸 하나, 이웃 칸과 붙으면 겹기둥): 머리판 · 쇠띠 둘 · 북돌 이음 · 둥근 굽 · 받침.
static func _pillar(col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var nx := (fx - w * 0.5) / (w * 0.5)
	var arc := 2.5 * u * sqrt(maxf(0.0, 1.0 - nx * nx))
	var c := L.shade_round(col.lightened(0.15), nx * 0.97, false)
	c = c.lerp(c.lightened(0.2), clampf(tex, -0.5, 0.5))
	if fy < 9.0 * u:  # 머리판(네모 — 칸 폭 전체)
		c = col.darkened(0.2).lerp(col.lightened(0.25), clampf(0.55 + tex - fx / w * 0.2, 0.0, 1.0))
		if fy < 1.5 * u:
			c = c.lightened(0.2)
		if fy > 8.0 * u:
			c = c.lerp(Ink.INK, 0.75)
		return c
	if fy < 12.0 * u:
		c = c.darkened(0.35)
	for band: float in [12.0, 86.0]:
		var by := band * u + arc
		if fy > by and fy < by + 5.0 * u:
			var m := L.shade_round(L.STEEL, nx * 0.97, true)
			if fy < by + 0.9 * u or fy > by + 4.1 * u:
				m = m.lerp(Ink.INK, 0.6)
			for rx: float in [-0.6, 0.0, 0.6]:
				m = L.rivet(m, int(fx), int(fy), Vector2(w * 0.5 + rx * w * 0.5, by + 2.5 * u), 1.2 * u)
			return m
		if fy >= by + 5.0 * u and fy < by + 7.0 * u:
			c = c.darkened(0.25)
	for j: float in [40.0, 64.0]:
		c = L.groove(c, fy - (j * u + arc), 1.0 * u, 0.7)
	if fy > 98.0 * u + arc * 0.5 and fy < 106.0 * u:  # 둥근 굽(위가 밝다)
		var t := (fy - 98.0 * u) / (8.0 * u)
		c = L.shade_round(col.lightened(0.2), nx * 0.97, false).lightened(0.2 * (1.0 - t * 2.0))
		if t < 0.12:
			c = c.lerp(Ink.INK, 0.5)
	if fy >= 106.0 * u:  # 네모 받침
		c = col.darkened(0.25).lerp(col.lightened(0.1), clampf(0.5 + tex, 0.0, 1.0))
		if fy < 107.0 * u:
			c = c.lerp(Ink.INK, 0.7)
		elif fy < 108.5 * u:
			c = c.lightened(0.2)
	if absf(nx) > 0.985:
		c = c.lerp(Ink.INK, 0.6)
	return c


## 거대 강철 문: 돌 상인방 · 선 띠(양옆) · 가로 띠 셋 · 들어간 판 둘 · 리벳.
static func _door(col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var streak := sin((fx + tex * 9.0) * 1.2 / u) * 0.03
	var c := col.darkened(0.42).lerp(col.lightened(0.08), clampf(0.5 + tex + streak, 0.0, 1.0))
	if fy < 8.0 * u:  # 상인방 돌
		var sc := Color("#3a3c42").lerp(Color("#62646a"), clampf(0.5 + tex, 0.0, 1.0))
		if fy < 1.5 * u:
			sc = sc.lightened(0.2)
		if fy > 7.0 * u:
			sc = sc.lerp(Ink.INK, 0.8)
		return sc
	var a := 5.0 * u
	var b := w - 5.0 * u
	if fx < a or fx > b:
		var lx := fx if fx < a else fx - b
		c = L.bevel(c.lightened(0.05), lx, fy - 8.0 * u, a - lx, 96.0 * u - fy, 1.6 * u, 0.8 * u)
		for ry: float in [20.0, 31.0, 42.0, 60.0, 71.0, 82.0]:
			c = L.rivet(c, int(fx), int(fy), Vector2((2.5 if fx < a else 61.5), ry) * u, 1.3 * u)
		return c
	var rails: Array[Vector2] = [Vector2(8, 14), Vector2(48, 54), Vector2(88, 96)]
	for r in rails:
		if fy >= r.x * u and fy < r.y * u:
			c = L.bevel(c.lightened(0.04), fx - a, fy - r.x * u, b - fx, r.y * u - fy, 1.6 * u, 0.8 * u)
			for rx: float in [11.0, 21.0, 43.0, 53.0]:
				c = L.rivet(c, int(fx), int(fy), Vector2(rx, (r.x + r.y) * 0.5) * u, 1.4 * u)
			return c
	var p0 := 14.0 if fy < 48.0 * u else 54.0
	var p1 := 48.0 if fy < 48.0 * u else 88.0
	return L.recess(c.darkened(0.08), fx - a, fy - p0 * u, b - fx, p1 * u - fy, 3.0 * u)


## 거대 강철 관 옆면: 뚜껑 턱 · 그 밑 그늘 · 리벳 줄 · 새긴 띠 · 굽.
static func _coffin_side(col: Color, fx: float, fy: float, w: int, u: float, tex: float) -> Color:
	var streak := sin((fx + tex * 7.0) * 1.3 / u) * 0.03
	var c := col.darkened(0.42).lerp(col.lightened(0.05), clampf(0.5 + tex + streak, 0.0, 1.0))
	if fy < 6.0 * u:
		c = c.lightened(0.12 + (0.18 if fy < 1.5 * u else 0.0))
		if fy > 5.0 * u:
			c = c.lerp(Ink.INK, 0.8)
		return c
	if fy < 9.0 * u:
		c = c.darkened(0.4 * (1.0 - (fy - 6.0 * u) / (3.0 * u)))
	c = L.groove(c, fy - 17.0 * u, 1.2 * u, 0.9)
	c = L.groove(c, fy - 38.0 * u, 1.2 * u, 0.9)
	if fy > 42.0 * u:
		c = c.darkened(0.18)
		if fy < 43.0 * u:
			c = c.lerp(Ink.INK, 0.6)
		elif fy < 44.5 * u:
			c = c.lightened(0.18)
	for rx: float in [8.0, 24.0, 40.0, 56.0]:
		c = L.rivet(c, int(fx), int(fy), Vector2(rx, 12.0) * u, 1.6 * u)
	return c


# ── 윗면 ────────────────────────────────────────────────

static func _top(p: Paint, style: String, col: Color, s: int) -> void:
	var w := p.w
	var h := p.h
	var u := w / 64.0
	var hf := Seam.field(w, h, s, 0.05, 3)
	var fine := Seam.field(w, h, s + 1, 0.25, 2)
	for y in h:
		for x in w:
			var i := y * w + x
			var fx := x + 0.5
			var fy := y + 0.5
			var tex := (hf[i] - 0.5) * 0.45 + Seam.relief(hf, w, h, x, y, 4.0) * 0.35 + (fine[i] - 0.5) * 0.12
			var c := col.darkened(0.35).lerp(col.lightened(0.25), clampf(0.5 + tex, 0.0, 1.0))
			match style:
				"niche", "pillar":  # 돌
					var half := h * 0.5
					var row := 0 if fy < half else 1
					var lx := fx if row == 0 else fposmod(fx + w * 0.5, float(w))
					c = L.bevel(c, lx, fy - row * half, w - lx, half - (fy - row * half), 2.5 * u, 1.0 * u)
					if style == "pillar":
						var cd := Vector2(fx - w * 0.5, fy - h * 0.5).length()
						c = L.groove(c, cd - 20.0 * u, 1.0 * u, 0.4)
				"coffin":  # 마름모 격자 새김 + 마디 리벳
					var d1 := (fx - fy) / sqrt(2.0)
					var d2 := (fx + fy - w) / sqrt(2.0)
					c = L.groove(c, fposmod(d1 + w * 0.3536, w * 0.7071) - w * 0.3536, 1.2 * u, 0.8)
					c = L.groove(c, fposmod(d2 + w * 0.3536, w * 0.7071) - w * 0.3536, 1.2 * u, 0.8)
					for q: Vector2 in [Vector2(0, 0), Vector2(64, 0), Vector2(0, 64), Vector2(64, 64), Vector2(32, 32)]:
						c = L.rivet(c, x, y, q * u, 2.3 * u)
					for q: Vector2 in [Vector2(32, 0), Vector2(0, 32), Vector2(64, 32), Vector2(32, 64)]:
						c = L.rivet(c, x, y, q * u, 1.4 * u)
				_:  # 강철 머리판: 가로 새김 둘 + 리벳
					c = L.groove(c, fy - 8.0 * u, 1.2 * u, 0.8)
					c = L.groove(c, fy - 56.0 * u, 1.2 * u, 0.8)
					if fx < 1.0 * u or fx > w - 1.0 * u:
						c = c.lerp(Ink.INK, 0.5)
					for q: Vector2 in [Vector2(16, 4), Vector2(48, 4), Vector2(16, 60), Vector2(48, 60)]:
						c = L.rivet(c, x, y, q * u, 1.6 * u)
					if style == "bannerwall" and fy > 17.0 * u and fy < 47.0 * u:  # 넘겨 건 붉은 천
						var fold := sin(fx / w * TAU * 2.0)
						c = L.CRIMSON.darkened(0.35).lerp(L.CRIMSON.lightened(0.1), clampf(0.5 + fold * 0.2 + tex * 0.6, 0.0, 1.0))
						if absf(fy - 20.0 * u) < 0.8 * u or absf(fy - 44.0 * u) < 0.8 * u:
							c = c.lerp(HEM, 0.55)
						if fy < 18.0 * u or fy > 46.0 * u:
							c = c.lerp(Ink.INK, 0.6)
					if style == "mural" and absf(fy - 32.0 * u) < 1.2 * u:
						c = c.lerp(HEM.lightened(0.2), 0.6)
			p.blend(x, y, c, 1.0)
