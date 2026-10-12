extends AiCondition
## 이번 전투의 첫 행동: {"if": "first_turn", "use": "goblin_trap"}


func test(_battle: Battle, unit: Combatant, _rule: Dictionary) -> bool:
	return unit.acted == 0
