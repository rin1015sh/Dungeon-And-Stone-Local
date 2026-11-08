class_name FieldTerrain
extends RefCounted
## 변하는 지형(망자의 땅 — docs/plans/floor2.md §14-4 · §14-5, FL14). 층 JSON "terrain":
##   "tide": {"period_hours", "flood": 타일, "deep": 타일} — 물때. map.anchors["tide"] = {칸: "flood" | "deep"}(FieldsRoute가 길 · 구간 "tide"로 표시).
##     썰물(주기 짝수 번째) = 그 칸의 원래 낮은 땅, 밀물 = flood(얕은 물 — 걸을 수 있고 느리다) 또는 deep(깊은 물 — 섬으로 가는 갯길이 끊긴다).
##     플레이어 · 무리가 선 칸과 그 둘레는 deep 대신 flood(갇히지 않게). 바뀐 칸 묶음은 tiles_changed로 다시 그린다.
##   "night_fog": {"zones": [구역], "from", "to"(시각 0~24), "cap_m"} — 밤에 그 구역에서는 시야가 cap_m를 넘지 못한다.
##   "crumble": {"hole": 타일, "drop": {"to": 표시 이름}} — 무른 땅(타일 art 없이 id로: map.anchors["crumble"] = {칸: true}).
##     밟고 지나가면(다음 칸으로 넘어가는 순간) 뒤의 칸이 꺼진다(hole). 표시 "drop" 칸은 꺼지며 떨어진다 — 지하 묘실(표시 to)로.
##   "wisps": [{"points": [[구간, dx, dy] …], "tile"}] — 넋불: 다가가면(4칸) 다음 자리로 물러난다, 끝 자리(숨은 방 앞)에서 멈춘다.
##   "procession": {"monsters", "route": [구간 …], "from", "to"(시각)} — 장례 행렬: 밤마다 구간을 잇는 길을 도는 무리, 낮이 되면 사라진다.
## ExploreSession이 start · pass_time · enter_cell · refresh_view에서 부른다. 세이브 없음(원정 중에만 산다).

var _cfg: Dictionary = {}
var _tide: Dictionary = {}      # 칸 → [마른 타일 번호, "flood"|"deep"]
var _high: int = -1             # 지금 물때(-1 = 아직 안 깔음, 0 썰물, 1 밀물)
var _crumble: Dictionary = {}   # 칸 → true(무른 땅)
var _drops: Dictionary = {}     # 칸 → 떨어질 표시 이름
var _wisps: Array[Dictionary] = []  # {points: [칸 …], at: 번호, under: 타일 번호, tile}
var _procession: FieldMonsters.Group = null
var _proc_route: Array[Vector2i] = []
var _proc_i: int = 0


static func setup(s: ExploreSession) -> FieldTerrain:
	var cfg := JsonUtil.get_dict(s.floor_def, "terrain")
	if cfg.is_empty():
		return null
	var t := FieldTerrain.new()
	t._cfg = cfg
	var tide: Dictionary = s.map.anchors.get("tide", {})
	for q: Vector2i in tide:
		t._tide[q] = [s.map.tiles[s.map.idx(q)], str(tide[q])]
	t._crumble = s.map.anchors.get("crumble", {})
	t._drops = s.map.anchors.get("drops", {})
	t._place_wisps(s)
	t.update(s)
	return t


## 시간이 흐를 때 · 처음.
func update(s: ExploreSession) -> void:
	_update_tide(s)
	_update_wisps(s)
	if s.monsters_enabled:
		_update_procession(s)


## 시야 상한(밤 안개).
func vision_cap(s: ExploreSession, vision_m: float) -> float:
	var fog := JsonUtil.get_dict(_cfg, "night_fog")
	if fog.is_empty() or not _is_night(s, fog) or not JsonUtil.get_array(fog, "zones").has(s.map.zone_at(s.pos)):
		return vision_m
	return minf(vision_m, JsonUtil.get_float(fog, "cap_m", 4.0))


## 칸을 옮겼다: 무른 땅이 꺼지고(뒤 칸), 떨어지는 자리면 떨어진다. 넋불이 물러난다.
func on_enter(s: ExploreSession, from: Vector2i, to: Vector2i) -> void:
	_update_wisps(s)
	if _drops.has(to):
		var mark := str(_drops[to])
		var marks: Dictionary = s.map.anchors.get("marks", {})
		if marks.has(mark):
			_collapse(s, to)
			s.fx.emit("burst", to, -1)
			s.message.emit("explore.ground_gives", {}, "danger")
			s.sound.emit("crumble", to)
			s.relocate(marks[mark])
			return
	if _crumble.has(from) and from != to:
		_collapse(s, from)
		s.sound.emit("crumble", from)


func _collapse(s: ExploreSession, q: Vector2i) -> void:
	var c := JsonUtil.get_dict(_cfg, "crumble")
	_crumble.erase(q)
	s.map.set_tile(q, JsonUtil.get_str(c, "hole"))
	s.tiles_changed.emit(Rect2i(q, Vector2i.ONE))


static func _is_night(s: ExploreSession, d: Dictionary) -> bool:
	var h := s.clock.hour_of_day()
	var a := JsonUtil.get_float(d, "from", 18.0)
	var b := JsonUtil.get_float(d, "to", 6.0)
	return (h >= a or h < b) if a > b else (h >= a and h < b)


# ── 물때 ──────────────────────────────────────────
func _update_tide(s: ExploreSession) -> void:
	var td := JsonUtil.get_dict(_cfg, "tide")
	if td.is_empty() or _tide.is_empty():
		return
	var high := int(floorf(s.clock.total_hours / JsonUtil.get_float(td, "period_hours", 24.0))) % 2
	if high == _high:
		return
	_high = high
	var flood := s.map.index_of(JsonUtil.get_str(td, "flood"))
	var deep := s.map.index_of(JsonUtil.get_str(td, "deep"))
	var lo := Vector2i(s.map.width, s.map.height)
	var hi := Vector2i(-1, -1)
	for q: Vector2i in _tide:
		var e: Array = _tide[q]
		var ti: int = int(e[0])
		if high == 1:
			ti = deep if str(e[1]) == "deep" and not _occupied(s, q) else flood
		if s.map.tiles[s.map.idx(q)] != ti:
			s.map.tiles[s.map.idx(q)] = ti
			lo = Vector2i(mini(lo.x, q.x), mini(lo.y, q.y))
			hi = Vector2i(maxi(hi.x, q.x), maxi(hi.y, q.y))
	if hi.x >= 0:
		s.tiles_changed.emit(Rect2i(lo, hi - lo + Vector2i.ONE))


## 플레이어나 무리가 그 칸 둘레(1칸)에 있다 — 깊은 물로 바꾸지 않는다(갇히지 않게).
func _occupied(s: ExploreSession, q: Vector2i) -> bool:
	if absi(q.x - s.pos.x) <= 1 and absi(q.y - s.pos.y) <= 1:
		return true
	for g: FieldMonsters.Group in s.monsters.groups:
		if absi(q.x - g.pos.x) <= 1 and absi(q.y - g.pos.y) <= 1:
			return true
	return false


func high_tide() -> bool:
	return _high == 1


# ── 넋불 ──────────────────────────────────────────
func _place_wisps(s: ExploreSession) -> void:
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	for w: Variant in JsonUtil.get_array(_cfg, "wisps"):
		var wd: Dictionary = w if w is Dictionary else {}
		var pts: Array[Vector2i] = []
		for p: Variant in JsonUtil.get_array(wd, "points"):
			var pa: Array = p
			var c: Vector2i = nodes.get(str(pa[0]), Vector2i(-1, -1))
			var q := c + Vector2i(int(pa[1]), int(pa[2]))
			if c.x >= 0 and s.map.is_walkable(q):
				pts.append(q)
		if pts.size() < 2:
			continue
		var e := {"points": pts, "at": 0, "under": s.map.tiles[s.map.idx(pts[0])], "tile": JsonUtil.get_str(wd, "tile")}
		s.map.set_tile(pts[0], str(e["tile"]))
		_wisps.append(e)


func _update_wisps(s: ExploreSession) -> void:
	for e in _wisps:
		var pts: Array[Vector2i] = e["points"]
		var at := int(e["at"])
		if at >= pts.size() - 1 or Vector2(pts[at] - s.pos).length() > 4.0:
			continue
		var old := pts[at]
		s.map.tiles[s.map.idx(old)] = int(e["under"])
		at += 1
		e["at"] = at
		e["under"] = s.map.tiles[s.map.idx(pts[at])]
		s.map.set_tile(pts[at], str(e["tile"]))
		s.tiles_changed.emit(Rect2i(Vector2i(mini(old.x, pts[at].x), mini(old.y, pts[at].y)), (old - pts[at]).abs() + Vector2i.ONE))


func wisp_at(i: int) -> Vector2i:
	return (_wisps[i]["points"] as Array[Vector2i])[int(_wisps[i]["at"])] if i < _wisps.size() else Vector2i(-1, -1)


# ── 장례 행렬 ──────────────────────────────────────
func _update_procession(s: ExploreSession) -> void:
	var pd := JsonUtil.get_dict(_cfg, "procession")
	if pd.is_empty():
		return
	var night := _is_night(s, pd)
	var alive := _procession != null and s.monsters.groups.has(_procession)
	if night and not alive:
		var nodes: Dictionary = s.map.anchors.get("nodes", {})
		_proc_route.clear()
		for id: Variant in JsonUtil.get_array(pd, "route"):
			if nodes.has(str(id)):
				_proc_route.append(nodes[str(id)])
		if _proc_route.size() < 2 or Vector2(_proc_route[0] - s.pos).length() < 12.0:
			return
		_procession = s.monsters.add_fixed(JsonUtil.get_array(pd, "monsters"), _proc_route[0])
		_proc_i = 0
	elif alive and not night and Vector2(_procession.pos - s.pos).length() > 12.0:
		s.monsters.groups.erase(_procession)
		s.monsters.changed.emit()
		_procession = null
	elif alive and _procession.route.is_empty() and _procession.state != FieldMonsters.STATE_CHASE:
		_proc_i = (_proc_i + 1) % _proc_route.size()  # 다음 구간으로(끝이면 처음으로 — 묘역 → 예배당 → 묘역)
		s.monsters.send_to(_procession, _proc_route[_proc_i], s.pos)
