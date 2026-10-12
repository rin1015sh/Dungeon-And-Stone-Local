extends TestCase
## 전투: Timeline(CTB), 피해 공식(DamageCalc), Battle(진행·스킬·방어·도주·AI).

const NO_ROLL := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}  # 명중, 치명타 없음, 편차 없음
const SLASH := {"type": "damage", "scaling": "phys", "power": 1.0, "damage_type": "slash"}


func _unit(agi: float, side: int = Combatant.SIDE_PARTY, order: int = 0) -> Combatant:
	return Combatant.new(Actor.new(db, {"agi": agi}), side, "front", order)


func _b(key: String) -> float:
	return float(db.bal("combat." + key, 0.0))


func _fresh_db() -> GameDatabase:
	var d := GameDatabase.new()
	d.load_all("res://data")
	return d


func _player() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _battle(seed_value: int, monsters: Array, party_first: bool = true, pc: PlayerCharacter = null) -> Battle:
	var party: Array[Actor] = [pc if pc != null else _player()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters, party_first)


## 양쪽 모두 AI로 끝까지 돌린다(아군은 기본 공격).
func _auto(b: Battle) -> String:
	for i in 500:
		var c := b.next_turn()
		if c == null:
			break
		b.act(c, b.ai_action(c))
	return b.result


func test_timeline_speed_ratio() -> void:
	var tl := Timeline.new(100.0, 1.0)
	var fast := _unit(20.0, 0, 0)
	var slow := _unit(10.0, 1, 1)
	tl.add(fast)
	tl.add(slow)
	var n := {fast: 0, slow: 0}
	for i in 60:
		var c := tl.next()
		n[c] = int(n[c]) + 1
		tl.consume(c)
	assert_eq(n[fast], 40, "민첩 2배 → 행동 2배")
	assert_eq(n[slow], 20)


func test_timeline_speed_base_softens_agility_gap() -> void:
	var tl := Timeline.new(100.0, 1.0, 5.0)
	var fast := _unit(20.0, 0, 0)
	var slow := _unit(10.0, 1, 1)
	tl.add(fast)
	tl.add(slow)
	var n := {fast: 0, slow: 0}
	for i in 80:
		var c := tl.next()
		n[c] = int(n[c]) + 1
		tl.consume(c)
	assert_eq(n[fast], 50, "속도 = 민첩 + 5 → 25 : 15")
	assert_eq(n[slow], 30)
	assert_eq(float(db.bal("combat.speed_base")), 5.0, "balance 기본값")


func test_timeline_delay_cost_and_min_speed() -> void:
	var tl := Timeline.new(100.0, 1.0)
	var a := _unit(10.0, 0, 0)
	var b := _unit(10.0, 1, 1)
	var zero := _unit(0.0, 1, 2)
	for u in [a, b, zero]:
		tl.add(u)
	var first := tl.next()
	assert_true(first == a, "같으면 먼저 등록된 쪽")
	tl.consume(first, 100.0)
	assert_true(tl.next() == b)
	tl.consume(b)
	assert_true(tl.next() == b, "delay_cost 100이면 상대가 한 번 더")
	tl.consume(b)
	var seen_zero := false
	for i in 300:
		var c := tl.next()
		seen_zero = seen_zero or c == zero
		tl.consume(c)
	assert_true(seen_zero, "민첩 0도 최소 속도로 언젠가 행동")


func test_preview_matches_actual() -> void:
	var tl := Timeline.new(100.0, 1.0)
	for i in 3:
		tl.add(_unit([7.0, 12.0, 19.0][i], i % 2, i))
	var predicted := tl.preview(12)
	assert_eq(predicted.size(), 12)
	var same := true
	for c in predicted:
		var actual := tl.next()
		same = same and actual == c
		tl.consume(actual)
	assert_true(same, "미리보기 = 실제 순서")


func test_damage_formula() -> void:
	var atk := Actor.new(db, {"str": 10})
	var soft := Actor.new(db, {"p_res": 0})
	var tough := Actor.new(db, {"p_res": 100})
	var base := (_b("unarmed_atk") + 10.0 * _b("phys_atk_per_str"))
	assert_eq(DamageCalc.resolve(db, atk, soft, SLASH, NO_ROLL)["amount"], roundi(base))
	assert_eq(DamageCalc.resolve(db, atk, tough, SLASH, NO_ROLL)["amount"], roundi(base * 100.0 / (100.0 + 100.0)), "방어 100 → 절반")
	var weak := DamageCalc.resolve(db, atk, soft, {"type": "damage", "power": 2.0, "damage_type": "slash"}, NO_ROLL)
	assert_eq(weak["amount"], roundi(base * 2.0), "위력 배율")
	var miss := DamageCalc.resolve(db, atk, soft, SLASH, {"hit": 0.999, "crit": 1.0, "var": 0.5, "lethal": 1.0})
	assert_false(miss["hit"], "명중 상한을 넘는 굴림은 빗나감")
	assert_eq(miss["amount"], 0)
	var crit := DamageCalc.resolve(db, atk, soft, SLASH, {"hit": 0.0, "crit": 0.0, "var": 0.5, "lethal": 1.0})
	assert_true(crit["crit"])
	assert_eq(crit["amount"], roundi(base * _b("crit_mult")))


func test_affinity_status_and_guard() -> void:
	var atk := Actor.new(db, {"str": 10})
	var wolf := Monster.create(db, "blade_wolf")
	var slash: int = DamageCalc.resolve(db, atk, wolf, SLASH, NO_ROLL)["amount"]
	var bolt: int = DamageCalc.resolve(db, atk, wolf, {"type": "damage", "damage_type": "lightning"}, NO_ROLL)["amount"]
	assert_true(bolt > slash, "칼날늑대는 번개에 약하다 (%d > %d)" % [bolt, slash])
	var d := _fresh_db()
	d.put_entry("monsters", {"id": "test_ghost", "name_ko": "시험 망령", "grade": 9, "type": "spirit", "family": ["wraith"],
		"immunities": ["physical"], "stats": {}, "resources": {"hp": 10}, "behavior": {"pack_size": [1, 1]}, "skills": [], "ai": []})
	var ghost := Monster.create(d, "test_ghost")
	assert_eq(DamageCalc.resolve(d, atk, ghost, SLASH, NO_ROLL)["amount"], 0, "영체류는 물리 면역")
	assert_true(DamageCalc.resolve(d, atk, ghost, {"type": "damage", "damage_type": "holy"}, NO_ROLL)["amount"] > 0, "다른 수단은 통한다")
	var target := Actor.new(db, {})
	var cold := {"type": "damage", "damage_type": "cold"}
	var normal: int = DamageCalc.resolve(db, atk, target, cold, NO_ROLL)["amount"]
	target.statuses.apply("hypothermia")
	assert_eq(DamageCalc.resolve(db, atk, target, cold, NO_ROLL)["amount"], normal * 2, "저체온증: 냉기 2배")
	target.statuses.remove("hypothermia")
	target.statuses.apply("guarding")
	assert_eq(DamageCalc.resolve(db, atk, target, cold, NO_ROLL)["amount"], roundi(normal * 0.5), "방어 태세: 절반")


func test_weak_point_and_lethal() -> void:
	var d := _fresh_db()
	d.put_entry("monsters", {"id": "test_skel", "name_ko": "시험 해골", "grade": 9, "type": "body", "family": ["undead"],
		"weak_point": {"name_ko": "갈비뼈 사이 핵"}, "stats": {}, "resources": {"hp": 100}, "behavior": {"pack_size": [1, 1]}, "skills": [], "ai": []})
	var atk := Actor.new(d, {"str": 10, "agi": 10})
	var skel := Monster.create(d, "test_skel")
	var plain: int = DamageCalc.resolve(d, atk, skel, SLASH, NO_ROLL)["amount"]
	var aimed := DamageCalc.resolve(d, atk, skel, SLASH, NO_ROLL, true)
	assert_true(aimed["weak"])
	assert_eq(aimed["amount"], roundi(plain * float(d.bal("combat.weak_point_damage_mult"))))
	assert_true(DamageCalc.hit_chance(d, atk, skel, true) < DamageCalc.hit_chance(d, atk, skel, false), "약점은 맞히기 어렵다")
	var lethal_roll := {"hit": 0.0, "crit": 0.0, "var": 0.5, "lethal": 0.0}
	assert_false(DamageCalc.resolve(d, atk, skel, SLASH, lethal_roll)["lethal"], "생명력이 넉넉하면 치명상 없음")
	skel.pool.set_current("hp", 30.0)
	assert_true(DamageCalc.resolve(d, atk, skel, SLASH, lethal_roll)["lethal"], "치명타로 30% 이하가 되면 급소 판정")


func test_battle_always_ends() -> void:
	for seed_value in range(1, 13):
		var r := _auto(_battle(seed_value, ["blade_wolf"], seed_value % 2 == 0))
		assert_true(r in [Battle.RESULT_VICTORY, Battle.RESULT_DEFEAT], "끝까지 진행 (시드 %d: %s)" % [seed_value, r])


func test_win_rates_print() -> void:
	for group: Array in [["goblin", "goblin"], ["blade_wolf"], ["ghoul"], ["gnome"], ["blade_wolf", "blade_wolf"]]:
		var wins := 0
		for seed_value in range(1, 31):
			if _auto(_battle(seed_value, group)) == Battle.RESULT_VICTORY:
				wins += 1
		print("    %s 상대 승률 %d/30" % [" + ".join(PackedStringArray(group)), wins])
		if group == ["goblin", "goblin"]:
			assert_true(wins >= 21, "고블린 둘은 대체로 이긴다")
		if group == ["blade_wolf"]:
			assert_true(wins >= 15, "칼날늑대 하나는 절반 이상 이긴다")


func test_skill_cost_cooldown_and_seal() -> void:
	var pc := _player()
	pc.skills.append("power_strike")
	var b := _battle(3, ["gnome"], true, pc)
	var c := b.next_turn()
	assert_true(c.actor == pc, "먼저 발견한 쪽이 먼저")
	var soul := pc.pool.get_current("soul")
	b.act(c, {"kind": "skill", "skill": "power_strike", "target": b.opponents(c)[0]})
	assert_near(pc.pool.get_current("soul"), soul - 5.0, 0.0001, "영혼력 코스트")
	var me := b.unit_of(pc)
	assert_eq(b.can_use(me, "power_strike"), "combat.reason_cooldown")
	me.cooldowns.clear()
	pc.pool.set_current("soul", 0.0)
	assert_true(pc.statuses.has("soul_exhaustion"))
	assert_eq(b.can_use(me, "power_strike"), "combat.reason_sealed", "영혼탈진이면 스킬 봉인")
	assert_eq(b.can_use(me, Battle.BASIC_ATTACK), "", "기본 공격은 된다")


func test_guard_and_flee() -> void:
	var pc := _player()
	var b := _battle(5, ["goblin"], true, pc)
	var c := b.next_turn()
	b.act(c, {"kind": "guard"})
	assert_true(pc.statuses.has("guarding"))
	var slow := b.flee_chance(c)
	pc.stats.set_base("agi", 60.0)
	assert_true(b.flee_chance(c) > slow, "민첩이 높을수록 잘 도망친다")
	for i in 40:
		var u := b.next_turn()
		if u == null:
			break
		b.act(u, {"kind": "flee"} if u.actor == pc else b.ai_action(u))
	assert_eq(b.result, Battle.RESULT_FLED)


func test_monster_ai_flees_when_hurt() -> void:
	var b := _battle(7, ["blade_wolf"], false)
	var wolf: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	wolf.actor.pool.set_current("hp", wolf.actor.pool.get_max("hp") * 0.2)
	assert_eq(b.ai_action(wolf)["skill"], "flee", "생명력 30% 이하면 도주")
	wolf.actor.pool.fill("hp")
	var picks := {}
	for i in 40:
		picks[b.ai_action(wolf)["skill"]] = true
	assert_true(picks.has("bite") and picks.has("pounce"), "확률 규칙과 기본 규칙을 섞어 쓴다")


func test_ai_and_effect_registries() -> void:
	var reg := ContentRegistries.new()
	for id: String in ["always", "hp_below", "chance"]:
		assert_true(reg.ai_conditions.has(id), id)
	for id: String in ["damage", "flee"]:
		assert_true(reg.effects.has_type(id), id)


func _keys(b: Battle) -> Array:
	var keys: Array = []
	b.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	return keys


func test_party_has_innate_talk_and_investigate() -> void:
	var pc := _player()
	assert_true(pc.skills.has("talk") and pc.skills.has("investigate"), "시작부터 대화·조사")
	PlayerCharacter.grant_innate_skills(pc)
	assert_eq(pc.skills.count("talk"), 1, "다시 줘도 중복되지 않는다")
	assert_false(pc.forget_skill("investigate"), "기본 스킬은 잊을 수 없다")
	pc.learn_skill("power_strike")
	assert_true(pc.forget_skill("power_strike"), "일반 스킬은 잊을 수 있다")
	var ally := PlayerCharacter.create(db, "human", "archer", "동료", {"agi": 5})
	assert_true(ally.skills.has("talk") and ally.skills.has("investigate"), "동료(다른 템플릿)도 가진다")
	var gob := Monster.create(db, "goblin")
	assert_false(gob.skills.has("talk"), "몬스터에게는 주지 않는다")
	for id in ["blade_wolf", "gnome", "ghoul", "goblin"]:
		assert_false(Monster.create(db, id).understands_speech(), "%s는 말이 통하지 않는다" % id)


func test_investigate_uses_a_turn() -> void:
	var pc := _player()
	var b := _battle(11, ["goblin"], true, pc)
	var keys := _keys(b)
	var c := b.next_turn()
	assert_true(c.actor == pc)
	var foe: Combatant = b.opponents(c)[0]
	var g0 := c.gauge
	assert_true(b.act(c, {"kind": "skill", "skill": "investigate", "target": foe}))
	assert_true(keys.has("combat.info_monster"), "몬스터 정보를 알려 준다")
	assert_near(c.gauge, g0 - _b("gauge_threshold"), 0.0001, "행동 게이지를 쓴다(무료 행동이 아니다)")
	assert_true(b.current == null and b.phase == Battle.PHASE_IDLE, "차례가 끝났다")
	assert_false(b.act(c, {"kind": "skill", "skill": "investigate", "target": foe}), "같은 차례에 두 번 행동할 수 없다")
	assert_true(b.next_turn() != null)


func test_talk_to_a_monster_does_nothing_but_costs_the_turn() -> void:
	var pc := _player()
	var b := _battle(12, ["blade_wolf"], true, pc)
	var keys := _keys(b)
	var c := b.next_turn()
	var wolf: Combatant = b.opponents(c)[0]
	var wolf_gauge := wolf.gauge
	var wolf_hp := wolf.actor.pool.get_current("hp")
	var g0 := c.gauge
	assert_true(b.act(c, {"kind": "skill", "skill": "talk", "target": wolf}))
	assert_true(keys.has("combat.talk_no_reply_beast"), "야수는 으르렁거릴 뿐")
	assert_near(wolf.gauge, wolf_gauge, 0.0001, "상대 게이지 그대로")
	assert_near(wolf.actor.pool.get_current("hp"), wolf_hp, 0.0001, "피해 없음")
	assert_true(wolf.is_active() and b.result.is_empty(), "전투는 계속된다")
	assert_near(c.gauge, g0 - _b("gauge_threshold"), 0.0001, "차례는 쓴다")


func test_talk_with_a_listener_has_outcomes() -> void:
	var d := _fresh_db()
	(d.get_entry("monsters", "goblin") as Dictionary)["talk"] = {"understands": true}
	var outcomes := {}
	for seed_value in range(1, 30):
		var pc := PlayerCharacter.create(d, "human", "warrior", "시험", {"str": 10, "agi": 30})
		var party: Array[Actor] = [pc]
		var b := Battle.from_encounter(d, ContentRegistries.new(), Rng.new(seed_value), party, ["goblin"], true)
		var keys := _keys(b)
		var c := b.next_turn()
		var gob: Combatant = b.opponents(c)[0]
		gob.actor.pool.set_current("hp", gob.actor.pool.get_max("hp") * 0.5)
		assert_true(b.act(c, {"kind": "skill", "skill": "talk", "target": gob}))
		for k: String in keys:
			if k.begins_with("combat.talk_"):
				outcomes[k] = true
	assert_false(outcomes.has("combat.talk_no_reply"), "말이 통하면 무반응이 아니다")
	assert_true(outcomes.size() >= 2, "결과가 여러 가지다: %s" % str(outcomes.keys()))


func test_invalid_actions_do_not_use_the_turn() -> void:
	var pc := _player()
	var b := _battle(13, ["goblin", "goblin"], true, pc)
	var c := b.next_turn()
	var g0 := c.gauge
	assert_false(b.act(c, {"kind": "skill", "skill": "power_strike"}), "모르는 스킬")
	assert_false(b.act(c, {"kind": "skill", "skill": "investigate", "target": null}), "조사 대상 없음")
	var dead: Combatant = b.opponents(c)[0]
	dead.actor.kill("test")
	assert_false(b.act(c, {"kind": "skill", "skill": "investigate", "target": dead}), "사라진 대상은 조사할 수 없다")
	assert_false(b.act(c, {"kind": "item", "item": "torch"}), "전투용이 아닌 아이템")
	assert_false(b.act(c, {"kind": "dance"}), "없는 행동")
	assert_false(b.act(b.opponents(c)[0], {"kind": "guard"}), "남의 차례에는 행동할 수 없다")
	assert_true(b.current == c and b.phase == Battle.PHASE_AWAIT and is_equal_approx(c.gauge, g0), "차례가 그대로 남는다")
	assert_true(b.next_turn() == c, "기다리는 차례를 건너뛰지 않는다")
	assert_true(b.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": dead}), "쓰러진 적을 노리면 다른 적을 친다")


func test_party_and_monsters_act_in_agility_order() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "빠름", {"str": 10, "agi": 12})
	var ally := PlayerCharacter.create(db, "human", "archer", "느림", {"str": 10, "agi": 2})
	var party: Array[Actor] = [pc, ally]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(4), party, ["goblin", "blade_wolf"], true)
	for u in b.units:
		u.gauge = 0.0
	var expected := b.units.duplicate()
	expected.sort_custom(func(x: Combatant, y: Combatant) -> bool: return x.speed(1.0) > y.speed(1.0))
	var speeds := expected.map(func(u: Combatant) -> float: return u.speed(1.0))
	assert_true(speeds[0] > speeds[1] and speeds[1] > speeds[2] and speeds[2] > speeds[3], "민첩이 서로 다르다 %s" % str(speeds))
	var order: Array[Combatant] = []  # 처음 행동한 순서
	var count := {}
	for i in 40:
		var c := b.next_turn()
		if not order.has(c):
			order.append(c)
		count[c] = int(count.get(c, 0)) + 1
		assert_true(b.act(c, {"kind": "guard"}))
	assert_eq(order, expected, "아군·몬스터 구분 없이 민첩이 높은 순서로 첫 행동")
	var party_turns := 0
	for c: Combatant in order:
		if c.side == Combatant.SIDE_PARTY:
			party_turns += 1
	assert_eq(party_turns, 2, "아군 둘 다 행동한다")
	assert_true(int(count[expected[0]]) > int(count[expected[3]]) * 2, "빠를수록 더 자주 행동한다")
