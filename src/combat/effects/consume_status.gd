extends EffectHandler
## 상태 터뜨리기(정수 재기획): {"type": "consume_status", "status": "bleeding", "power_per_stack": 0.3, "damage": {피해 효과},
##   "heal_ratio_per_stack": 0.03}
## 대상의 그 상태를 모두 없애고 중첩 수 n만큼: damage가 있으면 위력 + power_per_stack×n으로 친다,
## heal_ratio_per_stack이면 시전자가 최대 생명력 × 비율 × n 회복. 대상에 그 상태가 없으면 아무 일도 없다(damage도 치지 않는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.subject()
	var id := JsonUtil.get_str(data, "status")
	if t == null or t.dead or not t.statuses.has(id):
		return false
	var n := t.statuses.stacks(id)
	t.statuses.remove(id)
	var dmg := JsonUtil.get_dict(data, "damage")
	if not dmg.is_empty() and ctx.registry != null:
		var d := dmg.duplicate(true)
		d["type"] = "damage"
		d["power"] = JsonUtil.get_float(d, "power", 1.0) + JsonUtil.get_float(data, "power_per_stack") * n
		ctx.registry.apply_all(ctx, [d])
	var heal := JsonUtil.get_float(data, "heal_ratio_per_stack")
	if heal > 0.0 and ctx.source != null and not ctx.source.dead:
		var amt := ctx.source.pool.get_max("hp") * heal * n * ctx.source.statuses.heal_mult()
		var got := ctx.source.pool.modify("hp", amt, "effect:consume_status")
		if got > 0.0:
			ctx.source.statuses.on_healed()
			ctx.say("effect.restore", {"resource": ctx.source.pool.get_def("hp").name_ko, "amount": roundi(got)}, "good")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("statuses", JsonUtil.get_str(data, "status")):
		out.append("consume_status: status '%s' 없음" % data.get("status"))
	if not data.has("damage") and not data.has("heal_ratio_per_stack"):
		out.append("consume_status: damage나 heal_ratio_per_stack 중 하나는 있어야 한다")
	return out
