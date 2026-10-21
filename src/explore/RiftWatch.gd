class_name RiftWatch
extends RefCounted
## 층 위의 균열(순수 로직, 명세 §8.1): 자연 개방(RiftCalendar) · 강제 개방(기념비에 마석) · 균열 포탈 · 입장.
## 균열 포탈 = 타일 rift_portal + map.portals {"kind": "rift", "rift": id 또는 ""(입장할 때 4종 가중 무작위)}.
## 입장하면 포탈은 닫히고(타일이 바닥으로) RiftRun이 챕터 세션을 만든다.

var calendar: RiftCalendar = null  ## 없으면 자연 개방 없음(테스트·디버그)
var open_at: float = -1.0          ## 이번 원정의 자연 개방 시각(-1 = 이번 달은 안 열림)
var opened: bool = false
var _next_id: int = 1


## 층에 들어왔다(ExploreSession.start).
func begin(s: ExploreSession) -> void:
	if calendar != null and not rifts_for(s).is_empty():
		open_at = calendar.roll_month(s.db, s.rng, s.close_hours())


## 이 층에서 열리는 균열 id들(rifts/*.json host_floor).
static func rifts_for(s: ExploreSession) -> Array[String]:
	var out: Array[String] = []
	var fl := JsonUtil.get_int(s.floor_def, "floor", 0)
	var ids: Array = s.db.get_collection("rifts").keys()
	ids.sort()
	for id: Variant in ids:
		if JsonUtil.get_int(s.db.get_entry("rifts", str(id)), "host_floor") == fl and fl > 0:
			out.append(str(id))
	return out


func update(s: ExploreSession, _hours: float) -> void:
	if open_at >= 0.0 and not opened and s.clock.total_hours >= open_at:
		open_natural(s)


## 자연 개방: 맵 곳곳에 포탈 rift.portal_count개(종류는 들어갈 때 정한다).
func open_natural(s: ExploreSession) -> int:
	opened = true
	var range_: Array = s.db.bal("rift.portal_count", [3, 5])
	var n := s.rng.randi_range(int(range_[0]), int(range_[1]))
	var made := 0
	for i in n:
		if _place(s, "", _far_cell(s)):
			made += 1
	s.message.emit("explore.rift_opened", {"count": made}, "danger")
	return made


## 강제 개방(마석·디버그): near 옆에 그 균열의 포탈 하나.
func force_open(s: ExploreSession, rift_id: String, near: Vector2i) -> bool:
	if not s.db.has_entry("rifts", rift_id):
		return false
	var ok := _place(s, rift_id, _cell_near(s, near))
	if ok:
		s.message.emit("explore.rift_forced", {"name": DataNames.entry(s.db, "rifts", rift_id)}, "danger")
	return ok


## 기념비에서 마석 바치기: 가방에 균열 force_open.item이 있으면 하나 쓰고 그 균열을 연다. 바쳤으면 true.
## 그 층의 계층석(아이템 opens_floor_rift = 층 번호 — 계층군주 보상)이 있으면 그것을 먼저: 그 층 균열 하나(가중 무작위)를 연다.
func try_offer(s: ExploreSession, monument: Vector2i) -> bool:
	var fl := JsonUtil.get_int(s.floor_def, "floor", 0)
	for item in s.player.inventory.ids():
		if fl > 0 and JsonUtil.get_int(s.db.get_entry("items", item), "opens_floor_rift") == fl and not rifts_for(s).is_empty():
			s.message.emit("explore.rift_offer", {"item": DataNames.entry(s.db, "items", item)}, "system")
			if force_open(s, pick_rift(s), monument):
				s.player.inventory.remove(item, 1)
			else:
				s.message.emit("explore.rift_offer_failed", {}, "warn")
			return true
	for id in rifts_for(s):
		var item := JsonUtil.get_str(JsonUtil.get_dict(s.db.get_entry("rifts", id), "force_open"), "item")
		if not item.is_empty() and s.player.inventory.count(item) > 0:
			s.message.emit("explore.rift_offer", {"item": DataNames.entry(s.db, "items", item)}, "system")
			if force_open(s, id, monument):
				s.player.inventory.remove(item, 1)  # 열렸을 때만 마석을 쓴다(자리를 못 찾으면 그대로 남는다)
			else:
				s.message.emit("explore.rift_offer_failed", {}, "warn")
			return true  # 바치려 했다 — 기념비 기본 문구는 내지 않는다
	return false


## 포탈로 들어간다: 포탈을 닫고 RiftRun을 만들어 첫 챕터 세션을 돌려준다(균열은 세션의 rift_run).
func enter(s: ExploreSession, portal: Dictionary) -> ExploreSession:
	var rid := str(portal.get("rift", ""))
	if rid.is_empty():
		rid = pick_rift(s)
	if rid.is_empty():
		return null
	s.map.portals.erase(portal)
	s.map.set_tile(portal["pos"], JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "floor", "cave_floor"))
	return RiftRun.new(s, rid).start()


## 가중 무작위(rifts weight).
func pick_rift(s: ExploreSession) -> String:
	var ids := rifts_for(s)
	if ids.is_empty():
		return ""
	var weights: Array = ids.map(func(id: String) -> float: return JsonUtil.get_float(s.db.get_entry("rifts", id), "weight", 1.0))
	return ids[s.rng.weighted_index(weights)]


func _place(s: ExploreSession, rift_id: String, cell: Vector2i) -> bool:
	if cell.x < 0:
		return false
	s.map.set_tile(cell, "rift_portal")
	s.map.portals.append({"id": "rift_%d" % _next_id, "pos": cell, "dir": "", "to_floor": 0, "kind": "rift", "rift": rift_id, "found": false})
	_next_id += 1
	s.lights.add_cell(s.map, cell, maxf(0.01, float(s.db.bal("explore.meters_per_tile", 1.0))))
	s.refresh_view()
	return true


func _far_cell(s: ExploreSession) -> Vector2i:
	var min_d := float(s.db.bal("rift.portal_min_distance", 8))
	for tries in 400:
		var p := Vector2i(s.rng.randi_range(1, s.map.width - 2), s.rng.randi_range(1, s.map.height - 2))
		if _free(s, p) and Vector2(p - s.pos).length() >= min_d \
				and not s.map.portals.any(func(q: Dictionary) -> bool: return Vector2(q["pos"] - p).length() < min_d):
			return p
	return Vector2i(-1, -1)


func _cell_near(s: ExploreSession, near: Vector2i) -> Vector2i:
	for r in range(1, 5):
		for d: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r), Vector2i(r, r), Vector2i(-r, r), Vector2i(r, -r), Vector2i(-r, -r)]:
			if _free(s, near + d) and near + d != s.pos:
				return near + d
	return Vector2i(-1, -1)


func _free(s: ExploreSession, p: Vector2i) -> bool:
	return s.map.in_bounds(p) and s.map.is_walkable(p) and s.map.portal_at(p).is_empty() \
		and not s.map.in_safe_zone(p) and s.monsters.group_at(p) == null
