class_name BankPanel
extends CityPanel
## 은행 패널: 잔액·소지금 표시, 금액(그 칸에서 A/D로 city.bank_step씩 — 플레이어가 정한다) → 맡기기/찾기. 수수료는 미정(null이면 0).

var _amount: int = 0


func build() -> void:
	head(Strings.t("city.bank_status", {"balance": state.bank_balance, "money": pc.inventory.money}))
	choices()


func options() -> Array[Dictionary]:
	return [
		{"text": Strings.t("city.bank_amount"), "sub": Strings.t("city.cost_stones", {"n": _amount}), "on_adjust": _adjust},
		{"text": Strings.t("city.bank_deposit"), "enabled": _amount > 0, "on_pick": func() -> void: done(CityBank.deposit(state, pc, activity_id, amount()))},
		{"text": Strings.t("city.bank_withdraw"), "enabled": _amount > 0, "on_pick": func() -> void: done(CityBank.withdraw(state, pc, activity_id, amount()))},
		{"text": Strings.t("city.bank_all_money"), "on_pick": func() -> void: set_amount(pc.inventory.money)},
		{"text": Strings.t("city.bank_all_balance"), "on_pick": func() -> void: set_amount(state.bank_balance)},
	]


func amount() -> int:
	return _amount


func set_amount(v: int) -> void:
	_amount = clampi(v, 0, maxi(pc.inventory.money, state.bank_balance))
	rebuild()


func _adjust(dir: int) -> void:
	set_amount(_amount + dir * int(UiTheme.render_float("city.bank_step", 10.0)))
