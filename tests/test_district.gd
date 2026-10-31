extends TestCase
## 도시 구역 하나(사용자 결정 2026-10-31, CT63 — 거주 등급·이사를 없애고 통일, 특별 시설만 따로): 이름·그림 등급 · 여관 식사 · 상점·대장간 ·
## 거리 사건 · 특별 시설은 거리에 없다 · 그림 · 저장.


func _state() -> CityState:
	var s := CityState.new(db, 7)
	s.start()
	return s


func test_one_district_no_moving() -> void:
	var s := _state()
	assert_eq(CityDistrict.name_of(s), "라비기온", "사는 구역은 하나")
	assert_eq(CityDistrict.look(s), 3, "그림은 밝은 등급(컴멜비 5구역 그림)")
	assert_false((db.singletons.get("city", {}) as Dictionary).has("residence"), "거주 등급 표는 없다")
	for id: String in db.get_collection("activities"):
		for e: Variant in JsonUtil.get_array(db.get_entry("activities", id), "effects"):
			assert_true(JsonUtil.get_str(e as Dictionary, "type") != "residence_up", "이사 효과 없음: " + id)


func test_inn_meals_always_feast_on_event() -> void:
	var s := _state()
	s.happenings.clear()
	assert_eq(CityActions.activities_of(s, "inn"), ["inn_rest", "inn_snack", "inn_meal", "inn_hearty"] as Array[String], "식사 값대 셋은 늘")
	s.happenings.assign(["inn_special"])
	assert_true(CityActions.activities_of(s, "inn").has("inn_feast"), "여관 특식 사건이 걸린 순에 특식")
	assert_true(CityHappenings.eligible(_state()).has("inn_special"), "여관 특식 사건은 언제든 걸릴 수 있다")


func test_shop_and_smithy_stock() -> void:
	var s := _state()
	var shop := CityShop.stock(s, "shop_trade")
	assert_true(shop.has("ration") and shop.has("medium_potion") and shop.has("lantern"), "상점은 예전 네 등급 물건을 모두 판다")
	var top := 0
	for id in CityShop.stock(s, "smithy_trade"):
		top = maxi(top, JsonUtil.get_int(db.get_entry("items", id), "tier", 1))
	assert_eq(top, CityDistrict.smithy_material_tier(s), "대장간 소재 단계 상한 = district.smithy_material_tier")
	assert_true(CityShop.stock(s, "smithy_trade").has("lightium_sword"), "라이티늄부터 살 수 있다(값이 막는다)")


func test_street_events_have_no_district_condition() -> void:
	var s := _state()
	assert_true(CityAmbient._ok(s, CityAmbient.entry(s, "pickpocket"), "pickpocket", "human"), "소매치기는 그대로 일어난다")
	for id: String in db.get_collection("street_events"):
		var w := JsonUtil.get_dict(db.get_entry("street_events", id), "when")
		assert_false(w.has("residence_max") or w.has("residence_min"), "구역 조건 없음: " + id)


## 특별 시설(거래소)은 거리에 서지 않고, 그 자리만큼 뒤 건물을 당긴다. 들어가는 것은 거리 끝 창에서(enter_facility는 그대로).
func test_special_facilities_off_street() -> void:
	var s := _state()
	assert_eq(CityDistrict.special_ids(db), ["exchange"] as Array[String], "특별 시설 = 거래소")
	assert_false(s.facility_ids().has("exchange"), "거리에는 없다")
	assert_eq(s.enter_facility("exchange"), "", "따로 가서 들어간다")
	s.leave_facility()
	assert_eq(s.ap, 2, "다녀오면 행동력 1")
	var slot := JsonUtil.get_float(db.get_entry("facilities", "exchange"), "slot")
	var raw := func(id: String) -> float: return float(JsonUtil.get_int(db.get_entry("facilities", id), "x"))
	assert_eq(CityDistrict.facility_x(db, "smithy"), float(raw.call("smithy")) - slot, "거래소 뒤 건물은 당긴다")
	assert_eq(CityDistrict.facility_x(db, "shop"), float(raw.call("shop")), "앞 건물은 그대로")
	var w := JsonUtil.get_float(JsonUtil.get_dict(db.singletons.get("city", {}), "street"), "width")
	assert_eq(CityDistrict.street_width(db, w), w - slot, "거리 길이도 그만큼 짧다")


func test_art_and_save() -> void:
	var s := _state()
	for id in s.facility_ids():
		var f := db.get_entry("facilities", id)
		for key: String in ["building", "interior"]:
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
