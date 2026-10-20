class_name CityLifeRules
extends RefCounted
## 검사 규칙: 도시 생활(2026-10-20) — 오늘의 거리(city_events), 인연(city_people), 명성(city.json renown), 세금(city.json tax),
## 사건·인연으로만 열리는 활동(activities "extra": true — 시설 목록에 넣지 않고, 어딘가에서 열어야 한다).

const WHEN_KEYS := ["from_month", "periods", "weather", "min_renown", "bonds"]
const PERK_KEYS := ["discount", "unlock", "shop_discount"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	var opened := {}  # 사건·인연이 여는 활동
	_events(v, city, opened)
	_people(v, opened)
	_extras(v, opened)
	_renown(v, JsonUtil.get_dict(city, "renown"))
	_tax(v, JsonUtil.get_dict(city, "tax"))


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
		for who: Variant in JsonUtil.get_dict(when, "bonds"):
			v.ref(w + ".when.bonds", "city_people", who)


static func _people(v: ValidatorBase, opened: Dictionary) -> void:
	var seen := {}
	for id: String in v.entries("city_people"):
		var p := v.db.get_entry("city_people", id)
		var w := "city_people/" + id
		var fac := JsonUtil.get_str(p, "facility")
		v.ref(w + ".facility", "facilities", fac)
		if seen.has(fac):
			v.err(w, "시설 '%s'에 사람이 둘이다(%s)" % [fac, seen[fac]])
		seen[fac] = id
		for a: Variant in JsonUtil.get_dict(p, "gain"):
			v.ref(w + ".gain", "activities", a)
		var last := -1.0
		for st: Variant in JsonUtil.get_array(p, "stages"):
			var d := st as Dictionary
			if d == null:
				v.err(w, "stages 항목은 객체")
				continue
			var at := JsonUtil.get_float(d, "at", -1.0)
			if at <= last:
				v.err(w, "stages.at는 차례로 커져야 한다")
			last = at
			_part(v, w, d, fac, opened)
			var check := JsonUtil.get_dict(d, "check")
			if not check.is_empty():
				if not v.db.stats.has(JsonUtil.get_str(check, "stat")):
					v.err(w, "check.stat '%s' 없음" % check.get("stat"))
				for side: String in ["pass", "fail"]:
					_part(v, w + ".check." + side, JsonUtil.get_dict(check, side), fac, opened)


## 장면 한 토막: scene 문자열 키(또는 key.1 …), effects, perks.
static func _part(v: ValidatorBase, w: String, d: Dictionary, fac: String, opened: Dictionary) -> void:
	var scene := JsonUtil.get_str(d, "scene")
	if not scene.is_empty() and not Strings.has(scene) and not Strings.has(scene + ".1"):
		v.err(w, "장면 문자열 '%s' 없음(data/strings)" % scene)
	for e: Variant in JsonUtil.get_array(d, "effects"):
		if not e is Dictionary or not JsonUtil.get_str(e, "type") in v.city_effect_ids and not v.city_effect_ids.is_empty():
			v.err(w, "효과 type 핸들러 없음: %s" % [e])
		elif v.city_effect_checker.is_valid():
			for problem: String in v.city_effect_checker.call(e, v.db):
				v.err(w, problem)
	var perks := JsonUtil.get_dict(d, "perks")
	for k: Variant in perks:
		if not str(k) in PERK_KEYS:
			v.err(w, "perks 키는 %s 중에서: '%s'" % [PERK_KEYS, k])
	for a: Variant in JsonUtil.get_dict(perks, "discount"):
		v.ref(w + ".perks.discount", "activities", a)
	for a: Variant in JsonUtil.get_array(perks, "unlock"):
		_extra_ref(v, w + ".perks.unlock", str(a), fac)
		opened[str(a)] = true


## 사건·인연이 여는 활동: 있고, 그 시설 것이고, extra여야 한다.
static func _extra_ref(v: ValidatorBase, w: String, act_id: String, fac: String) -> void:
	if not v.db.has_entry("activities", act_id):
		v.err(w, "활동 '%s' 없음" % act_id)
		return
	var a := v.db.get_entry("activities", act_id)
	if JsonUtil.get_str(a, "facility") != fac:
		v.err(w, "활동 '%s'의 facility가 '%s'가 아니다" % [act_id, fac])
	if not JsonUtil.get_bool(a, "extra"):
		v.err(w, "활동 '%s'는 extra(사건·인연 전용)가 아니다" % act_id)


## extra 활동은 시설 목록에 없고, 어딘가에서 연다. 그 밖의 활동은 자기 시설 목록에 있다.
static func _extras(v: ValidatorBase, opened: Dictionary) -> void:
	for id: String in v.entries("activities"):
		var a := v.db.get_entry("activities", id)
		var listed := JsonUtil.get_array(v.db.get_entry("facilities", JsonUtil.get_str(a, "facility")), "activities").has(id)
		if JsonUtil.get_bool(a, "extra"):
			if listed:
				v.err("activities/" + id, "extra 활동은 시설 activities 목록에 넣지 않는다")
			elif not opened.has(id):
				v.warn("activities/" + id, "여는 사건·인연이 없다")
			var stock: Variant = a.get("stock")
			if stock is Array:
				for item: Variant in stock:
					v.ref("activities/" + id + ".stock", "items", item)
		elif not listed:
			v.warn("activities/" + id, "시설 activities 목록에 없다(고를 수 없다)")


static func _renown(v: ValidatorBase, r: Dictionary) -> void:
	var ids := {}
	for d: Variant in JsonUtil.get_array(r, "deeds"):
		var deed := d as Dictionary
		if deed == null:
			v.err("city.renown", "deeds 항목은 객체")
			continue
		var id := JsonUtil.get_str(deed, "id")
		if id.is_empty() or ids.has(id):
			v.err("city.renown", "deeds id가 비었거나 겹친다: '%s'" % id)
		ids[id] = true
		if JsonUtil.get_str(deed, "notice").is_empty() and not JsonUtil.get_bool(deed, "kill"):
			v.err("city.renown", "deed '%s'는 notice(알림 키) 또는 kill" % id)
		elif not JsonUtil.get_str(deed, "notice").is_empty() and not Strings.has(JsonUtil.get_str(deed, "notice")):
			v.err("city.renown", "deed '%s'의 알림 키 '%s'가 문자열에 없다" % [id, deed.get("notice")])
	var last := -1
	for s: Variant in JsonUtil.get_array(r, "stages"):
		if s != null and int(s) <= last:
			v.err("city.renown", "stages는 차례로 커져야 한다")
		last = int(s) if s != null else last


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
