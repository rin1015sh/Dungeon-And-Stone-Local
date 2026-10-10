class_name ContentRules
extends RefCounted
## 검사 규칙: 몬스터·스킬·정수·아이템.


static func run(v: ValidatorBase) -> void:
	_monsters(v)
	_skills(v)
	_essences(v)
	_items(v)


static func _monsters(v: ValidatorBase) -> void:
	var types := v.db.tag_ids("monster_types")
	var families := v.db.tag_ids("families")
	var damage := v.damage_ids()
	for id: String in v.entries("monsters"):
		var m := v.db.get_entry("monsters", id)
		var w := "monsters/" + id
		v.check_grade(w, m.get("grade"))
		v.check_grade(w + ".magic_stone_grade", m.get("magic_stone_grade", m.get("grade")))
		if not types.has(JsonUtil.get_str(m, "type")):
			v.err(w, "type '%s' 미등록(tags.monster_types)" % m.get("type"))
		for f: Variant in JsonUtil.get_array(m, "family"):
			if not families.has(str(f)):
				v.err(w, "family '%s' 미등록" % f)
		for im: Variant in JsonUtil.get_array(m, "immunities"):
			if not damage.has(str(im)):
				v.err(w, "immunities '%s' 미등록 피해 유형" % im)
		var weak := JsonUtil.get_dict(m, "weaknesses")
		for k: String in weak:
			if not damage.has(k):
				v.err(w, "weaknesses '%s' 미등록 피해 유형" % k)
			if not JsonUtil.is_number(weak[k]) or float(weak[k]) <= 0.0:
				v.err(w, "weaknesses 배율은 양수")
		v.check_stat_map(w, JsonUtil.get_dict(m, "stats"))
		var res := JsonUtil.get_dict(m, "resources")
		for r: String in res:
			if not v.db.resources.has(r):
				v.err(w, "resources '%s' 없는 자원" % r)
			v.check_formula(w + ".resources", res[r])
		for s: Variant in JsonUtil.get_array(m, "skills"):
			v.ref(w, "skills", s)
		for rule: Variant in JsonUtil.get_array(m, "ai"):
			if rule is Dictionary and (rule as Dictionary).has("use"):
				v.ref(w + ".ai", "skills", rule["use"])
		for drop: Variant in JsonUtil.get_array(m, "essence_drops"):
			var dd: Dictionary = drop if drop is Dictionary else {}
			v.ref(w, "essences", dd.get("essence"))
			v.check_chance(w, dd.get("chance"))


static func _skills(v: ValidatorBase) -> void:
	var targets := v.db.tag_ids("skill_targets")
	for id: String in v.entries("skills"):
		var s := v.db.get_entry("skills", id)
		var w := "skills/" + id
		if not targets.has(JsonUtil.get_str(s, "target")):
			v.err(w, "target '%s' 미등록(tags.skill_targets)" % s.get("target"))
		var cost := JsonUtil.get_dict(s, "cost")
		for r: String in cost:
			if not v.db.resources.has(r):
				v.err(w, "cost '%s' 없는 자원" % r)
			elif not JsonUtil.is_number(cost[r]) or float(cost[r]) < 0.0:
				v.err(w, "cost 값은 0 이상의 숫자")
		v.check_effects(w, JsonUtil.get_array(s, "effects"), v.check_skill_effects)


static func _essences(v: ValidatorBase) -> void:
	for id: String in v.entries("essences"):
		var e := v.db.get_entry("essences", id)
		var w := "essences/" + id
		v.check_grade(w, e.get("grade"))
		v.check_ranges(w, JsonUtil.get_dict(e, "stat_ranges"))
		if e.has("source_monster"):
			v.ref(w, "monsters", e["source_monster"])
		for r: String in JsonUtil.get_dict(e, "resource_mods"):
			if not v.db.resources.has(r):
				v.err(w, "resource_mods '%s' 없는 자원" % r)
		for sk: Variant in JsonUtil.get_array(e, "skills"):
			v.ref(w, "skills", (sk as Dictionary).get("id") if sk is Dictionary else sk)


static func _items(v: ValidatorBase) -> void:
	var categories := v.db.tag_ids("item_categories")
	for id: String in v.entries("items"):
		var it := v.db.get_entry("items", id)
		var w := "items/" + id
		if not categories.has(JsonUtil.get_str(it, "category")):
			v.err(w, "category '%s' 미등록(tags.item_categories)" % it.get("category"))
		if JsonUtil.get_float(it, "price", -1.0) < 0.0:
			v.err(w, "price는 0 이상의 숫자")
		if JsonUtil.get_int(it, "stack", 1) < 1:
			v.err(w, "stack은 1 이상")
		v.check_effects(w + ".use_effects", JsonUtil.get_array(it, "use_effects"), true)
