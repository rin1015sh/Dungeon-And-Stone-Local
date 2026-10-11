class_name CommandMenu
extends VBoxContainer
## 전투 기본 행동창: 공격 · 방어 · 스킬 · 도주.
##   공격 → 대상 선택(약점이 있는 적은 "약점 노리기" 버튼이 함께 나온다)
##   스킬 → 보유 스킬(대화·조사 포함) 목록 → 필요하면 대상 선택. 맨 아래 "아이템…" → 전투용 소지품.
## 고르면 chosen(action)을 한 번만 낸다(고른 즉시 메뉴를 닫아 중복 선택을 막는다).

signal chosen(action: Dictionary)

var _battle: Battle
var _unit: Combatant
var _title: Label
var _buttons: HFlowContainer


func _init() -> void:
	_title = UiTheme.label("", "body", "text_title")
	add_child(_title)
	_buttons = HFlowContainer.new()
	_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_buttons)


func open(battle: Battle, unit: Combatant) -> void:
	_battle = battle
	_unit = unit
	visible = true
	_root()


func close() -> void:
	visible = false
	_clear()


func _root() -> void:
	_set_title(Strings.t("combat.menu_root", {"name": _unit.label()}))
	_add(Strings.t("combat.cmd_attack"), _attack)
	_add(Strings.t("combat.cmd_guard"), func() -> void: _choose({"kind": "guard"}))
	_add(Strings.t("combat.cmd_skill"), _skills)
	_add(Strings.t("combat.cmd_flee", {"chance": roundi(_battle.flee_chance(_unit) * 100.0)}), func() -> void: _choose({"kind": "flee"}))
	_focus_first()


## 공격: 적 목록. 약점이 있는 적은 약점 노리기(명중이 낮고 피해가 크다)도 고를 수 있다.
func _attack() -> void:
	_set_title(Strings.t("combat.menu_target"))
	for t: Combatant in _battle.opponents(_unit):
		_add(_target_line(t), func() -> void: _choose_skill(Battle.BASIC_ATTACK, t))
		if not t.actor.weak_point().is_empty():
			_add(Strings.t("combat.target_weak", {"name": t.label()}), func() -> void:
				_choose({"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": t, "aim_weak": true}))
	_add_back()


func _skills() -> void:
	_set_title(Strings.t("combat.menu_skill"))
	var db := _battle.db
	for id in _unit.actor.skills:
		var sk := db.get_entry("skills", id)
		var cost := PackedStringArray()
		var costs := JsonUtil.get_dict(sk, "cost")
		for r: String in costs:
			cost.append("%s %d" % [db.resources[r].name_ko, int(costs[r])])
		var label := JsonUtil.get_str(sk, "name_ko", id) + ((" (" + ", ".join(cost) + ")") if not cost.is_empty() else "")
		var why := _battle.can_use(_unit, id)
		var b := _add(label, func() -> void: _skill_target(id))
		b.disabled = not why.is_empty()
		b.tooltip_text = Strings.t(why) if not why.is_empty() else JsonUtil.get_str(sk, "desc_ko")
	var item_btn := _add(Strings.t("combat.cmd_item"), _items)
	item_btn.disabled = _usable_items().is_empty()
	_add_back()


## 스킬 대상: 적 하나 → 적 목록, 아무나 하나 → 전장의 모두, 아군 하나 → 아군 목록. 그 밖은 바로 쓴다.
func _skill_target(skill_id: String) -> void:
	var kind := JsonUtil.get_str(_battle.db.get_entry("skills", skill_id), "target")
	var list: Array[Combatant] = []
	match kind:
		"enemy_single", "enemy_row":
			list = _battle.opponents(_unit)
		"any_single":
			list = _battle.side_units(_unit.side)
			list.append_array(_battle.opponents(_unit))
		"ally_single":
			list = _battle.side_units(_unit.side)
		_:
			_choose({"kind": "skill", "skill": skill_id})
			return
	_set_title(Strings.t("combat.menu_target"))
	for t in list:
		_add(_target_line(t), func() -> void: _choose_skill(skill_id, t))
	_add(Strings.t("menu.back"), _skills)
	_focus_first()


func _items() -> void:
	_set_title(Strings.t("combat.menu_item"))
	for id in _usable_items():
		_add("%s ×%d" % [DataNames.entry(_battle.db, "items", id), _unit.actor.inventory.count(id)],
			func() -> void: _choose({"kind": "item", "item": id}))
	_add(Strings.t("menu.back"), _skills)
	_focus_first()


func _usable_items() -> Array[String]:
	var out: Array[String] = []
	for id in _unit.actor.inventory.ids():
		if JsonUtil.get_bool(_battle.db.get_entry("items", id), "combat_usable"):
			out.append(id)
	return out


func _target_line(t: Combatant) -> String:
	return Strings.t("combat.target_line", {"name": t.label(), "hp": roundi(t.actor.pool.get_ratio("hp") * 100.0)})


func _choose_skill(skill_id: String, target: Combatant) -> void:
	_choose({"kind": "skill", "skill": skill_id, "target": target})


func _choose(action: Dictionary) -> void:
	if not visible:
		return
	close()
	chosen.emit(action)


func _add(text: String, cb: Callable) -> Button:
	var b := UiTheme.button(text, cb)
	b.custom_minimum_size.x = UiTheme.metric("combat_button_width", 150)
	_buttons.add_child(b)
	return b


func _add_back() -> void:
	_add(Strings.t("menu.back"), _root)
	_focus_first()


func _set_title(text: String) -> void:
	_clear()
	_title.text = text


func _clear() -> void:
	for c in _buttons.get_children():
		_buttons.remove_child(c)
		c.queue_free()


## 첫 버튼에 포커스(키보드 조작). 다음 프레임에 그때 남아 있는 버튼으로 잡는다(그사이 메뉴가 바뀌어도 안전).
func _focus_first() -> void:
	_grab_first.call_deferred()


func _grab_first() -> void:
	if not is_inside_tree() or not visible:
		return
	for c in _buttons.get_children():
		if c is Button and not (c as Button).disabled and (c as Button).is_inside_tree():
			(c as Button).grab_focus()
			return
