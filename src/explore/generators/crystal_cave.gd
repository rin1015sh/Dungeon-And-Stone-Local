class_name CrystalCaveGenerator
extends FloorGenerator
## 1층 수정동굴 생성기 — 거대한 두꺼운 십자가(CrossLayout: 중심부 + 동·서·남·북 팔).
## 고정(시드 무관): 십자가 구역, 중앙 대현자 기념비, 팔 끝 2층 포탈 4개, 팔 끝 암흑지대 4곳.
## 입장마다 새로(시드): 중심부 동굴(셀룰러 오토마타), 팔 안의 스파게티 동굴(CaveCarver), 무작위 랜드마크, 수정벽, 시작 위치.
## 순서: 동굴 지형(CrossTerrain) → 타일·구역·암흑지대 → 기념비 → 포탈 → 무작위 랜드마크 → 수정벽(암흑지대 제외) → 시작 위치.
## 불변식(테스트가 확인): 걷는 칸은 모두 이어져 있고, 기념비 옆에서 네 포탈 모두 그 팔 방향으로만(뒤로 가지 않고) 걸어 닿는다.

const STAMP_TRIES := 60


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var lay := CrossLayout.new(g)
	var cells := CrossTerrain.build(lay, g, rng)
	var tiles := JsonUtil.get_dict(g, "tiles")
	var map := _to_map(db, floor_def, lay, cells, tiles, rng)
	_place_monument(db, map, floor_def)
	_place_portals(map, lay, floor_def, tiles)
	_place_random_landmarks(db, map, lay, floor_def, rng)
	_place_crystals(map, lay, g, tiles, rng)
	_place_entry(map, lay, g, JsonUtil.get_str(tiles, "floor"), rng)
	return map


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var g := JsonUtil.get_dict(floor_def, "gen")
	var lay := CrossLayout.new(g)
	if lay.core_half < 6 or lay.arm_half < 4 or lay.arm_length < 16:
		out.append("crystal_cave: gen.core_size ≥ 13, arm_width ≥ 9, arm_length ≥ 16")
	if lay.arm_half > lay.core_half:
		out.append("crystal_cave: gen.arm_width는 core_size 이하")
	if lay.dark_depth < 1 or lay.dark_depth >= lay.arm_length - 4:
		out.append("crystal_cave: gen.dark_depth는 1 이상, arm_length - 4 미만")
	if lay.portal_inset < 3 or lay.portal_inset >= lay.dark_depth:
		out.append("crystal_cave: gen.portal_inset은 3 이상, dark_depth 미만(포탈은 암흑지대 안)")
	var tiles := JsonUtil.get_dict(g, "tiles")
	for key: String in ["floor", "wall", "crystal", "portal"]:
		if not db.has_entry("tiles", JsonUtil.get_str(tiles, key)):
			out.append("crystal_cave: gen.tiles.%s 타일 없음" % key)
	var centers := 0
	for lm: Variant in JsonUtil.get_array(floor_def, "landmarks"):
		if lm is Dictionary and JsonUtil.get_str(lm, "placement") == "center":
			centers += 1
	if centers != 1:
		out.append("crystal_cave: placement=center 랜드마크(기념비)가 정확히 하나 필요")
	for r: Variant in JsonUtil.get_array(floor_def, "regions"):
		var zone := JsonUtil.get_str(r if r is Dictionary else {}, "zone")
		if zone != CrossLayout.ZONE_CENTER and not CrossLayout.ARMS.has(zone):
			out.append("crystal_cave: regions.zone '%s'는 center/east/west/south/north 중 하나" % zone)
	var dirs := {}
	for p: Variant in JsonUtil.get_array(floor_def, "portals"):
		var pd: Dictionary = p if p is Dictionary else {}
		dirs[JsonUtil.get_str(pd, "dir")] = true
		if JsonUtil.get_str(pd, "dest").is_empty():
			out.append("crystal_cave: portals.dest(도착 지점 id)가 비었다")
	if dirs.size() != 4 or not CrossLayout.ARMS.all(func(d: String) -> bool: return dirs.has(d)):
		out.append("crystal_cave: portals는 east/west/south/north에 하나씩")
	return out


func _to_map(db: GameDatabase, floor_def: Dictionary, lay: CrossLayout, cells: PackedByteArray, tiles: Dictionary, rng: Rng) -> FloorMap:
	var map := FloorMap.new(db, lay.side, lay.side, JsonUtil.get_str(tiles, "wall"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	map.center = lay.center
	for z: String in [CrossLayout.ZONE_CENTER] + Array(CrossLayout.ARMS):
		map.zone_ids.append(z)
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	for i in map.tiles.size():
		var p := map.pos_of(i)
		if cells[i] == 0:
			map.tiles[i] = floor_index
		var zone := lay.zone_of(p)
		if not zone.is_empty():
			map.set_zone(p, zone)
		if lay.is_dark(p):
			map.dark[i] = 1
	return map


# ── 고정 장소 ─────────────────────────────────────────────

func _place_monument(db: GameDatabase, map: FloorMap, floor_def: Dictionary) -> void:
	for spec: Variant in JsonUtil.get_array(floor_def, "landmarks"):
		var sd: Dictionary = spec if spec is Dictionary else {}
		if JsonUtil.get_str(sd, "placement") != "center":
			continue
		var lm := db.get_entry("landmarks", JsonUtil.get_str(sd, "id"))
		if not lm.is_empty():
			_stamp_at(map, lm, map.center)
			map.safe_zones.append({"center": map.center, "radius": JsonUtil.get_float(sd, "safe_zone_radius", 4.0)})


## 팔 끝(암흑지대 안) 고정 자리에 2층 포탈. dest = 2층 도착 지점 id(포탈마다 다르다).
func _place_portals(map: FloorMap, lay: CrossLayout, floor_def: Dictionary, tiles: Dictionary) -> void:
	for spec: Variant in JsonUtil.get_array(floor_def, "portals"):
		var sd: Dictionary = spec if spec is Dictionary else {}
		var dir := JsonUtil.get_str(sd, "dir")
		if not CrossLayout.ARMS.has(dir):
			continue
		var at := lay.portal_pos(dir)
		map.set_tile(at, JsonUtil.get_str(tiles, "portal"))
		map.portals.append({"id": JsonUtil.get_str(sd, "id"), "pos": at, "dir": dir, "to_floor": JsonUtil.get_int(sd, "to_floor"),
			"dest": JsonUtil.get_str(sd, "dest"), "found": false})


## 기준 칸(anchor)이 at에 오도록 도장을 찍고 랜드마크로 기록한다.
func _stamp_at(map: FloorMap, lm: Dictionary, at: Vector2i) -> Dictionary:
	var stamp := JsonUtil.get_array(lm, "stamp")
	var top_left := at - GridAlgo.stamp_anchor(stamp, JsonUtil.get_str(lm, "anchor"))
	GridAlgo.apply_stamp(map, top_left, stamp, JsonUtil.get_dict(lm, "legend"))
	var record := {"id": JsonUtil.get_str(lm, "id"), "pos": at, "rect": Rect2i(top_left, GridAlgo.stamp_size(stamp)), "found": false}
	map.landmarks.append(record)
	return record


## 무작위 랜드마크: 암흑지대 밖 바닥에 찍되, 연결성과 나침반 경로가 그대로일 때만 남긴다(아니면 되돌리고 다시).
func _place_random_landmarks(db: GameDatabase, map: FloorMap, lay: CrossLayout, floor_def: Dictionary, rng: Rng) -> void:
	var min_dist := JsonUtil.get_float(JsonUtil.get_dict(floor_def, "gen"), "landmark_min_distance", 10.0)
	for spec: Variant in JsonUtil.get_array(floor_def, "landmarks"):
		var sd: Dictionary = spec if spec is Dictionary else {}
		var lm := db.get_entry("landmarks", JsonUtil.get_str(sd, "id"))
		if lm.is_empty() or JsonUtil.get_str(sd, "placement") == "center":
			continue
		for n in JsonUtil.get_int(sd, "count", 1):
			_stamp_random(map, lay, lm, min_dist, rng)


func _stamp_random(map: FloorMap, lay: CrossLayout, lm: Dictionary, min_dist: float, rng: Rng) -> void:
	var size := GridAlgo.stamp_size(JsonUtil.get_array(lm, "stamp"))
	for attempt in STAMP_TRIES:
		var at := Vector2i(rng.randi_range(size.x + 1, map.width - size.x - 2), rng.randi_range(size.y + 1, map.height - size.y - 2))
		if not map.is_walkable(at) or not map.portal_at(at).is_empty() or not _rect_inside(map, lay, at, lm):
			continue
		if not _far_from(map, at, min_dist):
			continue
		var backup := map.tiles.duplicate()
		var record := _stamp_at(map, lm, at)
		if _all_walkable_connected(map) and _compass_ok(map):
			return
		map.tiles = backup
		map.landmarks.erase(record)
	push_warning("crystal_cave: 랜드마크 '%s'를 놓을 자리를 찾지 못했다" % lm.get("id"))


## 도장 전체(한 칸 둘레 포함)가 십자가 안이고 암흑지대 밖인가.
func _rect_inside(map: FloorMap, lay: CrossLayout, at: Vector2i, lm: Dictionary) -> bool:
	var stamp := JsonUtil.get_array(lm, "stamp")
	var r := Rect2i(at - GridAlgo.stamp_anchor(stamp, JsonUtil.get_str(lm, "anchor")), GridAlgo.stamp_size(stamp)).grow(1)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if map.zone_at(Vector2i(x, y)).is_empty() or lay.is_dark(Vector2i(x, y)):
				return false
	return true


func _far_from(map: FloorMap, at: Vector2i, min_dist: float) -> bool:
	for rec: Dictionary in map.landmarks + map.portals:
		if Vector2(at - (rec["pos"] as Vector2i)).length() < min_dist:
			return false
	return true


## 기념비 옆 칸(기념비에서 팔 방향으로 2칸).
static func monument_side(map: FloorMap, dir: String) -> Vector2i:
	return map.center + CrossLayout.axis(dir) * 2


func _compass_ok(map: FloorMap) -> bool:
	for portal: Dictionary in map.portals:
		var dir := str(portal["dir"])
		if not CrossLayout.compass_path(map, monument_side(map, dir), dir, portal["pos"]):
			return false
	return true


func _all_walkable_connected(map: FloorMap) -> bool:
	var reach := map.reachable_from(monument_side(map, "south"))
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable and reach[i] == 0:
			return false
	return true


# ── 수정벽·시작 위치 ─────────────────────────────────────

## 바닥에 맞닿은 바위벽 일부를 빛나는 수정벽으로. 암흑지대와 그 둘레 crystal_dark_margin칸에는 두지 않는다(빛이 새지 않게).
func _place_crystals(map: FloorMap, lay: CrossLayout, g: Dictionary, tiles: Dictionary, rng: Rng) -> void:
	var chance := JsonUtil.get_float(g, "crystal_wall_chance", 0.07)
	var margin := JsonUtil.get_int(g, "crystal_dark_margin", 3)
	var no_light: Array[Rect2i] = []
	for dir in CrossLayout.ARMS:
		no_light.append(lay.dark_rect(dir).grow(margin))
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	for i in map.tiles.size():
		if map.tiles[i] != wall_index:
			continue
		var p := map.pos_of(i)
		if no_light.any(func(r: Rect2i) -> bool: return r.has_point(p)):
			continue
		var open := false
		for d in FloorMap.DIRS4:
			if map.is_walkable(p + d):
				open = true
				break
		if open and rng.chance(chance):
			map.set_tile(p, JsonUtil.get_str(tiles, "crystal"))


## 시작 위치: 팔 안(암흑지대에서 entry_dark_margin칸 이상 떨어진 곳), 기념비에서 entry_min_distance 이상.
func _place_entry(map: FloorMap, lay: CrossLayout, g: Dictionary, floor_tile: String, rng: Rng) -> void:
	var min_dist := JsonUtil.get_float(g, "entry_min_distance", 18.0)
	var max_depth := lay.dark_start() - JsonUtil.get_int(g, "entry_dark_margin", 4)
	var floor_index := map.index_of(floor_tile)
	var candidates: Array[Vector2i] = []
	for i in map.tiles.size():
		var p := map.pos_of(i)
		if map.tiles[i] != floor_index or map.dark[i] != 0 or not CrossLayout.ARMS.has(map.zone_at(p)):
			continue
		if lay.arm_depth(p) <= max_depth and Vector2(p - map.center).length() >= min_dist and not _inside_landmark(map, p):
			candidates.append(p)
	map.entry = rng.pick(candidates) if not candidates.is_empty() else monument_side(map, "south")


func _inside_landmark(map: FloorMap, p: Vector2i) -> bool:
	for rec: Dictionary in map.landmarks:
		if (rec["rect"] as Rect2i).has_point(p):
			return true
	return false
