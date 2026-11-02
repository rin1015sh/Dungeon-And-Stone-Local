class_name BattleSpawns
extends RefCounted
## 전투 중 개체가 늘고 주는 일(BattleRules.relay·BattlePassives가 부른다):
##   split(분열 — 효과 split): 시전자 생명력을 반으로 나눠 같은 몬스터 하나를 더 만든다. 새것은 그 스킬을 이미 쓴 것으로 친다.
##   absorb(흡수 — 효과 absorb_ally): 같은 편의 해당 몬스터 하나를 거둬들이고(전장에서 빠짐, 처치 아님) 최대 생명력 비율만큼 회복.
##   expire(소환 유지 — summon "rounds"): 소환수는 자기 차례가 그만큼 끝나면 사라진다.

const EXPIRE := "expire_in"


static func split(b: Battle, c: Combatant, e: Dictionary) -> void:
	if c.actor.statuses.has_flag("no_split"):  # 폭약에 그을려 갈라지지 못한다(녹색 탄광)
		b.message.emit("combat.split_blocked", {"name": c.label()}, "good")
		return
	if not c.actor is Monster or b.side_units(c.side).size() >= int(b.db.bal("combat.max_side_units", 6)):
		b.message.emit("combat.summon_fail", {"name": c.label()}, "info")
		return
	var hp := c.actor.pool.get_current("hp")
	var half := floorf(hp / 2.0)
	if half < 1.0:
		return
	c.actor.pool.set_current("hp", hp - half)
	var m := Monster.create(b.db, (c.actor as Monster).monster_id)
	m.pool.set_current("hp", half)
	var u := b.add(m, c.side, c.row)
	u.uses[str(e.get("skill", ""))] = 99
	BattleRules.joined(b, u)
	b.message.emit("combat.split", {"name": c.label(), "monster": m.display_name}, "danger")
	b.event.emit({"type": "summon", "unit": u})
	BattlePassives.refresh_auras(b)


static func absorb(b: Battle, c: Combatant, e: Dictionary) -> void:
	var ids: Array = e.get("monsters", [])
	for u in b.side_units(c.side):
		if u != c and u.actor is Monster and ids.has((u.actor as Monster).monster_id):
			u.fled = true
			var healed := c.actor.pool.modify("hp", c.actor.pool.get_max("hp") * float(e.get("heal_ratio", 0.1)) * c.actor.statuses.heal_mult(), "absorb")
			b.message.emit("combat.absorb", {"name": c.label(), "target": u.label(), "amount": roundi(healed)}, "danger")
			b.event.emit({"type": "fled", "unit": u})
			BattleRules.left_battle(b, u)
			return
	b.message.emit("combat.absorb_none", {"name": c.label()}, "info")


## 소환수 c의 차례가 끝났다 — 유지 라운드가 다 되면 사라진다.
static func tick_expire(b: Battle, c: Combatant) -> void:
	if not c.memo.has(EXPIRE) or not c.is_active():
		return
	c.memo[EXPIRE] = int(c.memo[EXPIRE]) - 1
	if int(c.memo[EXPIRE]) <= 0:
		c.fled = true
		b.message.emit("combat.summon_expired", {"name": c.label()}, "info")
		b.event.emit({"type": "fled", "unit": c})
		BattleRules.left_battle(b, c)
