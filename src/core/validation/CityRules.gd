class_name CityRules
extends RefCounted
## 검사 규칙: 도시(M4) — city.json(달력·행동력·피로도·상점·은행), 시설(facilities), 활동(activities), 소문/정보(city_info).
## null(미정) 값은 오류가 아니라 경고 목록 한 줄로 모은다(CityValues.nulls).

const IMAGE_PREFIX := "res://"
const SHOWS := ["temple_merit", "bank_balance", "rumors", "lore"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	if city.is_empty():
		v.err("city", "data/city.json(도시 규칙)이 없거나 비었다")
		return
	_calendar(v, JsonUtil.get_dict(city, "calendar"))
	_city_numbers(v, city)
	_facilities(v, city)
	_activities(v)
	_info(v)
	var undecided := CityValues.nulls(v.db)
	if not undecided.is_empty():
		v.warnings.append("도시 미정 값(null) %d개: %s" % [undecided.size(), ", ".join(undecided)])


static func _calendar(v: ValidatorBase, cal: Dictionary) -> void:
	var periods := JsonUtil.get_array(cal, "periods")
	if periods.is_empty():
		v.err("city.calendar", "periods(순)가 비었다")
	var ids: Array[String] = []
	for p: Variant in periods:
		var id := JsonUtil.get_str(p if p is Dictionary else {}, "id")
		if id.is_empty() or ids.has(id):
			v.err("city.calendar", "periods의 id가 비었거나 겹친다: '%s'" % id)
		ids.append(id)
	var st := JsonUtil.get_dict(cal, "start")
	if not JsonUtil.get_str(st, "period") in ids:
		v.err("city.calendar", "start.period '%s'이(가) periods에 없다" % st.get("period"))
	if JsonUtil.get_int(st, "month", 0) < 1:
		v.err("city.calendar", "start.month는 1 이상")
	for key: String in ["months_per_year", "action_points_per_period"]:
		if cal.get(key) != null and JsonUtil.get_int(cal, key, -1) < (1 if key == "months_per_year" else 0):
			v.err("city.calendar", key + " 값이 잘못됐다")


static func _city_numbers(v: ValidatorBase, city: Dictionary) -> void:
	var fat := JsonUtil.get_dict(city, "fatigue")
	var lo: Variant = fat.get("min")
	var hi: Variant = fat.get("max")
	if (lo is float or lo is int) and (hi is float or hi is int) and float(lo) > float(hi):
		v.err("city.fatigue", "min이 max보다 크다")
	var stock: Variant = JsonUtil.get_dict(city, "shop").get("stock")
	if stock is Array:
		for id: Variant in stock:
			v.ref("city.shop.stock", "items", id)
	elif stock != null:
		v.err("city.shop", "stock은 아이템 id 배열 또는 null")


static func _facilities(v: ValidatorBase, city: Dictionary) -> void:
	for id: Variant in JsonUtil.get_array(city, "facility_order"):
		v.ref("city.facility_order", "facilities", id)
	for id: String in v.entries("facilities"):
		var f := v.db.get_entry("facilities", id)
		var w := "facilities/" + id
		for key: String in ["building", "interior"]:
			var path := JsonUtil.get_str(f, key)
			if not path.is_empty() and not path.begins_with(IMAGE_PREFIX):
				v.err(w, key + "는 res:// 경로여야 한다")
		for s: Variant in JsonUtil.get_array(f, "shows"):
			if not str(s) in SHOWS:
				v.err(w, "shows는 %s 중에서" % [SHOWS])
		var acts := JsonUtil.get_array(f, "activities")
		if acts.is_empty():
			v.warn(w, "활동이 없다")
		for a: Variant in acts:
			v.ref(w + ".activities", "activities", a)
			if JsonUtil.get_str(v.db.get_entry("activities", str(a)), "facility") != id:
				v.err(w, "활동 '%s'의 facility가 '%s'가 아니다" % [a, id])


static func _activities(v: ValidatorBase) -> void:
	for id: String in v.entries("activities"):
		var a := v.db.get_entry("activities", id)
		var w := "activities/" + id
		v.ref(w + ".facility", "facilities", a.get("facility"))
		for key: String in ["ap_cost", "cost_stones"]:
			if a.get(key) != null and JsonUtil.get_float(a, key, -1.0) < 0.0:
				v.err(w, key + "는 0 이상의 수 또는 null")
		var panel := JsonUtil.get_str(a, "panel")
		if not panel.is_empty() and not panel in CityActions.PANELS:
			v.err(w, "panel은 %s 중 하나" % [CityActions.PANELS])
		for e: Variant in JsonUtil.get_array(a, "effects"):
			if not e is Dictionary:
				v.err(w, "effects 항목은 객체")
				continue
			var type := JsonUtil.get_str(e, "type")
			if not v.city_effect_ids.is_empty() and not type in v.city_effect_ids:
				v.err(w, "효과 type '%s' 핸들러 없음(src/city/effects/)" % type)
			elif v.city_effect_checker.is_valid():
				for problem: String in v.city_effect_checker.call(e, v.db):
					v.err(w, problem)


static func _info(v: ValidatorBase) -> void:
	for id: String in v.entries("city_info"):
		var e := v.db.get_entry("city_info", id)
		if not JsonUtil.get_str(e, "kind") in CityInfo.KINDS:
			v.err("city_info/" + id, "kind는 %s 중 하나" % [CityInfo.KINDS])
		if JsonUtil.get_str(e, "text_ko").is_empty():
			v.err("city_info/" + id, "text_ko가 비었다")
