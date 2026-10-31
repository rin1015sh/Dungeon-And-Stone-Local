extends TestCase
## 시설 실내 방(탑뷰 — CityRoom, CT62): 도서관 방 지도 · 문 · 책장 자리 · 사서 책상(남은 활동) · 이번 순에만 서는 독서대 · 방문 행동력.


func _state() -> CityState:
	var s := CityState.new(db, 5)
	s.start()
	s.happenings.clear()
	return s


func test_library_room_map_and_spots() -> void:
	var s := _state()
	var r := CityRoom.load_for(s, "library")
	assert_true(r != null, "도서관은 실내 방이 있다")
	assert_true(CityRoom.load_for(s, "inn") == null, "여관은 메뉴 시설(방 없음)")
	assert_true(r.map.is_walkable(Vector2i(floori(r.start.x), floori(r.start.y))), "들어온 자리는 바닥")
	assert_false(r.map.is_walkable(Vector2i(1, 1)), "뒷벽 책장 칸은 막힌다")
	assert_false(r.map.is_walkable(Vector2i(0, 5)), "옆벽은 막힌다")
	assert_true(r.is_door(Vector2i(9, r.height - 1)) and r.map.is_walkable(Vector2i(9, r.height - 1)), "문 칸은 걸어 들어갈 수 있다")
	assert_false(r.map.is_walkable(Vector2i(6, 6)), "탁자는 칸을 막는다")
	var shelf := r.target(Vector2(2.0, 3.5), Vector2i.UP)
	assert_eq(str(shelf.get("activity", "")), "library_dungeon", "첫 책장을 바라보면 '미궁에 관하여'")
	assert_true(r.target(Vector2(2.0, 3.5), Vector2i.DOWN).is_empty(), "등지면 아무것도 없다")
	var fields: Array[String] = []
	for sp: Dictionary in r.spots:
		fields.append(str(sp["activity"]))
	for f in CityInfo.field_ids(db):
		assert_true(fields.has("library_" + f), "분야마다 책장: " + f)


func test_rare_lectern_only_with_happening() -> void:
	var s := _state()
	var r := CityRoom.load_for(s, "library")
	assert_false(r.props.any(func(p: Dictionary) -> bool: return str(p["id"]) == "lectern"), "희귀서 입고가 없으면 독서대도 없다")
	assert_true(r.map.is_walkable(Vector2i(17, 5)), "독서대 자리는 빈 바닥")
	s.happenings.assign(["rare_books"])
	r = CityRoom.load_for(s, "library")
	assert_true(r.props.any(func(p: Dictionary) -> bool: return str(p["id"]) == "lectern"), "희귀서 입고 순에는 독서대가 선다")
	assert_false(r.map.is_walkable(Vector2i(17, 5)), "독서대가 칸을 막는다")
	assert_eq(str(r.target(Vector2(17.5, 6.5), Vector2i.UP).get("activity", "")), "library_rare", "독서대 = 희귀서 열람")


func test_desk_takes_unplaced_activities() -> void:
	var s := _state()
	var r := CityRoom.load_for(s, "library")
	var desk := r.target(Vector2(3.5, 7.5), Vector2i.UP)
	assert_eq(r.activities_at(s, desk), ["library_decode"] as Array[String], "사서 책상 = 고서 해독")


## 방은 걸어 다녀도 행동력을 쓰지 않는다 — 나올 때 1(CT62).
func test_visit_costs_one_on_leave() -> void:
	var s := _state()
	assert_eq(s.enter_facility("library"), "")
	assert_eq(s.ap, 3)
	s.leave_facility()
	assert_eq(s.ap, 2)
