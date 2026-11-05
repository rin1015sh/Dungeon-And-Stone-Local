class_name FieldsGenerator
extends FloorGenerator
## 들판 생성기(2층부터 — docs/plans/floors_2_10.md §2-2 · floor2.md). 지형 문법 gen.grammar가 모양을 정한다.
## 지금 문법: "marsh"(망자의 땅 — 남북으로 긴 열린 늪, 가운데 잔해, 북쪽 단단한 땅과 둔덕). 길마다 문법 파일을 늘려 간다.
## gen: {"size": [w, h], "grammar": "marsh", "margin": 바깥 둘레 칸, "edge_jag": 가장자리 들쭉날쭉 폭,
##       "tiles": {"rise", "floor", "hard", "ruin", "mound", "down", "up"},
##       "bands": [[구역 id, 남쪽부터 몫], …](합 1 — map.zones, 층 regions zone과 짝),
##       "hard_from": 몇 번째 띠부터 단단한 땅, "ruins": {"band", "count", "size": [최소, 최대], "broken"}, "mounds": {"band", "count", "radius": [최소, 최대]},
##       "props": [{"band", "tile", "count"}](서 있는 소품 한 칸씩 — 둘레 8칸이 모두 걸을 수 있는 칸에만, 길을 막지 않는다)}
## 공통: 바깥 = 솟은 외곽(rise), 시작 = 남쪽 가운데, 도착 비석(아래층 — 포탈 kind "floor_down") = 시작 두 칸 남쪽,
## 위층 포탈 = 북쪽 끝 가운데(층 JSON portals[0]). 불변식: 걸을 수 있는 칸은 모두 시작에서 닿는다(닿지 않는 칸은 외곽으로 메운다).

const CLEAR := 4  ## 시작·포탈 둘레 비워 두는 반경(칸)


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var t := JsonUtil.get_dict(g, "tiles")
	var size := JsonUtil.get_array(g, "size")
	var w := int(size[0])
	var h := int(size[1])
	var map := FloorMap.new(db, w, h, JsonUtil.get_str(t, "rise"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	var m := maxi(2, JsonUtil.get_int(g, "margin", 6))
	_carve_field(map, rng, m, maxi(0, JsonUtil.get_int(g, "edge_jag", 6)), JsonUtil.get_str(t, "floor"))
	var bands := _bands(map, g, m)
	_harden(map, bands, JsonUtil.get_int(g, "hard_from", 99), JsonUtil.get_str(t, "floor"), JsonUtil.get_str(t, "hard"))
	map.entry = Vector2i(w / 2, h - m - CLEAR - 3)
	var up := Vector2i(w / 2, m + CLEAR)
	var keep: Array[Vector2i] = [map.entry, up]
	_ruins(map, rng, bands, JsonUtil.get_dict(g, "ruins"), JsonUtil.get_str(t, "ruin"), keep)
	_mounds(map, rng, bands, JsonUtil.get_dict(g, "mounds"), JsonUtil.get_str(t, "mound"), keep)
	for pd: Variant in JsonUtil.get_array(g, "props"):
		_props(map, rng, bands, pd as Dictionary, keep)
	map.center = map.entry
	var down := map.entry + Vector2i(0, 2)
	map.set_tile(down, JsonUtil.get_str(t, "down"))
	map.portals.append({"id": "to_below", "pos": down, "dir": "south", "to_floor": JsonUtil.get_int(floor_def, "floor", 2) - 1,
		"kind": "floor_down", "found": true})
	var spec := JsonUtil.get_array(floor_def, "portals")
	if not spec.is_empty():
		var sd: Dictionary = spec[0]
		map.set_tile(up, JsonUtil.get_str(t, "up"))
		map.portals.append({"id": JsonUtil.get_str(sd, "id"), "pos": up, "dir": JsonUtil.get_str(sd, "dir", "north"),
			"to_floor": JsonUtil.get_int(sd, "to_floor"), "dest": JsonUtil.get_str(sd, "dest"), "found": false})
	_seal_unreachable(map, JsonUtil.get_str(t, "rise"))
	map.dark = FloorMap._zeros(w * h)
	return map


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var g := JsonUtil.get_dict(floor_def, "gen")
	if JsonUtil.get_str(g, "grammar") != "marsh":
		out.append("fields: gen.grammar는 지금 \"marsh\"만")
	var size := JsonUtil.get_array(g, "size")
	if size.size() != 2 or int(size[0]) < 40 or int(size[1]) < 40:
		out.append("fields: gen.size는 [40 이상, 40 이상]")
	var t := JsonUtil.get_dict(g, "tiles")
	for k in ["rise", "floor", "hard", "ruin", "mound", "down", "up"]:
		if not db.has_entry("tiles", JsonUtil.get_str(t, k)):
			out.append("fields: gen.tiles.%s 타일 없음" % k)
	var total := 0.0
	for b: Variant in JsonUtil.get_array(g, "bands"):
		total += float((b as Array)[1]) if b is Array and (b as Array).size() == 2 else 0.0
	if absf(total - 1.0) > 0.01:
		out.append("fields: gen.bands 몫의 합은 1")
	return out


## 둘레 m칸 안쪽을 판다. 동서 가장자리는 줄마다 조금씩 움직여(무작위 걸음) 곧은 벽이 되지 않게.
func _carve_field(map: FloorMap, rng: Rng, m: int, jag: int, floor_tile: String) -> void:
	var left := m + jag / 2
	var right := map.width - 1 - m - jag / 2
	var fi := map.index_of(floor_tile)
	for y in range(m, map.height - m):
		left = clampi(left + rng.randi_range(-1, 1), m, m + jag)
		right = clampi(right + rng.randi_range(-1, 1), map.width - 1 - m - jag, map.width - 1 - m)
		for x in range(left, right + 1):
			map.tiles[y * map.width + x] = fi


## 남쪽부터 띠마다 구역(map.zones). 돌려주는 것 = 띠마다 [y0, y1)(북쪽 y가 작다).
func _bands(map: FloorMap, g: Dictionary, m: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	map.zone_ids = PackedStringArray([""])
	var inner := map.height - 2 * m
	var y_end := map.height - m
	for b: Variant in JsonUtil.get_array(g, "bands"):
		var row: Array = b
		var y_start := maxi(m, y_end - roundi(inner * float(row[1])))
		map.zone_ids.append(str(row[0]))
		var zi := map.zone_ids.size() - 1
		for y in range(y_start, y_end):
			for x in map.width:
				map.zones[y * map.width + x] = zi
		out.append(Vector2i(y_start, y_end))
		y_end = y_start
	return out


func _harden(map: FloorMap, bands: Array[Vector2i], from: int, floor_tile: String, hard_tile: String) -> void:
	var fi := map.index_of(floor_tile)
	var hi := map.index_of(hard_tile)
	for k in range(mini(from, bands.size()), bands.size()):
		for y in range(bands[k].x, bands[k].y):
			for x in map.width:
				if map.tiles[y * map.width + x] == fi:
					map.tiles[y * map.width + x] = hi


## 잔해: 띠 band 안에 무너진 돌벽 사각형 count개(테두리만, broken 몫은 빠진 돌 — 사이로 걸어 들어간다).
func _ruins(map: FloorMap, rng: Rng, bands: Array[Vector2i], d: Dictionary, tile: String, keep: Array[Vector2i]) -> void:
	if d.is_empty() or JsonUtil.get_int(d, "band", 0) >= bands.size():
		return
	var band := bands[JsonUtil.get_int(d, "band", 0)]
	var sz := JsonUtil.get_array(d, "size")
	var broken := JsonUtil.get_float(d, "broken", 0.35)
	for i in JsonUtil.get_int(d, "count", 0):
		var rw := rng.randi_range(int(sz[0]), int(sz[1]))
		var rh := rng.randi_range(int(sz[0]), int(sz[1]))
		var x0 := rng.randi_range(2, map.width - rw - 3)
		var y0 := rng.randi_range(band.x, maxi(band.x, band.y - rh - 1))
		for y in range(y0, y0 + rh):
			for x in range(x0, x0 + rw):
				var edge := y == y0 or y == y0 + rh - 1 or x == x0 or x == x0 + rw - 1
				if edge and not rng.chance(broken):
					_put(map, Vector2i(x, y), tile, keep)


## 둔덕: 띠 band 안에 둥근 덩어리 count개(지금은 걷지 못하는 언덕 — 걸어 오르되 시야만 가리는 것은 floor2.md §3 다음 단계).
func _mounds(map: FloorMap, rng: Rng, bands: Array[Vector2i], d: Dictionary, tile: String, keep: Array[Vector2i]) -> void:
	if d.is_empty() or JsonUtil.get_int(d, "band", 0) >= bands.size():
		return
	var band := bands[JsonUtil.get_int(d, "band", 0)]
	var rr := JsonUtil.get_array(d, "radius")
	for i in JsonUtil.get_int(d, "count", 0):
		var r := rng.randf_range(float(rr[0]), float(rr[1]))
		var c := Vector2(rng.randi_range(4, map.width - 5), rng.randi_range(band.x, band.y - 1))
		var ri := ceili(r)
		for y in range(int(c.y) - ri, int(c.y) + ri + 1):
			for x in range(int(c.x) - ri, int(c.x) + ri + 1):
				if Vector2(x, y).distance_to(c) <= r * rng.randf_range(0.85, 1.0):
					_put(map, Vector2i(x, y), tile, keep)


## 서 있는 소품: 띠 band 안 무작위 칸 count개 — 둘레 8칸이 모두 걸을 수 있어야(소품끼리 붙지 않고 길을 막지 않는다).
func _props(map: FloorMap, rng: Rng, bands: Array[Vector2i], d: Dictionary, keep: Array[Vector2i]) -> void:
	if JsonUtil.get_int(d, "band", 0) >= bands.size():
		return
	var band := bands[JsonUtil.get_int(d, "band", 0)]
	var tile := JsonUtil.get_str(d, "tile")
	for i in JsonUtil.get_int(d, "count", 0):
		for tries in 8:
			var p := Vector2i(rng.randi_range(2, map.width - 3), rng.randi_range(band.x, band.y - 1))
			var open := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					open = open and map.is_walkable(p + Vector2i(dx, dy))
			if open:
				_put(map, p, tile, keep)
				break


## 걸을 수 있는 칸에만, 지켜 둘 자리(시작·포탈) 둘레는 비운다.
func _put(map: FloorMap, p: Vector2i, tile: String, keep: Array[Vector2i]) -> void:
	if not map.in_bounds(p) or not map.is_walkable(p):
		return
	for k in keep:
		if maxi(absi(p.x - k.x), absi(p.y - k.y)) <= CLEAR:
			return
	map.set_tile(p, tile)


## 시작에서 닿지 않는 걸을 수 있는 칸은 외곽으로 메운다(잔해·둔덕이 막아 만든 섬).
func _seal_unreachable(map: FloorMap, rise_tile: String) -> void:
	var seen := PackedByteArray()
	seen.resize(map.width * map.height)
	var queue: Array[Vector2i] = [map.entry]
	seen[map.idx(map.entry)] = 1
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			var q := p + d
			if map.in_bounds(q) and seen[map.idx(q)] == 0 and map.is_walkable(q):
				seen[map.idx(q)] = 1
				queue.append(q)
	var ri := map.index_of(rise_tile)
	for i in map.tiles.size():
		if seen[i] == 0 and map.defs[map.tiles[i]].walkable:
			map.tiles[i] = ri
