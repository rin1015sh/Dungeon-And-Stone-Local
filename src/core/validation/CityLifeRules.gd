class_name CityLifeRules
extends RefCounted
## 검사 규칙: 도시 생활(2026-10-20) — 세금(city.json tax) · 조사 의뢰(city.json guild — CityGuild, CT44) · 활동은 모두 자기 시설 목록에.
## 도시 사건(오늘의 거리 · 거리 사건)은 없앴다(사용자 결정 2026-11-08, CT114) — 사건 전용(extra) 활동도 없다.


static func run(v: ValidatorBase) -> void:
	var city: Dictionary = v.db.singletons.get("city", {})
	_listed(v)
	_tax(v, JsonUtil.get_dict(city, "tax"))
	for id: Variant in JsonUtil.get_array(JsonUtil.get_dict(city, "guild"), "survey_pool"):
		v.ref("city.guild.survey_pool", "monsters", id)
	TownRules.run(v)
	CityInteriorRules.run(v)


## 활동은 자기 시설 activities 목록에 있어야 고를 수 있다.
static func _listed(v: ValidatorBase) -> void:
	for id: String in v.entries("activities"):
		var a := v.db.get_entry("activities", id)
		if a.has("extra"):
			v.err("activities/" + id, "extra(사건 전용)는 없앴다 — 시설 activities 목록에 넣는다(CT114)")
		if not JsonUtil.get_array(v.db.get_entry("facilities", JsonUtil.get_str(a, "facility")), "activities").has(id):
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
