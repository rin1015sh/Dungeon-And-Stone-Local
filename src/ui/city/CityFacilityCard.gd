class_name CityFacilityCard
extends PanelContainer
## 건물 정보 카드(위 가운데): 거리에서 가리킨 건물(마우스, 없으면 화면 가운데)의 이름 · 소개 · 할 수 있는 활동과 행동력 ·
## 들어가는 비용(또는 못 들어가는 이유) · 조작 안내. 들어가기 전에 무엇을 할 수 있는지 확인하게 한다.

var _state: CityState
var _pc: PlayerCharacter
var _street: CityStreet
var _title: Label
var _enter: Label
var _desc: Label
var _acts: Label
var _hint: Label


func setup(state: CityState, pc: PlayerCharacter, street: CityStreet) -> void:
	_state = state
	_pc = pc
	_street = street


func _ready() -> void:
	add_theme_stylebox_override("panel", CityUi.card_box())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = UiTheme.render_float("city.card_width", 420.0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 정보만 보여 준다 — 뒤의 거리 클릭을 막지 않는다
	add_child(v)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(head)
	_title = CityUi.label("", "header", "bone")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_enter = CityUi.label("", "small", "accent")
	head.add_child(_enter)
	_desc = CityUi.label("", "small", "dim")
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_desc)
	_acts = CityUi.label("", "small", "bone")
	_acts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_acts)
	_hint = CityUi.label(Strings.t("city.hint", {"left": InputSetup.key_label("move_left"), "right": InputSetup.key_label("move_right"),
		"enter": InputSetup.key_label("menu_confirm")}), "small", "dim")
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_hint)
	var inner := custom_minimum_size.x - UiTheme.render_float("city.ui.card_padding", 12.0) * 2.0
	for l: Label in [_desc, _acts, _hint]:  # 줄바꿈 글상자는 폭을 정해 줘야 높이가 맞게 잡힌다
		l.custom_minimum_size.x = inner
	_street.target_changed.connect(func(_id: String) -> void: refresh())
	_state.changed.connect(refresh)
	refresh()


func refresh() -> void:
	var id := _street.target_id()
	visible = not id.is_empty() and _state.facility.is_empty()
	if id.is_empty():
		return
	var f := _state.db.get_entry("facilities", id)
	_title.text = JsonUtil.get_str(f, "name_ko", id)
	var can := _state.can_spend(_state.entry_cost())
	_enter.text = Strings.t("city.card_enter", {"cost": _state.entry_cost()}) if can else Strings.t("city.reason_no_ap")
	_enter.add_theme_color_override("font_color", CityUi.c("accent" if can else "dim"))
	_desc.text = JsonUtil.get_str(f, "desc_ko")
	_desc.visible = not _desc.text.is_empty()
	var parts := PackedStringArray()
	for act_id in CityActions.activities_of(_state, id):
		var act := _state.activity(act_id)
		var cost := Strings.t("city.cost_ap", {"n": CityActions.ap_cost(act)}) if CityValues.is_set(act, "ap_cost") else Strings.t("city.cost_ap_undecided")
		parts.append(Strings.t("city.card_activity", {"name": JsonUtil.get_str(act, "name_ko"), "cost": cost}))
	_acts.text = Strings.t("city.card_activities", {"list": "  ·  ".join(parts)})
	_fit.call_deferred()


## 글이 바뀌면 최소 크기로 다시 맞춘다(줄바꿈 글상자는 처음 배치 때 높이를 크게 잡을 수 있다). 위 가운데 기준.
func _fit() -> void:
	var ms := get_combined_minimum_size()
	offset_left = -ms.x / 2.0
	offset_right = ms.x / 2.0
	offset_bottom = offset_top + ms.y
