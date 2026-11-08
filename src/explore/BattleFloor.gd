class_name BattleFloor
extends RefCounted
## 층별 전투 기믹(전투 개선 CB10 — 프롬프트 "층별 고유 전투 기믹", 탐험에서 한 선택이 전투에 닿게). 순수 로직(오토로드 비의존).
## 층 JSON "battle": {
##   "rules": [{"status": 상태, "side": "party"|"enemy"|"all", "zones": [구역](선택 — 플레이어가 선 구역), "from": 시, "to": 시(선택 —
##             FieldClues.in_window, 자정을 넘으면 to < from), "families": [몬스터 family](선택 — 그 계열 적만), "alerted": true(선택 —
##             경보 · 진동 등으로 쫓아온 무리 — group.alert_until이 아직 남음), "storm": true(선택 — 데쓰웜 모래 폭풍 중, DesertRules)}],
##   "cap_zones": {구역: 수}(선택 — 그 구역에서 싸우면 적이 한 번에 그만큼만 선다 — 좁은 협곡, 나머지는 예비대)}
## 상태는 battle_only(전투가 끝나면 풀린다). 지형 상태(BattleTerrain)와 함께 쌓인다.


static func _cfg(s: ExploreSession) -> Dictionary:
	return JsonUtil.get_dict(s.floor_def, "battle")


## 그 자리에서 싸울 때 적 상한(0 = 제한 없음).
static func cap(s: ExploreSession) -> int:
	return JsonUtil.get_int(JsonUtil.get_dict(_cfg(s), "cap_zones"), s.map.zone_at(s.pos), 0)


## 지형 상한과 층 상한 중 작은 쪽(0은 없음).
static func merge_cap(a: int, b: int) -> int:
	if a <= 0:
		return b
	if b <= 0:
		return a
	return mini(a, b)


## 전투가 꾸려진 뒤: 맞는 규칙의 상태를 건다. 건 수.
static func apply(b: Battle, s: ExploreSession, g: FieldMonsters.Group) -> int:
	var n := 0
	if g != null and s.clock.total_hours < float(g.get_meta(MonsterTraits.STUNNED, -1.0)):  # 벽에 박은 멧돼지 — 기절한 채 시작
		for u in b.side_units(Combatant.SIDE_ENEMY):
			u.actor.statuses.apply("stun")
			n += 1
	var zone := s.map.zone_at(s.pos)
	for v: Variant in JsonUtil.get_array(_cfg(s), "rules"):
		var r: Dictionary = v if v is Dictionary else {}
		var zones := JsonUtil.get_array(r, "zones")
		if not zones.is_empty() and not zones.has(zone):
			continue
		if r.has("from") and not FieldClues.in_window(s, r):
			continue
		if JsonUtil.get_bool(r, "storm") and (s.desert == null or s.clock.total_hours >= s.desert.storm_until):
			continue
		if JsonUtil.get_bool(r, "alerted") and (g == null or s.clock.total_hours >= g.alert_until):
			continue
		var st := JsonUtil.get_str(r, "status")
		var side := JsonUtil.get_str(r, "side", "enemy")
		var fams := JsonUtil.get_array(r, "families")
		for u in b.units:
			if not u.is_active():
				continue
			if side == "party" and u.side != Combatant.SIDE_PARTY or side == "enemy" and u.side != Combatant.SIDE_ENEMY:
				continue
			if not fams.is_empty():
				if not u.actor is Monster or not JsonUtil.get_array((u.actor as Monster).def, "family").any(func(f: Variant) -> bool: return fams.has(f)):
					continue
			if u.actor.statuses.apply(st):
				n += 1
	return n
