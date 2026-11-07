class_name DesertRules
extends RefCounted
## 바위사막 규칙(floor2.md §4 — 레벨 디자인 LD14). 층 JSON "desert": {"heat": {…}, "sand_sea": {…}}. 순수 로직(오토로드 비의존).
##   heat {"zones", "from", "to"(시각), "status", "fatigue_per_hour", "shade_tiles", "shade_radius", "cool_status"}:
##     그 구역에서 낮(from~to) 동안 그늘(둘레 shade_radius칸에 shade_tiles 또는 솟은 외곽 — 바위산 · 잔해 · 화로) 밖이면 열기 상태(허기가 빨리 준다)
##     + 시간당 피로 fatigue_per_hour. 그늘 · 밤 · 다른 구역이면 풀린다. cool_status(샘물을 마시면 — 한동안 열기를 막는다)가 있으면 열기 없음.
##   sand_sea {"tiles", "per_step", "decay_per_hour", "threshold", "warn_at", "monsters", "line", "warn_line", "sound", "warn_sound"}:
##     모래 바다 칸을 걸을 때마다 진동이 per_step 쌓이고, 서 있거나 바다 밖이면 시간당 decay_per_hour 빠진다.
##     warn_at(비율)을 넘으면 한 번 경고(발밑이 떨린다 — 소리), threshold를 넘으면 바로 옆 모래에서 무리가 솟아 쫓아오고 진동은 0으로.
##     천천히(멈췄다 걷기) 가면 덜 쌓인다 — 걷는 동안 시간이 흘러 진동이 빠지는 틈이 생긴다.

var vibration: float = 0.0
var _cfg: Dictionary = {}
var _warned: bool = false
var _heat_zones: Array = []
var _sand: Dictionary = {}  ## 타일 id → true


static func setup(s: ExploreSession) -> DesertRules:
	var d := JsonUtil.get_dict(s.floor_def, "desert")
	if d.is_empty():
		return null
	var r := DesertRules.new()
	r._cfg = d
	r._heat_zones = JsonUtil.get_array(JsonUtil.get_dict(d, "heat"), "zones")
	for t: Variant in JsonUtil.get_array(JsonUtil.get_dict(d, "sand_sea"), "tiles"):
		r._sand[str(t)] = true
	return r


## 칸에 들어섰다: 모래 바다면 진동이 쌓인다.
func on_enter(s: ExploreSession, cell: Vector2i) -> void:
	var sea := JsonUtil.get_dict(_cfg, "sand_sea")
	if sea.is_empty() or not _sand.has(s.map.tile_id_at(cell)):
		return
	vibration += JsonUtil.get_float(sea, "per_step", 1.0)
	var thr := JsonUtil.get_float(sea, "threshold", 12.0)
	if not _warned and vibration >= thr * JsonUtil.get_float(sea, "warn_at", 0.6):
		_warned = true
		if sea.has("warn_sound"):
			s.sound.emit(JsonUtil.get_str(sea, "warn_sound"), cell)
		FieldFeatureAct.say_line(s, JsonUtil.get_str(sea, "warn_line"), {"pos": cell}, "warn")
	if vibration < thr:
		return
	vibration = 0.0
	_warned = false
	if not s.monsters_enabled:
		return
	var at := _sand_beside(s, cell)
	var g := s.monsters.add_fixed(JsonUtil.get_array(sea, "monsters"), at)
	if g == null:
		return
	g.alert_until = s.clock.total_hours + 1.0
	g.state = FieldMonsters.STATE_CHASE
	if sea.has("sound"):
		s.sound.emit(JsonUtil.get_str(sea, "sound"), at)
	FieldFeatureAct.say_line(s, JsonUtil.get_str(sea, "line"), {"pos": cell}, "danger")


## 시간이 흘렀다: 진동이 빠지고(서 있거나 바다 밖), 열기를 걸거나 푼다.
func update(s: ExploreSession, hours: float) -> void:
	var sea := JsonUtil.get_dict(_cfg, "sand_sea")
	if not sea.is_empty() and (not FieldStealth.moving(s) or not _sand.has(s.map.tile_id_at(s.pos))):
		vibration = maxf(0.0, vibration - JsonUtil.get_float(sea, "decay_per_hour", 20.0) * hours)
		if vibration < JsonUtil.get_float(sea, "threshold", 12.0) * JsonUtil.get_float(sea, "warn_at", 0.6) * 0.5:
			_warned = false
	var heat := JsonUtil.get_dict(_cfg, "heat")
	if heat.is_empty():
		return
	var st := JsonUtil.get_str(heat, "status", "heat")
	if hot(s):
		if not s.player.statuses.has(st):
			s.player.statuses.apply(st)
		s.player.fatigue.add(JsonUtil.get_float(heat, "fatigue_per_hour", 2.0) * hours, "heat")
	elif s.player.statuses.has(st):
		s.player.statuses.remove(st)


## 지금 열기를 받는가(구역 · 낮 · 그늘 밖 · 시원한 상태 없음).
func hot(s: ExploreSession) -> bool:
	var heat := JsonUtil.get_dict(_cfg, "heat")
	if heat.is_empty() or not FieldClues.in_window(s, heat) or not _heat_zones.has(s.map.zone_at(s.pos)):
		return false
	if s.player.statuses.has(JsonUtil.get_str(heat, "cool_status", "refreshed")):
		return false
	return not shaded(s, s.pos)


## cell 둘레 shade_radius칸에 그늘(shade_tiles · 솟은 외곽)이 있는가.
func shaded(s: ExploreSession, cell: Vector2i) -> bool:
	var heat := JsonUtil.get_dict(_cfg, "heat")
	var tiles := JsonUtil.get_array(heat, "shade_tiles")
	var r := JsonUtil.get_int(heat, "shade_radius", 2)
	var rise := JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(s.floor_def, "gen"), "tiles"), "rise")
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var q := cell + Vector2i(dx, dy)
			if not s.map.in_bounds(q):
				continue
			var id := s.map.tile_id_at(q)
			if id == rise or tiles.has(id):
				return true
	return false


static func _sand_beside(s: ExploreSession, cell: Vector2i) -> Vector2i:
	for r in [3, 2, 4]:
		for d: Vector2i in FloorMap.DIRS4:
			var q: Vector2i = cell + d * int(r)
			if s.map.in_bounds(q) and s.map.is_walkable(q) and s.monsters.group_at(q) == null:
				return q
	return cell + Vector2i.DOWN
