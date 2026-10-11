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
			var rd: Dictionary = rule if rule is Dictionary else {}
			v.ref(w + ".ai", "skills", rd.get("use"))
			if not v.ai_condition_ids.is_empty() and not v.ai_condition_ids.has(JsonUtil.get_str(rd, "if")):
				v.err(w + ".ai", "조건 '%s' 없음(src/combat/ai/)" % rd.get("if"))
			if not JsonUtil.get_array(m, "skills").has(rd.get("use")):
				v.warn(w + ".ai", "스킬 '%s'이(가) skills 목록에 없다" % rd.get("use"))
		if not v.db.tag_ids("monster_shapes").has(JsonUtil.get_str(m, "shape", "humanoid")):
			v.err(w, "shape '%s' 미등록(tags.monster_shapes)" % m.get("shape"))
		v.check_color(w, JsonUtil.get_str(m, "color"))
		var wp: Variant = m.get("weak_point")
		if wp != null and not (wp is Dictionary and (wp as Dictionary).has("name_ko")):
			v.err(w, "weak_point는 null 또는 {name_ko, …}")
		var beh := JsonUtil.get_dict(m, "behavior")
		var pack := JsonUtil.get_array(beh, "pack_size")
		if pack.size() != 2 or int(pack[0]) < 1 or int(pack[0]) > int(pack[1]):
			v.err(w, "behavior.pack_size는 [최소 1 이상, 최대]")
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
		if s.has("innate") and not s["innate"] is bool:
			v.err(w, "innate는 true/false")
	for id: Variant in v.db.bal("party.innate_skills", []):
		v.ref("balance.party.innate_skills", "skills", id)
		if v.db.has_entry("skills", str(id)) and not JsonUtil.get_bool(v.db.get_entry("skills", str(id)), "innate"):
			v.err("skills/" + str(id), "기본 스킬(party.innate_skills)은 \"innate\": true여야 한다")


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
