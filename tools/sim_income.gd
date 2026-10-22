extends SceneTree
## 1층 원정 한 번의 벌이(docs/plans/dungeon_loop_review.md A3): 시작 자리에서 포탈 하나로 가며 눈에 띈 동굴 요소에 들러 모두 살피고,
## 만난 무리는 모두 이긴 것으로 치고(정수·마석은 가방으로), 탐험가 무리는 지나간다(약탈자는 싸운다). 시간 상한이 되면 포탈로 간다.
## 벌이 = 돈 + 가방 물건의 도시 판매가(신원패는 길드 반납가) — 출처별(몬스터·약탈자·탐험가·요소)로 나눈다. 쓴 소모품·다친 몸은 세지 않는다(총수입).
## 조사 기록(길드)은 잡은 종의 생명력·상성을 다 알았다고 칠 때의 값을 따로 낸다(처음 한 번만 팔린다).
##   godot --headless --path . --script res://tools/sim_income.gd -- [--seeds=1,2,3] [--hours=60] [--detour=30] [--bag=10x6]
## 요소는 가까운 것부터(detour 칸 안에 없으면 가장 가까운 것) — 기념비 둘레부터 넓혀 간다.
## --hours: 이 게임 시간이 지나면 남은 요소를 두고 포탈로 간다(포탈 길에서 만나는 것까지 센다). --bag: 가방 크기(넘친 물건은 두고 간다).

const SOURCES := ["몬스터", "약탈자", "탐험가", "요소"]

var _pending: FieldMonsters.Group = null
var _met: FieldMonsters.Group = null
var _city: CityState
var _tag_value: int = 0


func _initialize() -> void:
	var args := {"seeds": "1,2,3", "hours": "60", "detour": "30", "bag": "10x6"}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var db := GameDatabase.new()
	db.load_all("res://data")
	_city = CityState.new(db, 1)
	_city.start()
	for fx: Variant in JsonUtil.get_array(db.get_entry("activities", "guild_tags"), "effects"):
		if JsonUtil.get_str(fx, "type") == "return_tags":
			_tag_value = int(CityValues.num(fx, "stones_each"))
	var def := db.get_entry("floors", "f1_crystal_cave")
	var bag := str(args["bag"]).split("x")
	var totals := {}
	var feat := {}
	var runs := 0
	for sv: String in str(args["seeds"]).split(","):
		for k in 4:
			var r := _run(db, def, sv.to_int(), k, float(str(args["hours"])), int(str(args["detour"])), Vector2i(bag[0].to_int(), bag[1].to_int()))
			runs += 1
			print("시드 %s 포탈 %d: %.0f시간 · 전투 %d(%d마리) · 요소 %d곳 · 탐험가 %d · 정수 %d · 벌이 %d %s · 놓친 물건 %d번" % [sv, k, r["hours"],
				r["battles"], r["kills"], r["features"], r["meets"], r["essences"], r["total"], r["by"], r["lost"]])
			for key: String in r:
				if r[key] is int or r[key] is float:
					totals[key] = float(totals.get(key, 0.0)) + float(r[key])
			for src: String in r["by"]:
				totals["by:" + src] = float(totals.get("by:" + src, 0.0)) + float(r["by"][src])
			for fid: String in r["feat"]:
				feat[fid] = int(feat.get(fid, 0)) + int(r["feat"][fid])
	var avg := func(key: String) -> float: return float(totals.get(key, 0.0)) / maxf(1.0, runs)
	var by := PackedStringArray()
	for src: String in SOURCES:
		by.append("%s %d" % [src, roundi(avg.call("by:" + src))])
	print("평균(%d번): %.0f시간 · 전투 %.1f(%.1f마리) · 요소 %.1f곳 · 정수 %.2f · 벌이 %d스톤 [%s] · 조사 기록(처음 한 번) %d" % [runs,
		avg.call("hours"), avg.call("battles"), avg.call("kills"), avg.call("features"), avg.call("essences"), roundi(avg.call("total")),
		", ".join(by), roundi(avg.call("records"))])
	var ids := feat.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool: return int(feat[a]) > int(feat[b]))
	var top := PackedStringArray()
	for fid: Variant in ids:
		if int(feat[fid]) > 0:
			top.append("%s %d" % [fid, roundi(float(feat[fid]) / runs)])
	print("요소별 평균 벌이: " + ", ".join(top))
	print("탐험가 무리를 만난 수(평균): %.1f" % avg.call("meets"))
	quit(0)


func _run(db: GameDatabase, def: Dictionary, seed_value: int, portal_index: int, max_hours: float, detour: int, bag: Vector2i) -> Dictionary:
	var reg := ContentRegistries.new()
	var map := reg.generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "측정", {})
	pc.inventory.width = bag.x
	pc.inventory.height = bag.y
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value * 7 + portal_index), reg.effects)
	var r := {"hours": 0.0, "battles": 0, "kills": 0, "features": 0, "essences": 0, "lost": 0, "total": 0, "records": 0, "meets": 0, "by": {}, "feat": {}}
	for src: String in SOURCES:
		r["by"][src] = 0
	var killed := {}
	s.encounter.connect(func(g: FieldMonsters.Group, _f: bool) -> void: _pending = g)
	s.party_met.connect(func(g: FieldMonsters.Group) -> void: _met = g)
	s.message.connect(func(key: String, _a: Dictionary, _k: String) -> void:
		if key == "reward.bag_full":
			r["lost"] = int(r["lost"]) + 1)
	s.start()
	var t0 := s.clock.total_hours
	var portals := map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) > 0)
	var goal: Vector2i = portals[portal_index % portals.size()]["pos"]
	var visited := {}
	var step_h := float(db.bal("explore.move_hours_base", 0.02))
	for guard in 2000:
		if s.ended or s.pos == goal:
			break
		var target := Vector2i(-1, -1)
		if s.clock.total_hours - t0 < max_hours:
			target = _nearest_feature(s, visited, detour)
			if target.x < 0:
				target = _nearest_feature(s, visited, 100000)
		var path: Array[Vector2i] = []
		if target.x >= 0:
			visited[target] = true
			path = FieldRoutes.path(map, s.pos, target, 100000)
		if path.is_empty():
			path = FieldRoutes.path(map, s.pos, goal, 100000).slice(0, 40)
		for cell in path:
			if s.ended:
				break
			s.try_move(cell - s.pos)
			pc.pool.fill("hunger")
			_resolve(s, r, killed)
			s.pass_time(step_h)
			_resolve(s, r, killed)
		if target.x >= 0 and not s.ended and Vector2(s.pos - target).length() <= 1.5:
			var before := _value(pc)
			for a: Dictionary in s.features.actions_at(target):
				s.features.act(s, target, str(a["id"]))
				_resolve(s, r, killed)
			var got := _value(pc) - before
			var fid := str(s.features._by_cell.get(target, {}).get("id", "?"))
			r["features"] = int(r["features"]) + 1
			r["by"]["요소"] = int(r["by"]["요소"]) + got
			r["feat"][fid] = int(r["feat"].get(fid, 0)) + got
	r["hours"] = s.clock.total_hours - t0
	for src: String in SOURCES:
		r["total"] = int(r["total"]) + int(r["by"][src])
	r["records"] = _records(db, killed)
	s.detach()
	return r


## 지금 자리에서 detour 칸 안의, 드러나 있고 아직 들르지 않은 요소 중 가장 가까운 것(없으면 (-1, -1)).
func _nearest_feature(s: ExploreSession, visited: Dictionary, detour: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := float(detour)
	for e: Dictionary in s.features.list:
		var p: Vector2i = e["pos"]
		if visited.has(p) or not bool(e["found"]) or bool(e["cleared"]) or JsonUtil.get_array(e["def"], "actions").is_empty():
			continue
		var d := Vector2(p - s.pos).length()
		if d <= best_d:
			best_d = d
			best = p
	return best


func _resolve(s: ExploreSession, r: Dictionary, killed: Dictionary) -> void:
	if _met != null:
		var g := _met
		_met = null
		r["meets"] = int(r["meets"]) + 1
		var before := _value(s.player)
		FieldPartyMeet.act(s, g, "fight" if str(g.party.get("kind")) == FieldParties.RAIDER else "leave")
		r["by"]["탐험가"] = int(r["by"]["탐험가"]) + _value(s.player) - before
	if _pending != null:
		var g := _pending
		_pending = null
		var src := "약탈자" if not g.party.is_empty() else "몬스터"
		var before := _value(s.player)
		var ids := g.monster_ids.duplicate()
		r["battles"] = int(r["battles"]) + 1
		r["kills"] = int(r["kills"]) + ids.size()
		for id: String in ids:
			killed[id] = true
		s.grant_battle_rewards(g, ids, [], true)
		for drop: Dictionary in s.battle_drops.duplicate():
			if str(drop.get("kind")) == "essence":
				r["essences"] = int(r["essences"]) + 1
				s.leave_drop(drop)
			else:
				s.take_drop(drop, s.player)
		s.resolve_encounter(g, Battle.RESULT_VICTORY, 3, ids)
		r["by"][src] = int(r["by"][src]) + _value(s.player) - before


## 돈 + 가방 물건을 도시에서 팔 때의 값(신원패 = 길드 반납가).
func _value(pc: PlayerCharacter) -> int:
	var v := pc.inventory.money
	for id in pc.inventory.ids():
		var each := _tag_value if id == "explorer_tag" else (CityShop.sell_price(_city, id) if CityShop.can_sell(_city, id) else 0)
		v += each * pc.inventory.count(id)
	return v


## 잡은 종의 생명력·상성을 다 알았을 때 길드가 처음 한 번 쳐 주는 값.
func _records(db: GameDatabase, killed: Dictionary) -> int:
	var fx := {}
	for f: Variant in JsonUtil.get_array(db.get_entry("activities", "guild_records"), "effects"):
		if JsonUtil.get_str(f, "type") == "sell_records":
			fx = f
	var pay := 0
	for id: String in killed:
		var m := db.get_entry("monsters", id)
		if JsonUtil.get_str(m, "rank") == "human":
			continue
		var scale := maxi(1, 10 - JsonUtil.get_int(m, "grade", 9))
		var affs := JsonUtil.get_dict(m, "weaknesses").size() + JsonUtil.get_array(m, "immunities").size()
		pay += scale * (int(CityValues.num(fx, "stats_stones")) + affs * int(CityValues.num(fx, "affinity_stones")))
	return pay
