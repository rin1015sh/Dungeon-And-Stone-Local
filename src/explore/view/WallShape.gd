class_name WallShape
extends RefCounted
## 부드러운 암벽 모양(타일 art.shape "smooth" — 그림만, 걷기·충돌·지도는 칸 그대로).
## 벽 덩어리의 바닥 평면 윤곽을 칸마다 다듬는다:
##   볼록 모서리(벽 칸에서 맞닿은 두 이웃이 열림) = 사선으로 깎는다,
##   오목 모서리(바닥 칸에서 맞닿은 두 이웃과 대각선이 벽) = 사선으로 메운다.
## 깎는 폭 r = 0.5칸이면 한 칸짜리 계단의 볼록·오목 사선이 한 줄로 이어져 곧은 45° 벽이 된다.
## 사선은 가운데를 bulge만큼 모서리 쪽으로 살짝 휘게 해(바위 결) 기계적인 팔각형이 되지 않게 한다.
## 3/4 시점: 덩어리 윗면은 앞면 높이만큼 위로 올려 검게(art.unexplored) 칠하고 — 바위 속은 보이지 않는다 —
## 남쪽을 향한 윤곽만 앞면 띠(위 = 올린 윤곽, 아래 = 바닥 윤곽 + 밑동)로 그린다.
## 윗면은 보이는 것을 가릴 때만 필요하다: 북쪽이 열린 벽 칸(앞면이 칸보다 높으면 그 높이 안에 바닥이 있는 칸까지) + 아래쪽 오목 메움. 나머지 바위 속 칸은 그리지 않는다.
## 줄마다 한 번(build) 계산해 두고, 그릴 때는 탐험 여부·빛만 본다(WallRow).
## 캐릭터와의 앞뒤(y 정렬): 아래쪽 모서리를 깎은 벽 칸·위쪽 오목 메움은 앞면이 칸 아래 가장자리보다 위(북쪽)에 있으니
## 따로 묶어(piece) 그 사선의 위쪽 끝 y로 정렬한다 — 줄 전체(칸 아래 가장자리)로 정렬하면 사선 앞에 선 캐릭터를 벽이 덮는다.
## 모양(smooth 배열 값 — 타일 art.shape):
##   SMOOTH "smooth" = 위 그대로(1층 암벽·수정벽 — 윗면 검게)
##   ROUND  "round"  = 같은 둥근 윤곽 — 균열 자연 암벽(얼음벽·갱도 벽 …), 깎은 자리는 옆 바닥 그림
##   BEVEL  "bevel"  = 지은 벽(성벽·금속벽): 직각 모서리는 그대로 두고 두 칸 이상 이어진 계단만 곧은 45° 사선으로(휨 없음)
## 윗면은 모두 검다 — 방과 방 사이가 검은 거리로 떨어져 보인다(사용자 레퍼런스 2026-11-01, AM62).
## 문(WallDoors — 방 북쪽 벽에 뚫린 좁은 통로) 양옆 벽의 아래 모서리는 깎지 않는다(아치가 곧은 문설주에 얹힌다).
## 깎는 모서리 쪽에 낭떠러지(void)가 있으면 깎지 않는다 — 깎은 자리에 바닥 조각이 허공 위로 보인다.
const SMOOTH := 1
const ROUND := 2
const BEVEL := 3
const PIECE_ROW := 0     ## 줄 전체와 함께(칸 아래 가장자리로 정렬)
const PIECE_CUT := 1     ## 아래 모서리를 깎은 벽 칸(사선 위 끝 = 칸 위 + t − r)
const PIECE_FILLET := 2  ## 위쪽 오목 메움(사선 가운데 = 칸 위 + r/2)

const STEPS := 4

## build 결과: tops = [{x, poly(바닥 평면 월드 좌표), h}] · faces = [{x(탐험 확인 칸), a, b(바닥 평면 선분, 왼→오), def, v(변형), u0, u1, h}]
var tops: Array[Dictionary] = []
var floors: Array[Dictionary] = []  ## [{x, poly, def(옆 바닥 — 없으면 층 기본 바닥)}] 벽 칸의 깎은 아래쪽 모서리 삼각형 — 바닥 그림을 채운다(바닥은 바닥 칸에만 그려지므로)
var _bulge: float = 0.0
var faces: Array[Dictionary] = []


## smooth = map.defs 번호 -> 부드럽게 그리는 벽의 모양(SMOOTH·ROUND·BEVEL, 0 = 아님). variant(x, y, def) -> 앞면 변형.
static func build(map: FloorMap, row: int, x0: int, x1: int, t: float, r: float, smooth: PackedByteArray, face_h: Callable, variant: Callable, bulge: float = 0.0) -> WallShape:
	var s := WallShape.new()
	s._bulge = bulge
	for x in range(x0, x1):
		var p := Vector2i(x, row)
		var def := map.def_at(p)
		if def.is_wall():
			if smooth[def.index] != 0:
				s._wall_cell(map, p, t, r, def, smooth, face_h, variant)
		elif not def.is_void:
			s._fillets(map, p, t, r, smooth, face_h, variant)
	return s


static func _wall(map: FloorMap, p: Vector2i) -> bool:
	return not map.in_bounds(p) or map.is_wall(p)


## 모서리를 깎아도 되는 열린 칸(벽도 낭떠러지도 아님).
static func _open(map: FloorMap, p: Vector2i) -> bool:
	return map.in_bounds(p) and not map.is_wall(p) and not map.def_at(p).is_void


## BEVEL: 벽 칸 p의 볼록 모서리 c(바깥 대각선 방향)가 계단의 한 단인가 — 사선을 따라 이웃한 벽 칸도 같은 모서리가 열려 있다.
static func _stair(map: FloorMap, p: Vector2i, c: Vector2i, smooth: PackedByteArray) -> bool:
	for q: Vector2i in [p + Vector2i(-c.x, c.y), p + Vector2i(c.x, -c.y)]:
		if _smooth_wall(map, q, smooth) and _open(map, q + Vector2i(c.x, 0)) and _open(map, q + Vector2i(0, c.y)):
			return true
	return false


func _wall_cell(map: FloorMap, p: Vector2i, t: float, r: float, def: TileDef, smooth: PackedByteArray, face_h: Callable, variant: Callable) -> void:
	var mode := smooth[def.index]
	var n := not _wall(map, p + Vector2i(0, -1))
	var e := not _wall(map, p + Vector2i(1, 0))
	var so := not _wall(map, p + Vector2i(0, 1))
	var w := not _wall(map, p + Vector2i(-1, 0))
	var cut := {}  # 모서리(바깥 대각선 방향) -> 깎는가
	for c: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
		var k := _open(map, p + Vector2i(c.x, 0)) and _open(map, p + Vector2i(0, c.y))
		if k and c.y > 0 and WallDoors.is_door(map, p + Vector2i(c.x, 0), smooth):
			k = false  # 문설주는 곧게
		cut[c] = k and (mode != BEVEL or _stair(map, p, c, smooth))
	var bulge := 0.0 if mode == BEVEL else _bulge  # 지은 벽은 곧은 사선
	var h: int = face_h.call(def)
	var o := Vector2(p) * t
	var piece := PIECE_CUT if so and (cut[Vector2i(1, 1)] or cut[Vector2i(-1, 1)]) else PIECE_ROW
	var from_floor := floors.size()
	var poly := PackedVector2Array()
	# 시계 방향: 왼위 → 오위 → 오아래 → 왼아래. 볼록 모서리는 두 변 위 r 지점을 잇는 사선.
	_corner(poly, o, p.x, cut[Vector2i(-1, -1)], Vector2(0, r), Vector2(r, 0), Vector2.ZERO, bulge)
	_corner(poly, o, p.x, cut[Vector2i(1, -1)], Vector2(t - r, 0), Vector2(t, r), Vector2(t, 0), bulge)
	var own := mode != SMOOTH  # 균열 벽: 깎은 자리에 옆 바닥 그림(바닥이 여러 가지다) — 1층은 층 기본 바닥 그대로
	_corner(poly, o, p.x, cut[Vector2i(1, 1)], Vector2(t, t - r), Vector2(t - r, t), Vector2(t, t), bulge, _floor_near(map, p, Vector2i(1, 1)) if own else -1)
	_corner(poly, o, p.x, cut[Vector2i(-1, 1)], Vector2(r, t), Vector2(0, t - r), Vector2(0, t), bulge, _floor_near(map, p, Vector2i(-1, 1)) if own else -1)
	for i in range(from_floor, floors.size()):
		floors[i]["piece"] = piece
	if n or _open_behind(map, p, t, h):
		tops.append({"x": p.x, "poly": poly, "h": h, "piece": piece})
	if not so:
		return
	var v: int = variant.call(p.x, p.y, def)
	# 남쪽을 향한 윤곽: 아래쪽 모서리 사선 + 아래 변(왼→오 순서로)
	var pts := PackedVector2Array()
	if cut[Vector2i(-1, 1)]:
		_cut(pts, o + Vector2(0, t - r), o + Vector2(r, t), o + Vector2(0, t), bulge)  # 왼아래 사선
	else:
		pts.append(o + Vector2(0, t))
	if cut[Vector2i(1, 1)]:
		_cut(pts, o + Vector2(t - r, t), o + Vector2(t, t - r), o + Vector2(t, t), bulge)  # 오아래 사선
	else:
		pts.append(o + Vector2(t, t))
	_add_faces(pts, p.x, o.x, t, def.index, v, h, piece)


## 앞면이 칸보다 높은 벽(48px — AM63): 북쪽 벽 칸 너머의 바닥도 이 칸 윗면이 가린다 — 그 칸 윗면을 그려야 바닥이 띠로 비치지 않는다.
static func _open_behind(map: FloorMap, p: Vector2i, t: float, h: int) -> bool:
	var k := 2
	while (k - 1) * t < h:
		if not _wall(map, p + Vector2i(0, -k)):
			return true
		k += 1
	return false


## 깎은 아래 모서리 c에 채울 바닥: 남쪽 이웃(앞면이 서는 쪽), 아니면 옆 이웃의 바닥 타일 번호(-1 = 층 기본 바닥).
static func _floor_near(map: FloorMap, p: Vector2i, c: Vector2i) -> int:
	for q: Vector2i in [p + Vector2i(0, c.y), p + Vector2i(c.x, 0)]:
		if _open(map, q):
			return map.def_at(q).index
	return -1


## 바닥 칸의 오목 모서리 메움. 위쪽 메움(벽이 북·서 또는 북·동)은 남쪽을 향해 앞면 띠가 생기고,
## 아래쪽 메움(벽이 남·서 또는 남·동)은 윗면만(북쪽을 향하니 앞면은 보이지 않는다).
func _fillets(map: FloorMap, p: Vector2i, t: float, r: float, smooth: PackedByteArray, face_h: Callable, variant: Callable) -> void:
	var o := Vector2(p) * t
	for c: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var a := p + Vector2i(c.x, 0)
		var b := p + Vector2i(0, c.y)
		if not (_smooth_wall(map, a, smooth) and _smooth_wall(map, b, smooth) and _wall(map, p + c)):
			continue
		var wdef := map.def_at(a)
		var bevel := smooth[wdef.index] == BEVEL or smooth[map.def_at(b).index] == BEVEL
		if bevel and not (_open(map, p + Vector2i(c.x, -c.y)) and _open(map, p + Vector2i(-c.x, c.y))):
			continue  # 지은 벽: 계단 사이의 오목 자리만(방 안쪽 직각 모서리는 그대로)
		var corner := o + Vector2(t if c.x > 0 else 0.0, t if c.y > 0 else 0.0)
		var arc := PackedVector2Array()
		# 사선: 가로 이웃 쪽 변 위 r 지점 → 세로 이웃 쪽 변 위 r 지점(가운데는 모서리 쪽으로 살짝 — 움푹한 바위 굽이)
		_cut(arc, corner + Vector2(0, -c.y * r), corner + Vector2(-c.x * r, 0), corner, 0.0 if bevel else _bulge)
		var poly := PackedVector2Array([corner])
		poly.append_array(arc)
		var h: int = face_h.call(wdef)
		if c.y > 0:
			tops.append({"x": p.x, "poly": poly, "h": h, "fillet": true})
			continue
		# 위쪽 메움: 원호가 남쪽을 향한다 — 왼→오 순서로 앞면.
		var pts := arc.duplicate()
		if pts[0].x > pts[pts.size() - 1].x:
			pts.reverse()
		_add_faces(pts, p.x, o.x, t, wdef.index, variant.call(a.x, a.y, wdef), h, PIECE_FILLET)


static func _smooth_wall(map: FloorMap, p: Vector2i, smooth: PackedByteArray) -> bool:
	return map.in_bounds(p) and map.is_wall(p) and smooth[map.def_at(p).index] != 0


func _add_faces(pts: PackedVector2Array, x: int, ox: float, t: float, def_index: int, v: int, h: int, piece: int = PIECE_ROW) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if b.x - a.x < 0.01:  # 세로이거나 거꾸로 가는 선분은 앞면이 보이지 않는다
			continue
		faces.append({"x": x, "a": a, "b": b, "def": def_index, "v": v, "u0": clampf((a.x - ox) / t, 0.0, 1.0),
			"u1": clampf((b.x - ox) / t, 0.0, 1.0), "h": h, "piece": piece})


## 이 모양에 piece 묶음이 있는가.
func has_piece(piece: int) -> bool:
	for list: Array[Dictionary] in [tops, faces, floors]:
		for it in list:
			if int(it.get("piece", PIECE_ROW)) == piece:
				return true
	return false


## piece 묶음의 정렬 y(줄 위 가장자리에서 아래로 px). t = 칸, r = 깎는 폭. 1px 북쪽으로 — 사선 끝에 발이 닿아도 캐릭터가 앞.
static func piece_sort(piece: int, t: float, r: float) -> float:
	return (t - r - 1.0) if piece == PIECE_CUT else (r * 0.5 - 1.0)


## 모서리 하나: 깎으면 a → b 사선(가운데가 모서리 쪽으로 bulge만큼 휨), 아니면 모서리 점. floor_def = 깎은 아래 모서리에 채울 바닥(-1 = 기본).
func _corner(poly: PackedVector2Array, o: Vector2, cx: int, cut: bool, a: Vector2, b: Vector2, corner: Vector2, bulge: float, floor_def: int = -1) -> void:
	if not cut:
		poly.append(o + corner)
		return
	var from := poly.size()
	_cut(poly, o + a, o + b, o + corner, bulge)
	if corner.y > 0.0:  # 아래쪽(앞면 쪽) 모서리만 — 위쪽 모서리 자리는 바위 옆면이라 검게 둔다
		var tri := PackedVector2Array([o + corner])
		tri.append_array(poly.slice(from))
		floors.append({"x": cx, "poly": tri, "def": floor_def})


## a → b 사선을 STEPS 토막으로, 가운데를 corner 쪽으로 bulge(px)만큼 휘게 해 out에 더한다.
static func _cut(out: PackedVector2Array, a: Vector2, b: Vector2, corner: Vector2, bulge: float) -> void:
	var mid := (a + b) * 0.5
	var dir := (corner - mid).normalized() if corner != mid else Vector2.ZERO
	for k in STEPS + 1:
		var f := float(k) / STEPS
		out.append(a.lerp(b, f) + dir * bulge * sin(f * PI))
