class_name CityBank
extends RefCounted
## 은행(돈 맡기기·찾기): 금액은 플레이어가 정한다. 잔액은 CityState.bank_balance.
## 수수료(city.json bank.deposit_fee·withdraw_fee = 금액에 대한 비율, null이면 0). 이자는 순이 바뀔 때 CityState가 붙인다(interest_per_period).
## 미궁 입장 시 소지금 처리 on_dungeon_enter = keep(그대로 들고 간다). 거래마다 활동(bank_account)의 이용료를 낸다.


static func fee(state: CityState, key: String, amount: int) -> int:
	var c := CityValues.city_section(state.db, state.overrides, "bank")
	return clampi(floori(amount * maxf(0.0, CityValues.num(c, key))), 0, amount)


static func deposit(state: CityState, pc: PlayerCharacter, act_id: String, amount: int) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if amount <= 0:
		return ctx.fail("city.reason_bad_amount")
	var why := CityActions.check(state, pc, act_id, amount)
	if not why.is_empty():
		return ctx.fail(why)
	CityActions.charge(ctx, act_id)
	var f := fee(state, "deposit_fee", amount)
	pc.inventory.add_money(-amount)
	state.bank_balance += amount - f
	ctx.say("city.bank_deposited", {"amount": amount, "fee": f, "balance": state.bank_balance, "money": pc.inventory.money}, "good")
	state.changed.emit()
	return ctx


static func withdraw(state: CityState, pc: PlayerCharacter, act_id: String, amount: int) -> CityContext:
	var ctx := CityContext.new(state, pc, act_id)
	if amount <= 0:
		return ctx.fail("city.reason_bad_amount")
	if amount > state.bank_balance:
		return ctx.fail("city.reason_no_balance")
	var why := CityActions.check(state, pc, act_id)
	if not why.is_empty():
		return ctx.fail(why)
	CityActions.charge(ctx, act_id)
	var f := fee(state, "withdraw_fee", amount)
	state.bank_balance -= amount
	pc.inventory.add_money(amount - f)
	ctx.say("city.bank_withdrew", {"amount": amount, "fee": f, "balance": state.bank_balance, "money": pc.inventory.money}, "good")
	state.changed.emit()
	return ctx
