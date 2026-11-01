class_name RiftLoot
extends RefCounted
## 균열에 놓인 물건(사용자 2026-10-30 "공간마다 있을 법한 아이템 — 몬스터 없이 곳곳에 놓인 것도", docs/plans/rift_rooms.md, RF25).
## 챕터 "loot": [{item, count}] — 설계도 marks.loot의 같은 순서 칸 바닥에 놓인다(LootView가 그 아이템 그림을 바닥에 그린다).
## 그 칸이나 바로 옆(4방향)에서 살피면 줍는다 — 조건·판정 없음, 한 번뿐(챕터 세션과 함께 보관되니 되돌아가도 그대로, 다음 균열은 새로).
## 장비·좋은 회복약은 상자에 담긴다(RiftChest — V25: 동전 던지기로 연다, 열린 상자는 빈 채 남는다).
## 균열 밖으로 가지고 나갈 수 있는 보통 아이템이다. 가방에 자리가 없으면 그대로 둔다.


## 챕터를 만들 때 자리마다 물건을 놓는다(s.loot: Vector2i -> {item, count, chest?, opened?}).
static func place(s: ExploreSession, ch: Dictionary) -> void:
	var cells: Array = s.map.anchors.get("loot", [])
	var list := JsonUtil.get_array(ch, "loot")
	var chests := RiftChest.pick(s.db, list)
	for i in mini(cells.size(), list.size()):
		var d: Dictionary = list[i] if list[i] is Dictionary else {}
		var e := {"item": JsonUtil.get_str(d, "item"), "count": JsonUtil.get_int(d, "count", 1)}
		if chests.has(i):
			e["chest"] = true
		s.loot[cells[i]] = e


## 지금 주울 수 있는 칸(선 칸 먼저, 그다음 4방향 — 열어 비운 상자는 빼고). 없으면 (-1, -1).
static func target(s: ExploreSession) -> Vector2i:
	if s.loot.is_empty():
		return Vector2i(-1, -1)
	for c: Vector2i in [s.pos, s.pos + FloorMap.DIRS4[0], s.pos + FloorMap.DIRS4[1], s.pos + FloorMap.DIRS4[2], s.pos + FloorMap.DIRS4[3]]:
		if s.loot.has(c) and not bool((s.loot[c] as Dictionary).get("opened", false)):
			return c
	return Vector2i(-1, -1)


## 주울 것을 다뤘으면 true(가방이 차서 못 주웠어도).
static func run(s: ExploreSession) -> bool:
	var p := target(s)
	if p.x < 0:
		return false
	var d: Dictionary = s.loot[p]
	if RiftChest.locked(d):
		return RiftChest.open(s, p)
	var item := str(d["item"])
	var n := int(d["count"])
	var name := DataNames.entry(s.db, "items", item)
	if not s.player.inventory.fits(item, n):
		s.message.emit("explore.scavenge_no_room", {"item": name}, "warn")
		return true
	s.loot.erase(p)
	s.player.inventory.add(item, n)
	s.message.emit(ItemInfo.got_key(n), {"item": name, "n": n}, "good")
	s.tiles_changed.emit(Rect2i(p, Vector2i.ONE))
	return true


static func target_name(s: ExploreSession) -> String:
	var p := target(s)
	if p.x < 0:
		return ""
	if RiftChest.locked(s.loot[p] as Dictionary):  # 상자 안은 열기 전에 알 수 없다
		return Strings.t("explore.chest")
	return DataNames.entry(s.db, "items", str((s.loot[p] as Dictionary)["item"]))
