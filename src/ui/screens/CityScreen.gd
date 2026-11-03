class_name CityScreen
extends Control
## 도시 화면(라비기온 7구역): 걸어 다니는 동네 지도(TownView — 2D 3/4 탑뷰, CT82 — 횡스크롤 거리는 버렸다) ↔ 시설 창(FacilityView — 동네 위에 어둡게),
## 귀퉁이 정보 카드(CityHud — 달력·탐험가·메뉴).
## 시설 문 앞에서 Enter = 들어가기(행동력 facility_entry_cost를 들어갈 때 쓴다 — CT72). 안에서는 활동을 몇 번이든, 나가기·Esc로 그 문 앞에.
## 행동력이 0인 채로 나오면 다음 순, 하순이면 미궁으로 떠난다(dungeon_requested). 새 게임 시작 후·미궁 귀환 후 모두 이 화면으로 온다.
## Tab 메뉴(GameMenu)·도감(B)·디버그 패널(F1)은 동네를 걷는 동안. Esc = 정지 창(계속 · 타이틀로). 동네 아래에도 대화창(못 들어가는 이유 등).
## 마우스는 쓰지 않는다(W/A/S/D 걷기, Enter 들어가기 — 사용자 결정 2026-10-19).

signal dungeon_requested
signal title_requested
signal executed  ## 세금을 못 내고 기한을 넘겼다 — 처형(사망과 같다, CityTax)

var state: CityState
var pc: PlayerCharacter
var _registry: ScriptRegistry
var _town: TownView
var _facility: FacilityView
var _hud: CityHud
var _dialog: DialogueBox  # 거리 아래 대화창(못 들어가는 이유 등 — 화면으로 알 수 있는 순 넘김·포션 결과는 보이지 않는다)
var _route: NoticeRoute
var _menu: GameMenu
var _codex: CodexMenu  ## 도감(B — UI32)
var _debug: CityDebugPanel
var _event_running := false  # 거리 사건 장면·선택 중 — 일러스트가 덮고 도시 조작을 막는다
var _event_view: StreetEventView
var _moving := false  # 특별 시설로 가는 창이 떠 있다


func setup(p_state: CityState, p_pc: PlayerCharacter, registry: ScriptRegistry) -> void:
	state = p_state
	pc = p_pc
	_registry = registry


func _ready() -> void:
	_town = TownView.new()
	_town.setup(state, pc)
	_town.facility_chosen.connect(choose_facility)
	_town.travel_requested.connect(offer_travel)
	_town.told.connect(func(key: String) -> void: say(Strings.t(key)))
	add_child(_town)
	_town.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	_hud = CityHud.new()
	_hud.setup(state, pc)
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu = GameMenu.new()
	_menu.setup(pc, GameState.party() if GameState.player == pc else ([pc] as Array[PlayerCharacter]))
	_menu.use_requested.connect(use_item)
	_menu.opened_changed.connect(_on_overlay)
	add_child(_menu)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_codex = CodexMenu.new()
	_codex.setup(pc, state.known_info)
	_codex.opened_changed.connect(_on_overlay)
	add_child(_codex)
	_codex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog = DialogueBox.new()  # 전투와 같은 대화창(UI36)
	DialogueBox.place_bottom(_dialog, self)
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
	state.period_started.connect(func(_m: int, _p: int) -> void: _town.refresh_weather())
	state.advance_if_spent.call_deferred()  # 행동력이 0인 채로 왔으면 바로 다음 순(하순이면 미궁으로)
	street_event.call_deferred("")  # 시작·귀환한 순의 거리 사건


func town() -> TownView:
	return _town


## 동네 걷기를 멈출지: 시설 창·메뉴·도감·대화창·거리 사건·작은 창이 떠 있으면 멈춘다.
func _process(_delta: float) -> void:
	_town.paused = _facility != null or _menu.is_open() or _codex.is_open() or _dialog.busy() or _event_running or _moving \
		or has_node("PauseChoice") or has_node("StreetChoice") or _debug.visible


func facility_view() -> FacilityView:
	return _facility


func debug_panel() -> CityDebugPanel:
	return _debug


func is_debug_open() -> bool:
	return _debug.visible


## 동네에서 시설 문을 골랐다: 시설 창으로(행동력은 들어갈 때 1 — CT72). 못 들어가면 안내.
func choose_facility(id: String) -> void:
	if _facility != null or _event_running:
		return
	var why := state.enter_facility(id)
	if not why.is_empty():
		say(Strings.t(why))
		return
	_facility = FacilityView.new()
	_facility.setup(state, pc, _registry, id)
	_facility.leave_requested.connect(leave_facility)
	_facility.art_shown.connect(func() -> void: _hud.visible = false)  # 그림이 덮는 동안 귀퉁이 카드는 숨긴다(요리·책)
	_facility.art_hidden.connect(func() -> void: _hud.visible = true)
	_hud.set_facility_mode(true)
	add_child(_facility)
	move_child(_facility, _town.get_index() + 1)
	_facility.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func leave_facility() -> void:
	if _facility == null:
		return
	for line in _facility.summary():
		say(line)
	var id := _facility.facility_id()
	_facility.queue_free()
	_facility = null
	_town.place_at_door(id)
	_hud.visible = true
	_hud.set_facility_mode(false)
	state.leave_facility()


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
	await _dialog.wait()
	if not is_inside_tree():
		return
	_event_view.close()
	_event_view = null
	_event_running = false


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


## 구역문을 바라보고 Enter: 특별 시설(동네에 서지 않는 곳)로 가는 작은 창(CT63). 고르면 그 시설에 바로 들어간다
## (행동력은 다른 시설처럼 들어갈 때 1). 특별 시설이 없으면 아무 일도 없다.
func offer_travel() -> void:
	if _facility != null or _event_running or _moving or _menu.is_open() or _dialog.busy():
		return
	var ids := CityDistrict.special_ids(state.db)
	if ids.is_empty():
		return
	_moving = true
	var opts: Array[Dictionary] = []
	for id in ids:
		var f := state.db.get_entry("facilities", id)
		var shut := state.closed.has(id)
		opts.append({"text": JsonUtil.get_str(f, "name_ko", id), "sub": JsonUtil.get_str(f, "place_ko"), "enabled": not shut,
			"desc": Strings.t("city.reason_closed") if shut else ""})
	opts.append({"text": Strings.t("city.travel_cancel")})
	var i: int = await ChoicePopup.ask(self, Strings.t("city.travel_title"), opts, true)
	_moving = false
	if i >= 0 and i < ids.size() and is_inside_tree():
		choose_facility(ids[i])


## Tab 메뉴·도감을 열 수 있는가: 동네를 걷는 중(시설 창·대화가 없을 때).
func _overlay_ok() -> bool:
	return _facility == null and not _dialog.busy()


## Tab 메뉴·도감이 열리고 닫힘(걷기는 _process가 멈춘다).
func _on_overlay(_on: bool) -> void:
	pass


## 소지품 쓰기(동네에서 — city.json item_use.categories 분류만, 포션 등). 결과는 막대·소지품으로 보이니 글로 알리지 않는다.
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
	_menu.float_use_numbers(ctx.messages)
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
	if event.is_action_pressed("menu") and _overlay_ok():
		_menu.toggle()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("codex") and _overlay_ok() and not _menu.is_open():
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
	pop.open(Strings.t("explore.paused"), [{"text": Strings.t("pause.resume")}, {"text": Strings.t("city.btn_title")}], false, Vector2(-1, -1))
	var i: int = await pop.picked
	pop.queue_free()
	if not is_inside_tree():
		return
	if i == 1:
		title_requested.emit()
