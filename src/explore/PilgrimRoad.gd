class_name PilgrimRoad
extends RefCounted
## 3층 '순례자의 길' 규칙 묶음(층 JSON "zones_ko" · "zone_vision" · "witch_forest" · "witch_hut" · "sky_event" · "orc_altar").
## ExploreSession은 이 하나만 부른다(세션 파일을 짧게): 칸에 들어섬 · 시간 흐름 · 실제 초 · 시야 · 걸음 방향 · 지도 기억 · 살피기 · 조우.
## 지역 이름: 구역이 바뀌면 zone_name · zone_since가 바뀐다(화면 Floor3Overlay가 지역명을 잠깐 띄운다 — 글 대화창이 아니다).

var witch: WitchForest = null
var hut: WitchHut = null
var sky: SkyLanterns = null
var altar: OrcAltar = null
var zone: String = ""
var zone_name: String = ""
var zone_since: float = -1.0  ## 지역이 바뀐 게임 시각
var _names: Dictionary = {}
var _vision: Dictionary = {}


static func setup(s: ExploreSession) -> PilgrimRoad:
	var f := s.floor_def
	if not (f.has("zones_ko") or f.has("witch_forest") or f.has("witch_hut") or f.has("sky_event") or f.has("orc_altar")):
		return null
	var p := PilgrimRoad.new()
	p._names = JsonUtil.get_dict(f, "zones_ko")
	p._vision = JsonUtil.get_dict(f, "zone_vision")
	p.witch = WitchForest.setup(s)
	p.hut = WitchHut.setup(s)
	p.sky = SkyLanterns.setup(s)
	p.altar = OrcAltar.setup(s)
	p._zone(s)
	return p


func on_enter(s: ExploreSession, cell: Vector2i) -> void:
	_zone(s)
	if witch != null:
		witch.on_enter(s, cell)


func update(s: ExploreSession, hours: float) -> void:
	if witch != null:
		witch.update(s, hours)
	if hut != null:
		hut.update(s, hours)
	if sky != null:
		sky.update(s)


func tick_real(s: ExploreSession, sec: float) -> void:
	if sky != null:
		sky.tick_real(s, sec)


func vision(s: ExploreSession, v: float) -> float:
	var out := v * JsonUtil.get_float(_vision, s.map.zone_at(s.pos), 1.0)
	if sky != null:
		out *= sky.vision_mult(s)
	return out


func steer(s: ExploreSession, dir: Vector2) -> Vector2:
	return witch.steer(s, dir) if witch != null else dir


func remembers(s: ExploreSession) -> bool:
	return witch == null or witch.remembers(s)


func interact(s: ExploreSession) -> bool:
	return (hut != null and hut.interact(s)) or (altar != null and altar.interact(s))


func target_name(s: ExploreSession) -> String:
	var n := hut.target_name(s) if hut != null else ""
	if n.is_empty() and altar != null:
		n = altar.target_name(s)
	return n


## 조우를 막는다(환각 무리 — 닿으면 사라진다). 막았으면 true.
func blocks(s: ExploreSession, g: FieldMonsters.Group) -> bool:
	if not WitchForest.is_phantom(g):
		return false
	s.monsters.groups.erase(g)
	s.monsters.changed.emit()
	return true


func _zone(s: ExploreSession) -> void:
	var z := s.map.zone_at(s.pos)
	if z == zone:
		return
	zone = z
	zone_name = JsonUtil.get_str(_names, z)
	zone_since = s.clock.total_hours
