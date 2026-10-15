class_name FacilityView
extends Control
## 시설 내부: 뒷배경 일러스트(data facilities.interior) + 오른쪽 패널(시설 이름·정보·활동 선택지·결과 텍스트).
## 왼쪽의 달력·탐험가 카드와 오른쪽 위 메뉴(CityHud)는 그대로 보인다 — 패널은 메뉴 아래부터(top_reserve).
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
var top_reserve: float = 0.0  ## 패널 위에 비워 둘 높이(메뉴 자리)
var _summary: PackedStringArray = []  # 마지막 활동 결과(거리로 나간 뒤 알림으로 보여 준다)


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
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var path := JsonUtil.get_str(f, "interior")
	bg.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	var panel := CityUi.card()
	panel.custom_minimum_size.x = UiTheme.render_float("city.interior_panel_width", 440.0)
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	panel.add_child(content)
	var head := HBoxContainer.new()
	content.add_child(head)
	var title := CityUi.label(JsonUtil.get_str(f, "name_ko", _facility_id), "header", "bone")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := CityUi.button("✕", _try_leave)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.tooltip_text = Strings.t("window.close")
	head.add_child(close)
	var desc := CityUi.label(JsonUtil.get_str(f, "desc_ko"), "small", "dim")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.visible = not desc.text.is_empty()
	content.add_child(desc)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_right = -m
	panel.offset_left = -m - panel.custom_minimum_size.x
	panel.offset_top = maxf(float(m), top_reserve)
	panel.offset_bottom = -m
	_info = CityUi.label("", "small", "accent")
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_info)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	content.add_child(_body)
	content.add_child(HSeparator.new())
	content.add_child(CityUi.label(Strings.t("city.results"), "small", "dim"))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = UiTheme.render_float("city.result_min_height", 72.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	content.add_child(scroll)
	_scroll = scroll
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results = VBoxContainer.new()
	_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_results)
	_leave = CityUi.button(Strings.t("city.leave"), _try_leave, true)
	content.add_child(_leave)
	_state.changed.connect(_refresh_info)
	_show_choices()
	_say(Strings.t("city.entered", {"name": JsonUtil.get_str(f, "name_ko", _facility_id), "ap": _state.ap}), "info")


## 활동 선택지(데이터 순서). 못 하는 활동은 이유와 함께 흐리게.
func _show_choices() -> void:
	_clear_body()
	for act_id in CityActions.activities_of(_state, _facility_id):
		var act := _state.activity(act_id)
		var why := CityActions.check(_state, _pc, act_id)
		var b := CityUi.button(_choice_text(act), func() -> void: _choose(act_id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not why.is_empty()
		b.tooltip_text = JsonUtil.get_str(act, "desc_ko")
		_body.add_child(b)
		var hint := UiTheme.label(JsonUtil.get_str(act, "desc_ko") if why.is_empty() else Strings.t(why), "small", "text_dim" if why.is_empty() else "warn")
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(hint)
	_refresh_info()


## 활동 이름(+ 이용료가 있으면 이용료). 시설 안 활동은 행동력을 쓰지 않는다.
func _choice_text(act: Dictionary) -> String:
	var name := JsonUtil.get_str(act, "name_ko")
	var stones := CityActions.stone_cost(act)
	return Strings.t("city.choice", {"name": name, "cost": Strings.t("city.cost_stones", {"n": stones})}) if stones > 0 else name


func _choose(act_id: String) -> void:
	var act := _state.activity(act_id)
	var panel := JsonUtil.get_str(act, "panel")
	if panel.is_empty():
		var ctx := CityActions.perform(_state, _pc, act_id, _registry)
		show_result(ctx)
		if ctx.ok:  # 활동 한 번 = 이 방문의 끝: 저절로 거리로 나간다
			leave_requested.emit.call_deferred()
		else:
			_show_choices()
		return
	var why := CityActions.check(_state, _pc, act_id)
	if not why.is_empty():
		_say(Strings.t(why), "warn")
		return
	_did_something = true
	_clear_body()  # 창구(상점·은행·정수 제거)는 연 것이 이 방문의 활동 — 거래를 마치면 "거리로 나간다"
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
	_summary.clear()
	if ctx.ok:
		_did_something = true
		var did := Strings.t("city.did", {"name": JsonUtil.get_str(_state.activity(ctx.activity_id), "name_ko")})
		_say(did, "info")
		_summary.append(did)
	for msg: Dictionary in ctx.messages:
		var text := Strings.t(str(msg["key"]), msg["args"])
		_say(text, str(msg["kind"]))
		if ctx.ok:
			_summary.append(text)


## 마지막 활동 결과 문구(거리로 나간 뒤 화면 위 알림에 쓴다).
func summary() -> PackedStringArray:
	return _summary
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
	var lines := PackedStringArray()
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
	_info.visible = not lines.is_empty()
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
