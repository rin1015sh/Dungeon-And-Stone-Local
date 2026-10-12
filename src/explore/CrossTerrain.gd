class_name CrossTerrain
extends RefCounted
## 1층 십자가의 동굴 지형(벽/바닥 격자)만 판다 — 고정 장소·타일 배치는 생성기(generators/crystal_cave.gd) 몫.
## 순서: 윤곽(팔 수 있는 칸) → 중심부 동굴 → 기념비 공터 → 등뼈 길 4개(기념비 → 포탈, 뒤로 가지 않음)
##       → 곁가지(갈림길·막다른 길·합류) → 벽 깎기 → 포탈 공동 → 떨어진 굴 잇기/메우기.
## 값은 floors/*.json의 gen(설명은 그 _comment).


## cells(1 = 벽, 0 = 바닥, 크기 lay.side²)를 돌려준다.
static func build(lay: CrossLayout, g: Dictionary, rng: Rng) -> PackedByteArray:
	var carver := CaveCarver.new(lay.side, lay.side, rng)
	carver.wide_chance = JsonUtil.get_float(g, "wide_chance", 0.4)
	_outline(carver, lay, JsonUtil.get_int(g, "outline_jitter", 2), rng)
	_core_cave(carver, lay, g, rng)
	var plaza := JsonUtil.get_float(g, "center_radius", 5.0)
	carver.blob(lay.center, plaza, 0.0)
	var start_off := maxi(1, int(plaza) - 1)
	var lat_limit := maxi(1, lay.arm_half - JsonUtil.get_int(g, "outline_jitter", 2) - 2)
	for dir in CrossLayout.ARMS:
		var a := CrossLayout.axis(dir)
		carver.spine(lay.center + a * start_off, a, lay.core_half + lay.arm_length - lay.portal_inset - start_off,
			lat_limit, JsonUtil.get_dict(g, "spine"))
	for dir in CrossLayout.ARMS:
		_fill_arm(carver, lay, dir, JsonUtil.get_dict(g, "branches"), rng)
	carver.roughen(JsonUtil.get_float(g, "roughen_chance", 0.15))
	for dir in CrossLayout.ARMS:
		carver.blob(lay.portal_pos(dir), JsonUtil.get_float(g, "portal_room_radius", 2.5), 0.0)
	carver.connect_pockets(lay.center, JsonUtil.get_int(g, "min_region", 20))
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


## 팔 하나를 곁가지로 채운다: 밀도(density)에 닿을 때까지 기존 바닥에서 바깥쪽으로 치우친 굴을 뻗는다.
## 다른 굴에 닿으면 합류(순환), 아니면 loop_chance로 근처 길에 다시 잇거나, 막다른 길 끝에 작은 공동.
static func _fill_arm(carver: CaveCarver, lay: CrossLayout, dir: String, b: Dictionary, rng: Rng) -> void:
	var rect := lay.arm_rect(dir)
	var target := int(rect.get_area() * JsonUtil.get_float(b, "density", 0.42))
	var steps := JsonUtil.get_array(b, "steps")
	var reach := JsonUtil.get_array(b, "loop_reach")
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
		var res := carver.branch(from, heading, length, b)
		if bool(res["joined"]):
			continue
		var end: Vector2i = res["end"]
		if rng.chance(JsonUtil.get_float(b, "loop_chance", 0.35)) and reach.size() == 2:
			_loop_back(carver, end, res["trail"], int(reach[0]), int(reach[1]), rng)
		elif rng.chance(JsonUtil.get_float(b, "dead_end_room_chance", 0.3)) and room.size() == 2:
			carver.blob(end, rng.randf_range(float(room[0]), float(room[1])))


## 막다른 끝을 lo~hi칸 떨어진 다른 길에 잇는다(순환 경로).
static func _loop_back(carver: CaveCarver, end: Vector2i, trail: Dictionary, lo: int, hi: int, rng: Rng) -> void:
	for t in 24:
		var q := end + Vector2i(rng.randi_range(-hi, hi), rng.randi_range(-hi, hi))
		if carver.is_floor(q) and not trail.has(q) and absi(q.x - end.x) + absi(q.y - end.y) >= lo:
			carver.tunnel(end, q)
			return
