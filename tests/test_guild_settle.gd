extends TestCase
## 귀환 정산(CT58 — GuildSettle): 마석을 등급별로 세어 price × settle.ratio 스톤으로 바꾼다. 마석이 아닌 물건은 그대로.


func test_settles_magic_stones_by_grade() -> void:
	var pc := PlayerCharacter.create(db, "human", "warrior", "정산", {"str": 8, "agi": 8, "p_res": 8, "m_res": 8, "int": 8})
	var inv := pc.inventory
	inv.add("magic_stone_9", 4)
	inv.add("magic_stone_7", 1)
	var potions := inv.count("minor_potion") + 2
	inv.add("minor_potion", 2)
	var lots := GuildSettle.lots(db, inv)
	assert_eq(lots.map(func(l: Dictionary) -> int: return int(l["grade"])), [9, 7], "흔한 등급부터")
	assert_eq(int(lots[0]["count"]), 4)
	var ratio := float(JsonUtil.get_dict(db.singletons.get("city", {}), "settle").get("ratio", 1.0))
	var want := roundi(JsonUtil.get_float(db.get_entry("items", "magic_stone_9"), "price") * ratio) * 4 \
		+ roundi(JsonUtil.get_float(db.get_entry("items", "magic_stone_7"), "price") * ratio)
	var before := inv.money
	assert_eq(GuildSettle.settle(db, inv), want, "받은 스톤")
	assert_eq(inv.money, before + want)
	assert_true(GuildSettle.lots(db, inv).is_empty(), "마석은 모두 넘겼다")
	assert_eq(inv.count("minor_potion"), potions, "다른 물건은 그대로")
	assert_eq(GuildSettle.explorer_grade(db), 9, "지금은 모두 9등급 탐험가")
