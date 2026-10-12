extends AiCondition
## 고를 수 있는 적 중에 게이지가 value 이상인 적이 있다: {"if": "foe_meter_at_least", "meter": "dread_fear", "value": 40}


func test(battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	var mid := JsonUtil.get_str(rule, "meter")
	for f in BattleRules.targetable(battle, unit):
		if Meters.value(f.actor, mid) >= JsonUtil.get_float(rule, "value"):
			return true
	return false
