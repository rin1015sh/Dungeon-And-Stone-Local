extends TestCase
## G6 빙하굴(docs/PROMPT_FLOOR1_V2.md §10): 오러·기습·보호막·광분·초재생·휘두르기·타룬바스 패턴·냉기 추가 피해·속성 내성·
## 히든 피스(빙정·얼음 조각)·영구 스탯 횟수·탐험 위험·오한 공유 중복 거부·챕터 데이터.

const HIT := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}


func _pc(level: int = 4) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(level)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array, n_party: int = 1, seed_value: int = 3) -> Battle:
	var party: Array[Actor] = []
	for i in n_party:
		party.append(_pc())
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters)


func _apply(src: Actor, tgt: Actor, fx: Array, seed_value: int = 1) -> EffectContext:
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, fx)
	return ctx


func _session() -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var s := ExploreSession.new(db, def, reg.generator("crystal_cave").generate(db, def, Rng.new(3)), _pc(), GameClock.new(), Rng.new(4), reg.effects)
	s.monsters_enabled = false
	s.start()
	return s


func test_ice_golem_aura_and_sabertooth_ambush() -> void:
	var b := _battle(["ice_golem"], 2)
	var golem := b.side_units(Combatant.SIDE_ENEMY)[0]
	BattlePassives.turn_end(b, golem)
	BattlePassives.turn_end(b, golem)
	for u in b.side_units(Combatant.SIDE_PARTY):
		assert_eq(u.actor.statuses.stacks("frost"), 2, "냉기 오러: 라운드마다 적 전체 [서리] +1(둔화는 서리로 합침)")
	var b2 := _battle(["sabertooth"])
	var tiger := b2.side_units(Combatant.SIDE_ENEMY)[0].actor
	var me := b2.side_units(Combatant.SIDE_PARTY)[0].actor
	assert_true(tiger.statuses.has("ambush_hunter"), "기습 사냥꾼: 전투 시작 때")
	var fx := {"scaling": "phys", "power": 1.0, "damage_type": "pierce", "accuracy": 1000}
	var roll := {"hit": 0.0, "crit": 0.3, "var": 0.5, "lethal": 1.0}
	assert_true(bool(DamageCalc.resolve(db, tiger, me, fx, roll)["crit"]), "첫 일격 치명타율 +30%p")
	tiger.statuses.remove("ambush_hunter")
	assert_false(bool(DamageCalc.resolve(db, tiger, me, fx, roll)["crit"]))


func test_steel_ice_wall_barrier_and_shaman_ai() -> void:
	var b := _battle(["ice_orc_shaman", "ice_orc_warrior"])
	var shaman := b.side_units(Combatant.SIDE_ENEMY)[0]
	var warrior := b.side_units(Combatant.SIDE_ENEMY)[1]
	warrior.actor.pool.set_current("hp", warrior.actor.pool.get_max("hp") * 0.5)
	var act := b.ai_action(shaman)
	assert_eq(act["skill"], "orc_steel_ice_wall", "아군 생명력 60% 이하면 강철빙벽 우선")
	assert_eq(act["target"], warrior, "가장 다친 아군에게")
	_apply(shaman.actor, warrior.actor, JsonUtil.get_array(db.get_entry("skills", "orc_steel_ice_wall"), "effects"))
	var wall := shaman.actor.stats.get_value("int") * 4.0
	assert_near(warrior.actor.statuses.barrier_total(), wall, 0.01, "보호막 = 정신력 × 4")
	var hp := warrior.actor.pool.get_current("hp")
	var me := b.side_units(Combatant.SIDE_PARTY)[0].actor
	var ctx := _apply(me, warrior.actor, [{"type": "damage", "power": 1.0, "damage_type": "fire", "scaling": "magic", "base": 30, "accuracy": 1000}])
	var dealt := int(ctx.events[0]["amount"])
	assert_true(dealt > 0)
	assert_near(warrior.actor.pool.get_current("hp"), hp - maxf(0.0, dealt - wall), 0.01, "보호막이 먼저 받는다")
	assert_eq(warrior.actor.statuses.has("steel_ice_wall"), dealt < wall, "다 닳으면 풀린다")
	assert_true(warrior.actor.stats.apply_modifiers("dmg_dealt:cold", 1.0) > 1.0, "한기의 매개: 아군 냉기 피해 +15%")


func test_kirdui_frenzy_super_regen_and_swing() -> void:
	var k := Monster.create(db, "kirdui")
	_apply(k, k, JsonUtil.get_array(db.get_entry("skills", "kirdui_frenzy"), "effects"))
	assert_true(k.statuses.has("troll_frenzy"))
	var me := _pc()
	_apply(me, k, [{"type": "apply_status", "status": "stun"}, {"type": "apply_status", "status": "fear"}])
	assert_false(k.statuses.has("stun") or k.statuses.has("fear"), "광분 중 공포·기절 면역")
	k.statuses.apply("bleeding")
	var max_hp := k.pool.get_max("hp")
	k.pool.set_current("hp", max_hp * 0.4)
	_apply(k, k, JsonUtil.get_array(db.get_entry("skills", "kirdui_super_regen"), "effects"))
	assert_near(k.pool.get_current("hp"), floorf(max_hp * 0.4) + floorf(max_hp * 0.25), 1.0, "초재생 25%")
	assert_false(k.statuses.has("bleeding"), "약화 1개 해제")
	var swing := JsonUtil.get_array(db.get_entry("skills", "kirdui_swing"), "effects")[0] as Dictionary
	var plain := {"scaling": "phys", "power": 1.0, "damage_type": "blunt"}
	assert_near(DamageCalc.attack_power(db, k, swing) - DamageCalc.attack_power(db, k, plain), k.stats.get_value("str"), 0.01, "휘두르기: 근력×1 추가")
	assert_eq(JsonUtil.get_str(k.weak_point(), "on_hit_status"), "regen_stopped", "머리를 맞히면 재생 정지")


func test_tarunbas_pattern_and_collapse() -> void:
	var b := _battle(["tarunbas"], 3)
	var t := b.side_units(Combatant.SIDE_ENEMY)[0]
	var seq: Array = []
	for i in 3:
		t.acted = i
		seq.append(b.ai_action(t)["skill"])
	assert_eq(seq, ["tarun_club_smash", "tarun_frenzied_claws", "tarun_club_smash"], "강타 → 손톱 → 강타")
	for i in 3:
		BossHooks.turn_end(b, t, false)
	for u in b.side_units(Combatant.SIDE_PARTY):
		assert_true(u.actor.statuses.has("telegraphed"), "3라운드마다 지면 붕괴 예고(전원)")
	var party := b.side_units(Combatant.SIDE_PARTY)
	party[0].actor.statuses.apply("guarding")
	var hp0 := party[0].actor.pool.get_current("hp")
	var hp1 := party[1].actor.pool.get_current("hp")
	BattleDelayed.tick(b, t)
	assert_true(hp1 - party[1].actor.pool.get_current("hp") > (hp0 - party[0].actor.pool.get_current("hp")) * 2.0, "방어하면 대부분 막는다")
	var pat := BossHooks.pattern(b, t)
	assert_false(pat.wants_extra_action(b, t))
	t.actor.pool.set_current("hp", t.actor.pool.get_max("hp") * 0.45)
	BossHooks.check_all(b)
	assert_true(t.actor.statuses.has("rally"), "50%에서 포효")
	assert_true(pat.wants_extra_action(b, t), "이후 라운드당 2회")
	assert_true(t.actor.damage_affinity("lightning", "magical") > 1.0, "전기 약점")
	assert_eq(t.actor.damage_affinity("cold", "magical"), 0.0, "냉기 면역")


func test_cold_rider_resist_and_affinity() -> void:
	var t := Monster.create(db, "tarunbas")
	var warm := _pc()
	var cold := _pc()
	cold.statuses.apply("hypothermia")
	var club := JsonUtil.get_array(db.get_entry("skills", "tarun_club_smash"), "effects")
	var c1 := _apply(t, warm, [(club[0] as Dictionary).merged({"accuracy": 1000})])
	var c2 := _apply(t, cold, [(club[0] as Dictionary).merged({"accuracy": 1000})])
	assert_true(c1.messages.any(func(m: Dictionary) -> bool: return m["key"] == "combat.rider_hit"), "냉기 추가 피해")
	var lost_warm := warm.pool.get_max("hp") - warm.pool.get_current("hp")
	var lost_cold := cold.pool.get_max("hp") - cold.pool.get_current("hp")
	assert_true(lost_cold > lost_warm, "저체온증이면 냉기 추가 피해 ×2 (%d > %d)" % [lost_cold, lost_warm])
	assert_true(c2.events.size() > 0)
	var atk := Actor.new(db, {"int": 10})
	var fx := {"scaling": "magic", "base": 20, "power": 1.0, "damage_type": "cold", "accuracy": 1000}
	var base := float(DamageCalc.resolve(db, atk, Actor.new(db, {}), fx, HIT)["amount"])
	assert_near(float(DamageCalc.resolve(db, atk, Actor.new(db, {"resist_cold": 10}), fx, HIT)["amount"]), base * 0.9, 1.0, "냉기 내성 10 → −10%")
	assert_near(float(DamageCalc.resolve(db, Actor.new(db, {"int": 10, "affinity_cold": 5}), Actor.new(db, {}), fx, HIT)["amount"]), base * 1.1, 1.0, "냉기 감응도 5 → +10%")


func test_hidden_pieces_and_boons() -> void:
	var s := _session()
	s.rifts.force_open(s, "rift_glacier_cave", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	var run := cs.rift_run
	assert_eq(run.guardian_id(), "kirdui" if run.variant else "tarunbas")
	assert_eq(run.hidden_at.size(), 1, "1챕터 연못")
	var pond: Vector2i = run.hidden_at.keys()[0]
	assert_eq(cs.map.tile_id_at(pond), "ice_pond")
	assert_true(Vector2(pond - cs.map.entry).length() <= float(db.bal("rift.near_entry_m")), "시작 자리 가까이")
	assert_true(run.take_hidden(cs, pond))
	var pc := s.player
	pc.inventory.add("ice_crystal", 3)
	var reg := ContentRegistries.new()
	var before := pc.stats.get_value("affinity_cold")
	for i in 3:
		assert_true(ItemUser.use(reg.effects, pc, "ice_crystal", Rng.new(1)).success)
	assert_near(pc.stats.get_value("affinity_cold"), before + 9.0, 0.001, "빙정 냉기 감응도 +3 × 3")
	assert_false(ItemUser.use(reg.effects, pc, "ice_crystal", Rng.new(1)).success, "네 번째는 듣지 않는다")
	assert_eq(pc.inventory.count("ice_crystal"), 1, "듣지 않으면 남는다")
	run.debug_clear()
	cs = run.use_exit(cs)
	assert_eq(cs.map.tile_id_at(run.hidden_at.keys()[0]), "ice_pillar_cracked", "2챕터 금 간 기둥")
	assert_true(run.take_hidden(cs, run.hidden_at.keys()[0]))
	assert_true(ItemUser.use(reg.effects, pc, "mana_ice_shard", Rng.new(1)).success)
	assert_near(pc.stats.get_base("resist_cold"), 3.0, 0.001, "얼음 조각 냉기 내성 +3")
	var saved := pc.progress_to_dict()
	var pc2 := _pc()
	pc2.progress_load_dict(saved)
	assert_near(pc2.stats.get_base("affinity_cold"), before + 9.0, 0.001, "영구 강화는 저장된다")
	assert_eq(int(pc2.boons["ice_crystal@affinity_cold"]), 3)


func test_hazards_in_chapter3() -> void:
	var s := _session()
	s.rifts.force_open(s, "rift_glacier_cave", s.pos)
	var cs := s.rifts.enter(s, s.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0])
	var run := cs.rift_run
	for i in 2:
		run.debug_clear()
		cs = run.use_exit(cs)
	assert_eq(run.chapter, 2)
	assert_true(s.player.statuses.has("hypothermia"), "3챕터 저체온증")
	assert_false(run.hazards.at.is_empty(), "탐험 위험이 깔린다")
	var cell: Vector2i = run.hazards.at.keys()[0]
	var group: Dictionary = run.hazards.at[cell]
	var tile := JsonUtil.get_str(group, "tile")
	assert_eq(cs.map.tile_id_at(cell), tile)
	assert_true(run.hazards.on_step(cs, cell) is bool, "처음 밟으면 판정")
	assert_false(run.hazards.at.has(cell), "한 번만")
	assert_eq(run.hazards.on_step(cs, cell), null)
	assert_true(cs.map.is_walkable(cell) and cs.map.tile_id_at(cell) == tile, "판정 뒤에도 그 자리에 남는다(걸을 수 있다)")
	var nimble := Actor.new(db, {"agi": 500})  # 비율 공식: 난이도의 수십 배여야 상한에 닿는다
	var clumsy := Actor.new(db, {"agi": 2})
	var chk := {"stat": "agi", "dc": 12}
	assert_true(RiftHazards.success_chance(db, nimble, chk) > RiftHazards.success_chance(db, clumsy, chk))
	assert_near(RiftHazards.success_chance(db, nimble, chk), float(db.bal("rift.hazard_max")), 0.001)


func test_shared_chill_and_exp() -> void:
	var pc := _pc(6)
	assert_eq(pc.essences.absorb(pc, {"essence": "yeti", "color": "white", "stats": {}}), "")
	assert_eq(pc.essences.check_absorb(pc, {"essence": "katumba", "color": "white", "stats": {}}), "essence.reason_duplicate", "예티↔카툼바 오한 중복 거부")
	assert_eq(pc.essences.check_absorb(pc, {"essence": "katumba", "color": "blue", "stats": {}}), "", "눈사태는 된다")
	var ex := {"frost_wolf": 1, "yeti": 3, "sabertooth": 2, "ice_orc_shaman": 3, "katumba": 4, "tarunbas": 3, "kirdui": 6}
	for id: String in ex:
		assert_eq(Progression.first_kill_exp(db, db.get_entry("monsters", id)), int(ex[id]), id)
	var rift := db.get_entry("rifts", "rift_glacier_cave")
	assert_false(rift.has("stand_in"))
	var ch2: Dictionary = JsonUtil.get_array(rift, "chapters")[1]
	var chain: Array = JsonUtil.get_array(JsonUtil.get_array(ch2, "encounters")[0], "battles")
	assert_eq(chain.size(), 10, "9연전 + 카툼바")
	assert_eq(chain[-1], ["katumba"])
	assert_eq(JsonUtil.get_float(db.get_entry("essences", "katumba"), "grade"), 7.0)
	assert_near(EssenceDrop.drop_chance(db, db.get_entry("monsters", "katumba")), 0.1, 0.0001, "카툼바 정수 10%")
