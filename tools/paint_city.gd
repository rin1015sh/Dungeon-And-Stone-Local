extends SceneTree
## 도시 그림 생성기: 거리 레이어(하늘·원경·중경·안개·거리·비네트) · 시설 건물 · 시설 내부를
## 손으로 칠한 듯한 어두운 일러스트(피어 앤 헝거 2풍 — 거친 붓결·잉크 윤곽·빗금·탁한 색·그레인)로 그려 data가 가리키는 경로에 저장한다.
##   godot --headless --path . --script res://tools/paint_city.gd [-- --only=street|buildings|plaza|events] [--facility=<id>] [--event=<id>]
## (--facility: 그 시설 건물·내부만 다시 그린다 — 다른 그림은 그대로 · --event: 그 거리 사건 일러스트만 — data/street_events art, CT45)
## 좌표 = '거리 단위'(화면 높이 720 기준 px). 건물 위치는 data/facilities x, 레이어 목록·경로는 data/city.json street,
## 땅 높이·건물 배율은 render.json city.baseline·building_scale. 손으로 그린 그림으로 바꾸려면 같은 경로에 덮어쓰면 된다.

const Buildings := preload("res://tools/city_art/Buildings.gd")
const Street := preload("res://tools/city_art/Street.gd")
const Backdrop := preload("res://tools/city_art/Backdrop.gd")
const Plaza := preload("res://tools/city_art/Plaza.gd")
const Events := preload("res://tools/city_art/Events.gd")
const Settle := preload("res://tools/city_art/Settle.gd")
const SEED := 1015
## 그림 시드 순서(시설 id → 번호). 시설이 늘어도 기존 그림이 바뀌지 않게 고정 — 새 시설은 끝에 붙인다.
const SEED_ORDER := ["bank", "inn", "library", "shop", "temple", "training", "smithy", "guild", "exchange"]  # 시드 순서 — 없앤 시설(훈련장·거래소)도 자리는 둔다(뒤 건물 그림이 바뀌지 않게)
## 그림 등급마다 따로 그리는 레이어(<경로>_t<등급> — CityStreet가 city.json district.look 것을 고른다, CT54·CT63). 나머지는 한 장.
const TIER_LAYERS := ["far", "mid", "street"]
## 그림 등급 수(1 = 옛 라비기온 13구역 뒷골목 · 2 = 7구역 · 3 = 컴멜비 5구역 · 4 = 3구역 — 지금 게임은 district.look 하나만 쓴다, CT63).
const LOOKS := 4
## 그 등급부터 그리는 시설(그 등급 그림 = 기본 경로, 위 등급 = _t<등급>) — 거래소는 컴멜비 5구역 그림부터.
const FIRST_LOOK := {"exchange": 3}
const MAX_VIEW := 1700.0  ## 이 너비(거리 단위)까지 보이는 화면에서 시차 레이어가 끊기지 않게 그린다


func _init() -> void:
	var only := ""
	var one := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.trim_prefix("--only=")
		if a.begins_with("--facility="):
			one = a.trim_prefix("--facility=")
			only = "facility"
		if a.begins_with("--event="):
			one = a.trim_prefix("--event=")
			only = "events"
	var db := GameDatabase.new()
	db.load_all("res://data")
	var street: Dictionary = JsonUtil.get_dict(db.singletons.get("city", {}), "street")
	var baseline := int(GameDatabase.single(db.render, "city.baseline", 600))
	var scale := float(GameDatabase.single(db.render, "city.building_scale", 0.85))
	var width := JsonUtil.get_int(street, "width", 3600)
	var spans: Array = []  # 등급 → [[x0, x1] …](거리에 서는 건물만 — 특별 시설 자리는 당긴다, CityDistrict.facility_x, CT63)
	var tiers := LOOKS
	for id: String in db.get_collection("facilities"):
		var f := db.get_entry("facilities", id)
		var i := SEED_ORDER.find(id) + 1 if SEED_ORDER.has(id) else 100 + absi(id.hash()) % 900
		var size: Vector2i = Buildings.SIZES.get(id, Vector2i(400, 400))
		var t0 := clampi(int(FIRST_LOOK.get(id, 1)), 1, tiers)
		var mine := only == "facility" and id == one
		if only.is_empty() or only == "buildings" or mine:
			var base := JsonUtil.get_str(f, "building")
			for t in range(t0, tiers + 1):  # 그림 등급마다(첫 등급 = 기본 경로, 그 위 = <이름>_t<등급> — CityDistrict.art_path)
				Buildings.paint(id, SEED + i * 101, t).save(_tier_path(base, t, t0))
				print("그림: 건물 %s 등급 %d %dx%d" % [id, t, size.x, size.y])
	for t in range(1, tiers + 1):
		var here: Array = []
		for id: String in db.get_collection("facilities"):
			if not CityDistrict.is_special(db, id):
				var x := CityDistrict.facility_x(db, id)
				here.append([x, x + Buildings.SIZES.get(id, Vector2i(400, 400)).x * scale])
		here.sort_custom(func(a: Array, c: Array) -> bool: return float(a[0]) < float(c[0]))
		spans.append(here)
	if only.is_empty() or only == "street":
		for layer: Variant in JsonUtil.get_array(street, "layers"):
			var tiered := JsonUtil.get_str(layer as Dictionary, "id") in TIER_LAYERS
			for t in range(1, tiers + 1 if tiered else 2):  # 구역마다 그리는 레이어는 그 구역 거리 길이로, 나머지는 가장 긴 거리로
				var w := int(CityDistrict.street_width(db, width)) if tiered else width
				_paint_layer(layer as Dictionary, w, baseline, spans[t - 1], t)
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
	if only.is_empty() or only == "settle":  # 귀환 정산 일러스트(CT58 — 천막·저울·길드 직원)
		var settle_path := str(GameDatabase.single(db.render, "city.plaza.settle_art", ""))
		if not settle_path.is_empty():
			Settle.paint(SEED + 47).save(settle_path)
			print("그림: 귀환 정산 → " + settle_path)
	if only.is_empty() or only == "events":
		for id: String in db.get_collection("street_events"):
			var path := JsonUtil.get_str(db.get_entry("street_events", id), "art")
			if path.is_empty() or (not one.is_empty() and id != one):
				continue
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
			var t0 := Time.get_ticks_msec()
			Events.paint(id, SEED + 500 + absi(id.hash()) % 9973).save(path)
			print("그림: 거리 사건 %s (%d ms)" % [id, Time.get_ticks_msec() - t0])
	quit(0)


## 등급 t 그림 경로: 시설이 서는 첫 등급 t0(레이어는 1)이면 기본 경로, 그 위는 <이름>_t<등급>.
static func _tier_path(base: String, t: int, t0: int = 1) -> String:
	return base if t == t0 else base.get_basename() + "_t%d." % t + base.get_extension()


func _paint_layer(layer: Dictionary, width: int, baseline: int, spans: Array, tier: int = 1) -> void:
	var id := JsonUtil.get_str(layer, "id")
	var path := _tier_path(JsonUtil.get_str(layer, "path"), tier)
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
			img = Backdrop.far(w, h, seed_value, tier)
		"mid":
			img = Backdrop.mid(w, h, seed_value, tier)
		"haze":
			img = Backdrop.haze(w, h, seed_value)
		"vignette":
			img = Backdrop.vignette(w, h, seed_value)
		"street":
			img = Street.paint(width, baseline, spans, seed_value, tier)
	if img == null:
		push_warning("알 수 없는 거리 레이어: " + id)
		return
	img.save(path)
	print("그림: 레이어 %s %dx%d → %s" % [id, img.w, img.h, path])
