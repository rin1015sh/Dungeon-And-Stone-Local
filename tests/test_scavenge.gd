extends TestCase
## 균열 장식 뒤지기(RF19): 장식 옆에서 살피면 그 균열 표의 잡템(또는 빈손), 한 칸은 한 번, 균열을 나가도 남는다.


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.pool.fill_all()
	return pc


func _rift(rift: String, seed_value: int = 3) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value)), _pc(), GameClock.new(), Rng.new(seed_value + 2), reg.effects)
	s.monsters_enabled = false
	s.start()
	s.rifts.force_open(s, rift, s.pos)
	return s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])


## 장식 칸 옆에 설 수 있는 바닥 칸들 [[장식, 설 자리], …].
func _spots(cs: ExploreSession) -> Array:
	var out: Array = []
	for y in cs.map.height:
		for x in cs.map.width:
			var p := Vector2i(x, y)
			var d := cs.map.def_at(p)
			if d == null or d.scavenge.is_empty():
				continue
			for k in FloorMap.DIRS4:
				if cs.map.is_walkable(p + k):
					out.append([p, p + k])
					break
	return out


func test_every_rift_has_scavenge_spots() -> void:
	for rift in ["rift_blood_fortress", "rift_glacier_cave", "rift_green_mine", "rift_iron_tomb"]:
		var cs := _rift(rift)
		assert_true(_spots(cs).size() >= 3, "%s 1챕터에 뒤질 장식 %d곳" % [rift, _spots(cs).size()])


func test_search_once_and_keep_items() -> void:
	var cs := _rift("rift_blood_fortress")
	var table: Array = JsonUtil.get_array(db.get_entry("scavenge", "fortress_stores"), "items").map(func(e: Variant) -> String: return str((e as Dictionary)["item"]))
	var got := 0
	var searched := 0
	for sp: Array in _spots(cs):
		if not cs.relocate(sp[1]):
			continue
		var target := RiftScavenge.target(cs)
		if target.x < 0:
			continue
		assert_true(RiftScavenge.run(cs))
		assert_true(cs.scavenged.has(target), "뒤진 칸으로 남는다")
		assert_true(RiftScavenge.target(cs) != target, "같은 칸은 다시 뒤지지 않는다")
		searched += 1
		if searched >= 12:
			break
	for id: String in table:
		got += cs.player.inventory.count(id)
	assert_true(searched >= 6, "여러 곳을 뒤졌다(%d)" % searched)
	assert_true(got >= 1 and got <= searched, "잡템 %d개 / %d곳" % [got, searched])
	var keep := got
	cs.rift_run.finish()
	var after := 0
	for id: String in table:
		after += cs.rift_run.outer.player.inventory.count(id)
	assert_eq(after, keep, "균열을 나가도 잡템은 가방에 남는다(팔 수 있다)")


func test_junk_is_sellable_misc() -> void:
	for t: String in db.get_collection("scavenge"):  # 균열 장식 표만 남았다(도시 가구 뒤지기 CT74는 실내와 함께 지웠다 — 2026-11-02)
		for e: Variant in JsonUtil.get_array(db.get_entry("scavenge", t), "items"):
			var it := db.get_entry("items", str((e as Dictionary)["item"]))
			assert_eq(JsonUtil.get_str(it, "category"), "misc", str(e))
			assert_true(JsonUtil.get_int(it, "price") > 0, "값이 있다")
			assert_true(JsonUtil.get_str(it, "rift_bound").is_empty(), "균열 밖으로 가져갈 수 있다")
			assert_false(it.has("use"), "쓸 수 없다")
