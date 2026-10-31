class_name CityRoom
extends RefCounted
## 시설 실내 방(탑뷰 — data/rooms, 사용자 결정 2026-10-31 "도서관 내부를 탐험 화면처럼 WASD로", CT62): 칸 지도 · 소품 · 살필 자리.
## 시설 JSON room이 방 id를 가리키면 메뉴(FacilityView) 대신 이 방을 걷는다(RoomView). 걷기·충돌은 탐험과 같은 Kinematics.
## rows 글자: # 벽 · B 벽에 붙은 가구(막힘 — 그림에 그려져 있다) · . 바닥 · D 문(밟으면 나간다).
## 소품(props)은 rect 칸을 막는다. needs = 그 활동이 지금 시설에 있을 때만 선다(희귀서 입고 같은 이번 순 사건 — 없으면 칸도 비운다).
## 살필 자리(spots)는 rect 칸을 바라보고 살피면 그 활동(activity 하나 또는 activities 여럿 — 지금 있는 것만), rest = 자리가 정해지지 않은 이 시설 활동도 여기서.
## 오토로드를 참조하지 않는다.

const BLOCKED := ["#", "B"]
const DOOR := "D"

var id: String = ""
var def: Dictionary = {}
var width: int = 0
var height: int = 0
var map: FloorMap
var start: Vector2 = Vector2.ZERO
## 지금 선 소품 {id, rect: Rect2i, art, sprite, face: Vector2i}.
var props: Array[Dictionary] = []
## 지금 살필 수 있는 자리 {rect: Rect2i, acts: Array[String](지금 있는 활동), rest}.
var spots: Array[Dictionary] = []
var _doors: Dictionary = {}  # Vector2i → true


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


func _build(state: CityState, room_id: String) -> void:
	id = room_id
	def = state.db.get_entry("rooms", room_id)
	var rows := JsonUtil.get_array(def, "rows")
	height = rows.size()
	for r: Variant in rows:
		width = maxi(width, str(r).length())
	var cfg := CityValues.city_section(state.db, state.overrides, "room")
	map = FloorMap.new(state.db, width, height, JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
	var floor_tile := JsonUtil.get_str(cfg, "floor_tile", "cave_floor")
	for y in height:
		var row := str(rows[y])
		for x in row.length():
			var ch := row[x]
			if not ch in BLOCKED:
				map.set_tile(Vector2i(x, y), floor_tile)
			if ch == DOOR:
				_doors[Vector2i(x, y)] = true
	var st := JsonUtil.get_array(def, "start")
	start = Vector2(float(st[0]), float(st[1])) if st.size() == 2 else Vector2(width * 0.5, height - 1.5)
	var open := CityActions.activities_of(state, JsonUtil.get_str(def, "facility"))
	for v: Variant in JsonUtil.get_array(def, "props"):
		var p: Dictionary = v
		var needs := JsonUtil.get_str(p, "needs")
		if not needs.is_empty() and not open.has(needs):
			continue
		var f := JsonUtil.get_array(p, "face")
		var prop := {"id": JsonUtil.get_str(p, "id"), "rect": rect_of(p), "art": JsonUtil.get_str(p, "art"),
			"sprite": JsonUtil.get_str(p, "sprite"), "face": Vector2i(int(f[0]), int(f[1])) if f.size() == 2 else Vector2i(0, 1)}
		props.append(prop)
		var rc: Rect2i = prop["rect"]
		for y in range(rc.position.y, rc.end.y):
			for x in range(rc.position.x, rc.end.x):
				map.set_tile(Vector2i(x, y), JsonUtil.get_str(cfg, "block_tile", "rock_wall"))
	for v: Variant in JsonUtil.get_array(def, "spots"):
		var s: Dictionary = v
		var acts: Array[String] = []
		for a in spot_activities(s):
			if open.has(a):
				acts.append(a)
		if acts.is_empty() and not JsonUtil.get_bool(s, "rest"):
			continue
		spots.append({"rect": rect_of(s), "acts": acts, "rest": JsonUtil.get_bool(s, "rest")})


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


func is_door(cell: Vector2i) -> bool:
	return _doors.has(cell)


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
