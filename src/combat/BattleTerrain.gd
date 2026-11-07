class_name BattleTerrain
extends RefCounted
## 전투 지형(레벨 디자인 LD6 — 사용자 2026-11-07 "지형이 전투에 영향 주게"). 순수 로직(오토로드 비의존).
## 타일 data "battle": 지형 id → balance.json combat.terrain[id]:
##   "status": 그 칸에 선 쪽 모두에게 거는 상태(차례 단위 — 전투가 끝나면 StatusSet.clear_temporary가 푼다)
##   "skip_behavior": 몬스터 behavior 플래그(구울 mud_walker — 진창 · 물에 익숙하다) — 그 몬스터는 빼고
##   "cap": 어느 쪽이든 그 칸이면 적이 한 번에 그만큼만 선다(좁은 다리 — 나머지는 예비대 BattleHorde)
## 플레이어가 선 칸 → 아군, 무리가 선 칸 → 적.


## 그 타일의 지형 정의(없으면 {}).
static func of_tile(db: GameDatabase, tile_id: String) -> Dictionary:
	var id := JsonUtil.get_str(db.get_entry("tiles", tile_id), "battle")
	if id.is_empty():
		return {}
	return JsonUtil.get_dict(JsonUtil.get_dict(JsonUtil.get_dict(db.balance, "combat"), "terrain"), id)


## 적 상한(0 = 지형 제한 없음 — balance combat.max_side_units).
static func cap(db: GameDatabase, party_tile: String, enemy_tile: String) -> int:
	var c := 0
	for t: String in [party_tile, enemy_tile]:
		var n := JsonUtil.get_int(of_tile(db, t), "cap")
		if n > 0:
			c = n if c == 0 else mini(c, n)
	return c


## 전투가 꾸려진 뒤: 선 칸의 지형 상태를 건다. 건 수.
static func apply(b: Battle, party_tile: String, enemy_tile: String) -> int:
	var n := 0
	for side: int in [Combatant.SIDE_PARTY, Combatant.SIDE_ENEMY]:
		var t := of_tile(b.db, party_tile if side == Combatant.SIDE_PARTY else enemy_tile)
		var st := JsonUtil.get_str(t, "status")
		if st.is_empty():
			continue
		var skip := JsonUtil.get_str(t, "skip_behavior")
		for u in b.side_units(side):
			if not skip.is_empty() and u.actor is Monster and JsonUtil.get_bool((u.actor as Monster).behavior(), skip):
				continue
			if u.actor.statuses.apply(st):
				n += 1
	return n
