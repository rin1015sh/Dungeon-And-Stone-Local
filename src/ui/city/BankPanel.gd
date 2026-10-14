class_name BankPanel
extends CityPanel
## 은행 패널: 잔액·소지금 표시, 금액 입력(플레이어가 정한다) → 맡기기/찾기. 수수료는 미정(null이면 0).

var _amount: SpinBox


func build() -> void:
	add_child(UiTheme.label(Strings.t("city.bank_status", {"balance": state.bank_balance, "money": pc.inventory.money}), "body", "text_title"))
	var h := HBoxContainer.new()
	add_child(h)
	h.add_child(UiTheme.label(Strings.t("city.bank_amount"), "small", "text"))
	_amount = SpinBox.new()
	_amount.min_value = 0
	_amount.max_value = maxi(pc.inventory.money, state.bank_balance)
	_amount.step = 1
	_amount.rounded = true
	_amount.allow_greater = true
	_amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_amount)
	var quick := HBoxContainer.new()
	add_child(quick)
	quick.add_child(UiTheme.button(Strings.t("city.bank_all_money"), func() -> void: _amount.value = pc.inventory.money))
	quick.add_child(UiTheme.button(Strings.t("city.bank_all_balance"), func() -> void: _amount.value = state.bank_balance))
	var acts := HBoxContainer.new()
	add_child(acts)
	acts.add_child(UiTheme.button(Strings.t("city.bank_deposit"), func() -> void: done(CityBank.deposit(state, pc, activity_id, amount()))))
	acts.add_child(UiTheme.button(Strings.t("city.bank_withdraw"), func() -> void: done(CityBank.withdraw(state, pc, activity_id, amount()))))
	var note := UiTheme.label(Strings.t("city.bank_note"), "small", "text_dim")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)


func amount() -> int:
	return int(_amount.value) if _amount != null else 0


func set_amount(v: int) -> void:
	_amount.value = v
