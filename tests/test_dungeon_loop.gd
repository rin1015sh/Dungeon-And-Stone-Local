extends TestCase
## 미궁 반복 루프(2026-10-22, docs/plans/dungeon_loop_review.md): 지식이 남는 전투(UI22) · 돈 단위(CT43) · 길드 조사 의뢰(CT44).


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _state(seed_value: int = 5) -> CityState:
	var s := CityState.new(db, seed_value)
	s.start()
	return s


func _investigate(pc: PlayerCharacter, m: Monster) -> void:
	var h: EffectHandler = load("res://src/combat/effects/investigate.gd").new()
	h.apply(EffectContext.new(db, pc, m, Rng.new(1)), {"type": "investigate"})


func test_party_knowledge_for_the_stage() -> void:
	var a := _pc()
	var b := _pc()
	var ks: Array[Knowledge] = [a.knowledge, b.knowledge]
	assert_false(BattleKnowledge.party_knows_stats(ks, "ghoul"), "처음엔 생명력을 모른다")
	b.knowledge.learn_stats("ghoul")
	assert_true(BattleKnowledge.party_knows_stats(ks, "ghoul"), "파티 누군가 조사했으면 보인다")
	a.knowledge.learn_affinity("ghoul", "fire", 1.25)
	b.knowledge.learn_affinity("ghoul", "slash", 1.0)
	var aff := BattleKnowledge.party_affinities(ks, "ghoul")
	assert_eq(aff.size(), 2, "둘의 기록을 합친다")
	var text := BattleKnowledge.describe(db, aff)
	assert_true(text.contains(DataNames.tag(db, "damage_types", "fire")), "약점은 글로")
	assert_false(text.contains(DataNames.tag(db, "damage_types", "slash")), "보통(×1)은 적지 않는다")
	assert_eq(BattleKnowledge.describe(db, {}), "", "모르면 빈칸(무대에 ??? 를 띄우지 않는다)")
	assert_eq(BattleKnowledge.describe_affinities(db, a.knowledge, "goblin"), Strings.t("knowledge.unknown"), "조사 창은 그대로 ???")


func test_investigate_counts_each_monster_once() -> void:
	var pc := _pc()
	var g1 := Monster.create(db, "gnome")
	var g2 := Monster.create(db, "gnome")
	_investigate(pc, g1)
	_investigate(pc, g1)
	assert_eq(pc.knowledge.surveys("gnome"), 1, "같은 몬스터는 한 번만 센다")
	_investigate(pc, g2)
	assert_eq(pc.knowledge.surveys("gnome"), 2)
	assert_true(pc.knowledge.knows_stats("gnome"))
	var k := Knowledge.new()
	k.load_dict(JSON.parse_string(JSON.stringify(pc.knowledge.to_dict())))
	assert_eq(k.surveys("gnome"), 2, "저장 왕복")
	assert_eq(k.seen_ids(), pc.knowledge.seen_ids(), "조사 수가 몬스터 기록으로 섞이지 않는다")


func test_guild_request_rolls_and_lasts() -> void:
	var s := _state()
	var pool := JsonUtil.get_array(CityGuild.config(s), "survey_pool")
	var first := CityGuild.target(s)
	assert_true(pool.has(first), "의뢰는 풀에서")
	var until := JsonUtil.get_int(s.guild_request, "until")
	assert_eq(until, s.month + int(JsonUtil.get_float(CityGuild.config(s), "months")) - 1)
	while s.month <= until:
		assert_eq(CityGuild.target(s), first, "기한까지 같은 의뢰")
		s.next_period()
	assert_true(CityGuild.target(s) != first, "기한이 지나면 다른 종")
	var t := _state()
	var u := _state()
	assert_eq(CityGuild.target(t), CityGuild.target(u), "같은 시드 = 같은 의뢰")


func test_guild_report_pays_and_clears() -> void:
	var s := _state()
	var pc := _pc()
	var id := CityGuild.target(s)
	var other := "goblin" if id != "goblin" else "ghoul"
	assert_eq(int(CityGuild.payout(s, pc)["n"]), 0)
	var money := pc.inventory.money
	assert_eq(int(CityGuild.report(s, pc)["n"]), 0, "센 것이 없으면 넘기지 못한다")
	assert_eq(pc.inventory.money, money)
	assert_false(JsonUtil.get_bool(s.guild_request, "done"))
	for i in CityGuild.cap(s) + 3:
		_investigate(pc, Monster.create(db, id))
	_investigate(pc, Monster.create(db, other))
	var p := CityGuild.report(s, pc)
	assert_eq(int(p["n"]), CityGuild.cap(s), "상한까지만")
	assert_eq(int(p["stones"]), CityGuild.cap(s) * CityGuild.payout_each(s))
	assert_eq(pc.inventory.money, money + int(p["stones"]))
	assert_eq(pc.knowledge.surveys(id) + pc.knowledge.surveys(other), 0, "넘기면 모든 조사 수가 지워진다")
	s.next_period()
	assert_true(CityGuild.target(s) != id, "넘긴 다음 순에 새 의뢰")
	var t := CityState.new(db, 1)
	t.start()
	t.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(t.guild_request, s.guild_request, "저장 왕복")
	assert_true(CityActions.activities_of(s, "guild").has("guild_survey"))


## 돈 단위(CT43): 탐험가 거래 값(9등급 마석 개수)이 도시 값과 크게 어긋나지 않는다 · 히든 피스 한 개가 경제를 끝내지 않는다.
func test_money_units() -> void:
	var stone := CityShop.price(db, "magic_stone_9")
	var ex := JsonUtil.get_dict(db.get_entry("floors", "f1_crystal_cave"), "explorers")
	for t: Variant in JsonUtil.get_array(ex, "trades"):
		var city := CityShop.price(db, JsonUtil.get_str(t, "give")) * JsonUtil.get_int(t, "n", 1)
		var paid := JsonUtil.get_int(t, "price") * stone
		assert_true(paid >= city * 0.5 and paid <= city * 2.0, "거래 %s: %d vs 도시 %d" % [JsonUtil.get_str(t, "give"), paid, city])
	var potion := CityShop.price(db, "minor_potion")
	assert_true(stone * 20 <= potion and stone * 60 >= potion, "9등급 마석 수십 개 = 포션 하나")
	for id in ["green_gem", "necronomicon"]:
		assert_true(CityShop.price(db, id) <= potion * 100, "%s 값이 원정 수십 번 치를 넘지 않는다" % id)
