class_name ChoicePopup
extends Control
## 작은 선택 창(사용자 결정 2026-10-16 — 획득할까? · 누가 받을까?): 질문 한 줄 + 세로 선택지(ChoiceGrid 1열).
## 키: W/S(menu_up/down) 커서, Enter(menu_confirm) 고르기, Esc(pause)는 can_back일 때만 뒤로(-1).
## 선택지: {"text", "sub", "enabled", "desc"(못 고르는 이유)}.
##   var i: int = await ChoicePopup.ask(parent, "질문", options, can_back, 가리킬 자리)

signal picked(index: int)

var grid: ChoiceGrid
var _panel: PanelContainer
var _desc: Label
## near 아래에 띄운다(전투 드롭 — 쓰러진 자리 표시 바로 아래, 사용자 요청 2026-10-24 "획득 창을 조금 내려").
var below: bool = false


## 띄우고 고를 때까지 기다린다. near(부모 좌표)가 있으면 그 위에(below면 그 아래에), 없으면 가운데. 돌려주는 값 = 고른 칸 번호(뒤로 = -1).
static func ask(parent: Control, title: String, options: Array[Dictionary], can_back: bool = false, near: Vector2 = Vector2(-1, -1), below: bool = false) -> int:
	var pop := ChoicePopup.new()
	pop.below = below
	parent.add_child(pop)
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pop.open(title, options, can_back, near)
	var i: int = await pop.picked
	pop.queue_free()
	return i


func open(title: String, options: Array[Dictionary], can_back: bool, near: Vector2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	_panel.add_child(v)
	var head := UiTheme.label(title, "body", "text_title")
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size.x = UiTheme.metric("popup_width", 340)
	v.add_child(head)
	grid = ChoiceGrid.new(1, clampi(options.size(), 1, UiTheme.metric("popup_rows", 5)), UiTheme.metric("popup_slot_height", 40), true)
	v.add_child(grid)
	_desc = UiTheme.label("", "small", "warn")  # 커서가 놓인 칸의 이유(못 받는 사람 등) — 있을 때만
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size.x = head.custom_minimum_size.x
	_desc.visible = options.any(func(o: Dictionary) -> bool: return not str(o.get("desc", "")).is_empty())
	v.add_child(_desc)
	grid.cursor_moved.connect(func(_i: int) -> void: _desc.text = str(grid.current_option().get("desc", "")))
	var opts: Array[Dictionary] = []
	for i in options.size():
		var o := options[i].duplicate()
		var idx := i
		o["on_pick"] = func() -> void: picked.emit(idx)
		opts.append(o)
	grid.show_choices(title, opts, (func() -> void: picked.emit(-1)) if can_back else Callable())
	_place.call_deferred(near)


## 고를 수 있는 첫 칸 번호(테스트·자동 진행용).
func first_enabled() -> int:
	for i in grid.option_count():
		if bool(grid.option(i).get("enabled", true)):
			return i
	return -1


func _place(near: Vector2) -> void:
	var sz := _panel.get_combined_minimum_size()
	_panel.size = sz
	var gap := float(UiTheme.metric("popup_gap", 24))
	var p := (size - sz) * 0.5 if near.x < 0.0 else (near + Vector2(-sz.x * 0.5, gap) if below else near - Vector2(sz.x * 0.5, sz.y + gap))
	var m := float(UiTheme.metric("margin", 16))
	_panel.position = Vector2(clampf(p.x, m, maxf(m, size.x - sz.x - m)), clampf(p.y, m, maxf(m, size.y - sz.y - m)))
