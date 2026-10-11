extends AiCondition
## 자기 생명력 비율이 value 이하: {"if": "hp_below", "value": 0.3, "use": "flee"}


func test(_battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	return unit.actor.pool.get_ratio("hp") <= JsonUtil.get_float(rule, "value", 0.3)
