class_name FeatureDialog
extends CenterContainer
## 동굴 요소의 행동 고르기(맑은 샘: 마신다·상처를 씻는다·물을 담는다 등 — FieldFeatures). 고르면 picked를 내고 닫힌다.
## 닫기(✕ · 정지 키)는 고르지 않고 닫는다.

signal picked(action_id: String)
signal closed

var _win: GothicWindow


func setup(title: String, actions: Array[Dictionary]) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_win = GothicWindow.new(title)
	_win.custom_minimum_size.x = UiTheme.metric("feature_dialog_width", 360)
	_win.close_requested.connect(cancel)
	add_child(_win)
	for a in actions:
		var aid := str(a["id"])
		_win.content.add_child(UiTheme.button(str(a["name_ko"]), func() -> void: _pick(aid)))
	_focus_first.call_deferred()


func cancel() -> void:
	if is_queued_for_deletion():
		return
	closed.emit()
	queue_free()


func _pick(aid: String) -> void:
	picked.emit(aid)
	closed.emit()
	queue_free()


func _focus_first() -> void:
	for c in _win.content.get_children():
		if c is Button and not c.is_queued_for_deletion():
			(c as Button).grab_focus()
			return
