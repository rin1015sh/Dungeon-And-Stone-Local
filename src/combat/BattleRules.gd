class_name BattleRules
extends RefCounted
## Battle을 돕는 규칙 모음(Battle.gd를 짧게 유지): 은신 대상 고르기, 증원, 전투 시작 선공, 전투당 사용 횟수, 도주 보정.


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


## 도주 확률 보정: 속박(no_flee)이면 0, 상대 패시브 flee_penalty만큼 깎는다. 기본 확률 k를 받아 최종 확률.
static func flee_adjust(b: Battle, c: Combatant, k: float) -> float:
	if c.actor.statuses.has_flag("no_flee"):
		return 0.0
	var pen := 0.0
	for o in b.opponents(c):
		pen += Passives.sum(o.actor, "flee_penalty")
	return k - pen


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
		var ev := e.duplicate()
		ev["unit"] = b.unit_of(e.get("target") as Actor) if e.get("target") is Actor else null
		ev.erase("target")
		b.event.emit(ev)
