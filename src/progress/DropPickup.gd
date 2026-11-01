class_name DropPickup
extends RefCounted
## 전투 장면에서 줍는 드롭(사용자 결정 2026-10-16 — ASSUMPTIONS UI13): 몬스터가 쓰러진 자리에 정수·마석(전리품)이 남고,
## 전투가 끝나면 하나씩 "획득할까?"를 묻고 받을 사람을 고른다(CombatScreen).
## 드롭: {"kind": "essence", "inst": 정수 사례, "slot": killed 순번} · {"kind": "item", "id": 아이템 id, "count": n, "slot": …}
## 정수는 받는 사람이 그 자리에서 흡수하고, 두고 가거나 아무도 받을 수 없으면 흩어져 사라진다(사용자 결정 — 남기지 않는다).
## 아이템은 받는 사람의 가방으로(넘치면 두고 간다), 두고 가면 사라진다. 메시지는 {key, args, kind}.


## killed(쓰러뜨린 순서)마다 전리품·정수를 굴려 드롭 목록으로. 인자는 Rewards.grant와 같다.
static func roll(db: GameDatabase, killed: Array[String], rng: Rng, in_rift: bool = false, essence_mult: float = 1.0,
		colors: Array[String] = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in killed.size():
		for drop in Loot.roll(db, killed[k], rng):
			out.append({"kind": "item", "id": str(drop["id"]), "count": int(drop["count"]), "slot": k, "monster": killed[k]})
		var ess := EssenceDrop.roll(db, killed[k], rng, in_rift, essence_mult, colors[k] if k < colors.size() else "")
		if not ess.is_empty():
			out.append({"kind": "essence", "inst": ess, "slot": k, "monster": killed[k]})
	return out


## 화면에 보일 이름: "붉은 고블린의 정수" · "마석(9등급) ×1".
static func label(db: GameDatabase, drop: Dictionary) -> String:
	if str(drop.get("kind")) == "essence":
		var inst: Dictionary = drop["inst"]
		return Strings.t("combat.drop_essence", {"color": DataNames.tag(db, "essence_colors", JsonUtil.get_str(inst, "color")),
			"name": DataNames.entry(db, "essences", JsonUtil.get_str(inst, "essence"))})
	return Strings.t("combat.drop_item", {"item": DataNames.entry(db, "items", str(drop.get("id"))), "count": int(drop.get("count", 1))})


## pc가 받을 수 없는 이유(문자열 키). 받을 수 있으면 "". 아이템은 가방이 차도 고를 수는 있다(넘치는 만큼 두고 간다).
static func check(drop: Dictionary, pc: PlayerCharacter) -> String:
	if pc == null or pc.dead:
		return "combat.drop_cannot"
	if str(drop.get("kind")) == "essence":
		return pc.essences.check_absorb(pc, drop["inst"])
	return ""


## 가방에 다 들어가는가(받을 사람 고르기 칸의 경고용).
static func fits(drop: Dictionary, pc: PlayerCharacter) -> bool:
	return str(drop.get("kind")) == "essence" or pc.inventory.fits(str(drop.get("id")), int(drop.get("count", 1)))


## pc가 받는다. 넘친 아이템 수는 "left"에 담아 돌려준다(균열 출구 물건 처리는 부르는 쪽).
static func take(drop: Dictionary, pc: PlayerCharacter) -> Dictionary:
	var db := pc.db
	if str(drop.get("kind")) == "essence":
		var inst: Dictionary = drop["inst"]
		var why := pc.essences.absorb(pc, inst)
		if not why.is_empty():
			return _m("reward.essence_refused", {"who": pc.display_name, "what": label(db, drop), "reason": Strings.t(why)}, "warn")
		return _m("reward.essence_absorbed", {"who": pc.display_name, "what": label(db, drop)}, "good")
	var id := str(drop.get("id"))
	var want := int(drop.get("count", 1))
	var got := pc.inventory.add(id, want)
	var name := DataNames.entry(db, "items", id)
	if got < want:
		var m := _m("reward.bag_full", {"item": name, "count": want - got, "item_id": id}, "warn")
		m["left"] = want - got
		m["got"] = got
		return m
	return _m(ItemInfo.got_key(got, true), {"who": pc.display_name, "item": name, "n": got}, "good")


## 두고 간다 — 정수는 흩어지고 전리품은 사라진다. reason = 아무도 받을 수 없던 이유 키.
static func leave(db: GameDatabase, drop: Dictionary, reason: String = "") -> Dictionary:
	if str(drop.get("kind")) == "essence":
		if not reason.is_empty():
			return _m("reward.essence_nobody", {"what": label(db, drop), "reason": Strings.t(reason)}, "warn")
		return _m("reward.essence_left", {"what": label(db, drop)}, "info")
	return _m("reward.loot_left", {"what": label(db, drop)}, "info")


static func _m(key: String, args: Dictionary, kind: String) -> Dictionary:
	return {"key": key, "args": args, "kind": kind}
