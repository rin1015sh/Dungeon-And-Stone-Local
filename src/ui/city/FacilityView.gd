class_name FacilityView
extends Control
## 시설 내부(피어 앤 헝거식 배치, 사용자 요청 2026-10-18 "건물 안 UI 재배치 · 나가기 버튼"):
##   뒷배경 일러스트(data facilities.interior)를 화면 가득 가리지 않고,
##   아래 = 대화창(DialogueBox — 이름판에 시설 이름, 평소엔 시설 정보 줄, 활동 결과는 한 쪽씩 Enter로 넘김),
##   대화창 위 오른쪽 = 선택 창(활동 + 맨 끝 "나가기", W/S·Enter — 도시에서는 Backspace를 쓰지 않는다, 사용자 결정 2026-10-20).
## 왼쪽 위 달력·탐험가 카드는 그대로, 오른쪽 위 메뉴(소지품·캐릭터)는 숨긴다(시설 안에서는 창을 쓰지 않는다).
## 들어올 때 쓴 행동력은 돌려주지 않는다 — 활동 전에 나가도 된다(나가기 버튼, 사용자 결정 2026-10-18: 예전엔 활동 전엔 못 나갔다).
## 활동 한 번이면 결과를 다 넘긴 뒤 저절로 거리로 나간다. 패널형 활동(상점·은행·정수 제거)은 선택 창 자리에 그 패널(선택판 맨 끝 나가기)을 열고,
## 거래 결과는 대화창에 남긴다(거래마다 Enter를 누르지 않게 넘기지 않는 글로). 할 수 있는 활동이 하나도 없으면 들어오자마자 그 이유를 들고 나간다.

signal leave_requested
signal art_shown  ## 결과 그림(요리·펼친 책)이 시설 안을 덮었다 — 도시 화면이 귀퉁이 카드를 숨긴다

var _state: CityState
var _pc: PlayerCharacter
var _registry: ScriptRegistry
var _facility_id: String = ""
var _dialog: DialogueBox
var _menu: PanelContainer  # 선택 창(또는 패널) 카드
var _grid: ChoiceGrid
var _panel_box: VBoxContainer
var _leaving: bool = false
var top_reserve: float = 0.0  ## 패널 위에 비워 둘 높이(메뉴 자리)
var _art_pic: Control = null  # 결과 그림(요리·펼친 책)이 덮고 있으면 그 그림
var _summary: PackedStringArray = []  # 할 게 없어 바로 나갈 때의 이유(거리 화면 위 알림으로 보여 준다)


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
	var path := CityResidence.building_path(JsonUtil.get_str(f, "interior"), CityResidence.tier(_state))  # 구역마다 다른 내부(<경로>_t<등급> — CT54)
	bg.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog = DialogueBox.new()  # 전투와 같은 대화창(UI36)
	DialogueBox.place_bottom(_dialog, self)
	_dialog.set_speaker(JsonUtil.get_str(f, "name_ko", _facility_id))
	_dialog.shown_changed.connect(func(_on: bool) -> void: _sync_menu())
	_dialog.drained.connect(_sync_menu)
	_menu = CityUi.card()
	add_child(_menu)
	_menu.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu.custom_minimum_size.x = UiTheme.render_float("city.interior_menu_width", 300.0)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	_menu.add_child(stack)
	_grid = ChoiceGrid.new(1, maxi(1, _entries().size() + 1), int(UiTheme.render_float("city.interior_slot_height", 40.0)), true)
	stack.add_child(_grid)
	_panel_box = VBoxContainer.new()
	_panel_box.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	_panel_box.visible = false
	stack.add_child(_panel_box)
	_state.changed.connect(_refresh_info)
	_show_choices()
	_refresh_info()
	_menu.minimum_size_changed.connect(_place_menu)
	resized.connect(_place_menu)
	_place_menu.call_deferred()
	if _nothing_to_do():  # 할 게 없다: 이유만 남기고 나간다
		_leave_empty()


## 선택 창: 활동(데이터 순서 — 이용료는 칸 오른쪽 아래, 못 하면 그 자리에 이유) + 맨 끝 나가기.
## 상점·대장간 창구(panel "shop")는 [구매]·[판매] 두 칸으로 나눠 바로 그 쪽을 연다(사용자 결정 2026-10-24).
func _show_choices(cursor: int = -1) -> void:
	var opts: Array[Dictionary] = []
	for e: Array in _entries():
		var act_id := str(e[0])
		var tab := str(e[1])
		var act := _state.activity(act_id)
		var why := CityActions.check(_state, _pc, act_id)
		opts.append({"text": Strings.t("city.shop_tab_" + tab) if not tab.is_empty() else JsonUtil.get_str(act, "name_ko"), "enabled": why.is_empty(),
			"sub": Strings.t(why) if not why.is_empty() else CityActions.price_text(_state, _pc, act_id),
			"on_pick": func() -> void: _choose(act_id, tab)})
	opts.append({"text": Strings.t("city.leave"), "on_pick": try_leave})
	_grid.show_choices("", opts, Callable(), cursor if cursor >= 0 else _grid.cursor())
	_sync_menu()


## 선택 창의 칸들: [활동 id, 창구 쪽("" 또는 buy·sell)].
func _entries() -> Array[Array]:
	var out: Array[Array] = []
	for act_id in CityActions.activities_of(_state, _facility_id):
		if JsonUtil.get_str(_state.activity(act_id), "panel") == "shop":
			for tab in CityShop.tabs(_state, act_id):  # 거래소는 판매만(활동 tabs — CT54)
				out.append([act_id, tab])
		else:
			out.append([act_id, ""])
	return out


func _choose(act_id: String, tab: String = "") -> void:
	var act := _state.activity(act_id)
	var panel := JsonUtil.get_str(act, "panel")
	if panel.is_empty():
		var ctx := CityActions.perform(_state, _pc, act_id, _registry)
		show_result(ctx)
		if ctx.ok:  # 활동 한 번 = 이 방문의 끝: 결과를 다 넘기면 저절로 거리로 나간다
			_leaving = true
			_sync_menu()
			await _dialog.wait()
			if is_inside_tree():
				leave_requested.emit.call_deferred()
		else:
			_show_choices()
		return
	var why := CityActions.check(_state, _pc, act_id)
	if not why.is_empty():
		_dialog.say(Strings.t(why), "warn")
		return
	var p: CityPanel  # 창구(상점·은행·정수 제거)는 연 것이 이 방문의 활동 — 거래를 마치면 나가기·Esc
	match panel:
		"shop":
			var sp := ShopPanel.new()
			sp.mode = tab if tab in ShopPanel.TABS else "buy"
			sp.back = _close_panel.bind(_entries().find([act_id, sp.mode]))
			p = sp
		"bank":
			p = BankPanel.new()
		"essence_remove":
			p = EssenceRemovePanel.new()
	if p == null:
		return
	p.setup(_state, _pc, act_id)
	p.leave = try_leave
	p.result.connect(_on_trade)
	_panel_box.add_child(p)
	_menu.custom_minimum_size.x = UiTheme.render_float("city.interior_panel_width", 440.0)
	_sync_menu()


## 창구를 닫고 선택 창으로(커서는 연 칸에).
func _close_panel(cursor: int) -> void:
	for c in _panel_box.get_children():
		_panel_box.remove_child(c)
		c.queue_free()
	_menu.custom_minimum_size.x = UiTheme.render_float("city.interior_menu_width", 300.0)
	_show_choices(maxi(0, cursor))
	_refresh_info()
	_menu.reset_size()
	_place_menu.call_deferred()


## 활동 결과(무엇이 얼마나 바뀌었는지)를 대화창에 쌓는다(한 쪽씩 Enter).
func show_result(ctx: CityContext) -> void:
	_art_pic = _show_art(ctx)
	if ctx.ok:
		_dialog.say(Strings.t("city.did", {"name": JsonUtil.get_str(_state.activity(ctx.activity_id), "name_ko")}), "info")
	for msg: Dictionary in ctx.messages:
		_dialog.say(CityLines.text(_state, ctx.activity_id, msg), str(msg["kind"]))


## 결과 그림이 실내 그림 위를 가득 덮는다 — 여관 식사(city.meal.<요리 id> → data/meals art, CT47) ·
## 도서관 서적(city.fx.book_new → 그 분야의 펼친 책 그림 city.json library.fields art, CT57 — 글은 아래 대화창에).
## 대화창은 그 위. 결과를 다 넘기면 방문이 끝나 거리로 나가며 함께 사라진다(실내 방 RoomView는 다 넘기면 걷어 낸다 — 덮은 그림을 돌려준다).
func _show_art(ctx: CityContext) -> Control:
	for msg: Dictionary in ctx.messages:
		var key := str(msg["key"])
		var art := ""
		if key.begins_with("city.meal."):
			art = JsonUtil.get_str(_state.db.get_entry("meals", key.trim_prefix("city.meal.")), "art")
		elif key == "city.fx.book_new":
			art = CityInfo.field_art(_state.db, JsonUtil.get_str(msg.get("args", {}), "field"))
		else:
			continue
		if art.is_empty() or not ResourceLoader.exists(art):
			return null
		var pic := TextureRect.new()
		pic.texture = load(art) as Texture2D
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(pic)
		move_child(pic, _dialog.get_index())
		pic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pic.modulate.a = 0.0
		create_tween().tween_property(pic, "modulate:a", 1.0, UiTheme.render_float("city.meal_art.fade_sec", 0.35))
		art_shown.emit()
		return pic
	return null


## 창구 거래 결과: 넘기지 않는 글로 대화창에 남긴다(마지막 거래만).
func _on_trade(ctx: CityContext) -> void:
	var lines := PackedStringArray()
	var kind := "info"
	for msg: Dictionary in ctx.messages:
		lines.append(CityLines.text(_state, ctx.activity_id, msg))
		kind = str(msg["kind"])
	_dialog.idle_kind = kind if kind in ["info", "good", "warn"] else ""
	_dialog.idle_text = "\n".join(lines) if not lines.is_empty() else _info_text()


## 할 게 없어 바로 나갈 때의 이유(거리로 나간 뒤 알림으로 쓴다).
func summary() -> PackedStringArray:
	return _summary


## 선택 창을 보일지: 결과를 넘기는 중·나가는 중이면 숨기고 키도 받지 않는다. 패널이 열렸으면 선택판 대신 패널.
func _sync_menu() -> void:
	if _menu == null:
		return
	var panel_open := _panel_box.get_child_count() > 0
	_menu.visible = not _leaving and (panel_open or not _dialog.busy())
	_panel_box.visible = panel_open
	_grid.visible = not panel_open
	_grid.active = _menu.visible and not panel_open and not _dialog.busy()
	for p in _panel_box.get_children():
		(p as CityPanel).active = _menu.visible and not _dialog.busy()


## 선택 창 자리: 대화창 바로 위 오른쪽(패널이 크면 위로 자란다 — 메뉴 자리 top_reserve 아래까지).
func _place_menu() -> void:
	var m := float(UiTheme.metric("margin", 16))
	var sz := _menu.get_combined_minimum_size()
	_menu.offset_right = -m
	_menu.offset_left = -m - sz.x
	_menu.offset_bottom = _dialog.offset_top - m * 0.5
	_menu.offset_top = maxf(_menu.offset_bottom - sz.y, -size.y + maxf(m, top_reserve))


## 시설별 정보 줄(data facilities.shows: 신전 공적치·은행 잔액·얻은 소문/정보 수) — 대화창의 평소 글.
func _refresh_info() -> void:
	if _dialog == null:
		return
	if _panel_box.get_child_count() == 0:
		_dialog.idle_kind = ""
		_dialog.idle_text = _info_text()


func _info_text() -> String:
	var lines := PackedStringArray()
	for key: Variant in JsonUtil.get_array(_state.db.get_entry("facilities", _facility_id), "shows"):
		match str(key):
			"temple_merit":
				lines.append(Strings.t("city.info_merit", {"merit": CityContext.fmt(_state.temple_merit)}))
			"bank_balance":
				lines.append(Strings.t("city.info_balance", {"balance": _state.bank_balance}))
			"residence":
				lines.append(Strings.t("city.info_residence", {"name": CityResidence.name_of(_state)}))
			"lore":
				lines.append(Strings.t("city.info_lore", {"n": CityInfo.known_of(_state).size()}))
			"survey":
				if not CityGuild.target(_state).is_empty():
					lines.append(Strings.t("city.info_survey", {"name": DataNames.entry(_state.db, "monsters", CityGuild.target(_state)),
						"n": mini(_pc.knowledge.surveys(CityGuild.target(_state)), CityGuild.cap(_state)), "cap": CityGuild.cap(_state),
						"stones": CityGuild.payout_each(_state)}))
	return "  ·  ".join(lines) if not lines.is_empty() else " "  # 비워 두면 대화창(이름판)이 사라진다


func _nothing_to_do() -> bool:
	if JsonUtil.get_bool(_state.db.get_entry("facilities", _facility_id), "placeholder"):
		return false  # 기능이 아직 없는 시설: 둘러보고 나가기만
	for act_id in CityActions.activities_of(_state, _facility_id):
		if CityActions.check(_state, _pc, act_id).is_empty():
			return false
	return true


## 나가기(선택판의 나가기·Esc). 들어올 때 쓴 행동력은 돌려주지 않는다.
func try_leave() -> void:
	if _leaving and _dialog.busy():
		return  # 결과를 넘기는 중 — 다 넘기면 저절로 나간다
	_leaving = true
	leave_requested.emit.call_deferred()


## 들어왔지만 할 수 있는 활동이 없다: 못 하는 이유(겹치면 한 번)를 알림으로 들고 거리로.
func _leave_empty() -> void:
	_summary.clear()
	for act_id in CityActions.activities_of(_state, _facility_id):
		var why := Strings.t(CityActions.check(_state, _pc, act_id))
		if not why in _summary:
			_summary.append(why)
	_leaving = true
	leave_requested.emit.call_deferred()
