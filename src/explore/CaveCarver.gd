class_name CaveCarver
extends RefCounted
## 스파게티 동굴 파기(층 생성기 공용). cells: 1 = 벽, 0 = 바닥. allowed: 1 = 팔 수 있는 칸.
## 모든 걸음은 4방향이다(대각선으로 맞붙은 틈은 지나갈 수 없다 — Kinematics). 그래서 판 칸은 늘 서로 4-연결이다.
## 모든 무작위는 생성자에서 받은 Rng를 쓴다.

const NONE := Vector2i(-1, -1)

var cells: PackedByteArray
var allowed: PackedByteArray
var w: int = 0
var h: int = 0
var wide_chance: float = 0.0  ## 걸음마다 옆 칸까지 넓혀 2칸 폭으로 팔 확률

var _rng: Rng


func _init(p_w: int, p_h: int, rng: Rng) -> void:
	w = p_w
	h = p_h
	_rng = rng
	cells = PackedByteArray()
	cells.resize(w * h)
	cells.fill(1)
	allowed = PackedByteArray()
	allowed.resize(w * h)


func can(p: Vector2i) -> bool:
	return p.x > 0 and p.y > 0 and p.x < w - 1 and p.y < h - 1 and allowed[p.y * w + p.x] != 0


func is_floor(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and cells[p.y * w + p.x] == 0


## p를 판다. side가 주어지면 wide_chance 확률로 옆 칸도 판다. 옆 칸을 팠으면 그 칸, 아니면 NONE.
func carve(p: Vector2i, side: Vector2i = Vector2i.ZERO) -> Vector2i:
	if can(p):
		cells[p.y * w + p.x] = 0
	if side != Vector2i.ZERO and _rng.chance(wide_chance) and can(p + side):
		cells[(p + side).y * w + (p + side).x] = 0
		return p + side
	return NONE


## 둥글고 울퉁불퉁한 작은 공동. jitter = 0이면 모양이 늘 같다(고정 장소용).
func blob(c: Vector2i, radius: float, jitter: float = 0.35) -> void:
	var r := ceili(radius + jitter) + 1
	for y in range(c.y - r, c.y + r + 1):
		for x in range(c.x - r, c.x + r + 1):
			var p := Vector2i(x, y)
			var lim := radius + (_rng.randf_range(-jitter, jitter) if jitter > 0.0 else 0.0)
			if Vector2(p - c).length() <= lim:
				carve(p)


## 등뼈 길: start에서 axis 쪽으로 length칸. **절대 뒤로 가지 않는다** → "나침반 방향만 지키면 끝에 닿는다".
## 직진·옆걸음·계단(대각) 구간을 번갈아 급커브가 많고, 옆으로는 중심선에서 ±lat_limit 안.
## 끝에서 중심선으로 돌아와 start + axis * length에 닿는다.
## p: {"outward_run", "side_run", "stair_run", "long_run", "long_run_chance", "weights": {"out", "side", "stair"}}
func spine(start: Vector2i, axis: Vector2i, length: int, lat_limit: int, p: Dictionary) -> void:
	var lat := Vector2i(-axis.y, axis.x)
	var wt := JsonUtil.get_dict(p, "weights")
	var weights := [JsonUtil.get_float(wt, "out", 1.0), JsonUtil.get_float(wt, "side", 1.0), JsonUtil.get_float(wt, "stair", 1.0)]
	var u := 0
	var v := 0
	var last := -1
	carve(start, lat)
	while u < length:
		var kind := _rng.weighted_index(weights)
		if kind == 0 and last == 0:
			kind = 1  # 직진 두 번 연속 금지 → 긴 직선이 드물다
		last = kind
		if kind == 0:
			var n := _range(p, "long_run", 6, 9) if _rng.chance(JsonUtil.get_float(p, "long_run_chance")) else _range(p, "outward_run", 2, 4)
			for i in mini(n, length - u):
				u += 1
				carve(start + axis * u + lat * v, lat)
		elif kind == 1:
			var dir := _side_dir(v, lat_limit)
			for i in _range(p, "side_run", 2, 7):
				if absi(v + dir) > lat_limit:
					break
				v += dir
				carve(start + axis * u + lat * v, axis)
		else:
			var dir := _side_dir(v, lat_limit)
			for i in _range(p, "stair_run", 2, 5):
				if u >= length:
					break
				u += 1
				carve(start + axis * u + lat * v, lat)
				if absi(v + dir) <= lat_limit:
					v += dir
					carve(start + axis * u + lat * v, axis)
	while v != 0:
		v -= signi(v)
		carve(start + axis * u + lat * v, axis)


## 곁가지: from에서 heading 쪽으로 치우쳐 구간마다 방향을 꺾으며(급커브) steps칸.
## 이미 판 다른 길에 닿으면 합류(순환 경로)하고 멈춘다. → {"end": 마지막 칸, "joined": bool, "trail": Dictionary}
## p: {"seg_run": [min, max], "heading_weights": [앞, 왼, 오른, 뒤], "join_after": int}
func branch(from: Vector2i, heading: Vector2i, steps: int, p: Dictionary) -> Dictionary:
	var lat := Vector2i(-heading.y, heading.x)
	var dirs: Array[Vector2i] = [heading, lat, -lat, -heading]
	var hw := JsonUtil.get_array(p, "heading_weights")
	if hw.size() != 4:
		hw = [0.4, 0.25, 0.25, 0.1]
	var join_after := JsonUtil.get_int(p, "join_after", 4)
	var trail := {from: true}
	var cur := from
	var walked := 0
	var dir: Vector2i = dirs[maxi(0, _rng.weighted_index(hw))]
	while walked < steps:
		var moved := false
		for i in _range(p, "seg_run", 2, 6):
			var nxt := cur + dir
			if not can(nxt):
				break
			if walked >= join_after and ((is_floor(nxt) and not trail.has(nxt)) or _touches_other(nxt, cur, trail)):
				carve(nxt)  # 다른 길에 붙었다 → 합류. 나란히 붙어 달리며 넓은 굴이 되지 않게 여기서 멈춘다.
				return {"end": nxt, "joined": true, "trail": trail}
			var extra := carve(nxt, Vector2i(-dir.y, dir.x))
			if extra != NONE:
				trail[extra] = true
			trail[nxt] = true
			cur = nxt
			walked += 1
			moved = true
			if walked >= steps:
				break
		var nd := dir
		for t in 6:
			nd = dirs[maxi(0, _rng.weighted_index(hw))]
			if nd != dir and nd != -dir:
				break
		if not moved and nd == dir:
			break  # 막혀서 꺾을 곳도 없다
		dir = nd
	return {"end": cur, "joined": false, "trail": trail}


## a에서 b까지 지그재그로 판다(팔 수 없는 칸은 다른 축으로 돌아간다). 닿았으면 true.
func tunnel(a: Vector2i, b: Vector2i) -> bool:
	var p := a
	for guard in (absi(b.x - a.x) + absi(b.y - a.y)) * 3 + 4:
		if p == b:
			return true
		var options: Array[Vector2i] = []
		if p.x != b.x and can(p + Vector2i(signi(b.x - p.x), 0)):
			options.append(Vector2i(signi(b.x - p.x), 0))
		if p.y != b.y and can(p + Vector2i(0, signi(b.y - p.y))):
			options.append(Vector2i(0, signi(b.y - p.y)))
		if options.is_empty():
			return false
		var d: Vector2i = _rng.pick(options)
		p += d
		carve(p, Vector2i(-d.y, d.x))
	return p == b


## anchor가 속한 영역에 모든 바닥을 잇는다: min_region 이상 영역은 팔 수 있는 칸으로만 굴을 내 잇고(tunnel),
## 작거나 잇지 못한 영역은 메운다. (GridAlgo.connect_regions와 달리 allowed 밖 — 십자가 바깥 — 을 파지 않는다)
func connect_pockets(anchor: Vector2i, min_region: int) -> void:
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
			tunnel(from, best)
	# 끝까지 이어지지 않은 것(작은 영역·막힌 굴)은 메운다
	var reach := GridAlgo.label_regions(cells, w, h)
	var final_labels: PackedInt32Array = reach["labels"]
	var keep := final_labels[anchor.y * w + anchor.x]
	for i in w * h:
		if final_labels[i] >= 0 and final_labels[i] != keep:
			cells[i] = 1


## 바닥에 닿은 벽을 chance 확률로 조금씩 깎아 벽면을 불규칙하게(한 번만 — 새 칸은 늘 기존 바닥 옆이라 연결 유지).
func roughen(chance: float) -> void:
	var picks: Array[int] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var i := y * w + x
			if cells[i] == 0 or allowed[i] == 0:
				continue
			if cells[i - 1] == 0 or cells[i + 1] == 0 or cells[i - w] == 0 or cells[i + w] == 0:
				if _rng.chance(chance):
					picks.append(i)
	for i in picks:
		cells[i] = 0


## rect 안의 무작위 바닥 칸(tries번 뽑아 못 찾으면 NONE).
func random_floor_in(rect: Rect2i, tries: int = 60) -> Vector2i:
	for t in tries:
		var p := Vector2i(_rng.randi_range(rect.position.x, rect.end.x - 1), _rng.randi_range(rect.position.y, rect.end.y - 1))
		if is_floor(p):
			return p
	return NONE


## rect 안에서 바닥이 clear칸 안에 하나도 없는 팔 수 있는 칸(빈 땅). 못 찾으면 NONE.
func random_empty_in(rect: Rect2i, clear: int, tries: int = 40) -> Vector2i:
	for t in tries:
		var p := Vector2i(_rng.randi_range(rect.position.x, rect.end.x - 1), _rng.randi_range(rect.position.y, rect.end.y - 1))
		if can(p) and nearest_floor(p, clear) == NONE:
			return p
	return NONE


## c에서 체비셰프 거리 max_r 안의 가장 가까운 바닥(같은 거리면 먼저 찾은 것).
func nearest_floor(c: Vector2i, max_r: int) -> Vector2i:
	if is_floor(c):
		return c
	for r in range(1, max_r + 1):
		for x in range(c.x - r, c.x + r + 1):
			for y: int in [c.y - r, c.y + r]:
				if is_floor(Vector2i(x, y)):
					return Vector2i(x, y)
		for y in range(c.y - r + 1, c.y + r):
			for x: int in [c.x - r, c.x + r]:
				if is_floor(Vector2i(x, y)):
					return Vector2i(x, y)
	return NONE


func floor_count_in(rect: Rect2i) -> int:
	var n := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if cells[y * w + x] == 0:
				n += 1
	return n


## p 둘레(4방향, 막 떠나온 칸 제외)에 이 곁가지가 판 것이 아닌 바닥이 있는가.
func _touches_other(p: Vector2i, came_from: Vector2i, trail: Dictionary) -> bool:
	for d: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var q := p + d
		if q != came_from and is_floor(q) and not trail.has(q):
			return true
	return false


func _side_dir(v: int, lat_limit: int) -> int:
	if v == 0:
		return 1 if _rng.chance(0.5) else -1
	var toward := 0.5 + 0.4 * absf(float(v)) / maxf(1.0, float(lat_limit))
	return -signi(v) if _rng.chance(toward) else signi(v)


func _range(p: Dictionary, key: String, lo: int, hi: int) -> int:
	var r := JsonUtil.get_array(p, key)
	if r.size() == 2:
		return _rng.randi_range(int(r[0]), int(r[1]))
	return _rng.randi_range(lo, hi)
