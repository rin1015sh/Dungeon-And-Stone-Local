extends TestCase
## 레벨 디자인 개선(LD — docs/plans/level_design_review.md): 흔적이 가리키는 곳(FieldClues) · 1층 고블린 봉화대(RouteWatch 요소 망루) ·
## 다른 종이 끼어드는 자리(지키는 무리) · 몬스터도 덫에 걸린다(MonsterSnares) · 데스나이트 징조(GraveWake omens) · 밤에만 우는 종.

var _reg: ContentRegistries


func _f1(monsters: bool, seed_value: int = 5) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var s := ExploreSession.new(db, def, _reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), _reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _f2(id: String, monsters: bool, seed_value: int = 4) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var def := db.get_entry("floors", id)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, _reg.generator("fields").generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), _reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _feats(s: ExploreSession, id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in s.features.list:
		if str(e["id"]) == id:
			out.append(e)
	return out


func test_floor1_arms_have_their_own_clues() -> void:
	var s := _f1(false)
	var zone_of := {"wolf_tracks": "east", "wolf_kill": "east", "gnome_marks": "west", "raided_stash": "west",
		"carrion_heap": "south", "rot_carcass": "south", "goblin_lookout": "north", "goblin_kennel": "north"}
	for id: String in zone_of:
		var list := _feats(s, id)
		assert_true(not list.is_empty(), "%s가 놓였다" % id)
		for e in list:
			assert_eq(s.map.zone_at(e["pos"]), zone_of[id], "%s는 제 구역" % id)
	for e in _feats(s, "carrion_heap"):
		assert_true(s.map.is_dark(e["pos"]), "썩은 고기 무더기는 깊은 곳(암흑지대 어귀)")


func test_wolf_tracks_point_to_den() -> void:
	var s := _f1(false)
	var tracks := _feats(s, "wolf_tracks")
	var found := false
	for tr in tracks:
		var den := FieldClues.nearest(s, tr["pos"], "wolf_den", 70.0)
		if den.is_empty():
			continue
		var dp: Vector2i = den["pos"]
		s.map.explored[s.map.idx(dp)] = 0
		s.features.act(s, tr["pos"], "follow")
		assert_eq(int(s.map.explored[s.map.idx(dp)]), 1, "발자국을 짚으면 늑대 굴 둘레가 밝혀진다")
		found = true
		break
	assert_true(found, "늑대 굴을 가리키는 발자국이 하나는 있다")


func test_gnome_marks_reveal_hidden_stash() -> void:
	var s := _f1(false)
	var hit := false
	for m in _feats(s, "gnome_marks"):
		var st := FieldClues.nearest(s, m["pos"], "gnome_stash", 45.0)
		if st.is_empty():
			continue
		assert_false(bool(st["found"]), "은닉처는 숨어 있다")
		s.features.act(s, m["pos"], "look")
		assert_true(bool(st["found"]), "돌 표지를 살피면 은닉처가 드러난다")
		hit = true
		break
	assert_true(hit, "은닉처를 가리키는 돌 표지가 하나는 있다")


func test_intruders_guard_story_spots() -> void:
	var s := _f1(true)
	for pair: Array in [["wolf_kill", "ghoul"], ["raided_stash", "goblin"], ["rot_carcass", "blade_wolf"], ["goblin_kennel", "blade_wolf"]]:
		var at: Vector2i = _feats(s, pair[0])[0]["pos"]
		var near := s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool:
			return Vector2(g.home - at).length() <= 3.0 and g.leader() == pair[1])
		assert_true(not near.is_empty(), "%s를 %s가 지킨다(다른 종이 끼어드는 자리)" % pair)
	s.detach()


func test_goblin_lookout_alarm_is_local() -> void:
	var s := _f1(true)
	assert_true(s.watch != null and s.watch.towers().size() >= 4, "1층 북쪽 봉화대 넷")
	var t: Dictionary = s.watch.towers()[0]
	var at: Vector2i = t["at"]
	assert_true(t["guard"] != null and (t["guard"] as FieldMonsters.Group).guard, "망꾼은 제자리에서 둘러본다")
	var near := s.monsters.add_fixed(["goblin"], at + Vector2i(0, 6))
	var far := s.monsters.add_fixed(["goblin"], at + Vector2i(0, 60)) if s.map.in_bounds(at + Vector2i(0, 60)) else null
	s.map.visible_now[s.map.idx(at)] = 1
	s.watch.on_enter(s, at + Vector2i(0, 4))
	assert_true(near != null and near.alert_until > s.clock.total_hours, "둘레 고블린이 쫓아온다")
	if far != null and Vector2(far.pos - at).length() > 35.0:
		assert_true(far.alert_until < s.clock.total_hours, "먼 고블린은 듣지 못한다")
	s.detach()


func test_chasing_monster_springs_snare() -> void:
	var s := _f2("f2_goblin_forest", true, 5)
	var cells: Array = s.features.hazards.at.keys()
	assert_true(not cells.is_empty(), "덫 묶음이 깔렸다")
	var c: Vector2i = cells[0]
	var hd: Dictionary = s.features.hazards.at[c]
	assert_true(hd.has("snares_monsters"), "숲 덫은 몬스터도 잡는다")
	var g := s.monsters.add_fixed(["goblin"], c)
	assert_true(g != null)
	g.place(c)
	g.state = FieldMonsters.STATE_IDLE
	assert_eq(MonsterSnares.update(s), 0, "순찰하는 무리는 제 덫을 안다")
	g.state = FieldMonsters.STATE_CHASE
	assert_eq(MonsterSnares.update(s), 1, "쫓다가 덫을 밟는다")
	assert_true(g.held_until > s.clock.total_hours, "덫에 묶였다")
	assert_false(s.features.hazards.at.has(c), "터진 덫은 다시 판정하지 않는다")
	var before := g.fpos
	s.monsters.update(s.fpos, 0.05, s.clock.total_hours, false)
	assert_eq(g.fpos, before, "묶인 동안 걷지 못한다")
	s.detach()


func test_grave_omens_by_day() -> void:
	var s := _f2("f2_land_of_dead", true)
	assert_true(s.grave != null and s.grave.pos.x >= 0)
	var corpses := _feats(s, "explorer_corpse").size()
	s.clock.advance(2.0 * 24.0 + 1.0)  # 3일 차
	s.grave.update(s)
	assert_eq(_feats(s, "explorer_corpse").size(), corpses + 1, "3일 차 — 새 시체")
	assert_eq(FieldClues.day_key(s, "field.grave_stone"), "field.grave_stone_d3", "비석 문구가 날마다 다르다")
	s.clock.advance(24.0)  # 4일 차
	s.grave.update(s)
	var wisp := false
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			wisp = wisp or s.map.tile_id_at(s.grave.pos + Vector2i(dx, dy)) == "f2d_wisp"
	assert_true(wisp, "4일 차 — 비석 곁 푸른 불")
	s.detach()


func test_night_bell_only_at_night() -> void:
	var s := _f2("f2_land_of_dead", false)
	var b: Dictionary = _feats(s, "bell_night")[0]
	s.pass_time(fposmod(12.0 - s.clock.hour_of_day(), 24.0))
	s.features.act(s, b["pos"], "ring")
	assert_eq(s.goal.count, 0, "낮에는 울지 않는다")
	s.pass_time(fposmod(22.0 - s.clock.hour_of_day(), 24.0))
	s.features.act(s, b["pos"], "ring")
	assert_eq(s.goal.count, 1, "밤에는 운다")


## 전투 지형(LD6): 진창 · 물에 선 쪽은 느려지고(구울은 진창에 익숙하다), 둔덕 위는 유리, 좁은 다리에선 적이 둘씩만 선다.
func test_battle_terrain() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["ghoul", "goblin"])
	BattleTerrain.apply(b, "f2d_mud", "f2d_mud")
	assert_true(pc.statuses.has("mired"), "진창에 선 플레이어는 진창 상태")
	for u in b.side_units(Combatant.SIDE_ENEMY):
		var ghoul := (u.actor as Monster).id == "ghoul"
		assert_eq(u.actor.statuses.has("mired"), not ghoul, "구울(mud_walker)만 진창을 타지 않는다: %s" % (u.actor as Monster).id)
	assert_true(pc.statuses.clear_temporary().has("mired"), "전투가 끝나면 풀린다")
	var b2 := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["goblin"])
	BattleTerrain.apply(b2, "f2d_mound", "f2d_hard")
	assert_true(pc.statuses.has("high_ground"), "둔덕 위 = 높은 자리")
	assert_false(b2.side_units(Combatant.SIDE_ENEMY)[0].actor.statuses.has("high_ground"), "아래의 적은 아니다")
	pc.statuses.clear_temporary()
	assert_eq(BattleTerrain.cap(db, "f2g_plank", "f2g_floor"), 2, "다리 위 — 적은 둘씩")
	assert_eq(BattleTerrain.cap(db, "f2g_floor", "f2g_floor"), 0, "그냥 숲 바닥은 제한 없음")
	var five := ["goblin", "goblin", "goblin", "goblin", "goblin"]
	var b3 := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, five, Battle.FIRST_NONE, 2)
	assert_eq(b3.side_units(Combatant.SIDE_ENEMY).size(), 2, "둘만 선다")
	assert_eq(b3.horde.size(), 3, "나머지 셋은 예비대")


## 망자의 땅 예배당(LD7): 긴 의자 줄 사이 가운데 통로, 종탑에 오르면 둘레 지도.
func test_chapel_pews_and_tower() -> void:
	var s := _f2("f2_land_of_dead", false)
	var c: Vector2i = s.map.anchors["nodes"]["chapel"]
	var pews := 0
	for dy in range(-19, 6):
		for dx in range(-11, 12):
			if s.map.tile_id_at(c + Vector2i(dx, dy)) == "f2d_pew":
				pews += 1
	assert_true(pews >= 40, "예배당 안 긴 의자 줄: %d칸" % pews)
	assert_true(s.map.is_walkable(c), "가운데 통로는 걷는다")
	var t := _feats(s, "tower_stairs")
	assert_eq(t.size(), 1, "종탑 계단")
	var far: Vector2i = (t[0]["pos"] as Vector2i) + Vector2i(30, 0)
	s.map.explored[s.map.idx(far)] = 0
	s.features.act(s, t[0]["pos"], "climb")
	assert_eq(int(s.map.explored[s.map.idx(far)]), 1, "종탑에 오르면 30칸 밖도 밝혀진다")
	s.detach()


## 엄폐(LD8): 묘비 · 긴 의자 옆에 서 있으면 숨는다(장례 행렬을 지나보낸다), 움직이면 풀린다.
func test_cover_hides_when_still() -> void:
	var s := _f2("f2_land_of_dead", false)
	var spot := Vector2i(-1, -1)
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if s.map.tile_id_at(p) == "f2d_pew" and s.map.is_walkable(p + Vector2i.DOWN):
			spot = p + Vector2i.DOWN
			break
	assert_true(spot.x >= 0 and s.relocate(spot), "긴 의자 옆")
	s.last_move_hours = s.clock.total_hours
	assert_false(FieldStealth.in_cover(s), "움직이는 중엔 숨지 못한다")
	assert_eq(FieldStealth.of(s), 0.0)
	s.clock.advance(0.1)
	assert_true(FieldStealth.in_cover(s), "서 있으면 숨는다")
	assert_near(FieldStealth.of(s), float(db.bal("explore.cover_stealth")), 0.001, "엄폐만큼 알아채는 반경이 준다")
	s.detach()


func _rift(rift_id: String, chapter: int) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	var s := ExploreSession.new(db, def, _reg.generator("crystal_cave").generate(db, def, Rng.new(3)), pc, GameClock.new(), Rng.new(5), _reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift_id, s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	return cs if chapter == 0 else cs.rift_run.build_chapter(chapter)


## 균열 장치(LD10): 강철의 묘 벽화 → 복도 함정이 드러난다 · 빙하굴 얼음을 깨면 길이 열린다 · 탄광 버팀목을 차면 둘레 무리가 깔린다.
func test_rift_set_pieces() -> void:
	var it := _rift("rift_iron_tomb", 0)
	var mural := _feats(it, "tomb_mural")
	assert_eq(mural.size(), 1, "벽화")
	var hidden_before := 0
	for q: Vector2i in it.rift_run.hazards.at:
		if JsonUtil.get_bool(it.rift_run.hazards.at[q], "hidden") and not bool(it.rift_run.hazards.at[q].get("detected", false)):
			hidden_before += 1
	assert_true(hidden_before > 0, "복도에 숨은 함정")
	it.features.act(it, mural[0]["pos"], "read")
	var still := 0
	for q: Vector2i in it.rift_run.hazards.at:
		if JsonUtil.get_bool(it.rift_run.hazards.at[q], "hidden") and not bool(it.rift_run.hazards.at[q].get("detected", false)):
			still += 1
	assert_eq(still, 0, "벽화를 보면 숨은 함정이 모두 드러난다")
	var gc := _rift("rift_glacier_cave", 1)
	var ice := _feats(gc, "frozen_explorer")
	assert_eq(ice.size(), 2, "얼음에 갇힌 형체 둘")
	var at: Vector2i = ice[0]["pos"]
	assert_false(gc.map.is_walkable(at))
	for tries in 30:
		gc.features.act(gc, at, "break")
		if gc.map.is_walkable(at):
			break
	assert_true(gc.map.is_walkable(at), "깨면 얼음 칸이 열린다")
	var gm := _rift("rift_green_mine", 1)
	var sup := _feats(gm, "mine_support")
	assert_eq(sup.size(), 2, "버팀목 둘")
	gm.monsters_enabled = true
	var sp: Vector2i = sup[0]["pos"]
	var g := gm.monsters.add_fixed(["goblin_miner"], sp + Vector2i(-3, 0))
	assert_true(g != null)
	gm.features.act(gm, sp, "kick")
	assert_true(g.held_until > gm.clock.total_hours, "무너진 천장에 깔렸다")
	assert_eq(gm.map.tile_id_at(sp), "gm_rock", "버팀목 자리는 돌무더기")
