extends TestCase
## 장비 스킬(사용자 요청 2026-10-26, IT8): 무기·방패 종류(item_types skills)가 든 사람에게 전투 스킬을 준다.
## 장비를 바꾸면 스킬도 바뀌고(맨 앞), 벗으면 잊고, 저장·불러오기 뒤에도 지금 장비와 맞는다.


func _pc(cls: String) -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", cls, "시험", {"str": 10, "agi": 8, "p_res": 5})


func _gear(a: Actor) -> Array[String]:
	var out: Array[String] = []
	for s in a.skills:
		if JsonUtil.get_bool(db.get_entry("skills", s), "gear"):
			out.append(s)
	return out


func test_every_weapon_type_gives_skills() -> void:
	for tid: String in db.get_collection("item_types"):
		var t := db.get_entry("item_types", tid)
		if JsonUtil.get_str(t, "category") == "weapon":
			assert_true(JsonUtil.get_array(t, "skills").size() >= 2, "%s 스킬 2개 이상" % tid)
	assert_eq(ItemInfo.skills(db, "redwood_bow"), ["wpn_bow_aim", "wpn_bow_volley"], "공식 아이템이 종류 스킬을 받는다")
	assert_eq(ItemInfo.skills(db, "steel_spear"), ["wpn_spear_pierce", "wpn_spear_keep"], "옛 장비(forge)도")


func test_start_templates_have_weapon_skills_first() -> void:
	for cls: String in db.get_collection("classes"):
		var pc := _pc(cls)
		assert_true(_gear(pc).size() >= 2, "%s 시작 무기 스킬" % cls)
		assert_true(JsonUtil.get_bool(db.get_entry("skills", pc.skills[0]), "gear"), "%s 장비 스킬이 목록 맨 앞" % cls)
		assert_true(pc.skills.has("talk") and pc.skills.has("investigate"), "기본 스킬은 그대로")
	var w := _pc("warrior")
	assert_true(_gear(w).has("wpn_shield_cover"), "전사 나무 방패 = 막아서기")


func test_swap_and_unequip_change_skills() -> void:
	var pc := _pc("swordsman")
	assert_eq(_gear(pc), ["wpn_sword_sweep", "wpn_sword_guard"])
	pc.equipment.equip(pc.stats, "steel_axe", "main_hand")
	assert_eq(_gear(pc), ["wpn_axe_hack", "wpn_axe_split"], "무기를 바꾸면 스킬도")
	pc.learn_skill("ess_ghoul_claw")
	pc.equipment.unequip(pc.stats, "main_hand")
	assert_eq(_gear(pc).size(), 0, "벗으면 잊는다")
	assert_true(pc.skills.has("ess_ghoul_claw") and pc.skills.has("talk"), "정수·기본 스킬은 남는다")


func test_save_round_trip_keeps_gear_skills_in_sync() -> void:
	var pc := _pc("archer")
	var d := SaveGame._pc_dict(pc)
	(d["skills"] as Array).append("wpn_sword_sweep")  # 낡은 저장(지금 장비와 안 맞는 장비 스킬)
	var back := SaveGame._restore_pc(db, d, "player")
	assert_eq(_gear(back), ["wpn_bow_aim", "wpn_bow_volley"], "불러오면 지금 장비 기준")


func test_gear_skill_usable_in_battle() -> void:
	var pc := _pc("spearman")
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["goblin"], Combatant.SIDE_PARTY)
	var me := b.next_turn()
	assert_eq(me.actor, pc, "아군 차례")
	assert_eq(b.can_use(me, "wpn_spear_pierce"), "", "창 스킬을 쓸 수 있다")
	var soul := pc.pool.get_current("soul")
	b.act(me, {"kind": "skill", "skill": "wpn_spear_pierce", "target": b.side_units(Combatant.SIDE_ENEMY)[0]})
	assert_true(pc.pool.get_current("soul") < soul, "영혼력을 쓴다")
