class_name CityStreet
extends Control
## 라비기온 거리(옆에서 본 긴 풍경)를 좌우로 스크롤하며 시설 건물을 고른다.
##   레이어(data/city.json street.layers): 하늘·원경·중경·안개는 시차(parallax)로 천천히 움직이는 실제 도시 풍경(고를 수 없음),
##   날씨(CityState.weather — city.json weather)에 따라 하늘 그림을 바꾸고 나머지 레이어·건물에 색을 곱한다(맑음 = 밝게).
##   거리 레이어 위에 시설 건물(고를 수 있음 — 화면 가운데 건물 강조, 윤곽 셰이더)과 이름판, 맨 앞에 화면 비네트.
##   이번 순 오늘의 거리 사건이 걸린 건물(CityHappenings.lit)은 등롱 불빛이 켜져 일렁인다(글로 알리지 않는다 — UI19).
##   키보드만(사용자 결정 2026-10-19): A/D·←/→ 스크롤, 화면 가운데 건물을 Enter/F로 들어간다.
## 좌표는 거리 단위(화면 높이 render.json city.street_height 기준) — 화면 높이에 맞춰 확대·축소한다.
## 그림 파일이 없으면 이름판과 빈 자리만 그린다(그림 없이도 고를 수 있다).

signal facility_chosen(facility_id: String)

const FALLBACK_SIZE := Vector2(400, 400)
const HIGHLIGHT := preload("res://assets/shaders/city_highlight.gdshader")

var _state: CityState
var _back: Control  # 시차 레이어(뒤)
var _content: Control  # 거리 레이어 + 건물 + 이름판(스크롤 1배)
var _front: Control  # 화면 고정 레이어(앞)
var _layers: Array[Dictionary] = []  # {id, node: TextureRect, parallax, y, height, scale, screen}
var _weather: String = "?"
var _buildings: Array[Dictionary] = []  # {id, node: TextureRect, plate, label, x, w, h}
var _offset: float = 0.0
var _scale: float = 1.0
var _street_w: float = 3600.0
var _focus: int = -1
var _outline_tex: float = 3.0  # 윤곽 두께(그림 픽셀)
var _glow_tex: GradientTexture2D
var _time: float = 0.0


func setup(state: CityState) -> void:
	_state = state


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var street := CityValues.city_section(_state.db, {}, "street")
	_street_w = JsonUtil.get_float(street, "width", _street_w)
	_back = _plain()
	_content = _plain()
	_front = _plain()
	for v: Variant in JsonUtil.get_array(street, "layers"):
		var d := v as Dictionary
		var front := JsonUtil.get_bool(d, "front")
		var parent := _front if front else (_content if JsonUtil.get_float(d, "parallax", 1.0) >= 1.0 and not JsonUtil.get_bool(d, "screen") else _back)
		_add_layer(d, parent)
	for id in _state.facility_ids():
		_add_building(id)
	resized.connect(_layout)
	_state.changed.connect(refresh)
	_layout()
	refresh()


func _plain() -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _add_layer(d: Dictionary, parent: Control) -> void:
	var tr := TextureRect.new()
	tr.texture = _tex(JsonUtil.get_str(d, "path"))
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if JsonUtil.get_bool(d, "screen") else TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tr)
	_layers.append({"id": JsonUtil.get_str(d, "id"), "path": JsonUtil.get_str(d, "path"), "node": tr, "parallax": JsonUtil.get_float(d, "parallax", 1.0), "y": JsonUtil.get_float(d, "y"),
		"height": JsonUtil.get_float(d, "height", 720.0), "scale": JsonUtil.get_float(d, "scale", 1.0), "screen": JsonUtil.get_bool(d, "screen")})


func _add_building(id: String) -> void:
	var f := _state.db.get_entry("facilities", id)
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture = _tex(JsonUtil.get_str(f, "building"))
	var mat := ShaderMaterial.new()
	mat.shader = HIGHLIGHT
	mat.set_shader_parameter("outline_color", UiTheme.render_color("city.selected_outline", UiTheme.color("gold")))
	art.material = mat
	_content.add_child(art)
	var glow := TextureRect.new()
	glow.texture = _glow()
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = add
	glow.visible = false
	_content.add_child(glow)
	var k := UiTheme.render_float("city.building_scale", 0.85)
	var size_u := Vector2(art.texture.get_size()) * k if art.texture != null else FALLBACK_SIZE
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiTheme.label(JsonUtil.get_str(f, "name_ko", id), "body", "text_title")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(label)
	add_child(plate)  # 이름판은 비네트보다 앞
	_buildings.append({"id": id, "node": art, "glow": glow, "plate": plate, "label": label,
		"x": float(JsonUtil.get_int(f, "x")), "w": size_u.x, "h": size_u.y})


## 등롱 불빛(둥근 그러데이션 — 가운데 render.json city.happening_glow, 가장자리 투명).
func _glow() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		var c := UiTheme.render_color("city.happening_glow", Color(1.0, 0.72, 0.35, 0.8))
		g.set_color(0, c)
		g.set_color(1, Color(c.r, c.g * 0.6, c.b * 0.4, 0.0))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 128
		_glow_tex.height = 128
	return _glow_tex


func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null


func _layout() -> void:
	if size.y <= 0.0:
		return
	_scale = size.y / UiTheme.render_float("city.street_height", 720.0)
	var baseline := UiTheme.render_float("city.baseline", 600.0)
	for L in _layers:
		var tr: TextureRect = L["node"]
		if bool(L["screen"]):
			tr.position = Vector2(0, float(L["y"]) * _scale)
			tr.size = Vector2(size.x, float(L["height"]) * _scale)
		elif tr.texture != null:
			tr.size = Vector2(tr.texture.get_size()) * float(L["scale"]) * _scale
	for b in _buildings:
		var node: TextureRect = b["node"]
		node.position = Vector2(float(b["x"]), baseline - float(b["h"])) * _scale
		node.size = Vector2(float(b["w"]), float(b["h"])) * _scale
		var gs := UiTheme.render_float("city.happening_glow_px", 170.0)
		var gy := UiTheme.render_float("city.happening_glow_y", 0.42)
		var glow: TextureRect = b["glow"]
		glow.size = Vector2(gs, gs) * _scale
		glow.position = Vector2(float(b["x"]) + float(b["w"]) / 2.0 - gs / 2.0, baseline - float(b["h"]) * gy - gs / 2.0) * _scale
	_outline_tex = UiTheme.render_float("city.outline_px", 3.0) / maxf(0.01, _scale * UiTheme.render_float("city.building_scale", 0.85))
	scroll_to(_offset)
	refresh()


func max_offset() -> float:
	return maxf(0.0, _street_w * _scale - size.x)


func scroll_to(x: float) -> void:
	_offset = clampf(x, 0.0, max_offset())
	_content.position.x = -roundf(_offset)
	for L in _layers:
		if not bool(L["screen"]) and float(L["parallax"]) < 1.0:
			(L["node"] as TextureRect).position = Vector2(-roundf(_offset * float(L["parallax"])), float(L["y"]) * _scale)
		elif not bool(L["screen"]):
			(L["node"] as TextureRect).position = Vector2(0, float(L["y"]) * _scale)
	_place_plates()
	_update_focus()


func scroll_by(dx: float) -> void:
	scroll_to(_offset + dx)


func offset() -> float:
	return _offset


func _place_plates() -> void:
	var baseline := UiTheme.render_float("city.baseline", 600.0)
	for b in _buildings:
		var plate: PanelContainer = b["plate"]
		plate.reset_size()
		plate.position = Vector2((float(b["x"]) + float(b["w"]) / 2.0) * _scale - plate.size.x / 2.0 - _offset,
			baseline * _scale + UiTheme.render_float("city.plate_offset_px", 8.0))


## 강조: 행동력이 되면 가리킨 건물은 밝고 윤곽, 안 되면 모두 흐리게(이름판도 흐림).
func refresh() -> void:
	if _state == null:
		return
	_apply_weather()
	for i in _buildings.size():
		var b := _buildings[i]
		var can := _state.can_spend(_state.entry_cost_of(str(b["id"]))) and _state.facility.is_empty()
		var lit := i == _focus
		var mat := (b["node"] as TextureRect).material as ShaderMaterial
		mat.set_shader_parameter("brighten", UiTheme.render_float("city.hover_brighten", 0.15) if lit and can else 0.0)
		mat.set_shader_parameter("dim", UiTheme.render_float("city.dim_unaffordable", 0.35) if not can else 0.0)
		mat.set_shader_parameter("outline", _outline_tex if lit and can else 0.0)
		(b["glow"] as TextureRect).visible = CityHappenings.lit(_state, str(b["id"]))
		var plate: PanelContainer = b["plate"]
		plate.add_theme_stylebox_override("panel", CityUi.plate_box(lit and can))
		(b["label"] as Label).add_theme_color_override("font_color", UiTheme.color("text_title" if can else "text_disabled"))


## 날씨가 바뀌었으면 하늘 그림·색을 맞춘다.
func _apply_weather() -> void:
	if _state.weather == _weather:
		return
	_weather = _state.weather
	var w := _state.weather_def()
	var tint := _rgb(w.get("tint"))
	for L in _layers:
		var tr: TextureRect = L["node"]
		match str(L["id"]):
			"sky":
				var sky := _tex(JsonUtil.get_str(w, "sky", str(L["path"])))
				tr.texture = sky if sky != null else _tex(str(L["path"]))
			"vignette":
				tr.modulate = Color(1, 1, 1, JsonUtil.get_float(w, "vignette", 1.0))
			"haze":
				tr.modulate = Color(tint.r, tint.g, tint.b, JsonUtil.get_float(w, "haze", 1.0))
			_:
				if tr.get_parent() == _back:
					tr.modulate = tint
	_content.modulate = tint


static func _rgb(v: Variant) -> Color:
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return Color.WHITE


func focused_id() -> String:
	return str(_buildings[_focus]["id"]) if _focus >= 0 and _focus < _buildings.size() else ""


func building_rect(id: String) -> Rect2:
	for b in _buildings:
		if str(b["id"]) == id:
			var node: Control = b["node"]
			return Rect2(node.position + _content.position, node.size)
	return Rect2()


## 화면 가운데에 가장 가까운 건물(키보드 선택 대상).
func _update_focus() -> void:
	var center := _offset + size.x / 2.0
	var best := -1
	var best_d := INF
	for i in _buildings.size():
		var b := _buildings[i]
		var mid := (float(b["x"]) + float(b["w"]) / 2.0) * _scale
		var d := absf(mid - center)
		if d < best_d:
			best_d = d
			best = i
	if best != _focus:
		_focus = best
		refresh()


func _process(delta: float) -> void:
	_time += delta
	var fl := UiTheme.render_float("city.happening_flicker", 0.15)
	for b in _buildings:
		var glow: TextureRect = b["glow"]
		if glow.visible:
			glow.modulate.a = 1.0 - fl * (0.5 + 0.5 * sin(_time * 7.0 + float(b["x"])) * sin(_time * 2.3))
	if not is_visible_in_tree() or get_viewport().gui_get_focus_owner() != null:  # 디버그 패널 등을 키로 다루는 중
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		scroll_by(dir * UiTheme.render_float("city.scroll_px_per_sec", 900.0) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("menu_confirm") or event.is_action_pressed("interact"):
		var id := focused_id()
		if not id.is_empty():
			get_viewport().set_input_as_handled()
			facility_chosen.emit(id)
