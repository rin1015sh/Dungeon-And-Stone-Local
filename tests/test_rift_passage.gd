extends TestCase
## 균열 챕터 사이 길목(RiftPassage, 사용자 요청 2026-10-20): 걸어 들어가면 넘어가고, 지나온 챕터로 돌아갈 수 있다(상태 그대로).


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


## 1층 세션에서 균열에 들어가 첫 챕터 세션을 돌려준다.
func _enter(rift_id: String) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(3))
	var s := ExploreSession.new(db, def, map, _pc(), GameClock.new(), Rng.new(4), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift_id, s.pos)
	var p: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	return s.rifts.enter(s, p)


## 길목 칸으로 걸어 들어간 것처럼 옮기고, 넘어간 세션(없으면 null)을 돌려준다.
func _step_on(cs: ExploreSession, cell: Vector2i) -> ExploreSession:
	var got: Array = []
	var take := func(t: ExploreSession) -> void: got.append(t)
	cs.transfer.connect(take)
	for g: FieldMonsters.Group in cs.monsters.groups:  # 길목 앞을 막고 선 무리는 비킨다(시험 — 자리만 본다)
		if g.pos == cell:
			g.pos += Vector2i(0, 3)
	cs.relocate(cell)
	cs.transfer.disconnect(take)
	return got[0] if not got.is_empty() else null


func _exit_pos(cs: ExploreSession) -> Vector2i:
	return RiftPassage.exit_portal(cs.map)["pos"]


func test_passages_are_floor_not_square_portal() -> void:
	var cs := _enter("rift_iron_tomb")
	var run := cs.rift_run
	var exit := _exit_pos(cs)
	assert_true(cs.map.tile_id_at(exit) != "rift_exit", "앞 길목은 사각형 출구 타일이 아니라 원래 바닥")
	assert_true(cs.lights.at(exit.x, exit.y).r > 0.0, "길목에 빛이 있다")
	assert_true(cs.map.portal_at(cs.map.entry).is_empty(), "첫 챕터 시작 자리는 길목이 아니다(균열 밖으로 나가는 길은 탈출 포탈뿐)")
	run.debug_clear()
	cs = _step_on(cs, exit)
	assert_eq(run.chapter, 1)
	assert_eq(str(cs.map.portal_at(cs.map.entry).get("kind", "")), RiftPassage.BACK, "2챕터 시작 자리 = 뒤 길목")
	while not run.is_last_chapter():
		run.debug_clear()
		cs = _step_on(cs, _exit_pos(cs))
	assert_eq(cs.map.tile_id_at(_exit_pos(cs)), "rift_exit", "마지막 챕터 출구는 탈출 포탈 그대로")


func test_walk_forward_and_back_keeps_state() -> void:
	var cs := _enter("rift_iron_tomb")
	var run := cs.rift_run
	var first := cs
	var exit := _exit_pos(cs)
	assert_eq(_step_on(cs, exit), null, "조우가 남으면 넘어가지 않는다")
	assert_true(run.session == first and run.chapter == 0)
	run.debug_clear()
	cs.relocate(cs.map.entry)
	var second := _step_on(cs, exit)
	assert_true(second != null and run.chapter == 1, "조우를 치우고 길목에 들어서면 다음 챕터")
	assert_true(first.ended, "지나온 챕터 세션은 쉰다")
	assert_true(second.fade_in, "화면이 어두워졌다 밝아진다")
	var zone := int(db.bal("rift.passage_zone"))
	var d := second.pos - second.map.entry
	assert_true(maxi(absi(d.x), absi(d.y)) > zone, "도착 자리는 뒤 길목 둘레 밖(바로 되돌아가지 않게)")
	assert_true(second.in_safe_zone(), "도착 자리는 시작 안전지대 안")
	var back := _step_on(second, second.map.entry)
	assert_eq(back, first, "뒤 길목으로 들어서면 지나온 챕터 — 같은 세션(치운 상태 그대로)")
	assert_eq(run.chapter, 0)
	assert_false(first.ended)
	assert_true(run.remaining.is_empty(), "치운 조우가 되살아나지 않는다")
	assert_true(second.ended)
	var e := first.pos - exit
	assert_true(maxi(absi(e.x), absi(e.y)) > zone, "앞 길목 둘레 밖에 선다")
	var again := _step_on(first, exit)
	assert_eq(again, second, "다시 앞으로 가면 같은 2챕터 세션")
	assert_eq(run.chapter, 1)


func test_exit_item_used_once() -> void:
	var cs := _enter("rift_blood_fortress")
	var run := cs.rift_run
	var pc := cs.player
	run.debug_clear()
	var exit := _exit_pos(cs)
	assert_eq(_step_on(cs, exit), null, "뿔피리가 없으면 넘어가지 않는다")
	pc.inventory.add("rift_horn", 1)
	cs.relocate(cs.map.entry)
	var second := _step_on(cs, exit)
	assert_true(second != null and pc.inventory.count("rift_horn") == 0, "뿔피리를 쓰고 넘어간다")
	var first := _step_on(second, second.map.entry)
	assert_true(first != null and run.chapter == 0)
	first.relocate(first.map.entry)
	assert_true(_step_on(first, exit) != null, "한 번 지난 길목은 뿔피리 없이 다시 지난다")


func test_finish_drops_kept_chapters() -> void:
	var cs := _enter("rift_iron_tomb")
	var run := cs.rift_run
	while not run.is_last_chapter():
		run.debug_clear()
		cs = _step_on(cs, _exit_pos(cs))
	run.debug_clear()
	assert_eq(run.use_exit(cs), run.outer, "마지막 챕터 출구(E)는 탈출")
	assert_true(run._kept.is_empty(), "나가면 보관한 챕터를 놓는다")


## 지도 가장자리의 트인 칸은 모두 길목 입구다 — 나가는 길처럼 보이는 막다른 가장자리가 없다
## (녹색 탄광 2챕터 철로가 동쪽 끝으로 열려 있어 그쪽으로 가면 아무 일도 없었다 — 2026-10-23).
## 넓은 통로는 표시 칸 둘레만이 아니라 입구 어느 칸으로 나가도 넘어간다.
func test_edge_openings_are_passages() -> void:
	var ids: Array = db.get_collection("rifts").keys()
	ids.sort()
	for id: Variant in ids:
		var cs := _enter(str(id))
		var run := cs.rift_run
		while true:
			var m := cs.map
			for y in m.height:
				for x in m.width:
					var p := Vector2i(x, y)
					if (x == 0 or y == 0 or x == m.width - 1 or y == m.height - 1) and m.is_walkable(p):
						assert_true(RiftPassage.dir_at(m, p, 0) != 0, "%s %d챕터 가장자리 %s가 트였는데 길목이 아니다" % [id, run.chapter + 1, p])
			if run.is_last_chapter():
				break
			run.debug_clear()
			var req := JsonUtil.get_str(JsonUtil.get_dict(run.chapters()[run.chapter], "exit_requires"), "item")
			if not req.is_empty():
				cs.player.inventory.add(req, 1)  # 뿔피리·폭약
			var mouth: Array = RiftPassage.exit_portal(m)["mouth"]
			var far: Vector2i = mouth[-1]  # 표시 칸에서 가장 먼 입구 칸
			var before := run.chapter
			var next := _step_on(cs, far)
			assert_true(next != null and run.chapter == before + 1, "%s %d챕터: 입구 끝 칸 %s로 나가도 넘어간다" % [id, before + 1, far])
			if next == null:
				break
			var zone := int(db.bal("rift.passage_zone"))
			assert_eq(RiftPassage.dir_at(next.map, next.pos, zone), 0, "%s %d챕터 도착 자리는 어느 길목 둘레에도 들지 않는다" % [id, run.chapter + 1])
			cs = next


## 모든 균열의 챕터 사이 길목은 지도 가장자리에 있다(그 너머로 길이 이어지는 것처럼 — 사용자 요청 2026-10-20).
func test_every_passage_is_on_map_edge() -> void:
	for id: Variant in db.get_collection("rifts").keys():
		var chs := JsonUtil.get_array(db.get_entry("rifts", str(id)), "chapters")
		for i in chs.size():
			var bp := JsonUtil.get_str(JsonUtil.get_dict(chs[i], "map"), "blueprint")
			if bp.is_empty():
				continue
			var data := FloorMapFile.read(bp)
			var w := JsonUtil.get_int(data, "width")
			var h := JsonUtil.get_int(data, "height")
			var marks := JsonUtil.get_dict(data, "marks")
			var keys: Array[String] = []
			if i < chs.size() - 1:
				keys.append("exit")
			if i > 0:
				keys.append("entry")
			for key in keys:
				var p := JsonUtil.get_array(marks, key)
				var x := int(p[0])
				var y := int(p[1])
				assert_true(x == 0 or y == 0 or x == w - 1 or y == h - 1, "%s %d챕터 %s %s가 가장자리" % [id, i + 1, key, p])


## 앞 챕터 출구와 다음 챕터 입구는 반대쪽 가장자리다(동쪽으로 나가면 다음 챕터 서쪽으로 들어온다 — 사용자 요청 2026-10-20).
func test_passage_directions_match() -> void:
	for id: Variant in db.get_collection("rifts").keys():
		var chs := JsonUtil.get_array(db.get_entry("rifts", str(id)), "chapters")
		for i in chs.size() - 1:
			var a := FloorMapFile.read(JsonUtil.get_str(JsonUtil.get_dict(chs[i], "map"), "blueprint"))
			var b := FloorMapFile.read(JsonUtil.get_str(JsonUtil.get_dict(chs[i + 1], "map"), "blueprint"))
			if a.is_empty() or b.is_empty():
				continue
			var out := _side(a, JsonUtil.get_array(JsonUtil.get_dict(a, "marks"), "exit"))
			var into := _side(b, JsonUtil.get_array(JsonUtil.get_dict(b, "marks"), "entry"))
			assert_eq(out, -into, "%s %d→%d챕터: 나간 쪽의 반대쪽으로 들어온다" % [id, i + 1, i + 2])


## 가장자리 방향(동 (1,0)·서 (-1,0)·북 (0,-1)·남 (0,1)).
func _side(data: Dictionary, p: Array) -> Vector2i:
	var w := JsonUtil.get_int(data, "width")
	var h := JsonUtil.get_int(data, "height")
	if int(p[0]) == w - 1:
		return Vector2i(1, 0)
	if int(p[0]) == 0:
		return Vector2i(-1, 0)
	if int(p[1]) == 0:
		return Vector2i(0, -1)
	return Vector2i(0, 1) if int(p[1]) == h - 1 else Vector2i.ZERO
