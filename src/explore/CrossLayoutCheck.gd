class_name CrossLayoutCheck
extends RefCounted
## 1층 십자가 지도 검사(테스트와 tools/floor_map.gd가 같이 쓴다). 문제 목록 — 비면 통과.
##   - 기념비 옆에서 네 포탈 모두 걸어서 닿는다(플러드필), 그 팔 방향으로만 걸어도 닿는다(나침반 경로)
##   - 기념비·포탈이 통로와 이어져 있고, 걷는 칸이 모두 한 덩어리
##   - 암흑지대 = 네 팔 끝뿐(그 밖엔 없고, 팔 끝은 전부 암흑), 암흑지대엔 수정·빛나는 타일이 없다
##   - 십자가 밖(구역 없음)에는 걷는 칸이 없다


static func problems(map: FloorMap, lay: CrossLayout) -> PackedStringArray:
	var out := PackedStringArray()
	var start := CrystalCaveGenerator.monument_side(map, "south")
	if map.tile_id_at(map.center) != "monument":
		out.append("기념비가 중앙에 없다")
	var reach := map.reachable_from(start)
	var touches_monument := false
	for d in FloorMap.DIRS4:
		if map.is_walkable(map.center + d * 2) and reach[map.idx(map.center + d * 2)] != 0:
			touches_monument = true
	if not touches_monument:
		out.append("기념비 주변이 통로와 이어져 있지 않다")
	if map.portals.size() != 4:
		out.append("2층 포탈이 %d개(4개여야 한다)" % map.portals.size())
	for portal: Dictionary in map.portals:
		var p: Vector2i = portal["pos"]
		var dir := str(portal["dir"])
		if reach[map.idx(p)] == 0:
			out.append("%s 포탈에 닿지 못한다" % dir)
		elif not CrossLayout.compass_path(map, CrystalCaveGenerator.monument_side(map, dir), dir, p):
			out.append("%s 포탈: 팔 방향으로만 걸어서는 닿지 못한다(나침반 경로 없음)" % dir)
		if p != lay.portal_pos(dir) or map.zone_at(p) != dir or not map.is_dark(p):
			out.append("%s 포탈이 고정 자리(팔 끝 암흑지대)에 없다" % dir)
	var lost := 0
	var outside := 0
	var dark_bad := 0
	var lit_in_dark := 0
	for i in map.tiles.size():
		var p := map.pos_of(i)
		var def := map.defs[map.tiles[i]]
		if def.walkable and reach[i] == 0:
			lost += 1
		if def.walkable and map.zone_at(p).is_empty():
			outside += 1
		if (map.dark[i] != 0) != lay.is_dark(p):
			dark_bad += 1
		if map.dark[i] != 0 and def.emits_light() and def.id != "portal":
			lit_in_dark += 1
	if lost > 0:
		out.append("고립된 걷는 칸 %d개" % lost)
	if outside > 0:
		out.append("십자가 밖 걷는 칸 %d개" % outside)
	if dark_bad > 0:
		out.append("암흑지대가 팔 끝 정의와 다른 칸 %d개" % dark_bad)
	if lit_in_dark > 0:
		out.append("암흑지대 안 빛나는 타일 %d개" % lit_in_dark)
	return out


## 지역 스폰 검사: 각 지역에서 n무리를 뽑아 표에 없는 몬스터·구역 밖 칸이 나오면 문제로 적는다.
static func spawn_problems(monsters: FieldMonsters, map: FloorMap, floor_def: Dictionary, n: int) -> PackedStringArray:
	var out := PackedStringArray()
	for r: Variant in JsonUtil.get_array(floor_def, "regions"):
		var region: Dictionary = r if r is Dictionary else {}
		var allowed := JsonUtil.get_array(region, "monsters")
		var zone := JsonUtil.get_str(region, "zone")
		var bad_monster := 0
		var bad_cell := 0
		for k in n:
			var g := monsters.spawn_group(region, Vector2i(-999, -999))
			if g == null:
				continue
			for id in g.monster_ids:
				if not allowed.has(id):
					bad_monster += 1
			if map.zone_at(g.pos) != zone:
				bad_cell += 1
			monsters.groups.erase(g)
		if bad_monster > 0:
			out.append("%s: 표에 없는 몬스터 %d마리" % [region.get("id"), bad_monster])
		if bad_cell > 0:
			out.append("%s: 구역 밖에 나온 무리 %d" % [region.get("id"), bad_cell])
	return out
