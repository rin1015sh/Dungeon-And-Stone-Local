class_name CombatFigure
extends RefCounted
## 전투 무대의 몸(그림 파일이 없을 때): 정면(적 — 이쪽을 노려본다)과 뒷모습(아군 — 적을 마주 본다).
## 피어 앤 헝거 전투처럼 어둠 속 한 덩이 실루엣: 짙은 윤곽선, 한쪽으로 몰린 그늘, 퀭한 눈.
## 좌표: foot = 발 가운데, h = 키(px). shape: humanoid / beast / blob (몬스터 데이터 shape).

const INK := Color(0.06, 0.045, 0.04, 1.0)
const EYE := Color(0.95, 0.82, 0.55, 1.0)


static func paint(c: CanvasItem, shape: String, color: Color, front: bool, foot: Vector2, h: float, glow: float = 0.0) -> void:
	var k := h / 100.0
	_shadow(c, foot, k * (36.0 if shape != "beast" else 50.0), k)
	match shape:
		"beast":
			_beast(c, color, front, foot, k)
		"blob":
			_blob(c, color, front, foot, k)
		_:
			_humanoid(c, color, front, foot, k)
	if glow > 0.0:
		_outline_glow(c, foot, h, glow)


## 그림 파일(MonsterArt)을 쓸 때의 발밑: 그림자 + (고른 대상·차례면) 금빛 고리. rx = 그림 폭의 절반.
static func ground(c: CanvasItem, foot: Vector2, rx: float, h: float, glow: float) -> void:
	_shadow(c, foot, rx, h / 100.0)
	if glow > 0.0:
		var ring := _ellipse(foot + Vector2(0, 2), rx * 1.05, rx * 0.19, 32)
		ring.append(ring[0])
		c.draw_polyline(ring, Color(0.95, 0.78, 0.35, glow), maxf(2.0, h / 60.0), true)


## 발에서 머리 꼭대기까지(키 h에 대한 비율) — 이름표 자리.
static func top_of(shape: String) -> float:
	match shape:
		"beast":
			return 0.8
		"blob":
			return 0.78
	return 1.1


## 정해진 키 h일 때 차지하는 폭(무대 배치용).
static func width_of(shape: String, h: float) -> float:
	match shape:
		"beast":
			return h * 1.15
		"blob":
			return h * 1.0
	return h * 0.62


static func _shadow(c: CanvasItem, foot: Vector2, rx: float, k: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(foot + Vector2(cos(a) * rx, sin(a) * rx * 0.18 + 2.0 * k))
	c.draw_colored_polygon(pts, Color(0, 0, 0, 0.55))


## 다각형 하나: 바탕 → 오른쪽 그늘(반쯤) → 윤곽선.
static func _part(c: CanvasItem, pts: PackedVector2Array, color: Color, k: float, axis: float, shade: float = 0.45) -> void:
	if pts.size() < 3:
		return
	c.draw_colored_polygon(pts, color)
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	var half := PackedVector2Array([Vector2(axis, r.position.y - 2), Vector2(r.end.x + 2, r.position.y - 2), Vector2(r.end.x + 2, r.end.y + 2), Vector2(axis, r.end.y + 2)])
	for part: PackedVector2Array in Geometry2D.intersect_polygons(pts, half):
		c.draw_colored_polygon(part, Color(0, 0, 0, shade))
	var loop := PackedVector2Array(pts)
	loop.append(pts[0])
	c.draw_polyline(loop, INK, maxf(1.5, 2.2 * k), true)


static func _poly(foot: Vector2, k: float, uv: Array, sx: float = 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for a: Array in uv:
		out.append(foot + Vector2(float(a[0]) * k * sx, float(a[1]) * k))
	return out


static func _ellipse(center: Vector2, rx: float, ry: float, n: int = 20) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## 사람형: 다리 둘 · 몸통(어깨가 넓다) · 늘어뜨린 팔 · 머리. 정면이면 퀭한 눈두덩과 눈빛, 뒷모습이면 뒤통수·등 솔기.
static func _humanoid(c: CanvasItem, color: Color, front: bool, foot: Vector2, k: float) -> void:
	var dark := color.darkened(0.35)
	var ax := foot.x + 2.0 * k
	for s: float in [-1.0, 1.0]:
		_part(c, _poly(foot, k, [[-3, -50], [-15, -50], [-14, -22], [-13, -3], [-17, 0], [-4, 0], [-5, -22]], s), dark, k, ax)
	for s: float in [-1.0, 1.0]:
		_part(c, _poly(foot, k, [[-17, -84], [-25, -80], [-29, -60], [-28, -40], [-22, -38], [-22, -58], [-16, -70]], s), color.darkened(0.12), k, ax)
		c.draw_colored_polygon(_ellipse(foot + Vector2(-24.5 * k * s, -37 * k), 4.0 * k, 4.5 * k), color.lightened(0.05).darkened(0.25))
	_part(c, _poly(foot, k, [[-18, -84], [-6, -88], [6, -88], [18, -84], [17, -64], [14, -48], [-14, -48], [-17, -64]]), color, k, ax)
	_part(c, _poly(foot, k, [[-4, -86], [4, -86], [4, -92], [-4, -92]]), dark, k, ax)
	var head := _ellipse(foot + Vector2(0, -99 * k), 8.5 * k, 10.5 * k)
	_part(c, head, color.lightened(0.12), k, ax, 0.4)
	if front:
		for s: float in [-1.0, 1.0]:
			var sock := _ellipse(foot + Vector2(3.6 * k * s, -100 * k), 2.8 * k, 2.0 * k, 12)
			c.draw_colored_polygon(sock, Color(0.04, 0.03, 0.03, 0.95))
			c.draw_circle(foot + Vector2(3.6 * k * s, -100 * k), maxf(0.8, 0.8 * k), EYE)
		c.draw_line(foot + Vector2(-3 * k, -93 * k), foot + Vector2(3 * k, -93.5 * k), INK, maxf(1.0, 1.2 * k))
	else:
		c.draw_colored_polygon(_ellipse(foot + Vector2(0, -101 * k), 8.0 * k, 8.0 * k), color.darkened(0.45))
		c.draw_line(foot + Vector2(0, -82 * k), foot + Vector2(0.6 * k, -52 * k), Color(0, 0, 0, 0.45), maxf(1.0, 1.4 * k))


## 네발짐승: 정면이면 낮게 숙인 머리가 가운데, 넓은 어깨 뒤로 등, 굵은 앞다리, 이빨 드러낸 주둥이. 뒷모습은 등·꼬리·뒷다리.
static func _beast(c: CanvasItem, color: Color, front: bool, foot: Vector2, k: float) -> void:
	var dark := color.darkened(0.35)
	var ax := foot.x + 4.0 * k
	_part(c, _poly(foot, k, [[-40, -40], [-30, -62], [-8, -70], [12, -70], [32, -62], [42, -40], [32, -24], [-32, -24]]), color.darkened(0.08), k, ax)
	for s: float in [-1.0, 1.0]:
		_part(c, _poly(foot, k, [[-30, -34], [-17, -34], [-15, -14], [-14, -2], [-20, 0], [-31, 0], [-29, -14]], s), dark, k, ax)
	if front:
		for s: float in [-1.0, 1.0]:
			_part(c, _poly(foot, k, [[-12, -62], [-20, -78], [-6, -66]], s), dark, k, ax)
		var head := _poly(foot, k, [[-17, -62], [-7, -68], [7, -68], [17, -62], [16, -46], [9, -32], [-9, -32], [-16, -46]])
		_part(c, head, color.lightened(0.1), k, ax, 0.4)
		_part(c, _poly(foot, k, [[-9, -40], [9, -40], [7, -27], [-7, -27]]), color.darkened(0.25), k, ax)
		c.draw_line(foot + Vector2(-6 * k, -32 * k), foot + Vector2(6 * k, -32 * k), INK, maxf(1.0, 1.6 * k))
		for i in 4:
			var tx := (-5.0 + i * 3.3) * k
			c.draw_line(foot + Vector2(tx, -32 * k), foot + Vector2(tx + 0.6 * k, -29 * k), Color(0.9, 0.86, 0.75), maxf(1.0, 1.0 * k))
		for s: float in [-1.0, 1.0]:
			c.draw_colored_polygon(_ellipse(foot + Vector2(7.5 * k * s, -53 * k), 3.2 * k, 2.2 * k, 12), Color(0.04, 0.03, 0.03, 0.95))
			c.draw_circle(foot + Vector2(7.5 * k * s, -53 * k), maxf(1.0, 1.3 * k), Color(0.95, 0.7, 0.3))
	else:
		_part(c, _poly(foot, k, [[-3, -66], [3, -66], [10, -86], [5, -88]]), dark, k, ax)


## 덩어리: 흘러내리는 둔덕 + 구멍 같은 눈과 입.
static func _blob(c: CanvasItem, color: Color, front: bool, foot: Vector2, k: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var t := float(i) / 32.0
		var x := lerpf(-46.0, 46.0, t)
		var y := -sin(t * PI) * 72.0 - sin(t * TAU * 3.0) * 4.0
		pts.append(foot + Vector2(x * k, y * k))
	_part(c, pts, color, k, foot.x + 6.0 * k)
	for i in 4:
		var dx := (-30.0 + i * 20.0) * k
		c.draw_colored_polygon(_ellipse(foot + Vector2(dx, -3 * k), 4.0 * k, 6.0 * k, 10), color.darkened(0.2))
	if front:
		for s: float in [-1.0, 1.0]:
			c.draw_colored_polygon(_ellipse(foot + Vector2(11 * k * s, -46 * k), 5.0 * k, 6.5 * k, 14), Color(0.04, 0.03, 0.03, 0.95))
			c.draw_circle(foot + Vector2(11 * k * s, -46 * k), maxf(1.0, 1.4 * k), EYE)
		c.draw_colored_polygon(_ellipse(foot + Vector2(0, -27 * k), 12.0 * k, 4.0 * k, 16), Color(0.05, 0.03, 0.03, 0.9))


## 대상으로 고른 참가자: 발밑에 금빛 고리.
static func _outline_glow(c: CanvasItem, foot: Vector2, h: float, strength: float) -> void:
	var ring := _ellipse(foot + Vector2(0, 2), h * 0.42, h * 0.075, 32)
	ring.append(ring[0])
	c.draw_polyline(ring, Color(0.95, 0.78, 0.35, strength), maxf(2.0, h / 60.0), true)
