class_name StreetEventView
extends Control
## 거리 사건 일러스트(2026-10-22 사용자 "이벤트 나오면 일러스트 나오고 뒤에 도시 조작은 막아두고", CT45):
## 도시 화면을 어둡게 덮고 가운데에 그 사건 그림 한 장(data/street_events art)을 테두리와 함께 띄운다 — 장면 글(대화창)·선택 창은 그 위.
## 떠 있는 동안 도시 조작(거리 넘기기·들어가기·Tab·Esc)은 CityScreen이 막는다. 배치·어둡기는 render.json city.event_art.

var _pic: TextureRect
var _frame: Panel


## path = 그림 경로(없으면 어둡게만 덮는다).
func setup(path: String) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cfg := UiTheme.render_dict("city.event_art")
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, JsonUtil.get_float(cfg, "dim", 0.82))
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_frame = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(JsonUtil.get_int(cfg, "border", 2))
	sb.border_color = CityUi.c("border")
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 10
	_frame.add_theme_stylebox_override("panel", sb)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	_pic = TextureRect.new()
	_pic.texture = load(path) as Texture2D
	_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pic)
	resized.connect(_layout)
	_layout()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, JsonUtil.get_float(cfg, "fade_sec", 0.3))


func has_picture() -> bool:
	return _pic != null


## 그림 자리: 위 여백부터 대화창 위까지, 가로 가운데(16:9 그대로).
func _layout() -> void:
	if _pic == null:
		return
	var cfg := UiTheme.render_dict("city.event_art")
	var top := JsonUtil.get_float(cfg, "top", 24.0)
	var bottom := size.y - JsonUtil.get_float(cfg, "bottom_reserve", 168.0)
	var tex := _pic.texture.get_size()
	var h := maxf(1.0, bottom - top)
	var w := minf(size.x - 2.0 * JsonUtil.get_float(cfg, "side", 32.0), h * tex.x / tex.y)
	h = w * tex.y / tex.x
	var rect := Rect2((size.x - w) / 2.0, top + (bottom - top - h) / 2.0, w, h)
	_pic.position = rect.position
	_pic.size = rect.size
	var b := float(JsonUtil.get_int(cfg, "border", 2))
	_frame.position = rect.position - Vector2(b, b)
	_frame.size = rect.size + Vector2(b, b) * 2.0


## 흐려지며 사라진다.
func close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, JsonUtil.get_float(UiTheme.render_dict("city.event_art"), "fade_sec", 0.3))
	tw.tween_callback(queue_free)
