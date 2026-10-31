extends TestCase
## 도서관 서적(사용자 2026-10-27, CT52): 분야마다 읽기 · 한 번에 1~2개 · 층(floor)으로 거른다(거주 등급 tier는 없앴다 — CT63) · 고서 문체(수치 없음).


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state() -> CityState:
	var s := CityState.new(db, 11)
	s.start()
	s.facility = "library"
	return s


func _reg() -> ScriptRegistry:
	return ContentRegistries.new().city_effects


func test_every_field_has_books() -> void:
	var fields := CityInfo.field_ids(db)
	assert_true(fields.size() >= 4 and ["dungeon", "arms", "ailments", "monsters"].all(func(f: String) -> bool: return fields.has(f)), "요청한 네 분야")
	for f in fields:
		assert_true(CityInfo.readable(_state(), f).size() >= 4, "%s 분야 책이 여럿" % f)
		assert_true(CityActions.activities_of(_state(), "library").has("library_" + f), "분야 읽기 " + f)


func test_reading_gives_one_or_two_until_done() -> void:
	var s := _state()
	var pc := _pc()
	pc.inventory.add_money(100000)
	var reads := 0
	while CityActions.check(s, pc, "library_dungeon").is_empty():
		var before := s.known_info.size()
		s.visit_done.clear()  # 다시 들어온 셈(한 방문에 분야마다 한 번 — CT72)
		CityActions.perform(s, pc, "library_dungeon", _reg())
		var got := s.known_info.size() - before
		assert_true(got >= 1 and got <= 2, "한 번에 1~2개 (%d)" % got)
		reads += 1
		assert_true(reads < 20)
		if CityActions.check(s, pc, "library_dungeon") == "city.reason_read_this_visit":
			s.visit_done.clear()
	for id in s.known_info:
		assert_eq(JsonUtil.get_str(db.get_entry("city_info", id), "field"), "dungeon", "그 분야 책만")
	assert_true(reads >= 2, "한 번에 분야 전부를 주지 않는다")
	assert_eq(CityActions.check(s, pc, "library_dungeon"), "city.reason_no_books", "다 읽었다")


func test_floor_gate_and_rare_books() -> void:
	var col := db.get_collection("city_info")
	col["t_deep"] = {"id": "t_deep", "field": "dungeon", "tier": 1, "floor": 3, "name_ko": "시험", "text_ko": "시험"}
	var s := _state()
	assert_false(CityInfo.readable(s, "dungeon").has("t_deep"), "1층까지만 간 자는 셋째 층 책을 못 읽는다")
	s.reach_floor(2)
	assert_true(CityInfo.readable(s, "dungeon").has("t_deep"), "가 본 층 + 1까지")
	col.erase("t_deep")
	var rare := CityInfo.readable(_state(), CityInfo.ANY)
	assert_true(rare.size() > CityInfo.readable(_state(), "dungeon").size(), "희귀서 = 아무 분야에서")


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
	var s := _state()
	var pc := _pc()
	pc.inventory.add_money(1000)
	var ctx := CityActions.perform(s, pc, "library_arms", _reg())
	var fields: Array = []
	for m: Dictionary in ctx.messages:
		if str(m["key"]) == "city.fx.book_new":
			fields.append(JsonUtil.get_str(m["args"], "field"))
	assert_true(not fields.is_empty() and fields.all(func(f: Variant) -> bool: return str(f) == "arms"), "읽은 책의 분야 (%s)" % [fields])
