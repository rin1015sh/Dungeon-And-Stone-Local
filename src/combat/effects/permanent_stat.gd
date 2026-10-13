extends EffectHandler
## 영구 스탯(영약 — 빙정·마력이 깃든 얼음 조각): {"type": "permanent_stat", "stat": "affinity_cold", "amount": 3, "key": "ice_crystal", "max_times": 3}
## 대상의 기본 스탯을 올린다. 같은 key는 캐릭터당 max_times번까지(Actor.boons["<key>@<stat>"]). 넘으면 실패(아이템이 남는다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var a := ctx.subject()
	var stat := JsonUtil.get_str(data, "stat")
	if a == null or not a.stats.has_stat(stat):
		return false
	var key := "%s@%s" % [JsonUtil.get_str(data, "key", ctx.item_id), stat]
	var times := int(a.boons.get(key, 0))
	var limit := JsonUtil.get_int(data, "max_times", 1)
	if times >= limit:
		ctx.say("effect.boon_limit", {"name": a.display_name, "max": limit}, "warn")
		return false
	var amount := JsonUtil.get_float(data, "amount")
	a.stats.set_base(stat, a.stats.get_base(stat) + amount)
	a.boons[key] = times + 1
	ctx.say("effect.boon", {"stat": (ctx.db.stats[stat] as StatDef).name_ko, "amount": ("%d" % int(amount)) if is_equal_approx(amount, roundf(amount)) else ("%.1f" % amount), "n": times + 1, "max": limit}, "good")
	return true


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.stats.has(JsonUtil.get_str(data, "stat")):
		out.append("permanent_stat: stat '%s' 없음" % data.get("stat"))
	if JsonUtil.get_float(data, "amount") == 0.0:
		out.append("permanent_stat: amount가 0")
	if data.has("max_times") and JsonUtil.get_int(data, "max_times") < 1:
		out.append("permanent_stat: max_times는 1 이상")
	if JsonUtil.get_str(data, "key").is_empty():
		out.append("permanent_stat: key가 없다(같은 영약끼리 횟수를 센다 — 스킬에서 쓰면 겹친다)")
	return out
