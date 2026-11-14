class_name WitchHut
extends RefCounted
## 마녀의 오두막(3층 — 층 JSON "witch_hut", docs/plans/floor3.md §5). 순수 로직(오토로드 비의존).
## 입구: check_every_hours마다 spawn_chance로 마녀의 숲 구간(witch_forest.hut_nodes) 하나에 보랏빛 나무(f3_purple_tree)가 선다
##   (정해진 간격으로 꼭 생기지 않는다 — 운이 나쁘면 며칠 없다). 나무는 open_hours 뒤 마른 나무로 돌아간다. 한 번에 max_open개까지.
## 들어가기: 나무 옆에서 살핀다 → 파티(플레이어 + 동료) 수가 capacity 이하면 오두막(지도 아래 따로 된 방 — gen.crypts, 길이 없다)으로.
##   들어간 무리 수가 capacity에 차면 그 입구는 닫힌다(나무가 마른 나무로). 오두막은 그 입구가 남은 시간만큼(만료 시각 until) 머문다.
##   안전지대(map.safe_zones — 휴식 회복 · 몬스터 없음), 구역이 숲이 아니라 필드 효과가 풀린다.
## 모닥불(f3_hut_bonfire): 시신(corpse_items 아이템)을 하나 바치면 until += extend_hours. 시신은 가방에서 사라지니 같은 시신을 두 번 쓸 수 없다.
## 시간이 다 되면 안에 있던 플레이어는 숲(입구 자리)으로 밀려난다. 안개(f3_hut_mist)를 살피면 스스로 나간다.
## 리아키스(riakis_flag가 player.progression.lords_defeated 또는 flags에 있으면): 바깥이 설원(그림 타일 바꿈), 안은 그대로.
##   그때 난로(f3_hut_hearth)에 들어가면 히든 피스(hidden_piece.reward — 원문에 없어 비어 있다) → 오두막이 닫히고 숲으로 추방,
##   다시 들어갈 수 없다(progression.flags "f3_hut_hidden" — 저장된다). 리아키스 전에는 난로가 그냥 따뜻하다.

const FLAG_HIDDEN := "f3_hut_hidden"

var entrances: Array = []   ## [{pos, until, used, base}]
var inside_of: Dictionary = {}  ## 지금 들어와 있는 입구(없으면 {})
var _cfg: Dictionary = {}
var _next_check: float = -1.0
var _safe: Dictionary = {}
var _decorated: String = ""


static func setup(s: ExploreSession) -> WitchHut:
	var d := JsonUtil.get_dict(s.floor_def, "witch_hut")
	if d.is_empty() or not (s.map.anchors.get("marks", {}) as Dictionary).has("hut_in"):
		return null
	var h := WitchHut.new()
	h._cfg = d
	return h


func inside() -> bool:
	return not inside_of.is_empty()


## 오두막이 남은 시간(안에 있을 때만, 아니면 -1).
func hours_left(s: ExploreSession) -> float:
	return maxf(0.0, float(inside_of["until"]) - s.clock.total_hours) if inside() else -1.0


func winter(s: ExploreSession) -> bool:
	var f := JsonUtil.get_str(_cfg, "riakis_flag", "riakis_slain")
	return s.player.progression.lords_defeated.has("riakis") or s.player.progression.flags.has(f)


func sealed(s: ExploreSession) -> bool:
	return s.player.progression.flags.has(FLAG_HIDDEN)


func update(s: ExploreSession, _hours: float) -> void:
	var now := s.clock.total_hours
	if _next_check < 0.0:
		_next_check = now + JsonUtil.get_float(_cfg, "check_every_hours", 6.0)
	elif now >= _next_check:
		_next_check = now + JsonUtil.get_float(_cfg, "check_every_hours", 6.0)
		if s.rng.chance(JsonUtil.get_float(_cfg, "spawn_chance", 0.35)):
			spawn(s)
	for e: Dictionary in entrances.duplicate():
		if now >= float(e["until"]):
			if e == inside_of:
				_expel(s, _line("expire"))
			_close(s, e)


## 보랏빛 나무 하나를 세운다(테스트 · 디버그도 부른다). 세운 칸(없으면 (-1, -1)).
func spawn(s: ExploreSession) -> Vector2i:
	if sealed(s) or entrances.size() >= JsonUtil.get_int(_cfg, "max_open", 2):
		return Vector2i(-1, -1)
	var nodes: Dictionary = s.map.anchors.get("nodes", {})
	var radii: Dictionary = s.map.anchors.get("node_r", {})
	var ids := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "witch_forest"), "hut_nodes")
	for tries in 12:
		if ids.is_empty():
			break
		var id := str(ids[s.rng.randi_range(0, ids.size() - 1)])
		if not nodes.has(id):
			continue
		var c: Vector2i = nodes[id]
		if Vector2(c - s.pos).length() < 12.0:
			continue  # 바로 눈앞에서 솟지 않는다
		var at := _tree_cell(s, c, float(radii.get(id, 8.0)))
		if at.x < 0:
			continue
		entrances.append({"pos": at, "base": s.map.tile_id_at(at), "until": s.clock.total_hours + JsonUtil.get_float(_cfg, "open_hours", 8.0), "used": 0})
		s.map.set_tile(at, "f3_purple_tree")
		s.tiles_changed.emit(Rect2i(at, Vector2i.ONE))
		return at
	return Vector2i(-1, -1)


func interact(s: ExploreSession) -> bool:
	var here := s.map.tile_id_at(s.pos)
	if here == "f3_hut_mist" and inside():
		_expel(s, _line("left"))
		return true
	for d in FloorMap.DIRS4:
		var q: Vector2i = s.pos + d
		match s.map.tile_id_at(q):
			"f3_purple_tree":
				_enter(s, q)
				return true
			"f3_hut_bonfire", "f3_hut_bonfire_snow":
				_offer(s)
				return true
			"f3_hut_hearth":
				_hearth(s)
				return true
	return false


func target_name(s: ExploreSession) -> String:
	if s.map.tile_id_at(s.pos) == "f3_hut_mist" and inside():
		return s.map.def_at(s.pos).name_ko
	for d in FloorMap.DIRS4:
		var id := s.map.tile_id_at(s.pos + d)
		if id in ["f3_purple_tree", "f3_hut_bonfire", "f3_hut_bonfire_snow", "f3_hut_hearth"]:
			return s.map.def_at(s.pos + d).name_ko
	return ""


# ── 내부 ─────────────────────────────────────────────────

func _enter(s: ExploreSession, tree: Vector2i) -> void:
	var e := _entrance_at(tree)
	if e.is_empty() or sealed(s):
		s.message.emit(_line("closed"), {}, "info")
		return
	var n := 1 + s.companions.size()
	var cap := JsonUtil.get_int(_cfg, "capacity", 5)
	if n + int(e["used"]) > cap:
		s.message.emit(_line("full"), {"n": cap}, "warn")
		return
	var marks: Dictionary = s.map.anchors.get("marks", {})
	_decorate(s)
	e["used"] = int(e["used"]) + n
	e["back"] = _beside(s, tree)
	inside_of = e
	_safe = {"center": marks.get("hut_center", marks["hut_in"]), "radius": 40.0}
	s.map.safe_zones.append(_safe)
	s.sound.emit("f3_hut_mist", tree)
	s.relocate(marks["hut_in"])
	FieldFeatureAct.say_line(s, _line("winter") if winter(s) else _line("enter"), {"pos": s.pos}, "system")
	if int(e["used"]) >= cap:
		_shut_tree(s, e)  # 정원이 찼다 — 바깥 입구가 닫힌다(안에 있는 동안 오두막은 그대로)


func _expel(s: ExploreSession, line: String) -> void:
	var e := inside_of
	inside_of = {}
	s.map.safe_zones.erase(_safe)
	_safe = {}
	var back: Vector2i = e.get("back", s.map.entry)
	s.sound.emit("f3_hut_mist", back)
	if not s.relocate(back):
		s.relocate(_beside(s, back))
	if not line.is_empty():
		FieldFeatureAct.say_line(s, line, {"pos": s.pos}, "info")


func _offer(s: ExploreSession) -> void:
	if not inside():
		return
	for it: Variant in JsonUtil.get_array(_cfg, "corpse_items"):
		var id := str(it)
		if s.player.inventory.has(id):
			s.player.inventory.remove(id, 1)
			inside_of["until"] = float(inside_of["until"]) + JsonUtil.get_float(_cfg, "extend_hours", 8.0)
			s.sound.emit("f3_hut_mist", s.pos)
			s.fx.emit("burst", s.pos, -1)
			s.message.emit(_line("offer"), {"hours": ceili(hours_left(s))}, "good")
			return
	s.message.emit(_line("offer_none"), {}, "info")


func _hearth(s: ExploreSession) -> void:
	if not inside() or not winter(s) or sealed(s):
		FieldFeatureAct.say_line(s, _line("hearth_cold") if not winter(s) else _line("closed"), {"pos": s.pos}, "info")
		return
	s.player.progression.flags[FLAG_HIDDEN] = true
	var hp := JsonUtil.get_dict(_cfg, "hidden_piece")
	FieldFeatureAct.say_line(s, _line("hearth"), {"pos": s.pos}, "system")
	var reward := JsonUtil.get_array(hp, "reward")
	if reward.is_empty():
		s.message.emit(_line("hidden"), {}, "good")
	else:
		FieldFeatureAct.give_items(s, reward)
	var e := inside_of
	_expel(s, "")
	for x: Dictionary in entrances.duplicate():
		_close(s, x)
	if not e.is_empty():
		_close(s, e)


func _close(s: ExploreSession, e: Dictionary) -> void:
	_shut_tree(s, e)
	entrances.erase(e)


func _shut_tree(s: ExploreSession, e: Dictionary) -> void:
	var q: Vector2i = e["pos"]
	if s.map.tile_id_at(q) == "f3_purple_tree":
		s.map.set_tile(q, "f3_witch_deadtree")
		s.tiles_changed.emit(Rect2i(q, Vector2i.ONE))


func _entrance_at(q: Vector2i) -> Dictionary:
	for e: Dictionary in entrances:
		if e["pos"] == q:
			return e
	return {}


## 오두막 바깥 그림(봄 · 설원)과 고정 소품(나무 · 모닥불 · 책장 · 식탁 · 난로)을 놓는다 — 들어갈 때마다(리아키스 뒤면 설원으로 바뀐다).
func _decorate(s: ExploreSession) -> void:
	var season := "winter" if winter(s) else "spring"
	if _decorated == season:
		return
	_decorated = season
	var p := JsonUtil.get_dict(JsonUtil.get_dict(_cfg, "props"), season)
	var marks: Dictionary = s.map.anchors.get("marks", {})
	var c: Vector2i = marks.get("hut_center", marks["hut_in"])
	var ground := JsonUtil.get_str(p, "ground", "f3_hut_meadow")
	var box := Rect2i(c - Vector2i(30, 12), Vector2i(61, 24))
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var q := Vector2i(x, y)
			if not s.map.in_bounds(q):
				continue
			var id := s.map.tile_id_at(q)
			if id in ["f3_hut_meadow", "f3_hut_snow", "f3_hut_oak", "f3_hut_birch", "f3_hut_bare", "f3_hut_pine_snow", "f3_hut_drift"]:
				s.map.set_tile(q, ground)
	var rng := Rng.new(7)
	var trees := [JsonUtil.get_str(p, "trees"), JsonUtil.get_str(p, "trees2"), JsonUtil.get_str(p, "drift")]
	for k in 40:
		var q := c + Vector2i(rng.randi_range(-26, 26), rng.randi_range(-8, 9))
		if absi(q.x - c.x) < 12 and q.y - c.y < 9:
			continue  # 오두막 · 모닥불 둘레는 비운다
		var t := str(trees[k % 3])
		if not t.is_empty() and s.map.tile_id_at(q) == ground and _open8(s, q):
			s.map.set_tile(q, t)
	var put := func(mark: String, tile: String) -> void:
		if marks.has(mark) and not tile.is_empty():
			s.map.set_tile(marks[mark], tile)
	put.call("hut_bonfire", JsonUtil.get_str(p, "bonfire"))
	put.call("hut_hearth", "f3_hut_hearth")
	put.call("hut_shelf_a", "f3_hut_shelf")
	put.call("hut_shelf_b", "f3_hut_shelf")
	put.call("hut_table", "f3_hut_table")
	s.tiles_changed.emit(box)


func _tree_cell(s: ExploreSession, c: Vector2i, r: float) -> Vector2i:
	for tries in 40:
		var q := c + Vector2i(s.rng.randi_range(-int(r), int(r)), s.rng.randi_range(-int(r), int(r)))
		if s.map.zone_at(q) == JsonUtil.get_str(JsonUtil.get_dict(s.floor_def, "witch_forest"), "zone", "f3_witch") and s.map.is_walkable(q) \
				and _open8(s, q) and s.map.portal_at(q).is_empty() and s.monsters.group_at(q) == null:
			return q
	return Vector2i(-1, -1)


func _open8(s: ExploreSession, q: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if not s.map.is_walkable(q + Vector2i(dx, dy)):
				return false
	return true


func _beside(s: ExploreSession, q: Vector2i) -> Vector2i:
	for d: Vector2i in [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i(1, 1), Vector2i(-1, 1)]:
		if s.map.is_walkable(q + d) and s.monsters.group_at(q + d) == null:
			return q + d
	return q + Vector2i.DOWN


func _line(k: String) -> String:
	return JsonUtil.get_str(JsonUtil.get_dict(_cfg, "lines"), k)
