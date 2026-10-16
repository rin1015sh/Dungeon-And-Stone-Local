class_name CaveLinks
extends RefCounted
## 공동끼리 굴로 잇기(CaveChambers 다음, CrossTerrain이 부른다).
## 이음 고르기: 두 공동 가장자리 사이 거리(틈)로 최소 신장 트리(모든 공동이 이어짐) → 이음이 하나뿐인 공동은 다음으로 가까운
##   공동과도 잇는다(막다른 방 없음) → 가까운 이웃 neighbors개 중 loop_chance로 더 잇는다(틈 max_extra_gap 이하, 순환로).
##   중심 거리가 max_link보다 멀거나, 두 중심을 잇는 직선이 팔 수 없는 곳(십자가 바깥 모서리)을 지나는 쌍은 잇지 않는다.
## 굴 모양(meander): 목표 쪽으로 가되 방향이 조금씩 흔들리며(wiggle, 최대 max_turn 라디안) 구불구불, 폭은 원판 반지름
##   tunnel_radius 안에서 천천히 바뀌고 wide_chance로 넓은 회랑(wide_radius), bulge_chance로 옆구리가 불룩한 곳. 판 칸은 늘 이전 칸과 이어진다.
## 값은 floors/*.json gen.chambers.links.


## 이음 목록 [[a, b] …](공동 번호)을 고르고 굴을 판다.
static func build(carver: CaveCarver, chambers: Array[Dictionary], cfg: Dictionary, rng: Rng) -> Array[Vector2i]:
	var n := chambers.size()
	var ok := _feasible(carver, chambers, JsonUtil.get_float(cfg, "max_link", 120.0))
	var edges: Array[Vector2i] = []
	var degree := PackedInt32Array()
	degree.resize(n)
	var linked := {}
	# 최소 신장 트리(Prim) — 이을 수 없는 쌍은 건너뛴다(그런 공동은 등뼈 길·곁가지·마지막 잇기가 잇는다).
	var in_tree := PackedByteArray()
	in_tree.resize(n)
	var best := PackedFloat32Array()
	best.resize(n)
	best.fill(INF)
	var from := PackedInt32Array()
	from.resize(n)
	from.fill(-1)
	best[0] = 0.0
	for step in n:
		var u := -1
		for i in n:
			if in_tree[i] == 0 and best[i] < INF and (u < 0 or best[i] < best[u]):
				u = i
		if u < 0:
			break
		in_tree[u] = 1
		if from[u] >= 0:
			_add(edges, degree, linked, from[u], u)
		for v in n:
			if in_tree[v] == 0 and ok[u * n + v] != 0:
				var g := _gap(chambers[u], chambers[v])
				if g < best[v]:
					best[v] = g
					from[v] = u
	# 이음이 하나뿐인 공동 → 다음으로 가까운 공동과도.
	for i in n:
		if degree[i] <= 1:
			var j := _nearest(chambers, ok, linked, i)
			if j >= 0:
				_add(edges, degree, linked, i, j)
	# 순환로 더하기.
	var k := JsonUtil.get_int(cfg, "neighbors", 3)
	var max_gap := JsonUtil.get_float(cfg, "max_extra_gap", 60.0)
	var loop_chance := JsonUtil.get_float(cfg, "loop_chance", 0.3)
	for i in n:
		for j in _k_nearest(chambers, ok, i, k):
			if not linked.has(_key(i, j)) and _gap(chambers[i], chambers[j]) <= max_gap and rng.chance(loop_chance):
				_add(edges, degree, linked, i, j)
	for e in edges:
		meander(carver, chambers[e.x]["c"], chambers[e.y]["c"], cfg, rng)
	return edges


## 등뼈 길: start에서 axis 쪽으로 length칸. 방향(축에서 벗어난 각)이 천천히 흔들리지만 max_angle(< 90°) 안이라
## **축 방향으로 절대 뒤로 가지 않는다** → "나침반 방향만 지키면 끝에 닿는다"(원판이 이어 붙어 앞·옆 걸음만으로 지나갈 수 있다).
## 옆으로는 중심선에서 ±lat_limit 안, 끝이 가까우면 중심선으로 돌아와 start + axis * length에 닿는다.
## p: {"radius": [최소, 최대], "wide_chance", "wide_radius", "wiggle", "max_angle"}
static func spine(carver: CaveCarver, start: Vector2i, axis: Vector2i, length: int, lat_limit: int, p: Dictionary, rng: Rng) -> void:
	var ax := Vector2(axis)
	var lat := Vector2(-axis.y, axis.x)
	var rr := JsonUtil.get_array(p, "radius")
	var lo := float(rr[0]) if rr.size() == 2 else 1.2
	var hi := float(rr[1]) if rr.size() == 2 else 2.0
	var wiggle := JsonUtil.get_float(p, "wiggle", 0.12)
	var max_angle := minf(JsonUtil.get_float(p, "max_angle", 1.1), 1.4)
	var radius := rng.randf_range(lo, hi)
	var u := 0.0
	var v := 0.0
	var ang := 0.0
	var origin := Vector2(start)
	_disc(carver, origin, radius)
	while u < length:
		ang += rng.randf_range(-wiggle, wiggle)
		if absf(v) > lat_limit * 0.7:
			ang -= signf(v) * wiggle * 1.5
		var remain := float(length) - u
		if remain < absf(v) * 1.5 + 10.0:
			ang = lerpf(ang, atan2(-v, maxf(1.0, remain)), 0.3)
		ang = clampf(ang, -max_angle, max_angle)
		u += cos(ang) * 0.8
		v = clampf(v + sin(ang) * 0.8, -lat_limit, lat_limit)
		if rng.chance(0.06):
			radius = JsonUtil.get_float(p, "wide_radius", 2.8) if rng.chance(JsonUtil.get_float(p, "wide_chance", 0.0)) \
				else rng.randf_range(lo, hi)
		_disc(carver, origin + ax * u + lat * v, radius)
	while absf(v) > 0.4:
		v -= signf(v) * minf(0.8, absf(v))
		_disc(carver, origin + ax * u + lat * v, lo)
	_disc(carver, origin + ax * float(length), radius)


## a에서 b까지 구불구불한 굴을 판다. 막히면(팔 수 없는 칸) 곧장 목표 쪽으로, 그래도 막히면 CaveCarver.tunnel로 마무리.
static func meander(carver: CaveCarver, a: Vector2, b: Vector2, cfg: Dictionary, rng: Rng) -> void:
	var rr := JsonUtil.get_array(cfg, "tunnel_radius")
	var lo := float(rr[0]) if rr.size() == 2 else 1.1
	var hi := float(rr[1]) if rr.size() == 2 else 1.8
	var wide := rng.chance(JsonUtil.get_float(cfg, "wide_chance", 0.0))
	var radius := JsonUtil.get_float(cfg, "wide_radius", 2.6) if wide else rng.randf_range(lo, hi)
	var wiggle := JsonUtil.get_float(cfg, "wiggle", 0.18)
	var max_turn := JsonUtil.get_float(cfg, "max_turn", 1.0)
	var off := 0.0
	var p := a
	_disc(carver, p, radius)
	for guard in int(a.distance_to(b) * 4.0) + 40:
		var to := b - p
		if to.length() < 1.0:
			return
		off = clampf(off + rng.randf_range(-wiggle, wiggle), -max_turn, max_turn)
		var nxt := p + to.normalized().rotated(off) * 0.8
		if not carver.can(Vector2i(nxt.round())):
			off *= 0.3
			nxt = p + to.normalized() * 0.8
			if not carver.can(Vector2i(nxt.round())):
				carver.tunnel(Vector2i(p.round()), Vector2i(b.round()))
				return
		p = nxt
		if not wide and rng.chance(0.08):
			radius = clampf(radius + rng.randf_range(-0.3, 0.3), lo, hi)
		_disc(carver, p, radius)
		_bulge(carver, p, to.normalized(), radius, cfg, rng)
	carver.tunnel(Vector2i(p.round()), Vector2i(b.round()))


## 굴 옆구리가 불룩한 곳(bulge_chance — 걸음마다): 옆으로 조금 비켜 작은 원판(bulge_radius).
static func _bulge(carver: CaveCarver, p: Vector2, heading: Vector2, radius: float, cfg: Dictionary, rng: Rng) -> void:
	if not rng.chance(JsonUtil.get_float(cfg, "bulge_chance", 0.0)):
		return
	var br := JsonUtil.get_array(cfg, "bulge_radius")
	var r := rng.randf_range(float(br[0]), float(br[1])) if br.size() == 2 else 2.5
	var side := heading.orthogonal() * (1.0 if rng.chance(0.5) else -1.0)
	_disc(carver, p + side * (radius + r * 0.4), r)


static func _disc(carver: CaveCarver, c: Vector2, r: float) -> void:
	var k := ceili(r)
	var base := Vector2i(c.round())
	for dy in range(-k, k + 1):
		for dx in range(-k, k + 1):
			var q := base + Vector2i(dx, dy)
			if Vector2(q).distance_to(c) <= r:
				carver.carve(q)


## 두 공동 가장자리 사이 거리(대략).
static func _gap(a: Dictionary, b: Dictionary) -> float:
	return maxf(0.0, (a["c"] as Vector2).distance_to(b["c"]) - float(a["radius"]) - float(b["radius"]))


## 쌍마다 이을 수 있는가(중심 거리 max_link 이하이고, 중심을 잇는 직선 위 칸이 모두 팔 수 있는 칸). 1 = 된다.
static func _feasible(carver: CaveCarver, chambers: Array[Dictionary], max_link: float) -> PackedByteArray:
	var n := chambers.size()
	var ok := PackedByteArray()
	ok.resize(n * n)
	for i in n:
		for j in range(i + 1, n):
			var a: Vector2 = chambers[i]["c"]
			var b: Vector2 = chambers[j]["c"]
			if a.distance_to(b) > max_link:
				continue
			var good := true
			var steps := ceili(a.distance_to(b) / 2.0)
			for s in steps + 1:
				if not carver.can(Vector2i(a.lerp(b, float(s) / maxf(1.0, float(steps))).round())):
					good = false
					break
			if good:
				ok[i * n + j] = 1
				ok[j * n + i] = 1
	return ok


static func _add(edges: Array[Vector2i], degree: PackedInt32Array, linked: Dictionary, i: int, j: int) -> void:
	edges.append(Vector2i(i, j))
	degree[i] += 1
	degree[j] += 1
	linked[_key(i, j)] = true


static func _key(i: int, j: int) -> Vector2i:
	return Vector2i(mini(i, j), maxi(i, j))


static func _nearest(chambers: Array[Dictionary], ok: PackedByteArray, linked: Dictionary, i: int) -> int:
	var n := chambers.size()
	var best := -1
	var best_gap := INF
	for j in n:
		if j != i and ok[i * n + j] != 0 and not linked.has(_key(i, j)):
			var g := _gap(chambers[i], chambers[j])
			if g < best_gap:
				best_gap = g
				best = j
	return best


static func _k_nearest(chambers: Array[Dictionary], ok: PackedByteArray, i: int, k: int) -> Array[int]:
	var n := chambers.size()
	var cand: Array[Vector2] = []  # (틈, 번호)
	for j in n:
		if j != i and ok[i * n + j] != 0:
			cand.append(Vector2(_gap(chambers[i], chambers[j]), j))
	cand.sort_custom(func(x: Vector2, y: Vector2) -> bool: return x.x < y.x)
	var out: Array[int] = []
	for c in cand.slice(0, k):
		out.append(int(c.y))
	return out
