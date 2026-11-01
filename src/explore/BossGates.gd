class_name BossGates
extends RefCounted
## 보스 방 문 닫힘(순수 로직 — 사용자 2026-11-01 보스 등장 아이디어 1 "뒤에서 문·창살이 닫혀 도망칠 수 없게", V23):
## 보스가 깨어나면(등장 연출 — BossReveal) 보스가 있는 공간의 좁은 문목을 모두 창살(타일 balance boss_gate.tile)로 막고,
## 보스 무리가 지도에서 사라지면(이김) 원래 타일로 연다. 전투에서 도망쳐도 닫힌 채 — 다시 싸워야 나간다.
##
## 공간 찾기는 손 설계 지도마다 문 자리를 적지 않게 자동으로(_Finder — 진짜 벽 · 문목 · 옆길·벽감 넣기). 방이 max_cells를 넘으면(트인 들판) 닫지 않는다.

var at: Dictionary = {}  ## 무리 id → [[칸, 원래 타일 id], …]
var seals: Dictionary = {}  ## 무리 id → true: 문목이 없어(챕터 전체가 보스 터) 균열 길목을 막았다 — RiftRun.passage_step이 넘어가지 않는다


## 보스 무리 g의 방을 닫는다. 닫은 칸들(없으면 빈 배열).
func close(map: FloorMap, g: FieldMonsters.Group, player: Vector2i, db: GameDatabase, groups: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if at.has(g.id):
		return out
	var tile := str(db.bal("boss_gate.tile", "boss_gate"))
	var cells := find(map, g.pos, player, int(db.bal("boss_gate.width", 4)), int(db.bal("boss_gate.max_cells", 1600)))
	var seal := cells.is_empty()
	if seal:  # 문목이 없다(트인 굴 — 챕터 전체가 보스 터): 균열 길목 입구를 막는다
		for pt: Dictionary in map.portals:
			if bool(pt.get("passage", false)):
				for c: Vector2i in pt.get("mouth", [pt["pos"]]):
					if map.is_walkable(c) and maxi(absi(c.x - player.x), absi(c.y - player.y)) > 1:
						cells.append(c)
	var saved: Array = []
	for c in cells:
		var taken := false
		for o: FieldMonsters.Group in groups:
			taken = taken or o.pos == c
		if taken or (not seal and map.portal_at(c).size() > 0):
			continue
		saved.append([c, map.tile_id_at(c)])
		map.set_tile(c, tile)
		out.append(c)
	at[g.id] = saved
	if seal:
		seals[g.id] = true
	return out


## 균열 길목이 막혔는가(깨어난 보스가 살아 있다).
func sealed() -> bool:
	return not seals.is_empty()


## 무리 id의 창살을 연다. 연 칸들.
func open(map: FloorMap, group_id: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for e: Array in at.get(group_id, []):
		map.set_tile(e[0], str(e[1]))
		out.append(e[0])
	at.erase(group_id)
	seals.erase(group_id)
	return out


## 창살 칸들(방이 트여 닫을 수 없으면 빈 배열).
static func find(map: FloorMap, boss: Vector2i, player: Vector2i, width: int, max_cells: int) -> Array[Vector2i]:
	return _Finder.new(map, width, max_cells).run(boss, player)


## 방 찾기:
##   진짜 벽 = 걸을 수 없고 서 있는 장식(art.stand)이 아니며, 이어진 벽 덩이가 MIN_WALL칸 이상(기둥 몇 칸은 벽으로 치지 않는다 — 성채 5장 신랑 기둥 사이에
##            창살이 37칸 내렸다).
##   문목 칸 = 걸을 수 있고 가로나 세로로 진짜 벽 사이 폭이 width칸 이하.
##   보스 칸에서 문목이 아닌 칸만 따라 퍼진 곳 = 방(플레이어가 그 밖이면 플레이어 둘레 3칸까지도).
##   방에 닿은 문목 칸을 이어진 덩이로 묶어 — width + 1칸보다 긴 덩이(방을 따라 뻗은 좁은 옆길)와 막다른 곳(그 너머가 DEAD_END칸 이하 — 창 사이 벽감)은
##   방으로 넣고 다시 퍼진다. 남은 짧은 덩이(복도 입구·문)가 창살 자리.
class _Finder:
	const MIN_WALL := 10
	const DEAD_END := 40
	var map: FloorMap
	var width: int
	var max_cells: int
	var _wall := {}  # 칸 → 진짜 벽인가(덩이째 기억)
	var room := {}
	var allowed := {}
	var _beyond: Array[Vector2i] = []

	func _init(p_map: FloorMap, p_width: int, p_max: int) -> void:
		map = p_map
		width = p_width
		max_cells = p_max

	func run(boss: Vector2i, player: Vector2i) -> Array[Vector2i]:
		var gates: Array[Vector2i] = []
		if door(boss):
			return gates
		room[boss] = true
		if not grow([boss] as Array[Vector2i], Vector2i(-99, -99)):
			return gates
		if not room.has(player):  # 플레이어가 문목·복도에서 보스를 봤다
			room[player] = true
			if not grow([player] as Array[Vector2i], player):
				return gates
		for round_i in 16:
			var absorb: Array[Vector2i] = []
			var groups := frontier()
			for g: Array in groups:
				if g.size() > width + 1:
					absorb.append_array(g)
					continue
				if dead_end(g):
					absorb.append_array(g)
					absorb.append_array(_beyond)
			if absorb.is_empty():
				for g: Array in groups:
					for c: Vector2i in g:
						if maxi(absi(c.x - player.x), absi(c.y - player.y)) > 1:  # 플레이어 바로 곁에는 내리지 않는다
							gates.append(c)
				return gates
			for c in absorb:
				room[c] = true
				allowed[c] = true
			if not grow(absorb, player):
				return [] as Array[Vector2i]
		return gates

	## room에서 문목이 아닌 칸으로 퍼진다(near 둘레 3칸 안 · allowed는 문목도). max_cells를 넘으면 false.
	func grow(queue: Array[Vector2i], near: Vector2i) -> bool:
		var head := 0
		while head < queue.size():
			var p := queue[head]
			head += 1
			for d in FloorMap.DIRS4:
				var q := p + d
				if room.has(q) or not map.is_walkable(q) or map.in_safe_zone(q):
					continue
				if door(q) and maxi(absi(q.x - near.x), absi(q.y - near.y)) > 3 and not allowed.has(q):
					continue
				room[q] = true
				queue.append(q)
				if room.size() > max_cells:
					return false
		return true

	## 방에 닿은 걸을 수 있는 칸을 8방향으로 이어진 덩이로.
	func frontier() -> Array:
		var front := {}
		for c: Vector2i in room:
			for d in FloorMap.DIRS4:
				var q := c + d
				if not room.has(q) and map.is_walkable(q) and not map.in_safe_zone(q):
					front[q] = true
		var out: Array = []
		var seen := {}
		for c: Vector2i in front:
			if seen.has(c):
				continue
			var group: Array[Vector2i] = []
			var todo: Array[Vector2i] = [c]
			seen[c] = true
			while not todo.is_empty():
				var p: Vector2i = todo.pop_back()
				group.append(p)
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
					var q: Vector2i = p + d
					if front.has(q) and not seen.has(q):
						seen[q] = true
						todo.append(q)
			out.append(group)
		return out

	## 덩이 너머가 막다른 곳인가(DEAD_END칸 이하 — 그 칸들은 _beyond).
	func dead_end(group: Array) -> bool:
		var seen := {}
		var todo: Array[Vector2i] = []
		for c: Vector2i in group:
			seen[c] = true
			todo.append(c)
		_beyond.clear()
		var out := _beyond
		while not todo.is_empty():
			var p: Vector2i = todo.pop_back()
			for d in FloorMap.DIRS4:
				var q := p + d
				if seen.has(q) or room.has(q) or not map.is_walkable(q):
					continue
				seen[q] = true
				out.append(q)
				if out.size() > DEAD_END:
					return false
				todo.append(q)
		return true

	## 문목 칸인가: 가로나 세로로 진짜 벽 사이 폭이 width 이하.
	func door(c: Vector2i) -> bool:
		return span(c, Vector2i(1, 0)) <= width or span(c, Vector2i(0, 1)) <= width

	## c를 지나 dir 방향으로 진짜 벽까지 막히지 않은 칸 수(width + 1에서 멈춘다).
	func span(c: Vector2i, dir: Vector2i) -> int:
		var n := 1
		for s: int in [1, -1]:
			var q := c + dir * s
			while n <= width and not is_wall(q):
				n += 1
				q += dir * s
		return n

	## 진짜 벽인가(지도 밖 포함). 걸을 수 없는 칸 덩이(서 있는 장식 빼고)가 MIN_WALL칸 이상.
	func is_wall(c: Vector2i) -> bool:
		if not map.in_bounds(c):
			return true
		if _wall.has(c):
			return _wall[c]
		if not _solid(c):
			_wall[c] = false
			return false
		var lump: Array[Vector2i] = [c]
		var seen := {c: true}
		var head := 0
		var big := false
		while head < lump.size() and not big:
			var p := lump[head]
			head += 1
			for d in FloorMap.DIRS4:
				var q := p + d
				if not map.in_bounds(q):
					big = true  # 지도 가장자리에 붙은 벽
					break
				if not seen.has(q) and _solid(q):
					seen[q] = true
					lump.append(q)
					if lump.size() >= MIN_WALL:
						big = true
						break
		if big:
			_wall[c] = true  # 큰 덩이: 이 칸만 기억(덩이 전체를 훑지 않게)
		else:
			for q in lump:
				_wall[q] = false  # 작은 덩이(기둥 등) 전체
		return big

	func _solid(c: Vector2i) -> bool:
		var d := map.def_at(c)
		return not d.walkable and d.stand_sheet.is_empty()
