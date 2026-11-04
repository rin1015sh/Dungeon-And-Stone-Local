extends TestCase
## 시설 실내(CT106 — data/interiors, CityInterior): 방 나누기 · 자리 · 사건으로만 서는 것 · 잠긴 문 · 들어온 자리.


func _state(happen: Array[String] = []) -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	s.happenings.assign(happen)
	return s


func test_every_facility_has_interior() -> void:
	var s := _state()
	for fid in ["inn", "temple", "guild", "library", "shop", "smithy", "bank"]:
		var r := CityInterior.load_for(s, fid)
		assert_true(r != null, "실내가 있다: " + fid)
		if r == null:
			continue
		assert_true(r.rooms.size() >= 1 and r.is_exit(Kinematics.cell_of(r.start() + Vector2(0, 1))), "%s: 들어온 자리 바로 아래가 바깥 문" % fid)
		assert_true(r.map.is_walkable(Kinematics.cell_of(r.start())), "%s: 들어온 자리는 걷는 칸" % fid)
		for room: Dictionary in r.rooms:
			assert_false(str(room["name_ko"]).is_empty(), "%s: 방마다 이름" % fid)


func test_inn_rooms_corridor_between() -> void:
	var r := CityInterior.load_for(_state(), "inn")
	var names: Array[String] = []
	for room: Dictionary in r.rooms:
		names.append(str(room["name_ko"]))
	assert_eq(names.size(), 3, "여관 = 방 셋")
	assert_true(names.has("주점 홀") and names.has("객실 복도") and names.has("내 방"), "주점 홀 · 객실 복도 · 내 방")
	var hall := r.room_at(Kinematics.cell_of(r.start()))
	assert_eq(str(r.rooms[hall]["name_ko"]), "주점 홀", "들어오면 주점 홀")
	assert_eq(r.room_at(Vector2i(18, 7)), -1, "방 사이 문 칸은 어느 방도 아니다")
	assert_eq(str(r.rooms[r.room_at(Vector2i(18, 6))]["name_ko"]), "객실 복도", "홀 북쪽 문 너머 = 복도")
	assert_eq(str(r.rooms[r.room_at(Vector2i(17, 3))]["name_ko"]), "내 방", "복도 북쪽 문 너머 = 내 방")


func test_spots_and_targets() -> void:
	var r := CityInterior.load_for(_state(), "inn")
	var at := r.target(Vector2(4.5, 10.5), Vector2i.UP)
	assert_true((at.get("acts", []) as Array).has("inn_meal"), "바 앞에서 위를 보면 바(식사)")
	assert_false((at.get("acts", []) as Array).has("inn_feast"), "특식은 사건 순에만")
	var bed := r.target(Vector2(16.5, 3.5), Vector2i.UP)
	assert_eq(bed.get("acts", []), ["inn_rest"], "내 방 침대 = 휴식")
	assert_true(bool(r.target(Vector2(3.5, 5.5), Vector2i.UP).get("locked", false)), "다른 객실 문 = 잠겨 있다")
	assert_true(r.target(Vector2(10.5, 12.5), Vector2i.DOWN).is_empty(), "바닥을 보면 아무것도 없다")
	var feast := CityInterior.load_for(_state(["inn_special"] as Array[String]), "inn")
	assert_true((feast.target(Vector2(4.5, 10.5), Vector2i.UP).get("acts", []) as Array).has("inn_feast"), "여관 특식 순 = 바에 특식")


func test_event_only_things() -> void:
	var lib := CityInterior.load_for(_state(), "library")
	assert_eq(lib.kind_at(Vector2i(8, 3)), "wallart", "희귀서 서고 문은 평소 닫힘")
	assert_false(lib.map.is_walkable(Vector2i(8, 3)), "닫힌 문은 못 지나간다")
	var open := CityInterior.load_for(_state(["rare_books"] as Array[String]), "library")
	assert_eq(open.kind_at(Vector2i(8, 3)), "door", "희귀서 입고 순 = 서고 문이 열린다")
	assert_true(open.map.is_walkable(Vector2i(8, 3)), "열린 문은 지나간다")
	var shop := CityInterior.load_for(_state(), "shop")
	assert_eq(shop.npcs.size(), 1, "평소 상점 = 상인 하나")
	assert_eq(shop.kind_at(Vector2i(3, 4)), "floor", "떠돌이 노점은 그 순에만(평소 빈 바닥)")
	var peddler := CityInterior.load_for(_state(["peddler"] as Array[String]), "shop")
	assert_eq(peddler.npcs.size(), 2, "떠돌이 상인 순 = 떠돌이 상인이 선다")
	assert_true((peddler.target(Vector2(3.5, 5.5), Vector2i.UP).get("acts", []) as Array).has("shop_peddler"), "노점 앞 = 떠돌이 상인")


func test_temple_rooms_and_side_spots() -> void:
	var r := CityInterior.load_for(_state(), "temple")
	assert_eq(r.rooms.size(), 4, "신전 = 예배당 · 곁방 둘 · 전실")
	assert_eq(str(r.rooms[r.room_at(Kinematics.cell_of(r.start()))]["name_ko"]), "전실", "들어오면 전실")
	assert_true((r.target(Vector2(1.5, 14.5), Vector2i.UP).get("acts", []) as Array).has("temple_service"), "봉헌 곁방 촛대 = 봉사활동")
	assert_true((r.target(Vector2(10.5, 3.5), Vector2i.UP).get("acts", []) as Array).has("temple_remove_essence"), "제단 = 정수 제거")
