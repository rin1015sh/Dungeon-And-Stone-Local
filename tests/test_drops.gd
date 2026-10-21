extends TestCase
## 전투 장면에서 줍는 드롭(DropPickup — ASSUMPTIONS UI13): 쓰러진 순서대로 굴린 드롭, 받기(정수 흡수·가방), 두고 가기(사라진다).


func _pc(d: GameDatabase) -> PlayerCharacter:
	return PlayerCharacter.create(d, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 5})


func _db_all_drops() -> GameDatabase:
	var d := GameDatabase.new()
	d.load_all("res://data")
	(d.singletons["balance"]["loot"] as Dictionary)["magic_stone_chance"] = 1.0
	return d


func test_roll_keeps_slot_order() -> void:
	var d := _db_all_drops()
	var killed: Array[String] = ["goblin", "blade_wolf"]
	var drops := DropPickup.roll(d, killed, Rng.new(4))
	assert_true(drops.size() >= 2, "마석 둘")
	assert_eq(int(drops[0]["slot"]), 0, "첫 드롭은 첫 몬스터 자리")
	assert_eq(int(drops[drops.size() - 1]["slot"]), 1, "마지막 드롭은 둘째 몬스터 자리")
	assert_eq(str(drops[0]["kind"]), "item")


func test_grant_without_drops_gives_exp_only() -> void:
	var d := _db_all_drops()
	var pc := _pc(d)
	var killed: Array[String] = ["goblin"]
	Rewards.grant(pc, killed, Rng.new(2), -1.0, false, 1.0, [], false)
	assert_eq(pc.progression.exp_total, 1, "공적은 준다")
	assert_eq(pc.inventory.count("magic_stone_9"), 0, "전리품은 전투 장면에서 줍는다")


func test_take_item_and_essence() -> void:
	var d := _db_all_drops()
	var pc := _pc(d)
	var stone := {"kind": "item", "id": "magic_stone_9", "count": 2, "slot": 0}
	assert_eq(DropPickup.check(stone, pc), "", "누구나 주울 수 있다")
	var m := DropPickup.take(stone, pc)
	assert_eq(str(m["key"]), "reward.loot_by")
	assert_eq(pc.inventory.count("magic_stone_9"), 2, "가방에")
	var ess := {"kind": "essence", "inst": EssenceDrop.make(d, "goblin", "", Rng.new(1)), "slot": 0}
	assert_eq(DropPickup.check(ess, pc), "", "빈 슬롯이 있으면 흡수할 수 있다")
	assert_eq(str(DropPickup.take(ess, pc)["key"]), "reward.essence_absorbed")
	assert_true(pc.essences.has_essence("goblin"), "흡수했다")
	assert_eq(DropPickup.check(ess, pc), "essence.reason_no_slot", "레벨 1 — 슬롯이 다 찼다")
	pc.set_level(3)
	assert_eq(DropPickup.check(ess, pc), "essence.reason_duplicate", "슬롯이 남아도 같은 정수는 또 받을 수 없다")


func test_leave_drops_vanish() -> void:
	var d := _db_all_drops()
	var pc := _pc(d)
	var ess := {"kind": "essence", "inst": EssenceDrop.make(d, "goblin", "", Rng.new(1)), "slot": 0}
	assert_eq(str(DropPickup.leave(d, ess)["key"]), "reward.essence_left")
	assert_eq(str(DropPickup.leave(d, ess, "essence.reason_no_slot")["key"]), "reward.essence_nobody", "아무도 못 받으면 이유와 함께 흩어진다")
	assert_true(pc.essences.absorbed.is_empty(), "두고 간 정수는 남지 않는다")
	var stone := {"kind": "item", "id": "magic_stone_9", "count": 1, "slot": 0}
	assert_eq(str(DropPickup.leave(d, stone)["key"]), "reward.loot_left")
	assert_eq(pc.inventory.count("magic_stone_9"), 0, "두고 간 전리품은 사라진다")


func test_bag_full_reports_left_count() -> void:
	var d := _db_all_drops()
	var pc := _pc(d)
	pc.inventory = Inventory.new(d, 1, 1)
	pc.inventory.add("ration")
	var stone := {"kind": "item", "id": "magic_stone_9", "count": 1, "slot": 0}
	assert_false(DropPickup.fits(stone, pc), "자리 없음")
	var m := DropPickup.take(stone, pc)
	assert_eq(str(m["key"]), "reward.bag_full")
	assert_eq(int(m["left"]), 1, "넘친 수")


## 처치 드롭(사용자 결정 2026-10-21): 일반 몬스터는 마석(등급) 하나뿐 — 잡템 없음. 정수는 따로 확률. 예외는 균열 열쇠(지휘관 데드맨의 뿔피리)·계층군주 보상.
func test_kill_drops_are_magic_stone_only() -> void:
	for id: String in db.get_collection("monsters"):
		var def := db.get_entry("monsters", id)
		if JsonUtil.get_str(def, "rank") == "lord":
			continue  # 계층군주 보상(lord_drops)은 따로 — test_lord.test_lord_rewards
		var drops := Loot.roll(db, id, Rng.new(7))
		var stones := drops.filter(func(d: Dictionary) -> bool: return str(d["id"]).begins_with("magic_stone_"))
		if def.has("magic_stone_grade"):
			assert_eq(stones.size(), 1, id + ": 마석은 늘 하나")
			assert_eq(str(stones[0]["id"]), "magic_stone_%d" % JsonUtil.get_int(def, "magic_stone_grade"), id + ": 그 등급 마석")
		for d: Dictionary in drops:
			if not str(d["id"]).begins_with("magic_stone_"):
				assert_false(JsonUtil.get_str(db.get_entry("items", str(d["id"])), "rift_bound").is_empty(), id + ": 잡템 없음 — " + str(d["id"]))
