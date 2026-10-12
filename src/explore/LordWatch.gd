class_name LordWatch
extends RefCounted
## 계층군주 소환 감시(순수 로직, docs/PROMPT_FLOOR1_V2.md §7.1). 층 JSON "lord" 블록:
##   {"monster": "dreadfear", "min_day": 3, "min_party": 5, "stay_radius_m": 5, "hazard_base_per_hour": 0.01,
##    "hazard_doubling_hours": 4, "omen_stay_hours": 3, "respawn_hours": 6, "vision_m": 2, "spawn_distance_tiles": 4}
## min_day일 차 이후 한곳(처음 머문 자리에서 stay_radius_m 안)에 min_party명 이상이 머물면, 머문 시간 t에 대해
## 시간당 위험률 hazard_base × 2^(t / doubling)으로 소환된다(하루면 사실상 확정). 자리를 벗어나면 머문 시간이 0으로.
## 머문 지 omen_stay_hours가 지나면 첫 전조, 소환되면 두 번째 전조(수정이 붉어짐)·결속 해제·시야 vision_m.
## 군주는 필드 무리로 나타나 다가온다. 쓰러뜨리면 respawn_hours 뒤 다시 소환될 수 있다.
## 패배하면 소환 조건을 채운 탐험가만 죽고 나머지는 생명력 1로 산다(동료가 생기면 — 지금은 혼자라 곧 사망).

const IDLE := "idle"
const ACTIVE := "active"
const COOLDOWN := "cooldown"

var def: Dictionary = {}
var state: String = IDLE
var group: FieldMonsters.Group = null
var stay_hours: float = 0.0
var cooldown_until: float = 0.0
var trigger_id: String = ""  ## 소환 조건을 채운 탐험가(패배 시 이 사람만 죽는다)

var _anchor: Vector2i = Vector2i(-9999, -9999)
var _omened: bool = false


func _init(p_def: Dictionary) -> void:
	def = p_def


func enabled() -> bool:
	return not def.is_empty()


func is_active() -> bool:
	return state == ACTIVE


## 소환 중 시야 상한(m). 소환 중이 아니면 음수.
func vision_cap_m() -> float:
	return JsonUtil.get_float(def, "vision_m", 2.0) if is_active() else -1.0


## 시간이 흘렀다(ExploreSession.pass_time). 소환했으면 true.
func update(s: ExploreSession, hours: float) -> bool:
	if not enabled() or hours <= 0.0:
		return false
	var now := s.clock.total_hours
	if state == COOLDOWN and now >= cooldown_until:
		state = IDLE
	if state != IDLE:
		return false
	var radius := JsonUtil.get_float(def, "stay_radius_m", 5.0) / maxf(0.01, float(s.db.bal("explore.meters_per_tile", 1.0)))
	if not _conditions_met(s) or Vector2(s.pos - _anchor).length() > radius:
		_anchor = s.pos
		stay_hours = 0.0
		_omened = false
		if not _conditions_met(s):
			return false
	stay_hours += hours
	if not _omened and stay_hours >= JsonUtil.get_float(def, "omen_stay_hours", 3.0):
		_omened = true
		s.message.emit("explore.lord_omen", {}, "warn")
	if s.rng.chance(chance_for(stay_hours, hours)):
		summon(s)
		return true
	return false


## 머문 시간 t에서 hours 동안 소환될 확률.
func chance_for(t: float, hours: float) -> float:
	var hazard := JsonUtil.get_float(def, "hazard_base_per_hour", 0.01) * pow(2.0, t / maxf(0.01, JsonUtil.get_float(def, "hazard_doubling_hours", 4.0)))
	return 1.0 - exp(-hazard * hours)


func _conditions_met(s: ExploreSession) -> bool:
	var day := int(floor(s.clock.total_hours / 24.0)) + 1
	return day >= JsonUtil.get_int(def, "min_day", 3) and s.party_size() >= JsonUtil.get_int(def, "min_party", 5)


## 소환(조건 충족 또는 디버그). 군주 무리를 spawn_distance_tiles쯤 떨어진 곳에 세운다.
func summon(s: ExploreSession) -> bool:
	if not enabled() or state == ACTIVE:
		return false
	var mid := JsonUtil.get_str(def, "monster")
	var at := _spawn_cell(s)
	group = s.monsters.spawn_group({"id": "", "monsters": [mid]}, s.pos, at, mid)
	if group == null:
		return false
	state = ACTIVE
	trigger_id = s.player.id
	stay_hours = 0.0
	s.message.emit("explore.lord_summoned", {"name": DataNames.entry(s.db, "monsters", mid)}, "danger")
	s.message.emit("explore.lord_bond", {}, "warn")
	s.monsters.changed.emit()
	s.refresh_view()
	return true


## 군주와의 전투가 끝났다. 군주 전투였으면 true.
func on_battle_end(s: ExploreSession, g: FieldMonsters.Group, result: String) -> bool:
	if g == null or g != group:
		return false
	group = null
	s.monsters.groups.erase(g)
	s.monsters.changed.emit()
	state = COOLDOWN
	cooldown_until = s.clock.total_hours + JsonUtil.get_float(def, "respawn_hours", 6.0)
	_anchor = Vector2i(-9999, -9999)
	stay_hours = 0.0
	_omened = false
	if result == Battle.RESULT_VICTORY:
		s.message.emit("explore.lord_defeated", {"name": DataNames.entry(s.db, "monsters", JsonUtil.get_str(def, "monster"))}, "good")
	else:
		s.message.emit("explore.lord_vanished", {}, "warn")
	return true


func _spawn_cell(s: ExploreSession) -> Vector2i:
	var dist := JsonUtil.get_int(def, "spawn_distance_tiles", 4)
	for d in range(dist, 0, -1):
		var dirs: Array = [Vector2i(d, 0), Vector2i(-d, 0), Vector2i(0, d), Vector2i(0, -d), Vector2i(d, d), Vector2i(-d, -d), Vector2i(d, -d), Vector2i(-d, d)]
		s.rng.shuffle(dirs)
		for o: Vector2i in dirs:
			if s.map.is_walkable(s.pos + o) and s.monsters.group_at(s.pos + o) == null:
				return s.pos + o
	return s.pos
