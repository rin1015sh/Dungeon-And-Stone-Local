extends TestCase
## 정수 시너지(ES1~ — docs/plans/essence_synergy.md, CLAUDE.md "정수 연계 규칙"): 새 정수를 만들 때도 지켜야 하는 규칙(데이터)과
## 연계가 실제로 켜지고 꺼지는지(장착 · 제거 · 잠금 · 저장 · 상한 · 반격 하나 · 은신 · 처치 게이지).

## 다른 정수와 상태로 이어지지 않아도 되는 정수(이유) — 새 정수는 여기에 넣기 전에 연계를 먼저 찾는다.
const EXEMPT := {
	"iron_cavalry": "돌격 밀치기 · 방패 벽 — 순서 늦추기 · 막기로 혼자 완결",
	"dullahan": "철기병과 같은 스킬 — 혼자 완결",
	"sabertooth": "기습 치명 · 빈사 처형 — 상태가 아니라 생명력 조건",
}
## 거는 쪽만 있어도 되는 상태(효과가 그 자체로 보상 — 자기 버프 · 모두에게 통하는 피해 증폭).
const INHERENT := ["shield_wall", "rally", "troll_frenzy", "lurk", "vulnerable", "marked", "intimidated", "isolated", "haste",
	"guarding", "covered", "vitality_drain", "overheat", "march_order", "vamp_blood_feast", "vamp_blood_veil", "venom_weapon", "steel_ice_wall",
	"sacrifice_mark", "magnetized", "acid_corrosion", "heal_block", "trap_set", "confusion", "petrify", "burn", "counter_stance", "lurk"]
const MAX_PAYOFF_MULT := 1.3     ## 반응 패시브 하나의 배율 상한
const MAX_PAYOFFS_PER_STATUS := 3  ## 한 상태에 반응하는 패시브 수 상한(한 축이 모든 최적 조합을 먹지 않게)


func _all() -> Dictionary:
	var out := {}  # id → {applies, reacts, passive}
	for id: String in db.get_collection("essences"):
		var def := db.get_entry("essences", id)
		var inst := {"essence": id, "color": "rainbow"}
		var li := EssenceLinks.of_instance(db, inst)
		out[id] = {"applies": (li["applies"] as Dictionary).keys(), "reacts": (li["reacts"] as Dictionary).keys(), "passive": JsonUtil.get_dict(def, "passive")}
	return out


## 규칙 1: 모든 정수는 다른 정수 하나 이상과 상태로 이어진다(예외는 EXEMPT에 이유와 함께).
func test_every_essence_links_to_another() -> void:
	var all := _all()
	for id: String in all:
		if EXEMPT.has(id):
			continue
		var ok := false
		for o: String in all:
			if o == id:
				continue
			for s: String in all[id]["applies"]:
				ok = ok or (all[o]["reacts"] as Array).has(s)
			for s: String in all[id]["reacts"]:
				ok = ok or (all[o]["applies"] as Array).has(s)
		assert_true(ok, "%s: 다른 정수와 이어지는 상태가 없다 — 거는 상태에 반응하는 정수가 있거나, 반응하는 상태를 거는 정수가 있어야 한다" % id)


## 규칙 2: 정수 둘 이상이 거는 상태에는 반응하는 정수가 있다(덤 효과로 남기지 않는다). 반응이 없는 반응 패시브도 없다.
func test_statuses_have_payoffs() -> void:
	var all := _all()
	var appliers := {}
	var reactors := {}
	for id: String in all:
		for s: String in all[id]["applies"]:
			appliers[s] = int(appliers.get(s, 0)) + 1
		for s: String in all[id]["reacts"]:
			reactors[s] = int(reactors.get(s, 0)) + 1
	for s: String in appliers:
		if int(appliers[s]) >= 2 and not INHERENT.has(s):
			assert_true(reactors.has(s), "[%s]을(를) 정수 %d개가 거는데 반응하는 정수가 없다" % [s, appliers[s]])
	for s: String in reactors:
		assert_true(appliers.has(s), "[%s]에 반응하는 정수가 있는데 거는 정수가 없다" % s)


## 규칙 3: 반응 패시브 하나의 배율 ≤ 1.3, 상한이 있다, 한 상태에 반응 패시브 ≤ 3.
func test_payoff_bounds() -> void:
	var cap := float(db.bal("combat.status_payoff_cap", 0.0))
	assert_true(cap >= 1.2 and cap <= 1.5, "반응 배율 상한 %.2f" % cap)
	var per := {}
	for id: String in db.get_collection("essences"):
		var p := JsonUtil.get_dict(db.get_entry("essences", id), "passive")
		var pv := JsonUtil.get_dict(p, "power_vs_status")
		if not pv.is_empty():
			assert_true(JsonUtil.get_float(pv, "mult") <= MAX_PAYOFF_MULT + 0.001, "%s 반응 배율 %.2f" % [id, JsonUtil.get_float(pv, "mult")])
		for s in EssenceLinks.passive_reacts(p):
			if not (per.get(s, []) as Array).has(JsonUtil.get_str(p, "id")):
				per[s] = (per.get(s, []) as Array) + [JsonUtil.get_str(p, "id")]
	for s: String in per:
		assert_true((per[s] as Array).size() <= MAX_PAYOFFS_PER_STATUS, "[%s] 반응 패시브 %d개: %s" % [s, (per[s] as Array).size(), per[s]])


func _pc() -> PlayerCharacter:
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 10, "p_res": 10})
	pc.set_level(6)
	pc.pool.fill_all()
	return pc


func _foe(status: String = "") -> Monster:
	var m := Monster.create(db, "goblin")
	if not status.is_empty():
		m.statuses.apply(status)
	return m


## 장착하면 켜지고, 제거 · 잠금이면 꺼지고, 저장 → 불러오기 뒤 다시 켜진다.
func test_link_follows_equip_lock_and_save() -> void:
	var pc := _pc()
	var stunned := _foe("stun")
	assert_eq(Passives.damage_mult_vs(pc, stunned), 1.0)
	assert_eq(pc.essences.absorb(pc, {"essence": "hobgoblin", "color": "red", "stats": {}}), "")
	assert_near(Passives.damage_mult_vs(pc, stunned), 1.25, 0.001, "기절 대상 ×1.25")
	assert_eq(Passives.damage_mult_vs(pc, _foe()), 1.0, "기절이 아니면 그대로")
	var saved := pc.essences.to_dict()
	var pc2 := _pc()
	pc2.essences.load_dict(pc2, saved)
	assert_near(Passives.damage_mult_vs(pc2, stunned), 1.25, 0.001, "불러온 뒤에도")
	pc.essences.absorb(pc, {"essence": "kobold_shield", "color": "red", "stats": {}})
	var hob := pc.essences.absorbed[0]
	assert_true(EssencePanel.link_texts(db, pc.essences.absorbed[1], pc.essences.absorbed).size() >= 1, "방패 밀치기(기절) → 짓밟기 연계 줄")
	pc.set_level(1)
	pc.essences.sync_slots(pc, Rng.new(1))
	if EssenceSet.is_locked(hob):
		assert_eq(Passives.damage_mult_vs(pc, stunned), 1.0, "잠기면 꺼진다")
	pc.set_level(6)
	pc.essences.sync_slots(pc, Rng.new(1))
	assert_near(Passives.damage_mult_vs(pc, stunned), 1.25, 0.001, "풀리면 다시")
	pc.essences.remove(pc, pc.essences.absorbed.find(hob))
	assert_eq(Passives.damage_mult_vs(pc, stunned), 1.0, "제거하면 꺼진다")


## 반응 패시브를 여럿 모아도 한 대상에 대한 배율은 상한까지만.
func test_payoff_cap() -> void:
	var pc := _pc()
	for e: String in ["blood_blade_wolf", "goblin_swordsman"]:
		pc.essences.absorb(pc, {"essence": e, "color": "red", "stats": {}})
	var bleeding := _foe("bleeding")
	assert_near(Passives.damage_mult_vs(pc, bleeding), 1.125 * 1.1, 0.001, "둘은 곱한다")
	pc.add_passive({"id": "test_extra", "power_vs_status": {"status": "bleeding", "mult": 1.3}})
	assert_near(Passives.damage_mult_vs(pc, bleeding), float(db.bal("combat.status_payoff_cap")), 0.001, "상한에서 멈춘다")


## 철벽 · 끌어들이기 반격 패시브를 같이 가져도 반격은 한 번(가장 센 것 하나).
func test_counter_takes_one() -> void:
	var pc := _pc()
	for e: String in ["monolith_soldier", "kobold_shield"]:
		pc.essences.absorb(pc, {"essence": e, "color": "red", "stats": {}})
	pc.statuses.apply("iron_wall")
	pc.statuses.apply("taunt")
	var foe := _foe()
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, foe, pc, Rng.new(3))
	ctx.registry = reg.effects
	for i in 6:
		reg.effects.apply_all(ctx, [{"type": "damage", "scaling": "phys", "power": 1.0, "damage_type": "slash", "accuracy": 1000}])
	var counters := ctx.messages.filter(func(m: Dictionary) -> bool: return m["key"] == "combat.counter").size()
	assert_true(counters >= 1 and counters <= 6, "맞을 때마다 반격 한 번 이하: %d" % counters)


func test_hidden_crit_and_kill_gauge() -> void:
	var pc := _pc()
	pc.essences.absorb(pc, {"essence": "bulkar", "color": "blue", "stats": {}})
	var base := Passives.crit_bonus(pc, "slash")
	pc.statuses.apply("hidden")
	assert_near(Passives.crit_bonus(pc, "slash") - base, 0.25, 0.001, "은신한 동안 치명 +25%")
	var wolf := _pc()
	wolf.essences.absorb(wolf, {"essence": "werewolf", "color": "red", "stats": {}})
	var foe := _foe()
	foe.pool.set_current("hp", 1.0)
	var reg := ContentRegistries.new()
	var ctx := EffectContext.new(db, wolf, foe, Rng.new(3))
	ctx.registry = reg.effects
	reg.effects.apply_all(ctx, [{"type": "damage", "scaling": "phys", "power": 2.0, "damage_type": "slash", "accuracy": 1000}])
	assert_true(foe.dead)
	var g := ctx.events.filter(func(e: Dictionary) -> bool: return e["type"] == "gauge" and e["target"] == wolf)
	assert_eq(g.size(), 1, "쓰러뜨리면 게이지 한 번")
	assert_near(float(g[0]["amount"]), 40.0, 0.01)


## 무한 상태 중첩 · 연속 기절 없음(상한 · 면역) — 반응 축이 무한 연쇄를 만들지 않는다.
func test_no_infinite_status_loops() -> void:
	var m := _foe()
	for i in 10:
		m.statuses.apply("bleeding")
	assert_true(m.statuses.stacks("bleeding") <= 3, "출혈 중첩 상한")
	assert_true(JsonUtil.get_int(db.get_entry("statuses", "stun"), "after_immune") >= 1, "기절 뒤 면역")
	assert_true(JsonUtil.get_int(db.get_entry("statuses", "frozen"), "after_immune") >= 1, "빙결 뒤 면역")


## 규칙 4(무한 연쇄 금지): 정수가 거는 상태 중 중첩되는 것은 중첩 상한(max_stacks)이, 차례를 빼앗는 것(skip_turn)은 풀린 뒤 면역(after_immune)이 있다.
func test_essence_statuses_are_bounded() -> void:
	var self_limited := ["vamp_blood_feast"]  # 제물 수만큼만 쌓인다(피의 낙인 unless_target_status)
	var all := _all()
	var seen := {}
	for id: String in all:
		for s: String in all[id]["applies"]:
			if s.begins_with("@") or seen.has(s):
				continue
			seen[s] = true
			var def := db.get_entry("statuses", s)
			if JsonUtil.get_bool(def, "stackable") and not self_limited.has(s):
				assert_true(def.has("max_stacks"), "[%s] 중첩 상한이 없다" % s)
			if JsonUtil.get_array(def, "flags").has("skip_turn"):
				assert_true(JsonUtil.get_int(def, "after_immune") >= 1, "[%s] 차례를 빼앗는데 풀린 뒤 면역이 없다" % s)
