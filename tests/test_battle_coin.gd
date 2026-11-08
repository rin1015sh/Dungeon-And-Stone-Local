extends TestCase
## 보스 동전 기술(C27 — BattleCoin): 예고 없이 쓰는 순간 앞뒤를 고르고 동전 — 맞히면 피함 · 덜 아프게, 틀리면 그대로.

const COIN_SKILLS := ["blater_death_sentence", "king_jump_crush"]


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


func _battle(monster: String, n_party: int = 1, seed_value: int = 3) -> Battle:
	var party: Array[Actor] = []
	for i in n_party:
		party.append(_pc())
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, [monster])


## 보스가 그 스킬을 쓰게 하고(동전 결과 coin — 비우면 Battle이 던진다) 아군이 받은 피해 사건을 돌려준다.
func _cast(b: Battle, skill: String, coin: Dictionary) -> Array:
	var boss := b.side_units(Combatant.SIDE_ENEMY)[0]
	boss.actor.pool.fill_all()
	var got: Array = []
	b.event.connect(func(e: Dictionary) -> void: got.append(e))
	b.current = boss
	b.phase = Battle.PHASE_AWAIT
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var action := {"kind": "skill", "skill": skill, "target": me}
	if not coin.is_empty():
		action["coin"] = coin
	assert_true(b.act(boss, action), skill + ": 쓴다")
	return got


func _lost(events: Array) -> Array:
	return events.filter(func(e: Dictionary) -> bool: return e.get("type") == "damage" and e.get("unit") is Combatant and (e["unit"] as Combatant).side == Combatant.SIDE_PARTY)


func test_coin_skills_have_no_telegraph() -> void:
	for sid: String in COIN_SKILLS:
		var sk := db.get_entry("skills", sid)
		assert_false(JsonUtil.get_dict(sk, "coin").is_empty(), sid + ": coin")
		for e: Variant in JsonUtil.get_array(sk, "effects"):
			assert_true(JsonUtil.get_str(e, "type") != "delayed", sid + ": 예고 없음")
		var ess := "ess_" + sid
		assert_true(JsonUtil.get_dict(db.get_entry("skills", ess), "coin").is_empty(), ess + ": 우리 정수판은 동전 없음")


func test_right_guess_dodges_sentence() -> void:
	var b := _battle("blater")
	var ev := _cast(b, "blater_death_sentence", {"guess": 0, "heads": true, "right": true})
	var dmg := _lost(ev)
	assert_eq(dmg.size(), 1)
	assert_false(bool(dmg[0]["hit"]), "맞히면 피한다(화면에 '회피')")
	assert_true(ev.any(func(e: Dictionary) -> bool: return e.get("type") == "coin" and bool(e["right"])), "동전 사건")


func test_wrong_guess_takes_full_hit() -> void:
	var b := _battle("blater")
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var hp := me.actor.pool.get_current("hp")
	var dmg := _lost(_cast(b, "blater_death_sentence", {"guess": 1, "heads": true, "right": false}))
	assert_true(bool(dmg[0]["hit"]), "틀리면 그대로 맞는다")
	assert_true(me.actor.dead or me.actor.pool.get_current("hp") < hp)


func test_right_guess_softens_jump_for_all() -> void:
	var full := _lost(_cast(_battle("king_slime", 3, 7), "king_jump_crush", {"guess": 0, "heads": false, "right": false}))
	var soft := _lost(_cast(_battle("king_slime", 3, 7), "king_jump_crush", {"guess": 0, "heads": true, "right": true}))
	assert_eq(full.size(), 3, "광역 — 셋 모두")
	assert_eq(soft.size(), 3, "동전 하나로 셋 모두")
	for i in 3:
		assert_near(float(soft[i]["amount"]), float(full[i]["amount"]) * 0.3, 2.0, "맞히면 ×0.3")


func test_guard_still_helps_on_wrong_guess() -> void:
	var plain := _battle("king_slime", 1, 9)
	var guard := _battle("king_slime", 1, 9)
	guard.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.apply("guarding")
	var wrong := {"guess": 0, "heads": false, "right": false}
	var a := float(_lost(_cast(plain, "king_jump_crush", wrong))[0]["amount"])
	var g := float(_lost(_cast(guard, "king_jump_crush", wrong))[0]["amount"])
	assert_true(g < a * 0.5, "방어 중이면 틀려도 덜 아프다 %d vs %d" % [g, a])


func test_battle_flips_when_no_screen() -> void:
	var b := _battle("blater")
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var ev := _cast(b, "blater_death_sentence", {})
	assert_eq(ev.filter(func(e: Dictionary) -> bool: return e.get("type") == "coin").size(), 1, "화면이 없으면 Battle이 던진다")
	assert_false(BattleCoin.wants(b, me, {"kind": "skill", "skill": "blater_death_sentence"}), "아군이 쓰면 묻지 않는다")
	assert_false(BattleCoin.wants(b, b.side_units(Combatant.SIDE_ENEMY)[0], {"kind": "skill", "skill": "blater_cursed_slash"}), "다른 스킬은 동전 없음")
