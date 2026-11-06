class_name RouteAmbush
extends RefCounted
## 길목 매복(망자의 땅 — 사용자 2026-11-06 "통로에 사건", FL18): 층 JSON route_spots.ambush
##   [{"edge": [구간 a, 구간 b], "t": 0~1(길 위 자리), "monsters": [id …], "radius": 칸, "line": 문구 키, "sound": 소리 키}]
##   그 자리에서 radius칸 안에 처음 들어서면 길가 땅에서 무리가 일어나 바로 쫓아온다(한 원정에 한 번). 자리는 a → b 곧은 선의 t 지점에서
##   가장 가까운 걸을 수 있는 칸. 순수 로직(오토로드 비의존).

var _spots: Array[Dictionary] = []  ## {at: Vector2i, def: Dictionary}


static func build(s: ExploreSession) -> RouteAmbush:
	var list := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "ambush")
	if list.is_empty():
		return null
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	var r := RouteAmbush.new()
	for v: Variant in list:
		var d: Dictionary = v if v is Dictionary else {}
		var e := JsonUtil.get_array(d, "edge")
		if e.size() != 2 or not nodes.has(str(e[0])) or not nodes.has(str(e[1])):
			continue
		var p := Vector2i(Vector2(nodes[str(e[0])] as Vector2i).lerp(Vector2(nodes[str(e[1])] as Vector2i), JsonUtil.get_float(d, "t", 0.5)).round())
		var at := _walkable_near(s.map, p)
		if at.x >= 0:
			r._spots.append({"at": at, "def": d})
	return r


func spots() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for sp in _spots:
		out.append(sp["at"])
	return out


## 플레이어가 cell에 들어섰다: 가까운 매복이 터진다.
func on_enter(s: ExploreSession, cell: Vector2i) -> void:
	if not s.monsters_enabled:
		return
	for i in range(_spots.size() - 1, -1, -1):
		var sp := _spots[i]
		var d: Dictionary = sp["def"]
		if Vector2(cell - (sp["at"] as Vector2i)).length() > JsonUtil.get_float(d, "radius", 3.0):
			continue
		_spots.remove_at(i)
		var g := s.monsters.add_fixed(JsonUtil.get_array(d, "monsters"), _beside(s, cell))
		if g == null:
			continue
		g.alert_until = s.clock.total_hours + 1.0
		g.state = FieldMonsters.STATE_CHASE
		if d.has("sound"):
			s.sound.emit(JsonUtil.get_str(d, "sound"), g.pos)
		FieldFeatureAct.say_line(s, JsonUtil.get_str(d, "line"), {"pos": cell}, "danger")


## 플레이어 둘레 2~3칸의 걸을 수 있는 칸(곧장 붙지 않게 — 한 걸음 물러설 틈).
static func _beside(s: ExploreSession, cell: Vector2i) -> Vector2i:
	for r in [3, 2, 4]:
		for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var q: Vector2i = cell + d * int(r)
			if s.map.in_bounds(q) and s.map.is_walkable(q) and s.monsters.group_at(q) == null:
				return q
	return cell + Vector2i.DOWN


static func _walkable_near(map: FloorMap, p: Vector2i) -> Vector2i:
	for r in 10:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if map.in_bounds(q) and map.is_walkable(q):
					return q
	return Vector2i(-1, -1)
