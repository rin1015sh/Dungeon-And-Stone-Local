class_name RiddleDialog
extends CenterContainer
## 수수께끼 문지기 대화창(강철의 묘 — RiftRiddle). 문항과 남은 선택지를 보이고, 정답이면 "지나간다 / 약해진 문지기와 싸운다"를 고른다.
## 고르면 answered(결과 RiftRiddle.PASS/WEAKEN/WRONG)를 내고 스스로 닫힌다. 닫기(✕)는 고르지 않고 물러난다(cancelled).

signal answered(outcome: String)
signal cancelled

var _win: GothicWindow


func setup(riddle: RiftRiddle, pc: PlayerCharacter) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_win = GothicWindow.new(Strings.t("riddle.title"))
	_win.custom_minimum_size.x = UiTheme.metric("riddle_width", 520)
	_win.close_requested.connect(cancel)
	add_child(_win)
	var q := UiTheme.label(JsonUtil.get_str(riddle.data, "question_ko"), "body", "text")
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_win.content.add_child(q)
	var known := riddle.known(pc)
	if known > 0:
		_win.content.add_child(UiTheme.label(Strings.t("riddle.hints_known", {"n": known}), "small", "text_dim"))
	var choices := JsonUtil.get_array(riddle.data, "choices_ko")
	for i in riddle.choices(pc):
		var idx := i
		_win.content.add_child(UiTheme.button(str(choices[i]), func() -> void: _pick(riddle, idx)))
	_focus_first.call_deferred()


## 고르지 않고 물러난다(✕ · 정지 키).
func cancel() -> void:
	if is_queued_for_deletion():
		return
	cancelled.emit()
	queue_free()


## 키보드로도 답하게 첫 선택지에 포커스(위아래 화살표·Tab으로 옮기고 Space/Enter로 고른다).
func _focus_first() -> void:
	for c in _win.content.get_children():
		if c is Button and not c.is_queued_for_deletion():
			(c as Button).grab_focus()
			return


func _pick(riddle: RiftRiddle, idx: int) -> void:
	if not riddle.is_correct(idx):
		answered.emit(RiftRiddle.WRONG)
		queue_free()
		return
	for c in _win.content.get_children():
		c.queue_free()
	var ok := UiTheme.label(Strings.t("riddle.correct"), "body", "text_title")
	ok.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_win.content.add_child(ok)
	_win.content.add_child(UiTheme.button(Strings.t("riddle.choose_pass"), func() -> void: _done(RiftRiddle.PASS)))
	_win.content.add_child(UiTheme.button(Strings.t("riddle.choose_weaken"), func() -> void: _done(RiftRiddle.WEAKEN)))
	_focus_first.call_deferred()


func _done(outcome: String) -> void:
	answered.emit(outcome)
	queue_free()
