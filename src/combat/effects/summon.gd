extends EffectHandler
## 증원: {"type": "summon", "monster": "goblin", "chance": 0.5, "rounds": 2} — 전투 중에만(Battle이 사건을 받아 몬스터를 더한다).
## rounds가 있으면 소환수는 자기 차례가 그만큼 끝나면 사라진다(슬라임 정수 분열). "pick": [..]이면 그중 하나(수호자의 눈 경보).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	if ctx.source != null and ctx.source.dead:
		return false
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		ctx.say("combat.summon_fail", {"name": ctx.source.display_name if ctx.source != null else ""}, "info")
		return false
	var pool := JsonUtil.get_array(data, "pick")
	var mid := str(ctx.rng.pick(pool)) if not pool.is_empty() else JsonUtil.get_str(data, "monster")
	ctx.events.append({"type": "summon", "monster": mid, "rounds": JsonUtil.get_int(data, "rounds", 0)})
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	var ids: Array = JsonUtil.get_array(data, "pick") if data.has("pick") else [data.get("monster")]
	for id: Variant in ids:
		if not db.has_entry("monsters", str(id)):
			out.append("summon: monster '%s' 없음" % id)
	return out
