extends AiCondition
## 고를 수 있는 적 중에 그 상태인 적이 있다("not": true면 그 상태가 아닌 적이 있다).
##   {"if": "foe_status", "status": "bleeding", "not": true, "use": "wolf_blade_graze", "target": "without_status", "target_status": "bleeding"}


func test(battle: Battle, unit: Combatant, rule: Dictionary) -> bool:
	var st := JsonUtil.get_str(rule, "status")
	var want := not JsonUtil.get_bool(rule, "not")
	for f in BattleRules.targetable(battle, unit):
		if f.actor.statuses.has(st) == want:
			return true
	return false
