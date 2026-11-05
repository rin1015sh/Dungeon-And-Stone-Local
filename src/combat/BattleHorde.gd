class_name BattleHorde
extends RefCounted
## 큰 무리의 예비대(2층 "열댓 마리" — docs/plans/floor2.md §1-2): 적이 combat.max_side_units보다 많으면 앞의 몇 마리만 서고
## 나머지는 Battle.horde에 줄 선다. 적이 쓰러질 때마다 빈자리만큼 예비대에서 들어온다(게이지 0 — 증원과 같은 틀).
## 도주 확률은 지금 선 적만 센다(BattleRules.flee_chance가 side_units만 보므로 따로 할 일 없음). 순수 로직(오토로드 비의존).


## monster_ids를 [지금 설 몬스터, 예비대]로 나눈다.
static func split(db: GameDatabase, monster_ids: Array) -> Array:
	var cap := maxi(1, int(db.bal("combat.max_side_units", 6)))
	var front: Array = monster_ids.slice(0, cap)
	var rest: Array[String] = []
	for id: Variant in monster_ids.slice(cap):
		rest.append(str(id))
	return [front, rest]


## 빈자리만큼 예비대를 들인다. 들어온 수.
static func refill(b: Battle) -> int:
	var cap := int(b.db.bal("combat.max_side_units", 6))
	var n := 0
	while not b.horde.is_empty() and b.side_units(Combatant.SIDE_ENEMY).size() < cap:
		var m := Monster.create(b.db, b.horde.pop_front())
		var u := b.add(m, Combatant.SIDE_ENEMY, JsonUtil.get_str(m.behavior(), "row", "front"))
		BattleRules.joined(b, u)
		b.event.emit({"type": "summon", "unit": u})
		n += 1
	return n
