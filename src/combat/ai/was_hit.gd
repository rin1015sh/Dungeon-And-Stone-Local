extends AiCondition
## 마지막 자기 행동 뒤에 피해를 받았다: {"if": "was_hit", "also": [{"if": "chance", "value": 0.5}], "use": "…"}


func test(_battle: Battle, unit: Combatant, _rule: Dictionary) -> bool:
	return unit.was_hit
