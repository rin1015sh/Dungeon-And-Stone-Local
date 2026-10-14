class_name CityStreet
extends Control
## 라비기온 거리(옆에서 본 가로로 긴 그림)를 좌우로 스크롤하며 시설 건물을 고른다.
##   스크롤: 마우스 드래그·휠, A/D·←/→(이동 키). 고르기: 클릭·탭, 또는 화면 가운데 건물을 Space/F/Enter.
##   고를 수 있는(행동력이 되는) 건물은 이름판이 강조되고, 마우스를 올리거나 가운데에 오면 밝아진다.
## 건물 위치·그림 경로는 data(facilities x·building, city.json street.backdrop), 크기·속도는 render.json city.
## 그림 파일이 없으면 이름판과 빈 자리만 그린다(그림 없이도 고를 수 있다).

signal facility_chosen(facility_id: String)

const STREET_H := 240.0  ## 밑그림 높이(px) — 화면 높이에 맞춰 확대한다
const FALLBACK_SIZE := Vector2(140, 140)

var _state: CityState
var _content: Control
var _backdrop: TextureRect
var _buildings: Array[Dictionary] = []  # {id, node: Control, art: TextureRect, plate: PanelContainer, label: Label, x, w, h}
var _offset: float = 0.0
var _scale: float = 3.0
var _street_w: float = 1360.0
var _hover: int = -1
var _focus: int = -1
var _press_pos: Vector2 = Vector2.ZERO
var _pressing: bool = false
var _dragged: bool = false


func setup(state: CityState) -> void:
	_state = state


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_backdrop = TextureRect.new()
	_backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.texture = _tex(JsonUtil.get_str(CityValues.city_section(_state.db, {}, "street"), "backdrop"))
	_content.add_child(_backdrop)
	if _backdrop.texture != null:
		_street_w = _backdrop.texture.get_width()
	for id in _state.facility_ids():
		_add_building(id)
	resized.connect(_layout)
	_state.changed.connect(refresh)
	_layout()
	refresh()


func _add_building(id: String) -> void:
	var f := _state.db.get_entry("facilities", id)
	var node := Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(node)
	var art := TextureRect.new()
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _tex(JsonUtil.get_str(f, "building"))
	node.add_child(art)
	var size_px := Vector2(art.texture.get_size()) if art.texture != null else FALLBACK_SIZE
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiTheme.label(JsonUtil.get_str(f, "name_ko", id), "body", "text_title")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(label)
	_content.add_child(plate)
	_buildings.append({"id": id, "node": node, "art": art, "plate": plate, "label": label,
		"x": float(JsonUtil.get_int(f, "x")), "w": size_px.x, "h": size_px.y})
	_street_w = maxf(_street_w, float(JsonUtil.get_int(f, "x")) + size_px.x)


func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null


func _layout() -> void:
	if size.y <= 0.0:
		return
	_scale = size.y / STREET_H
	var baseline := float(UiTheme.render_float("city.baseline", 196.0))
	_backdrop.position = Vector2.ZERO
	_backdrop.size = Vector2(_street_w, STREET_H) * _scale
	for b in _buildings:
		var node: Control = b["node"]
		node.position = Vector2(float(b["x"]), baseline - float(b["h"])) * _scale
		node.size = Vector2(float(b["w"]), float(b["h"])) * _scale
		(b["art"] as TextureRect).size = node.size
		var plate: PanelContainer = b["plate"]
		plate.reset_size()
		plate.position = Vector2((float(b["x"]) + float(b["w"]) / 2.0) * _scale - plate.size.x / 2.0,
			baseline * _scale + UiTheme.render_float("city.plate_offset_px", 10.0))
	scroll_to(_offset)


func max_offset() -> float:
	return maxf(0.0, _street_w * _scale - size.x)


func scroll_to(x: float) -> void:
	_offset = clampf(x, 0.0, max_offset())
	_content.position.x = -roundf(_offset)
	_update_focus()


func scroll_by(dx: float) -> void:
	scroll_to(_offset + dx)


func offset() -> float:
	return _offset


## 화면에 보이는 건물을 강조(행동력이 되는 건물 = 이름판 금테, 안 되는 건물 = 흐리게).
func refresh() -> void:
	if _state == null:
		return
	var can := _state.can_spend(_state.entry_cost()) and _state.facility.is_empty()
	for i in _buildings.size():
		var b := _buildings[i]
		var lit := i == _hover or (i == _focus and _hover < 0)
		var bright := 1.0 + (UiTheme.render_float("city.hover_brighten", 0.18) if lit and can else 0.0)
		var dim := 1.0 - (UiTheme.render_float("city.dim_unaffordable", 0.35) if not can else 0.0)
		(b["node"] as Control).modulate = Color(bright * dim, bright * dim, bright * dim * 0.97)
		var plate: PanelContainer = b["plate"]
		var box := GothicStyle.plaque_box()
		if can:
			box.border_color = UiTheme.color("gold") if not lit else UiTheme.render_color("city.selected_outline", UiTheme.color("gold"))
			box.set_border_width_all(2 if lit else 1)
		plate.add_theme_stylebox_override("panel", box)
		(b["label"] as Label).add_theme_color_override("font_color", UiTheme.color("text_title" if can else "text_disabled"))


func focused_id() -> String:
	return str(_buildings[_focus]["id"]) if _focus >= 0 and _focus < _buildings.size() else ""


func building_rect(id: String) -> Rect2:
	for b in _buildings:
		if str(b["id"]) == id:
			var node: Control = b["node"]
			return Rect2(node.position + _content.position, node.size)
	return Rect2()


## 화면 가운데에 가장 가까운 건물(키보드 선택 대상).
func _update_focus() -> void:
	var center := _offset + size.x / 2.0
	var best := -1
	var best_d := INF
	for i in _buildings.size():
		var b := _buildings[i]
		var mid := (float(b["x"]) + float(b["w"]) / 2.0) * _scale
		var d := absf(mid - center)
		if d < best_d:
			best_d = d
			best = i
	if best != _focus:
		_focus = best
		refresh()


func _hit(local: Vector2) -> int:
	var p := local - _content.position
	for i in range(_buildings.size() - 1, -1, -1):
		var node: Control = _buildings[i]["node"]
		var plate: PanelContainer = _buildings[i]["plate"]
		if Rect2(node.position, node.size).has_point(p) or Rect2(plate.position, plate.size).has_point(p):
			return i
	return -1


func _process(delta: float) -> void:
	if not is_visible_in_tree() or get_viewport().gui_get_focus_owner() is LineEdit:
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		scroll_by(dir * UiTheme.render_float("city.scroll_px_per_sec", 900.0) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("interact"):
		var id := focused_id()
		if not id.is_empty():
			get_viewport().set_input_as_handled()
			facility_chosen.emit(id)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			if mb.pressed:
				scroll_by(-UiTheme.render_float("city.wheel_step_px", 140.0))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN or mb.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			if mb.pressed:
				scroll_by(UiTheme.render_float("city.wheel_step_px", 140.0))
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_dragged = false
				_press_pos = mb.position
			elif _pressing:
				_pressing = false
				if not _dragged:
					var i := _hit(mb.position)
					if i >= 0:
						facility_chosen.emit(str(_buildings[i]["id"]))
			accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null:
		if _pressing:
			if not _dragged and mm.position.distance_to(_press_pos) >= UiTheme.render_float("city.drag_threshold_px", 10.0):
				_dragged = true
			if _dragged:
				scroll_by(-mm.relative.x)
		var h := _hit(mm.position)
		if h != _hover:
			_hover = h
			refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and _hover >= 0:
		_hover = -1
		refresh()
