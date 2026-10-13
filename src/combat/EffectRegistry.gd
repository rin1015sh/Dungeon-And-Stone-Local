class_name EffectRegistry
extends RefCounted
## 효과 타입 레지스트리. src/combat/effects/<type>.gd (EffectHandler 상속)를 모은다.
## 스킬 effects, 아이템 use_effects, 이벤트 effects가 모두 이 레지스트리를 쓴다.

const DIR := "res://src/combat/effects"

var _reg: ScriptRegistry


func _init(dir: String = DIR) -> void:
	_reg = ScriptRegistry.new(dir)


func types() -> PackedStringArray:
	return _reg.ids()


func has_type(type: String) -> bool:
	return _reg.has(type)


func handler(type: String) -> EffectHandler:
	return _reg.instance(type) as EffectHandler


## 효과 목록을 순서대로 적용한다. 하나라도 일어났으면 ctx.success = true.
func apply_all(ctx: EffectContext, effects: Array) -> bool:
	for e: Variant in effects:
		if not e is Dictionary:
			continue
		var type := JsonUtil.get_str(e, "type")
		var h := handler(type)
		if h == null:
			push_error("EffectRegistry: 핸들러 없는 효과 타입 '%s'" % type)
			continue
		if ctx.landed == 0 and type != "damage" and not JsonUtil.get_bool(e, "always") and JsonUtil.get_str(e, "to") != "self":
			continue  # 앞의 공격이 빗나갔거나 면역 — 그 공격에 딸린 효과는 걸리지 않는다
		if h.apply(ctx, e):
			ctx.success = true
	return ctx.success


## 검증기용: 효과 하나의 데이터 검사(타입 존재 + 핸들러의 validate).
func check_data(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var type := JsonUtil.get_str(data, "type")
	var h := handler(type)
	if h == null:
		return PackedStringArray(["효과 type '%s' 핸들러 없음" % type])
	return h.validate(data, db)
