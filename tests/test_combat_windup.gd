extends TestCase
## 전투 개선(CB1~CB3): 큰 몸짓(일반 몬스터의 강한 공격 = 한 차례 앞선 예고) · 시전자 표시 · 기절로 끊기 ·
## 보스 예고는 끊기지 않음 · 데쓰웜 단계 · 숨어 기다린 매복 선공.

const WINDUPS := ["cav_charge", "ghoul_pounce", "hob_club_smash", "chimera_frenzy_charge", "yeti_ice_smash", "deathworm_devour"]

var _reg: ContentRegistries = null


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array, n_party: int = 1) -> Battle:
	var party: Array[Actor] = []
	for i in n_party:
		party.append(_pc())
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, monsters)


func _said(b: Battle, key: String) -> bool:
	return b.history.any(func(m: Dictionary) -> bool: return m["key"] == key)


func _cast(b: Battle, skill: String) -> Array:
	var foe := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BossHooks.apply_effects(b, foe, me, JsonUtil.get_array(db.get_entry("skills", skill), "effects"))
	return [foe, me]


func test_strong_attacks_are_interruptible_windups() -> void:
	for sid: String in WINDUPS:
		var fx := JsonUtil.get_array(db.get_entry("skills", sid), "effects")
		assert_eq(fx.size(), 1, sid)
		var d: Dictionary = fx[0]
		assert_eq(JsonUtil.get_str(d, "type"), "delayed", "%s: 큰 몸짓" % sid)
		assert_eq(JsonUtil.get_str(d, "target"), "cast", "%s: 노린 대상이 보인다" % sid)
		assert_true(JsonUtil.get_bool(d, "interruptible"), "%s: 기절로 끊긴다" % sid)
		assert_true(JsonUtil.get_float(d, "guarded_mult", 1.0) < 1.0, "%s: 방어가 답" % sid)
		assert_true(JsonUtil.get_int(db.get_entry("skills", sid), "cooldown") >= 2, "%s: 연달아 준비하지 않는다" % sid)
		assert_true(Strings.has(JsonUtil.get_str(d, "warn")) and Strings.has(JsonUtil.get_str(d, "fire")), "%s: 문구" % sid)
	# 정수판은 그대로(C15 — 바로 친다)
	var ess := JsonUtil.get_array(db.get_entry("skills", "ess_cav_charge"), "effects")
	assert_eq(JsonUtil.get_str(ess[0], "type"), "damage", "정수판 돌격은 바로 친다")


func test_windup_marks_caster_and_fires_next_turn() -> void:
	var b := _battle(["ghoul"])
	var pair := _cast(b, "ghoul_pounce")
	var ghoul: Combatant = pair[0]
	var me: Combatant = pair[1]
	assert_true(me.actor.statuses.has("telegraphed"), "노린 대상에 예고")
	assert_true(ghoul.actor.statuses.has(BattleDelayed.WINDUP), "준비하는 적 머리 위에 큰 몸짓")
	BattleDelayed.tick(b, ghoul)
	assert_true(_said(b, "combat.ghoul_pounce_fire"), "다음 자기 차례 시작에 터진다")
	assert_false(ghoul.actor.statuses.has(BattleDelayed.WINDUP), "터지면 표시가 풀린다")
	assert_false(me.actor.statuses.has("telegraphed"))


func test_stun_breaks_windup() -> void:
	var b := _battle(["hobgoblin"])
	var pair := _cast(b, "hob_club_smash")
	var hob: Combatant = pair[0]
	var me: Combatant = pair[1]
	var hp := me.actor.pool.get_current("hp")
	BattleDelayed.tick(b, hob, true)
	assert_true(_said(b, "combat.windup_broken"), "기절하면 큰 몸짓이 끊긴다")
	assert_false(_said(b, "combat.hob_club_smash_fire"), "터지지 않는다")
	assert_eq(me.actor.pool.get_current("hp"), hp, "피해 없음")
	assert_false(hob.actor.statuses.has(BattleDelayed.WINDUP))
	assert_false(me.actor.statuses.has("telegraphed"), "예고 표식도 풀린다")
	assert_true((hob.memo.get("delayed", []) as Array).is_empty())


func test_boss_telegraph_is_not_broken_by_stun() -> void:
	var b := _battle(["king_slime"])
	var king := b.side_units(Combatant.SIDE_ENEMY)[0]
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BossHooks.apply_effects(b, king, me, JsonUtil.get_array(db.get_entry("skills", "king_jump_crush"), "effects"))
	BattleDelayed.tick(b, king, true)
	assert_false(_said(b, "combat.windup_broken"), "보스 예고는 끊기지 않는다")
	assert_true(_said(b, "combat.king_jump_fire"), "그대로 터진다")


func test_guard_softens_windup() -> void:
	var b := _battle(["iron_cavalry"])
	var pair := _cast(b, "cav_charge")
	var me: Combatant = pair[1]
	me.actor.statuses.apply("guarding")
	BattleDelayed.tick(b, pair[0])
	assert_true(_said(b, "combat.telegraph_guarded"), "막아 낸다")


func test_deathworm_hunts_the_weak_when_hurt() -> void:
	var b := _battle(["deathworm"])
	var worm := b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_eq(str(worm.memo.get("phase", "")), "p1")
	worm.actor.pool.set_current("hp", worm.actor.pool.get_max("hp") * 0.4)
	BossHooks.check_all(b)
	assert_eq(str(worm.memo.get("phase", "")), "p2", "절반 아래")
	assert_eq(str(worm.memo.get("target_rule", "")), "lowest_hp", "가장 약한 사람을 노린다")
	assert_true(_said(b, "combat.deathworm_rage"))


func _f2(monsters: bool) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var def := db.get_entry("floors", "f2_land_of_dead")
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8})
	var s := ExploreSession.new(db, def, _reg.generator("fields").generate(db, def, Rng.new(4)), pc, GameClock.new(),
		Rng.new(5), _reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


## 숨어 기다린 매복(CB3): 엄폐 옆에 서 있는데 모르는 무리가 닿으면 플레이어 선공, 쫓기던 무리 · 걷는 중 · 보스는 아니다.
func test_cover_ambush_gives_first_strike() -> void:
	var s := _f2(true)
	var spot := Vector2i(-1, -1)
	for i in s.map.tiles.size():
		var p := s.map.pos_of(i)
		if s.map.tile_id_at(p) == "f2d_pew" and s.map.is_walkable(p + Vector2i.DOWN):
			spot = p + Vector2i.DOWN
			break
	assert_true(spot.x >= 0 and s.relocate(spot), "긴 의자 옆")
	var g := s.monsters.add_fixed(["skeleton"], spot + Vector2i(3, 0))
	assert_true(g != null)
	g.state = FieldMonsters.STATE_IDLE
	g.alert_until = -1.0
	s.last_move_hours = s.clock.total_hours
	assert_false(FieldStealth.springs_ambush(s, g), "걷는 중이면 아니다")
	s.clock.advance(0.1)
	assert_true(FieldStealth.springs_ambush(s, g), "숨어 기다렸다 — 선공")
	g.state = FieldMonsters.STATE_CHASE
	assert_false(FieldStealth.springs_ambush(s, g), "쫓기던 무리는 아니다")
	g.state = FieldMonsters.STATE_IDLE
	g.boss = "skeleton"
	assert_false(FieldStealth.springs_ambush(s, g), "보스는 아니다")
	s.detach()


func test_first_strike_battle_starts_ahead() -> void:
	var party: Array[Actor] = [_pc()]
	var b := Battle.from_encounter(db, ContentRegistries.new(), Rng.new(3), party, ["skeleton"], Combatant.SIDE_PARTY)
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	var foe := b.side_units(Combatant.SIDE_ENEMY)[0]
	assert_true(me.gauge > foe.gauge, "플레이어 쪽이 게이지를 앞서 받는다")
	assert_true(_said(b, "combat.start_first"))


## 큰 몸짓 중(끊기는 예고)이면 기절 · 빙결 확률 × combat.windup_stun_mult(CB6) — 보스 예고는 해당 없음.
func test_off_balance_doubles_stun_chance() -> void:
	var b := _battle(["hobgoblin"])
	var pair := _cast(b, "hob_club_smash")
	var hob: Combatant = pair[0]
	assert_true(hob.actor.has_meta(BattleDelayed.OFF_BALANCE), "큰 몸짓 중 — 중심을 잃었다")
	var stun := [{"type": "apply_status", "status": "stun", "chance": 0.3}]
	var mult := float(db.bal("combat.windup_stun_mult", 1.0))
	assert_true(mult > 1.0)
	var hits := [0, 0]
	for i in 400:
		for k in 2:
			var target: Actor = Monster.create(db, "hobgoblin")  # 매번 새로(기절은 풀린 뒤 잠깐 면역 — after_immune)
			if k == 0:
				target.set_meta(BattleDelayed.OFF_BALANCE, true)
			var ctx := EffectContext.new(db, pair[1].actor, target, Rng.new(1000 + i))
			var reg := ContentRegistries.new()
			ctx.registry = reg.effects
			reg.effects.apply_all(ctx, stun)
			hits[k] += 1 if target.statuses.has("stun") else 0
	assert_true(hits[0] > hits[1] * 1.4, "큰 몸짓 중이 더 잘 걸린다 %d vs %d" % hits)
	BattleDelayed.tick(b, hob)
	assert_false(hob.actor.has_meta(BattleDelayed.OFF_BALANCE), "터지면 풀린다")
	var kb := _battle(["king_slime"])
	var king := kb.side_units(Combatant.SIDE_ENEMY)[0]
	BossHooks.apply_effects(kb, king, kb.side_units(Combatant.SIDE_PARTY)[0], JsonUtil.get_array(db.get_entry("skills", "king_jump_crush"), "effects"))
	assert_false(king.actor.has_meta(BattleDelayed.OFF_BALANCE), "보스 예고는 해당 없음")


## 행동 순서(CB7): 앞으로의 차례 목록 · 큰 몸짓이 터지는 그 적의 차례 자리.
func test_turn_order_marks_windup_turn() -> void:
	var b := _battle(["hobgoblin"])
	var pair := _cast(b, "hob_club_smash")
	var hob: Combatant = pair[0]
	var to := TurnOrder.new()
	to.setup(b)
	var list := to.order()
	assert_eq(list.size(), 6, "여섯 차례")
	var boom := to.fires(list)
	assert_eq(boom.size(), 1, "터지는 자리 하나")
	var at: int = boom.keys()[0]
	assert_eq(list[at], hob, "큰 몸짓을 준비한 적의 차례")
	assert_eq(list.find(hob), at, "그 적의 다음 차례")
	assert_eq(int(to.first_index()[hob]), at + 1, "무대 이름 앞 번호")
	to.free()
