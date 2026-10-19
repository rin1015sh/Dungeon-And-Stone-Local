class_name ChoiceGrid
extends VBoxContainer
## 고정 칸 선택판(포켓몬 기술 창처럼): 정해진 테두리 칸 열×줄(render.json combat_menu_columns·rows, 기본 2×3 = 한 쪽 6칸)에
## 선택지를 하나씩 넣는다. 칸 수·크기는 늘 같고(빈 칸도 테두리가 남는다), 넘치면 쪽을 나눈다(◀ 1/3 ▶).
##   키: menu_up/down/left/right(WASD) 커서 이동 — 맨 왼쪽·오른쪽 칸에서 한 번 더 누르면 이전·다음 쪽,
##       menu_confirm(Enter) 확정, menu_back(Backspace) 뒤로. 마우스는 쓰지 않는다(사용자 결정 2026-10-19).
##   커서가 놓인 선택지의 설명(못 쓰면 그 이유)은 칸 아래 설명줄에 나온다.
## 선택지: {"text", "sub"(칸 오른쪽 아래 작은 글씨 — 대가·남은 차례·확률), "enabled", "desc", "on_pick": Callable}
## 칸은 Button이지만 포커스를 받지 않는다(Enter가 엔진 기본 ui_accept로 엉뚱한 버튼을 누르지 않게 키는 직접 받는다).
## 선택지에 "on_adjust": Callable(dir)이 있으면 그 칸에서 A/D는 쪽 넘기기 대신 값을 바꾼다(은행 금액 등).

signal cursor_moved(index: int)

## 키 입력을 받는가(전투 행동창은 명령 칸과 목록 칸 두 판 중 하나만 받는다). 꺼져 있으면 커서는 그대로 보인다.
var active: bool = true

var _head: HBoxContainer
var _title: Label
var _prev: Label
var _page: Label
var _next: Label
var _slots: Array[Button] = []
var _subs: Array[Label] = []
var _marks: Array[Label] = []
var _desc: Label
var _options: Array[Dictionary] = []
var _back: Callable = Callable()
var _cursor: int = 0
var _cols: int = 2
var _rows: int = 3
var _slot_h: int = 50
var _compact: bool = false


## cols·rows 0이면 render.json combat_menu_columns·rows. slot_h 0이면 combat_slot_height. compact = 제목줄·설명줄 없이 칸만(쪽이 여럿이면 쪽 표시만).
func _init(cols: int = 0, rows: int = 0, slot_h: int = 0, compact: bool = false) -> void:
	_cols = maxi(1, cols if cols > 0 else UiTheme.metric("combat_menu_columns", 2))
	_rows = maxi(1, rows if rows > 0 else UiTheme.metric("combat_menu_rows", 3))
	_slot_h = slot_h if slot_h > 0 else UiTheme.metric("combat_slot_height", 50)
	_compact = compact
	var head := HBoxContainer.new()
	head.visible = not compact
	_head = head
	add_child(head)
	_title = UiTheme.label("", "body", "text_title")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	head.add_child(_title)
	_prev = _arrow(Strings.t("menu.page_prev"))
	head.add_child(_prev)
	_page = UiTheme.label("", "small", "text_dim")
	head.add_child(_page)
	_next = _arrow(Strings.t("menu.page_next"))
	head.add_child(_next)
	var grid := GridContainer.new()
	grid.columns = _cols
	var gap := UiTheme.metric("combat_slot_gap", 4)
	grid.add_theme_constant_override("h_separation", gap)
	grid.add_theme_constant_override("v_separation", gap)
	add_child(grid)
	for i in _cols * _rows:
		grid.add_child(_make_slot(i))
	_desc = UiTheme.label("", "small", "text_dim")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.max_lines_visible = UiTheme.metric("combat_desc_lines", 3)
	_desc.custom_minimum_size.y = UiTheme.metric("combat_desc_height", 40)
	_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc.visible = not compact
	add_child(_desc)


## 선택지를 채운다. back이 없으면(맨 위 메뉴) 뒤로 키는 아무 일도 하지 않는다. start = 처음 커서 자리.
func show_choices(title: String, options: Array[Dictionary], back: Callable = Callable(), start: int = 0) -> void:
	_title.text = title
	_options = options
	_back = back
	_cursor = clampi(start, 0, maxi(0, _options.size() - 1))
	_render()
	cursor_moved.emit(_cursor)  # 처음 자리도 알린다(대상 카드 강조)


func clear() -> void:
	_options = []
	_back = Callable()
	_cursor = 0
	_render()


func title_text() -> String:
	return _title.text


func cursor() -> int:
	return _cursor


## 커서가 놓인 선택지(없으면 {}).
func current_option() -> Dictionary:
	return _options[_cursor] if _cursor >= 0 and _cursor < _options.size() else {}


func option_count() -> int:
	return _options.size()


func option(i: int) -> Dictionary:
	return _options[i] if i >= 0 and i < _options.size() else {}


func page_size() -> int:
	return _cols * _rows


func page_count() -> int:
	return maxi(1, ceili(float(_options.size()) / float(page_size())))


## 모든 쪽의 선택지 글자(테스트·도움말용).
func option_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for o in _options:
		out.append(str(o.get("text", "")))
	return out


func _input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree() or not (event.is_pressed()):
		return
	var act := ""
	for a: String in ["menu_up", "menu_down", "menu_left", "menu_right"]:
		if InputMap.has_action(a) and event.is_action_pressed(a, true):
			act = a
	for a: String in ["menu_confirm", "menu_back"]:
		if InputMap.has_action(a) and event.is_action_pressed(a):
			act = a
	if act.is_empty():
		return
	get_viewport().set_input_as_handled()  # 먼저 막는다 — 확정으로 이 판이 닫히거나 사라질 수 있다
	match act:
		"menu_up":
			move(0, -1)
		"menu_down":
			move(0, 1)
		"menu_left":
			if not _adjust(-1):
				move(-1, 0)
		"menu_right":
			if not _adjust(1):
				move(1, 0)
		"menu_confirm":
			confirm()
		"menu_back":
			go_back()


## 커서 이동. 위아래는 같은 쪽 안에서만, 좌우는 끝 칸에서 한 번 더 가면 쪽을 넘긴다.
func move(dx: int, dy: int) -> void:
	if _options.is_empty():
		return
	var per := page_size()
	var page := _cursor / per
	var pos := _cursor % per
	var col := pos % _cols
	var row := pos / _cols
	var on_page := mini(per, _options.size() - page * per)
	if dy != 0:
		var r := row + dy
		if r < 0 or r * _cols >= on_page:
			return  # 그 줄에는 선택지가 없다
		_set_cursor(page * per + mini(r * _cols + col, on_page - 1))
		return
	var c := col + dx
	if c >= 0 and c < _cols and row * _cols + c < on_page:
		_set_cursor(page * per + row * _cols + c)
		return
	var np := page + dx
	if np < 0 or np >= page_count():
		return
	var n_on := mini(per, _options.size() - np * per)
	_set_cursor(np * per + mini(row * _cols + (0 if dx > 0 else _cols - 1), n_on - 1))


## 커서 자리의 선택지를 고른다(못 쓰는 선택지면 아무 일도 없다 — 이유는 설명줄에 이미 보인다).
func confirm() -> void:
	if _cursor < 0 or _cursor >= _options.size():
		return
	var o := _options[_cursor]
	if not bool(o.get("enabled", true)):
		return
	var cb: Callable = o.get("on_pick", Callable())
	if cb.is_valid():
		cb.call()


## 커서 칸에 on_adjust가 있으면 값을 바꾸고 true.
func _adjust(dir: int) -> bool:
	var cb: Callable = current_option().get("on_adjust", Callable())
	if not cb.is_valid():
		return false
	cb.call(dir)
	return true


func go_back() -> void:
	if _back.is_valid():
		_back.call()


func _set_cursor(i: int) -> void:
	if i == _cursor or i < 0 or i >= _options.size():
		return
	_cursor = i
	_render()
	cursor_moved.emit(i)


func _render() -> void:
	var per := page_size()
	var page := _cursor / per
	var pages := page_count()
	_page.text = Strings.t("menu.page", {"page": page + 1, "pages": pages})
	for l: Label in [_prev, _page, _next]:
		l.visible = pages > 1
	_head.visible = not _compact or pages > 1  # 칸만 보이는 판도 쪽이 여럿이면 쪽 표시는 보인다
	_prev.modulate.a = 1.0 if page > 0 else 0.3
	_next.modulate.a = 1.0 if page < pages - 1 else 0.3
	for i in _slots.size():
		var idx := page * per + i
		var has := idx < _options.size()
		var o: Dictionary = _options[idx] if has else {}
		var b := _slots[i]
		b.text = str(o.get("text", "")) if has else Strings.t("menu.empty_slot")
		b.disabled = not has or not bool(o.get("enabled", true))
		_subs[i].text = str(o.get("sub", ""))
		var sel := has and idx == _cursor
		_marks[i].visible = sel
		_style(b, "empty" if not has else ("selected" if sel else ""))
	var cur: Dictionary = _options[_cursor] if _cursor < _options.size() else {}
	_desc.text = str(cur.get("desc", ""))
	_desc.add_theme_color_override("font_color", UiTheme.color("warn" if not bool(cur.get("enabled", true)) else "text_dim"))


func _make_slot(i: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(UiTheme.metric("combat_slot_min_width", 160), _slot_h)
	b.pressed.connect(_on_slot_pressed.bind(i))
	var mark := UiTheme.label(Strings.t("menu.cursor"), "small", "gold")
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.position = Vector2(UiTheme.metric("combat_slot_mark_x", 6), UiTheme.metric("combat_slot_mark_y", 6))
	b.add_child(mark)
	var sub := UiTheme.label("", "small", "text_dim")
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sub.clip_text = true
	sub.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.offset_right = -UiTheme.metric("combat_slot_pad", 8)
	sub.offset_bottom = -2
	b.add_child(sub)
	_slots.append(b)
	_subs.append(sub)
	_marks.append(mark)
	return b


## 칸 꾸밈. state: "" / "selected"(커서, 금색 테두리) / "empty"(빈 칸 — 테두리만)
func _style(b: Button, state: String) -> void:
	var bg := UiTheme.color("slot_hover" if state == "selected" else ("frame_dark" if state == "empty" else "slot"))
	var border := UiTheme.color("gold" if state == "selected" else "slot_border")
	var box := UiTheme.box(bg, border, 2, 0)
	box.set_border_width_all(2 if state == "selected" else 1)
	box.content_margin_left = UiTheme.metric("combat_slot_text_x", 22)
	box.content_margin_right = UiTheme.metric("combat_slot_pad", 8)
	box.content_margin_top = 2
	box.content_margin_bottom = 2 if _compact else UiTheme.metric("combat_slot_sub_height", 18)  # 아래쪽은 작은 글씨(sub) 자리
	for s: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		b.add_theme_stylebox_override(s, box)
	var fg := UiTheme.color("text_title" if state == "selected" else "text")
	for s: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(s, fg)
	b.add_theme_color_override("font_disabled_color", UiTheme.color("text_disabled"))


## 칸 버튼의 pressed(스모크 테스트가 누른다 — 화면에서는 키로만 고른다).
func _on_slot_pressed(i: int) -> void:
	if not active:
		return
	var idx := (_cursor / page_size()) * page_size() + i
	if idx < _options.size():
		_set_cursor(idx)
		confirm()


func _arrow(text: String) -> Label:
	return UiTheme.label(text, "small", "text_title")
