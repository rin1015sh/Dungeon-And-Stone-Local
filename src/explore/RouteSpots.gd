class_name RouteSpots
extends RefCounted
## 길 그래프 구간에 놓는 것(floor2.md §13 — 층 JSON "route_spots"): 입장 때 한 번.
##   guards: [{"node", "monsters": [..]}] — 그 구간 가운데에 지키는 무리(관문 · 엘리트 — 고정 무리, 리스폰 없음)
##   features: [{"node", "event", "at": [dx, dy]}] — 그 구간 가운데에서 at만큼 떨어진 칸에 동굴 요소(쉼터 모닥불 · 곁길 보상)
##   scatter: [{"zone" | "node"(+ "r"), "event", "count"}] — 그 구역(또는 구간 반지름 r 안)의 둘레 8칸이 트인 칸 count곳에 무작위로
##     (원정마다 자리가 바뀐다 — 파헤칠 무덤 · 비문, FL13)
## 구간 자리는 map.anchors["nodes"](FieldsRoute). 자리가 걸을 수 없으면 둘레 빈 칸.


static func place_features(s: ExploreSession) -> void:
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	for f: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "features"):
		var fd: Dictionary = f if f is Dictionary else {}
		var at := JsonUtil.get_array(fd, "at")
		var c: Vector2i = nodes.get(JsonUtil.get_str(fd, "node"), Vector2i(-1, -1))
		if c.x < 0:
			continue
		var p := c + (Vector2i(int(at[0]), int(at[1])) if at.size() == 2 else Vector2i.ZERO)
		var def := s.db.get_entry("events", JsonUtil.get_str(fd, "event"))
		if def.is_empty() or not s.map.is_walkable(p) or not s.map.portal_at(p).is_empty():
			continue
		s.map.set_tile(p, JsonUtil.get_str(def, "tile"))
		s.features.add_at(s, JsonUtil.get_str(fd, "event"), p)


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
			for tries in 60:
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
				if not open or Vector2(p - s.map.entry).length() < 6.0:
					continue
				s.map.set_tile(p, JsonUtil.get_str(def, "tile"))
				s.features.add_at(s, JsonUtil.get_str(fd, "event"), p)
				break


static func place_guards(s: ExploreSession) -> void:
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	for gd: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "guards"):
		var d: Dictionary = gd if gd is Dictionary else {}
		var c: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		var ids := JsonUtil.get_array(d, "monsters")
		if c.x >= 0 and not ids.is_empty():
			s.monsters.add_fixed(ids, c)
