class_name FloorIncidents
extends RefCounted
## 사건 덱(plans/expansion_f1_3_D §0 — 2026-11-19): 고정 지도에서 사건이 늘 같은 자리 · 같은 방식으로 일어나지 않게,
## 원정마다 층 JSON "incidents"의 덱에서 몇 장을 뽑아 후보 자리 중 하나에 놓는다. 순수 로직(오토로드 비의존).
##   "incidents": {"per_expedition": [최소, 최대], "gap": 사건끼리 최소 칸(40), "entry_gap": 도착 칸에서 최소 칸(20),
##     "pool": [{"id", "weight", "any": [자리 …](RouteSpots 자리 키 — "node" · "mark" · "edge"+"t", 또는 "feature": 요소 id(지도에 놓인
##        그 요소 중 하나 곁 — 1층처럼 구간 이름이 없는 지도) · "zone": 구역 id(그 구역의 트인 칸 하나), + "at"),
##       "days": [from, to](원정 날 1부터 — from날이 되면 놓는다, to날이 지나면 아직 안 놓은 것은 버린다. 없으면 [1, 10]),
##       "features": [{"event", "at", "tile"}](그 자리 + at에 요소), "guards": [{"monsters", "at"}](지키는 무리 — 몬스터가 켜져 있을 때),
##       "ambush": [{"at", "monsters", "radius", "line", "sound", …}](길목 매복 — RouteAmbush 항목에서 자리 키만 빼고)}]}
## 한 원정에 한 사건 한 번. 사건이 이미 있는 요소 · 매복 · 무리 장치를 놓기만 하므로 그 다음은 그 장치들의 규칙을 따른다.

var chosen: Array[Dictionary] = []  ## {def: 덱 항목, at: Vector2i, placed: bool}


static func build(s: ExploreSession) -> FloorIncidents:
	var cfg := JsonUtil.get_dict(s.floor_def, "incidents")
	var pool := JsonUtil.get_array(cfg, "pool")
	if pool.is_empty():
		return null
	var fi := FloorIncidents.new()
	var nr := JsonUtil.get_array(cfg, "per_expedition")
	var want := s.side_rng().randi_range(int(nr[0]), int(nr[1])) if nr.size() == 2 else 2
	var left: Array = pool.duplicate()
	var gap := JsonUtil.get_float(cfg, "gap", 40.0)
	var entry_gap := JsonUtil.get_float(cfg, "entry_gap", 20.0)
	while fi.chosen.size() < want and not left.is_empty():
		var d: Dictionary = _weighted(s, left)
		left.erase(d)
		var at := fi._spot(s, d, gap, entry_gap)
		if at.x >= 0:
			fi.chosen.append({"def": d, "at": at, "placed": false})
	fi.update(s)
	return fi


## 그날이 된 사건을 놓는다(입장 때 · 시간이 흐를 때 — ExploreSession.pass_time).
func update(s: ExploreSession) -> void:
	var day := floori(s.clock.total_hours / 24.0) + 1
	for c in chosen:
		if bool(c["placed"]):
			continue
		var days := JsonUtil.get_array(c["def"], "days")
		var from := int(days[0]) if days.size() == 2 else 1
		var to := int(days[1]) if days.size() == 2 else 99
		if day > to:
			c["placed"] = true  # 놓을 날이 지났다 — 이번 원정에는 없다
		elif day >= from:
			_place(s, c["def"], c["at"])
			c["placed"] = true


func ids() -> Array[String]:
	var out: Array[String] = []
	for c in chosen:
		out.append(JsonUtil.get_str(c["def"], "id"))
	return out


static func _weighted(s: ExploreSession, list: Array) -> Dictionary:
	var total := 0.0
	for d: Variant in list:
		total += JsonUtil.get_float(d as Dictionary, "weight", 1.0)
	var r := s.side_rng().randf() * total
	for d: Variant in list:
		r -= JsonUtil.get_float(d as Dictionary, "weight", 1.0)
		if r <= 0.0:
			return d
	return list[-1]


## 후보 자리 중(섞어서) 다른 사건 · 도착 칸에서 떨어진 첫 자리. 없으면 (-1, -1).
func _spot(s: ExploreSession, d: Dictionary, gap: float, entry_gap: float) -> Vector2i:
	var alts: Array = JsonUtil.get_array(d, "any").duplicate()
	if alts.is_empty():
		alts = [d]
	for i in range(alts.size() - 1, 0, -1):  # 섞기(Rng를 거친다)
		var j := s.side_rng().randi_range(0, i)
		var t: Variant = alts[i]
		alts[i] = alts[j]
		alts[j] = t
	for a: Variant in alts:
		var ad: Dictionary = a if a is Dictionary else {}
		var c := _base(s, ad)
		if c.x < 0:
			continue
		var off := JsonUtil.get_array(ad, "at")
		if off.size() == 2:
			c += Vector2i(int(off[0]), int(off[1]))
		if Vector2(c - s.map.entry).length() < entry_gap:
			continue
		if chosen.any(func(o: Dictionary) -> bool: return Vector2(c - (o["at"] as Vector2i)).length() < gap):
			continue
		return c
	return Vector2i(-1, -1)


## 자리 기준 칸: 요소 곁 · 구역 안 · 그 밖(RouteSpots 자리 키). 없으면 (-1, -1).
static func _base(s: ExploreSession, ad: Dictionary) -> Vector2i:
	if ad.has("feature"):
		var fid := JsonUtil.get_str(ad, "feature")
		var hits: Array = s.features.list.filter(func(e: Dictionary) -> bool: return str(e["id"]) == fid and not bool(e.get("cleared", false)))
		return (s.side_rng().pick(hits) as Dictionary)["pos"] if not hits.is_empty() else Vector2i(-1, -1)
	if ad.has("zone"):
		var zi := s.map.zone_ids.find(JsonUtil.get_str(ad, "zone"))
		for tries in 400:
			var p := Vector2i(s.side_rng().randi_range(3, s.map.width - 4), s.side_rng().randi_range(3, s.map.height - 4))
			if zi >= 0 and s.map.zones[s.map.idx(p)] == zi and _open3(s, p):
				return p
		return Vector2i(-1, -1)
	return RouteSpots._anchor(s, ad)


static func _open3(s: ExploreSession, p: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := p + Vector2i(dx, dy)
			if not s.map.is_walkable(q) or s.map.in_safe_zone(q) or not s.map.portal_at(q).is_empty() or s.features.live_at(q):
				return false
	return true


static func _place(s: ExploreSession, d: Dictionary, at: Vector2i) -> void:
	for f: Variant in JsonUtil.get_array(d, "features"):
		var fd: Dictionary = f if f is Dictionary else {}
		RouteSpots.place_feature(s, fd, at + _off(fd))
	if s.monsters_enabled:
		for g: Variant in JsonUtil.get_array(d, "guards"):
			var gd: Dictionary = g if g is Dictionary else {}
			var ids := JsonUtil.get_array(gd, "monsters")
			var p := RouteAmbush._walkable_near(s.map, at + _off(gd))
			if not ids.is_empty() and p.x >= 0:
				s.monsters.add_fixed(ids, p)
	for a: Variant in JsonUtil.get_array(d, "ambush"):
		var ad: Dictionary = a if a is Dictionary else {}
		if s.ambush == null:
			s.ambush = RouteAmbush.new()
		s.ambush.add_spot(s, at + _off(ad), ad)
	s.refresh_view()


static func _off(d: Dictionary) -> Vector2i:
	var o := JsonUtil.get_array(d, "at")
	return Vector2i(int(o[0]), int(o[1])) if o.size() == 2 else Vector2i.ZERO
