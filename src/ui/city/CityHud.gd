class_name CityHud
extends Control
## 도시 화면 정보(위 띠 하나에 몰지 않고 귀퉁이에 나눈다 — 거리 그림은 가운데에 둔다):
##   왼쪽 위 = 달력 카드(장소 · 날짜 · 상순/중순/하순 진행 · 행동력 구슬 · 순 넘김 안내),
##   왼쪽 아래 = 탐험가 카드(이름·레벨 · 소지금 · 생명력 막대 · 피로도),
##   오른쪽 위 = 메뉴(소지품 · 캐릭터 · 미궁 입장(임시) · 타이틀로).
## 은행 잔액·신전 공적치는 그 시설 안에서만 보인다(facilities shows). 아래 가운데·오른쪽은 건물 이름판 자리.

signal dungeon_requested
signal title_requested
signal window_requested(kind: String)

var _state: CityState
var _pc: PlayerCharacter
var _date: Label
var _periods: Array[Label] = []
var _pips: Label
var _ap: Label
var _name: Label
var _hp_bar: ProgressBar
var _hp: Label
var _fatigue: Label
var _money: Label
var _dock: PanelContainer


func setup(state: CityState, pc: PlayerCharacter) -> void:
	_state = state
	_pc = pc


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := UiTheme.metric("margin", 16)
	_build_calendar(m)
	_build_vitals(m)
	_build_dock(m)
	_state.changed.connect(refresh)
	_pc.inventory.money_changed.connect(func(_m: int) -> void: refresh())
	_pc.fatigue.changed.connect(func(_v: float, _d: float, _s: String) -> void: refresh())
	refresh()


## 시설 패널이 비워 둘 위쪽 높이(메뉴 아래부터).
func dock_bottom() -> float:
	return UiTheme.metric("margin", 16) + _dock.get_combined_minimum_size().y


func _build_calendar(m: int) -> void:
	var box := CityUi.card()
	box.custom_minimum_size.x = UiTheme.render_float("city.calendar_width", 300.0)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var place: Dictionary = CityValues.city_section(_state.db, {}, "place")
	v.add_child(CityUi.label(Strings.t("city.place", {"city": JsonUtil.get_str(place, "city_ko"), "district": JsonUtil.get_str(place, "district_ko")}), "small", "dim"))
	_date = CityUi.label("", "header", "bone")
	v.add_child(_date)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	v.add_child(row)
	for i in _state.periods().size():
		var l := CityUi.label(_state.period_name(i), "small", "dim")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		_periods.append(l)
	var ap := HBoxContainer.new()
	v.add_child(ap)
	ap.add_child(CityUi.label(Strings.t("city.ap_label"), "body", "bone"))
	_pips = CityUi.label("", "body", "accent")
	_pips.add_theme_font_size_override("font_size", int(UiTheme.render_float("city.pip_font_size", 24.0)))
	_pips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ap.add_child(_pips)
	_ap = CityUi.label("", "body", "bone")
	ap.add_child(_ap)
	var hint := CityUi.label(Strings.t("city.period_hint"), "small", "dim")
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = box.custom_minimum_size.x - UiTheme.render_float("city.ui.card_padding", 12.0) * 2.0
	v.add_child(hint)


func _build_vitals(m: int) -> void:
	var box := CityUi.card()
	box.custom_minimum_size.x = UiTheme.render_float("city.vitals_width", 300.0)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, m)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	_name = CityUi.label("", "body", "bone")
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	top.add_child(_name)
	_money = CityUi.label("", "body", "accent")
	top.add_child(_money)
	var hp := HBoxContainer.new()
	v.add_child(hp)
	hp.add_child(CityUi.label(Strings.t("city.hp_label"), "small", "dim"))
	_hp_bar = CityUi.bar(UiTheme.render_color("city.ui.blood").lightened(0.15))
	hp.add_child(_hp_bar)
	_hp = CityUi.label("", "small", "bone")
	hp.add_child(_hp)
	_fatigue = CityUi.label("", "small", "bone")
	v.add_child(_fatigue)


func _build_dock(m: int) -> void:
	_dock = CityUi.card()
	_dock.custom_minimum_size.x = UiTheme.render_float("city.dock_width", 400.0)
	add_child(_dock)
	_dock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, m)
	_dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_dock.add_child(v)
	var r1 := HBoxContainer.new()
	v.add_child(r1)
	r1.add_child(CityUi.button(Strings.t("city.btn_inventory", {"key": InputSetup.key_label("inventory")}), func() -> void: window_requested.emit("inventory")))
	r1.add_child(CityUi.button(Strings.t("city.btn_character", {"key": InputSetup.key_label("character")}), func() -> void: window_requested.emit("character")))
	var r2 := HBoxContainer.new()
	v.add_child(r2)
	r2.add_child(CityUi.button(Strings.t("city.btn_dungeon"), func() -> void: dungeon_requested.emit(), true))
	r2.add_child(CityUi.button(Strings.t("city.btn_title"), func() -> void: title_requested.emit()))


func refresh() -> void:
	_date.text = date_text(_state)
	for i in _periods.size():
		var now := i == _state.period
		_periods[i].add_theme_color_override("font_color", CityUi.c("accent" if now else "dim"))
		_periods[i].text = ("▸ %s" if now else "%s") % _state.period_name(i)
	var pips := PackedStringArray()
	for i in _state.ap_per_period():
		pips.append("●" if i < _state.ap else "○")
	_pips.text = " ".join(pips)
	_ap.text = Strings.t("city.ap_value", {"ap": _state.ap, "max": _state.ap_per_period()})
	_name.text = Strings.t("city.vitals_name", {"name": _pc.display_name, "level": _pc.get_level()})
	var hp := _pc.pool.get_current("hp")
	var hp_max := _pc.pool.get_max("hp")
	_hp_bar.max_value = maxf(1.0, hp_max)
	_hp_bar.value = hp
	_hp.text = Strings.t("city.hp_value", {"hp": roundi(hp), "max": roundi(hp_max)})
	_fatigue.text = Strings.t("city.hud_fatigue", {"value": CityContext.fmt(_pc.fatigue.value)})
	_money.text = Strings.t("city.hud_money", {"money": _pc.inventory.money})


## "○번째 달 상순"(2년째부터는 연도를 붙인다). 연·월 이름 정의가 없어 시작부터 센 달로 표시한다.
static func date_text(state: CityState) -> String:
	var args := {"month": state.month_of_year(), "period": state.period_name(), "year": state.year()}
	return Strings.t("city.date_year" if state.year() > 1 else "city.date", args)
