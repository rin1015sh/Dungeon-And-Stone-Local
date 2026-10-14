extends TestCase
## 정수(docs/PROMPT_FLOOR1_V2.md §3): 흡수(패시브·색 액티브·스탯) · 슬롯 · 중복 거부 · 수호자 · 제거·삭제 비용 · 드롭 · 저장.


func _pc(level: int = 3) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 5})
	pc.set_level(level)
	return pc


func _inst(id: String, color: String, stats: Dictionary = {}) -> Dictionary:
	return {"essence": id, "color": color, "stats": stats}


func test_absorb_grants_passive_active_and_stats() -> void:
	var pc := _pc()
	var agi := pc.stats.get_value("agi")
	assert_eq(pc.essences.absorb(pc, _inst("gnome", "blue", {"agi": 2})), "")
	assert_true(pc.skills.has("ess_gnome_harden"), "파랑 = 굳히기")
	assert_false(pc.skills.has("ess_gnome_merge"), "다른 색 액티브는 없다")
	assert_eq(pc.stats.get_value("agi"), agi + 2.0, "굴린 스탯")
	assert_true(pc.stats.apply_modifiers("dmg_taken:slash", 1.0) < 1.0, "진흙 몸: 베기 피해 감소")
	assert_true(pc.stats.apply_modifiers("dmg_taken:blunt", 1.0) > 1.0, "진흙 몸: 둔기 피해 증가")


func test_slots_limit_by_level() -> void:
	var pc := _pc(1)
	assert_eq(pc.essences.absorb(pc, _inst("goblin", "red")), "")
	assert_eq(pc.essences.absorb(pc, _inst("ghoul", "red")), "essence.reason_no_slot", "슬롯 = 레벨")
	pc.set_level(2)
	assert_eq(pc.essences.absorb(pc, _inst("ghoul", "red")), "")


func test_same_monster_other_color_is_rejected() -> void:
	var pc := _pc()
	assert_eq(pc.essences.absorb(pc, _inst("blade_wolf", "red")), "")
	assert_eq(pc.essences.absorb(pc, _inst("blade_wolf", "blue")), "essence.reason_duplicate", "패시브가 겹친다")


func test_shared_skill_conflicts_across_essences() -> void:
	# 변이종(엘더 구울 등)이 아직 없으므로 공유 스킬을 쓰는 가짜 정수로 확인한다.
	var d := GameDatabase.new()
	d.load_all("res://data")
	d.put_entry("essences", {"id": "fake_elder", "name_ko": "가짜", "grade": 9,
		"passive": {"id": "fake_passive", "name_ko": "가짜", "modifiers": []},
		"actives": [{"color": "gray", "skill": "ess_ghoul_claw"}], "stat_ranges": {}})
	var pc := PlayerCharacter.create(d, "human", "warrior", "시험", {"str": 10})
	pc.set_level(3)
	assert_eq(pc.essences.absorb(pc, _inst("ghoul", "red")), "")
	assert_eq(pc.essences.absorb(pc, _inst("fake_elder", "gray")), "essence.reason_duplicate",
		"구울 빨강(할퀴기)과 같은 이능")
	assert_true(EssenceSet.conflict_keys(d, _inst("ghoul", "red")).has("skill:ghoul_claw"), "비교 키 = essence_of")


func test_guardian_essence_has_all_actives_and_upgrades() -> void:
	var pc := _pc()
	assert_eq(pc.essences.absorb(pc, _inst("goblin", "red")), "")
	var g := EssenceDrop.make(db, "goblin", "", Rng.new(1), true)
	assert_eq(str(g["color"]), "rainbow")
	assert_eq(EssenceSet.granted_skills(db, g).size(), 3, "무지갯빛 = 액티브 전부")
	assert_eq(pc.essences.absorb(pc, g), "", "같은 정수 일반 → 수호자 업그레이드")
	assert_eq(pc.essences.absorbed.size(), 1, "자리를 바꾼다")
	assert_true(pc.skills.has("ess_goblin_trap") and pc.skills.has("ess_goblin_sand"))
	var r := Rng.new(5)
	var normal := EssenceDrop.roll_stats(db, {"stat_ranges": {"agi": [10, 10]}}, r)
	var boosted := EssenceDrop.roll_stats(db, {"stat_ranges": {"agi": [10, 10]}}, r, true)
	assert_eq(int(normal["agi"]), 10)
	assert_eq(int(boosted["agi"]), 15, "스탯 × 1.5")


func test_remove_detaches_and_delete_cost_doubles() -> void:
	var pc := _pc()
	var agi := pc.stats.get_value("agi")
	var base := int(db.bal("essence.delete_cost_base"))
	assert_eq(pc.essences.next_delete_cost(db), base)
	pc.essences.absorb(pc, _inst("ghoul", "blue", {"agi": 3}))
	assert_true(pc.essences.remove(pc, 0))
	assert_false(pc.skills.has("ess_ghoul_pounce"), "스킬도 사라진다")
	assert_eq(pc.stats.get_value("agi"), agi)
	assert_eq(pc.essences.next_delete_cost(db), base * 2, "매번 2배")
	assert_eq(pc.essences.absorb(pc, _inst("ghoul", "red")), "", "지운 뒤에는 다시 받아들일 수 있다")


func test_drop_chance_and_pending_expiry() -> void:
	var d := GameDatabase.new()
	d.load_all("res://data")
	assert_eq(EssenceDrop.drop_chance(d, {"grade": 9}), 0.02)
	assert_eq(EssenceDrop.drop_chance(d, {"grade": 9}, true), 0.08, "균열 안 ×4")
	assert_eq(EssenceDrop.drop_chance(d, {"grade": 6, "rank": "guardian"}), 0.33)
	assert_eq(EssenceDrop.essence_of_monster(d, "goblin"), "goblin")
	(d.singletons["balance"]["essence"]["drop_chance_by_grade"] as Dictionary)["9"] = 1.0
	var pc := PlayerCharacter.create(d, "human", "warrior", "시험", {"str": 10})
	var killed: Array[String] = ["gnome"]
	var msgs := Rewards.grant(pc, killed, Rng.new(4), 10.0)
	assert_true(msgs.any(func(m: Dictionary) -> bool: return m["key"] == "reward.essence"), "정수가 떨어진다")
	assert_eq(pc.essences.pending.size(), 1)
	assert_eq(pc.essences.expire_pending(10.1).size(), 0)
	assert_eq(pc.essences.expire_pending(10.0 + float(d.bal("essence.expire_hours"))).size(), 1, "오래 두면 사라진다")
	assert_eq(pc.essences.pending.size(), 0)


func test_absorb_pending_and_save_roundtrip() -> void:
	var pc := _pc()
	pc.essences.add_pending(db, _inst("blade_wolf", "yellow", {"int": 9}))
	assert_eq(pc.essences.absorb_pending(pc, 0), "")
	assert_eq(pc.essences.pending.size(), 0)
	pc.essences.add_pending(db, _inst("goblin", "green"))
	var data := pc.progress_to_dict()
	var copy := _pc()
	copy.progress_load_dict(data)
	assert_true(copy.essences.has_essence("blade_wolf"))
	assert_true(copy.skills.has("ess_wolf_blade_graze"), "불러오면 스킬도 다시 붙는다")
	assert_eq(copy.stats.get_value("int"), pc.stats.get_value("int"))
	assert_eq(copy.essences.pending.size(), 1)


func test_essence_skill_usable_in_battle() -> void:
	var pc := _pc()
	pc.essences.absorb(pc, _inst("ghoul", "red"))
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(7), party, ["goblin"], true)
	var c := b.next_turn()
	while c != null and c.actor != pc:
		b.act(c, b.ai_action(c))
		c = b.next_turn()
	assert_true(c != null, "플레이어 차례가 온다")
	assert_true(b.act(c, {"kind": "skill", "skill": "ess_ghoul_claw", "target": b.opponents(c)[0]}), "정수 스킬 사용")


## 모든 정수(수호자 = 액티브 전부)의 스킬이 전투에서 실제로 쓰인다(대상 종류별로 행동창이 고르는 대상을 넘긴다).
func test_every_essence_skill_usable_in_battle() -> void:
	for eid: String in db.get_collection("essences").keys():
		var inst := _inst(eid, str(db.bal("essence.guardian_color", "rainbow")))
		for sid: String in EssenceSet.granted_skills(db, inst):
			var pc := _pc(11)
			assert_eq(pc.essences.absorb(pc, inst), "", "%s 흡수" % eid)
			pc.pool.set_current("soul", pc.pool.get_max("soul"))
			var party: Array[Actor] = [pc]
			var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["goblin"], true)
			var c := b.next_turn()
			while c != null and c.actor != pc:
				b.act(c, b.ai_action(c))
				c = b.next_turn()
			assert_true(c != null, "%s: 플레이어 차례" % sid)
			if c == null:
				continue
			assert_eq(b.can_use(c, sid), "", "%s: 쓸 수 있다" % sid)
			var kind := JsonUtil.get_str(db.get_entry("skills", sid), "target")
			var tgt: Variant = b.opponents(c)[0] if kind in ["enemy_single", "enemy_row"] else (c if kind in ["ally_single", "any_single"] else null)
			var before := b.history.size()
			assert_true(b.act(c, {"kind": "skill", "skill": sid, "target": tgt}), "%s: 사용" % sid)
			assert_true(b.history.size() >= before + 2, "%s: 사용 안내 + 결과(효과가 없어도 알린다)" % sid)


## 확률 상태 스킬이 빗나가도 조용히 끝나지 않는다.
func test_failed_status_skill_reports_no_effect() -> void:
	var seen := false
	for seed_value in 40:
		var pc := _pc()
		pc.essences.absorb(pc, _inst("guardian_eye", "blue"))
		assert_true(pc.skills.has("ess_eye_paralysis_gaze"))
		var party: Array[Actor] = [pc]
		var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, ["goblin"], true)
		var c := b.next_turn()
		while c != null and c.actor != pc:
			b.act(c, b.ai_action(c))
			c = b.next_turn()
		if c == null:
			continue
		b.act(c, {"kind": "skill", "skill": "ess_eye_paralysis_gaze", "target": b.opponents(c)[0]})
		var keys := b.history.map(func(h: Dictionary) -> String: return str(h["key"]))
		if keys.has("combat.no_effect"):
			seen = true
			break
	assert_true(seen, "마비 시선이 안 걸리면 '아무 효과도 내지 못했다'를 알린다")
