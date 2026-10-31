class_name CityScreen
extends Control
## 도시 화면(라비기온 구역): 횡스크롤 거리(CityStreet) ↔ 시설 내부(FacilityView), 귀퉁이 정보 카드(CityHud — 달력·탐험가·메뉴).
## 시설을 고르면 들어가고(행동력 facility_entry_cost가 있어야), 나올 때 그 행동력을 쓴다. 행동력이 0이 되면 다음 순으로 넘어간다.
## 새 게임 시작 후·미궁 귀환 후 모두 이 화면으로 온다. 하순에 행동력을 다 쓰고 거리로 나오면 미궁으로 떠난다(dungeon_requested).
## 시설 안에서 활동을 한 번 하면 결과를 시설 대화창에서 넘긴 뒤 저절로 거리로 나온다. 실내 방이 있는 시설(도서관 — RoomView)은 걸어서 문으로 나온다.
## 행동력은 시설 한 번 다녀오기에 1 — 나올 때 쓴다(CT62). 거리 아래에도 대화창(못 들어가는 이유 등).
## Tab 메뉴(소지품·캐릭터·도감 한 화면, GameMenu)와 디버그 패널(F1)을 쓸 수 있다. 거리에서 Esc = 정지 창(계속 · 타이틀로).
## 마우스는 쓰지 않는다(A/D 스크롤, Enter 들어가기 — 사용자 결정 2026-10-19).

signal dungeon_requested
signal title_requested
signal executed  ## 세금을 못 내고 기한을 넘겼다 — 처형(사망과 같다, CityTax)

var state: CityState
var pc: PlayerCharacter
var _registry: ScriptRegistry
var _street: CityStreet
var _facility: FacilityView
var _hud: CityHud
var _dialog: DialogueBox  # 거리 아래 대화창(못 들어가는 이유 등 — 화면으로 알 수 있는 순 넘김·포션 결과는 보이지 않는다)
var _route: NoticeRoute
var _menu: GameMenu
var _codex: CodexMenu  ## 도감(B — UI32)
var _debug: CityDebugPanel
var _event_running := false  # 거리 사건 장면·선택 중 — 일러스트가 덮고 도시 조작을 막는다
var _event_view: StreetEventView
var _moving := false  # 이사 선택 창이 떠 있다


func setup(p_state: CityState, p_pc: PlayerCharacter, registry: ScriptRegistry) -> void:
	state = p_state
	pc = p_pc
	_registry = registry


func _ready() -> void:
	_street = CityStreet.new()
	_street.setup(state)
	_street.facility_chosen.connect(choose_facility)
	_street.end_reached.connect(offer_move)
	add_child(_street)
	_street.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	_hud = CityHud.new()
	_hud.setup(state, pc)
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu = GameMenu.new()
	_menu.setup(pc, GameState.party() if GameState.player == pc else ([pc] as Array[PlayerCharacter]))
	_menu.use_requested.connect(use_item)
	_menu.opened_changed.connect(func(on: bool) -> void: _street.set_process(not on))
	add_child(_menu)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_codex = CodexMenu.new()
	_codex.setup(pc, state.known_info)
	_codex.opened_changed.connect(func(on: bool) -> void: _street.set_process(not on))
	add_child(_codex)
	_codex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog = DialogueBox.new()  # 전투와 같은 대화창(UI36)
	DialogueBox.place_bottom(_dialog, self)
	_dialog.shown_changed.connect(func(on: bool) -> void: _street.set_process(not on and not _menu.is_open() and not _event_running))
	_menu.hold = _dialog.busy
	_route = NoticeRoute.new(state.db)
	EventBus.notice.connect(_on_notice)
	_debug = CityDebugPanel.new()
	_debug.setup(state, pc)
	_debug.dungeon_requested.connect(func() -> void: dungeon_requested.emit())
	_debug.street_event_requested.connect(street_event.bind(""))
	_debug.visible = false
	add_child(_debug)
	_debug.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_debug.offset_left = m
	_debug.offset_right = m + UiTheme.render_float("city.debug_width", 420.0)
	_debug.offset_top = UiTheme.render_float("city.hud_height", 104.0) + m
	state.expedition_due.connect(_on_expedition_due)
	state.period_started.connect(func(_m: int, _p: int) -> void: street_event.call_deferred(""))
	state.advance_if_spent.call_deferred()  # 행동력이 0인 채로 왔으면 바로 다음 순(하순이면 미궁으로)
	street_event.call_deferred("")  # 시작·귀환한 순의 거리 사건


func street() -> CityStreet:
	return _street


func facility_view() -> FacilityView:
	return _facility


func debug_panel() -> CityDebugPanel:
	return _debug


func is_debug_open() -> bool:
	return _debug.visible


## 거리에서 시설을 고른다: 내부로(행동력은 나올 때). 못 들어가면 안내.
func choose_facility(id: String) -> void:
	if _facility != null or _event_running:
		return
	var why := state.enter_facility(id)
	if not why.is_empty():
		say(Strings.t(why))
		return
	var has_room := not JsonUtil.get_str(state.db.get_entry("facilities", id), "room").is_empty()
	_facility = RoomView.new() if has_room else FacilityView.new()  # 실내 방이 있으면 걸어 다니는 방(CT62)
	_facility.setup(state, pc, _registry, id)
	_facility.leave_requested.connect(leave_facility)
	_facility.art_shown.connect(func() -> void: _hud.visible = false)  # 그림이 덮는 동안 귀퉁이 카드는 숨긴다(요리·책)
	if _facility is RoomView:
		(_facility as RoomView).art_hidden.connect(func() -> void: _hud.visible = true)
	_menu.close()  # 시설 안에서는 Tab 메뉴를 쓰지 않는다
	_hud.set_facility_mode(true)
	add_child(_facility)
	move_child(_facility, _street.get_index() + 1)
	_facility.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_street.visible = false


func leave_facility() -> void:
	if _facility == null:
		return
	for line in _facility.summary():
		say(line)
	_facility.queue_free()
	_facility = null
	_street.visible = true
	_hud.visible = true
	_hud.set_facility_mode(false)
	state.leave_facility()
	_street.refresh()


## 하순이 끝났다: 미궁으로 떠난다(미궁 기록 첫 줄에 남긴다). 세금 기한을 넘겼으면 처형 장면을 넘긴 뒤 끝(CityTax).
func _on_expedition_due() -> void:
	if CityTax.overdue(state, pc.race_id):
		var n := 0
		while Strings.has("city.tax_execution.%d" % (n + 1)):
			n += 1
			say(Strings.t("city.tax_execution.%d" % n), "warn")
		await _dialog.wait()
		if is_inside_tree():
			executed.emit()
		return
	LogPanel.history.append({"text": Strings.t("city.expedition_auto", {"date": CityHud.date_text(state)}), "kind": "info"})
	dungeon_requested.emit()


## 거리 사건(CityAmbient — 행동력 없이 순마다): 일러스트(StreetEventView — 도시를 덮는다) + 장면 → (선택지가 있으면 고르기) → 결과 장면.
## 다 넘기면 일러스트가 사라지고 도시 조작이 돌아온다(그동안 거리 넘기기·들어가기·Tab·Esc 막음, CT45).
## 결과는 장면 글과 화면(소지금·닫힌 건물 흐림)으로 보이고, 효과 문구는 못 받은 것(가방 자리)만 띄운다.
## force_id = 굴리지 않고 그 사건(디버그·테스트·캡처).
func street_event(force_id: String = "") -> void:
	if _event_running or not is_inside_tree():
		return
	var id := CityAmbient.force(state, force_id) if not force_id.is_empty() else CityAmbient.roll(state, pc.race_id)
	if id.is_empty():
		return
	_event_running = true
	_menu.close()
	_street.set_process(false)
	_event_view = StreetEventView.new()
	add_child(_event_view)
	move_child(_event_view, _dialog.get_index())  # 대화창·선택 창은 그림 위
	_event_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_event_view.setup(JsonUtil.get_str(CityAmbient.entry(state, id), "art"))
	for k in CityAmbient.line_keys(id, "intro"):
		say(Strings.t(k))
	var pick := -1
	var choices := CityAmbient.choices(state)
	if not choices.is_empty():
		await _dialog.wait()
		if not is_inside_tree():
			return
		pick = await _street_choice(id, choices)
	var r := CityAmbient.resolve(state, pc, pick, _registry)
	var ctx: CityContext = r["ctx"]
	var args := {}
	for m: Dictionary in ctx.messages:
		args.merge(m["args"] as Dictionary, true)
	for k in CityAmbient.line_keys(id, str(r["outcome"])):
		say(Strings.t(k, args))
	for m: Dictionary in ctx.messages:
		if str(m["key"]) in CityAmbient.SHOWN_FX:
			say(Strings.t(str(m["key"]), m["args"]), str(m["kind"]))
	_hud.refresh()
	_street.refresh()
	await _dialog.wait()
	if not is_inside_tree():
		return
	_event_view.close()
	_event_view = null
	_event_running = false
	_street.set_process(not _menu.is_open() and not _dialog.busy())


func event_view() -> StreetEventView:
	return _event_view


func _street_choice(id: String, choices: Array) -> int:
	var opts: Array[Dictionary] = []
	for c: Variant in choices:
		var d: Dictionary = c
		var cost := int(CityValues.num(d, "cost_stones"))
		var can := CityAmbient.can_choose(pc, d)
		opts.append({"text": Strings.t("city.street.%s.choice.%s" % [id, JsonUtil.get_str(d, "id")]),
			"sub": Strings.t("city.cost_stones", {"n": cost}) if cost > 0 else "", "enabled": can,
			"desc": "" if can else Strings.t("city.reason_no_money")})
	var pop := ChoicePopup.new()
	pop.name = "StreetChoice"
	add_child(pop)
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pop.open(JsonUtil.get_str(CityAmbient.entry(state, id), "name_ko"), opts, false, Vector2(-1, -1))
	var i: int = await pop.picked
	pop.queue_free()
	return i


## 거리 오른쪽 끝에서 D: 다음 구역으로 이사(값을 내고 — 행동력은 쓰지 않는다, CT60). 가장 높으면 이유 한 줄.
func offer_move() -> void:
	if _facility != null or _event_running or _moving or _menu.is_open() or _dialog.busy():
		return
	var cost := CityResidence.next_cost(state)
	if cost < 0:
		say(Strings.t("city.reason_residence_max"))
		return
	_moving = true
	var can := pc.inventory.money >= cost
	var opts: Array[Dictionary] = [
		{"text": CityResidence.name_of(state, CityResidence.tier(state) + 1), "sub": Strings.t("city.cost_stones", {"n": cost}),
			"enabled": can, "desc": "" if can else Strings.t("city.reason_no_money")},
		{"text": Strings.t("city.move_cancel")}]
	var i: int = await ChoicePopup.ask(self, Strings.t("city.move_title"), opts, true)
	_moving = false
	if i == 0 and CityResidence.upgrade(state, pc).is_empty():
		state.changed.emit()
		_street.refresh()
		_hud.refresh()


## 거리에서 소지품 쓰기(city.json item_use.categories 분류만 — 포션 등). 결과는 막대·소지품으로 보이니 글로 알리지 않는다.
func use_item(item_id: String) -> void:
	if _facility != null:
		return
	var db := state.db
	var cats := JsonUtil.get_array(CityValues.city_section(db, state.overrides, "item_use"), "categories")
	if not JsonUtil.get_str(db.get_entry("items", item_id), "category") in cats:
		say(Strings.t("city.cannot_use_here"), "warn")
		return
	var ctx := ItemUser.use(DataRegistry.registries.effects, pc, item_id, state.rng, _menu.shown())  # Tab에서 고른 아군에게
	if ctx == null:
		return
	for m: Dictionary in ctx.messages:
		_on_notice(str(m["key"]), m["args"], str(m["kind"]))
	_menu.refresh()
	_hud.refresh()


## 거리 아래 대화창에 한 줄(Enter로 넘김).
func say(text: String, kind: String = "info") -> void:
	if not text.is_empty():
		_dialog.say(text, kind)


func dialog() -> DialogueBox:
	return _dialog


func menu() -> GameMenu:
	return _menu


## 문구 키 알림(Tab 메뉴의 가방 자리 없음 등) → 화면으로 알 수 없는 것만 대화창(NoticeRoute).
func _on_notice(key: String, args: Dictionary, kind: String) -> void:
	if is_inside_tree() and not is_queued_for_deletion() and not _route.silent(key):
		say(Strings.t(key, args), kind)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_debug.visible = not _debug.visible
		get_viewport().set_input_as_handled()
		return
	if get_viewport().gui_get_focus_owner() is LineEdit or has_node("StreetChoice") or _event_running:  # 거리 사건 중엔 도시 조작 없음
		return
	var pause_pop := get_node_or_null("PauseChoice") as ChoicePopup
	if pause_pop != null:  # 정지 창: W/S·Enter는 창이 먼저 받는다, Esc = 계속
		if event.is_action_pressed("pause"):
			pause_pop.picked.emit(-1)
		if event is InputEventKey or event is InputEventAction:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu") and _facility == null:
		_menu.toggle()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("codex") and _facility == null and not _menu.is_open():
		_codex.open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):  # Esc: 시설에서 나가기 · 메뉴 닫기 · (거리에서) 정지 창
		if _facility != null:
			_facility.try_leave()
		elif _menu.is_open():
			_menu.close()
		elif event.is_action_pressed("pause"):
			_pause_choice()
		get_viewport().set_input_as_handled()


## 거리의 정지 창: 계속 · 타이틀로(W/S·Enter, Esc = 계속 — Backspace는 쓰지 않는다).
func _pause_choice() -> void:
	var pop := ChoicePopup.new()
	pop.name = "PauseChoice"
	add_child(pop)
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_street.set_process(false)
	pop.open(Strings.t("explore.paused"), [{"text": Strings.t("pause.resume")}, {"text": Strings.t("city.btn_title")}], false, Vector2(-1, -1))
	var i: int = await pop.picked
	pop.queue_free()
	if not is_inside_tree():
		return
	_street.set_process(true)
	if i == 1:
		title_requested.emit()
