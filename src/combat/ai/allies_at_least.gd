extends AiCondition
## 자기 진영(자신 포함)에 value 이상 남았다. "same_lineage": true면 같은 계열만 센다.
##   {"if": "allies_at_least", "value": 2, "same_lineage": true, "use": "wolf_pack_hunt"}


func test(battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	var n := 0
	var lin := (unit.actor as Monster).lineage() if unit.actor is Monster else ""
	for u in battle.side_units(unit.side):
		if JsonUtil.get_bool(rule, "same_lineage") and (not u.actor is Monster or (u.actor as Monster).lineage() != lin):
			continue
		n += 1
	return n >= JsonUtil.get_int(rule, "value", 2)
