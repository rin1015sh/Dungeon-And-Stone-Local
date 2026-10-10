class_name CrystalCaveGenerator
extends FloorGenerator
## 1층 수정동굴 생성기. 입장할 때마다 지형이 바뀌지만 고정 랜드마크는 항상 있다.
## 순서: 셀룰러 오토마타 동굴 → 중앙 공터 → 영역 잇기 → 랜드마크 도장(중앙 기념비 + 무작위)
##       → 동서남북 포탈 → 암흑지대 → 수정벽 → 시작 위치 → 안전지대.
## 불변식: 걸을 수 있는 칸은 모두 기념비 옆 칸에서 걸어서 닿는다(테스트가 확인한다).

const DIRECTION_AXES := {"east": Vector2i(1, 0), "west": Vector2i(-1, 0), "south": Vector2i(0, 1), "north": Vector2i(0, -1)}
const STAMP_TRIES := 40


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var tiles := JsonUtil.get_dict(g, "tiles")
	var size: Array = JsonUtil.get_array(g, "size")
	var w := int(size[0])
	var h := int(size[1])
	var center := Vector2i(w / 2, h / 2)

	var cells := GridAlgo.random_fill(w, h, JsonUtil.get_float(g, "fill_ratio", 0.45), rng)
	for i in JsonUtil.get_int(g, "smooth_steps", 5):
		cells = GridAlgo.smooth(cells, w, h)
	GridAlgo.carve_disc(cells, w, h, center, JsonUtil.get_float(g, "center_radius", 5.0))
	GridAlgo.connect_regions(cells, w, h, center, JsonUtil.get_int(g, "min_region", 30), rng)

	var map := FloorMap.new(db, w, h, JsonUtil.get_str(tiles, "wall"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	map.center = center
	var floor_tile := JsonUtil.get_str(tiles, "floor")
	for i in w * h:
		if cells[i] == 0:
			map.tiles[i] = map.index_of(floor_tile)

	_place_landmarks(db, map, floor_def, rng)
	_place_portals(map, floor_def, tiles, rng)
	_place_dark_zones(map, g, rng)
	_place_crystals(map, g, tiles, rng)
	_place_entry(map, g, floor_tile, rng)
	return map


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var g := JsonUtil.get_dict(floor_def, "gen")
	var size := JsonUtil.get_array(g, "size")
	if size.size() != 2 or not JsonUtil.is_number(size[0]) or int(size[0]) < 24 or int(size[1]) < 24:
		out.append("crystal_cave: gen.size는 [24 이상, 24 이상]")
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
	return out


# ── 랜드마크 ─────────────────────────────────────────────

func _place_landmarks(db: GameDatabase, map: FloorMap, floor_def: Dictionary, rng: Rng) -> void:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var min_dist := JsonUtil.get_float(g, "landmark_min_distance", 10.0)
	for spec: Variant in JsonUtil.get_array(floor_def, "landmarks"):
		var sd: Dictionary = spec if spec is Dictionary else {}
		var lm := db.get_entry("landmarks", JsonUtil.get_str(sd, "id"))
		if lm.is_empty():
			continue
		if JsonUtil.get_str(sd, "placement") == "center":
			_stamp_at(map, lm, map.center)
			map.safe_zones.append({"center": map.center, "radius": JsonUtil.get_float(sd, "safe_zone_radius", 4.0)})
			continue
		for n in JsonUtil.get_int(sd, "count", 1):
			_stamp_random(map, lm, min_dist, rng)


## 기준 칸(anchor)이 at에 오도록 도장을 찍고 랜드마크로 기록한다.
func _stamp_at(map: FloorMap, lm: Dictionary, at: Vector2i) -> Dictionary:
	var stamp := JsonUtil.get_array(lm, "stamp")
	var top_left := at - GridAlgo.stamp_anchor(stamp, JsonUtil.get_str(lm, "anchor"))
	GridAlgo.apply_stamp(map, top_left, stamp, JsonUtil.get_dict(lm, "legend"))
	var record := {"id": JsonUtil.get_str(lm, "id"), "pos": at, "rect": Rect2i(top_left, GridAlgo.stamp_size(stamp)), "found": false}
	map.landmarks.append(record)
	return record


## 무작위 자리에 찍되, 모든 바닥이 여전히 이어져 있을 때만 남긴다(아니면 되돌리고 다시).
func _stamp_random(map: FloorMap, lm: Dictionary, min_dist: float, rng: Rng) -> void:
	var size := GridAlgo.stamp_size(JsonUtil.get_array(lm, "stamp"))
	for attempt in STAMP_TRIES:
		var at := Vector2i(rng.randi_range(size.x + 1, map.width - size.x - 2), rng.randi_range(size.y + 1, map.height - size.y - 2))
		if not map.is_walkable(at) or not _far_from_landmarks(map, at, min_dist):
			continue
		var backup := map.tiles.duplicate()
		var record := _stamp_at(map, lm, at)
		if _all_walkable_connected(map):
			return
		map.tiles = backup
		map.landmarks.erase(record)
	push_warning("crystal_cave: 랜드마크 '%s'를 놓을 자리를 찾지 못했다" % lm.get("id"))


func _far_from_landmarks(map: FloorMap, at: Vector2i, min_dist: float) -> bool:
	for rec: Dictionary in map.landmarks:
		if Vector2(at - (rec["pos"] as Vector2i)).length() < min_dist:
			return false
	return true


func _anchor_cell(map: FloorMap) -> Vector2i:
	for r in range(1, 4):
		for d in FloorMap.DIRS4:
			var p := map.center + d * r
			if map.is_walkable(p):
				return p
	return map.center


func _all_walkable_connected(map: FloorMap) -> bool:
	var reach := map.reachable_from(_anchor_cell(map))
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable and reach[i] == 0:
			return false
	return true


# ── 포탈·암흑지대·수정벽·시작 위치 ───────────────────────

## 각 방향으로 가장 멀리 나간 바닥 칸(상위 band 이내에서 무작위)에 포탈을 둔다.
func _place_portals(map: FloorMap, floor_def: Dictionary, tiles: Dictionary, rng: Rng) -> void:
	var band := JsonUtil.get_int(JsonUtil.get_dict(floor_def, "gen"), "portal_pick_band", 2)
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	for spec: Variant in JsonUtil.get_array(floor_def, "portals"):
		var sd: Dictionary = spec if spec is Dictionary else {}
		var axis: Vector2i = DIRECTION_AXES.get(JsonUtil.get_str(sd, "dir"), Vector2i.ZERO)
		var best := -map.width - map.height
		for i in map.tiles.size():
			if map.tiles[i] == floor_index:
				best = maxi(best, _axis_score(map, map.pos_of(i), axis))
		var candidates: Array[Vector2i] = []
		for i in map.tiles.size():
			if map.tiles[i] == floor_index and _axis_score(map, map.pos_of(i), axis) >= best - band:
				candidates.append(map.pos_of(i))
		if candidates.is_empty():
			continue
		var at: Vector2i = rng.pick(candidates)
		map.set_tile(at, JsonUtil.get_str(tiles, "portal"))
		map.portals.append({"id": JsonUtil.get_str(sd, "id"), "pos": at, "dir": JsonUtil.get_str(sd, "dir"),
			"to_floor": JsonUtil.get_int(sd, "to_floor"), "found": false})


## 중심에서 axis 방향으로 얼마나 나갔는지.
func _axis_score(map: FloorMap, p: Vector2i, axis: Vector2i) -> int:
	var d := p - map.center
	return d.x * axis.x + d.y * axis.y


func _place_dark_zones(map: FloorMap, g: Dictionary, rng: Rng) -> void:
	var count_range := JsonUtil.get_array(g, "dark_zone_count")
	var radius_range := JsonUtil.get_array(g, "dark_zone_radius")
	if count_range.size() != 2 or radius_range.size() != 2:
		return
	var min_dist := JsonUtil.get_float(g, "dark_zone_min_distance", 12.0)
	for n in rng.randi_range(int(count_range[0]), int(count_range[1])):
		var radius := float(rng.randi_range(int(radius_range[0]), int(radius_range[1])))
		for attempt in STAMP_TRIES:
			var at := Vector2i(rng.randi_range(1, map.width - 2), rng.randi_range(1, map.height - 2))
			if not map.is_walkable(at) or Vector2(at - map.center).length() < min_dist:
				continue
			if not _clear_of_features(map, at, radius + 2.0):
				continue
			var r := ceili(radius)
			for y in range(at.y - r, at.y + r + 1):
				for x in range(at.x - r, at.x + r + 1):
					var p := Vector2i(x, y)
					if map.in_bounds(p) and Vector2(p - at).length() <= radius:
						map.dark[map.idx(p)] = 1
			break


func _clear_of_features(map: FloorMap, at: Vector2i, dist: float) -> bool:
	for portal: Dictionary in map.portals:
		if Vector2(at - (portal["pos"] as Vector2i)).length() < dist:
			return false
	for rec: Dictionary in map.landmarks:
		if Vector2(at - (rec["pos"] as Vector2i)).length() < dist:
			return false
	return true


## 바닥에 맞닿은 바위벽 일부를 빛나는 수정벽으로(암흑지대 제외).
func _place_crystals(map: FloorMap, g: Dictionary, tiles: Dictionary, rng: Rng) -> void:
	var chance := JsonUtil.get_float(g, "crystal_wall_chance", 0.06)
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	for i in map.tiles.size():
		if map.tiles[i] != wall_index or map.dark[i] != 0:
			continue
		var p := map.pos_of(i)
		var open := false
		for d in FloorMap.DIRS4:
			if map.is_walkable(p + d):
				open = true
				break
		if open and rng.chance(chance):
			map.set_tile(p, JsonUtil.get_str(tiles, "crystal"))


## 시작 위치: 기념비에서 멀고, 어둡지 않은 바닥. 없으면 가장 먼 바닥.
func _place_entry(map: FloorMap, g: Dictionary, floor_tile: String, rng: Rng) -> void:
	var min_dist := JsonUtil.get_float(g, "entry_min_distance", 14.0)
	var floor_index := map.index_of(floor_tile)
	var candidates: Array[Vector2i] = []
	var farthest := map.center
	for i in map.tiles.size():
		if map.tiles[i] != floor_index or map.dark[i] != 0:
			continue
		var p := map.pos_of(i)
		var d := Vector2(p - map.center).length()
		if d >= min_dist and not _inside_landmark(map, p):
			candidates.append(p)
		if d > Vector2(farthest - map.center).length():
			farthest = p
	map.entry = rng.pick(candidates) if not candidates.is_empty() else farthest


func _inside_landmark(map: FloorMap, p: Vector2i) -> bool:
	for rec: Dictionary in map.landmarks:
		if (rec["rect"] as Rect2i).has_point(p):
			return true
	return false
