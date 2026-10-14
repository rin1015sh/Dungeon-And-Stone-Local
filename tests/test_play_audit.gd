extends TestCase
## 플레이 감사(2026-10-14): 로직은 맞는데 플레이에서 어긋나던 것들의 회귀 시험.
## 포션 헛소모 · 독 저항 · 소환 이름 · 본 나이트 정수 색 · 전투 아이템 차례 · 지속 피해 안내 · 봉인 중 대화/조사 · 도발 폴백 · 균열 열쇠.


func _pc() -> PlayerCharacter:
	return PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 10, "agi": 8, "p_res": 9, "m_res": 6, "int": 6})


func _battle(seed_value: int, monsters: Array, pc: PlayerCharacter = null) -> Battle:
	var party: Array[Actor] = [pc if pc != null else _pc()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters, true)


## 플레이어 차례까지 돌린다(적 차례는 AI).
func _player_turn(b: Battle) -> Combatant:
	var c := b.next_turn()
	while c != null and c.side != Combatant.SIDE_PARTY:
		b.act(c, b.ai_action(c))
		c = b.next_turn()
	return c


func test_potion_at_full_hp_is_not_used() -> void:
	var pc := _pc()
	pc.inventory.add("medium_potion", 3)
	for i in 30:
		var ctx := ItemUser.use(ContentRegistries.new().effects, pc, "medium_potion", Rng.new(i))
		assert_false(ctx.success, "생명력이 가득하면 쓰이지 않는다")
	assert_eq(pc.inventory.count("medium_potion"), 3, "소모 없음")
	assert_false(pc.statuses.has("hyperalgesia"), "본 효과가 없으면 부작용도 없다")


func test_poison_resistance_reduces_poison() -> void:
	var weak := _pc()
	var tough := _pc()
	tough.stats.set_base("resist_poison", 60.0)
	assert_true(tough.statuses.resist_chance("poison") > 0.0, "독 저항이 중독을 버틸 확률을 준다")
	for a: PlayerCharacter in [weak, tough]:
		a.statuses.apply("poison")
	var w0 := weak.pool.get_current("hp")
	var t0 := tough.pool.get_current("hp")
	weak.advance_turns(1.0)
	tough.advance_turns(1.0)
	assert_true(t0 - tough.pool.get_current("hp") < w0 - weak.pool.get_current("hp"), "독 저항이 중독 피해를 줄인다")


func test_spawned_monsters_get_letters() -> void:
	var b := _battle(1, ["goblin", "goblin"])
	var c := b.side_units(Combatant.SIDE_ENEMY)[0]
	BattleRules.summon(b, c, {"monster": "goblin"})
	BattleRules.summon(b, c, {"monster": "goblin"})
	var labels := b.side_units(Combatant.SIDE_ENEMY).map(func(u: Combatant) -> String: return u.label())
	assert_eq(labels.size(), 4)
	for i in labels.size():
		for j in range(i + 1, labels.size()):
			assert_true(labels[i] != labels[j], "이름이 겹치지 않는다: %s" % str(labels))


func test_bone_knight_type_sets_essence_color() -> void:
	var m := Monster.create(db, "bone_knight")
	for t: Variant in JsonUtil.get_array(m.def, "types"):
		m.set_meta("monster_type", JsonUtil.get_str(t, "id"))
		assert_eq(BattlePassives.type_essence_color(m), JsonUtil.get_str(t, "essence_color"), "타입이 곧 색")
	var ess := EssenceDrop.make(db, "bone_knight", "blue", Rng.new(1))
	assert_eq(str(ess["color"]), "blue")


func test_useless_item_in_battle_keeps_turn() -> void:
	var pc := _pc()
	pc.inventory.add("medium_potion", 1)
	var b := _battle(2, ["goblin"], pc)
	var c := _player_turn(b)
	assert_true(c != null)
	var turns := b.turns
	assert_false(b.act(c, {"kind": "item", "item": "medium_potion"}), "생명력이 가득하면 차례를 쓰지 않는다")
	assert_eq(b.turns, turns)
	assert_eq(b.current, c, "같은 차례가 이어진다")
	assert_eq(pc.inventory.count("medium_potion"), 1)


func test_damage_over_time_is_reported() -> void:
	var pc := _pc()
	var b := _battle(3, ["goblin"], pc)
	pc.statuses.apply("poison")
	var keys: Array[String] = []
	b.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	for i in 6:
		var c := b.next_turn()
		if c == null:
			break
		if keys.has("combat.dot"):
			break
		b.act(c, {"kind": "guard"})
	assert_true(keys.has("combat.dot"), "중독 피해를 기록에 알린다")


func test_innate_skills_survive_skill_seal() -> void:
	var pc := _pc()
	var b := _battle(4, ["goblin"], pc)
	var c := _player_turn(b)
	pc.statuses.apply("lethargy")
	assert_true(pc.statuses.has_flag("no_skills"))
	assert_eq(b.can_use(c, "investigate"), "", "조사는 이능이 아니다")
	assert_eq(b.can_use(c, "talk"), "", "대화도")


func test_taunt_first_falls_back_to_guarding() -> void:
	var pc := _pc()
	var b := _battle(5, ["goblin"], pc)
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BattleRules.summon(b, me, {"monster": "deadman"})
	pc.statuses.apply("guarding")
	var gob := b.side_units(Combatant.SIDE_ENEMY)[0]
	for i in 20:
		assert_eq(MonsterAi.target(b, gob, {"target": "taunt_first"}), me, "도발한 이가 없으면 방어 중인 쪽")


func _session(seed_value: int = 3) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value))
	var pc := _pc()
	pc.set_level(4)
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


## 가방이 차 있어도 출구 열쇠(뿔피리)는 손에 쥐어 출구에서 쓴다 — 균열에 갇히지 않는다.
func test_rift_exit_key_kept_when_bag_full() -> void:
	var s := _session()
	assert_true(s.rifts.force_open(s, "rift_blood_fortress", s.pos))
	var p: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	var cs := s.rifts.enter(s, p)
	var run := cs.rift_run
	while s.player.inventory.add("magic_stone_9", 99) > 0:
		pass  # 가방을 가득 채운다
	assert_false(s.player.inventory.fits("rift_horn"))
	var killed: Array[String] = ["deadman_commander"]
	cs.grant_battle_rewards(null, killed)
	assert_eq(int(run.held.get("rift_horn", 0)), 1, "뿔피리를 손에 쥐었다")
	for g: FieldMonsters.Group in run.remaining.duplicate():
		var guard := 0
		while run.remaining.has(g) and guard < 20:
			guard += 1
			run.on_battle_end(cs, g, Battle.RESULT_VICTORY)
	var next := run.use_exit(cs)
	assert_true(next != null, "쥔 뿔피리로 1챕터 출구를 지난다")
	assert_eq(int(run.held.get("rift_horn", 0)), 0, "썼다")


## 가방이 차면 히든 피스는 그 자리에 남는다(탈출 폭약을 잃지 않게).
func test_hidden_piece_stays_when_bag_full() -> void:
	var s := _session(5)
	assert_true(s.rifts.force_open(s, "rift_green_mine", s.pos))
	var p: Dictionary = s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	var cs := s.rifts.enter(s, p)
	var run := cs.rift_run
	var at: Dictionary = run.hidden_at
	if at.is_empty():
		return  # 1챕터에 히든 피스가 없는 균열(시험 전제 없음)
	var cell: Vector2i = at.keys()[0]
	while s.player.inventory.add("magic_stone_9", 99) > 0:
		pass
	run.take_hidden(cs, cell)
	assert_true(run.hidden_at.has(cell), "가방이 차 있으면 그대로 남는다")
