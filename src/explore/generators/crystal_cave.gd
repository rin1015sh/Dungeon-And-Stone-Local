class_name CrystalCaveGenerator
extends FloorGenerator
## 1층 수정동굴 생성기 — 거대한 두꺼운 십자가(CrossLayout: 중심부 + 동·서·남·북 팔).
## 고정(시드 무관): 십자가 구역, 중앙 대현자 기념비, 팔 끝 2층 포탈 4개, 팔 끝 암흑지대 4곳.
## 입장마다 새로(시드): 중심부 동굴(셀룰러 오토마타), 팔 안의 스파게티 동굴(CaveCarver), 무작위 랜드마크, 수정벽, 시작 위치.
## 순서: 동굴 지형(CrossTerrain) → 타일·구역·암흑지대 → 기념비 → 포탈 → 무작위 랜드마크 → 통로 폭 다시 맞추기
##       → 수정벽(암흑지대 제외) → 시작 위치.
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
	_widen_map(map, g, tiles)
	_trim_dead_ends(map, g, tiles)
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
			map.zones[i] = map.zone_ids.find(zone)
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


## 무작위 랜드마크: 십자가 안·암흑지대 밖 바닥에 찍는다. 도장은 벽을 찍지 않고 바닥과 그 바닥으로 둘러싼 장식(수정·바위·연못)만
## 찍으므로 연결과 나침반 경로를 깨지 않는다(둘레 바닥으로 옆걸음해 돌아갈 수 있다 — CrossLayoutCheck가 여러 시드로 확인).
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
		_stamp_at(map, lm, at)
		return
	push_warning("crystal_cave: 랜드마크 '%s'를 놓을 자리를 찾지 못했다" % lm.get("id"))


## 도장 전체(두 칸 둘레 포함)가 십자가 안이고 암흑지대 밖인가.
func _rect_inside(map: FloorMap, lay: CrossLayout, at: Vector2i, lm: Dictionary) -> bool:
	var stamp := JsonUtil.get_array(lm, "stamp")
	var r := Rect2i(at - GridAlgo.stamp_anchor(stamp, JsonUtil.get_str(lm, "anchor")), GridAlgo.stamp_size(stamp)).grow(2)
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


## 도장(연못·바위·수정)이 지형과 맞닿아 생긴 한 칸 폭 목을 둘레 바위벽을 깎아 2칸으로(GridWiden, 메우지는 않는다).
func _widen_map(map: FloorMap, g: Dictionary, tiles: Dictionary) -> void:
	var cells := GridWiden.walk_cells(map)
	var can := PackedByteArray()
	can.resize(cells.size())
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	for i in cells.size():
		can[i] = 1 if map.tiles[i] == wall_index and map.zones[i] != 0 else 0
	GridWiden.widen(cells, can, map.width, map.height, JsonUtil.get_int(g, "widen_passes", 6), false)
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	for i in cells.size():
		if cells[i] == 0 and map.tiles[i] == wall_index:
			map.tiles[i] = floor_index


## 막다른 곳(GridSpurs — 순환로·거점 사이 길에 속하지 않는 곁가지·홈)을 바위벽으로 메우고 폭을 다시 맞춘다(trim_passes번).
## → 어느 길로 들어가도 다른 길로 이어져 기념비·포탈로 갈 수 있다.
func _trim_dead_ends(map: FloorMap, g: Dictionary, tiles: Dictionary) -> void:
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	var floor_index := map.index_of(JsonUtil.get_str(tiles, "floor"))
	for t in JsonUtil.get_int(g, "trim_passes", 2):
		var spurs := GridSpurs.spur_cells(GridWiden.walk_cells(map), map.width, map.height, CrossLayoutCheck.hubs(map))
		var filled := 0
		for i in spurs.size():
			if spurs[i] != 0 and map.tiles[i] == floor_index:
				map.tiles[i] = wall_index
				filled += 1
		if filled == 0:
			return
		_widen_map(map, g, tiles)


# ── 수정벽·시작 위치 ─────────────────────────────────────

## 바닥에 맞닿은 바위벽 일부를 빛나는 수정벽으로. 암흑지대와 그 둘레 crystal_dark_margin칸에는 두지 않는다(빛이 새지 않게).
func _place_crystals(map: FloorMap, lay: CrossLayout, g: Dictionary, tiles: Dictionary, rng: Rng) -> void:
	var chance := JsonUtil.get_float(g, "crystal_wall_chance", 0.07)
	var margin := JsonUtil.get_int(g, "crystal_dark_margin", 3)
	var no_light := PackedByteArray()
	no_light.resize(map.tiles.size())
	for dir in CrossLayout.ARMS:
		var r := lay.dark_rect(dir).grow(margin).intersection(Rect2i(0, 0, map.width, map.height))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				no_light[y * map.width + x] = 1
	var wall_index := map.index_of(JsonUtil.get_str(tiles, "wall"))
	var crystal_index := map.index_of(JsonUtil.get_str(tiles, "crystal"))
	var walk := GridWiden.walk_cells(map)
	var w := map.width
	for y in range(1, map.height - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if map.tiles[i] != wall_index or no_light[i] != 0:
				continue
			if (walk[i - 1] == 0 or walk[i + 1] == 0 or walk[i - w] == 0 or walk[i + w] == 0) and rng.chance(chance):
				map.tiles[i] = crystal_index


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
