extends RefCounted
## 사람 그리기 부품(Npcs.gd 전용): 피어 앤 헝거 인물화처럼 — 곡선 윤곽(캐트멀-롬), 굵기가 변하는 팔다리 관,
## 경계가 거칠게 끊기는 3단 명암(밝음·바탕·깊은 그늘) + 그늘 빗금, 고르지 않은 잉크 선, 때·얼룩.
## 좌표 o = Vector3(발 중심 x, 발 y, 키 px), 점 [u, v] = 키에 대한 비율(u 가로, v 발에서 위로).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const SHADOW := 0.5  ## 그늘 = 바탕을 이만큼 어둡게
const GRIME := Color("#2a2118")


static func q(o: Vector3, u: float, v: float) -> Vector2:
	return Vector2(o.x + u * o.z, o.y - v * o.z)


static func lw(o: Vector3) -> float:
	return maxf(1.0, o.z / 110.0)


## 점 배열 → 부드러운 곡선(캐트멀-롬). closed면 닫힌 윤곽.
static func spline(pts: PackedVector2Array, closed: bool = true, per: int = 5) -> PackedVector2Array:
	var n := pts.size()
	var out := PackedVector2Array()
	if n < 3:
		return pts
	var segs := n if closed else n - 1
	for i in segs:
		var p0 := pts[(i - 1 + n) % n] if (closed or i > 0) else pts[0]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n] if (closed or i + 2 < n) else pts[n - 1]
		for k in per:
			var t := float(k) / per
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	if not closed:
		out.append(pts[n - 1])
	return out


## [u, v] 점들 → 부드러운 닫힌 윤곽(s = -1이면 좌우 뒤집기).
static func shape(o: Vector3, uv: Array, s: float = 1.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for a: Array in uv:
		pts.append(q(o, float(a[0]) * s, float(a[1])))
	return spline(pts)


## 관(팔·다리·목·창대): 가운데 선 [u, v] + 굵기(반지름, 키 비율) → 끝이 둥근 윤곽.
static func limb(o: Vector3, uv: Array, widths: Array, s: float = 1.0) -> PackedVector2Array:
	var c := PackedVector2Array()
	for a: Array in uv:
		c.append(q(o, float(a[0]) * s, float(a[1])))
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n := c.size()
	for i in n:
		var t := (c[mini(i + 1, n - 1)] - c[maxi(i - 1, 0)]).normalized()
		var nr := Vector2(-t.y, t.x)
		var r := float(widths[i]) * o.z
		left.append(c[i] + nr * r)
		right.append(c[i] - nr * r)
	var pts := PackedVector2Array()
	var t0 := (c[1] - c[0]).normalized()
	var t1 := (c[n - 1] - c[n - 2]).normalized()
	pts.append(c[0] - t0 * float(widths[0]) * o.z * 0.6)
	pts.append_array(left)
	pts.append(c[n - 1] + t1 * float(widths[n - 1]) * o.z * 0.7)
	right.reverse()
	pts.append_array(right)
	return spline(pts)


## 칠하기: 3단 명암(빛 쪽 밝음 · 바탕 · 반대쪽 깊은 그늘, 경계는 잡음으로 거칠게) + 그늘 빗금 + 잉크 윤곽.
## lit = 빛이 오는 쪽(-1 왼쪽, 1 오른쪽). edge = 그늘이 시작되는 위치(-1 ~ 1, 클수록 그늘이 좁다).
static func paint(p: Paint, o: Vector3, poly: PackedVector2Array, base: Color, lit: float, edge: float = 0.15, hatch: bool = true, line: float = 1.0) -> void:
	var r := Paint.bounds(poly)
	var cx := r.get_center().x
	var hw := maxf(1.0, r.size.x / 2.0)
	var top := r.position.y
	var hh := maxf(1.0, r.size.y)
	var deep := base.darkened(SHADOW)
	var mid := base.darkened(SHADOW * 0.45)
	var hi := base.lightened(0.16)
	var sh := func(x: int, y: int) -> Color:
		var d := (x - cx) / hw * -lit + (p.nz("mid", x, y) - 0.5) * 0.28 + (y - top) / hh * 0.2
		var c := base
		if d > edge:
			c = deep
		elif d > edge - 0.38:
			c = mid
		elif d < -0.62:
			c = hi
		return p.vary(c, x, y, 0.12)
	p.fill_poly(poly, sh)
	if hatch and r.size.x > 5.0:
		var sp := maxf(2.0, o.z / 70.0)
		var half := Paint.rect_poly(cx + (0.0 if lit < 0.0 else -hw), top, hw, hh)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(poly, half):
			Ink.hatch(p, part, sp, 58.0 if lit < 0.0 else 122.0, 0.32, maxf(0.7, o.z / 220.0))
		var edge_x := cx + hw * (0.45 if lit < 0.0 else -0.45)  # 가장 깊은 그늘은 엇갈린 빗금
		var deep_rect := Paint.rect_poly(edge_x if lit < 0.0 else r.position.x, top, hw * 0.55, hh)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(poly, deep_rect):
			Ink.hatch(p, part, sp * 1.2, 122.0 if lit < 0.0 else 58.0, 0.24, maxf(0.7, o.z / 220.0))
	if line > 0.0:
		Ink.path(p, poly, lw(o) * line, true, Ink.INK, 0.85, 1.4)


## 옷 주름·때: 짧은 곡선 획 몇 개 + 얼룩.
static func folds(p: Paint, o: Vector3, strokes: Array, s: float = 1.0) -> void:
	for st: Array in strokes:
		var pts := PackedVector2Array()
		for a: Array in st:
			pts.append(q(o, float(a[0]) * s, float(a[1])))
		Ink.path(p, spline(pts, false, 4), lw(o) * 0.8, false, Ink.INK, 0.55, 1.0)


static func grime(p: Paint, poly: PackedVector2Array, amount: float = 0.25) -> void:
	var r := Paint.bounds(poly)
	var sh := func(x: int, y: int) -> Color:
		var n := p.nz("lo", x, y) * 0.6 + p.nz("hi", x, y) * 0.4
		return Color(GRIME.r, GRIME.g, GRIME.b, clampf((n - 0.55) * 3.0, 0.0, 1.0) * amount)
	p.fill_poly(poly, sh, 1.0, true)
	if r.size.y > 30.0:
		Ink.strokes(p, poly, 0.6, r.size.y / 10.0, maxf(2.0, r.size.x / 18.0), 80.0, 0.12, 0.35)


## 다른 캔버스(src)를 dst의 (ox, oy)에 얹는다. keep = 그 자리 밝기를 실내 어둠(Interiors.light)에서 지키는 정도.
static func stamp(dst: Paint, src: Paint, ox: int, oy: int, keep: float) -> void:
	if dst.keep.size() != dst.w * dst.h:
		dst.keep.resize(dst.w * dst.h)
	for y in src.h:
		for x in src.w:
			var a := src.alpha_at(x, y)
			if a <= 0.0:
				continue
			var dx := ox + x
			var dy := oy + y
			if dx < 0 or dy < 0 or dx >= dst.w or dy >= dst.h:
				continue
			dst.blend(dx, dy, src.get_c(x, y), a)
			var k := dy * dst.w + dx
			dst.keep[k] = maxf(dst.keep[k], keep * a)


## 테두리 빛(가장자리 한 줄 밝게): 빛 쪽 가장자리 — 어두운 배경에서 사람이 떨어져 보이게.
static func rim(p: Paint, lit: float, width: int, c: Color, strength: float) -> void:
	var marks: Array[Vector3] = []
	for y in p.h:
		for x in p.w:
			if p.alpha_at(x, y) < 0.9:
				continue
			for k in range(1, width + 1):
				if p.alpha_at(x + int(lit) * k, y) < 0.2:
					marks.append(Vector3(x, y, 1.0 - float(k - 1) / width))
					break
	for m in marks:
		p.add_light(int(m.x), int(m.y), c, strength * m.z)
