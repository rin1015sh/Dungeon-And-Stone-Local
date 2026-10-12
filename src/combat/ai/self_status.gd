extends AiCondition
## 자신이 그 상태다(value: 상태 id, "not": true면 아니다): {"if": "self_status", "status": "hidden", "not": true, "use": "gnome_merge"}


func test(_battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	return unit.actor.statuses.has(JsonUtil.get_str(rule, "status")) != JsonUtil.get_bool(rule, "not")
