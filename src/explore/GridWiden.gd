class_name GridWiden
extends RefCounted
## 통로 폭 최소 2칸 맞추기(층 생성기 공용). cells: 1 = 벽, 0 = 바닥, can: 1 = 벽을 바닥으로(또는 막다른 칸을 벽으로) 바꿔도 되는 칸.
## 규칙: 4방향으로 이웃한 두 바닥 칸마다 둘을 함께 품는 2×2 바닥 블록이 하나는 있어야 한다
##       (= 한 칸 폭 통로·목이 없다. 3/4 시점에서 가로 통로가 남쪽 벽 윗면에 가려 안 보이는 일도 없다).
## 없으면 그 변 양옆의 2×2 블록 중 덜 파도 되는(그리고 팔 수 있는) 쪽을 판다. 둘 다 못 파면 fill일 때 막다른 한 칸을 메운다.


## 고치고 남은 좁은 변의 수를 돌려준다(0이면 통과).
static func widen(cells: PackedByteArray, can: PackedByteArray, w: int, h: int, passes: int, fill: bool) -> int:
	for pass_i in passes:
		var changed := false
		for y in range(1, h - 1):
			for x in range(1, w - 1):
				var i := y * w + x
				if cells[i] != 0:
					continue
				if cells[i + 1] == 0 and not (_open(cells, i - w, w) or _open(cells, i, w)):
					if _fix(cells, can, w, [i - w, i]) or (fill and _fill_leaf(cells, can, w, [i, i + 1])):
						changed = true
				if cells[i] == 0 and cells[i + w] == 0 and not (_open(cells, i - 1, w) or _open(cells, i, w)):
					if _fix(cells, can, w, [i - 1, i]) or (fill and _fill_leaf(cells, can, w, [i, i + w])):
						changed = true
		if not changed:
			break
	return count_narrow(cells, w, h)


## 2×2 블록에 함께 들지 못하는 이웃 바닥 쌍의 수.
static func count_narrow(cells: PackedByteArray, w: int, h: int) -> int:
	var n := 0
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if cells[i] != 0:
				continue
			if cells[i + 1] == 0 and not (_open(cells, i - w, w) or _open(cells, i, w)):
				n += 1
			if cells[i + w] == 0 and not (_open(cells, i - 1, w) or _open(cells, i, w)):
				n += 1
	return n


## 지도의 걷는 칸으로 cells(0 = 걷는 칸)를 만든다.
static func walk_cells(map: FloorMap) -> PackedByteArray:
	var cells := PackedByteArray()
	cells.resize(map.width * map.height)
	for i in cells.size():
		cells[i] = 0 if map.defs[map.tiles[i]].walkable else 1
	return cells


## 왼쪽 위가 b인 2×2 블록이 모두 바닥인가.
static func _open(cells: PackedByteArray, b: int, w: int) -> bool:
	return cells[b] == 0 and cells[b + 1] == 0 and cells[b + w] == 0 and cells[b + w + 1] == 0


static func _fix(cells: PackedByteArray, can: PackedByteArray, w: int, blocks: Array) -> bool:
	var best := -1
	var best_cost := 5
	for b: int in blocks:
		var cost := 0
		var ok := true
		for j: int in [b, b + 1, b + w, b + w + 1]:
			if cells[j] != 0:
				if can[j] == 0:
					ok = false
					break
				cost += 1
		if ok and cost < best_cost:
			best = b
			best_cost = cost
	if best < 0:
		return false
	for j: int in [best, best + 1, best + w, best + w + 1]:
		cells[j] = 0
	return true


## 둘 중 바닥 이웃이 하나뿐인(막다른) 칸을 메운다 — 연결을 끊지 않는다.
static func _fill_leaf(cells: PackedByteArray, can: PackedByteArray, w: int, pair: Array) -> bool:
	for i: int in pair:
		if can[i] == 0:
			continue
		var n := int(cells[i - 1] == 0) + int(cells[i + 1] == 0) + int(cells[i - w] == 0) + int(cells[i + w] == 0)
		if n <= 1:
			cells[i] = 1
			return true
	return false
