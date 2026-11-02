extends TestCase
## Rev Up(C20): 아군만 차례마다 차고(상한), 방어하면 더 차고, 피해 스킬에 얹으면 위력이 오르고, 다 얹은 기본 공격은 두 번.


func _pc(name: String) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", name, {"str": 30, "agi": 200, "p_res": 30, "m_res": 10, "int": 6})
	pc.pool.fill_all()
	return pc


func _battle(seed: int = 9) -> Battle:
	var party: Array[Actor] = [_pc("탐험가")]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed), party, ["blater"], Combatant.SIDE_PARTY)


## 아군 차례가 올 때까지 돌린다(적은 방어).
func _to_party(b: Battle) -> Combatant:
	for i in 40:
		var c := b.next_turn()
		if c == null:
			return null
		if b.is_player_controlled(c):
			return c
		b.act(c, {"kind": "guard"})
	return null


func _hits(b: Battle, action: Dictionary) -> Array[int]:
	var out: Array[int] = []
	var grab := func(e: Dictionary) -> void:
		if str(e.get("type")) == "damage" and (e.get("unit") as Combatant) != null and (e.get("unit") as Combatant).side == Combatant.SIDE_ENEMY:
			out.append(int(e.get("amount", 0)))
	b.event.connect(grab)
	var c := _to_party(b)
	assert_true(b.act(c, action), "행동이 들어간다")
	b.event.disconnect(grab)
	return out


func test_charge_cap_and_guard() -> void:
	var b := _battle()
	var cap := BattleRev.cap(db)
	var c := _to_party(b)
	assert_eq(c.rev, 1, "첫 차례에 하나")
	b.act(c, {"kind": "guard"})
	assert_eq(c.rev, 2, "방어하면 하나 더")
	for i in 6:
		c = _to_party(b)
		b.act(c, {"kind": "guard"})
	assert_eq(c.rev, cap, "상한까지만")
	for u in b.side_units(Combatant.SIDE_ENEMY):
		assert_eq(u.rev, 0, "적은 Rev가 없다")


func test_rev_multiplies_damage() -> void:
	var plain := _hits(_battle(), {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null})
	var b := _battle()
	var c := _to_party(b)
	c.rev = 2
	var revved: Array[int] = []
	var grab := func(e: Dictionary) -> void:
		if str(e.get("type")) == "damage" and (e.get("unit") as Combatant) != null and (e.get("unit") as Combatant).side == Combatant.SIDE_ENEMY:
			revved.append(int(e.get("amount", 0)))
	b.event.connect(grab)
	assert_true(b.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null, "rev": 2}))
	b.event.disconnect(grab)
	assert_eq(plain.size(), 1)
	assert_eq(revved.size(), 1)
	if plain.size() == 1 and revved.size() == 1 and plain[0] > 0:
		assert_near(float(revved[0]) / float(plain[0]), BattleRev.power(db, 2), 0.05, "위력 × power[2]")
	assert_eq(c.rev, 0, "얹은 만큼 쓴다")


func test_full_rev_basic_attack_hits_twice() -> void:
	var b := _battle()
	var c := _to_party(b)
	c.rev = BattleRev.cap(db)
	var n := [0]
	var grab := func(e: Dictionary) -> void:
		if str(e.get("type")) == "damage" and (e.get("unit") as Combatant) != null and (e.get("unit") as Combatant).side == Combatant.SIDE_ENEMY:
			n[0] += 1
	b.event.connect(grab)
	b.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null, "rev": BattleRev.cap(db)})
	b.event.disconnect(grab)
	assert_eq(n[0], int(db.bal("combat.rev.basic_full_hits", 2)), "다 얹은 기본 공격은 두 번")
	assert_eq(c.rev, 0)


func test_no_rev_on_guard_and_overask() -> void:
	var b := _battle()
	var c := _to_party(b)
	b.act(c, {"kind": "guard", "rev": 3})
	assert_eq(c.rev, 2, "방어에는 얹지 않는다(차기만 한다)")
	c = _to_party(b)
	assert_eq(c.rev, 3)
	b.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null, "rev": 9})
	assert_eq(c.rev, 0, "가진 만큼만 쓴다")
	assert_true(BattleRev.applies(db.get_entry("skills", Battle.BASIC_ATTACK)))


func test_plan_max_counts_coming_charge() -> void:
	var b := _battle()
	var c := _to_party(b)
	assert_eq(BattleRev.plan_max(b, c), 1, "지금 차례면 가진 만큼")
	b.act(c, {"kind": "guard"})
	assert_eq(BattleRev.plan_max(b, c), mini(BattleRev.cap(db), 3), "차례가 아직이면 그때 찰 것까지")
