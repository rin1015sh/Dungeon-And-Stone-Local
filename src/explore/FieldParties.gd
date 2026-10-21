class_name FieldParties
extends RefCounted
## 1층의 다른 탐험가들(순수 로직, 층 JSON "explorers" — 없으면 아무것도 하지 않는다. 균열 챕터에는 없다).
## 탐험가 무리 = FieldMonsters.Group(party = {"kind", "members", "look", …}). 지도 위를 걷고(멀리 쉬는 무리는 바로 옮긴다),
## 닿으면 선택 창(FieldPartyMeet). 시간마다(한 시간에 한 번) 굴린다:
##   rookie   신참 파티: 돌아다닌다(portal_from_day일 차부터는 포탈 쪽으로). death_per_hour(암흑지대 ×dark_mult, 날마다 +day_add)로 죽는다.
##            약탈자가 raider_kill_tiles 안이면 raider_kill_chance로 당한다.
##   wounded  다친 탐험가: 플레이어 둘레(near_tiles)에 wounded_per_hour로 생긴다. wounded_hours가 지나면 숨진다.
##   fighting 싸우는 탐험가: fight_per_hour로 생기고 곁에 그 지역 몬스터 무리. fight_hours 뒤 fight_death로 진다(이기면 신참).
##   raider   약탈자: 날마다 raiders_by_day 무리, 가까운 신참을 쫓는다(raider_hunt_tiles). 플레이어에게는 통행세 → 싸움.
## 누가 죽으면 그 자리에 갓 죽은 탐험가(events fresh_corpse)가 남고, 들리는 거리(scream_tiles)면 방향과 함께 비명이 들린다.
## 시체 냄새를 맡는 몬스터(behavior seeks_corpses_tiles — 구울)가 그쪽으로 모인다. 보이지 않는 곳에서도 unseen_corpse_per_hour로 시체가 생긴다.
## 날짜(1일 차 = 0번)마다 rookies_by_day 만큼 신참이 채워지고 raiders_by_day 만큼 약탈자가 채워진다(F — 날마다 바뀌는 1층).

const ROOKIE := "rookie"
const WOUNDED := "wounded"
const FIGHTING := "fighting"
const RAIDER := "raider"

var def: Dictionary = {}
var _acc: float = 0.0
var _day: int = -1


func setup(s: ExploreSession) -> void:
	def = JsonUtil.get_dict(s.floor_def, "explorers")


func enabled() -> bool:
	return not def.is_empty()


## 입장 직후(몬스터가 나타난 뒤) 한 번.
func start(s: ExploreSession) -> void:
	if not enabled():
		return
	_day = 0
	_fill_day(s)


## 시간이 흘렀다(ExploreSession.pass_time). 한 시간이 찰 때마다 굴리고, 함께 다니는 무리는 늘 곁으로.
func update(s: ExploreSession, hours: float) -> void:
	if not enabled():
		return
	_acc += hours
	while _acc >= 1.0 and not s.in_combat and not s.ended:
		_acc -= 1.0
		_tick_hour(s)
	FieldPartyMeet.follow(s, self)


func all(s: ExploreSession) -> Array[FieldMonsters.Group]:
	var out: Array[FieldMonsters.Group] = []
	for g in s.monsters.groups:
		if not g.party.is_empty():
			out.append(g)
	return out


func of_kind(s: ExploreSession, kind: String) -> Array[FieldMonsters.Group]:
	return all(s).filter(func(g: FieldMonsters.Group) -> bool: return str(g.party.get("kind")) == kind)


## 한곳에 함께 있는 탐험가 수(계층군주 소환 조건) = 플레이어 + 곁에서 함께 다니는 무리.
func party_size(s: ExploreSession) -> int:
	var n := 1
	for g in all(s):
		if float(g.party.get("follow_until", -1.0)) > s.clock.total_hours and g.fpos.distance_to(s.fpos) <= 4.0:
			n += int(g.party.get("members", 1))
	return n


## 함께 다니는 무리가 있으면 밖에서 쉴 때 습격 확률 배율(망을 봐 준다).
func watch_mult(s: ExploreSession) -> float:
	return JsonUtil.get_float(def, "watch_ambush_mult", 1.0) if party_size(s) > 1 else 1.0


## 탐험가 무리에 닿았다(ExploreSession.engage). 선택 창을 띄웠으면 true — 싸움이 되면(약탈자가 답을 들었다) false.
func meets(s: ExploreSession, g: FieldMonsters.Group) -> bool:
	if g.party.is_empty() or (str(g.party.get("kind")) == RAIDER and bool(g.party.get("asked", false))):
		return false
	s.party_met.emit(g)
	return true


## 전투가 끝났다(ExploreSession.resolve_encounter — 무리를 지우기 전). 약탈자를 이기면 유품, 탐험가와 싸우던 몬스터를 이기면 고마움.
func on_battle_end(s: ExploreSession, g: FieldMonsters.Group, result: String) -> void:
	if g == null or result != Battle.RESULT_VICTORY:
		return
	if str(g.party.get("kind")) == RAIDER:
		s.features.add_runtime(s, "raider_remains", g.pos)
		s.refresh_view()
		return
	for p in of_kind(s, FIGHTING):
		if int(p.party.get("foe", -1)) == g.id:
			FieldPartyMeet.thank(s, p)


## 무리가 죽었다: 지우고 그 자리에 시체, 들리면 비명(scream), 구울이 모인다.
func kill(s: ExploreSession, g: FieldMonsters.Group, scream: bool) -> void:
	s.monsters.groups.erase(g)
	_release_foe(s, g)
	s.monsters.changed.emit()
	drop_corpse(s, g.pos, scream)


func drop_corpse(s: ExploreSession, at: Vector2i, scream: bool) -> void:
	var e := s.features.add_runtime(s, "fresh_corpse", at)
	if e.is_empty():
		return
	var cell: Vector2i = e["pos"]
	var d := Vector2(cell - s.pos).length()
	if scream and d <= JsonUtil.get_float(def, "scream_tiles", 140.0):
		var near := d <= JsonUtil.get_float(def, "near_tiles_sound", 30.0)
		FieldFeatureAct.say_line_args(s, "explore.party.scream_near" if near else "explore.party.scream",
			{"dir": dir_word(s.pos, cell)}, "warn")
	_attract(s, cell)
	if s.map.visible_now[s.map.idx(cell)] != 0:
		s.refresh_view()


## 플레이어 자리에서 본 방향 낱말(8방향, data/strings dir8).
static func dir_word(from: Vector2i, to: Vector2i) -> String:
	var d := Vector2(to - from)
	if d.length() < 0.5:
		return Strings.t("dir8.here")
	var k := posmod(roundi(atan2(d.x, -d.y) / (PI / 4.0)), 8)
	return Strings.t("dir8.%d" % k)


# ── 내부 ─────────────────────────────────────────────────

func _tick_hour(s: ExploreSession) -> void:
	var day := floori(s.clock.total_hours / 24.0)
	if day != _day:
		_day = day
		_fill_day(s)
	var now := s.clock.total_hours
	var raiders := of_kind(s, RAIDER)
	for g in all(s):
		match str(g.party.get("kind")):
			ROOKIE:
				_rookie_hour(s, g, raiders, day)
			WOUNDED:
				if now >= float(g.party.get("dies_at", INF)):
					kill(s, g, false)
			FIGHTING:
				if now >= float(g.party.get("fight_until", INF)):
					_fight_over(s, g)
			RAIDER:
				_raider_hour(s, g)
	_events(s, day)


func _rookie_hour(s: ExploreSession, g: FieldMonsters.Group, raiders: Array[FieldMonsters.Group], day: int) -> void:
	if float(g.party.get("follow_until", -1.0)) > s.clock.total_hours:
		return
	var p := JsonUtil.get_float(def, "death_per_hour") * (1.0 + day * JsonUtil.get_float(def, "day_add"))
	if s.map.is_dark(g.pos):
		p *= JsonUtil.get_float(def, "dark_mult", 1.0)
	var kill_r := JsonUtil.get_float(def, "raider_kill_tiles", 3.0)
	for r in raiders:
		if r.hostile() and r.fpos.distance_to(g.fpos) <= kill_r:
			p = maxf(p, JsonUtil.get_float(def, "raider_kill_chance", 0.5))
	if s.rng.chance(p):
		kill(s, g, true)
	elif g.route.is_empty() and s.rng.chance(JsonUtil.get_float(def, "travel_chance", 0.5)):
		s.monsters.send_to(g, _destination(s, g, day), s.pos)


func _raider_hour(s: ExploreSession, g: FieldMonsters.Group) -> void:
	if g.state == FieldMonsters.STATE_CHASE or not g.route.is_empty():
		return
	var best: FieldMonsters.Group = null
	var hunt := JsonUtil.get_float(def, "raider_hunt_tiles", 60.0)
	for r in of_kind(s, ROOKIE):
		var d := r.fpos.distance_to(g.fpos)
		if d <= hunt and (best == null or d < best.fpos.distance_to(g.fpos)):
			best = r
	var to := best.pos if best != null else _random_cell(s, g.pos, 50)
	if to.x >= 0:
		s.monsters.send_to(g, to, s.pos)


func _fight_over(s: ExploreSession, g: FieldMonsters.Group) -> void:
	var foe := _foe(s, g)
	if foe == null or not s.rng.chance(JsonUtil.get_float(def, "fight_death", 0.6)):
		if foe != null:
			s.monsters.groups.erase(foe)
			s.monsters.changed.emit()
		g.party["kind"] = ROOKIE
		g.party.erase("foe")
		return
	kill(s, g, true)


## 날이 바뀌었다: 신참·약탈자를 그날 수만큼 채운다.
func _fill_day(s: ExploreSession) -> void:
	var rookies := _by_day("rookies_by_day") - of_kind(s, ROOKIE).size()
	for i in rookies:
		_spawn(s, ROOKIE, _spawn_cell(s, _day >= JsonUtil.get_int(def, "portal_from_day", 99) - 1))
	var raiders := _by_day("raiders_by_day") - of_kind(s, RAIDER).filter(func(g: FieldMonsters.Group) -> bool: return g.hostile()).size()
	for i in raiders:
		_spawn(s, RAIDER, _spawn_cell(s, false))


## 플레이어 둘레의 사건: 다친 탐험가·싸우는 탐험가, 보이지 않는 곳의 시체.
func _events(s: ExploreSession, day: int) -> void:
	var near := JsonUtil.get_array(def, "near_tiles")
	var lo := int(near[0]) if near.size() == 2 else 25
	var hi := int(near[1]) if near.size() == 2 else 50
	if s.rng.chance(JsonUtil.get_float(def, "wounded_per_hour")):
		var c := _ring_cell(s, lo, hi)
		var g := _spawn(s, WOUNDED, c)
		if g != null:
			g.party["dies_at"] = s.clock.total_hours + JsonUtil.get_float(def, "wounded_hours", 10.0)
	if s.rng.chance(JsonUtil.get_float(def, "fight_per_hour")):
		_spawn_fight(s, _ring_cell(s, lo, hi))
	if s.rng.chance(JsonUtil.get_float(def, "unseen_corpse_per_hour") * (1.0 + day * JsonUtil.get_float(def, "day_add"))):
		var c := _spawn_cell(s, false)
		if c.x >= 0 and s.map.explored[s.map.idx(c)] == 0:
			drop_corpse(s, c, false)


func _spawn_fight(s: ExploreSession, at: Vector2i) -> void:
	var g := _spawn(s, FIGHTING, at)
	if g == null:
		return
	var region := _region_at(s, g.pos)
	var foe := s.monsters.spawn_group(region, s.pos, g.pos) if not region.is_empty() else null
	if foe == null:
		g.party["kind"] = ROOKIE
		return
	var until := s.clock.total_hours + JsonUtil.get_float(def, "fight_hours", 1.5)
	g.party["foe"] = foe.id
	g.party["fight_until"] = until
	foe.grace_until = until  # 탐험가와 싸우느라 플레이어를 쫓지 않는다
	FieldFeatureAct.say_line_args(s, "explore.party.fight_heard", {"dir": dir_word(s.pos, g.pos)}, "warn")


func _spawn(s: ExploreSession, kind: String, at: Vector2i) -> FieldMonsters.Group:
	if at.x < 0:
		return null
	var looks := JsonUtil.get_array(def, "looks")
	var party := {"kind": kind, "look": str(s.rng.pick(looks)) if not looks.is_empty() else "human"}
	var ids: Array = []
	if kind == RAIDER:
		for id: Variant in JsonUtil.get_array(def, "raider_pack"):
			if s.rng.chance(JsonUtil.get_float(def, "raider_member_chance", 0.7)) or ids.is_empty():
				ids.append(str(id))
		if _day + 1 >= JsonUtil.get_int(def, "chief_from_day", 4):
			ids.append(JsonUtil.get_str(def, "raider_chief", "raider_chief"))
		party["members"] = ids.size()
	else:
		var m := JsonUtil.get_array(def, "members")
		party["members"] = 1 if kind == WOUNDED else (s.rng.randi_range(int(m[0]), int(m[1])) if m.size() == 2 else 3)
	if kind == ROOKIE:
		var offers := JsonUtil.get_array(def, "trades")
		if not offers.is_empty():
			party["trade"] = (s.rng.pick(offers) as Dictionary).duplicate()
	return s.monsters.add_party(ids, at, party)


func _destination(s: ExploreSession, g: FieldMonsters.Group, day: int) -> Vector2i:
	if day + 1 >= JsonUtil.get_int(def, "portal_from_day", 99):
		var best := Vector2i(-1, -1)
		for p: Dictionary in s.map.portals:
			if int(p.get("to_floor", 0)) > 0 and (best.x < 0 or (p["pos"] - g.pos).length_squared() < (best - g.pos).length_squared()):
				best = p["pos"]
		if best.x >= 0:
			return FieldRoutes.random_cell_near(s.map, s.rng, best, 10)
	return _random_cell(s, g.pos, 50)


func _spawn_cell(s: ExploreSession, near_portal: bool) -> Vector2i:
	if near_portal and not s.map.portals.is_empty():
		var p: Dictionary = s.rng.pick(s.map.portals)
		var c := FieldRoutes.random_cell_near(s.map, s.rng, p["pos"], 20, _hidden_from(s))
		if c.x >= 0:
			return c
	for attempt in 30:
		var c := Vector2i(s.rng.randi_range(1, s.map.width - 2), s.rng.randi_range(1, s.map.height - 2))
		if s.map.is_walkable(c) and not s.map.in_safe_zone(c) and bool(_hidden_from(s).call(c)) and Vector2(c - s.pos).length() >= 20.0:
			return c
	return Vector2i(-1, -1)


## 플레이어에게서 lo~hi칸 떨어진, 지금 보이지 않는 칸.
func _ring_cell(s: ExploreSession, lo: int, hi: int) -> Vector2i:
	for attempt in 40:
		var a := s.rng.randf() * TAU
		var r := s.rng.randf_range(lo, hi)
		var c := s.pos + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
		if s.map.is_walkable(c) and not s.map.in_safe_zone(c) and s.map.portal_at(c).is_empty() and bool(_hidden_from(s).call(c)):
			return c
	return Vector2i(-1, -1)


func _random_cell(s: ExploreSession, around: Vector2i, radius: int) -> Vector2i:
	return FieldRoutes.random_cell_near(s.map, s.rng, around, radius)


func _hidden_from(s: ExploreSession) -> Callable:
	return func(c: Vector2i) -> bool: return s.map.in_bounds(c) and s.map.visible_now[s.map.idx(c)] == 0


func _region_at(s: ExploreSession, p: Vector2i) -> Dictionary:
	var zone := s.map.zone_at(p)
	for r: Variant in JsonUtil.get_array(s.floor_def, "regions"):
		if r is Dictionary and JsonUtil.get_str(r, "zone") == zone and not JsonUtil.get_array(r, "monsters").is_empty():
			return r
	return {}


## 시체 냄새: 반경 안 구울 무리(가까운 것부터 corpse_seekers개)가 시체 곁으로 간다.
func _attract(s: ExploreSession, cell: Vector2i) -> void:
	var seekers: Array[FieldMonsters.Group] = []
	for g in s.monsters.groups:
		var r := JsonUtil.get_float(JsonUtil.get_dict(s.db.get_entry("monsters", g.leader()), "behavior"), "seeks_corpses_tiles")
		if g.party.is_empty() and r > 0.0 and g.state != FieldMonsters.STATE_CHASE and Vector2(g.pos - cell).length() <= r:
			seekers.append(g)
	seekers.sort_custom(func(a: FieldMonsters.Group, b: FieldMonsters.Group) -> bool:
		return (a.pos - cell).length_squared() < (b.pos - cell).length_squared())
	for i in mini(seekers.size(), JsonUtil.get_int(def, "corpse_seekers", 2)):
		var to := FieldRoutes.random_cell_near(s.map, s.rng, cell, 2)
		if to.x >= 0:
			s.monsters.send_to(seekers[i], to, s.pos)


func _foe(s: ExploreSession, g: FieldMonsters.Group) -> FieldMonsters.Group:
	var id := int(g.party.get("foe", -1))
	for m in s.monsters.groups:
		if m.id == id:
			return m
	return null


func _release_foe(s: ExploreSession, g: FieldMonsters.Group) -> void:
	var foe := _foe(s, g)
	if foe != null:
		foe.grace_until = -1.0


func _by_day(key: String) -> int:
	var arr := JsonUtil.get_array(def, key)
	return int(arr[clampi(_day, 0, arr.size() - 1)]) if not arr.is_empty() else 0
