extends AiCondition
## 자기 진영에 자신만 남았다: {"if": "alone", "use": "goblin_howl"}


func test(battle: Battle, unit: Combatant, _rule: Dictionary) -> bool:
	return battle.side_units(unit.side).size() <= 1
