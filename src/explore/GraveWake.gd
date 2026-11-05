class_name GraveWake
extends RefCounted
## 망자의 땅 비석(docs/plans/floor2.md §3): 원정마다 구역 zone 안 무작위 자리에 비석(동굴 요소 event) 하나가 선다.
## 원정 day일 차가 되면(시계 = 원정 시계 — 층과 무관) 비석에서 monster가 깨어난다(지도에 보스 무리 — 보이면 등장 연출 뒤 전투).
## 그 전에 비석을 부수면(요소 행동 clear — 근력 판정, FieldFeatureAct check) 깨어나지 않는다.
## 층 JSON "grave_wake": {"event", "zone", "min_entry_tiles", "day", "monster", "line", "sound"}. 입장마다 새로(층이 새 지도라서).

var pos: Vector2i = Vector2i(-1, -1)
var woke: bool = false
var _def: Dictionary = {}


## 입장 때 비석 자리를 정해 세운다. 자리가 없으면 아무것도 하지 않는다.
func setup(s: ExploreSession, d: Dictionary) -> void:
	_def = d
	var zone := JsonUtil.get_str(d, "zone")
	var far := float(JsonUtil.get_int(d, "min_entry_tiles", 40))
	var event := s.db.get_entry("events", JsonUtil.get_str(d, "event"))
	if event.is_empty():
		return
	for tries in 600:
		var p := Vector2i(s.rng.randi_range(2, s.map.width - 3), s.rng.randi_range(2, s.map.height - 3))
		if s.map.zone_at(p) != zone or Vector2(p - s.map.entry).length() < far or not s.map.portal_at(p).is_empty():
			continue
		if FloorMap.DIRS4.all(func(dd: Vector2i) -> bool: return s.map.is_walkable(p + dd)) and s.map.is_walkable(p):
			pos = p
			break
	if pos.x < 0:
		return
	s.map.set_tile(pos, JsonUtil.get_str(event, "tile"))
	s.features.add_at(s, JsonUtil.get_str(d, "event"), pos)


## 시간이 흐를 때(ExploreSession.pass_time). 깨어날 때가 됐고 비석이 서 있으면 깨운다. 깨웠으면 true.
func update(s: ExploreSession) -> bool:
	if woke or pos.x < 0 or s.clock.total_hours < (JsonUtil.get_float(_def, "day", 7.0) - 1.0) * 24.0:
		return false
	if not s.features.live_at(pos):
		woke = true  # 부순 비석 — 아무것도 깨어나지 않는다
		return false
	woke = true
	var mid := JsonUtil.get_str(_def, "monster")
	var g := s.monsters.add_fixed([mid], pos + Vector2i(0, 1))
	if g == null:
		return false
	s.message.emit(JsonUtil.get_str(_def, "line", "explore.grave_wakes"), {}, "danger")
	s.sound.emit(JsonUtil.get_str(_def, "sound", "boss_reveal"), pos)
	return true


## 부서졌는가(살필 행동이 남지 않은 비석).
func broken(s: ExploreSession) -> bool:
	return pos.x >= 0 and not s.features.live_at(pos)
