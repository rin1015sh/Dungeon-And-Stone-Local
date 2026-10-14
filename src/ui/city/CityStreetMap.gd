class_name CityStreetMap
extends PanelContainer
## 거리 지도(오른쪽 위): 거리 전체를 한 줄로 줄여 시설 위치(이름)와 지금 보이는 구간(테두리 상자)을 보여 준다.
## 누르거나 끌면 그 위치로 거리를 스크롤한다. 가리킨(정보 카드) 시설은 호박색, 행동력이 모자라면 모두 흐리게.

var _state: CityState
var _street: CityStreet
var _strip: Control
var _dragging: bool = false


func setup(state: CityState, street: CityStreet) -> void:
	_state = state
	_street = street


func _ready() -> void:
	add_theme_stylebox_override("panel", CityUi.card_box())
	mouse_filter = Control.MOUSE_FILTER_STOP
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	add_child(v)
	v.add_child(CityUi.label(Strings.t("city.map_title"), "small", "dim"))
	_strip = Control.new()
	_strip.custom_minimum_size = Vector2(UiTheme.render_float("city.map_width", 380.0), UiTheme.render_float("city.map_height", 46.0))
	_strip.mouse_filter = Control.MOUSE_FILTER_PASS
	_strip.draw.connect(_draw_strip)
	v.add_child(_strip)
	_street.target_changed.connect(func(_id: String) -> void: _strip.queue_redraw())
	_state.changed.connect(_strip.queue_redraw)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_strip.queue_redraw()


func _draw_strip() -> void:
	var w := _strip.size.x
	var h := _strip.size.y
	var line_y := h * 0.32
	_strip.draw_line(Vector2(0, line_y), Vector2(w, line_y), CityUi.c("border"), 2.0)
	var total := maxf(1.0, _street.street_px())
	var x0 := _street.offset() / total * w
	var x1 := (_street.offset() + _street.size.x) / total * w
	_strip.draw_rect(Rect2(x0, 2, maxf(4.0, x1 - x0), line_y * 2.0 - 4.0), Color(CityUi.c("bone"), 0.12))
	_strip.draw_rect(Rect2(x0, 2, maxf(4.0, x1 - x0), line_y * 2.0 - 4.0), CityUi.c("bone"), false, 1.0)
	var font := get_theme_default_font()
	var fs := UiTheme.metric("small_font_size", 14) - 2
	var can := _state.can_spend(_state.entry_cost())
	var target := _street.target_id()
	for id in _state.facility_ids():
		var x := _street.facility_ratio(id) * w
		var col := CityUi.c("accent") if id == target else CityUi.c("bone" if can else "dim")
		_strip.draw_rect(Rect2(x - 4, line_y - 4, 8, 8), col)
		var name := JsonUtil.get_str(_state.db.get_entry("facilities", id), "name_ko", id)
		var tw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_strip.draw_string(font, Vector2(clampf(x - tw / 2.0, 0.0, w - tw), h - 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		_dragging = mb.pressed
		if mb.pressed:
			_jump(mb.position)
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm != null and _dragging:
		_jump(mm.position)
		accept_event()


## 지도의 그 지점이 화면 가운데에 오게 스크롤.
func _jump(pos: Vector2) -> void:
	var local := pos - _strip.position
	var ratio := clampf(local.x / maxf(1.0, _strip.size.x), 0.0, 1.0)
	_street.scroll_to(ratio * _street.street_px() - _street.size.x / 2.0)
