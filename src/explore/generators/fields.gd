class_name FieldsGenerator
extends FloorGenerator
## 들판 생성기(2층부터 — docs/plans/floors_2_10.md §2-2 · floor2.md §13). 지형 문법 gen.grammar가 모양을 정한다.
## 문법: "route" — 손으로 설계한 길 그래프(구간 · 길 · 곁길 · 회랑 · 표지)를 판다(FieldsRoute). 예전 "marsh"(열린 늪)는
## 사용자 결정(2026-11-05 "의도된 경로가 있는 느낌으로")으로 없앴다.
## 공통 gen: {"size": [w, h], "seed": 고정 시드(있으면 원정마다 같은 지도 — 길을 익힌다), "tiles": {"rise", "floor", "down", "up"}}.
## 시작 = 구간 kind "arrival" 가운데, 도착 비석(아래층 — 포탈 kind "floor_down") = 시작 두 칸 남쪽,
## 위층 포탈 = 구간 kind "exit" 가운데(층 JSON portals[0]). 불변식: 걸을 수 있는 칸은 모두 시작에서 닿는다(닿지 않는 칸은 외곽으로 메운다).


func generate(db: GameDatabase, floor_def: Dictionary, rng: Rng) -> FloorMap:
	var g := JsonUtil.get_dict(floor_def, "gen")
	var t := JsonUtil.get_dict(g, "tiles")
	var size := JsonUtil.get_array(g, "size")
	var w := int(size[0])
	var h := int(size[1])
	if g.has("seed"):
		rng = Rng.new(JsonUtil.get_int(g, "seed"))
	var map := FloorMap.new(db, w, h, JsonUtil.get_str(t, "rise"))
	map.floor_id = JsonUtil.get_str(floor_def, "id")
	map.seed_value = rng.seed_value
	FieldsRoute.build(map, db, floor_def, g, rng)
	var down := map.entry + Vector2i(0, 2)
	map.set_tile(down, JsonUtil.get_str(t, "down"))
	map.portals.append({"id": "to_below", "pos": down, "dir": "south", "to_floor": JsonUtil.get_int(floor_def, "floor", 2) - 1,
		"kind": "floor_down", "found": true})
	var spec := JsonUtil.get_array(floor_def, "portals")
	if not spec.is_empty():
		var sd: Dictionary = spec[0]
		map.set_tile(map.center, JsonUtil.get_str(t, "up"))
		map.portals.append({"id": JsonUtil.get_str(sd, "id"), "pos": map.center, "dir": JsonUtil.get_str(sd, "dir", "north"),
			"to_floor": JsonUtil.get_int(sd, "to_floor"), "dest": JsonUtil.get_str(sd, "dest"), "found": false})
	_unblock(map, db, floor_def)  # 소품이 출발점 · 출구 사이 길을 끊었으면 그 소품을 치운다(3층 — 출발점이 여럿)
	_seal_unreachable(map, JsonUtil.get_str(t, "rise"))
	FloorGoal.place_gate(map, g)  # 고개 쇠문(층 목표 — 메운 뒤에, 문 너머가 메워지지 않게, FL18)
	map.dark = FloorMap._zeros(w * h)
	FieldsRouteBuild.crypts(map, g)
	FieldsRouteBuild.maws(map, g, map.anchors.get("nodes", {}))  # 닿지 않는 따로 된 방(지하 묘실) — 메운 뒤에 판다(FL14)
	return map


func validate(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var g := JsonUtil.get_dict(floor_def, "gen")
	if JsonUtil.get_str(g, "grammar") != "route":
		out.append("fields: gen.grammar는 \"route\"")
	var size := JsonUtil.get_array(g, "size")
	if size.size() != 2 or int(size[0]) < 40 or int(size[1]) < 40:
		out.append("fields: gen.size는 [40 이상, 40 이상]")
	var tiles := PackedStringArray()
	var t := JsonUtil.get_dict(g, "tiles")
	for k in ["rise", "floor", "down", "up"]:
		tiles.append(JsonUtil.get_str(t, k))
	for z: Variant in JsonUtil.get_dict(g, "zone_fill").values():
		tiles.append(str(z))
	for z: Variant in JsonUtil.get_dict(g, "zone_floor").values():
		tiles.append(str(z))
	var ids := {}
	var kinds := {}
	for nd: Variant in JsonUtil.get_array(g, "nodes"):
		var d: Dictionary = nd if nd is Dictionary else {}
		var id := JsonUtil.get_str(d, "id")
		if id.is_empty() or ids.has(id) or JsonUtil.get_array(d, "at").size() != 2:
			out.append("fields: 구간 id가 비었거나 겹치거나 at이 [x, y]가 아니다 — '%s'" % id)
		ids[id] = true
		kinds[JsonUtil.get_str(d, "kind")] = true
		for k in ["tile", "beacon"]:
			if d.has(k):
				tiles.append(JsonUtil.get_str(d, k))
		for pd: Variant in JsonUtil.get_array(d, "props"):
			tiles.append(JsonUtil.get_str(pd if pd is Dictionary else {}, "tile"))
	if not kinds.has("arrival") or not kinds.has("exit"):
		out.append("fields: 구간 kind arrival · exit가 하나씩 있어야 한다")
	for e: Variant in JsonUtil.get_array(g, "edges"):
		var d: Dictionary = e if e is Dictionary else {}
		if not ids.has(JsonUtil.get_str(d, "a")) or not ids.has(JsonUtil.get_str(d, "b")):
			out.append("fields: 길 %s → %s — 없는 구간" % [JsonUtil.get_str(d, "a"), JsonUtil.get_str(d, "b")])
		for k in ["tile", "walls"]:
			if d.has(k):
				tiles.append(JsonUtil.get_str(d, k))
	for c: Variant in JsonUtil.get_array(g, "crypts"):
		for v: Variant in JsonUtil.get_dict(c if c is Dictionary else {}, "legend").values():
			tiles.append(str(v))
	for key in ["props", "ruins", "fence", "outer_props", "crumble", "drops"]:
		for pd: Variant in JsonUtil.get_array(g, key):
			tiles.append(JsonUtil.get_str(pd if pd is Dictionary else {}, "tile"))
	if g.has("gate"):
		tiles.append(JsonUtil.get_str(JsonUtil.get_dict(g, "gate"), "tile"))
	for z: Variant in JsonUtil.get_dict(g, "zone_low").values():
		tiles.append(str(z))
	for k: Variant in JsonUtil.get_dict(g, "levels").values():
		tiles.append(str(k))
	for st: Variant in JsonUtil.get_array(g, "stamps"):
		var sd: Dictionary = st if st is Dictionary else {}
		if not ids.has(JsonUtil.get_str(sd, "node")):
			out.append("fields: 장소 조각 — 없는 구간 '%s'" % JsonUtil.get_str(sd, "node"))
		for v: Variant in JsonUtil.get_dict(sd, "legend").values():
			tiles.append(str(v))
	for nd: Variant in JsonUtil.get_array(g, "nodes"):
		for td: Variant in JsonUtil.get_array(nd if nd is Dictionary else {}, "terraces"):
			if (td as Dictionary).has("tile"):
				tiles.append(JsonUtil.get_str(td, "tile"))
	for u: Variant in JsonUtil.get_dict(g, "landmarks_under").values():
		tiles.append(str(u))
	for b: Variant in JsonUtil.get_array(g, "buildings"):
		var bd: Dictionary = b if b is Dictionary else {}
		if not ids.has(JsonUtil.get_str(bd, "node")) or JsonUtil.get_array(bd, "at").size() != 2 or JsonUtil.get_array(bd, "size").size() != 2:
			out.append("fields: 건물 — 없는 구간이거나 at · size가 [x, y]가 아니다")
		for k in ["wall", "floor", "path"]:
			if bd.has(k):
				tiles.append(JsonUtil.get_str(bd, k))
	for tid in tiles:
		if not db.has_entry("tiles", tid):
			out.append("fields: 타일 '%s' 없음" % tid)
	return out


## 시작에서 닿지 않는 걸을 수 있는 칸은 외곽으로 메운다(소품 · 벽이 막아 만든 섬).
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



## 출발점(구간 kind arrival — 여럿일 수 있다) · 출구가 시작에서 모두 닿는지 보고, 닿지 않으면 서 있는 소품(밑 바닥 stand_under가 있는 칸)을
## 지나갈 수 있다고 치고 가장 적은 소품을 지나는 길(0-1 너비 우선)을 찾아 그 길 위 소품만 밑 바닥으로 되돌린다. 소품은 둘레 8칸이 트인 곳에만 서지만,
## 장면(구간 props at)이 좁은 둑에서 줄로 서면 길을 끊을 수 있다(3층 강어귀 — 출발점이 여럿).
func _unblock(map: FloorMap, db: GameDatabase, floor_def: Dictionary) -> void:
	var targets: Array[Vector2i] = [map.center]
	for nd: Variant in JsonUtil.get_array(JsonUtil.get_dict(floor_def, "gen"), "nodes"):
		var d: Dictionary = nd
		if JsonUtil.get_str(d, "kind") == "arrival":
			var at := JsonUtil.get_array(d, "at")
			targets.append(Vector2i(int(at[0]), int(at[1])))
	var prop := func(q: Vector2i) -> bool:
		var d := map.def_at(q)
		return not d.walkable and not d.stand_under.is_empty() and db.has_entry("tiles", d.stand_under)
	for q in targets:
		if not map.in_bounds(q) or not map.is_walkable(q) or map.entry == q:
			continue
		var n := map.width * map.height
		var cost := PackedInt32Array()
		cost.resize(n)
		cost.fill(1 << 30)
		var prev := PackedInt32Array()
		prev.resize(n)
		prev.fill(-1)
		var dq: Array[Vector2i] = [map.entry]
		cost[map.idx(map.entry)] = 0
		var head := 0
		var front: Array[Vector2i] = []  # 비용 0 칸은 앞에(두 줄 대기열)
		while head < dq.size() or not front.is_empty():
			var p: Vector2i = front.pop_back() if not front.is_empty() else dq[head]
			if front.is_empty() and head < dq.size() and dq[head] == p:
				head += 1
			if p == q:
				break
			for dd in FloorMap.DIRS4:
				var r := p + dd
				if not map.in_bounds(r):
					continue
				var w := 0 if map.is_walkable(r) else (1 if prop.call(r) else -1)
				if w < 0:
					continue
				var c := cost[map.idx(p)] + w
				if c < cost[map.idx(r)]:
					cost[map.idx(r)] = c
					prev[map.idx(r)] = map.idx(p)
					if w == 0:
						front.append(r)
					else:
						dq.append(r)
		if cost[map.idx(q)] <= 0 or cost[map.idx(q)] >= (1 << 30):
			continue
		var i := map.idx(q)
		while i >= 0:
			var c := map.pos_of(i)
			if prop.call(c):
				map.set_tile(c, map.def_at(c).stand_under)
			i = prev[i]
