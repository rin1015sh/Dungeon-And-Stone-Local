class_name CityTax
extends RefCounted
## 세금(사용자 결정 2026-10-20 — 원작 설정 참고, CT37): 해마다 한 번, city.json tax.due_month(그해 몇 번째 달)의 하순이 끝나
## 포탈로 떠나기 전까지 은행에서 낸다(효과 pay_tax). 못 냈으면 처형 — 사망과 같다(CityScreen).
##   금액 = by_year[연차−1](넘으면 마지막) × scale × race_rate[종족](없으면 1) × relief[종족].ratio(연차 ≤ years일 때). exempt 종족 = 0.
## 원작: 이종족 1년 차 70만·2년 차부터 80만 스톤, 인간은 이종족보다 적게(사용자 결정 — race_rate), 바바리안 2년 감면, 용인 면제.
## 값이 null(미정)이면 세금 없음. 오토로드를 참조하지 않는다.


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "tax")


## 올해 낼 세금(0 = 없음).
static func amount(state: CityState, race_id: String) -> int:
	var c := config(state)
	var years := JsonUtil.get_array(c, "by_year")
	if years.is_empty() or race_id in JsonUtil.get_array(c, "exempt"):
		return 0
	var y := state.year()
	var base: Variant = years[mini(y, years.size()) - 1]
	if base == null:
		return 0
	var v := float(base) * CityValues.num(c, "scale")
	var rates := JsonUtil.get_dict(c, "race_rate")
	if rates.get(race_id) != null:
		v *= float(rates[race_id])
	var relief := JsonUtil.get_dict(JsonUtil.get_dict(c, "relief"), race_id)
	if not relief.is_empty() and y <= JsonUtil.get_int(relief, "years") and relief.get("ratio") != null:
		v *= float(relief["ratio"])
	return maxi(0, floori(v))


static func due_month(state: CityState) -> int:
	return clampi(JsonUtil.get_int(config(state), "due_month", state.months_per_year()), 1, state.months_per_year())


static func paid(state: CityState) -> bool:
	return state.tax_paid_year >= state.year()


## 올해 아직 낼 세금이 남았는가.
static func owed(state: CityState, race_id: String) -> bool:
	return not paid(state) and amount(state, race_id) > 0


## 기한(그해 due_month의 하순 끝)에 이르렀는데 안 냈다 — 포탈 앞에서 부른다.
static func overdue(state: CityState, race_id: String) -> bool:
	return owed(state, race_id) and state.month_of_year() >= due_month(state) and state.is_last_period()


## 낸다(소지금에서). 실패하면 이유 키.
static func pay(state: CityState, pc: PlayerCharacter) -> String:
	if not owed(state, pc.race_id):
		return "city.reason_tax_none"
	var n := amount(state, pc.race_id)
	if pc.inventory.money < n:
		return "city.reason_no_money"
	pc.inventory.add_money(-n)
	state.tax_paid_year = state.year()
	return ""
