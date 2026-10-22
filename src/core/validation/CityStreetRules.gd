class_name CityStreetRules
extends RefCounted
## 검사 규칙: 거리 사건(data/street_events — CityAmbient, CT42) · city.json ambient · city.json guild(조사 의뢰 — CityGuild, CT44).

const WHEN_KEYS := ["from_month", "months_of_year", "periods", "weather", "tax_month", "tax_owed"]
const BRANCH_KEYS := ["cost_stones", "effects", "check", "success", "fail"]


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	for id: Variant in JsonUtil.get_array(JsonUtil.get_dict(city, "guild"), "survey_pool"):
		v.ref("city.guild.survey_pool", "monsters", id)
	var chance: Variant = JsonUtil.get_dict(city, "ambient").get("chance")
	if chance != null and (float(chance) < 0.0 or float(chance) > 1.0):
		v.err("city.ambient", "chance는 0~1")
	var periods: Array = JsonUtil.get_array(JsonUtil.get_dict(city, "calendar"), "periods").map(func(p: Variant) -> String: return JsonUtil.get_str(p as Dictionary, "id"))
	var weather: Array = JsonUtil.get_array(JsonUtil.get_dict(city, "weather"), "kinds").map(func(k: Variant) -> String: return JsonUtil.get_str(k as Dictionary, "id"))
	for id: String in v.entries(CityAmbient.COL):
		var e := v.db.get_entry(CityAmbient.COL, id)
		var w := CityAmbient.COL + "/" + id
		var art := JsonUtil.get_str(e, "art")
		if not art.is_empty() and not FileAccess.file_exists(art):
			v.err(w, "일러스트 '%s'이(가) 없다(tools/paint_city.gd -- --only=events)" % art)
		var when := JsonUtil.get_dict(e, "when")
		for k: Variant in when:
			if not str(k) in WHEN_KEYS:
				v.err(w, "when 키는 %s 중에서: '%s'" % [WHEN_KEYS, k])
		for p: Variant in JsonUtil.get_array(when, "periods"):
			if not str(p) in periods:
				v.err(w, "when.periods '%s'이(가) 달력에 없다" % p)
		for x: Variant in JsonUtil.get_array(when, "weather") + JsonUtil.get_dict(e, "weather_weight").keys():
			if not str(x) in weather:
				v.err(w, "날씨 '%s'이(가) 없다" % x)
		for m: Variant in JsonUtil.get_array(when, "months_of_year"):
			if int(m) < 1 or int(m) > 12:
				v.err(w, "months_of_year는 1~12")
		var choices := JsonUtil.get_array(e, "choices")
		if choices.is_empty():
			_branch(v, w, e)
		else:
			for k: String in BRANCH_KEYS:
				if e.has(k):
					v.err(w, "선택지가 있으면 '%s'는 선택지 안에" % k)
			var seen := {}
			for c: Variant in choices:
				if not c is Dictionary or JsonUtil.get_str(c, "id").is_empty():
					v.err(w, "choices 항목은 id가 있는 객체")
					continue
				if seen.has(JsonUtil.get_str(c, "id")):
					v.err(w, "선택지 id '%s' 겹침" % JsonUtil.get_str(c, "id"))
				seen[JsonUtil.get_str(c, "id")] = true
				_branch(v, w + "." + JsonUtil.get_str(c, "id"), c)


## 갈래 하나: 효과 type·형식, 판정 스탯, 판정이 없으면 success·fail을 두지 않는다.
static func _branch(v: ValidatorBase, w: String, b: Dictionary) -> void:
	if b.get("cost_stones") != null and JsonUtil.get_float(b, "cost_stones", -1.0) < 0.0:
		v.err(w, "cost_stones는 0 이상")
	var chk := JsonUtil.get_dict(b, "check")
	for s: Variant in JsonUtil.get_array(chk, "stats"):
		if not v.db.stats.has(str(s)):
			v.err(w, "check 스탯 '%s' 없음" % s)
	if chk.is_empty() and (b.has("success") or b.has("fail")):
		v.err(w, "success·fail은 check가 있을 때만")
	for key: String in ["effects", "success", "fail"]:
		for e: Variant in JsonUtil.get_array(b, key):
			if not e is Dictionary:
				v.err(w, key + " 항목은 객체")
				continue
			var type := JsonUtil.get_str(e, "type")
			if not v.city_effect_ids.is_empty() and not type in v.city_effect_ids:
				v.err(w, "효과 type '%s' 핸들러 없음(src/city/effects/)" % type)
			elif v.city_effect_checker.is_valid():
				for problem: String in v.city_effect_checker.call(e, v.db):
					v.err(w, problem)
