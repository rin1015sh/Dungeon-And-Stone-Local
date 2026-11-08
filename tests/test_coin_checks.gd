extends TestCase
## 스탯 판정 → 동전(사용자 2026-11-08, V29 — CoinBet): 살피기 행동 coin gate · risk, Esc로 그만둠,
## 밟은 함정(그만둘 수 없다), 아귀 입 고르기, 데이터에 스탯 판정이 남지 않았는가.

const FLOOR := "f1_crystal_cave"

var _reg: ContentRegistries


func _session(monsters: bool = true, seed_value: int = 5) -> ExploreSession:
	if _reg == null:
		_reg = ContentRegistries.new()
	var def := db.get_entry("floors", FLOOR)
	var map := _reg.generator("crystal_cave").generate(db, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {})
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value + 1), _reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


## 다음 동전 결과를 미리 보고 맞히게(right) · 틀리게 고른다. pick = -1이면 그만둔다.
func _rig(s: ExploreSession, right: bool, kind: String, quit: bool = false) -> void:
	s.coin_guess.connect(func(then: Callable) -> void:
		if quit:
			then.call(-1)
			return
		var probe := Rng.new()
		probe.set_state_string(s.rng.get_state_string())
		var heads := probe.chance(CoinToss.heads_chance(s.db, kind))
		then.call(0 if heads == right else 1))
	s.coin_toss.connect(func(_heads: bool, then: Callable) -> void: then.call())


## 걸을 수 있고 바로 아래도 걸을 수 있는 칸(spawn이 그 아래에 무리를 세운다)의 가짜 요소.
func _feature(s: ExploreSession) -> Dictionary:
	var at := s.pos
	for r in range(0, 12):
		for d: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
			var q := s.pos + d
			if at == s.pos and q != s.pos and s.map.is_walkable(q) and s.map.is_walkable(q + Vector2i.DOWN) and s.monsters.group_at(q + Vector2i.DOWN) == null:
				at = q
	return {"pos": at, "used": {}, "def": {}, "found": true}


func _keys(s: ExploreSession) -> Array[String]:
	var keys: Array[String] = []
	s.message.connect(func(k: String, _a: Dictionary, _kind: String) -> void: keys.append(k))
	return keys


const GATE := {"id": "lift", "name_ko": "들어 올린다", "coin": "gate", "hours": 0.5, "fail_line": "field.bell_stuck", "line": "field.bell_ring",
	"give": [{"item": "magic_stone_9", "count": [1, 1]}]}
const RISK := {"id": "dig", "name_ko": "파헤친다", "coin": "risk", "line": "field.dig_grave_dig",
	"give": [{"item": "magic_stone_9", "count": [1, 1]}], "risk_effects": [{"type": "apply_status", "status": "curse"}],
	"spawn": {"monsters": ["goblin"], "line": "field.dig_grave_wake"}}


func test_gate_wrong_fails_and_can_retry() -> void:
	var s := _session(false)
	_rig(s, false, "field")
	var e := _feature(s)
	var keys := _keys(s)
	var t0 := s.clock.total_hours
	FieldFeatureAct.run(s, e, GATE)
	assert_true(keys.has("field.bell_stuck"), "틀리면 fail_line")
	assert_false((e["used"] as Dictionary).has("lift"), "횟수를 쓰지 않는다 — 다시 해 볼 수 있다")
	assert_eq(s.player.inventory.count("magic_stone_9"), 0)
	assert_near(s.clock.total_hours - t0, 0.5, 0.001, "시간은 흐른다")


func test_gate_right_succeeds() -> void:
	var s := _session(false)
	_rig(s, true, "field")
	var e := _feature(s)
	FieldFeatureAct.run(s, e, GATE)
	assert_true((e["used"] as Dictionary).has("lift"), "맞히면 해낸다")
	assert_eq(s.player.inventory.count("magic_stone_9"), 1)


func test_risk_wrong_brings_danger() -> void:
	var s := _session(true)
	_rig(s, false, "field")
	var n0 := s.monsters.groups.size()
	FieldFeatureAct.run(s, _feature(s), RISK)
	assert_eq(s.player.inventory.count("magic_stone_9"), 1, "risk는 틀려도 해낸다")
	assert_true(s.player.statuses.has("curse"), "틀리면 risk_effects")
	assert_eq(s.monsters.groups.size(), n0 + 1, "틀리면 spawn이 반드시 일어난다")


func test_risk_right_is_safe() -> void:
	var s := _session(true)
	_rig(s, true, "field")
	var n0 := s.monsters.groups.size()
	FieldFeatureAct.run(s, _feature(s), RISK)
	assert_eq(s.player.inventory.count("magic_stone_9"), 1)
	assert_false(s.player.statuses.has("curse"), "맞히면 위험 없음")
	assert_eq(s.monsters.groups.size(), n0, "맞히면 아무것도 일어나지 않는다")


func test_quit_spends_nothing() -> void:
	var s := _session(false)
	_rig(s, true, "field", true)
	s.player.inventory.add("magic_stone_9", 1)
	var e := _feature(s)
	var t0 := s.clock.total_hours
	var paid := GATE.duplicate(true)
	paid["cost"] = {"item": "magic_stone_9", "count": 1}
	FieldFeatureAct.run(s, e, paid)
	assert_eq(s.player.inventory.count("magic_stone_9"), 1, "그만두면 값을 치르지 않는다")
	assert_near(s.clock.total_hours, t0, 0.001, "시간도 흐르지 않는다")
	assert_true((e["used"] as Dictionary).is_empty())


func test_hazard_cannot_be_quit() -> void:
	var s := _session(false)
	var asked := [false]
	s.coin_guess.connect(func(then: Callable) -> void:
		asked[0] = true
		assert_false(s.coin_can_back, "밟은 함정은 그만둘 수 없다")
		then.call(-1))
	var hz := s.features.hazards
	var hd := {"id": "t", "tile": "feat_wet_slope", "fail": [{"type": "apply_status", "status": "curse"}]}
	hz.at[s.pos] = hd.merged({"cells": [s.pos]})
	assert_eq(hz.on_step(s, s.pos), true)
	assert_true(asked[0], "앞뒤를 묻는다")
	assert_false(hz.at.has(s.pos), "한 번만")


func test_no_stat_checks_left_in_data() -> void:
	for id: String in db.get_collection("events"):
		var ev := db.get_entry("events", id)
		for a: Variant in JsonUtil.get_array(ev, "actions"):
			assert_false((a as Dictionary).has("check"), "%s: 스탯 판정 없음" % id)
		var hz := JsonUtil.get_dict(ev, "hazard")
		assert_false(hz.has("check") or hz.has("detect"), "%s: 함정 판정은 동전" % id)
		assert_false(JsonUtil.get_dict(ev, "hidden").has("dc"), "%s: 알아채기는 동전" % id)
	for id: String in ["sarcophagus", "ringer_coffin", "dig_grave", "ghoul_feast", "carrion_heap", "offering_pile", "blood_well"]:
		var risky := JsonUtil.get_array(db.get_entry("events", id), "actions").filter(func(a: Variant) -> bool: return JsonUtil.get_str(a, "coin") == "risk")
		assert_eq(risky.size(), 1, id + ": 위험한 행동 하나가 동전")
