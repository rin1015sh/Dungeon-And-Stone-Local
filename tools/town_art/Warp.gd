extends RefCounted
## 동네 집 굽기의 옮겨 붙이기: 평평하게 그린 면 그림(Elev)을 게임 시점(화면 = (x, y − z) × S)의 기운 면으로 —
## 면 틀(o, u, v)의 화면 기울기를 뒤집어 화면 칸마다 입면도 좌표를 찾고 두 점 사이로 섞어 읽는다(겹선형). 면마다 빛 배율을 곱하고 잉크 윤곽.

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")

const LIGHT := Vector3(-0.55, 0.35, 0.76)


static func proj(q: Vector3, S: float, origin: Vector2) -> Vector2:
	return Vector2(q.x * S, (q.y - q.z) * S) - origin


## 면 빛 배율(왼쪽 위에서 — 그늘 면도 너무 검지 않게).
static func light_k(n: Vector3) -> float:
	return 0.7 + 0.5 * maxf(0.0, n.dot(LIGHT.normalized()))


## 게임 시점 화면 축(x, y − z).
const GAME_AX := Vector3(1, 0, 0)
const GAME_AY := Vector3(0, 1, -1)


static func compose(sp: Paint, f: Dictionary, flat: Paint, P: float, S: float, origin: Vector2, ax: Vector3 = GAME_AX, ay: Vector3 = GAME_AY) -> void:
	var o: Vector3 = f["o"]
	var u: Vector3 = f["u"]
	var v: Vector3 = f["v"]
	var so := Vector2(o.dot(ax), o.dot(ay)) * S - origin
	var du := Vector2(u.dot(ax), u.dot(ay)) * S
	var dv := Vector2(v.dot(ax), v.dot(ay)) * S
	var det := du.x * dv.y - du.y * dv.x
	if absf(det) < 0.5:
		return  # 거의 옆에서 본 면
	var k := light_k(f["n"])
	var pts := PackedVector2Array()
	for q: Vector3 in f["pts"]:
		pts.append(Vector2(q.dot(ax), q.dot(ay)) * S - origin)
	var sh := func(x: int, y: int) -> Color:
		var d := Vector2(x + 0.5, y + 0.5) - so
		var lu := (d.x * dv.y - d.y * dv.x) / det
		var lv := (du.x * d.y - du.y * d.x) / det
		var c := _sample(flat, lu * P, lv * P)
		return Color(c.r * k, c.g * k, c.b * k, c.a)
	sp.fill_poly(pts, sh)
	Ink.path(sp, pts, 1.3, true, Ink.INK, 0.75, 0.25)


static func _sample(p: Paint, fx: float, fy: float) -> Color:
	var x := clampf(fx - 0.5, 0.0, p.w - 1.001)
	var y := clampf(fy - 0.5, 0.0, p.h - 1.001)
	var x0 := int(x)
	var y0 := int(y)
	var tx := x - x0
	var ty := y - y0
	var a := p.get_c(x0, y0)
	var b := p.get_c(x0 + 1, y0)
	var c := p.get_c(x0, y0 + 1)
	var d := p.get_c(x0 + 1, y0 + 1)
	var top := a.lerp(b, tx)
	var bot := c.lerp(d, tx)
	var out := top.lerp(bot, ty)
	if out.a < 0.99 and out.a > 0.0:  # 가장자리: 칠한 쪽 색을 쓴다(검은 테 번짐 막기)
		var best := a if a.a >= b.a and a.a >= c.a and a.a >= d.a else (b if b.a >= c.a and b.a >= d.a else (c if c.a >= d.a else d))
		out = Color(best.r, best.g, best.b, maxf(out.a, 0.0))
	if out.a < 1.0:
		out.a = 1.0  # 면 안쪽은 다 칠한다(입면도 테두리의 반투명을 메운다)
	return out
