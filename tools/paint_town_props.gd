extends SceneTree
## 동네 거리 소품을 3D로 지어(tools/town_kit/Props3D) 탐험 화면 3/4로 찍는다(사용자 2026-11-03 "소품 3d 느낌 나게", CT99).
## → user://town_props/<kind>_raw.png · _id.png → python3 tools/town_hand_bake.py --props → assets/town/props/<kind>.webp
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/paint_town_props.gd [-- --only=lamp,well]
## 그림은 가로 가운데 = 발자리 가운데, 아래 끝 = 발자리 앞(남) 끝(TownProp이 발 = 아래 가운데로 그린다), 칸당 48px(TownProp.ART_SCALE 1.5).

const Kit := preload("res://tools/town_kit/Kit.gd")
const Props3D := preload("res://tools/town_kit/Props3D.gd")
const Deco3D := preload("res://tools/town_kit/Deco3D.gd")

const RAW := "user://town_props"
const S := 48.0
const MARGIN := 0.3


func _init() -> void:
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RAW))
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var shear := Node3D.new()
	shear.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 1)), Vector3.ZERO)  # 3/4 밀림: y' = y − z
	world.add_child(shear)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffe2b0")
	sun.light_energy = 1.3
	world.add_child(sun)
	sun.look_at_from_position(Vector3(-0.6, 0.75, 0.35) * 40.0, Vector3.ZERO, Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
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
	await process_frame
	for kind: String in Props3D.KINDS + Deco3D.KINDS:
		if not only.is_empty() and not only.has(kind):
			continue
		var holder := Node3D.new()
		if kind in Deco3D.KINDS:
			Deco3D.build(kind, Kit.new(holder, 64.0))
		else:
			Props3D.build(kind, Kit.new(holder, 64.0))
		shear.add_child(holder)
		var b := _bounds(holder)  # (x0, y'0, x1, y'1)
		var half := maxf(absf(b.x), absf(b.z)) + MARGIN
		var top := b.w + MARGIN
		var bottom := b.y - 0.04
		vp.size = Vector2i(int(ceil(half * 2.0 * S)), int(ceil((top - bottom) * S)))
		cam.size = float(vp.size.y) / S
		cam.position = Vector3(0.0, (top + bottom) * 0.5, 300.0)
		env.background_color = Color("#d8cdb4")
		vp.msaa_3d = Viewport.MSAA_4X
		for i in 3:
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(RAW.path_join(kind + "_raw.png")))
		_ids(holder, [0])
		env.background_color = Color.BLACK
		vp.msaa_3d = Viewport.MSAA_DISABLED
		for i in 3:
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(RAW.path_join(kind + "_id.png")))
		holder.free()
		print("소품: ", kind, " ", vp.size)
	vp.queue_free()
	await process_frame
	quit(0)


func _bounds(node: Node3D) -> Vector4:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var ab := m.mesh.get_aabb()
		for k in 8:
			var p := m.global_transform * (ab.position + ab.size * Vector3(k & 1, (k >> 1) & 1, (k >> 2) & 1))
			lo = lo.min(Vector2(p.x, p.y))
			hi = hi.max(Vector2(p.x, p.y))
	return Vector4(lo.x, lo.y, hi.x, hi.y)


func _ids(node: Node, n: Array) -> void:
	for ch in node.get_children():
		if ch is MeshInstance3D:
			n[0] += 1
			var k: int = n[0] if not ch.has_meta("gid") else 4000 + int(ch.get_meta("gid"))  # 잎 덩이 = 한 면(Deco3D.blob)
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color8(k % 251, (k * 7) % 253, 40 + (k / 251) * 9)
			(ch as MeshInstance3D).material_override = m
		_ids(ch, n)
