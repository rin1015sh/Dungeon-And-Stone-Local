class_name FieldsRouteBuild
extends RefCounted
## 길 그래프(FieldsRoute) 위에 세우는 것(사용자 2026-11-05 "석조 건축물 · 숨겨진 작은 방 · 외곽 장식 — 첨부 그림처럼", FL10):
##   gen "buildings": [{"node", "at": [dx, dy](구간 가운데에서 왼쪽 위 모서리), "size": [w, h], "door": "n"|"s"|"e"|"w"|""(없으면 속이 찬 석조물),
##                     "wall", "floor", "path"(문에서 길까지 1칸 샛길 바닥 — 없으면 floor)}]
##     벽 테두리 + 안 바닥(걸을 수 있음), 문 칸에서 바깥으로 곧게 걸을 수 있는 칸에 닿을 때까지 샛길을 판다(최대 24칸 — 숨은 방은 덤불 너머).
##   gen "ruins": [{"zone", "tile", "count"}] — 걸을 수 있는 칸 위 무너진 벽 조각(2~4칸 가로)(둘레가 모두 걸을 수 있을 때만 — 길을 막지 않는다)
##   gen "fence": [{"node", "tile", "pad", "along"}] — 그 구간 반지름 + pad 안, 소품 밑 바닥과 같은 칸 중 상하좌우로 along 타일(둔덕)과 맞닿은 칸
##     (along이 없으면 걸을 수 있는 칸과 맞닿은 칸)에 울타리 — 둔덕 앞 가장자리를 두른다(길이 둔덕을 뚫고 나가는 곳은 비어 문이 된다)
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
				var len := rng.randi_range(2, 4)
				var step := Vector2i.RIGHT  # 가로 벽 조각만(세로 1칸 폭은 둥근 윤곽에서 지그재그 기둥으로 보였다 — FL11)
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
		var along := JsonUtil.get_str(f, "along")
		var ri := ceili(r)
		for y in range(c.y - ri, c.y + ri + 1):
			for x in range(c.x - ri, c.x + ri + 1):
				var q := Vector2i(x, y)
				if not _ok(map, q) or Vector2(q - c).length() > r or map.tile_id_at(q) != under:
					continue
				if map.is_walkable(q + Vector2i.LEFT) and map.is_walkable(q + Vector2i.RIGHT) or map.is_walkable(q + Vector2i.UP) and map.is_walkable(q + Vector2i.DOWN):
					continue  # 좁은 샛길(양쪽이 걸을 수 있는 칸)은 막지 않는다 — 숨은 방 길
				for d in FloorMap.DIRS4:
					if along.is_empty() and map.is_walkable(q + d) or not along.is_empty() and map.tile_id_at(q + d) == along:
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


## ── 높낮이(FL12 — 사용자 2026-11-05 "절벽 등 높고 낮은 층고를 도입") ──────────────────
## 땅은 두 층: 높은 땅(보통 바닥) · 낮은 땅(art.sunk 바닥 — MoatBank가 높은 땅 가장자리 아래로 절벽 면을 그린다). 깊은 물도 낮은 층.
## levels: 낮은 땅 칸이 높은 땅 칸과 맞닿으면(8방향) 그 낮은 칸은 절벽 밑 돌무더기(gen.levels.scree — 걷지 못하는 낮은 칸)로 바꾼다 —
## 그래서 높낮이 사이는 비탈(gen.levels.ramp — art.ramp, 절벽 없음)로만 오르내린다. 비탈 = ramps 칸 중 높낮이 경계에 선 칸
## (길 "ramp": true의 길 칸 · 단의 비탈 띠). 높은 쪽 비탈 칸을 먼저 바꾸고(그 옆 낮은 칸은 비탈만 보니 돌무더기가 되지 않는다), 다음 낮은 쪽.
static func levels(map: FloorMap, g: Dictionary, ramps: Dictionary) -> void:
	var cfg := JsonUtil.get_dict(g, "levels")
	if cfg.is_empty():
		return
	var scree := map.index_of(JsonUtil.get_str(cfg, "scree"))
	var ramp := map.index_of(JsonUtil.get_str(cfg, "ramp"))
	var high := func(q: Vector2i) -> bool:
		if not map.in_bounds(q):
			return false
		var d := map.def_at(q)
		return d.walkable and not d.sunk and not d.ramp and not d.is_wall()
	var low := func(q: Vector2i) -> bool:
		return map.in_bounds(q) and map.def_at(q).walkable and map.def_at(q).sunk
	for q: Vector2i in ramps:  # 높은 쪽 비탈
		if high.call(q):
			for d in FloorMap.DIRS4:
				if low.call(q + d):
					map.tiles[map.idx(q)] = ramp
					break
	var to_scree: Array[Vector2i] = []
	for y in range(1, map.height - 1):
		for x in range(1, map.width - 1):
			var q := Vector2i(x, y)
			if not low.call(q):
				continue
			var near_high := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					near_high = near_high or high.call(q + Vector2i(dx, dy))
			if not near_high:
				continue
			if ramps.has(q):
				map.tiles[map.idx(q)] = ramp
			else:
				to_scree.append(q)
	for q in to_scree:
		map.tiles[map.idx(q)] = scree


## 단(terrace): 구간 가운데 + at에 반지름 r의 들쭉날쭉한 터를 tile로(높은 구간 안 움푹 꺼진 땅 · 낮은 구간 안 솟은 언덕).
## ramp = [dx, dy] 방향: 그쪽 가장자리 띠(폭 5칸)가 비탈 후보.
static func terrace(map: FloorMap, rng: Rng, c: Vector2i, td: Dictionary, tile: String, walk: PackedByteArray, ramps: Dictionary) -> void:
	var at := JsonUtil.get_array(td, "at")
	var o := c + Vector2i(int(at[0]), int(at[1]))
	var r := JsonUtil.get_float(td, "r", 5.0)
	var ti := map.index_of(tile)
	var rd := JsonUtil.get_array(td, "ramp")
	var dir := Vector2(float(rd[0]), float(rd[1])).normalized() if rd.size() == 2 else Vector2.ZERO
	var p1 := rng.randf_range(0.0, TAU)
	var ri := ceili(r * 1.2) + 1
	for y in range(o.y - ri, o.y + ri + 1):
		for x in range(o.x - ri, o.x + ri + 1):
			var q := Vector2i(x, y)
			var v := Vector2(q - o)
			var lim := r * (1.0 + 0.12 * sin(v.angle() * 3.0 + p1))
			if not _ok(map, q) or v.length() > lim + 1.0:
				continue
			if v.length() <= lim:
				map.tiles[map.idx(q)] = ti
				walk[map.idx(q)] = 1
			if dir != Vector2.ZERO and v.dot(dir) > lim * 0.55 and absf(v.dot(Vector2(-dir.y, dir.x))) <= 2.5:
				ramps[q] = true  # 비탈 띠(안쪽 가장자리 · 바깥 한 칸 — 어느 쪽이 높든 경계에 걸린다)


## 손으로 그린 장소 조각: gen "stamps": [{"node", "at": [dx, dy](구간 가운데에서 왼쪽 위), "legend": {글자: 타일}, "rows": [...]}]
## 글자 " "(공백)은 그대로 둔다. 걸을 수 있는 타일은 판 칸, 아니면 벽 칸(메움으로 덮지 않는다).
static func stamps(map: FloorMap, g: Dictionary, nodes: Dictionary, walk: PackedByteArray) -> void:
	for st: Dictionary in JsonUtil.get_array(g, "stamps"):
		var c: Vector2i = nodes.get(JsonUtil.get_str(st, "node"), Vector2i(-1, -1))
		if c.x < 0:
			continue
		var at := JsonUtil.get_array(st, "at")
		var o := c + Vector2i(int(at[0]), int(at[1]))
		var legend := JsonUtil.get_dict(st, "legend")
		var idx := {}
		for k: String in legend:
			idx[k] = map.index_of(str(legend[k]))
		var rows := JsonUtil.get_array(st, "rows")
		for y in rows.size():
			var row := str(rows[y])
			for x in row.length():
				var ch := row[x]
				if ch == " " or not idx.has(ch):
					continue
				var q := o + Vector2i(x, y)
				if not _ok(map, q):
					continue
				var ti: int = idx[ch]
				map.tiles[map.idx(q)] = ti
				walk[map.idx(q)] = 1 if map.defs[ti].walkable else 2
