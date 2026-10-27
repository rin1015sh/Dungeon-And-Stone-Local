extends TestCase
## 도서관 서적(사용자 2026-10-27, CT52): 분야마다 읽기 · 한 번에 1~2개 · 거주 등급(tier)·층(floor)으로 거른다 · 고서 문체(수치 없음).


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state(tier: int = 1) -> CityState:
	var s := CityState.new(db, 11)
	s.start()
	s.residence = tier
	s.facility = "library"
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


func test_every_field_has_books_for_every_tier() -> void:
	var fields := CityInfo.field_ids(db)
	assert_true(fields.size() >= 4 and ["dungeon", "arms", "ailments", "monsters"].all(func(f: String) -> bool: return fields.has(f)), "요청한 네 분야")
	for f in fields:
		for t in range(1, 5):
			var n := 0
			for id: String in db.get_collection("city_info"):
				var e := db.get_entry("city_info", id)
				if JsonUtil.get_str(e, "field") == f and JsonUtil.get_int(e, "tier") == t:
					n += 1
			assert_true(n >= 1, "%s %d등급 책" % [f, t])
		assert_true(CityActions.activities_of(_state(), "library").has("library_" + f), "분야 읽기 " + f)


func test_reading_gives_one_or_two_within_tier() -> void:
	var s := _state(1)
	var pc := _pc()
	pc.inventory.add_money(100000)
	var reads := 0
	while CityActions.check(s, pc, "library_dungeon").is_empty():
		var before := s.known_info.size()
		CityActions.perform(s, pc, "library_dungeon", _reg())
		var got := s.known_info.size() - before
		assert_true(got >= 1 and got <= 2, "한 번에 1~2개 (%d)" % got)
		reads += 1
		assert_true(reads < 20)
	for id in s.known_info:
		var e := db.get_entry("city_info", id)
		assert_eq([JsonUtil.get_str(e, "field"), JsonUtil.get_int(e, "tier")], ["dungeon", 1], "뒷골목 = 그 분야 1등급 책만")
	assert_true(reads >= 2, "한 번에 분야 전부를 주지 않는다")
	assert_eq(CityActions.check(s, pc, "library_dungeon"), "city.reason_books_locked", "더 좋은 거리 도서관에 남았다")
	s.residence = 4
	assert_eq(CityActions.check(s, pc, "library_dungeon"), "", "이사하면 더 읽는다")
	for id in CityInfo.readable(s, "dungeon"):
		s.learn_info(id)
	assert_eq(CityActions.check(s, pc, "library_dungeon"), "city.reason_no_books", "다 읽었다")


func test_floor_gate_and_rare_books() -> void:
	var col := db.get_collection("city_info")
	col["t_deep"] = {"id": "t_deep", "field": "dungeon", "tier": 1, "floor": 3, "name_ko": "시험", "text_ko": "시험"}
	var s := _state(1)
	assert_false(CityInfo.readable(s, "dungeon").has("t_deep"), "1층까지만 간 자는 셋째 층 책을 못 읽는다")
	s.reach_floor(2)
	assert_true(CityInfo.readable(s, "dungeon").has("t_deep"), "가 본 층 + 1까지")
	col.erase("t_deep")
	var rare := CityInfo.readable(_state(1), CityInfo.ANY, 1)
	assert_true(rare.any(func(id: String) -> bool: return JsonUtil.get_int(db.get_entry("city_info", id), "tier") == 2), "희귀서 = 한 등급 위까지")


func test_books_have_no_numbers() -> void:
	var digit := RegEx.create_from_string("[0-9%]")
	for id: String in db.get_collection("city_info"):
		var e := db.get_entry("city_info", id)
		assert_true(digit.search(JsonUtil.get_str(e, "text_ko")) == null, "수치 없이(상중하로): " + id)
		assert_true(RegEx.create_from_string("습니다|세요|십시오|해요").search(JsonUtil.get_str(e, "text_ko")) == null, "존댓말 없이: " + id)


## 서적 그림(사용자 2026-10-27, CT57): 분야마다 펼친 책 그림이 있고, 읽은 결과 문구가 그 분야를 알려 준다(FacilityView가 그림을 고른다).
func test_every_field_has_book_art_and_read_names_field() -> void:
	for f in CityInfo.field_ids(db):
		var art := CityInfo.field_art(db, f)
		assert_true(not art.is_empty() and FileAccess.file_exists(art), "책 그림 " + f)
	var s := _state(1)
	var pc := _pc()
	pc.inventory.add_money(1000)
	var ctx := CityActions.perform(s, pc, "library_arms", _reg())
	var fields: Array = []
	for m: Dictionary in ctx.messages:
		if str(m["key"]) == "city.fx.book_new":
			fields.append(JsonUtil.get_str(m["args"], "field"))
	assert_true(not fields.is_empty() and fields.all(func(f: Variant) -> bool: return str(f) == "arms"), "읽은 책의 분야 (%s)" % [fields])


## 이사해도 예전 거리에서 다 못 읽은 낮은 등급 책은 계속 읽는다(사용자 2026-10-27 확인 요청).
func test_lower_tier_books_stay_readable_after_moving_up() -> void:
	var s := _state(1)
	var low: Array[String] = CityInfo.readable(s, "dungeon")
	assert_true(low.size() >= 2)
	s.learn_info(low[0])  # 13구역에서 하나만 읽고 이사
	s.residence = 2
	var now := CityInfo.readable(s, "dungeon")
	for id in low.slice(1):
		assert_true(now.has(id), "못 읽은 1등급 책이 남는다: " + id)
	assert_false(now.has(low[0]), "읽은 책은 다시 나오지 않는다")
	var tier2 := now.filter(func(id: String) -> bool: return JsonUtil.get_int(db.get_entry("city_info", id), "tier") == 2)
	assert_false(tier2.is_empty(), "2등급 책도 같이")
	var pc := _pc()
	pc.inventory.add_money(100000)
	while CityActions.check(s, pc, "library_dungeon").is_empty():
		CityActions.perform(s, pc, "library_dungeon", _reg())
	for id in low:
		assert_true(s.known_info.has(id), "읽다 보면 낮은 등급 책도 다 읽는다: " + id)
