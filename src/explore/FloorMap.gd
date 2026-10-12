class_name FloorMap
extends RefCounted
## 한 층의 그리드 데이터(바닥 평면 논리). 이동·충돌·시야·길찾기는 전부 여기 기준이고,
## 3/4 시점의 높이는 그리기(FloorView)에서만 다룬다.

const DIRS4: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var floor_id: String = ""
var width: int = 0
var height: int = 0
var seed_value: int = 0
var tiles: PackedInt32Array       ## 칸마다 타일 인덱스(defs의 인덱스)
var defs: Array[TileDef] = []
var dark: PackedByteArray         ## 암흑지대(주변 수정 빛이 닿지 않는 곳)
var explored: PackedByteArray     ## 한 번이라도 본 칸(안개 기억)
var visible_now: PackedByteArray  ## 지금 보이는 칸
var landmarks: Array[Dictionary] = []  ## {"id", "pos": Vector2i(기준 칸), "rect": Rect2i, "found": bool}
var portals: Array[Dictionary] = []    ## {"id", "pos", "dir", "to_floor", "found"}
var safe_zones: Array[Dictionary] = [] ## {"center": Vector2i, "radius": float}
var slots: Array[Vector2i] = []        ## 고정 조우 자리(균열 챕터: 방 가운데, 입구 쪽부터)
var entry: Vector2i = Vector2i(-1, -1)
var center: Vector2i = Vector2i(-1, -1)

var _index_of: Dictionary = {}    # 타일 id -> 인덱스


func _init(db: GameDatabase, p_width: int, p_height: int, fill_tile: String) -> void:
	var entries := db.get_collection("tiles")
	for tid: String in entries:
		var def := TileDef.from_dict(entries[tid], defs.size())
		_index_of[tid] = def.index
		defs.append(def)
	width = p_width
	height = p_height
	var n := width * height
	tiles = PackedInt32Array()
	tiles.resize(n)
	tiles.fill(index_of(fill_tile))
	dark = _zeros(n)
	explored = _zeros(n)
	visible_now = _zeros(n)


func index_of(tile_id: String) -> int:
	if not _index_of.has(tile_id):
		push_error("FloorMap: 알 수 없는 타일 '%s'" % tile_id)
		return 0
	return _index_of[tile_id]


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func idx(p: Vector2i) -> int:
	return p.y * width + p.x


func pos_of(i: int) -> Vector2i:
	return Vector2i(i % width, i / width)


func def_at(p: Vector2i) -> TileDef:
	return defs[tiles[idx(p)]] if in_bounds(p) else null


func tile_id_at(p: Vector2i) -> String:
	var d := def_at(p)
	return d.id if d != null else ""


func set_tile(p: Vector2i, tile_id: String) -> void:
	if in_bounds(p):
		tiles[idx(p)] = index_of(tile_id)


func is_walkable(p: Vector2i) -> bool:
	return in_bounds(p) and defs[tiles[idx(p)]].walkable


## 지도 밖은 시야를 막는다.
func blocks_sight(p: Vector2i) -> bool:
	return not in_bounds(p) or defs[tiles[idx(p)]].blocks_sight


func is_wall(p: Vector2i) -> bool:
	return not in_bounds(p) or defs[tiles[idx(p)]].is_wall()


func is_dark(p: Vector2i) -> bool:
	return in_bounds(p) and dark[idx(p)] != 0


func in_safe_zone(p: Vector2i) -> bool:
	for z: Dictionary in safe_zones:
		if Vector2(p - (z["center"] as Vector2i)).length() <= float(z["radius"]):
			return true
	return false


func portal_at(p: Vector2i) -> Dictionary:
	for portal: Dictionary in portals:
		if portal["pos"] == p:
			return portal
	return {}


## start에서 4방향으로 걸어서 닿는 칸(1 = 닿음).
func reachable_from(start: Vector2i) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(width * height)
	if not is_walkable(start):
		return seen
	var queue: Array[Vector2i] = [start]
	seen[idx(start)] = 1
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in DIRS4:
			var q := p + d
			if is_walkable(q) and seen[idx(q)] == 0:
				seen[idx(q)] = 1
				queue.append(q)
	return seen


func count_tile(tile_id: String) -> int:
	return tiles.count(index_of(tile_id))


## 지금 보이는 칸을 탐험 기록에 더한다.
func remember_visible() -> void:
	for i in visible_now.size():
		if visible_now[i] != 0:
			explored[i] = 1


static func _zeros(n: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(n)
	return b
