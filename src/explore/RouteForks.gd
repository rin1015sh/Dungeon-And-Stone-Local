class_name RouteForks
extends RefCounted
## 갈림길 규칙(야수의 소굴 — floor2.md §2 "갈림길마다 바른 갈래가 하나", 레벨 디자인 LD11). 순수 로직(오토로드 비의존).
## 층 JSON route_spots "forks": [{"branches": [{"mouth": 표시, "block": 표시}, …], "right": 요소 id, "wrong": 요소 id,
##   "block_tile": 타일, "block_r": 칸}] — 입장마다(원정마다 — 외워서 뚫지 못하게) 갈래 하나를 바른 길로 고르고,
##   나머지 갈래는 block 표시 둘레(block_r — 체비셰프 거리) 걸을 수 있는 칸을 무너진 돌(block_tile)로 막는다(막다른 길 — 시간 손해).
##   갈래 입구(mouth)에는 바른 길이면 right, 아니면 wrong 요소를 놓는다(바람이 불어온다 / 공기가 고였다 … 다가가면 한 줄 — near).
##   높은 바위턱(망루 요소)에서 내려다보면 막힌 갈래가 보인다.

var right: Array[int] = []  ## 갈림길마다 고른 바른 갈래 번호


static func setup(s: ExploreSession) -> RouteForks:
	var list := JsonUtil.get_array(JsonUtil.get_dict(s.floor_def, "route_spots"), "forks")
	if list.is_empty():
		return null
	var f := RouteForks.new()
	var marks: Dictionary = s.map.anchors.get("marks", {})
	for v: Variant in list:
		var fd: Dictionary = v if v is Dictionary else {}
		var branches := JsonUtil.get_array(fd, "branches")
		if branches.is_empty():
			f.right.append(-1)
			continue
		var pick := s.rng.randi_range(0, branches.size() - 1)
		f.right.append(pick)
		var tile := JsonUtil.get_str(fd, "block_tile", "f2d_scree")
		var r := JsonUtil.get_int(fd, "block_r", 2)
		for i in branches.size():
			var b: Dictionary = branches[i] if branches[i] is Dictionary else {}
			var mouth: Vector2i = marks.get(JsonUtil.get_str(b, "mouth"), Vector2i(-1, -1))
			if mouth.x >= 0:
				s.features.add_at(s, JsonUtil.get_str(fd, "right" if i == pick else "wrong"), mouth)
			if i == pick:
				continue
			var at: Vector2i = marks.get(JsonUtil.get_str(b, "block"), Vector2i(-1, -1))
			if at.x >= 0:
				_block(s, at, r, tile)
	return f


## at 둘레 r칸 안 걸을 수 있는 칸을 tile로(무너진 돌 — 갈래를 끊는다).
static func _block(s: ExploreSession, at: Vector2i, r: int, tile: String) -> void:
	var box := Rect2i(at - Vector2i(r, r), Vector2i(r * 2 + 1, r * 2 + 1))
	for y in range(at.y - r, at.y + r + 1):
		for x in range(at.x - r, at.x + r + 1):
			var q := Vector2i(x, y)
			if s.map.in_bounds(q) and s.map.is_walkable(q) and s.map.portal_at(q).is_empty():
				s.map.set_tile(q, tile)
	s.tiles_changed.emit(box)
