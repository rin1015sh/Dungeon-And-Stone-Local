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
## 잠긴 문은 연 셈으로(도서관은 1층뿐 — 지하 서고는 희귀서 입고 순에만 열린다, 사용자 2026-10-31 "도서관 2층 없애기").
func test_floors_connect_in_one_map() -> void:
	var s := _state()
	s.happenings.assign(db.get_collection("city_events").keys())
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


## 이번 순 사건 활동(특식·떠돌이 상인 …)은 rest 자리에서 한다.
func test_event_activities_land_on_rest_spots() -> void:
	var s := _state()
	s.happenings.assign(["inn_special", "peddler"])
	var inn := CityRoom.load_for(s, "inn")
	var bar := _spot_with(inn, "inn_snack")
	assert_true(inn.activities_at(s, bar).has("inn_feast") and inn.activities_at(s, bar).has("inn_hearty"), "여관 특식 순 — 주인에게 특식·든든한 식사")
	var shop := CityRoom.load_for(s, "shop")
	assert_false(_spot_with(shop, "shop_peddler").is_empty(), "떠돌이 상인 노점")


## 행동력은 건물에 들어갈 때 1(CT72). 안에서는 활동을 몇 번이든 — 도서관 서적은 한 방문에 분야마다 한 번.
func test_visit_costs_one_on_enter_and_library_field_once() -> void:
	var s := _state()
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
	pc.inventory.money = 100000
	assert_eq(s.enter_facility("library"), "")
	assert_eq(s.ap, 2, "들어가면서 1")
	var fields := CityInfo.field_ids(db).filter(func(f: String) -> bool: return CityActions.check(s, pc, "library_" + f).is_empty())
	assert_true(fields.size() >= 2, "읽을 분야가 둘 이상")
	var a := "library_" + str(fields[0])
	assert_true(CityActions.perform(s, pc, a, ContentRegistries.new().city_effects).ok, "한 분야 읽기")
	assert_eq(CityActions.check(s, pc, a), "city.reason_read_this_visit", "같은 분야는 이번 방문에 한 번")
	assert_eq(CityActions.check(s, pc, "library_" + str(fields[1])), "", "다른 분야는 이어서 읽는다")
	s.leave_facility()
	assert_eq(s.ap, 2, "나올 때는 쓰지 않는다")
	s.enter_facility("library")
	assert_eq(CityActions.check(s, pc, a), "", "다시 들어오면 그 분야도 또")


## 사람마다 그 건물에 맞는 동작(CT69): act가 있으면 동작 그림이 있고 칸이 돈다.
func test_npcs_play_their_act() -> void:
	var s := _state()
	var acts := 0
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		for n: Dictionary in r.npcs:
			assert_eq(r.kind_at(n["at"]), "npc", "%s %s 자리 = 사람 칸" % [f, n["name_ko"]])
			if str(n["act"]).is_empty():
				continue
			acts += 1
			var sheet := NpcActSheet.load_for(db.render, str(n["look"]), str(n["act"]))
			assert_true(sheet != null, "%s %s 동작 그림(%s)" % [f, n["name_ko"], n["act"]])
	assert_true(acts >= 30, "사람 대부분이 동작을 한다(%d)" % acts)
	var forge := CityRoom.load_for(s, "smithy")
	var smith: NpcActSheet = null
	for n: Dictionary in forge.npcs:
		if str(n["act"]) == "hammer":
			smith = NpcActSheet.load_for(db.render, str(n["look"]), "hammer")
	assert_true(smith != null and smith.seq.size() > 1 and smith.col_at(0.0) != smith.col_at(1.0 / smith.fps * 3.0), "대장장이 망치질은 칸이 바뀐다")


## 말 걸기(CT76): 일하는 사람이 아닌 사람은 모두 할 말이 있고(city.npc.<talk>.1~), 바라보면 그 사람이 살필 자리.
func test_people_talk() -> void:
	var s := _state()
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		for n: Dictionary in r.npcs:
			if bool(n["staff"]):
				continue
			assert_true(Strings.has("city.npc.%s.1" % n["talk"]), "%s %s 할 말" % [f, n["name_ko"]])
			var at: Vector2i = n["at"]
			var seen := _reach(r)
			for d: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
				if seen.has(at + d):
					var t := r.target(Vector2(at + d) + Vector2(0.5, 0.5), -d)
					assert_eq(str(t.get("talk", "")), str(n["talk"]), "%s %s 바라보면 말 걸기" % [f, n["name_ko"]])
					break


## 검은 테두리(CT77): 활동 자리마다 테두리를 두를 그림(가구 · 벽 장식 — 사람은 두르지 않는다)이 있다 — 이름판이 없으니 테두리로만 알아본다.
func test_every_spot_has_something_outlined() -> void:
	var s := _state()
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		var walldeco := CityRoom.groups(r.rows, r.legend, ["walldeco"])
		for sp: Dictionary in r.spots:
			var rc: Rect2i = sp["rect"]
			var hit := r.furniture.any(func(g: Dictionary) -> bool: return (g["rect"] as Rect2i).intersects(rc))
			hit = hit or walldeco.any(func(g: Dictionary) -> bool: return (g["rect"] as Rect2i).intersects(rc))
			assert_true(hit, "%s %s 자리에 테두리 두를 그림" % [f, sp["name_ko"]])


## 가구 뒤지기(CT74): 건물마다 뒤질 가구가 있고, 바라보고 뒤지면 그 건물 잡템(또는 빈손), 한 자리는 한 순에 한 번 — 순이 바뀌면 다시.
func test_search_furniture_once_per_period() -> void:
	var s := _state()
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})
	var found := {}
	for f in s.facility_ids():
		var r := CityRoom.load_for(s, f)
		assert_true(r.searchables.size() >= 3, "%s 뒤질 가구 %d" % [f, r.searchables.size()])
		for sp: Dictionary in r.searchables:
			var res := CityScavenge.run(s, pc, sp)
			if str(res["key"]) == "item.got":
				found[f] = true
			assert_eq(str(CityScavenge.run(s, pc, sp)["key"]), "city.reason_searched", "%s %s는 이번 순에 한 번" % [f, sp["name_ko"]])
	assert_true(found.size() >= 6, "건물 대부분에서 무언가 찾는다(%s)" % [found.keys()])
	assert_true(pc.inventory.count("iron_scrap") + pc.inventory.count("rusty_nails") + pc.inventory.count("broken_blade") > 0, "대장간 잡템")
	var smithy := CityRoom.load_for(s, "smithy")
	s.next_period()
	assert_false(CityScavenge.done(s, smithy.searchables[0]), "순이 바뀌면 다시 뒤진다")
	var r2 := CityRoom.load_for(s, "library")
	var shelf := r2.searchables.filter(func(sp: Dictionary) -> bool: return str(sp["search"]) == "library_shelf")
	assert_false(shelf.is_empty(), "도서관 책장·책 더미")
	var faced := 0
	for sp: Dictionary in shelf:  # 활동 자리와 겹치지 않는 책장 칸 아래에서 위를 보면 뒤질 자리
		var rc: Rect2i = sp["rect"]
		for x in range(rc.position.x, rc.end.x):
			var below := Vector2(x + 0.5, rc.end.y + 0.5)
			if r2.map.is_walkable(Kinematics.cell_of(below)) and not r2.spots.any(func(s2: Dictionary) -> bool: return (s2["rect"] as Rect2i).has_point(Vector2i(x, rc.end.y - 1))):
				faced += 1 if r2.target(below, Vector2i.UP).has("search") else 0
	assert_true(faced > 0, "가구를 바라보면 뒤질 자리")
