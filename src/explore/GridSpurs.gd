class_name GridSpurs
extends RefCounted
## 막다른 곁가지(spur) 찾기(층 생성기·검사 공용). cells: 1 = 벽, 0 = 바닥.
## 2×2 바닥 블록을 마디로 보고(통로 폭 ≥ 2), 이어진 블록이 하나 이하인 블록을 거듭 깎아 낸다(거점 둘레 블록은 남긴다).
## 남은 블록 = 순환로와 거점 사이 길. 남은 블록이 덮지 못하는 바닥 칸 = 막다른 곳.
## 블록 이음: 상하좌우 + 대각선(사이의 상하좌우 블록이 처음부터 없을 때만 — 한 칸을 함께 쓰는 대각 이음은 걸어서 지나갈 수 있지만,
## 모퉁이에서 삼각형 고리를 만들어 막다른 길을 숨기지 않게).

const HUB_RADIUS := 3


## 막다른 바닥 칸 표시(1 = 막다른 곳).
static func spur_cells(cells: PackedByteArray, w: int, h: int, hubs: Array[Vector2i]) -> PackedByteArray:
	var n := w * h
	var alive := PackedByteArray()
	alive.resize(n)
	for y in range(0, h - 1):
		for x in range(0, w - 1):
			var b := y * w + x
			if cells[b] == 0 and cells[b + 1] == 0 and cells[b + w] == 0 and cells[b + w + 1] == 0:
				alive[b] = 1
	var start := alive.duplicate()
	var degree := PackedInt32Array()
	degree.resize(n)
	var queue: Array[int] = []
	for b in n:
		if alive[b] != 0:
			degree[b] = _links(b, w, start, alive).size()
			if degree[b] <= 1 and not _near_hub(b, w, hubs):
				queue.append(b)
	var head := 0
	while head < queue.size():
		var b := queue[head]
		head += 1
		if alive[b] == 0:
			continue
		var links := _links(b, w, start, alive)
		alive[b] = 0
		for c in links:
			degree[c] -= 1
			if degree[c] <= 1 and not _near_hub(c, w, hubs):
				queue.append(c)
	var out := PackedByteArray()
	out.resize(n)
	for i in n:
		if cells[i] == 0:
			out[i] = 1
	for b in n:
		if alive[b] != 0:
			out[b] = 0
			out[b + 1] = 0
			out[b + w] = 0
			out[b + w + 1] = 0
	return out


## 가장 큰 막다른 덩어리의 칸 수.
static func max_spur(cells: PackedByteArray, w: int, h: int, hubs: Array[Vector2i]) -> int:
	var spurs := spur_cells(cells, w, h, hubs)
	var inv := PackedByteArray()
	inv.resize(spurs.size())
	for i in spurs.size():
		inv[i] = 0 if spurs[i] != 0 else 1
	var biggest := 0
	for s: int in GridAlgo.label_regions(inv, w, h)["sizes"]:
		biggest = maxi(biggest, s)
	return biggest


static func _links(b: int, w: int, start: PackedByteArray, alive: PackedByteArray) -> Array[int]:
	var out: Array[int] = []
	var n := alive.size()
	for d: int in [-1, 1, -w, w]:
		var c := b + d
		if c >= 0 and c < n and alive[c] != 0:
			out.append(c)
	for dy: int in [-1, 1]:
		for dx: int in [-1, 1]:
			var c := b + dy * w + dx
			if c >= 0 and c < n and alive[c] != 0 and start[b + dx] == 0 and start[b + dy * w] == 0:
				out.append(c)
	return out


static func _near_hub(b: int, w: int, hubs: Array[Vector2i]) -> bool:
	var p := Vector2i(b % w, b / w)
	for hub in hubs:
		if absi(p.x - hub.x) <= HUB_RADIUS and absi(p.y - hub.y) <= HUB_RADIUS:
			return true
	return false
