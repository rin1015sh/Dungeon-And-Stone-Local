class_name ExploreScreen
extends Control
## 탐험 화면: 3/4 시점 월드(SubViewport) + 왼쪽 위 정보(HUD) + 하단 바(BottomBar) + 하단 대화창(DialogueBox — 알림을 Enter로 넘김) +
## Tab 메뉴(소지품 · 캐릭터 · 도감을 한 화면에, GameMenu) + 디버그 패널(F1). 마우스는 쓰지 않는다(키보드만).
## 키 입력을 ExploreSession에 넘기고, 세션 시그널로 그림·기록을 갱신한다.
## 매 프레임 실제 경과 시간을 세션에 넘겨 시간이 실시간으로 흐른다. 일시정지(Esc/P)·디버그 패널·
## 입력칸 입력·창 포커스 잃음·전투 중·Tab 메뉴가 열려 있을 때·대화창에 넘길 알림이 있을 때 시간이 멈춘다(정지 사유는 RealtimeDriver가 모은다).
## 알림(세션 안내·소지품 창 경고)은 피어 앤 헝거처럼 아래 대화창에 한 쪽씩 뜨고 Enter로 넘긴다(사용자 결정 2026-10-18) — 떠 있는 동안 하단 바는 숨는다.
## 화면으로 알 수 있는 것(횃불·포션·식사·상태·대기·어둠 등)은 글로 알리지 않는다 — 문구 키로 나눈다(NoticeRoute, render.json ui.notice, 사용자 결정 2026-10-19).
## 대기·휴식은 글 대신 화면이 잠깐 어두워졌다 밝아진다(render.json ui.rest_fade).

signal run_ended(kind: String, info: Dictionary)  ## kind: "closed"(층 폐쇄로 강제 귀환) / "died"(사망) / "abandoned"(일시정지 메뉴에서 포기)
signal regenerate_requested(seed_value: int)
signal session_switch(target: ExploreSession)  ## 균열 챕터 ↔ 바깥 층(Main이 화면을 새로 만든다)

const POST_SHADER := "res://assets/shaders/post_grade.gdshader"

var session: ExploreSession
var _tone: CanvasModulate
var _tone_base: Color = Color.WHITE
var _post: ShaderMaterial = null
var _ambience: String = ""
var _view: FloorView
var _hud: ExploreHud
var _debug: DebugPanel
var _ended: bool = false
var _combat: CombatScreen = null
var _pause_overlay: PauseMenu
var _bar: BottomBar
var _menu: GameMenu
var _dialog: DialogueBox
var _shade: ColorRect  # 대기·휴식 때 잠깐 어두워지는 막
var _veil: ColorRect   # 균열 길목을 지날 때 화면 전체를 덮는 검은 막(어두워졌다 → 다음 챕터에서 밝아진다)
var _route: NoticeRoute
var _routing: bool = false  # _notify가 기록(log_message)을 내는 중 — _on_log가 한 번 더 보이지 않게
var _defeated: bool = false  # 전투에서 졌다 — 남은 안내 없이 바로 타이틀로


func setup(p_session: ExploreSession) -> void:
	session = p_session


func _ready() -> void:
	_build_world()
	_shade = ColorRect.new()
	_shade.color = Color(UiTheme.color("bg"), 0.0)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud = ExploreHud.new()
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.bind(session)
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
	_menu = GameMenu.new()
	_menu.setup(session.player)
	add_child(_menu)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu.opened_changed.connect(_on_menu_opened)
	_menu.use_requested.connect(_use_item)
	_build_dialog(m)
	_menu.hold = _dialog.busy  # 메뉴 위에 뜬 알림(버렸다 등)을 먼저 넘긴다
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
	session.feature_choice.connect(_on_feature_choice)
	session.transfer.connect(_on_transfer)
	_build_pause_overlay()
	session.start()
	_veil = ColorRect.new()
	_veil.color = Color(0, 0, 0, 0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if session.fade_in:  # 길목을 지나왔다: 검은 화면에서 밝아진다
		session.fade_in = false
		_veil.color.a = 1.0
		_fade_veil(0.0)
	for pm: Dictionary in session.take_pending():
		_on_message(str(pm["key"]), pm["args"], str(pm["kind"]))
	# 화면이 생기기 전에 끝났을 수 있다(빙하굴 3챕터 입장 피해로 사망 등) — 결과 화면으로 넘긴다.
	if session.player.dead:
		_end("died")
	elif session.ended:
		_end("closed")


## 다른 세션으로 넘어간다. 균열 길목이면 화면이 어두워진 뒤 바꾼다(다음 화면이 밝아진다).
func _on_transfer(t: ExploreSession) -> void:
	if not t.fade_in or _fade_sec() <= 0.0:
		session_switch.emit.call_deferred(t)
		return
	_fade_veil(1.0).finished.connect(func() -> void: session_switch.emit(t))


func _fade_veil(alpha: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(_veil, "color:a", alpha, _fade_sec())
	return tw


## 길목 연출 시간(테스트·캡처처럼 대화창을 기다리지 않을 때는 0).
func _fade_sec() -> float:
	return 0.0 if DialogueBox.auto_skip else JsonUtil.get_float(UiTheme.ui_dict("rift_passage"), "fade_sec", 0.35)


func _process(delta: float) -> void:
	session.realtime.set_paused("debug", _debug.visible)
	session.realtime.set_paused("typing", _typing())
	session.realtime.set_paused("dialog", _dialog.busy())
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
	var feature := get_node_or_null("FeatureChoice") as ChoicePopup
	if feature != null:  # 동굴 요소 선택 창: 탐험 키는 먹지 않는다(W/S·Enter·Backspace는 창이 먼저 받는다). 정지 키 = 그만두기
		if event.is_action_pressed("pause"):
			feature.picked.emit(-1)
		if event is InputEventKey or event is InputEventAction:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if _menu.is_open():
			_menu.close()
		else:
			set_paused(not is_paused())
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu_back") and (_menu.is_open() or is_paused()):  # 취소: 메뉴를 닫고, 없으면 일시정지를 푼다
		if _menu.is_open():
			_menu.close()
		else:
			set_paused(false)
		get_viewport().set_input_as_handled()
		return
	if is_paused():
		return
	if event.is_action_pressed("menu"):
		_menu.toggle()
		get_viewport().set_input_as_handled()
		return
	if _menu.is_open():
		return
	var handled := true
	if event.is_action_pressed("wait"):
		_fade()
		session.wait()
	elif event.is_action_pressed("rest"):
		_fade()
		session.rest()
	elif event.is_action_pressed("interact"):
		session.interact()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


## 대기·휴식: 글 대신 화면이 잠깐 어두워졌다가 밝아진다.
func _fade() -> void:
	var cfg := UiTheme.ui_dict("rest_fade")
	var sec := JsonUtil.get_float(cfg, "sec", 0.9)
	_shade.color.a = 0.0
	var tw := _shade.create_tween()
	tw.tween_property(_shade, "color:a", JsonUtil.get_float(cfg, "alpha", 0.9), sec * 0.4)
	tw.tween_property(_shade, "color:a", 0.0, sec * 0.6)


func shade_alpha() -> float:
	return _shade.color.a


func is_debug_open() -> bool:
	return _debug.visible


func menu() -> GameMenu:
	return _menu


func bottom_bar() -> BottomBar:
	return _bar


## 소지품 사용(Tab 메뉴에서만 — 단축칸·단축 키 없음). 탐험 규칙(ExploreSession)이 판정한다.
func _use_item(item_id: String) -> void:
	if _ended or _combat != null or is_paused():
		return
	session.use_item(item_id)
	_menu.refresh()
	_bar.refresh()


## Tab 메뉴가 열리면 시간이 멈춘다. 닫히면 하단 바(단축칸)를 다시 그린다.
func _on_menu_opened(on: bool) -> void:
	session.realtime.set_paused("window", on)
	if not on:
		_bar.refresh()


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


## 동굴 요소의 행동이 여럿이다(맑은 샘 등): 작은 선택 창(ChoicePopup — W/S·Enter, Backspace = 그만두기). 고르는 동안 시간을 멈춘다.
func _on_feature_choice(at: Vector2i) -> void:
	if has_node("FeatureChoice"):
		return
	var acts := session.features.actions_at(at)
	var opts: Array[Dictionary] = []
	for a in acts:
		opts.append({"text": str(a["name_ko"])})
	session.realtime.set_paused("feature", true)
	var pop := ChoicePopup.new()
	pop.name = "FeatureChoice"
	add_child(pop)
	pop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pop.open(session.features.name_at(at), opts, true, Vector2(-1, -1))
	var i: int = await pop.picked
	pop.queue_free()
	session.realtime.set_paused("feature", false)
	if i >= 0 and i < acts.size():
		session.features.act(session, at, str(acts[i]["id"]))


## 몬스터 무리와 마주쳤다: 전투 화면을 겹쳐 열고, 끝나면 결과를 탐험 규칙에 돌려준다.
func _on_encounter(group: FieldMonsters.Group, party_first: bool) -> void:
	var party: Array[Actor] = [session.player]
	var battle_rng := Rng.new(session.rng.randi_range(1, 1 << 30))
	var battle := Battle.from_encounter(session.db, DataRegistry.registries, battle_rng, party, group.monster_ids, party_first)
	BattleRules.set_objective(battle, group.battle_rules)
	_debug.visible = false
	_menu.close()
	_dialog.clear()  # 마주친 안내는 전투 화면이 이어서 보인다
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
		_defeated = result == Battle.RESULT_DEFEAT
		for id in killed:
			EventBus.monster_killed.emit(id, session.player.id)
		session.resolve_encounter(group, result, turns, killed))


## 하단 대화창: 하단 바 자리에 겹친다(폭 ui.dialog.width — 화면이 좁으면 여백만 남기고).
func _build_dialog(m: int) -> void:
	_dialog = DialogueBox.new()
	add_child(_dialog)
	var w := UiTheme.ui_dict("dialog").get("width", 960.0) as float
	var h := UiTheme.ui_dict("dialog").get("height", 128.0) as float
	_dialog.anchor_left = 0.5
	_dialog.anchor_right = 0.5
	_dialog.anchor_top = 1.0
	_dialog.anchor_bottom = 1.0
	_dialog.offset_top = -m * 0.5 - h
	_dialog.offset_bottom = -m * 0.5
	var fit := func() -> void:
		var half := minf(w / 2.0, size.x / 2.0 - m)
		_dialog.offset_left = -half
		_dialog.offset_right = half
	fit.call()
	resized.connect(fit)
	_dialog.shown_changed.connect(func(on: bool) -> void: _bar.visible = not on)
	EventBus.log_message.connect(_on_log)
	EventBus.notice.connect(_notify)
	_route = NoticeRoute.new(session.db)


## 문구 키 알림 → 기록(log_message) + 나눈 자리(보이지 않음 / 대화창). 전투 중·끝난 뒤는 기록만.
func _notify(key: String, args: Dictionary, kind: String) -> void:
	GameState.note_deed(key)  # 귀환 뒤 도시 명성(CityRenown — 알림 키로 센다)
	var a := args
	if not a.has("interact"):
		a = args.duplicate()
		a["interact"] = InputSetup.key_label("interact")
	var text := Strings.t(key, a)
	_routing = true
	EventBus.log_message.emit(text, kind)
	_routing = false
	if _combat != null or _ended or is_queued_for_deletion():
		return
	if not _route.silent(key):
		_dialog.say(text, kind)


## 키 없이 온 알림(log_message) → 대화창. 전투 중(전투 화면이 자기 대화창에 보인다)·끝난 뒤는 받지 않는다.
func _on_log(text: String, kind: String) -> void:
	if not _routing and _combat == null and not _ended and not is_queued_for_deletion():
		_dialog.say(text, kind)


func dialog() -> DialogueBox:
	return _dialog


func _build_pause_overlay() -> void:
	_pause_overlay = PauseMenu.new()
	add_child(_pause_overlay)
	_pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.resume_requested.connect(func() -> void: set_paused(false))
	_pause_overlay.abandon_requested.connect(func() -> void: _end("abandoned"))
	_pause_overlay.quality_changed.connect(_on_quality_changed)


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
	var art := FloorArt.resolve(session.db.render, session.floor_def, GraphicsSettings.quality())
	var back := CanvasLayer.new()  # 미탐험 = 순흑(층 art.palette.unexplored) — 화면 기본 배경색과 따로
	back.layer = -1
	var dark := ColorRect.new()
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark.color = art.unexplored
	back.add_child(dark)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.add_child(back)
	_tone = CanvasModulate.new()
	_tone_base = art.tone
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
		_post = ShaderMaterial.new()
		_post.shader = load(POST_SHADER) as Shader
		_apply_post(art)
		rect.material = _post
		layer.add_child(rect)
		rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vp.add_child(layer)
	_ambience = art.ambience
	AudioBus.play_ambience(_ambience)


func _apply_post(art: FloorArt) -> void:
	if _post == null:
		return
	for key: String in art.post:
		_post.set_shader_parameter(key, float(art.post[key]))


## 일시정지 메뉴에서 그래픽 품질을 바꿨다.
func _on_quality_changed(quality: String) -> void:
	_apply_post(FloorArt.resolve(session.db.render, session.floor_def, quality))
	_view.set_quality(quality)


func _exit_tree() -> void:
	AudioBus.stop_ambience(_ambience)  # 다음 화면(균열 챕터 등)이 먼저 틀었으면 그대로 둔다


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


## 세션 안내 → _notify(문구의 {interact}는 지금 묶인 살피기 키로 채운다 — 키를 바꿔도 안내가 맞게).
func _on_message(key: String, args: Dictionary, kind: String) -> void:
	_notify(key, args, kind)


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
	if kind == "died":  # 사망 화면 없이 타이틀로(사용자 결정 2026-10-18): 전투 패배는 전투 대화창의 "당신은 패배했다..."로 끝,
		if _defeated or _combat != null:  # 그 밖(굶주림·함정 등)은 남은 안내("숨이 멎었다.")를 넘긴 뒤
			_dialog.clear()
		elif _dialog.busy():
			await _dialog.wait()
		if is_inside_tree():
			run_ended.emit(kind, info)
		return
	await get_tree().create_timer(UiTheme.ui_float("end_delay_sec", 1.2)).timeout
	run_ended.emit(kind, info)
