extends RefCounted
## 한 점 투시 방 그리기 부품과 빛 칠(light) — 거리 사건·정산 천막 그림이 쓴다(시설 내부 배경 일러스트는 2026-11-02에 지웠다 — 도시 동네 지도 M0).
## 어둡게 칠한 뒤 촛불·난로·창빛만 다시 밝히는 방식(빛이 닿는 곳만 보인다). 오른쪽은 활동 창이 덮으므로 볼거리는 왼쪽·가운데에.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Refine := preload("res://tools/city_art/Refine.gd")
## 거주 구역마다 방의 밝기(빛이 닿지 않는 곳의 배율 — 1 = 13구역, CT54).
const AMBIENT := [0.58, 0.66, 0.78, 0.88]

const W := 960
const H := 540
const VP := Vector2(360, 230)  ## 소실점
const BACK := Rect2(170, 110, 380, 220)  ## 뒷벽


static func pt(q: Vector2, s: float) -> Vector2:
	return VP + (q - VP) * s


## 방 뼈대: 뒷벽·옆벽·천장·바닥(각자 재질 셰이더) + 모서리 잉크 + 구석 그늘.
static func room(p: Paint, back_sh: Callable, side_sh: Callable, floor_sh: Callable, ceil_sh: Callable) -> void:
	var b := BACK
	var tl := b.position
	var tr := Vector2(b.end.x, b.position.y)
	var bl := Vector2(b.position.x, b.end.y)
	var br := b.end
	var far := 4.0
	var ceil := Paint.poly([pt(tl, far), pt(tr, far), tr, tl])
	var flo := Paint.poly([bl, br, pt(br, far), pt(bl, far)])
	var left := Paint.poly([pt(tl, far), tl, bl, pt(bl, far)])
	var right := Paint.poly([tr, pt(tr, far), pt(br, far), br])
	p.fill_poly(ceil, ceil_sh)
	p.fill_poly(left, side_sh)
	p.fill_poly(right, side_sh)
	p.fill_poly(flo, floor_sh)
	p.fill_poly(Paint.rect_poly(b.position.x, b.position.y, b.size.x, b.size.y), back_sh)
	Ink.shade(p, left, Vector2(0, 0), tl, 0.0, 0.35)
	Ink.shade(p, right, Vector2(W, 0), tr, 0.0, 0.35)
	Ink.shade(p, flo, Vector2(0, H), bl, 0.0, 0.45)
	Ink.shade(p, ceil, Vector2(0, 0), tl, 0.2, 0.6)
	for c: Vector2 in [tl, tr, bl, br]:
		Ink.line(p, c, pt(c, far), 2.4, Ink.INK, 0.8, 1.0)
	Ink.path(p, Paint.rect_poly(b.position.x, b.position.y, b.size.x, b.size.y), 2.4)


## 앞을 향한 상자(탁자·계산대·궤짝): 앞면 + 윗면(소실점 쪽으로 좁아짐).
static func box(p: Paint, x: float, y: float, bw: float, bh: float, depth: float, front_sh: Callable, top_sh: Callable) -> void:
	var a := Vector2(x, y)
	var b := Vector2(x + bw, y)
	var k := depth / maxf(1.0, (a.y - VP.y))
	var a2 := a + (VP - a) * k
	var b2 := b + (VP - b) * k
	var top := Paint.poly([a, b, b2, a2])
	var front := Paint.rect_poly(x, y, bw, bh)
	p.fill_poly(top, top_sh)
	p.fill_poly(front, front_sh)
	Ink.shade(p, front, Vector2(0, y), Vector2(0, y + bh), 0.1, 0.5)
	Ink.path(p, top, 2.0)
	Ink.path(p, front, 2.2)


## 빛줄기(창에서 바닥으로): 두 점 → 두 점 사다리꼴, 더하기 빛.
static func shaft(p: Paint, a0: Vector2, a1: Vector2, b0: Vector2, b1: Vector2, c: Color, strength: float) -> void:
	var poly := Paint.poly([a0, a1, b1, b0])
	var mid_top := (a0 + a1) / 2.0
	var mid_bot := (b0 + b1) / 2.0
	var r := Paint.bounds(poly)
	for y in range(int(r.position.y), int(r.end.y)):
		for x in range(int(r.position.x), int(r.end.x)):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), poly):
				var t := clampf((Vector2(x, y) - mid_top).dot(mid_bot - mid_top) / maxf(1.0, mid_top.distance_squared_to(mid_bot)), 0.0, 1.0)
				p.add_light(x, y, c, strength * (1.0 - t * 0.7) * (0.6 + 0.6 * p.nz("vs", x, y)))


## 어둡게 내린 뒤 광원 주변만 밝힌다. lights = [[Vector2, 반지름, 색, 세기] …]
static func light(p: Paint, lights: Array, ambient: float = 0.58) -> void:
	for y in H:
		for x in W:
			var k := (y * W + x) * 4
			var f := ambient
			for L: Array in lights:
				var d := Vector2(x, y).distance_to(L[0]) / float(L[1])
				if d < 1.0:
					f += (1.0 - d) * (1.0 - d) * float(L[3])
			f = minf(f, 1.25)
			if not p.keep.is_empty() and p.keep[y * W + x] > 0.0 and f < 1.0:
				f = lerpf(f, 1.0, p.keep[y * W + x])
			for j in 3:
				p.buf[k + j] *= f
	for L: Array in lights:
		Ink.glow(p, L[0].x, L[0].y, float(L[1]) * 0.45, L[2], float(L[3]) * 0.35)
