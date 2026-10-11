class_name MonsterAi
extends RefCounted
## 몬스터 AI: 데이터 ai 규칙을 위에서부터 보고, 조건이 참이고 지금 쓸 수 있는 첫 스킬을 고른다. 없으면 기본 공격.
## 조건은 src/combat/ai/<조건>.gd(AiCondition). 아군을 자동으로 돌릴 때(테스트)도 같은 함수를 쓴다 → 기본 공격.


static func choose(b: Battle, c: Combatant) -> Dictionary:
	var rules: Array = []
	if c.actor is Monster:
		rules = JsonUtil.get_array((c.actor as Monster).def, "ai")
	for r: Variant in rules:
		var rule: Dictionary = r if r is Dictionary else {}
		var cond := b.ai.instance(JsonUtil.get_str(rule, "if")) as AiCondition
		var skill_id := JsonUtil.get_str(rule, "use")
		if cond == null or not cond.test(b, c, rule):
			continue
		var action := {"kind": "skill", "skill": skill_id, "target": null}
		if not ActionCheck.reason(b, c, action).is_empty():
			continue
		action["target"] = target(b, c, rule)
		return action
	return {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": target(b, c, {})}


## 대상: 규칙의 target이 "lowest_hp"면 생명력 비율이 가장 낮은 적, 아니면 무작위 적.
static func target(b: Battle, c: Combatant, rule: Dictionary) -> Combatant:
	var foes := b.opponents(c)
	if foes.is_empty():
		return null
	if JsonUtil.get_str(rule, "target") == "lowest_hp":
		var best := foes[0]
		for f in foes:
			if f.actor.pool.get_ratio("hp") < best.actor.pool.get_ratio("hp"):
				best = f
		return best
	return b.rng.pick(foes) as Combatant
