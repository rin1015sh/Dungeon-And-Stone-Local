class_name MonsterAi
extends RefCounted
## 몬스터 AI: 데이터 ai 규칙을 위에서부터 보고, 조건이 모두 참이고 지금 쓸 수 있는 첫 스킬을 고른다.
## 규칙: {"if": "<조건 id>", "value": …, "status": …, "also": [{"if": …}, …], "use": "<스킬 id>",
##        "target": "random|lowest_hp|highest_hp|with_status|without_status", "target_status": "<상태 id>"}
## 맞는 규칙이 없으면 ai_cycle(고정 순환, 예: 할퀴기 → 할퀴기 → 달려들기)의 이번 차례 스킬, 그것도 없으면 기본 공격.
## 조건은 src/combat/ai/<조건>.gd(AiCondition). 아군을 자동으로 돌릴 때(테스트)도 같은 함수를 쓴다 → 기본 공격.


static func choose(b: Battle, c: Combatant) -> Dictionary:
	var def: Dictionary = (c.actor as Monster).def if c.actor is Monster else {}
	for r: Variant in JsonUtil.get_array(def, "ai"):
		var rule: Dictionary = r if r is Dictionary else {}
		if not _all_true(b, c, rule):
			continue
		var action := _action(b, c, JsonUtil.get_str(rule, "use"), rule)
		if not action.is_empty():
			return action
	var cycle := JsonUtil.get_array(def, "ai_cycle")
	if not cycle.is_empty():
		var action := _action(b, c, str(cycle[c.acted % cycle.size()]), {})
		if not action.is_empty():
			return action
	return {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": target(b, c, {})}


static func _all_true(b: Battle, c: Combatant, rule: Dictionary) -> bool:
	var conds: Array = [rule]
	conds.append_array(JsonUtil.get_array(rule, "also"))
	for x: Variant in conds:
		var cd: Dictionary = x if x is Dictionary else {}
		var cond := b.ai.instance(JsonUtil.get_str(cd, "if", "always")) as AiCondition
		if cond == null or not cond.test(b, c, cd):
			return false
	return true


## 쓸 수 있으면 행동, 아니면 {}.
static func _action(b: Battle, c: Combatant, skill_id: String, rule: Dictionary) -> Dictionary:
	var action := {"kind": "skill", "skill": skill_id, "target": null}
	if not ActionCheck.reason(b, c, action).is_empty():
		return {}
	action["target"] = target(b, c, rule)
	return action


## 대상 고르기(은신한 적은 빼고 — BattleRules.targetable).
static func target(b: Battle, c: Combatant, rule: Dictionary) -> Combatant:
	var foes := BattleRules.targetable(b, c)
	if foes.is_empty():
		return null
	var st := JsonUtil.get_str(rule, "target_status")
	match JsonUtil.get_str(rule, "target"):
		"lowest_hp":
			return _by_hp(foes, true)
		"highest_hp":
			return _by_hp(foes, false)
		"with_status", "without_status":
			var want := JsonUtil.get_str(rule, "target") == "with_status"
			var fit := foes.filter(func(f: Combatant) -> bool: return f.actor.statuses.has(st) == want)
			if not fit.is_empty():
				return b.rng.pick(fit) as Combatant
	return b.rng.pick(foes) as Combatant


static func _by_hp(foes: Array[Combatant], lowest: bool) -> Combatant:
	var best := foes[0]
	for f in foes:
		var r := f.actor.pool.get_ratio("hp")
		if (r < best.actor.pool.get_ratio("hp")) == lowest and not is_equal_approx(r, best.actor.pool.get_ratio("hp")):
			best = f
	return best
