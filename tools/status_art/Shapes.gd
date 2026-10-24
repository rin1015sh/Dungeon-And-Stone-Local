extends RefCounted
## 상태이상 아이콘 그리기 바탕(tools/paint_status_icons.gd 전용): 96×96 캔버스, 가운데 (48, 48).
## 도형 하나 = 다각형을 위에서 아래로 밝음 → 어둠 붓 칠 + 굵은 잉크 윤곽 + 왼쪽 위 작은 반짝임(우리 그림체 — 칠한 위에 펜).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const S := 96
const C := Vector2(48, 48)
const INK := Color("#120c0a")


## 칠한 도형(밝은 위 → 어두운 아래, 붓결) + 윤곽.
static func shape(p: Paint, poly: PackedVector2Array, col: Color, outline: float = 3.0, shine: bool = true) -> void:
	var r := Paint.bounds(poly)
	var top := col.lightened(0.28)
	var low := col.darkened(0.45)
	p.fill_poly(poly, func(x: int, y: int) -> Color:
		var t := clampf((y - r.position.y) / maxf(1.0, r.size.y) * 0.8 + (x - r.position.x) / maxf(1.0, r.size.x) * 0.2, 0.0, 1.0)
		return p.vary(top.lerp(low, t), x, y, 0.1))
	if outline > 0.0:
		Ink.path(p, poly, outline, true, INK, 0.95, 0.35)
	if shine:
		var hp := r.position + r.size * Vector2(0.3, 0.25)
		Ink.glow(p, hp.x, hp.y, minf(r.size.x, r.size.y) * 0.22, Color(1, 0.97, 0.9), 0.35)


## 굵은 선(잉크 윤곽이 있는 색 막대): 칠 + 테두리.
static func bar(p: Paint, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	Ink.line(p, a, b, w + 4.0, INK, 0.95, 0.2)
	Ink.line(p, a, b, w, col, 1.0, 0.2)
	Ink.line(p, a.lerp(b, 0.1) + Vector2(-w * 0.15, -w * 0.15), a.lerp(b, 0.6) + Vector2(-w * 0.15, -w * 0.15), maxf(1.0, w * 0.3), col.lightened(0.4), 0.6, 0.2)


static func circle(c: Vector2, r: float, n: int = 28, ry: float = -1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(c + Vector2(cos(a) * r, sin(a) * (r if ry < 0.0 else ry)))
	return out


static func star(c: Vector2, r_out: float, r_in: float, n: int = 5, rot: float = -PI / 2.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n * 2:
		var a := rot + PI * i / n
		out.append(c + Vector2.from_angle(a) * (r_out if i % 2 == 0 else r_in))
	return out


static func poly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for v: Vector2 in pts:
		out.append(v)
	return out


## 받침: 어두운 둥근 판 + 종류 색 테(해로운 것 = 검붉은, 이로운 것 = 탁한 금빛) — 어두운 무대 위에서도 보이게.
static func plate(p: Paint, rim: Color) -> void:
	p.fill_poly(circle(C, 44.0, 40), func(x: int, y: int) -> Color:
		var d := Vector2(x, y).distance_to(C) / 44.0
		return p.vary(Color("#1c1614").lerp(Color("#0c0908"), d), x, y, 0.15))
	Ink.path(p, circle(C, 43.0, 40), 3.0, true, rim, 0.9, 0.3)
	Ink.path(p, circle(C, 45.5, 40), 1.5, true, INK, 0.9, 0.2)
