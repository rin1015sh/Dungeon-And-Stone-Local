extends SceneTree
## 1층 걷기 리듬 측정(docs/plans/floor1_fill.md D): 시작 자리에서 네 포탈까지 최단 길을 걸으며
## "무언가를 만나기까지 걸린 실제 초"를 잰다. 무언가 = 전투(닿은 무리 — 바로 이긴 것으로 친다) · 탐험가 무리(지나간다) ·
## 처음 보이는 동굴 요소 · 들리는 소리(비명·싸움 — explore.party.*). 실제 초 = 게임 시간 / realtime_hours_per_sec.
##   godot --headless --path . --script res://tools/sim_walk.gd -- [--seeds=1,2,3] [--day=1] [--no-parties]
## --day=n: n일 차 아침에 출발한다(그 전까지 시작 자리에서 시간만 흘린다 — 시체·약탈자·구울이 늘어난 뒤).
## --no-parties: 층 JSON explorers를 빼고(다른 탐험가 없음) 잰다 — 비교용.

var _events: Array[Dictionary] = []  # {"t": 실제 초, "kind"}
var _pending: FieldMonsters.Group = null
var _met: FieldMonsters.Group = null
var _t0: float = 0.0


func _initialize() -> void:
	var args := {"seeds": "1,2,3"}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
		elif a.begins_with("--"):
			args[a.substr(2)] = "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	var def := db.get_entry("floors", "f1_crystal_cave").duplicate(true)
	if args.has("no-parties"):
		def.erase("explorers")
	var all_gaps: Array[float] = []
	var counts := {}
	var total_sec := 0.0
	for sv: String in str(args["seeds"]).split(","):
		var seed_value := sv.to_int()
		for k in 4:
			var r := _walk(db, def, seed_value, k, maxi(1, str(args.get("day", "1")).to_int()))
			total_sec += float(r["sec"])
			all_gaps.append_array(r["gaps"])
			for kind: String in r["counts"]:
				counts[kind] = int(counts.get(kind, 0)) + int(r["counts"][kind])
			print("시드 %d 포탈 %d: %.0f초, 만남 %d번, 평균 간격 %.1f초, 가장 긴 간격 %.1f초 %s" % [seed_value, k, r["sec"],
				(r["gaps"] as Array).size(), _mean(r["gaps"]), _max(r["gaps"]), r["counts"]])
	all_gaps.sort()
	print("합계: 걸은 시간 %.0f초, 만남 %d번 %s" % [total_sec, all_gaps.size(), counts])
	print("간격: 평균 %.1f초 · 가운데 %.1f초 · 90%% %.1f초 · 가장 긴 %.1f초" % [_mean(all_gaps),
		all_gaps[all_gaps.size() / 2] if not all_gaps.is_empty() else 0.0,
		all_gaps[int(all_gaps.size() * 0.9)] if not all_gaps.is_empty() else 0.0, _max(all_gaps)])
	quit(0)


func _walk(db: GameDatabase, def: Dictionary, seed_value: int, portal_index: int, day: int) -> Dictionary:
	var reg := ContentRegistries.new()
	var map := reg.generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(seed_value))
	var pc := PlayerCharacter.create(db, "human", "warrior", "측정", {})
	var s := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value * 7 + portal_index), reg.effects)
	_events.clear()
	s.encounter.connect(func(g: FieldMonsters.Group, _f: bool) -> void: _pending = g)
	s.party_met.connect(func(g: FieldMonsters.Group) -> void: _met = g)
	s.message.connect(func(key: String, _a: Dictionary, _k: String) -> void:
		if key.begins_with("explore.party.scream") or key.begins_with("explore.party.fight_heard"):
			_add(s, "소리"))
	s.start()
	for h in (day - 1) * 24:
		s.pass_time(1.0)
		_resolve(s)
	_events.clear()
	var t0 := s.clock.total_hours
	var portals := map.portals.filter(func(p: Dictionary) -> bool: return int(p.get("to_floor", 0)) > 0)
	var goal: Vector2i = portals[portal_index % portals.size()]["pos"]
	var path := FieldRoutes.path(map, s.pos, goal, 100000)
	var seen := {}
	var step_h := float(db.bal("explore.move_hours_base", 0.02))
	for cell in path:
		if s.ended:
			break
		s.try_move(cell - s.pos)
		_resolve(s)
		s.pass_time(step_h)
		_resolve(s)
		for f: Dictionary in map.features:
			var key: Vector2i = f["pos"]
			if not seen.has(key) and map.visible_now[map.idx(key)] != 0:
				seen[key] = true
				_add(s, "요소")
	_t0 = t0
	var sec := (s.clock.total_hours - t0) / float(db.bal("explore.realtime_hours_per_sec", 0.1))
	var gaps: Array[float] = []
	var last := 0.0
	for e in _events:
		e["t"] = float(e["t"]) - t0 / 0.1
	var counts := {}
	for e in _events:
		gaps.append(float(e["t"]) - last)
		last = float(e["t"])
		counts[e["kind"]] = int(counts.get(e["kind"], 0)) + 1
	gaps.append(sec - last)
	s.detach()
	return {"sec": sec, "gaps": gaps, "counts": counts}


func _resolve(s: ExploreSession) -> void:
	if _met != null:
		var g := _met
		_met = null
		_add(s, "탐험가")
		FieldPartyMeet.act(s, g, "fight" if str(g.party.get("kind")) == FieldParties.RAIDER else "leave")
	if _pending != null:
		var g := _pending
		_pending = null
		_add(s, "전투")
		s.resolve_encounter(g, Battle.RESULT_VICTORY, 3, g.monster_ids.duplicate())


func _add(s: ExploreSession, kind: String) -> void:
	_events.append({"t": s.clock.total_hours / 0.1, "kind": kind})


func _mean(a: Array) -> float:
	var t := 0.0
	for v: Variant in a:
		t += float(v)
	return t / maxf(1.0, a.size())


func _max(a: Array) -> float:
	var m := 0.0
	for v: Variant in a:
		m = maxf(m, float(v))
	return m
