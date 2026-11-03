extends RefCounted
## 동네 집 한 채를 집 키트 바리에이션(tools/town_kit/Designs — 손그림 집)으로 세운다(CT95 · CT97).
## 3/4 구상 그림(tools/town_v3_render.gd)과 게임 집 그림 굽기(tools/paint_town_hand.gd)가 같은 집을 쓰게 한 곳에 둔다.
##   보통 집: 바닥 크기가 가장 가까운 바리에이션(같은 크기면 집 번호로 돌려 가며 · 6칸보다 높은 것은 덜 고른다) → 필지에 맞게 늘이고 각도대로 돌린다.
##   시설: 길드 = v17 · 신전 = 예배당(크게) · 은행 = 맨사드 · 여관 = 회랑 집 · 잡화점 = 가게집 · 대장간 = 공방 · 도서관 = 원형 열람당(원기둥 + 돔).
## 좌표: 칸(X 동, Y 위, Z 남) — 지도 칸(x, y)이 그대로 (X, Z). 땅 높이는 부르는 쪽이 더한다.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Designs := preload("res://tools/town_kit/Designs.gd")

## 보통 집으로 쓸 바리에이션(탑 · 종탑 · 예배당은 빼고 — 3/4에서는 높이가 줄지 않아 탑처럼 솟는다).
const HOUSE_FNS := ["_narrow_jetty", "_eaves_dormers", "_tall_hip", "_cross_gable", "_arch_house", "_shop_house",
	"_gallery_house", "_mansard", "_step_gable", "_workshop", "_manor"]
const TALL := 6.0  ## 이보다 높은 바리에이션은 덜 고른다(칸)
const FAC_FNS := {"guild": "_guild", "temple": "_chapel", "bank": "_mansard", "inn": "_gallery_house", "shop": "_shop_house", "smithy": "_workshop"}

static var _tpl := {}


## 바리에이션 원본(한 번만 짓는다): [Node3D, lo, hi].
static func template(fn: String) -> Array:
	if not _tpl.has(fn):
		var holder := Node3D.new()
		var k := Kit.new(holder, 64.0)
		Designs.new().call(fn, k)
		_tpl[fn] = [holder, k.lo, k.hi]
	return _tpl[fn]


static func clear() -> void:
	for key: String in _tpl:
		((_tpl[key] as Array)[0] as Node3D).free()
	_tpl.clear()


static func mat(name: String, tint: Color, scale: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/town/mat/%s.webp" % name) as Texture2D
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 1.0
	m.metallic_specular = 0.1
	m.vertex_color_use_as_albedo = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


## 집 한 채(땅 높이 0) — 지도 집 i번째(TownMap.houses[i]).
static func make(h: Dictionary, i: int) -> Node3D:
	var fac := str(h.get("facility", ""))
	if fac == "library":
		return _rotunda(h)
	var size: Vector2 = h.get("size", Vector2(4, 4))
	var ctr: Vector2 = h.get("center", Vector2.ZERO)
	var fn := str(FAC_FNS.get(fac, ""))
	if fn.is_empty():
		var best: Array = []
		for f: String in HOUSE_FNS:
			var t: Array = template(f)
			var w: float = (t[2] as Vector3).x - (t[1] as Vector3).x
			var d: float = (t[2] as Vector3).z - (t[1] as Vector3).z
			best.append([absf(log(w / size.x)) + absf(log(d / size.y)) + 0.25 * maxf(0.0, (t[2] as Vector3).y - TALL), f])
		best.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		fn = str(best[i % 3][1])
	var tp: Array = template(fn)
	var lo: Vector3 = tp[1]
	var hi: Vector3 = tp[2]
	var sx := size.x / (hi.x - lo.x) * 1.1  # 바리에이션 크기엔 처마 · 디딤돌이 들어 있어 벽이 필지보다 작아진다 — 조금 키워 필지를 채운다
	var sz := size.y / (hi.z - lo.z) * 1.1
	if not fac.is_empty():  # 시설은 비율을 지킨다(신전 · 은행이 일그러지지 않게)
		sx = minf(sx, sz) if fac != "temple" else maxf(sx, sz) * 0.9
		sz = sx
	var node := (tp[0] as Node3D).duplicate() as Node3D
	var a := float(h.get("angle", 0.0))
	var sy := clampf(sqrt(sx * sz), 0.72, 1.25)  # 필지 크기를 따라 높이도 조금(작으면 탑처럼 솟지 않게 · 크면 큰 집답게 — CT96)
	if fac == "temple":
		sy = minf(sqrt(sx * sz), 1.3)
	var basis := Basis(Vector3.UP, -a) * Basis.from_scale(Vector3(sx, sy, sz))
	var mid := Vector3((lo.x + hi.x) * 0.5, 0.0, (lo.z + hi.z) * 0.5)
	if i % 2 == 1 and fac.is_empty():  # 좌우 뒤집기(같은 집이 덜 되풀이되어 보이게)
		basis = basis * Basis.from_scale(Vector3(-1, 1, 1))
		mid.x = -mid.x
	node.transform = Transform3D(basis, Vector3(ctr.x, 0.0, ctr.y) - basis * mid)
	return node


static func _rotunda(h: Dictionary) -> Node3D:
	var c: Array = h["circle"]
	var holder := Node3D.new()
	holder.position = Vector3(float(c[0]), 0.0, float(c[1]))
	var r := float(c[2])
	var parts := [
		[_cyl(r * 0.92, 5.4), Vector3(0, 2.7, 0), mat("ashlar", Color("#b9b0a0"), 0.5)],
		[_cyl(r * 0.62, 1.4), Vector3(0, 6.1, 0), mat("plaster", Color("#c8bea8"), 0.5)],
	]
	var sm := SphereMesh.new()
	sm.radius = r * 0.66
	sm.height = r * 0.66
	sm.is_hemisphere = true
	sm.radial_segments = 48
	parts.append([sm, Vector3(0, 6.8, 0), mat("lead", Color("#6a7480"), 0.6)])
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.9, 0.3)
	parts.append([bm, Vector3(0, 0.95, r * 0.92), mat("wood", Color("#4a3426"), 0.8)])
	for p: Array in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p[0]
		mi.position = p[1]
		mi.material_override = p[2]
		holder.add_child(mi)
	return holder


static func _cyl(r: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 48
	return cm
