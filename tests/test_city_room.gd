extends TestCase
## 시설 실내(탑뷰 한 지도 — CityRoom, CT62·CT64·CT66): 모든 시설 · 층이 한 지도에서 계단·사다리로 이어진다 · 자리마다 걸어서 닿는다 ·
## 잠긴 문·이번 순에만 서는 가구 · 사람 · 방문 행동력.


func _state() -> CityState:
	var s := CityState.new(db, 5)
	s.start()
	s.happenings.clear()
	return s


## 입구(start)에서 걸어서 닿는 칸.
func _reach(r: CityRoom) -> Dictionary:
	var start := Vector2i(floori(r.start.x), floori(r.start.y))
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var c: Vector2i = todo.pop_back()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not seen.has(c + d) and r.map.is_walkable(c + d):
				seen[c + d] = true
				todo.append(c + d)
	return seen


func _spot_with(r: CityRoom, act: String) -> Dictionary:
	for sp: Dictionary in r.spots:
		if (sp["acts"] as Array).has(act):
			return sp
	return {}


func test_every_facility_is_a_room_with_reachable_spots() -> void:
	var s := _state()
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		assert_true(r != null, "실내: " + f)
		if r == null:
			continue
		assert_true(r.map.is_walkable(Vector2i(floori(r.start.x), floori(r.start.y))), f + " 들어온 자리는 걷는 칸")
		var seen := _reach(r)
		for a in CityActions.activities_of(s, f):
			var sp := {}
			for spot: Dictionary in r.spots:
				if r.activities_at(s, spot).has(a):
					sp = spot
			assert_false(sp.is_empty(), "%s 활동 %s 자리" % [f, a])
			if sp.is_empty():
				continue
			var rc: Rect2i = sp["rect"]
			var ok := false
			for y in range(rc.position.y, rc.end.y):
				for x in range(rc.position.x, rc.end.x):
					for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
						ok = ok or (seen.has(Vector2i(x, y) + d) and not rc.has_point(Vector2i(x, y) + d))
			assert_true(ok, "%s %s 자리에 걸어서 닿는다" % [f, a])
		assert_true(r.npcs.any(func(n: Dictionary) -> bool: return bool(n["staff"])), "직원이 서 있다: " + f)
		assert_true(FileAccess.file_exists(JsonUtil.get_str(r.def, "art_dir").path_join("floor.webp")), "바닥 그림: " + f)


## 복층은 한 지도(CT66): 건물마다 계단·사다리 칸이 있고, 입구에서 그 줄을 따라 위층·지하까지 걸어서 간다.
func test_floors_connect_in_one_map() -> void:
	var s := _state()
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		var seen := _reach(r)
		var links := 0
		var top := r.height
		var bottom := 0
		for c: Vector2i in seen:
			if r.kind_at(c) in ["stairs", "ladder"]:
				links += 1
			top = mini(top, c.y)
			bottom = maxi(bottom, c.y)
		assert_true(links > 0, f + " 계단·사다리로 층을 잇는다")
		assert_true(bottom - top > 18, f + " 입구에서 다른 층까지 걸어서 닿는다(%d줄)" % (bottom - top))


func test_library_shelves_desk_and_locked_archive() -> void:
	var s := _state()
	var r := CityRoom.load_for(s, "library")
	var shelf := _spot_with(r, "library_dungeon")
	var rc: Rect2i = shelf["rect"]
	var stand := Vector2(rc.position.x + rc.size.x * 0.5, rc.end.y + 0.5)
	assert_eq(r.activities_at(s, r.target(stand, Vector2i.UP)), ["library_dungeon"] as Array[String], "책장 앞에서 위를 보면 '미궁에 관하여'")
	assert_true(r.target(stand, Vector2i.DOWN).is_empty(), "등지면 아무것도 없다")
	for f in CityInfo.field_ids(db):
		assert_false(_spot_with(r, "library_" + f).is_empty(), "분야마다 책장: " + f)
	assert_eq(r.activities_at(s, _spot_with(r, "library_decode")), ["library_decode"] as Array[String], "사서 책상 = 고서 해독")
	assert_true(_spot_with(r, "library_rare").is_empty(), "희귀서 입고가 없으면 독서대 자리도 없다")
	assert_false(r.furniture.any(func(g: Dictionary) -> bool: return JsonUtil.get_str(g["def"], "needs") == "library_rare"), "독서대도 없다")
	var locked := 0
	for c: Vector2i in _reach(r):
		locked += 1 if r.kind_at(c) == "locked" else 0
	assert_eq(_reach(r).size() < _reach_open(s).size(), true, "잠긴 서고 문 — 희귀서 입고 순에만 지하 서고로")


func _reach_open(s: CityState) -> Dictionary:
	s.happenings.assign(["rare_books"])
	var r := CityRoom.load_for(s, "library")
	assert_false(_spot_with(r, "library_rare").is_empty(), "희귀서 입고 순 — 쇠사슬 책 자리")
	assert_true(r.furniture.any(func(g: Dictionary) -> bool: return JsonUtil.get_str(g["def"], "needs") == "library_rare"), "독서대가 선다")
	return _reach(r)


## 이번 순 사건 활동(특식·떠돌이 상인·교관 특강 …)은 rest 자리에서 한다.
func test_event_activities_land_on_rest_spots() -> void:
	var s := _state()
	s.happenings.assign(["inn_special", "peddler", "lecture"])
	var inn := CityRoom.load_for(s, "inn")
	var bar := _spot_with(inn, "inn_snack")
	assert_true(inn.activities_at(s, bar).has("inn_feast") and inn.activities_at(s, bar).has("inn_hearty"), "여관 특식 순 — 주인에게 특식·든든한 식사")
	var shop := CityRoom.load_for(s, "shop")
	assert_false(_spot_with(shop, "shop_peddler").is_empty(), "떠돌이 상인 노점")
	var gym := CityRoom.load_for(s, "training")
	var trainer := {}
	for sp: Dictionary in gym.spots:
		if str(sp["name_ko"]) == "교관":
			trainer = sp
	assert_true(gym.activities_at(s, trainer).has("training_lecture"), "교관 특강 — 교관에게")


## 행동력은 건물 한 번 다녀오기에 1 — 나올 때(CT62). 층을 오가도 그대로.
func test_visit_costs_one_on_leave() -> void:
	var s := _state()
	assert_eq(s.enter_facility("library"), "")
	assert_eq(s.ap, 3)
	s.leave_facility()
	assert_eq(s.ap, 2)
