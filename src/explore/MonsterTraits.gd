class_name MonsterTraits
extends RefCounted
## 몬스터 지도 행동(2층 새 몬스터 — docs/plans/floor2_monsters.md): 몬스터 behavior의 키를 보고 탐험 시간마다 한다(순수 로직).
##   lays_traps {event, every_tiles, max, zones}   고블린 덫꾼 — 걸어온 칸 뒤에 지형 덫(event의 hazard)을 하나씩. 무리마다 max까지.
##   runs_to_alarm {radius, monster, alarm_radius, hours, sound, line}  늑대 기수 — 플레이어를 보면 싸우러 오지 않고 radius 안
##       가장 가까운 망대로 달려가 닿으면 그 망대 경보(RouteWatch.ring — monster 무리만 alarm_radius 안). 닿기 전에 잡으면 조용하다.
##   alarm_caller {radius, hours, families, line, sound}  시체 까마귀 — 보면 radius 안의 그 가족 무리가 hours 동안 쫓아오게 하고
##       자기는 쫓지 않는다(한 번 울면 그 뒤로는 떠돈다).
##   charge_line {speed_mult, tiles}               가시등 멧돼지 — 보면 그쪽으로 일직선 돌진(빠르게, 방향을 바꾸지 않는다).
##       벽에 막혀 멈추면 잠깐 비틀거리고, 그 사이 맞닥뜨리면 멧돼지가 기절한 채 전투가 시작된다(STUNNED — BattleFloor).
##   trails [몬스터 id …]                          뼈 하이에나 — 그 몬스터 무리를 8~12칸 뒤에서 따라다닌다.
## 지역 키 hours [from, to](원한령 · 밤 전갈): 그 시간에만 무리가 있다 — 시간이 지나면 화면 밖 무리부터 거두고, 시간이 되면 다시 깐다.
## 걷기 덮어쓰기: Group 메타 RUN이 있으면 FieldMonsters.update가 그 무리는 생각(MonsterMind)하지 않고 route만 따라 걷는다(SPEED 배율).

const RUN := "trait_run"        ## 생각 없이 route를 따라 걷는 중(값 = 끝나면 할 일 "alarm" | "charge")
const SPEED := "trait_speed"    ## 걷기 배율
const STUNNED := "trait_stunned_until"  ## 이 시각 전에 전투가 걸리면 그 무리가 기절한 채 시작
const _TRAIL_FAR := 12.0
const _TRAIL_NEAR := 8.0

var _walked := {}   ## 무리 id → 덫을 놓은 뒤 걸은 칸
var _last := {}     ## 무리 id → 지난 칸
var _laid := {}     ## 무리 id → 놓은 덫 수
var _night_spawned := {}  ## 지역 id → 그 시간대에 깔았다


func tick(s: ExploreSession) -> void:
	if not s.monsters_enabled:
		return
	var now := s.clock.total_hours
	for g: FieldMonsters.Group in s.monsters.groups.duplicate():
		if not g.party.is_empty() or not g.boss.is_empty():
			continue
		var beh := JsonUtil.get_dict(s.db.get_entry("monsters", g.leader()), "behavior")
		if beh.has("lays_traps"):
			_lay_traps(s, g, JsonUtil.get_dict(beh, "lays_traps"))
		if g.has_meta(RUN):
			_follow_run(s, g, beh)
			continue
		if g.state == FieldMonsters.STATE_CHASE:
			if beh.has("runs_to_alarm") and not g.has_meta("trait_rang"):
				_start_alarm_run(s, g, JsonUtil.get_dict(beh, "runs_to_alarm"))
			elif beh.has("alarm_caller") and not g.has_meta("trait_rang"):
				_caw(s, g, JsonUtil.get_dict(beh, "alarm_caller"))
			elif beh.has("charge_line") and not g.has_meta("trait_charged"):
				_start_charge(s, g, JsonUtil.get_dict(beh, "charge_line"))
		elif beh.has("trails"):
			_trail(s, g, JsonUtil.get_array(beh, "trails"))
	_timed_regions(s, now)


# ── 덫꾼 ─────────────────────────────────────────────

func _lay_traps(s: ExploreSession, g: FieldMonsters.Group, d: Dictionary) -> void:
	var was: Vector2i = _last.get(g.id, g.pos)
	_last[g.id] = g.pos
	if was == g.pos or int(_laid.get(g.id, 0)) >= JsonUtil.get_int(d, "max", 3):
		return
	_walked[g.id] = int(_walked.get(g.id, 0)) + 1
	if int(_walked[g.id]) < JsonUtil.get_int(d, "every_tiles", 6):
		return
	var zones := JsonUtil.get_array(d, "zones")
	if not zones.is_empty() and not zones.has(s.map.zone_at(was)):
		return
	if Vector2(was - s.pos).length() < 4.0 or s.features.hazards.at.has(was) or not s.map.portal_at(was).is_empty():
		return
	var hd := JsonUtil.get_dict(s.db.get_entry("events", JsonUtil.get_str(d, "event")), "hazard")
	if hd.is_empty() or s.features.hazards.fit_cells(s, was).is_empty():
		return
	s.features.hazards.add_group(s, hd, was)
	_walked[g.id] = 0
	_laid[g.id] = int(_laid.get(g.id, 0)) + 1


# ── 늑대 기수 ─────────────────────────────────────────

func _start_alarm_run(s: ExploreSession, g: FieldMonsters.Group, d: Dictionary) -> void:
	g.set_meta("trait_rang", true)  # 한 번만(잡히지 않으면 망대에 닿아 울린다)
	if s.watch == null:
		return
	var best := Vector2i(-1, -1)
	var best_d := JsonUtil.get_float(d, "radius", 30.0)
	for t in s.watch.towers():
		var at: Vector2i = t["at"]
		var dist := Vector2(at - g.pos).length()
		if dist <= best_d:
			best = at
			best_d = dist
	if best.x < 0:
		return
	best = RouteAmbush._walkable_near(s.map, best)  # 망대 칸 자체는 걸을 수 없는 소품일 수 있다
	var route := FieldRoutes.path(s.map, g.pos, best, int(s.db.bal("monsters.route_radius", 90)))
	if route.is_empty():
		return
	g.route = route
	g.patrol.clear()
	g.waypoint = Vector2(-1, -1)
	g.state = FieldMonsters.STATE_IDLE
	g.set_meta(RUN, "alarm")
	g.set_meta("trait_target", best)


func _follow_run(s: ExploreSession, g: FieldMonsters.Group, beh: Dictionary) -> void:
	g.state = FieldMonsters.STATE_IDLE
	if not g.route.is_empty():
		return
	var kind := str(g.get_meta(RUN))
	g.remove_meta(RUN)
	if g.has_meta(SPEED):
		g.remove_meta(SPEED)
	match kind:
		"flyoff":  # 까마귀: 울고 난 뒤에는 플레이어에게서 멀어지며 떠돈다
			g.route = FieldRoutes.path(s.map, g.pos, _away(s, g, 8), 30)
			if not g.route.is_empty():
				g.set_meta(RUN, "flyoff")
			return
		"alarm":
			var at: Vector2i = g.get_meta("trait_target", g.pos)
			if Vector2(at - g.pos).length() <= 3.0:
				s.watch.ring(s, at, JsonUtil.get_dict(beh, "runs_to_alarm"))
		"charge":
			var d := JsonUtil.get_dict(beh, "charge_line")
			if g.has_meta("trait_wall"):
				g.remove_meta("trait_wall")
				g.set_meta(STUNNED, s.clock.total_hours + JsonUtil.get_float(d, "stun_hours", 0.15))
				g.held_until = s.clock.total_hours + JsonUtil.get_float(d, "stun_hours", 0.15)
				FieldFeatureAct.say_line(s, JsonUtil.get_str(d, "line", "field.boar_wall"), {"pos": g.pos}, "info")
	g.state = FieldMonsters.STATE_CHASE
	g.alert_until = s.clock.total_hours + 0.3


# ── 시체 까마귀 ───────────────────────────────────────

func _caw(s: ExploreSession, g: FieldMonsters.Group, d: Dictionary) -> void:
	g.set_meta("trait_rang", true)
	var r := JsonUtil.get_float(d, "radius", 20.0)
	var fams := JsonUtil.get_array(d, "families")
	var until := s.clock.total_hours + JsonUtil.get_float(d, "hours", 0.5)
	for o: FieldMonsters.Group in s.monsters.groups:
		if o == g or not o.hostile() or not o.party.is_empty() or Vector2(o.pos - g.pos).length() > r:
			continue
		var fam := JsonUtil.get_array(s.db.get_entry("monsters", o.leader()), "family")
		if fams.is_empty() or fams.any(func(f: Variant) -> bool: return fam.has(f)):
			o.alert_until = until
			o.state = FieldMonsters.STATE_CHASE
	if d.has("sound"):
		s.sound.emit(JsonUtil.get_str(d, "sound"), g.pos)
	FieldFeatureAct.say_line(s, JsonUtil.get_str(d, "line"), {"pos": g.pos}, "danger")
	# 자기는 쫓지 않고 둘레를 떠돈다
	g.route = FieldRoutes.path(s.map, g.pos, _away(s, g, 8), 30)
	g.state = FieldMonsters.STATE_IDLE
	g.set_meta(RUN, "flyoff")


func _away(s: ExploreSession, g: FieldMonsters.Group, n: int) -> Vector2i:
	var dir := Vector2(g.pos - s.pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	for k in range(n, 0, -1):
		var q := g.pos + Vector2i(roundi(dir.x * k), roundi(dir.y * k))
		if s.map.in_bounds(q) and s.map.is_walkable(q):
			return q
	return g.pos


# ── 멧돼지 돌진 ───────────────────────────────────────

func _start_charge(s: ExploreSession, g: FieldMonsters.Group, d: Dictionary) -> void:
	g.set_meta("trait_charged", true)
	var dir := Vector2(s.pos - g.pos)
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var route: Array[Vector2i] = []
	var wall := false
	var prev := g.pos
	for k in range(1, JsonUtil.get_int(d, "tiles", 14) + 1):
		var q := g.pos + Vector2i(roundi(dir.x * k), roundi(dir.y * k))
		if q == prev:
			continue
		if not s.map.in_bounds(q) or not s.map.is_walkable(q):
			wall = true
			break
		route.append(q)
		prev = q
	if route.is_empty():
		return
	g.route = route
	g.patrol.clear()
	g.waypoint = Vector2(-1, -1)
	g.state = FieldMonsters.STATE_IDLE
	g.set_meta(RUN, "charge")
	g.set_meta(SPEED, JsonUtil.get_float(d, "speed_mult", 2.5))
	if wall:
		g.set_meta("trait_wall", true)


# ── 하이에나 ──────────────────────────────────────────

func _trail(s: ExploreSession, g: FieldMonsters.Group, kinds: Array) -> void:
	if not g.route.is_empty():
		return
	var best: FieldMonsters.Group = null
	var best_d := 40.0
	for o: FieldMonsters.Group in s.monsters.groups:
		if o != g and kinds.has(o.leader()):
			var dist := Vector2(o.pos - g.pos).length()
			if dist < best_d:
				best = o
				best_d = dist
	if best == null:
		return
	if best.state == FieldMonsters.STATE_CHASE:  # 늑대가 싸우러 가면 뒤따라 끼어든다
		g.state = FieldMonsters.STATE_CHASE
		g.alert_until = maxf(g.alert_until, best.alert_until)
		return
	if best_d > _TRAIL_FAR:
		var to := best.pos + Vector2i(roundi(signf(g.pos.x - best.pos.x) * _TRAIL_NEAR), roundi(signf(g.pos.y - best.pos.y) * _TRAIL_NEAR))
		s.monsters.send_to(g, to if s.map.in_bounds(to) and s.map.is_walkable(to) else best.pos, s.pos)


# ── 시간대 지역(원한령 · 밤 전갈) ─────────────────────

func _timed_regions(s: ExploreSession, now: float) -> void:
	for v: Variant in JsonUtil.get_array(s.floor_def, "regions"):
		var r: Dictionary = v if v is Dictionary else {}
		var hours := JsonUtil.get_array(r, "hours")
		if hours.size() != 2:
			continue
		var rid := JsonUtil.get_str(r, "id")
		var open := FieldClues.in_window(s, {"from": float(hours[0]), "to": float(hours[1])})
		if open and not _night_spawned.get(rid, false):
			_night_spawned[rid] = true
			var range_ := JsonUtil.get_array(r, "groups")
			var n := s.rng.randi_range(int(range_[0]), int(range_[1])) if range_.size() == 2 else 1
			if s.monsters.groups.filter(func(g: FieldMonsters.Group) -> bool: return g.region == rid).is_empty():
				for i in n:
					s.monsters.spawn_group(r, s.pos)
				s.monsters.changed.emit()
		elif not open:
			_night_spawned[rid] = false
			for g: FieldMonsters.Group in s.monsters.groups.duplicate():
				if g.region == rid and g.state != FieldMonsters.STATE_CHASE and not s.monsters.is_visible(g, s.pos):
					s.monsters.remove(g, now)
