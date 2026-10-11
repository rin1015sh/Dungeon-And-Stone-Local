class_name Inventory
extends RefCounted
## 소지품(스톤샤드식 격자 가방): width × height 칸. 아이템마다 크기(w×h)가 있고 왼쪽 위 칸(pos)에 놓인다.
## 같은 아이템은 stack 개수까지 한 자리에 쌓인다. 돈(스톤)은 따로 센다.
## 예전 API(add/remove/count/has/ids/first_where)는 그대로 — 개수 기준으로 동작하고 자리는 알아서 찾는다.
## 저장은 자리 목록 {id, count, x, y}와 돈만.

signal changed(item_id: String, count: int)
signal money_changed(amount: int)

var width: int = 10
var height: int = 6
var money: int = 0

var _db: GameDatabase
var _stacks: Array[Dictionary] = []  # {"id": String, "count": int, "pos": Vector2i}


func _init(db: GameDatabase = null, p_width: int = 10, p_height: int = 6) -> void:
	_db = db
	width = p_width
	height = p_height


## n개를 넣는다(기존 자리에 먼저 쌓고, 모자라면 빈 자리를 찾는다). 실제로 넣은 개수.
func add(id: String, n: int = 1) -> int:
	if n <= 0 or id.is_empty():
		return 0
	var left := n
	var cap := ItemInfo.stack(_db, id)
	for s in _stacks:
		if left <= 0:
			break
		if s["id"] == id and int(s["count"]) < cap:
			var put := mini(cap - int(s["count"]), left)
			s["count"] = int(s["count"]) + put
			left -= put
	while left > 0:
		var p := free_spot(id)
		if p.x < 0:
			break
		var put := mini(cap, left)
		_stacks.append({"id": id, "count": put, "pos": p})
		left -= put
	if left < n:
		changed.emit(id, count(id))
	return n - left


## n개를 뺀다(뒤쪽 자리부터). 모자라면 아무것도 하지 않고 false.
func remove(id: String, n: int = 1) -> bool:
	if n <= 0 or count(id) < n:
		return false
	var left := n
	for i in range(_stacks.size() - 1, -1, -1):
		if left <= 0:
			break
		var s := _stacks[i]
		if s["id"] != id:
			continue
		var take := mini(int(s["count"]), left)
		s["count"] = int(s["count"]) - take
		left -= take
		if int(s["count"]) <= 0:
			_stacks.remove_at(i)
	changed.emit(id, count(id))
	return true


func count(id: String) -> int:
	var n := 0
	for s in _stacks:
		if s["id"] == id:
			n += int(s["count"])
	return n


func has(id: String, n: int = 1) -> bool:
	return count(id) >= n


## 가진 아이템 id(처음 넣은 순서, 중복 없음).
func ids() -> Array[String]:
	var out: Array[String] = []
	for s in _stacks:
		if not out.has(str(s["id"])):
			out.append(str(s["id"]))
	return out


## 조건에 맞는 첫 아이템 id (예: 분류가 food인 것). 없으면 "".
func first_where(db: GameDatabase, key: String, value: String) -> String:
	for id in ids():
		if JsonUtil.get_str(db.get_entry("items", id), key) == value:
			return id
	return ""


# ── 격자 ─────────────────────────────────────────────────

func stacks() -> Array[Dictionary]:
	return _stacks


## 칸 cell을 덮고 있는 자리의 번호. 없으면 -1.
func stack_at(cell: Vector2i) -> int:
	for i in _stacks.size():
		if Rect2i(_stacks[i]["pos"], ItemInfo.size(_db, _stacks[i]["id"])).has_point(cell):
			return i
	return -1


## id를 pos(왼쪽 위)에 놓을 수 있는가. ignore = 비어 있다고 볼 자리 번호(옮기는 중인 자기 자신).
func can_place(id: String, pos: Vector2i, ignore: int = -1) -> bool:
	var r := Rect2i(pos, ItemInfo.size(_db, id))
	if r.position.x < 0 or r.position.y < 0 or r.end.x > width or r.end.y > height:
		return false
	for i in _stacks.size():
		if i != ignore and Rect2i(_stacks[i]["pos"], ItemInfo.size(_db, _stacks[i]["id"])).intersects(r):
			return false
	return true


## id가 들어갈 첫 빈 자리(위→아래, 왼쪽→오른쪽). 없으면 (-1, -1).
func free_spot(id: String) -> Vector2i:
	for y in height:
		for x in width:
			if can_place(id, Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)


## 자리 i를 pos로 옮긴다. 같은 아이템이 있는 자리에 놓으면 쌓는다. 성공하면 true.
func move_stack(i: int, pos: Vector2i) -> bool:
	if i < 0 or i >= _stacks.size():
		return false
	var s := _stacks[i]
	var other := stack_at(pos)
	if other >= 0 and other != i and _stacks[other]["id"] == s["id"]:
		var cap := ItemInfo.stack(_db, s["id"])
		var put := mini(cap - int(_stacks[other]["count"]), int(s["count"]))
		if put <= 0:
			return false
		_stacks[other]["count"] = int(_stacks[other]["count"]) + put
		s["count"] = int(s["count"]) - put
		if int(s["count"]) <= 0:
			_stacks.remove_at(i)
		changed.emit(str(s["id"]), count(s["id"]))
		return true
	if not can_place(s["id"], pos, i):
		return false
	s["pos"] = pos
	changed.emit(str(s["id"]), count(s["id"]))
	return true


## 자리 i를 통째로 꺼낸다 {id, count, pos}. 없으면 {}.
func take_stack(i: int) -> Dictionary:
	if i < 0 or i >= _stacks.size():
		return {}
	var s: Dictionary = _stacks[i]
	_stacks.remove_at(i)
	changed.emit(str(s["id"]), count(s["id"]))
	return s


## id n개를 pos에 새 자리로 놓는다(쌓기 한도 안). 성공하면 true.
func place(id: String, n: int, pos: Vector2i) -> bool:
	if n <= 0 or n > ItemInfo.stack(_db, id) or not can_place(id, pos):
		return false
	_stacks.append({"id": id, "count": n, "pos": pos})
	changed.emit(id, count(id))
	return true


## id n개가 들어갈 수 있는가(쌓기 여유 + 빈 자리). 넣지는 않는다.
func fits(id: String, n: int = 1) -> bool:
	var probe := Inventory.new(_db, width, height)
	probe.load_dict(to_dict())
	return probe.add(id, n) == n


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


func to_dict() -> Dictionary:
	var list: Array = []
	for s in _stacks:
		list.append({"id": s["id"], "count": s["count"], "x": (s["pos"] as Vector2i).x, "y": (s["pos"] as Vector2i).y})
	return {"w": width, "h": height, "money": money, "stacks": list}


func load_dict(d: Dictionary) -> void:
	_stacks.clear()
	width = JsonUtil.get_int(d, "w", width)
	height = JsonUtil.get_int(d, "h", height)
	money = JsonUtil.get_int(d, "money")
	for e: Variant in JsonUtil.get_array(d, "stacks"):
		var s: Dictionary = e if e is Dictionary else {}
		var id := JsonUtil.get_str(s, "id")
		var n := JsonUtil.get_int(s, "count")
		var p := Vector2i(JsonUtil.get_int(s, "x"), JsonUtil.get_int(s, "y"))
		if n > 0 and not id.is_empty() and not place(id, mini(n, ItemInfo.stack(_db, id)), p):
			add(id, n)  # 저장된 자리가 맞지 않으면(데이터 크기 변경 등) 빈 자리로
