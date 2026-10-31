class_name CityDistrict
extends RefCounted
## 도시 구역 하나(사용자 결정 2026-10-31 "거주지역 등급 상승 체계를 없애고 도시 구역은 하나로 통일, 특별시설만 따로 이동 — 지금 거주지역이 너무 어두워", CT63).
## city.json district: name_ko(사는 구역 — 달력 카드) · look(그림 등급 — 건물·거리·시설 내부 <경로>_t<look>, 1 = 기본 그림) ·
##   street_tint(먼 도시 레이어 색) · smithy_material_tier(대장간에서 살 수 있는 소재 단계 상한).
## 특별 시설(시설 JSON special — 알미너스 중앙 거래소 …)은 거리에 서지 않는다: 거리 오른쪽 끝에서 D → 고르는 창으로 바로 간다(CityScreen.offer_travel).
## 오토로드를 참조하지 않는다.


static func section(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "district")


static func name_of(state: CityState) -> String:
	return JsonUtil.get_str(section(state), "name_ko")


## 그림 등급(건물·거리·내부 그림 <경로>_t<look>). 1 = 기본 그림.
static func look(state: CityState) -> int:
	return maxi(1, JsonUtil.get_int(section(state), "look", 1))


## 먼 도시 레이어(원경·중경·안개)에 날씨 색과 함께 곱하는 색.
static func street_tint(state: CityState) -> Variant:
	return section(state).get("street_tint")


## 대장간에서 살 수 있는 소재 단계 상한.
static func smithy_material_tier(state: CityState) -> int:
	return maxi(1, JsonUtil.get_int(section(state), "smithy_material_tier", 1))


## 특별 시설(거리에 서지 않고 따로 가는 곳)인가.
static func is_special(db: GameDatabase, facility_id: String) -> bool:
	return JsonUtil.get_bool(db.get_entry("facilities", facility_id), "special")


## 특별 시설 id(데이터 order 순).
static func special_ids(db: GameDatabase) -> Array[String]:
	var out: Array[String] = []
	for id: String in db.get_collection("facilities"):
		if is_special(db, id):
			out.append(id)
	out.sort_custom(func(a: String, b: String) -> bool:
		return JsonUtil.get_int(db.get_entry("facilities", a), "order") < JsonUtil.get_int(db.get_entry("facilities", b), "order"))
	return out


## 거리에서 시설의 x(거리 단위): 데이터 x에서, 앞쪽에 있던 특별 시설의 slot만큼 당긴다(거래소가 서던 자리 — 그림 도구 paint_city도 같은 값).
static func facility_x(db: GameDatabase, facility_id: String) -> float:
	var x := float(JsonUtil.get_int(db.get_entry("facilities", facility_id), "x"))
	var out := x
	for other: String in db.get_collection("facilities"):
		var o := db.get_entry("facilities", other)
		if is_special(db, other) and float(JsonUtil.get_int(o, "x")) < x:
			out -= JsonUtil.get_float(o, "slot")
	return out


## 거리 길이: city.json street.width에서 특별 시설의 slot을 뺀다.
static func street_width(db: GameDatabase, width: float) -> float:
	var out := width
	for other: String in db.get_collection("facilities"):
		if is_special(db, other):
			out -= JsonUtil.get_float(db.get_entry("facilities", other), "slot")
	return out


## 그림 경로: look 1 = 데이터 경로, 그 위 = <같은 이름>_t<등급>.webp(없으면 아래 등급으로 — 결국 기본 그림).
static func art_path(base: String, t: int) -> String:
	for k in range(t, 1, -1):
		var p := base.get_basename() + "_t%d." % k + base.get_extension()
		if ResourceLoader.exists(p):
			return p
	return base
