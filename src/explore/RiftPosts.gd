class_name RiftPosts
extends RefCounted
## 균열 챕터의 대기 무리(조우 kind "posts", 사용자 2026-10-27 "넓은데 적이 적다 — 텅 빈 곳에 대기하는 적", RF23).
## 시작 칸·출구·길목·이미 선 무리를 출발점으로 걸음 수 장(BFS)을 만들어, 가장 먼 칸(= 가장 빈 곳)의 balance rift.post_pick_ratio 이상인
## 칸 중 하나에 무리를 세운다. 하나 세울 때마다 그 자리를 출발점에 더해 다시 잰다 — 무리가 지도 곳곳에 고르게 퍼진다.
## 대기 무리(Group.guard)는 순찰하지 않고 제자리에서 둘러보다 알아채면 쫓고, 놓치면 제자리로 돌아온다(MonsterPatrol).


## e = {"count": n, "packs": [구성, …]} — compose(구성) -> 몬스터 id 배열(RiftRun.compose). 세운 무리를 돌려준다.
static func place(s: ExploreSession, e: Dictionary, compose: Callable, rng: Rng) -> Array[FieldMonsters.Group]:
	var out: Array[FieldMonsters.Group] = []
	var packs := JsonUtil.get_array(e, "packs")
	if packs.is_empty():
		return out
	var min_tiles := int(s.db.bal("rift.post_min_tiles", 8))
	var ratio := float(s.db.bal("rift.post_pick_ratio", 0.75))
	var taken: Array[Vector2i] = [s.map.entry]
	taken.append_array(s.map.slots)
	for p: Dictionary in s.map.portals:
		taken.append(p["pos"])
	for g: FieldMonsters.Group in s.monsters.groups:
		taken.append(g.pos)
	for i in JsonUtil.get_int(e, "count", 1):
		var dist := _steps_from(s.map, taken)
		var far := 0
		for d: int in dist.values():
			far = maxi(far, d)
		if far < min_tiles:
			break  # 빈 곳이 없다
		var cands: Array[Vector2i] = []
		for c: Vector2i in dist:
			if int(dist[c]) >= maxi(min_tiles, int(far * ratio)) and not s.map.in_safe_zone(c) and s.monsters.group_at(c) == null:
				cands.append(c)
		if cands.is_empty():
			break
		cands.sort()  # 사전 순서 → 같은 시드면 같은 자리
		var at: Vector2i = cands[rng.randi_range(0, cands.size() - 1)]
		var ids: Array = compose.call(packs[rng.randi_range(0, packs.size() - 1)])
		var g := s.monsters.add_fixed(ids, at)
		if g == null:
			continue
		g.tag = "battle"
		g.guard = true
		taken.append(g.pos)
		out.append(g)
	return out


## 출발점들에서 걸음 수(4방향, 걸을 수 있는 칸 — 시작 둘레 안전지대도 지나간다: 막으면 시작 칸이 먼 곳으로 잡혔다) — 닿지 않는 칸은 없다.
static func _steps_from(map: FloorMap, starts: Array[Vector2i]) -> Dictionary:
	var dist := {}
	var queue: Array[Vector2i] = []
	for p in starts:
		if map.in_bounds(p) and not dist.has(p):
			dist[p] = 0
			queue.append(p)
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		for d in FloorMap.DIRS4:
			var q := p + d
			if not dist.has(q) and map.is_walkable(q):
				dist[q] = int(dist[p]) + 1
				queue.append(q)
	return dist
