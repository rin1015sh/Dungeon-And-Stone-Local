extends Node
## UI 스모크: 실제 화면을 띄우고 버튼·키 입력으로 흐름을 끝까지 밀어 본다.
##   godot --headless --path . res://tests/smoke_ui.tscn
## (--script 모드는 오토로드 등록 전에 컴파일되어 UI 스크립트를 못 읽으므로 씬으로 실행한다)
##   1) 기반 점검: 버튼으로 허기 임계값·영혼탈진·사망 판정까지
##   2) 새 탐험가 → 미궁 입장 → 이동·대기·횃불 → 디버그 패널 → 폐쇄 → 강제 귀환 화면 → 타이틀
##   3) 새 탐험가 → 굶주림 → 아사 → 사망 화면 → 타이틀
## 오류 없이 끝나면 종료 코드 0.

const WAIT_LIMIT_MS := 8000

var _main: Control
var _logs: PackedStringArray = PackedStringArray()
var _failed: bool = false


func _ready() -> void:
	EventBus.log_message.connect(func(text: String, _kind: String) -> void: _logs.append(text))
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(2)
	await _foundation_flow()
	await _closing_flow()
	await _starvation_flow()
	print("UI 스모크 로그 %d줄" % _logs.size())
	print("UI 스모크 %s" % ("실패" if _failed else "통과"))
	get_tree().quit(1 if _failed else 0)


func _foundation_flow() -> void:
	var title := (await _screen(TitleScreen)) as TitleScreen
	if not _expect(title != null, "타이틀 화면"):
		return
	title.foundation_requested.emit()
	var screen := (await _screen(FoundationScreen)) as FoundationScreen
	if not _expect(screen != null, "기반 점검 화면"):
		return
	_press(screen, Strings.t("foundation.reroll", {"left": _bal("char_creation.max_rerolls")}))
	_press(screen, Strings.t("foundation.level_up"))
	_toggle(screen, Strings.t("foundation.in_dungeon"))
	_press(screen, Strings.t("foundation.act_buff_on", {"amount": _bal("debug.sandbox_buff_str"), "hours": _bal("debug.sandbox_buff_hours")}))
	for i in 75:
		_press(screen, Strings.t("foundation.act_hour"))
	_press(screen, Strings.t("foundation.act_eat", {"amount": _bal("debug.sandbox_food")}))
	for i in 10:
		_press(screen, Strings.t("foundation.act_spend_soul", {"amount": _bal("debug.sandbox_soul_cost")}))
	for i in 5:
		_press(screen, Strings.t("foundation.act_turn"))
	for i in 30:
		_press(screen, Strings.t("foundation.act_damage", {"amount": _bal("debug.sandbox_damage")}))
	_press(screen, Strings.t("foundation.act_restore"))
	_expect_log(Strings.t("log.buff_expired"), "비약 만료")
	_expect_log(Strings.t("log.depleted_hp"), "사망 판정")
	_expect_log(Strings.t("log.status_on", {"status": _status("hungry")}), "허기 진입")
	_expect_log(Strings.t("log.status_on", {"status": _status("soul_exhaustion")}), "영혼탈진 진입")
	_expect_log(Strings.t("log.status_off", {"status": _status("soul_exhaustion")}), "영혼탈진 해제")
	screen.back_requested.emit()


## 새 탐험가 → 입장 → 이동·대기·횃불·디버그 → 폐쇄 → 강제 귀환 → 타이틀
func _closing_flow() -> void:
	var explore := await _enter_dungeon("시험 탐험가")
	if explore == null:
		return
	_expect_log(Strings.t("explore.enter", {"floor": explore.session.floor_name()}), "입장 메시지")
	var start := explore.session.pos
	for action: String in ["move_up", "move_right", "move_down", "move_left"]:
		Input.action_press(action)
		await _frames(3)
		Input.action_release(action)
		await _frames(1)
	await _action("wait")
	await _action("torch")
	_expect(explore.session.player.light.is_lit(), "T로 횃불을 켠다")
	await _action("debug_toggle")
	_expect(explore.is_debug_open(), "F1로 디버그 패널")
	_press(explore, Strings.t("debug.to_portal"))
	_expect(explore.session.pos != start, "디버그 이동")
	_press(explore, Strings.t("debug.reveal"))
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	_expect_log(Strings.t("explore.closed"), "층 폐쇄 메시지")
	var end := (await _screen(EndScreen)) as EndScreen
	if _expect(end != null, "강제 귀환 화면"):
		_press(end, Strings.t("end.to_title"))


## 새 탐험가 → 허기 0 → 시간 스킵 → 아사 → 사망 화면 → 타이틀
func _starvation_flow() -> void:
	var explore := await _enter_dungeon("굶는 탐험가")
	if explore == null:
		return
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.hunger_zero"))
	for i in 10:
		if explore.session.ended:
			break
		_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_long")}))
	_expect(explore.session.player.dead, "아사")
	var end := (await _screen(EndScreen)) as EndScreen
	if _expect(end != null, "사망 화면"):
		_press(end, Strings.t("end.to_title"))
	var back := await _screen(TitleScreen)
	_expect(back != null, "타이틀로 복귀")


func _enter_dungeon(explorer_name: String) -> ExploreScreen:
	var title := (await _screen(TitleScreen)) as TitleScreen
	if not _expect(title != null, "타이틀 화면"):
		return null
	title.new_game_requested.emit()
	var create := (await _screen(CharacterCreateScreen)) as CharacterCreateScreen
	if not _expect(create != null, "새 탐험가 화면"):
		return null
	_press(create, Strings.t("create.reroll", {"left": _bal("char_creation.max_rerolls")}))
	for edit: Node in create.find_children("*", "LineEdit", true, false):
		(edit as LineEdit).text = explorer_name
	_press(create, Strings.t("create.enter"))
	var explore := (await _screen(ExploreScreen)) as ExploreScreen
	_expect(explore != null and explore.session.player.display_name == explorer_name, "미궁 입장(" + explorer_name + ")")
	await _frames(2)
	return explore


func _screen(type: Variant) -> Node:
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline:
		var s: Control = _main.current_screen()
		if s != null and is_instance_of(s, type) and s.is_inside_tree():
			return s
		await get_tree().process_frame
	return null


func _action(action: String) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _press(screen: Node, text: String) -> void:
	for b: Node in screen.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.text == text and not btn.disabled and btn.is_visible_in_tree():
			btn.pressed.emit()
			return
	_expect(false, "버튼 '%s'" % text)


func _toggle(screen: Node, text: String) -> void:
	for b: Node in screen.find_children("*", "CheckButton", true, false):
		var btn := b as CheckButton
		if btn.text == text:
			btn.button_pressed = not btn.button_pressed
			return
	_expect(false, "토글 '%s'" % text)


func _expect_log(text: String, what: String) -> void:
	_expect("\n".join(_logs).contains(text), "기록: " + what)


func _bal(path: String) -> int:
	return int(DataRegistry.db.bal(path, 0))


func _status(id: String) -> String:
	return DataNames.entry(DataRegistry.db, "statuses", id)


func _expect(cond: bool, what: String) -> bool:
	if not cond:
		_failed = true
		print("FAIL  UI 스모크: " + what)
	return cond
