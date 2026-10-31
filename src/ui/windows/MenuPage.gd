class_name MenuPage
extends PanelContainer
## Tab 메뉴(GameMenu)의 한 쪽(소지품 · 캐릭터 · 도감): 게임 전체 창 판(UiTheme.panel_box) + 위 글자 제목·가는 선 + 내용(content).
## 지금 쪽은 제목이 밝고, 다른 쪽은 통째로 한 단계 어둡다(금색 테두리 없음 — 사용자 결정 2026-10-29, UI45).
## 키는 GameMenu가 받아 지금 쪽(active)에 넘긴다 — nav(방향)·confirm(Enter)·back(Esc).
## nav가 false를 돌려주면(그 방향에 고를 것이 없다) GameMenu가 옆 쪽으로 옮긴다.

var content: VBoxContainer
## 쪽 안의 작은 선택 창을 띄울 곳(GameMenu — 화면 전체를 덮는다). 클래스 이름으로 서로 부르면 종료 때 누수라 Control로 받는다.
var popup_host: Control = null
var _title: Label
var active: bool = false:
	set(v):
		active = v
		_paint()
		on_active(v)


func _init(title: String) -> void:
	_paint()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	add_child(v)
	_title = UiTheme.label(title, "body", "text_dim")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_title)
	var line := ColorRect.new()
	line.color = UiTheme.color("frame_edge")
	line.custom_minimum_size.y = cfg("title_line", 1.0)
	v.add_child(line)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(content)


## 커서 이동(d = (±1, 0) / (0, ±1)). 그 방향에 더 고를 것이 없으면 false.
func nav(_d: Vector2i) -> bool:
	return false


## Enter: 커서 자리를 고른다.
func confirm() -> void:
	pass


## Esc: 쪽 안에서 물릴 것(옮기던 물건 등)이 있으면 물리고 true. 없으면 false(GameMenu가 닫는다).
func back() -> bool:
	return false


## 옆 쪽에서 넘어왔다(from_left = 왼쪽 쪽에서 오른쪽으로 왔다).
func enter(_from_left: bool) -> void:
	pass


func refresh() -> void:
	pass


## 쪽 안의 작은 선택 창이 키를 받는 중이다(GameMenu는 아무 키도 받지 않는다).
func busy() -> bool:
	return false


## 지금 쪽이 되거나 아니게 됐다(커서 그리기 등).
func on_active(_on: bool) -> void:
	pass


func _paint() -> void:
	var b := UiTheme.see_through(UiTheme.panel_box(UiTheme.metric("padding", 8)), cfg("page_alpha", 0.97))
	if active:
		b.border_color = UiTheme.color("frame_edge")
	add_theme_stylebox_override("panel", b)
	var shade := 1.0 if active else cfg("inactive_shade", 0.75)
	modulate = Color(shade, shade, shade)
	if _title != null:
		_title.add_theme_color_override("font_color", UiTheme.color("text_title" if active else "text_dim"))


## render.json ui.menu 값.
static func cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("menu"), key, fallback)


## 방향 d로 from에서 가장 가까운 사각형 번호(없으면 -1). 그 방향 부채꼴 안에서 진행 방향 거리 + 옆으로 벗어난 거리 × 2가 가장 작은 것.
static func nearest(rects: Array[Rect2], from: Rect2, d: Vector2i) -> int:
	var c := from.get_center()
	var dir := Vector2(d)
	var best := -1
	var best_score := INF
	for i in rects.size():
		var r := rects[i]
		if r.is_equal_approx(from):
			continue
		var off := r.get_center() - c
		var ahead := off.dot(dir)
		if ahead <= 1.0:
			continue
		var side := absf(off.dot(Vector2(-dir.y, dir.x)))
		if side > ahead * 1.5:  # 그 방향 부채꼴(약 56도) 밖
			continue
		var score := ahead + side * 2.0
		if score < best_score:
			best_score = score
			best = i
	return best
