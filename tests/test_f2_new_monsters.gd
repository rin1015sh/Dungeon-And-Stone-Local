extends TestCase
## 2층 새 몬스터 15종(docs/plans/floor2_monsters.md — 사용자 2026-11-08): 자리 · 전투 규칙(빼앗기 · 주술사 · 떼 광역 약점) ·
## 지도 행동(MonsterTraits — 덫 깔기 · 망대로 달리기 · 돌진 · 까마귀 · 밤 지역, RouteAmbush 타일 · 횃불 매복).

const NEW := ["goblin_trapper", "goblin_shaman", "goblin_wolf_rider", "goblin_hound", "thorn_creeper", "spine_boar", "canyon_bat", "bone_hyena",
	"drowned", "grave_keeper", "carrion_crow", "wraith", "dune_scorpion", "desert_vulture", "dried_pilgrim"]


func _session(floor_id: String, seed_value: int, monsters: bool = true) -> ExploreSession:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", floor_id)
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 12, "agi": 8, "int": 8})
	var s := ExploreSession.new(db, def, reg.generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(seed_value)), pc, GameClock.new(),
		Rng.new(seed_value + 1), reg.effects)
	s.monsters_enabled = monsters
	s.start()
	return s


func _mentions(v: Variant, id: String) -> bool:
	if v is Dictionary:
		for k: Variant in v:
			if str(k) == id or _mentions(v[k], id):
				return true
	elif v is Array:
		for x: Variant in v:
			if _mentions(x, id):
				return true
	return str(v) == id


func test_every_new_monster_has_a_place_on_floor2() -> void:
	for id: String in NEW:
		var found := false
		for fid: String in ["f2_goblin_forest", "f2_beast_den", "f2_land_of_dead", "f2_rock_desert"]:
			var def := db.get_entry("floors", fid)
			found = found or _mentions(def.get("regions"), id) or _mentions(def.get("route_spots"), id)
		assert_true(found, "%s: 2층 어디에도 없다" % id)
		assert_true(db.has_entry("essences", id), "%s 정수" % id)


func _battle(enemy: String) -> Array:
	var reg := ContentRegistries.new()
	var b := Battle.new(db, reg.effects, reg.ai_conditions, Rng.new(7))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 14, "agi": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	var p := b.add(pc, Combatant.SIDE_PARTY)
	var e := b.add(Monster.create(db, enemy), Combatant.SIDE_ENEMY)
	return [b, p, e, reg]


## 순례자가 빼앗은 물건은 그 전투에서 쓰러뜨리면 되찾는다.
func test_pilgrim_steals_and_gives_back() -> void:
	var t := _battle("dried_pilgrim")
	var b: Battle = t[0]
	var p: Combatant = t[1]
	var e: Combatant = t[2]
	b.start()
	p.actor.inventory.add("spring_water", 1)
	var ctx := EffectContext.new(db, e.actor, p.actor, Rng.new(1))
	ctx.registry = (t[3] as ContentRegistries).effects
	ctx.registry.apply_all(ctx, [{"type": "steal_item", "items": ["spring_water"], "categories": ["potion"], "chance": 1.0}])
	assert_eq(p.actor.inventory.count("spring_water"), 0, "빼앗겼다")
	e.actor.pool.set_current("hp", 0.0)
	BattlePassives.on_down(b, e)
	assert_eq(p.actor.inventory.count("spring_water"), 1, "쓰러뜨리면 되찾는다")


## 주술사가 살아 있으면 고블린은 달아나지 못하고, 쓰러지면 같은 편이 겁먹는다.
func test_shaman_holds_and_frightens() -> void:
	var t := _battle("goblin_shaman")
	var b: Battle = t[0]
	var sh: Combatant = t[2]
	var gob := b.add(Monster.create(db, "goblin"), Combatant.SIDE_ENEMY)
	b.start()
	assert_true(BattleRules.held_by_pack(b, gob), "주술사가 붙잡는다")
	assert_false(BattleRules.held_by_pack(b, sh), "자기 자신은 아니다")
	var scared := false
	for i in 12:  # 공포 확률 0.9 · 지능 저항 — 여러 번 굴려 본다
		gob.actor.statuses.remove("fear")
		BattlePassives.on_down(b, sh)
		scared = scared or gob.actor.statuses.has("fear")
	assert_true(scared, "주술사가 쓰러지면 공포")


## 떼(박쥐 · 까마귀)는 광역 스킬에 더 아프다.
func test_swarm_takes_more_from_aoe() -> void:
	var t := _battle("canyon_bat")
	var p: Combatant = t[1]
	var e: Combatant = t[2]
	var dmg := {"type": "damage", "scaling": "phys", "power": 1.0, "damage_type": "blunt", "accuracy": 1000}
	var one := 0
	var many := 0
	for k in 6:
		for aoe: bool in [false, true]:
			e.actor.pool.fill_all()
			var ctx := EffectContext.new(db, p.actor, e.actor, Rng.new(40 + k))
			ctx.registry = (t[3] as ContentRegistries).effects
			ctx.info = {"aoe": aoe}
			ctx.registry.apply_all(ctx, [dmg])
			var lost := int(e.actor.pool.get_max("hp") - e.actor.pool.get_current("hp"))
			if aoe:
				many += lost
			else:
				one += lost
	assert_true(many > one, "광역 %d > 단일 %d" % [many, one])


## 덫꾼은 걸어온 길 뒤에 덫을 깐다(무리마다 최대 3).
func test_trapper_lays_traps() -> void:
	var s := _session("f2_goblin_forest", 3)
	var before := s.features.hazards.at.size()
	var g := s.monsters.add_fixed(["goblin_trapper"], s.map.entry)
	assert_true(g != null)
	var region := s.map.zone_ids.find("f2g_eaves")
	var cells: Array[Vector2i] = []
	for y in s.map.height:
		for x in s.map.width:
			var q := Vector2i(x, y)
			if s.map.is_walkable(q) and s.map.zones[s.map.idx(q)] == region and Vector2(q - s.pos).length() > 8.0:
				cells.append(q)
	for q in cells.slice(0, 60):
		g.place(q)
		s.traits.tick(s)
	var laid := s.features.hazards.at.size() - before
	assert_true(laid > 0, "덫이 생겼다")
	assert_true(laid <= 3 * 4, "무리 하나 덫 3개 이하(덫 묶음 칸 수 포함): %d" % laid)


## 늑대 기수: 쫓기 시작하면 망대로 달려간다(생각하지 않고 길만 걷는다).
func test_rider_runs_to_watchtower() -> void:
	var s := _session("f2_goblin_forest", 3)
	assert_true(s.watch != null and not s.watch.towers().is_empty(), "망대")
	var tower: Vector2i = s.watch.towers()[0]["at"]
	var near := tower + Vector2i(0, 12)
	for r in 8:
		if s.map.is_walkable(near):
			break
		near += Vector2i(1, 0)
	var g := s.monsters.add_fixed(["goblin_wolf_rider"], near)
	g.state = FieldMonsters.STATE_CHASE
	s.traits.tick(s)
	assert_true(g.has_meta(MonsterTraits.RUN), "달리기 시작")
	assert_true(not g.route.is_empty(), "망대까지 길")
	var last: Vector2i = g.route[g.route.size() - 1]
	assert_true(Vector2(last - tower).length() <= 3.0, "길 끝 = 망대")


## 멧돼지: 벽 쪽으로 돌진하면 길이 벽 앞에서 끝나고 기절 표시가 붙는다.
func test_boar_charge_into_wall_stuns() -> void:
	var s := _session("f2_beast_den", 3)
	var g := s.monsters.add_fixed(["spine_boar"], s.pos)
	g.state = FieldMonsters.STATE_CHASE
	g.place(s.pos + Vector2i(0, 3) if s.map.is_walkable(s.pos + Vector2i(0, 3)) else s.pos)
	s.traits.tick(s)
	assert_true(g.has_meta("trait_charged"), "돌진했다")
	g.route.clear()
	g.set_meta(MonsterTraits.RUN, "charge")
	g.set_meta("trait_wall", true)
	s.traits.tick(s)
	assert_true(float(g.get_meta(MonsterTraits.STUNNED, -1.0)) > s.clock.total_hours, "벽에 박아 비틀거린다")


## 밤 지역: 원한령은 밤에만 있다.
func test_wraiths_only_at_night() -> void:
	var s := _session("f2_land_of_dead", 3)
	var count := func() -> int: return s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.leader() == "wraith").size()
	s.traits.tick(s)
	var day: int = count.call()
	var to_night := fmod(21.0 - s.clock.hour_of_day() + 24.0, 24.0)
	s.clock.advance(to_night)
	s.traits.tick(s)
	assert_true(count.call() > 0, "밤에는 원한령")
	if s.clock.hour_of_day() >= 19.0 or s.clock.hour_of_day() < 5.0:
		s.clock.advance(12.0)
		s.traits.tick(s)
	assert_true(count.call() <= day + 6, "낮이면 화면 밖 원한령을 거둔다")


## 타일 매복: 진창을 걸으면 익사자가 일어난다(걸음마다 확률, 원정에 max번).
func test_mud_ambush() -> void:
	var s := _session("f2_land_of_dead", 3)
	var rule_def := {"on_tiles": [s.map.tile_id_at(s.pos)], "chance": 1.0, "max": 1, "monsters": ["drowned"], "line": "field.ambush_drowned"}
	var amb := RouteAmbush.new()
	amb._tile_rules.append({"def": rule_def, "left": 1})
	var n := s.monsters.groups.size()
	amb.on_enter(s, s.pos)
	assert_eq(s.monsters.groups.size(), n + 1, "익사자가 일어났다")
	amb.on_enter(s, s.pos)
	assert_eq(s.monsters.groups.size(), n + 1, "원정에 max번까지")


## 횃불 매복: 박쥐 떼는 불을 켰을 때만 깬다.
func test_bats_wake_only_for_torch() -> void:
	var s := _session("f2_beast_den", 3)
	var amb := RouteAmbush.new()
	amb._spots.append({"at": s.pos, "def": {"monsters": ["canyon_bat"], "radius": 6, "lit_only": true}})
	var n := s.monsters.groups.size()
	assert_false(s.player.light.is_lit(), "처음엔 불이 꺼져 있다")
	amb.on_enter(s, s.pos)
	assert_eq(s.monsters.groups.size(), n, "어둠 속이면 그대로")
	assert_eq(amb.spots().size(), 1, "매복은 남는다")
	s.player.light.ignite("torch", 4.0, 1.0)
	amb.on_enter(s, s.pos)
	assert_eq(s.monsters.groups.size(), n + 1, "횃불을 켜면 깬다")
