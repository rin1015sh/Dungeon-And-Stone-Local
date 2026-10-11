extends EffectHandler
## 피해: {"type": "damage", "scaling": "phys"|"magic", "power": 1.0, "damage_type": "slash"|"weapon"|…, "base": 0}
## 계산은 DamageCalc. 치명상(급소)이면 생명력을 0으로 만든다. 출처는 "attack:<공격자 id>".


func apply(ctx: EffectContext, data: Dictionary) -> bool:
	var target := ctx.target
	var source := ctx.source
	if target == null or source == null or target.dead:
		return false
	var rolls := {"hit": ctx.rng.randf(), "crit": ctx.rng.randf(), "var": ctx.rng.randf(), "lethal": ctx.rng.randf()}
	var r := DamageCalc.resolve(ctx.db, source, target, data, rolls, bool(ctx.info.get("aim_weak", false)))
	var args := {"source": source.display_name, "target": target.display_name, "amount": r["amount"]}
	var ev := r.duplicate()
	ev["type"] = "damage"
	ev["target"] = target
	ctx.events.append(ev)
	if not bool(r["hit"]):
		ctx.say("combat.miss", args, "info")
		return true
	if float(r["affinity"]) <= 0.0:
		ctx.say("combat.immune", args, "warn")
		return true
	var origin := "attack:" + source.id
	target.pool.modify("hp", -float(r["amount"]), origin)
	if bool(r["crit"]):
		ctx.say("combat.crit", args, "danger")
	elif bool(r["weak"]):
		ctx.say("combat.weak_hit", args, "danger")
	else:
		ctx.say("combat.hit", args, "info")
	if float(r["affinity"]) > 1.0:
		ctx.say("combat.effective", args, "good")
	if bool(r["lethal"]) and not target.dead:
		target.pool.set_current("hp", 0.0, origin)
		ctx.say("combat.lethal", args, "danger")
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "scaling", "phys") in ["phys", "magic"]:
		out.append("damage: scaling은 phys/magic")
	if JsonUtil.get_float(data, "power", 1.0) <= 0.0:
		out.append("damage: power는 0보다 커야 한다")
	return out
