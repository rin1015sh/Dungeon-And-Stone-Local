class_name ExploreDebug
extends RefCounted
## 탐험 디버그 기능(디버그 패널·테스트용). 게임 규칙 밖의 조작만 모았다.


static func teleport(s: ExploreSession, to: Vector2i) -> bool:
	return s.relocate(to)


## 기념비 옆 걸을 수 있는 칸으로.
static func to_monument(s: ExploreSession) -> bool:
	for r in range(1, 4):
		for d in FloorMap.DIRS4:
			if s.relocate(s.map.center + d * r):
				return true
	return false


static func reveal(s: ExploreSession) -> void:
	s.map.explored.fill(1)
	s.view_changed.emit()


## 폐쇄까지 hours_left만 남도록 시계를 돌린다(개체 상태는 흐르지 않는다).
static func close_in(s: ExploreSession, hours_left: float) -> void:
	s.clock.total_hours = maxf(s.clock.total_hours, s.close_hours() - hours_left)
	s.pass_time(0.0001)


static func nearest_portal(s: ExploreSession) -> Vector2i:
	var best := Vector2i(-1, -1)
	for portal: Dictionary in s.map.portals:
		var p: Vector2i = portal["pos"]
		if best.x < 0 or (p - s.pos).length_squared() < (best - s.pos).length_squared():
			best = p
	return best


## 플레이어 옆에 몬스터 무리를 만들고 바로 전투를 건다. monster_id가 비면 지역 몬스터 중 무작위.
static func spawn_and_engage(s: ExploreSession, monster_id: String = "") -> bool:
	var regions := JsonUtil.get_array(s.floor_def, "regions").filter(
		func(r: Variant) -> bool: return r is Dictionary and not JsonUtil.get_array(r, "monsters").is_empty())
	if regions.is_empty():
		return false
	var g := s.monsters.spawn_group(s.rng.pick(regions), s.pos, s.pos, monster_id)
	if g == null:
		return false
	s.monsters.changed.emit()
	s.engage(g, true)
	return true
