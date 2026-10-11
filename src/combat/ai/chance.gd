extends AiCondition
## 확률 value(0~1)로 참: {"if": "chance", "value": 0.35, "use": "pounce"}


func test(battle: Battle, _unit: Combatant, rule: Dictionary) -> bool:
	return battle.rng.chance(JsonUtil.get_float(rule, "value", 0.5))
