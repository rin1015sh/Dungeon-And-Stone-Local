class_name PlazaScreen
extends Control
## 차원광장(미궁 입구): 하순이 끝나면(한 달에 한 번 — CityState.expedition_month) 거리에서 이리로 온다. 이어하기도 여기서 시작한다.
## 도착하면 돌 고리 안에 포탈이 열리고, 다 열린 뒤에만 "기록을 남긴다"(한 칸 저장 — 저장은 여기서만)와 "포탈로 들어간다"가 나온다.
## 그림(render.json city.plaza): 하늘(날씨) · 원경 far 레이어 일부 · 광장(tools/paint_city.gd --only=plaza) · 포탈 셰이더 2장(고리 안 소용돌이 + 빛 번짐).
## 화면 크기와 상관없이 1280×720 무대를 화면을 덮게 늘려 놓는다(포탈 자리가 그림과 어긋나지 않게).

signal enter_requested
signal save_requested

const STAGE := Vector2(1280, 720)

var state: CityState
var pc: PlayerCharacter
var _stage: Control
var _portal: ShaderMaterial
var _glow: ShaderMaterial
var _panel: PanelContainer
var _save_btn: Button
var _enter_btn: Button
var _flash: ColorRect
var _opened: bool = false
var _entering: bool = false
var _cfg: Dictionary = {}
var _open_tween: Tween


func setup(p_state: CityState, p_pc: PlayerCharacter) -> void:
	state = p_state
	pc = p_pc


func _ready() -> void:
	clip_contents = true
	_cfg = GameDatabase.single(state.db.render, "city.plaza", {}) as Dictionary
	var weather := state.weather_def()
	var tint := CityStreet._rgb(weather.get("tint"))
	var sky := TextureRect.new()
	sky.texture = _tex(JsonUtil.get_str(weather, "sky", "res://assets/city/layers/sky.webp"))
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.size = STAGE
	add_child(_stage)
	_build_stage(tint)
	_build_ui()
	resized.connect(_fit)
	_fit()
	_open_portal()


func _build_stage(tint: Color) -> void:
	var far_tex := _tex(_far_path())
	if far_tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = far_tex
		atlas.region = _rect(_cfg.get("far_region"), Rect2(0, 0, 640, 240))
		var far := _layer(atlas, Rect2(0, float(_cfg.get("far_y", 110)), STAGE.x, float(_cfg.get("far_height", 480))))
		far.modulate = tint
	var bg := _layer(_tex(JsonUtil.get_str(_cfg, "background")), Rect2(Vector2.ZERO, STAGE))
	bg.modulate = tint
	var pr := _rect(_cfg.get("portal_rect"), Rect2(498, 152, 284, 296))
	var gs := float(_cfg.get("glow_scale", 2.6))
	_glow = _shader_rect("res://assets/shaders/portal_glow.gdshader", Rect2(pr.get_center() - pr.size * gs / 2.0, pr.size * gs))
	_glow.set_shader_parameter("tint", Color(JsonUtil.get_str(_cfg, "portal_edge", "#7a5ad8")))
	_portal = _shader_rect("res://assets/shaders/portal.gdshader", pr)
	for k: String in ["core", "edge", "deep"]:
		_portal.set_shader_parameter(k, Color(JsonUtil.get_str(_cfg, "portal_" + k, "#ffffff")))


func _build_ui() -> void:
	var hud := CityHud.new()
	hud.place_key = "plaza_ko"
	hud.setup(state, pc)
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.set_facility_mode(true)
	var m := UiTheme.metric("margin", 16)
	_panel = CityUi.card()
	_panel.custom_minimum_size.x = float(_cfg.get("panel_width", 280))
	_panel.visible = false
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, m)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	_panel.add_child(v)
	_save_btn = CityUi.button(Strings.t("plaza.save"), func() -> void: save_requested.emit())
	v.add_child(_save_btn)
	_enter_btn = CityUi.button(Strings.t("plaza.enter"), enter, true)
	v.add_child(_enter_btn)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## 무대(1280×720)를 화면을 덮게 키우고 가운데에 둔다.
func _fit() -> void:
	var s := maxf(size.x / STAGE.x, size.y / STAGE.y)
	if s <= 0.0:
		return
	_stage.scale = Vector2(s, s)
	_stage.position = (size - STAGE * s) / 2.0


## 잠깐 뒤 포탈이 가운데서 번져 고리를 채운다 → 선택지가 나온다.
func _open_portal() -> void:
	var t := create_tween()
	_open_tween = t
	t.tween_interval(float(_cfg.get("open_delay", 0.8)))
	t.tween_method(_set_open, 0.0, 1.0, float(_cfg.get("open_seconds", 2.6))).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(_on_opened)


func _set_open(v: float) -> void:
	_portal.set_shader_parameter("open", v)
	_glow.set_shader_parameter("strength", v * float(_cfg.get("glow_strength", 0.55)))


func _on_opened() -> void:
	if _opened:
		return
	_opened = true
	if _open_tween != null and _open_tween.is_valid():
		_open_tween.kill()
	_set_open(1.0)
	_panel.visible = true


## Enter(menu_confirm) = 포탈로 들어간다(열린 뒤에만).
func _unhandled_input(event: InputEvent) -> void:
	if _opened and event.is_action_pressed("menu_confirm"):
		get_viewport().set_input_as_handled()
		enter()


## 테스트·캡처용: 기다리지 않고 바로 연다.
func open_now() -> void:
	_on_opened()


func is_open() -> bool:
	return _opened


## 저장 결과(Main이 GameState.save_run() 뒤에 알려 준다).
func save_done(ok: bool) -> void:
	_save_btn.text = Strings.t("plaza.saved" if ok else "plaza.save_failed")
	_save_btn.disabled = ok


## 포탈로 들어간다: 하얗게 타오르고 화면이 빛에 덮인 뒤 enter_requested.
func enter() -> void:
	if not _opened or _entering:
		return
	_entering = true
	_panel.visible = false
	var sec := float(_cfg.get("enter_seconds", 1.1))
	var t := create_tween().set_parallel(true)
	t.tween_method(func(v: float) -> void: _portal.set_shader_parameter("flare", v), 0.0, 1.0, sec * 0.6)
	t.tween_method(func(v: float) -> void: _glow.set_shader_parameter("strength", float(_cfg.get("glow_strength", 0.55)) * (1.0 + v * 2.0)), 0.0, 1.0, sec)
	t.tween_property(_flash, "color:a", 1.0, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(func() -> void: enter_requested.emit())


func _layer(tex: Texture2D, r: Rect2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.position = r.position
	tr.size = r.size
	_stage.add_child(tr)
	return tr


func _shader_rect(path: String, r: Rect2) -> ShaderMaterial:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.position = r.position
	c.size = r.size
	var mat := ShaderMaterial.new()
	mat.shader = load(path) as Shader
	c.material = mat
	_stage.add_child(c)
	return mat


func _far_path() -> String:
	for L: Variant in JsonUtil.get_array(JsonUtil.get_dict(state.db.singletons.get("city", {}), "street"), "layers"):
		if L is Dictionary and JsonUtil.get_str(L, "id") == "far":
			return JsonUtil.get_str(L, "path")
	return ""


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null


static func _rect(v: Variant, fallback: Rect2) -> Rect2:
	if v is Array and (v as Array).size() >= 4:
		return Rect2(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
	return fallback
