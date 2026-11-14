class_name WitchForest
extends RefCounted
## 마녀의 숲(3층 — 층 JSON "witch_forest", docs/plans/floor3.md §4). 순수 로직(오토로드 비의존).
## 필드 효과: 구역 zone 안에 있으면 statuses(방향치 · 환각 · 환청 · 통각강화)가 걸리고, 숲을 나가면(오두막 포함) 풀린다.
##   방향치: 숲에서는 지나온 칸이 지도 안개 기억에 남지 않고(disorient.no_memory) 이따금 발걸음이 45° 틀어진다(steer — 충돌은 그대로).
##   환각: 없는 무리(phantoms.monsters — 닿으면 싸우지 않는 무리)가 보였다가 vanish_dist 안으로 다가가면 사라진다.
##     가끔은 마른 나무 한 그루가 보랏빛으로 보인다(false_tree — 같은 걷지 못하는 칸이라 길 · 충돌은 그대로).
##   환청: whispers.sounds 중 하나를 불규칙하게(소리 키 — 실제 몬스터 자리와 무관).
##   통각강화: 전투 화면이 맞을 때 흔들림을 pain.shake_mult배(CombatScreen이 본다). 피해 배율 pain.damage_mult(기본 1 — 그대로).
## 마녀의 눈(추적): 숲에 처음 든 시각부터 흐른 시간(숲 밖에서도 흐른다)으로 단계(stages[].after_hours)가 오른다. 1단계부터 상태 f3_witch_eye.
##   한곳 = 처음 선 칸(anchor)에서 dwell_radius칸 안. 그 안에 있는 동안(걷든 서든 · 대기 · 휴식 모두) 머문 시간이 쌓이고, 벗어나면 그 칸에서 다시 센다.
##   머문 시간이 그 단계의 wait_hours × omen_at이면 전조(심장 소리 · 글 한 줄), wait_hours면 카나바로(hunter) 한 마리가 spawn_dist칸 떨어진
##   숲속에서 쫓아온다(바로 닿지 않는다 — 도망치거나 맞설 틈). 이미 숲에 카나바로가 있으면 더 나오지 않고, 쓰러뜨리면 hunter_cooldown_hours 뒤부터 다시.
##   숲을 나가면 머문 시간은 0(leave_resets_dwell), 단계는 그대로. 쫓던 카나바로는 플레이어가 숲 밖에 hunter_leash_hours 넘게 있으면 숲으로 돌아가 사라진다.

const PHANTOM := "f3_phantom"

var stage: int = -1
var entered_at: float = -1.0   ## 숲에 처음 든 게임 시각(< 0 = 아직)
var dwell: float = 0.0         ## 지금 자리에 머문 시간
var anchor: Vector2i = Vector2i(-1, -1)
var inside: bool = false
var hunter: FieldMonsters.Group = null
var omen_until: float = -1.0   ## 전조 연출이 보이는 동안(화면이 본다)
var _cfg: Dictionary = {}
var _omened: bool = false
var _hunter_ready: float = 0.0
var _outside_since: float = -1.0
var _phantoms: Array = []      ## [{g, until}]
var _false_trees: Array = []   ## [{pos, tile, until}]
var _next_phantom: float = -1.0
var _next_whisper: float = -1.0
var _next_drift: float = -1.0
var _drift_until: float = -1.0
var _drift_angle: float = 0.0


static func setup(s: ExploreSession) -> WitchForest:
	var d := JsonUtil.get_dict(s.floor_def, "witch_forest")
	if d.is_empty():
		return null
	var w := WitchForest.new()
	w._cfg = d
	return w


func zone() -> String:
	return JsonUtil.get_str(_cfg, "zone", "f3_witch")


func cfg() -> Dictionary:
	return _cfg


## 지금 단계의 한곳 머무는 한도(게임 시간).
func wait_hours() -> float:
	var out := 1.0
	for sd: Variant in JsonUtil.get_array(_cfg, "stages"):
		var d: Dictionary = sd
		if JsonUtil.get_int(d, "stage") <= maxi(0, stage):
			out = JsonUtil.get_float(d, "wait_hours", out)
	return out


## 머문 시간 / 한도(0~1 — 화면의 전조 세기).
func dread() -> float:
	return clampf(dwell / maxf(0.001, wait_hours()), 0.0, 1.0) if inside else 0.0


func pain_shake() -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(_cfg, "pain"), "shake_mult", 1.0) if inside else 1.0


func on_enter(s: ExploreSession, cell: Vector2i) -> void:
	_vanish_near(s, Vector2(cell) + Vector2(0.5, 0.5))


func update(s: ExploreSession, hours: float) -> void:
	var now := s.clock.total_hours
	var was := inside
	inside = s.map.zone_at(s.pos) == zone()
	_statuses(s)
	if inside and entered_at < 0.0:
		entered_at = now
		FieldFeatureAct.say_line(s, _line("first"), {"pos": s.pos}, "warn")
	_stage(s, now)
	_track_hunter(s, now)
	if inside:
		_outside_since = -1.0
		_dwell(s, hours, now)
		_hallucinate(s, now)
		_whisper(s, now)
	else:
		if was:
			_outside_since = now
		if JsonUtil.get_bool(_cfg, "leave_resets_dwell", true):
			dwell = 0.0
			anchor = Vector2i(-1, -1)
			_omened = false
		_clear_illusions(s)
	_vanish_near(s, s.fpos)
	_expire(s, now)


## 방향치: 이따금 발걸음이 틀어진다(입력 방향만 — 충돌 · 길은 그대로).
func steer(s: ExploreSession, dir: Vector2) -> Vector2:
	if not inside or not s.player.statuses.has("f3_disoriented"):
		return dir
	var now := s.clock.total_hours
	var dc := JsonUtil.get_dict(_cfg, "disorient")
	if _next_drift < 0.0:
		_next_drift = now + _range(s, JsonUtil.get_array(dc, "drift_every_hours"), 0.5)
	if now >= _next_drift:
		_drift_until = now + JsonUtil.get_float(dc, "drift_hours", 0.05)
		_drift_angle = PI / 4.0 * (1.0 if s.rng.chance(0.5) else -1.0)
		_next_drift = now + _range(s, JsonUtil.get_array(dc, "drift_every_hours"), 0.5)
	return dir.rotated(_drift_angle) if now < _drift_until else dir


## 방향치: 숲에서는 본 칸을 기억(지도 안개)에 남기지 않는다.
func remembers(s: ExploreSession) -> bool:
	return not (inside and s.player.statuses.has("f3_disoriented") and JsonUtil.get_bool(JsonUtil.get_dict(_cfg, "disorient"), "no_memory", true))


## 환각으로 세운 무리인가(닿아도 싸우지 않는다).
static func is_phantom(g: FieldMonsters.Group) -> bool:
	return g != null and g.has_meta(PHANTOM)


# ── 내부 ─────────────────────────────────────────────────

func _statuses(s: ExploreSession) -> void:
	for st: Variant in JsonUtil.get_array(_cfg, "statuses"):
		var id := str(st)
		for pc: PlayerCharacter in [s.player] + s.companions:
			if inside and not pc.statuses.has(id):
				pc.statuses.apply(id)
			elif not inside and pc.statuses.has(id):
				pc.statuses.remove(id)


func _stage(s: ExploreSession, now: float) -> void:
	if entered_at < 0.0:
		return
	var h := now - entered_at
	var st := 0
	for sd: Variant in JsonUtil.get_array(_cfg, "stages"):
		var d: Dictionary = sd
		if h >= JsonUtil.get_float(d, "after_hours"):
			st = maxi(st, JsonUtil.get_int(d, "stage"))
	st = mini(st, JsonUtil.get_int(_cfg, "max_stage", 10))
	if st == stage:
		return
	var up := st > stage and stage >= 0
	stage = st
	if stage >= 1 and not s.player.statuses.has("f3_witch_eye"):
		s.player.statuses.apply("f3_witch_eye")
	if up and stage >= 1:
		s.sound.emit("f3_hunter_omen", s.pos)
		FieldFeatureAct.say_line(s, _line("stage"), {"pos": s.pos}, "danger")


func _dwell(s: ExploreSession, hours: float, now: float) -> void:
	var r := JsonUtil.get_float(_cfg, "dwell_radius", 6.0)
	if anchor.x < 0 or Vector2(s.pos - anchor).length() > r:
		anchor = s.pos
		dwell = 0.0
		_omened = false
		return
	dwell += hours
	var wait := wait_hours()
	if not _omened and dwell >= wait * JsonUtil.get_float(_cfg, "omen_at", 0.6) and _hunter_free(now):
		_omened = true
		omen_until = now + wait * 0.6
		s.sound.emit("f3_hunter_omen", s.pos)
		FieldFeatureAct.say_line(s, _line("omen"), {"pos": s.pos}, "danger")
	if dwell >= wait and _hunter_free(now):
		_spawn_hunter(s, now)
		dwell = 0.0
		_omened = false


func _hunter_free(now: float) -> bool:
	return hunter == null and now >= _hunter_ready


func _spawn_hunter(s: ExploreSession, now: float) -> void:
	if not s.monsters_enabled:
		return
	var at := _cell_around(s, JsonUtil.get_array(_cfg, "spawn_dist"), true)
	if at.x < 0:
		return
	var g := s.monsters.add_fixed([JsonUtil.get_str(_cfg, "hunter", "canavaro")], at)
	if g == null:
		return
	hunter = g
	g.alert_until = now + JsonUtil.get_float(_cfg, "hunter_chase_hours", 6.0)
	g.state = FieldMonsters.STATE_CHASE
	g.target = s.pos
	s.sound.emit("f3_crossbow", at)
	s.fx.emit("bang", at, g.id)
	FieldFeatureAct.say_line(s, _line("hunter"), {"pos": at}, "danger")


## 카나바로가 사라졌으면(쓰러짐) 쉬는 시간을 둔다. 숲 밖에 오래 있으면 쫓기를 그만두고 숲으로 돌아간다.
func _track_hunter(s: ExploreSession, now: float) -> void:
	if hunter == null:
		return
	if not s.monsters.groups.has(hunter):
		hunter = null
		_hunter_ready = now + JsonUtil.get_float(_cfg, "hunter_cooldown_hours", 1.0)
		return
	if _outside_since >= 0.0 and now - _outside_since > JsonUtil.get_float(_cfg, "hunter_leash_hours", 0.5) and not s.in_combat:
		s.fx.emit("snap", hunter.pos, hunter.id)
		s.monsters.groups.erase(hunter)
		s.monsters.changed.emit()
		hunter = null
		_hunter_ready = now + JsonUtil.get_float(_cfg, "hunter_cooldown_hours", 1.0)


func _hallucinate(s: ExploreSession, now: float) -> void:
	if not s.player.statuses.has("f3_hallucination"):
		return
	var pc := JsonUtil.get_dict(_cfg, "phantoms")
	if _next_phantom < 0.0:
		_next_phantom = now + _range(s, JsonUtil.get_array(pc, "every_hours"), 0.5)
		return
	if now < _next_phantom:
		return
	_next_phantom = now + _range(s, JsonUtil.get_array(pc, "every_hours"), 0.5)
	var until := now + JsonUtil.get_float(pc, "last_hours", 1.5)
	if s.rng.chance(JsonUtil.get_float(pc, "false_tree_chance", 0.3)) and _false_tree(s, until):
		return
	if _phantoms.size() >= JsonUtil.get_int(pc, "max", 3) or not s.monsters_enabled:
		return
	var ids := JsonUtil.get_array(pc, "monsters")
	if ids.is_empty():
		return
	var at := _cell_around(s, JsonUtil.get_array(pc, "dist"), false)
	if at.x < 0:
		return
	var g := s.monsters.add_fixed([str(ids[s.rng.randi_range(0, ids.size() - 1)])], at)
	if g == null:
		return
	g.set_meta(PHANTOM, true)
	g.grace_until = 1.0e9  # 닿아도 싸우지 않는다
	g.guard = true
	_phantoms.append({"g": g, "until": until})


## 보이는 마른 나무 한 그루를 보랏빛으로(환각 — 같은 걷지 못하는 칸).
func _false_tree(s: ExploreSession, until: float) -> bool:
	var r := 9
	var cands: Array[Vector2i] = []
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := s.pos + Vector2i(dx, dy)
			if s.map.in_bounds(q) and s.map.tile_id_at(q) == "f3_witch_deadtree" and Vector2(dx, dy).length() > 4.0:
				cands.append(q)
	if cands.is_empty():
		return false
	var q := cands[s.rng.randi_range(0, cands.size() - 1)]
	s.map.set_tile(q, "f3_purple_tree_false")
	_false_trees.append({"pos": q, "tile": "f3_witch_deadtree", "until": until})
	s.tiles_changed.emit(Rect2i(q, Vector2i.ONE))
	return true


func _whisper(s: ExploreSession, now: float) -> void:
	if not s.player.statuses.has("f3_auditory"):
		return
	var wc := JsonUtil.get_dict(_cfg, "whispers")
	if _next_whisper < 0.0 or now >= _next_whisper:
		var first := _next_whisper < 0.0
		_next_whisper = now + _range(s, JsonUtil.get_array(wc, "every_hours"), 0.3)
		var keys := JsonUtil.get_array(wc, "sounds")
		if not first and not keys.is_empty():
			s.sound.emit(str(keys[s.rng.randi_range(0, keys.size() - 1)]), s.pos)


## 다가가면 사라지는 환각(무리 · 보랏빛 나무).
func _vanish_near(s: ExploreSession, at: Vector2) -> void:
	var vd := JsonUtil.get_float(JsonUtil.get_dict(_cfg, "phantoms"), "vanish_dist", 3.5)
	for ph: Dictionary in _phantoms.duplicate():
		var g: FieldMonsters.Group = ph["g"]
		if g.fpos.distance_to(at) <= vd:
			_drop_phantom(s, ph)
	for ft: Dictionary in _false_trees.duplicate():
		if (Vector2(ft["pos"]) + Vector2(0.5, 0.5)).distance_to(at) <= vd:
			_drop_tree(s, ft)


func _expire(s: ExploreSession, now: float) -> void:
	for ph: Dictionary in _phantoms.duplicate():
		if now >= float(ph["until"]):
			_drop_phantom(s, ph)
	for ft: Dictionary in _false_trees.duplicate():
		if now >= float(ft["until"]):
			_drop_tree(s, ft)


func _clear_illusions(s: ExploreSession) -> void:
	for ph: Dictionary in _phantoms.duplicate():
		_drop_phantom(s, ph)
	for ft: Dictionary in _false_trees.duplicate():
		_drop_tree(s, ft)


func _drop_phantom(s: ExploreSession, ph: Dictionary) -> void:
	_phantoms.erase(ph)
	var g: FieldMonsters.Group = ph["g"]
	if s.monsters.groups.has(g):
		s.monsters.groups.erase(g)
		s.monsters.changed.emit()


func _drop_tree(s: ExploreSession, ft: Dictionary) -> void:
	_false_trees.erase(ft)
	var q: Vector2i = ft["pos"]
	if s.map.tile_id_at(q) == "f3_purple_tree_false":
		s.map.set_tile(q, str(ft["tile"]))
		s.tiles_changed.emit(Rect2i(q, Vector2i.ONE))


## 플레이어에게서 dist[0]~dist[1]칸 떨어진 숲속 걸을 수 있는 칸(hidden이면 지금 보이지 않는 칸을 먼저). 없으면 (-1, -1).
func _cell_around(s: ExploreSession, dist: Array, hidden: bool) -> Vector2i:
	var lo := float(dist[0]) if dist.size() == 2 else 8.0
	var hi := float(dist[1]) if dist.size() == 2 else 12.0
	var fallback := Vector2i(-1, -1)
	for tries in 60:
		var a := s.rng.randf_range(0.0, TAU)
		var d := s.rng.randf_range(lo, hi)
		var q := s.pos + Vector2i(roundi(cos(a) * d), roundi(sin(a) * d))
		if not s.map.in_bounds(q) or not s.map.is_walkable(q) or s.map.zone_at(q) != zone() or s.monsters.group_at(q) != null:
			continue
		if not hidden or s.map.visible_now[s.map.idx(q)] == 0:
			return q
		if fallback.x < 0:
			fallback = q
	return fallback


func _range(s: ExploreSession, r: Array, fallback: float) -> float:
	return s.rng.randf_range(float(r[0]), float(r[1])) if r.size() == 2 else fallback


func _line(k: String) -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(_cfg, "lines"), k)
