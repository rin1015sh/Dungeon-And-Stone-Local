class_name CityValues
extends RefCounted
## 도시 데이터 값 다루기(미정 null 찾기 · 디버그로 바꿀 수 있는 값 목록 · 임시값 덮기).
##   - 경로: "city/<키>/…"(data/city.json), "activities/<id>/<키>/…", "facilities/<id>/…" — 배열은 숫자 인덱스.
##   - nulls(): 미정 값 경로 목록(검증기 경고). tunables(): 디버그 패널에서 바꿔 볼 수 있는 규칙 값 경로.
##   - resolved(): 디버그 임시값(overrides: 경로 → 값)을 덮은 사본. 원본 데이터·파일은 바꾸지 않는다.
## 오토로드를 참조하지 않는다.

const COLLECTIONS := ["activities", "facilities"]
## 디버그로 바꿀 값이 아닌 것(이름·설명·연결·그림·배치).
const FIXED_KEYS := ["id", "name_ko", "desc_ko", "facility", "panel", "source", "type", "notes", "order", "version",
	"place", "street", "facility_order", "periods", "building", "interior", "x", "activities", "shows", "extra", "stock", "deals", "equipment_categories"]


## 미정 값 경로 전부(정렬). '_'로 시작하는 키(주석)는 건너뛴다.
static func nulls(db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	_collect(db.singletons.get("city", {}), "city", out)
	for col: String in COLLECTIONS:
		var entries := db.get_collection(col)
		for id: String in entries:
			_collect(entries[id], col + "/" + id, out)
	out.sort()
	return out


static func _collect(v: Variant, path: String, out: PackedStringArray) -> void:
	if v == null:
		out.append(path)
	elif v is Dictionary:
		for k: Variant in v:
			if not str(k).begins_with("_"):
				_collect(v[k], path + "/" + str(k), out)
	elif v is Array:
		for i in (v as Array).size():
			_collect(v[i], path + "/" + str(i), out)


## 디버그 패널에서 바꿔 볼 수 있는 값 경로: city.json 규칙과 활동의 비용·효과 수치(숫자·문자열·불·값 배열 = 한 칸).
static func tunables(db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var city: Dictionary = db.singletons.get("city", {})
	for k: Variant in city:
		if not str(k).begins_with("_") and not str(k) in FIXED_KEYS:
			_leaves(city[k], "city/" + str(k), out)
	var acts := db.get_collection("activities")
	for id: String in acts:
		_leaves(acts[id], "activities/" + id, out)
	out.sort()
	return out


static func _leaves(v: Variant, path: String, out: PackedStringArray) -> void:
	if v is Dictionary:
		for k: Variant in v:
			if not str(k).begins_with("_") and not str(k) in FIXED_KEYS:
				_leaves(v[k], path + "/" + str(k), out)
	elif v is Array and (v as Array).any(func(e: Variant) -> bool: return e is Dictionary or e is Array):
		for i in (v as Array).size():
			_leaves(v[i], path + "/" + str(i), out)
	elif path.count("/") > 1 or path.begins_with("city/"):
		out.append(path)


## 경로의 데이터 값(임시값 없이). 없으면 null.
static func value_at(db: GameDatabase, path: String) -> Variant:
	var parts := path.split("/")
	var node: Variant = db.singletons.get("city", {}) if parts[0] == "city" else db.get_entry(parts[0], parts[1] if parts.size() > 1 else "")
	for i in range(1 if parts[0] == "city" else 2, parts.size()):
		if node is Dictionary:
			node = (node as Dictionary).get(parts[i])
		elif node is Array and parts[i].is_valid_int() and parts[i].to_int() < (node as Array).size():
			node = node[parts[i].to_int()]
		else:
			return null
	return node


## 원본 src(경로 prefix)에 prefix로 시작하는 임시값을 덮은 깊은 사본.
static func resolved(src: Dictionary, prefix: String, overrides: Dictionary) -> Dictionary:
	var out := src.duplicate(true)
	for path: String in overrides:
		if path.begins_with(prefix + "/"):
			_set_path(out, path.substr(prefix.length() + 1).split("/"), overrides[path])
	return out


## 도시 규칙(city.json)의 한 구역(예: "fatigue")을 임시값까지 반영해 돌려준다.
static func city_section(db: GameDatabase, overrides: Dictionary, key: String) -> Dictionary:
	var city: Dictionary = db.singletons.get("city", {})
	return resolved(JsonUtil.get_dict(city, key), "city/" + key, overrides)


static func city_value(db: GameDatabase, overrides: Dictionary, key: String) -> Variant:
	var path := "city/" + key
	if overrides.has(path):
		return overrides[path]
	return (db.singletons.get("city", {}) as Dictionary).get(key)


static func entry(db: GameDatabase, overrides: Dictionary, col: String, id: String) -> Dictionary:
	return resolved(db.get_entry(col, id), col + "/" + id, overrides)


static func _set_path(node: Variant, parts: PackedStringArray, value: Variant) -> void:
	if parts.is_empty():
		return
	var key := parts[0]
	var last := parts.size() == 1
	if node is Dictionary:
		if last:
			node[key] = value
		elif node.has(key):
			_set_path(node[key], parts.slice(1), value)
	elif node is Array and key.is_valid_int():
		var i := key.to_int()
		if i < 0 or i >= (node as Array).size():
			return
		if last:
			node[i] = value
		else:
			_set_path(node[i], parts.slice(1), value)


## null이면 0(미정 = 효과 없음).
static func num(d: Dictionary, key: String) -> float:
	return JsonUtil.get_float(d, key, 0.0)


static func is_set(d: Dictionary, key: String) -> bool:
	return d.get(key) != null
