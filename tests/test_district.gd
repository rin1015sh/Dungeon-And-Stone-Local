extends TestCase
## 도시 구역 하나(사용자 결정 2026-10-31, CT63 — 거주 등급·이사를 없애고 통일 → CT64 라비기온 7구역, 거래소 없음): 이름·그림 등급 · 여관 식사 ·
## 상점·대장간 · 특별 시설 · 그림 · 저장.


func _state() -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	return s


func test_one_district_no_moving() -> void:
	var s := _state()
	assert_eq(CityDistrict.name_of(s), "라비기온 7구역", "사는 구역은 하나 — 라비기온 7구역(CT64)")
	assert_eq(CityDistrict.look(s), 2, "그림은 7구역 그림")
	assert_false((db.singletons.get("city", {}) as Dictionary).has("residence"), "거주 등급 표는 없다")
	for id: String in db.get_collection("activities"):
		for e: Variant in JsonUtil.get_array(db.get_entry("activities", id), "effects"):
			assert_true(JsonUtil.get_str(e as Dictionary, "type") != "residence_up", "이사 효과 없음: " + id)


func test_inn_meals_hearty_and_feast() -> void:
	var s := _state()
	assert_eq(CityActions.activities_of(s, "inn"), ["inn_rest", "inn_snack", "inn_meal", "inn_hearty", "inn_feast"] as Array[String],
		"7구역 여관 = 휴식·요기·식사·든든한 식사·특식(도시 사건을 없애 늘 — CT114)")


func test_shop_and_smithy_stock() -> void:
	var s := _state()
	var shop := CityShop.stock(s, "shop_trade")
	assert_true(shop.has("ration") and shop.has("medium_potion") and not shop.has("lantern"), "상점 = 7구역 물건(옛 2등급까지)")
	var top := 0
	for id in CityShop.stock(s, "smithy_trade"):
		top = maxi(top, JsonUtil.get_int(db.get_entry("items", id), "tier", 1))
	assert_eq(top, CityDistrict.smithy_material_tier(s), "대장간 소재 단계 상한 = district.smithy_material_tier")
	assert_eq(CityDistrict.smithy_material_tier(s), 2, "대장간 = 라이티늄까지(7구역)")
	assert_true(CityShop.stock(s, "smithy_trade").has("lightium_sword"), "라이티늄 검")


## 특별 시설(시설 special — 거리 끝 D로 따로 간다)은 지금 없다 — 거래소를 없앴다(CT64). 거리는 데이터 x 그대로.
func test_no_special_facilities_now() -> void:
	var s := _state()
	assert_true(CityDistrict.special_ids(db).is_empty(), "특별 시설 없음")
	assert_false(db.has_entry("facilities", "exchange") or db.has_entry("activities", "exchange_trade"), "거래소 없음")
	assert_eq(CityDistrict.facility_x(db, "smithy"), float(JsonUtil.get_int(db.get_entry("facilities", "smithy"), "x")), "건물 자리 = 데이터 x")
	var w := JsonUtil.get_float(JsonUtil.get_dict(db.singletons.get("city", {}), "street"), "width")
	assert_eq(CityDistrict.street_width(db, w), w, "거리 길이 = 데이터")
	assert_eq(s.facility_ids().size(), 7, "거리 시설 일곱(훈련장 없앰 — 2026-11-01)")


func test_art_and_save() -> void:
	var s := _state()
	for id in s.facility_ids():
		var f := db.get_entry("facilities", id)
		for key: String in ["building"]:
			var b := JsonUtil.get_str(f, key)
			assert_true(CityDistrict.art_path(b, CityDistrict.look(s)) != b, "%s %s 그림 등급 %d" % [id, key, CityDistrict.look(s)])
	for layer: String in ["far", "mid", "street"]:
		assert_true(ResourceLoader.exists("res://assets/city/layers/%s_t%d.webp" % [layer, CityDistrict.look(s)]), "거리 레이어 " + layer)
	s.reach_floor(2)
	var copy := CityState.new(db, 1)
	copy.load_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(copy.reached_floor, 2, "저장 왕복")
	copy.load_dict({"residence": 3})
	assert_eq(copy.reached_floor, 1, "옛 저장(거주 등급)도 읽는다")
