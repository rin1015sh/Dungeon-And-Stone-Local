extends SceneTree
## 도시 구상 그림(사용자 2026-11-02 "둘 다 쓸 거고 틀어진 각도랑 정면 각도 생각해서 도시 맵 다시 구상해봐. 차원광장 옆에는 탐험가 길드"):
## 집 바리에이션(tools/town_kit/Designs)을 tools/town_kit/Concept.gd의 배치대로 한 장면에 세워 게임 카메라(정면 · 약 18° — CT88)로 렌더.
## 거리는 세 방향뿐 — 정면 줄(0°) · 사선 줄(−28.8° = 사선 판 그대로) · 거울 사선 줄(+28.8° = 사선 판 좌우 뒤집음). 그래서 이 그림의 집은 모두
## 정면 판 또는 사선 판(뒤집기 포함) 한 장으로 그릴 수 있다. 땅은 테라스(옹벽 + 계단)로 북쪽이 높다.
## → docs/plans/town/concept/raw/(날 그림·면 번호 — python3 tools/town_handdrawn.py --dir=concept가 district_hand.png로) · labels.json(이름 자리) · plan.png(위에서 본 배치) — 이름표는 tools/town_concept_board.py
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_concept.gd

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Kit := preload("res://tools/town_kit/Kit.gd")
const Designs := preload("res://tools/town_kit/Designs.gd")
const Concept := preload("res://tools/town_kit/Concept.gd")

const OUT := "res://docs/plans/town/concept"
const VIEW := Vector3(0.0, 0.325, 1.0)
const W := 3200
const H := 1800

var _tpl := {}  # 짓는 함수 → [Node3D, lo, hi]
var _world: Node3D
var _labels: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.path_join("raw")))
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	_world = Node3D.new()
	vp.add_child(_world)
	var t0 := Time.get_ticks_msec()
	var c := Concept.new()
	for g: Dictionary in c.ground():
		_ground(g)
	for b: Dictionary in c.buildings():
		_place(b)
	for r: Dictionary in c.rows():
		_row(r)
	for pr: Dictionary in c.props():
		_prop(pr)
	_labels = c.labels()
	print("지음: %d ms" % (Time.get_ticks_msec() - t0))
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.35
	sun.shadow_enabled = false
	_world.add_child(sun)
	sun.look_at_from_position(Vector3(-0.6, 0.75, 0.35) * 40.0, Vector3.ZERO, Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#d8cdb4")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a90a0")
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = float(c.FRAME["height"])
	cam.far = 400.0
	_world.add_child(cam)
	var ctr: Vector3 = c.FRAME["center"]
	cam.look_at_from_position(ctr + VIEW.normalized() * 120.0, ctr, Vector3.UP)
	cam.make_current()
	for i in 4:
		await RenderingServer.frame_post_draw
	var raw := vp.get_texture().get_image()
	_save(raw, "raw/district_raw.png")
	var out := []
	for l: Dictionary in _labels:
		var sp := cam.unproject_position(l["at"])
		out.append({"text": l["text"], "x": sp.x, "y": sp.y, "kind": l.get("kind", "")})
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT.path_join("labels.json")), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	# 위에서 본 배치(정사영, 북쪽 위)
	cam.look_at_from_position(Vector3(ctr.x, 100.0, c.FRAME["plan_z"]), Vector3(ctr.x, 0.0, c.FRAME["plan_z"]), Vector3(0, 0, -1))
	cam.size = float(c.FRAME["plan_height"])
	for i in 3:
		await RenderingServer.frame_post_draw
	_save(vp.get_texture().get_image(), "plan.png")
	var out2 := []
	for l: Dictionary in _labels:
		var sp := cam.unproject_position(l["at"])
		out2.append({"text": l["text"], "x": sp.x, "y": sp.y, "kind": l.get("kind", "")})
	f = FileAccess.open(ProjectSettings.globalize_path(OUT.path_join("plan_labels.json")), FileAccess.WRITE)
	f.store_string(JSON.stringify(out2, " "))
	f.close()
	# 면 번호(손그림 윤곽용) — 다시 게임 카메라로
	cam.size = float(c.FRAME["height"])
	cam.look_at_from_position(ctr + VIEW.normalized() * 120.0, ctr, Vector3.UP)
	var n := [0]
	_ids(_world, n)
	env.background_color = Color.BLACK
	vp.msaa_3d = Viewport.MSAA_DISABLED
	for i in 3:
		await RenderingServer.frame_post_draw
	_save(vp.get_texture().get_image(), "raw/district_id.png")
	print("그림: %d ms · 면 %d" % [Time.get_ticks_msec() - t0, n[0]])
	vp.queue_free()
	for k: String in _tpl:
		((_tpl[k] as Array)[0] as Node3D).free()
	_tpl.clear()
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


## 줄: 줄 방향(yaw로 돌린 동쪽)으로 집 폭만큼씩 나아가며 세운다.
func _row(r: Dictionary) -> void:
	var yaw := float(r.get("yaw", 0.0))
	var d3 := Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3.RIGHT
	var d := Vector2(d3.x, d3.z)
	var t := 0.0
	var flips: Array = r.get("flip", [])
	var fns: Array = r["fns"]
	for i in fns.size():
		var tp: Array = _template(str(fns[i]))
		var w: float = (tp[2] as Vector3).x - (tp[1] as Vector3).x
		var start: Vector2 = r["start"]
		var back := Vector2(d.y, -d.x) * float(r.get("jitter", 0.0)) * Paint.hash01(i, int(start.x * 7.0), 31)  # 집마다 조금씩 뒤로(반듯한 줄이 계획 도시처럼 보이지 않게)
		_place({"fn": fns[i], "at": start + d * (t + w * 0.5) + back, "y": r["y"], "yaw": yaw, "flip": flips.has(i)})
		t += w + float(r.get("gap", 0.2)) * (0.3 + 1.4 * Paint.hash01(i, int(start.y * 7.0), 37))


func _template(fn: String) -> Array:
	if not _tpl.has(fn):
		var holder := Node3D.new()
		var k := Kit.new(holder, 64.0)
		Designs.new().call(fn, k)
		_tpl[fn] = [holder, k.lo, k.hi]
	return _tpl[fn]


## 집 한 채: fn(짓는 함수) · at(앞면 가운데 바닥, Vector2(x, z)) · y(바닥 높이) · yaw(도 — 0 정면, −28.8 사선, +28.8 거울 사선).
func _place(b: Dictionary) -> void:
	var t: Array = _template(str(b["fn"]))
	var node := (t[0] as Node3D).duplicate() as Node3D
	var lo: Vector3 = t[1]
	var hi: Vector3 = t[2]
	var basis := Basis(Vector3.UP, deg_to_rad(float(b.get("yaw", 0.0))))
	var at: Vector2 = b["at"]
	var front := Vector3((lo.x + hi.x) * 0.5, 0.0, float(b.get("front", hi.z)))
	if bool(b.get("flip", false)):  # 좌우 뒤집기(같은 집이 덜 되풀이되어 보이게)
		basis = basis * Basis.from_scale(Vector3(-1, 1, 1))
		front.x = -front.x
	node.transform = Transform3D(basis, Vector3(at.x, float(b.get("y", 0.0)), at.y) - basis * front)
	_world.add_child(node)


## 땅 조각: kind box(옹벽·단 — 옆면 돌) · top(윗면 재질) · disc(원판) · torus(돌 고리) · stairs(계단).
func _ground(g: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	match str(g["kind"]):
		"box":
			var bm := BoxMesh.new()
			var a: Vector3 = g["a"]
			var b: Vector3 = g["b"]
			bm.size = (b - a).abs()
			mi.mesh = bm
			mi.position = (a + b) * 0.5
		"disc":
			var cm := CylinderMesh.new()
			cm.top_radius = float(g["r"])
			cm.bottom_radius = float(g["r"])
			cm.height = float(g["h"])
			cm.radial_segments = 48
			mi.mesh = cm
			mi.position = g["at"]
		"torus":
			var tm := TorusMesh.new()
			tm.inner_radius = float(g["r0"])
			tm.outer_radius = float(g["r1"])
			tm.rings = 48
			mi.mesh = tm
			mi.position = g["at"]
			mi.rotation_degrees = Vector3(90, 0, 0)
		"stairs":  # a = 아래 단 앞 가운데, 계단은 -z(북)로 오른다 · w 폭 · n 단 · rise · run
			var a: Vector3 = g["a"]
			var dir := float(g.get("dir", -1.0))
			var holder := Node3D.new()
			for i in int(g["n"]):
				var s := MeshInstance3D.new()
				var bm := BoxMesh.new()
				var top := float(g["rise"]) * (i + 1)
				bm.size = Vector3(float(g["w"]), top + 4.0, float(g["run"]))
				s.mesh = bm
				s.position = Vector3(a.x, a.y + top * 0.5 - 2.0, a.z + dir * float(g["run"]) * (i + 0.5))
				s.material_override = _mat(str(g.get("mat", "slabs")), Color(g.get("color", "#aaa190")))
				holder.add_child(s)
			_world.add_child(holder)
			return
	mi.material_override = _mat(str(g.get("mat", "ashlar")), Color(g.get("color", "#7a756b")), float(g.get("scale", 0.5)))
	_world.add_child(mi)


func _mat(name: String, tint: Color, scale: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/town/mat/%s.webp" % name) as Texture2D
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.roughness = 1.0
	m.metallic_specular = 0.1
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m


## 소품: 가로등(쇠기둥 + 불빛) · 천막(정산 천막 — 줄무늬 천 박공) · 공시판.
func _prop(pr: Dictionary) -> void:
	var holder := Node3D.new()
	var k := Kit.new(holder, 64.0)
	var at: Vector3 = pr["at"]
	var F := preload("res://tools/town_kit/Facade.gd")
	match str(pr["kind"]):
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
	holder.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(pr.get("yaw", 0.0)))), at)
	_world.add_child(holder)


static func _glow() -> Callable:
	return func(p: Paint, poly: PackedVector2Array, _size: Vector2) -> void:
		p.fill_poly(poly, p.flat(Color("#e8b860"), 0.1))
		Ink.path(p, poly, 1.4)
