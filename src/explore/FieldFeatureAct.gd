class_name FieldFeatureAct
extends RefCounted
## 동굴 요소의 행동 하나(FieldFeatures가 부른다). data/events/<id>.json의 actions[]:
##   {"id", "name_ko", "limit": "once"(입장마다 한 번 — 기본) | "day"(미궁 하루에 한 번) | "always",
##    "needs_status": 상태 id(없으면 missing 문구), "cost": {"item", "count"}(없으면 no_cost 문구 — 있으면 가져간다),
##    "line": 문구 키(없어도 된다 — 번호 변형 line.1, line.2 … 중 하나를 고른다. "line_zone": true면 line.<구역>.n),
##    "give": [{"item" 또는 "one_of": [아이템 id …](그중 하나), "count": [최소, 최대], "chance"}](항목마다 따로 굴린다),
##    "effects": [전투 효과 — 대상 = 탐험가](restore_resource·apply_status·remove_status·fatigue …),
##    "learn_stats": 몬스터 id(도감에 생명력·스탯이 드러난다), "alert": {"monster", "radius", "hours"}(근처 그 몬스터 무리가 쫓아온다),
##    "clear": true(하고 나면 요소가 사라진다 — 줍는 것), "done"·"missing" 문구 키(못 하는 이유),
##    "after": {"action", "hours"}(그 행동을 하고 그만큼 지나야 — 아직이면 "wait" 문구, 안 했으면 missing),
##    "sound": 소리 키(data/audio.json sfx — 글 대신 소리로, ExploreSession.sound),
##    "spawn": {"monsters": [id …], "chance", "line"}(그 확률로 바로 옆에 그 무리가 일어나 쫓아온다 — 무덤 파기, FL13),
##    "clear_tile": 타일(clear 뒤 그 칸 — 없으면 층 기본 바닥), "reveal": 칸 반경(그 둘레 지도를 밝힌다 — 망루, FL13), "goto": 표시 이름(map.anchors.marks — 계단으로 옮겨 선다, FL14),
##    "goal": 층 목표 이름(FloorGoal — 하나 센다, 망자의 땅 종 울리기 FL18),
##    "point_to" · "hours_window" · "line_day": 흔적이 가리키는 요소 · 그 시각에만 · 날마다 다른 문구(FieldClues — 레벨 디자인 LD),
##    "hours": 해 보는 데 드는 시간(성공 · 실패 모두 흐른다), "check": {stat, dc}(성공 확률 = RiftHazards.success_chance — 실패면 "fail_line"을 말하고
##    횟수를 쓰지 않는다 — 다시 해 볼 수 있다: 망자의 땅 비석 부수기 GraveWake)}.


static func run(s: ExploreSession, e: Dictionary, a: Dictionary) -> void:
	var aid := JsonUtil.get_str(a, "id")
	var limit := JsonUtil.get_str(a, "limit", "once")
	var used: Dictionary = e["used"]
	var today := floori(s.clock.total_hours / 24.0)
	if (limit == "once" and used.has(aid)) or (limit == "day" and int(used.get(aid, -1)) == today):
		s.message.emit(JsonUtil.get_str(a, "done", "field.done_today" if limit == "day" else "field.done"), {}, "info")
		return
	var need := JsonUtil.get_str(a, "needs_status")
	if not need.is_empty() and not s.player.statuses.has(need):
		s.message.emit(JsonUtil.get_str(a, "missing", "field.missing"), {"status": DataNames.entry(s.db, "statuses", need)}, "info")
		return
	if not FieldClues.in_window(s, JsonUtil.get_dict(a, "hours_window")):
		s.message.emit(JsonUtil.get_str(JsonUtil.get_dict(a, "hours_window"), "missing", "field.missing"), {}, "info")
		return
	var after := JsonUtil.get_dict(a, "after")  # {"action", "hours"}: 그 행동을 하고 hours시간이 지나야(공물의 답례)
	if not after.is_empty():
		var t: Variant = used.get("@" + JsonUtil.get_str(after, "action"))
		if t == null:
			s.message.emit(JsonUtil.get_str(a, "missing", "field.missing"), {}, "info")
			return
		if s.clock.total_hours - float(t) < JsonUtil.get_float(after, "hours"):
			s.message.emit(JsonUtil.get_str(a, "wait", "field.done"), {}, "info")
			return
	var cost := JsonUtil.get_dict(a, "cost")
	var cost_item := JsonUtil.get_str(cost, "item")
	if not cost_item.is_empty():
		if s.player.inventory.count(cost_item) < JsonUtil.get_int(cost, "count", 1):
			s.message.emit(JsonUtil.get_str(a, "missing", "field.no_cost"), {"item": DataNames.entry(s.db, "items", cost_item)}, "info")
			return
		s.player.inventory.remove(cost_item, JsonUtil.get_int(cost, "count", 1))
	if a.has("hours"):
		s.pass_time(JsonUtil.get_float(a, "hours"))
	var check := JsonUtil.get_dict(a, "check")
	if not check.is_empty() and not s.rng.chance(RiftHazards.success_chance(s.db, s.player, check)):
		say_line(s, JsonUtil.get_str(a, "fail_line"), e, "info")
		s.refresh_view()
		return
	used[aid] = today if limit == "day" else true
	used["@" + aid] = s.clock.total_hours  # 한 시각(after가 본다)
	var line := JsonUtil.get_str(a, "line")
	say_line(s, FieldClues.day_key(s, line) if JsonUtil.get_bool(a, "line_day") else line, e, "info", JsonUtil.get_bool(a, "line_zone"))
	if a.has("sound"):
		s.sound.emit(JsonUtil.get_str(a, "sound"), e["pos"])
	_give(s, JsonUtil.get_array(a, "give"))
	_effects(s, JsonUtil.get_array(a, "effects"))
	var learn := JsonUtil.get_str(a, "learn_stats")
	if not learn.is_empty() and s.player.knowledge.learn_stats(learn):
		s.message.emit("field.learned", {"monster": DataNames.entry(s.db, "monsters", learn)}, "good")
	_alert(s, e["pos"], JsonUtil.get_dict(a, "alert"))
	FieldClues.point_to(s, e["pos"], JsonUtil.get_dict(a, "point_to"))
	FieldClues.reveal_traps(s, e["pos"], JsonUtil.get_float(a, "reveal_traps"))
	FieldClues.crush(s, e["pos"], JsonUtil.get_dict(a, "crush"))
	var goto := JsonUtil.get_str(a, "goto")  # 계단(지하 묘실 — FL14): map.anchors.marks의 그 자리로 옮겨 선다
	if not goto.is_empty() and (s.map.anchors.get("marks", {}) as Dictionary).has(goto):
		s.relocate((s.map.anchors["marks"] as Dictionary)[goto])
	if JsonUtil.get_float(a, "reveal") > 0.0:
		FieldClues.reveal_around(s, e["pos"], JsonUtil.get_float(a, "reveal"))
	if JsonUtil.get_bool(a, "clear"):
		e["cleared"] = true
		var floor_tile := JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "floor", "cave_floor")
		s.map.set_tile(e["pos"], JsonUtil.get_str(a, "clear_tile", floor_tile))
		s.tiles_changed.emit(Rect2i(e["pos"], Vector2i.ONE))  # 테두리·소품을 다시 그린다
	_spawn(s, e["pos"], JsonUtil.get_dict(a, "spawn"))
	if a.has("goal") and s.goal != null:  # 층 목표 하나(종 울리기 — FloorGoal, FL18)
		s.goal.advance(s, JsonUtil.get_str(a, "goal"))
	s.refresh_view()


## 무덤에서 일어나는 무리(FL13): chance로 pos 바로 옆에 세우고 곧장 쫓아오게.
static func _spawn(s: ExploreSession, pos: Vector2i, sp: Dictionary) -> void:
	var ids := JsonUtil.get_array(sp, "monsters")
	if ids.is_empty() or not s.monsters_enabled or not s.rng.chance(JsonUtil.get_float(sp, "chance", 1.0)):
		return
	var g := s.monsters.add_fixed(ids, pos + Vector2i.DOWN)
	if g == null:
		return
	g.alert_until = s.clock.total_hours + 1.0
	g.state = FieldMonsters.STATE_CHASE
	say_line(s, JsonUtil.get_str(sp, "line"), {"pos": pos}, "danger")


## 문구 하나: key.1, key.2 …가 있으면 그중 하나(zone이면 key.<구역>.n), 없으면 key 그대로.
static func say_line(s: ExploreSession, key: String, e: Dictionary, kind: String = "info", zone: bool = false) -> void:
	if key.is_empty():
		return
	var base := key + "." + s.map.zone_at(e["pos"]) if zone else key
	var n := 0
	while Strings.has("%s.%d" % [base, n + 1]):
		n += 1
	s.message.emit(base if n == 0 else "%s.%d" % [base, s.rng.randi_range(1, n)], {}, kind)


## say_line과 같되 문구 인자를 넘긴다(탐험가 무리·비명 — FieldParties).
static func say_line_args(s: ExploreSession, key: String, args: Dictionary, kind: String = "info") -> void:
	var n := 0
	while Strings.has("%s.%d" % [key, n + 1]):
		n += 1
	s.message.emit(key if n == 0 else "%s.%d" % [key, s.rng.randi_range(1, n)], args, kind)


## give 목록을 준다(FieldPartyMeet 보답 — 형식은 actions[].give).
static func give_items(s: ExploreSession, list: Array) -> void:
	_give(s, list)


static func _give(s: ExploreSession, list: Array) -> void:
	for g: Variant in list:
		var gd: Dictionary = g if g is Dictionary else {}
		if gd.has("chance") and not s.rng.chance(JsonUtil.get_float(gd, "chance")):
			continue
		var item := JsonUtil.get_str(gd, "item")
		if gd.has("one_of"):
			item = str(s.rng.pick(JsonUtil.get_array(gd, "one_of")))
		var cr := JsonUtil.get_array(gd, "count")
		var n := s.rng.randi_range(int(cr[0]), int(cr[1])) if cr.size() == 2 else 1
		var name := DataNames.entry(s.db, "items", item)
		var got := 0
		for i in n:
			if not s.player.inventory.fits(item, 1):
				break
			s.player.inventory.add(item, 1)
			got += 1
		if got > 0:
			s.message.emit(ItemInfo.got_key(got), {"item": name, "n": got}, "good")
		if got < n:
			s.message.emit("field.no_room", {"item": name}, "warn")


static func _effects(s: ExploreSession, list: Array) -> void:
	if list.is_empty():
		return
	var ctx := EffectContext.new(s.db, s.player, s.player, s.rng)
	ctx.registry = s.effects
	s.effects.apply_all(ctx, list)
	for m: Dictionary in ctx.messages:
		s.message.emit(str(m["key"]), m["args"], str(m["kind"]))


## 근처(radius칸) 그 몬스터 무리가 hours시간 동안 쫓아온다(노움 은닉처).
static func _alert(s: ExploreSession, at: Vector2i, al: Dictionary) -> void:
	var mid := JsonUtil.get_str(al, "monster")
	if mid.is_empty():
		return
	var until := s.clock.total_hours + JsonUtil.get_float(al, "hours", 0.5)
	for g: FieldMonsters.Group in s.monsters.groups:
		if g.leader() == mid and Vector2(g.pos - at).length() <= JsonUtil.get_float(al, "radius", 20.0):
			g.alert_until = until
			g.state = FieldMonsters.STATE_CHASE
