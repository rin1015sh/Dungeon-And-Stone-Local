extends SceneTree
## 동네 집 그림 방식 비교(사용자 2026-11-02 "그냥 건물을 4·5채를 여러 방식으로 다시 그려"): 같은 집 다섯 채를 방식마다 —
##   A 정면 쿼터뷰(게임 시점 (x, y − z), 기울이지 않음) · B 비스듬히(캐비닛 — 앞면 + 오른쪽 옆면) · C 등각(아이소메트릭) ·
##   D Godot 3D로 지어 빛·그림자로 렌더(면 그림은 같은 붓) — E 픽셀아트는 tools/town_styles_sheet.py가 C를 줄여 만든다.
## 면 그림은 모두 횡스크롤 건물 붓(tools/town_art/Elev·Landmarks — Paint·Mat·Parts·Ink). → docs/plans/town/styles/<방식>_<집>.png
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_styles.gd [-- --only=A,B]
## 다음 python3 tools/town_styles_sheet.py → docs/plans/town/styles/sheet.png(모아 보기).

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Refine := preload("res://tools/city_art/Refine.gd")
const Geo := preload("res://tools/town_art/Geo.gd")
const Elev := preload("res://tools/town_art/Elev.gd")
const Warp := preload("res://tools/town_art/Warp.gd")
const Landmarks := preload("res://tools/town_art/Landmarks.gd")

const OUT := "res://docs/plans/town/styles"
const S := 48.0
const P := 80.0
## 방식 → 화면 축(화면 = (q·ax, q·ay) × S).
const VIEWS := {
	"A": [Vector3(1, 0, 0), Vector3(0, 1, -1)],
	"B": [Vector3(1, -0.45, 0), Vector3(0, 0.45, -1)],
	"C": [Vector3(0.866, -0.866, 0), Vector3(0.5, 0.5, -1)],
}


static func buildings() -> Array[Dictionary]:
	return [
		{"id": "b1", "center": Vector2(10, 10), "size": Vector2(5, 4), "angle": 0.0, "floors": 3, "roof": "gable", "ridge_long": true, "style": "timber", "look": 4, "facility": "", "door": Vector2i(-1, -1)},
		{"id": "b2", "center": Vector2(10, 10), "size": Vector2(6, 5), "angle": 0.0, "floors": 3, "roof": "hip", "ridge_long": true, "style": "stone", "look": 7, "facility": "", "door": Vector2i(-1, -1)},
		{"id": "b3", "center": Vector2(10, 10), "size": Vector2(3.4, 5), "angle": 0.0, "floors": 4, "roof": "gable", "ridge_long": true, "style": "plaster", "look": 11, "facility": "", "door": Vector2i(-1, -1)},
		{"id": "b4", "center": Vector2(10, 10), "size": Vector2(8, 6), "angle": 0.0, "floors": 3, "roof": "gable", "ridge_long": true, "style": "inn", "look": 5, "facility": "inn", "rect": Rect2i(6, 7, 8, 6), "door": Vector2i(10, 12)},
		{"id": "b5", "center": Vector2(10, 9), "size": Vector2(16, 14), "angle": 0.0, "floors": 4, "style": "gothic", "look": 3, "facility": "temple", "rect": Rect2i(2, 2, 16, 14), "door": Vector2i(10, 15)},
	]


func _init() -> void:
	var only := PackedStringArray(["A", "B", "C", "D"])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	var db := GameDatabase.new()
	db.load_all("res://data")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for m: String in only:
		for h in buildings():
			var t0 := Time.get_ticks_msec()
			var img: Image
			if m == "D":
				img = await _render_3d(h, db.render)
			else:
				img = _paint_view(h, db.render, VIEWS[m][0], VIEWS[m][1])
			img.save_png(ProjectSettings.globalize_path(OUT.path_join("%s_%s.png" % [m, h["id"]])))
			print("그림: %s %s %d ms" % [m, h["id"], Time.get_ticks_msec() - t0])
	quit(0)


static func _geo(h: Dictionary, render: Dictionary) -> Geo:
	var g := Geo.new(render)
	g.cull = false
	if str(h.get("style", "")) == "gothic":
		Landmarks.gothic(g, h)
	else:
		g.house(h)
	return g


static func _flat(f: Dictionary, h: Dictionary, seed_value: int) -> Paint:
	return Landmarks.face(f, h, P, seed_value) if Landmarks.handles(str(f["kind"])) else Elev.face(f, h, P, seed_value)


## 면 그림을 그 시점으로 옮겨 붙인 한 장(보이는 면만, 먼 면부터) + 횡스크롤 마감.
static func _paint_view(h: Dictionary, render: Dictionary, ax: Vector3, ay: Vector3) -> Image:
	var g := _geo(h, render)
	var view := ax.cross(ay)
	if view.z < 0.0:
		view = -view
	var vis: Array[Dictionary] = []
	for f in g.faces:
		if (f["n"] as Vector3).dot(view) > 0.02:
			vis.append(f)
	vis.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _depth(a, view) < _depth(b, view))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for f in vis:
		for q: Vector3 in f["pts"]:
			var s := Vector2(q.dot(ax), q.dot(ay)) * S
			lo = lo.min(s)
			hi = hi.max(s)
	var origin := (lo - Vector2(10, 10)).floor()
	var size := Vector2i((hi - origin + Vector2(10, 10)).ceil())
	var sp := Paint.new(size.x, size.y, 4242)
	for i in vis.size():
		Warp.compose(sp, vis[i], _flat(vis[i], h, 500 + i), P, S, origin, ax, ay)
	Refine.look(sp, 2)
	Ink.silhouette(sp, 2)
	Ink.grade(sp, 0.22, 1.12)
	Ink.finish(sp, 0.03)
	return sp.to_image()


static func _depth(f: Dictionary, view: Vector3) -> float:
	var d := 0.0
	for q: Vector3 in f["pts"]:
		d += q.dot(view)
	return d / (f["pts"] as PackedVector3Array).size()


## 우리 좌표(x 동, y 남, z 위) → Godot 3D(x, y 위, z 남).
static func _g(q: Vector3) -> Vector3:
	return Vector3(q.x, q.z, q.y)


## D: 면마다 그 붓 그림을 재질로 붙인 3D 집 + 자갈 바닥 · 왼쪽 위 해(그림자) · 흐린 하늘빛 → 정사영 카메라(남동쪽 위에서).
func _render_3d(h: Dictionary, render: Dictionary) -> Image:
	var g := _geo(h, render)
	var vp := SubViewport.new()
	vp.size = Vector2i(1000, 1000)
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for i in g.faces.size():
		var f: Dictionary = g.faces[i]
		var flat := _flat(f, h, 500 + i)
		var img := flat.to_image()
		var mesh := ArrayMesh.new()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		var vs := PackedVector3Array()
		var ns := PackedVector3Array()
		var uvs := PackedVector2Array()
		var pts: PackedVector3Array = f["pts"]
		var loc: PackedVector2Array = f["local"]
		for k in range(1, pts.size() - 1):
			for j: int in [0, k + 1, k]:  # y·z를 바꿔 옮기면 손이 바뀐다 — 감는 방향을 뒤집어 앞면으로
				vs.append(_g(pts[j]))
				ns.append(_g(f["n"]))
				uvs.append(loc[j] * P / Vector2(img.get_width(), img.get_height()))
				lo = lo.min(pts[j])
				hi = hi.max(pts[j])
		arr[Mesh.ARRAY_VERTEX] = vs
		arr[Mesh.ARRAY_NORMAL] = ns
		arr[Mesh.ARRAY_TEX_UV] = uvs
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = ImageTexture.create_from_image(img)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 1.0
		mat.metallic_specular = 0.1
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		vp.add_child(mi)
	var ctr := (lo + hi) * 0.5
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 60)
	ground.mesh = plane
	ground.position = _g(Vector3(ctr.x, ctr.y, -0.01))
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = load("res://assets/town/mat/cobble.webp") as Texture2D
	gm.albedo_color = Color("#6a645a")
	gm.uv1_scale = Vector3(15, 15, 1)
	gm.roughness = 1.0
	ground.material_override = gm
	vp.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff0d8")
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 120.0
	vp.add_child(sun)
	sun.look_at_from_position(_g(Vector3(-0.55, 0.35, 0.76)) * 40.0, Vector3.ZERO, Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#2a2622")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#9aa0a8")
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var extent := maxf(hi.x - lo.x, maxf(hi.y - lo.y, hi.z - lo.z))
	cam.size = extent * 1.45 + 2.0
	cam.far = 400.0
	vp.add_child(cam)
	var dir := _g(Vector3(0.5, 1.0, 1.1)).normalized()
	cam.look_at_from_position(_g(ctr) + dir * 80.0, _g(ctr), Vector3.UP)
	cam.make_current()
	for k in 4:
		await RenderingServer.frame_post_draw
	var shot := vp.get_texture().get_image()
	vp.queue_free()
	shot.convert(Image.FORMAT_RGBA8)
	var p := Paint.new(shot.get_width(), shot.get_height(), 77)
	for y in shot.get_height():
		for x in shot.get_width():
			var c := shot.get_pixel(x, y)
			var i := (y * p.w + x) * 4
			p.buf[i] = c.r
			p.buf[i + 1] = c.g
			p.buf[i + 2] = c.b
			p.buf[i + 3] = 1.0
	Ink.grade(p, 0.22, 1.12)
	Ink.finish(p, 0.03)
	return p.to_image()
