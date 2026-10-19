class_name RiddleDialog
extends CenterContainer
## 수수께끼 문지기 대화창(강철의 묘 — RiftRiddle). 문항과 남은 선택지를 보이고, 정답이면 "지나간다 / 약해진 문지기와 싸운다"를 고른다.
## 선택지는 ChoiceGrid(W/S·Enter). 고르면 answered(결과 RiftRiddle.PASS/WEAKEN/WRONG)를 내고 스스로 닫힌다.
## 정지 키·Backspace는 고르지 않고 물러난다(cancelled — ExploreScreen이 받는다).

signal answered(outcome: String)
signal cancelled

var _win: GothicWindow
var _grid: ChoiceGrid


func setup(riddle: RiftRiddle, pc: PlayerCharacter) -> void:
	_win = GothicWindow.new(Strings.t("riddle.title"))
	_win.custom_minimum_size.x = UiTheme.metric("riddle_width", 520)
	add_child(_win)
	var q := UiTheme.label(JsonUtil.get_str(riddle.data, "question_ko"), "body", "text")
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_win.content.add_child(q)
	var known := riddle.known(pc)
	if known > 0:
		_win.content.add_child(UiTheme.label(Strings.t("riddle.hints_known", {"n": known}), "small", "text_dim"))
	var choices := JsonUtil.get_array(riddle.data, "choices_ko")
	var opts: Array[Dictionary] = []
	for i in riddle.choices(pc):
		var idx := i
		opts.append({"text": str(choices[i]), "on_pick": func() -> void: _pick(riddle, idx)})
	_show(opts)


## 고르지 않고 물러난다(정지 키·Backspace).
func cancel() -> void:
	if is_queued_for_deletion():
		return
	cancelled.emit()
	queue_free()


func _show(opts: Array[Dictionary]) -> void:
	if _grid != null:
		_grid.queue_free()
	_grid = ChoiceGrid.new(1, opts.size(), UiTheme.metric("popup_slot_height", 40), true)
	_win.content.add_child(_grid)
	_grid.show_choices("", opts, cancel)


func _pick(riddle: RiftRiddle, idx: int) -> void:
	if not riddle.is_correct(idx):
		answered.emit(RiftRiddle.WRONG)
		queue_free()
		return
	for c in _win.content.get_children():
		c.queue_free()
	_grid = null
	var ok := UiTheme.label(Strings.t("riddle.correct"), "body", "text_title")
	ok.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_win.content.add_child(ok)
	_show([{"text": Strings.t("riddle.choose_pass"), "on_pick": func() -> void: _done(RiftRiddle.PASS)},
		{"text": Strings.t("riddle.choose_weaken"), "on_pick": func() -> void: _done(RiftRiddle.WEAKEN)}])


func _done(outcome: String) -> void:
	answered.emit(outcome)
	queue_free()
