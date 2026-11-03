class_name TownRules
extends RefCounted
## 검사 규칙: 도시 동네 지도(data/town — TownMap, CT82) · city.json town.
## 지도가 있는가 · 거리 시설(facility_order)마다 건물과 문이 하나씩 · 문은 건물 앞면 맨 아래 줄이고 문 앞은 걷는 칸 ·
## 들어온 자리에서 모든 문 앞·구역문 앞까지 걸어서 닿는가.

const AREA_KINDS := ["street", "avenue", "paving", "plaza", "stairs", "bridge", "yard", "water", "retain", "wall", "gate", "dais"]
const STYLES := ["gothic", "rotunda", "hall", "stone", "inn", "arcade", "workshop"]
const PROPS := ["lamp", "tent", "board", "barrel", "crate", "sacks", "well", "grave"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	var cfg := JsonUtil.get_dict(city, "town")
	for key: String in ["floor_tile", "block_tile"]:
		v.ref("city.town." + key, "tiles", JsonUtil.get_str(cfg, key))
	var map_id := JsonUtil.get_str(cfg, "map")
	v.ref("city.town.map", "town", map_id)
	if not v.db.has_entry("town", map_id):
		return
	var d := v.db.get_entry("town", map_id)
	var w := "town/" + map_id
	for a: Variant in JsonUtil.get_array(d, "areas"):
		if not JsonUtil.get_str(a as Dictionary, "kind") in AREA_KINDS:
			v.err(w, "areas kind는 %s 중에서" % [AREA_KINDS])
	for p: Variant in JsonUtil.get_array(d, "props"):
		if not JsonUtil.get_str(p as Dictionary, "kind") in PROPS:
			v.err(w, "props kind는 %s 중에서" % [PROPS])
	var t := TownMap.load_for(v.db)
	var seen := {}
	for b: Variant in JsonUtil.get_array(d, "buildings"):
		var fac := JsonUtil.get_str(b as Dictionary, "facility")
		v.ref(w + ".buildings", "facilities", fac)
		if not JsonUtil.get_str(b as Dictionary, "style") in STYLES:
			v.err(w, "%s style은 %s 중에서" % [fac, STYLES])
		seen[fac] = true
	for fac: Variant in JsonUtil.get_array(city, "facility_order"):
		if not seen.has(str(fac)):
			v.err(w, "거리 시설 '%s'의 건물이 없다" % fac)
	var reach := t.map.reachable_from(t.start)
	if not t.is_walkable(t.start):
		v.err(w, "start가 걷는 칸이 아니다")
		return
	for h: Dictionary in t.houses:
		if str(h["facility"]).is_empty():
			continue
		var door: Vector2i = h["door"]
		var rc: Rect2i = h["rect"]
		if door.y != rc.end.y - 1 or door.x < rc.position.x or door.x >= rc.end.x:
			v.err(w, "%s 문 %s은 건물 앞면 맨 아래 줄에" % [h["facility"], door])
		var front := door + Vector2i(0, 1)
		if not t.is_walkable(front) or reach[t.map.idx(front)] == 0:
			v.err(w, "%s 문 앞 %s에 들어온 자리에서 걸어 닿지 않는다" % [h["facility"], front])
	for g: Vector2i in t.gates:
		var ok := false
		for n: Vector2i in [g + Vector2i.DOWN, g + Vector2i.RIGHT, g + Vector2i.LEFT, g + Vector2i.UP]:
			if t.map.in_bounds(n) and t.is_walkable(n) and reach[t.map.idx(n)] != 0:
				ok = true
		if not ok and (t.gates[g] as Dictionary).get("travel", false) and _edge_cell(t, g):
			v.err(w, "구역문 %s 앞에 걸어 닿지 않는다" % g)


## 구역문 칸 가운데 길 쪽 한 줄(안쪽으로 이어진 칸)만 본다(성벽 · 지도 밖 빈곳은 길이 아니다).
static func _edge_cell(t: TownMap, g: Vector2i) -> bool:
	for n: Vector2i in [g + Vector2i.DOWN, g + Vector2i.RIGHT, g + Vector2i.LEFT, g + Vector2i.UP]:
		if t.map.in_bounds(n) and not t.kind_at(n) in ["gate", "wall", "void"]:
			return true
	return false
