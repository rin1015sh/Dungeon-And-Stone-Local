class_name GothicStyle
extends RefCounted
## 스톤샤드풍 창 꾸밈(이미지 없이 코드로): 돌판 테두리 창 · 움푹한 칸 · 이름판 · 고딕 아치 띠.
## 색은 render.json palette(frame*, slot*, plaque, arch*).


## 창 바깥: 어두운 돌판 + 두꺼운 테두리 + 그림자.
static func frame_box() -> StyleBoxFlat:
	var b := UiTheme.box(UiTheme.color("frame"), UiTheme.color("frame_edge"), 3, UiTheme.metric("padding", 8))
	b.set_border_width_all(3)
	b.shadow_color = Color(0, 0, 0, 0.6)
	b.shadow_size = 8
	return b


## 창 안쪽 판(장비 인형·격자 바탕).
static func inset_box() -> StyleBoxFlat:
	var b := UiTheme.box(UiTheme.color("frame_dark"), UiTheme.color("slot_border"), 2, 6)
	b.set_border_width_all(2)
	return b


## 아이템 칸. state: "" / "hover" / "ok"(놓을 수 있음) / "bad"(못 놓음)
static func slot_box(state: String = "") -> StyleBoxFlat:
	var bg := UiTheme.color("slot")
	match state:
		"hover":
			bg = UiTheme.color("slot_hover")
		"ok":
			bg = UiTheme.color("slot_ok")
		"bad":
			bg = UiTheme.color("slot_bad")
	var b := UiTheme.box(bg, UiTheme.color("slot_border"), 2, 0)
	b.set_border_width_all(1)
	return b


## 제목 이름판.
static func plaque_box() -> StyleBoxFlat:
	var b := UiTheme.box(UiTheme.color("plaque"), UiTheme.color("frame_light"), 2, 6)
	b.set_border_width_all(2)
	b.content_margin_left = 24
	b.content_margin_right = 24
	return b


## 칸 하나를 직접 그린다(격자처럼 많은 칸을 한 Control에 그릴 때).
static func draw_slot(c: CanvasItem, r: Rect2, state: String = "") -> void:
	slot_box(state).draw(c.get_canvas_item(), r)


## 고딕 아치가 줄지어 선 장식 띠(창 머리). 아치마다 어두운 벽감 + 테두리 선 + 가운데 기둥.
static func draw_arches(c: CanvasItem, r: Rect2, count: int = 5) -> void:
	c.draw_rect(r, UiTheme.color("arch"))
	var w := r.size.x / count
	var line := UiTheme.color("arch_line")
	var dark := UiTheme.color("frame_dark")
	for i in count:
		var x0 := r.position.x + i * w + w * 0.16
		var x1 := r.position.x + (i + 1) * w - w * 0.16
		var top := r.position.y + r.size.y * 0.12
		var spring := r.position.y + r.size.y * 0.45
		var bottom := r.end.y
		var mid := (x0 + x1) * 0.5
		var pts := PackedVector2Array()
		pts.append(Vector2(x0, bottom))
		pts.append(Vector2(x0, spring))
		for k in range(1, 7):
			var t := k / 6.0
			pts.append(Vector2(lerpf(x0, mid, t), lerpf(spring, top, sqrt(t))))
		for k in range(1, 7):
			var t := k / 6.0
			pts.append(Vector2(lerpf(mid, x1, t), lerpf(top, spring, t * t)))
		pts.append(Vector2(x1, bottom))
		c.draw_colored_polygon(pts, dark)
		c.draw_polyline(pts, line, 2.0)
		# 벽감 속 석상 실루엣
		var head := Vector2(mid, spring + (bottom - spring) * 0.12)
		c.draw_circle(head, w * 0.07, line)
		c.draw_rect(Rect2(mid - w * 0.09, head.y + w * 0.06, w * 0.18, bottom - head.y - w * 0.06), line)
	c.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), UiTheme.color("frame_edge"), 3.0)
