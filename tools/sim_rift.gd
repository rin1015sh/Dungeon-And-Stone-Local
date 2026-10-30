extends SceneTree
## 균열 통과 점검(헤드리스): 모든 균열을 실제 이동(충돌 Kinematics·PlayerMotion)으로 처음부터 끝까지 걸어 본다.
##   godot --headless --path . --script res://tools/sim_rift.gd -- [--rift=<id>] [--seeds=1,2]
## 챕터마다: 조우가 남은 채로도 길목이 열리는지(RF21) → 바닥에 놓인 물건을 모두 줍기(RiftLoot) → 조우 자리로 걸어가 닿으면 이긴 것으로 친다(수수께끼는 정답) → 출구에 필요한 물건(폭약)이 히든 피스면
## 그 옆으로 걸어가 살핀다(아니면 가방에 넣어 준다) → 앞 길목으로 걸어가 넘어가는지 → 뒤 길목으로 걸어 돌아갔다가 다시 앞으로.
## 마지막 챕터는 탈출 포탈에서 살피기로 나간다. 걸어서 닿지 못하거나 넘어가지 않으면 "!!"로 알리고 종료 코드 1.

var _fail: int = 0
var _got: ExploreSession = null


func _initialize() -> void:
	var args := {"seeds": "1"}
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var db := GameDatabase.new()
	db.load_all("res://data")
	var ids: Array = db.get_collection("rifts").keys()
	ids.sort()
	if args.has("rift"):
		ids = [str(args["rift"])]
	for sv: String in str(args["seeds"]).split(","):
		for id: Variant in ids:
			_run(db, str(id), sv.to_int())
	print("균열 통과 점검: %s" % ("모두 통과" if _fail == 0 else "문제 %d개" % _fail))
	quit(1 if _fail > 0 else 0)


func _run(db: GameDatabase, rift_id: String, seed_value: int) -> void:
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", "f1_crystal_cave")
	var map := reg.generator("crystal_cave").generate(db, def, Rng.new(3))
	var pc := PlayerCharacter.create(db, "human", "warrior", "시험", {"str": 18, "agi": 16, "p_res": 14, "m_res": 8, "int": 10})
	pc.set_level(4)
	pc.pool.fill_all()
	var outer := ExploreSession.new(db, def, map, pc, GameClock.new(), Rng.new(seed_value), reg.effects)
	outer.monsters_enabled = false
	outer.start()
	outer.rifts.force_open(outer, rift_id, outer.pos)
	var p: Dictionary = outer.map.portals.filter(func(q: Dictionary) -> bool: return str(q.get("kind", "")) == "rift")[0]
	var cs := outer.rifts.enter(outer, p)
	var run := cs.rift_run
	print("== %s (시드 %d, 챕터 %d)" % [rift_id, seed_value, run.chapters().size()])
	while true:
		var tag := "%s %d챕터" % [rift_id, run.chapter + 1]
		# 조우가 남아도 길목은 열린다(RF21 — 출구 물건이 필요한 챕터는 물건을 쓰게 되니 보지 않는다)
		var needs_item := not JsonUtil.get_dict(run.chapters()[run.chapter], "exit_requires").is_empty()
		if not run.is_last_chapter() and not needs_item and not run.remaining.is_empty() and not run._can_leave(cs, true):
			_bad("%s: 조우가 남았다고 길목이 막힌다(남은 조우 %d)" % [tag, run.remaining.size()])
		if not _clear(cs, tag):
			return
		_pick_loot(cs, tag)
		_fetch_key(cs, tag)
		var exit := RiftPassage.exit_portal(cs.map)
		if exit.is_empty():
			_bad("%s: 출구가 없다" % tag)
			return
		if run.is_last_chapter():
			if not _walk(cs, exit["pos"], tag + " 탈출 포탈"):
				return
			_got = null
			var on_t := func(t: ExploreSession) -> void: _got = t
			cs.transfer.connect(on_t)
			cs.interact()
			cs.transfer.disconnect(on_t)
			if _got != outer:
				_bad("%s: 탈출 포탈에서 살펴도 나가지 않는다(remaining %d, guardian_down %s)" % [tag, run.remaining.size(), run.guardian_down])
				return
			print("   %s: 탈출 — 1층으로" % tag)
			return
		var before := run.chapter
		var next := _walk_through(cs, exit["pos"], tag + " 앞 길목")
		if next == null or run.chapter != before + 1:
			_bad("%s: 앞 길목에서 다음 챕터로 넘어가지 않는다(지금 %s, 챕터 %d)" % [tag, Kinematics.cell_of(cs.fpos), run.chapter + 1])
			return
		# 뒤 길목으로 돌아갔다가 다시 앞으로
		var back := _walk_through(next, next.map.entry, tag + "→뒤 길목")
		if back != cs or run.chapter != before:
			_bad("%s: 다음 챕터 뒤 길목에서 돌아오지 않는다" % tag)
			return
		var again := _walk_through(cs, exit["pos"], tag + " 앞 길목(다시)")
		if again != next:
			_bad("%s: 돌아왔다 다시 앞 길목으로 가지 못한다" % tag)
			return
		print("   %s: 조우 정리·앞으로·뒤로·다시 앞으로 통과" % tag)
		cs = next


## 남은 조우를 모두 찾아가 이긴다(게임은 남겨도 넘어갈 수 있다 — 여기선 모든 조우에 걸어서 닿는지를 본다).
func _clear(cs: ExploreSession, tag: String) -> bool:
	var run := cs.rift_run
	var guard := 0
	# 전투 시작은 정리하는 내내 듣는다 — 이긴 뒤 시간이 흐르는 사이 방의 보스가 알아채 바로 거는 전투(FieldMonsters — 보스는 화면에 들면 곧장)도
	# 놓치지 않게. 걷는 동안만 들으면 그 전투가 끝나지 않은 채(in_combat) 남아 다음 조우로 걸어가지 못했다(녹색 탄광 2챕터 동골렘 → 고블린 폭탄병).
	var hits: Array = []
	var on_enc := func(eg: FieldMonsters.Group, _pf: bool) -> void: hits.append(eg)
	var on_riddle := func(eg: FieldMonsters.Group) -> void: cs.answer_riddle(eg, RiftRiddle.PASS)
	cs.encounter.connect(on_enc)
	cs.riddle_asked.connect(on_riddle)
	while not run.remaining.is_empty() and guard < 20:
		guard += 1
		var g: FieldMonsters.Group = run.remaining[0]
		var reached := true
		if not cs.in_combat:
			reached = _walk(cs, g.pos, "%s 조우 %s" % [tag, g.monster_ids])
		if not reached and hits.is_empty() and run.remaining.has(g):
			break
		while not hits.is_empty():
			var eg: FieldMonsters.Group = hits.pop_front()
			while run.remaining.has(eg) and cs.in_combat:
				var waves := eg.waves.size()
				cs.resolve_encounter(eg, Battle.RESULT_VICTORY, 1, eg.monster_ids.duplicate())
				if waves > 0 and run.remaining.has(eg):
					cs.in_combat = true  # 연전(engage는 call_deferred) — 다음 구성도 이긴 것으로
		cs.player.pool.fill_all()
	cs.encounter.disconnect(on_enc)
	cs.riddle_asked.disconnect(on_riddle)
	if not run.remaining.is_empty():
		_bad("%s: 걸어가 정리하지 못한 조우가 남았다 %d" % [tag, run.remaining.size()])
		return false
	return true


## 바닥에 놓인 물건(RiftLoot)마다 걸어가 줍는다(가방이 차지 않게 주운 것은 바로 뺀다).
func _pick_loot(cs: ExploreSession, tag: String) -> void:
	var n := 0
	for at: Vector2i in cs.loot.keys():
		var d: Dictionary = cs.loot[at]
		if not _walk(cs, at, "%s 물건 %s" % [tag, d["item"]]) or cs.in_combat:
			continue
		cs.interact()
		if cs.loot.has(at):
			_bad("%s: %s의 %s를 줍지 못한다" % [tag, at, d["item"]])
			continue
		cs.player.inventory.remove(str(d["item"]), int(d["count"]))
		n += 1
	if n > 0:
		print("   %s: 놓인 물건 %d개 주움" % [tag, n])


## 출구에 필요한 물건: 이 챕터 히든 피스면 걸어가 살핀다(닿지 못하면 알림), 아니면 가방에 넣는다.
func _fetch_key(cs: ExploreSession, tag: String) -> void:
	var run := cs.rift_run
	var req := JsonUtil.get_dict(run.chapters()[run.chapter], "exit_requires")
	var item := JsonUtil.get_str(req, "item")
	if item.is_empty() or cs.player.inventory.count(item) > 0:
		return
	for at: Vector2i in run.hidden.at:
		if JsonUtil.get_str(run.hidden.at[at], "item") != item:
			continue
		for d in FloorMap.DIRS4:
			if cs.map.is_walkable(at + d) and _walk(cs, at + d, "%s %s 옆" % [tag, item]):
				cs.interact()
				if cs.player.inventory.count(item) > 0:
					print("   %s: %s 획득(히든 피스)" % [tag, item])
					return
		_bad("%s: 히든 피스 %s(%s)를 얻지 못한다" % [tag, item, at])
	cs.player.inventory.add(item, 1)


## 길목으로 걸어가 넘어간 세션을 돌려준다(못 넘어가면 null).
func _walk_through(cs: ExploreSession, cell: Vector2i, label: String) -> ExploreSession:
	_got = null
	var on_t := func(t: ExploreSession) -> void: _got = t
	cs.transfer.connect(on_t)
	_walk(cs, cell, label)
	cs.transfer.disconnect(on_t)
	return _got


## 칸 cell까지 걷는다(4방향 최단 길을 칸 중심으로 따라간다). 전투가 시작되거나 다른 챕터로 넘어가면 멈춘다.
func _walk(cs: ExploreSession, cell: Vector2i, label: String) -> bool:
	_got = null
	var on_t := func(t: ExploreSession) -> void: _got = t
	cs.transfer.connect(on_t)
	var ok := _walk_inner(cs, cell, label)
	cs.transfer.disconnect(on_t)
	return ok


func _walk_inner(cs: ExploreSession, cell: Vector2i, label: String) -> bool:
	var path := _path(cs, Kinematics.cell_of(cs.fpos), cell)
	if path.is_empty():
		_bad("%s: %s에서 %s까지 걸어갈 길이 없다" % [label, Kinematics.cell_of(cs.fpos), cell])
		return false
	for target: Vector2i in path:
		var goal := Kinematics.center_of(target)
		var stuck := 0
		while cs.fpos.distance_to(goal) > 0.06:
			if _got != null or cs.ended:
				return true
			if cs.in_combat:
				return true
			var before := cs.fpos
			var d := goal - cs.fpos
			PlayerMotion.move_by(cs, d.normalized() * minf(0.1, d.length()))
			if cs.in_combat or _got != null:
				return true
			if cs.fpos.distance_to(before) < 0.001:
				stuck += 1
				if stuck > 30:
					_bad("%s: %s 근처에서 막혔다(다음 칸 %s, 목표 %s)" % [label, cs.fpos, target, cell])
					return false
	return true


## 4방향 최단 길(시작 칸 제외, 목표 칸 포함). 목표 칸이 걸을 수 없거나 무리가 서 있어도 마지막 칸으로는 둔다.
func _path(cs: ExploreSession, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var prev := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == to:
			break
		for d in FloorMap.DIRS4:
			var q := p + d
			if prev.has(q) or not cs.map.in_bounds(q):
				continue
			if q != to and (not cs.map.is_walkable(q) or cs.monsters.group_at(q) != null):
				continue
			prev[q] = p
			queue.append(q)
	var out: Array[Vector2i] = []
	if not prev.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(c)
		c = prev[c]
	return out


func _bad(msg: String) -> void:
	_fail += 1
	print("!! " + msg)
