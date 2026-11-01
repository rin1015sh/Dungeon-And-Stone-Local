class_name MonsterHunt
extends RefCounted
## 놓친 상대를 찾는 길(순수 로직 — MonsterMind가 가진다, V22). 걸어갈 칸 길은 Group.patrol, 걷기·곧게 펴기는 MonsterPatrol.follow.
##   쫓기(pursue)  : 마지막으로 본·들은 칸(Group.target)까지 칸 길로 — 모퉁이를 돌아 사라져도 그 모퉁이까지는 따라온다.
##   내다보기(predict): 그 칸에서도 안 보이면 마지막으로 본 움직임(Group.vel) 쪽으로 열린 칸을 따라 ai.predict_tiles까지 더 간다
##                    — 굴이 꺾이면 꺾인 쪽으로(길 거리 안에서 그 방향으로 가장 멀리 간 칸).
##   수색(sweep)   : 둘레 ai.search_radius 안에서 ai.search_points 곳을 골라(그 자리에서 안 보이는 곳 · 갈림길 · 움직이던 쪽을 먼저)
##                   차례로 가서 ai.look_hours 동안 둘러본다. 전체 ai.search_hours(× 성격 tenacity)가 지나면 그만둔다.
##   조사(investigate): 이상한 것(흘끗 본 것·발소리·동료의 외침)이 있던 칸까지 조심스럽게 가서 둘러본다.

var _map: FloorMap
var _rng: Rng
var _sight: MonsterSight
var _patrol: MonsterPatrol
var _predict: int = 6
var _radius: int = 8
var _points: int = 3
var _look: float = 0.05
var _route: int = 48


func _init(db: GameDatabase, map: FloorMap, rng: Rng, sight: MonsterSight, patrol: MonsterPatrol) -> void:
	_map = map
	_rng = rng
	_sight = sight
	_patrol = patrol
	_predict = int(db.bal("monsters.ai.predict_tiles", 6))
	_radius = int(db.bal("monsters.ai.search_radius", 8))
	_points = int(db.bal("monsters.ai.search_points", 3))
	_look = float(db.bal("monsters.ai.look_hours", 0.05))
	_route = int(db.bal("monsters.chase_path_radius", 24)) * 2


## cell까지 걸어간다(이번 단계의 끝 — 닿으면 둘러본다).
func go(g: FieldMonsters.Group, cell: Vector2i) -> void:
	g.patrol = FieldRoutes.path(_map, g.pos, cell, _route) if cell.x >= 0 else ([] as Array[Vector2i])
	g.rest_until = -1.0


## 이번 단계에 닿았는가(걸을 길이 없다).
func arrived(g: FieldMonsters.Group) -> bool:
	return g.patrol.is_empty() and g.waypoint.x < 0.0


## 마지막으로 본 움직임 쪽으로 열린 칸을 따라 내다본 칸(움직임이 없거나 갈 데가 없으면 (-1, -1)).
## 되돌아가는 쪽만 빼고 길 거리로 가장 멀리 — 굴이 꺾이면 꺾인 쪽으로(벽에 막힌 방향만 보면 모퉁이에서 멈췄다), 트인 곳이면 그 방향으로.
func predict(from: Vector2i, vel: Vector2) -> Vector2i:
	if vel.length_squared() < 0.01:
		return Vector2i(-1, -1)
	var dir := vel.normalized()
	var best := Vector2i(-1, -1)
	var best_score := 1.5  # 적어도 한두 칸은 나아가야
	var dist := {from: 0}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var d: int = dist[p]
		var off := Vector2(p - from)
		var score := float(d) + off.dot(dir) * 0.6
		if score > best_score and off.dot(dir) > -0.3 * off.length():
			best_score = score
			best = p
		if d >= _predict:
			continue
		for step in FloorMap.DIRS4:
			var q := p + step
			if not dist.has(q) and _map.is_walkable(q) and not _map.in_safe_zone(q):
				dist[q] = d + 1
				queue.append(q)
	return best


## 수색할 곳들: center 둘레 길 거리 search_radius 안에서 — center에서 안 보이는 곳(모퉁이 너머) · 갈림길 · 움직이던 쪽을 먼저, 서로 떨어지게.
func sweep_points(center: Vector2i, vel: Vector2, mult: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var radius := maxi(3, roundi(_radius * mult))
	var dir := vel.normalized() if vel.length_squared() > 0.01 else Vector2.ZERO
	var dist := {center: 0}
	var queue: Array[Vector2i] = [center]
	var cands: Array[Vector2i] = []
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var d: int = dist[p]
		if d >= 3:
			cands.append(p)
		if d >= radius:
			continue
		for step in FloorMap.DIRS4:
			var q := p + step
			if not dist.has(q) and _map.is_walkable(q) and not _map.in_safe_zone(q):
				dist[q] = d + 1
				queue.append(q)
	var c0 := Kinematics.center_of(center)
	for k in maxi(1, roundi(_points * mult)):
		var best := Vector2i(-1, -1)
		var best_score := -INF
		for i in mini(cands.size(), 400):
			var p: Vector2i = cands[_rng.randi_range(0, cands.size() - 1)] if cands.size() > 400 else cands[i]
			var score := float(dist[p]) * 0.3 + _rng.randf() * 1.5
			if not _sight.clear(c0, Kinematics.center_of(p)):
				score += 3.0  # 모퉁이 너머 — 숨었을 만한 곳
			var open := 0
			for step in FloorMap.DIRS4:
				open += 1 if _map.is_walkable(p + step) else 0
			score += 1.5 if open >= 3 else 0.0  # 갈림길
			if dir != Vector2.ZERO:
				score += Vector2(p - center).normalized().dot(dir) * 2.5
			for o in out:
				score -= 6.0 / maxf(1.0, Vector2(p - o).length())  # 이미 고른 곳과 떨어지게
			if score > best_score:
				best_score = score
				best = p
		if best.x < 0:
			break
		out.append(best)
		cands.erase(best)
	return out


## 다음에 걸어갈 칸(길을 따라 곧게 — MonsterPatrol.follow). 닿았으면 (-1, -1) — 둘러보기는 MonsterMind가 정한다.
func next_cell(g: FieldMonsters.Group, now: float) -> Vector2i:
	return _patrol.follow(g, now)


## 그 자리에서 둘러볼 시간(조사·수색 한 지점).
func look_hours() -> float:
	return _look
