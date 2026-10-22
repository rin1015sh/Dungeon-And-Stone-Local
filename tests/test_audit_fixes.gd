extends TestCase
## 전투·스탯·상태이상 감사(2026-10-13)에서 고친 것들의 회귀 테스트:
## 전투 뒤 일시 상태 해제·지속 상태 유지, 아군 소환수(AI·보상 없음·승패 제외), 빗나간 공격의 딸린 효과, 여러 페이즈 한 번에,
## 최대 생명력 일시 감소 복구, 정수 업그레이드 잠금·빼앗긴 정수 삭제 횟수, 도주 뒤 무리, 보호막과 치명상, 봉인 면역.

const HIT := {"hit": 0.0, "crit": 1.0, "var": 0.5, "lethal": 1.0}


func _pc(level: int = 4) -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(level)
	pc.pool.fill_all()
	return pc


func _battle(monsters: Array, seed_value: int = 3) -> Battle:
	var party: Array[Actor] = [_pc()]
	return Battle.from_encounter(db, ContentRegistries.new(), Rng.new(seed_value), party, monsters)


func _apply(src: Actor, tgt: Actor, fx: Array, seed_value: int = 1) -> EffectContext:
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, src, tgt, Rng.new(seed_value))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, fx)
	return ctx


func test_battle_end_clears_temporary_keeps_lingering() -> void:
	var b := _battle(["goblin"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0].actor
	for st in ["guarding", "snare", "stun", "poison"]:
		me.statuses.apply(st)
	b.finish(Battle.RESULT_VICTORY)
	assert_false(me.statuses.has("guarding") or me.statuses.has("snare") or me.statuses.has("stun"), "일시 상태는 전투와 함께 풀린다")
	assert_true(me.statuses.has("poison"), "독은 남는다(lingers)")
	var hp := me.pool.get_current("hp")
	me.advance_hours(5.0 * float(db.bal("status.linger_hours_per_turn", 0.25)) + 0.01)
	assert_false(me.statuses.has("poison"), "탐험 시간으로 지속시간이 흐른다")
	assert_true(me.pool.get_current("hp") < hp, "남은 독은 탐험 중에도 피해를 준다")


func test_party_summons_are_ai_and_not_kills() -> void:
	var b := _battle(["goblin"])
	var me := b.side_units(Combatant.SIDE_PARTY)[0]
	BattleRules.summon(b, me, {"monster": "slime"})
	var pet: Combatant = b.units[b.units.size() - 1]
	assert_true(pet.summoned and pet.side == Combatant.SIDE_PARTY, "아군 소환수")
	assert_false(b.is_player_controlled(pet), "소환수는 AI가 움직인다")
	assert_true(b.is_player_controlled(me))
	pet.actor.pool.set_current("hp", 0.0)
	b._after_effects()
	assert_true(b.killed.is_empty(), "내 소환수가 쓰러져도 처치(보상)가 아니다")
	BattleRules.summon(b, me, {"monster": "slime"})
	me.actor.pool.set_current("hp", 0.0)
	b._after_effects()
	assert_eq(b.result, Battle.RESULT_DEFEAT, "소환수가 남아도 탐험가가 쓰러지면 패배")


func test_missed_attack_carries_no_riders() -> void:
	var pc := _pc()
	var banshee := Monster.create(db, "banshee")
	var fx := [{"type": "damage", "power": 1.0, "damage_type": "slash", "accuracy": 1000}, {"type": "apply_status", "status": "bleeding"}]
	assert_true(banshee.damage_affinity("slash", "physical") <= 0.0, "벤시는 물리 면역")
	_apply(pc, banshee, fx)
	assert_false(banshee.statuses.has("bleeding"), "면역으로 막힌 공격에 딸린 출혈은 걸리지 않는다")


func test_phase_skip_casts_once() -> void:
	var b := _battle(["king_slime"])
	var king := b.side_units(Combatant.SIDE_ENEMY)[0]
	var before := b.units.size()
	king.actor.pool.set_current("hp", king.actor.pool.get_max("hp") * 0.2)
	BossHooks.check_all(b)
	assert_eq(b.units.size() - before, 2, "한 번에 여러 구간을 넘어도 분열은 한 번(GM3)")


func test_temporary_max_drop_returns_hp() -> void:
	var pc := _pc()
	var full := pc.pool.get_current("hp")
	pc.statuses.apply("exhaustion")
	assert_true(pc.pool.get_max("hp") < full, "탈진으로 최대 생명력이 준다")
	pc.statuses.remove("exhaustion")
	assert_near(pc.pool.get_current("hp"), full, 0.001, "풀리면 잘렸던 생명력이 돌아온다(R11)")


func test_essence_upgrade_keeps_lock_and_stolen_is_free() -> void:
	var pc := _pc(2)
	assert_eq(pc.essences.absorb(pc, {"essence": "goblin", "color": "red", "stats": {}}), "")
	assert_eq(pc.essences.absorb(pc, {"essence": "ghoul", "color": "red", "stats": {}}), "")
	pc.change_level(1, Rng.new(1))
	var locked_i := -1
	for i in pc.essences.absorbed.size():
		if EssenceSet.is_locked(pc.essences.absorbed[i]):
			locked_i = i
	assert_true(locked_i >= 0, "레벨이 내려가 하나가 잠긴다")
	var id := str(pc.essences.absorbed[locked_i]["essence"])
	var g := EssenceDrop.make(db, id, "", Rng.new(1), true)
	assert_eq(pc.essences.absorb(pc, g), "")
	assert_true(EssenceSet.is_locked(pc.essences.absorbed[locked_i]), "잠긴 자리를 무지갯빛으로 바꿔도 잠금은 그대로")
	pc.essences.remove(pc, 0, false)
	assert_eq(pc.essences.deletions, 0, "빼앗긴 정수(영혼 베기)는 삭제 횟수에 들지 않는다")
	pc.essences.remove(pc, 0)
	assert_eq(pc.essences.deletions, 1)


func test_barrier_blocks_lethal_and_seal_immunity() -> void:
	var pc := _pc()
	var foe := Monster.create(db, "goblin")
	foe.pool.set_current("hp", foe.pool.get_max("hp") * 0.35)
	foe.statuses.apply("steel_ice_wall")
	foe.statuses.set_barrier("steel_ice_wall", 9999.0)
	var hp := foe.pool.get_current("hp")
	for i in 30:  # 치명상 확률 굴림이 여러 번 나오도록
		_apply(pc, foe, [{"type": "damage", "power": 0.3, "damage_type": "blunt", "accuracy": 1000, "crit_bonus": 1.0}], i + 1)
	assert_false(foe.dead, "보호막이 다 막은 치명타로는 치명상(즉사)이 나지 않는다")
	assert_near(foe.pool.get_current("hp"), hp, 0.001)
	var gk := _pc()
	assert_eq(gk.essences.absorb(gk, {"essence": "riddle_gatekeeper", "color": "red", "stats": {}}), "")
	assert_true(gk.statuses.immune("seal"), "문지기 정수: 봉인 면역이 상태 묶음에 반영된다")
	gk.learn_skill("ess_goblin_trap")
	var ctx := _apply(Monster.create(db, "riddle_gatekeeper"), gk, [{"type": "seal_skill", "rounds": 2}])
	assert_false(ctx.events.any(func(e: Dictionary) -> bool: return str(e.get("type")) == "seal"), "면역이면 스킬도 막히지 않는다")
