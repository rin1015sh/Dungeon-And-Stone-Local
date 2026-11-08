class_name RouteAmbush
extends RefCounted
## 길목 매복(망자의 땅 — 사용자 2026-11-06 "통로에 사건", FL18): 층 JSON route_spots.ambush
##   [{"edge": [구간 a, 구간 b], "t": 0~1(길 위 자리) 또는 "node" · "mark", "monsters": [id …], "radius": 칸, "line": 문구 키, "sound": 소리 키}]
##   그 자리에서 radius칸 안에 처음 들어서면 길가 땅에서 무리가 일어나 바로 쫓아온다(한 원정에 한 번). 자리는 a → b 곧은 선의 t 지점에서
##   가장 가까운 걸을 수 있는 칸. "stops_if_gone": 몬스터 id — 그 몬스터가 든 무리가 지도에 하나도 없으면(쓰러뜨렸다) 터지지 않는다
##   (짐승의 소굴 벽두더지 매복 ↔ 여왕 굴 — LD12). "lit_only": true면 횃불을 켰을 때만 터진다(박쥐 떼 — 끄고 지나가면 그대로).
## 자리 없는 타일 매복(2층 새 몬스터): {"on_tiles": [타일 id …], "near": 칸(그 타일에서 이만큼 안이면 — 기본 0), "chance": 걸음마다 확률,
##   "max": 한 원정에 몇 번, "hours": [from, to](선택), "monsters", "line", "sound"} — 진창 익사자 · 그늘 전갈. 순수 로직(오토로드 비의존).

var _spots: Array[Dictionary] = []  ## {at: Vector2i, def: Dictionary}
var _tile_rules: Array[Dictionary] = []  ## {def, left}


static func build(s: ExploreSession) -> RouteAmbush:
	var list := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "ambush")
	if list.is_empty():
		return null
	var r := RouteAmbush.new()
	for v: Variant in list:
		var d: Dictionary = v if v is Dictionary else {}
		if d.has("on_tiles"):
			r._tile_rules.append({"def": d, "left": JsonUtil.get_int(d, "max", 2)})
			continue
		var p := RouteSpots._anchor(s, d)  # "edge"+"t" · "node" · "mark"(손으로 짠 지도 — FL25)
		if p.x < 0:
			continue
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
	_tile_ambush(s, cell)
	for i in range(_spots.size() - 1, -1, -1):
		var sp := _spots[i]
		var d: Dictionary = sp["def"]
		if Vector2(cell - (sp["at"] as Vector2i)).length() > JsonUtil.get_float(d, "radius", 3.0):
			continue
		if JsonUtil.get_bool(d, "lit_only") and not s.player.light.is_lit():
			continue  # 어둠 속을 지나가면 천장의 떼가 깨지 않는다
		var boss := JsonUtil.get_str(d, "stops_if_gone")
		if not boss.is_empty() and not s.monsters.groups.any(func(g: FieldMonsters.Group) -> bool: return g.monster_ids.has(boss)):
			_spots.remove_at(i)  # 여왕이 쓰러졌다 — 벽 속 무리도 흩어졌다
			continue
		_spots.remove_at(i)
		_spring(s, cell, d)


## 타일 매복: 지금 칸(또는 near칸 안)이 그 타일이고 시간이 맞으면 걸음마다 chance로.
func _tile_ambush(s: ExploreSession, cell: Vector2i) -> void:
	for rule in _tile_rules:
		var d: Dictionary = rule["def"]
		if int(rule["left"]) <= 0:
			continue
		var hours := JsonUtil.get_array(d, "hours")
		if hours.size() == 2 and not FieldClues.in_window(s, {"from": float(hours[0]), "to": float(hours[1])}):
			continue
		if not _on_tiles(s, cell, JsonUtil.get_array(d, "on_tiles"), JsonUtil.get_int(d, "near", 0)):
			continue
		if not s.rng.chance(JsonUtil.get_float(d, "chance", 0.02)):
			continue
		rule["left"] = int(rule["left"]) - 1
		_spring(s, cell, d)
		return


static func _on_tiles(s: ExploreSession, cell: Vector2i, tiles: Array, near: int) -> bool:
	for dy in range(-near, near + 1):
		for dx in range(-near, near + 1):
			var q := cell + Vector2i(dx, dy)
			if s.map.in_bounds(q) and tiles.has(s.map.tile_id_at(q)):
				return true
	return false


static func _spring(s: ExploreSession, cell: Vector2i, d: Dictionary) -> void:
	var g := s.monsters.add_fixed(JsonUtil.get_array(d, "monsters"), _beside(s, cell))
	if g == null:
		return
	g.alert_until = s.clock.total_hours + 1.0
	g.state = FieldMonsters.STATE_CHASE
	s.fx.emit("burst", g.pos, -1)  # 땅 · 벽 · 덤불이 터지며 솟아오른다(글 대신 — 문구는 silent)
	s.fx.emit("bang", g.pos, g.id)
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
