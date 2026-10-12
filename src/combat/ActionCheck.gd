class_name ActionCheck
extends RefCounted
## 전투 행동이 지금 실행 가능한지 검사한다(순수 로직). 문제가 있으면 이유(문자열 키), 없으면 "".
## 잘못된 행동은 차례를 쓰지 않는다 — 화면은 메뉴를 다시 열고, AI는 기본 공격으로 바꾼다.
##   행동: {"kind": "skill", "skill": id, "target": Combatant, "aim_weak": bool}
##       | {"kind": "guard"} | {"kind": "item", "item": id} | {"kind": "flee"}


static func reason(b: Battle, c: Combatant, action: Dictionary) -> String:
	if c == null or not c.is_active():
		return "combat.reason_unknown"
	match str(action.get("kind", "")):
		"skill":
			return _skill(b, c, str(action.get("skill", Battle.BASIC_ATTACK)), action.get("target"))
		"guard":
			return ""
		"flee":
			return "combat.reason_no_flee" if is_zero_approx(b.flee_chance(c)) else ""
		"item":
			var id := str(action.get("item", ""))
			if c.actor.inventory.count(id) <= 0 or not JsonUtil.get_bool(b.db.get_entry("items", id), "combat_usable"):
				return "combat.no_item"
			return ""
	return "combat.reason_unknown"


static func _skill(b: Battle, c: Combatant, skill_id: String, target: Variant) -> String:
	var sk := b.db.get_entry("skills", skill_id)
	if sk.is_empty() or (skill_id != Battle.BASIC_ATTACK and not c.actor.skills.has(skill_id)):
		return "combat.reason_unknown"
	var why := b.can_use(c, skill_id)
	if not why.is_empty():
		return why
	match JsonUtil.get_str(sk, "target"):
		"ally_single":
			# 배신의 장막: 아군을 알아볼 수 없어 아군 하나를 고르는 스킬을 못 쓴다(자기 자신만 고르면 괜찮다).
			if c.actor.statuses.has_flag("no_ally_single") and target is Combatant and target != c:
				return "combat.reason_veiled"
		"any_single":
			# 아무나 하나(조사 등): 고른 대상이 있어야 하고, 아직 전장에 있어야 한다.
			if not target is Combatant or not (target as Combatant).is_active():
				return "combat.reason_no_target"
		"enemy_single", "enemy_row":
			# 고른 적이 사라졌으면 Battle이 다른 적을 고른다. 적이 아예 없을 때만 실패.
			if b.opponents(c).is_empty():
				return "combat.reason_no_target"
			# 은신한 적은 (다른 적이 있으면) 고를 수 없다.
			if target is Combatant and (target as Combatant).is_active() and (target as Combatant).side != c.side \
					and not BattleRules.is_targetable(b, c, target as Combatant):
				return "combat.reason_hidden"
	return ""
