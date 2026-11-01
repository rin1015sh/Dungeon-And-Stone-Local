extends SceneTree
## 몬스터 스킬 실전 시뮬(2026-11-01 몬스터 스킬 검사): 몬스터마다 AI + 보스 패턴으로 16판 — 가진 스킬을 한 번이라도 꺼내 쓰는지.
##   godot --headless --path . --script res://tools/sim_skills.gd            (MON=<id> 환경 변수면 그 몬스터만 + 쓴 횟수)
## 쓴 것은 combat.use_skill 알림으로 센다. 몬스터 생명력은 판마다 12·22·32 차례에 걸쳐 바닥까지 고르게 내린다("생명력 몇 % 아래" 규칙을 모두 거치게),
## 판 % 4: 0 = 홀로(4차례째에 동료를 모두 쓰러뜨림 — alone), 1 = 고블린 하나, 2·3 = 같은 종 둘(무리 사냥·흡수). 아군은 반은 기본 공격, 반은 방어.
## 끝에 "모두 씀" 또는 몬스터마다 안 쓴 스킬. 드레드피어 증오 폭발은 증오 게이지(P3부터 라운드당 5)가 차야 해 여기서는 안 나온다 — tests/test_lord.gd가 본다.
var db: GameDatabase
var used := {}  # 몬스터 id → {스킬 이름: 횟수}
var by_label := {}

func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 14, "p_res": 30, "m_res": 20, "int": 20})
	pc.set_level(5)
	pc.pool.fill_all()
	pc.skills.append("ess_deadman_grab")
	pc.pool.set_min_value("hp", 1.0)
	return pc

func _on_msg(k: String, a: Dictionary, _kind: String) -> void:
	if k != "combat.use_skill":
		return
	var mid := str(by_label.get(str(a.get("name")), ""))
	if mid.is_empty():
		return
	var d: Dictionary = used.get(mid, {})
	d[str(a["skill"])] = int(d.get(str(a["skill"]), 0)) + 1
	used[mid] = d

func _init() -> void:
	db = GameDatabase.new()
	db.load_all("res://data")
	var reg := ContentRegistries.new()
	var only := OS.get_environment("MON")
	var bad := 0
	for mid: String in db.get_collection("monsters").keys():
		if not only.is_empty() and mid != only:
			continue
		var m := db.get_entry("monsters", mid)
		for game in 16:
			var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(hash("g%d%s" % [game, mid]) % 1000000 + 1))
			b.message.connect(_on_msg)
			for i in 3:
				b.add(_pc(), Combatant.SIDE_PARTY, "front" if i < 2 else "back")
			var row := JsonUtil.get_str(JsonUtil.get_dict(m, "behavior"), "row", "front")
			var mon := b.add(Monster.create(db, mid), Combatant.SIDE_ENEMY, row)
			mon.actor.pool.set_min_value("hp", 1.0)
			match game % 4:
				1:
					b.add(Monster.create(db, "goblin"), Combatant.SIDE_ENEMY)
				2, 3:  # 같은 종 동료 둘(무리 사냥·흡수)
					for k in 2:
						b.add(Monster.create(db, mid), Combatant.SIDE_ENEMY)
			b.start()
			var mine := 0
			var span := 12 + (game % 3) * 10  # 생명력이 이 차례 수에 걸쳐 바닥까지
			for t in 500:
				var c := b.next_turn()
				if c == null or b.is_over():
					break
				by_label.clear()
				for u in b.units:
					by_label[u.label()] = u.actor.id
				if b.is_player_controlled(c):
					var foes := BattleRules.targetable(b, c)
					if b.rng.chance(0.5) and not foes.is_empty():
						b.act(c, {"kind": "skill", "skill": "basic_attack", "target": foes[0]})
					else:
						b.act(c, {"kind": "guard"})
				else:
					if c == mon:
						var want := clampf(1.0 - float(mine) / span, 0.03, 1.0)
						if mon.actor.pool.get_ratio("hp") > want:
							mon.actor.pool.set_current("hp", mon.actor.pool.get_max("hp") * want)
							BossHooks.check_all(b)
					var a := b.ai_action(c)
					if not b.act(c, a):
						print("거부 %s %s" % [c.actor.id, str(a.get("skill", a.get("kind")))])
						b.act(c, {"kind": "guard"})
					if c == mon:
						mine += 1
						if game % 4 == 0 and mine == 4:  # 동료를 모두 쓰러뜨려 홀로 남긴다(구울 군주 소환 — alone)
							for u in b.side_units(Combatant.SIDE_ENEMY):
								if u != mon:
									u.actor.pool.set_min_value("hp", 0.0)
									u.actor.pool.set_current("hp", 0.0)
							b._after_effects()
						if mine >= span + 8:
							break
		var d: Dictionary = used.get(mid, {})
		var never: Array = []
		for s in JsonUtil.get_array(m, "skills"):
			if str(s) != "basic_attack" and not d.has(JsonUtil.get_str(db.get_entry("skills", str(s)), "name_ko")):
				never.append(s)
		if mid == "dreadfear":
			never.erase("dread_hate_explosion")  # 증오 게이지가 차야(test_lord)
		if not never.is_empty():
			bad += 1
			print("%s 안 씀=%s 쓴 것=%s" % [mid, str(never), str(d)])
		elif not only.is_empty():
			print("%s 다 씀 %s" % [mid, str(d)])
	print("모두 씀" if bad == 0 else "안 쓰는 스킬이 있는 몬스터 %d" % bad)
	quit()
