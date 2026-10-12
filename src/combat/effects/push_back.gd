extends EffectHandler
## 순서 밀기(방패 밀치기): {"type": "push_back", "amount": 60, "chance": 0.5} — 대상의 행동 게이지를 amount만큼 깎는다(다음 차례가 늦어진다).
## 전투 중에만(Battle이 gauge 사건을 반영한다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.subject()
	if t == null or t.dead:
		return false
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		return false
	ctx.events.append({"type": "gauge", "target": t, "amount": -JsonUtil.get_float(data, "amount", 50.0)})
	ctx.say("combat.pushed_back", {"name": t.display_name}, "info")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	return PackedStringArray() if JsonUtil.get_float(data, "amount", 0.0) > 0.0 else PackedStringArray(["push_back: amount는 양수"])
