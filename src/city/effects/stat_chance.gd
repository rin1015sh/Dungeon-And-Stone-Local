extends CityEffect
## 확률 능력치 상승(독서·훈련): {"type": "stat_chance", "stats": [id…], "pick": "random"|"all", "chance": 0~1, "amount": n}
## 판정은 시드 난수(CityState.rng). 성공하면 기본 스탯을 영구로 올리고 PlayerCharacter.stat_history에 어떤 활동으로 올랐는지 남긴다.
## stats·chance·amount가 null(미정)이면 오르지 않는다(chance null = 0). pick null = 임시로 random.

const PICKS := ["random", "all"]


func apply(ctx: CityContext, data: Dictionary) -> void:
	var stats := JsonUtil.get_array(data, "stats")
	if stats.is_empty() or not CityValues.is_set(data, "chance"):
		ctx.say("city.fx.stat_undecided")
		return
	if not ctx.rng().chance(clampf(CityValues.num(data, "chance"), 0.0, 1.0)):
		ctx.say("city.fx.stat_fail")
		return
	if not CityValues.is_set(data, "amount") or is_zero_approx(CityValues.num(data, "amount")):
		ctx.say("city.fx.stat_no_amount")
		return
	var amount := CityValues.num(data, "amount")
	var targets: Array = stats if JsonUtil.get_str(data, "pick") == "all" else [ctx.rng().pick(stats)]
	for v: Variant in targets:
		var stat := str(v)
		if not ctx.pc.stats.has_stat(stat):
			continue
		ctx.pc.stats.set_base(stat, ctx.pc.stats.get_base(stat) + amount)
		ctx.pc.stat_history.append({"stat": stat, "amount": amount, "activity": ctx.activity_id,
			"month": ctx.state.month, "period": ctx.state.period})
		ctx.say("city.fx.stat_up", {"stat": (ctx.db.stats[stat] as StatDef).name_ko, "delta": CityContext.signed(amount),
			"value": CityContext.fmt(ctx.pc.stats.get_value(stat))}, "good")


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	for v: Variant in JsonUtil.get_array(data, "stats"):
		if not db.stats.has(str(v)):
			out.append("stat_chance: 스탯 '%s' 없음" % v)
	if data.get("pick") != null and not JsonUtil.get_str(data, "pick") in PICKS:
		out.append("stat_chance: pick은 %s 중 하나" % [PICKS])
	if data.get("stats") != null and not data.get("stats") is Array:
		out.append("stat_chance: stats는 배열")
	return out
