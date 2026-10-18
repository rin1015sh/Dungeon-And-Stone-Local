class_name NoticeToast
extends PanelContainer
## 잠깐 떴다 사라지는 알림 띠(사용자 결정 2026-10-18): 자잘한 탐험 알림(대기·상태 변화·안전지대·근처 문구 등)은
## 대화창처럼 Enter를 기다리지 않고 화면 위 가운데에 몇 초 보였다가 흐려진다. 시간도 멈추지 않는다.
## 최근 render.json ui.notice.lines 줄까지 쌓이고, 줄마다 ui.notice.seconds 뒤에 빠진다.

var _box: VBoxContainer
var _lines: Array[Dictionary] = []  # {"label", "left"}


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 2)
	add_child(_box)
	visible = false


static func _cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("notice"), key, fallback)


func show_line(text: String, kind: String = "info") -> void:
	if text.is_empty():
		return
	var l := UiTheme.label(text, "body", "log_" + kind)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = _cfg("width", 520.0)
	_box.add_child(l)
	_lines.append({"label": l, "left": _cfg("seconds", 2.6)})
	while _lines.size() > int(_cfg("lines", 3.0)):
		_drop(0)
	visible = true
	_recenter.call_deferred()


func line_count() -> int:
	return _lines.size()


func _process(delta: float) -> void:
	var i := 0
	while i < _lines.size():
		var e: Dictionary = _lines[i]
		e["left"] = float(e["left"]) - delta
		(e["label"] as Label).modulate.a = clampf(float(e["left"]) / _cfg("fade", 0.6), 0.0, 1.0)
		if float(e["left"]) <= 0.0:
			_drop(i)
			continue
		i += 1


func _drop(i: int) -> void:
	var l: Label = _lines[i]["label"]
	_lines.remove_at(i)
	_box.remove_child(l)
	l.queue_free()
	visible = not _lines.is_empty()
	_recenter.call_deferred()


func _recenter() -> void:
	reset_size()
	offset_left = -size.x / 2.0
	offset_right = size.x / 2.0
