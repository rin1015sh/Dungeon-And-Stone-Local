extends EffectHandler
## 피해: {"type": "damage", "scaling": "phys"|"magic", "power": 1.0, "damage_type": "slash"|"weapon"|…, "base": 0,
##        "accuracy": 95, "crit_bonus": 0.15, "ranged": false, "power_if_status": {status, power},
##        "drain_if_status": {"status": "bleeding", "ratio": 0.4}}
## 계산은 DamageCalc. 치명상(급소)이면 생명력을 0으로 만든다. 출처는 "attack:<공격자 id>".
## 맞힌 뒤 Passives.after_hit(적중 시 효과·반사·반격), 흡혈.


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
	if int(r["amount"]) > 0:
		for broken in target.statuses.on_damaged(str(r["damage_type"])):
			ctx.say("effect.status_broken", {"name": target.display_name, "status": DataNames.entry(ctx.db, "statuses", broken)}, "info")
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
	var drain := JsonUtil.get_dict(data, "drain_if_status")
	if not drain.is_empty() and target.statuses.has(JsonUtil.get_str(drain, "status")) and not source.dead:
		var healed := roundi(float(r["amount"]) * JsonUtil.get_float(drain, "ratio"))
		if healed > 0:
			source.pool.modify("hp", float(healed), "drain")
			ctx.say("combat.drain", {"source": source.display_name, "amount": healed}, "info")
	var ranged := JsonUtil.get_bool(data, "ranged") if data.has("ranged") else \
		(JsonUtil.get_str(data, "damage_type", "blunt") == "weapon" and source.weapon_is_ranged())
	Passives.after_hit(ctx, ctx.registry, int(r["amount"]), bool(r["crit"]), ranged, str(r["damage_type"]))
	return true


func validate(data: Dictionary, _db: GameDatabase) -> PackedStringArray:
	var out := PackedStringArray()
	if not JsonUtil.get_str(data, "scaling", "phys") in ["phys", "magic"]:
		out.append("damage: scaling은 phys/magic")
	if JsonUtil.get_float(data, "power", 1.0) <= 0.0:
		out.append("damage: power는 0보다 커야 한다")
	return out
