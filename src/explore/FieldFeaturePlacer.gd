class_name FieldFeaturePlacer
extends RefCounted
## 동굴 요소 놓기(생성기가 지도를 다 만든 뒤 — 1층은 굽는 때 한 번, 좌표가 고정 지도 파일에 남는다).
## 층 JSON "features": [{"event": data/events id, "count", "spot", "zones"(선택 — 없으면 전부), "gap"(같은 종류끼리 최소 거리)}],
## "features_gap": 서로 다른 요소끼리 최소 거리. 자리(spot):
##   room       사방 8칸이 모두 동굴 바닥(공동·방 안)          wall     벽에 붙은 바닥
##   corridor   좁은 굴(사방 8칸 중 바닥 5칸 이하)              crystal  수정벽에 붙은 바닥
##   crystal_room  방 안이면서 둘레 5칸 안에 수정벽 5개 이상   dark_edge  암흑지대에 막 들어선 곳(경계에서 5칸 안)
##   near_portal   포탈에서 5~10칸(암흑지대)                    near_monument  기념비에서 5~8칸
## 모든 요소는 걸을 수 있는 칸이라(장애물이 아니다) 연결·나침반 경로·통로 폭을 깨지 않는다.
## 빛나는 타일(이끼·모닥불)은 암흑지대와 그 둘레에 두지 않는다. 기념비 안전지대(근처 기념비 자리 제외)·포탈·랜드마크 칸은 피한다.
## 벽 바로 뒤(남쪽 칸이 벽 — 3/4 시점에서 벽 윗면에 가려 안 보인다)에 떨어진 요소는 다 놓은 뒤 같은 자리 종류의 가장 가까운 보이는 칸으로 옮긴다
## (난수를 쓰지 않아 다른 요소 자리는 그대로 — 사용자 요청 2026-10-25 "벽에 가려지는 수정버섯 등").

const SPOTS := ["room", "wall", "corridor", "crystal", "crystal_room", "dark_edge", "near_portal", "near_monument"]


static func place(db: GameDatabase, map: FloorMap, lay: CrossLayout, floor_def: Dictionary, g: Dictionary, rng: Rng) -> void:
	var specs := JsonUtil.get_array(floor_def, "features")
	if specs.is_empty():
		return
	var floor_index := map.index_of(JsonUtil.get_str(JsonUtil.get_dict(g, "tiles"), "floor"))
	var no_light := lay.no_light_mask(map, JsonUtil.get_int(g, "crystal_dark_margin", 3))
	var spots := _spots(map, lay, floor_index)
	var gap_any := JsonUtil.get_float(floor_def, "features_gap", 6.0)
	var placed: Array[Vector2i] = []
	var first := map.features.size()
	var rules: Array[Dictionary] = []  # 놓은 요소마다 {cand, gap} — 가려진 것을 옮길 때 쓴다
	for s: Variant in specs:
		var sd: Dictionary = s if s is Dictionary else {}
		var ev := db.get_entry("events", JsonUtil.get_str(sd, "event"))
		if ev.is_empty():
			continue
		var tile := JsonUtil.get_str(ev, "tile")
		var lit := not tile.is_empty() and db.has_entry("tiles", tile) and not JsonUtil.get_dict(db.get_entry("tiles", tile), "light").is_empty()
		var zones := JsonUtil.get_array(sd, "zones")
		var pool: Array = spots.get(JsonUtil.get_str(sd, "spot", "room"), [])
		var cand: Array[Vector2i] = []
		for p: Vector2i in pool:
			if (zones.is_empty() or zones.has(map.zone_at(p))) and not (lit and no_light[map.idx(p)] != 0):
				cand.append(p)
		var mine: Array[Vector2i] = []
		var gap := JsonUtil.get_float(sd, "gap", 20.0)
		for n in JsonUtil.get_int(sd, "count", 1):
			var at := _pick(cand, placed, mine, gap_any, gap, rng)
			if at.x < 0:
				push_warning("동굴 요소 '%s': 놓을 자리가 모자라 %d개만 놓았다" % [ev.get("id"), n])
				break
			mine.append(at)
			placed.append(at)
			map.features.append({"id": JsonUtil.get_str(ev, "id"), "pos": at})
			rules.append({"cand": cand, "gap": gap})
	_lift_hidden(map, first, rules, gap_any)


## 벽 윗면에 가리는 칸인가(바로 남쪽 칸이 벽 — 벽은 앞면 높이만큼 위로 그려 윗줄 칸을 덮는다).
static func hidden_by_wall(map: FloorMap, p: Vector2i) -> bool:
	var s := p + Vector2i(0, 1)
	return not map.in_bounds(s) or map.is_wall(s)


## 가려진 요소를 같은 후보 중 가장 가까운 보이는 칸으로(다른 요소와의 거리 규칙은 그대로 지킨다). 갈 곳이 없으면 그대로 둔다.
static func _lift_hidden(map: FloorMap, first: int, rules: Array[Dictionary], gap_any: float) -> void:
	for k in range(first, map.features.size()):
		var f: Dictionary = map.features[k]
		var p: Vector2i = f["pos"]
		if not hidden_by_wall(map, p):
			continue
		var others: Array[Vector2i] = []
		var kin: Array[Vector2i] = []
		for j in map.features.size():
			if j != k:
				others.append(map.features[j]["pos"])
				if map.features[j]["id"] == f["id"]:
					kin.append(map.features[j]["pos"])
		var rule: Dictionary = rules[k - first]
		var best := Vector2i(-1, -1)
		var best_d := INF
		for q: Vector2i in rule["cand"]:
			var d := float((q - p).length_squared())
			if d >= best_d or hidden_by_wall(map, q):
				continue
			if _far(q, others, gap_any) and _far(q, kin, float(rule["gap"])):
				best = q
				best_d = d
		if best.x >= 0:
			f["pos"] = best


## 요소의 보이는 타일을 지도에 깐다(숨은 것·함정은 세션이 다룬다). 생성기·고정 지도 읽기가 같이 쓴다.
static func apply_tiles(db: GameDatabase, map: FloorMap) -> void:
	for f: Dictionary in map.features:
		var ev := db.get_entry("events", str(f["id"]))
		var tile := JsonUtil.get_str(ev, "tile")
		if not tile.is_empty() and not ev.has("hidden") and not ev.has("hazard"):
			map.set_tile(f["pos"], tile)


static func _pick(cand: Array[Vector2i], placed: Array[Vector2i], mine: Array[Vector2i], gap_any: float, gap: float, rng: Rng) -> Vector2i:
	for attempt in 200:
		if cand.is_empty():
			break
		var p: Vector2i = cand[rng.randi_range(0, cand.size() - 1)]
		if _far(p, placed, gap_any) and _far(p, mine, gap):
			return p
	return Vector2i(-1, -1)


static func _far(p: Vector2i, list: Array[Vector2i], d: float) -> bool:
	for q in list:
		if Vector2(p - q).length() < d:
			return false
	return true


## 걷는 칸을 한 번 훑어 자리 종류별 후보를 모은다.
static func _spots(map: FloorMap, lay: CrossLayout, floor_index: int) -> Dictionary:
	var out := {}
	for s: String in SPOTS:
		out[s] = []
	var crystal := map.index_of("crystal_wall")
	var portals: Array[Vector2i] = []
	for portal: Dictionary in map.portals:
		portals.append(portal["pos"])
	for i in map.tiles.size():
		if map.tiles[i] != floor_index:
			continue
		var p := map.pos_of(i)
		if p.x < 6 or p.y < 6 or p.x >= map.width - 6 or p.y >= map.height - 6 or _inside_landmark(map, p):
			continue
		var d_center := Vector2(p - map.center).length()
		if d_center >= 5.0 and d_center <= 8.0:
			(out["near_monument"] as Array).append(p)
		if map.in_safe_zone(p) or d_center < 12.0:
			continue
		var floors := 0
		var walls := 0
		var crystals := 0
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var q := p + Vector2i(dx, dy)
				if map.is_walkable(q):
					floors += 1
				elif map.tiles[map.idx(q)] == crystal:
					crystals += 1
				if map.is_wall(q) and (dx == 0 or dy == 0):
					walls += 1
		var dark := map.is_dark(p)
		if dark:
			var depth := lay.arm_depth(p) - lay.dark_start()
			if depth >= 1 and depth <= 5:
				(out["dark_edge"] as Array).append(p)
			for q in portals:
				var d := Vector2(p - q).length()
				if d >= 5.0 and d <= 10.0:
					(out["near_portal"] as Array).append(p)
		if floors == 8:
			(out["room"] as Array).append(p)
			if not dark and _crystals_near(map, p, crystal, 5) >= 5:
				(out["crystal_room"] as Array).append(p)
		elif floors <= 5:
			(out["corridor"] as Array).append(p)
		if walls > 0:
			(out["wall"] as Array).append(p)
		if crystals > 0:
			(out["crystal"] as Array).append(p)
	return out


static func _crystals_near(map: FloorMap, p: Vector2i, crystal: int, r: int) -> int:
	var n := 0
	for y in range(p.y - r, p.y + r + 1):
		for x in range(p.x - r, p.x + r + 1):
			if map.tiles[y * map.width + x] == crystal:
				n += 1
	return n


static func _inside_landmark(map: FloorMap, p: Vector2i) -> bool:
	for rec: Dictionary in map.landmarks:
		if (rec["rect"] as Rect2i).grow(2).has_point(p):
			return true
	return false
