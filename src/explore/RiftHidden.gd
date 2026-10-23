class_name RiftHidden
extends RefCounted
## 균열 챕터의 살필 수 있는 물체(RiftRun이 챕터를 만들 때 place, ExploreInteract가 E로 take).
## 챕터 "hidden": [{"id", "item", "tile", "message", "near_entry"}] — 방 안쪽에 물체(tile)를 두고 옆에서 E로 아이템을 얻는다(히든 피스).
##   near_entry: true면 시작 자리 가까이(빙하굴 빙정 연못).
##   "mural": true — 벽화(강철의 묘): 아이템 대신 이 균열 수수께끼(RiftRiddle)의 힌트를 읽는다. 벽화는 남고 다시 읽을 수 있다.

var at: Dictionary = {}      ## 이 챕터의 물체 칸 -> 정의
var taken: Dictionary = {}   ## 얻은 히든 피스 id -> true(균열 한 번 동안)
var under: Dictionary = {}   ## 물체 칸 -> 원래 타일(설계도 지도 — 가져간 뒤 되돌린다)


## 물체를 방 안쪽 칸(사방 8칸이 모두 바닥이고 조우·출구·시작 자리가 아닌 곳)에 둔다. 설계도 지도(map.anchors.hidden)면 그 자리에.
func place(cs: ExploreSession, ch: Dictionary, rng: Rng) -> void:
	at.clear()
	under.clear()
	var spots: Array = cs.map.anchors.get("hidden", [])
	var k := -1
	for h: Variant in JsonUtil.get_array(ch, "hidden"):
		var hd: Dictionary = h if h is Dictionary else {}
		k += 1
		if taken.has(JsonUtil.get_str(hd, "id")):
			continue
		if k < spots.size():  # 설계도 지도: 정해진 자리(분수대·책장·벽화 자리 — 벽 칸이어도 옆에서 살핀다)
			var sp: Vector2i = spots[k]
			under[sp] = cs.map.tile_id_at(sp)
			cs.map.set_tile(sp, JsonUtil.get_str(hd, "tile"))
			at[sp] = hd
			continue
		var cells: Array[Vector2i] = []
		for i in cs.map.tiles.size():
			var p := cs.map.pos_of(i)
			if RiftHazards._interior(cs.map, p) and not cs.map.slots.has(p) and p != cs.map.entry and cs.map.portal_at(p).is_empty() \
					and not at.has(p) and Vector2(p - cs.map.entry).length() > 3.0:
				cells.append(p)
		var near := cells.filter(func(p: Vector2i) -> bool: return Vector2(p - cs.map.entry).length() <= float(cs.db.bal("rift.near_entry_m", 8)))
		if JsonUtil.get_bool(hd, "near_entry") and not near.is_empty():
			cells.assign(near)
		if cells.is_empty():
			continue
		var p: Vector2i = rng.pick(cells)
		cs.map.set_tile(p, JsonUtil.get_str(hd, "tile"))
		at[p] = hd


## 물체를 살핀다(옆 칸 p). 무언가 했으면 true.
func take(cs: ExploreSession, p: Vector2i, floor_tile: String, riddle: RiftRiddle) -> bool:
	var hd: Dictionary = at.get(p, {})
	if hd.is_empty():
		return false
	if JsonUtil.get_bool(hd, "mural"):
		if riddle == null:
			return false
		var hint := riddle.read_mural(cs.player, p)
		cs.message.emit(JsonUtil.get_str(hd, "message", "explore.mural_read"), {"hint": hint}, "system")
		return true
	var item := JsonUtil.get_str(hd, "item")
	if not cs.player.inventory.fits(item, 1):  # 가방이 찼으면 그 자리에 둔다(탈출에 필요한 물건을 잃지 않게)
		cs.message.emit("explore.hidden_no_room", {"item": DataNames.entry(cs.db, "items", item)}, "warn")
		return true
	at.erase(p)
	taken[JsonUtil.get_str(hd, "id")] = true
	cs.map.set_tile(p, str(under.get(p, floor_tile)))
	cs.tiles_changed.emit(Rect2i(p, Vector2i.ONE))
	cs.player.inventory.add(item, 1)
	cs.message.emit(JsonUtil.get_str(hd, "message", "explore.hidden_found"), {"item": DataNames.entry(cs.db, "items", item)}, "good")
	cs.refresh_view()
	return true
