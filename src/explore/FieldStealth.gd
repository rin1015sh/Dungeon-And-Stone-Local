class_name FieldStealth
extends RefCounted
## 탐험 중 은신(정수 이능의 field_stealth, 명세 §6.3·§6.9): 몬스터가 플레이어를 알아채는 반경을 줄인다.
##   스킬 데이터 "field_stealth": {"still": 0.7, "moving": 0.3} — 서 있으면 still, 움직이는 중이면 moving만큼 반경 감소.
##   여러 개면 가장 큰 값. 서 있음 = 마지막 이동 뒤 explore.stealth_still_hours 이상 지남.
##   칼날늑대처럼 behavior.ignores_stealth인 몬스터에게는 듣지 않는다(MonsterSteering).


## 방금 움직였는가(마지막 이동 뒤 explore.stealth_still_hours 안 — 몬스터가 소리를 듣는다).
static func moving(s: ExploreSession) -> bool:
	return s.last_move_hours >= 0.0 and s.clock.total_hours - s.last_move_hours < float(s.db.bal("explore.stealth_still_hours", 0.02))


## 0(감소 없음) ~ 1(완전히 숨음).
static func of(s: ExploreSession) -> float:
	var still := not moving(s)
	var best := 0.0
	for sid in s.player.skills:
		var fs := JsonUtil.get_dict(s.db.get_entry("skills", sid), "field_stealth")
		if not fs.is_empty():
			best = maxf(best, JsonUtil.get_float(fs, "still" if still else "moving"))
	return clampf(best, 0.0, 1.0)
