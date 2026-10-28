extends TestCase
## 귀환 정산(CT58 — GuildSettle): 마석을 등급별로 세어 price × settle.ratio 스톤으로 바꾼다. 마석이 아닌 물건은 그대로.


func test_settles_magic_stones_by_grade() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "정산", {"str": 8, "agi": 8, "p_res": 8, "m_res": 8, "int": 8})
	var inv := pc.inventory
	inv.add("magic_stone_9", 4)
	inv.add("magic_stone_7", 1)
	var potions := inv.count("minor_potion") + 2
	inv.add("minor_potion", 2)
	var lots := GuildSettle.lots(db, pc)
	assert_eq(lots.map(func(l: Dictionary) -> int: return int(l["grade"])), [9, 7], "흔한 등급부터")
	assert_eq(int(lots[0]["count"]), 4)
	var ratio := float(JsonUtil.get_dict(db.singletons.get("city", {}), "settle").get("ratio", 1.0))
	var want := roundi(JsonUtil.get_float(db.get_entry("items", "magic_stone_9"), "price") * ratio) * 4 \
		+ roundi(JsonUtil.get_float(db.get_entry("items", "magic_stone_7"), "price") * ratio)
	var before := inv.money
	assert_eq(GuildSettle.settle(db, pc), want, "받은 스톤")
	assert_eq(inv.money, before + want)
	assert_true(GuildSettle.lots(db, pc).is_empty(), "마석은 모두 넘겼다")
	assert_eq(inv.count("minor_potion"), potions, "다른 물건은 그대로")
	assert_eq(GuildSettle.explorer_grade(db, pc), 9, "처음은 9등급 탐험가")
	assert_eq(pc.progression.settled_total, want, "정산 누계")


## 탐험가 등급(CT59): 정산 누계와 레벨이 차면 한 등급씩 오르고, 오른 등급은 정산 값을 올리고 저장된다.
func test_explorer_grade_rises_with_settled_total_and_level() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "승급", {"str": 8, "agi": 8, "p_res": 8, "m_res": 8, "int": 8})
	var nxt := GuildSettle.next_grade(db, pc)
	assert_eq(JsonUtil.get_int(nxt, "grade"), 8)
	pc.progression.settled_total = JsonUtil.get_int(nxt, "settled") - 1
	pc.set_level(JsonUtil.get_int(nxt, "level"))
	assert_eq(GuildSettle.promote(db, pc), 0, "누계가 모자라면 그대로")
	pc.progression.settled_total += 1
	pc.set_level(JsonUtil.get_int(nxt, "level") - 1)
	assert_eq(GuildSettle.promote(db, pc), 0, "레벨이 모자라면 그대로")
	pc.set_level(JsonUtil.get_int(nxt, "level"))
	var before := GuildSettle.bonus(db, pc)
	pc.inventory.add("magic_stone_9", 10)
	var each9 := int(GuildSettle.lots(db, pc)[0]["each"])
	assert_eq(GuildSettle.promote(db, pc), 8, "둘 다 차면 8등급")
	assert_eq(GuildSettle.explorer_grade(db, pc), 8)
	assert_true(GuildSettle.bonus(db, pc) > before and int(GuildSettle.lots(db, pc)[0]["each"]) >= each9, "등급이 오르면 정산 값도 오른다")
	pc.progression.settled_total = 1 << 30
	pc.set_level(11)
	assert_eq(GuildSettle.promote(db, pc), 7, "한 번에 한 등급만")
	var copy := Progression.new()
	copy.load_dict(JSON.parse_string(JSON.stringify(pc.progression.to_dict())))
	assert_eq([copy.explorer_grade, copy.settled_total], [7, 1 << 30], "저장 왕복")
	for g in range(6, 0, -1):
		GuildSettle.promote(db, pc)
	assert_eq(GuildSettle.explorer_grade(db, pc), 1, "1등급까지")
	assert_true(GuildSettle.next_grade(db, pc).is_empty() and GuildSettle.promote(db, pc) == 0, "1등급 위는 없다")
