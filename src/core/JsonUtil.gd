class_name JsonUtil
extends RefCounted
## JSON 파일 읽기와 Dictionary 값 꺼내기 도우미.
## 실패는 예외 대신 errors 배열에 한국어 메시지로 쌓는다.


## path의 JSON을 읽어 Dictionary/Array를 돌려준다. 실패하면 null.
static func read_file(path: String, errors: Array[String]) -> Variant:
	if not FileAccess.file_exists(path):
		errors.append("파일 없음: %s" % path)
		return null
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		errors.append("JSON 파싱 실패: %s (%d행) %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


## dir_path 안의 *.json 경로(정렬). '_'로 시작하는 파일(스키마 템플릿)은 제외한다.
static func list_json(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(dir_path):
		return out
	for file: String in DirAccess.get_files_at(dir_path):
		if file.ends_with(".json") and not file.begins_with("_"):
			out.append(dir_path.path_join(file))
	out.sort()
	return out


static func get_str(d: Dictionary, key: String, default: String = "") -> String:
	var v: Variant = d.get(key)
	return default if v == null else str(v)


static func get_float(d: Dictionary, key: String, default: float = 0.0) -> float:
	var v: Variant = d.get(key)
	if v is float or v is int:
		return float(v)
	return default


static func get_int(d: Dictionary, key: String, default: int = 0) -> int:
	var v: Variant = d.get(key)
	if v is float or v is int:
		return int(v)
	return default


static func get_bool(d: Dictionary, key: String, default: bool = false) -> bool:
	var v: Variant = d.get(key)
	if v is bool:
		return bool(v)
	return default


static func get_dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key)
	if v is Dictionary:
		return v
	return {}


static func get_array(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key)
	if v is Array:
		return v
	return []


static func is_number(v: Variant) -> bool:
	return v is float or v is int
