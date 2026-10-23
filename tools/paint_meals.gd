extends SceneTree
## 여관 요리 그림 생성기(CT47): data/meals.json 요리마다 art 경로에 960×540 그림 한 장(tools/meal_art/MealArt.gd).
##   godot --headless --path . --script res://tools/paint_meals.gd [-- --only=<id,id>] [--out=<폴더>(시험 — art 경로 대신)]
## 장당 몇 초~수십 초. 다 그린 뒤 --import. 확인은 캡처 --screen=city --facility=inn --activity=inn_meal --meal_pick=<id> --dialog.

const MealArt := preload("res://tools/meal_art/MealArt.gd")
const SEED := 2310


func _init() -> void:
	var only: PackedStringArray = []
	var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=").split(",")
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	for id: String in db.get_collection("meals"):
		if not only.is_empty() and not only.has(id):
			continue
		var path := JsonUtil.get_str(db.get_entry("meals", id), "art")
		if not out.is_empty():
			path = out.path_join(id + ".webp")
		if path.is_empty() or not MealArt.has(id):
			print("건너뜀: %s(그림 경로·그리는 함수 없음)" % id)
			continue
		var t0 := Time.get_ticks_msec()
		MealArt.paint(id, SEED + absi(id.hash()) % 9973).save(path)
		print("그림: 요리 %s (%d ms)" % [id, Time.get_ticks_msec() - t0])
	quit(0)
