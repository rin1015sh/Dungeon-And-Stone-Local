class_name FieldStealth
extends RefCounted
## 탐험 중 은신(정수 이능의 field_stealth, 명세 §6.3·§6.9): 몬스터가 플레이어를 알아채는 반경을 줄인다.
##   스킬 데이터 "field_stealth": {"still": 0.7, "moving": 0.3} — 서 있으면 still, 움직이는 중이면 moving만큼 반경 감소.
##   여러 개면 가장 큰 값. 서 있음 = 마지막 이동 뒤 explore.stealth_still_hours 이상 지남.
##   칼날늑대처럼 behavior.ignores_stealth인 몬스터에게는 듣지 않는다(MonsterSteering).
##   엄폐(레벨 디자인 LD8): 서 있고 옆(4방향)에 타일 data "cover": true인 칸(묘비 · 긴 의자 · 울타리 · 수레 · 덤불 …)이 있으면
##   explore.cover_stealth만큼 숨는다 — 정수 이능이 없어도 장례 행렬 · 순찰을 묘비 뒤에서 지나보낸다. 숨은 동안 몸이 흐려진다(FloorView).
##   숨어 기다린 매복(전투 개선 CB3 — C11의 "플레이어가 기습하는 특수 경우"): 숨은 채 서 있는데 플레이어를 모르는 무리
##   (쫓기 · 찾기가 아니고 경보 시각도 지난 — 보스 제외)가 몸에 닿으면 플레이어 쪽이 먼저 움직인다(combat.first_strike_gauge).


## 방금 움직였는가(마지막 이동 뒤 explore.stealth_still_hours 안 — 몬스터가 소리를 듣는다).
static func moving(s: ExploreSession) -> bool:
	return s.last_move_hours >= 0.0 and s.clock.total_hours - s.last_move_hours < float(s.db.bal("explore.stealth_still_hours", 0.02))


## 0(감소 없음) ~ 1(완전히 숨음).
static func of(s: ExploreSession) -> float:
	var still := not moving(s)
	var best := float(s.db.bal("explore.cover_stealth", 0.6)) if still and next_to_cover(s) else 0.0
	for sid in s.player.skills:
		var fs := JsonUtil.get_dict(s.db.get_entry("skills", sid), "field_stealth")
		if not fs.is_empty():
			best = maxf(best, JsonUtil.get_float(fs, "still" if still else "moving"))
	return clampf(best, 0.0, 1.0)


## 서 있는 칸 옆(4방향)에 엄폐물이 있는가(움직이는 중이어도 — 숨었는지는 in_cover).
static func next_to_cover(s: ExploreSession) -> bool:
	for d in FloorMap.DIRS4:
		if JsonUtil.get_bool(s.db.get_entry("tiles", s.map.tile_id_at(s.pos + d)), "cover"):
			return true
	return false


## 지금 엄폐물 뒤에 숨어 있는가(서 있고 옆에 엄폐물 — 몸이 흐려진다).
static func in_cover(s: ExploreSession) -> bool:
	return not moving(s) and next_to_cover(s)


## 숨은 채 기다리다 모르고 다가온 무리와 맞닥뜨렸는가(그러면 플레이어 선공 — CB3). 걷는 중 · 쫓기던 중 · 보스는 아니다.
static func springs_ambush(s: ExploreSession, g: FieldMonsters.Group) -> bool:
	if g == null or not g.boss.is_empty() or moving(s) or of(s) <= 0.0:
		return false
	if g.state == FieldMonsters.STATE_CHASE or g.state == FieldMonsters.STATE_SEARCH:
		return false
	return s.clock.total_hours >= g.alert_until
