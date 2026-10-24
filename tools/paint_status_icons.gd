extends SceneTree
## 상태이상 아이콘 생성기(UI23 다음 — 2026-10-24): 상태마다 96×96 한 장 → assets/statuses/<id>.webp
## (+ meal(여관 요리 전부)·buff·debuff(표에 없는 상태)). 기호·색 = tools/status_art/Icons.gd MAP.
##   godot --headless --path . --script res://tools/paint_status_icons.gd [-- --only=<id,id>] [--out=<폴더>]
## 몇 초. 다 그린 뒤 --import. 확인: 캡처 --screen=explore --combat --monster=<id> --statuses=<id,id>.

const Icons := preload("res://tools/status_art/Icons.gd")
const DIR := "res://assets/statuses"


func _init() -> void:
	var only: PackedStringArray = []
	var out := DIR
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	var jobs: Array = []
	for id: String in db.get_collection("statuses"):
		var d := db.get_entry("statuses", id)
		if JsonUtil.get_str(d, "meal").is_empty():
			jobs.append([id, JsonUtil.get_str(d, "kind") == "buff"])
	jobs.append_array([["meal", true], ["buff", true], ["debuff", false]])
	var n := 0
	for j: Array in jobs:
		var id := str(j[0])
		if not only.is_empty() and not only.has(id):
			continue
		Icons.paint(id, bool(j[1]), 4100 + absi(id.hash()) % 997).save(out.path_join(id + ".webp"), 0.9)
		n += 1
	print("상태이상 아이콘 %d장 → %s" % [n, out])
	quit(0)
