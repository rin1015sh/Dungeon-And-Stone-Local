class_name FloorGoal
extends RefCounted
## 층 목표(망자의 땅 — 곳곳의 종 셋을 울리면 고개의 쇠문이 열린다, FL18 · 사용자 2026-11-06 "층 목표"):
##   층 JSON "goal": {"flag": 이름, "need": 수, "hud": HUD 문구 키({n}/{need}), "open_line": 문이 열릴 때 문구 키, "open_sound": 소리 키}
##   동굴 요소 행동 "goal": 이름(FieldFeatureAct — 종 울리기)이 하나씩 센다. need에 닿으면 문 칸(map.anchors["gate"])을 원래 바닥으로.
##   생성기 gen.gate {"a", "b", "t", "tile"} = 길 a → b의 t 지점을 가로지르는 칸 줄을 닫힌 문 타일로(place_gate — FieldsGenerator가
##   _seal_unreachable 뒤에 부른다, 문 너머가 메워지지 않게). 순수 로직(오토로드 비의존).

var flag := ""
var need := 0
var count := 0
var opened := false
var _cfg: Dictionary = {}


static func setup(s: ExploreSession) -> FloorGoal:
	if not s.floor_def.has("goal"):
		return null
	var g := FloorGoal.new()
	g._cfg = JsonUtil.get_dict(s.floor_def, "goal")
	g.flag = JsonUtil.get_str(g._cfg, "flag")
	g.need = maxi(1, JsonUtil.get_int(g._cfg, "need", 1))
	return g


func hud_text() -> String:
	return JsonUtil.get_str(_cfg, "hud")


## 그 이름의 목표를 하나 이뤘다(종 하나를 울렸다).
func advance(s: ExploreSession, what: String) -> void:
	if what != flag or opened:
		return
	count += 1
	if count >= need:
		open(s)
	s.view_changed.emit()


func open(s: ExploreSession) -> void:
	opened = true
	var gate: Dictionary = s.map.anchors.get("gate", {})
	var cells: Array = gate.get("cells", [])
	var under: Array = gate.get("under", [])
	if cells.is_empty():
		return
	var lo: Vector2i = cells[0]
	var hi: Vector2i = cells[0]
	for i in cells.size():
		var c: Vector2i = cells[i]
		s.map.tiles[s.map.idx(c)] = int(under[i])
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	for e: Dictionary in s.features.list:  # 문에 놓인 요소(닫힌 쇠문 살피기)는 문과 함께 사라진다
		if cells.has(e["pos"]):
			e["cleared"] = true
	s.tiles_changed.emit(Rect2i(lo, hi - lo + Vector2i.ONE))
	var mid: Vector2i = cells[cells.size() / 2]
	if _cfg.has("open_sound"):
		s.sound.emit(JsonUtil.get_str(_cfg, "open_sound"), mid)
	if _cfg.has("open_line"):
		s.message.emit(JsonUtil.get_str(_cfg, "open_line"), {}, "info")
	s.refresh_view()


## 생성 때: 길 a → b의 t 지점에서 가장 가까운 걸을 수 있는 칸을 지나는 가로(길이 남북이면) 또는 세로 줄 전체를 문으로.
static func place_gate(map: FloorMap, g: Dictionary) -> void:
	var gd := JsonUtil.get_dict(g, "gate")
	var nodes: Dictionary = map.anchors.get("nodes", {})
	if gd.is_empty() or not nodes.has(JsonUtil.get_str(gd, "a")) or not nodes.has(JsonUtil.get_str(gd, "b")):
		return
	var a: Vector2i = nodes[JsonUtil.get_str(gd, "a")]
	var b: Vector2i = nodes[JsonUtil.get_str(gd, "b")]
	var p := Vector2i(Vector2(a).lerp(Vector2(b), JsonUtil.get_float(gd, "t", 0.5)).round())
	var start := Vector2i(-1, -1)
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := p + Vector2i(dx, dy)
				if start.x < 0 and map.in_bounds(q) and map.is_walkable(q):
					start = q
		if start.x >= 0:
			break
	if start.x < 0:
		return
	var step := Vector2i(1, 0) if absi(b.y - a.y) >= absi(b.x - a.x) else Vector2i(0, 1)
	var cells: Array = [start]
	for dir: Vector2i in [step, -step]:
		var q := start + dir
		while map.in_bounds(q) and map.is_walkable(q):
			cells.append(q)
			q += dir
	cells.sort()
	var under: Array = []
	var ti := map.index_of(JsonUtil.get_str(gd, "tile"))
	for c: Vector2i in cells:
		under.append(map.tiles[map.idx(c)])
		map.tiles[map.idx(c)] = ti
	map.anchors["gate"] = {"cells": cells, "under": under}
	if not map.anchors.has("marks"):
		map.anchors["marks"] = {}
	(map.anchors["marks"] as Dictionary)["gate_mid"] = cells[cells.size() / 2]  # 문 살피기 자리(route_spots features mark)
