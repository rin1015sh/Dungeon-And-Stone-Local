extends EffectHandler
## 증원: {"type": "summon", "monster": "goblin", "chance": 0.5, "rounds": 2} — 전투 중에만(Battle이 사건을 받아 몬스터를 더한다).
## rounds가 있으면 소환수는 자기 차례가 그만큼 끝나면 사라진다(슬라임 정수 분열).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	if data.has("chance") and not ctx.rng.chance(JsonUtil.get_float(data, "chance", 1.0)):
		ctx.say("combat.summon_fail", {"name": ctx.source.display_name if ctx.source != null else ""}, "info")
		return false
	ctx.events.append({"type": "summon", "monster": JsonUtil.get_str(data, "monster"), "rounds": JsonUtil.get_int(data, "rounds", 0)})
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("monsters", JsonUtil.get_str(data, "monster")):
		out.append("summon: monster '%s' 없음" % data.get("monster"))
	return out
