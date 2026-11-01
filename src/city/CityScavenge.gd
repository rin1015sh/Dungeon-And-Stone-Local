class_name CityScavenge
extends RefCounted
## 도시 건물 안 가구 뒤지기(사용자 요청 2026-10-31 "도시 건물 타일들과 상호작용 — 잡템(대장간 쇳조각 · 도서관 새 책 등)", CT74).
## 뒤질 자리(CityRoom.searchables — city.json room.search[시설][가구 shape·벽 장식 style] 또는 범례 scavenge)를 바라보고 Enter:
## 균열 잡템과 같은 표(data/scavenge.json {empty_chance, items[{item, weight}]})에서 무게대로 하나(empty_chance면 빈손).
## 한 자리는 한 순에 한 번(CityState.searched — 순이 바뀌면 비운다). 가방에 자리가 없으면 뒤지지 않은 채로 둔다.
## 무작위는 CityState.rng. 오토로드를 참조하지 않는다.


## 그 자리를 이번 순에 이미 뒤졌는가.
static func done(state: CityState, spot: Dictionary) -> bool:
	return state.searched.has(str(spot.get("key", "")))


## 뒤진다 → {key: 문구 키, args, tone}(대화창 한 줄 — 얻은 것 · 빈손 · 가방이 참 · 이미 뒤졌다).
static func run(state: CityState, pc: PlayerCharacter, spot: Dictionary) -> Dictionary:
	var tile := str(spot.get("name_ko", ""))
	if done(state, spot):
		return {"key": "city.reason_searched", "args": {}, "tone": "warn"}
	var table := state.db.get_entry("scavenge", str(spot.get("search", "")))
	var item := ""
	if not state.rng.chance(JsonUtil.get_float(table, "empty_chance")):
		var list := JsonUtil.get_array(table, "items")
		var w: Array = list.map(func(e: Variant) -> float: return JsonUtil.get_float(e as Dictionary, "weight", 1.0))
		var i := state.rng.weighted_index(w)
		if i >= 0:
			item = JsonUtil.get_str(list[i] as Dictionary, "item")
	if item.is_empty():
		state.searched.append(str(spot["key"]))
		return {"key": "explore.scavenge_empty", "args": {"tile": tile}, "tone": "info"}
	var name := DataNames.entry(state.db, "items", item)
	if not pc.inventory.fits(item, 1):
		return {"key": "explore.scavenge_no_room", "args": {"item": name}, "tone": "warn"}
	state.searched.append(str(spot["key"]))
	pc.inventory.add(item, 1)
	return {"key": ItemInfo.got_key(1), "args": {"item": name, "n": 1}, "tone": "good"}
