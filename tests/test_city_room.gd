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
	assert_true(r.map.is_walkable(Vector2i(floori(r.start.x), floori(r.start.y))), "들어온 자리는 바닥")
	assert_false(r.map.is_walkable(Vector2i(1, 1)), "뒷벽 책장 칸은 막힌다")
	assert_false(r.map.is_walkable(Vector2i(0, 5)), "옆벽은 막힌다")
	assert_true(r.is_door(Vector2i(9, r.height - 1)) and r.map.is_walkable(Vector2i(9, r.height - 1)), "문 칸은 걸어 들어갈 수 있다")
	assert_false(r.map.is_walkable(Vector2i(6, 6)), "탁자는 칸을 막는다")
	var shelf := r.target(Vector2(2.0, 3.5), Vector2i.UP)
	assert_eq(r.activities_at(s, shelf), ["library_dungeon"] as Array[String], "첫 책장을 바라보면 '미궁에 관하여'")
	assert_true(r.target(Vector2(2.0, 3.5), Vector2i.DOWN).is_empty(), "등지면 아무것도 없다")
	var fields: Array[String] = []
	for sp: Dictionary in r.spots:
		fields.append_array(sp["acts"] as Array[String])
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
	assert_eq(r.activities_at(s, r.target(Vector2(17.5, 6.5), Vector2i.UP)), ["library_rare"] as Array[String], "독서대 = 희귀서 열람")


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


## 모든 거리 시설이 실내 방(CT64): 방이 있고, 시설 활동마다 걸어가서 할 자리가 있고, 사람(몸 그림)이 서 있다.
func test_every_facility_is_a_room() -> void:
	var s := _state()
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		assert_true(r != null, "실내 방: " + f)
		if r == null:
			continue
		var reach: Array[String] = []
		for sp: Dictionary in r.spots:
			reach.append_array(r.activities_at(s, sp))
		for a in CityActions.activities_of(s, f):
			assert_true(reach.has(a), "%s 활동 %s 자리" % [f, a])
		assert_true(r.props.any(func(p: Dictionary) -> bool: return not str(p["sprite"]).is_empty()), "사람이 서 있다: " + f)
		assert_true(FileAccess.file_exists(JsonUtil.get_str(r.def, "art")), "방 그림: " + f)


## 이번 순 사건 활동(특식·떠돌이 상인·정화 의식 …)은 rest 자리에서 한다.
func test_event_activities_land_on_rest_spots() -> void:
	var s := _state()
	s.happenings.assign(["inn_special", "peddler", "lecture"])
	var inn := CityRoom.load_for(s, "inn")
	var bar := inn.target(Vector2(8.5, 5.5), Vector2i.UP)
	assert_true(inn.activities_at(s, bar).has("inn_feast") and inn.activities_at(s, bar).has("inn_hearty"), "여관 특식 순 — 주인에게 특식·든든한 식사")
	var shop := CityRoom.load_for(s, "shop")
	assert_true(shop.activities_at(s, shop.target(Vector2(8.5, 5.5), Vector2i.UP)).has("shop_peddler"), "떠돌이 상인 — 상점 계산대")
	var gym := CityRoom.load_for(s, "training")
	assert_true(gym.activities_at(s, gym.target(Vector2(11.5, 5.5), Vector2i.UP)).has("training_lecture"), "교관 특강 — 교관에게")
