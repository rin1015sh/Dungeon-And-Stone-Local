extends SceneTree
## 집 바리에이션 그림(사용자 2026-11-02 "도시 기획은 버리고 건물의 다양한 바리에이션을 뽑는데 집중"): tools/town_kit/Designs.LIST의 집을
## 하나씩 3D로 지어(면은 횡스크롤 건물 붓 — Facade) 따뜻한 해·그림자·하늘빛으로 정사영 렌더 → docs/plans/town/variants/<id>.png.
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_variants.gd [-- --only=v01,v05]
## 모아 보기: python3 tools/town_variants_sheet.py → docs/plans/town/variants/sheet.png

const Paint := preload("res://tools/city_art/Paint.gd")
const Ink := preload("res://tools/city_art/Ink.gd")
const Kit := preload("res://tools/town_kit/Kit.gd")
const Designs := preload("res://tools/town_kit/Designs.gd")

const OUT := "res://docs/plans/town/variants"
const SIZE := 820


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for d: Array in Designs.LIST:
		if not only.is_empty() and not only.has(str(d[0])):
			continue
		var t0 := Time.get_ticks_msec()
		var img: Image = await _render(str(d[2]))
		img.save_png(ProjectSettings.globalize_path(OUT.path_join(str(d[0]) + ".png")))
		print("그림: %s %s %d ms" % [d[0], d[1], Time.get_ticks_msec() - t0])
	quit(0)


func _render(fn: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var k := Kit.new(world, 64.0)
	Designs.new().call(fn, k)
	var ctr := (k.lo + k.hi) * 0.5
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.position = Vector3(ctr.x, -0.01, ctr.z)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = load("res://assets/town/mat/cobble.webp") as Texture2D
	gm.albedo_color = Color("#6a645a")
	gm.uv1_scale = Vector3(30, 30, 1)
	gm.roughness = 1.0
	ground.material_override = gm
	world.add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-0.6, 0.75, 0.35) * 40.0, Vector3.ZERO, Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#221f1c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a90a0")
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var ext := k.hi - k.lo
	cam.size = maxf(ext.y * 1.25, maxf(ext.x, ext.z) * 1.35) + 1.5
	cam.far = 300.0
	world.add_child(cam)
	var dir := Vector3(0.55, 0.62, 1.0).normalized()
	cam.look_at_from_position(ctr + dir * 60.0, ctr, Vector3.UP)
	cam.make_current()
	for i in 4:
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
	Ink.grade(p, 0.18, 1.1)
	Ink.finish(p, 0.025)
	return p.to_image()
