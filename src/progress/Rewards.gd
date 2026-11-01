class_name Rewards
extends RefCounted
## 전투 승리 보상을 플레이어에게 준다: 처치 기록(도감)·첫 처치 경험치·레벨업·(with_drops면) 전리품(가방).
## 정수는 여기서 주지 않는다 — 전투 장면에서 쓰러진 자리의 정수를 바로 흡수하거나 버린다(DropPickup·CombatDrops).
## 하고 싶은 말은 메시지 목록 {key, args, kind}로 돌려준다(번역은 화면 몫).


## in_rift·essence_mult·colors는 예전 호출과 맞추려고 받는다(정수 굴림은 DropPickup.roll).
## with_drops = false면 전리품도 주지 않는다(전투 장면에서 하나씩 묻고 주울 때 — DropPickup).
static func grant(pc: PlayerCharacter, killed: Array[String], rng: Rng, _now_hours: float = -1.0, _in_rift: bool = false,
		_essence_mult: float = 1.0, _colors: Array[String] = [], with_drops: bool = true) -> Array[Dictionary]:
	var db := pc.db
	var msgs: Array[Dictionary] = []
	var before := pc.get_level()
	for k in killed.size():
		var id := killed[k]
		pc.knowledge.see(id)
		var gained := pc.progression.record_kill(db, id)
		var parts := pc.progression.last_kill
		var mname := DataNames.entry(db, "monsters", id)
		if int(parts.get("first", 0)) > 0:
			msgs.append(_m("reward.first_kill", {"name": mname, "exp": int(parts["first"])}, "gain"))
		if int(parts.get("guardian", 0)) > 0:
			msgs.append(_m("reward.guardian_bonus", {"name": mname, "exp": int(parts["guardian"])}, "gain"))
		if int(parts.get("lord", 0)) > 0:
			msgs.append(_m("reward.lord_bonus", {"name": mname, "exp": int(parts["lord"])}, "gain"))
		if gained > 0:
			pc.progression.gain(pc, gained, rng)
		if not with_drops:
			continue
		for drop in Loot.roll(db, id, rng):
			var want := int(drop["count"])
			var got := pc.inventory.add(str(drop["id"]), want)
			var item_name := DataNames.entry(db, "items", str(drop["id"]))
			if got > 0:
				msgs.append(_m(ItemInfo.got_key(got), {"item": item_name, "n": got}, "good"))
			if got < want:
				msgs.append(_m("reward.bag_full", {"item": item_name, "count": want - got, "item_id": str(drop["id"])}, "warn"))
	if pc.get_level() > before:
		msgs.append(_m("reward.level_up", {"level": pc.get_level(),
			"slots": Progression.essence_slots(db, pc.get_level())}, "gain"))
	return msgs


## kind "gain" = 공적·레벨업(초록 글 — 대화창에서 초록은 이것뿐, 사용자 2026-10-27 UI33). 얻은 물건 등 나머지 "good"은 흰 글.
static func _m(key: String, args: Dictionary, kind: String) -> Dictionary:
	return {"key": key, "args": args, "kind": kind}
