class_name CityActions
extends RefCounted
## 도시 활동 실행: 조건 검사 → 이용 비용 지불 → 효과 목록 적용(레지스트리 src/city/effects/).
## 시설 안 활동은 행동력을 쓰지 않는다(행동력은 시설에 들어갈 때 facility_entry_cost만 — 사용자 결정 2026-10-15).
## 패널형 활동(shop·bank·essence_remove)은 거래마다 charge()로 비용을 낸다(CityShop·CityBank·CityTemple).
## cost_stones가 null(미정)이면 0. 오토로드를 참조하지 않는다.

const EFFECT_DIR := "res://src/city/effects"
const PANELS := ["shop", "bank", "essence_remove"]


static func stone_cost(act: Dictionary) -> int:
	return maxi(0, int(CityValues.num(act, "cost_stones")))


## 지금 낼 이용료.
static func cost(state: CityState, act_id: String) -> int:
	return stone_cost(state.activity(act_id))


## 지금 이 활동을 할 수 있는가. 할 수 있으면 "", 아니면 이유(문자열 키). extra_stones = 거래 금액 등 추가로 필요한 돈.
static func check(state: CityState, pc: PlayerCharacter, act_id: String, extra_stones: int = 0) -> String:
	var act := state.activity(act_id)
	if act.is_empty():
		return "city.reason_unknown"
	if state.facility != JsonUtil.get_str(act, "facility") or not activities_of(state, state.facility).has(act_id):
		return "city.reason_not_here"
	if _pays_tax(act):
		if not CityTax.owed(state, pc.race_id):
			return "city.reason_tax_none"
		extra_stones += CityTax.amount(state, pc.race_id)
	if pc.inventory.money < cost(state, act_id) + extra_stones:
		return "city.reason_no_money"
	return ""


## 세금 납부 활동인가(효과 pay_tax) — 낼 세금이 없으면 고를 수 없고, 소지금이 세금만큼 있어야 한다.
static func _pays_tax(act: Dictionary) -> bool:
	for e: Variant in JsonUtil.get_array(act, "effects"):
		if e is Dictionary and JsonUtil.get_str(e, "type") == "pay_tax":
			return true
	return false


## 선택지 칸 오른쪽 아래 글: 세금이면 낼 금액, 아니면 이용료(없으면 "").
static func price_text(state: CityState, pc: PlayerCharacter, act_id: String) -> String:
	if _pays_tax(state.activity(act_id)):
		return Strings.t("city.cost_stones", {"n": CityTax.amount(state, pc.race_id)})
	var stones := cost(state, act_id)
	return Strings.t("city.cost_stones", {"n": stones}) if stones > 0 else ""


## 이용 비용을 낸다(check를 통과했다고 본다). 결과 문구를 ctx에 남긴다.
static func charge(ctx: CityContext, act_id: String) -> void:
	var stones := cost(ctx.state, act_id)
	if stones > 0:
		ctx.pc.inventory.add_money(-stones)
		ctx.say("city.spent_stones", {"n": stones})


## 효과 목록형 활동을 한다. 결과는 ctx.messages.
static func perform(state: CityState, pc: PlayerCharacter, act_id: String, registry: ScriptRegistry) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	var why := check(state, pc, act_id)
	if not why.is_empty():
		return ctx.fail(why)
	var act := state.activity(act_id)
	if not JsonUtil.get_str(act, "panel").is_empty():
		return ctx.fail("city.reason_panel")
	charge(ctx, act_id)
	for e: Variant in JsonUtil.get_array(act, "effects"):
		if not e is Dictionary:
			continue
		var h := registry.instance(JsonUtil.get_str(e, "type")) as CityEffect
		if h != null:
			h.apply(ctx, e)
	state.changed.emit()
	return ctx


## 이 시설의 활동 id: 이번 순 사건(CityHappenings — 맨 앞) + 데이터 순서.
static func activities_of(state: CityState, facility_id: String) -> Array[String]:
	var out: Array[String] = CityHappenings.activities_at(state, facility_id)
	for v: Variant in JsonUtil.get_array(state.db.get_entry("facilities", facility_id), "activities"):
		if state.db.has_entry("activities", str(v)) and not out.has(str(v)):
			out.append(str(v))
	return out
