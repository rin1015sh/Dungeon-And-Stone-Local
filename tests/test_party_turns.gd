extends TestCase
## 파티 전투의 민첩 추가 차례(C12)와 플레이어만 하는 행동(C13 — 대화·조사·도주).


func _pc(name: String, agi: int) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", name, {"str": 10, "agi": agi, "p_res": 30, "m_res": 10, "int": 6})
	pc.pool.fill_all()
	return pc


func _battle(fast_first: bool = true) -> Battle:
	var fast := _pc("빠름", 40)
	var slow := _pc("느림", 4)
	var party: Array[Actor] = []
	party.append_array([fast, slow] if fast_first else [slow, fast])
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(9), party, ["goblin"], Combatant.SIDE_PARTY)


func _unit(b: Battle, name: String) -> Combatant:
	for u in b.side_units(Combatant.SIDE_PARTY):
		if u.label() == name:
			return u
	return null


## 화면의 흐름(CombatScreen._loop)대로: 아군 차례에 정해 둔 행동이 없으면 PlanOrder.who로 정하고, 차례가 오면 쓴다.
func _run(b: Battle, turns: int) -> Array:
	var plan := {}
	var asked: Array = []  # [[지금 차례, [정한 사람들]], …]
	for i in turns:
		var c := b.next_turn()
		if c == null:
			break
		if b.is_player_controlled(c):
			if not plan.has(c):
				var who := PlanOrder.who(b, c, plan)
				asked.append([c, who, c.extra_turn])
				for u: Combatant in who:
					plan[u] = {"kind": "guard"}
			b.act(c, plan[c])
			plan.erase(c)
		else:
			b.act(c, {"kind": "guard"})
	return asked


func test_extra_turn_plans_only_that_ally() -> void:
	for fast_first: bool in [true, false]:
		var b := _battle(fast_first)
		var fast := _unit(b, "빠름")
		var slow := _unit(b, "느림")
		var asked := _run(b, 24)
		var alone := 0
		for a: Array in asked:
			var who: Array = a[1]
			assert_eq(who[0], a[0], "지금 차례인 사람을 먼저 정한다")
			assert_eq(who.count(a[0]), 1)
			if who.size() == 1:
				alone += 1
				assert_eq(a[0], fast, "혼자 정하는 건 추가 차례가 온 빠른 사람")
				assert_true(bool(a[2]), "그 차례는 추가 차례로 표시된다(파티 창 이름 옆, C14)")
			if a[0] == slow:
				assert_false(bool(a[2]), "느린 사람은 추가 차례가 없다")
		assert_true(alone >= 1, "빠른 사람이 느린 사람보다 먼저 한 번 더 온다(%s)" % fast_first)
		assert_true(asked.any(func(a: Array) -> bool: return (a[1] as Array).has(slow)), "느린 사람도 정한다")


func test_only_leader_talks_investigates_flees() -> void:
	var b := _battle()
	var lead := _unit(b, "빠름")
	var mate := _unit(b, "느림")
	assert_eq(b.leader(), lead, "먼저 들어온 사람 = 플레이어")
	var foe: Combatant = b.side_units(Combatant.SIDE_ENEMY)[0]
	for sid: Variant in db.bal("party.innate_skills", []):
		assert_true(mate.actor.skills.has(str(sid)), "동료도 배운 채지만")
		assert_eq(b.can_use(mate, str(sid)), "combat.reason_leader_only", str(sid) + "는 플레이어만")
		assert_eq(b.can_use(lead, str(sid)), "", str(sid))
		assert_eq(ActionCheck.reason(b, mate, {"kind": "skill", "skill": str(sid), "target": foe}), "combat.reason_leader_only")
	assert_eq(ActionCheck.reason(b, mate, {"kind": "flee"}), "combat.reason_leader_only", "도주는 플레이어만")
	assert_eq(ActionCheck.reason(b, lead, {"kind": "flee"}), "")
