extends EffectHandler
## 대화: {"type": "talk", "outcomes": [{"id", "weight", "weight_low_hp", "gauge"?, "withdraw"?}]}
## 말이 통하지 않는 상대(Actor.understands_speech() = false, 마수 전부)에게는 아무 효과가 없고 차례만 버린다.
##   반응 문장은 계열별 "combat.talk_no_reply_<계열>", 없으면 "combat.talk_no_reply".
## 말이 통하면 상대 생명력이 낮을수록 weight_low_hp 쪽으로 기운 가중 추첨으로 결과 하나:
##   gauge: 상대 행동 게이지 증감(음수 = 머뭇거림, 양수 = 자극), withdraw: 상대가 전투에서 물러남.
##   결과 문장은 "combat.talk_<id>". 대화가 통해도 전투가 반드시 끝나지는 않는다.


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var a := ctx.target
	if a == null or ctx.source == null or a.dead:
		return false
	var args := {"source": ctx.source.display_name, "target": a.display_name}
	if not a.understands_speech():
		ctx.say(_no_reply_key(a), args, "info")
		return false
	var o := _pick(ctx, JsonUtil.get_array(data, "outcomes"), 1.0 - a.pool.get_ratio("hp"))
	if o.is_empty():
		ctx.say("combat.talk_ignore", args, "info")
		return false
	var key := "combat.talk_" + JsonUtil.get_str(o, "id")
	ctx.say(key, args, "info")
	if JsonUtil.get_float(o, "gauge") != 0.0:
		ctx.events.append({"type": "gauge", "target": a, "amount": JsonUtil.get_float(o, "gauge")})
	if JsonUtil.get_bool(o, "withdraw"):
		ctx.events.append({"type": "withdraw", "target": a})
	return true


func _no_reply_key(a: Actor) -> String:
	if a is Monster:
		for f: Variant in JsonUtil.get_array((a as Monster).def, "family"):
			if Strings.has("combat.talk_no_reply_" + str(f)):
				return "combat.talk_no_reply_" + str(f)
	return "combat.talk_no_reply"


## hurt(0~1)만큼 weight → weight_low_hp로 옮긴 가중치로 하나를 뽑는다.
func _pick(ctx: EffectContext, outcomes: Array, hurt: float) -> Dictionary:
	var total := 0.0
	var weights: Array[float] = []
	for o: Variant in outcomes:
		var d: Dictionary = o if o is Dictionary else {}
		var w := maxf(0.0, lerpf(JsonUtil.get_float(d, "weight"), JsonUtil.get_float(d, "weight_low_hp", JsonUtil.get_float(d, "weight")), clampf(hurt, 0.0, 1.0)))
		weights.append(w)
		total += w
	if total <= 0.0:
		return {}
	var roll := ctx.rng.randf() * total
	for i in weights.size():
		roll -= weights[i]
		if roll < 0.0:
			return outcomes[i]
	return outcomes[outcomes.size() - 1]


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	for o: Variant in JsonUtil.get_array(data, "outcomes"):
		if not o is Dictionary or JsonUtil.get_str(o, "id").is_empty():
			out.append("talk: outcomes 항목은 id가 있는 객체")
		elif JsonUtil.get_float(o, "weight", -1.0) < 0.0:
			out.append("talk: outcomes.weight는 0 이상")
	return out
