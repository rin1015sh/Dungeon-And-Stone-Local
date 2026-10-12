class_name BattlePassives
extends RefCounted
## 전투 단위로 작동하는 패시브·몬스터 데이터(Battle·BattleRules가 부른다, 키 설명은 Passives.gd):
##   전투 시작 — start_summons(동반), foe_statuses_on_start(상대 전원 상태), 몬스터 types(본 나이트 타입), ally_aura
##   증원 뒤 — ally_aura 다시 계산
##   자기 차례 끝 — regen_per_round(재생, flag no_regen이면 멈춤)
##   스킬 효과 — skill "repeat_per_ally"(같은 편 그 몬스터 수만큼 반복), 기본 공격 basic_attack_effects·basic_extra_hit_chance

const AURA_SOURCE := "aura:"


static func on_start(b: Battle) -> void:
	for u in b.units.duplicate():
		for id: Variant in _list(u.actor, "start_summons"):
			if b.side_units(u.side).size() < int(b.db.bal("combat.max_side_units", 6)):
				var m := Monster.create(b.db, str(id), " +")
				b.add(m, u.side, JsonUtil.get_str(m.behavior(), "row", "front"))
				b.message.emit("combat.summon", {"name": u.label(), "monster": m.display_name}, "danger")
	for u in b.units:
		for st: Variant in _list(u.actor, "foe_statuses_on_start"):
			for f in b.opponents(u):
				f.actor.statuses.apply(str(st))
		if u.actor is Monster:
			_pick_type(b, u)
	refresh_auras(b)


## 같은 편 ally_aura를 모두 떼고 다시 붙인다.
static func refresh_auras(b: Battle) -> void:
	for u in b.units:
		for p in u.actor.passives:
			if p.has("ally_aura"):
				for a in b.units:
					a.actor.stats.remove_source(AURA_SOURCE + JsonUtil.get_str(p, "id") + ":" + u.actor.id + str(u.order))
	for u in b.units:
		if not u.is_active():
			continue
		for p in u.actor.passives:
			var aura := JsonUtil.get_dict(p, "ally_aura")
			if aura.is_empty():
				continue
			for a in b.side_units(u.side):
				if a != u and _aura_fits(a, aura):
					a.actor.stats.add_modifiers_from_data(AURA_SOURCE + JsonUtil.get_str(p, "id") + ":" + u.actor.id + str(u.order),
						JsonUtil.get_array(aura, "modifiers"))


## 자기 차례가 끝났다(행동했거나 건너뛰었다).
static func turn_end(b: Battle, c: Combatant) -> void:
	var r := Passives.sum(c.actor, "regen_per_round")
	if r > 0.0 and c.is_active() and not c.actor.statuses.has_flag("no_regen"):
		var amount := roundi(c.actor.pool.get_max("hp") * r * c.actor.statuses.heal_mult())
		var healed := c.actor.pool.modify("hp", float(amount), "regen")
		if healed > 0.0:
			b.message.emit("combat.regen", {"name": c.label(), "amount": roundi(healed)}, "info")


## 이번 스킬 사용의 효과 목록(반복·기본 공격 대체 반영).
static func skill_effects(b: Battle, c: Combatant, skill_id: String, sk: Dictionary) -> Array:
	var fx := JsonUtil.get_array(sk, "effects")
	if skill_id == Battle.BASIC_ATTACK:
		for p in c.actor.passives:
			if p.has("basic_attack_effects"):
				fx = JsonUtil.get_array(p, "basic_attack_effects")
		if b.rng.chance(Passives.sum(c.actor, "basic_extra_hit_chance")):
			fx = fx + fx
			b.message.emit("combat.extra_hit", {"name": c.label()}, "info")
	var per := JsonUtil.get_str(sk, "repeat_per_ally")
	if not per.is_empty():
		var n := b.side_units(c.side).filter(func(u: Combatant) -> bool:
			return u.actor is Monster and (u.actor as Monster).monster_id == per).size()
		var out: Array = []
		for i in maxi(1, n):
			out.append_array(fx)
		return out
	return fx


## 본 나이트처럼 타입이 여럿인 몬스터: 데이터 "types": [{id, name_ko, skills, warn_key?}] 중 하나(전투 rng).
static func _pick_type(b: Battle, u: Combatant) -> void:
	var m := u.actor as Monster
	var types := JsonUtil.get_array(m.def, "types")
	if types.is_empty() or m.has_meta("monster_type"):
		return
	var t: Dictionary = b.rng.pick(types)
	m.set_meta("monster_type", JsonUtil.get_str(t, "id"))
	for s: Variant in JsonUtil.get_array(t, "skills"):
		if not m.skills.has(str(s)):
			m.skills.append(str(s))
	m.display_name += " (%s)" % JsonUtil.get_str(t, "name_ko")
	b.message.emit(JsonUtil.get_str(t, "message", "combat.monster_type"), {"name": m.display_name}, "danger" if t.has("message") else "info")


static func _aura_fits(a: Combatant, aura: Dictionary) -> bool:
	if not a.actor is Monster:
		return false
	var m := a.actor as Monster
	return JsonUtil.get_array(aura, "lineages").has(m.lineage()) or JsonUtil.get_array(aura, "monsters").has(m.monster_id)


static func _list(a: Actor, key: String) -> Array:
	var out: Array = []
	for p in a.passives:
		out.append_array(JsonUtil.get_array(p, key))
	return out
