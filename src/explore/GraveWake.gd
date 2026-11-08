class_name GraveWake
extends RefCounted
## 망자의 땅 비석(docs/plans/floor2.md §3): 원정마다 구역 zone 안 무작위 자리에 비석(동굴 요소 event) 하나가 선다.
## 원정 day일 차가 되면(시계 = 원정 시계 — 층과 무관) 비석에서 monster가 깨어난다(지도에 보스 무리 — 보이면 등장 연출 뒤 전투).
## 그 전에 비석을 부수면(요소 행동 clear — 근력 판정, FieldFeatureAct check) 깨어나지 않는다.
## 층 JSON "grave_wake": {"event", "node"(비석 터 구간 — 그 안 무작위 자리) 또는 "zone" + "min_entry_tiles", "stand_at"(깨어나 설 구간 —
## 없으면 비석 아래 칸), "day", "monster", "line", "sound", "omens"}. 비석 자리는 원정마다 새로.
## 징조(레벨 디자인 LD — 깨어나기 전에 날마다 단서): "omens": [{"day", "event"(요소 — 시체 등, 선택), "tile"(그 칸 그림 — 선택),
##   "near": "grave" | "stand_at"(어디 둘레 — 기본 grave), "sound"(소리 키 — 선택)}]. 그날이 되면 비석이 서 있을 때만 한 번
##   그 둘레 빈 칸에 요소나 그림을 놓는다(3일 차 새 시체 · 4일 차 비석 곁 푸른 불 · 갑옷 소리). 비석 살피기 문구는 날마다 다르다(line_day).

var pos: Vector2i = Vector2i(-1, -1)
var woke: bool = false
var _def: Dictionary = {}
var _omens_done: Array[int] = []  ## 이미 놓은 징조(omens 번호)


## 입장 때 비석 자리를 정해 세운다. 자리가 없으면 아무것도 하지 않는다.
func setup(s: ExploreSession, d: Dictionary) -> void:
	_def = d
	var zone := JsonUtil.get_str(d, "zone")
	var far := float(JsonUtil.get_int(d, "min_entry_tiles", 40))
	var event := s.db.get_entry("events", JsonUtil.get_str(d, "event"))
	if event.is_empty():
		return
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	var node := JsonUtil.get_str(d, "node")
	for tries in 600:
		var p := Vector2i(s.rng.randi_range(2, s.map.width - 3), s.rng.randi_range(2, s.map.height - 3))
		if not node.is_empty() and nodes.has(node):  # 비석 터 구간 안(가장자리 빼고)
			var r := float((s.map.anchors.get("node_r", {}) as Dictionary).get(node, 6.0)) * 0.7
			p = (nodes[node] as Vector2i) + Vector2i(s.rng.randi_range(-int(r), int(r)), s.rng.randi_range(-int(r), int(r)))
		elif s.map.zone_at(p) != zone or Vector2(p - s.map.entry).length() < far:
			continue
		if not s.map.portal_at(p).is_empty() or s.features.live_at(p):
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
	if not woke and pos.x >= 0:
		_omens(s)
	if woke or pos.x < 0 or s.clock.total_hours < (JsonUtil.get_float(_def, "day", 7.0) - 1.0) * 24.0:
		return false
	if not s.features.live_at(pos):
		woke = true  # 부순 비석 — 아무것도 깨어나지 않는다
		return false
	woke = true
	var mid := JsonUtil.get_str(_def, "monster")
	var at := pos + Vector2i(0, 1)
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	if nodes.has(JsonUtil.get_str(_def, "stand_at")):
		at = nodes[JsonUtil.get_str(_def, "stand_at")]  # 묘역 문을 막고 선다(floor2.md §13-2)
	var g := s.monsters.add_fixed([mid], at)
	if g == null:
		return false
	s.fx.emit("burst", at, -1)
	s.message.emit(JsonUtil.get_str(_def, "line", "explore.grave_wakes"), {}, "danger")
	s.sound.emit(JsonUtil.get_str(_def, "sound", "boss_reveal"), pos)
	return true


## 부서졌는가(살필 행동이 남지 않은 비석).
func broken(s: ExploreSession) -> bool:
	return pos.x >= 0 and not s.features.live_at(pos)


## 그날이 된 징조를 놓는다(비석이 서 있을 때만).
func _omens(s: ExploreSession) -> void:
	var list := JsonUtil.get_array(_def, "omens")
	for i in list.size():
		var o: Dictionary = list[i] if list[i] is Dictionary else {}
		if _omens_done.has(i) or s.clock.total_hours < (JsonUtil.get_float(o, "day", 99.0) - 1.0) * 24.0:
			continue
		_omens_done.append(i)
		if not s.features.live_at(pos):
			continue  # 부순 비석 — 징조도 없다
		var c := pos
		var nodes: Dictionary = s.map.anchors.get("nodes", {})
		if JsonUtil.get_str(o, "near") == "stand_at" and nodes.has(JsonUtil.get_str(_def, "stand_at")):
			c = nodes[JsonUtil.get_str(_def, "stand_at")]
		var cell := _free_near(s, c)
		if cell.x < 0:
			continue
		var ev := JsonUtil.get_str(o, "event")
		if not ev.is_empty():
			s.features.add_at(s, ev, cell)  # 그림은 아래 tile(층마다 다른 시체 그림)
		if o.has("tile"):
			s.map.set_tile(cell, JsonUtil.get_str(o, "tile"))
			s.tiles_changed.emit(Rect2i(cell, Vector2i.ONE))
		if o.has("sound"):
			s.sound.emit(JsonUtil.get_str(o, "sound"), pos)


## c 둘레(2~4칸) 걸을 수 있고 요소 · 포탈이 없으며 사방이 트인 칸 — 길을 막지 않게. 없으면 (-1, -1).
func _free_near(s: ExploreSession, c: Vector2i) -> Vector2i:
	for r in range(2, 5):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := c + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) != r or not s.map.in_bounds(q) or not s.map.is_walkable(q) or s.features.has_at(q) \
						or not s.map.portal_at(q).is_empty():
					continue
				if FloorMap.DIRS4.all(func(d: Vector2i) -> bool: return s.map.is_walkable(q + d)):
					return q
	return Vector2i(-1, -1)
