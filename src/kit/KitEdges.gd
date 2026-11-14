class_name KitEdges
extends RefCounted
## 던전 에셋 키트의 가장자리 깔기(에셋 라이브러리 — docs/asset_library/GENERATION_GUIDE.md §2): 바닥 번짐 띠 · 물가 테 · 낭떠러지.
## 번짐 순위(kit.json fringe.rank)가 높은 바닥이 이웃 칸으로 스며든다 — 물 · 용암이 가장 낮아 물가는 뭍이 덮는다.
## 타일은 DungeonKit.tileset()의 소스 SRC_FRINGE(번짐 띠 · 물가 테 · 낭떠러지 턱) · SRC_DROP(낭떠러지 벽 64 × 160)에 있다.

const DIRS := [["n", Vector2i.UP], ["e", Vector2i.RIGHT], ["s", Vector2i.DOWN], ["w", Vector2i.LEFT]]
const DIAGS := [["ne", Vector2i(1, -1), 0, 1], ["se", Vector2i(1, 1), 1, 2], ["sw", Vector2i(-1, 1), 2, 3], ["nw", Vector2i(-1, -1), 3, 0]]  # 이름 · 방향 · 낀 두 변


static func rank(kit: DungeonKit, ground: String) -> int:
	var f: Dictionary = kit.data.get("fringe", {})
	return int((f.get("rank", {}) as Dictionary).get(ground.get_slice(".", 0), f.get("default_rank", 1)))


## 바닥 id → 그 바닥의 번짐 띠 에셋 id(없으면 스며들지 않는 바닥).
static func fringe_ids(kit: DungeonKit) -> Dictionary:
	var out := {}
	for id in kit.ids("floor", "decal", "fringe"):
		out[String((kit.info(id).get("meta", {}) as Dictionary).get("of", ""))] = id
	return out


## floor_of = {칸: 바닥 참조("ground_grass" · "ground_lava.poison")}. layers = TileMapLayer 넷(북 · 동 · 남 · 서 변 — 대각 모서리는 빈 변의 층을 쓴다).
## rims = 물가 · 용암가 테를 깔 층 넷(없으면 테 없이). 층은 바닥 위 · 물건 아래에 둔다.
static func put_fringe(kit: DungeonKit, layers: Array, floor_of: Dictionary, rims: Array = []) -> void:
	kit.tileset()
	var of := fringe_ids(kit)
	var liquid: Dictionary = (kit.data.get("fringe", {}) as Dictionary).get("liquid", {})
	for cell: Vector2i in floor_of:
		var me := String(floor_of[cell])
		var mine := rank(kit, me)
		var edge := [false, false, false, false]
		var shore := [false, false, false, false]
		var wet := String(liquid.get(me.get_slice(".", 0), ""))
		if wet == "lava" and me.ends_with(".poison"):
			wet = "poison"
		for i in 4:
			var other := String(floor_of.get(cell + (DIRS[i][1] as Vector2i), ""))
			if other.is_empty():
				continue
			var oid := other.get_slice(".", 0)
			if not wet.is_empty() and oid != me.get_slice(".", 0):
				shore[i] = true
				if rims.size() == 4:
					_put(kit, rims[i], cell, "shore_rim.%s_%s" % [wet, DIRS[i][0]])
			if rank(kit, oid) > mine and of.has(oid):
				edge[i] = true
				_put(kit, layers[i], cell, "%s.%s_%s" % [of[oid], DIRS[i][0], "a" if posmod(cell.x * 7 + cell.y * 13, 2) == 0 else "b"])
		for d: Array in DIAGS:
			var other := String(floor_of.get(cell + (d[1] as Vector2i), ""))
			if other.is_empty():
				continue
			var oid := other.get_slice(".", 0)
			if not wet.is_empty() and oid != me.get_slice(".", 0) and not shore[d[2]] and not shore[d[3]] and rims.size() == 4:
				_put(kit, rims[d[2]], cell, "shore_rim.%s_%s" % [wet, d[0]])
			if rank(kit, oid) > mine and of.has(oid) and not edge[d[2]] and not edge[d[3]]:
				_put(kit, layers[d[2]], cell, "%s.%s" % [of[oid], d[0]])


## 낭떠러지: voids = {빈 칸: true}, floor_cells = {바닥 칸: …}. 북쪽이 바닥인 빈 칸에는 아래로 떨어지는 암벽(drops 층 — 2.5칸),
## 옆 · 대각이 바닥인 빈 칸에는 부서진 턱(lips 층). kind = cave · sandstone · ice · basalt · stone.
static func put_cliffs(kit: DungeonKit, drops: TileMapLayer, lips: TileMapLayer, voids: Dictionary, floor_cells: Dictionary, kind: String = "cave") -> void:
	kit.tileset()
	var face: Dictionary = kit.tile_of("cliff_drop.%s" % kind)
	for cell: Vector2i in voids:
		if floor_cells.has(cell + Vector2i.UP) and not face.is_empty():
			drops.set_cell(cell, DungeonKit.SRC_DROP, (face["base"] as Vector2i) + Vector2i(posmod(cell.x, 4), 0))
			continue
		var ab := "a" if posmod(cell.x * 5 + cell.y * 11, 2) == 0 else "b"
		if floor_cells.has(cell + Vector2i.RIGHT):
			_put(kit, lips, cell, "cliff_lip.e_" + ab)
		elif floor_cells.has(cell + Vector2i.LEFT):
			_put(kit, lips, cell, "cliff_lip.w_" + ab)
		elif floor_cells.has(cell + Vector2i(1, -1)) and not voids.has(cell + Vector2i.UP):
			_put(kit, lips, cell, "cliff_lip.ne")
		elif floor_cells.has(cell + Vector2i(-1, -1)) and not voids.has(cell + Vector2i.UP):
			_put(kit, lips, cell, "cliff_lip.nw")


static func _put(kit: DungeonKit, layer: TileMapLayer, cell: Vector2i, key: String) -> void:
	var t: Dictionary = kit.tile_of(key)
	if not t.is_empty():
		layer.set_cell(cell, int(t["source"]), t["base"] as Vector2i)
