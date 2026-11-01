class_name RiftChest
extends RefCounted
## 균열 상자(사용자 2026-11-01 "장비나 꽤 쓸만한 아이템은 상자에 — 남용은 말고 · 동전 던지기로 획득", V25).
## 챕터 "loot"의 물건 가운데 상자에 담기는 것(pick): 항목에 "chest": true/false가 있으면 그대로, 없으면
##   장비(ItemInfo.equip이 있는 것) 또는 값이 balance chest.min_price 이상인 물건(가장 좋은 회복약)
##   — 한 챕터에 chest.max_per_chapter개까지(장비 먼저, 그다음 값 높은 순 — 장비가 아닌 것은 chest.max_non_gear개). 나머지는 지금처럼 바닥에 놓인다.
## 열기(open): 동전(CoinToss "chest") — 앞면이면 물건을 꺼낸다(상자는 열린 채 남는다), 뒷면이면 자물쇠 함정(chest.trap 효과 + 소리)
## 상자는 잠긴 채 남아 다시 열어 볼 수 있다(그때마다 동전 — 함정 위험). 가방에 자리가 없으면 던지지 않는다.


## 상자에 담을 항목 번호들(loot 목록 순서).
static func pick(db: GameDatabase, list: Array) -> Array[int]:
	var forced: Array[int] = []
	var cand: Array = []  # [번호, 장비면 1, 값]
	for i in list.size():
		var d: Dictionary = list[i] if list[i] is Dictionary else {}
		if d.has("chest"):
			if bool(d["chest"]):
				forced.append(i)
			continue
		var item := JsonUtil.get_str(d, "item")
		var gear := not ItemInfo.equip(db, item).is_empty()
		var price := ItemInfo.price(db, item)
		if gear or price >= int(db.bal("chest.min_price", 6000)):
			cand.append([i, 1 if gear else 0, price])
	cand.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1] or (a[1] == b[1] and (a[2] > b[2] or (a[2] == b[2] and a[0] < b[0]))))
	var out := forced.duplicate()
	var cap := int(db.bal("chest.max_per_chapter", 3))
	var others := int(db.bal("chest.max_non_gear", 1))  # 장비가 아닌 것(회복약)은 챕터에 이만큼만
	for c: Array in cand:
		if out.size() >= cap:
			break
		if int(c[1]) == 0:
			if others <= 0:
				continue
			others -= 1
		out.append(int(c[0]))
	out.sort()
	return out


## 잠긴 상자인가(꺼내기 전).
static func locked(d: Dictionary) -> bool:
	return bool(d.get("chest", false)) and not bool(d.get("opened", false))


## p 칸의 상자를 연다(동전). 다뤘으면 true.
static func open(s: ExploreSession, p: Vector2i) -> bool:
	var d: Dictionary = s.loot[p]
	var item := str(d["item"])
	var n := int(d["count"])
	var name := DataNames.entry(s.db, "items", item)
	if not s.player.inventory.fits(item, n):
		s.message.emit("explore.scavenge_no_room", {"item": name}, "warn")
		return true
	var heads := CoinToss.flip(s.db, s.rng, "chest")
	s.toss(heads, func() -> void: _result(s, p, heads))
	return true


static func _result(s: ExploreSession, p: Vector2i, heads: bool) -> void:
	if not s.loot.has(p) or not locked(s.loot[p] as Dictionary):
		return
	var d: Dictionary = s.loot[p]
	if heads:
		var item := str(d["item"])
		var n := int(d["count"])
		d["opened"] = true
		s.player.inventory.add(item, n)
		s.sound.emit("chest_open", p)
		s.message.emit("explore.chest_found" if n == 1 else "explore.chest_found_n", {"item": DataNames.entry(s.db, "items", item), "n": n}, "good")
	else:
		s.sound.emit("chest_trap", p)
		var ctx := EffectContext.new(s.db, null, s.player, s.rng)
		ctx.registry = s.effects
		s.effects.apply_all(ctx, JsonUtil.get_array(s.db.bal("chest", {}) as Dictionary, "trap"))
		s.message.emit("explore.chest_trap", {}, "danger")
		for m: Dictionary in ctx.messages:
			s.message.emit(str(m["key"]), m["args"], str(m["kind"]))
	s.tiles_changed.emit(Rect2i(p, Vector2i.ONE))
	s.refresh_view()
