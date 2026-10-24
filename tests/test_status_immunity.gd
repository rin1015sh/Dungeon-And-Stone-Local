extends TestCase
## 보스마다 몇 가지 상태이상 면역(UI25)과 상태 아이콘 3개씩 넘기기(StatusIcons).


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 12, "p_res": 12, "m_res": 8, "int": 10})
	pc.pool.fill_all()
	return pc


## 보스마다 몇 가지만(1층 균열 보스 2~3 · 중간 보스 1~2 · 계층군주 5) — 나머지 상태는 그대로 걸린다.
func test_bosses_have_a_few_immunities() -> void:
	var pc := _pc()
	var limits := {"midboss": [1, 2], "guardian": [2, 3], "variant_guardian": [2, 3], "lord": [4, 6]}
	for id: String in db.get_collection("monsters"):
		var m := Monster.create(db, id, "대상")
		var rank := JsonUtil.get_str(m.def, "rank")
		var imm := JsonUtil.get_array(m.def, "status_immune")
		if not limits.has(rank):
			continue
		var lim: Array = limits[rank]
		assert_true(imm.size() >= int(lim[0]) and imm.size() <= int(lim[1]), "%s(%s) 면역 %d개" % [id, rank, imm.size()])
		for sid: Variant in imm:
			assert_eq(Passives.try_status(db, null, pc, m, str(sid)), "immune", id + " → " + str(sid))
		for sid in ["stun", "marked"]:
			if not imm.has(sid):
				assert_eq(Passives.try_status(db, null, pc, m, sid), "", id + "에게 " + sid + "는 걸린다")


func test_lord_has_more_than_rift_bosses() -> void:
	var lord := JsonUtil.get_array(db.get_entry("monsters", "dreadfear"), "status_immune").size()
	for id in ["blater", "king_slime", "ildium", "tarunbas", "kirdui", "kambormir"]:
		assert_true(lord > JsonUtil.get_array(db.get_entry("monsters", id), "status_immune").size(), id)


func test_icons_page_three_at_a_time() -> void:
	var pc := _pc()
	var icons := StatusIcons.new()
	for sid in ["poison", "bleeding", "stun", "marked", "frost"]:
		pc.statuses.apply(sid)
	assert_true(icons.show_for(pc))
	assert_eq(icons.page_count(), 2)
	assert_eq(icons.shown(), 3)
	icons._process(_sec() + 0.01)
	assert_eq(icons.shown(), 2, "다음 쪽")
	icons._process(_sec() + 0.01)
	assert_eq(icons.shown(), 3, "처음으로 돌아온다")
	pc.statuses.remove("frost")
	pc.statuses.remove("marked")
	icons.show_for(pc)
	assert_eq(icons.page_count(), 1)
	icons._process(_sec() + 0.01)
	assert_eq(icons.modulate.a, 1.0, "한 쪽이면 깜빡이지 않는다")
	icons.free()


func _sec() -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(JsonUtil.get_dict(db.render, "ui"), "combat_status_icon"), "page_sec", 1.8)
