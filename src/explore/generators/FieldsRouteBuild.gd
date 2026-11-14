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


## 길 밖 소품: gen "outer_props": [{zone, tile, count, near(걸을 수 있는 칸에서 2 ~ near칸), clear: [반폭, 높이](선택)}].
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
		var clear := JsonUtil.get_array(o, "clear")  # [반폭, 높이](칸): 그림이 덮는 위쪽 사각에 걸을 수 있는 칸이 있으면 세우지 않는다(키 큰 나무가 길 · 사람을 가리지 않게, FL23)
		for n in mini(JsonUtil.get_int(o, "count"), cand.size()):
			var i := cand[rng.randi_range(0, cand.size() - 1)]
			var q := Vector2i(i % map.width, i / map.width)
			if map.tile_id_at(q) == under and (clear.size() != 2 or _clear_above(map, q, int(clear[0]), int(clear[1]))):
				map.set_tile(q, tile)


static func _clear_above(map: FloorMap, q: Vector2i, hw: int, h: int) -> bool:
	for y in range(q.y - h, q.y + 1):
		for x in range(q.x - hw, q.x + hw + 1):
			var c := Vector2i(x, y)
			if map.in_bounds(c) and map.is_walkable(c):
				return false
	return true


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



## 무른 땅(FL14 — FieldTerrain): gen "crumble": [{"node", "at": [dx, dy](왼쪽 위), "size": [w, h], "tile"}] — 그 네모 안 걸을 수 있는 칸을
## 무른 땅 타일로(map.anchors["crumble"]), "drops": [{"node", "at", "tile", "to": 표시 이름}] — 밟으면 꺼져 그 표시로 떨어지는 칸(anchors["drops"]).
static func crumble(map: FloorMap, g: Dictionary, nodes: Dictionary) -> void:
	var cr := {}
	for c: Dictionary in JsonUtil.get_array(g, "crumble"):
		var n: Vector2i = nodes.get(JsonUtil.get_str(c, "node"), Vector2i(-1, -1))
		if n.x < 0:
			continue
		var at := JsonUtil.get_array(c, "at")
		var sz := JsonUtil.get_array(c, "size")
		for y in int(sz[1]):
			for x in int(sz[0]):
				var q := n + Vector2i(int(at[0]) + x, int(at[1]) + y)
				if map.is_walkable(q) and not map.def_at(q).ramp:
					map.set_tile(q, JsonUtil.get_str(c, "tile"))
					cr[q] = true
	var drops := {}
	for d: Dictionary in JsonUtil.get_array(g, "drops"):
		var n: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		var at := JsonUtil.get_array(d, "at")
		var q := n + Vector2i(int(at[0]), int(at[1]))
		if n.x >= 0 and map.is_walkable(q):
			map.set_tile(q, JsonUtil.get_str(d, "tile"))
			drops[q] = JsonUtil.get_str(d, "to")
	if not cr.is_empty():
		map.anchors["crumble"] = cr
	if not drops.is_empty():
		map.anchors["drops"] = drops


## 표시(순간 이동 자리): gen "marks": [{"name", "node", "at"}] → map.anchors["marks"][name] = 칸(지하 묘실 계단 나오는 자리 등).
static func marks(map: FloorMap, g: Dictionary, nodes: Dictionary) -> void:
	var m: Dictionary = map.anchors.get("marks", {})
	for d: Dictionary in JsonUtil.get_array(g, "marks"):
		var n: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		var at := JsonUtil.get_array(d, "at")
		if n.x >= 0:
			m[JsonUtil.get_str(d, "name")] = n + Vector2i(int(at[0]), int(at[1]))
	map.anchors["marks"] = m


## 지하 묘실(FL14 — floor2.md §14-2 납골당 아래): gen "crypts": [{"at": [x, y](지도 칸 — 길에서 먼 메움 속), "legend", "rows",
## "marks": {이름: [dx, dy]}}]. 시작에서 닿지 않는 따로 된 방이라 fields.gd가 닿지 않는 칸을 메운 뒤에 판다. 모두 어둠(map.dark — 횃불이 있어야 보인다).
## 들어가고 나오는 길은 요소의 "goto"(계단) · 무른 땅 drops.
static func crypts(map: FloorMap, g: Dictionary) -> void:
	var m: Dictionary = map.anchors.get("marks", {})
	for c: Dictionary in JsonUtil.get_array(g, "crypts"):
		var at := JsonUtil.get_array(c, "at")
		var o := Vector2i(int(at[0]), int(at[1]))
		var legend := JsonUtil.get_dict(c, "legend")
		var rows := JsonUtil.get_array(c, "rows")
		for y in rows.size():
			var row := str(rows[y])
			for x in row.length():
				var q := o + Vector2i(x, y)
				if not legend.has(row[x]) or not _ok(map, q):
					continue
				map.set_tile(q, str(legend[row[x]]))
				if not JsonUtil.get_bool(c, "lit"):
					map.dark[map.idx(q)] = 1
		var mk := JsonUtil.get_dict(c, "marks")
		for name: String in mk:
			var a: Array = mk[name]
			m[name] = o + Vector2i(int(a[0]), int(a[1]))
	map.anchors["marks"] = m



## 아귀 입 자리(FL15 — MawTraps): gen "maws": [{"node", "at": [dx, dy]}] — 그 칸과 둘레(가로 5칸 · 위 1칸 · 아래 3칸)가 걸을 수 있을 때만(아니면 가장 가까운 그런 칸, 4칸 안).
static func maws(map: FloorMap, g: Dictionary, nodes: Dictionary) -> void:
	var out: Array = []
	for d: Dictionary in JsonUtil.get_array(g, "maws"):
		var n: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		if n.x < 0:
			continue
		var at := JsonUtil.get_array(d, "at")
		var c := n + Vector2i(int(at[0]), int(at[1]))
		var best := Vector2i(-1, -1)
		for r in 5:
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var q := c + Vector2i(dx, dy)
					if best.x < 0 and _open9(map, q) and not out.has(q):
						best = q
			if best.x >= 0:
				break
		if best.x >= 0:
			out.append(best)
	if not out.is_empty():
		map.anchors["maws"] = out


static func _open9(map: FloorMap, q: Vector2i) -> bool:  # 입 그림 폭(가로 5칸)이 빈 곳 — 남쪽 3칸까지(남쪽 벽 · 소품 그림은 위로 솟아 입을 가린다)
	for dy in range(-1, 4):
		for dx in range(-2, 3):
			var p := q + Vector2i(dx, dy)
			if not map.in_bounds(p) or not map.is_walkable(p) or map.def_at(p).ramp:
				return false
	return true


## 큰 구조물(FL16 — 사용자 "커다란 구조물 · 토핑 뿌린 느낌"): gen "landmarks": [{"node", "at": [dx, dy](발 줄 가운데), "kind", "foot": [폭, 깊이]}],
## "landmarks_under": {접미: 바닥 타일}(구조물마다 "prefix" · "unders"로 바꿀 수 있다 — 3층은 두 층의 구조물을 섞는다). 발 칸(맨 아래 줄 가운데)에 큰 그림 타일 <앞>_big_<kind>_<접미>, 발자리 나머지는 <앞>_block_<접미>(그림 없음). <앞> = "landmarks_prefix"(기본 f2d).
## 자리는 발자리와 둘레 한 칸이 모두 걸을 수 있는 칸(비탈 아님)이어야 — 아니면 4칸 안에서 가장 가까운 그런 자리(길을 막지 않는다).
## 밑 바닥 = 발 칸 바닥과 같은 그림(FieldsRoute.under_ok)인 접미, 없으면 건너뛴다.
static func landmarks(map: FloorMap, g: Dictionary, nodes: Dictionary) -> void:
	var unders0 := JsonUtil.get_dict(g, "landmarks_under")
	var pre0 := JsonUtil.get_str(g, "landmarks_prefix", "f2d")  # 타일 이름 앞(고블린 숲 f2g — FL21)
	for d: Dictionary in JsonUtil.get_array(g, "landmarks"):
		var n: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		if n.x < 0:
			continue
		var pre := JsonUtil.get_str(d, "prefix", pre0)
		var unders: Dictionary = JsonUtil.get_dict(d, "unders") if d.has("unders") else unders0
		var at := JsonUtil.get_array(d, "at")
		var ft := JsonUtil.get_array(d, "foot")
		var fw := int(ft[0])
		var fd := int(ft[1])
		var c0 := n + Vector2i(int(at[0]), int(at[1]))
		var spot := Vector2i(-1, -1)
		for r in 5:
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if spot.x < 0 and maxi(absi(dx), absi(dy)) == r and _foot_ok(map, c0 + Vector2i(dx, dy), fw, fd):
						spot = c0 + Vector2i(dx, dy)
			if spot.x >= 0:
				break
		if spot.x < 0:
			continue
		var suffix := ""
		for k: String in unders:
			if suffix.is_empty() and FieldsRoute.under_ok(map, spot, str(unders[k])):
				suffix = k
		if suffix.is_empty():
			continue
		for y in range(spot.y - fd + 1, spot.y + 1):
			for x in range(spot.x - fw / 2, spot.x - fw / 2 + fw):
				map.set_tile(Vector2i(x, y), pre + "_block_" + suffix)
		map.set_tile(spot, "%s_big_%s_%s" % [pre, JsonUtil.get_str(d, "kind"), suffix])


static func _foot_ok(map: FloorMap, c: Vector2i, fw: int, fd: int) -> bool:
	for y in range(c.y - fd, c.y + 2):
		for x in range(c.x - fw / 2 - 1, c.x - fw / 2 + fw + 1):
			var q := Vector2i(x, y)
			if not map.in_bounds(q) or not map.is_walkable(q) or map.def_at(q).ramp:
				return false
	return true


## 장애물 줄(3층 오픈 필드 — 트인 들판 위에 강 · 도랑 · 능선 · 갈대 · 방벽을 긋는다): gen "strokes": [{"points": [[x, y], …](지도 칸),
## "width", "tile", "wiggle"(굽이 폭, 기본 0), "gaps": [[t0, t1], …](0~1 — 그 구간은 긋지 않는다: 여울 · 문)}].
## 구간 터를 판 뒤에 긋는다. 걸을 수 있는 타일은 판 칸, 아니면 벽 칸(메움으로 덮지 않는다). 지도 가장자리 3칸은 건드리지 않는다.
static func strokes(map: FloorMap, rng: Rng, g: Dictionary, walk: PackedByteArray) -> void:
	for sd: Dictionary in JsonUtil.get_array(g, "strokes"):
		var pts := JsonUtil.get_array(sd, "points")
		if pts.size() < 2:
			continue
		var ti := map.index_of(JsonUtil.get_str(sd, "tile"))
		var mark := 1 if map.defs[ti].walkable else 2
		var r := JsonUtil.get_float(sd, "width", 3.0) * 0.5
		var wig := JsonUtil.get_float(sd, "wiggle", 0.0)
		var gaps := JsonUtil.get_array(sd, "gaps")
		var total := 0.0
		for i in range(1, pts.size()):
			total += Vector2(float(pts[i][0]) - float(pts[i - 1][0]), float(pts[i][1]) - float(pts[i - 1][1])).length()
		var p1 := rng.randf_range(0.0, TAU)
		var run := 0.0
		for i in range(1, pts.size()):
			var a := Vector2(float(pts[i - 1][0]), float(pts[i - 1][1]))
			var b := Vector2(float(pts[i][0]), float(pts[i][1]))
			var n := maxi(1, ceili(a.distance_to(b)))
			var side := (b - a).normalized().orthogonal()
			for k in n + 1:
				var u := float(k) / float(n)
				var t := (run + a.distance_to(b) * u) / maxf(1.0, total)
				var skip := false
				for gp: Variant in gaps:
					skip = skip or (t >= float(gp[0]) and t <= float(gp[1]))
				if skip:
					continue
				var c := a.lerp(b, u) + side * sin(t * total * 0.12 + p1) * wig
				var ri := ceili(r)
				for y in range(int(c.y) - ri, int(c.y) + ri + 1):
					for x in range(int(c.x) - ri, int(c.x) + ri + 1):
						var q := Vector2i(x, y)
						if Vector2(q).distance_to(c) <= r and _ok(map, q):
							map.tiles[map.idx(q)] = ti
							walk[map.idx(q)] = mark
			run += a.distance_to(b)
