extends Node
## 화면 캡처 도구(시각 확인용). 창이 잠깐 떴다가 PNG를 저장하고 닫힌다. 헤드리스에서는 렌더링이 없어 쓸 수 없다.
##   godot --path . res://tools/screenshot.tscn -- --screen=foundation --out=C:/tmp/shot.png
## --screen: title(기본) / foundation

var _frame: int = 0
var _main: Control
var _screen: String = "title"
var _out: String = "user://screenshot.png"


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			_screen = arg.trim_prefix("--screen=")
		elif arg.begins_with("--out="):
			_out = arg.trim_prefix("--out=")
	_main = (load("res://src/Main.tscn") as PackedScene).instantiate()
	add_child(_main)


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == 3 and _screen == "foundation":
		for c: Node in _main.get_children():
			if c is TitleScreen:
				(c as TitleScreen).foundation_requested.emit()
	if _frame == 12:
		var img := get_viewport().get_texture().get_image()
		var err := img.save_png(_out)
		print("스크린샷 %s → %s" % ["저장" if err == OK else "실패(%d)" % err, ProjectSettings.globalize_path(_out)])
		get_tree().quit(0 if err == OK else 1)
