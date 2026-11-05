class_name RouteSpots
extends RefCounted
## 길 그래프 구간에 놓는 것(floor2.md §13 — 층 JSON "route_spots"): 입장 때 한 번.
##   guards: [{"node", "monsters": [..]}] — 그 구간 가운데에 지키는 무리(관문 · 엘리트 — 고정 무리, 리스폰 없음)
##   features: [{"node", "event", "at": [dx, dy]}] — 그 구간 가운데에서 at만큼 떨어진 칸에 동굴 요소(쉼터 모닥불 · 곁길 보상)
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


static func place_guards(s: ExploreSession) -> void:
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	for gd: Variant in JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "guards"):
		var d: Dictionary = gd if gd is Dictionary else {}
		var c: Vector2i = nodes.get(JsonUtil.get_str(d, "node"), Vector2i(-1, -1))
		var ids := JsonUtil.get_array(d, "monsters")
		if c.x >= 0 and not ids.is_empty():
			s.monsters.add_fixed(ids, c)
