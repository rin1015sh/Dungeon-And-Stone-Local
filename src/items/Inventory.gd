class_name Inventory
extends RefCounted
## 소지품: 아이템 id → 개수. 저장은 id와 개수만.
## (M3에서 무게·장비 칸·개별 롤 값이 있는 아이템을 확장한다)

signal changed(item_id: String, count: int)

var _counts: Dictionary = {}  # id -> int (넣은 순서 유지)


func add(id: String, n: int = 1) -> void:
	if n <= 0 or id.is_empty():
		return
	_counts[id] = int(_counts.get(id, 0)) + n
	changed.emit(id, _counts[id])


## n개를 뺀다. 모자라면 아무것도 하지 않고 false.
func remove(id: String, n: int = 1) -> bool:
	var have := count(id)
	if n <= 0 or have < n:
		return false
	if have == n:
		_counts.erase(id)
	else:
		_counts[id] = have - n
	changed.emit(id, have - n)
	return true


func count(id: String) -> int:
	return int(_counts.get(id, 0))


func has(id: String, n: int = 1) -> bool:
	return count(id) >= n


func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in _counts:
		out.append(id)
	return out


## 조건에 맞는 첫 아이템 id (예: 분류가 food인 것). 없으면 "".
func first_where(db: GameDatabase, key: String, value: String) -> String:
	for id: String in _counts:
		var entry := db.get_entry("items", id)
		if JsonUtil.get_str(entry, key) == value:
			return id
	return ""


func to_dict() -> Dictionary:
	return _counts.duplicate()


func load_dict(d: Dictionary) -> void:
	_counts.clear()
	for id: String in d:
		if JsonUtil.is_number(d[id]) and int(d[id]) > 0:
			_counts[id] = int(d[id])
