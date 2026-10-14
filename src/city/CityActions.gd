class_name CityActions
extends RefCounted
## 도시 활동 실행: 조건 검사 → 행동력·비용 지불 → 효과 목록 적용(레지스트리 src/city/effects/).
## 패널형 활동(shop·bank·essence_remove)은 거래마다 charge()로 행동력·비용을 낸다(CityShop·CityBank·CityTemple).
## ap_cost·cost_stones가 null(미정)이면 0. 오토로드를 참조하지 않는다.

const EFFECT_DIR := "res://src/city/effects"
const PANELS := ["shop", "bank", "essence_remove"]


static func ap_cost(act: Dictionary) -> int:
	return maxi(0, int(CityValues.num(act, "ap_cost")))


static func stone_cost(act: Dictionary) -> int:
	return maxi(0, int(CityValues.num(act, "cost_stones")))


## 지금 이 활동을 할 수 있는가. 할 수 있으면 "", 아니면 이유(문자열 키). extra_stones = 거래 금액 등 추가로 필요한 돈.
static func check(state: CityState, pc: PlayerCharacter, act_id: String, extra_stones: int = 0) -> String:
	var act := state.activity(act_id)
	if act.is_empty():
		return "city.reason_unknown"
	if state.facility != JsonUtil.get_str(act, "facility"):
		return "city.reason_not_here"
	if not state.can_spend(ap_cost(act)):
		return "city.reason_no_ap"
	if pc.inventory.money < stone_cost(act) + extra_stones:
		return "city.reason_no_money"
	return ""


## 행동력·이용 비용을 낸다(check를 통과했다고 본다). 결과 문구를 ctx에 남긴다.
static func charge(ctx: CityContext, act_id: String) -> void:
	var act := ctx.state.activity(act_id)
	var ap := ap_cost(act)
	var stones := stone_cost(act)
	ctx.state.spend_ap(ap)
	if ap > 0:
		ctx.say("city.spent_ap", {"n": ap, "left": ctx.state.ap})
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


## 이 시설의 활동 id(데이터 순서).
static func activities_of(state: CityState, facility_id: String) -> Array[String]:
	var out: Array[String] = []
	for v: Variant in JsonUtil.get_array(state.db.get_entry("facilities", facility_id), "activities"):
		if state.db.has_entry("activities", str(v)):
			out.append(str(v))
	return out
