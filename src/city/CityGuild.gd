class_name CityGuild
extends RefCounted
## 모험가 길드 조사 의뢰(2026-10-22, CT44 — docs/plans/dungeon_loop_review.md B1): 길드는 늘 몬스터 한 종의 조사를 의뢰한다.
##   의뢰 = CityState.guild_request {monster, until}(until = 이 달까지 유효 — 받은 달 + months − 1, 그 사이 원정 한 번).
##   전투에서 그 종에게 '조사'를 쓰면 한 마리에 한 번 센다(Knowledge.note_survey). 길드 '조사 보고'로 넘기면
##   min(센 수, cap) × stones_per × (10 − 등급)을 받고 모든 조사 수가 지워진다. 넘겼거나 기한이 지나면 다음 순에 새 의뢰.
## 값은 city.json guild {survey_pool[몬스터 id], months, stones_per, cap}. 판정은 CityState.rng. 오토로드를 참조하지 않는다.


static func config(state: CityState) -> Dictionary:
	return CityValues.city_section(state.db, state.overrides, "guild")


## 순이 시작될 때: 의뢰가 없거나·넘겼거나·기한이 지났으면 새로 고른다(같은 종이 이어지지 않게 — 고를 종이 둘 이상이면).
static func refresh(state: CityState) -> void:
	var req := state.guild_request
	if not req.is_empty() and not JsonUtil.get_bool(req, "done") and state.month <= JsonUtil.get_int(req, "until"):
		return
	var pool: Array = []
	for id: Variant in JsonUtil.get_array(config(state), "survey_pool"):
		if state.db.has_entry("monsters", str(id)):
			pool.append(str(id))
	if pool.size() > 1:
		pool.erase(JsonUtil.get_str(req, "monster"))
	if pool.is_empty():
		state.guild_request = {}
		return
	state.guild_request = {"monster": str(state.rng.pick(pool)),
		"until": state.month + maxi(1, int(JsonUtil.get_float(config(state), "months", 2.0))) - 1}


## 지금 의뢰받은 몬스터 id(없으면 "").
static func target(state: CityState) -> String:
	return JsonUtil.get_str(state.guild_request, "monster")


static func cap(state: CityState) -> int:
	return maxi(1, int(JsonUtil.get_float(config(state), "cap", 1.0)))


## 한 마리 값(stones_per × (10 − 등급)).
static func payout_each(state: CityState) -> int:
	var grade := JsonUtil.get_int(state.db.get_entry("monsters", target(state)), "grade", 9)
	return maxi(0, int(CityValues.num(config(state), "stones_per"))) * maxi(1, 10 - grade)


## 넘기면 받을 값(센 수는 cap까지).
static func payout(state: CityState, pc: PlayerCharacter) -> Dictionary:
	var id := target(state)
	var n := mini(pc.knowledge.surveys(id), cap(state)) if not id.is_empty() else 0
	return {"n": n, "stones": n * payout_each(state)}


## 넘긴다: 돈을 받고 조사 수를 모두 지우고 의뢰를 끝낸다. 넘긴 것이 없으면 아무것도 바꾸지 않는다.
static func report(state: CityState, pc: PlayerCharacter) -> Dictionary:
	var p := payout(state, pc)
	if int(p["n"]) <= 0:
		return p
	pc.inventory.add_money(int(p["stones"]))
	pc.knowledge.clear_surveys()
	state.guild_request["done"] = true
	state.changed.emit()
	return p
