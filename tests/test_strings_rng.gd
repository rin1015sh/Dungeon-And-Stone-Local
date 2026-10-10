extends TestCase
## Strings(문자열 로더), Rng(시드 고정 난수), CharacterRoller(스탯 굴림).

## Strings.t("키")와, 키를 넘기는 say/_say/_log("키") 호출을 모두 찾는다.
const KEY_PATTERN := "(?:Strings\\.t|\\bsay|_say|_log)\\(\\s*\"([a-z_]+\\.[a-z_.]*)\""


func test_strings_lookup_and_format() -> void:
	assert_eq(Strings.load_locale("ko").size(), 0)
	assert_eq(Strings.t("app.title"), "던전 앤 스톤")
	assert_true(Strings.t("log.damage", {"amount": 7}).contains("7"))
	assert_false(Strings.has("_comment"), "'_' 키는 건너뛴다")


func test_every_code_string_key_exists() -> void:
	var re := RegEx.create_from_string(KEY_PATTERN)
	var missing := PackedStringArray()
	var scanned := 0
	for path in _gd_files("res://src"):
		scanned += 1
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
			var key := m.get_string(1)
			# "collection." + col 처럼 동적으로 잇는 접두어는 그 아래 키가 하나라도 있으면 된다.
			var ok := _has_prefix(key) if key.ends_with(".") else Strings.has(key)
			if not ok:
				missing.append("%s: %s" % [path.get_file(), key])
	assert_true(scanned > 0, "src 스캔")
	assert_eq(missing.size(), 0, "ko.json에 없는 키: " + ", ".join(missing))


func test_every_collection_has_display_name() -> void:
	for col: String in db.collections:
		assert_true(Strings.has("collection." + col), "collection.%s" % col)


func test_rng_is_deterministic() -> void:
	var a := Rng.new(12345)
	var b := Rng.new(12345)
	for i in 20:
		assert_eq(a.randi_range(0, 1000), b.randi_range(0, 1000))
	var c := Rng.new(12345)
	c.randf()
	var state := c.get_state_string()
	var next := c.randf()
	c.set_state_string(state)
	assert_near(c.randf(), next, 0.0, "상태 저장/복원")


func test_rng_helpers() -> void:
	var r := Rng.new(7)
	for i in 50:
		assert_false(r.chance(0.0))
		assert_true(r.chance(1.0))
		assert_eq(r.weighted_index([0, 0, 5, 0]), 2)
	assert_eq(r.weighted_index([0, 0]), -1)
	assert_true(Rng.new().seed_value != 0, "무작위 시드도 값이 보인다")


func test_roller_within_bounds_and_deterministic() -> void:
	for race in db.enabled_ids("races"):
		for cls in db.enabled_ids("classes"):
			var bounds := CharacterRoller.stat_bounds(db, race, cls)
			var rolled := CharacterRoller.roll_base_stats(db, race, cls, Rng.new(99))
			var again := CharacterRoller.roll_base_stats(db, race, cls, Rng.new(99))
			assert_eq(rolled, again, "같은 시드 같은 결과 %s/%s" % [race, cls])
			for id: String in bounds:
				var v := float(rolled.get(id, -1.0))
				assert_true(v >= bounds[id][0] and v <= bounds[id][1], "%s/%s %s=%s" % [race, cls, id, v])


func _has_prefix(prefix: String) -> bool:
	for k in Strings.keys():
		if k.begins_with(prefix):
			return true
	return false


func _gd_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(sub)))
	return out
