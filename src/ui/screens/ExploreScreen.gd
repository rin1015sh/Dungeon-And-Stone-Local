class_name ExploreScreen
extends Control
## 탐험 화면: 3/4 시점 월드(SubViewport) + 왼쪽 위 정보(HUD) + 왼쪽 아래 기록창 + 하단 바(BottomBar) +
## 창(소지품 I · 캐릭터 C · 도감 B, WindowManager) + 디버그 패널(F1).
## 키 입력을 ExploreSession에 넘기고, 세션 시그널로 그림·기록을 갱신한다.
## 매 프레임 실제 경과 시간을 세션에 넘겨 시간이 실시간으로 흐른다. 일시정지(Esc/P)·디버그 패널·
## 입력칸 입력·창 포커스 잃음·전투 중·창(소지품 등)이 열려 있을 때 시간이 멈춘다(정지 사유는 RealtimeDriver가 모은다).

signal run_ended(kind: String, info: Dictionary)  ## kind: "closed"(층 폐쇄로 강제 귀환) / "died"(사망) / "abandoned"(일시정지 메뉴에서 포기)
signal regenerate_requested(seed_value: int)
signal session_switch(target: ExploreSession)  ## 균열 챕터 ↔ 바깥 층(Main이 화면을 새로 만든다)

const POST_SHADER := "res://assets/shaders/post_grade.gdshader"
const POST_PARAMS := ["saturation", "vignette_strength", "vignette_radius", "grain_strength"]

var session: ExploreSession
var _tone: CanvasModulate
var _tone_base: Color = Color.WHITE
var _view: FloorView
var _hud: ExploreHud
var _debug: DebugPanel
var _ended: bool = false
var _combat: CombatScreen = null
var _pause_overlay: PauseMenu
var _bar: BottomBar
var _windows: WindowManager


func setup(p_session: ExploreSession) -> void:
	session = p_session


func _ready() -> void:
	_build_world()
	_hud = ExploreHud.new()
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.bind(session)
	var log_panel := LogPanel.new()
	log_panel.translucent = true
	log_panel.keeps_history = true
	add_child(log_panel)
	var m := UiTheme.metric("margin", 16)
	_bar = BottomBar.new()
	_bar.setup(session.player)
	add_child(_bar)
	_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bar.offset_left = -_bar.get_combined_minimum_size().x * 0.5
	_bar.offset_right = _bar.get_combined_minimum_size().x * 0.5
	_bar.offset_bottom = -m * 0.5
	_bar.offset_top = _bar.offset_bottom - _bar.get_combined_minimum_size().y
	_bar.window_requested.connect(func(kind: String) -> void: _windows.toggle(kind))
	_bar.action_requested.connect(_on_bar_action)
	_bar.use_requested.connect(_use_item)
	log_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	log_panel.offset_left = m
	log_panel.offset_right = m + UiTheme.metric("explore_log_width", 380)
	log_panel.offset_bottom = _bar.offset_top - m * 0.5
	log_panel.offset_top = log_panel.offset_bottom - UiTheme.metric("explore_log_height", 200)
	_windows = WindowManager.new()
	_windows.setup(session.player)
	_windows.now_hours = func() -> float: return session.clock.total_hours
	add_child(_windows)
	_windows.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_windows.opened_changed.connect(func(on: bool) -> void: session.realtime.set_paused("window", on))
	_windows.use_requested.connect(_use_item)
	_debug = DebugPanel.new()
	_debug.bind(session)
	_debug.visible = false
	add_child(_debug)
	_debug.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_debug.offset_left = -m - UiTheme.metric("debug_panel_width", 300)
	_debug.offset_right = -m
	_debug.offset_top = m
	_debug.regenerate_requested.connect(func(s: int) -> void: regenerate_requested.emit(s))
	session.message.connect(_on_message)
	session.view_changed.connect(_view.refresh)
	session.moved.connect(func(_from: Vector2i, to: Vector2i) -> void: _view.move_player(to))
	session.closing_warning.connect(func(h: float) -> void: EventBus.floor_closing.emit(session.map.floor_id, h))
	session.floor_closed.connect(func() -> void: _end("closed"))
	session.player_died.connect(func(_cause: String) -> void: _end("died"))
	session.encounter.connect(_on_encounter)
	session.riddle_asked.connect(_on_riddle)
	session.transfer.connect(func(t: ExploreSession) -> void: session_switch.emit.call_deferred(t))
	_build_pause_overlay()
	session.start()
	for pm: Dictionary in session.take_pending():
		_on_message(str(pm["key"]), pm["args"], str(pm["kind"]))
	# 화면이 생기기 전에 끝났을 수 있다(빙하굴 3챕터 입장 피해로 사망 등) — 결과 화면으로 넘긴다.
	if session.player.dead:
		_end("died")
	elif session.ended:
		_end("closed")


func _process(delta: float) -> void:
	session.realtime.set_paused("debug", _debug.visible)
	session.realtime.set_paused("typing", _typing())
	session.tick_realtime(delta)
	# 계층군주 소환 중: 수정이 붉게 물든다(층 JSON lord.tint).
	_tone.color = _tone_base * Color.from_string(JsonUtil.get_str(session.lord.def, "tint"), Color.WHITE) if session.lord.is_active() else _tone_base
	if _ended or _combat != null or session.realtime.is_paused():
		return
	# 누르고 있는 동안 매 프레임 그만큼 걷는다(8방향, 속도는 세션이 민첩으로 정한다).
	var dir := _input_dir()
	if dir != Vector2.ZERO:
		session.move_dir(dir, delta)


func _notification(what: int) -> void:
	if session == null or session.realtime == null:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		session.realtime.set_paused("focus", true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		session.realtime.set_paused("focus", false)


func _unhandled_input(event: InputEvent) -> void:
	if _ended or _typing() or _combat != null:
		return  # 전투 중에는 디버그 패널도 열지 않는다(전투 화면 뒤에 숨어 버린다)
	if event.is_action_pressed("debug_toggle"):
		_debug.visible = not _debug.visible
		get_viewport().set_input_as_handled()
		return
	var riddle := get_node_or_null("RiddleDialog") as RiddleDialog
	if riddle != null:  # 수수께끼 대화창이 떠 있으면 탐험 키는 먹지 않는다. 정지 키·취소 키(Backspace) = 물러나기
		if event.is_action_pressed("pause") or event.is_action_pressed("menu_back"):
			riddle.cancel()
		if event is InputEventKey or event is InputEventAction:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if _windows.any_open():
			_windows.close_all()
		else:
			set_paused(not is_paused())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_back") and (_windows.any_open() or is_paused()):  # 취소: 열린 창을 닫고, 없으면 일시정지를 푼다
		if _windows.any_open():
			_windows.close_all()
		else:
			set_paused(false)
		get_viewport().set_input_as_handled()
		return
	if is_paused():
		return
	for kind: String in WindowManager.KINDS:
		if event.is_action_pressed(kind):
			_windows.toggle(kind)
			get_viewport().set_input_as_handled()
			return
	for i in PlayerCharacter.HOTBAR_SIZE:
		if event.is_action_pressed("hotbar_%d" % ((i + 1) % 10)):
			var id: String = session.player.hotbar[i]
			if not id.is_empty():
				_use_item(id)
			get_viewport().set_input_as_handled()
			return
	if _windows.any_open():
		return
	var handled := true
	if event.is_action_pressed("wait"):
		session.wait()
	elif event.is_action_pressed("rest"):
		session.rest()
	elif event.is_action_pressed("torch"):
		session.use_category("light")
	elif event.is_action_pressed("eat"):
		session.use_category("food")
	elif event.is_action_pressed("interact"):
		session.interact()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func is_debug_open() -> bool:
	return _debug.visible


func windows() -> WindowManager:
	return _windows


func bottom_bar() -> BottomBar:
	return _bar


## 소지품 사용(단축칸·소지품 창). 탐험 규칙(ExploreSession)이 판정한다.
func _use_item(item_id: String) -> void:
	if _ended or _combat != null or is_paused():
		return
	session.use_item(item_id)
	_windows.refresh()
	_bar.refresh()


func _on_bar_action(action: String) -> void:
	if _ended or _combat != null or (is_paused() and action != "pause"):
		return
	match action:
		"wait":
			session.wait()
		"rest":
			session.rest()
		"pause":
			set_paused(not is_paused())


## 일시정지 메뉴: 시간이 멈추고 이동·단축키를 막는다.
func set_paused(on: bool) -> void:
	session.realtime.set_paused("menu", on)
	_pause_overlay.show_menu(on)


func is_paused() -> bool:
	return session.realtime.is_paused("menu")


func combat_screen() -> CombatScreen:
	return _combat


## 수수께끼 문지기와 마주쳤다: 대화창을 띄우고 답하는 동안 시간을 멈춘다. 물러나면 조금 떨어질 때까지 다시 묻지 않는다.
func _on_riddle(group: FieldMonsters.Group) -> void:
	if session.rift_run == null or has_node("RiddleDialog"):
		return
	var dlg := RiddleDialog.new()
	dlg.name = "RiddleDialog"
	dlg.setup(session.rift_run.riddle, session.player)
	add_child(dlg)
	dlg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	session.realtime.set_paused("riddle", true)
	dlg.answered.connect(func(outcome: String) -> void:
		session.realtime.set_paused("riddle", false)
		session.answer_riddle(group, outcome))
	dlg.cancelled.connect(func() -> void:
		session.realtime.set_paused("riddle", false)
		session.monsters.set_grace(group, session.clock.total_hours))


## 몬스터 무리와 마주쳤다: 전투 화면을 겹쳐 열고, 끝나면 결과를 탐험 규칙에 돌려준다.
func _on_encounter(group: FieldMonsters.Group, party_first: bool) -> void:
	var party: Array[Actor] = [session.player]
	var battle_rng := Rng.new(session.rng.randi_range(1, 1 << 30))
	var battle := Battle.from_encounter(session.db, DataRegistry.registries, battle_rng, party, group.monster_ids, party_first)
	BattleRules.set_objective(battle, group.battle_rules)
	_debug.visible = false
	_windows.close_all()
	_combat = CombatScreen.new()
	_combat.setup(battle)
	# 보상은 결과가 정해질 때 바로 준다 — 전투 결과 칸에 보이고(웨이브가 이어져도 놓치지 않게) 기록에도 남는다.
	# 정수·전리품은 쓰러진 자리에 남기고 전투 장면에서 하나씩 묻는다(CombatDrops — 받을 사람 고르기).
	var cs := _combat
	_combat.reward_provider = func(_result: String, killed: Array[String], colors: Array[String]) -> Array:
		var msgs := session.grant_battle_rewards(group, killed, colors, true)
		cs.drops = session.battle_drops.duplicate()
		session.battle_drops.clear()
		return msgs
	_combat.drop_taker = func(d: Dictionary, pc: PlayerCharacter) -> Dictionary: return session.take_drop(d, pc)
	_combat.drop_leaver = func(d: Dictionary, reason: String) -> Dictionary: return session.leave_drop(d, reason)
	add_child(_combat)
	_combat.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_combat.finished.connect(func(result: String, turns: int, killed: Array[String]) -> void:
		_combat.queue_free()
		_combat = null
		for id in killed:
			EventBus.monster_killed.emit(id, session.player.id)
		session.resolve_encounter(group, result, turns, killed))


func _build_pause_overlay() -> void:
	_pause_overlay = PauseMenu.new()
	add_child(_pause_overlay)
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.resume_requested.connect(func() -> void: set_paused(false))
	_pause_overlay.abandon_requested.connect(func() -> void: _end("abandoned"))


func _build_world() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := SubViewport.new()
	var linear := JsonUtil.get_str(JsonUtil.get_dict(session.db.render, "view"), "texture_filter", "nearest") == "linear"
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if linear \
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(vp)
	var lighting := JsonUtil.get_dict(session.db.render, "lighting")
	_tone = CanvasModulate.new()
	_tone_base = Color.from_string(JsonUtil.get_str(lighting, "canvas_modulate"), Color.WHITE)
	_tone.color = _tone_base
	vp.add_child(_tone)
	_view = FloorView.new()
	_view.setup(session)
	vp.add_child(_view)
	if JsonUtil.get_bool(lighting, "post_process", true) and ResourceLoader.exists(POST_SHADER):
		var layer := CanvasLayer.new()
		layer.layer = 10
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = load(POST_SHADER) as Shader
		for key: String in POST_PARAMS:
			if lighting.has(key):
				mat.set_shader_parameter(key, JsonUtil.get_float(lighting, key))
		rect.material = mat
		layer.add_child(rect)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vp.add_child(layer)


func _input_dir() -> Vector2:
	var d := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		d.y -= 1.0
	if Input.is_action_pressed("move_down"):
		d.y += 1.0
	if Input.is_action_pressed("move_left"):
		d.x -= 1.0
	if Input.is_action_pressed("move_right"):
		d.x += 1.0
	return d


## 입력칸에 글을 쓰는 중이면 이동·단축키를 막는다.
func _typing() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit


## 문구의 {interact}는 지금 묶인 살피기 키로 채운다(키를 바꿔도 안내가 맞게).
func _on_message(key: String, args: Dictionary, kind: String) -> void:
	var a := args
	if not a.has("interact"):
		a = args.duplicate()
		a["interact"] = InputSetup.key_label("interact")
	EventBus.log_message.emit(Strings.t(key, a), kind)


func _end(kind: String) -> void:
	if _ended:
		return
	_ended = true
	set_paused(false)
	var pc := session.player
	var base := session.rift_run.outer if session.rift_run != null and session.rift_run.outer != null else session  # 균열 안이면 바깥 층 기준
	var info := {
		"name": pc.display_name, "floor": base.floor_name(), "cause": pc.death_cause,
		"day": session.clock.day(), "hours": session.clock.total_hours, "steps": base.steps + (session.steps if base != session else 0),
		"landmarks": base.found_count(base.map.landmarks), "landmarks_total": base.map.landmarks.size(),
		"portals": base.found_count(base.map.portals), "portals_total": base.map.portals.size()}
	if _combat != null:
		await _combat.finished
	await get_tree().create_timer(UiTheme.ui_float("end_delay_sec", 1.2)).timeout
	run_ended.emit(kind, info)
