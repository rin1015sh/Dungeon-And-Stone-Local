class_name CityRoom
extends RefCounted
## 시설 실내(탑뷰 한 지도 — data/rooms, CT62·CT64·CT66): 칸 글자 지도 + 범례(city.json room.legend 위에 방 JSON legend) · 가구 무리 · 사람 · 살필 자리.
## 층은 한 지도 안에 있다(사용자 2026-10-31 "복층은 한 맵에서 이어지게") — 위층은 북쪽, 지하는 남쪽, 계단(stairs)·사다리(ladder) 칸 줄이 벽·틈을 지나 잇는다.
## 칸 종류(kind): floor(material — 없으면 regions·방 floor) · rug · decor(걷는 바닥 장식) · wall · walldeco(벽 장식) · furniture(가구 — 같은 글자가 붙은 칸이 한 무리,
##   needs = 그 활동이 지금 있을 때만 — 없으면 빈 바닥) · door · doorway · locked(opens = 이번 순 사건 id가 걸리면 열림) · entry(밟으면 나간다) ·
##   stairs · ladder(그 칸 위에서는 좌우를 막는다 — RoomView) · open(트인 곳) · rail · void · npc(사람 자리 — npcs 목록이 그린다).
## 살필 자리(spots)는 rect 칸을 바라보고 살피면 그 활동(activity·activities — 지금 있는 것만), rest = 자리가 없는 이 시설 활동(이번 순 사건 등)도 여기서.
## 오토로드를 참조하지 않는다.

const WALK := ["floor", "rug", "decor", "door", "doorway", "entry", "stairs", "ladder"]

var id: String = ""
var def: Dictionary = {}
var legend: Dictionary = {}
var rows: PackedStringArray = []
var width: int = 0
var height: int = 0
var map: FloorMap
var start: Vector2 = Vector2.ZERO
## 지금 선 가구 무리 {char, rect: Rect2i, def}.
var furniture: Array[Dictionary] = []
## 사람 {at: Vector2i, look, name_ko, staff, face: Vector2i}.
var npcs: Array[Dictionary] = []
## 지금 살필 수 있는 자리 {rect: Rect2i, acts: Array[String], rest, name_ko}.
var spots: Array[Dictionary] = []
var _kind: Dictionary = {}  # Vector2i → 그 칸 kind(지금 상태 — 잠김·가구 needs 반영)


## 이 시설의 방(없으면 null — 메뉴 시설).
static func load_for(state: CityState, facility_id: String) -> CityRoom:
	var room_id := JsonUtil.get_str(state.db.get_entry("facilities", facility_id), "room")
	if room_id.is_empty() or not state.db.has_entry("rooms", room_id):
		return null
	var r := CityRoom.new()
	r._build(state, room_id)
	return r


## 방 규칙 값(city.json room).
static func rule(state: CityState, key: String, fallback: float) -> float:
	var v := CityValues.num(CityValues.city_section(state.db, state.overrides, "room"), key)
	return v if v > 0.0 else fallback


## 범례: 공통(city.json room.legend) 위에 방 JSON legend.
static func legend_of(db: GameDatabase, room: Dictionary) -> Dictionary:
	var out := JsonUtil.get_dict(JsonUtil.get_dict(db.singletons.get("city", {}), "room"), "legend").duplicate()
	out.merge(JsonUtil.get_dict(room, "legend"), true)
	return out


## 같은 글자가 붙은 칸 무리(4방향) — kind가 kinds 중 하나인 글자만. [{char, rect: Rect2i, cells: Array[Vector2i]}] (위에서 아래, 왼쪽에서 오른쪽 순).
static func groups(p_rows: PackedStringArray, p_legend: Dictionary, kinds: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	for y in p_rows.size():
		for x in p_rows[y].length():
			var ch := p_rows[y][x]
			if seen.has(Vector2i(x, y)) or not JsonUtil.get_str(JsonUtil.get_dict(p_legend, ch), "kind") in kinds:
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


## 가구 무리 그림 경로(art_dir/f_<글자 코드>_<w>x<h>.webp — 같은 글자·크기는 한 장).
static func furniture_art(room: Dictionary, ch: String, size: Vector2i) -> String:
	return JsonUtil.get_str(room, "art_dir").path_join("f_%x_%dx%d.webp" % [ch.unicode_at(0), size.x, size.y])


func _build(state: CityState, room_id: String) -> void:
	id = room_id
	def = state.db.get_entry("rooms", room_id)
	legend = legend_of(state.db, def)
	for r: Variant in JsonUtil.get_array(def, "rows"):
		rows.append(str(r))
		width = maxi(width, str(r).length())
	height = rows.size()
	var cfg := CityValues.city_section(state.db, state.overrides, "room")
	map = FloorMap.new(state.db, width, height, JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
	var floor_tile := JsonUtil.get_str(cfg, "floor_tile", "cave_floor")
	var open := CityActions.activities_of(state, JsonUtil.get_str(def, "facility"))
	for y in height:
		for x in rows[y].length():
			var d := JsonUtil.get_dict(legend, rows[y][x])
			var k := JsonUtil.get_str(d, "kind", "void")
			if k == "locked" and state.happenings.has(JsonUtil.get_str(d, "opens")) and not JsonUtil.get_str(d, "opens").is_empty():
				k = "doorway"
			if k == "furniture" and not JsonUtil.get_str(d, "needs").is_empty() and not open.has(JsonUtil.get_str(d, "needs")):
				k = "floor"
			_kind[Vector2i(x, y)] = k
			if k in WALK:
				map.set_tile(Vector2i(x, y), floor_tile)
	for g: Dictionary in groups(rows, legend, ["furniture"]):
		if _kind.get((g["cells"] as Array)[0], "") == "furniture":
			furniture.append({"char": g["char"], "rect": g["rect"], "def": JsonUtil.get_dict(legend, str(g["char"]))})
	var st := JsonUtil.get_array(def, "start")
	start = Vector2(float(st[0]), float(st[1])) if st.size() == 2 else Vector2(width * 0.5, height - 1.5)
	for v: Variant in JsonUtil.get_array(def, "npcs"):
		var n: Dictionary = v
		var at := JsonUtil.get_array(n, "at")
		var f := JsonUtil.get_array(n, "face")
		npcs.append({"at": Vector2i(int(at[0]), int(at[1])), "look": JsonUtil.get_str(n, "look"), "name_ko": JsonUtil.get_str(n, "name_ko"),
			"staff": JsonUtil.get_bool(n, "staff", true), "face": Vector2i(int(f[0]), int(f[1])) if f.size() == 2 else Vector2i(0, 1)})
	for v: Variant in JsonUtil.get_array(def, "spots"):
		var s: Dictionary = v
		var acts: Array[String] = []
		for a in spot_activities(s):
			if open.has(a):
				acts.append(a)
		if acts.is_empty() and not JsonUtil.get_bool(s, "rest"):
			continue
		spots.append({"rect": rect_of(s), "acts": acts, "rest": JsonUtil.get_bool(s, "rest"), "name_ko": JsonUtil.get_str(s, "name_ko")})


## 자리 정의의 활동 id(activity 하나 또는 activities 여럿).
static func spot_activities(s: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if not JsonUtil.get_str(s, "activity").is_empty():
		out.append(JsonUtil.get_str(s, "activity"))
	for a: Variant in JsonUtil.get_array(s, "activities"):
		out.append(str(a))
	return out


static func rect_of(d: Dictionary) -> Rect2i:
	var r := JsonUtil.get_array(d, "rect")
	return Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])) if r.size() == 4 else Rect2i()


## 칸의 지금 kind(지도 밖 = void).
func kind_at(cell: Vector2i) -> String:
	return str(_kind.get(cell, "void"))


func is_door(cell: Vector2i) -> bool:
	return kind_at(cell) == "entry"


## 몸(칸 좌표 pos)이 facing을 보고 있을 때 바로 앞 칸의 살필 자리(없으면 {}).
func target(pos: Vector2, facing: Vector2i) -> Dictionary:
	var ahead := Kinematics.cell_of(pos + Vector2(facing) * 0.8)
	for s: Dictionary in spots:
		if (s["rect"] as Rect2i).has_point(ahead):
			return s
	return {}


## 그 자리에서 할 수 있는 활동: 자리의 활동 + (rest면) 다른 자리에 없는 이 시설 활동(이번 순 사건 등).
func activities_at(state: CityState, spot: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if spot.is_empty():
		return out
	out.assign(spot.get("acts", []))
	if bool(spot.get("rest", false)):
		var placed: Array[String] = []
		for s: Dictionary in spots:
			placed.append_array(s["acts"] as Array[String])
		for act in CityActions.activities_of(state, JsonUtil.get_str(def, "facility")):
			if not placed.has(act) and not out.has(act):
				out.append(act)
	return out
