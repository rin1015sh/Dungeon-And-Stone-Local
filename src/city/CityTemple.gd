class_name CityTemple
extends RefCounted
## 신전 정수 제거: 기존 정수 삭제 로직(EssenceSet.remove)과 비용(EssenceSet.next_delete_cost — balance essence.delete_cost_*)을 그대로 쓴다.
## 활동(temple_remove_essence)의 행동력·이용 비용(미정이면 0)은 따로 낸다.


static func remove_essence(state: CityState, pc: PlayerCharacter, act_id: String, index: int) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if index < 0 or index >= pc.essences.absorbed.size():
		return ctx.fail("city.reason_no_essence")
	var cost := pc.essences.next_delete_cost(state.db)
	var why := CityActions.check(state, pc, act_id, cost)
	if not why.is_empty():
		return ctx.fail(why)
	var essence_id := JsonUtil.get_str(pc.essences.absorbed[index], "essence")
	CityActions.charge(ctx, act_id)
	pc.inventory.add_money(-cost)
	pc.essences.remove(pc, index, true)
	ctx.say("city.essence_removed", {"name": JsonUtil.get_str(state.db.get_entry("essences", essence_id), "name_ko", essence_id),
		"cost": cost, "next": pc.essences.next_delete_cost(state.db)}, "good")
	state.changed.emit()
	return ctx
