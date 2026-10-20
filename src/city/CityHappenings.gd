class_name CityHappenings
extends RefCounted
## 오늘의 거리(사용자 결정 2026-10-20, CT35): 순마다 data/city_events에서 몇 개를 골라 그 시설에 건다.
##   사건 = {id, facility, weight, when{from_month, periods[], weather[], min_renown, bonds{사람 id: 단계}}, activities[], once}.
##   걸린 사건의 activities는 그 순 동안 그 시설의 선택지에 붙는다(활동 JSON의 "extra": true). once면 한 판에 한 번만.
## 거리에서는 그 건물 등롱이 켜진다(CityStreet — 글로 알리지 않는다). 판정은 CityState.rng. 오토로드를 참조하지 않는다.


## 이번 순의 사건을 새로 고른다(같은 시설에 둘은 걸지 않는다). 개수 = city.json happenings.count [최소, 최대].
static func roll(state: CityState) -> void:
	state.happenings.clear()
	var range_v := JsonUtil.get_array(CityValues.city_section(state.db, state.overrides, "happenings"), "count")
	var lo := int(range_v[0]) if range_v.size() > 0 and range_v[0] != null else 0
	var hi := int(range_v[1]) if range_v.size() > 1 and range_v[1] != null else lo
	var n := state.rng.randi_range(mini(lo, hi), maxi(lo, hi)) if hi > 0 else 0
	var pool := eligible(state)
	while state.happenings.size() < n and not pool.is_empty():
		var id := _pick(state, pool)
		state.happenings.append(id)
		var fac := facility_of(state.db, id)
		pool = pool.filter(func(e: String) -> bool: return facility_of(state.db, e) != fac)
	for id in state.happenings:
		if JsonUtil.get_bool(state.db.get_entry("city_events", id), "once") and not state.seen_once.has(id):
			state.seen_once.append(id)


## 지금 걸 수 있는 사건 id(조건을 모두 채운 것, 이름순).
static func eligible(state: CityState) -> Array[String]:
	var out: Array[String] = []
	for id: String in state.db.get_collection("city_events"):
		if _ok(state, state.db.get_entry("city_events", id), id):
			out.append(id)
	out.sort()
	return out


static func _ok(state: CityState, e: Dictionary, id: String) -> bool:
	if JsonUtil.get_float(e, "weight", 1.0) <= 0.0 or not state.db.has_entry("facilities", JsonUtil.get_str(e, "facility")):
		return false
	if JsonUtil.get_bool(e, "once") and state.seen_once.has(id):
		return false
	var w := JsonUtil.get_dict(e, "when")
	if state.month < JsonUtil.get_int(w, "from_month", 1):
		return false
	var periods := JsonUtil.get_array(w, "periods")
	if not periods.is_empty() and not JsonUtil.get_str(state.periods()[state.period] as Dictionary, "id") in periods:
		return false
	var weather := JsonUtil.get_array(w, "weather")
	if not weather.is_empty() and not state.weather in weather:
		return false
	if CityRenown.stage(state) < JsonUtil.get_int(w, "min_renown"):
		return false
	var bonds := JsonUtil.get_dict(w, "bonds")
	for who: Variant in bonds:
		if CityBonds.stage(state, str(who)) < int(bonds[who]):
			return false
	return true


static func _pick(state: CityState, pool: Array[String]) -> String:
	var total := 0.0
	for id in pool:
		total += JsonUtil.get_float(state.db.get_entry("city_events", id), "weight", 1.0)
	var roll_v := state.rng.randf() * total
	for id in pool:
		roll_v -= JsonUtil.get_float(state.db.get_entry("city_events", id), "weight", 1.0)
		if roll_v < 0.0:
			return id
	return pool[-1]


static func facility_of(db: GameDatabase, event_id: String) -> String:
	return JsonUtil.get_str(db.get_entry("city_events", event_id), "facility")


## 이번 순에 이 시설에 걸린 사건이 있는가(거리 등롱).
static func lit(state: CityState, facility_id: String) -> bool:
	for id in state.happenings:
		if facility_of(state.db, id) == facility_id:
			return true
	return false


## 이번 순 이 시설에 붙는 활동 id.
static func activities_at(state: CityState, facility_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in state.happenings:
		if facility_of(state.db, id) == facility_id:
			for a: Variant in JsonUtil.get_array(state.db.get_entry("city_events", id), "activities"):
				if state.db.has_entry("activities", str(a)) and not out.has(str(a)):
					out.append(str(a))
	return out
