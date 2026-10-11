class_name FigurePainter
extends RefCounted
## 임시 그래픽(스프라이트가 없을 때)의 캐릭터·몬스터 도형. 원점 = 발 위치, 위쪽이 음수.
## shape: humanoid(사람형) / beast(네발짐승) / blob(진흙 덩어리). scale 1 = 키 48px 기준.
## silhouette이면 그림자·눈·불꽃 없이 단색 윤곽만(벽에 가려졌을 때 겹치는 실루엣용).


## base: 그릴 자리(발 위치·배율). 전투 카드처럼 원점을 옮겨 그릴 때 넘긴다.
static func paint(canvas: CanvasItem, shape: String, scale: float, color: Color, facing: Vector2i,
		silhouette: bool = false, torch: bool = false, base: Transform2D = Transform2D.IDENTITY) -> void:
	if not silhouette:
		canvas.draw_set_transform_matrix(base * Transform2D(0.0, Vector2(1.0, 0.4), 0.0, Vector2(0, -1)))
		canvas.draw_circle(Vector2.ZERO, (14.0 if shape == "beast" else 10.0) * scale, Color(0, 0, 0, 0.45))
	canvas.draw_set_transform_matrix(base)
	match shape:
		"beast":
			_beast(canvas, scale, color, facing, silhouette)
		"blob":
			_blob(canvas, scale, color, silhouette)
		_:
			_humanoid(canvas, scale, color, facing, silhouette, torch)


static func _humanoid(c: CanvasItem, s: float, color: Color, facing: Vector2i, silhouette: bool, torch: bool) -> void:
	var body := Color.WHITE if silhouette else color
	var dark := Color.WHITE if silhouette else color.darkened(0.45)
	c.draw_rect(Rect2(-6 * s, -14 * s, 5 * s, 14 * s), dark)
	c.draw_rect(Rect2(1 * s, -14 * s, 5 * s, 14 * s), dark)
	c.draw_rect(Rect2(-8 * s, -31 * s, 16 * s, 18 * s), body)
	c.draw_circle(Vector2(0, -38 * s), 7.0 * s, body if silhouette else body.lightened(0.15))
	if silhouette:
		return
	var eye := Color(0.08, 0.06, 0.06)
	if facing == Vector2i(0, 1):
		c.draw_rect(Rect2(-4 * s, -39 * s, 2 * s, 2 * s), eye)
		c.draw_rect(Rect2(2 * s, -39 * s, 2 * s, 2 * s), eye)
	elif facing == Vector2i(-1, 0):
		c.draw_rect(Rect2(-6 * s, -39 * s, 2 * s, 2 * s), eye)
	elif facing == Vector2i(1, 0):
		c.draw_rect(Rect2(4 * s, -39 * s, 2 * s, 2 * s), eye)
	else:
		c.draw_circle(Vector2(0, -40 * s), 5.0 * s, body.darkened(0.3))
	if torch:
		var hand := Vector2(-10 * s if facing == Vector2i(1, 0) else 10 * s, -24 * s)
		c.draw_line(hand, hand + Vector2(0, -10 * s), Color(0.35, 0.22, 0.12), 2.0 * s)
		c.draw_circle(hand + Vector2(0, -13 * s), 3.5 * s, Color(1.0, 0.62, 0.2))
		c.draw_circle(hand + Vector2(0, -14 * s), 1.8 * s, Color(1.0, 0.92, 0.6))


## 옆모습 네발짐승. 왼쪽을 보면 좌우를 뒤집는다.
static func _beast(c: CanvasItem, s: float, color: Color, facing: Vector2i, silhouette: bool) -> void:
	var f := -1.0 if facing.x < 0 else 1.0
	var body := Color.WHITE if silhouette else color
	var dark := Color.WHITE if silhouette else color.darkened(0.45)
	for lx: float in [-11.0, -6.0, 6.0, 11.0]:
		c.draw_rect(Rect2(lx * s * f - 1.5 * s, -10 * s, 3 * s, 10 * s), dark)
	c.draw_rect(Rect2(-14 * s, -20 * s, 28 * s, 11 * s), body)
	c.draw_circle(Vector2(16 * s * f, -20 * s), 6.0 * s, body if silhouette else body.lightened(0.1))
	c.draw_line(Vector2(-14 * s * f, -17 * s), Vector2(-21 * s * f, -23 * s), dark, 2.0 * s)
	if not silhouette:
		c.draw_rect(Rect2(18 * s * f - 1.0 * s, -22 * s, 2 * s, 2 * s), Color(0.9, 0.85, 0.5))


static func _blob(c: CanvasItem, s: float, color: Color, silhouette: bool) -> void:
	var body := Color.WHITE if silhouette else color
	c.draw_circle(Vector2(0, -11 * s), 11.0 * s, body)
	c.draw_circle(Vector2(0, -22 * s), 8.0 * s, body if silhouette else body.lightened(0.1))
	if not silhouette:
		var eye := Color(0.12, 0.08, 0.05)
		c.draw_rect(Rect2(-4 * s, -24 * s, 2 * s, 3 * s), eye)
		c.draw_rect(Rect2(2 * s, -24 * s, 2 * s, 3 * s), eye)
