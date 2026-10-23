extends RefCounted
## 소재 표면 무늬·둘레 장식(Style.surface · trim · glow): 이미 빚은 덩어리(그룹 g) 위, 다각형 poly 안에 새기거나 얹는다.
## surface: holes(뚫린 구멍) · damascus(물결 단조) · dents(망치 자국) · runes(새긴 글자) · scales · big_scales(비늘) · warts(혹) ·
##   grain(나뭇결) · web(거미줄) · patches(덧댄 조각) · cracks(갈라짐) · veins(핏줄·잎맥) · crescents(초승달) · stitch(바늘땀) ·
##   knots(옹이) · filigree(금실 무늬) · facets(깎은 면)
## trim: rivets(징) · bands(쇠띠) · bands_wood(나무 마디) · rope(감은 끈) · gold(금테) · fur(털) · leaves(잎) · spikes(가시) · patches
## glow 색이 있으면 새긴 줄(글자·핏줄·갈라짐·초승달)을 따라 빛이 스민다(없으면 표면 몇 곳에서 은은하게).

const Clay := preload("res://tools/monster_art/Clay.gd")


## blade = 날(칼날·도끼날·창날)이면 둘레 장식은 금테만(징·쇠띠는 날에 어울리지 않는다).
static func apply(ctx: Dictionary, g: int, poly: PackedVector2Array, style: Dictionary, blade: bool = false) -> void:
	if poly.size() < 3:
		return
	var lines := _surface(ctx, g, poly, str(style.get("surface", "none")))
	var trim := str(style.get("trim", "none"))
	if not blade or trim == "gold":
		_trim(ctx, g, poly, trim)
	var gc := str(style.get("glow", ""))
	if gc.is_empty():
		return
	var col := Color.from_string(gc, Color.WHITE)
	var w := maxf(1.2, float(ctx["W"]) / 55.0)
	for ln: Array in lines:
		for k in ln.size() - 1:
			ctx["lines"].append([ln[k], ln[k + 1], w, col])
	var r := _bounds(poly)
	for k in 3:
		var p := _pick(ctx, poly, r)
		if p.x >= 0.0:
			ctx["glows"].append([p, minf(r.size.x, r.size.y) * 0.5, col, 0.45])


## 무늬를 새기고, 빛이 스밀 줄 목록을 돌려준다.
static func _surface(ctx: Dictionary, g: int, poly: PackedVector2Array, kind: String) -> Array:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var r := _bounds(poly)
	var S := minf(r.size.x, r.size.y)
	var tall := r.size.y >= r.size.x
	var lines: Array = []
	match kind:
		"holes":  # 가벼운 쇠 — 긴 축을 따라 뚫린 구멍(뒤가 비친다)
			for k in 3:
				var t := 0.3 + k * 0.17
				var c := r.position + (Vector2(r.size.x * 0.5, r.size.y * (1.0 - t)) if tall else Vector2(r.size.x * t, r.size.y * 0.5))
				if Geometry2D.is_point_in_polygon(c, poly):
					cl.erase(g, c, S * 0.13, S * 0.2 if tall else S * 0.13, 0.0)
		"damascus":
			var n := int(r.size.y / maxf(4.0, S * 0.18)) if tall else 6
			for k in n:
				var pts: Array = []
				var y0 := r.position.y + r.size.y * (k + 0.5) / n
				for s in 9:
					var x := r.position.x + r.size.x * s / 8.0
					pts.append(Vector2(x, y0 + sin(s * 1.3 + k * 0.9) * S * 0.12))
				_grooves_in(cl, g, poly, pts, S * 0.035, S * 0.05)
		"dents":
			for k in int(6 + r.size.x * r.size.y / (S * S) * 1.5):
				var p := _pick(ctx, poly, r)
				if p.x >= 0.0:
					cl.carve(g, p, S * 0.09, S * 0.07, S * 0.06, rng.randf() * PI)
		"runes":
			var x := r.position.x + r.size.x * 0.5
			var y := r.position.y + r.size.y * 0.2
			while y < r.end.y - S * 0.4:
				var a := Vector2(x - S * 0.12, y)
				var b := Vector2(x + S * 0.12, y + S * 0.2)
				var c := Vector2(x - S * 0.06, y + S * 0.28)
				if Geometry2D.is_point_in_polygon(b, poly):
					var glyph := [a, b, c] if rng.randf() < 0.5 else [b, a, c]
					_grooves_in(cl, g, poly, glyph, S * 0.03, S * 0.05)
					lines.append(glyph)
				y += S * 0.42
		"scales", "big_scales":
			var sz := S * (0.16 if kind == "scales" else 0.26)
			var row := 0
			var y := r.position.y + sz * 0.5
			while y < r.end.y:
				var x := r.position.x + (sz * 0.5 if row % 2 == 1 else 0.0)
				while x < r.end.x:
					if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
						cl.bump(g, Vector2(x, y), sz * 0.55, sz * 0.4, sz * 0.06, _mat_at(ctx, g, x, y), 2.0)  # 납작한 비늘 판
						var arc: Array = []
						for s in 5:  # 비늘 아래 끝(겹친 자리)의 반달 골
							var a := PI * 0.15 + s * PI * 0.175
							arc.append(Vector2(x + cos(a) * sz * 0.5, y + sin(a) * sz * 0.38))
						_grooves_in(cl, g, poly, arc, sz * 0.06, sz * 0.1)
					x += sz
				y += sz * 0.7
				row += 1
		"warts":
			for k in int(5 + r.size.x * r.size.y / (S * S) * 2.0):
				var p := _pick(ctx, poly, r)
				if p.x >= 0.0:
					var rr := S * (0.05 + rng.randf() * 0.07)
					cl.bump(g, p, rr, rr * 0.9, rr * 0.6, _mat_at(ctx, g, p.x, p.y), 2.0)
		"grain":
			for k in 5:
				var pts: Array = []
				var u := (k + 0.5) / 5.0
				for s in 12:
					var v := s / 11.0
					var q := Vector2(u + sin(v * 7.0 + k) * 0.03, v) if tall else Vector2(v, u + sin(v * 7.0 + k) * 0.03)
					pts.append(r.position + q * r.size)
				_grooves_in(cl, g, poly, pts, S * 0.02, S * 0.03)
		"web":
			var o := r.position + Vector2(r.size.x * 0.15, r.size.y * 0.12)
			for k in 6:
				var a := PI * 0.05 + k * PI * 0.08
				_grooves_in(cl, g, poly, [o, o + Vector2(cos(a), sin(a)) * maxf(r.size.x, r.size.y)], S * 0.015, S * 0.025)
			for k in 4:
				var arc: Array = []
				for s in 8:
					var a := PI * 0.05 + s * PI * 0.06
					arc.append(o + Vector2(cos(a), sin(a)) * (k + 1) * S * 0.35)
				_grooves_in(cl, g, poly, arc, S * 0.012, S * 0.02)
		"patches":
			_patches(ctx, g, poly, r, S)
		"cracks":
			for k in 3:
				var p := _pick(ctx, poly, r)
				if p.x < 0.0:
					continue
				var pts: Array = [p]
				for s in 4:
					p += Vector2((rng.randf() - 0.5) * S * 0.5, (rng.randf() - 0.2) * S * 0.45)
					pts.append(p)
				_grooves_in(cl, g, poly, pts, S * 0.025, S * 0.06)
				lines.append(pts)
		"veins":
			var base := Vector2(r.position.x + r.size.x * 0.5, r.end.y - S * 0.1)
			for k in 4:
				var pts: Array = [base]
				var p := base
				var dir := Vector2((k - 1.5) * 0.35, -1.0).normalized()
				for s in 5:
					p += dir * maxf(r.size.x, r.size.y) * 0.17
					dir = dir.rotated((rng.randf() - 0.5) * 0.7)
					pts.append(p)
				_grooves_in(cl, g, poly, pts, S * 0.02, S * 0.035)
				lines.append(pts.filter(func(q: Vector2) -> bool: return Geometry2D.is_point_in_polygon(q, poly)))
		"crescents":
			for k in 2:
				var c := r.position + r.size * Vector2(0.5, 0.3 + k * 0.38)
				var arc: Array = []
				for s in 7:
					var a := -PI * 0.15 + s * PI * 0.22
					arc.append(c + Vector2(cos(a), sin(a)) * S * 0.24)
				_grooves_in(cl, g, poly, arc, S * 0.03, S * 0.05)
				lines.append(arc)
		"stitch":
			var ring := _inset(poly, 0.86)
			for k in ring.size():
				var a: Vector2 = ring[k]
				var b: Vector2 = ring[(k + 1) % ring.size()]
				var n := int(a.distance_to(b) / maxf(3.0, S * 0.12))
				for s in n:
					if s % 2 == 0:
						cl.groove(g, a.lerp(b, float(s) / n), a.lerp(b, float(s + 0.6) / n), S * 0.014, S * 0.025)
		"knots":
			for k in 3:
				var p := _pick(ctx, poly, r)
				if p.x >= 0.0:
					cl.bump(g, p, S * 0.1, S * 0.08, S * 0.06, _mat_at(ctx, g, p.x, p.y), 2.0)
					cl.carve(g, p, S * 0.04, S * 0.03, S * 0.04)
					lines.append([p - Vector2(S * 0.02, 0), p + Vector2(S * 0.02, 0)])
		"filigree":
			var gold := cl.mat(Color("#a88a48"), "metal", {"spec": 0.6})
			for k in 3:
				var c := r.position + r.size * Vector2(0.5, 0.25 + k * 0.25)
				var pts: Array = []
				for s in 9:
					var a := s * 0.8
					pts.append(c + Vector2(sin(a) * S * 0.18, (s - 4) * S * 0.04))
				cl.ridge(g, pts.filter(func(q: Vector2) -> bool: return Geometry2D.is_point_in_polygon(q, poly)), S * 0.025, S * 0.03, gold)
		"facets":
			var c := r.get_center()
			for k in 5:
				var a := TAU * k / 5.0 + 0.3
				_grooves_in(cl, g, poly, [c, c + Vector2(cos(a), sin(a)) * S], S * 0.02, S * 0.05)
	return lines


static func _trim(ctx: Dictionary, g: int, poly: PackedVector2Array, kind: String) -> void:
	var cl: Clay = ctx["cl"]
	var rng: RandomNumberGenerator = ctx["rng"]
	var r := _bounds(poly)
	var S := minf(r.size.x, r.size.y)
	var tall := r.size.y >= r.size.x
	match kind:
		"rivets":
			var ring := _inset(poly, 0.84)
			for k in ring.size():
				cl.bump(g, ring[k], S * 0.06, S * 0.06, S * 0.05, ctx["steel"], 1.0)
		"bands", "bands_wood", "rope":
			var n := 2 if kind != "rope" else 1
			for k in n:
				var t := (k + 1.0) / (n + 1.0)
				var a := r.position + (Vector2(0, r.size.y * t) if tall else Vector2(r.size.x * t, 0))
				var b := a + (Vector2(r.size.x, 0) if tall else Vector2(0, r.size.y))
				if kind == "bands":
					cl.ridge(g, _clip_line(poly, a, b), S * 0.07, S * 0.06, ctx["steel"])
				elif kind == "bands_wood":
					_grooves_in(cl, g, poly, [a, b], S * 0.03, S * 0.05)
				else:
					var rope := cl.mat(Color("#8a7450"), "cloth")
					for s in 4:
						var off := (Vector2(0, S * 0.08) if tall else Vector2(S * 0.08, 0)) * (s - 1.5)
						cl.ridge(g, _clip_line(poly, a + off, b + off), S * 0.045, S * 0.04, rope)
		"gold":
			var ring := _inset(poly, 0.9)
			var pts: Array = Array(ring)
			pts.append(ring[0])
			cl.ridge(g, pts, S * 0.035, S * 0.03, cl.mat(Color("#a88a48"), "metal", {"spec": 0.6}))
		"fur":
			var fur := cl.mat(Color("#cfc6b4"), "fur")
			var top := r.position.y + S * 0.08
			var x := r.position.x
			while x < r.end.x:
				var p := Vector2(x, top + sin(x * 0.7) * S * 0.04)
				if Geometry2D.is_point_in_polygon(p + Vector2(0, S * 0.1), poly):
					cl.ell(g, Vector3(p.x, p.y + S * 0.08, cl.surf(g, p.x, p.y + S * 0.1) + S * 0.04), S * 0.12, S * 0.1, S * 0.08, fur, 3.0)
				x += S * 0.12
		"leaves":
			var leaf := cl.mat(Color("#4e6a34"), "skin")
			for k in 3:
				var p := _pick(ctx, poly, r)
				if p.x < 0.0:
					continue
				var a := rng.randf() * TAU
				var d := Vector2(cos(a), sin(a)) * S * 0.16
				var n := Vector2(-d.y, d.x) * 0.45
				var lg := cl.group()
				cl.slab(lg, PackedVector2Array([p - d, p - n * 0.3, p + d, p + n]), cl.surf(g, p.x, p.y) + S * 0.04, S * 0.04, leaf, 1.0, S * 0.05)
		"spikes":
			var ring := _inset(poly, 0.97)
			for k in range(0, ring.size(), maxi(1, ring.size() / 6)):
				var p: Vector2 = ring[k]
				var out := (p - r.get_center()).normalized()
				var z := maxf(cl.surf(g, p.x, p.y), 0.0)
				cl.cap(g, Vector3(p.x, p.y, z), Vector3(p.x + out.x * S * 0.2, p.y + out.y * S * 0.2, z), S * 0.06, S * 0.01, ctx["bone"], 1.0)
		"patches":
			_patches(ctx, g, poly, r, S)


static func _patches(ctx: Dictionary, g: int, poly: PackedVector2Array, r: Rect2, S: float) -> void:
	var cl: Clay = ctx["cl"]
	for k in 2:
		var p := _pick(ctx, poly, r)
		if p.x < 0.0:
			continue
		var hw := S * 0.2
		var sq := [p + Vector2(-hw, -hw * 0.8), p + Vector2(hw, -hw * 0.7), p + Vector2(hw * 0.9, hw), p + Vector2(-hw, hw * 0.9)]
		cl.bump(g, p, hw * 1.0, hw * 0.9, S * 0.03, cl.mat(Color(ctx["c"]).darkened(0.25), "leather"), 2.0)
		for s in 4:
			cl.groove(g, sq[s], sq[(s + 1) % 4], S * 0.012, S * 0.03)


## 그룹 g가 그 칸에 쓴 재질(없으면 주 재질) — 혹·비늘을 같은 재질로 얹는다.
static func _mat_at(ctx: Dictionary, g: int, x: float, y: float) -> int:
	var cl: Clay = ctx["cl"]
	var xi := clampi(int(x), 0, cl.w - 1)
	var yi := clampi(int(y), 0, cl.h - 1)
	var mm: PackedInt32Array = cl._M[g]
	var m := mm[yi * cl.w + xi]
	return m if m >= 0 else int(ctx["m"])


## 다각형 안에서 고른 점(실패하면 (-1, -1)).
static func _pick(ctx: Dictionary, poly: PackedVector2Array, r: Rect2) -> Vector2:
	var rng: RandomNumberGenerator = ctx["rng"]
	for t in 20:
		var p := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
		if Geometry2D.is_point_in_polygon(p, _inset(poly, 0.85)):
			return p
	return Vector2(-1, -1)


## 다각형 안에 있는 마디만 골로 판다.
static func _grooves_in(cl: Clay, g: int, poly: PackedVector2Array, pts: Array, width: float, depth: float) -> void:
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		if Geometry2D.is_point_in_polygon(a, poly) or Geometry2D.is_point_in_polygon(b, poly):
			cl.groove(g, a, b, width, depth)


static func _clip_line(poly: PackedVector2Array, a: Vector2, b: Vector2) -> Array:
	var out: Array = []
	for s in 17:
		var p := a.lerp(b, s / 16.0)
		if Geometry2D.is_point_in_polygon(p, _inset(poly, 0.97)):
			out.append(p)
	return out


static func _inset(poly: PackedVector2Array, f: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= poly.size()
	var out := PackedVector2Array()
	for p in poly:
		out.append(c + (p - c) * f)
	return out


static func _bounds(poly: PackedVector2Array) -> Rect2:
	var r := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		r = r.expand(p)
	return r


## 원을 다각형으로(타원으로 빚은 덩어리 — 철퇴 머리·둥근 방패·투구에 무늬를 넣을 때).
static func circle(c: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		var a := TAU * k / n
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out
