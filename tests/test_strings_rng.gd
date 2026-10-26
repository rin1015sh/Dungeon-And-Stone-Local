extends TestCase
## Strings(문자열 로더), Rng(시드 고정 난수), CharacterRoller(스탯 굴림).

## Strings.t("키")와, 키를 넘기는 say/_say/_log/say_later("키") · 시그널 emit("키") 호출을 모두 찾는다
## (전투·탐험 메시지는 message.emit("combat.…")로 나간다 — 빠진 키가 화면에 [키]로 보이지 않게).
const KEY_PATTERN := "(?:Strings\\.t|\\bsay|_say|_log|say_later|\\bemit)\\(\\s*\"([a-z_]+\\.[a-z_.]*)\""


func test_strings_lookup_and_format() -> void:
	assert_eq(Strings.load_locale("ko").size(), 0)
	assert_eq(Strings.t("app.title"), "던전 앤 스톤")
	assert_true(Strings.t("log.damage", {"amount": 7}).contains("7"))
	assert_false(Strings.has("_comment"), "'_' 키는 건너뛴다")


## 스톤 금액은 만의 자리부터 만·억 단위로 끊는다(사용자 요청 2026-10-26).
func test_stone_amounts_use_korean_units() -> void:
	assert_eq(Strings.stones(300), "300")
	assert_eq(Strings.stones(3500), "3500")
	assert_eq(Strings.stones(10000), "1만")
	assert_eq(Strings.stones(15000), "1만 5000")
	assert_eq(Strings.stones(55002000), "5500만 2000")
	assert_eq(Strings.stones(150000000), "1억 5000만")
	assert_eq(Strings.stones(100000005), "1억 5")
	assert_eq(Strings.stones(-15000), "-1만 5000")
	# 문구에서 "스톤" 바로 앞의 수만 바뀐다(개수 {n}개는 그대로).
	assert_eq(Strings.t("city.hud_money", {"money": 150000000}), "소지금 1억 5000만 스톤")
	assert_eq(Strings.t("city.shop_bought", {"item": "횃불", "n": 12000, "price": 15000.0}), "횃불 12000개를 1만 5000 스톤에 샀다.")


func test_every_code_string_key_exists() -> void:
	var re := RegEx.create_from_string(KEY_PATTERN)
	var missing := PackedStringArray()
	var scanned := 0
	for path in _gd_files("res://src"):
		scanned += 1
		for m: RegExMatch in re.search_all(FileAccess.get_file_as_string(path)):
			var key := m.get_string(1)
			# "collection." + col, "combat.end_" + r 처럼 동적으로 잇는 접두어는 그 아래 키가 하나라도 있으면 된다.
			var ok := _has_prefix(key) if key.ends_with(".") or key.ends_with("_") else Strings.has(key)
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
