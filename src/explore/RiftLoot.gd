class_name RiftLoot
extends RefCounted
## 균열에 놓인 물건(사용자 2026-10-30 "공간마다 있을 법한 아이템 — 몬스터 없이 곳곳에 놓인 것도", docs/plans/rift_rooms.md, RF25).
## 챕터 "loot": [{item, count}] — 설계도 marks.loot의 같은 순서 칸 바닥에 놓인다(LootView가 그 아이템 그림을 바닥에 그린다).
## 그 칸이나 바로 옆(4방향)에서 살피면 줍는다 — 조건·판정 없음, 한 번뿐(챕터 세션과 함께 보관되니 되돌아가도 그대로, 다음 균열은 새로).
## 균열 밖으로 가지고 나갈 수 있는 보통 아이템이다. 가방에 자리가 없으면 그대로 둔다.


## 챕터를 만들 때 자리마다 물건을 놓는다(s.loot: Vector2i -> {item, count}).
static func place(s: ExploreSession, ch: Dictionary) -> void:
	var cells: Array = s.map.anchors.get("loot", [])
	var list := JsonUtil.get_array(ch, "loot")
	for i in mini(cells.size(), list.size()):
		var d: Dictionary = list[i] if list[i] is Dictionary else {}
		s.loot[cells[i]] = {"item": JsonUtil.get_str(d, "item"), "count": JsonUtil.get_int(d, "count", 1)}


## 지금 주울 수 있는 칸(선 칸 먼저, 그다음 4방향). 없으면 (-1, -1).
static func target(s: ExploreSession) -> Vector2i:
	if s.loot.is_empty():
		return Vector2i(-1, -1)
	if s.loot.has(s.pos):
		return s.pos
	for d in FloorMap.DIRS4:
		if s.loot.has(s.pos + d):
			return s.pos + d
	return Vector2i(-1, -1)


## 주울 것을 다뤘으면 true(가방이 차서 못 주웠어도).
static func run(s: ExploreSession) -> bool:
	var p := target(s)
	if p.x < 0:
		return false
	var d: Dictionary = s.loot[p]
	var item := str(d["item"])
	var n := int(d["count"])
	var name := DataNames.entry(s.db, "items", item)
	if not s.player.inventory.fits(item, n):
		s.message.emit("explore.scavenge_no_room", {"item": name}, "warn")
		return true
	s.loot.erase(p)
	s.player.inventory.add(item, n)
	s.message.emit("explore.loot_found" if n == 1 else "explore.loot_found_n", {"item": name, "n": n}, "good")
	s.tiles_changed.emit(Rect2i(p, Vector2i.ONE))
	return true


static func target_name(s: ExploreSession) -> String:
	var p := target(s)
	return DataNames.entry(s.db, "items", str((s.loot[p] as Dictionary)["item"])) if p.x >= 0 else ""
