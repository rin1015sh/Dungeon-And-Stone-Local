class_name CaveCarver
extends RefCounted
## 스파게티 동굴 파기(층 생성기 공용). cells: 1 = 벽, 0 = 바닥. allowed: 1 = 팔 수 있는 칸.
## 굴은 폭 2~3칸 정사각 붓(brush)으로 판다 — 붓이 걸음마다 통째로 찍혀서 꺾이는 곳에서도 폭이 줄지 않는다.
## 모든 걸음은 4방향(대각선 틈은 지나갈 수 없다 — Kinematics)이라 판 칸은 늘 4-연결이다.
## 곁가지는 반드시 다른 길에 다시 이어진다(막다른 길 없음). 못 이으면 판 것을 되돌린다.
## 모든 무작위는 생성자에서 받은 Rng를 쓴다.

const NONE := Vector2i(-1, -1)
const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

var cells: PackedByteArray
var allowed: PackedByteArray
var w: int = 0
var h: int = 0
var brush: int = 2               ## 지금 붓 폭(2 또는 3)
var wide3_chance: float = 0.35   ## 구간마다 붓을 3칸으로 할 확률(아니면 2칸)

var _rng: Rng
var _log: Array[int] = []        ## 기록 중이면 새로 판 칸(되돌리기용)
var _logging: bool = false


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


## 한 칸을 판다(팔 수 있을 때만).
func carve(p: Vector2i) -> void:
	if can(p) and cells[p.y * w + p.x] != 0:
		cells[p.y * w + p.x] = 0
		if _logging:
			_log.append(p.y * w + p.x)


## 구간마다 붓 폭을 새로 고른다.
func pick_brush() -> void:
	brush = 3 if _rng.chance(wide3_chance) else 2


## p를 기준으로 붓이 덮는 칸들(2칸: p와 오른쪽·아래, 3칸: p 둘레 3×3).
func footprint(p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var lo := -1 if brush == 3 else 0
	for dy in range(lo, lo + brush):
		for dx in range(lo, lo + brush):
			out.append(p + Vector2i(dx, dy))
	return out


func fits(p: Vector2i) -> bool:
	for q in footprint(p):
		if not can(q):
			return false
	return true


func paint(p: Vector2i) -> void:
	for q in footprint(p):
		carve(q)


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
	pick_brush()
	paint(start)
	while u < length:
		pick_brush()
		var kind := _rng.weighted_index(weights)
		if kind == 0 and last == 0:
			kind = 1  # 직진 두 번 연속 금지 → 긴 직선이 드물다
		last = kind
		if kind == 0:
			var n := _range(p, "long_run", 6, 9) if _rng.chance(JsonUtil.get_float(p, "long_run_chance")) else _range(p, "outward_run", 2, 4)
			for i in mini(n, length - u):
				u += 1
				paint(start + axis * u + lat * v)
		elif kind == 1:
			var dir := _side_dir(v, lat_limit)
			for i in _range(p, "side_run", 2, 7):
				if absi(v + dir) > lat_limit:
					break
				v += dir
				paint(start + axis * u + lat * v)
		else:
			var dir := _side_dir(v, lat_limit)
			for i in _range(p, "stair_run", 2, 5):
				if u >= length:
					break
				u += 1
				paint(start + axis * u + lat * v)
				if absi(v + dir) <= lat_limit:
					v += dir
					paint(start + axis * u + lat * v)
	while v != 0:
		v -= signi(v)
		paint(start + axis * u + lat * v)


## 곁가지: from에서 heading 쪽으로 치우쳐 구간마다 방향을 꺾으며(급커브) steps걸음.
## 이미 판 다른 길에 닿으면 합류(순환)하고 멈춘다. 끝까지 못 닿으면 가장 가까운 다른 길로 굴을 내 잇고,
## 그것도 안 되면 이 곁가지를 되돌린다 → 막다른 길이 남지 않는다. 돌려줌: 합류한 칸(되돌렸으면 NONE).
## p: {"seg_run": [min, max], "heading_weights": [앞, 왼, 오른, 뒤], "join_after": int, "reconnect_radius": int}
func branch(from: Vector2i, heading: Vector2i, steps: int, p: Dictionary) -> Vector2i:
	var lat := Vector2i(-heading.y, heading.x)
	var dirs: Array[Vector2i] = [heading, lat, -lat, -heading]
	var hw := JsonUtil.get_array(p, "heading_weights")
	if hw.size() != 4:
		hw = [0.4, 0.25, 0.25, 0.1]
	var join_after := JsonUtil.get_int(p, "join_after", 4)
	_log.clear()
	_logging = true
	pick_brush()
	var trail := {}
	for q in footprint(from):
		trail[q] = true
	var cur := from
	var walked := 0
	var dir: Vector2i = dirs[maxi(0, _rng.weighted_index(hw))]
	while walked < steps:
		var moved := false
		for i in _range(p, "seg_run", 2, 6):
			var nxt := cur + dir
			if not fits(nxt):
				break
			var touched := walked >= join_after and _touches_other(nxt, trail)
			paint(nxt)
			for q in footprint(nxt):
				trail[q] = true
			cur = nxt
			walked += 1
			moved = true
			if touched:
				_logging = false
				return cur  # 다른 길에 붙었다 → 합류(나란히 붙어 달리며 넓은 굴이 되지 않게 여기서 멈춘다)
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
		pick_brush()
	# 다시 잇기: 곁가지가 떠나온 자리(from 둘레) 말고 다른 굴로. 제 길을 되밟아 닿은 것(새로 판 칸 없음)은 이은 게 아니다.
	var away := trail.duplicate()
	var keep_off := JsonUtil.get_int(p, "reconnect_keep_off", 8)
	for y in range(from.y - keep_off, from.y + keep_off + 1):
		for x in range(from.x - keep_off, from.x + keep_off + 1):
			away[Vector2i(x, y)] = true
	var target := _nearest_other_floor(cur, away, JsonUtil.get_int(p, "reconnect_radius", 24))
	var before := _log.size()
	if target != NONE and tunnel(cur, target) and _log.size() > before:
		_logging = false
		return cur
	for i in _log:
		cells[i] = 1  # 이을 길이 없다 → 되돌린다(막다른 길을 남기지 않는다)
	_logging = false
	return NONE


## a에서 b까지 붓으로 지그재그로 판다(붓이 들어가지 않는 쪽은 다른 축으로 돌아간다). 닿았으면 true.
func tunnel(a: Vector2i, b: Vector2i) -> bool:
	var p := a
	pick_brush()
	for guard in (absi(b.x - a.x) + absi(b.y - a.y)) * 3 + 8:
		if p == b or (is_floor(b) and footprint(p).has(b)):
			return true
		var options: Array[Vector2i] = []
		for d: Vector2i in [Vector2i(signi(b.x - p.x), 0), Vector2i(0, signi(b.y - p.y))]:
			if d != Vector2i.ZERO and fits(p + d):
				options.append(d)
		if options.is_empty():
			brush = 2
			for d: Vector2i in [Vector2i(signi(b.x - p.x), 0), Vector2i(0, signi(b.y - p.y))]:
				if d != Vector2i.ZERO and fits(p + d):
					options.append(d)
		if options.is_empty():
			return false
		var d: Vector2i = _rng.pick(options)
		p += d
		paint(p)
	return p == b


## 통로 폭 최소 2칸으로(GridWiden). 남은 좁은 곳 수.
func widen(passes: int = 6) -> int:
	return GridWiden.widen(cells, allowed, w, h, passes, true)


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
	return _nearest_other_floor(c, {}, max_r)


func floor_count_in(rect: Rect2i) -> int:
	var n := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if cells[y * w + x] == 0:
				n += 1
	return n


func _nearest_other_floor(c: Vector2i, exclude: Dictionary, max_r: int) -> Vector2i:
	if is_floor(c) and not exclude.has(c):
		return c
	for r in range(1, max_r + 1):
		for x in range(c.x - r, c.x + r + 1):
			for y: int in [c.y - r, c.y + r]:
				if is_floor(Vector2i(x, y)) and not exclude.has(Vector2i(x, y)):
					return Vector2i(x, y)
		for y in range(c.y - r + 1, c.y + r):
			for x: int in [c.x - r, c.x + r]:
				if is_floor(Vector2i(x, y)) and not exclude.has(Vector2i(x, y)):
					return Vector2i(x, y)
	return NONE


## 붓 자리 p(와 그 4방향 둘레)에 이 곁가지가 판 것이 아닌 바닥이 있는가.
func _touches_other(p: Vector2i, trail: Dictionary) -> bool:
	for q in footprint(p):
		if is_floor(q) and not trail.has(q):
			return true
		for d in DIRS:
			if is_floor(q + d) and not trail.has(q + d):
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
