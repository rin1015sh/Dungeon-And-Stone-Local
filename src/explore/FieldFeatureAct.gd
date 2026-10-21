class_name FieldFeatureAct
extends RefCounted
## 동굴 요소의 행동 하나(FieldFeatures가 부른다). data/events/<id>.json의 actions[]:
##   {"id", "name_ko", "limit": "once"(입장마다 한 번 — 기본) | "day"(미궁 하루에 한 번) | "always",
##    "needs_status": 상태 id(없으면 missing 문구), "cost": {"item", "count"}(없으면 no_cost 문구 — 있으면 가져간다),
##    "line": 문구 키(번호 변형 line.1, line.2 … 중 하나를 고른다. "line_zone": true면 line.<구역>.n),
##    "give": [{"item" 또는 "one_of": [아이템 id …](그중 하나), "count": [최소, 최대], "chance"}](항목마다 따로 굴린다),
##    "effects": [전투 효과 — 대상 = 탐험가](restore_resource·apply_status·remove_status·fatigue …),
##    "learn_stats": 몬스터 id(도감에 생명력·스탯이 드러난다), "alert": {"monster", "radius", "hours"}(근처 그 몬스터 무리가 쫓아온다),
##    "clear": true(하고 나면 요소가 사라진다 — 줍는 것), "done"·"missing" 문구 키(못 하는 이유)}.


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
	var cost := JsonUtil.get_dict(a, "cost")
	var cost_item := JsonUtil.get_str(cost, "item")
	if not cost_item.is_empty():
		if s.player.inventory.count(cost_item) < JsonUtil.get_int(cost, "count", 1):
			s.message.emit(JsonUtil.get_str(a, "missing", "field.no_cost"), {"item": DataNames.entry(s.db, "items", cost_item)}, "info")
			return
		s.player.inventory.remove(cost_item, JsonUtil.get_int(cost, "count", 1))
	used[aid] = today if limit == "day" else true
	say_line(s, JsonUtil.get_str(a, "line"), e, "info", JsonUtil.get_bool(a, "line_zone"))
	_give(s, JsonUtil.get_array(a, "give"))
	_effects(s, JsonUtil.get_array(a, "effects"))
	var learn := JsonUtil.get_str(a, "learn_stats")
	if not learn.is_empty() and s.player.knowledge.learn_stats(learn):
		s.message.emit("field.learned", {"monster": DataNames.entry(s.db, "monsters", learn)}, "good")
	_alert(s, e["pos"], JsonUtil.get_dict(a, "alert"))
	if JsonUtil.get_bool(a, "clear"):
		e["cleared"] = true
		s.map.set_tile(e["pos"], JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "floor", "cave_floor"))
	s.refresh_view()


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
			s.message.emit("field.got" if got == 1 else "field.got_n", {"item": name, "n": got}, "good")
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
