class_name LordWatch
extends RefCounted
## 계층군주(순수 로직). 층 JSON "lord" 블록: {"monster": "dreadfear", "monument": true, "respawn_hours": 6, "vision_m": 2, "spawn_distance_tiles": 4}
## 부르는 길은 대현자 기념비뿐(Monument — 그 층 균열 수호자를 모두 쓰러뜨린 뒤, 사용자 2026-10-27 DF17).
## 원작의 머묾 소환(3일 차 이후 5인 이상이 한곳에 머물면)은 사용자 결정으로 없앴다(2026-10-27).
## 소환되면 전조(수정이 붉어짐)·결속 해제·시야 vision_m. 군주는 필드 무리로 나타나 다가온다. 쓰러뜨리면 respawn_hours 뒤 다시 부를 수 있다.
## 패배하면 군주를 부른 탐험가만 죽고 나머지는 생명력 1로 산다.

const IDLE := "idle"
const ACTIVE := "active"
const COOLDOWN := "cooldown"

var def: Dictionary = {}
var state: String = IDLE
var group: FieldMonsters.Group = null
var cooldown_until: float = 0.0
var trigger_id: String = ""  ## 군주를 부른 탐험가(패배 시 이 사람만 죽는다)


func _init(p_def: Dictionary) -> void:
	def = p_def


func enabled() -> bool:
	return not def.is_empty()


func is_active() -> bool:
	return state == ACTIVE


## 소환 중 시야 상한(m). 소환 중이 아니면 음수.
func vision_cap_m() -> float:
	return JsonUtil.get_float(def, "vision_m", 2.0) if is_active() else -1.0


## 시간이 흘렀다(ExploreSession.pass_time): 다시 깨어나기를 기다리던 군주를 부를 수 있게 한다. 저절로 소환되지는 않는다(늘 false).
func update(s: ExploreSession, hours: float) -> bool:
	if enabled() and hours > 0.0 and state == COOLDOWN and s.clock.total_hours >= cooldown_until:
		state = IDLE
	return false


## 소환(기념비 — Monument, 또는 디버그). 군주 무리를 spawn_distance_tiles쯤 떨어진 곳에 세운다.
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
	s.monsters.changed.emit()
	s.refresh_view()
	var g := group
	s.lord_rise(g, func() -> void:  # 화면이 소환 연출(구더기가 모여 군주를 이룬다 — LordRiseFx)을 보인 뒤 알린다(V27)
		s.message.emit("explore.lord_summoned", {"name": DataNames.entry(s.db, "monsters", mid)}, "danger")
		s.message.emit("explore.lord_bond", {}, "warn"))
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
