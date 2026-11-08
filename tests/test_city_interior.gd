extends TestCase
## 시설 실내(CT106 — data/interiors, CityInterior): 방 나누기 · 자리 · 옛 사건 전용이던 것(늘 — CT114) · 잠긴 문 · 들어온 자리.


func _state() -> CityState:
	var s := CityState.new(db, 7)
	s.start()
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
	assert_true((at.get("acts", []) as Array).has("inn_feast"), "바에 특식도 늘(CT114)")
	var bed := r.target(Vector2(16.5, 3.5), Vector2i.UP)
	assert_eq(bed.get("acts", []), ["inn_rest"], "내 방 침대 = 휴식")
	assert_true(bool(r.target(Vector2(3.5, 5.5), Vector2i.UP).get("locked", false)), "다른 객실 문 = 잠겨 있다")
	assert_true(r.target(Vector2(10.5, 12.5), Vector2i.DOWN).is_empty(), "바닥을 보면 아무것도 없다")


## 옛 사건 전용이던 것(희귀서 서고 · 떠돌이 상인)은 늘 열려 있다(도시 사건을 없앰 — CT114).
func test_former_event_things_always_there() -> void:
	var lib := CityInterior.load_for(_state(), "library")
	assert_eq(lib.kind_at(Vector2i(8, 3)), "door", "희귀서 서고 문은 늘 열림")
	assert_true(lib.map.is_walkable(Vector2i(8, 3)), "열린 문은 지나간다")
	var shop := CityInterior.load_for(_state(), "shop")
	assert_eq(shop.npcs.size(), 2, "상점 = 상인 + 떠돌이 상인")
	assert_true((shop.target(Vector2(3.5, 5.5), Vector2i.UP).get("acts", []) as Array).has("shop_peddler"), "노점 앞 = 떠돌이 상인")


func test_temple_rooms_and_side_spots() -> void:
	var r := CityInterior.load_for(_state(), "temple")
	assert_eq(r.rooms.size(), 4, "신전 = 예배당 · 곁방 둘 · 전실")
	assert_eq(str(r.rooms[r.room_at(Kinematics.cell_of(r.start()))]["name_ko"]), "전실", "들어오면 전실")
	assert_true((r.target(Vector2(1.5, 14.5), Vector2i.UP).get("acts", []) as Array).has("temple_service"), "봉헌 곁방 촛대 = 봉사활동")
	assert_true((r.target(Vector2(10.5, 3.5), Vector2i.UP).get("acts", []) as Array).has("temple_remove_essence"), "제단 = 정수 제거")


func test_house_doors_locked_and_kinds() -> void:
	var town := TownMap.load_for(db)
	assert_true(town.house_doors.size() >= 20, "일반 집 문이 지도에 있다(tools/town_doors.gd — CT110)")
	var kinds := JsonUtil.get_dict(JsonUtil.get_dict(db.singletons.get("city", {}), "interior"), "house_kinds")
	var used := {}
	for c: Vector2i in town.house_doors:
		var e: Dictionary = town.house_doors[c]
		assert_false(town.is_walkable(c), "문 칸은 집: %s" % e["house"])
		assert_true(town.is_walkable(c + Vector2i.DOWN), "문 앞은 길: %s" % e["house"])
		assert_true(kinds.has(str(e["design"])), "집 바리에이션마다 실내: " + str(e["design"]))
		used[JsonUtil.get_str(kinds, str(e["design"]))] = true
		var t := town.target(Vector2(c) + Vector2(0.5, 1.5), Vector2i.UP)
		assert_eq(str(t.get("house", "")), str(e["house"]), "문 앞에서 위를 보면 그 집")
	var ids := {}
	for d: String in kinds:
		ids[JsonUtil.get_str(kinds, d)] = true
	assert_eq(ids.size(), 8, "집 실내는 8가지(바리에이션을 생김새로 묶어 돌려 쓴다)")
	assert_true(JsonUtil.get_bool(JsonUtil.get_dict(db.singletons.get("city", {}), "interior"), "houses_locked"), "지금은 잠겨 있다")
	var s := _state()
	for iid: String in ids:
		var r := CityInterior.load_id(s, iid)
		assert_true(r != null and r.rooms.size() >= 1 and r.spots.is_empty(), "집 실내 %s: 방 · 활동 없음" % iid)
