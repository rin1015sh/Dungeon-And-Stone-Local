class_name ScriptRegistry
extends RefCounted
## "폴더의 스크립트 파일 하나 = 항목 하나" 레지스트리. 파일 이름(확장자 제외)이 id.
##   효과 타입(src/combat/effects/), 층 생성기(src/explore/generators/) 등이 쓴다.
## 새 항목 추가 = 그 폴더에 파일 하나. 기존 코드는 고치지 않는다.
## 내보내기 빌드의 이름(.gd.remap, .gdc)도 처리한다.

var dir_path: String = ""
var _scripts: Dictionary = {}    # id -> Script
var _instances: Dictionary = {}  # id -> Object (처음 요청할 때 만든다)


func _init(p_dir: String) -> void:
	dir_path = p_dir
	scan()


func scan() -> void:
	_scripts.clear()
	_instances.clear()
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	for f: String in DirAccess.get_files_at(dir_path):
		var file := f.trim_suffix(".remap")
		if file.ends_with(".gdc"):
			file = file.trim_suffix(".gdc") + ".gd"
		if not file.ends_with(".gd"):
			continue
		var id := file.get_basename()
		if _scripts.has(id):
			continue
		var script := load(dir_path.path_join(file)) as Script
		if script != null and script.can_instantiate():
			_scripts[id] = script
		else:
			push_error("ScriptRegistry: 불러올 수 없는 스크립트 %s" % dir_path.path_join(file))


func ids() -> PackedStringArray:
	var out := PackedStringArray(_scripts.keys())
	out.sort()
	return out


func has(id: String) -> bool:
	return _scripts.has(id)


## id의 인스턴스(공유). 없으면 null.
func instance(id: String) -> Object:
	if not _scripts.has(id):
		return null
	if not _instances.has(id):
		_instances[id] = (_scripts[id] as Script).new()
	return _instances[id]
