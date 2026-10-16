extends EffectHandler
## 피로도 증감(탐험가만 — 피로도가 있는 대상): {"type": "fatigue", "amount": -10} — 음수면 줄고 양수면 는다.
## 1층 맑은 샘·샘물 병. 이미 0이라 줄 것이 없으면 효과가 없다(물건을 쓰지 않는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.subject()
	var fat: Variant = actor.get("fatigue") if actor != null else null
	if actor == null or actor.dead or not fat is Fatigue:
		return false
	var d := (fat as Fatigue).add(JsonUtil.get_float(data, "amount"), "effect")
	if is_zero_approx(d):
		ctx.say("effect.fatigue_none", {}, "info")
		return false
	ctx.say("effect.fatigue_down" if d < 0.0 else "effect.fatigue_up", {"amount": CityContext.fmt(absf(d))}, "good" if d < 0.0 else "warn")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	if not JsonUtil.is_number(data.get("amount")):
		return PackedStringArray(["fatigue: amount는 숫자(음수 = 줄임)"])
	return PackedStringArray()
