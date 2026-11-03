extends SceneTree
## 게임 동네 집 그림을 손그림 집 키트로 굽는다(사용자 2026-11-03 "게임 집 손그림으로 바꿔 봐", CT97).
## 지도 집마다 tools/town_kit/HouseFit(3/4 구상 그림과 같은 바리에이션 · 크기 · 각도)으로 세워 탐험 화면 3/4(장면을 y' = 높이 − 남쪽 깊이로
## 밀어 수평 정사영)로 한 채씩 찍는다 — 날 그림(종이색 배경) + 면 번호 그림 → user://town_hand/<집 id>_raw.png · _id.png · .json(off · key).
## 손그림 마감·투명 배경은 python3 tools/town_hand_bake.py(→ user://town_bake/<id>.png · .json), 그림판 묶기는 paint_town_houses.gd --pack.
##   xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/paint_town_hand.gd [-- --part=i/n | --only=h3,h7]
## 굽는 배율 S = 칸당 48px(paint_town_houses와 같다 — index.json scale 1.5), off = 노드 원점(0, 필지 남쪽 끝 × 32) 기준 그림 왼쪽 위(게임 px).

const HouseFit := preload("res://tools/town_kit/HouseFit.gd")

const RAW := "user://town_hand"
const S := 48.0
const GAME_TILE := 32.0
const MARGIN := 0.35  ## 그림 둘레 여유(칸 — 바깥 먹선 자리)
const PAPER := Color("#d8cdb4")


func _init() -> void:
	var part := Vector2i(0, 1)
	var only := PackedStringArray()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--part="):
			var s := a.trim_prefix("--part=").split("/")
			part = Vector2i(s[0].to_int(), s[1].to_int())
		elif a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RAW))
	var db := GameDatabase.new()
	db.load_all("res://data")
	var town := TownMap.load_for(db)
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
	sun.shadow_enabled = false
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
	await process_frame  # 장면이 나무에 붙은 뒤에 재야 global_transform이 맞다(첫 집의 범위가 틀렸었다)
	var t0 := Time.get_ticks_msec()
	var n := 0
	for i in town.houses.size():
		var h: Dictionary = town.houses[i]
		var id := str(h["id"])
		if not only.is_empty() and not only.has(id):
			continue
		if only.is_empty() and i % part.y != part.x:
			continue
		var node := HouseFit.make(h, i)
		shear.add_child(node)
		var box := _bounds(node)  # (x0, y'0, x1, y'1) 칸
		if OS.has_environment("HAND_DEBUG"):
			print(id, " ", box, " meshes ", node.find_children("*", "MeshInstance3D", true, false).size(), " at ", h.get("center"))
		var size := Vector2i(int(ceil((box.z - box.x + MARGIN * 2.0) * S)), int(ceil((box.w - box.y + MARGIN * 2.0) * S)))
		vp.size = size
		cam.size = float(size.y) / S
		cam.position = Vector3((box.x + box.z) * 0.5, (box.y + box.w) * 0.5, 300.0)
		env.background_color = PAPER
		vp.msaa_3d = Viewport.MSAA_4X
		for k in 3:
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(RAW.path_join(id + "_raw.png")))
		_ids(node, [0])
		env.background_color = Color.BLACK
		vp.msaa_3d = Viewport.MSAA_DISABLED
		for k in 3:
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(RAW.path_join(id + "_id.png")))
		# 그림 왼쪽 위 = (x0 − 여유, y'1 + 여유) → 게임 화면 y = −y' (남쪽 깊이 − 높이)
		var off := Vector2((box.x - MARGIN) * GAME_TILE, -(box.w + MARGIN) * GAME_TILE - TownHouse.front_y_of(h) * GAME_TILE)
		var meta := FileAccess.open(RAW.path_join(id + ".json"), FileAccess.WRITE)
		meta.store_string(JSON.stringify({"off": [off.x, off.y], "key": TownHouse.bake_key(h)}))
		meta.close()
		node.free()
		n += 1
		if n % 10 == 0:
			print("집 %d채 (%.1f초)" % [n, (Time.get_ticks_msec() - t0) / 1000.0])
	print("찍음: 집 %d채 %.1f초" % [n, (Time.get_ticks_msec() - t0) / 1000.0])
	vp.queue_free()
	HouseFit.clear()
	await process_frame
	quit(0)


## 집의 화면 범위(밀림 뒤 세계 좌표): Vector4(x0, y'0, x1, y'1).
func _bounds(node: Node3D) -> Vector4:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
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
			var k: int = n[0]
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color8(k % 251, (k * 7) % 253, 40 + (k / 251) * 9)
			(ch as MeshInstance3D).material_override = m
		_ids(ch, n)
