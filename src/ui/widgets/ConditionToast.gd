class_name ConditionToast
extends Control
## 허기·피로 단계 알림(사용자 결정 2026-11-04 "구간에 도달할 때마다 — 엔터로 넘기는 알림이 아니라 좌하단에 저절로 사라지게"):
## 화면 왼쪽 아래에 짧은 문구가 쌓였다가 sec초 뒤 흐려지며 사라진다. Enter를 받지 않고 흐름을 멈추지 않는다.
## 문구 = ko.json condition.<id>({who} = 탐험가 이름). 수치는 render.json ui.condition_toast.

var _stack: VBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.add_theme_constant_override("separation", 4)
	_stack.alignment = BoxContainer.ALIGNMENT_END
	add_child(_stack)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stack.anchor_left = 0.0
	_stack.anchor_right = 0.0
	_stack.anchor_top = 1.0
	_stack.anchor_bottom = 1.0
	_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_stack.offset_left = float(_cfg_int("x", 18))
	_stack.offset_bottom = -float(_cfg_int("y", 190))


## id = 허기 상태 id 또는 피로 단계 id. 심해지는 단계일수록 붉은 글자(starving·starvation·collapse).
func notice(id: String, who: String) -> void:
	var key := "condition." + id
	var text := Strings.t(key, {"who": who})
	if text == key:  # 문구 없는 단계는 띄우지 않는다
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiTheme.translucent_panel())
	var severe := id in ["starving", "starvation", "collapse"]
	panel.add_child(UiTheme.label(text, "body", "bad" if severe else "text_title"))
	_stack.add_child(panel)
	while _stack.get_child_count() > _cfg_int("max", 3):
		var old := _stack.get_child(0)
		_stack.remove_child(old)
		old.queue_free()
	var tw := panel.create_tween()
	tw.tween_interval(_cfg_float("sec", 3.5))
	tw.tween_property(panel, "modulate:a", 0.0, _cfg_float("fade_sec", 0.8))
	tw.tween_callback(panel.queue_free)


## 지금 떠 있는 알림 수(시험용).
func count() -> int:
	return _stack.get_child_count()


func _cfg_int(key: String, fallback: int) -> int:
	return int(_cfg(key, float(fallback)))


func _cfg_float(key: String, fallback: float) -> float:
	return _cfg(key, fallback)


func _cfg(key: String, fallback: float) -> float:
	return JsonUtil.get_float(UiTheme.ui_dict("condition_toast"), key, fallback)
