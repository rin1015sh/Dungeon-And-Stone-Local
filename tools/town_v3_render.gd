extends SceneTree
## 도시 구상 v3 — 게임 동네 지도(data/town/district7.json · TownMap)를 집 키트 17채(tools/town_kit/Designs — 손그림 집)로 세워
## 탐험 화면과 같은 3/4(바닥 깊이 그대로 · 높이 그대로 위로 — CT92)로 렌더한다. 사용자 2026-11-03 "좋은데 이대로 진행해 봐"(CT95).
##   집: tools/town_kit/HouseFit(바닥 크기가 가장 가까운 바리에이션 · 시설은 정한 것 — 게임 집 그림 굽기 tools/paint_town_hand.gd와 같은 집).
##   땅: 칸마다 높이(단 · 계단 · 수로)로 윗면 + 남쪽이 낮으면 앞면(옹벽 · 계단 단 · 둑).
## 3/4 투영: Godot 카메라는 사선 투영이 없어서 장면을 밀어(y' = 높이 − 남쪽 깊이) 수평 정사영으로 찍는다.
## → docs/plans/town/v3/raw/{town,plaza}_raw.png · _id.png(면 번호) — python3 tools/town_handdrawn.py --dir=v3 → town_hand.png · plaza_hand.png
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_v3_render.gd

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Kit := preload("res://tools/town_kit/Kit.gd")
const F := preload("res://tools/town_kit/Facade.gd")
const HouseFit := preload("res://tools/town_kit/HouseFit.gd")

const OUT := "res://docs/plans/town/v3"
const PX := 20  ## 칸당 px(전체 그림)
const PLAZA_PX := 34  ## 광장 가까이 그림
const GROUND := {
	"cobble": ["#8f8676", ["street", "house", "prop", "dais", "gate"]],
	"slabs": ["#a39b8a", ["avenue", "paving", "bridge", "retain"]],
	"plaza": ["#b3aa96", ["plaza"]],
	"stairs": ["#a9a08c", ["stairs"]],
	"dirt": ["#8a7a62", ["yard", "court"]],
	"water": ["#5a6e72", ["water"]],
}

var _root: Node3D
var _town: TownMap


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join("raw")))
	var db := GameDatabase.new()
	db.load_all("res://data")
	_town = TownMap.load_for(db)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	_root = Node3D.new()
	_root.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 1)), Vector3.ZERO)  # 3/4 밀림: y' = y − z
	world.add_child(_root)
	var t0 := Time.get_ticks_msec()
	_ground()
	var n := 0
	for i in _town.houses.size():
		n += _house(_town.houses[i], i)
	for p: Dictionary in _town.props:
		_prop(p)
	_dais()
	print("지음: %d ms · 집 %d" % [Time.get_ticks_msec() - t0, n])
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.3
	sun.shadow_enabled = false
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-0.6, 0.75, 0.35) * 40.0, Vector3.ZERO, Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1a1816")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a90a0")
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 600.0
	world.add_child(cam)
	cam.make_current()
	var top := _town.max_height() + 16.0  # 가장 높은 지붕 · 첨탑 자리
	# 전체(가로 80칸) · 광장 가까이(가로 44칸)
	var shots := [["town", Rect2(0, -top, _town.width, _town.height + top + 4.0), PX]]
	var pc := Vector2(_town.dais["center"]) + Vector2(0.5, 0.5)
	shots.append(["plaza", Rect2(pc.x - 22.0, pc.y - 30.0 - 8.0, 44.0, 44.0), PLAZA_PX])
	for s: Array in shots:
		var r: Rect2 = s[1]
		vp.size = Vector2i(int(r.size.x * int(s[2])), int(r.size.y * int(s[2])))
		cam.size = r.size.y
		cam.position = Vector3(r.get_center().x, -r.get_center().y, 300.0)  # 화면 위 = y' 큰 쪽 = 북 · 높은 곳
		for i in 4:
			await RenderingServer.frame_post_draw
		_save(vp.get_texture().get_image(), "raw/%s_raw.png" % s[0])
	var k := [0]
	_ids(_root, k)
	env.background_color = Color.BLACK
	vp.msaa_3d = Viewport.MSAA_DISABLED
	for s: Array in shots:
		var r: Rect2 = s[1]
		vp.size = Vector2i(int(r.size.x * int(s[2])), int(r.size.y * int(s[2])))
		cam.size = r.size.y
		cam.position = Vector3(r.get_center().x, -r.get_center().y, 300.0)
		for i in 3:
			await RenderingServer.frame_post_draw
		_save(vp.get_texture().get_image(), "raw/%s_id.png" % s[0])
	print("그림: %d ms · 면 %d" % [Time.get_ticks_msec() - t0, k[0]])
	vp.queue_free()
	HouseFit.clear()
	await process_frame
	quit(0)


func _save(img: Image, name: String) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(name)))


func _ids(node: Node, n: Array) -> void:
	for ch in node.get_children():
		if ch is MeshInstance3D:
			n[0] += 1
			var k: int = n[0]
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color8(k % 251, (k * 7) % 253, 40 + (k / 251) * 9)
			(ch as MeshInstance3D).material_override = m
		_ids(ch, n)


## 땅: 재질마다 한 덩어리(윗면) + 앞면 한 덩어리(마름돌). 칸 가장자리 선이 생기지 않게 재질끼리만 나눈다.
func _ground() -> void:
	var tops := {}
	for m: String in GROUND:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tops[m] = st
	var faces := SurfaceTool.new()
	faces.begin(Mesh.PRIMITIVE_TRIANGLES)
	var used := {}
	for y in _town.height:
		for x in _town.width:
			var c := Vector2i(x, y)
			var k := _town.ground_at(c)
			if k == "void":
				continue
			var m := "cobble"
			for name: String in GROUND:
				if k in (GROUND[name] as Array)[1]:
					m = name
			var h := _town.height_at(c)
			var shade := 0.92 + 0.08 * Paint.hash01(x, y, 5)
			_quad(tops[m], Vector3(x, h, y), Vector3(x + 1, h, y), Vector3(x + 1, h, y + 1), Vector3(x, h, y + 1), Vector3.UP, Color(shade, shade, shade))
			used[m] = true
			var s := c + Vector2i.DOWN
			if _town.ground_at(s) != "void":
				var hs := _town.height_at(s)
				if h - hs > 0.05:
					var dark := 0.85 if k == "stairs" else 1.0
					_quad(faces, Vector3(x, h, y + 1), Vector3(x + 1, h, y + 1), Vector3(x + 1, hs, y + 1), Vector3(x, hs, y + 1), Vector3.BACK, Color(dark, dark, dark))
	for m: String in GROUND:
		if not used.has(m):
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = (tops[m] as SurfaceTool).commit()
		mi.material_override = HouseFit.mat(m if m != "stairs" else "slabs", Color((GROUND[m] as Array)[0]), 0.35)
		_root.add_child(mi)
	var fm := MeshInstance3D.new()
	fm.mesh = faces.commit()
	fm.material_override = HouseFit.mat("ashlar", Color("#9a9384"), 0.45)
	_root.add_child(fm)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	for p: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(p)


## 집 한 채: tools/town_kit/HouseFit(게임 집 그림 굽기와 같은 집) → 땅 높이에 세운다.
func _house(h: Dictionary, i: int) -> int:
	var node := HouseFit.make(h, i)
	node.position.y += float(h.get("elev", 0.0))
	_root.add_child(node)
	return 1


## 소품: 가로등 · 천막 · 공시판 · 우물 · 묘비 · 상자(노점).
func _prop(p: Dictionary) -> void:
	var rc: Rect2i = p["rect"]
	var at := Vector3(rc.get_center().x, _town.height_at(rc.position), rc.end.y - 0.4)
	var holder := Node3D.new()
	var k := Kit.new(holder, 64.0)
	match str(p["kind"]):
		"lamp":
			k.box(-0.06, -0.06, 0.06, 0.06, 0.0, 2.1, {}, F.plain("dark"))
			k.box(-0.18, -0.18, 0.18, 0.18, 2.1, 2.5, {"top": F.plain("dark")}, _glow())
			k.pyramid(-0.2, -0.2, 0.2, 0.2, 2.5, 0.25, 0.02, F.plain("dark"))
		"tent":
			for x: float in [-1.4, 1.4]:
				for z: float in [-1.0, 1.0]:
					k.box(x - 0.05, z - 0.05, x + 0.05, z + 0.05, 0.0, 1.5, {}, F.plain("wood"))
			k.gable_roof(-1.4, -1.0, 1.4, 1.0, 1.5, 0.8, true, 0.15, F.awning(), F.awning())
			k.box(-1.0, 0.3, 1.0, 0.9, 0.0, 0.8, {"top": F.plain("wood")}, F.plain("wood"))
		"board":
			k.box(-0.9, -0.08, 0.9, 0.08, 0.6, 1.7, {}, F.plain("wood"))
			for x: float in [-0.8, 0.8]:
				k.box(x - 0.06, -0.06, x + 0.06, 0.06, 0.0, 1.9, {}, F.plain("wood"))
		"well":
			k.box(-0.7, -0.7, 0.7, 0.7, 0.0, 0.7, {"top": F.plain("dark")}, F.plain("stone"))
			for x: float in [-0.6, 0.6]:
				k.box(x - 0.05, -0.05, x + 0.05, 0.05, 0.7, 1.8, {}, F.plain("wood"))
			k.gable_roof(-0.8, -0.5, 0.8, 0.5, 1.8, 0.45, true, 0.1, F.plain("wood"), F.plain("wood"))
		"grave":
			k.box(-0.25, -0.08, 0.25, 0.08, 0.0, 0.7, {"top": F.plain("stone")}, F.plain("stone"))
		_:
			k.box(-0.4, -0.3, 0.4, 0.3, 0.0, 0.6, {"top": F.plain("wood")}, F.plain("wood"))
	holder.position = at
	_root.add_child(holder)


## 광장 가운데 세 단 돌 단 + 돌 고리.
func _dais() -> void:
	if _town.dais.is_empty():
		return
	var c := Vector2(_town.dais["center"]) + Vector2(0.5, 0.5)
	var h := _town.height_at(_town.dais["center"])
	for i in 3:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 3.4 - 0.65 * i
		cm.bottom_radius = cm.top_radius
		cm.height = 0.3
		cm.radial_segments = 48
		mi.mesh = cm
		mi.position = Vector3(c.x, h + 0.15 + 0.3 * i, c.y)
		mi.material_override = HouseFit.mat("slabs", Color("#a9a08c"), 0.5)
		_root.add_child(mi)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.5
	tm.outer_radius = 1.95
	tm.rings = 48
	ring.mesh = tm
	ring.position = Vector3(c.x, h + 0.9 + 1.95, c.y)
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.material_override = HouseFit.mat("ashlar", Color("#9a9384"), 1.2)
	_root.add_child(ring)


static func _glow() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#e8b860"), 0.1))
		Ink.path(p, poly, 1.4)
