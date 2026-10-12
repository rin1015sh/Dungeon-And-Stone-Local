class_name Rewards
extends RefCounted
## 전투 승리 보상을 플레이어에게 준다: 처치 기록(도감)·첫 처치 경험치·레벨업·전리품(가방)·정수(대기 목록).
## now_hours(게임 시각)를 주면 대기 정수가 essence.expire_hours 뒤에 사라진다.
## 하고 싶은 말은 메시지 목록 {key, args, kind}로 돌려준다(번역은 화면 몫).


static func grant(pc: PlayerCharacter, killed: Array[String], rng: Rng, now_hours: float = -1.0) -> Array[Dictionary]:
	var db := pc.db
	var msgs: Array[Dictionary] = []
	var before := pc.get_level()
	for id in killed:
		pc.knowledge.see(id)
		var gained := pc.progression.record_kill(db, id)
		var parts := pc.progression.last_kill
		var mname := DataNames.entry(db, "monsters", id)
		if int(parts.get("first", 0)) > 0:
			msgs.append(_m("reward.first_kill", {"name": mname, "exp": int(parts["first"])}, "good"))
		if int(parts.get("guardian", 0)) > 0:
			msgs.append(_m("reward.guardian_bonus", {"name": mname, "exp": int(parts["guardian"])}, "good"))
		if int(parts.get("lord", 0)) > 0:
			msgs.append(_m("reward.lord_bonus", {"name": mname, "exp": int(parts["lord"])}, "good"))
		if gained > 0:
			pc.progression.gain(pc, gained, rng)
		for drop in Loot.roll(db, id, rng):
			var want := int(drop["count"])
			var got := pc.inventory.add(str(drop["id"]), want)
			var item_name := DataNames.entry(db, "items", str(drop["id"]))
			if got > 0:
				msgs.append(_m("reward.loot", {"item": item_name, "count": got}, "good"))
			if got < want:
				msgs.append(_m("reward.bag_full", {"item": item_name, "count": want - got}, "warn"))
		var ess := EssenceDrop.roll(db, id, rng)
		if not ess.is_empty():
			pc.essences.add_pending(db, ess, now_hours)
			msgs.append(_m("reward.essence", {"name": DataNames.entry(db, "essences", str(ess["essence"])),
				"color": DataNames.tag(db, "essence_colors", str(ess["color"]))}, "good"))
	if pc.get_level() > before:
		msgs.append(_m("reward.level_up", {"level": pc.get_level(),
			"slots": Progression.essence_slots(db, pc.get_level())}, "good"))
	return msgs


static func _m(key: String, args: Dictionary, kind: String) -> Dictionary:
	return {"key": key, "args": args, "kind": kind}
