extends Node
## 데이터 레지스트리(오토로드). 시작할 때 data/를 읽고 검증한다.
## 실제 저장소는 GameDatabase(db) — 게임 코드는 DataRegistry.db로 접근한다.
## 핵심 로직(src/core)은 이 오토로드를 직접 참조하지 않고 db를 인자로 받는다.

const DATA_ROOT := "res://data"

var db: GameDatabase = GameDatabase.new()
var validator: DataValidator = DataValidator.new()


func _ready() -> void:
	reload()


func reload() -> bool:
	db = GameDatabase.new()
	db.load_all(DATA_ROOT)
	validator = DataValidator.new()
	validator.validate(db)
	validator.errors.append_array(Strings.load_locale())
	for e: String in validator.errors:
		push_error("[데이터] " + e)
	for w: String in validator.warnings:
		print("[데이터 경고] " + w)
	EventBus.data_reloaded.emit()
	return not has_errors()


func has_errors() -> bool:
	return not validator.errors.is_empty()
