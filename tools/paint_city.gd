extends SceneTree
## 도시 그림 생성기: 거리 레이어(하늘·원경·중경·안개·거리·비네트) · 시설 건물 · 시설 내부를
## 손으로 칠한 듯한 어두운 일러스트(피어 앤 헝거 2풍 — 거친 붓결·잉크 윤곽·빗금·탁한 색·그레인)로 그려 data가 가리키는 경로에 저장한다.
##   godot --headless --path . --script res://tools/paint_city.gd [-- --only=street|buildings|interiors|plaza]
## 좌표 = '거리 단위'(화면 높이 720 기준 px). 건물 위치는 data/facilities x, 레이어 목록·경로는 data/city.json street,
## 땅 높이·건물 배율은 render.json city.baseline·building_scale. 손으로 그린 그림으로 바꾸려면 같은 경로에 덮어쓰면 된다.

const Buildings := preload("res://tools/city_art/Buildings.gd")
const Interiors := preload("res://tools/city_art/Interiors.gd")
const Street := preload("res://tools/city_art/Street.gd")
const Backdrop := preload("res://tools/city_art/Backdrop.gd")
const Plaza := preload("res://tools/city_art/Plaza.gd")
const SEED := 1015
const MAX_VIEW := 1700.0  ## 이 너비(거리 단위)까지 보이는 화면에서 시차 레이어가 끊기지 않게 그린다


func _init() -> void:
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
	var db := GameDatabase.new()
	db.load_all("res://data")
	var street: Dictionary = JsonUtil.get_dict(db.singletons.get("city", {}), "street")
	var baseline := int(GameDatabase.single(db.render, "city.baseline", 600))
	var scale := float(GameDatabase.single(db.render, "city.building_scale", 0.85))
	var width := JsonUtil.get_int(street, "width", 3600)
	var spans: Array = []
	var i := 0
	for id: String in db.get_collection("facilities"):
		var f := db.get_entry("facilities", id)
		i += 1
		var size: Vector2i = Buildings.SIZES.get(id, Vector2i(400, 400))
		var x := float(JsonUtil.get_int(f, "x"))
		spans.append([x, x + size.x * scale])
		if only.is_empty() or only == "buildings":
			Buildings.paint(id, SEED + i * 101).save(JsonUtil.get_str(f, "building"))
			print("그림: 건물 %s %dx%d" % [id, size.x, size.y])
		if only.is_empty() or only == "interiors":
			Interiors.paint(id, SEED + i * 211).save(JsonUtil.get_str(f, "interior"))
			print("그림: 내부 %s" % id)
	spans.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
	if only.is_empty() or only == "street":
		for layer: Variant in JsonUtil.get_array(street, "layers"):
			_paint_layer(layer as Dictionary, width, baseline, spans)
		for kind: Variant in JsonUtil.get_array(JsonUtil.get_dict(db.singletons.get("city", {}), "weather"), "kinds"):
			var sky_path := JsonUtil.get_str(kind as Dictionary, "sky")
			if JsonUtil.get_str(kind as Dictionary, "sky_style") == "clear" and not sky_path.is_empty():
				Backdrop.sky_clear(640, 360, SEED + 7).save(sky_path)
				print("그림: 맑은 하늘 → " + sky_path)
	if only.is_empty() or only == "plaza":
		var plaza_path := str(GameDatabase.single(db.render, "city.plaza.background", ""))
		if not plaza_path.is_empty():
			Plaza.paint(SEED + 31).save(plaza_path)
			print("그림: 차원광장 → " + plaza_path)
	quit(0)


func _paint_layer(layer: Dictionary, width: int, baseline: int, spans: Array) -> void:
	var id := JsonUtil.get_str(layer, "id")
	var path := JsonUtil.get_str(layer, "path")
	var s := JsonUtil.get_float(layer, "scale", 1.0)
	var par := JsonUtil.get_float(layer, "parallax", 1.0)
	var units_h := JsonUtil.get_float(layer, "height", 720.0)
	var units_w := MAX_VIEW + maxf(0.0, width - MAX_VIEW) * par
	if JsonUtil.get_bool(layer, "screen"):
		units_w = 1280.0
	var w := int(ceil(units_w / s))
	var h := int(ceil(units_h / s))
	var seed_value := SEED + id.hash() % 997
	var img: Variant = null
	match id:
		"sky":
			img = Backdrop.sky(w, h, seed_value)
		"far":
			img = Backdrop.far(w, h, seed_value)
		"mid":
			img = Backdrop.mid(w, h, seed_value)
		"haze":
			img = Backdrop.haze(w, h, seed_value)
		"vignette":
			img = Backdrop.vignette(w, h, seed_value)
		"street":
			img = Street.paint(width, baseline, spans, seed_value)
	if img == null:
		push_warning("알 수 없는 거리 레이어: " + id)
		return
	img.save(path)
	print("그림: 레이어 %s %dx%d → %s" % [id, img.w, img.h, path])
