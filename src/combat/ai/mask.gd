extends AiCondition
## 후회의 군주의 지금 탈이 그중 하나다(RegretMasks): {"if": "mask", "value": ["beast"], "use": "…"}


func test(battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	return JsonUtil.get_array(rule, "value").has(RegretMasks.current(battle, unit))
