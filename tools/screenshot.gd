extends Node
## 화면 캡처 도구(시각 확인용). 창이 잠깐 떴다가 PNG를 저장하고 닫힌다. 헤드리스에서는 렌더링이 없어 쓸 수 없다.
##   godot --path . res://tools/screenshot.tscn -- --screen=explore --out=C:/tmp/shot.png [--seed=123] [--walk=6] [--debug]
## --screen: title(기본) / foundation / create / explore
## --seed: 탐험 층 시드 고정, --walk: 입장 후 오른쪽·아래로 몇 걸음 걸을지, --debug: 디버그 패널 열기,
## --portal: 가장 가까운 2층 포탈로 순간이동(1층 팔 끝 암흑지대 확인), --torch: 횃불 켜기, --reveal: 안개 걷기, --combat: 옆에 몬스터를 불러 전투 화면, --pause: 일시정지 화면
## --monster=<id>: --combat에서 부를 몬스터, --summon: 전투 화면에서 적 진영에 고블린 증원(카드가 붙는지 확인)
## --rift_open=<균열 id>: 옆에 균열 포탈, --rift=<균열 id> [--chapter=n] [--engage[=guardian|riddle]]: 들어가서 n번째 챕터로(riddle = 수수께끼 대화창)
## (앞 챕터는 디버그로 치움, 출구 조건 아이템은 지급), 첫 조우(또는 그 종류의 조우)와 전투
## --lord: 맵에 계층군주 소환(붉은 수정·시야 2m), --meters: 전투 화면에서 탐험가 게이지를 채우고 보스를 P2로(게이지 표시 확인)
## --tooltip: 아이템 툴팁(비교) 띄우기, --inventory / --character / --bestiary: 창 열기(--loot: 마석·장비 몇 개를 가방에 넣고 도감 기록을 채운다)
## --essence: 레벨 3으로 올리고 정수 하나 흡수 + 흡수 대기 둘(하나는 중복이라 흡수 불가) — --character와 함께
## --summon=N: 적 N마리 증원, --ally_summon: 아군 소환수, --win: 적을 모두 쓰러뜨려 승리 결과 칸(보상)
## --details: (--character와 함께) 캐릭터 창 세부 능력 탭
## --many: (--essence와 함께) 만렙 + 수호자 정수 여럿, --skills: 전투 행동창에서 스킬 목록, --keys=a,b: 행동창 키 액션 차례로
## --lock: (--essence와 함께) 정수를 하나 더 흡수한 뒤 레벨 1로 내려 잠긴 정수를 보인다

var _main: Control
var _args: Dictionary = {"screen": "title", "out": "user://screenshot.png", "seed": "0", "walk": "0"}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var kv := arg.trim_prefix("--").split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	GameState.debug_seed_override = str(_args["seed"]).to_int()
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(3)
	var screen := str(_args["screen"])
	if screen != "title":
		var title := _main.current_screen() as TitleScreen
		if screen == "foundation":
			title.foundation_requested.emit()
		else:
			title.new_game_requested.emit()
		await _frames(3)
	if screen == "explore":
		var create := _main.current_screen() as CharacterCreateScreen
		for b: Node in create.find_children("*", "Button", true, false):
			if (b as Button).text == Strings.t("create.enter"):
				(b as Button).pressed.emit()
		await _frames(3)
		var explore := _main.current_screen() as ExploreScreen
		if _args.has("torch"):
			explore.session.use_category("light")
		var steps := str(_args["walk"]).to_int()
		for i in steps:
			explore.session.pass_time(explore.session.move_hours())  # 이동 간격을 채운다(실시간을 기다리지 않음)
			var dir := Vector2i(1, 0) if i % 2 == 0 else Vector2i(0, 1)
			if not explore.session.try_move(dir):
				explore.session.try_move(Vector2i(0, -1) if i % 2 == 0 else Vector2i(-1, 0))
			await _frames(2)
		if _args.has("portal"):
			ExploreDebug.teleport(explore.session, ExploreDebug.nearest_portal(explore.session))
			await _frames(2)
		if _args.has("reveal"):
			ExploreDebug.reveal(explore.session)
		if _args.has("loot"):
			var pc := explore.session.player
			pc.inventory.add("magic_stone_9", 7)
			pc.inventory.add("steel_spear")
			pc.inventory.add("copper_ring")
			pc.inventory.add("iron_helm")
			pc.inventory.add("medium_potion", 2)
			for id: String in ["goblin", "blade_wolf"]:
				pc.knowledge.see(id)
				pc.progression.gain(pc, pc.progression.record_kill(pc.db, id))
			pc.knowledge.learn_stats("blade_wolf")
			pc.knowledge.learn_affinity("blade_wolf", "lightning", 1.5)
		if _args.has("essence"):
			var epc := explore.session.player
			epc.set_level(3)
			epc.essences.absorb(epc, {"essence": "gnome", "color": "blue", "stats": {"p_res": 3, "m_res": 1, "agi": 2}})
			epc.essences.add_pending(epc.db, {"essence": "goblin", "color": "red", "stats": {"agi": 3}})
			epc.essences.add_pending(epc.db, {"essence": "gnome", "color": "green", "stats": {"p_res": 2}})
			if _args.has("many"):  # 만렙 + 수호자 정수 여럿(스킬이 많은 행동창 확인)
				epc.set_level(11)
				for id: String in ["goblin", "ghoul", "blade_wolf", "chimera_wolf", "blater", "bone_knight"]:
					epc.essences.absorb(epc, {"essence": id, "color": "rainbow", "stats": {}})
			if _args.has("lock"):
				epc.essences.absorb(epc, {"essence": "ghoul", "color": "red", "stats": {"agi": 3}})
				epc.set_level(1)
		for w: String in ["inventory", "character", "bestiary"]:
			if _args.has(w):
				explore.windows().open(w)
		if _args.has("details"):  # 캐릭터 창 "세부 능력" 탭
			for t: Node in _main.find_children("*", "TabContainer", true, false):
				(t as TabContainer).current_tab = 1
		if _args.has("tooltip"):  # 툴팁 모양 확인: 가방의 창(장착 중인 무기와 비교)
			var tip := ItemTooltip.build(explore.session.db, "steel_spear", explore.session.player)
			explore.add_child(tip)
			tip.position = Vector2(80, 80)
		if _args.has("pause"):
			explore.set_paused(true)
		if _args.has("rift_open"):
			explore.session.rifts.force_open(explore.session, str(_args["rift_open"]), explore.session.pos)
		if _args.has("rift"):
			explore = await _enter_rift(explore)
		if _args.has("lord"):
			explore.session.lord.summon(explore.session)
		if _args.has("combat"):
			ExploreDebug.spawn_and_engage(explore.session, str(_args.get("monster", "")))
			if _args.has("meters"):
				await _frames(3)
				for n: Node in _main.find_children("*", "", true, false):
					if n is CombatScreen:
						var cb := (n as CombatScreen).battle
						var me := cb.side_units(Combatant.SIDE_PARTY)[0]
						me.actor.meters["dread_fear"] = 45.0
						me.actor.meters["dread_plague"] = 16.0
						var boss := cb.side_units(Combatant.SIDE_ENEMY)[0]
						boss.actor.pool.set_current("hp", boss.actor.pool.get_max("hp") * 0.6)
						BossHooks.check_all(cb)
						BossHooks.turn_end(cb, boss, false)
			if _args.has("summon"):
				await _frames(3)
				for n: Node in _main.find_children("*", "", true, false):
					if n is CombatScreen:
						var cs := n as CombatScreen
						for k in int(str(_args["summon"]).to_int()) if str(_args["summon"]).is_valid_int() else 1:  # --summon=N: N마리
							BattleRules.summon(cs.battle, cs.battle.side_units(Combatant.SIDE_ENEMY)[0], {"monster": "goblin"})
						if _args.has("ally_summon"):  # 아군 소환수 카드(정수판 망자의 맹세)
							BattleRules.summon(cs.battle, cs.battle.side_units(Combatant.SIDE_PARTY)[0], {"monster": "deadman"})
		if _args.has("win"):  # 전투 승리 결과 칸(보상 안내) 확인: 적을 모두 쓰러뜨리고 방어로 차례를 넘긴다
			await _frames(10)
			for n: Node in _main.find_children("*", "", true, false):
				if n is CombatScreen:
					var wb := (n as CombatScreen).battle
					for u in wb.side_units(Combatant.SIDE_ENEMY):
						u.actor.pool.set_current("hp", 0.0)
					(n as CombatScreen)._on_chosen({"kind": "guard"})
		if _args.has("drain"):  # 영혼력을 바닥내 "대가 부족" 칸을 보인다
			explore.session.player.pool.set_current("soul", 0.0)
		if _args.has("skills"):  # 전투 행동창에서 "스킬"을 눌러 스킬 목록을 띄운다(정수 스킬 표시 확인)
			await _frames(10)
			for m: Node in _main.find_children("*", "CommandMenu", true, false):
				for b: Node in m.find_children("*", "Button", true, false):
					if (b as Button).text == Strings.t("combat.cmd_skill"):
						(b as Button).pressed.emit()
		if _args.has("keys"):  # 행동창 키 입력 흉내: --keys=menu_right,menu_right,menu_confirm (쪽 넘김·커서 확인)
			await _frames(10)
			for a: String in str(_args["keys"]).split(","):
				var kev := InputEventAction.new()
				kev.action = a
				kev.pressed = true
				Input.parse_input_event(kev)
				await _frames(2)
		if _args.has("debug"):
			var ev := InputEventAction.new()
			ev.action = "debug_toggle"
			ev.pressed = true
			Input.parse_input_event(ev)
		await _frames(30)
	await _frames(6)
	var img := get_viewport().get_texture().get_image()
	var out := str(_args["out"])
	var err := img.save_png(out)
	print("스크린샷 %s → %s" % ["저장" if err == OK else "실패(%d)" % err, ProjectSettings.globalize_path(out)])
	get_tree().quit(0 if err == OK else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _enter_rift(explore: ExploreScreen) -> ExploreScreen:
	var s := explore.session
	s.rifts.force_open(s, str(_args["rift"]), s.pos)
	var portal: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	s.relocate(portal["pos"])
	s.interact()
	await _frames(4)
	explore = _main.current_screen() as ExploreScreen
	for i in int(str(_args.get("chapter", "1"))) - 1:
		explore.session.rift_run.debug_clear()
		var req := JsonUtil.get_dict(explore.session.rift_run.chapters()[explore.session.rift_run.chapter], "exit_requires")
		if not req.is_empty():
			explore.session.player.inventory.add(JsonUtil.get_str(req, "item"), 1)
		explore.session.relocate(explore.session.map.portals[0]["pos"])
		explore.session.interact()
		await _frames(4)
		explore = _main.current_screen() as ExploreScreen
	if _args.has("engage"):
		var run := explore.session.rift_run
		var pick: FieldMonsters.Group = run.remaining[0]
		for g: FieldMonsters.Group in run.remaining:
			if g.tag == str(_args["engage"]):
				pick = g
		explore.session.engage(pick, true)
	return explore
