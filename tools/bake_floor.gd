extends SceneTree
## 고정 지도 굽기: 층 JSON fixed_map.seed(또는 --seed)로 지도를 절차대로 만들고 검사한 뒤 fixed_map.file에 쓴다.
##   godot --headless --path . --script res://tools/bake_floor.gd -- [--floor=f1_crystal_cave] [--seed=6] [--png=C:/tmp/f1.png]
## 검사(CrossLayoutCheck)에 문제가 있으면 쓰지 않고 종료 코드 1. --seed를 바꿨으면 층 JSON fixed_map.seed도 같은 값으로 고친다
## (테스트가 파일과 그 시드로 새로 만든 지도가 같은지 본다). 시드 고르기는 tools/floor_map.gd --procedural.

var _args: Dictionary = {"floor": "f1_crystal_cave", "seed": ""}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
	var db := GameDatabase.new()
	db.load_all("res://data")
	var def := db.get_entry("floors", str(_args["floor"]))
	var fixed := JsonUtil.get_dict(def, "fixed_map")
	var path := JsonUtil.get_str(fixed, "file")
	if path.is_empty():
		print("층 %s에 fixed_map.file이 없다" % _args["floor"])
		quit(1)
		return
	var seed_value := str(_args["seed"]).to_int() if not str(_args["seed"]).is_empty() else JsonUtil.get_int(fixed, "seed", 1)
	var gen := CrystalCaveGenerator.new()
	var t := Time.get_ticks_msec()
	var map := gen.build(db, CrystalCaveGenerator.procedural(def), Rng.new(seed_value))
	print("시드 %d — %d×%d, 생성 %dms, 동굴 요소 %d곳" % [seed_value, map.width, map.height, Time.get_ticks_msec() - t, map.features.size()])
	var problems := CrossLayoutCheck.problems(map, CrossLayout.new(JsonUtil.get_dict(def, "gen")))
	for p in problems:
		print("  문제: " + p)
	if not problems.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := FloorMapFile.save(map, path, seed_value, JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(def, "gen"), "tiles"), "floor"))
	print("고정 지도 저장: %s (%s)" % [ProjectSettings.globalize_path(path), "성공" if err == OK else "실패 %d" % err])
	if seed_value != JsonUtil.get_int(fixed, "seed", 1):
		print("  주의: 층 JSON fixed_map.seed를 %d로 고칠 것" % seed_value)
	quit(0 if err == OK else 1)
