class_name WallDoors
extends RefCounted
## 문(아치): 방 북쪽 벽에 뚫린 좁은 통로(1~max_cells칸)의 들머리에 벽 앞면이 아치로 이어지고, 그 위는 검은 벽 머리(사용자 레퍼런스 2026-11-01, AM62).
## 방과 방 사이를 넘어갈 때 "문을 지난다"가 보이게 한다 — 1층 수정동굴은 바위 아치, 균열 성채·묘는 돌 아치(벽 앞면 그림을 이어 쓴다).
## 문 칸 = 걸을 수 있는 칸들의 가로 줄(row r)로:
##   양옆이 다듬는 벽(art.shape — WallShape) · 적어도 한쪽은 남쪽이 열려 있다(방의 북쪽 벽 앞면 줄) · 문 칸 남쪽은 모두 열린 칸(방)
##   · 북쪽으로 depth칸 통로가 이어진다(줄마다 양옆이 벽이고 열린 칸이 있다 — 울퉁불퉁한 동굴 벽의 굴곡은 문이 아니다) · 포탈·동굴 요소 칸이 아니다.
## 그림은 DoorArt(WallRow의 줄 조각 — 줄 아래 가장자리로 캐릭터와 y 정렬, 문을 지나는 캐릭터는 인방·벽 머리에 가려진다).
## 수치 = render.json view.door(FloorTextures가 읽어 둔다 — 모양별 높이는 door.kinds).

static var max_cells: int = 4
static var depth: int = 2          ## 문 북쪽으로 이어져야 하는 통로 길이(칸)


## render.json view.door를 읽는다.
static func configure(cfg: Dictionary) -> void:
	max_cells = maxi(1, JsonUtil.get_int(cfg, "max_cells", 4))
	depth = maxi(1, JsonUtil.get_int(cfg, "depth", 2))
	DoorArt.configure(cfg)


## 칸 p가 문 칸인가.
static func is_door(map: FloorMap, p: Vector2i, smooth: PackedByteArray) -> bool:
	return run_at(map, p, smooth).x >= 0


## 칸 p가 든 문의 가로 칸 범위 (서쪽 x, 동쪽 x — 끝 포함), 문이 아니면 (-1, -1).
static func run_at(map: FloorMap, p: Vector2i, smooth: PackedByteArray) -> Vector2i:
	var none := Vector2i(-1, -1)
	if not WallShape._open(map, p):
		return none
	var r := p.y
	var a := p.x
	while WallShape._open(map, Vector2i(a - 1, r)):
		a -= 1
		if p.x - a >= max_cells:
			return none
	var b := p.x
	while WallShape._open(map, Vector2i(b + 1, r)):
		b += 1
		if b - a + 1 > max_cells:
			return none
	var face := false
	for side: int in [a - 1, b + 1]:  # 문설주: 다듬는 벽 · 적어도 한쪽은 방의 북쪽 벽 앞면 줄(남쪽이 열림)
		if not WallShape._smooth_wall(map, Vector2i(side, r), smooth):
			return none
		face = face or WallShape._open(map, Vector2i(side, r + 1))
	if not face or map.def_at(Vector2i(a - 1, r)).art_doors.has("none"):  # 아치를 두지 않는 벽(art.doors ["none"] — 1층 수정동굴, 사용자 2026-11-04)
		return none
	for k in range(1, depth + 1):  # 북쪽으로 통로가 depth칸 이어진다(양옆이 벽 — 동굴 벽의 작은 굴곡은 문이 아니다)
		if not WallShape._wall(map, Vector2i(a - 1, r - k)) or not WallShape._wall(map, Vector2i(b + 1, r - k)):
			return none
		var open := false
		for x in range(a, b + 1):
			open = open or WallShape._open(map, Vector2i(x, r - k))
		if not open:
			return none
	for x in range(a, b + 1):
		var c := Vector2i(x, r)
		if not WallShape._open(map, c + Vector2i(0, 1)) or not map.portal_at(c).is_empty():
			return none
	for f in map.features:
		var fp: Vector2i = f["pos"]
		if fp.y == r and fp.x >= a and fp.x <= b:
			return none
	return Vector2i(a, b)


## 줄 row의 [x0, x1) 안에 서쪽 문설주가 있는 문들: [{x0, x1(끝 포함), flank(서쪽 문설주 타일 번호)}].
static func find(map: FloorMap, row: int, x0: int, x1: int, smooth: PackedByteArray) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for x in range(x0, x1):
		var p := Vector2i(x, row)
		if not WallShape._smooth_wall(map, p, smooth) or not WallShape._open(map, p + Vector2i(1, 0)):
			continue
		var run := run_at(map, p + Vector2i(1, 0), smooth)
		if run.x == x + 1:
			out.append({"x0": run.x, "x1": run.y, "flank": map.def_at(p).index})
	return out


## 문 하나를 cv(WallRow — 위치 = 줄 아래 가장자리)에 그린다(모양·장식은 DoorArt).
static func draw(view: FloorView, cv: CanvasItem, row: int, door: Dictionary) -> void:
	DoorArt.draw(view, cv, row, door)
