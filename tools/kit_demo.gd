extends SceneTree
## 던전 에셋 키트를 Godot에서 실제로 쌓아 찍어 본다(DungeonKit.build_set — 타일셋 · 스프라이트 · 애니메이션 · 충돌이 엔진에서 도는지 확인).
##   xvfb-run -a -s "-screen 0 1280x800x24" godot --rendering-driver opengl3 --path . --script res://tools/kit_demo.gd -- --set=prison --out=/tmp/kit_prison.png [--scale=1.0] [--shapes]
## --set=all 이면 세트마다 <out 폴더>/godot_<세트>.png. --shapes = 충돌 네모를 붉게 덧그린다.


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var kit := DungeonKit.open()
	var names := kit.set_names() if String(args.get("set", "all")) == "all" else PackedStringArray([String(args["set"])])
	var out := String(args.get("out", "user://kit_demo"))
	root.size = Vector2i(1280, 800)
	RenderingServer.set_default_clear_color(Color("#0c0b0b"))
	for set_name in names:
		var room := kit.build_set(set_name, {"scale": float(args.get("scale", "1.0"))})
		root.add_child(room)
		if args.has("shapes"):
			_show_shapes(room)
		for i in 6:
			await process_frame
		var img := root.get_texture().get_image()
		var path := out if names.size() == 1 and out.ends_with(".png") else out.path_join("godot_%s.png" % set_name)
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		img.save_png(path)
		print("찍음: %s (노드 %d개)" % [path, room.get_child_count()])
		room.queue_free()
		await process_frame
	quit()


func _show_shapes(room: Node) -> void:
	for body in room.find_children("Body", "StaticBody2D", true, false):
		for shape in body.get_children():
			var cs := shape as CollisionShape2D
			var rect := (cs.shape as RectangleShape2D).size
			var mark := ColorRect.new()
			mark.color = Color(1, 0.2, 0.2, 0.35)
			mark.size = rect
			mark.position = cs.position - rect * 0.5
			mark.z_index = 50
			body.add_child(mark)
