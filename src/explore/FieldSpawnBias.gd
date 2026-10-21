class_name FieldSpawnBias
extends RefCounted
## 필드 무리를 어디에·무엇으로 세울지 치우치게 하는 규칙(순수 로직, 층 JSON "spawn"):
##   cluster {"share": 비율, "radius_tiles": n, "features": {동굴 요소 id: [몬스터 id …]}}
##     입장 때 무리의 share만큼은 그 지역 안의 소굴(동굴 요소 자리) 둘레 radius칸에 세운다 — 위험한 곳과 고요한 굴이 번갈아 온다.
##     목록이 비었으면(물가 등) 지역 몬스터 표에서 고른다. 그 지역 표에 없는 몬스터는 세우지 않는다.
##   growth_bias {"min_day": n, "monster": id, "chance": p}: min_day일 차부터 시간이 지나 늘어나는 무리가 p 확률로 그 몬스터.


## 소굴 둘레 자리 {"cell", "monster"}. 고르지 않았으면(share 굴림 실패·소굴 없음) {}. in_area = 칸이 그 지역인가.
static func cluster_spot(map: FloorMap, rng: Rng, cluster: Dictionary, region: Dictionary, avoid: Vector2i,
		in_area: Callable) -> Dictionary:
	if cluster.is_empty() or not rng.chance(JsonUtil.get_float(cluster, "share")):
		return {}
	var feats := JsonUtil.get_dict(cluster, "features")
	var list := JsonUtil.get_array(region, "monsters")
	var spots: Array[Dictionary] = []
	for f: Dictionary in map.features:
		var fid := str(f["id"])
		if feats.has(fid) and bool(in_area.call(f["pos"])):
			spots.append(f)
	if spots.is_empty():
		return {}
	var f: Dictionary = rng.pick(spots)
	var wants: Array = (feats[str(f["id"])] as Array).filter(func(id: Variant) -> bool: return list.has(id))
	if not (feats[str(f["id"])] as Array).is_empty() and wants.is_empty():
		return {}
	var radius := JsonUtil.get_int(cluster, "radius_tiles", 12)
	var cell := FieldRoutes.random_cell_near(map, rng, f["pos"], radius,
		func(p: Vector2i) -> bool: return bool(in_area.call(p)) and (p - avoid).length_squared() > 100)
	if cell.x < 0:
		return {}
	var mid := str(rng.pick(wants)) if not wants.is_empty() else _weighted(rng, region)
	return {"cell": cell, "monster": mid}


## 시간이 지나 늘어나는 무리의 몬스터("" = 지역 표대로).
static func growth_monster(db: GameDatabase, rng: Rng, spawn: Dictionary, now: float) -> String:
	var gb := JsonUtil.get_dict(spawn, "growth_bias")
	var mid := JsonUtil.get_str(gb, "monster")
	if mid.is_empty() or not db.has_entry("monsters", mid) or floori(now / 24.0) + 1 < JsonUtil.get_int(gb, "min_day", 3):
		return ""
	return mid if rng.chance(JsonUtil.get_float(gb, "chance")) else ""


static func _weighted(rng: Rng, region: Dictionary) -> String:
	var list := JsonUtil.get_array(region, "monsters")
	var wt := JsonUtil.get_dict(region, "weights")
	var weights: Array = list.map(func(id: Variant) -> float: return JsonUtil.get_float(wt, str(id), 1.0))
	var k := rng.weighted_index(weights)
	return str(list[k]) if k >= 0 else ""
