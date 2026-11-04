class_name CityInterior
extends RefCounted
## 시설 실내(CT106 — data/interiors): 칸 글자 지도 하나에 방 몇 개(벽 · 벽 장식 · 방 사이 문으로 나뉜 칸 덩어리). 단층.
## 칸 종류(kind): wall('#') · floor('.') · exit('D' — 밟으면 나간다) · 범례 kind — wallart(벽에 붙은 것) · furniture(가구, 같은 글자 덩어리 = 그림 하나) ·
##   low(지나가는 낮은 것) · door(방 사이 문 — opens 사건 순이 아니거나 locked면 닫힘) · back(카운터 안쪽 — 못 들어감) · npc(사람 자리 — 막힘).
## needs가 걸린 가구 · 사람은 그 활동이 이번 순에 있을 때만 선다(없으면 빈 바닥). 활동 자리(spots)는 그 칸을 바라보고 Enter.
## 오토로드를 참조하지 않는다.

const WALK := ["floor", "exit", "low", "door"]
const SPLIT := ["wall", "wallart", "door", "exit", "void"]  ## 방을 나누는 칸

var id: String = ""
var def: Dictionary = {}
var legend: Dictionary = {}
var rows: PackedStringArray = []
var width: int = 0
var height: int = 0
var map: FloorMap
## 방 [{name_ko, rect: Rect2i(바닥 칸 둘레), def(rooms 항목)}] — 번호 = 이 배열 순서(칸 덩어리를 위→아래, 왼→오른쪽으로 찾은 순).
var rooms: Array[Dictionary] = []
## 지금 선 가구 덩어리 {char, rect: Rect2i, def, low}.
var furniture: Array[Dictionary] = []
## 지금 선 사람 {at: Vector2i, look, name_ko, face: Vector2i}.
var npcs: Array[Dictionary] = []
## 지금 할 수 있는 활동 자리 {cells: Array[Vector2i], acts: Array[String], name_ko}.
var spots: Array[Dictionary] = []
var _kind: Dictionary = {}  # Vector2i → 지금 kind(needs·opens 반영)
var _room: Dictionary = {}  # Vector2i → 방 번호(방 바닥 칸만)


## 이 시설의 실내(없으면 null — 시설 창).
static func load_for(state: CityState, facility_id: String) -> CityInterior:
	var iid := JsonUtil.get_str(state.db.get_entry("facilities", facility_id), "interior")
	if iid.is_empty() or not state.db.has_entry("interiors", iid):
		return null
	var r := CityInterior.new()
	r._build(state.db, iid, CityActions.activities_of(state, facility_id), state.happenings)
	return r


## 실내 id로 바로(일반 집 — 시설 활동 없음, CT110). 없으면 null.
static func load_id(state: CityState, iid: String) -> CityInterior:
	if iid.is_empty() or not state.db.has_entry("interiors", iid):
		return null
	var r := CityInterior.new()
	r._build(state.db, iid, [] as Array[String], state.happenings)
	return r


## 칸 글자의 범례(#·.·D는 정해진 것).
static func cell_def(p_legend: Dictionary, ch: String) -> Dictionary:
	match ch:
		"#":
			return {"kind": "wall"}
		".":
			return {"kind": "floor"}
		"D":
			return {"kind": "exit"}
	return JsonUtil.get_dict(p_legend, ch) if p_legend.has(ch) else {"kind": "void"}


## 같은 글자가 붙은 칸 덩어리(4방향) — kind가 kinds 중 하나인 글자만. [{char, rect, cells}] (위→아래, 왼→오른쪽).
static func groups(p_rows: PackedStringArray, p_legend: Dictionary, kinds: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for y in p_rows.size():
		for x in p_rows[y].length():
			var ch := p_rows[y][x]
			if seen.has(Vector2i(x, y)) or not JsonUtil.get_str(cell_def(p_legend, ch), "kind") in kinds:
				continue
			var cells: Array[Vector2i] = []
			var todo: Array[Vector2i] = [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var lo := Vector2i(x, y)
			var hi := Vector2i(x, y)
			while not todo.is_empty():
				var c: Vector2i = todo.pop_back()
				cells.append(c)
				lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
				hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := c + d
					if n.y >= 0 and n.y < p_rows.size() and n.x >= 0 and n.x < p_rows[n.y].length() and p_rows[n.y][n.x] == ch and not seen.has(n):
						seen[n] = true
						todo.append(n)
			out.append({"char": ch, "rect": Rect2i(lo, hi - lo + Vector2i.ONE), "cells": cells})
	return out


## 방 나누기: 나누는 칸(벽 · 벽 장식 · 문 · 바깥 문)이 아닌 칸 덩어리 [[칸 …] …] (위→아래, 왼→오른쪽). 범례만 본다(사건과 무관).
static func room_cells(p_rows: PackedStringArray, p_legend: Dictionary) -> Array[Array]:
	var out: Array[Array] = []
	var seen := {}
	var inside := func(c: Vector2i) -> bool:
		return c.y >= 0 and c.y < p_rows.size() and c.x >= 0 and c.x < p_rows[c.y].length() \
			and not JsonUtil.get_str(cell_def(p_legend, p_rows[c.y][c.x]), "kind") in SPLIT
	for y in p_rows.size():
		for x in p_rows[y].length():
			var s := Vector2i(x, y)
			if seen.has(s) or not inside.call(s):
				continue
			var cells: Array[Vector2i] = []
			var todo: Array[Vector2i] = [s]
			seen[s] = true
			while not todo.is_empty():
				var c: Vector2i = todo.pop_back()
				cells.append(c)
				for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var n := c + d
					if not seen.has(n) and inside.call(n):
						seen[n] = true
						todo.append(n)
			out.append(cells)
	return out


func _build(db: GameDatabase, iid: String, open: Array[String], happenings: Array[String]) -> void:
	id = iid
	def = db.get_entry("interiors", iid)
	legend = JsonUtil.get_dict(def, "legend")
	for r: Variant in JsonUtil.get_array(def, "rows"):
		rows.append(str(r))
		width = maxi(width, str(r).length())
	height = rows.size()
	var town := JsonUtil.get_dict(db.singletons.get("city", {}), "town")
	map = FloorMap.new(db, width, height, JsonUtil.get_str(town, "block_tile", "rock_wall"))
	var floor_tile := JsonUtil.get_str(town, "floor_tile", "cave_floor")
	for y in height:
		for x in rows[y].length():
			var d := cell_def(legend, rows[y][x])
			var k := JsonUtil.get_str(d, "kind", "void")
			var needs := JsonUtil.get_str(d, "needs")
			if not needs.is_empty() and not open.has(needs):
				k = "floor"
			if k == "door" and (JsonUtil.get_bool(d, "locked") or (d.has("opens") and not happenings.has(JsonUtil.get_str(d, "opens")))):
				k = "wallart"  # 닫힌 문 = 벽(바라보고 Enter = 잠겨 있다)
			_kind[Vector2i(x, y)] = k
			if k in WALK:
				map.set_tile(Vector2i(x, y), floor_tile)
	var rdefs := JsonUtil.get_array(def, "rooms")
	for cells: Array in room_cells(rows, legend):
		var lo := Vector2i(width, height)
		var hi := Vector2i(-1, -1)
		var rd := {}
		for c: Vector2i in cells:
			_room[c] = rooms.size()
			lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
			hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
			for v: Variant in rdefs:
				var at := JsonUtil.get_array(v as Dictionary, "at")
				if at.size() == 2 and Vector2i(int(at[0]), int(at[1])) == c:
					rd = v as Dictionary
		rooms.append({"name_ko": JsonUtil.get_str(rd, "name_ko"), "rect": Rect2i(lo, hi - lo + Vector2i.ONE), "def": rd})
	for g: Dictionary in groups(rows, legend, ["furniture", "low"]):
		if _kind.get((g["cells"] as Array)[0], "") in ["furniture", "low"]:
			var gd := cell_def(legend, str(g["char"]))
			furniture.append({"char": g["char"], "rect": g["rect"], "def": gd, "low": JsonUtil.get_str(gd, "kind") == "low"})
	for v: Variant in JsonUtil.get_array(def, "npcs"):
		var n: Dictionary = v
		if not JsonUtil.get_str(n, "needs").is_empty() and not open.has(JsonUtil.get_str(n, "needs")):
			continue
		var at := JsonUtil.get_array(n, "at")
		var f := JsonUtil.get_array(n, "face")
		npcs.append({"at": Vector2i(int(at[0]), int(at[1])), "look": JsonUtil.get_str(n, "look"), "name_ko": JsonUtil.get_str(n, "name_ko"),
			"face": Vector2i(int(f[0]), int(f[1])) if f.size() == 2 else Vector2i(0, 1)})
	for v: Variant in JsonUtil.get_array(def, "spots"):
		var s: Dictionary = v
		var acts: Array[String] = []
		for a: Variant in JsonUtil.get_array(s, "activities"):
			if open.has(str(a)) and not acts.has(str(a)):
				acts.append(str(a))
		var cells := spot_cells(s)
		if acts.is_empty() or cells.is_empty() or _kind.get(cells[0], "") == "floor":
			continue  # 이번 순에 없는 활동 · 서지 않은 가구
		spots.append({"cells": cells, "acts": acts, "name_ko": JsonUtil.get_str(s, "name_ko")})


## 자리 정의의 칸들(char = 그 글자 칸 모두, at = 한 칸).
func spot_cells(s: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var at := JsonUtil.get_array(s, "at")
	if at.size() == 2:
		out.append(Vector2i(int(at[0]), int(at[1])))
	var ch := JsonUtil.get_str(s, "char")
	if not ch.is_empty():
		for y in height:
			for x in rows[y].length():
				if rows[y][x] == ch:
					out.append(Vector2i(x, y))
	return out


func kind_at(cell: Vector2i) -> String:
	return str(_kind.get(cell, "void"))


func is_exit(cell: Vector2i) -> bool:
	return kind_at(cell) == "exit"


## 그 칸이 속한 방 번호(방 사이 문 · 벽 = -1).
func room_at(cell: Vector2i) -> int:
	return int(_room.get(cell, -1))


## 들어온 자리: 바깥 문(D) 칸들 가운데의 한 칸 위(북쪽), 위를 본다.
func start() -> Vector2:
	var xs: Array[int] = []
	var y := 0
	for yy in height:
		for x in rows[yy].length():
			if rows[yy][x] == "D":
				xs.append(x)
				y = yy
	if xs.is_empty():
		return Vector2(width * 0.5, height - 1.5)
	return Vector2((xs.min() + xs.max() + 1) * 0.5, y - 0.5)


## 몸(칸 좌표 pos)이 facing을 볼 때 바로 앞의 것: 활동 자리 {cells, acts, name_ko} · 잠긴 문 {locked: true} · 없으면 {}.
func target(pos: Vector2, facing: Vector2i) -> Dictionary:
	var ahead := Kinematics.cell_of(pos + Vector2(facing) * 0.8)
	for s: Dictionary in spots:
		if (s["cells"] as Array).has(ahead):
			return s
	var d := cell_def(legend, rows[ahead.y][ahead.x]) if ahead.y >= 0 and ahead.y < height and ahead.x >= 0 and ahead.x < rows[ahead.y].length() else {}
	if JsonUtil.get_bool(d, "locked") or (JsonUtil.get_str(d, "kind") == "door" and kind_at(ahead) != "door"):
		return {"locked": true, "cells": [ahead] as Array[Vector2i], "acts": [] as Array[String], "name_ko": ""}
	return {}


## 상호작용 대상 칸(검은 테두리 — CT77): 활동 자리 칸 모두.
func interactive_cells() -> Dictionary:
	var out := {}
	for s: Dictionary in spots:
		for c: Vector2i in s["cells"]:
			out[c] = true
	return out
