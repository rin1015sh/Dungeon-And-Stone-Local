class_name CrossTerrain
extends RefCounted
## 1층 십자가의 동굴 지형(벽/바닥 격자)만 판다 — 고정 장소·타일 배치는 생성기(generators/crystal_cave.gd) 몫.
## 순서: 윤곽(팔 수 있는 칸) → 중심부 동굴 → 기념비 공터 → 등뼈 길 4개(기념비 → 포탈, 뒤로 가지 않음)
##       → 곁가지(갈림길·합류 — 막다른 길 없음) → 벽 깎기 → 포탈 공동 → 떨어진 굴 잇기/메우기 → 통로 폭 최소 2칸.
## 굴 폭: 붓 2~3칸(CaveCarver), 마지막에 GridWiden이 한 칸 폭 목을 없앤다.
## 값은 floors/*.json의 gen(설명은 그 _comment).


## cells(1 = 벽, 0 = 바닥, 크기 lay.side²)를 돌려준다.
static func build(lay: CrossLayout, g: Dictionary, rng: Rng) -> PackedByteArray:
	var carver := CaveCarver.new(lay.side, lay.side, rng)
	carver.wide3_chance = JsonUtil.get_float(g, "wide3_chance", 0.35)
	_outline(carver, lay, JsonUtil.get_int(g, "outline_jitter", 2), rng)
	_core_cave(carver, lay, g, rng)
	var plaza := JsonUtil.get_float(g, "center_radius", 5.0)
	carver.blob(lay.center, plaza, 0.0)
	var start_off := maxi(1, int(plaza) - 1)
	var lat_limit := maxi(1, lay.arm_half - JsonUtil.get_int(g, "outline_jitter", 2) - 3)
	for dir in CrossLayout.ARMS:
		var a := CrossLayout.axis(dir)
		carver.spine(lay.center + a * start_off, a, lay.core_half + lay.arm_length - lay.portal_inset - start_off,
			lat_limit, JsonUtil.get_dict(g, "spine"))
	for dir in CrossLayout.ARMS:
		_fill_arm(carver, lay, dir, JsonUtil.get_dict(g, "branches"), rng)
	_roughen(carver, JsonUtil.get_float(g, "roughen_chance", 0.15), rng)
	for dir in CrossLayout.ARMS:
		carver.blob(lay.portal_pos(dir), JsonUtil.get_float(g, "portal_room_radius", 2.5), 0.0)
	_connect_pockets(carver, lay.center, JsonUtil.get_int(g, "min_region", 20))
	carver.widen(JsonUtil.get_int(g, "widen_passes", 6))
	return carver.cells


## 팔 수 있는 칸: 중심부 정사각형 전체 + 팔(옆 폭은 칸마다 조금씩 흔들려 윤곽이 자연스럽다). 팔 끝 줄은 벽으로 남긴다.
static func _outline(carver: CaveCarver, lay: CrossLayout, jitter: int, rng: Rng) -> void:
	var core := lay.core_rect()
	for y in range(core.position.y, core.end.y):
		for x in range(core.position.x, core.end.x):
			carver.allowed[y * lay.side + x] = 1
	for dir in CrossLayout.ARMS:
		var a := CrossLayout.axis(dir)
		var l := CrossLayout.lateral(dir)
		var hw_left := lay.arm_half
		var hw_right := lay.arm_half
		for u in range(1, lay.arm_length):
			hw_left = clampi(hw_left + rng.randi_range(-1, 1), lay.arm_half - jitter, lay.arm_half)
			hw_right = clampi(hw_right + rng.randi_range(-1, 1), lay.arm_half - jitter, lay.arm_half)
			for v in range(-hw_right + 1, hw_left):
				var p := lay.center + a * (lay.core_half + u) + l * v
				carver.allowed[p.y * lay.side + p.x] = 1


## 중심부: 둥근 사각형 안에 셀룰러 오토마타 동굴(팔보다 트인 공동이 많다).
static func _core_cave(carver: CaveCarver, lay: CrossLayout, g: Dictionary, rng: Rng) -> void:
	var n := lay.core_half * 2 + 3
	var cells := GridAlgo.random_fill(n, n, JsonUtil.get_float(g, "core_fill_ratio", 0.45), rng)
	for i in JsonUtil.get_int(g, "core_smooth_steps", 4):
		cells = GridAlgo.smooth(cells, n, n)
	var r := float(lay.core_half) - 1.0
	for y in n:
		for x in n:
			var d := Vector2i(x, y) - Vector2i(n / 2, n / 2)
			var rounded := Vector2(d).length() * 0.45 + maxi(absi(d.x), absi(d.y)) * 0.55
			if cells[y * n + x] == 0 and rounded <= r:
				carver.carve(lay.center + d)


## 팔 하나를 곁가지로 채운다: 밀도(density)에 닿을 때까지 빈 땅을 골라 가장 가까운 굴에서 그쪽으로 뻗는다.
## 곁가지는 다른 굴에 닿으면 합류(순환)하고, 못 닿으면 가장 가까운 굴로 다시 이어진다(CaveCarver.branch — 막다른 길 없음).
## 합류한 자리에는 join_room_chance로 작은 공동.
static func _fill_arm(carver: CaveCarver, lay: CrossLayout, dir: String, b: Dictionary, rng: Rng) -> void:
	var rect := lay.arm_rect(dir)
	var target := int(rect.get_area() * JsonUtil.get_float(b, "density", 0.42))
	var steps := JsonUtil.get_array(b, "steps")
	var room := JsonUtil.get_array(b, "room_radius")
	for n in JsonUtil.get_int(b, "max_per_arm", 70):
		if n % 4 == 0 and carver.floor_count_in(rect) >= target:
			break
		# 빈 땅을 하나 골라 가장 가까운 길에서 그쪽으로 뻗는다(이미 굴이 많은 곳만 더 파이지 않게).
		var heading := CrossLayout.axis(dir)
		var from := CaveCarver.NONE
		var empty := carver.random_empty_in(rect, JsonUtil.get_int(b, "empty_clearance", 3))
		if empty != CaveCarver.NONE:
			from = carver.nearest_floor(empty, rect.size.x + rect.size.y)
			var d := empty - from
			heading = Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
		if from == CaveCarver.NONE:
			from = carver.random_floor_in(rect)
		if from == CaveCarver.NONE:
			break
		var length := rng.randi_range(int(steps[0]), int(steps[1])) if steps.size() == 2 else 20
		var joined := carver.branch(from, heading, length, b)
		if joined != CaveCarver.NONE and room.size() == 2 and rng.chance(JsonUtil.get_float(b, "join_room_chance", 0.2)):
			carver.blob(joined, rng.randf_range(float(room[0]), float(room[1])))


## anchor가 속한 영역에 모든 바닥을 잇는다: min_region 이상 영역은 팔 수 있는 칸으로만 굴을 내 잇고(tunnel),
## 작거나 잇지 못한 영역은 메운다. (GridAlgo.connect_regions와 달리 allowed 밖 — 십자가 바깥 — 을 파지 않는다)
static func _connect_pockets(carver: CaveCarver, anchor: Vector2i, min_region: int) -> void:
	var cells := carver.cells
	var w := carver.w
	var h := carver.h
	var info := GridAlgo.label_regions(cells, w, h)
	var labels: PackedInt32Array = info["labels"]
	var sizes: Array[int] = info["sizes"]
	var main := labels[anchor.y * w + anchor.x]
	if main < 0:
		return
	var main_cells: Array[Vector2i] = []
	var first_cell: Dictionary = {}
	for i in w * h:
		if labels[i] == main:
			main_cells.append(Vector2i(i % w, i / w))
		elif labels[i] >= 0 and not first_cell.has(labels[i]):
			first_cell[labels[i]] = Vector2i(i % w, i / w)
	for lab: int in first_cell:
		if sizes[lab] >= min_region:
			var from: Vector2i = first_cell[lab]
			var best := main_cells[0]
			for c in main_cells:
				if (c - from).length_squared() < (best - from).length_squared():
					best = c
			carver.tunnel(from, best)
	var reach := GridAlgo.label_regions(cells, w, h)
	var final_labels: PackedInt32Array = reach["labels"]
	var keep := final_labels[anchor.y * w + anchor.x]
	for i in w * h:
		if final_labels[i] >= 0 and final_labels[i] != keep:
			cells[i] = 1


## 바닥에 닿은 벽을 chance 확률로 조금씩 깎아 벽면을 불규칙하게(새 칸은 늘 기존 바닥 옆이라 연결 유지).
## 한 칸짜리 홈은 뒤의 widen이 2×2로 넓히거나 메운다. (cells는 참조로 넘어와 carver.cells가 바뀐다)
static func _roughen(carver: CaveCarver, chance: float, rng: Rng) -> void:
	var cells := carver.cells
	var w := carver.w
	var h := carver.h
	var allowed := carver.allowed
	var picks: Array[int] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if cells[i] == 0 or allowed[i] == 0:
				continue
			if cells[i - 1] == 0 or cells[i + 1] == 0 or cells[i - w] == 0 or cells[i + w] == 0:
				if rng.chance(chance):
					picks.append(i)
	for i in picks:
		cells[i] = 0
