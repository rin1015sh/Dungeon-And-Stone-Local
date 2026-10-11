class_name ContentRegistries
extends RefCounted
## 스크립트 레지스트리 묶음: 효과 타입(src/combat/effects/), 층 생성기(src/explore/generators/),
## 몬스터 AI 조건(src/combat/ai/).
## DataRegistry(오토로드)·검증 도구·테스트가 같은 방식으로 만들어 쓴다.

const GENERATOR_DIR := "res://src/explore/generators"
const AI_DIR := "res://src/combat/ai"

var effects: EffectRegistry
var generators: ScriptRegistry
var ai_conditions: ScriptRegistry


func _init() -> void:
	effects = EffectRegistry.new()
	generators = ScriptRegistry.new(GENERATOR_DIR)
	ai_conditions = ScriptRegistry.new(AI_DIR)


func generator(id: String) -> FloorGenerator:
	return generators.instance(id) as FloorGenerator


## 레지스트리 정보를 채운 검증기.
func make_validator() -> DataValidator:
	var v := DataValidator.new()
	v.effect_types = effects.types()
	v.effect_checker = effects.check_data
	v.generator_ids = generators.ids()
	v.generator_checker = _check_floor
	v.ai_condition_ids = ai_conditions.ids()
	v.check_skill_effects = true
	return v


func _check_floor(floor_def: Dictionary, db: GameDatabase) -> PackedStringArray:
	var gen := generator(JsonUtil.get_str(floor_def, "generator"))
	return gen.validate(floor_def, db) if gen != null else PackedStringArray()
