extends RefCounted
## 동네 집 한 채를 집 키트 바리에이션(tools/town_kit/Designs — 손그림 집)으로 세운다(CT95 · CT97).
## 3/4 구상 그림(tools/town_v3_render.gd)과 게임 집 그림 굽기(tools/paint_town_hand.gd)가 같은 집을 쓰게 한 곳에 둔다.
##   보통 집: 바닥 크기가 가장 가까운 바리에이션(같은 크기면 집 번호로 돌려 가며 · 6칸보다 높은 것은 덜 고른다) → 필지에 맞게 늘이고 각도대로 돌린다.
##   시설: 길드 = v17 · 신전 = 예배당(크게) · 은행 = 맨사드 · 여관 = 회랑 집 · 잡화점 = 가게집 · 대장간 = 공방 · 도서관 = 원형 열람당(원기둥 + 돔).
## 좌표: 칸(X 동, Y 위, Z 남) — 지도 칸(x, y)이 그대로 (X, Z). 땅 높이는 부르는 쪽이 더한다.

const Kit := preload("res://tools/town_kit/Kit.gd")
const Designs := preload("res://tools/town_kit/Designs2.gd")  # Designs + 3차 개선 건물(CT103)
const Mat := preload("res://tools/city_art/Mat.gd")
const F := preload("res://tools/town_kit/Facade.gd")

## 보통 집으로 쓸 바리에이션(탑 · 종탑 · 예배당은 빼고 — 3/4에서는 높이가 줄지 않아 탑처럼 솟는다).
const HOUSE_FNS := ["_narrow_jetty", "_eaves_dormers", "_tall_hip", "_cross_gable", "_arch_house", "_shop_house2",
	"_gallery_house", "_mansard", "_step_gable", "_workshop", "_manor"]
## 구역마다 고르는 바리에이션(사용자 3차 개선 "구역별 건축물 차별화", CT103): 윗단 행정 · 종교 = 큰 석조, 광장 · 시장 = 가게 · 차양,
## 좌우 주거 = 반목조 주택 · 작은 공방, 강변 = 창고 · 공방. 이웃(집 번호가 하나 차이)은 늘 다른 바리에이션(i % 3).
const ZONE_FNS := {
	"civic": ["_mansard", "_manor", "_tall_hip", "_step_gable"],
	"market": ["_shop_house2", "_corner_shop", "_gallery_house", "_arch_house", "_eaves_dormers"],
	"res": ["_narrow_jetty", "_row_timber", "_eaves_dormers", "_cross_gable", "_gallery_house", "_arch_house", "_workshop"],
	"river": ["_warehouse", "_workshop", "_row_timber", "_eaves_dormers"],
}
const ZONE_ROOF := {"civic": ["grey", "dark", "grey"], "market": ["red", "brown", "red", "dark"], "res": ["brown", "dark", "brown", "red", "brown"],
	"river": ["dark", "grey", "brown"]}
const TALL := 6.0  ## 이보다 높은 바리에이션은 덜 고른다(칸)
const FAC_FNS := {"library": "_museum", "guild": "_guild", "temple": "_cathedral", "bank": "_bank", "inn": "_inn", "shop": "_shop_house2", "smithy": "_workshop"}
## 퀘스트 자리 집의 꼴(가게는 간판 · 차양, 초소는 돌집, 창고 · 공방은 외쪽지붕 — CT98).
const PLACE_FNS := {"tavern": "_gallery_house", "herbalist": "_shop_house2", "pawnshop": "_shop_house2", "guard_post": "_mansard",
	"poorhouse": "_eaves_dormers", "abandoned_house": "_narrow_jetty", "warehouse": "_warehouse", "gate": "_tall_hip"}
## 지붕 기운(어두운 갈색 밑색 Facade.ROOF에 곱한다 — 예전 색감 안에서만 조금씩: 갈색 · 붉은 갈색 · 잿빛 · 짙은 갈색, CT99).
const ROOF_TINTS := {"brown": Color(1.0, 1.0, 1.0), "red": Color(1.12, 0.92, 0.84), "grey": Color(0.9, 0.96, 1.06), "dark": Color(0.82, 0.8, 0.78),
	"pale": Color(1.8, 2.1, 2.5), "slate": Color(0.96, 1.12, 1.38), "crimson": Color(1.3, 0.84, 0.72)}
## 시설 지붕 · 외벽 기운(사용자 2026-11-03 "주요 건물은 다른 건물과 비교되게 — 신전은 비교적 하얀 색감", CT104):
## 신전 = 흰 석회석 벽 · 옅은 잿빛 지붕, 도서관 = 따뜻한 사암 · 구리 돔, 은행 = 옅은 잿돌 · 청회색 슬레이트, 길드 = 짙은 돌 · 검붉은 지붕,
## 여관 = 따뜻한 벽 · 붉은 지붕, 잡화점 = 붉은 지붕, 대장간 = 그을린 벽 · 짙은 지붕. 외벽 기운은 지붕이 아닌 면에 곱한다(1보다 크면 밝게).
const FAC_ROOF := {"guild": "crimson", "temple": "pale", "bank": "slate", "inn": "red", "shop": "red", "smithy": "dark", "library": "slate"}
const FAC_WALL := {"temple": Color(1.95, 1.98, 2.05), "library": Color(1.6, 1.42, 1.1), "bank": Color(1.26, 1.26, 1.3), "guild": Color(0.84, 0.82, 0.82),
	"inn": Color(1.12, 1.02, 0.88), "smithy": Color(0.74, 0.7, 0.68)}

static var _tpl := {}


## 바리에이션 원본(한 번만 짓는다): [Node3D, lo, hi].
static func template(fn: String) -> Array:
	if not _tpl.has(fn):
		Mat.glass_dark = [Color("#4f5e58"), Color("#121816")]  # 창유리: 예전 어두운 녹회색에 아주 조금 청록(CT99)
		var holder := Node3D.new()
		var k := Kit.new(holder, F.P)  # 면 그림 해상도 = 붓 기준(Facade.P — CT109: 64로 남아 장식이 1.5배로 부풀었다)
		Designs.new().call(fn, k)
		_tpl[fn] = [holder, k.lo, k.hi, k.doors]
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
	if fac == "library" and h.has("circle"):  # 옛 원형 열람당 지도(v3)
		return _rotunda(h)
	var size: Vector2 = h.get("size", Vector2(4, 4))
	var ctr: Vector2 = h.get("center", Vector2.ZERO)
	var fn := str(FAC_FNS.get(fac, PLACE_FNS.get(str(h.get("place", "")), "")))
	var zone := str(h.get("zone", ""))
	if zone == "townhall":
		fn = "_town_hall"
	if fn.is_empty():
		var best: Array = []
		for f: String in ZONE_FNS.get(zone, HOUSE_FNS):
			var t: Array = template(f)
			var w: float = (t[2] as Vector3).x - (t[1] as Vector3).x
			var d: float = (t[2] as Vector3).z - (t[1] as Vector3).z
			best.append([absf(log(w / size.x)) + absf(log(d / size.y)) + 0.25 * maxf(0.0, (t[2] as Vector3).y - TALL), f])
		best.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		fn = str(best[i % 3][1])
	var tp: Array = template(fn)
	var lo: Vector3 = tp[1]
	var hi: Vector3 = tp[2]
	# 필지에 맞춘다(처마 · 디딤돌까지 필지 안 — 벽이 충돌 칸 밖으로 나가지 않게, CT98)
	var sx := size.x / (hi.x - lo.x)
	var sz := size.y / (hi.z - lo.z)
	if not fac.is_empty() and fac != "temple":  # 시설은 비율을 지킨다(일그러지지 않게)
		sx = minf(sx, sz)
		sz = sx
	var node := (tp[0] as Node3D).duplicate() as Node3D
	var a := float(h.get("angle", 0.0))
	var sy := clampf(sqrt(sx * sz), 0.8, 1.2)  # 필지 크기를 따라 높이도 조금(작으면 탑처럼 솟지 않게 · 크면 큰 집답게)
	if fac == "temple":
		sy = 1.1
	var basis := Basis(Vector3.UP, -a) * Basis.from_scale(Vector3(sx, sy, sz))
	var mid := Vector3((lo.x + hi.x) * 0.5, 0.0, (lo.z + hi.z) * 0.5)
	if i % 2 == 1 and fac.is_empty():  # 좌우 뒤집기(같은 집이 덜 되풀이되어 보이게)
		basis = basis * Basis.from_scale(Vector3(-1, 1, 1))
		mid.x = -mid.x
	node.transform = Transform3D(basis, Vector3(ctr.x, 0.0, ctr.y) - basis * mid)
	var doors := PackedVector3Array()  # 문 앞 디딤돌(세계 칸 — tools/town_doors.gd, CT110)
	for q: Vector3 in (tp[3] as Array):
		doors.append(node.transform * q)
	node.set_meta("doors", doors)
	node.set_meta("design", fn)
	var tint: Color = ROOF_TINTS[_roof_of(h, i)]
	var wall: Color = FAC_WALL.get(fac, Color.WHITE)
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var roof := (mi as MeshInstance3D).has_meta("roof")
		if roof or wall != Color.WHITE:
			var m := ((mi as MeshInstance3D).material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			m.albedo_color = tint if roof else wall
			(mi as MeshInstance3D).material_override = m
	return node


## 이 집의 지붕 색 이름: 시설 · 가게는 정한 것, 보통 집은 집 번호로 돌려 가며(갈색이 가장 많다).
static func _roof_of(h: Dictionary, i: int) -> String:
	var fac := str(h.get("facility", ""))
	if FAC_ROOF.has(fac):
		return str(FAC_ROOF[fac])
	var place := str(h.get("place", ""))
	if place in ["tavern", "herbalist", "pawnshop"]:
		return "red"
	if place in ["guard_post", "gate"]:
		return "grey"
	var zone := str(h.get("zone", ""))
	if zone == "townhall":
		return "grey"
	if ZONE_ROOF.has(zone):
		var pool: Array = ZONE_ROOF[zone]
		return str(pool[(i * 5 + 3) % pool.size()])
	return ["brown", "red", "brown", "grey", "dark", "brown", "red"][(i * 5 + 3) % 7]


static func _rotunda(h: Dictionary) -> Node3D:
	var c: Array = h["circle"]
	var holder := Node3D.new()
	holder.position = Vector3(float(c[0]), 0.0, float(c[1]))
	var r := float(c[2])
	var parts := [
		[_cyl(r * 0.92, 5.4), Vector3(0, 2.7, 0), mat("ashlar", Color("#6e665a"), 0.5)],  # 어두운 바닥 · 집 색에 맞춰(CT103 — 혼자 밝게 튀었다)
		[_cyl(r * 0.62, 1.4), Vector3(0, 6.1, 0), mat("plaster", Color("#7e7462"), 0.5)],
	]
	var sm := SphereMesh.new()
	sm.radius = r * 0.66
	sm.height = r * 0.66
	sm.is_hemisphere = true
	sm.radial_segments = 48
	parts.append([sm, Vector3(0, 6.8, 0), mat("lead", Color("#545c66"), 0.6)])
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
