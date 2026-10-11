extends Node
## UI 스모크: 실제 화면을 띄우고 버튼·키 입력으로 흐름을 끝까지 밀어 본다.
##   godot --headless --path . res://tests/smoke_ui.tscn
## (--script 모드는 오토로드 등록 전에 컴파일되어 UI 스크립트를 못 읽으므로 씬으로 실행한다)
##   1) 기반 점검: 버튼으로 허기 임계값·영혼탈진·사망 판정까지
##   2) 새 탐험가 → 미궁 입장 → 이동·대기·횃불 → 디버그 패널 → 폐쇄 → 강제 귀환 화면 → 타이틀
##   3) 새 탐험가 → 굶주림 → 아사 → 사망 화면 → 타이틀
##   5) 새 탐험가 → 소지품 창(시간 정지)·끌어놓기 장착/해제·오른쪽 클릭 장착·단축칸 사용·캐릭터/도감 창
##   4) 새 탐험가 → 가만히 있어도 시간이 흐름 → 일시정지 → 몬스터 소환 → 전투(행동창 4개·조사·공격) → 탐험 복귀
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
	await _realtime_combat_flow()
	await _inventory_flow()
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


## 실시간 시간 흐름 · 일시정지 · 전투 진입/이탈 시 시간 · 기본 행동창 · 조사
func _realtime_combat_flow() -> void:
	var explore := await _enter_dungeon("실시간 탐험가")
	if explore == null:
		return
	var s := explore.session
	var t0 := s.clock.total_hours
	var p0 := s.pos
	await _seconds(0.6)
	_expect(s.pos == p0 and s.clock.total_hours > t0, "가만히 있어도 시간이 흐른다")
	await _action("pause")
	_expect(explore.is_paused(), "일시정지")
	var tp := s.clock.total_hours
	await _seconds(0.4)
	_expect(is_equal_approx(s.clock.total_hours, tp), "일시정지 중에는 시간이 멈춘다")
	await _action("pause")
	_expect(not explore.is_paused(), "일시정지 해제")
	GameState.debug_fast_combat = true
	await _action("debug_toggle")
	_toggle(explore, Strings.t("debug.invulnerable"))
	_press(explore, Strings.t("debug.spawn_monster"))
	await _frames(3)
	var combat := explore.combat_screen()
	if not _expect(combat != null and s.in_combat, "몬스터 소환 → 전투 화면"):
		return
	var tc := s.clock.total_hours
	var menu := await _open_menu(combat)
	if not _expect(menu != null, "행동창이 열린다"):
		return
	var labels := _button_texts(menu)
	_expect(labels == [Strings.t("combat.cmd_attack"), Strings.t("combat.cmd_guard"), Strings.t("combat.cmd_skill"),
		Strings.t("combat.cmd_flee", {"chance": roundi(combat.battle.flee_chance(combat.battle.current) * 100.0)})],
		"기본 행동창: 공격·방어·스킬·도주 (%s)" % ", ".join(PackedStringArray(labels)))
	_expect(not _has_node_named(combat, "TimelineBar"), "상단 순서 표시 없음")
	var turns_before := combat.battle.turns
	_press(combat, Strings.t("combat.cmd_skill"))
	var skill_labels := _button_texts(menu)
	_expect(skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "talk")) and skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "investigate")),
		"스킬 메뉴에 대화·조사")
	_press(combat, DataNames.entry(DataRegistry.db, "skills", "investigate"))
	_press_first(menu)
	_expect_log("[조사]", "조사 결과")
	_expect(combat.battle.turns > turns_before or not combat.battle.result.is_empty(), "조사가 행동 기회를 쓴다(차례가 넘어감)")
	for i in 60:
		if not combat.battle.result.is_empty():
			break
		if await _open_menu(combat) == null:
			break
		_press(combat, Strings.t("combat.cmd_attack"))
		_press_first(menu)
	await _frames(2)
	_expect(not combat.battle.result.is_empty(), "전투가 끝난다 (%s)" % combat.battle.result)
	_expect(is_equal_approx(s.clock.total_hours, tc), "전투 중에는 탐험 시간이 멈춘다")
	var turns := combat.battle.turns
	var won := combat.battle.result == Battle.RESULT_VICTORY
	_press(combat, Strings.t("combat.continue"))
	await _frames(3)
	_expect(explore.combat_screen() == null and not s.in_combat, "탐험으로 복귀")
	if won:
		_expect(s.player.progression.exp_total > 0, "첫 처치 공적")
	_expect(s.clock.total_hours >= tc + turns * float(DataRegistry.db.bal("combat.hours_per_turn")) - 0.0001, "전투 차례만큼 시간 반영")
	var tr := s.clock.total_hours
	await _seconds(0.4)
	_expect(s.clock.total_hours > tr, "복귀 뒤 다시 시간이 흐른다")
	GameState.debug_fast_combat = false
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	var end := (await _screen(EndScreen)) as EndScreen
	if _expect(end != null, "결과 화면"):
		_press(end, Strings.t("end.to_title"))


## 소지품 창 · 장비 끌어놓기 · 단축칸 · 캐릭터/도감 창
func _inventory_flow() -> void:
	var explore := await _enter_dungeon("소지품 탐험가")
	if explore == null:
		return
	var s := explore.session
	var pc := s.player
	await _action("inventory")
	var win := explore.windows().window("inventory") as InventoryWindow
	if not _expect(win != null, "I로 소지품 창"):
		return
	_expect(s.realtime.is_paused("window"), "창이 열리면 시간이 멈춘다")
	var t0 := s.clock.total_hours
	await _seconds(0.3)
	_expect(is_equal_approx(s.clock.total_hours, t0), "창이 열린 동안 시계가 그대로")
	pc.inventory.add("steel_spear")
	var idx := pc.inventory.stacks().size() - 1
	var slot: PaperDoll.EquipSlot = win.doll.slots["main_hand"]
	_expect(slot.drop({"type": "item", "from": "grid", "index": idx, "id": "steel_spear"}), "창을 주무기 칸에 끌어놓기")
	_expect(pc.equipment.item_in("main_hand") == "steel_spear" and pc.inventory.count("iron_mace") == 1, "창 장착, 철퇴는 가방으로")
	_expect(pc.equipment.is_empty("off_hand"), "양손 무기면 방패가 빠진다")
	var spot := pc.inventory.free_spot("leather_boots")
	_expect(win.grid.drop({"type": "item", "from": "slot", "slot": "feet", "id": "leather_boots"}, spot), "장화를 가방으로 끌어 벗기")
	_expect(pc.equipment.is_empty("feet") and pc.inventory.count("leather_boots") == 1, "장화가 가방에")
	for i in pc.inventory.stacks().size():
		if pc.inventory.stacks()[i]["id"] == "leather_boots":
			win.grid.activated.emit(i)
			break
	_expect(pc.equipment.item_in("feet") == "leather_boots", "오른쪽 클릭으로 다시 장착")
	await _action("pause")
	_expect(not explore.windows().any_open() and not s.realtime.is_paused("window"), "Esc로 창 닫기 → 시간 다시 흐름")
	_expect(not explore.is_paused(), "창을 닫은 Esc는 일시정지가 아니다")
	explore.bottom_bar().slot(4).assign("medium_potion")
	_expect(pc.hotbar[4] == "medium_potion", "단축칸에 등록")
	_expect(pc.hotbar[0] == "torch", "횃불은 1번 칸")
	await _action("hotbar_1")
	_expect(pc.light.is_lit(), "1번 키로 횃불")
	await _action("character")
	_expect(explore.windows().is_open("character"), "C로 캐릭터 창")
	await _action("bestiary")
	_expect(explore.windows().is_open("bestiary"), "B로 도감 창")
	explore.windows().close_all()
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	var end := (await _screen(EndScreen)) as EndScreen
	if _expect(end != null, "결과 화면"):
		_press(end, Strings.t("end.to_title"))


## 아군 차례가 와서 행동창이 열릴 때까지 기다린다. 전투가 끝나면 null.
func _open_menu(combat: CombatScreen) -> CommandMenu:
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline and combat.battle.result.is_empty():
		for n: Node in combat.find_children("*", "", true, false):
			if n is CommandMenu and (n as CommandMenu).visible:
				return n as CommandMenu
		await get_tree().process_frame
	return null


func _button_texts(menu: Node) -> Array:
	var out: Array = []
	for b: Node in menu.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not b.is_queued_for_deletion():
			out.append((b as Button).text)
	return out


## 메뉴의 첫 번째(뒤로가 아닌) 버튼을 누른다 — 대상 목록의 첫 대상.
func _press_first(menu: Node) -> void:
	for b: Node in menu.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.is_visible_in_tree() and not btn.disabled and not btn.is_queued_for_deletion() and btn.text != Strings.t("menu.back"):
			btn.pressed.emit()
			return
	_expect(false, "메뉴의 첫 버튼")


func _has_node_named(root: Node, class_label: String) -> bool:
	for n: Node in root.find_children("*", "", true, false):
		var sc := n.get_script() as Script
		if sc != null and sc.get_global_name() == class_label:
			return true
	return false


func _seconds(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


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
