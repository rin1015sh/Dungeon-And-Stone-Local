class_name CommandMenu
extends HBoxContainer
## 전투 아래 창(피어 앤 헝거식): 왼쪽 = 명령 칸(공격 · 스킬 · 방어 · 아이템, 세로 한 줄),
## 오른쪽 = 파티 창(PartyRoster — 지금 차례인 사람의 줄이 밝다). 스킬·아이템·대상을 고를 때는 오른쪽이 목록 칸(ChoiceGrid 2×3)으로 바뀐다.
##   공격 → 대상(약점이 있는 적은 "약점 노리기"도) · 스킬 → 보유 스킬 + 맨 끝 "도주"(성공 확률) → 필요하면 대상 · 아이템 → 전투용 소지품
##   대상을 고를 때 커서가 놓인 적은 무대에서 발밑 고리가 빛나고(target_hovered), 무대의 적을 직접 눌러도 된다(pick_target).
## 키: 위·아래(W·S) 이동, Space 확정, Enter 뒤로. 스킬 칸 커서와 마지막 대상은 차례가 바뀌어도 기억한다.
## 고르면 chosen(action)을 한 번만 낸다(고른 즉시 닫아 중복 선택을 막는다). 적 차례에는 명령 칸이 흐리게 남는다.

signal chosen(action: Dictionary)
signal target_hovered(target: Combatant)
## 명령 칸에서 뒤로(Enter) — 앞사람의 행동을 다시 고른다.
signal root_back

const ROOT_ATTACK := 0
const ROOT_SKILL := 1
const ROOT_GUARD := 2
const ROOT_ITEM := 3

var _battle: Battle
var _unit: Combatant
var _cmds: ChoiceGrid
var _list: ChoiceGrid
var _roster: Control
var _open: bool = false
var _skill_cursor: Dictionary = {}  # 유닛 instance id -> 스킬 칸 커서
var _last_target: Dictionary = {}   # 유닛 instance id -> 마지막으로 고른 대상(Combatant)


func _init() -> void:
	add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	var left := _window()
	left.custom_minimum_size.x = UiTheme.metric("combat_cmd_width", 200)
	add_child(left)
	_cmds = ChoiceGrid.new(1, 4, UiTheme.metric("combat_cmd_slot_height", 36), true)
	_cmds.cursor_moved.connect(func(_i: int) -> void: target_hovered.emit(null))
	left.add_child(_cmds)
	var right := _window()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(right)
	var stack := VBoxContainer.new()
	right.add_child(stack)
	_list = ChoiceGrid.new(2, 3, UiTheme.metric("combat_list_slot_height", 40))
	_list.visible = false
	_list.active = false
	_list.cursor_moved.connect(func(_i: int) -> void: target_hovered.emit(_list.current_option().get("target")))
	stack.add_child(_list)


static func _window() -> PanelContainer:
	var p := PanelContainer.new()
	var box := UiTheme.box(Color(0.06, 0.055, 0.05, 0.99), UiTheme.color("slot_border"), 3, UiTheme.metric("padding", 8))
	box.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", box)
	return p


## 파티 창을 오른쪽 창에 넣는다(목록을 고를 때는 숨는다).
func set_roster(r: Control) -> void:
	_roster = r
	_list.get_parent().add_child(r)
	_list.get_parent().move_child(r, 0)


func open(battle: Battle, unit: Combatant) -> void:
	_battle = battle
	_unit = unit
	_open = true
	_root(ROOT_ATTACK)


func close() -> void:
	_open = false
	_show_list(false)
	_cmds.active = false
	var opts: Array[Dictionary] = []
	for k: String in ["combat.cmd_attack", "combat.cmd_skill", "combat.cmd_guard", "combat.cmd_item"]:
		opts.append(_opt(Strings.t(k), "", "", Callable(), false))
	_cmds.show_choices("", opts)
	target_hovered.emit(null)


func is_open() -> bool:
	return _open


## 지금 키를 받는 칸(명령 칸 또는 목록 칸).
func grid() -> ChoiceGrid:
	return _list if _list.visible else _cmds


func root_grid() -> ChoiceGrid:
	return _cmds


## 무대에서 누른 참가자를 대상으로 고른다(대상 목록이 열려 있고 그 참가자가 있을 때만).
func pick_target(u: Combatant) -> void:
	if not _open or not _list.visible:
		return
	var opts := _list.option_count()
	for i in opts:
		var o := _list.option(i)
		if o.get("target") == u and bool(o.get("enabled", true)) and not str(o.get("text", "")).is_empty():
			_list.select(i)
			_list.confirm()
			return


func _show_list(on: bool) -> void:
	_list.visible = on
	_list.active = on
	_cmds.active = not on and _open
	if _roster != null:
		_roster.visible = not on


func _root(start: int) -> void:
	var items := _usable_items()
	var opts: Array[Dictionary] = [
		_opt(Strings.t("combat.cmd_attack"), "", "", _attack),
		_opt(Strings.t("combat.cmd_skill"), "", "", func() -> void: _skills(_skill_cursor.get(_unit.get_instance_id(), 0))),
		_opt(Strings.t("combat.cmd_guard"), "", "", func() -> void: _choose({"kind": "guard"})),
		_opt(Strings.t("combat.cmd_item"), "", "" if not items.is_empty() else Strings.t("combat.no_usable_item"), _items, not items.is_empty()),
	]
	_show_list(false)
	_cmds.show_choices("", opts, func() -> void: root_back.emit(), start)


func _sub(title: String, opts: Array[Dictionary], back: Callable, start: int = 0) -> void:
	_show_list(true)
	_list.show_choices(title, opts, back, start)


## 공격: 적 목록. 약점이 있는 적은 약점 노리기(명중이 낮고 피해가 크다)도 고를 수 있다.
func _attack() -> void:
	var opts: Array[Dictionary] = []
	var start := 0
	for t: Combatant in _battle.opponents(_unit):
		if t == _last_target.get(_unit.get_instance_id()):
			start = opts.size()
		opts.append(_target_opt(t, t.label(), func() -> void: _choose_skill(Battle.BASIC_ATTACK, t)))
		if not t.actor.weak_point().is_empty():
			var aim := func() -> void:
				_remember_target(t)
				_choose({"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": t, "aim_weak": true})
			opts.append(_target_opt(t, Strings.t("combat.target_weak", {"name": t.label()}), aim))
	_sub(Strings.t("combat.menu_target"), opts, func() -> void: _root(ROOT_ATTACK), start)


## 스킬: 보유 스킬(대화·조사 포함) + 맨 끝 도주. 칸 오른쪽 아래에 대가 또는 못 쓰는 이유.
func _skills(start: int = 0) -> void:
	var db := _battle.db
	var opts: Array[Dictionary] = []
	for i in _unit.actor.skills.size():
		var id := _unit.actor.skills[i]
		var sk := db.get_entry("skills", id)
		var why := _battle.can_use(_unit, id)
		var sub := _short_reason(id, why) if not why.is_empty() else _cost_text(sk)
		var desc := SkillBrief.describe(db, sk)
		if not why.is_empty():
			desc = Strings.t(why) + "  " + desc
		var pick := func() -> void:
			_skill_cursor[_unit.get_instance_id()] = i
			_skill_target(id, i)
		opts.append(_opt(JsonUtil.get_str(sk, "name_ko", id), sub, desc, pick, why.is_empty()))
	var flee := roundi(_battle.flee_chance(_unit) * 100.0)
	var flee_i := opts.size()
	var run := func() -> void:
		_skill_cursor[_unit.get_instance_id()] = flee_i
		_choose({"kind": "flee"})
	opts.append(_opt(Strings.t("combat.cmd_flee"), Strings.t("combat.sub_chance", {"chance": flee}),
		"" if flee > 0 else Strings.t("combat.reason_no_flee"), run, flee > 0))
	var back := func() -> void:
		_skill_cursor[_unit.get_instance_id()] = _list.cursor()
		_root(ROOT_SKILL)
	_sub(Strings.t("combat.menu_skill"), opts, back, start)


## 스킬 대상: 적 하나 → 적 목록, 아무나 하나 → 전장의 모두, 아군 하나 → 아군 목록. 그 밖은 바로 쓴다.
func _skill_target(skill_id: String, skill_index: int) -> void:
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
	var opts: Array[Dictionary] = []
	var start := 0
	var veiled := kind == "ally_single" and _unit.actor.statuses.has_flag("no_ally_single")
	for t in list:
		if t == _last_target.get(_unit.get_instance_id()):
			start = opts.size()
		var o := _target_opt(t, t.label(), func() -> void: _choose_skill(skill_id, t))
		if veiled and t != _unit:  # 배신의 장막: 다른 아군을 알아볼 수 없다(자기 자신은 된다)
			o["enabled"] = false
			o["desc"] = Strings.t("combat.reason_veiled")
		opts.append(o)
	_sub(Strings.t("combat.menu_target"), opts, func() -> void: _skills(skill_index), start)


func _items() -> void:
	var opts: Array[Dictionary] = []
	for id in _usable_items():
		opts.append(_opt(DataNames.entry(_battle.db, "items", id), Strings.t("combat.sub_stack", {"n": _unit.actor.inventory.count(id)}),
			"", func() -> void: _choose({"kind": "item", "item": id})))
	_sub(Strings.t("combat.menu_item"), opts, func() -> void: _root(ROOT_ITEM))


func _usable_items() -> Array[String]:
	var out: Array[String] = []
	for id in _unit.actor.inventory.ids():
		if JsonUtil.get_bool(_battle.db.get_entry("items", id), "combat_usable"):
			out.append(id)
	return out


## 대상 칸: 이름 + 생명력 %, 설명줄에 걸린 상태. 적 쪽에서 고를 수 없는 대상(은신)은 꺼 둔다.
func _target_opt(t: Combatant, text: String, cb: Callable) -> Dictionary:
	var names := PackedStringArray()
	for sid in t.actor.statuses.ids():
		names.append(DataNames.entry(_battle.db, "statuses", sid))
	var ok := t.side == _unit.side or BattleRules.is_targetable(_battle, _unit, t)
	var desc := Strings.t("combat.reason_hidden") if not ok else \
		(Strings.t("combat.target_statuses", {"list": ", ".join(names)}) if not names.is_empty() else "")
	var o := _opt(text, Strings.t("combat.sub_hp", {"hp": roundi(t.actor.pool.get_ratio("hp") * 100.0)}), desc, cb, ok)
	o["target"] = t
	return o


func _opt(text: String, sub: String, desc: String, cb: Callable, enabled: bool = true) -> Dictionary:
	return {"text": text, "sub": sub, "desc": desc, "on_pick": cb, "enabled": enabled}


func _cost_text(sk: Dictionary) -> String:
	var cost := PackedStringArray()
	var costs := JsonUtil.get_dict(sk, "cost")
	for r: String in costs:
		cost.append("%s %d" % [_battle.db.resources[r].name_ko, int(costs[r])])
	return ", ".join(cost)


## 못 쓰는 이유를 칸에 붙일 짧은 말로: 재사용 대기(남은 자기 차례 수) · 횟수 소진 · 대가 부족 · 봉인.
func _short_reason(skill_id: String, why: String) -> String:
	match why:
		"combat.reason_cooldown":
			if _unit.cooldowns.has(skill_id):
				return Strings.t("combat.skill_wait", {"n": int(_unit.cooldowns[skill_id])})
			return Strings.t("combat.skill_used_up")
		"combat.reason_cost":
			return Strings.t("combat.skill_no_cost")
		"combat.reason_sealed":
			return Strings.t("combat.skill_sealed")
	return Strings.t("combat.skill_unusable")


func _remember_target(t: Combatant) -> void:
	_last_target[_unit.get_instance_id()] = t


func _choose_skill(skill_id: String, target: Combatant) -> void:
	_remember_target(target)
	_choose({"kind": "skill", "skill": skill_id, "target": target})


func _choose(action: Dictionary) -> void:
	if not _open:
		return
	close()
	chosen.emit(action)
