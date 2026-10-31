class_name DialogueBox
extends PanelContainer
## 하단 대화창(피어 앤 헝거식, 사용자 결정 2026-10-18): 알림·전투 안내를 대사처럼 한 쪽씩 보여 주고 Enter로 넘긴다.
## **한 쪽 = 한 문장**(사용자 결정 2026-10-31, UI44 — `DialogueSplit`이 문장으로 나눈다, 책 제목 줄은 첫 문장에 붙는다). 한 문장이 창보다 길면
## 창 폭으로 미리 접은 줄을 창 높이에 들어가는 만큼(최대 render.json ui.dialog.lines)씩 쪽으로 나누고, 창 안에서 다시 접지 않는다(사용자 요청 2026-10-27).
## 글자는 한 자씩 나오고(chars_per_sec), 나오는 중에 Enter = 바로 다 보이기.
## 게임 전체가 이 창 하나(전투 화면 모양·자리 — place_bottom)를 쓴다(사용자 결정 2026-10-27, UI36).
## 줄이 남아 있는 동안(busy) 보이고, 다 넘기면 숨고 drained를 낸다(idle_text가 있으면 그 글을 흐리게 남긴 채 보인다).
## 떠 있는 동안 키 입력은 이 창이 먼저 먹는다(정지 Esc·디버그 F1만 지나간다) — 아래 화면이 같은 Enter로 움직이지 않게.
##   box.say("글", "warn") · await box.wait() — 다 넘길 때까지 기다린다(쌓인 줄이 없으면 바로 돌아온다).

signal drained
signal shown_changed(on: bool)

## 테스트·캡처용: 켜면 모든 대화창이 기다리지 않는다(줄을 보이지 않고 바로 지나간다).
static var auto_skip: bool = false

## 이 창만 기다리지 않는다(전투 빨리 감기 디버그).
var instant: bool = false
## 넘길 줄이 없을 때 흐리게 보일 글(시설 정보 줄 등). 비어 있으면 줄이 없을 때 창을 숨긴다.
var idle_text: String = "":
	set(v):
		idle_text = v
		if is_node_ready() and not busy():
			_render()
## idle_text 색(log_<kind>). 비어 있으면 흐린 글.
var idle_kind: String = ""

var _queue: Array[Dictionary] = []  # 아직 안 보인 문장 {"parts": 접은 줄들, "kind"} — 한 쪽에 하나만
var _page: Array[Dictionary] = []  # 지금 쪽의 보이는 줄 {"text", "kind"}
var _text: RichTextLabel
var _mark: Control
var _plate: Label
var _reveal: float = 0.0  # 지금 쪽에서 나온 글자 수
var _blink: float = 0.0


func _init(style: StyleBox = null) -> void:
	add_theme_stylebox_override("panel", style if style != null else default_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


static func default_style() -> StyleBoxFlat:
	var box := UiTheme.panel_box(UiTheme.metric("padding", 8))
	box.content_margin_left = _cfg("pad_x", 22.0)
	box.content_margin_right = _cfg("pad_x", 22.0)
	box.content_margin_top = _cfg("pad_y", 14.0)
	box.content_margin_bottom = _cfg("pad_y", 14.0)
	return box


static func _cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("dialog"), key, fallback)


## 창 크기(폭·높이 — 전투 아래 창도 같은 크기).
static func box_size() -> Vector2:
	return Vector2(_cfg("width", 800.0), _cfg("height", 196.0))


## 화면 아래 가운데에 놓는다(폭 box_size — 화면이 좁으면 여백만 남기고). 어느 화면이든 같은 자리.
static func place_bottom(c: Control, parent: Control) -> void:
	parent.add_child(c)
	var m := float(UiTheme.metric("margin", 16))
	var sz := box_size()
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_top = -m - sz.y
	c.offset_bottom = -m
	var fit := func() -> void:
		var half := minf(sz.x / 2.0, parent.size.x / 2.0 - m) if parent.size.x > 0.0 else sz.x / 2.0
		c.offset_left = -half
		c.offset_right = half
	fit.call()
	parent.resized.connect(fit)


func _ready() -> void:
	var font := int(_cfg("font_size", 18.0))
	custom_minimum_size.y = _cfg("height", 128.0)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.scroll_active = false
	_text.fit_content = false
	_text.autowrap_mode = TextServer.AUTOWRAP_OFF  # 줄은 _wrap이 미리 접는다(창 안에서 다시 접히면 쪽이 넘친다)
	_text.clip_contents = true
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", font)
	_text.add_theme_constant_override("line_separation", int(_cfg("line_gap", 6.0)))
	add_child(_text)
	_mark = Control.new()  # 다음 쪽 표시(아래 가운데 깜박이는 작은 삼각형) — 글꼴에 없는 기호를 쓰지 않으려고 직접 그린다
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.draw.connect(_draw_mark)
	add_child(_mark)
	_plate = UiTheme.label("", "body", "text_title")  # 이름판(시설 이름 등): 창 위 왼쪽에 걸친다
	_plate.visible = false
	var pb := UiTheme.panel_box(4)
	pb.content_margin_left = 14
	pb.content_margin_right = 14
	_plate.add_theme_stylebox_override("normal", pb)
	_plate.top_level = true
	add_child(_plate)
	resized.connect(_place_plate)
	_render()


## 이름판 글(빈 글이면 숨김).
func set_speaker(text: String) -> void:
	_plate.text = text
	_plate.visible = not text.is_empty() and visible
	_place_plate.call_deferred()


func say(text: String, kind: String = "info") -> void:
	if text.is_empty() or _skipping():
		return
	for s in DialogueSplit.sentences(text):
		_queue.append({"parts": _wrap(s), "kind": kind})
	if _page.is_empty() and not _queue.is_empty():
		_next_page()


## 넘길 줄이 남았는가.
func busy() -> bool:
	return not _page.is_empty() or not _queue.is_empty()


## 다 넘길 때까지 기다린다.
func wait() -> void:
	while busy() and is_inside_tree():
		await drained


## 쌓인 줄을 모두 버리고 닫는다(drained를 낸다).
func clear() -> void:
	var was := busy()
	_queue.clear()
	_page.clear()
	_render()
	if was:
		drained.emit()


## Enter: 글자가 나오는 중이면 다 보이고, 다 보였으면 다음 쪽(없으면 닫힘).
func advance() -> void:
	if not busy():
		return
	if _reveal < float(_page_chars()):
		_reveal = float(_page_chars())
		_text.visible_characters = -1
		return
	_page.clear()
	if busy():
		_next_page()
	else:
		_render()
		drained.emit()


func page_text() -> String:
	return "\n".join(_page.map(func(l: Dictionary) -> String: return str(l["text"])))


func _skipping() -> bool:
	return auto_skip or instant


## 한 쪽 줄 수: 창 안쪽 높이에 들어가는 줄(글꼴 높이 + 줄 간격) — 최대 ui.dialog.lines.
func _per_page() -> int:
	var font := _font()
	var line_h := font.get_height(_font_size()) + _cfg("line_gap", 6.0)
	var inner := box_size().y - _cfg("pad_y", 14.0) * 2.0 - _cfg("mark_size", 7.0)
	return clampi(int((inner + _cfg("line_gap", 6.0)) / line_h), 1, maxi(1, int(_cfg("lines", 4.0))))


func _font() -> Font:
	return _text.get_theme_font("normal_font") if _text != null else ThemeDB.fallback_font


func _font_size() -> int:
	return int(_cfg("font_size", 18.0))


## 글을 창 폭에 맞춰 보이는 줄로 접는다(낱말 단위, 줄바꿈 글자도 지킨다).
func _wrap(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var width := _wrap_width()
	var font := _font()
	for para in text.split("\n"):
		var tp := TextParagraph.new()
		tp.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
		tp.width = width
		tp.add_string(para, font, _font_size())
		if tp.get_line_count() == 0:
			out.append("")
		for i in tp.get_line_count():
			var r := tp.get_line_range(i)
			out.append(para.substr(r.x, r.y - r.x).strip_edges())
	return out


func _wrap_width() -> float:
	var w := size.x if size.x > 0.0 else box_size().x
	return maxf(40.0, w - _cfg("pad_x", 22.0) * 2.0 - 2.0)


## 빈 쪽을 다음 문장 하나로 채운다(다른 문장은 섞지 않는다 — UI44). 창보다 긴 문장만 들어가는 줄까지 보이고 남은 줄은 다음 쪽으로.
func _fill() -> void:
	if not _page.is_empty() or _queue.is_empty():
		return
	var q: Dictionary = _queue[0]
	var parts: PackedStringArray = q["parts"]
	var take := mini(_per_page(), parts.size())
	for i in take:
		_page.append({"text": parts[i], "kind": q["kind"]})
	if take < parts.size():
		q["parts"] = parts.slice(take)
	else:
		_queue.pop_front()


func _next_page() -> void:
	_page.clear()
	_fill()
	_reveal = 0.0
	_render()


func _page_chars() -> int:
	return _text.get_total_character_count() if _text != null else 0


func _render() -> void:
	if _text == null:
		return
	_text.clear()
	if busy():
		for i in _page.size():
			var l: Dictionary = _page[i]
			if i > 0:
				_text.newline()
			_text.push_color(UiTheme.color("log_" + str(l["kind"]), UiTheme.color("text")))
			_text.add_text(str(l["text"]))
			_text.pop()
		_text.visible_characters = int(_reveal) if _reveal < float(_page_chars()) else -1
	elif not idle_text.is_empty():
		_text.push_color(UiTheme.color("log_" + idle_kind, UiTheme.color("text")) if not idle_kind.is_empty() else UiTheme.color("text_dim"))
		var idle := _wrap(idle_text)
		_text.add_text("\n".join(idle.slice(0, _per_page())))
		_text.pop()
		_text.visible_characters = -1
	var on := busy() or not idle_text.is_empty()
	if on != visible:
		visible = on
		_plate.visible = on and not _plate.text.is_empty()
		shown_changed.emit(on)
	_mark.queue_redraw()


func _process(delta: float) -> void:
	if not busy():
		return
	_blink += delta
	var total := float(_page_chars())
	if _reveal < total:
		_reveal = minf(total, _reveal + delta * _cfg("chars_per_sec", 90.0))
		_text.visible_characters = int(_reveal) if _reveal < total else -1
	_mark.queue_redraw()


func _draw_mark() -> void:
	if not busy() or _reveal < float(_page_chars()):
		return
	var r := get_rect()
	_mark.position = Vector2.ZERO
	var s := _cfg("mark_size", 7.0)
	var c := Vector2(r.size.x * 0.5, r.size.y - s - 4.0 + sin(_blink * 5.0) * 2.0)
	var col := UiTheme.color("select")
	col.a = 0.6 + 0.4 * absf(sin(_blink * 3.0))
	_mark.draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s * 0.6), c + Vector2(s, -s * 0.6), c + Vector2(0, s * 0.6)]), col)


func _place_plate() -> void:
	if _plate == null or not is_inside_tree():
		return
	_plate.reset_size()
	_plate.global_position = global_position + Vector2(_cfg("plate_x", 18.0), -_plate.size.y + 4.0)


## 줄이 남아 있으면 키를 먼저 먹는다: Enter(선택)·살피기 키 = 넘기기, 정지·디버그 키만 아래로 지나간다.
func _unhandled_input(event: InputEvent) -> void:
	if not busy() or not is_visible_in_tree() or not (event is InputEventKey or event is InputEventAction) or not event.is_pressed():
		return
	for pass_through: String in ["pause", "debug_toggle"]:
		if InputMap.has_action(pass_through) and event.is_action_pressed(pass_through):
			return
	get_viewport().set_input_as_handled()
	for a: String in ["menu_confirm", "interact", "ui_accept"]:
		if InputMap.has_action(a) and event.is_action_pressed(a):
			advance()
			return
