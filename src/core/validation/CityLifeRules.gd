class_name CityLifeRules
extends RefCounted
## 검사 규칙: 도시 생활(2026-10-20) — 오늘의 거리(city_events), 세금(city.json tax),
## 사건으로만 열리는 활동(activities "extra": true — 시설 목록에 넣지 않고, 사건이 연다).

const WHEN_KEYS := ["from_month", "periods", "weather"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	var opened := {}  # 사건이 여는 활동
	_events(v, city, opened)
	_extras(v, opened)
	_tax(v, JsonUtil.get_dict(city, "tax"))
	CityStreetRules.run(v)
	TownRules.run(v)


static func _events(v: ValidatorBase, city: Dictionary, opened: Dictionary) -> void:
	var periods: Array = JsonUtil.get_array(JsonUtil.get_dict(city, "calendar"), "periods").map(func(p: Variant) -> String: return JsonUtil.get_str(p as Dictionary, "id"))
	var weather: Array = JsonUtil.get_array(JsonUtil.get_dict(city, "weather"), "kinds").map(func(k: Variant) -> String: return JsonUtil.get_str(k as Dictionary, "id"))
	for id: String in v.entries("city_events"):
		var e := v.db.get_entry("city_events", id)
		var w := "city_events/" + id
		var fac := JsonUtil.get_str(e, "facility")
		v.ref(w + ".facility", "facilities", fac)
		var acts := JsonUtil.get_array(e, "activities")
		if acts.is_empty():
			v.err(w, "activities가 비었다")
		for a: Variant in acts:
			_extra_ref(v, w, str(a), fac)
			opened[str(a)] = true
		var when := JsonUtil.get_dict(e, "when")
		for k: Variant in when:
			if not str(k) in WHEN_KEYS:
				v.err(w, "when 키는 %s 중에서: '%s'" % [WHEN_KEYS, k])
		for p: Variant in JsonUtil.get_array(when, "periods"):
			if not str(p) in periods:
				v.err(w, "when.periods '%s'이(가) 달력에 없다" % p)
		for x: Variant in JsonUtil.get_array(when, "weather"):
			if not str(x) in weather:
				v.err(w, "when.weather '%s'이(가) 날씨에 없다" % x)


## 사건이 여는 활동: 있고, 그 시설 것이고, extra(사건 전용)여야 한다.
static func _extra_ref(v: ValidatorBase, w: String, act_id: String, fac: String) -> void:
	if not v.db.has_entry("activities", act_id):
		v.err(w, "활동 '%s' 없음" % act_id)
		return
	var a := v.db.get_entry("activities", act_id)
	if JsonUtil.get_str(a, "facility") != fac:
		v.err(w, "활동 '%s'의 facility가 '%s'가 아니다" % [act_id, fac])
	if not JsonUtil.get_bool(a, "extra"):
		v.err(w, "활동 '%s'는 extra(사건 전용)가 아니다" % act_id)


## extra 활동은 시설 목록에 없고, 사건이 연다. 그 밖의 활동은 자기 시설 목록에 있다.
static func _extras(v: ValidatorBase, opened: Dictionary) -> void:
	for id: String in v.entries("activities"):
		var a := v.db.get_entry("activities", id)
		var listed := JsonUtil.get_array(v.db.get_entry("facilities", JsonUtil.get_str(a, "facility")), "activities").has(id)
		if JsonUtil.get_bool(a, "extra"):
			if listed:
				v.err("activities/" + id, "extra 활동은 시설 activities 목록에 넣지 않는다")
			elif not opened.has(id):
				v.warn("activities/" + id, "여는 사건이 없다")
			var stock: Variant = a.get("stock")
			if stock is Array:
				for item: Variant in stock:
					v.ref("activities/" + id + ".stock", "items", item)
		elif not listed:
			v.warn("activities/" + id, "시설 activities 목록에 없다(고를 수 없다)")


static func _tax(v: ValidatorBase, t: Dictionary) -> void:
	for y: Variant in JsonUtil.get_array(t, "by_year"):
		if y != null and not (y is float or y is int):
			v.err("city.tax", "by_year는 수 배열")
	for r: Variant in JsonUtil.get_dict(t, "race_rate"):
		v.ref("city.tax.race_rate", "races", r)
	for r: Variant in JsonUtil.get_dict(t, "relief"):
		v.ref("city.tax.relief", "races", r)
	for r: Variant in JsonUtil.get_array(t, "exempt"):
		v.ref("city.tax.exempt", "races", r)
	var due: Variant = t.get("due_month")
	if due != null and (int(due) < 1 or int(due) > 12):
		v.err("city.tax", "due_month는 1~12")
