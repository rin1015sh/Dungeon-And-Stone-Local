extends EffectHandler
## 상태이상 부여: {"type": "apply_status", "status": "bleeding", "chance": 0.2, "duration": 3}
## chance가 없으면 확정. duration이 없으면 상태이상 정의의 지속시간. "to": "self"면 시전자에게.
## "unless_target_status": 대상이 이미 그 상태면 건너뛴다(정수판 피의 낙인 — 새 제물에게만 향연 중첩).
## "if_target_status": 대상이 그 상태일 때만 건다(금속 독).
## 큰 몸짓 중인 상대(끊기는 예고 — BattleDelayed.OFF_BALANCE)에게 차례를 빼앗는 상태(flag skip_turn — 기절 · 빙결)를 걸 때는
##   확률 × combat.windup_stun_mult(중심을 잃었다 — 끊을 때를 노리면 잘 걸린다, 전투 개선 CB6).
## 남(적)이 건 상태는 정의의 resist {stats}로 저항한다: 확률 = min(status.resist_max, Σ 스탯 × status.resist_per_point).


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var actor := ctx.source if JsonUtil.get_str(data, "to") == "self" else ctx.subject()
	if actor == null or actor.dead:
		return false
	var unless := JsonUtil.get_str(data, "unless_target_status")
	if not unless.is_empty() and ctx.target != null and ctx.target.statuses.has(unless):
		return false
	var only_if := JsonUtil.get_str(data, "if_target_status")  # 대상이 이미 그 상태일 때만(금속 독 — 중독 대상에게 한 겹 더)
	if not only_if.is_empty() and (ctx.target == null or not ctx.target.statuses.has(only_if)):
		return false
	var status_id := JsonUtil.get_str(data, "status")
	if data.has("chance") and not ctx.rng.chance(_chance(ctx, actor, status_id, JsonUtil.get_float(data, "chance", 1.0))):
		return false
	var args := {"name": actor.display_name, "status": DataNames.entry(ctx.db, "statuses", status_id)}
	match Passives.try_status(ctx.db, ctx.rng, ctx.source, actor, status_id, JsonUtil.get_float(data, "duration", -1.0)):
		"":
			var now := status_id
			if not actor.statuses.has(status_id):  # 최대 중첩에서 다른 상태로 바뀌었다(서리 → 빙결)
				var conv := JsonUtil.get_str(JsonUtil.get_dict(ctx.db.get_entry("statuses", status_id), "on_max_stacks"), "status")
				now = conv if actor.statuses.has(conv) else status_id
			ctx.say("effect.status_on_named", {"name": actor.display_name, "status": DataNames.entry(ctx.db, "statuses", now)}, "warn")
			return true
		"immune":
			ctx.say("effect.status_immune", args, "info")
		"resisted":
			ctx.say("effect.status_resisted", args, "info")
	return false


func _chance(ctx: EffectContext, actor: Actor, status_id: String, base: float) -> float:
	if not actor.has_meta(BattleDelayed.OFF_BALANCE):
		return base
	if not JsonUtil.get_array(ctx.db.get_entry("statuses", status_id), "flags").has("skip_turn"):
		return base
	return minf(1.0, base * float(ctx.db.bal("combat.windup_stun_mult", 1.0)))


func validate(data: Dictionary, db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not db.has_entry("statuses", JsonUtil.get_str(data, "status")):
		out.append("apply_status: status '%s' 없음" % data.get("status"))
	if data.has("chance"):
		var c := JsonUtil.get_float(data, "chance", -1.0)
		if c < 0.0 or c > 1.0:
			out.append("apply_status: chance는 0~1")
	return out
