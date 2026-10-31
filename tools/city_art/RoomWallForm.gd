extends RefCounted
## 시설 실내 벽의 입체(RoomPaint 전용 — CT71: 사용자 "벽이 입체감을 무시해 — 타일처럼 쳐 바르면 벽인지 바닥인지 천장인지 구분이 안 간다"):
## 윗면(cap) = 위에서 본 벽 두께 — 거의 검은 덩어리에 밝은 테(바닥·앞면과 맞닿은 가장자리, 앞면 위 모서리는 더 밝게) · 바깥 잉크 선.
## 앞면(face) = 세운 벽 — 재질 위에 위는 밝고 아래로 어두워지는 그늘 · 맨 위 처마 띠 · 아래 굽도리 · 벽이 꺾이는 끝은 세로 그늘(모서리).
## 문(door·doorway·locked·entry)은 놓인 벽의 방향대로: 옆벽(위아래가 벽)이면 세로 문턱 + 벽에 붙여 연 문짝(옆에서 본 얇은 판),
## 앞벽(좌우가 벽)이면 가로 문턱 + 문틀(양 기둥·상인방).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Mat := preload("res://tools/city_art/Mat.gd")

const CAP := Color("#1e1a17")
const RIM := Color("#5e5246")
const RIM_LIT := Color("#8a7a66")


## 윗면 한 칸. wall(dx, dy) = 그 쪽 이웃이 벽인가, face_below = 아래 칸이 앞면인가.
static func cap(p: Paint, x: int, y: int, t: int, wall: Callable, face_below: bool) -> void:
	p.fill_rect(x * t, y * t, t, t, func(px: int, py: int) -> Color: return p.vary(CAP.lerp(Color("#2a2420"), p.nz("lo", px, py) * 0.6), px, py, 0.05))
	var rim := maxf(3.0, t * 0.07)
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if bool(wall.call(d.x, d.y)) and not (d == Vector2i.DOWN and face_below):
			continue
		var lit := d == Vector2i.DOWN  # 앞면 위 모서리(빛을 받는 벽 윗선)
		var r := Rect2(x * t, y * t, t, t)
		match d:
			Vector2i.UP:
				r = Rect2(x * t, y * t, t, rim)
			Vector2i.DOWN:
				r = Rect2(x * t, y * t + t - rim, t, rim)
			Vector2i.LEFT:
				r = Rect2(x * t, y * t, rim, t)
			Vector2i.RIGHT:
				r = Rect2(x * t + t - rim, y * t, rim, t)
		p.fill_rect(r.position.x, r.position.y, r.size.x, r.size.y, p.flat(RIM_LIT if lit else RIM, 0.05))
		var a := Vector2(x * t + (t if d.x > 0 else 0), y * t + (t if d.y > 0 else 0))
		var b := a + (Vector2(0, t) if d.x != 0 else Vector2(t, 0))
		Ink.line(p, a, b, 1.6, Ink.INK, 0.9, 0.2)


## 앞면 한 칸(재질은 이미 칠함): top = 이 칸이 앞면 맨 위(위가 윗면), bottom = 맨 아래(아래가 바닥), left_end·right_end = 옆이 앞면이 아님(꺾이는 끝).
static func face(p: Paint, x: int, y: int, t: int, top: bool, bottom: bool, left_end: bool, right_end: bool) -> void:
	var r := Paint.rect_poly(x * t, y * t, t, t)
	# 위 → 아래 그늘: 맨 위 칸은 밝게 시작, 맨 아래 칸은 바닥 쪽으로 짙게(앞면 두 칸이 한 판으로 이어 보이게)
	Ink.shade(p, r, Vector2(0, y * t), Vector2(0, y * t + t), 0.18 if top else 0.3, 0.55 if bottom else 0.3)  # 바닥보다 늘 어둡게(세운 면은 빛을 덜 받는다)
	if top:
		var band := t * 0.13
		p.fill_rect(x * t, y * t, t, band, p.flat(Color("#2e2620"), 0.05))
		Ink.line(p, Vector2(x * t, y * t + band), Vector2(x * t + t, y * t + band), 1.4, Color("#a8987e"), 0.55, 0.2)
		Ink.line(p, Vector2(x * t, y * t + band + 2), Vector2(x * t + t, y * t + band + 2), 1.2, Ink.INK, 0.6, 0.2)
	if bottom:
		p.fill_rect(x * t, y * t + t - t * 0.12, t, t * 0.12, p.flat(Color("#2a1f17"), 0.08))
		Ink.line(p, Vector2(x * t, y * t + t - t * 0.12), Vector2(x * t + t, y * t + t - t * 0.12), 1.2, Color("#6a5a48"), 0.6, 0.2)
		Ink.line(p, Vector2(x * t, y * t + t), Vector2(x * t + t, y * t + t), 2.0, Ink.INK, 0.85, 0.3)
	var edge := t * 0.16
	if left_end:
		Ink.shade(p, Paint.rect_poly(x * t, y * t, edge, t), Vector2(x * t, 0), Vector2(x * t + edge, 0), 0.5, 0.0)
		Ink.line(p, Vector2(x * t, y * t), Vector2(x * t, y * t + t), 1.6, Ink.INK, 0.85, 0.2)
	if right_end:
		Ink.shade(p, Paint.rect_poly(x * t + t - edge, y * t, edge, t), Vector2(x * t + t, 0), Vector2(x * t + t - edge, 0), 0.5, 0.0)
		Ink.line(p, Vector2(x * t + t, y * t), Vector2(x * t + t, y * t + t), 1.6, Ink.INK, 0.85, 0.2)


## 문 자리의 바닥(문턱): side = 옆벽 문(세로), 아니면 앞벽 문(가로). entry = 건물 입구(바깥 빛).
static func threshold(p: Paint, x: int, y: int, t: int, side: bool, entry: bool) -> void:
	if side:
		p.fill_rect(x * t + t * 0.3, y * t + 2, t * 0.4, t - 4, Mat.planks(p, Color("#5a4632"), 0, 0, true, 8))
		Ink.path(p, Paint.rect_poly(x * t + t * 0.3, y * t + 2, t * 0.4, t - 4), 1.2, true, Ink.INK, 0.6)
	else:
		p.fill_rect(x * t + 2, y * t + t * 0.3, t - 4, t * 0.4, Mat.planks(p, Color("#5a4632"), 0, 0, false, 8))
		Ink.path(p, Paint.rect_poly(x * t + 2, y * t + t * 0.3, t - 4, t * 0.4), 1.2, true, Ink.INK, 0.6)
	if entry:
		p.fill_rect(x * t, y * t + t * 0.6, t, t * 0.4, p.flat(Color("#2a2e34"), 0.05))


## 문짝·문틀(벽 층): side면 옆벽 — 문짝을 방 안쪽으로 열어 벽에 붙인 얇은 판(옆에서 본 문), 위 벽 끝에 상인방 그늘.
## 앞벽이면 양 기둥 + 상인방(문틀만 — 열린 문). door = 문짝이 있는 문(문간·입구는 틀만).
static func door(p: Paint, x: int, y: int, t: int, side: bool, door_leaf: bool, hinge_left: bool) -> void:
	var wood := Color("#4e3624")
	if side:
		for yy: float in [y * t + 1.0, y * t + t - 4.0]:  # 문설주 끝(위·아래 벽 끝에 붙은 나무 틀)
			p.fill_rect(x * t + t * 0.2, yy, t * 0.6, 3, p.flat(wood.darkened(0.2), 0.05))
		if door_leaf:
			var lx := x * t + (t * 0.06 if hinge_left else t * 0.78)
			var leaf := Paint.rect_poly(lx, y * t - t * 0.55, t * 0.16, t * 1.45)
			p.fill_poly(leaf, Mat.planks(p, wood, 0, 0, true, 5))
			Ink.shade(p, leaf, Vector2(0, y * t - t * 0.55), Vector2(0, y * t + t * 0.9), 0.0, 0.3)
			Ink.path(p, leaf, 1.6)
			p.fill_rect(lx + t * 0.04, y * t + t * 0.2, 3, 3, p.flat(Color("#9a8458"), 0.05))
	else:
		for px: float in [x * t, x * t + t - t * 0.14]:  # 앞벽 문은 한 칸 높이 벽에만 있다 — 틀은 그 칸 안
			var post := Paint.rect_poly(px, y * t, t * 0.14, t)
			p.fill_poly(post, Mat.planks(p, wood, 0, 0, true, 6))
			Ink.path(p, post, 1.4)
		var lintel := Paint.rect_poly(x * t - 2, y * t, t + 4, t * 0.16)
		p.fill_poly(lintel, Mat.planks(p, wood.darkened(0.1), 0, 0, false, 6))
		Ink.path(p, lintel, 1.4)
		if door_leaf:  # 안쪽으로 연 문짝 — 틀 안쪽 한쪽에 얇게
			var leaf := Paint.rect_poly(x * t + (t * 0.14 if hinge_left else t * 0.7), y * t + t * 0.16, t * 0.16, t * 0.8)
			p.fill_poly(leaf, Mat.planks(p, wood.lightened(0.05), 0, 0, true, 5))
			Ink.path(p, leaf, 1.4)
