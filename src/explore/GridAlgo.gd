class_name GridAlgo
extends RefCounted
## 층 생성기 공용 격자 알고리즘. cells: PackedByteArray(1 = 벽, 0 = 바닥), 너비 w × 높이 h.
## 모든 무작위는 인자로 받은 Rng를 쓴다(시드가 같으면 결과가 같다).


## 가장자리는 벽, 안쪽은 ratio 확률로 벽.
static func random_fill(w: int, h: int, ratio: float, rng: Rng) -> PackedByteArray:
	var cells := PackedByteArray()
	cells.resize(w * h)
	for y in h:
		for x in w:
			var edge := x == 0 or y == 0 or x == w - 1 or y == h - 1
			cells[y * w + x] = 1 if edge or rng.chance(ratio) else 0
	return cells


## 셀룰러 오토마타 한 단계(4-5 규칙): 주변 8칸 중 벽이 5개 이상이면 벽, 3개 이하면 바닥.
static func smooth(cells: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := cells.duplicate()
	for y in range(1, h - 1):
		var r := y * w
		for x in range(1, w - 1):
			var n := cells[r - w + x - 1] + cells[r - w + x] + cells[r - w + x + 1] \
				+ cells[r + x - 1] + cells[r + x + 1] \
				+ cells[r + w + x - 1] + cells[r + w + x] + cells[r + w + x + 1]
			if n > 4:
				out[r + x] = 1
			elif n < 4:
				out[r + x] = 0
	return out


## 원형으로 바닥을 판다(가장자리 한 칸은 남긴다).
static func carve_disc(cells: PackedByteArray, w: int, h: int, c: Vector2i, radius: float) -> void:
	var r := ceili(radius)
	for y in range(maxi(1, c.y - r), mini(h - 1, c.y + r + 1)):
		for x in range(maxi(1, c.x - r), mini(w - 1, c.x + r + 1)):
			if Vector2(x - c.x, y - c.y).length() <= radius:
				cells[y * w + x] = 0


## 4-연결 바닥 영역 라벨링. {"labels": PackedInt32Array(벽 = -1), "sizes": Array[int]}
static func label_regions(cells: PackedByteArray, w: int, h: int) -> Dictionary:
	var labels := PackedInt32Array()
	labels.resize(w * h)
	labels.fill(-1)
	var sizes: Array[int] = []
	for start in w * h:
		if cells[start] != 0 or labels[start] != -1:
			continue
		var label := sizes.size()
		var queue: Array[int] = [start]
		labels[start] = label
		var head := 0
		while head < queue.size():
			var i := queue[head]
			head += 1
			var x := i % w
			for j: int in [i - w, i + w, i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1]:
				if j >= 0 and j < w * h and cells[j] == 0 and labels[j] == -1:
					labels[j] = label
					queue.append(j)
		sizes.append(queue.size())
	return {"labels": labels, "sizes": sizes}


## a에서 b까지 1칸 폭 굴을 판다(축을 무작위로 번갈아 가며 → 구불구불).
static func carve_tunnel(cells: PackedByteArray, w: int, h: int, a: Vector2i, b: Vector2i, rng: Rng) -> void:
	var p := a
	var guard := w * h
	while p != b and guard > 0:
		guard -= 1
		cells[p.y * w + p.x] = 0
		var dx := signi(b.x - p.x)
		var dy := signi(b.y - p.y)
		if dx != 0 and (dy == 0 or rng.chance(0.5)):
			p.x += dx
		else:
			p.y += dy
		p = Vector2i(clampi(p.x, 1, w - 2), clampi(p.y, 1, h - 2))
	cells[b.y * w + b.x] = 0


## anchor가 속한 영역에 모든 바닥을 잇는다: min_region 이상인 영역은 굴로 잇고, 작은 영역은 메운다.
static func connect_regions(cells: PackedByteArray, w: int, h: int, anchor: Vector2i, min_region: int, rng: Rng) -> void:
	var info := label_regions(cells, w, h)
	var labels: PackedInt32Array = info["labels"]
	var sizes: Array[int] = info["sizes"]
	var main := labels[anchor.y * w + anchor.x]
	if main < 0:
		push_error("GridAlgo.connect_regions: 기준점이 벽이다")
		return
	var main_cells: Array[Vector2i] = []
	var first_cell: Dictionary = {}  # 라벨 -> 그 영역의 첫 칸
	for i in w * h:
		var lab := labels[i]
		if lab == main:
			main_cells.append(Vector2i(i % w, i / w))
		elif lab >= 0 and not first_cell.has(lab):
			first_cell[lab] = Vector2i(i % w, i / w)
	for lab: int in first_cell:
		if sizes[lab] < min_region:
			continue
		var from: Vector2i = first_cell[lab]
		carve_tunnel(cells, w, h, from, _nearest(main_cells, from), rng)
	for i in w * h:
		var lab := labels[i]
		if lab >= 0 and lab != main and sizes[lab] < min_region:
			cells[i] = 1


## 문자열 배열 도장의 크기.
static func stamp_size(stamp: Array) -> Vector2i:
	var w := 0
	for row: Variant in stamp:
		w = maxi(w, str(row).length())
	return Vector2i(w, stamp.size())


## 도장 안에서 anchor 글자의 위치(없으면 가운데).
static func stamp_anchor(stamp: Array, anchor: String) -> Vector2i:
	for y in stamp.size():
		var x := str(stamp[y]).find(anchor) if not anchor.is_empty() else -1
		if x >= 0:
			return Vector2i(x, y)
	var size := stamp_size(stamp)
	return Vector2i(size.x / 2, size.y / 2)


## 도장을 찍는다: 각 글자를 legend[글자]의 타일로 바꾼다. legend 값이 null이면 그 칸은 그대로.
static func apply_stamp(map: FloorMap, top_left: Vector2i, stamp: Array, legend: Dictionary) -> void:
	for y in stamp.size():
		var row := str(stamp[y])
		for x in row.length():
			var tile: Variant = legend.get(row[x])
			if tile != null:
				map.set_tile(top_left + Vector2i(x, y), str(tile))


static func _nearest(cells: Array[Vector2i], to: Vector2i) -> Vector2i:
	var best := cells[0]
	var best_d := (best - to).length_squared()
	for c in cells:
		var d := (c - to).length_squared()
		if d < best_d:
			best = c
			best_d = d
	return best
