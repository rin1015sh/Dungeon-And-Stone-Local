class_name RiftPassage
extends RefCounted
## 균열 챕터 사이 길목(사용자 요청 2026-10-20 — 사각형 포탈 대신 이어진 길처럼):
##   앞 길목 = 출구(마지막 챕터는 탈출 포탈 그대로 — E로 나간다), 뒤 길목 = 2챕터부터 시작 자리(지나온 챕터로 돌아간다).
##   길목 칸은 원래 바닥 그대로 두고 은은한 빛만 단다(render.json rift_passage). 길목 둘레 rift.passage_zone칸에 걸어 들어가면 넘어간다(RiftRun.passage_step).
##   넘어간 쪽에서는 그 챕터의 반대쪽 길목에서 rift.passage_arrive_steps걸음 안쪽에 선다(바로 되돌아가지 않게, 걸어온 방향을 보고).

const BACK := "rift_back"


## 챕터 지도에 길목을 단다. last = 마지막 챕터(출구 = 탈출 포탈), has_back = 지나온 챕터가 있다.
static func setup(cs: ExploreSession, last: bool, has_back: bool, floor_tile: String) -> void:
	var exit := exit_portal(cs.map)
	if not exit.is_empty() and not last:
		cs.map.set_tile(exit["pos"], str(exit.get("under", floor_tile)))
		exit["passage"] = true
		exit["found"] = true  # 보이는 길 — 따로 알리지 않는다
		_glow(cs, exit["pos"])
	if has_back:
		cs.map.portals.append({"id": BACK, "pos": cs.map.entry, "dir": "", "to_floor": 0, "kind": BACK, "found": true, "passage": true})
		_glow(cs, cs.map.entry)


static func exit_portal(map: FloorMap) -> Dictionary:
	for pt: Dictionary in map.portals:
		if str(pt.get("kind", "")) == "rift_exit":
			return pt
	return {}


## 칸 p가 길목 둘레면 그 쪽(+1 앞, -1 뒤), 아니면 0.
static func dir_at(map: FloorMap, p: Vector2i, zone: int) -> int:
	for pt: Dictionary in map.portals:
		if bool(pt.get("passage", false)):
			var d: Vector2i = p - (pt["pos"] as Vector2i)
			if maxi(absi(d.x), absi(d.y)) <= zone:
				return -1 if str(pt["kind"]) == BACK else 1
	return 0


## 길목 cell로 들어온 사람이 설 자리: 걸을 수 있는 칸을 따라 길목 둘레(zone) 밖으로 steps걸음 — 지도 가장자리에서 먼(안쪽) 칸.
static func arrival(cs: ExploreSession, cell: Vector2i, zone: int, steps: int) -> Vector2i:
	var map := cs.map
	var dist := {cell: 0}
	var queue: Array[Vector2i] = [cell]
	var best := Vector2i(-1, -1)
	var best_key := -1
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		var d := int(dist[p])
		var off := p - cell
		var outside := maxi(absi(off.x), absi(off.y)) > zone
		if outside and d >= steps and cs.monsters.group_at(p) == null:
			var inner := mini(mini(p.x, map.width - 1 - p.x), mini(p.y, map.height - 1 - p.y))
			if best.x < 0 or (d == int(dist[best]) and inner > best_key):
				best = p
				best_key = inner
		if best.x >= 0 and d > int(dist[best]):
			break
		for dir in FloorMap.DIRS4:
			var q := p + dir
			if not dist.has(q) and map.is_walkable(q):
				dist[q] = d + 1
				queue.append(q)
	return best if best.x >= 0 else cell


## 길목에서 도착 자리로 걸어 나오는 방향(4방향).
static func facing(cell: Vector2i, at: Vector2i) -> Vector2i:
	return PlayerMotion.facing_of(Vector2(at - cell)) if at != cell else Vector2i(0, 1)


static func _glow(cs: ExploreSession, cell: Vector2i) -> void:
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(cs.db.render, "ui"), "rift_passage")
	var mpt := maxf(0.01, float(cs.db.bal("explore.meters_per_tile", 1.0)))
	cs.lights.add_point(cell, JsonUtil.get_float(cfg, "light_radius_m", 3.0) / mpt,
		Color.from_string(JsonUtil.get_str(cfg, "light_color", "#ffe2b8"), Color.WHITE), JsonUtil.get_float(cfg, "light_intensity", 0.6))
