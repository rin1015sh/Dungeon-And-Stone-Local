class_name BattleDelayed
extends RefCounted
## 예고 공격(효과 delayed): 시전자의 차례 시작을 rounds번 지나면 터진다. 대기열은 Combatant.memo["delayed"].
## 대상: 찍힌 대상(marked, 예고 — delayed target cast)이 아직 있으면 그쪽, 아니면 상대 진영에서 끌어들이는 상태
## (flag draws_attacks)가 있으면 그중, 없으면 무작위 — hits번 따로 고른다.


static func schedule(c: Combatant, e: Dictionary) -> void:
	var q: Array = c.memo.get("delayed", [])
	q.append({"left": int(e.get("rounds", 1)), "hits": int(e.get("hits", 1)), "effects": e.get("effects", []), "marked": e.get("marked"),
		"guarded_mult": float(e.get("guarded_mult", 1.0)), "fire": str(e.get("fire", "combat.delayed_fire"))})
	c.memo["delayed"] = q


## 시전자 c의 차례가 시작됐다. 추가 행동(같은 라운드의 두 번째 차례)에서는 세지 않는다 — 예고를 받고 대응할 틈을 준다.
static func tick(b: Battle, c: Combatant) -> void:
	var q: Array = c.memo.get("delayed", [])
	if q.is_empty() or bool(c.memo.get("in_extra", false)):
		return
	if not c.is_active():
		drop(b, c)
		return
	var keep: Array = []
	for item: Dictionary in q:
		item["left"] = int(item["left"]) - 1
		if int(item["left"]) > 0:
			keep.append(item)
			continue
		if not bool(c.memo.get("fired_now", false)):
			b.message.emit(str(item.get("fire", "combat.delayed_fire")), {"name": c.label()}, "danger")
		c.memo["fired_now"] = true
		var mk: Combatant = b.unit_of(item["marked"] as Actor) if item.get("marked") is Actor else null
		if mk != null and not _marked_elsewhere(b, mk.actor, item):
			mk.actor.statuses.remove("telegraphed")
		for i in int(item["hits"]):
			var t := mk if mk != null and mk.is_active() else pick_target(b, c)
			if t != null:
				var fx: Array = item["effects"]
				if t.actor.statuses.has("guarding") and float(item.get("guarded_mult", 1.0)) < 1.0:
					fx = BattleTargets.boosted(fx, {"power_mult": float(item["guarded_mult"]), "ignore_defense": false})
					b.message.emit("combat.telegraph_guarded", {"name": t.label()}, "good")
				BossHooks.apply_effects(b, c, t, fx)
	c.memo["delayed"] = keep
	c.memo.erase("fired_now")


## 시전자가 쓰러지거나 물러났다: 예고를 거두고 찍힌 표식도 푼다.
static func drop(b: Battle, c: Combatant) -> void:
	var q: Array = c.memo.get("delayed", [])
	if q.is_empty():
		return
	c.memo["delayed"] = []
	for item: Dictionary in q:
		var mk: Combatant = b.unit_of(item["marked"] as Actor) if item.get("marked") is Actor else null
		if mk != null and not _marked_elsewhere(b, mk.actor, item):
			mk.actor.statuses.remove("telegraphed")
	b.message.emit("combat.delayed_dropped", {"name": c.label()}, "good")


## 그 대상을 찍은 다른 예고가 아직 남았는가(겹친 예고의 표식을 먼저 지우지 않는다).
static func _marked_elsewhere(b: Battle, a: Actor, except: Dictionary) -> bool:
	for u in b.units:
		if not u.is_active():
			continue
		for item: Dictionary in u.memo.get("delayed", []):
			if not is_same(item, except) and item.get("marked") == a and int(item["left"]) > 0:
				return true
	return false


static func pick_target(b: Battle, c: Combatant) -> Combatant:
	var foes := b.opponents(c)
	if foes.is_empty():
		return null
	var lure := foes.filter(func(f: Combatant) -> bool: return f.actor.statuses.has_flag("draws_attacks"))
	return b.rng.pick(lure if not lure.is_empty() else foes) as Combatant
