class_name BattleRules
extends RefCounted
## Battle을 돕는 규칙 모음(Battle.gd를 짧게 유지): 은신 대상 고르기, 증원, 전투 시작 선공, 전투당 사용 횟수, 도주 확률,
## 공포의 행동 실패, 전투 종료 정리(게이지·전투 한정 상태), 효과 사건 반영.


## c가 고를 수 있는 상대: 은신(untargetable)은 빼되, 고를 수 있는 상대가 하나도 없으면 전부.
## 은신을 꿰뚫는 패시브(see_hidden)가 있으면 전부.
static func targetable(b: Battle, c: Combatant) -> Array[Combatant]:
	var foes := b.opponents(c)
	if Passives.has_flag(c.actor, "see_hidden"):
		return foes
	var out: Array[Combatant] = []
	for f in foes:
		if not f.actor.statuses.has_flag("untargetable"):
			out.append(f)
	return out if not out.is_empty() else foes


static func is_targetable(b: Battle, c: Combatant, t: Combatant) -> bool:
	return targetable(b, c).has(t)


## 전투 시작: 패시브 start_gauge(첫 차례 선공)를 더한다.
static func on_start(b: Battle) -> void:
	BattlePassives.on_start(b)
	for u in b.units:
		u.gauge += Passives.sum(u.actor, "start_gauge")


## 전투 목표를 정한다(화면이 조우의 battle_rules로). enemy_statuses(수수께끼 문지기 약화·강화)는 적 전원에게 건다
## (나중에 들어오는 증원·소환에도 — joined).
static func set_objective(b: Battle, rules: Dictionary) -> void:
	b.objective = rules.duplicate()
	for u in b.side_units(Combatant.SIDE_ENEMY):
		_objective_statuses(b, u)


static func _objective_statuses(b: Battle, u: Combatant) -> void:
	if u.side != Combatant.SIDE_ENEMY:
		return
	for st: Variant in JsonUtil.get_array(b.objective, "enemy_statuses"):
		Passives.try_status(b.db, null, null, u.actor, str(st))


## 전투 중에 새 개체가 들어왔다(소환·분열·증원): 소환수 표시, 전투 시작 처리(몬스터 타입·보스 패턴·목표 상태·도감).
static func joined(b: Battle, u: Combatant) -> void:
	u.summoned = true
	_objective_statuses(b, u)
	BattlePassives.on_join(b, u)
	BossHooks.on_join(b, u)
	BattleKnowledge.see(b, u)


## 공격 스킬을 한 번 썼다: 공격자의 consume_on_attack 상태(진군 명령·기습)를 푼다.
static func consume_on_attack(b: Battle, c: Combatant) -> void:
	for st in c.actor.statuses.ids():
		if JsonUtil.get_bool(b.db.get_entry("statuses", st), "consume_on_attack"):
			c.actor.statuses.remove(st)


## 전투당 사용 횟수(skill "uses_per_battle")가 남았는가.
static func uses_left(b: Battle, c: Combatant, skill_id: String) -> bool:
	var limit := JsonUtil.get_int(b.db.get_entry("skills", skill_id), "uses_per_battle", 0)
	return limit <= 0 or int(c.uses.get(skill_id, 0)) < limit


## 도주 확률(명세 §1): flee_base + (아군 평균 민첩 − 적 평균 민첩)×flee_agi_coef, flee_min~flee_max.
## 수호자·계층군주(combat.no_flee_ranks)가 상대에 있거나 속박(no_flee)이면 0. 상대 패시브 flee_penalty만큼 깎는다.
static func flee_chance(b: Battle, c: Combatant) -> float:
	if c.actor.statuses.has_flag("no_flee"):
		return 0.0
	var no_flee: Array = b.db.bal("combat.no_flee_ranks", [])
	var pen := 0.0
	for o in b.opponents(c):
		if o.actor is Monster and JsonUtil.get_str((o.actor as Monster).def, "rank") in no_flee:
			return 0.0
		pen += Passives.sum(o.actor, "flee_penalty")
	var k := float(b.db.bal("combat.flee_base", 0.5)) \
		+ (_avg_agi(b.side_units(c.side)) - _avg_agi(b.opponents(c))) * float(b.db.bal("combat.flee_agi_coef", 0.02))
	return clampf(k - pen, float(b.db.bal("combat.flee_min", 0.1)), float(b.db.bal("combat.flee_max", 0.9)))


static func _avg_agi(list: Array[Combatant]) -> float:
	if list.is_empty():
		return 0.0
	var s := 0.0
	for u in list:
		s += u.actor.stats.get_value("agi")
	return s / float(list.size())


## 공포(flag may_skip_turn): 차례마다 combat.may_skip_chance 확률로 움직이지 못한다.
static func fear_skip(b: Battle, c: Combatant) -> bool:
	return c.actor.statuses.has_flag("may_skip_turn") and b.rng.chance(float(b.db.bal("combat.may_skip_chance", 0.3)))


## 전투가 끝났다: 게이지·전투 표식·오러를 비우고, 전투 한정 상태(statuses "battle_only": true)와
## 차례 단위 일시 상태(속박·방어 태세·기절 …)를 지운다. "lingers": true인 상태(독·출혈 …)는 남는다(StatusSet.clear_temporary).
static func cleanup(b: Battle) -> void:
	for u in b.units:
		u.actor.meters.clear()
		for meta: String in [Passives.REVIVED_META, Passives.MARKED_META]:
			if u.actor.has_meta(meta):
				u.actor.remove_meta(meta)
		u.actor.stats.remove_source_prefix(BattlePassives.AURA_SOURCE)
		for id in u.actor.statuses.ids():
			if JsonUtil.get_bool(b.db.get_entry("statuses", id), "battle_only"):
				u.actor.statuses.remove(id)
		u.actor.statuses.clear_temporary()


## 개체가 전장을 떠났다(도주·물러남·흡수·만료): 그 개체의 예고를 거두고 오러를 다시 계산한다.
static func left_battle(b: Battle, u: Combatant) -> void:
	BattleDelayed.drop(b, u)
	BattlePassives.refresh_auras(b)


## 대열 섞기: 그 진영의 전열·후열 값을 무작위로 다시 나눠 준다.
static func shuffle_rows(b: Battle, side: int) -> void:
	var list := b.side_units(side)
	var rows: Array = list.map(func(u: Combatant) -> String: return u.row)
	b.rng.shuffle(rows)
	for i in list.size():
		list[i].row = str(rows[i])
	b.message.emit("combat.rows_shuffled", {}, "warn")


## 여신의 눈물: 상대 진영의 해당 계열에게 고정 신성 피해 + 상태. 해당하는 적이 없으면 사용자 회복.
## 피해는 보호막·버티기(revive_once)·피해로 풀리는 상태를 거친다(DamageApply).
static func smite(b: Battle, c: Combatant, e: Dictionary) -> void:
	var hit := false
	for f in b.opponents(c):
		var fam: Array = JsonUtil.get_array((f.actor as Monster).def, "family") if f.actor is Monster else []
		if fam.any(func(x: Variant) -> bool: return (e.get("families", []) as Array).has(x)):
			hit = true
			var ctx := EffectContext.new(b.db, c.actor, f.actor, b.rng)
			# 신성 피해도 약점·면역을 따른다(성수에 약한 언데드 ×배율). 알아낸 상성은 도감에 남는다.
			var aff := (f.actor as Monster).damage_affinity("holy", "magical")
			var amount := roundi(float(e.get("amount", 0.0)) * aff)
			b.message.emit("combat.smite", {"target": f.label(), "amount": amount}, "good")
			DamageApply.hurt(ctx, f.actor, amount, "smite", "holy")
			b.event.emit({"type": "damage", "unit": f, "hit": true, "amount": amount, "crit": false})
			BattleKnowledge.on_damage(b, c, {"target": f.actor, "hit": true, "damage_type": "holy", "affinity": aff})
			if not str(e.get("status", "")).is_empty():
				Passives.try_status(b.db, null, c.actor, f.actor, str(e["status"]))
			for m: Dictionary in ctx.messages:
				b.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	if not hit:
		c.actor.pool.modify("hp", float(e.get("heal", 0.0)) * c.actor.statuses.heal_mult(), "smite")
		b.message.emit("effect.smite_heal", {"name": c.label()}, "good")


## 증원(효과 summon의 사건): 같은 진영에 몬스터를 더한다(한 진영 최대 combat.max_side_units).
static func summon(b: Battle, c: Combatant, e: Dictionary) -> void:
	var mid := str(e.get("monster", ""))
	if not b.db.has_entry("monsters", mid) or b.side_units(c.side).size() >= int(b.db.bal("combat.max_side_units", 6)):
		b.message.emit("combat.summon_fail", {"name": c.label()}, "info")
		return
	if c.actor.dead:
		return  # 시전하다 쓰러졌다(정수판 분열의 생명력 소모 등)
	var m := Monster.create(b.db, mid, " +")
	var u := b.add(m, c.side, JsonUtil.get_str(m.behavior(), "row", "front"))
	if int(e.get("rounds", 0)) > 0:
		u.memo[BattleSpawns.EXPIRE] = int(e["rounds"])
	joined(b, u)
	b.message.emit("combat.summon", {"name": c.label(), "monster": m.display_name}, "danger")
	b.event.emit({"type": "summon", "unit": u})
	BattlePassives.refresh_auras(b)


## 효과 문맥의 메시지·사건을 전투에 반영한다(도주·게이지·물러남·피해 기록·증원).
static func relay(b: Battle, ctx: EffectContext, c: Combatant) -> void:
	for m: Dictionary in ctx.messages:
		b.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	for e: Dictionary in ctx.events:
		match str(e.get("type")):
			"flee":
				b.try_flee(c)
				continue
			"gauge":
				var gu := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if gu != null:
					gu.gauge += float(e.get("amount", 0.0))
			"withdraw":
				var wu := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if wu != null and wu.is_active():
					wu.fled = true
					b.message.emit("combat.withdraw", {"name": wu.label()}, "warn")
					b.event.emit({"type": "fled", "unit": wu})
					left_battle(b, wu)
			"damage":
				BattleKnowledge.on_damage(b, c, e)
				var hu := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if hu != null and bool(e.get("hit", false)):
					hu.was_hit = true
			"summon":
				summon(b, c, e)
				continue
			"split":
				BattleSpawns.split(b, c, e)
				continue
			"absorb_ally":
				BattleSpawns.absorb(b, c, e)
				continue
			"delayed":
				BattleDelayed.schedule(c, e)
				continue
			"smite":
				smite(b, c, e)
				continue
			"seal":
				var lu := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if lu != null:  # 자기 차례 시작에 하나씩 준다 → rounds번의 자기 차례 동안 막힌다(이미 더 긴 쿨타임이면 그대로)
					var sid := str(e.get("skill", ""))
					lu.cooldowns[sid] = maxi(int(lu.cooldowns.get(sid, 0)), int(e.get("rounds", 2)) + 1)
				continue
			"shuffle_rows":
				var su := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if su != null:
					shuffle_rows(b, su.side)
				continue
		var ev := e.duplicate()
		ev["unit"] = b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
		ev.erase("target")
		b.event.emit(ev)
