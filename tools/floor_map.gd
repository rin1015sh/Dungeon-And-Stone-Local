extends SceneTree
## 층 전체 지도를 PNG로 그리고 검사 결과를 출력한다(디버그 미니맵).
##   godot --headless --path . --script res://tools/floor_map.gd -- --seed=5 --out=C:/tmp/f1.png [--floor=f1_crystal_cave] [--scale=5] [--no-spawns] [--procedural]
## 고정 지도(층 JSON fixed_map)가 있는 층은 그 지도를 그린다(시드는 시작 위치·무리만 바꾼다). --procedural이면 고정 지도를 무시하고
## 그 시드로 새로 만든다(굽기 전에 시드 고르기).
## 색(data/render.json "debug_map"): 구역별 바닥색(중심부·동·서·남·북), 같은 색의 어두운 벽, 수정벽, 암흑지대(어둡게 + 빗금),
## 기념비(흰색), 2층 포탈(분홍), 시작 위치(하늘색), 무작위 랜드마크(노란 테두리), 몬스터 무리(몬스터별 점), 막다른 곳(주황),
## 동굴 요소(검은 테두리 + 그 타일의 표식 색).
## 검사(CrossLayoutCheck): 네 포탈 도달·나침반 경로·연결·암흑지대 위치·지역 스폰. 문제가 있으면 종료 코드 1.
## 그림 층 검사(FloorArtCheck): 바닥 변형 연속·걷는 칸을 막는 장식·동굴 요소와 겹친 장식(docs/PROMPT_ART_MAP.md §5.4 — 그림 층은 A2부터).

var _args: Dictionary = {"seed": "1", "out": "user://floor_map.png", "floor": "f1_crystal_cave", "scale": ""}
var _db: GameDatabase


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			_args[a.substr(2, a.find("=") - 2)] = a.substr(a.find("=") + 1)
		elif a.begins_with("--"):
			_args[a.substr(2)] = "true"
	var db := GameDatabase.new()
	db.load_all("res://data")
	_db = db
	var reg := ContentRegistries.new()
	var def := db.get_entry("floors", str(_args["floor"]))
	if _args.has("procedural"):
		def = CrystalCaveGenerator.procedural(def)
	var seed_value := str(_args["seed"]).to_int()
	var t := Time.get_ticks_usec()
	var map := reg.generator(JsonUtil.get_str(def, "generator")).generate(db, def, Rng.new(seed_value))
	print("층 %s 시드 %d — %d×%d, 생성 %.0fms" % [_args["floor"], seed_value, map.width, map.height, (Time.get_ticks_usec() - t) / 1000.0])
	var fm := FieldMonsters.new(db, map, def, Rng.new(seed_value + 1))
	if not _args.has("no-spawns"):
		fm.spawn_initial(map.entry)
	var problems := PackedStringArray()
	if JsonUtil.get_str(def, "generator") == "crystal_cave":
		var lay := CrossLayout.new(JsonUtil.get_dict(def, "gen"))
		problems = CrossLayoutCheck.problems(map, lay)
		problems.append_array(CrossLayoutCheck.spawn_problems(FieldMonsters.new(db, map, def, Rng.new(seed_value + 2)), map, def, 60))
		_print_stats(map, lay)
	var art_problems := FloorArtCheck.problems(map, FloorArtCheck.empty_art())  # 그림 층(A2부터 실제 층을 넘긴다)
	print("  그림 층 검사: %s" % ("통과" if art_problems.is_empty() else "문제 %d개" % art_problems.size()))
	problems.append_array(art_problems)
	var cfg := JsonUtil.get_dict(db.render, "debug_map")
	var scale := str(_args["scale"]).to_int() if not str(_args["scale"]).is_empty() else JsonUtil.get_int(cfg, "scale", 5)
	var img := _draw(map, fm, cfg, maxi(1, scale))
	var out := str(_args["out"])
	var err := img.save_png(out)
	print("지도 저장: %s (%s)" % [ProjectSettings.globalize_path(out), "성공" if err == OK else "실패 %d" % err])
	for p in problems:
		print("  문제: " + p)
	print("검사: %s" % ("통과" if problems.is_empty() else "문제 %d개" % problems.size()))
	quit(0 if problems.is_empty() and err == OK else 1)


func _print_stats(map: FloorMap, lay: CrossLayout) -> void:
	var floors := {}
	var dark_floor := 0
	for i in map.tiles.size():
		if map.defs[map.tiles[i]].walkable:
			var z := map.zone_at(map.pos_of(i))
			floors[z] = int(floors.get(z, 0)) + 1
			if map.dark[i] != 0:
				dark_floor += 1
	print("  걷는 칸(구역별): %s, 암흑지대 걷는 칸 %d" % [floors, dark_floor])
	print("  수정벽 %d, 랜드마크 %s" % [map.count_tile("crystal_wall"), map.landmarks.map(func(r: Dictionary) -> String: return str(r["id"]))])
	for portal: Dictionary in map.portals:
		var path := _path_len(map, CrystalCaveGenerator.monument_side(map, str(portal["dir"])), portal["pos"])
		var straight := absi((portal["pos"] as Vector2i).x - map.center.x) + absi((portal["pos"] as Vector2i).y - map.center.y)
		print("  %s 포탈 %s → %s, 기념비에서 최단 %d걸음(직선 %d, 굴곡 %.2f배)" % [portal["dir"], portal["pos"], portal["dest"], path, straight, float(path) / maxf(1.0, straight)])
	print("  시작 위치 %s (%s), 암흑지대 깊이 %d칸" % [map.entry, map.zone_at(map.entry), lay.dark_depth])
	print("  한 칸 폭 목 %d곳, 가장 큰 막다른 곳 %d칸" % [GridWiden.count_narrow(GridWiden.walk_cells(map), map.width, map.height), CrossLayoutCheck.max_dead_end(map)])


func _path_len(map: FloorMap, a: Vector2i, b: Vector2i) -> int:
	var dist := {a: 0}
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var p := queue[head]
		head += 1
		if p == b:
			return dist[p]
		for d in FloorMap.DIRS4:
			if map.is_walkable(p + d) and not dist.has(p + d):
				dist[p + d] = int(dist[p]) + 1
				queue.append(p + d)
	return -1


func _draw(map: FloorMap, fm: FieldMonsters, cfg: Dictionary, s: int) -> Image:
	var img := Image.create(map.width * s, map.height * s, false, Image.FORMAT_RGB8)
	var zones := JsonUtil.get_dict(cfg, "zones")
	var rock := _c(cfg, "rock")
	var hatch := _c(cfg, "dark_hatch")
	for i in map.tiles.size():
		var p := map.pos_of(i)
		var def := map.defs[map.tiles[i]]
		var zone := map.zone_at(p)
		var base := Color.from_string(JsonUtil.get_str(zones, zone, "#808080"), Color.GRAY) if not zone.is_empty() else rock
		var col := base
		if def.id == "crystal_wall":
			col = _c(cfg, "crystal")
		elif not def.walkable:
			col = base * JsonUtil.get_float(cfg, "wall_shade", 0.3) if not zone.is_empty() else rock
		if map.dark[i] != 0:
			col = col * JsonUtil.get_float(cfg, "dark_shade", 0.4)
		col.a = 1.0
		img.fill_rect(Rect2i(p * s, Vector2i(s, s)), col)
		if map.dark[i] != 0 and s >= 3:
			img.set_pixel(p.x * s + (p.y % 2) * (s - 1), p.y * s, hatch)
	if map.has_zones():
		var dead := GridSpurs.spur_cells(GridWiden.walk_cells(map), map.width, map.height, CrossLayoutCheck.hubs(map))
		for i in dead.size():
			if dead[i] != 0:
				img.fill_rect(Rect2i(map.pos_of(i) * s, Vector2i(s, s)), _c(cfg, "dead_end"))
	for rec: Dictionary in map.landmarks:
		var r: Rect2i = rec["rect"]
		_outline(img, Rect2i(r.position * s, r.size * s), _c(cfg, "landmark"))
	img.fill_rect(Rect2i((map.center - Vector2i.ONE) * s, Vector2i(3, 3) * s), _c(cfg, "monument"))
	for portal: Dictionary in map.portals:
		var p: Vector2i = portal["pos"]
		img.fill_rect(Rect2i((p - Vector2i.ONE) * s, Vector2i(3, 3) * s), _c(cfg, "portal"))
	img.fill_rect(Rect2i(map.entry * s - Vector2i(s, s) / 2, Vector2i(2, 2) * s), _c(cfg, "entry"))
	for f: Dictionary in map.features:  # 동굴 요소: 타일 표식 색(없으면 기본색), 테두리 = 검정
		var tile := JsonUtil.get_str(_db.get_entry("events", str(f["id"])), "tile")
		if tile.is_empty():
			tile = JsonUtil.get_str(JsonUtil.get_dict(_db.get_entry("events", str(f["id"])), "hazard"), "tile")
		var mark := JsonUtil.get_dict(_db.get_entry("tiles", tile), "colors")
		var fc := Color.from_string(JsonUtil.get_str(mark, "mark", JsonUtil.get_str(cfg, "feature", "#ffffff")), Color.WHITE)
		var fp: Vector2i = f["pos"]
		img.fill_rect(Rect2i((fp - Vector2i.ONE) * s, Vector2i(3, 3) * s), Color.BLACK)
		img.fill_rect(Rect2i(fp * s, Vector2i(s, s)), fc)
	var mcol := JsonUtil.get_dict(cfg, "monsters")
	for g in fm.groups:
		var c := Color.from_string(JsonUtil.get_str(mcol, g.leader(), JsonUtil.get_str(cfg, "monster_default", "#ffffff")), Color.WHITE)
		img.fill_rect(Rect2i(g.pos * s - Vector2i(s, s) / 2, Vector2i(2, 2) * s), c)
	return img


func _outline(img: Image, r: Rect2i, c: Color) -> void:
	for x in range(r.position.x, r.end.x):
		img.set_pixel(x, r.position.y, c)
		img.set_pixel(x, r.end.y - 1, c)
	for y in range(r.position.y, r.end.y):
		img.set_pixel(r.position.x, y, c)
		img.set_pixel(r.end.x - 1, y, c)


func _c(cfg: Dictionary, key: String) -> Color:
	return Color.from_string(JsonUtil.get_str(cfg, key, "#ff00ff"), Color.MAGENTA)
