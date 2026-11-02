class_name TownSolid
extends RefCounted
## 도시 동네 지도의 입체 그리기(CT82 — 2026-11-02 사용자 "건물이 컨테이너 박스 같고 지붕에서 입체감이 안 느껴진다 · 각도를 뒤틀어"):
## 집을 3D 면(벽·지붕·굴뚝·지붕창)으로 짓고, 게임 시점(3/4 — 바닥은 그대로, 높이 z는 화면 위로: 화면 = (x, y − z) × 칸)으로 눌러 그린다.
##   보이는 면만(카메라 쪽 — n.y + n.z > 0), 먼 면부터(y + z가 작은 것부터) · 면마다 빛(왼쪽 위 — render.json city.town.light) ·
##   재질 그림은 면 위 좌표로 붙인다(지붕 기와 줄이 처마와 나란하게) · 면 가장자리에 먹선. 벽에 붙는 창·문·들보는 그 벽 바로 뒤에 그린다(decal).
## 좌표: 칸(x 동, y 남, z 위). 노드 원점 y(px)를 빼서 그린다.

var tile: float = 32.0
var origin_y: float = 0.0
var light := Vector3(-0.55, 0.35, 0.76).normalized()
var ambient: float = 0.5
var diffuse: float = 0.62
var ink := Color(0.06, 0.05, 0.04, 0.7)
var _faces: Array[Dictionary] = []
## 그린 범위(세계 px — 가림·정렬).
var lo := Vector2(INF, INF)
var hi := Vector2(-INF, -INF)


func _init(p_tile: float, p_origin_y: float, render: Dictionary) -> void:
	tile = p_tile
	origin_y = p_origin_y
	var l := JsonUtil.get_array(TownBrush.cfg(render), "light")
	if l.size() == 3:
		light = Vector3(float(l[0]), float(l[1]), float(l[2])).normalized()
	ambient = TownBrush.num(render, "ambient", ambient)
	diffuse = TownBrush.num(render, "diffuse", diffuse)
	ink = TownBrush.col(render, "ink")
	ink.a = TownBrush.num(render, "ink_alpha", 0.7)


func project(p: Vector3) -> Vector2:
	var s := Vector2(p.x * tile, (p.y - p.z) * tile)
	lo = lo.min(s)
	hi = hi.max(s)
	return s - Vector2(0, origin_y)


static func normal_of(pts: PackedVector3Array) -> Vector3:
	var n := Vector3.ZERO
	for i in pts.size():  # 뉴웰 법
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		n += Vector3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
	return n.normalized()


## 면 하나(볼록, 바깥에서 보아 어느 방향 순서든 — 바깥쪽 법선 hint와 맞춘다). 카메라 반대쪽이면 버린다. 돌려줌: 면(장식을 덧붙일 때) 또는 {}.
func face(pts: PackedVector3Array, col: Color, mat: String, outward: Vector3, outline: bool = true) -> Dictionary:
	var n := normal_of(pts)
	if n.dot(outward) < 0.0:
		n = -n
	if n.y + n.z <= 0.02:
		return {}
	var f := {"pts": pts, "n": n, "col": col, "mat": mat, "outline": outline, "decals": [], "depth": _depth(pts)}
	_faces.append(f)
	return f


## 면에 붙는 장식(창·문·들보 — 그 면 바로 뒤에 그린다). pts는 면 위 3D 점.
func decal(f: Dictionary, pts: PackedVector3Array, col: Color, mat: String = "", lit: bool = true) -> void:
	if f.is_empty():
		return
	(f["decals"] as Array).append({"pts": pts, "col": col, "mat": mat, "lit": lit})


## 상자(굴뚝·탑·지붕창 몸) — 바닥 네 점(시계 반대) + 높이 z0~z1.
func box(base: PackedVector2Array, z0: float, z1: float, col: Color, mat: String, top_col: Color = Color(0, 0, 0, 0), top_mat: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c := Vector2.ZERO
	for p in base:
		c += p / base.size()
	for i in base.size():
		var a := base[i]
		var b := base[(i + 1) % base.size()]
		var mid := (a + b) * 0.5 - c
		out.append(face(PackedVector3Array([Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1)]),
			col, mat, Vector3(mid.x, mid.y, 0.0)))
	var top := PackedVector3Array()
	for p in base:
		top.append(Vector3(p.x, p.y, z1))
	out.append(face(top, top_col if top_col.a > 0.0 else col, top_mat if not top_mat.is_empty() else mat, Vector3(0, 0, 1)))
	return out


## 빛을 받은 색.
func lit(c: Color, n: Vector3) -> Color:
	return TownBrush.shade(c, ambient + diffuse * maxf(0.0, n.dot(light)))


## 지금까지 넣은 면의 화면 범위(세계 px).
func measure() -> Rect2:
	for f in _faces:
		for p: Vector3 in f["pts"]:
			project(p)
	return Rect2(lo, hi - lo)


static func _depth(pts: PackedVector3Array) -> float:
	var d := 0.0
	for p in pts:
		d += p.y + p.z
	return d / pts.size()


## 먼 면부터 그린다(장식은 제 면 바로 뒤, 먹선은 면마다).
func flush(b: TownBrush) -> void:
	_faces.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x["depth"]) < float(y["depth"]))
	for f in _faces:
		var n: Vector3 = f["n"]
		_draw_poly(b, f["pts"], lit(f["col"], n), str(f["mat"]), n)
		for d: Dictionary in f["decals"]:
			_draw_poly(b, d["pts"], lit(d["col"], n) if bool(d["lit"]) else d["col"], str(d["mat"]), n)
		if bool(f["outline"]):
			var pts: PackedVector3Array = f["pts"]
			for i in pts.size():
				b.line(project(pts[i]), project(pts[(i + 1) % pts.size()]), 1.1, ink)
	_faces.clear()


## 재질 좌표: 벽은 (수평, 아래로), 지붕은 (처마 방향, 내리막) — 기와 줄이 처마와 나란하다.
func _draw_poly(b: TownBrush, pts: PackedVector3Array, c: Color, mat: String, n: Vector3) -> void:
	var p2 := PackedVector2Array()
	for p in pts:
		p2.append(project(p))
	if mat.is_empty():
		b.poly(p2, c)
		return
	var eu := Vector3(-n.y, n.x, 0.0)
	eu = eu.normalized() if eu.length() > 0.05 else Vector3.RIGHT
	var ev := n.cross(eu).normalized()
	if ev.z > 0.0:
		ev = -ev
	if absf(n.z) > 0.97:
		ev = Vector3(0, 1, 0)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append(Vector2(p.dot(eu), p.dot(ev)) * tile)
	b.poly_uv(p2, c, uvs, mat)
