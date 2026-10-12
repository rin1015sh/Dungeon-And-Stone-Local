extends AiCondition
## 보스 페이즈가 그중 하나다(BossHooks, memo phase): {"if": "phase", "value": ["p3", "p4"], "use": "…"}


func test(_battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	return JsonUtil.get_array(rule, "value").has(str(unit.memo.get("phase", "")))
