extends TestCase
## 한 칸 저장(SaveGame): 차원광장에서 남긴 탐험가·도시를 그대로 되살리는가.

const PATH := "user://dungeon_and_stone/test_save.json"


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "기록", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func test_round_trip_restores_explorer_and_city() -> void:
	var pc := _pc()
	pc.inventory.add("leftovers", 2)
	pc.inventory.add_money(123)
	pc.pool.modify("hp", -17.0)
	pc.fatigue.set_value(55.0)
	pc.progression.exp_total = Progression.exp_for_level(db, 3)
	pc.set_level(3)
	var city := CityState.new(db, 5)
	city.start()
	city.month = 4
	city.period = 2
	city.ap = 0
	city.bank_balance = 900
	city.temple_merit = 40.0
	city.expedition_month = 4
	var rifts := RiftCalendar.new(db)
	rifts.months_since_open = 2
	assert_true(SaveGame.write(SaveGame.capture(pc, city, rifts, 777, 3), PATH), "쓰기")
	var data := SaveGame.read(PATH)
	assert_false(data.is_empty(), "읽기")
	var back := SaveGame.restore_player(db, data)
	assert_eq([back.display_name, back.race_id, back.class_id], ["기록", "human", "warrior"])
	assert_eq(back.get_level(), 3, "레벨")
	assert_eq(back.inventory.money, pc.inventory.money, "소지금")
	assert_eq(back.inventory.count("leftovers"), 2, "가방")
	assert_near(back.pool.get_current("hp"), pc.pool.get_current("hp"), 0.01, "생명력")
	assert_near(back.fatigue.value, 55.0, 0.01, "피로도")
	assert_true(back.stats.has_source(PlayerCharacter.FATIGUE_SOURCE), "피로도 단계 효과도 다시 붙는다")
	assert_eq(back.equipment.to_dict(), pc.equipment.to_dict(), "장비")
	var c2 := CityState.new(db, 1)
	c2.start()
	c2.load_dict(JsonUtil.get_dict(data, "city"))
	assert_eq([c2.month, c2.period, c2.bank_balance, c2.expedition_month], [4, 2, 900, 4], "도시")
	assert_eq(JsonUtil.get_int(JsonUtil.get_dict(data, "game"), "master_seed"), 777)
	SaveGame.delete(PATH)
	assert_false(SaveGame.exists(PATH), "지우기")


func test_broken_or_old_save_is_ignored() -> void:
	DirAccess.make_dir_recursive_absolute(PATH.get_base_dir())
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{\"version\": 0}")
	f.close()
	assert_false(SaveGame.exists(PATH), "버전이 다르면 없는 것으로")
	f = FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("not json")
	f.close()
	assert_true(SaveGame.read(PATH).is_empty(), "깨진 파일")
	SaveGame.delete(PATH)
