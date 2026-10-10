extends TestCase
## GameDatabase 로드와 DataValidator(정상 데이터 통과 + 잘못된 데이터 검출).


func _fresh_db() -> GameDatabase:
	var d := GameDatabase.new()
	d.load_all("res://data")
	return d


func _has_error(v: DataValidator, needle: String) -> bool:
	for e: String in v.errors:
		if e.contains(needle):
			return true
	return false


func test_loads_without_errors() -> void:
	assert_eq(db.load_errors.size(), 0, "\n".join(db.load_errors))
	for s: String in ["balance", "render", "tags", "audio"]:
		assert_false((db.singletons.get(s, {}) as Dictionary).is_empty(), s)


func test_validator_passes_real_data() -> void:
	var v := DataValidator.new()
	v.validate(db)
	assert_eq(v.errors.size(), 0, "\n" + "\n".join(v.errors))


func test_manifest_collections_loaded() -> void:
	for col: String in ["stats", "resources", "statuses", "races", "classes", "monsters", "skills"]:
		assert_true(db.get_collection(col).size() > 0, col)


func test_templates_are_not_loaded() -> void:
	assert_false(JsonUtil.list_json("res://data/essences").has("res://data/essences/_template.json"))
	for col: String in db.collections:
		for id: String in db.get_collection(col):
			assert_false(id.begins_with("_"), "%s/%s" % [col, id])


func test_enabled_races_cover_core_stats() -> void:
	var races := db.enabled_ids("races")
	assert_true(races.has("human") and races.has("barbarian"), "1차: 인간·바바리안")
	for id in races:
		var ranges := JsonUtil.get_dict(db.get_entry("races", id), "stat_ranges")
		for core: String in ["str", "agi", "p_res", "m_res", "int"]:
			assert_true(ranges.has(core), "%s.%s" % [id, core])


func test_balance_lookup() -> void:
	assert_true(JsonUtil.is_number(db.bal("hp.base")))
	assert_eq(db.bal("no.such.path", "x"), "x")


func test_validator_catches_bad_references() -> void:
	var d := _fresh_db()
	d.put_entry("monsters", {"id": "bad_mob", "name_ko": "x", "grade": 12, "type": "ghostly",
		"stats": {"nostat": 1}, "skills": ["no_skill"], "weaknesses": {"plasma": 2.0},
		"essence_drops": [{"essence": "no_essence", "chance": 3}]})
	d.put_entry("resources", {"id": "bad_res", "name_ko": "x", "max_formula": "{nostat} + {bal.no.key}",
		"thresholds": [{"at_ratio": 0.5, "apply_status": "no_status"}]})
	d.put_entry("stats", {"id": "orphan", "name_ko": "x", "group": "body", "parent": "ghost", "coef": 1})
	d.put_entry("skills", {"id": "bad_skill", "name_ko": "x", "target": "everyone", "cost": {"gold": 1}})
	d.rebuild_index()
	var v := DataValidator.new()
	v.validate(d)
	for needle: String in ["등급은 1~9", "type 'ghostly'", "스탯 'nostat'", "skills 'no_skill'",
			"weaknesses 'plasma'", "essences 'no_essence'", "확률은 0~1", "{nostat}", "{bal.no.key}",
			"statuses 'no_status'", "parent 'ghost'", "target 'everyone'", "cost 'gold'"]:
		assert_true(_has_error(v, needle), "검출해야 함: " + needle)


func test_validator_detects_parent_cycle() -> void:
	var d := _fresh_db()
	d.put_entry("stats", {"id": "cyc_a", "name_ko": "x", "parent": "cyc_b", "coef": 1})
	d.put_entry("stats", {"id": "cyc_b", "name_ko": "x", "parent": "cyc_a", "coef": 1})
	d.rebuild_index()
	var v := DataValidator.new()
	v.validate(d)
	assert_true(_has_error(v, "parent 순환"))


func test_validator_checks_effect_types_when_registry_given() -> void:
	var v := DataValidator.new()
	v.effect_types = PackedStringArray(["damage"])
	v.validate(db)
	assert_true(_has_error(v, "effect type 'apply_status'"), "등록 안 된 효과 타입 검출")
