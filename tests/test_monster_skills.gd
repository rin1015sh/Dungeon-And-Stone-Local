extends TestCase
## 몬스터 스킬 전수 검사(2026-11-01 사용자 "몬스터 스킬이 잘 작동하는지"): 몬스터가 가진 스킬(+ AI 규칙·순환에 적힌 스킬)마다
## 실제 전투에서 한 번 써 보고 전장 상태(생명력·영혼력·상태·게이지·대열·능력치·참가자 수 — 시전자의 비용은 빼고)가 바뀌는지.
## 확률 스킬(상태 확률·영혼 베기)은 시드를 바꿔 가며 최대 TRIES번. AI가 실전에서 스킬을 꺼내 쓰는지는 tools/sim_skills.gd.

const TRIES := 40


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(6)
	pc.pool.fill_all()
	pc.skills.append("ess_deadman_grab")  # 봉인 문양이 막을 스킬
	return pc


## 전장 상태 한 줄씩(시전자의 비용·쿨타임은 뺀다 — 비용만 치르고 아무 일도 없던 스킬을 잡으려고).
func _snap(b: Battle, caster: Combatant) -> String:
	var parts: Array[String] = [str(b.units.size())]
	for u in b.units:
		var st: Array = []
		for id in u.actor.statuses.ids():
			st.append("%s:%d" % [id, u.actor.statuses.stacks(id)])
		var pool: Array = []
		for r in u.actor.pool.ids():
			if u != caster or r == "hp":
				pool.append("%s=%.2f/%.2f" % [r, u.actor.pool.get_current(r), u.actor.pool.get_max(r)])
		var stats: Array = []
		for s in u.actor.stats.ids():
			stats.append("%.2f" % u.actor.stats.get_value(s))
		parts.append("%s|%s|%s|%s|%s|%s|%.2f|%s|%s|%s" % [u.label(), u.row, str(u.actor.dead), str(pool), str(st),
			str(u.actor.meters), u.gauge, str(u.memo.keys()), str(stats), str(u.fled)])
	return "\n".join(parts)


func _skills_of(m: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var add := func(s: String) -> void:
		if s != Battle.BASIC_ATTACK and not s.is_empty() and not out.has(s):
			out.append(s)
	for s in JsonUtil.get_array(m, "skills"):
		add.call(str(s))
	for r in JsonUtil.get_array(m, "ai"):
		add.call(JsonUtil.get_str(r if r is Dictionary else {}, "use"))
	for s in JsonUtil.get_array(m, "ai_cycle"):
		add.call(str(s))
	return out


## 한 번 써 보고 상태가 바뀌었는가.
func _works(mid: String, sid: String, seed: int) -> bool:
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(seed))
	for i in 3:
		b.add(_pc(), Combatant.SIDE_PARTY, "front" if i < 2 else "back")
	var mon := b.add(Monster.create(db, mid), Combatant.SIDE_ENEMY)
	var mate := b.add(Monster.create(db, "goblin"), Combatant.SIDE_ENEMY)  # 아군에게 거는 스킬·흡수
	b.start()
	mate.actor.pool.set_current("hp", mate.actor.pool.get_max("hp") * 0.5)
	mon.actor.pool.set_current("hp", mon.actor.pool.get_max("hp") * 0.6)  # 회복 스킬도 차이가 보이게
	var tgt: Variant = mate if JsonUtil.get_str(db.get_entry("skills", sid), "target") == "ally_single" else null
	var before := _snap(b, mon)
	b._use_skill(mon, sid, tgt, false)
	b._after_effects()
	return _snap(b, mon) != before


func test_every_monster_skill_does_something() -> void:
	var count := 0
	for mid: String in db.get_collection("monsters").keys():
		for sid in _skills_of(db.get_entry("monsters", mid)):
			count += 1
			assert_true(db.has_entry("skills", sid), "%s: 스킬 %s 데이터" % [mid, sid])
			if not db.has_entry("skills", sid):
				continue
			var ok := false
			for t in TRIES:
				if _works(mid, sid, hash("%d%s%s" % [t, mid, sid]) % 1000000 + 1):
					ok = true
					break
			assert_true(ok, "%s의 %s — %d번 써도 전장에 아무 일도 없다" % [mid, sid, TRIES])
	assert_true(count > 100, "몬스터 스킬 %d개" % count)


## 데스핀드: 방패팔 막기(다음 자기 차례까지)는 차례가 오면 끝나 "막는 중이 아니면" 조건이 늘 참이었다 — 생명력 절반 아래에서 막기만 되풀이(재사용 2차례로 고침).
func test_deathfiend_does_not_only_shield() -> void:
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(5))
	b.add(_pc(), Combatant.SIDE_PARTY)
	var df := b.add(Monster.create(db, "deathfiend"), Combatant.SIDE_ENEMY)
	b.start()
	df.acted = 1
	var seq: Array[String] = []
	for i in 6:
		df.actor.pool.set_current("hp", df.actor.pool.get_max("hp") * 0.3)
		df.actor.pool.fill("soul")
		df.was_hit = true
		var a := b.ai_action(df)
		seq.append(str(a.get("skill", "")))
		b._use_skill(df, str(a["skill"]), a.get("target"), false)
		df.actor.advance_turns(1.0)
		df.tick_cooldowns()
		df.acted += 1
	assert_true(seq.has("deathfiend_halfmoon"), "막기 사이에 반월 베기 (%s)" % str(seq))
	for i in seq.size() - 1:
		assert_false(seq[i] == "deathfiend_shield_arm" and seq[i + 1] == "deathfiend_shield_arm", "막기를 잇달아 쓰지 않는다 (%s)" % str(seq))
