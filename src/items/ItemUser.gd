class_name ItemUser
extends RefCounted
## 아이템 사용: items/<id>.json의 use_effects를 효과 레지스트리로 적용하고,
## 실제로 효과가 일어났고 consumable이면 하나를 소모한다.
## 첫 효과가 본 효과다 — 그것이 일어나지 않으면(생명력이 이미 가득 등) 나머지(부작용)도 적용하지 않고 소모하지 않는다.


## 사용 결과 문맥(메시지·성공 여부)을 돌려준다. 아이템이 없으면 null.
static func use(effects: EffectRegistry, user: Actor, item_id: String, rng: Rng, target: Actor = null, info: Dictionary = {}) -> EffectContext:
	if not user.inventory.has(item_id):
		return null
	var item := user.db.get_entry("items", item_id)
	var ctx := EffectContext.new(user.db, user, target if target != null else user, rng)
	ctx.item_id = item_id
	ctx.info = info
	var fx := JsonUtil.get_array(item, "use_effects")
	if not fx.is_empty() and effects.apply_all(ctx, [fx[0]]):
		effects.apply_all(ctx, fx.slice(1))
	if ctx.success and JsonUtil.get_bool(item, "consumable", true):
		user.inventory.remove(item_id)
	return ctx
