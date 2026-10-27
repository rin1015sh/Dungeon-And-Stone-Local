class_name CityExchange
extends RefCounted
## 알미너스 중앙 거래소(사용자 2026-10-27, CT54): 컴멜비 5구역부터 거리에 서는 시설(facilities exchange — min_residence).
##   창구 = 팔기만(활동 exchange_trade: panel shop, tabs ["sell"]) — 무엇이든(장비·잡화·마석) 상점보다 후하게(활동 sell_ratio),
##   마석은 순마다 바뀌는 시세(city.json exchange.stone_rate [최소, 최대] — 활동 stone_market)로 산다.
##   시세는 새 순에 거래소가 열려 있을 때만 굴린다(CityState.rng — 13구역 판정 순서는 그대로) → price_mods "market:magic_stone"(저장된다).
## 오토로드를 참조하지 않는다.

const KEY := "market:magic_stone"


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "exchange")


## 시세를 쓰는 시설(활동 stone_market)이 지금 구역에 서 있으면 이번 순 마석 시세를 굴린다.
static func roll(state: CityState) -> void:
	if not open(state):
		return
	var r := JsonUtil.get_array(config(state), "stone_rate")
	if r.size() < 2 or r[0] == null or r[1] == null:
		return
	var lo := float(r[0])
	var hi := float(r[1])
	state.price_mods[KEY] = snappedf(lo + state.rng.randf() * maxf(0.0, hi - lo), 0.01)


## 이번 순 마석 시세(배율 — 굴리지 않았으면 1).
static func rate(state: CityState) -> float:
	return float(state.price_mods.get(KEY, 1.0))


## 마석 시세를 쓰는 창구가 있는 시설이 지금 구역에 서 있는가.
static func open(state: CityState) -> bool:
	for fid in state.facility_ids():
		for a: Variant in JsonUtil.get_array(state.db.get_entry("facilities", fid), "activities"):
			if JsonUtil.get_bool(state.activity(str(a)), "stone_market"):
				return true
	return false
