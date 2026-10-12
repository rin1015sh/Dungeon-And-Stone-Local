extends AiCondition
## 같은 편(자기 포함) 중 생명력 비율이 value 이하인 개체가 있다: {"if": "ally_hp_below", "value": 0.6, "use": "orc_steel_ice_wall"}


func test(battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	for u in battle.side_units(unit.side):
		if u.actor.pool.get_ratio("hp") <= JsonUtil.get_float(rule, "value", 0.6):
			return true
	return false
