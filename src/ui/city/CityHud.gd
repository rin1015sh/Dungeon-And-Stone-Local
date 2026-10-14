class_name CityHud
extends PanelContainer
## 도시 상단 정보 띠: 장소 이름 · 날짜(○번째 달 상순) · 남은 행동력 · 생명력 · 피로도 · 소지금
## + 버튼(기록 보기 · 소지품 · 캐릭터 · 미궁 입장(임시) · 타이틀로).

signal dungeon_requested
signal title_requested
signal info_requested
signal window_requested(kind: String)

var _state: CityState
var _pc: PlayerCharacter
var _place: Label
var _date: Label
var _ap: Label
var _hp: Label
var _fatigue: Label
var _money: Label


func setup(state: CityState, pc: PlayerCharacter) -> void:
	_state = state
	_pc = pc


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HFlowContainer.new()  # 좁은 화면(모바일 웹)에서는 줄을 바꾼다
	row.add_theme_constant_override("h_separation", UiTheme.metric("spacing", 8) + UiTheme.metric("spacing", 8) / 2)
	add_child(row)
	var place: Dictionary = CityValues.city_section(_state.db, {}, "place")
	_place = _add(row, UiTheme.label(Strings.t("city.place", {"city": JsonUtil.get_str(place, "city_ko"),
		"district": JsonUtil.get_str(place, "district_ko")}), "body", "text_title"))
	_date = _add(row, UiTheme.label("", "body", "gold"))
	_ap = _add(row, UiTheme.label("", "body", "text"))
	_hp = _add(row, UiTheme.label("", "body", "text"))
	_fatigue = _add(row, UiTheme.label("", "body", "text"))
	_money = _add(row, UiTheme.label("", "body", "gold"))
	_btn(row, Strings.t("city.btn_info"), func() -> void: info_requested.emit())
	_btn(row, Strings.t("city.btn_inventory", {"key": InputSetup.key_label("inventory")}), func() -> void: window_requested.emit("inventory"))
	_btn(row, Strings.t("city.btn_character", {"key": InputSetup.key_label("character")}), func() -> void: window_requested.emit("character"))
	_btn(row, Strings.t("city.btn_dungeon"), func() -> void: dungeon_requested.emit())
	_btn(row, Strings.t("city.btn_title"), func() -> void: title_requested.emit())
	_state.changed.connect(refresh)
	_pc.inventory.money_changed.connect(func(_m: int) -> void: refresh())
	_pc.fatigue.changed.connect(func(_v: float, _d: float, _s: String) -> void: refresh())
	refresh()


func refresh() -> void:
	_date.text = date_text(_state)
	var pips := ""
	for i in _state.ap_per_period():
		pips += "●" if i < _state.ap else "○"
	_ap.text = Strings.t("city.hud_ap", {"pips": pips, "ap": _state.ap, "max": _state.ap_per_period()})
	_hp.text = Strings.t("city.hud_hp", {"hp": roundi(_pc.pool.get_current("hp")), "max": roundi(_pc.pool.get_max("hp"))})
	_fatigue.text = Strings.t("city.hud_fatigue", {"value": CityContext.fmt(_pc.fatigue.value)})
	_money.text = Strings.t("city.hud_money", {"money": _pc.inventory.money})


## "○번째 달 상순"(2년째부터는 연도를 붙인다). 연·월 이름 정의가 없어 시작부터 센 달로 표시한다.
static func date_text(state: CityState) -> String:
	var args := {"month": state.month_of_year(), "period": state.period_name(), "year": state.year()}
	return Strings.t("city.date_year" if state.year() > 1 else "city.date", args)


func _add(parent: Control, l: Label) -> Label:
	parent.add_child(l)
	return l


func _btn(parent: Control, text: String, cb: Callable) -> void:
	var b := UiTheme.button(text, cb)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", UiTheme.metric("small_font_size", 14))
	parent.add_child(b)
