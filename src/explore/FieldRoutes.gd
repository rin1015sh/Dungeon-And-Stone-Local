class_name FieldRoutes
extends RefCounted
## 필드 무리가 먼 곳까지 걸어갈 길(순수 로직): 칸 BFS로 최단 경로를 찾는다(4방향, 안전지대는 지나지 않는다).
## 무리를 다른 곳으로 보낼 때 한 번만 부른다(구울이 새 시체로, 탐험가 무리가 포탈 쪽으로 — FieldMonsters.send_to).


## a에서 b까지 칸 목록(a는 빼고 b까지). radius(걸음) 안에 길이 없으면 빈 배열.
static func path(map: FloorMap, a: Vector2i, b: Vector2i, radius: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if a == b or not map.is_walkable(b):
		return out
	var prev := {a: a}
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == b:
			break
		var d: int = dist[p]
		if d >= radius:
			continue
		for dir in FloorMap.DIRS4:
			var q := p + dir
			if not prev.has(q) and map.is_walkable(q) and not map.in_safe_zone(q):
				prev[q] = p
				dist[q] = d + 1
				queue.append(q)
	if not prev.has(b):
		return out
	var c := b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out


## p 둘레 radius칸 안의 걸을 수 있는 무작위 칸(accept가 참인 것). 못 찾으면 (-1, -1).
static func random_cell_near(map: FloorMap, rng: Rng, p: Vector2i, radius: int, accept: Callable = Callable()) -> Vector2i:
	for attempt in 40:
		var q := p + Vector2i(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))
		if map.is_walkable(q) and not map.in_safe_zone(q) and map.portal_at(q).is_empty() \
				and (not accept.is_valid() or bool(accept.call(q))):
			return q
	return Vector2i(-1, -1)
