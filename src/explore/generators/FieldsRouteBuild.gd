class_name FieldsRouteBuild
extends RefCounted
## 길 그래프(FieldsRoute) 위에 세우는 것(사용자 2026-11-05 "석조 건축물 · 숨겨진 작은 방 · 외곽 장식 — 첨부 그림처럼", FL10):
##   gen "buildings": [{"node", "at": [dx, dy](구간 가운데에서 왼쪽 위 모서리), "size": [w, h], "door": "n"|"s"|"e"|"w"|""(없으면 속이 찬 석조물),
##                     "wall", "floor", "path"(문에서 길까지 1칸 샛길 바닥 — 없으면 floor)}]
##     벽 테두리 + 안 바닥(걸을 수 있음), 문 칸에서 바깥으로 곧게 걸을 수 있는 칸에 닿을 때까지 샛길을 판다(최대 24칸 — 숨은 방은 덤불 너머).
##   gen "ruins": [{"zone", "tile", "count"}] — 걸을 수 있는 칸 위 무너진 벽 조각(1 · 2 · 3칸 가로 · 세로)과 기둥(둘레가 모두 걸을 수 있을 때만 — 길을 막지 않는다)
##   gen "fence": [{"node", "tile", "pad"}] — 그 구간 반지름 + pad 안, 걸을 수 있는 칸과 상하좌우로 맞닿은 메움 칸에 울타리(길이 지나는 곳은 걸을 수 있어 비워진다 = 문)
##   gen "outer_props": [{"zone", "tile", "count", "near"}] — 걸을 수 있는 칸에서 near칸 안의 메움 칸(소품 밑 바닥과 같은 칸)에 서 있는 소품(길 밖 풍경)
## walk: 0 = 메움(아직 안 판 칸), 1 = 판 칸, 2 = 벽(메움으로 덮지 않는다).


static func buildings(map: FloorMap, g: Dictionary, nodes: Dictionary, walk: PackedByteArray) -> void:
	for b: Dictionary in JsonUtil.get_array(g, "buildings"):
		var c: Vector2i = nodes.get(JsonUtil.get_str(b, "node"), Vector2i(-1, -1))
		if c.x < 0:
			continue
		var at := JsonUtil.get_array(b, "at")
		var sz := JsonUtil.get_array(b, "size")
		var o := c + Vector2i(int(at[0]), int(at[1]))
		var w := int(sz[0])
		var h := int(sz[1])
		var wall := map.index_of(JsonUtil.get_str(b, "wall"))
		var fl := map.index_of(JsonUtil.get_str(b, "floor"))
		var door := JsonUtil.get_str(b, "door")
		for y in h:
			for x in w:
				var q := o + Vector2i(x, y)
				if not _ok(map, q):
					continue
				var edge := x == 0 or y == 0 or x == w - 1 or y == h - 1
				var solid := edge or door.is_empty()
				map.tiles[map.idx(q)] = wall if solid else fl
				walk[map.idx(q)] = 2 if solid else 1
		if door.is_empty():
			continue
		var dir: Vector2i = {"n": Vector2i.UP, "s": Vector2i.DOWN, "e": Vector2i.RIGHT, "w": Vector2i.LEFT}.get(door, Vector2i.DOWN)
		var d := o + Vector2i(w / 2, h / 2)
		while d.x >= o.x and d.y >= o.y and d.x < o.x + w and d.y < o.y + h:  # 안에서 문 쪽 벽까지
			d += dir
		d -= dir
		var path := map.index_of(JsonUtil.get_str(b, "path", JsonUtil.get_str(b, "floor")))
		map.tiles[map.idx(d)] = fl
		walk[map.idx(d)] = 1
		var q := d + dir
		for i in 24:  # 샛길: 걸을 수 있는 칸에 닿을 때까지
			if not _ok(map, q) or walk[map.idx(q)] == 1:
				break
			map.tiles[map.idx(q)] = path
			walk[map.idx(q)] = 1
			q += dir


static func ruins(map: FloorMap, rng: Rng, g: Dictionary, walk: PackedByteArray) -> void:
	for r: Dictionary in JsonUtil.get_array(g, "ruins"):
		var zi := map.zone_ids.find(JsonUtil.get_str(r, "zone"))
		var ti := map.index_of(JsonUtil.get_str(r, "tile"))
		for n in JsonUtil.get_int(r, "count"):
			for tries in 40:
				var p := Vector2i(rng.randi_range(4, map.width - 5), rng.randi_range(4, map.height - 5))
				if map.zones[map.idx(p)] != zi:
					continue
				var len := rng.randi_range(1, 3)
				var step := Vector2i.RIGHT if rng.randf() < 0.5 else Vector2i.DOWN
				var cells: Array[Vector2i] = []
				for k in len:
					cells.append(p + step * k)
				var ok := true
				for q in cells:
					for dy in range(-2, 3):
						for dx in range(-2, 3):
							ok = ok and walk[map.idx(q + Vector2i(dx, dy))] == 1 and map.defs[map.tiles[map.idx(q + Vector2i(dx, dy))]].walkable
				if not ok:
					continue
				for q in cells:
					map.tiles[map.idx(q)] = ti
					walk[map.idx(q)] = 2
				break


## 울타리 · 길 밖 소품 — 메움 지형을 깐 뒤(소품 밑 바닥 = 메움 타일이어야 한다).
static func fences(map: FloorMap, g: Dictionary, nodes: Dictionary, radii: Dictionary) -> void:
	for f: Dictionary in JsonUtil.get_array(g, "fence"):
		var id := JsonUtil.get_str(f, "node")
		if not nodes.has(id):
			continue
		var c: Vector2i = nodes[id]
		var r := float(radii[id]) + JsonUtil.get_float(f, "pad", 3.0)
		var tile := JsonUtil.get_str(f, "tile")
		var under := map.defs[map.index_of(tile)].stand_under
		var ri := ceili(r)
		for y in range(c.y - ri, c.y + ri + 1):
			for x in range(c.x - ri, c.x + ri + 1):
				var q := Vector2i(x, y)
				if not _ok(map, q) or Vector2(q - c).length() > r or map.is_walkable(q) or map.tile_id_at(q) != under:
					continue
				for d in FloorMap.DIRS4:
					if map.is_walkable(q + d):
						map.set_tile(q, tile)
						break


static func outer_props(map: FloorMap, rng: Rng, g: Dictionary) -> void:
	var list := JsonUtil.get_array(g, "outer_props")
	if list.is_empty():
		return
	var far := 0
	for o: Dictionary in list:
		far = maxi(far, JsonUtil.get_int(o, "near", 6))
	var dist := _distance(map, far)
	for o: Dictionary in list:
		var zi := map.zone_ids.find(JsonUtil.get_str(o, "zone"))
		var tile := JsonUtil.get_str(o, "tile")
		var under := map.defs[map.index_of(tile)].stand_under
		var near := JsonUtil.get_int(o, "near", 6)
		var cand: Array[int] = []
		for i in dist.size():
			if dist[i] >= 2 and dist[i] <= near and map.zones[i] == zi and map.tile_id_at(Vector2i(i % map.width, i / map.width)) == under:
				cand.append(i)
		for n in mini(JsonUtil.get_int(o, "count"), cand.size()):
			var i := cand[rng.randi_range(0, cand.size() - 1)]
			var q := Vector2i(i % map.width, i / map.width)
			if map.tile_id_at(q) == under:
				map.set_tile(q, tile)


## 걸을 수 있는 칸에서의 칸 거리(상하좌우, cap까지 — 넘으면 cap + 1).
static func _distance(map: FloorMap, cap: int) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(map.width * map.height)
	d.fill(cap + 1)
	var queue: Array[Vector2i] = []
	for i in d.size():
		if map.defs[map.tiles[i]].walkable:
			d[i] = 0
			queue.append(Vector2i(i % map.width, i / map.width))
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var nd := d[map.idx(p)] + 1
		if nd > cap:
			continue
		for dir in FloorMap.DIRS4:
			var q := p + dir
			if map.in_bounds(q) and d[map.idx(q)] > nd:
				d[map.idx(q)] = nd
				queue.append(q)
	return d


static func _ok(map: FloorMap, q: Vector2i) -> bool:
	return q.x >= 3 and q.y >= 3 and q.x < map.width - 3 and q.y < map.height - 3
