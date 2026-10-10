extends Node
## UI 스모크: 메인 씬 → 기반 점검 화면 → 조작 버튼을 실제로 눌러 본다.
##   godot --headless --path . res://tests/smoke_ui.tscn
## (--script 모드는 오토로드 등록 전에 컴파일되어 UI 스크립트를 못 읽으므로 씬으로 실행한다)
## 허기 임계값·영혼탈진·사망 판정까지 이어지는지 로그로 확인하고, 오류 없이 끝나면 종료 코드 0.

var _frame: int = 0
var _main: Control
var _logs: PackedStringArray = PackedStringArray()
var _failed: bool = false


func _ready() -> void:
	EventBus.log_message.connect(func(text: String, _kind: String) -> void: _logs.append(text))
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		2:
			var title := _find(TitleScreen) as TitleScreen
			_expect(title != null, "타이틀 화면")
			if title != null:
				title.foundation_requested.emit()
		4:
			_drive_foundation()
		6:
			var screen := _find(FoundationScreen) as FoundationScreen
			if screen != null:
				screen.back_requested.emit()
		8:
			_expect(_find(TitleScreen) != null, "돌아가기 후 타이틀")
			print("UI 스모크 로그 %d줄" % _logs.size())
			print("UI 스모크 %s" % ("실패" if _failed else "통과"))
			get_tree().quit(1 if _failed else 0)


func _drive_foundation() -> void:
	var screen := _find(FoundationScreen) as FoundationScreen
	_expect(screen != null, "기반 점검 화면")
	if screen == null:
		return
	_press(screen, Strings.t("foundation.reroll", {"left": _bal("char_creation.max_rerolls")}))
	_press(screen, Strings.t("foundation.level_up"))
	_press_toggle(screen, Strings.t("foundation.in_dungeon"))
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
	var text := "\n".join(_logs)
	for key: String in ["log.buff_expired", "log.depleted_hp", "log.restore"]:
		_expect(text.contains(Strings.t(key)), key)
	_expect(text.contains(Strings.t("log.status_on", {"status": _status_name("hungry")})), "허기 진입")
	_expect(text.contains(Strings.t("log.status_on", {"status": _status_name("soul_exhaustion")})), "영혼탈진 진입")
	_expect(text.contains(Strings.t("log.status_off", {"status": _status_name("soul_exhaustion")})), "영혼탈진 해제")


func _press(screen: Node, text: String) -> void:
	for b: Node in screen.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.text == text and not btn.disabled:
			btn.pressed.emit()
			return
	_expect(false, "버튼 '%s'" % text)


func _press_toggle(screen: Node, text: String) -> void:
	for b: Node in screen.find_children("*", "CheckButton", true, false):
		var btn := b as CheckButton
		if btn.text == text:
			btn.button_pressed = not btn.button_pressed
			return
	_expect(false, "토글 '%s'" % text)


func _find(type: Variant) -> Node:
	for c: Node in _main.get_children():
		if is_instance_of(c, type) and not c.is_queued_for_deletion():
			return c
	return null


func _bal(path: String) -> int:
	return int(DataRegistry.db.bal(path, 0))


func _status_name(id: String) -> String:
	return JsonUtil.get_str(DataRegistry.db.get_entry("statuses", id), "name_ko", id)


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_failed = true
		print("FAIL  UI 스모크: " + what)
