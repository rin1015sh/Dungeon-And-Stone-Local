class_name RouteSpots
extends RefCounted
## 길 그래프 구간에 놓는 것(floor2.md §13 — 층 JSON "route_spots"): 입장 때 한 번.
##   guards: [{"node", "monsters": [..]}] — 그 구간 가운데에 지키는 무리(관문 · 엘리트 — 고정 무리, 리스폰 없음)
##   features: [{"node", "event", "at": [dx, dy], "tile"(없으면 요소의 tile), "object": true(타일을 바꾸지 않는다 — 닫힌 쇠문)}] — 그 구간 가운데에서 at만큼 떨어진 칸에 동굴 요소(쉼터 모닥불 · 곁길 보상)
##   scatter: [{"zone" | "node"(+ "r"), "event", "count"}] — 그 구역(또는 구간 반지름 r 안)의 둘레 8칸이 트인 칸 count곳에 무작위로
##     (원정마다 자리가 바뀐다 — 파헤칠 무덤 · 비문, FL13)
## 자리는 "edge" + "t"(길 위 — FL18), "node"(map.anchors["nodes"] — FieldsRoute) 또는 "mark"(map.anchors["marks"] — 지하 묘실 등, FL14) + "at". 자리가 걸을 수 없으면 둘레 빈 칸.


static func place_features(s: ExploreSession) -> void:
	for f: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "features"):
		var fd: Dictionary = f if f is Dictionary else {}
		var at := JsonUtil.get_array(fd, "at")
		var c := _anchor(s, fd)
		if c.x < 0:
			continue
		var p := c + (Vector2i(int(at[0]), int(at[1])) if at.size() == 2 else Vector2i.ZERO)
		var def := s.db.get_entry("events", JsonUtil.get_str(fd, "event"))
		var obj := JsonUtil.get_bool(fd, "object")  # 이미 있는 물체 칸에(닫힌 쇠문 — 타일을 바꾸지 않고 걷지 못하는 칸도 된다)
		if def.is_empty():
			continue
		if not obj and not _free(s, p):  # 물체 칸은 포탈 자리여도 된다(진짜 비석)
			p = _free_near(s, p)  # 무작위 소품이 그 칸에 섰다 — 둘레 빈 칸으로(종 · 궤짝이 사라지지 않게)
			if p.x < 0:
				continue
		var tile := JsonUtil.get_str(fd, "tile", JsonUtil.get_str(def, "tile"))
		if not obj and not tile.is_empty():  # 그림 없는 요소(다가가면 한 줄 — near만)는 바닥을 그대로
			s.map.set_tile(p, tile)  # "tile": 그 층 바닥에 맞춘 요소 칸(망자의 땅 — 1층 바닥 네모가 비치지 않게)
		s.features.add_at(s, JsonUtil.get_str(fd, "event"), p)


static func _free(s: ExploreSession, p: Vector2i) -> bool:
	return s.map.is_walkable(p) and s.map.portal_at(p).is_empty() and not s.features.has_at(p)


## p 둘레(1~3칸, 가까운 고리부터) 걸을 수 있고 포탈 · 요소가 없는 칸. 없으면 (-1, -1).
static func _free_near(s: ExploreSession, p: Vector2i) -> Vector2i:
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if maxi(absi(dx), absi(dy)) == r and s.map.in_bounds(q) and _free(s, q):
					return q
	return Vector2i(-1, -1)


static func scatter(s: ExploreSession) -> void:
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	for f: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "scatter"):
		var fd: Dictionary = f if f is Dictionary else {}
		var def := s.db.get_entry("events", JsonUtil.get_str(fd, "event"))
		if def.is_empty():
			continue
		var zi := s.map.zone_ids.find(JsonUtil.get_str(fd, "zone"))
		var c: Vector2i = nodes.get(JsonUtil.get_str(fd, "node"), Vector2i(-1, -1))
		var r := JsonUtil.get_float(fd, "r", 10.0)
		for n in JsonUtil.get_int(fd, "count"):
			for tries in (60 if c.x >= 0 else 600):  # 구역 전체에서 고를 땐 넉넉히(소품 밑 바닥이 맞는 칸만 — 드물다)
				var p: Vector2i
				if c.x >= 0:
					p = c + Vector2i(s.rng.randi_range(-int(r), int(r)), s.rng.randi_range(-int(r), int(r)))
				else:
					p = Vector2i(s.rng.randi_range(3, s.map.width - 4), s.rng.randi_range(3, s.map.height - 4))
				if not s.map.in_bounds(p) or (c.x < 0 and s.map.zones[s.map.idx(p)] != zi) or s.features.live_at(p) or not s.map.portal_at(p).is_empty():
					continue
				var open := true
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var q := p + Vector2i(dx, dy)
						open = open and s.map.is_walkable(q) and not s.features.live_at(q) and not s.map.def_at(q).ramp
				var under := s.map.defs[s.map.index_of(JsonUtil.get_str(def, "tile"))].stand_under
				open = open and (under.is_empty() or FieldsRoute.under_ok(s.map, p, under)) and not s.map.is_dark(p)
				for mw: Vector2i in s.map.anchors.get("maws", []):  # 아귀 입 둘레는 비운다(FL15)
					open = open and Vector2(p - mw).length() > 2.5
				if not open or Vector2(p - s.map.entry).length() < 6.0:
					continue
				s.map.set_tile(p, JsonUtil.get_str(def, "tile"))
				s.features.add_at(s, JsonUtil.get_str(fd, "event"), p)
				break


## 지형 덫(고블린 숲 — FL21): route_spots "hazards": [{"zone" 또는 "node" · "edge"+"t"(+ "r" — 그 둘레에 몰아서, FL22), "on": 바닥 타일, "event"(요소 hazard 정의), "count", "gap": 칸}]
## — 그 구역 · 그 바닥 칸에 숨은 덫 묶음(RiftHazards — FieldFeatures.hazards)을 흩뿌린다. 도착 칸 8칸 안 · 포탈 칸은 피한다. 원정마다 자리가 바뀐다.
static func scatter_hazards(s: ExploreSession) -> void:
	for f: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "hazards"):
		var fd: Dictionary = f if f is Dictionary else {}
		var hd := JsonUtil.get_dict(s.db.get_entry("events", JsonUtil.get_str(fd, "event")), "hazard")
		if hd.is_empty():
			continue
		var zi := s.map.zone_ids.find(JsonUtil.get_str(fd, "zone")) if fd.has("zone") else -1
		var on := s.map.index_of(JsonUtil.get_str(fd, "on"))
		var gap := JsonUtil.get_float(fd, "gap", 4.0)
		var c := _anchor(s, fd) if fd.has("node") or fd.has("edge") or fd.has("mark") else Vector2i(-1, -1)  # 덫 밭: 그 자리 둘레 r칸에 몰아서(FL22)
		var r := JsonUtil.get_int(fd, "r", 8)
		var placed: Array[Vector2i] = []
		for n in JsonUtil.get_int(fd, "count"):
			for tries in 400:
				var p := Vector2i(s.rng.randi_range(2, s.map.width - 3), s.rng.randi_range(2, s.map.height - 3)) if c.x < 0 \
					else c + Vector2i(s.rng.randi_range(-r, r), s.rng.randi_range(-r, r))
				if not s.map.in_bounds(p):
					continue
				var i := s.map.idx(p)
				if s.map.tiles[i] != on or (zi >= 0 and s.map.zones[i] != zi) or Vector2(p - s.map.entry).length() < 8.0 \
						or s.features.hazards.at.has(p) or placed.any(func(q: Vector2i) -> bool: return Vector2(q - p).length() < gap):
					continue
				s.features.hazards.add_group(s, hd, p)
				placed.append(p)
				break


static func place_guards(s: ExploreSession) -> void:
	for gd: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "guards"):
		var d: Dictionary = gd if gd is Dictionary else {}
		var at := JsonUtil.get_array(d, "at")
		var c := _anchor(s, d) + (Vector2i(int(at[0]), int(at[1])) if at.size() == 2 else Vector2i.ZERO)
		var ids := JsonUtil.get_array(d, "monsters")
		if c.x >= 0 and not ids.is_empty():
			s.monsters.add_fixed(ids, c)


## 자리 기준 칸: "node" 또는 "mark". 없으면 (-1, -1).
static func _anchor(s: ExploreSession, d: Dictionary) -> Vector2i:
	var e := JsonUtil.get_array(d, "edge")  # 길 위: "edge": [구간 a, 구간 b], "t": 0~1 — 곧은 선의 그 지점에서 가장 가까운 걸을 수 있는 칸(FL18)
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	if e.size() == 2 and nodes.has(str(e[0])) and nodes.has(str(e[1])):
		var p := Vector2i(Vector2(nodes[str(e[0])] as Vector2i).lerp(Vector2(nodes[str(e[1])] as Vector2i), JsonUtil.get_float(d, "t", 0.5)).round())
		return RouteAmbush._walkable_near(s.map, p)
	if d.has("mark"):
		return (s.map.anchors.get("marks", {}) as Dictionary).get(JsonUtil.get_str(d, "mark"), Vector2i(-1, -1))
	return (s.map.anchors.get("nodes", {}) as Dictionary).get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
