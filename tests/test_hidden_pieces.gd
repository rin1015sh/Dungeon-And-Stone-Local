extends TestCase
## 히든 피스 §6(2026-10-24 — docs/plans/rift_hidden_pieces.md, RF17): 찾는 법 조건(함정 무발동·부숨·건너뛰기·수수께끼·되돌아가기·
## 피의 대가·힘 판정·하나만 진짜·수호자 뒤) + 1층 어둠 속 수정·공물의 답례 + 도서관 고서 해독.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


func _outer(seed_value: int = 3) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value)), _pc(), GameClock.new(), Rng.new(seed_value + 2), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


## 그 균열 chapter번째(0부터) 챕터 세션.
func _chapter(rift: String, chapter: int, seed_value: int = 3) -> ExploreSession:
	var s := _outer(seed_value)
	s.rifts.force_open(s, rift, s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	for i in chapter:
		cs.rift_run.debug_clear()
		if cs.rift_run.chapter == 2 and rift == "rift_green_mine":
			cs.player.inventory.add("mine_explosive", 1)
		cs = cs.rift_run.use_exit(cs)
	return cs


## 그 히든 피스의 물체 칸(없으면 (-1, -1)).
func _at(cs: ExploreSession, id: String) -> Vector2i:
	for p: Vector2i in cs.rift_run.hidden.at:
		if JsonUtil.get_str(cs.rift_run.hidden.at[p], "id") == id:
			return p
	return Vector2i(-1, -1)


func _hazard(cs: ExploreSession, id: String, how: String) -> void:
	cs.rift_run.hidden.on_hazard(cs, cs.rift_run.chapter, {"id": id}, how)


func test_tomb_oil_needs_no_trap_triggered() -> void:
	var cs := _chapter("rift_iron_tomb", 0)
	var p := _at(cs, "tomb_oil")
	assert_true(p.x >= 0, "벽감이 놓였다")
	_hazard(cs, "plate", "fail")
	assert_true(cs.rift_run.take_hidden(cs, p))
	assert_eq(cs.player.inventory.count("tomb_oil"), 0, "함정이 발동했으면 기름 단지가 깨져 있다")
	var clean := _chapter("rift_iron_tomb", 0, 7)
	_hazard(clean, "plate", "disarm")
	assert_true(clean.rift_run.take_hidden(clean, _at(clean, "tomb_oil")))
	assert_eq(clean.player.inventory.count("tomb_oil"), 1, "함정을 하나도 발동시키지 않았다")
	clean.rift_run.finish()
	assert_eq(clean.player.inventory.count("tomb_oil"), 1, "스탯 영약도 균열 밖으로 가지고 나간다(RF27)")


func test_steel_relic_only_when_blades_crushed() -> void:
	var cs := _chapter("rift_iron_tomb", 1)
	assert_eq(_at(cs, "steel_relic"), Vector2i(-1, -1), "처음엔 숨어 있다")
	_hazard(cs, "blades", "disarm")
	assert_eq(_at(cs, "steel_relic"), Vector2i(-1, -1), "해제하면 홈이 닫힌다")
	var cs2 := _chapter("rift_iron_tomb", 1, 7)
	_hazard(cs2, "blades", "bypass")
	var p := _at(cs2, "steel_relic")
	assert_true(p.x >= 0, "부숴 지나가면 나타난다")
	assert_true(cs2.rift_run.take_hidden(cs2, p))
	assert_eq(cs2.player.inventory.count("steel_relic"), 1)


## 칼날 홈(사용자 2026-11-04): 홈마다 칼날이 실제로 오가고, 닿으면 베인다. 단단하면 칼날이 부러지고 강철 유물이 나온다.
func test_groove_blades_cut_or_break() -> void:
	var cs := _chapter("rift_iron_tomb", 1)
	assert_true(cs.blades != null and cs.blades.runs.size() == 7, "홈 일곱 줄마다 칼날")
	assert_true(cs.rift_run.hazards.at.is_empty(), "바닥에서 튀어나오는 숨은 칼날 함정은 없다")
	(cs.blades.def["bypass"] as Dictionary)["at_least"] = 9999.0  # 이 시험 탐험가는 베인다
	var a := cs.blades.blade_at(0)
	cs.blades.t += 1.6
	assert_true(cs.blades.blade_at(0).distance_to(a) > 0.5, "칼날이 홈을 따라 움직인다")
	assert_eq(cs.blades.blade_at(0).x, a.x, "홈 밖으로 벗어나지 않는다")
	var hp := cs.player.pool.get_current("hp")
	cs.fpos = cs.blades.blade_at(0)
	assert_true(cs.blades.tick(cs, 0.01), "칼날이 지나가는 칸에 서 있으면 베인다")
	assert_true(cs.player.pool.get_current("hp") < hp)
	assert_false(cs.blades.tick(cs, 0.01), "베인 직후엔 다시 베이지 않는다")
	assert_eq(_at(cs, "steel_relic"), Vector2i(-1, -1), "베였으면 유물은 나오지 않는다")
	var cs2 := _chapter("rift_iron_tomb", 1, 7)
	(cs2.blades.def["bypass"] as Dictionary)["at_least"] = 0.0
	cs2.fpos = cs2.blades.blade_at(2)
	cs2.blades.tick(cs2, 0.01)
	assert_true(bool(cs2.blades.runs[2].get("broken", false)), "단단하면 칼날이 부러져 멈춘다")
	assert_true(_at(cs2, "steel_relic").x >= 0, "칼날을 부수면 강철 유물이 나타난다")


func test_coffin_needs_correct_riddle_and_treasure_one_real() -> void:
	var cs := _chapter("rift_iron_tomb", 3)
	var run := cs.rift_run
	var coffin := _at(cs, "death_mask")
	run.riddle.outcome = RiftRiddle.WRONG
	assert_true(run.take_hidden(cs, coffin))
	assert_eq(cs.player.inventory.count("death_mask"), 0, "틀렸으면 관이 열리지 않는다")
	run.riddle.outcome = RiftRiddle.WEAKEN
	assert_true(run.take_hidden(cs, coffin))
	assert_eq(cs.player.inventory.count("death_mask"), 1, "맞혔으면 데스마스크")
	assert_true(JsonUtil.get_float(db.get_entry("items", "death_mask"), "price") > 0.0 and JsonUtil.get_str(db.get_entry("items", "death_mask"), "rift_bound").is_empty(), "팔 수 있고 가지고 나간다")
	var piles: Array[Vector2i] = []
	for i in 3:
		piles.append(_at(cs, "tomb_gold_%d" % (i + 1)))
	var real := str(run.hidden._real["tomb_treasure"])
	for i in run.riddle.hints().size():  # 벽화를 다 읽었다
		cs.player.knowledge.learn_fact(run.riddle._fact(i))
	for i in 3:
		var id := "tomb_gold_%d" % (i + 1)
		assert_true(run.take_hidden(cs, piles[i]))
		assert_eq(cs.player.inventory.count("tomb_gold"), 0, "벽화를 다 읽었으면 먼저 들여다본다")
		if id != real:
			assert_true(run.take_hidden(cs, piles[i]))
			assert_true(cs.player.statuses.has("tomb_curse"), "가짜 더미 = 저주")
	assert_true(run.take_hidden(cs, piles[int(real.trim_prefix("tomb_gold_")) - 1]))
	assert_eq(cs.player.inventory.count("tomb_gold"), 1, "진짜 더미에서 부장품")


func test_fortress_key_backtrack_and_blood_well() -> void:
	var cs := _chapter("rift_blood_fortress", 3)
	var run := cs.rift_run
	assert_true(run.take_hidden(cs, _at(cs, "fortress_key")))
	assert_eq(cs.player.inventory.count("fortress_key"), 1, "4챕터 고문대의 열쇠")
	var c3 := run._go(cs, 2)
	var well := Vector2i(22, 22)
	assert_eq(c3.features.name_at(well), "핏빛 우물")
	var hp_max := c3.player.pool.get_max("hp")
	var hp := c3.player.pool.get_current("hp")
	c3.features.act(c3, well, "pour")
	assert_true(c3.player.pool.get_current("hp") < hp, "피를 부었다")
	assert_eq(c3.player.inventory.count("blood_chalice"), 1, "피의 성배")
	var ctx := EffectContext.new(db, c3.player, c3.player, c3.rng)
	ctx.registry = c3.effects
	ctx.item_id = "blood_chalice"
	c3.effects.apply_all(ctx, JsonUtil.get_array(db.get_entry("items", "blood_chalice"), "use_effects"))
	assert_near(c3.player.pool.get_max("hp"), hp_max + 5.0, 0.01, "생명력 최대치 +5")
	var c2 := run._go(c3, 1)
	var wagon := _at(c2, "silver_chest")
	assert_true(wagon.x >= 0)
	c2.player.inventory.remove("fortress_key", 1)
	assert_true(run.take_hidden(c2, wagon))
	assert_eq(c2.player.inventory.count("silver_chest"), 0, "열쇠가 없으면 잠겨 있다")
	c2.player.inventory.add("fortress_key", 1)
	assert_true(run.take_hidden(c2, wagon))
	assert_eq(c2.player.inventory.count("silver_chest"), 1, "2챕터로 되돌아와 은화 상자")
	assert_eq(c2.player.inventory.count("fortress_key"), 0, "열쇠를 썼다")


func test_glacier_lotus_and_ice_core() -> void:
	var cs := _chapter("rift_glacier_cave", 2)
	var falls := _at(cs, "snow_lotus")
	assert_true(cs.rift_run.take_hidden(cs, falls))
	assert_eq(cs.player.inventory.count("snow_lotus"), 0, "위험을 다 지나지 않았다")
	for id: String in ["slick", "slick", "slope", "rope"]:
		_hazard(cs, id, "pass")
	assert_true(cs.rift_run.take_hidden(cs, falls))
	assert_eq(cs.player.inventory.count("snow_lotus"), 1, "모두 한 번에 지났다")
	var c4 := _chapter("rift_glacier_cave", 3)
	var core := _at(c4, "eternal_ice")
	assert_true(c4.rift_run.take_hidden(c4, core))
	assert_eq(c4.player.inventory.count("eternal_ice"), 0, "수호자가 살아 있다")
	c4.rift_run.guardian_down = true
	assert_true(c4.rift_run.take_hidden(c4, core))
	assert_eq(c4.player.inventory.count("eternal_ice"), 1)


func test_mine_cart_vein_and_two_explosives() -> void:
	var cs := _chapter("rift_green_mine", 0)
	cs.player.stats.set_base("str", 60.0)
	assert_true(cs.rift_run.take_hidden(cs, _at(cs, "mine_heart")))
	assert_eq(cs.player.inventory.count("mine_heart"), 1, "광차를 밀어 숨은 갱도")
	var weak := _chapter("rift_green_mine", 0, 7)
	weak.player.stats.set_base("str", 1.0)
	var cart := _at(weak, "mine_heart")
	assert_true(weak.rift_run.take_hidden(weak, cart))
	assert_eq(weak.player.inventory.count("mine_heart"), 0, "실패")
	assert_false(weak.rift_run.take_hidden(weak, cart), "다시 못 한다")
	var c2 := _chapter("rift_green_mine", 1)
	_hazard(c2, "bridge", "pass")
	assert_true(c2.rift_run.take_hidden(c2, _at(c2, "green_vein")))
	assert_eq(c2.player.inventory.count("green_vein"), 1, "건너뛰어 광맥")
	var c3 := _chapter("rift_green_mine", 2)
	c3.player.inventory.remove("mine_explosive", c3.player.inventory.count("mine_explosive"))
	assert_true(c3.rift_run.take_hidden(c3, _at(c3, "mine_explosive")))
	assert_eq(c3.player.inventory.count("mine_explosive"), 2, "폭약 상자에 두 개")


func test_explosive_burns_slime_and_stops_split() -> void:
	var pc := _pc()
	pc.inventory.add("mine_explosive", 1)
	var party: Array[Actor] = [pc]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["slime"], Combatant.SIDE_PARTY)
	var me := b.next_turn()
	var sl := b.side_units(Combatant.SIDE_ENEMY)[0]
	var hp := sl.actor.pool.get_current("hp")
	assert_true(b.act(me, {"kind": "item", "item": "mine_explosive"}))
	assert_true(sl.actor.dead or sl.actor.pool.get_current("hp") < hp, "슬라임에게 큰 피해")
	if not sl.actor.dead:
		assert_true(sl.actor.statuses.has_flag("no_split"), "그을려 갈라지지 못한다")
		var n := b.side_units(Combatant.SIDE_ENEMY).size()
		BattleSpawns.split(b, sl, {})
		assert_eq(b.side_units(Combatant.SIDE_ENEMY).size(), n)


func test_dark_crystal_only_without_light() -> void:
	var s := _outer()
	var e: Dictionary = {}
	for f: Dictionary in s.features.list:
		if f["id"] == "dark_crystal":
			e = f
	assert_false(e.is_empty(), "고정 지도에 어둠 속 수정")
	assert_true(s.map.is_dark(e["pos"]), "암흑지대 안")
	s.player.light.ignite("torch", 7.0, 5.0)
	s.features.on_step(s, (e["pos"] as Vector2i) + Vector2i(1, 0))
	assert_false(bool(e["found"]), "횃불을 켜고 있으면 그냥 돌")
	s.player.light.hours_left = 0.0
	s.features.on_step(s, (e["pos"] as Vector2i) + Vector2i(1, 0))
	assert_true(bool(e["found"]), "불을 끄면 보인다")
	var sight := s.player.stats.get_base("sight")
	s.features.act(s, e["pos"], "touch")
	assert_near(s.player.stats.get_base("sight"), sight + 5.0, 0.01, "시각 +5 영구")


func test_offering_answer_after_a_day() -> void:
	var s := _outer()
	var e: Dictionary = {}
	for f: Dictionary in s.features.list:
		if f["id"] == "offering_pile":
			e = f
			break
	var at: Vector2i = e["pos"]
	var sr := s.player.stats.get_base("soul_regen")
	s.features.act(s, at, "answer")
	assert_near(s.player.stats.get_base("soul_regen"), sr, 0.01, "바치지 않았으면 아무것도 없다")
	s.player.inventory.add("crystal_mushroom", 3)
	s.features.act(s, at, "offer_mushroom")
	assert_eq(s.player.inventory.count("crystal_mushroom"), 0, "버섯 셋을 바쳤다")
	s.clock.advance(10.0)
	s.features.act(s, at, "answer")
	assert_near(s.player.stats.get_base("soul_regen"), sr, 0.01, "아직 하루가 안 됐다")
	s.clock.advance(15.0)
	s.features.act(s, at, "answer")
	assert_near(s.player.stats.get_base("soul_regen"), sr + 2.0, 0.01, "하루 뒤 답례 — 영혼 재생력 +2")


func test_library_decode_necronomicon() -> void:
	var st := CityState.new(db, 7)
	st.start()
	st.facility = "library"
	var pc := _pc()
	var reg := ContentRegistries.new().city_effects
	assert_eq(CityActions.check(st, pc, "library_decode"), "city.reason_no_item", "책이 없으면 못 한다")
	pc.inventory.add("necronomicon", 1)
	var dark := pc.stats.get_base("resist_dark")
	var ctx := CityActions.perform(st, pc, "library_decode", reg)
	assert_true(ctx.ok)
	assert_eq(pc.inventory.count("necronomicon"), 0, "책을 쓴다(팔 값을 포기)")
	assert_near(pc.stats.get_base("resist_dark"), dark + 3.0, 0.01, "어둠 내성 +3")
	assert_true(pc.knowledge.knows_stats("deadman"), "언데드 조사 기록")
