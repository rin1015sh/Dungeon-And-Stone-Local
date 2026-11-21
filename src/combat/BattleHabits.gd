class_name BattleHabits
extends RefCounted
## 전투 중 탐험가의 습관 기록(후회의 군주 고블린 탈 — plans/expansion_f1_3_B §6-4 "같은 기술만 쓰기"를 벌한다).
## 액터 메타 USES = {"battle": 전투 인스턴스 id, "uses": {스킬 id: 횟수}} — 새 전투에서 처음 쓰면 지운다. 기본 공격은 세지 않는다.
## 화면의 행동 기록이 같은 순서를 보이므로 "어떤 스킬이 봉인될지"를 플레이어가 미리 읽을 수 있다.

const USES := "battle_skill_uses"


static func record(b: Battle, c: Combatant, skill_id: String) -> void:
	if skill_id.is_empty() or skill_id == Battle.BASIC_ATTACK:
		return
	var rec: Dictionary = c.actor.get_meta(USES, {})
	if int(rec.get("battle", 0)) != b.get_instance_id():
		rec = {"battle": b.get_instance_id(), "uses": {}}
	var uses: Dictionary = rec["uses"]
	uses[skill_id] = int(uses.get(skill_id, 0)) + 1
	c.actor.set_meta(USES, rec)


## pool 안에서 이번 전투에 가장 많이 쓴 스킬(같으면 pool 앞쪽). 쓴 것이 없으면 "".
static func most_used(a: Actor, pool: Array) -> String:
	var uses: Dictionary = (a.get_meta(USES, {}) as Dictionary).get("uses", {})
	var best := ""
	var n := 0
	for sid: Variant in pool:
		var k := int(uses.get(str(sid), 0))
		if k > n:
			best = str(sid)
			n = k
	return best


## 한 편의 행동 순서를 뒤집는다(모래 탈 모래시계 — 효과 reverse_order): 살아 있는 개체의 게이지를 큰 순서 ↔ 작은 순서로 맞바꾼다.
static func reverse_order(b: Battle, side: int) -> void:
	var us := b.side_units(side).filter(func(u: Combatant) -> bool: return u.is_active())
	us.sort_custom(func(x: Combatant, y: Combatant) -> bool: return x.gauge > y.gauge)
	var gs: Array = us.map(func(u: Combatant) -> float: return u.gauge)
	for i in us.size():
		(us[i] as Combatant).gauge = float(gs[us.size() - 1 - i])
