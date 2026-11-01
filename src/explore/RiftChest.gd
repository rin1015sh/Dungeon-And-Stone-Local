class_name RiftChest
extends RefCounted
## 균열 상자(사용자 2026-11-01 "장비나 꽤 쓸만한 아이템은 상자에 — 남용은 말고 · 동전 던지기로 획득", V25 →
## 같은 날 "던지기 전에 앞면·뒷면을 물어봐 W/S로 고르는 창 · 맞추면 아이템, 못 맞추면 그냥 잡템 — 열고 못 열고가 아니라 좋은 아이템을 얻고 못 얻고").
## 챕터 "loot"의 물건 가운데 상자에 담기는 것(pick): 항목에 "chest": true/false가 있으면 그대로, 없으면
##   장비(ItemInfo.equip이 있는 것) 또는 값이 balance chest.min_price 이상인 물건(가장 좋은 회복약)
##   — 한 챕터에 chest.max_per_chapter개까지(장비 먼저, 그다음 값 높은 순 — 장비가 아닌 것은 chest.max_non_gear개). 나머지는 지금처럼 바닥에 놓인다.
## 열기(open): 앞면·뒷면을 고르고(ExploreSession.guess — 화면이 W/S 선택 창, Esc면 그만둠) → 동전(CoinToss "chest", 연출 toss) →
##   맞히면 담긴 물건, 못 맞히면 그 균열의 잡템 하나(balance chest.junk[균열 id] = data/scavenge.json 표). 어느 쪽이든 상자는 열린 빈 채 남는다(한 번뿐).
## 가방에 자리가 없으면 고르지 않는다.


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


## p 칸의 상자를 연다(앞뒤 고르기 → 동전). 다뤘으면 true.
static func open(s: ExploreSession, p: Vector2i) -> bool:
	var d: Dictionary = s.loot[p]
	var item := str(d["item"])
	var n := int(d["count"])
	if not s.player.inventory.fits(item, n):
		s.message.emit("explore.scavenge_no_room", {"item": DataNames.entry(s.db, "items", item)}, "warn")
		return true
	s.guess(func(pick: int) -> void:
		if pick < 0 or not s.loot.has(p) or not locked(s.loot[p] as Dictionary):
			return  # 고르지 않고 물러났다 — 상자는 그대로
		var heads := CoinToss.flip(s.db, s.rng, "chest")
		var hit := (pick == 0) == heads
		s.toss(heads, func() -> void: _result(s, p, hit)))
	return true


## 결과: 맞혔으면 담긴 물건, 못 맞혔으면 잡템 하나. 상자는 열린 채.
static func _result(s: ExploreSession, p: Vector2i, hit: bool) -> void:
	if not s.loot.has(p) or not locked(s.loot[p] as Dictionary):
		return
	var d: Dictionary = s.loot[p]
	d["opened"] = true
	s.sound.emit("chest_open", p)
	if hit:
		var item := str(d["item"])
		var n := int(d["count"])
		s.player.inventory.add(item, n)
		s.message.emit("explore.chest_found" if n == 1 else "explore.chest_found_n", {"item": DataNames.entry(s.db, "items", item), "n": n}, "good")
	else:
		var junk := junk_item(s)
		if not junk.is_empty() and s.player.inventory.fits(junk, 1):
			s.player.inventory.add(junk, 1)
			s.message.emit("explore.chest_junk", {"item": DataNames.entry(s.db, "items", junk)}, "info")
		else:
			s.message.emit("explore.chest_nothing", {}, "info")
	s.tiles_changed.emit(Rect2i(p, Vector2i.ONE))
	s.refresh_view()


## 이 균열의 잡템 하나(balance chest.junk[균열 id] → scavenge 표에서 무게대로 — 빈손 확률은 쓰지 않는다). 없으면 "".
static func junk_item(s: ExploreSession) -> String:
	var rid := s.rift_run.rift_id if s.rift_run != null else ""
	var table := s.db.get_entry("scavenge", JsonUtil.get_str(JsonUtil.get_dict(s.db.bal("chest", {}) as Dictionary, "junk"), rid))
	var list := JsonUtil.get_array(table, "items")
	if list.is_empty():
		return ""
	var w: Array = list.map(func(e: Variant) -> float: return JsonUtil.get_float(e as Dictionary, "weight", 1.0))
	var i := s.rng.weighted_index(w)
	return JsonUtil.get_str(list[i] as Dictionary, "item") if i >= 0 else ""
