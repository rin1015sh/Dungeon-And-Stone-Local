class_name MonsterAi
extends RefCounted
## 몬스터 AI: 데이터 ai 규칙을 위에서부터 보고, 조건이 모두 참이고 지금 쓸 수 있는 첫 스킬을 고른다.
## 규칙: {"if": "<조건 id>", "value": …, "status": …, "also": [{"if": …}, …], "use": "<스킬 id>",
##        "target": "random|lowest_hp|highest_hp|with_status|without_status|highest_meter|guard_front",
##        "target_status": "<상태 id>", "target_meter": "<게이지 id>"}
## 규칙에 target이 없으면 보스 페이즈의 대상 규칙(memo target_rule)을 쓴다.
## guard_front: 방어 중이거나 끌어들이는 상태(draws_attacks)인 적 → 전열 → 무작위. taunt_first: 끌어들이는 적 → 무작위(가고일 석화).
## 무작위 대상(규칙 없음)이면 끌어들이는 적을 combat.taunt_chance 확률로 먼저(끌어들이기 상태 — 상태이상 재기획), 그다음은 전위 무게(front_weighted).
## ally_lowest_hp: 같은 편(자기 포함)에서 생명력 비율이 가장 낮은 개체(아군에게 거는 스킬 — 강철빙벽).
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
	if JsonUtil.get_str(rule, "target") == "ally_lowest_hp":
		return _by_hp(b.side_units(c.side), true)
	var foes := BattleRules.targetable(b, c)
	if foes.is_empty():
		return null
	var st := JsonUtil.get_str(rule, "target_status")
	var mode := JsonUtil.get_str(rule, "target", str(c.memo.get("target_rule", "")))
	match mode:
		"highest_meter":
			var mid := JsonUtil.get_str(rule, "target_meter")
			var best := foes[0]
			for f in foes:
				if Meters.value(f.actor, mid) > Meters.value(best.actor, mid):
					best = f
			return best
		"taunt_first", "guard_front":
			# 도발(draws_attacks) → 방어 중 → 전열 → 무작위(ASSUMPTIONS AU4). taunt_first는 도발한 쪽만 먼저 본다.
			var lure := foes.filter(func(f: Combatant) -> bool: return f.actor.statuses.has_flag("draws_attacks"))
			if lure.is_empty() or mode == "guard_front":
				lure.append_array(foes.filter(func(f: Combatant) -> bool:
					return f.actor.statuses.has("guarding") and not lure.has(f)))
			if lure.is_empty():
				lure = foes.filter(func(f: Combatant) -> bool: return f.row == "front")
			if not lure.is_empty():
				return b.rng.pick(lure) as Combatant
		"lowest_hp":
			return _by_hp(foes, true)
		"highest_hp":
			return _by_hp(foes, false)
		"with_status", "without_status":
			var want := mode == "with_status"
			var fit := foes.filter(func(f: Combatant) -> bool: return f.actor.statuses.has(st) == want)
			if not fit.is_empty():
				return b.rng.pick(fit) as Combatant
	# 대상 규칙이 없는 공격(무작위)은 끌어들이는 적(draws_attacks — 굳히기·얼음 갑옷 …)을 combat.taunt_chance 확률로 먼저 노린다.
	var lured := foes.filter(func(f: Combatant) -> bool: return f.actor.statuses.has_flag("draws_attacks"))
	if not lured.is_empty() and mode in ["", "random"] and b.rng.chance(float(b.db.bal("combat.taunt_chance", 0.75))):
		return b.rng.pick(lured) as Combatant
	return front_weighted(b, foes)


## 무작위 대상: 전위는 combat.front_aggro, 후위는 1의 무게(사용자 2026-10-25 — 전위가 어그로를 더 많이 받는다).
static func front_weighted(b: Battle, foes: Array[Combatant]) -> Combatant:
	var w := float(b.db.bal("combat.front_aggro", 1.0))
	var weights: Array = foes.map(func(f: Combatant) -> float: return w if f.row == "front" else 1.0)
	return foes[maxi(0, b.rng.weighted_index(weights))]


static func _by_hp(foes: Array[Combatant], lowest: bool) -> Combatant:
	var best := foes[0]
	for f in foes:
		var r := f.actor.pool.get_ratio("hp")
		if (r < best.actor.pool.get_ratio("hp")) == lowest and not is_equal_approx(r, best.actor.pool.get_ratio("hp")):
			best = f
	return best
