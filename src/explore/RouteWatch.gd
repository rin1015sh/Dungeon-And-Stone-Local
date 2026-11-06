class_name RouteWatch
extends RefCounted
## 망대 경보(고블린 숲 — 사용자 2026-11-06 "맵 다시 기획", FL22): 층 JSON route_spots
##   "watch": [{"node" | "edge"+"t" | "mark", "at": [dx, dy], "radius": 칸, "archer": 몬스터 id}] — 망대 자리 둘레에 궁수 하나(지키는 무리)를 세운다.
##   "watch_alarm": {"region": 지역 id, "hours", "sound", "line"} — 망대 궁수가 살아 있고 플레이어가 radius칸 안에서 망대를 볼 수 있으면(서로 보인다)
##   그 지역 무리 모두가 hours시간 동안 보지 못해도 쫓아온다(뿔피리). 망대마다 한 번. 궁수를 먼저 쓰러뜨리면 그 망대는 조용하다.
## 순수 로직(오토로드 비의존).

var _towers: Array[Dictionary] = []  ## {at: Vector2i, radius, guard: FieldMonsters.Group | null, rang: bool}
var _alarm: Dictionary = {}


static func build(s: ExploreSession) -> RouteWatch:
	var rs := JsonUtil.get_dict(s.floor_def, "route_spots")
	var list := JsonUtil.get_array(rs, "watch")
	if list.is_empty():
		return null
	var w := RouteWatch.new()
	w._alarm = JsonUtil.get_dict(rs, "watch_alarm")
	for v: Variant in list:
		var d: Dictionary = v if v is Dictionary else {}
		var c := RouteSpots._anchor(s, d)
		if c.x < 0:
			continue
		var at := JsonUtil.get_array(d, "at")
		c += Vector2i(int(at[0]), int(at[1])) if at.size() == 2 else Vector2i.ZERO
		var g: FieldMonsters.Group = null
		if s.monsters_enabled and not JsonUtil.get_str(d, "archer").is_empty():
			g = s.monsters.add_fixed([JsonUtil.get_str(d, "archer")], c)
		w._towers.append({"at": c, "radius": JsonUtil.get_float(d, "radius", 12.0), "guard": g, "rang": false})
	return w


func towers() -> Array[Dictionary]:
	return _towers


## 플레이어가 cell에 들어섰다: 볼 수 있는 망대가 있으면 경보.
func on_enter(s: ExploreSession, cell: Vector2i) -> void:
	for t in _towers:
		if bool(t["rang"]) or not _guard_alive(s, t):
			continue
		var at: Vector2i = t["at"]
		if Vector2(cell - at).length() > float(t["radius"]) or not s.map.in_bounds(at) or s.map.visible_now[s.map.idx(at)] == 0:
			continue
		t["rang"] = true
		ring(s, at)


## 경보: 그 지역 무리 모두가 쫓아온다.
func ring(s: ExploreSession, at: Vector2i) -> void:
	var region := JsonUtil.get_str(_alarm, "region")
	var until := s.clock.total_hours + JsonUtil.get_float(_alarm, "hours", 1.0)
	for g: FieldMonsters.Group in s.monsters.groups:
		if g.region == region:
			g.alert_until = until
			g.state = FieldMonsters.STATE_CHASE
	if _alarm.has("sound"):
		s.sound.emit(JsonUtil.get_str(_alarm, "sound"), at)
	FieldFeatureAct.say_line(s, JsonUtil.get_str(_alarm, "line"), {"pos": at}, "danger")


func _guard_alive(s: ExploreSession, t: Dictionary) -> bool:
	var g: Variant = t["guard"]
	return g != null and s.monsters.groups.has(g)
