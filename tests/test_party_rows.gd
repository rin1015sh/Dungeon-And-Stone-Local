extends TestCase
## 전위·후위(사용자 2026-10-25 — 전위가 적 어그로를 더 받는다) · 10층 비율 공식의 CTB(등급 속도 배율·연달아 2번) · 동료 저장.


func _pc(cls: String, name: String, agi: int = 10) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", cls, name, {"str": 10, "agi": agi, "p_res": 9, "m_res": 6, "int": 6})
	pc.pool.fill_all()
	return pc


func test_row_from_template_role_and_override() -> void:
	assert_eq(_pc("warrior", "전사").get_row(), "front", "탱커 = 전위")
	assert_eq(_pc("swordsman", "검사").get_row(), "front", "근접 딜러 = 전위")
	var archer := _pc("archer", "궁수")
	assert_eq(archer.get_row(), "back", "궁수 = 후위")
	archer.row = "front"
	assert_eq(archer.get_row(), "front", "직접 바꾼 줄이 이긴다")


func test_battle_uses_rows_and_front_draws_attacks() -> void:
	var front := _pc("warrior", "전위")
	var back := _pc("archer", "후위")
	var party: Array[Actor] = [front, back]
	var hits := {"전위": 0, "후위": 0}
	for s in 200:
		var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(s + 1), party, ["goblin"])
		assert_eq(b.unit_of(back).row, "back")
		var t := MonsterAi.front_weighted(b, b.side_units(Combatant.SIDE_PARTY))
		hits[t.label()] = int(hits[t.label()]) + 1
	var w := float(db.bal("combat.front_aggro"))
	var want := 200.0 * w / (w + 1.0)
	assert_true(absf(float(hits["전위"]) - want) < 25.0, "전위가 무게 %.0f : 1로 더 맞는다 (%d/200, 기대 %d)" % [w, hits["전위"], roundi(want)])


func test_lord_speed_mult_and_no_three_in_a_row() -> void:
	var slow := _pc("warrior", "느림", 1)
	var party: Array[Actor] = [slow]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["dreadfear"])
	var lord: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.unit_of(slow)
	var mult := float((db.bal("combat.rank_speed") as Dictionary)["lord"])
	assert_near(b.timeline.speed_of(lord), lord.speed(1.0, float(db.bal("combat.speed_base")), float(db.bal("combat.speed_exp"))) * mult, 0.001,
		"계층군주 속도 × %.2f" % mult)
	var order := b.timeline.preview(30)
	var streak := 0
	var worst := 0
	var last: Combatant = null
	for c in order:
		streak = streak + 1 if c == last else 1
		last = c
		worst = maxi(worst, streak)
	assert_true(order.has(me), "느려도 차례가 온다")
	assert_true(worst <= int(db.bal("combat.max_streak")), "아무리 빨라도 연달아 %d번까지 (%d)" % [int(db.bal("combat.max_streak")), worst])


func test_companions_saved_with_rows() -> void:
	var pc := _pc("warrior", "주인")
	var mate := CharacterRoller.random_companion(db, Rng.new(5), 3, 7)
	mate.display_name = "동료"
	mate.row = "back"
	var city := CityState.new(db, 5)
	city.start()
	var path := "user://dungeon_and_stone/test_party_save.json"
	var mates: Array[PlayerCharacter] = [mate]
	assert_true(SaveGame.write(SaveGame.capture(pc, city, RiftCalendar.new(db), 1, 0, mates), path))
	var data := SaveGame.read(path)
	var back := SaveGame.restore_companions(db, data)
	assert_eq(back.size(), 1, "동료 하나")
	assert_eq([back[0].display_name, back[0].id, back[0].row, back[0].get_level()], ["동료", "mate_7", "back", 3], "이름·id·줄·레벨")
	assert_eq(back[0].inventory.money, 0, "동료는 따로 돈·가방을 갖지 않는다(공용 가방)")
	assert_eq(SaveGame.restore_companions(db, {"player": {}}).size(), 0, "옛 저장 = 동료 없음")
	SaveGame.delete(path)


func test_boss_enrages_after_long_fight() -> void:
	var me := _pc("warrior", "버팀")
	var party: Array[Actor] = [me]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(4), party, ["blater"])
	var boss: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	var after := int(((db.bal("combat.enrage") as Dictionary)["after_turns"] as Dictionary)["guardian"])
	for i in after:
		BossHooks.turn_end(b, boss, false)
	assert_near(boss.actor.stats.apply_modifiers("dmg_dealt:all", 1.0), 1.0, 0.001, "정해진 차례까지는 그대로")
	BossHooks.turn_end(b, boss, false)
	BossHooks.turn_end(b, boss, false)
	assert_near(boss.actor.stats.apply_modifiers("dmg_dealt:all", 1.0), 1.0 + 2.0 * float((db.bal("combat.enrage") as Dictionary)["per_turn"]), 0.001, "넘긴 차례마다 주는 피해가 오른다")
	assert_true(b.history.any(func(h: Dictionary) -> bool: return str(h["key"]) == "combat.enrage"), "처음 넘을 때 알린다")
