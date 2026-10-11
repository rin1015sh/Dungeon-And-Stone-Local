extends AiCondition
## 항상 참: {"if": "always", "use": "bite"}


func test(_battle: Battle, _unit: Combatant, _rule: Dictionary) -> bool:
	return true
