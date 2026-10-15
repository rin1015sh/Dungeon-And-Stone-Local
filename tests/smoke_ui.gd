extends Node
## UI 스모크: 실제 화면을 띄우고 버튼·키 입력으로 흐름을 끝까지 밀어 본다.
##   godot --headless --path . res://tests/smoke_ui.tscn
## (--script 모드는 오토로드 등록 전에 컴파일되어 UI 스크립트를 못 읽으므로 씬으로 실행한다)
##   1) 기반 점검: 버튼으로 허기 임계값·영혼탈진·사망 판정까지
##   2) 새 탐험가 → 미궁 입장 → 이동·대기·횃불 → 디버그 패널 → 폐쇄 → 강제 귀환 화면 → 타이틀
##   3) 새 탐험가 → 굶주림 → 아사 → 사망 화면 → 타이틀
##   5) 새 탐험가 → 소지품 창(시간 정지)·끌어놓기 장착/해제·오른쪽 클릭 장착·단축칸 사용·캐릭터/도감 창
##   4) 새 탐험가 → 가만히 있어도 시간이 흐름 → 일시정지 → 몬스터 소환 → 전투(행동창 4개·조사·공격) → 탐험 복귀
##   6) 새 탐험가 → 강철의 묘 3챕터 → 수수께끼 문지기 대화창(시간 정지) → 오답 → 강화된 문지기와 전투 → 승리 → 문이 열림
##   7) 새 탐험가 → 도시(M4): 키 스크롤·건물 클릭(행동력 1) → 휴식(미정 값) → 나가기 잠금/해제 → 디버그 임시값 → 휴식으로 피로도 감소
##      → 순 넘김 → 상점 사기 → 은행 맡기기/찾기 → 소문·정보 창 → 미궁 입장 → 피로도 유지 → 귀환 → 같은 날짜로 도시
## (2~6의 강제 귀환 결과 화면은 이제 도시로 간 뒤 "타이틀로"를 누른다)
## 오류 없이 끝나면 종료 코드 0.

const WAIT_LIMIT_MS := 8000

const TEST_SAVE := "user://dungeon_and_stone/smoke_save.json"
var _main: Control
var _logs: PackedStringArray = PackedStringArray()
var _failed: bool = false


func _ready() -> void:
	GameState.save_path = TEST_SAVE  # 실제 저장(한 칸)을 덮지 않는다
	SaveGame.delete(TEST_SAVE)
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
	await _riddle_flow()
	await _city_flow()
	SaveGame.delete(TEST_SAVE)
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
		await _city_to_title(end)


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
	var labels := Array(menu.grid().option_texts())
	_expect(labels == [Strings.t("combat.cmd_attack"), Strings.t("combat.cmd_skill"), Strings.t("combat.cmd_guard"),
		Strings.t("combat.cmd_item")],
		"기본 명령: 공격·스킬·방어·아이템 (%s)" % ", ".join(PackedStringArray(labels)))
	var slots := _button_texts(menu.root_grid())
	_expect(slots.size() == menu.root_grid().page_size(), "명령 칸 %d개 — %d" % [menu.root_grid().page_size(), slots.size()])
	_expect(_has_node_named(combat, "PartyRoster") and _has_node_named(combat, "BattleStage"), "파티 창·무대")
	_expect(not _has_node_named(combat, "TimelineBar"), "상단 순서 표시 없음")
	await _keyboard_menu(combat, menu)
	menu = await _open_menu(combat)
	if not _expect(menu != null, "키보드 공격 뒤 다시 행동창"):
		return
	var turns_before := combat.battle.turns
	_press(combat, Strings.t("combat.cmd_skill"))
	var skill_labels := Array(menu.grid().option_texts())
	_expect(skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "talk")) and skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "investigate")),
		"스킬 메뉴에 대화·조사")
	_expect(skill_labels.has(Strings.t("combat.cmd_flee")), "도주는 스킬 목록에")
	_press(combat, DataNames.entry(DataRegistry.db, "skills", "investigate"))
	_press_first(menu.grid())
	_expect_log("[조사]", "조사 결과")
	_expect(combat.battle.turns > turns_before or not combat.battle.result.is_empty(), "조사가 행동 기회를 쓴다(차례가 넘어감)")
	for i in 60:
		if not combat.battle.result.is_empty():
			break
		if await _open_menu(combat) == null:
			break
		_press(combat, Strings.t("combat.cmd_attack"))
		_press_first(menu.grid())
	await _frames(2)
	_expect(not combat.battle.result.is_empty(), "전투가 끝난다 (%s, 차례 %d, 적 %s)" % [combat.battle.result, combat.battle.turns,
		combat.battle.side_units(Combatant.SIDE_ENEMY).map(func(u: Combatant) -> String: return "%s:%d" % [(u.actor as Monster).monster_id, int(u.actor.pool.get_current("hp"))])])
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
		await _city_to_title(end)


## 강철의 묘 수수께끼 문지기: 대화창 → 오답 → 강화 전투 → 승리
func _riddle_flow() -> void:
	var explore := await _enter_dungeon("수수께끼 탐험가")
	if explore == null:
		return
	var s := explore.session
	s.rifts.force_open(s, "rift_iron_tomb", s.pos)
	s.relocate(s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]["pos"])
	s.interact()
	await _frames(4)
	for i in 2:
		explore = _main.current_screen() as ExploreScreen
		explore.session.rift_run.debug_clear()
		explore.session.relocate(explore.session.map.portals[0]["pos"])
		explore.session.interact()
		await _frames(4)
	explore = _main.current_screen() as ExploreScreen
	var run := explore.session.rift_run
	if not _expect(run != null and run.chapter == 2, "강철의 묘 3챕터"):
		return
	var gate: FieldMonsters.Group = run.remaining.filter(func(g: FieldMonsters.Group) -> bool: return g.tag == "riddle")[0]
	explore.session.engage(gate, true)
	await _frames(2)
	var dlg := explore.get_node_or_null("RiddleDialog")
	if not _expect(dlg != null and explore.session.realtime.is_paused() and not explore.session.in_combat, "수수께끼 대화창(전투 대신, 시간 정지)"):
		return
	var rd := run.riddle
	var wrong := ""
	for i in rd.choices(explore.session.player):
		if not rd.is_correct(i):
			wrong = str(JsonUtil.get_array(rd.data, "choices_ko")[i])
	_press(dlg, wrong)
	await _frames(3)
	var combat := explore.combat_screen()
	if not _expect(combat != null and combat.battle.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("riddle_empowered"), "오답 → 강화된 문지기와 전투"):
		return
	combat.battle.side_units(Combatant.SIDE_ENEMY)[0].actor.pool.set_current("hp", 1.0)
	for i in 40:
		if not combat.battle.result.is_empty():
			break
		var menu := await _open_menu(combat)
		if menu == null:
			break
		_press(combat, Strings.t("combat.cmd_attack"))
		_press_first(menu.grid())
	await _frames(2)
	_expect(combat.battle.result == Battle.RESULT_VICTORY, "강화된 문지기를 쓰러뜨린다")
	_press(combat, Strings.t("combat.continue"))
	await _frames(3)
	_expect(not run.remaining.has(gate) and not explore.session.realtime.is_paused(), "문이 열리고 시간이 다시 흐른다")
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	var end := (await _screen(EndScreen)) as EndScreen
	if _expect(end != null, "결과 화면"):
		await _city_to_title(end)


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
		await _city_to_title(end)


## 행동창 키 조작: D → 스킬 칸, Space → 스킬 목록, Enter → 맨 위(커서는 스킬 칸), A → 공격, Space·Space → 첫 적을 친다.
func _keyboard_menu(combat: CombatScreen, menu: CommandMenu) -> void:
	var g := menu.grid()
	_expect(g.cursor() == CommandMenu.ROOT_ATTACK, "처음 커서는 공격")
	await _action("menu_down")
	_expect(g.cursor() == CommandMenu.ROOT_SKILL, "S → 스킬 (%d)" % g.cursor())
	await _action("menu_confirm")
	_expect(Array(menu.grid().option_texts()).has(DataNames.entry(DataRegistry.db, "skills", "talk")), "Space → 스킬 목록")
	await _action("menu_back")
	_expect(menu.grid() == g and g.cursor() == CommandMenu.ROOT_SKILL, "Enter → 명령 칸, 커서는 스킬")
	await _action("menu_down")
	_expect(g.cursor() == CommandMenu.ROOT_GUARD, "S → 방어 (%d)" % g.cursor())
	await _action("menu_up")
	await _action("menu_up")
	_expect(g.cursor() == CommandMenu.ROOT_ATTACK, "W·W → 공격")
	var turns := combat.battle.turns
	await _action("menu_confirm")
	_expect(menu.grid().title_text() == Strings.t("combat.menu_target"), "Space → 대상 고르기")
	await _action("menu_confirm")
	await _frames(2)
	_expect(combat.battle.turns > turns or not combat.battle.result.is_empty(), "Space로 고른 공격이 차례를 쓴다")


## 아군 차례가 와서 행동창이 열릴 때까지 기다린다. 전투가 끝나면 null.
func _open_menu(combat: CombatScreen) -> CommandMenu:
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline and combat.battle.result.is_empty():
		for n: Node in combat.find_children("*", "", true, false):
			if n is CommandMenu and (n as CommandMenu).is_open():
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


## 타이틀 → 새 탐험가 → 도시 화면.
func _new_city(explorer_name: String) -> CityScreen:
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
	var city := (await _screen(CityScreen)) as CityScreen
	_expect(city != null, "새 게임 시작 후 도시(" + explorer_name + ")")
	await _frames(2)
	return city


## 결과 화면(살아서 귀환) → 도시 → 타이틀.
func _city_to_title(end: EndScreen) -> void:
	_press(end, Strings.t("end.to_city"))
	var city := (await _screen(CityScreen)) as CityScreen
	if _expect(city != null, "귀환 후 도시"):
		_press(city, Strings.t("city.btn_title"))


func _enter_dungeon(explorer_name: String) -> ExploreScreen:
	var city := await _new_city(explorer_name)
	if city == null:
		return null
	city.dungeon_requested.emit()  # 하순이 끝난 것처럼(임시 버튼은 없다)
	var plaza := (await _screen(PlazaScreen)) as PlazaScreen
	if not _expect(plaza != null, "차원광장(" + explorer_name + ")"):
		return null
	plaza.open_now()
	plaza.enter_requested.emit()
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

## 도시(M4): 스크롤·건물 고르기·활동·나가기·순 넘김·상점·은행·디버그 임시값·미궁 왕복.
func _city_flow() -> void:
	var city := await _new_city("도시 탐험가")
	if city == null:
		return
	var st := city.state
	var pc := city.pc
	_expect(st.ap == 3 and st.month == 1 and st.period == 0, "첫 달 상순, 행동력 3")
	var street := city.street()
	street.scroll_to(0.0)
	Input.action_press("move_right")
	await _frames(8)
	Input.action_release("move_right")
	_expect(street.offset() > 0.0, "D로 거리를 스크롤한다")
	street.scroll_to(0.0)
	await _frames(1)
	var r := street.building_rect("inn")
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = r.get_center()
		ev.global_position = r.get_center()
		get_viewport().push_input(ev, true)
		await _frames(1)
	var fv := city.facility_view()
	if not _expect(fv != null and fv.facility_id() == "inn" and st.ap == 2, "건물 클릭 → 행동력 1을 쓰고 여관 안으로"):
		return
	_expect(not fv.can_leave(), "들어오면 무언가 하기 전엔 못 나간다")
	await _action("inventory")
	_expect(not city.windows_open() and not _has_button(city, Strings.t("city.btn_inventory", {"key": InputSetup.key_label("inventory")})), "시설 안에서는 소지품 창·버튼이 없다")
	pc.pool.modify("hp", -30.0)
	pc.fatigue.set_value(60.0)
	_press_prefix(fv, DataNames.entry(DataRegistry.db, "activities", "inn_rest"))
	await _frames(2)
	_expect(city.facility_view() == null and street.is_visible_in_tree(), "활동 한 번 → 저절로 거리로 나온다")
	_expect(is_equal_approx(pc.fatigue.value, 20.0), "휴식(−40) → 피로도 60 → 20")
	_expect(is_equal_approx(pc.pool.get_current("hp"), pc.pool.get_max("hp")), "여관 휴식 → 생명력 회복")
	pc.pool.modify("hp", -30.0)
	pc.inventory.add("minor_potion", 1)
	var hp_before := pc.pool.get_current("hp")
	var potions := pc.inventory.count("minor_potion")
	city.use_item("minor_potion")
	_expect(pc.pool.get_current("hp") > hp_before and pc.inventory.count("minor_potion") == potions - 1, "거리에서 포션을 마셨다")
	pc.inventory.add("ration", 1)
	city.use_item("ration")
	_expect(pc.inventory.has("ration"), "식량은 도시에서 쓰지 않는다")
	_expect(not city.toast_text().is_empty(), "결과가 화면 위 알림으로")
	await _action("debug_toggle")
	_expect(city.is_debug_open(), "F1로 도시 디버그 패널")
	city.debug_panel().set_edit("activities/inn_rest/effects/1/amount", "3")
	_press(city.debug_panel(), Strings.t("city.debug_apply_overrides"))
	pc.fatigue.set_value(10.0)
	await _action("debug_toggle")
	street.scroll_to(0.0)
	await _frames(1)
	await _action("menu_confirm")
	fv = city.facility_view()
	if not _expect(fv != null and fv.facility_id() == street.focused_id() and st.ap == 1, "Space로 가운데 건물에 들어간다"):
		return
	if fv.facility_id() == "inn":
		_press_prefix(fv, DataNames.entry(DataRegistry.db, "activities", "inn_rest"))
		_expect(is_equal_approx(pc.fatigue.value, 7.0), "임시값(3) 휴식 → 피로도 10 → 7")
	else:
		city.leave_facility()
	await _frames(2)
	_expect(city.facility_view() == null, "거리로 나왔다")
	city.choose_facility("shop")
	fv = city.facility_view()
	if not _expect(fv != null and st.ap == 0, "상점(행동력 0)"):
		return
	_press_prefix(fv, DataNames.entry(DataRegistry.db, "activities", "shop_trade"))
	var money := pc.inventory.money
	_press(fv, Strings.t("city.shop_buy"))
	_expect(pc.inventory.money < money, "상점에서 샀다")
	await _action("pause")
	await _frames(1)
	_expect(city.facility_view() == null, "창구에서 Esc → 거리로")
	_expect(st.period == 1 and st.ap == 3, "행동력을 다 써서 중순(행동력 3)")
	_expect(city.toast_text().contains(st.period_name()), "순 넘김 안내")
	city.choose_facility("bank")
	fv = city.facility_view()
	if _expect(fv != null, "은행"):
		_press_prefix(fv, DataNames.entry(DataRegistry.db, "activities", "bank_account"))
		var bank := fv.find_children("*", "BankPanel", true, false)
		if _expect(bank.size() == 1, "은행 패널"):
			var total := pc.inventory.money + st.bank_balance
			(bank[0] as BankPanel).set_amount(100)
			_press(fv, Strings.t("city.bank_deposit"))
			_expect(st.bank_balance == 100 and pc.inventory.money + st.bank_balance == total, "맡기기(합 그대로)")
			await _frames(1)
			bank = fv.find_children("*", "BankPanel", true, false)
			(bank[0] as BankPanel).set_amount(40)
			_press(fv, Strings.t("city.bank_withdraw"))
			_expect(st.bank_balance == 60 and pc.inventory.money + st.bank_balance == total, "찾기(합 그대로)")
		fv.try_leave()
	await _frames(1)
	var cash := pc.inventory.money
	pc.inventory.money = 0
	city.choose_facility("inn")
	await _frames(2)
	_expect(city.facility_view() == null and city.toast_text().contains(Strings.t("city.reason_no_money")), "할 게 없으면 이유를 들고 바로 나온다")
	pc.inventory.money = cash
	var fatigue := pc.fatigue.value
	var month := st.month
	st.period = st.periods().size() - 1  # 하순으로 건너뛰고 마지막 행동력으로 시설 하나
	st.ap = 1
	city.choose_facility("inn")
	fv = city.facility_view()
	if _expect(fv != null and st.ap == 0, "하순 마지막 행동력으로 여관"):
		_press_prefix(fv, DataNames.entry(DataRegistry.db, "activities", "inn_rest"))
		_expect(st.ap == 0, "시설 안 활동은 행동력을 쓰지 않는다")
		fatigue = pc.fatigue.value  # 휴식(임시값)으로 줄어든 값이 미궁으로 이어진다(활동 뒤 저절로 나와 하순이 끝난다)
	var plaza := (await _screen(PlazaScreen)) as PlazaScreen
	if not _expect(plaza != null, "하순이 끝나면 저절로 차원광장으로"):
		return
	_expect(not _has_button(plaza, Strings.t("plaza.enter")), "포탈이 열리기 전에는 들어갈 수 없다")
	var opened_by := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while not plaza.is_open() and Time.get_ticks_msec() < opened_by:
		await _frames(1)
	_expect(plaza.is_open() and _has_button(plaza, Strings.t("plaza.enter")), "포탈이 열리면 들어갈 수 있다")
	_press(plaza, Strings.t("plaza.save"))
	_expect(GameState.has_save() and _has_button(plaza, Strings.t("plaza.saved")), "차원광장에서 기록(한 칸 저장)")
	var saved_month := st.month
	var saved_name := pc.display_name
	var saved_money := pc.inventory.money
	_press(plaza, Strings.t("plaza.enter"))
	var explore := (await _screen(ExploreScreen)) as ExploreScreen
	if not _expect(explore != null, "포탈로 들어가 미궁으로"):
		return
	await _frames(2)
	var in_dungeon := explore.session.player.fatigue.value
	_expect(in_dungeon >= fatigue and in_dungeon < fatigue + 1.0, "미궁으로 피로도가 이어진다(시간이 흐르면 조금씩 오른다)")
	_expect(_has_label(explore, Strings.t("explore.hud_fatigue", {"value": CityContext.fmt(in_dungeon)}).left(4)), "미궁 HUD에 피로도")
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	var end := (await _screen(EndScreen)) as EndScreen
	if not _expect(end != null, "강제 귀환 화면"):
		return
	_press(end, Strings.t("end.to_city"))
	var back := (await _screen(CityScreen)) as CityScreen
	if _expect(back != null, "귀환 → 도시"):
		_expect([back.state.month, back.state.period, back.state.ap] == [month + 1, 0, 3], "귀환하면 다음 달 상순(행동력 3)")
		_expect(back.pc.fatigue.value > fatigue, "미궁에서 쌓인 피로도가 도시로 이어진다")
		_press(back, Strings.t("city.btn_title"))
	var title := (await _screen(TitleScreen)) as TitleScreen
	if not _expect(title != null, "타이틀로"):
		return
	_press(title, Strings.t("menu.continue"))
	var again := (await _screen(PlazaScreen)) as PlazaScreen
	if _expect(again != null, "이어하기 → 차원광장"):
		_expect(again.state.month == saved_month and again.pc.display_name == saved_name and again.pc.inventory.money == saved_money, "저장한 날짜·탐험가·소지금 그대로")
		again.open_now()
		_expect(not again.state.is_last_period() or again.state.expedition_month == saved_month, "미궁은 그 달에 한 번")
	GameState.on_death()
	_expect(not GameState.has_save(), "죽으면 기록이 지워진다")


func _press_prefix(screen: Node, prefix: String) -> void:
	for b: Node in screen.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.text.begins_with(prefix) and not btn.disabled and btn.is_visible_in_tree():
			btn.pressed.emit()
			return
	_expect(false, "버튼 '%s…'" % prefix)


## 보이는 버튼 중 그 글자의 버튼이 있는가.
func _has_button(root: Node, text: String) -> bool:
	for b: Node in root.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return true
	return false


func _has_label(root: Node, text: String) -> bool:
	for l: Node in root.find_children("*", "Label", true, false):
		if (l as Label).text.contains(text):
			return true
	return false
