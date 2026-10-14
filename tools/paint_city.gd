extends SceneTree
## 도시 그림 생성기: 거리 배경·시설 건물·시설 내부 PNG를 픽셀아트로 그려 data가 가리키는 경로에 저장한다.
##   godot --headless --path . --script res://tools/paint_city.gd
## 건물 위치(x)·그림 경로는 data/facilities, 거리 배경 경로는 data/city.json street.backdrop, 땅 높이는 render.json city.baseline.
## 손으로 그린 그림으로 바꾸려면 같은 경로에 PNG를 덮어쓰면 된다(게임은 경로만 읽는다).

const Buildings := preload("res://tools/city_art/Buildings.gd")
const Interiors := preload("res://tools/city_art/Interiors.gd")
const Street := preload("res://tools/city_art/Street.gd")
const SEED := 1015
const END_MARGIN := 86


func _init() -> void:
	var db := GameDatabase.new()
	db.load_all("res://data")
	var city: Dictionary = db.singletons.get("city", {})
	var baseline := int(GameDatabase.single(db.render, "city.baseline", 196))
	var spans: Array = []
	var width := 0
	var i := 0
	for id: String in db.get_collection("facilities"):
		var f := db.get_entry("facilities", id)
		i += 1
		var b: Variant = Buildings.paint(id, SEED + i * 101)
		var x := JsonUtil.get_int(f, "x")
		spans.append([x, x + int(b.w)])
		width = maxi(width, x + int(b.w) + END_MARGIN)
		b.save(JsonUtil.get_str(f, "building"))
		Interiors.paint(id, SEED + i * 211).save(JsonUtil.get_str(f, "interior"))
		print("그림: %s 건물 %dx%d, 내부" % [id, b.w, b.h])
	spans.sort_custom(func(a: Array, c: Array) -> bool: return int(a[0]) < int(c[0]))
	var street_path := JsonUtil.get_str(JsonUtil.get_dict(city, "street"), "backdrop")
	Street.paint(width, baseline, spans, SEED).save(street_path)
	print("그림: 거리 %dx%d → %s" % [width, Street.HEIGHT, street_path])
	quit(0)
