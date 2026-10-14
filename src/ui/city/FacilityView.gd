class_name FacilityView
extends Control
## 시설 내부: 뒷배경 일러스트(data facilities.interior) + 왼쪽 패널(시설 이름·정보·활동 선택지·결과 텍스트).
## 들어올 때 행동력을 이미 썼으므로 '뒤로'(취소)는 없다. 활동을 한 번 하거나(패널형은 연 순간) 할 수 있는 활동이 없을 때만
## "거리로 나간다"가 열린다. 패널형 활동(상점·은행·정수 제거)은 선택지 자리를 그 패널로 바꾼다.

signal leave_requested

var _state: CityState
var _pc: PlayerCharacter
var _registry: ScriptRegistry
var _facility_id: String = ""
var _info: Label
var _body: VBoxContainer  # 선택지 또는 패널
var _results: VBoxContainer
var _scroll: ScrollContainer
var _leave: Button
var _did_something: bool = false


func setup(state: CityState, pc: PlayerCharacter, registry: ScriptRegistry, facility_id: String) -> void:
	_state = state
	_pc = pc
	_registry = registry
	_facility_id = facility_id


func facility_id() -> String:
	return _facility_id


func _ready() -> void:
	var f := _state.db.get_entry("facilities", _facility_id)
	var bg := TextureRect.new()
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := JsonUtil.get_str(f, "interior")
	bg.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	var panel := GothicWindow.new(JsonUtil.get_str(f, "name_ko", _facility_id))
	panel.custom_minimum_size.x = UiTheme.render_float("city.interior_panel_width", 440.0)
	panel.close_requested.connect(_try_leave)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = m
	panel.offset_top = UiTheme.render_float("city.hud_height", 64.0) + m
	panel.offset_bottom = -m
	panel.offset_right = m + panel.custom_minimum_size.x
	_info = UiTheme.label("", "small", "gold")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.content.add_child(_info)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	panel.content.add_child(_body)
	panel.content.add_child(HSeparator.new())
	panel.content.add_child(UiTheme.label(Strings.t("city.results"), "small", "text_dim"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = UiTheme.render_float("city.result_min_height", 72.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.content.add_child(scroll)
	_scroll = scroll
	panel.content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results = VBoxContainer.new()
	_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_results)
	_leave = UiTheme.button(Strings.t("city.leave"), _try_leave)
	panel.content.add_child(_leave)
	_state.changed.connect(_refresh_info)
	_show_choices()
	_say(Strings.t("city.entered", {"name": JsonUtil.get_str(f, "name_ko", _facility_id), "ap": _state.ap}), "info")


## 활동 선택지(데이터 순서). 못 하는 활동은 이유와 함께 흐리게.
func _show_choices() -> void:
	_clear_body()
	for act_id in CityActions.activities_of(_state, _facility_id):
		var act := _state.activity(act_id)
		var why := CityActions.check(_state, _pc, act_id)
		var b := UiTheme.button(_choice_text(act), func() -> void: _choose(act_id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not why.is_empty()
		b.tooltip_text = JsonUtil.get_str(act, "desc_ko")
		_body.add_child(b)
		var hint := UiTheme.label(JsonUtil.get_str(act, "desc_ko") if why.is_empty() else Strings.t(why), "small", "text_dim" if why.is_empty() else "warn")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(hint)
	_refresh_info()


func _choice_text(act: Dictionary) -> String:
	var parts := PackedStringArray()
	var ap := CityActions.ap_cost(act)
	var stones := CityActions.stone_cost(act)
	parts.append(Strings.t("city.cost_ap", {"n": ap}) if CityValues.is_set(act, "ap_cost") else Strings.t("city.cost_ap_undecided"))
	if stones > 0:
		parts.append(Strings.t("city.cost_stones", {"n": stones}))
	return Strings.t("city.choice", {"name": JsonUtil.get_str(act, "name_ko"), "cost": " · ".join(parts)})


func _choose(act_id: String) -> void:
	var act := _state.activity(act_id)
	var panel := JsonUtil.get_str(act, "panel")
	if panel.is_empty():
		show_result(CityActions.perform(_state, _pc, act_id, _registry))
		_show_choices()
		return
	var why := CityActions.check(_state, _pc, act_id)
	if not why.is_empty():
		_say(Strings.t(why), "warn")
		return
	_did_something = true
	_clear_body()
	var back := UiTheme.button(Strings.t("city.back_to_choices"), _show_choices)
	_body.add_child(back)
	var p: CityPanel
	match panel:
		"shop":
			p = ShopPanel.new()
		"bank":
			p = BankPanel.new()
		"essence_remove":
			p = EssenceRemovePanel.new()
	if p == null:
		return
	p.setup(_state, _pc, act_id)
	p.result.connect(show_result)
	_body.add_child(p)
	_refresh_info()


## 활동 결과(무엇이 얼마나 바뀌었는지)를 결과 칸에 쌓는다.
func show_result(ctx: CityContext) -> void:
	if ctx.ok:
		_did_something = true
		_say(Strings.t("city.did", {"name": JsonUtil.get_str(_state.activity(ctx.activity_id), "name_ko")}), "info")
	for msg: Dictionary in ctx.messages:
		_say(Strings.t(str(msg["key"]), msg["args"]), str(msg["kind"]))
	_refresh_info()


func _say(text: String, kind: String) -> void:
	var l := UiTheme.label(text, "small", "log_" + kind if kind in ["info", "good", "warn"] else "text")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_results.add_child(l)
	while _results.get_child_count() > int(UiTheme.render_float("city.result_lines", 14.0)):
		var old := _results.get_child(0)
		_results.remove_child(old)
		old.queue_free()
	_scroll_to_end.call_deferred()


func _scroll_to_end() -> void:
	if _scroll != null:
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


## 시설별 정보 줄(data facilities.shows: 신전 공적치·은행 잔액·얻은 소문/정보 수) + 나가기 버튼 상태.
func _refresh_info() -> void:
	if _info == null:
		return
	var lines := PackedStringArray([Strings.t("city.info_ap", {"ap": _state.ap})])
	for key: Variant in JsonUtil.get_array(_state.db.get_entry("facilities", _facility_id), "shows"):
		match str(key):
			"temple_merit":
				lines.append(Strings.t("city.info_merit", {"merit": CityContext.fmt(_state.temple_merit)}))
			"bank_balance":
				lines.append(Strings.t("city.info_balance", {"balance": _state.bank_balance}))
			"rumors":
				lines.append(Strings.t("city.info_rumors", {"n": CityInfo.known_of(_state, "rumor").size()}))
			"lore":
				lines.append(Strings.t("city.info_lore", {"n": CityInfo.known_of(_state, "lore").size()}))
	_info.text = "  ·  ".join(lines)
	_leave.disabled = not can_leave()
	_leave.tooltip_text = "" if can_leave() else Strings.t("city.leave_locked")


## 나갈 수 있는가: 활동을 했거나, 할 수 있는 활동이 하나도 없을 때.
func can_leave() -> bool:
	if _did_something:
		return true
	for act_id in CityActions.activities_of(_state, _facility_id):
		if CityActions.check(_state, _pc, act_id).is_empty():
			return false
	return true


func _try_leave() -> void:
	if can_leave():
		leave_requested.emit()
	else:
		_say(Strings.t("city.leave_locked"), "warn")


func _clear_body() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
