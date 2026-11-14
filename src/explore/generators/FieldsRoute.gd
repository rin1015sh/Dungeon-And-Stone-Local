class_name FieldsRoute
extends RefCounted
## fields 생성기 문법 "route"(사용자 2026-11-05 "2층은 오픈 필드가 아니라 의도된 경로가 있는 느낌으로" — docs/plans/floor2.md §13):
## 손으로 설계한 길 그래프(구간 · 길)를 판다. 길 밖은 구역마다 메움 지형(깊은 늪 · 솟은 외곽 …)이라 넘을 수 없다.
## gen: {"grammar": "route", "size": [w, h], "seed": 고정 시드(같은 지도 — 길을 익힌다),
##   "tiles": {"rise", "floor", "down", "up"}, "zone_fill": {구역: 메움 타일}, "zone_floor": {구역: 구간 기본 바닥},
##   "nodes": [{"id", "at": [x, y], "r", "zone", "tile"(없으면 zone_floor), "kind": arrival|exit|place|pocket, "beacon": 타일(가운데 위쪽 표지)}],
##   "edges": [{"a", "b", "width", "tile"(없으면 a 구간 바닥), "wiggle": 굽이 폭(칸), "walls": 타일(길 양옆 한 칸을 그 벽으로 — 회랑)}],
##   "props": [{"zone", "tile", "count"}](서 있는 소품 — 둘레 8칸이 걸을 수 있는 칸에만),
##   구간 "props": [{"tile", "count"}(그 구간 안 무작위) | {"tile", "at": [[dx, dy], …]}(가운데에서 그 칸들 — 예배당 긴 의자 줄)],
##   "buildings" · "ruins" · "fence" · "outer_props"(석조 건물 · 숨은 방 · 무너진 벽 · 울타리 · 길 밖 풍경 — FieldsRouteBuild),
##   높낮이(FL12): "zone_low" {구역: 낮은 땅 타일(art.sunk 바닥)}, 구간 · 길 "level": "low", 길 "ramp": true(높낮이가 바뀌는 곳이 비탈),
##   구간 "terraces" [{at, r, level, ramp: [dx, dy](비탈 방향)}], "stamps"(손으로 그린 장소 조각), "levels" {scree, ramp}(절벽 밑 · 비탈 타일)}
## 지도 표시: map.anchors["nodes"] = {id: Vector2i 가운데}, ["node_r"] = {id: 반지름} — 지키는 무리(RouteGuards) · 비석(GraveWake)이 쓴다.
## 구역(map.zones) = 걸을 수 있는 칸은 가장 가까운 구간의 zone, 메움 칸도 같게(구역별 메움 지형).

const BLOCK := 4  ## 구역 나누기를 이 칸 묶음으로(지도 전체 × 구간 수 계산을 줄인다)


static func build(map: FloorMap, db: GameDatabase, floor_def: Dictionary, g: Dictionary, rng: Rng) -> void:
	var t := JsonUtil.get_dict(g, "tiles")
	var nodes := {}
	var radii := {}
	var zone_of := {}
	var zone_floor := JsonUtil.get_dict(g, "zone_floor")
	var zone_low := JsonUtil.get_dict(g, "zone_low")  # 낮은 땅(sunk 바닥) 타일 — level "low"인 구간 · 길 · 단(FL12)
	var ramps := {}  # 높낮이 사이 비탈이 될 수 있는 칸(FieldsRouteBuild.levels)
	map.zone_ids = PackedStringArray([""])
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		var id := JsonUtil.get_str(nd, "id")
		var at := JsonUtil.get_array(nd, "at")
		nodes[id] = Vector2i(int(at[0]), int(at[1]))
		radii[id] = JsonUtil.get_float(nd, "r", 8.0)
		var z := JsonUtil.get_str(nd, "zone")
		zone_of[id] = z
		if not map.zone_ids.has(z):
			map.zone_ids.append(z)
	var walk := PackedByteArray()
	walk.resize(map.width * map.height)
	var edge_cells: Array = []
	for e: Dictionary in JsonUtil.get_array(g, "edges"):
		var a := JsonUtil.get_str(e, "a")
		var b := JsonUtil.get_str(e, "b")
		var zf := zone_low if JsonUtil.get_str(e, "level") == "low" else zone_floor
		var tile := JsonUtil.get_str(e, "tile", JsonUtil.get_str(zf, str(zone_of.get(a, "")), JsonUtil.get_str(t, "floor")))
		var cells := _path(map, rng, nodes[a], nodes[b], JsonUtil.get_float(e, "width", 5.0), JsonUtil.get_float(e, "wiggle", 4.0), tile, walk)
		edge_cells.append(cells)
		if JsonUtil.get_bool(e, "ramp"):
			for q in cells:
				ramps[q] = true
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		var id := JsonUtil.get_str(nd, "id")
		var zf := zone_low if JsonUtil.get_str(nd, "level") == "low" else zone_floor
		var tile := JsonUtil.get_str(nd, "tile", JsonUtil.get_str(zf, str(zone_of[id]), JsonUtil.get_str(t, "floor")))
		_blob(map, rng, nodes[id], float(radii[id]), tile, walk)
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		var id := JsonUtil.get_str(nd, "id")
		for td: Dictionary in JsonUtil.get_array(nd, "terraces"):
			var zf := zone_low if JsonUtil.get_str(td, "level") == "low" else zone_floor
			FieldsRouteBuild.terrace(map, rng, nodes[id], td, JsonUtil.get_str(td, "tile", JsonUtil.get_str(zf, str(zone_of[id]), JsonUtil.get_str(t, "floor"))), walk, ramps)
	FieldsRouteBuild.buildings(map, g, nodes, walk)
	FieldsRouteBuild.stamps(map, g, nodes, walk)
	FieldsRouteBuild.strokes(map, rng, g, walk)  # 트인 들판 위 장애물 줄(강 · 도랑 · 능선 · 갈대 · 방벽 — 3층 오픈 필드)
	var ei := 0
	for e: Dictionary in JsonUtil.get_array(g, "edges"):
		var wt := JsonUtil.get_str(e, "walls")
		if not wt.is_empty():
			_walls(map, edge_cells[ei], wt, walk)
		ei += 1
	var seeds := _zone_seeds(g, nodes, zone_of)  # 구역 나누기 기준점(gen "zone_seeds" — 없으면 구간 전부)
	_zones_and_fill(map, seeds[0], seeds[1], JsonUtil.get_dict(g, "zone_fill"), JsonUtil.get_str(t, "rise"), walk)
	FieldsRouteBuild.ruins(map, rng, g, walk)
	FieldsRouteBuild.levels(map, g, ramps)
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		if JsonUtil.get_str(nd, "kind") == "cover":  # 들판을 덮는 터(오픈 필드) — 이름 붙은 자리가 아니다(소품 · 표시 계산에서 뺀다)
			nodes.erase(JsonUtil.get_str(nd, "id"))
			radii.erase(JsonUtil.get_str(nd, "id"))
	_tide_marks(map, g, nodes, radii, edge_cells)
	FieldsRouteBuild.landmarks(map, g, nodes)  # 큰 구조물(소품보다 먼저 — 소품이 그 둘레를 피한다)
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		if not nodes.has(JsonUtil.get_str(nd, "id")):
			continue
		var bt := JsonUtil.get_str(nd, "beacon")
		if not bt.is_empty():
			map.set_tile(nodes[JsonUtil.get_str(nd, "id")] + Vector2i(0, -int(float(radii[JsonUtil.get_str(nd, "id")]) * 0.5)), bt)
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		var id := JsonUtil.get_str(nd, "id")
		if not nodes.has(id):
			continue
		for pd: Dictionary in JsonUtil.get_array(nd, "props"):
			_node_props(map, rng, nodes[id], float(radii[id]), pd)
	for pd: Dictionary in JsonUtil.get_array(g, "props"):
		_props(map, rng, str(pd.get("zone", "")), JsonUtil.get_str(pd, "tile"), JsonUtil.get_int(pd, "count"), nodes)
	FieldsRouteBuild.fences(map, g, nodes, radii)
	FieldsRouteBuild.outer_props(map, rng, g)
	FieldsRouteBuild.crumble(map, g, nodes)
	FieldsRouteBuild.marks(map, g, nodes)
	map.anchors["nodes"] = nodes
	map.anchors["node_r"] = radii
	var arrive := JsonUtil.get_str(floor_def, "_arrive")  # 출발점이 여럿인 층: 올라온 포탈 dest와 같은 "dest"의 arrival 구간(없으면 첫 arrival)
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		if not nodes.has(JsonUtil.get_str(nd, "id")):
			continue
		match JsonUtil.get_str(nd, "kind"):
			"arrival":
				if map.entry.x < 0 or (not arrive.is_empty() and JsonUtil.get_str(nd, "dest") == arrive):
					map.entry = nodes[JsonUtil.get_str(nd, "id")]
			"exit":
				map.center = nodes[JsonUtil.get_str(nd, "id")]
	if map.center.x < 0:
		map.center = map.entry


## 구역 기준점: gen "zone_seeds": [[x, y, 구역], …]가 있으면 그것(구간이 수백 개인 오픈 필드 — 칸마다 가까운 점 찾기를 줄인다), 없으면 구간 전부.
static func _zone_seeds(g: Dictionary, nodes: Dictionary, zone_of: Dictionary) -> Array:
	var list := JsonUtil.get_array(g, "zone_seeds")
	if list.is_empty():
		return [nodes, zone_of]
	var pts := {}
	var zs := {}
	var k := 0
	for sd: Variant in list:
		var a: Array = sd
		pts["seed%d" % k] = Vector2i(int(a[0]), int(a[1]))
		zs["seed%d" % k] = str(a[2])
		k += 1
	return [pts, zs]


## 물때 칸(FieldTerrain): 길 · 구간 "tide": "flood" | "deep" — 그 길 칸 · 구간 반지름 안의 걸을 수 있는 낮은 땅(비탈 · 돌무더기 제외).
static func _tide_marks(map: FloorMap, g: Dictionary, nodes: Dictionary, radii: Dictionary, edge_cells: Array) -> void:
	var tide := {}
	var low := func(q: Vector2i) -> bool: return map.in_bounds(q) and map.def_at(q).walkable and map.def_at(q).sunk
	var ei := 0
	for e: Dictionary in JsonUtil.get_array(g, "edges"):
		var k := JsonUtil.get_str(e, "tide")
		if not k.is_empty():
			for q: Vector2i in edge_cells[ei]:
				if low.call(q):
					tide[q] = k
		ei += 1
	for nd: Dictionary in JsonUtil.get_array(g, "nodes"):
		var k := JsonUtil.get_str(nd, "tide")
		if k.is_empty():
			continue
		var c: Vector2i = nodes[JsonUtil.get_str(nd, "id")]
		var r := ceili(float(radii[JsonUtil.get_str(nd, "id")]) * 1.25)
		for y in range(c.y - r, c.y + r + 1):
			for x in range(c.x - r, c.x + r + 1):
				if low.call(Vector2i(x, y)):
					tide[Vector2i(x, y)] = k
	if not tide.is_empty():
		map.anchors["tide"] = tide


## 두 점 사이 굽은 길: 1칸마다 옆으로 흔든(사인 두 겹 — 위상은 무작위) 점에 폭 width 붓. 판 칸 목록을 돌려준다.
static func _path(map: FloorMap, rng: Rng, a: Vector2i, b: Vector2i, width: float, wiggle: float, tile: String, walk: PackedByteArray) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var d := Vector2(b - a)
	var n := maxi(1, ceili(d.length()))
	var side := Vector2(-d.y, d.x).normalized()
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var k1 := rng.randf_range(1.0, 2.0)
	var k2 := rng.randf_range(2.5, 4.0)
	var ti := map.index_of(tile)
	var seen := {}
	for i in n + 1:
		var u := float(i) / float(n)
		var fade := sin(u * PI)  # 양 끝(구간)에서는 흔들림 없이
		var off := (sin(u * TAU * k1 * 0.5 + p1) * 0.65 + sin(u * TAU * k2 * 0.5 + p2) * 0.35) * wiggle * fade
		var c := Vector2(a).lerp(Vector2(b), u) + side * off
		var r := width * 0.5 * rng.randf_range(0.9, 1.1)
		var ri := ceili(r)
		for y in range(int(c.y) - ri, int(c.y) + ri + 1):
			for x in range(int(c.x) - ri, int(c.x) + ri + 1):
				var q := Vector2i(x, y)
				if Vector2(q).distance_to(c) <= r and _inside(map, q) and not seen.has(q):
					seen[q] = true
					map.tiles[map.idx(q)] = ti
					walk[map.idx(q)] = 1
					out.append(q)
	return out


## 구간: 가장자리가 들쭉날쭉한 둥근 터(반지름이 각도마다 ±15%).
static func _blob(map: FloorMap, rng: Rng, c: Vector2i, r: float, tile: String, walk: PackedByteArray) -> void:
	var ti := map.index_of(tile)
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var ri := ceili(r * 1.2)
	for y in range(c.y - ri, c.y + ri + 1):
		for x in range(c.x - ri, c.x + ri + 1):
			var q := Vector2i(x, y)
			var v := Vector2(q - c)
			var ang := v.angle()
			var lim := r * (1.0 + 0.1 * sin(ang * 3.0 + p1) + 0.06 * sin(ang * 7.0 + p2))
			if v.length() <= lim and _inside(map, q):
				map.tiles[map.idx(q)] = ti
				walk[map.idx(q)] = 1


## 회랑: 길 칸 둘레(8방향) 중 판 칸이 아닌 곳을 벽으로.
static func _walls(map: FloorMap, cells: Array, tile: String, walk: PackedByteArray) -> void:
	var ti := map.index_of(tile)
	for q: Vector2i in cells:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var p := q + Vector2i(dx, dy)
				if _inside(map, p) and walk[map.idx(p)] == 0:
					map.tiles[map.idx(p)] = ti
					walk[map.idx(p)] = 2  # 벽 — 메움으로 덮지 않는다


## 구역 = 가장 가까운 구간(BLOCK칸 묶음마다 한 번 셈), 판 칸이 아닌 곳은 그 구역의 메움 지형(지도 둘레는 솟은 외곽).
static func _zones_and_fill(map: FloorMap, nodes: Dictionary, zone_of: Dictionary, fill: Dictionary, rise: String, walk: PackedByteArray) -> void:
	var ids: Array = nodes.keys()
	var fill_idx := {}
	for z: String in fill:
		fill_idx[z] = map.index_of(str(fill[z]))
	var rise_i := map.index_of(rise)
	for by in range(0, map.height, BLOCK):
		for bx in range(0, map.width, BLOCK):
			var c := Vector2(bx + BLOCK * 0.5, by + BLOCK * 0.5)
			var best := ""
			var bd := INF
			for id: String in ids:
				var dd := c.distance_squared_to(Vector2(nodes[id]))
				if dd < bd:
					bd = dd
					best = id
			var z := str(zone_of[best])
			var zi := map.zone_ids.find(z)
			for y in range(by, mini(by + BLOCK, map.height)):
				for x in range(bx, mini(bx + BLOCK, map.width)):
					var i := y * map.width + x
					map.zones[i] = zi
					if walk[i] == 0:
						map.tiles[i] = rise_i if not _inside(map, Vector2i(x, y)) else int(fill_idx.get(z, rise_i))


## 서 있는 소품 count개를 구역 zone 안 걸을 수 있는 칸에(둘레 8칸이 모두 걸을 수 있어야 — 길을 막지 않는다, 구간 가운데는 비운다).
static func _props(map: FloorMap, rng: Rng, zone: String, tile: String, count: int, nodes: Dictionary) -> void:
	var zi := map.zone_ids.find(zone)
	var under := map.defs[map.index_of(tile)].stand_under  # 소품 그림 밑 바닥과 같은 바닥에만(다른 바닥 위면 네모 자국이 남는다)
	for i in count:
		for tries in 30:
			var p := Vector2i(rng.randi_range(2, map.width - 3), rng.randi_range(2, map.height - 3))
			if map.zones[map.idx(p)] != zi or (not under.is_empty() and not under_ok(map, p, under)):
				continue
			var ok := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					ok = ok and map.is_walkable(p + Vector2i(dx, dy))
			for id: String in nodes:
				ok = ok and Vector2(p - (nodes[id] as Vector2i)).length() > 3.0
			if ok:
				map.set_tile(p, tile)
				break


## 구간 소품: "at"이면 가운데에서 그 칸들(걸을 수 있고 소품 밑 바닥이 맞는 칸만), 아니면 구간 반지름 안 무작위 count개
## (가운데 4칸 안은 비우고, 둘레 8칸이 걸을 수 있는 칸에만 — 길을 막지 않는다).
static func _node_props(map: FloorMap, rng: Rng, c: Vector2i, r: float, pd: Dictionary) -> void:
	var tile := JsonUtil.get_str(pd, "tile")
	var under := map.defs[map.index_of(tile)].stand_under
	var fits := func(q: Vector2i) -> bool: return map.is_walkable(q) and (under.is_empty() or under_ok(map, q, under))
	if pd.has("at"):
		for o: Variant in JsonUtil.get_array(pd, "at"):
			var q := c + Vector2i(int(o[0]), int(o[1]))
			if fits.call(q):
				map.set_tile(q, tile)
		return
	for i in JsonUtil.get_int(pd, "count"):
		for tries in 30:
			var q := c + Vector2i(rng.randi_range(-int(r), int(r)), rng.randi_range(-int(r), int(r)))
			if Vector2(q - c).length() > r or Vector2(q - c).length() < 4.0 or not fits.call(q):
				continue
			var ok := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					ok = ok and map.is_walkable(q + Vector2i(dx, dy))
			if ok:
				map.set_tile(q, tile)
				break


## 소품 밑 바닥 under와 같은 그림인 칸인가(같은 타일 또는 같은 아틀라스 — 낮은 땅 타일은 높은 땅과 그림을 같이 쓴다, FL12).
static func under_ok(map: FloorMap, q: Vector2i, under: String) -> bool:
	if map.tile_id_at(q) == under:
		return true
	var a := map.defs[map.index_of(under)].art_atlas
	return not a.is_empty() and map.def_at(q).art_atlas == a


static func _inside(map: FloorMap, p: Vector2i) -> bool:
	return p.x >= 3 and p.y >= 3 and p.x < map.width - 3 and p.y < map.height - 3
