extends TestCase
## 성장: 첫 처치 경험치·도감·레벨업 · Knowledge(???) · 전리품 · 저장 왕복.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 5})


func test_first_kill_exp_only_once() -> void:
	var p := Progression.new()
	assert_eq(p.record_kill(db, "goblin"), 1, "9등급 = 10 − 9")
	assert_eq(p.record_kill(db, "goblin"), 0, "같은 몬스터는 다시 주지 않는다")
	assert_eq(p.kill_count("goblin"), 2)
	assert_eq(Progression.first_kill_exp(db, {"grade": 7}), 3, "(10 − 등급)")


func test_level_up_raises_soul_and_slots() -> void:
	var pc := _pc()
	var soul := pc.pool.get_max("soul")
	var table := Progression.exp_table(db)
	assert_eq(pc.progression.gain(pc, int(table[1])), 2)
	assert_true(pc.pool.get_max("soul") > soul, "레벨업 → 영혼력 최대치 증가")
	pc.progression.gain(pc, 100000)
	assert_eq(pc.get_level(), Progression.max_level(db), "만렙")
	assert_eq(Progression.exp_for_next(db, pc.get_level()), -1)
	assert_eq(Progression.essence_slots(db, 3), 3)


func test_floor1_alone_does_not_reach_level5() -> void:
	var total := 0
	for id: String in ["blade_wolf", "gnome", "ghoul", "goblin"]:
		total += Progression.first_kill_exp(db, db.get_entry("monsters", id))
	assert_true(Progression.level_for(db, total) < 5, "1층만으로는 5레벨이 안 된다(%d)" % total)


func test_knowledge_and_investigate() -> void:
	var pc := _pc()
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["blade_wolf"], Combatant.SIDE_PARTY)
	assert_true(pc.knowledge.has_seen("blade_wolf"), "마주치면 봤다")
	assert_false(pc.knowledge.knows_stats("blade_wolf"))
	var keys: Array = []
	var args: Array = []
	b.message.connect(func(k: String, a: Dictionary, _kind: String) -> void:
		keys.append(k)
		args.append(a))
	var c := b.next_turn()
	b.act(c, {"kind": "skill", "skill": "investigate", "target": b.opponents(c)[0]})
	assert_true(pc.knowledge.knows_stats("blade_wolf"), "조사 → 스탯 공개")
	var info: Dictionary = args[keys.find("combat.info_monster")]
	assert_false(info.has("hp_now") or info.has("aff"), "전투 중 조사로는 생명력·상성을 알리지 않는다(도감 B에서만)")
	pc.knowledge.learn_affinity("blade_wolf", "lightning", 1.5)
	assert_true(BattleKnowledge.describe_affinities(db, pc.knowledge, "blade_wolf").contains("1.5"))


func test_hitting_reveals_affinity() -> void:
	var pc := _pc()
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5), party, ["goblin"], Combatant.SIDE_PARTY)
	var c := b.unit_of(pc)
	BattleKnowledge.on_damage(b, c, {"type": "damage", "hit": true, "damage_type": "blunt", "affinity": 1.0,
		"target": b.opponents(c)[0].actor})
	assert_eq(pc.knowledge.affinities("goblin").get("blunt"), 1.0, "보통 상성도 기록")


func test_loot_and_rewards() -> void:
	var d := GameDatabase.new()
	d.load_all("res://data")
	(d.singletons["balance"]["loot"] as Dictionary)["magic_stone_chance"] = 1.0
	var pc := PlayerCharacter.create(d, "human", "warrior", "시험", {"str": 10})
	var loot := Loot.roll(d, "goblin", Rng.new(1))
	assert_eq(loot[0]["id"], "magic_stone_9", "9등급 마석")
	var killed: Array[String] = ["goblin", "goblin", "blade_wolf"]
	var msgs := Rewards.grant(pc, killed, Rng.new(2))
	assert_eq(pc.progression.exp_total, 2, "고블린 1 + 칼날늑대 1 (두 번째 고블린은 0)")
	assert_true(pc.inventory.count("magic_stone_9") >= 3, "마석 셋")
	var keys := msgs.map(func(m: Dictionary) -> String: return str(m["key"]))
	assert_eq(keys.count("reward.first_kill"), 2)
	pc.inventory = Inventory.new(d, 1, 1)
	pc.inventory.add("ration")
	var ghoul: Array[String] = ["ghoul"]
	var full := Rewards.grant(pc, ghoul, Rng.new(3))
	assert_true(full.any(func(m: Dictionary) -> bool: return m["key"] == "reward.bag_full"), "가방이 가득 차면 두고 간다")


func test_progress_save_roundtrip() -> void:
	var pc := _pc()
	pc.progression.record_kill(db, "goblin")
	pc.progression.gain(pc, 1)
	pc.knowledge.learn_stats("ghoul")
	pc.inventory.add("copper_ring")
	var data := pc.progress_to_dict()
	var copy := PlayerCharacter.create(db, "human", "swordsman", "복사", {"str": 10})
	copy.progress_load_dict(JSON.parse_string(JSON.stringify(data)))
	assert_eq(copy.progression.exp_total, 1)
	assert_eq(copy.progression.kill_count("goblin"), 1)
	assert_true(copy.knowledge.knows_stats("ghoul"))
	assert_eq(copy.equipment.item_in("main_hand"), "iron_mace", "장비도 그대로")
	assert_eq(copy.inventory.count("copper_ring"), 1)
