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


## 위층(지금은 2층)으로 바로 오른다: 만들어진 층으로 가는 층 포탈 하나로 FloorTravel.up(포탈 자리에서 올라간 것으로 — 내려오면 그 포탈 앞).
## 갈 층이 없거나 균열 안이면 false.
## dest가 있으면 그 포탈(1층 팔 끝 — floor2_south 망자의 땅 · floor2_north 고블린 숲)로만.
static func go_up(s: ExploreSession, dest: String = "") -> bool:
	if s.rift_run != null:
		return false
	for portal: Dictionary in s.map.portals:
		if str(portal.get("kind", "")) == "floor_down" or FloorTravel.floor_for(s.db, str(portal.get("dest", ""))).is_empty():
			continue
		if not dest.is_empty() and str(portal.get("dest", "")) != dest:
			continue
		var next := FloorTravel.up(s, portal)
		if next != null:
			s.transfer.emit(next)
			return true
	return false


## 디버그 미궁 이동(F1): 층 JSON으로 길을 찾아 그 층으로 간다(새 층이 생기면 저절로 — 1층 포탈 dest → 2층 arrival → 2층 포탈 dest → 3층 …).
## 지금 층이 길 위에 없으면 아래층으로 내려가(below) 길에 닿은 뒤, 길을 따라 그 층 포탈로 오른다. 같은 층이면 false.
static func travel_to(s: ExploreSession, floor_id: String) -> bool:
	if s.rift_run != null or JsonUtil.get_str(s.floor_def, "id") == floor_id:
		return false
	var path := floor_path(s.db, floor_id)
	if path.is_empty():
		return false
	var cur := s
	while not path.has(JsonUtil.get_str(cur.floor_def, "id")):
		if cur.below == null:
			return false
		cur = FloorTravel.down(cur)
	for i in range(path.find(JsonUtil.get_str(cur.floor_def, "id")) + 1, path.size()):
		var dest := JsonUtil.get_str(s.db.get_entry("floors", path[i]), "arrival")
		var next: ExploreSession = null
		for portal: Dictionary in cur.map.portals:
			if str(portal.get("dest", "")) == dest:
				next = FloorTravel.up(cur, portal)
				break
		if next == null:
			break
		cur = next
	if cur == s:
		return false
	s.transfer.emit(cur)
	return true


## 맨 아래층(도착 arrival이 없는 층)에서 floor_id까지 거치는 층 id들(못 가면 빈 배열).
static func floor_path(db: GameDatabase, floor_id: String) -> Array[String]:
	var out: Array[String] = []
	var cur := floor_id
	for guard in 32:
		out.push_front(cur)
		var a := JsonUtil.get_str(db.get_entry("floors", cur), "arrival")
		if a.is_empty():
			return out
		var parent := ""
		for fid: String in db.get_collection("floors"):
			for p: Variant in JsonUtil.get_array(db.get_entry("floors", fid), "portals"):
				if p is Dictionary and JsonUtil.get_str(p, "dest") == a:
					parent = fid
		if parent.is_empty():
			return []
		cur = parent
	return []


## 디버그 미궁 이동 목록: 층 번호 · id 순.
static func travel_floors(db: GameDatabase) -> Array[String]:
	var out: Array[String] = []
	for fid: String in db.get_collection("floors"):
		if not floor_path(db, fid).is_empty():
			out.append(fid)
	out.sort_custom(func(a: String, b: String) -> bool:
		var fa := JsonUtil.get_int(db.get_entry("floors", a), "floor")
		var fb := JsonUtil.get_int(db.get_entry("floors", b), "floor")
		return fa < fb or (fa == fb and a < b))
	return out


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
	var parts := monster_id.split("*")  # "ghoul*10" = 그 몬스터 10마리 무리(큰 무리 확인 — BattleHorde)
	var g := s.monsters.spawn_group(s.rng.pick(regions), s.pos, s.pos, parts[0])
	if g == null:
		return false
	if parts.size() == 2:
		g.monster_ids.clear()
		for i in maxi(1, parts[1].to_int()):
			g.monster_ids.append(parts[0])
	s.monsters.changed.emit()
	s.engage(g, true)
	return true


## 3층: 보랏빛 나무(마녀의 오두막 입구)를 하나 세우고 그 곁에 선다.
static func f3_hut_tree(s: ExploreSession) -> bool:
	if s.pilgrim == null or s.pilgrim.hut == null:
		return false
	var at := s.pilgrim.hut.spawn(s)
	if at.x < 0 and not s.pilgrim.hut.entrances.is_empty():
		at = s.pilgrim.hut.entrances[0]["pos"]
	for d: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
		if at.x >= 0 and s.relocate(at + d):
			return true
	return false
