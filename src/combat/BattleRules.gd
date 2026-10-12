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
	for u in b.units:
		u.gauge += Passives.sum(u.actor, "start_gauge")


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


## 전투가 끝났다: 게이지를 비우고 전투 한정 상태(statuses "battle_only": true)를 지운다.
static func cleanup(b: Battle) -> void:
	for u in b.units:
		u.actor.meters.clear()
		for id in u.actor.statuses.ids():
			if JsonUtil.get_bool(b.db.get_entry("statuses", id), "battle_only"):
				u.actor.statuses.remove(id)


## 대열 섞기: 그 진영의 전열·후열 값을 무작위로 다시 나눠 준다.
static func shuffle_rows(b: Battle, side: int) -> void:
	var list := b.side_units(side)
	var rows: Array = list.map(func(u: Combatant) -> String: return u.row)
	b.rng.shuffle(rows)
	for i in list.size():
		list[i].row = str(rows[i])
	b.message.emit("combat.rows_shuffled", {}, "warn")


## 증원(효과 summon의 사건): 같은 진영에 몬스터를 더한다(한 진영 최대 combat.max_side_units).
static func summon(b: Battle, c: Combatant, e: Dictionary) -> void:
	var mid := str(e.get("monster", ""))
	if not b.db.has_entry("monsters", mid) or b.side_units(c.side).size() >= int(b.db.bal("combat.max_side_units", 6)):
		b.message.emit("combat.summon_fail", {"name": c.label()}, "info")
		return
	var m := Monster.create(b.db, mid, " +")
	var u := b.add(m, c.side, JsonUtil.get_str(m.behavior(), "row", "front"))
	b.message.emit("combat.summon", {"name": c.label(), "monster": m.display_name}, "danger")
	b.event.emit({"type": "summon", "unit": u})


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
			"damage":
				BattleKnowledge.on_damage(b, c, e)
				var hu := b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
				if hu != null and bool(e.get("hit", false)):
					hu.was_hit = true
			"summon":
				summon(b, c, e)
				continue
			"delayed":
				BattleDelayed.schedule(c, e)
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
