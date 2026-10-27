class_name CityResidence
extends RefCounted
## 거주 구역(사용자 2026-10-27, CT50): 라프도니아 14구역 중 사는 곳 — city.json residence.tiers(1부터: 라비기온 13구역 → 7구역 → 컴멜비 5구역 → 3구역).
## 은행 '이사'(효과 residence_up)로 다음 등급의 upgrade_cost를 내고 한 단계 올린다. 등급이 바꾸는 것:
##   건물 외관(building_path) · 활동 min_residence(여관 식사 — 오늘의 거리로 붙는 활동은 event_min_residence) ·
##   상점 판매 목록(CityShop) · 대장간 소재 단계 상한(smithy_material_tier) · 도서관 서적 tier(CityInfo) · 거리 사건(CityAmbient).
## 오토로드를 참조하지 않는다.


static func tiers(state: CityState) -> Array:
	return JsonUtil.get_array(CityValues.city_section(state.db, state.overrides, "residence"), "tiers")


static func max_tier(state: CityState) -> int:
	return maxi(1, tiers(state).size())


## 지금 등급(1 ~ max_tier).
static func tier(state: CityState) -> int:
	return clampi(state.residence, 1, max_tier(state))


static func def(state: CityState, t: int = -1) -> Dictionary:
	var list := tiers(state)
	var i := (tier(state) if t < 0 else t) - 1
	return list[i] if i >= 0 and i < list.size() and list[i] is Dictionary else {}


static func name_of(state: CityState, t: int = -1) -> String:
	return JsonUtil.get_str(def(state, t), "name_ko")


## 다음 등급으로 옮기는 값. 이미 가장 높으면 -1.
static func next_cost(state: CityState) -> int:
	if tier(state) >= max_tier(state):
		return -1
	return maxi(0, int(CityValues.num(def(state, tier(state) + 1), "upgrade_cost")))


## 이 활동을 지금 등급에서 할 수 있는가(min_residence — 오늘의 거리 사건으로 붙은 것이면 event_min_residence가 먼저).
static func allows_activity(state: CityState, act: Dictionary, from_event: bool = false) -> bool:
	var need := JsonUtil.get_int(act, "min_residence", 1)
	if from_event and act.has("event_min_residence"):
		need = JsonUtil.get_int(act, "event_min_residence", need)
	return tier(state) >= need


## 물가 배율(시설 이용료·상점/대장간 사는 값 — 컴멜비는 비싸다).
static func price_mult(state: CityState) -> float:
	return maxf(0.0, JsonUtil.get_float(def(state), "price_mult", 1.0))


## 대장간에서 살 수 있는 소재 단계 상한.
static func smithy_material_tier(state: CityState) -> int:
	return maxi(1, JsonUtil.get_int(def(state), "smithy_material_tier", 1))


## when.residence_min / residence_max(거리 사건·오늘의 거리)가 맞는가.
static func when_ok(state: CityState, w: Dictionary) -> bool:
	var t := tier(state)
	return t >= JsonUtil.get_int(w, "residence_min", 1) and t <= JsonUtil.get_int(w, "residence_max", 999)


## 거리 사건 가중치 배율 residence_weight {"등급": 배율}(없으면 1).
static func weight_mult(state: CityState, e: Dictionary) -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(e, "residence_weight"), str(tier(state)), 1.0)


## 건물 그림 경로: 1등급 = 시설 데이터 building, 그 위 = <같은 이름>_t<등급>.webp(없으면 아래 등급으로).
static func building_path(base: String, t: int) -> String:
	for k in range(t, 1, -1):
		var p := base.get_basename() + "_t%d." % k + base.get_extension()
		if ResourceLoader.exists(p):
			return p
	return base


## 한 등급 올린다(돈은 부르는 쪽이 이미 확인 — 여기서 낸다). 못 올리면 이유 키.
static func upgrade(state: CityState, pc: PlayerCharacter) -> String:
	var cost := next_cost(state)
	if cost < 0:
		return "city.reason_residence_max"
	if pc.inventory.money < cost:
		return "city.reason_no_money"
	pc.inventory.add_money(-cost)
	state.residence = tier(state) + 1
	return ""
