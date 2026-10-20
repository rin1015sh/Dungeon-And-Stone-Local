extends EffectHandler
## 대신 맞기(정수 재기획): {"type": "cover", "duration": 2} — 시전자가 대상 아군을 지킨다.
## 대상에게 "covered"(보호받음) 상태를 걸고 지키는 사람을 묶어 둔다. 그동안 적의 단일 대상 공격은 지키는 사람이 받는다(Battle._use_skill).


const STATUS := "covered"


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var t := ctx.subject()
	if t == null or t.dead or t == ctx.source:
		return false
	if not t.statuses.apply(STATUS, JsonUtil.get_float(data, "duration", -1.0)):
		return false
	t.statuses.set_link(STATUS, ctx.source)
	ctx.say("combat.cover", {"protector": ctx.source.display_name, "name": t.display_name}, "info")
	return true


func validate(_data: Dictionary, db: GameDatabase) -> PackedStringArray:
	return PackedStringArray() if db.has_entry("statuses", STATUS) else PackedStringArray(["cover: statuses에 covered 없음"])
