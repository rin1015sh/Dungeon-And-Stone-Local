extends TestCase
## 상태이상 전수 점검(사용자 요청 2026-10-24 "전투 안에서 상태이상이 제대로 작동하는지 검토"):
## data/statuses.json의 모든 상태를 실제 전투 개체에 걸어, 정의한 키마다 규칙이 그대로 일어나는지 본다 —
## 걸림 · 수정자(스탯·최대치·받는 피해) · 지속(차례·시간) · 주기 효과 · 전투 끝 정리(battle_only·lingers) ·
## 피해로 풀림 · 최대 중첩 변환 · 면역 부여 · 풀린 뒤 면역 · 보호막 · 반격 · 치유 배율 · 플래그(기절·봉인·속박·은신·필중·도발·재생 막음·분열 막음).


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 30, "p_res": 12, "m_res": 8, "int": 10})
	pc.set_level(3)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array = ["goblin"], pc: PlayerCharacter = null) -> Battle:
	var party: Array[Actor] = [pc if pc != null else _pc()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(5), party, monsters, Combatant.SIDE_PARTY)


func _statuses() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in db.get_collection("statuses"):
		var d := db.get_entry("statuses", id)
		if not JsonUtil.get_str(d, "meal").is_empty():
			continue  # 여관 요리는 test_meals
		out.append(d)
	return out


## 상태를 받을 개체: 버프는 탐험가, 디버프는 고블린.
func _holder(b: Battle, def: Dictionary) -> Combatant:
	return b.side_units(Combatant.SIDE_PARTY)[0] if JsonUtil.get_str(def, "kind") == "buff" else b.side_units(Combatant.SIDE_ENEMY)[0]


func test_every_status_applies_and_modifies() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var id := JsonUtil.get_str(def, "id")
		var b := _battle()
		var a := _holder(b, def).actor
		var before := {}
		for m: Variant in JsonUtil.get_array(def, "modifiers"):
			var t := JsonUtil.get_str(m, "target")
			if a.stats.has_stat(t):
				before[t] = a.stats.get_value(t)
			elif t.begins_with("max:"):
				before[t] = a.pool.get_max(t.trim_prefix("max:"))
		if not a.statuses.apply(id):
			if not def.has("immune_if"):
				bad.append("%s: 걸리지 않는다" % id)
			continue
		for t: String in before:
			var now := a.pool.get_max(t.trim_prefix("max:")) if t.begins_with("max:") else a.stats.get_value(t)
			if is_equal_approx(now, float(before[t])) and not _formula_zero(def, t, a):
				bad.append("%s: 수정자 %s가 바뀌지 않는다(%.2f)" % [id, t, now])
	assert_eq(bad.size(), 0, "\n".join(bad))


## 수식 수정자가 지금 스탯으로 0이 되는 경우(저체온증 — 냉기 내성이 높으면 0)는 넘어간다.
func _formula_zero(def: Dictionary, target: String, a: Actor) -> bool:
	for m: Variant in JsonUtil.get_array(def, "modifiers"):
		if JsonUtil.get_str(m, "target") == target and ((m as Dictionary).get("percent") is String or (m as Dictionary).get("flat") is String):
			return true
	return a == null


func test_every_timed_status_wears_off() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var dur := JsonUtil.get_dict(def, "duration")
		if dur.is_empty():
			continue
		var id := JsonUtil.get_str(def, "id")
		var b := _battle()
		var a := _holder(b, def).actor
		a.pool.set_current("hp", a.pool.get_max("hp"))
		if not a.statuses.apply(id):
			continue
		var n := JsonUtil.get_float(dur, "amount")
		match JsonUtil.get_str(dur, "unit", "turn"):
			"turn":
				for i in int(ceil(n)) + 1:
					a.statuses.tick_turns(1.0)
			"hour":
				a.statuses.tick_hours(n + 0.5)
			"battle":
				for i in int(n) + 1:
					a.statuses.end_battle()
		if a.statuses.has(id):
			bad.append("%s: %s %s 뒤에도 남는다" % [id, n, JsonUtil.get_str(dur, "unit", "turn")])
	assert_eq(bad.size(), 0, "\n".join(bad))


func test_periodic_effects_tick() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var per := JsonUtil.get_array(def, "periodic")
		if per.is_empty():
			continue
		var id := JsonUtil.get_str(def, "id")
		var b := _battle(["hobgoblin"])
		var a := _holder(b, def).actor
		var p: Dictionary = per[0]
		var res := JsonUtil.get_str(p, "resource")
		a.pool.set_current(res, a.pool.get_max(res) * 0.5)
		if not a.statuses.apply(id):
			continue
		var was := a.pool.get_current(res)
		if JsonUtil.get_str(p, "trigger") == "time":
			a.statuses.tick_hours(1.0)
		else:
			a.statuses.tick_turns(1.0)
		if is_equal_approx(a.pool.get_current(res), was):
			bad.append("%s: 주기 효과(%s)가 %s를 바꾸지 않는다" % [id, JsonUtil.get_str(p, "trigger"), res])
	assert_eq(bad.size(), 0, "\n".join(bad))


func test_battle_end_cleanup() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var id := JsonUtil.get_str(def, "id")
		var b := _battle()
		var a := _holder(b, def).actor
		if not a.statuses.apply(id):
			continue
		BattleRules.cleanup(b)
		var turn := JsonUtil.get_str(JsonUtil.get_dict(def, "duration"), "unit", "") == "turn"
		var should_go := JsonUtil.get_bool(def, "battle_only") or (turn and not JsonUtil.get_bool(def, "lingers"))
		if should_go and a.statuses.has(id):
			bad.append("%s: 전투가 끝나도 남는다" % id)
		if not should_go and not a.statuses.has(id):
			bad.append("%s: 전투가 끝나면 사라진다(lingers·시간 단위인데)" % id)
	assert_eq(bad.size(), 0, "\n".join(bad))


func test_special_keys() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var id := JsonUtil.get_str(def, "id")
		var b := _battle()
		var a := _holder(b, def).actor
		if def.has("break_on_damage") or def.has("break_on_damage_types"):
			a.statuses.apply(id)
			var types := JsonUtil.get_array(def, "break_on_damage_types")
			a.statuses.on_damaged(str(types[0]) if not types.is_empty() else "slash")
			if a.statuses.has(id):
				bad.append("%s: 피해를 받아도 풀리지 않는다" % id)
		if def.has("on_max_stacks"):
			var into := JsonUtil.get_str(JsonUtil.get_dict(def, "on_max_stacks"), "status")
			for i in JsonUtil.get_int(def, "max_stacks", 3) + 1:
				a.statuses.apply(id)
			if not a.statuses.has(into):
				bad.append("%s: 최대 중첩에서 %s로 바뀌지 않는다" % [id, into])
		for im: Variant in JsonUtil.get_array(def, "grants_immunity"):
			var c := _battle()
			var a2 := _holder(c, def).actor
			a2.statuses.apply(id)
			if a2.statuses.apply(str(im)):
				bad.append("%s: 걸린 동안 %s에 면역이어야 한다" % [id, im])
		if def.has("after_immune"):
			var c := _battle()
			var a3 := _holder(c, def).actor
			a3.statuses.apply(id)
			a3.statuses.remove(id)
			if a3.statuses.apply(id):
				bad.append("%s: 풀린 직후 다시 걸린다(after_immune)" % id)
		if JsonUtil.get_bool(def, "barrier"):
			var c := _battle()
			var a4 := _holder(c, def).actor
			a4.statuses.apply(id)
			a4.statuses.set_barrier(id, 30.0)
			if a4.statuses.absorb(20) != 0 or a4.statuses.absorb(20) != 10:
				bad.append("%s: 보호막이 피해를 먼저 받지 않는다" % id)
		if def.has("counter"):
			var c := _battle()
			var a5 := _holder(c, def).actor
			a5.statuses.apply(id)
			if a5.statuses.counter_power() <= 0.0:
				bad.append("%s: 반격 위력이 없다" % id)
		if def.has("heal_mult"):
			var c := _battle()
			var a6 := _holder(c, def).actor
			a6.statuses.apply(id)
			if is_equal_approx(a6.statuses.heal_mult(), 1.0):
				bad.append("%s: 치유 배율이 그대로다" % id)
	assert_eq(bad.size(), 0, "\n".join(bad))


func test_flags_in_battle() -> void:
	var bad := PackedStringArray()
	for def in _statuses():
		var id := JsonUtil.get_str(def, "id")
		for flag: Variant in JsonUtil.get_array(def, "flags"):
			var err := _flag(id, str(flag))
			if not err.is_empty():
				bad.append("%s(%s): %s" % [id, flag, err])
	assert_eq(bad.size(), 0, "\n".join(bad))


## 플래그 하나가 전투에서 실제로 먹히는지. 문제가 없으면 "".
func _flag(id: String, flag: String) -> String:
	var b := _battle(["goblin", "goblin"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var foe := b.side_units(Combatant.SIDE_ENEMY)[0]
	match flag:
		"skip_turn":  # 빠른 개체는 건너뛴 뒤 곧바로 또 차례가 올 수 있다 — "건너뜀"이 일어났는지로 본다
			me.actor.statuses.apply(id)
			return "" if _skips(b) > 0 else "차례를 건너뛰지 않는다"
		"may_skip_turn":
			var skipped := 0
			for i in 60:
				var c := _battle(["goblin"])
				c.side_units(Combatant.SIDE_PARTY)[0].actor.statuses.apply(id)
				c.rng = Rng.new(i)
				if _skips(c) > 0:
					skipped += 1
			return "한 번도 못 움직인 적이 없다" if skipped == 0 else ("늘 못 움직인다" if skipped == 60 else "")
		"no_skills":
			me.actor.statuses.apply(id)
			var sk := ""
			for s: String in me.actor.skills:
				if s != Battle.BASIC_ATTACK and not JsonUtil.get_bool(db.get_entry("skills", s), "innate"):
					sk = s
			if sk.is_empty():
				me.actor.skills.append("power_strike")
				sk = "power_strike"
			b.next_turn()
			return "스킬이 막히지 않는다" if b.can_use(me, sk).is_empty() else ""
		"no_flee":
			me.actor.statuses.apply(id)
			return "도망칠 수 있다" if b.flee_chance(me) > 0.0 else ""
		"untargetable":
			foe.actor.statuses.apply(id)
			return "고를 수 있다" if BattleRules.is_targetable(b, me, foe) else ""
		"always_hit":
			foe.actor.statuses.apply(id)
			me.actor.stats.set_base("accuracy", -200.0)
			return "빗나갈 수 있다" if DamageCalc.hit_chance(db, me.actor, foe.actor) < 1.0 else ""
		"draws_attacks":
			var mate := PlayerCharacter.create(db, "human", "warrior", "동료", {"str": 9, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
			var lure := b.add(mate, Combatant.SIDE_PARTY)
			lure.actor.statuses.apply(id)
			var hits := 0
			for i in 40:
				b.rng = Rng.new(i)
				var act := b.ai_action(foe)
				if act.get("target") == lure:
					hits += 1
			return "끌어들이지 못한다(%d/40)" % hits if hits <= 20 else ""
		"no_regen":
			foe.actor.statuses.apply(id)
			foe.actor.passives.append({"id": "test_regen", "regen_per_round": 0.2})
			foe.actor.pool.set_current("hp", 1.0)
			BattlePassives.turn_end(b, foe)
			return "재생이 멈추지 않는다" if foe.actor.pool.get_current("hp") > 1.0 else ""
		"no_split":
			foe.actor.statuses.apply(id)
			var n := b.side_units(Combatant.SIDE_ENEMY).size()
			BattleSpawns.split(b, foe, {})
			return "갈라진다" if b.side_units(Combatant.SIDE_ENEMY).size() > n else ""
		"no_ally_single":
			me.actor.statuses.apply(id)
			return ""  # 아군 한 명에게 거는 스킬을 막는다 — ActionCheck(아군 지정 스킬이 있는 직업에서 test_status_redesign)
	return "점검하지 않은 플래그"


## 스킬이 거는 상태가 실제로 걸리는가(효과 처리기 apply_status → Passives.try_status → 저항·면역). 확률은 빼고 시드 20번.
## 그 스킬을 가진 몬스터가 시전자(없으면 탐험가), 대상은 고블린(디버프)·시전자 자신("to": "self"·버프).
func test_skill_statuses_land() -> void:
	var bad := PackedStringArray()
	var owner := {}
	for mid: String in db.get_collection("monsters"):
		for sk: Variant in JsonUtil.get_array(db.get_entry("monsters", mid), "skills"):
			owner[str(sk)] = mid
	var reg := ContentRegistries.new()
	for sid: String in db.get_collection("skills"):
		for e: Variant in JsonUtil.get_array(db.get_entry("skills", sid), "effects"):
			var ed: Dictionary = e if e is Dictionary else {}
			if JsonUtil.get_str(ed, "type") != "apply_status" or ed.has("if_target_status"):
				continue
			var data := ed.duplicate()
			data.erase("chance")
			var landed := 0
			for i in 20:
				var caster: Actor = Monster.create(db, str(owner[sid]), "시전자") if owner.has(sid) else _pc()
				var target: Actor = Monster.create(db, "goblin", "대상")
				var buff := JsonUtil.get_str(db.get_entry("statuses", JsonUtil.get_str(data, "status")), "kind") == "buff"
				var ctx := EffectContext.new(db, caster, caster if buff else target, Rng.new(i * 7 + 1))
				ctx.registry = reg.effects
				reg.effects.apply_all(ctx, [data])
				var who := caster if buff or JsonUtil.get_str(data, "to") == "self" else target
				if who.statuses.has(JsonUtil.get_str(data, "status")) or not JsonUtil.get_str(JsonUtil.get_dict(db.get_entry("statuses", JsonUtil.get_str(data, "status")), "on_max_stacks"), "status").is_empty():
					landed += 1
			if landed == 0:
				bad.append("%s: %s가 한 번도 걸리지 않는다" % [sid, JsonUtil.get_str(data, "status")])
	assert_eq(bad.size(), 0, "\n".join(bad))


## 첫 차례를 하나 받을 때까지 "건너뜀"이 몇 번 일어났는가.
func _skips(b: Battle) -> int:
	var n := [0]
	var count := func(k: String, _a: Dictionary, _kind: String) -> void:
		if k == "combat.skip":
			n[0] += 1
	b.message.connect(count)
	b.next_turn()
	b.message.disconnect(count)
	return n[0]


## 미궁을 나오면 남은 상태가 도시로 따라오지 않는다(독·출혈·저주가 순이 지나도 그대로 있다가 다음 원정에 이어지던 것).
func test_statuses_cleared_when_leaving_dungeon() -> void:
	var pc := _pc()
	pc.statuses.apply("poison")
	pc.statuses.apply("tomb_curse")
	pc.statuses.apply("grudge_mark")
	pc.statuses.leave_dungeon()
	assert_true(pc.statuses.ids().is_empty(), "남은 상태 %s" % [pc.statuses.ids()])


## 머리 위 아이콘(UI24): 요리가 아닌 상태마다 제 그림, 요리·표에 없는 상태용 meal·buff·debuff — tools/paint_status_icons.gd로 그린다.
func test_every_status_has_icon() -> void:
	var need: Array[String] = ["meal", "buff", "debuff"]
	for d: Dictionary in _statuses():
		need.append(JsonUtil.get_str(d, "id"))
	for id in need:
		assert_true(FileAccess.file_exists("res://assets/statuses/%s.webp" % id), "상태 아이콘 없음: " + id)
