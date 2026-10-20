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
	_street(v, JsonUtil.get_dict(city, "street"))
	_facilities(v, city)
	_activities(v)
	_info(v)
	CityLifeRules.run(v)
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
	var tiers: Variant = fat.get("effects")
	if tiers is Array:
		for t: Variant in tiers:
			if not t is Dictionary or not (t as Dictionary).has("at_least") or not JsonUtil.get_array(t, "modifiers") is Array:
				v.err("city.fatigue.effects", "단계는 {at_least, name_ko, modifiers[]}")
				continue
			for m: Variant in JsonUtil.get_array(t, "modifiers"):
				if not m is Dictionary or not v.db.stats.has(JsonUtil.get_str(m, "target")):
					v.err("city.fatigue.effects", "수정자 target은 스탯 id: %s" % [m])
	elif tiers != null:
		v.err("city.fatigue", "effects는 단계 배열 또는 null")
	var cal := JsonUtil.get_dict(city, "calendar")
	for pair: Array in [["portal_rule", ["after_late_period"]], ["return_date_rule", ["next_month_early"]]]:
		var rv: Variant = cal.get(pair[0])
		if rv != null and not str(rv) in pair[1]:
			v.err("city.calendar", "%s는 %s 또는 null" % [pair[0], pair[1]])
	var enter: Variant = JsonUtil.get_dict(city, "bank").get("on_dungeon_enter")
	if enter != null and str(enter) != "keep":
		v.err("city.bank", "on_dungeon_enter는 keep 또는 null")
	var stock: Variant = JsonUtil.get_dict(city, "shop").get("stock")
	if stock is Array:
		for id: Variant in stock:
			v.ref("city.shop.stock", "items", id)
	elif stock != null:
		v.err("city.shop", "stock은 아이템 id 배열 또는 null")


## 거리 레이어: id·경로(res://)·시차 0~1·배율 > 0, 거리 길이 > 0. 그림 파일이 없어도 게임은 돈다(경로만 검사).
static func _street(v: ValidatorBase, street: Dictionary) -> void:
	if JsonUtil.get_float(street, "width", 0.0) <= 0.0:
		v.err("city.street", "width(거리 길이)는 0보다 커야 한다")
	var ids := {}
	for layer: Variant in JsonUtil.get_array(street, "layers"):
		var d := layer as Dictionary
		if d == null:
			v.err("city.street.layers", "레이어는 객체여야 한다")
			continue
		var id := JsonUtil.get_str(d, "id")
		if id.is_empty() or ids.has(id):
			v.err("city.street.layers", "레이어 id가 비었거나 겹친다: '%s'" % id)
		ids[id] = true
		if not JsonUtil.get_str(d, "path").begins_with(IMAGE_PREFIX):
			v.err("city.street.layers." + id, "path는 res:// 경로여야 한다")
		var par := JsonUtil.get_float(d, "parallax", 1.0)
		if par < 0.0 or par > 1.0:
			v.err("city.street.layers." + id, "parallax는 0~1")
		if JsonUtil.get_float(d, "scale", 1.0) <= 0.0 or JsonUtil.get_float(d, "height", 720.0) <= 0.0:
			v.err("city.street.layers." + id, "scale·height는 0보다 커야 한다")


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
		if acts.is_empty() and not JsonUtil.get_bool(f, "placeholder"):
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
		if a.has("ap_cost"):
			v.err(w, "ap_cost는 쓰지 않는다 — 시설 안 활동은 행동력을 쓰지 않는다(입장 비용은 city.json facility_entry_cost)")
		for key: String in ["cost_stones"]:
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
