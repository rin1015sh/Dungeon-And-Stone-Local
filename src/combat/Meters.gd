class_name Meters
extends RefCounted
## 전투 게이지(data/meters.json, docs/PROMPT_FLOOR1_V2.md §7.2): 드레드피어의 공포·역병·원망(탐험가)과 분노·증오(보스).
## 값은 Actor.meters(id -> 값)에 있고, 전투가 끝나면 BattleRules.cleanup이 비운다.
## 정의: {id, name_ko, max, on_full {status}, reset_on_full, color}. 가득 차면 on_full의 상태이상을 건다(면역이면 안 걸림).
## 효과 meter(더하기)·meter_damage(게이지 비례 고정 피해), 패시브 meter_on_damaged·attacker_meter가 쓴다.


static func value(a: Actor, id: String) -> float:
	return float(a.meters.get(id, 0.0))


static func max_of(db: GameDatabase, id: String) -> float:
	return JsonUtil.get_float(db.get_entry("meters", id), "max", 100.0)


## 게이지를 amount만큼 바꾼다. 가득 차면 상태이상을 걸고(가능하면) 메시지를 ctx에 남긴다. 가득 찼으면 true.
static func add(db: GameDatabase, a: Actor, id: String, amount: float, ctx: EffectContext = null) -> bool:
	var def := db.get_entry("meters", id)
	if def.is_empty() or a == null or a.dead or is_zero_approx(amount):
		return false
	var mx := JsonUtil.get_float(def, "max", 100.0)
	var before := value(a, id)
	if before >= mx and amount > 0.0:
		return false
	var now := clampf(before + amount, 0.0, mx)
	a.meters[id] = now
	if now < mx:
		return false
	var st := JsonUtil.get_str(JsonUtil.get_dict(def, "on_full"), "status")
	var took := st.is_empty() or Passives.try_status(db, null, null, a, st).is_empty()
	if JsonUtil.get_bool(def, "reset_on_full", true):
		a.meters[id] = 0.0
	if ctx != null and took:
		ctx.say("combat.meter_full", {"name": a.display_name, "meter": JsonUtil.get_str(def, "name_ko", id),
			"status": DataNames.entry(db, "statuses", st)}, "danger")
	return true


## 표시용: [{id, name, value, max, color}] (값이 0보다 큰 것만).
static func list(db: GameDatabase, a: Actor) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var keys: Array = a.meters.keys()
	keys.sort()
	for id: Variant in keys:
		var v := float(a.meters[id])
		if v <= 0.0:
			continue
		var def := db.get_entry("meters", str(id))
		out.append({"id": str(id), "name": JsonUtil.get_str(def, "name_ko", str(id)), "value": v,
			"max": JsonUtil.get_float(def, "max", 100.0), "color": JsonUtil.get_str(def, "color", "#ffffff")})
	return out
