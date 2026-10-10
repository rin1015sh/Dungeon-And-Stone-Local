class_name ContentRegistries
extends RefCounted
## 스크립트 레지스트리 묶음: 효과 타입(src/combat/effects/), 층 생성기(src/explore/generators/).
## DataRegistry(오토로드)·검증 도구·테스트가 같은 방식으로 만들어 쓴다.

const GENERATOR_DIR := "res://src/explore/generators"

var effects: EffectRegistry
var generators: ScriptRegistry


func _init() -> void:
	effects = EffectRegistry.new()
	generators = ScriptRegistry.new(GENERATOR_DIR)


func generator(id: String) -> FloorGenerator:
	return generators.instance(id) as FloorGenerator


## 레지스트리 정보를 채운 검증기.
func make_validator() -> DataValidator:
	var v := DataValidator.new()
	v.effect_types = effects.types()
	v.effect_checker = effects.check_data
	v.generator_ids = generators.ids()
	v.generator_checker = _check_floor
	return v


func _check_floor(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var gen := generator(JsonUtil.get_str(floor_def, "generator"))
	return gen.validate(floor_def, db) if gen != null else PackedStringArray()
