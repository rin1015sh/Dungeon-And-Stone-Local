class_name CityDebugPanel
extends PanelContainer
## 도시 디버그 패널(F1): 날짜·순 바꾸기, 행동력·피로도 설정, 미정(null) 값을 실행 중에만 임시로 넣어 보기.
## 임시값은 CityState.overrides에만 들어간다 — 저장되지 않고 데이터 파일도 바뀌지 않는다. 값은 JSON으로 읽는다(숫자, ["str","agi"], true …).

var _state: CityState
var _pc: PlayerCharacter
var _ap: SpinBox
var _fatigue: SpinBox
var _month: SpinBox
var _period: OptionButton
var _status: Label
var _edits: Dictionary = {}  # 경로 -> LineEdit


func setup(state: CityState, pc: PlayerCharacter) -> void:
	_state = state
	_pc = pc


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	custom_minimum_size.x = UiTheme.render_float("city.debug_width", 420.0)
	var v := VBoxContainer.new()
	add_child(v)
	v.add_child(UiTheme.label(Strings.t("city.debug_title"), "header", "warn"))
	var date := HBoxContainer.new()
	v.add_child(date)
	_month = _spin(date, 1, 9999, _state.month)
	_period = OptionButton.new()
	for i in _state.periods().size():
		_period.add_item(_state.period_name(i))
	_period.selected = _state.period
	date.add_child(_period)
	_btn(date, Strings.t("city.debug_set_date"), _set_date)
	_btn(date, Strings.t("city.debug_next_period"), func() -> void: _state.next_period())
	var ap := HBoxContainer.new()
	v.add_child(ap)
	ap.add_child(UiTheme.label(Strings.t("city.debug_ap"), "small", "text"))
	_ap = _spin(ap, 0, 99, _state.ap)
	_btn(ap, Strings.t("city.debug_apply"), func() -> void:
		_state.ap = int(_ap.value)
		_state.changed.emit())
	ap.add_child(UiTheme.label(Strings.t("city.debug_fatigue"), "small", "text"))
	_fatigue = _spin(ap, -9999, 9999, _pc.fatigue.value)
	_btn(ap, Strings.t("city.debug_apply"), func() -> void: _pc.fatigue.set_value(_fatigue.value))
	v.add_child(HSeparator.new())
	v.add_child(UiTheme.label(Strings.t("city.debug_undecided"), "small", "text_dim"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = UiTheme.render_float("city.debug_list_height", 300.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	for path in CityValues.nulls(_state.db):
		var l := UiTheme.label(path, "small", "text")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.clip_text = true
		l.tooltip_text = path
		grid.add_child(l)
		var e := LineEdit.new()
		e.placeholder_text = Strings.t("city.debug_null")
		e.custom_minimum_size.x = UiTheme.render_float("city.debug_edit_width", 110.0)
		if _state.overrides.has(path):
			e.text = JSON.stringify(_state.overrides[path])
		grid.add_child(e)
		_edits[path] = e
	var row := HBoxContainer.new()
	v.add_child(row)
	_btn(row, Strings.t("city.debug_apply_overrides"), apply_overrides)
	_btn(row, Strings.t("city.debug_clear_overrides"), clear_overrides)
	_status = UiTheme.label("", "small", "text_dim")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_status)
	_state.changed.connect(_sync)


func _sync() -> void:
	_ap.set_value_no_signal(_state.ap)
	_month.set_value_no_signal(_state.month)
	_period.selected = _state.period
	_fatigue.set_value_no_signal(_pc.fatigue.value)


func _set_date() -> void:
	_state.month = int(_month.value)
	_state.period = _period.selected
	_state.changed.emit()


## 입력칸을 읽어 임시값으로 넣는다(빈 칸 = 미정 그대로). 피로도 규칙은 캐릭터에 바로 반영한다.
func apply_overrides() -> void:
	var n := 0
	var bad := PackedStringArray()
	for path: String in _edits:
		var text := (_edits[path] as LineEdit).text.strip_edges()
		if text.is_empty():
			_state.overrides.erase(path)
			continue
		var json := JSON.new()
		if json.parse(text) != OK:
			bad.append(path)
			continue
		_state.overrides[path] = json.data
		n += 1
	_pc.fatigue.setup(CityValues.city_section(_state.db, _state.overrides, "fatigue"), false)
	_state.changed.emit()
	_status.text = Strings.t("city.debug_applied", {"n": n}) + ("" if bad.is_empty() else " " + Strings.t("city.debug_bad", {"list": ", ".join(bad)}))


func clear_overrides() -> void:
	_state.overrides.clear()
	for path: String in _edits:
		(_edits[path] as LineEdit).text = ""
	_pc.fatigue.setup(CityValues.city_section(_state.db, {}, "fatigue"), false)
	_state.changed.emit()
	_status.text = Strings.t("city.debug_cleared")


## 테스트·스모크용: 경로에 값을 넣는다(입력칸도 맞춘다).
func set_edit(path: String, text: String) -> void:
	if _edits.has(path):
		(_edits[path] as LineEdit).text = text


func _spin(parent: Control, lo: float, hi: float, value: float) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1
	s.value = value
	parent.add_child(s)
	return s


func _btn(parent: Control, text: String, cb: Callable) -> void:
	var b := UiTheme.button(text, cb)
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
