extends EffectHandler
## 예고 공격(죽은 자의 기억 등): {"type": "delayed", "rounds": 2, "hits": 3, "effects": [ … ], "target": "random"|"cast"}
## "target": "cast"면 시전 때 고른 대상에게 [예고](telegraphed)를 걸고 그 대상에게 터진다(대상이 사라졌으면 무작위).
## "guarded_mult": 터질 때 대상이 방어 중이면 피해 위력에 더 곱한다(방어로 받아 내는 패턴 — 사형 선고 0.3).
## 시전자의 다음 차례 시작을 rounds번 지나면 무작위 적(끌어들이는 상태 draws_attacks가 있으면 그쪽 먼저)에게
## effects를 hits번 적용한다. 전투 중에만(Battle이 사건을 받아 BattleDelayed에 맡긴다).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var marked: Actor = ctx.target if JsonUtil.get_str(data, "target", "random") == "cast" and ctx.target != ctx.source else null
	if marked != null:
		marked.statuses.apply("telegraphed")
	ctx.events.append({"type": "delayed", "rounds": JsonUtil.get_int(data, "rounds", 1), "hits": JsonUtil.get_int(data, "hits", 1),
		"effects": JsonUtil.get_array(data, "effects"), "name": str(ctx.info.get("skill_name", "")), "marked": marked,
		"guarded_mult": JsonUtil.get_float(data, "guarded_mult", 1.0)})
	ctx.say("combat.delayed_warn", {"name": ctx.source.display_name if ctx.source != null else ""}, "danger")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if JsonUtil.get_int(data, "rounds", 0) < 1:
		out.append("delayed: rounds는 1 이상")
	if JsonUtil.get_array(data, "effects").is_empty():
		out.append("delayed: effects가 비었다")
	if not JsonUtil.get_str(data, "target", "random") in ["random", "cast"]:
		out.append("delayed: target은 random/cast")
	return out
