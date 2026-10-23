class_name GameDatabase
extends RefCounted
## data/ 아래 JSON 전체를 읽어 보관하는 순수 데이터 저장소.
## 오토로드에 의존하지 않으므로 테스트·도구에서 직접 만들어 쓸 수 있다.
## 무엇을 읽을지는 data/manifest.json이 정한다(새 컬렉션 = manifest에 한 줄).

const MANIFEST_FILE := "manifest.json"

var root_path: String = ""
var manifest: Dictionary = {}
var singletons: Dictionary = {}   ## 이름 -> Dictionary (balance, render, tags, audio …)
var collections: Dictionary = {}  ## 컬렉션 이름 -> {id: 항목 Dictionary}
var sources: Dictionary = {}      ## "컬렉션/id" -> 파일 경로 (오류 메시지용)
var stats: Dictionary = {}        ## id -> StatDef (stats.json 순서 유지)
var resources: Dictionary = {}    ## id -> ResourceDef
var load_errors: Array[String] = []

var balance: Dictionary:
	get:
		return singletons.get("balance", {})

var render: Dictionary:
	get:
		return singletons.get("render", {})

var tags: Dictionary:
	get:
		return singletons.get("tags", {})


func load_all(root: String = "res://data") -> bool:
	root_path = root
	manifest = {}
	singletons = {}
	collections = {}
	sources = {}
	load_errors.clear()
	var m: Variant = JsonUtil.read_file(root.path_join(MANIFEST_FILE), load_errors)
	if not m is Dictionary:
		load_errors.append("manifest.json을 읽을 수 없다")
		rebuild_index()
		return false
	manifest = m
	var singles := JsonUtil.get_dict(manifest, "singletons")
	for name: String in singles:
		var data: Variant = JsonUtil.read_file(root.path_join(str(singles[name])), load_errors)
		singletons[name] = data if data is Dictionary else {}
	var cols := JsonUtil.get_dict(manifest, "collections")
	for name: String in cols:
		var spec: Dictionary = cols[name]
		collections[name] = {}
		if spec.has("file"):
			_load_entries(name, root.path_join(str(spec["file"])))
		if spec.has("dir"):
			for path: String in JsonUtil.list_json(root.path_join(str(spec["dir"]))):
				_load_entries(name, path)
	ItemForge.forge_all(collections, singletons.get("balance", {}))  # 종류 × 소재 장비(아이템 공식)
	rebuild_index()
	return load_errors.is_empty()


## 원본 항목(collections)으로부터 타입 정의(StatDef/ResourceDef)를 다시 만든다.
## 테스트에서 collections를 직접 고친 뒤에도 호출한다.
func rebuild_index() -> void:
	stats.clear()
	resources.clear()
	var stat_entries: Dictionary = collections.get("stats", {})
	for id: String in stat_entries:
		stats[id] = StatDef.from_dict(stat_entries[id])
	var res_entries: Dictionary = collections.get("resources", {})
	for id: String in res_entries:
		resources[id] = ResourceDef.from_dict(res_entries[id])


func get_collection(col: String) -> Dictionary:
	return collections.get(col, {})


func get_entry(col: String, id: String) -> Dictionary:
	return get_collection(col).get(id, {})


func has_entry(col: String, id: String) -> bool:
	return get_collection(col).has(id)


## 항목을 직접 넣는다(테스트·디버그용). 이미 있으면 덮어쓴다.
func put_entry(col: String, entry: Dictionary) -> void:
	if not collections.has(col):
		collections[col] = {}
	(collections[col] as Dictionary)[JsonUtil.get_str(entry, "id")] = entry


## "enabled": false가 아닌 항목 id 목록(파일 순서).
func enabled_ids(col: String) -> Array[String]:
	var out: Array[String] = []
	var entries := get_collection(col)
	for id: String in entries:
		if JsonUtil.get_bool(entries[id], "enabled", true):
			out.append(id)
	return out


func enabled_resource_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in resources:
		if (resources[id] as ResourceDef).enabled:
			out.append(id)
	return out


## balance.json 값을 "a.b.c" 경로로 꺼낸다.
func bal(path: String, default: Variant = null) -> Variant:
	return single(balance, path, default)


## progression.json(레벨·경험치) 값. 예: db.prog("level.exp_table")
func prog(path: String, default: Variant = null) -> Variant:
	return single(singletons.get("progression", {}), path, default)


## 단일 파일 데이터에서 "a.b.c" 경로 값. 없으면 default.
static func single(root: Dictionary, path: String, default: Variant = null) -> Variant:
	var node: Variant = root
	for part in path.split("."):
		if node is Dictionary and (node as Dictionary).has(part):
			node = (node as Dictionary)[part]
		else:
			return default
	return node


## tags.json의 목록(항목이 {id} 객체 또는 문자열)에서 id만 뽑는다.
func tag_ids(list_name: String) -> PackedStringArray:
	var out := PackedStringArray()
	for item: Variant in JsonUtil.get_array(tags, list_name):
		if item is Dictionary:
			out.append(JsonUtil.get_str(item, "id"))
		else:
			out.append(str(item))
	return out


func _load_entries(col: String, path: String) -> void:
	var data: Variant = JsonUtil.read_file(path, load_errors)
	if data is Dictionary:
		_add_entry(col, data, path)
	elif data is Array:
		for e: Variant in data:
			if e is Dictionary:
				_add_entry(col, e, path)
			else:
				load_errors.append("[%s] 객체가 아닌 항목: %s" % [col, path])
	elif data != null:
		load_errors.append("[%s] 최상위가 객체/배열이 아님: %s" % [col, path])


func _add_entry(col: String, entry: Dictionary, path: String) -> void:
	var id := JsonUtil.get_str(entry, "id")
	var entries: Dictionary = collections[col]
	if id.is_empty():
		load_errors.append("[%s] id 없는 항목: %s" % [col, path])
		return
	if entries.has(id):
		load_errors.append("[%s] 중복 id '%s': %s / %s" % [col, id, sources.get(col + "/" + id, "?"), path])
		return
	entries[id] = entry
	sources[col + "/" + id] = path
