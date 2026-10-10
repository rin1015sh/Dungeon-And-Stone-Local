extends Node
## 화면 캡처 도구(시각 확인용). 창이 잠깐 떴다가 PNG를 저장하고 닫힌다. 헤드리스에서는 렌더링이 없어 쓸 수 없다.
##   godot --path . res://tools/screenshot.tscn -- --screen=explore --out=C:/tmp/shot.png [--seed=123] [--walk=6] [--debug]
## --screen: title(기본) / foundation / create / explore
## --seed: 탐험 층 시드 고정, --walk: 입장 후 오른쪽·아래로 몇 걸음 걸을지, --debug: 디버그 패널 열기,
## --torch: 횃불 켜기, --reveal: 안개 걷기

var _main: Control
var _args: Dictionary = {"screen": "title", "out": "user://screenshot.png", "seed": "0", "walk": "0"}


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var kv := arg.trim_prefix("--").split("=", true, 1)
			_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	GameState.debug_seed_override = str(_args["seed"]).to_int()
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)
	_run.call_deferred()


func _run() -> void:
	await _frames(3)
	var screen := str(_args["screen"])
	if screen != "title":
		var title := _main.current_screen() as TitleScreen
		if screen == "foundation":
			title.foundation_requested.emit()
		else:
			title.new_game_requested.emit()
		await _frames(3)
	if screen == "explore":
		var create := _main.current_screen() as CharacterCreateScreen
		for b: Node in create.find_children("*", "Button", true, false):
			if (b as Button).text == Strings.t("create.enter"):
				(b as Button).pressed.emit()
		await _frames(3)
		var explore := _main.current_screen() as ExploreScreen
		if _args.has("torch"):
			explore.session.use_category("light")
		var steps := str(_args["walk"]).to_int()
		for i in steps:
			var dir := Vector2i(1, 0) if i % 2 == 0 else Vector2i(0, 1)
			if not explore.session.try_move(dir):
				explore.session.try_move(Vector2i(0, -1) if i % 2 == 0 else Vector2i(-1, 0))
			await _frames(2)
		if _args.has("reveal"):
			explore.session.debug_reveal()
		if _args.has("debug"):
			var ev := InputEventAction.new()
			ev.action = "debug_toggle"
			ev.pressed = true
			Input.parse_input_event(ev)
		await _frames(30)
	await _frames(6)
	var img := get_viewport().get_texture().get_image()
	var out := str(_args["out"])
	var err := img.save_png(out)
	print("스크린샷 %s → %s" % ["저장" if err == OK else "실패(%d)" % err, ProjectSettings.globalize_path(out)])
	get_tree().quit(0 if err == OK else 1)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
