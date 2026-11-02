extends RefCounted
## 집 짓기 도구(3D — 사용자 2026-11-02 "건물의 다양한 바리에이션을 뽑는데 집중"): 면마다 횡스크롤 건물 붓(Paint)으로 그림을 그려 붙인 3D 조각.
## 좌표는 Godot(X 동, Y 위, Z 남), 1 = 지도 한 칸. 면은 볼록이 아니어도 된다(계단식 박공 — 삼각분할).
## 면 그림 틀: 곧은 면은 u = 밖에서 보아 오른쪽, v = 아래 · 기운 면은 u = 처마 방향, v = 내리막 · 수평 면은 u = 동, v = 남. 칸당 P px.
## 면은 앞뒤 두 벌(감는 방향만 반대, 법선은 같은 바깥쪽)로 넣고 뒷면 지우기 — 어느 쪽에서 보아도 빛이 맞다.
## painter: Callable(p: Paint, poly_px: PackedVector2Array, size_units: Vector2) — 면 꼴(px) 안을 칠한다.

const Paint := preload("res://tools/city_art/Paint.gd")

var root: Node3D
var P := 64.0
var _n := 0
## 지은 것의 범위(카메라 맞추기).
var lo := Vector3(INF, INF, INF)
var hi := Vector3(-INF, -INF, -INF)


func _init(p_root: Node3D, p_px: float = 64.0) -> void:
	root = p_root
	P = p_px


func face(pts: PackedVector3Array, hint: Vector3, painter: Callable) -> void:
	var n := Vector3.ZERO
	for i in pts.size():  # 뉴웰 법선, 바깥쪽(hint)으로
		var qa := pts[i]
		var qb := pts[(i + 1) % pts.size()]
		n += Vector3((qa.y - qb.y) * (qa.z + qb.z), (qa.z - qb.z) * (qa.x + qb.x), (qa.x - qb.x) * (qa.y + qb.y))
	n = n.normalized()
	if n.dot(hint) < 0.0:
		n = -n
	var u: Vector3
	var v: Vector3
	if absf(n.y) < 0.02:
		u = (-n).cross(Vector3.UP).normalized()
		v = Vector3.DOWN
	elif absf(n.y) > 0.98:
		u = Vector3.RIGHT
		v = Vector3(0, 0, 1)
	else:
		var nh := Vector3(n.x, 0, n.z).normalized()
		u = (-nh).cross(Vector3.UP).normalized()
		v = n.cross(u).normalized()
		if v.y > 0.0:
			v = -v
	var lmin := Vector2(INF, INF)
	var local := PackedVector2Array()
	for q in pts:
		var l := Vector2((q - pts[0]).dot(u), (q - pts[0]).dot(v))
		local.append(l)
		lmin = lmin.min(l)
	var size := Vector2.ZERO
	for i in local.size():
		local[i] -= lmin
		size = size.max(local[i])
	_n += 1
	var p := Paint.new(maxi(2, int(ceil(size.x * P)) + 2), maxi(2, int(ceil(size.y * P)) + 2), 1000 + _n * 17)
	var poly := PackedVector2Array()
	for l in local:
		poly.append(l * P + Vector2(1, 1))
	painter.call(p, poly, size)
	for q in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	var tris := Geometry2D.triangulate_polygon(local)
	if tris.is_empty():
		return
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var uvs := PackedVector2Array()
	var tex_size := Vector2(p.w, p.h)
	for side in 2:
		for t in range(0, tris.size(), 3):
			var ids := [tris[t], tris[t + 1], tris[t + 2]] if side == 0 else [tris[t], tris[t + 2], tris[t + 1]]
			for i: int in ids:
				vs.append(pts[i])
				ns.append(n)
				uvs.append((local[i] * P + Vector2(1, 1)) / tex_size)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(p.to_image())
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mat.roughness = 1.0
	mat.metallic_specular = 0.15
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)


## 곧은 벽 한 면: 바닥 두 점(밖에서 보아 왼쪽 a → 오른쪽 b) · 높이 y0~y1. 위에 박공 꼭짓점(top)이 있으면 오각.
func wall(a: Vector3, b: Vector3, y0: float, y1: float, painter: Callable, apex: float = -1.0) -> void:
	var n := (b - a).cross(Vector3.UP).normalized()
	if y1 <= y0 + 0.001:  # 박공 삼각만
		var m0 := (a + b) * 0.5
		face(PackedVector3Array([Vector3(a.x, y0, a.z), Vector3(b.x, y0, b.z), Vector3(m0.x, apex, m0.z)]), n, painter)
		return
	var pts := PackedVector3Array([Vector3(a.x, y0, a.z), Vector3(b.x, y0, b.z), Vector3(b.x, y1, b.z)])
	if apex > y1:
		var m := (a + b) * 0.5
		pts.append(Vector3(m.x, apex, m.z))
	pts.append(Vector3(a.x, y1, a.z))
	face(pts, n, painter)


## 상자(벽 넷 + 윗면). painters: {"s","e","n","w","top"} — 없으면 default. 바닥 x0..x1 · z0..z1.
func box(x0: float, z0: float, x1: float, z1: float, y0: float, y1: float, painters: Dictionary, default: Callable) -> void:
	var c := [Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(x1, 0, z0), Vector3(x0, 0, z0)]  # 남서 · 남동 · 북동 · 북서
	var sides := ["s", "e", "n", "w"]
	for i in 4:
		wall(c[i], c[(i + 1) % 4], y0, y1, painters.get(sides[i], default))
	if painters.has("top"):
		face(PackedVector3Array([Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1)]), Vector3.UP, painters["top"])


## 박공 지붕: 바닥 x0..x1 · z0..z1, 처마 높이 y, 마루 올림 rise, along_x = 마루가 동서. over = 처마 내밈. 박공 벽(삼각)은 gable 그림.
func gable_roof(x0: float, z0: float, x1: float, z1: float, y: float, rise: float, along_x: bool, over: float, roof: Callable, gable: Callable) -> void:
	var ox0 := x0 - over
	var ox1 := x1 + over
	var oz0 := z0 - over
	var oz1 := z1 + over
	var ye := y - over * rise / ((z1 - z0) * 0.5 if along_x else (x1 - x0) * 0.5)
	if along_x:
		var zm := (z0 + z1) * 0.5
		face(PackedVector3Array([Vector3(ox0, ye, oz1), Vector3(ox1, ye, oz1), Vector3(ox1, y + rise, zm), Vector3(ox0, y + rise, zm)]), Vector3(0, 1, 1) * Vector3(1, (z1 - z0) * 0.5, rise), roof)
		face(PackedVector3Array([Vector3(ox1, ye, oz0), Vector3(ox0, ye, oz0), Vector3(ox0, y + rise, zm), Vector3(ox1, y + rise, zm)]), Vector3(0, (z1 - z0) * 0.5, -rise), roof)
		wall(Vector3(x1, 0, z1), Vector3(x1, 0, z0), y, y, gable, y + rise)
		wall(Vector3(x0, 0, z0), Vector3(x0, 0, z1), y, y, gable, y + rise)
	else:
		var xm := (x0 + x1) * 0.5
		face(PackedVector3Array([Vector3(ox1, ye, oz1), Vector3(ox1, ye, oz0), Vector3(xm, y + rise, oz0), Vector3(xm, y + rise, oz1)]), Vector3(rise, (x1 - x0) * 0.5, 0), roof)
		face(PackedVector3Array([Vector3(ox0, ye, oz0), Vector3(ox0, ye, oz1), Vector3(xm, y + rise, oz1), Vector3(xm, y + rise, oz0)]), Vector3(-rise, (x1 - x0) * 0.5, 0), roof)
		wall(Vector3(x0, 0, z1), Vector3(x1, 0, z1), y, y, gable, y + rise)
		wall(Vector3(x1, 0, z0), Vector3(x0, 0, z0), y, y, gable, y + rise)


## 모임지붕(정사각이면 뿔지붕).
func hip_roof(x0: float, z0: float, x1: float, z1: float, y: float, rise: float, over: float, roof: Callable) -> void:
	var a := Vector3(x0 - over, y - over * 0.6, z1 + over)
	var b := Vector3(x1 + over, y - over * 0.6, z1 + over)
	var c := Vector3(x1 + over, y - over * 0.6, z0 - over)
	var d := Vector3(x0 - over, y - over * 0.6, z0 - over)
	var w := x1 - x0
	var dd := z1 - z0
	var r0: Vector3
	var r1: Vector3
	if w >= dd:
		r0 = Vector3(x0 + dd * 0.5, y + rise, (z0 + z1) * 0.5)
		r1 = Vector3(x1 - dd * 0.5, y + rise, (z0 + z1) * 0.5)
	else:
		r0 = Vector3((x0 + x1) * 0.5, y + rise, z1 - w * 0.5)
		r1 = Vector3((x0 + x1) * 0.5, y + rise, z0 + w * 0.5)
	if w >= dd:
		face(_pts([a, b, r1, r0]), Vector3(0, 1, 1), roof)
		face(_pts([c, d, r0, r1]), Vector3(0, 1, -1), roof)
		face(_pts([b, c, r1]), Vector3(1, 1, 0), roof)
		face(_pts([d, a, r0]), Vector3(-1, 1, 0), roof)
	else:
		face(_pts([a, b, r0]), Vector3(0, 1, 1), roof)
		face(_pts([c, d, r1]), Vector3(0, 1, -1), roof)
		face(_pts([b, c, r1, r0]), Vector3(1, 1, 0), roof)
		face(_pts([d, a, r0, r1]), Vector3(-1, 1, 0), roof)


## 외쪽지붕: 북쪽이 높다.
func shed_roof(x0: float, z0: float, x1: float, z1: float, y_low: float, y_high: float, over: float, roof: Callable, side: Callable) -> void:
	face(_pts([Vector3(x0 - over, y_low, z1 + over), Vector3(x1 + over, y_low, z1 + over), Vector3(x1 + over, y_high, z0 - over), Vector3(x0 - over, y_high, z0 - over)]), Vector3(0, z1 - z0, y_high - y_low), roof)
	face(_pts([Vector3(x1, y_low, z1), Vector3(x1, y_low, z0), Vector3(x1, y_high, z0)]), Vector3.RIGHT, side)
	face(_pts([Vector3(x0, y_low, z0), Vector3(x0, y_low, z1), Vector3(x0, y_high, z0)]), Vector3.LEFT, side)
	wall(Vector3(x1, 0, z0), Vector3(x0, 0, z0), y_low, y_high, side)


## 각뿔 지붕(탑 첨탑): 바닥 사각 + 높이 h.
func pyramid(x0: float, z0: float, x1: float, z1: float, y: float, h: float, over: float, roof: Callable) -> void:
	var top := Vector3((x0 + x1) * 0.5, y + h, (z0 + z1) * 0.5)
	var cs := [Vector3(x0 - over, y, z1 + over), Vector3(x1 + over, y, z1 + over), Vector3(x1 + over, y, z0 - over), Vector3(x0 - over, y, z0 - over)]
	for i in 4:
		var a: Vector3 = cs[i]
		var b: Vector3 = cs[(i + 1) % 4]
		var m := (a + b) * 0.5 - Vector3(top.x, y, top.z)
		face(_pts([a, b, top]), Vector3(m.x, h * 0.3, m.z), roof)


## 둥근 벽(탑): 조각 segs개, painter_i(i) → 조각마다 그림.
func cylinder(cx: float, cz: float, r: float, y0: float, y1: float, segs: int, painter_i: Callable) -> void:
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var pa := Vector3(cx + cos(a1) * r, 0, cz + sin(a1) * r)
		var pb := Vector3(cx + cos(a0) * r, 0, cz + sin(a0) * r)
		wall(pa, pb, y0, y1, painter_i.call(i))


## 원뿔 지붕.
func cone(cx: float, cz: float, r: float, y: float, h: float, segs: int, roof: Callable) -> void:
	var top := Vector3(cx, y + h, cz)
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var am := (a0 + a1) * 0.5
		face(_pts([Vector3(cx + cos(a1) * r, y, cz + sin(a1) * r), Vector3(cx + cos(a0) * r, y, cz + sin(a0) * r), top]), Vector3(cos(am), r / h, sin(am)), roof)


static func _pts(a: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for q: Vector3 in a:
		out.append(q)
	return out
