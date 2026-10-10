class_name ExploreScreen
extends Control
## 탐험 화면: 3/4 시점 월드(SubViewport) + HUD + 기록창 + 디버그 패널(F1).
## 키 입력을 ExploreSession에 넘기고, 세션 시그널로 그림·기록을 갱신한다.

signal run_ended(kind: String, info: Dictionary)  ## kind: "closed"(층 폐쇄로 강제 귀환) / "died"(사망)
signal regenerate_requested(seed_value: int)

const POST_SHADER := "res://assets/shaders/post_grade.gdshader"
const POST_PARAMS := ["saturation", "vignette_strength", "vignette_radius", "grain_strength"]

var session: ExploreSession
var _view: FloorView
var _hud: ExploreHud
var _debug: DebugPanel
var _held: Vector2i = Vector2i.ZERO
var _repeat_left: float = 0.0
var _ended: bool = false


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
	add_child(log_panel)
	var m := UiTheme.metric("margin", 16)
	log_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	log_panel.offset_left = -m - UiTheme.metric("explore_log_width", 380)
	log_panel.offset_right = -m
	log_panel.offset_top = m
	log_panel.offset_bottom = m + UiTheme.metric("explore_log_height", 260)
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
	session.start()


func _process(delta: float) -> void:
	if _ended or _typing():
		_held = Vector2i.ZERO
		return
	var dir := _input_dir()
	if dir == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return
	var view_cfg := JsonUtil.get_dict(session.db.render, "view")
	if dir != _held:
		_held = dir
		session.try_move(dir)
		_repeat_left = JsonUtil.get_float(view_cfg, "move_first_delay_sec", 0.22)
		return
	_repeat_left -= delta
	if _repeat_left <= 0.0:
		session.try_move(dir)
		_repeat_left = JsonUtil.get_float(view_cfg, "move_repeat_sec", 0.11)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_debug.visible = not _debug.visible
		get_viewport().set_input_as_handled()
		return
	if _ended or _typing():
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


func _build_world() -> void:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp := SubViewport.new()
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(vp)
	var lighting := JsonUtil.get_dict(session.db.render, "lighting")
	var tone := CanvasModulate.new()
	tone.color = Color.from_string(JsonUtil.get_str(lighting, "canvas_modulate"), Color.WHITE)
	vp.add_child(tone)
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


func _input_dir() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	if Input.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	if Input.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	if Input.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO


## 입력칸에 글을 쓰는 중이면 이동·단축키를 막는다.
func _typing() -> bool:
	return get_viewport().gui_get_focus_owner() is LineEdit


func _on_message(key: String, args: Dictionary, kind: String) -> void:
	EventBus.log_message.emit(Strings.t(key, args), kind)


func _end(kind: String) -> void:
	if _ended:
		return
	_ended = true
	var pc := session.player
	var info := {
		"name": pc.display_name, "floor": session.floor_name(), "cause": pc.death_cause,
		"day": session.clock.day(), "hours": session.clock.total_hours, "steps": session.steps,
		"landmarks": session.found_count(session.map.landmarks), "landmarks_total": session.map.landmarks.size(),
		"portals": session.found_count(session.map.portals), "portals_total": session.map.portals.size()}
	await get_tree().create_timer(UiTheme.ui_float("end_delay_sec", 1.2)).timeout
	run_ended.emit(kind, info)
