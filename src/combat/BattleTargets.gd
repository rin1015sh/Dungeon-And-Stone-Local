class_name BattleTargets
extends RefCounted
## 스킬 대상 정하기(Battle._use_skill이 부른다)와 오인 공격.
## 오인(상태이상 "misdirect": {"chance", "power_mult", "ignore_defense"}): 적 하나를 노린 행동이 chance 확률로
## 무작위 아군(자신 제외)에게 간다. 피해 위력 ×power_mult, ignore_defense면 방어 무시(배신의 장막).
## 아군이 없으면 오인하지 않는다. "pool": "any"면 전장의 아무나(혼란 — 적일 수도 있다).


static func resolve(b: Battle, c: Combatant, kind: String, chosen: Variant) -> Array[Combatant]:
	var foes := b.opponents(c)
	var picked: Combatant = chosen as Combatant if chosen is Combatant and (chosen as Combatant).is_active() else null
	var out: Array[Combatant] = []
	match kind:
		"self":
			out.append(c)
		"enemy_all":
			out = foes
		"ally_all":
			out = b.side_units(c.side)
		"ally_single":
			out.append(picked if picked != null and picked.side == c.side else c)
		"any_single":
			if picked != null:
				out.append(picked)
		"enemy_row":
			var row := picked.row if picked != null else "front"
			for u in foes:
				if u.row == row:
					out.append(u)
		_:
			if picked == null or picked.side == c.side or not BattleRules.is_targetable(b, c, picked):
				picked = b.rng.pick(BattleRules.targetable(b, c)) as Combatant
			if picked != null:
				out.append(picked)
	return out


## 오인 공격 판정. 오인이면 {"target": 아군, "power_mult", "ignore_defense"}, 아니면 {}.
static func misdirect(b: Battle, c: Combatant, kind: String) -> Dictionary:
	if not kind in ["enemy_single", ""]:
		return {}
	var best := {}
	for id in c.actor.statuses.ids():
		var m := JsonUtil.get_dict(b.db.get_entry("statuses", id), "misdirect")
		if not m.is_empty() and JsonUtil.get_float(m, "chance") > JsonUtil.get_float(best, "chance"):
			best = m
	if best.is_empty() or not b.rng.chance(JsonUtil.get_float(best, "chance")):
		return {}
	# pool "any"(혼란): 자기 빼고 전장의 아무나. 기본은 다른 아군.
	var pool: Array = b.units.filter(func(u: Combatant) -> bool: return u != c and u.is_active()) \
		if JsonUtil.get_str(best, "pool") == "any" else b.side_units(c.side).filter(func(u: Combatant) -> bool: return u != c)
	if pool.is_empty():
		return {}
	return {"target": b.rng.pick(pool), "power_mult": JsonUtil.get_float(best, "power_mult", 1.0),
		"ignore_defense": JsonUtil.get_bool(best, "ignore_defense")}


## 오인 공격용으로 피해 효과의 위력·방어 무시를 바꾼 사본.
static func boosted(effects: Array, mis: Dictionary) -> Array:
	var out: Array = []
	for e: Variant in effects:
		if e is Dictionary and JsonUtil.get_str(e, "type") == "damage":
			var d: Dictionary = (e as Dictionary).duplicate(true)
			d["power"] = JsonUtil.get_float(d, "power", 1.0) * float(mis["power_mult"])
			if d.has("power_if_status"):  # 조건부 위력도 같은 배율(조건이 맞으면 power 대신 쓰인다)
				var cond: Dictionary = d["power_if_status"]
				cond["power"] = JsonUtil.get_float(cond, "power", 1.0) * float(mis["power_mult"])
			if bool(mis["ignore_defense"]):
				d["ignore_defense"] = true
			out.append(d)
		else:
			out.append(e)
	return out
