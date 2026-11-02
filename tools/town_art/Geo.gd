extends RefCounted
## 동네 집 굽기(tools/paint_town.gd --houses)의 모양: 집 한 채(TownMap 집 사전)를 3D 면으로 —
## 면마다 종류(wall · gable · roof · dormer · chimney · 시설 면)와 면 위 2D 좌표틀(o + u·lu + v·lv, 칸)을 붙인다.
## 화가(Elev)는 그 틀에서 횡스크롤 건물처럼 평평한 입면도를 그리고, Warp가 게임 시점(화면 = (x, y − z))으로 옮겨 붙인다.
## 크기 값은 render.json city.town(storey · base · roof_pitch · facility_pitch · overhang)과 같은 것을 쓴다(게임 TownHouse와 같은 집).

var faces: Array[Dictionary] = []
var storey := 1.0
var base := 0.2
var pitch := 1.15
var facility_pitch := 0.8
var overhang := 0.28


func _init(render: Dictionary) -> void:
	var c: Dictionary = GameDatabase.single(render, "city.town", {})
	storey = JsonUtil.get_float(c, "storey", storey)
	base = JsonUtil.get_float(c, "base", base)
	pitch = JsonUtil.get_float(c, "roof_pitch", pitch)
	facility_pitch = JsonUtil.get_float(c, "facility_pitch", facility_pitch)
	overhang = JsonUtil.get_float(c, "overhang", overhang)


static func normal_of(pts: PackedVector3Array) -> Vector3:
	var n := Vector3.ZERO
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		n += Vector3((a.y - b.y) * (a.z + b.z), (a.z - b.z) * (a.x + b.x), (a.x - b.x) * (a.y + b.y))
	return n.normalized()


## 면 하나 — 카메라 쪽(n.y + n.z > 0.03)만 남긴다. 틀: 벽은 u = 밖에서 보아 오른쪽(수평), v = 아래 · 지붕은 u = 처마 방향, v = 내리막.
func add(kind: String, pts: PackedVector3Array, outward: Vector3, info: Dictionary = {}) -> Dictionary:
	var n := normal_of(pts)
	if n.dot(outward) < 0.0:
		n = -n
	if n.y + n.z <= 0.03:
		return {}
	var u: Vector3
	var v: Vector3
	if absf(n.z) > 0.97:
		u = Vector3.RIGHT
		v = Vector3(0, 1, 0)
	elif absf(n.z) < 0.3:
		u = Vector3(0, 0, 1).cross(-Vector3(n.x, n.y, 0).normalized()).normalized()
		v = Vector3(0, 0, -1)
	else:
		var nh := Vector3(n.x, n.y, 0).normalized()
		u = Vector3(0, 0, 1).cross(-nh).normalized()
		v = n.cross(u).normalized()
		if v.z > 0.0:
			v = -v
	var lo := Vector2(INF, INF)
	var local := PackedVector2Array()
	for p in pts:
		var l := Vector2((p - pts[0]).dot(u), (p - pts[0]).dot(v))
		local.append(l)
		lo = lo.min(l)
	var size := Vector2.ZERO
	for i in local.size():
		local[i] -= lo
		size = size.max(local[i])
	var o := pts[0] + u * lo.x + v * lo.y
	var f := {"kind": kind, "pts": pts, "n": n, "o": o, "u": u, "v": v, "local": local, "size": size, "info": info,
		"depth": _depth(pts)}
	faces.append(f)
	return f


static func _depth(pts: PackedVector3Array) -> float:
	var d := 0.0
	for p in pts:
		d += p.y + p.z
	return d / pts.size()


static func quad_v(a: Vector2, b: Vector2, z0: float, z1: float) -> PackedVector3Array:
	return PackedVector3Array([Vector3(a.x, a.y, z0), Vector3(b.x, b.y, z0), Vector3(b.x, b.y, z1), Vector3(a.x, a.y, z1)])


static func corners(h: Dictionary) -> PackedVector2Array:
	var c: Vector2 = h.get("center", Vector2.ZERO)
	var s: Vector2 = h.get("size", Vector2.ONE)
	var a := float(h.get("angle", 0.0))
	var ax := Vector2(cos(a), sin(a)) * s.x * 0.5
	var ay := Vector2(-sin(a), cos(a)) * s.y * 0.5
	return PackedVector2Array([c - ax - ay, c + ax - ay, c + ax + ay, c - ax + ay])


func wall_height(h: Dictionary) -> float:
	return int(h.get("floors", 2)) * storey + base


## 상자 집: 벽 넷(가장 남쪽을 보는 벽 = 앞 — 문) · 박공 또는 모임지붕 · 박공 벽 · 지붕창 · 굴뚝.
func house(h: Dictionary) -> void:
	var cs := corners(h)
	var c: Vector2 = h["center"]
	var hgt := wall_height(h)
	var fi := 0
	for i in 4:
		if ((cs[i] + cs[(i + 1) % 4]) * 0.5 - c).normalized().y > ((cs[fi] + cs[(fi + 1) % 4]) * 0.5 - c).normalized().y:
			fi = i
	for i in 4:
		var a := cs[i]
		var b := cs[(i + 1) % 4]
		var out := (a + b) * 0.5 - c
		add("wall", quad_v(a, b, 0.0, hgt), Vector3(out.x, out.y, 0), {"front": i == fi, "floors": int(h.get("floors", 2))})
	_roof(h, c, hgt)


func _roof(h: Dictionary, c: Vector2, hgt: float) -> void:
	var size: Vector2 = h["size"]
	var a := float(h.get("angle", 0.0))
	var ax := Vector2(cos(a), sin(a))
	var ay := Vector2(-sin(a), cos(a))
	var along_x := (size.x >= size.y) == bool(h.get("ridge_long", true))
	var r := ax if along_x else ay
	var p := ay if along_x else ax
	var hr := (size.x if along_x else size.y) * 0.5
	var hp := (size.y if along_x else size.x) * 0.5
	var o := overhang
	var rise := hp * (facility_pitch if not str(h.get("facility", "")).is_empty() else pitch)
	var ze := hgt - 0.05
	var zr := hgt + rise
	var e := func(i: float, j: float) -> Vector3:
		var q: Vector2 = c + r * (hr + o) * i + p * (hp + o) * j
		return Vector3(q.x, q.y, ze)
	var hip := str(h.get("roof", "gable")) == "hip"
	var rl := maxf(0.0, hr - hp) if hip else hr + o
	var q0 := Vector3(c.x - r.x * rl, c.y - r.y * rl, zr)
	var q1 := Vector3(c.x + r.x * rl, c.y + r.y * rl, zr)
	add("roof", PackedVector3Array([e.call(-1.0, 1.0), e.call(1.0, 1.0), q1, q0]), Vector3(p.x, p.y, 1.0))
	add("roof", PackedVector3Array([e.call(1.0, -1.0), e.call(-1.0, -1.0), q0, q1]), Vector3(-p.x, -p.y, 1.0))
	if hip:
		add("roof", PackedVector3Array([e.call(-1.0, -1.0), e.call(-1.0, 1.0), q0]), Vector3(-r.x, -r.y, 1.0))
		add("roof", PackedVector3Array([e.call(1.0, 1.0), e.call(1.0, -1.0), q1]), Vector3(r.x, r.y, 1.0))
	else:
		for k: float in [-1.0, 1.0]:
			var w0 := c + r * hr * k - p * hp
			var w1 := c + r * hr * k + p * hp
			var top := c + r * hr * k
			add("gable", PackedVector3Array([Vector3(w0.x, w0.y, hgt), Vector3(w1.x, w1.y, hgt), Vector3(top.x, top.y, zr - 0.08)]), Vector3(r.x * k, r.y * k, 0))
	var side := 1.0 if p.y >= 0.0 else -1.0
	var look := int(h.get("look", 0))
	if hp >= 1.5 and hr >= 1.4 and look % 3 != 0:
		_dormer(c, r, p * side, hp, o, ze, zr)
	if look % 4 != 0:
		var at := c + r * hr * (0.45 if look % 2 == 0 else -0.45) - p * side * hp * 0.25
		var q := Vector2(-r.y, r.x)
		var w := 0.22
		var b := PackedVector2Array([at - r * w - q * w, at + r * w - q * w, at + r * w + q * w, at - r * w + q * w])
		box("chimney", b, hgt + rise * 0.5, zr + 0.6)


## 지붕창: 경사면 위의 작은 앞벽(창) + 작은 박공 지붕(큰 지붕에 닿을 때까지).
func _dormer(c: Vector2, r: Vector2, p: Vector2, hp: float, o: float, ze: float, zr: float) -> void:
	var span := hp + o
	var t := hp * 0.55
	var hw := 0.4
	var g := c + p * t
	var zb := zr - (zr - ze) * t / span
	var zt := zb + 0.6
	var apex := zt + 0.34
	var t2 := (zr - apex) * span / (zr - ze)
	var t3 := (zr - zt) * span / (zr - ze)
	var gl := g - r * hw
	var gr := g + r * hw
	add("dormer", PackedVector3Array([Vector3(gl.x, gl.y, zb), Vector3(gr.x, gr.y, zb), Vector3(gr.x, gr.y, zt), Vector3(g.x, g.y, apex), Vector3(gl.x, gl.y, zt)]), Vector3(p.x, p.y, 0))
	var e := hw + 0.1
	var gb := c + p * t2
	var ll := c + p * t3 - r * e
	var lr := c + p * t3 + r * e
	var fl := g - r * e + p * 0.06
	var fr := g + r * e + p * 0.06
	var ap := g + p * 0.06
	add("roof", PackedVector3Array([Vector3(fl.x, fl.y, zt - 0.04), Vector3(ap.x, ap.y, apex + 0.04), Vector3(gb.x, gb.y, apex + 0.04), Vector3(ll.x, ll.y, zt - 0.04)]), Vector3(-r.x, -r.y, 1.0), {"small": true})
	add("roof", PackedVector3Array([Vector3(ap.x, ap.y, apex + 0.04), Vector3(fr.x, fr.y, zt - 0.04), Vector3(lr.x, lr.y, zt - 0.04), Vector3(gb.x, gb.y, apex + 0.04)]), Vector3(r.x, r.y, 1.0), {"small": true})


## 상자(굴뚝·탑·기둥): 바닥 네 점(시계 반대) + 높이 z0~z1. 옆면 kind, 윗면 kind + "_top".
func box(kind: String, b: PackedVector2Array, z0: float, z1: float, info: Dictionary = {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c := Vector2.ZERO
	for q in b:
		c += q / b.size()
	for i in b.size():
		var a := b[i]
		var bb := b[(i + 1) % b.size()]
		var m := (a + bb) * 0.5 - c
		out.append(add(kind, quad_v(a, bb, z0, z1), Vector3(m.x, m.y, 0), info))
	var top := PackedVector3Array()
	for q in b:
		top.append(Vector3(q.x, q.y, z1))
	out.append(add(kind + "_top", top, Vector3(0, 0, 1), info))
	return out
