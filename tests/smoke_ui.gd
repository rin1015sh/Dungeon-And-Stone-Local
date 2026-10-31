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
const SMOKE_FOE_HP := 80  ## 전투 흐름 시험 동안 적에게 더하는 생명력(첫 공격에 전투가 끝나지 않게)

const TEST_SAVE := "user://dungeon_and_stone/smoke_save.json"
var _main: Control
var _logs: PackedStringArray = PackedStringArray()
var _failed: bool = false


func _ready() -> void:
	GameState.save_path = TEST_SAVE  # 실제 저장(한 칸)을 덮지 않는다
	DialogueBox.auto_skip = true  # 대화창(알림)은 기다리지 않는다 — 대화창 자체는 _dialog_checks에서 따로 본다
	CityAmbient.enabled = false  # 거리 사건은 _street_flow에서만(선택 창이 다른 흐름을 막지 않게)
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
	await _tax_flow()
	await _street_flow()
	await _library_flow()
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
	await _action("menu")  # 아이템은 Tab 메뉴에서만: 횃불 칸 → Enter → 사용한다
	var tpc := explore.session.player
	for i in tpc.inventory.stacks().size():
		if tpc.inventory.stacks()[i]["id"] == "torch":
			explore.menu().inventory().cursor_to_cell(Vector2i(tpc.inventory.stacks()[i]["pos"]))
	await _action("menu_confirm")
	await _action("menu_confirm")
	await _action("menu")
	_expect(tpc.light.is_lit() and not explore.menu().is_open(), "Tab 메뉴에서 횃불을 켠다")
	await _action("debug_toggle")
	_expect(explore.is_debug_open(), "F1로 디버그 패널")
	_press(explore, Strings.t("debug.to_portal"))
	_expect(explore.session.pos != start, "디버그 이동")
	_press(explore, Strings.t("debug.reveal"))
	explore.session.monsters.groups.clear()  # 폐쇄 시험: 포탈 옆 무리와 마주쳐 전투가 열리면 디버그 패널이 닫혀 버린다(무리 자리는 판마다 무작위)
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	_expect_log(Strings.t("explore.closed"), "층 폐쇄 메시지")
	await _city_to_title()


## 새 탐험가 → 허기 0 → 시간 스킵 → 아사 → (사망 화면 없이) 타이틀
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
	var back := await _screen(TitleScreen)
	_expect(back != null and _main.find_children("*", "EndScreen", true, false).is_empty(), "사망 화면 없이 바로 타이틀로")


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
	await _action("menu_back")
	_expect(not explore.is_paused() and not explore.menu().is_open(), "탐험에서 Backspace는 아무 일도 하지 않는다")
	await _action("menu")
	await _action("pause")
	_expect(not explore.menu().is_open() and not explore.is_paused(), "Esc로 메뉴 닫기(일시정지 아님)")
	await _tab_party_checks(explore)
	await _explore_dialog_checks(explore)
	await _party_checks(explore)
	await _action("debug_toggle")
	_toggle(explore, Strings.t("debug.invulnerable"))
	DialogueBox.auto_skip = false
	_press(explore, Strings.t("debug.spawn_monster"))
	await _frames(3)
	var combat := explore.combat_screen()
	if not _expect(combat != null and s.in_combat, "몬스터 소환 → 전투 화면"):
		DialogueBox.auto_skip = true
		return
	var battle := combat.battle  # 전투 화면은 끝나면 스스로 사라진다(드롭이 없으면 바로) — 결과는 battle로 본다
	await _combat_dialog_checks(combat)
	await _stage_checks(combat)
	GameState.debug_fast_combat = true
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
	var bars := 0
	for v: Node in combat.find_children("*", "BattlerView", true, false):
		bars += v.find_children("*", "ProgressBar", true, false).size()
	_expect(bars == 0, "무대에 생명력 막대 없음(적 생명력은 보이지 않는다) — %d" % bars)
	var foe: Combatant = battle.side_units(Combatant.SIDE_ENEMY)[0]
	for ev: Dictionary in [{"hit": false}, {"hit": true, "immune": true}, {"hit": true, "lost": 0, "amount": 0}]:
		ev["type"] = "damage"
		ev["unit"] = foe
		combat._on_event(ev)
	_expect(_has_label(combat, Strings.t("combat.float_miss")) and _has_label(combat, Strings.t("combat.float_immune"))
		and _has_label(combat, Strings.t("combat.float_blocked")), "빗나감 = 회피, 면역 = 면역, 보호막에 막힘 = 막힘 — 각자 그 글자로 뜬다")
	for u in battle.side_units(Combatant.SIDE_ENEMY):  # 첫 공격(치명타·치명상)에 전투가 끝나 버리면 아래 행동창 검사를 못 한다 — 시험 동안만 버티게
		u.actor.stats.add_modifier(Modifier.new("smoke", "max:hp", float(SMOKE_FOE_HP)))
		u.actor.pool.fill_all()
	await _keyboard_menu(combat, menu)
	menu = await _open_menu(combat)
	if not _expect(menu != null, "키보드 공격 뒤 다시 행동창"):
		return
	await _plan_flow(combat, menu)
	menu = await _open_menu(combat)
	if not _expect(menu != null, "행동 정하기 뒤 다시 행동창"):
		return
	var turns_before := battle.turns
	_press(combat, Strings.t("combat.cmd_skill"))
	var skill_labels := Array(menu.grid().option_texts())
	_expect(skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "talk")) and skill_labels.has(DataNames.entry(DataRegistry.db, "skills", "investigate")),
		"스킬 메뉴에 대화·조사")
	_expect(skill_labels.has(Strings.t("combat.cmd_flee")), "도주는 스킬 목록에")
	_press(combat, DataNames.entry(DataRegistry.db, "skills", "investigate"))
	var foe_u: Combatant = null  # 고를 수 있는 적을 조사한다(대상 목록 첫 칸은 아군 — 숨은 노움처럼 못 고르는 적도 있다)
	for i in menu.grid().option_count():
		for u: Combatant in battle.side_units(Combatant.SIDE_ENEMY):
			if foe_u == null and u.label() == str(menu.grid().option(i).get("text")) and bool(menu.grid().option(i).get("enabled", true)):
				foe_u = u
				menu.grid()._set_cursor(i)
	if foe_u != null:
		menu.grid().confirm()
	else:
		_press_first(menu.grid())
	_expect_log("[조사]", "조사 결과")
	await _frames(1)
	if foe_u != null and battle.result.is_empty() and combat.stage().view(foe_u) != null:
		_expect(combat.stage().view(foe_u).find_children("*", "Label", false, false).size() == 1,
			"조사해도 무대엔 이름뿐 — 생명력·상성은 도감 B에서만")
	_expect(battle.turns > turns_before or not battle.result.is_empty(), "조사가 행동 기회를 쓴다(차례가 넘어감)")
	for i in 60:
		if not battle.result.is_empty():
			break
		if await _open_menu(combat) == null:
			break
		_press(combat, Strings.t("combat.cmd_attack"))
		_press_first(menu.grid())
	await _frames(2)
	_expect(not battle.result.is_empty(), "전투가 끝난다 (%s, 차례 %d, 적 %s)" % [battle.result, battle.turns,
		battle.side_units(Combatant.SIDE_ENEMY).map(func(u: Combatant) -> String: return "%s:%d" % [(u.actor as Monster).monster_id, int(u.actor.pool.get_current("hp"))])])
	_expect(not s.in_combat or is_equal_approx(s.clock.total_hours, tc), "전투 중에는 탐험 시간이 멈춘다")  # 이미 끝났으면 전투 차례만큼 흘렀다(아래에서 본다)
	var turns := battle.turns
	var won := battle.result == Battle.RESULT_VICTORY
	var picked := await _take_drops(combat, true)
	if picked > 0:
		_expect("\n".join(_logs).contains("주웠다") or "\n".join(_logs).contains("스며들었다"), "드롭을 주웠다(기록)")
	await _frames(3)
	_expect(explore.combat_screen() == null and not s.in_combat, "결과·보상 안내를 다 넘기면 탐험으로 복귀")
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
	await _city_to_title()


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
	for i in rd.choices():
		if not rd.is_correct(i):
			wrong = str(JsonUtil.get_array(rd.data, "choices_ko")[i])
	_press(dlg, wrong)
	await _frames(3)
	var combat := explore.combat_screen()
	if not _expect(combat != null and combat.battle.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("riddle_empowered"), "오답 → 강화된 문지기와 전투"):
		return
	var battle := combat.battle
	battle.side_units(Combatant.SIDE_ENEMY)[0].actor.pool.set_current("hp", 1.0)
	explore.session.player.pool.set_min_value("hp", 1.0)  # 강화된 문지기(3층 파티용 균열 — C18)는 1층 시험 캐릭터를 두 대에 쓰러뜨린다 — 이 시험은 수수께끼 흐름만 본다
	for i in 40:
		if not battle.result.is_empty():
			break
		var menu := await _open_menu(combat)
		if menu == null:
			break
		_press(combat, Strings.t("combat.cmd_attack"))
		_press_first(menu.grid())
	await _frames(2)
	_expect(battle.result == Battle.RESULT_VICTORY, "강화된 문지기를 쓰러뜨린다")
	explore.session.player.pool.set_min_value("hp", 0.0)
	await _take_drops(combat, false)
	await _frames(3)
	_expect(not run.remaining.has(gate) and not explore.session.realtime.is_paused(), "문이 열리고 시간이 다시 흐른다")
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	await _city_to_title()


## Tab 메뉴(소지품·캐릭터·도감 한 화면) · 키로 장착·벗기·옮기기·단축칸·버리기 · 쪽 넘기기
func _inventory_flow() -> void:
	var explore := await _enter_dungeon("소지품 탐험가")
	if explore == null:
		return
	var s := explore.session
	var pc := s.player
	await _action("menu")
	var menu := explore.menu()
	if not _expect(menu.is_open() and menu.inventory() != null and menu.character() != null, "Tab으로 아군·캐릭터·소지품이 한 화면에"):
		return
	await _frames(2)
	_expect(menu.active_page() == "inventory", "처음 커서는 소지품 쪽")
	_expect(s.realtime.is_paused("window"), "메뉴가 열리면 시간이 멈춘다")
	var t0 := s.clock.total_hours
	await _seconds(0.3)
	_expect(is_equal_approx(s.clock.total_hours, t0), "메뉴가 열린 동안 시계가 그대로")
	var inv := menu.inventory()
	pc.inventory.add("steel_greatsword")
	inv.refresh()
	inv.cursor_to_cell(Vector2i(pc.inventory.stacks()[pc.inventory.stacks().size() - 1]["pos"]))
	await _action("menu_confirm")
	_expect(_has_node_named(menu, "ChoicePopup") and inv.busy(), "Enter → 할 일 고르기 창")
	await _action("menu_confirm")  # 첫 칸 = 장착한다
	_expect(pc.equipment.item_in("main_hand") == "steel_greatsword" and pc.inventory.count("iron_mace") == 1, "Enter·Enter로 대검 장착, 철퇴는 가방으로")
	_expect(pc.equipment.is_empty("off_hand"), "양손 무기면 방패가 빠진다")
	await _frames(1)
	inv.cursor_to_slot("feet")
	await _action("menu_confirm")
	await _action("menu_confirm")  # 벗는다
	_expect(pc.equipment.is_empty("feet") and pc.inventory.count("leather_boots") == 1, "장화 칸 Enter·Enter → 가방으로 벗기")
	await _frames(1)
	var boots := -1
	for i in pc.inventory.stacks().size():
		if pc.inventory.stacks()[i]["id"] == "leather_boots":
			boots = i
	inv.cursor_to_cell(Vector2i(pc.inventory.stacks()[boots]["pos"]))
	await _action("menu_confirm")
	await _action("menu_down")  # 장착한다 → 옮긴다
	await _action("menu_confirm")
	_expect(inv.carrying(), "옮긴다 → 놓을 자리 고르기")
	var spot := pc.inventory.free_spot("leather_boots")
	inv.cursor_to_cell(spot)
	await _action("menu_confirm")
	_expect(not inv.carrying() and Vector2i(pc.inventory.stacks()[pc.inventory.stack_at(spot)]["pos"]) == spot \
		and pc.inventory.stacks()[pc.inventory.stack_at(spot)]["id"] == "leather_boots", "Enter로 그 자리에 놓았다")
	pc.inventory.add("medium_potion")
	pc.pool.modify("hp", -30.0)
	inv.refresh()
	var potions := pc.inventory.count("medium_potion")
	for i in pc.inventory.stacks().size():
		if pc.inventory.stacks()[i]["id"] == "medium_potion":
			inv.cursor_to_cell(Vector2i(pc.inventory.stacks()[i]["pos"]))
	await _action("menu_confirm")
	await _action("menu_confirm")  # 사용한다
	_expect(pc.inventory.count("medium_potion") == potions - 1, "메뉴에서 포션을 마셨다")
	pc.inventory.add("ration")
	var rations := pc.inventory.count("ration")
	for i in pc.inventory.stacks().size():
		if pc.inventory.stacks()[i]["id"] == "ration":
			_expect(inv.discard(i) and pc.inventory.count("ration") < rations, "버린다")
			break
	inv.cursor_to_cell(Vector2i(0, pc.inventory.height - 1))
	await _action("menu_left")
	_expect(menu.active_page() == "character", "가방 왼쪽 끝에서 A → 캐릭터 쪽")
	pc.set_level(3)  # 정수 순서 바꾸기(UI34): W/S로 카드 · Enter 집기 · S 옮기기 · Enter 확정 · Esc 되돌리기
	for e: Array in [["goblin", "red"], ["gnome", "blue"]]:
		pc.essences.absorb(pc, {"essence": e[0], "color": e[1], "stats": {}})
	menu.character().refresh()
	await _frames(1)
	await _action("menu_confirm")
	_expect(str(pc.essences.absorbed[0]["essence"]) == "goblin", "맨 위 요약에서 Enter는 아무것도 집지 않는다(UI39)")
	await _action("menu_down")  # 요약 → 첫 카드
	await _action("menu_confirm")
	await _action("menu_down")
	await _action("menu_confirm")
	_expect(str(pc.essences.absorbed[0]["essence"]) == "gnome" and str(pc.essences.absorbed[1]["essence"]) == "goblin", "S·Enter·S·Enter → 첫 정수를 아래로")
	await _action("menu_confirm")
	await _action("menu_up")
	await _action("menu_back")
	_expect(str(pc.essences.absorbed[0]["essence"]) == "goblin" and menu.is_open(), "메뉴에서 Backspace는 아무 일도 하지 않는다")
	await _action("pause")
	_expect(str(pc.essences.absorbed[1]["essence"]) == "goblin" and menu.is_open(), "집어 옮기다 Esc → 원래 자리(메뉴는 그대로)")
	var gi := pc.skills.find(EssenceSet.granted_skills(DataRegistry.db, pc.essences.absorbed[0])[0])
	var bi := pc.skills.find(EssenceSet.granted_skills(DataRegistry.db, pc.essences.absorbed[1])[0])
	_expect(gi >= 0 and bi > gi, "전투 스킬 순서도 정수 순서")
	await _action("menu_right")
	_expect(menu.active_page() == "inventory", "D → 다시 소지품 쪽")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = menu.inventory().get_global_rect().get_center()
	click.global_position = click.position
	get_viewport().push_input(click, true)
	await _frames(1)
	_expect(menu.is_open() and menu.active_page() == "inventory", "마우스 클릭은 아무 일도 하지 않는다")
	await _action("menu")
	_expect(not menu.is_open() and not s.realtime.is_paused("window"), "Tab으로 닫기 → 시간 다시 흐름")
	await _codex_checks(explore)
	_expect(not explore.is_paused(), "메뉴를 닫은 키는 일시정지가 아니다")
	await _action("menu")
	await _action("pause")
	_expect(not menu.is_open() and not explore.is_paused(), "Esc로도 메뉴 닫기(일시정지 아님)")
	_expect(not InputMap.has_action("hotbar_1") and not InputMap.has_action("torch") and not InputMap.has_action("eat"), "단축칸·횃불·식사 키가 없다")
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	await _city_to_title()


## 행동창 키 조작: S → 스킬 칸, Enter → 스킬 목록, Backspace → 맨 위(커서는 스킬 칸), W → 공격, Enter·Enter → 첫 적을 친다.
func _keyboard_menu(combat: CombatScreen, menu: CommandMenu) -> void:
	var g := menu.grid()
	_expect(g.cursor() == CommandMenu.ROOT_ATTACK, "처음 커서는 공격")
	await _action("menu_down")
	_expect(g.cursor() == CommandMenu.ROOT_SKILL, "S → 스킬 (%d)" % g.cursor())
	await _action("menu_confirm")
	_expect(Array(menu.grid().option_texts()).has(DataNames.entry(DataRegistry.db, "skills", "talk")), "Enter → 스킬 목록")
	await _action("pause")
	_expect(menu.grid() != g, "행동창에서 Esc는 뒤로 가지 않는다(뒤로 = Backspace)")
	await _action("menu_back")
	_expect(menu.grid() == g and g.cursor() == CommandMenu.ROOT_SKILL, "Backspace → 명령 칸, 커서는 스킬")
	await _action("menu_down")
	_expect(g.cursor() == CommandMenu.ROOT_GUARD, "S → 방어 (%d)" % g.cursor())
	await _action("menu_up")
	await _action("menu_up")
	_expect(g.cursor() == CommandMenu.ROOT_ATTACK, "W·W → 공격")
	await _single_item_target(combat, menu, g)
	var turns := combat.battle.turns
	await _action("menu_confirm")
	_expect(menu.grid().title_text() == Strings.t("combat.menu_target"), "Enter → 대상 고르기")
	await _action("menu_confirm")
	await _frames(2)
	_expect(combat.battle.turns > turns or not combat.battle.result.is_empty(), "Enter로 고른 공격이 차례를 쓴다")


## 하나만 치는 균열 전투 도구(RF27): 아이템 → 적 고르기(듣지 않는 계열은 흐림) → Backspace로 아이템 목록 → 명령 칸.
func _single_item_target(combat: CombatScreen, menu: CommandMenu, g: ChoiceGrid) -> void:
	var me := combat.battle.current
	me.actor.inventory.add("mine_powder_pouch", 1)
	menu._item_pick("mine_powder_pouch", 0)
	var t := menu.grid()
	var foes := combat.battle.opponents(me)
	var e := BattleRules.single_smite(DataRegistry.db, "mine_powder_pouch")
	var ok := t.title_text() == Strings.t("combat.menu_target") and t.option_count() == foes.size()
	for i in mini(t.option_count(), foes.size()):
		ok = ok and (bool(t.option(i).get("enabled", true)) == (BattleRules.smite_fits(e, foes[i]) and BattleRules.is_targetable(combat.battle, me, foes[i])))
	_expect(ok, "화약 주머니 → 적 하나 고르기(듣지 않는 적은 흐림)")
	await _action("menu_back")
	_expect(menu.grid().title_text() == Strings.t("combat.menu_item"), "Backspace → 아이템 목록")
	await _action("menu_back")
	_expect(menu.grid() == g and g.cursor() == CommandMenu.ROOT_ITEM, "Backspace → 명령 칸(아이템)")
	me.actor.inventory.remove("mine_powder_pouch")
	for i in 3:
		await _action("menu_up")


## 행동 정하기(피어 앤 헝거식): 동료가 있으면 차례가 온 사람 + 아직 안 정한 동료의 행동을 먼저 다 고르고 나서 움직인다.
## 뒤로(Backspace)는 앞사람 행동을 다시 고른다. 시험 뒤 동료는 전투에서 빠진다(쓰러진 것으로).
func _plan_flow(combat: CombatScreen, menu: CommandMenu) -> void:
	var b := combat.battle
	var mate := PlayerCharacter.create(DataRegistry.db, "human", "warrior", "동료", {"str": 9, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
	var mu := b.add(mate, Combatant.SIDE_PARTY)
	combat._add_unit(mu)
	menu.close()
	combat._begin_planning(b.current)
	var turns := b.turns
	_press(combat, Strings.t("combat.cmd_guard"))
	_expect(b.turns == turns and menu.is_open() and combat._planning.size() == 2 and combat._plan_i == 1, "한 사람을 정하면 다음 사람 차례(아직 움직이지 않음)")
	_expect(_has_label(combat, Strings.t("combat.cmd_guard")), "파티 창에 정해 둔 행동")
	await _action("menu_back")
	_expect(combat._plan_i == 0 and combat._plan.is_empty(), "뒤로 → 앞사람 다시 고르기")
	b.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.apply("stun", 2.0)  # 탐험가 다음 차례를 건너뛰어 동료 차례가 오게
	_press(combat, Strings.t("combat.cmd_guard"))
	_press(combat, Strings.t("combat.cmd_guard"))
	await _frames(2)
	_expect(b.turns > turns or not b.result.is_empty(), "모두 정하면 차례대로 움직인다")
	var dl := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < dl and b.current != mu and b.result.is_empty():
		await get_tree().process_frame
	_expect(b.current == mu or not b.result.is_empty(), "탐험가가 기절해 동료 차례")
	mate.pool.set_current("hp", 0.0)  # 동료가 자기 차례(행동 정하기 중)에 쓰러진다 — 전투가 멈추지 않고 다음 차례로 가야 한다
	combat._refresh()
	await _frames(2)


## 전투가 끝나고 무대에 남은 드롭(정수·전리품)의 작은 창을 모두 넘긴다 — Enter = 획득한다.
## keys면 첫 창에서 S(두고 간다로)·W(다시 획득한다로)를 눌러 커서를 본다. "계속" 버튼이 나오면 끝. 고른 수.
func _take_drops(combat: Variant, keys: bool) -> int:  # Variant: 드롭이 없으면 넘기기 전에 이미 사라졌을 수 있다
	var n := 0
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline:
		await _frames(2)
		if not is_instance_valid(combat) or not (combat as Node).is_inside_tree() or (combat as Node).is_queued_for_deletion():
			break
		var pops := (combat as Node).find_children("*", "ChoicePopup", true, false)
		if pops.is_empty():
			continue
		var pop := pops[0] as ChoicePopup
		if keys and n == 0:
			await _action("menu_down")
			_expect(pop.grid.cursor() == 1, "드롭 창: S → 두고 간다")
			await _action("menu_up")
			_expect(pop.grid.cursor() == 0, "드롭 창: W → 획득한다")
		await _action("menu_confirm")
		n += 1
	_expect(not is_instance_valid(combat) or not (combat as Node).is_inside_tree() or (combat as Node).is_queued_for_deletion(), "드롭을 다 고르면(안내를 넘기면) 전투가 끝난다")
	return n


## 탐험 알림 → 하단 대화창: 떠 있는 동안 시간이 멈추고, Enter로 넘기면 닫힌다.
func _explore_dialog_checks(explore: ExploreScreen) -> void:
	var s := explore.session
	var dlg := explore.dialog()
	DialogueBox.auto_skip = false
	EventBus.log_message.emit(Strings.t("city.leave"), "info")
	await _frames(2)
	_expect(dlg.busy() and dlg.is_visible_in_tree() and s.realtime.is_paused("dialog"), "알림 → 하단 대화창(시간 정지)")
	var tq := s.clock.total_hours
	await _seconds(0.3)
	_expect(is_equal_approx(s.clock.total_hours, tq), "대화창이 떠 있는 동안 시간이 멈춘다")
	for i in 3:
		if dlg.busy():
			await _action("menu_confirm")
	await _frames(2)
	_expect(not dlg.busy() and not dlg.visible and not s.realtime.is_paused(), "Enter로 넘기면 닫히고 시간이 다시 흐른다")
	s.message.emit("effect.light_on", {"hours": 4}, "good")
	s.message.emit("explore.portal_here", {}, "system")
	await _frames(1)
	_expect(not dlg.busy(), "횃불 켜기·포탈 위에 섬 = 보이지 않는다")
	for key: String in ["explore.status_on", "explore.safe_enter", "explore.dark_enter", "explore.light_out", "inventory.discarded"]:
		s.message.emit(key, {"status": "x", "item": "x", "count": 1}, "info")
	await _frames(1)
	_expect(not dlg.busy() and not s.realtime.is_paused(), "상태·안전지대·어둠·횃불 꺼짐·버리기 = 화면으로 보이니 글이 없다")
	_expect(explore.find_children("*", "NoticeToast", true, false).is_empty(), "위 알림 띠가 없다")
	await _action("wait")
	await _frames(2)
	_expect(not dlg.busy() and explore.shade_alpha() > 0.0, "대기 = 글 대신 화면이 잠깐 어두워진다")
	s.message.emit("field.got", {"item": "x"}, "good")
	await _frames(1)
	_expect(dlg.busy(), "아이템 획득 = 대화창(Enter)")
	dlg.clear()
	DialogueBox.auto_skip = true


## 다른 탐험가 무리(FieldParties): 닿으면 선택 창 — 고르는 동안 시간이 멈추고, Esc = 지나가기.
func _party_checks(explore: ExploreScreen) -> void:
	var s := explore.session
	var g := s.parties._spawn(s, FieldParties.ROOKIE, FieldRoutes.random_cell_near(s.map, s.rng, s.pos, 6))  # 1층엔 돌아다니는 신참 무리가 없어 하나 세운다(사용자 2026-10-26)
	_expect(g != null, "탐험가 무리를 세울 수 있다")
	if g == null:
		return
	s.party_met.emit(g)
	await _frames(2)
	_expect(explore.has_node("PartyChoice") and s.realtime.is_paused("party"), "탐험가 무리 선택 창(시간 정지)")
	await _action("pause")
	await _frames(2)
	_expect(not explore.has_node("PartyChoice") and not s.realtime.is_paused("party") and g.grace_until > s.clock.total_hours,
		"Esc = 지나간다(잠시 다시 말을 걸지 않는다)")


## 전투 안내 → 아래 창 왼쪽 대화창: 떠 있는 동안 행동창이 열리지 않고, Enter로 넘기면 행동창이 열린다.
func _combat_dialog_checks(combat: CombatScreen) -> void:
	var dlg := combat.dialog()
	_expect(dlg.busy() and dlg.is_visible_in_tree() and not _menu_open(combat), "전투 시작 안내가 대화창에(행동창은 아직)")
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline and is_instance_valid(combat) and not _menu_open(combat) and combat.battle.result.is_empty():
		if dlg.busy():
			await _action("menu_confirm")
		await _frames(2)
	_expect(_menu_open(combat) and not dlg.busy(), "안내를 다 넘기면 행동창")
	DialogueBox.auto_skip = true
	dlg.instant = true


## 스킬 이름 = 위쪽 작은 알림창(대화창이 아니다), 적 자리 = 고정(쓰러져도 남은 적이 가운데로 모이지 않는다), 적 발은 아군 머리 조금 아래까지(UI41).
func _stage_checks(combat: CombatScreen) -> void:
	var b := combat.battle
	b.message.emit("combat.use_skill", {"name": "x", "skill": "시험 스킬"}, "system")
	await _frames(1)
	_expect(combat.banner().text() == "시험 스킬" and not combat.dialog().busy(), "스킬 이름은 위 알림창에(대화창 아님)")
	var foe0: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	BattleRules.summon(b, foe0, {"monster": "goblin"})
	BattleRules.summon(b, foe0, {"monster": "goblin"})
	await _frames(3)
	var st := combat.stage()
	var foes := b.side_units(Combatant.SIDE_ENEMY)
	var before := {}
	for u in foes:
		before[u] = st.view(u).position
	var ally_top := INF
	for u: Combatant in b.side_units(Combatant.SIDE_PARTY):
		ally_top = minf(ally_top, st.view(u).position.y)
	var feet: Array = foes.map(func(u: Combatant) -> float: return st.view(u).position.y + st.view(u).size.y)
	var reach := (st.size.y - st._bottom()) * UiTheme.ui_float("combat_enemy_overlap", 0.24)  # 적 발은 아군 머리보다 이만큼 아래까지(UI41 — 아군 바로 앞에 선 듯)
	_expect(feet.all(func(y: float) -> bool: return y <= ally_top + reach + 0.5), "적 발은 아군 머리 조금 아래까지 (발 %s · 머리 %.0f · 무대 %s)" % [feet, ally_top, st.size])
	var gone: Combatant = foes[0]
	st.remove_unit(gone)
	await _frames(2)
	_expect(foes.slice(1).all(func(u: Combatant) -> bool: return st.view(u).position.is_equal_approx(before[u])), "적이 빠져도 남은 적 자리는 그대로")
	st.add_unit(gone)  # 무대만 되돌린다(전투 규칙은 그대로)
	await _frames(2)


func _menu_open(combat: CombatScreen) -> bool:
	for n: Node in combat.find_children("*", "CommandMenu", true, false):
		if (n as CommandMenu).is_open():
			return true
	return false


## 아군 차례가 와서 행동창이 열릴 때까지 기다린다. 전투가 끝나면 null.
func _open_menu(combat: CombatScreen) -> CommandMenu:
	var deadline := Time.get_ticks_msec() + WAIT_LIMIT_MS
	while Time.get_ticks_msec() < deadline and is_instance_valid(combat) and combat.battle.result.is_empty():
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


## 살아서 귀환 → 차원광장 정산(대화창은 auto_skip이라 바로 넘어간다 — 결과 창 없음) → 도시 → 타이틀.
func _city_to_title() -> void:
	var city := (await _screen(CityScreen)) as CityScreen
	if _expect(city != null, "귀환 후 도시"):
		await _city_title(city)


## 도시 거리에서 Esc → 정지 창 → 타이틀로(W/S·Enter).
func _city_title(city: CityScreen) -> void:
	await _action("pause")
	_expect(_has_button(city, Strings.t("city.btn_title")), "거리에서 Esc → 정지 창")
	await _action("menu_down")
	await _action("menu_confirm")


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
	if explore != null:  # 시작 자리는 무작위 — 바로 옆 무리와 저절로 붙어 흐름이 어긋나지 않게 가까운 무리를 치운다
		var s := explore.session
		for g: FieldMonsters.Group in s.monsters.groups.duplicate():
			if Vector2(g.pos).distance_to(Vector2(s.pos)) < 40.0:
				s.monsters.remove(g, s.clock.total_hours)
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


## 실내 방(CT64): 그 활동 자리 바로 앞에 서서 위를 보고 Enter — 자리에 칸이 여럿이면 선택 창에서 S로 그 칸까지 내려가 Enter. 창구면 패널이 열린다.
func _room_do(room: RoomView, act_id: String, tab: String = "") -> void:
	var spot := {}
	for sp: Dictionary in room.room().spots:
		if room.entries(sp).has([act_id, tab]):
			spot = sp
			break
	if not _expect(not spot.is_empty(), "방에 %s 자리" % act_id):
		return
	var rc: Rect2i = spot["rect"]
	room.pos = Vector2(rc.position.x + rc.size.x * 0.5, rc.end.y + 0.5)
	room.facing = Vector2i.UP
	await _frames(2)
	var opts := room.entries(spot)
	await _action("interact")
	await _frames(2)
	if opts.size() > 1:
		for _k in opts.find([act_id, tab]):
			await _action("menu_down")
		await _action("menu_confirm")
		await _frames(2)


## 액션 키를 sec초 동안 누르고 있다가 뗀다(실내 방 걷기).
func _hold(action: String, sec: float) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(sec).timeout
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await _frames(1)


## 도서관 실내 방(탑뷰 — CT62): W/A/S/D로 걷고, 책장을 바라보고 Enter = 읽기(분야마다 한 방문에 한 번), 문을 밟으면 거리로(행동력은 들어갈 때 1 — CT72).
func _library_flow() -> void:
	_main.call("_show_title")
	var city := await _new_city("도서관")
	if city == null:
		return
	var st := city.state
	st.happenings.clear()
	city.choose_facility("library")
	await _frames(2)
	var room := city.facility_view() as RoomView
	if not _expect(room != null and st.ap == 2, "도서관 = 걸어 다니는 실내 방(들어가며 행동력 1 — CT72)"):
		return
	await _action("menu")  # 건물 안에서도 Tab 메뉴(CT74) — 열려 있는 동안 걷지 않는다
	await _frames(2)
	_expect(city.menu().is_open() and room.paused, "건물 안에서 Tab = 메뉴(걷기 멈춤)")
	await _action("menu")
	await _frames(2)
	_expect(not city.menu().is_open() and not room.paused and city.facility_view() == room, "Tab을 다시 누르면 닫히고 방에 그대로")
	var start := room.pos
	await _hold("move_up", 0.4)
	_expect(room.pos.y < start.y - 0.5 and room.facing == Vector2i.UP, "W를 누르고 있으면 위로 걷는다")
	var shelf := {}
	for sp: Dictionary in room.room().spots:
		if (sp["acts"] as Array).has("library_dungeon"):
			shelf = sp
	var rc: Rect2i = shelf["rect"]
	room.pos = Vector2(rc.position.x + rc.size.x * 0.5, rc.end.y + 0.5)
	room.facing = Vector2i.UP
	await _frames(2)
	_expect(room.entries(room.focus()) == [["library_dungeon", ""]], "책장을 바라보면 그 분야 이름판")
	var known := st.known_info.size()
	await _action("interact")
	await _frames(3)
	_expect(st.known_info.size() > known and city.facility_view() == room, "Enter = 그 책장 읽기, 읽고 나도 방에 남는다")
	_expect(room.reason("library_dungeon") == "city.reason_read_this_visit" and room.reason("library_arms") != "city.reason_read_this_visit", "같은 분야는 한 방문에 한 번, 다른 분야는 이어서")
	room.pos = room.room().start
	await _hold("move_down", 0.5)
	await _frames(2)
	_expect(city.facility_view() == null and st.ap == 2, "문을 밟으면 거리로 — 행동력은 들어갈 때 1(나올 때는 그대로)")
	city.choose_facility("smithy")  # 사다리(CT66): 좌우는 막고 위로 오른다 — 다락은 같은 지도
	await _frames(2)
	var smithy := city.facility_view() as RoomView
	if not _expect(smithy != null, "대장간 실내"):
		return
	var foot := Vector2i(-1, -1)
	for y in smithy.room().height:
		for x in smithy.room().width:
			if smithy.room().kind_at(Vector2i(x, y)) == "ladder" and y > foot.y:
				foot = Vector2i(x, y)
	smithy.pos = Vector2(foot) + Vector2(0.5, 0.5)
	await _frames(1)
	var x0 := smithy.pos.x
	await _hold("move_left", 0.25)
	_expect(is_equal_approx(smithy.pos.x, x0) and smithy.room().kind_at(Kinematics.cell_of(smithy.pos)) == "ladder", "사다리 위에서는 좌우로 못 간다")
	var y0 := smithy.pos.y
	await _hold("move_up", 0.8)
	_expect(smithy.pos.y < y0 - 1.0 and smithy.facing == Vector2i.UP, "사다리를 오른다(뒷모습)")
	smithy.try_leave()
	await _frames(2)


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
	await _frames(1)
	var first := street.focused_id()
	await _action("move_right")
	_expect(street.focused_id() != first and street.focused_id() == st.facility_ids()[1], "D 한 번 = 옆 건물")
	await _seconds(UiTheme.render_float("city.step_sec", 0.25) + 0.15)
	var rr := street.building_rect(street.focused_id())
	_expect(not street.is_stepping() and absf(rr.get_center().x - street.size.x / 2.0) < 2.0, "넘어간 건물이 화면 가운데에 온다")
	await _action("move_left")
	await _seconds(UiTheme.render_float("city.step_sec", 0.25) + 0.15)
	_expect(street.focused_id() == first, "A 한 번 = 다시 왼쪽 건물")
	_expect(street.building_rect("exchange") == Rect2() and not DataRegistry.db.has_entry("facilities", "exchange"), "거래소는 없다(CT64)")
	var ids := st.facility_ids()
	for _i in ids.size() - 1 - ids.find(street.focused_id()):  # 끝 건물까지
		await _action("move_right")
		await _seconds(UiTheme.render_float("city.step_sec", 0.25) + 0.1)
	_expect(street.focused_id() == ids[-1], "D를 계속 누르면 오른쪽 끝 건물")
	await _action("move_right")
	await _frames(2)
	_expect(city.find_children("*", "ChoicePopup", true, false).is_empty(), "특별 시설이 없으면 끝에서 D를 더 눌러도 창이 없다")
	street.scroll_to(0.0)
	await _frames(1)
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
	_expect(city.facility_view() == null and st.ap == 3, "건물을 클릭해도 들어가지 않는다(키보드만)")
	street.scroll_to(r.get_center().x - street.size.x / 2.0)
	await _frames(1)
	_expect(street.focused_id() == "inn", "여관을 화면 가운데로")
	await _action("menu_confirm")
	var fv := city.facility_view()
	if not _expect(fv is RoomView and fv.facility_id() == "inn" and st.ap == 2, "Enter → 여관 실내 방으로(들어가며 행동력 1 — CT72)"):
		return
	await _action("menu")
	_expect(city.menu().is_open(), "시설 안에서도 Tab 메뉴(CT74)")
	await _action("menu")
	_expect(not city.menu().is_open(), "Tab으로 닫는다")
	pc.pool.modify("hp", -30.0)
	pc.fatigue.set_value(60.0)
	await _room_do(fv as RoomView, "inn_rest")  # 계단 앞에서 Enter
	_expect(city.facility_view() == fv, "활동 뒤에도 방에 남는다")
	fv.try_leave()
	await _frames(2)
	_expect(city.facility_view() == null and street.is_visible_in_tree(), "Esc → 거리로")
	_expect(is_equal_approx(pc.fatigue.value, 20.0), "휴식(−40) → 피로도 60 → 20")
	_expect(is_equal_approx(pc.pool.get_current("hp"), pc.pool.get_max("hp")), "여관 휴식 → 생명력 회복")
	pc.pool.modify("hp", -30.0)
	pc.inventory.add("minor_potion", 1)
	var hp_before := pc.pool.get_current("hp")
	var potions := pc.inventory.count("minor_potion")
	DialogueBox.auto_skip = false
	city.use_item("minor_potion")
	_expect(pc.pool.get_current("hp") > hp_before and pc.inventory.count("minor_potion") == potions - 1, "거리에서 포션을 마셨다")
	_expect(not city.dialog().busy(), "거리에서 포션을 마셔도 글이 뜨지 않는다(막대로 보인다)")
	pc.inventory.add("ration", 1)
	city.use_item("ration")
	_expect(pc.inventory.has("ration") and city.dialog().busy(), "식량은 도시에서 쓰지 않는다(이유는 아래 대화창)")
	city.dialog().clear()
	var box := city.dialog()  # 긴 글: 창 폭으로 미리 접어 쪽마다 들어가는 줄까지만, 넘겨 보면 글이 빠짐없이 나온다(UI36)
	var long_text := "가나다라마바사 아자차카타파하 ".repeat(40).strip_edges()
	box.say("짧은 머리말")
	box.say(long_text)
	var seen := ""
	var pages_ok := true
	for _i in 30:
		if not box.busy():
			break
		pages_ok = pages_ok and box.page_text().split("\n").size() <= box._per_page()
		seen += box.page_text()
		box.advance()
		box.advance()
	_expect(pages_ok and seen.replace("\n", "").replace(" ", "") == ("짧은 머리말" + long_text).replace(" ", ""), "긴 글은 쪽마다 들어가는 줄까지만, 넘기면 빠짐없이")
	box.say("첫째 문장이다. 둘째 문장이다!")  # 한 쪽 = 한 문장(UI44)
	var first_page := box.page_text()
	box.advance()
	box.advance()
	_expect(first_page == "첫째 문장이다." and box.page_text() == "둘째 문장이다!", "대화창은 한 번에 한 문장")
	box.clear()
	DialogueBox.auto_skip = true
	await _action("debug_toggle")
	_expect(city.is_debug_open(), "F1로 도시 디버그 패널")
	city.debug_panel().set_edit("activities/inn_rest/effects/1/amount", "3")
	_press(city.debug_panel(), Strings.t("city.debug_apply_overrides"))
	pc.fatigue.set_value(10.0)
	await _action("debug_toggle")
	street.scroll_to(0.0)
	await _frames(1)
	street.scroll_to(street.building_rect("inn").get_center().x - street.size.x / 2.0)  # 맨 왼쪽은 길드 — 여관으로
	await _frames(1)
	await _action("menu_confirm")
	fv = city.facility_view()
	if not _expect(fv != null and fv.facility_id() == street.focused_id() and st.ap == 1, "Enter로 가운데 건물에 들어간다(여관에 한 번 들어갔다 와서 또 들어가니 행동력 1)"):
		return
	if fv.facility_id() == "inn":
		await _room_do(fv as RoomView, "inn_rest")
		_expect(is_equal_approx(pc.fatigue.value, 7.0), "임시값(3) 휴식 → 피로도 10 → 7")
	fv.try_leave()
	await _frames(2)
	_expect(city.facility_view() == null, "거리로 나왔다")
	city.choose_facility("shop")
	fv = city.facility_view()
	if not _expect(fv != null and st.ap == 0, "상점(마지막 행동력 — 들어가며 썼다, CT72)"):
		return
	await _room_do(fv as RoomView, "shop_trade", "buy")  # 계산대 앞 Enter → [구매] → 구매 목록
	var money := pc.inventory.money
	await _frames(1)
	await _action("menu_confirm")  # 구매 목록 첫 칸 = 첫 판매 물건
	_expect(pc.inventory.money < money, "상점에서 [구매] → Enter로 샀다")
	var shop_items := CityShop.stock(st, "shop_trade")
	_expect(not shop_items.any(func(i: String) -> bool: return CityShop.is_equipment(st, i)), "상점은 장비를 팔지 않는다(대장간)")
	var shop_panel := fv.find_children("*", "ShopPanel", true, false)
	await _action("menu_back")
	_expect(city.facility_view() == fv and (shop_panel[0] as ShopPanel).mode == "buy", "도시에서는 Backspace가 아무 일도 하지 않는다")
	(shop_panel[0] as ShopPanel).back.call()  # 목록 맨 끝 돌아가기 → 창구를 닫고 방으로
	await _frames(1)
	_expect(fv.find_children("*", "ShopPanel", true, false).is_empty() and city.facility_view() == fv, "돌아가기 → 창구를 닫고 방으로")
	await _room_do(fv as RoomView, "shop_trade", "sell")  # 계산대 앞 Enter → 선택 창에서 S → [판매]
	shop_panel = fv.find_children("*", "ShopPanel", true, false)
	_expect(shop_panel.size() == 1 and (shop_panel[0] as ShopPanel).mode == "sell", "W/S로 [판매]를 고른다")
	await _action("pause")
	await _frames(1)
	_expect(city.facility_view() == fv and fv.find_children("*", "ShopPanel", true, false).is_empty(), "창구에서 Esc → 창구만 닫는다")
	await _action("pause")
	await _frames(2)
	_expect(city.facility_view() == null, "한 번 더 Esc → 거리로")
	_expect(st.period == 1 and st.ap == 3, "행동력을 다 써서 중순(행동력 3 — 달력 카드로 보인다)")
	city.choose_facility("bank")
	fv = city.facility_view()
	if _expect(fv != null, "은행"):
		await _room_do(fv as RoomView, "bank_account")
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
		_press(fv, Strings.t("city.leave"))  # 창구 선택판 맨 끝 나가기 → 창구만 닫는다
		await _frames(1)
		fv.try_leave()
	await _frames(2)
	var cash := pc.inventory.money
	pc.inventory.money = 0
	st.happenings.clear()  # 오늘의 거리 사건이 있으면 할 게 남는다
	DialogueBox.auto_skip = false
	city.choose_facility("inn")
	await _frames(2)
	var poor := city.facility_view() as RoomView
	if _expect(poor != null, "돈이 없어도 방에는 들어간다"):
		_expect(poor.reason("inn_snack") == "city.reason_no_money", "돈이 없으면 주인 이름판에 이유")
		poor.try_leave()
		await _frames(2)
	city.dialog().clear()
	DialogueBox.auto_skip = true
	pc.inventory.money = cash
	var fatigue := pc.fatigue.value
	var month := st.month
	st.period = st.periods().size() - 1  # 하순으로 건너뛰고 마지막 행동력으로 시설 하나
	st.ap = 1
	city.choose_facility("inn")
	fv = city.facility_view()
	if _expect(fv != null and st.ap == 0, "하순 마지막 행동력으로 여관(들어가며 썼다)"):
		await _room_do(fv as RoomView, "inn_rest")
		_expect(st.ap == 0 and city.facility_view() == fv, "시설 안 활동은 행동력을 쓰지 않는다(0이어도 안에서 이어서)")
		fatigue = pc.fatigue.value  # 휴식(임시값)으로 줄어든 값이 미궁으로 이어진다(나오면 하순이 끝난다)
		fv.try_leave()
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
	var bag := explore.session.player.inventory
	bag.add("magic_stone_9", 3)
	bag.add("magic_stone_8", 1)
	var stone_value := 0
	for lot: Dictionary in GuildSettle.lots(DataRegistry.db, bag):
		stone_value += int(lot["count"]) * int(lot["each"])
	var money_before := bag.money
	await _action("debug_toggle")
	_press(explore, Strings.t("debug.close_soon"))
	_press(explore, Strings.t("debug.skip", {"hours": _bal("debug.skip_hours_short")}))
	var back := (await _screen(CityScreen)) as CityScreen
	_expect(stone_value > 0 and GuildSettle.lots(DataRegistry.db, bag).is_empty() and bag.money == money_before + stone_value,
		"강제 귀환 → 차원광장에서 길드 직원이 마석을 스톤으로 정산한다(결과 창 없음, CT58)")
	if _expect(back != null, "귀환 → 도시"):
		_expect([back.state.month, back.state.period, back.state.ap] == [month + 1, 0, 3], "귀환하면 다음 달 상순(행동력 3)")
		_expect(back.pc.fatigue.value > fatigue, "미궁에서 쌓인 피로도가 도시로 이어진다")
		await _city_title(back)
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


## 세금(CityTax): 기한 달 하순에 안 내고 마지막 행동력을 쓰면 처형 장면 → 타이틀(저장 삭제).
func _tax_flow() -> void:
	_main.call("_show_title")
	var city := await _new_city("세금")
	if city == null:
		return
	var st := city.state
	st.month = CityTax.due_month(st)
	st.period = st.periods().size() - 1
	st.ap = 1
	_expect(CityTax.owed(st, city.pc.race_id), "올해 세금이 남았다")
	city.choose_facility("inn")
	city.facility_view().try_leave()
	var title := (await _screen(TitleScreen)) as TitleScreen
	_expect(title != null and not GameState.has_save(), "세금을 못 내고 기한을 넘기면 처형 → 타이틀(기록 삭제)")


## 거리 사건(CityAmbient): 장면은 대화창, 선택지는 작은 창(Enter), 닫힌 시설은 못 들어간다, 행동력은 그대로.
func _street_flow() -> void:
	_main.call("_show_title")
	var city := await _new_city("거리")
	if city == null:
		return
	var st := city.state
	var pc := city.pc
	var ap := st.ap
	DialogueBox.auto_skip = false
	st.month = CityTax.due_month(st) + 1
	st.period = 0
	st.ambient_pending = true
	CityAmbient.enabled = true
	city.street_event()
	await _frames(1)
	_expect(city.dialog().page_text().contains(Strings.t("city.street.hanging.intro.1").left(8)), "세금 기한 다음 달 상순 = 교수형 장면")
	_expect(city.event_view() != null and city.event_view().has_picture(), "거리 사건 = 일러스트가 도시를 덮는다(CT45)")
	city.choose_facility(st.facility_ids()[0])
	await _action("menu")
	await _frames(1)
	_expect(city.facility_view() == null and not city.menu().is_open(), "사건 중엔 시설·Tab 메뉴를 쓸 수 없다")
	city.dialog().clear()
	await _frames(1)
	_expect(city.event_view() == null, "다 넘기면 일러스트가 사라진다")
	DialogueBox.auto_skip = true
	var money := pc.inventory.money
	city.street_event("beggar")
	await _frames(2)
	_expect(city.has_node("StreetChoice"), "선택지가 있는 사건은 작은 창")
	await _action("menu_confirm")
	await _frames(2)
	_expect(not city.has_node("StreetChoice") and pc.inventory.money == money - 10, "Enter로 고르면 효과(동전)")
	city.street_event("checkpoint")
	await _frames(2)
	if _expect(st.closed.size() == 1, "검문 — 시설 하나가 닫힌다"):
		DialogueBox.auto_skip = false
		city.choose_facility(st.closed[0])
		await _frames(1)
		_expect(city.facility_view() == null and city.dialog().page_text().contains(Strings.t("city.reason_closed")), "닫힌 시설은 못 들어간다")
		city.dialog().clear()
		DialogueBox.auto_skip = true
	_expect(st.ap == ap, "거리 사건은 행동력을 쓰지 않는다")
	CityAmbient.enabled = false
	_main.call("_show_title")


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


## 도감(B — UI32): 몬스터 · 서적 분야. W/S로 분야를 옮기면 오른쪽이 바뀌고, 읽은 대목이 보인다. B로 닫으면 시간이 다시 흐른다.
func _codex_checks(explore: ExploreScreen) -> void:
	var s := explore.session
	var known := explore.codex().known
	known.append("d_cave_shape")
	await _action("codex")
	var cx := explore.codex()
	_expect(cx.is_open() and cx.page() is BestiaryPage and s.realtime.is_paused("codex"), "B = 도감(몬스터부터), 시간 멈춤")
	await _action("menu_down")
	_expect(cx.index().current() == "dungeon" and cx.page() is LorePage, "W/S로 분야 → 오른쪽이 서적")
	await _action("menu_confirm")
	_expect(cx.active_page() == cx.page() and (cx.page() as LorePage).current_id() == "d_cave_shape", "Enter → 읽은 대목")
	await _action("pause")
	_expect(cx.active_page() == cx.index() and cx.is_open(), "Esc → 왼쪽 목록")
	await _action("codex")
	_expect(not cx.is_open() and not s.realtime.is_paused("codex"), "B로 닫기 → 시간 다시 흐름")
	known.erase("d_cave_shape")


## Tab 메뉴(UI26): 왼쪽 아군 목록 — W/S·Enter로 아군을 고르면 가운데·오른쪽이 그 아군.
func _tab_party_checks(explore: ExploreScreen) -> void:
	var gm := explore.menu()
	var mate := PlayerCharacter.create(DataRegistry.db, "human", "archer", "동료", {"str": 9, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
	gm.party.append(mate)
	_expect(mate.get_row() == "back" and explore.session.player.get_row() == "front", "궁수 = 후위, 전사 = 전위(템플릿 역할)")
	await _action("menu")
	_expect(gm.is_open() and gm.order() == (["party", "character", "inventory"] as Array[String]), "Tab = 아군 · 캐릭터 · 소지품")
	gm.focus("party")
	await _action("menu_down")
	await _action("menu_confirm")
	_expect(gm.shown() == mate and gm.character().pc == mate and gm.inventory().wearer == mate and gm.inventory().actor == explore.session.player,
		"동료를 고르면 가운데·장비는 동료, 가방은 공용")
	await _action("menu_up")
	await _action("menu_confirm")
	_expect(gm.shown() == explore.session.player and gm.character().visible, "플레이어로 돌아온다")
	# 전위·후위·내보내기(사용자 2026-10-25): 고른 아군에서 Enter 한 번 더 → 창
	await _action("menu_down")
	await _action("menu_confirm")
	await _action("menu_confirm")
	_expect(gm.find_children("*", "ChoicePopup", true, false).size() == 1 and gm.party_page().busy(), "고른 아군에서 Enter 한 번 더 = 전위/후위/내보내기 창")
	await _action("menu_confirm")  # 첫 칸 = 전위(후위인 궁수라 고를 수 있다)
	await _frames(2)
	_expect(mate.get_row() == "front" and not gm.party_page().busy(), "전위로 바꾼다")
	mate.row = "back"
	gm._reorder(mate)
	_expect(gm.party.find(mate) == gm.party.size() - 1, "후위는 아래로")
	await _action("menu_confirm")
	await _action("menu_down")
	await _action("menu_down")  # 전위(커서) → 후위(지금 줄이라 못 고름) → 파티에서 내보낸다
	await _action("menu_confirm")  # 한 번 더 묻는다
	await _frames(2)
	_expect(gm.party.has(mate) and gm.find_children("*", "ChoicePopup", true, false).size() == 1
		and str(gm.find_children("*", "ChoicePopup", true, false)[0].grid.current_option().get("text")) == Strings.t("party.release_yes"),
		"내보내기는 한 번 더 묻는다")
	await _action("menu_confirm")
	await _frames(2)
	_expect(not gm.party.has(mate) and gm.shown() == explore.session.player, "내보내면 목록에서 빠지고 플레이어를 본다")
	await _action("menu")
	gm.party.erase(mate)
