class_name RiftScavenge
extends RefCounted
## 균열 장식 뒤지기(사용자 요청 2026-10-24 "균열 장식 타일을 F로 살피면 썩은 고기·오래된 은화 같은 잡템 — 쓸 수는 없고 모아 파는 돈벌이", RF19).
## 타일 "scavenge": 표 id(data/scavenge.json {id, empty_chance, items[{item, weight}]}) — 바로 옆(4방향)에서 살피면
## 표에서 하나를 무게대로 뽑는다(empty_chance면 빈손). 한 칸은 이번 균열에서 한 번뿐(ExploreSession.scavenged — 챕터 세션과 함께
## 보관되니 되돌아가도 그대로, 다음 달 균열은 새로). 가방에 자리가 없으면 뒤지지 않은 채로 둔다.


## 바로 옆에 아직 뒤지지 않은 장식이 있으면 그 칸, 없으면 (-1, -1).
static func target(s: ExploreSession) -> Vector2i:
	if s.rift_run == null:
		return Vector2i(-1, -1)
	for d in FloorMap.DIRS4:
		var p := s.pos + d
		var def := s.map.def_at(p)
		if def != null and not def.scavenge.is_empty() and not s.scavenged.has(p):
			return p
	return Vector2i(-1, -1)


## 뒤졌으면 true(빈손이어도).
static func run(s: ExploreSession) -> bool:
	var p := target(s)
	if p.x < 0:
		return false
	var def := s.map.def_at(p)
	var table := s.db.get_entry("scavenge", def.scavenge)
	var item := ""
	if not s.rng.chance(JsonUtil.get_float(table, "empty_chance")):
		var list := JsonUtil.get_array(table, "items")
		var w: Array = list.map(func(e: Variant) -> float: return JsonUtil.get_float(e as Dictionary, "weight", 1.0))
		var i := s.rng.weighted_index(w)
		if i >= 0:
			item = JsonUtil.get_str(list[i] as Dictionary, "item")
	if item.is_empty():
		s.scavenged[p] = true
		s.message.emit("explore.scavenge_empty", {"tile": def.name_ko}, "info")
		return true
	var name := DataNames.entry(s.db, "items", item)
	if not s.player.inventory.fits(item, 1):
		s.message.emit("explore.scavenge_no_room", {"item": name}, "warn")
		return true
	s.scavenged[p] = true
	s.player.inventory.add(item, 1)
	s.message.emit("explore.scavenge_found", {"tile": def.name_ko, "item": name}, "good")
	return true
