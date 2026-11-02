class_name CommandMenu
extends HBoxContainer
## 전투 아래 창(피어 앤 헝거식): 왼쪽 = 명령 칸(공격 · 스킬 · 방어 · 아이템, 세로 한 줄 — 행동을 정할 때만 보이고 그 밖에는 숨는다, 자리는 그대로),
## 오른쪽 = 파티 창(PartyRoster — 지금 차례인 사람의 줄이 빛난다, 줄 높이·간격이 명령 칸과 같아 줄이 나란하다). 스킬·아이템을 고를 때는 오른쪽이 목록 칸(ChoiceGrid 2×3)으로 바뀐다.
##   공격 → 대상 · 스킬 → 보유 스킬 + 맨 끝 "도주"(성공 확률) → 필요하면 대상 · 아이템 → 전투용 소지품(하나만 치는 것은 대상)
##   대상은 아래 창 목록이 아니라 무대에서 고른다(TargetPicker — 적 A/D, 약점 W/S, 아군은 파티 창 줄 — 사용자 2026-11-02). 커서가 놓인 대상은 target_hovered.
## 키: 위·아래(W·S) 이동, Enter 확정, Backspace 뒤로(게임에서 Backspace를 쓰는 곳은 여기뿐 — UI43). 스킬 칸 커서와 마지막 대상은 차례가 바뀌어도 기억한다.
## 고르면 chosen(action)을 한 번만 낸다(고른 즉시 닫아 중복 선택을 막는다).

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
var _left: PanelContainer
var _picker: TargetPicker
var _stage: BattleStage = null
var _open: bool = false
var _skill_cursor: Dictionary = {}  # 유닛 instance id -> 스킬 칸 커서
var _last_target: Dictionary = {}   # 유닛 instance id -> 마지막으로 고른 대상(Combatant)


func _init() -> void:
	add_theme_constant_override("separation", UiTheme.metric("spacing", 8))
	var left := _window()
	left.custom_minimum_size.x = UiTheme.metric("combat_cmd_width", 200)
	add_child(left)
	_left = left
	_cmds = ChoiceGrid.new(1, 4, UiTheme.metric("combat_cmd_slot_height", 40), true)
	_cmds.back_action = "menu_back"  # Backspace는 전투 행동창에서만 쓴다(UI43)
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
	_list.back_action = "menu_back"
	_list.cursor_moved.connect(func(_i: int) -> void: target_hovered.emit(null))
	stack.add_child(_list)
	_picker = TargetPicker.new()
	_picker.hovered.connect(func(t: Combatant) -> void: target_hovered.emit(t))
	add_child(_picker)


static func _window() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.see_through(UiTheme.panel_box(UiTheme.metric("padding", 8)), UiTheme.ui_float("combat_window_alpha", 0.72)))  # 전투 아래 창은 반투명(사용자 2026-10-28)
	return p


## 파티 창을 오른쪽 창에 넣는다(목록을 고를 때는 숨는다).
func set_roster(r: Control) -> void:
	_roster = r
	_list.get_parent().add_child(r)
	_list.get_parent().move_child(r, 0)


## 무대(적 순서 — 왼쪽부터)와 위쪽 작은 창(고르는 대상 이름)을 잇는다.
func set_stage(stage: BattleStage, tag: SkillBanner) -> void:
	_stage = stage
	_picker.set_tag(tag)


func open(battle: Battle, unit: Combatant) -> void:
	_battle = battle
	_unit = unit
	_open = true
	_left.modulate.a = 1.0
	_root(ROOT_ATTACK)


func close() -> void:
	_open = false
	_picker.close()
	_show_list(false)
	_cmds.active = false
	_left.modulate.a = 0.0  # 행동을 정할 때만 보인다(사용자 2026-11-02) — 자리는 남겨 파티 창이 움직이지 않게
	target_hovered.emit(null)


func is_open() -> bool:
	return _open


## 지금 키를 받는 칸(명령 칸 또는 목록 칸). 대상을 고르는 중이면 picker().
func grid() -> ChoiceGrid:
	return _list if _list.visible else _cmds


func picker() -> TargetPicker:
	return _picker


func root_grid() -> ChoiceGrid:
	return _cmds


func _show_list(on: bool) -> void:
	_picker.close()
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


## 공격: 무대에서 적을 고른다. 약점이 있는 적은 W/S로 약점 노리기(명중이 낮고 피해가 크다).
func _attack() -> void:
	_pick(_foes(), func(t: Combatant, weak: bool) -> void:
		_choose({"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": t, "aim_weak": weak}),
		func() -> void: _root(ROOT_ATTACK), true)


## 스킬: 보유 스킬(대화·조사 포함) + 맨 끝 도주. 칸 오른쪽 아래에 대가 또는 못 쓰는 이유.
func _skills(start: int = 0) -> void:
	var db := _battle.db
	var opts: Array[Dictionary] = []
	var lead := _battle.is_leader(_unit)  # 대화·조사·도주는 플레이어만(C13) — 동료 목록엔 아예 없다
	for i in _unit.actor.skills.size():
		var id := _unit.actor.skills[i]
		var sk := db.get_entry("skills", id)
		if not lead and JsonUtil.get_bool(sk, "innate"):
			continue
		var at := opts.size()  # 목록 칸 번호(건너뛴 스킬이 있으면 스킬 번호와 다르다)
		var why := _battle.can_use(_unit, id)
		var sub := _short_reason(id, why) if not why.is_empty() else _cost_text(sk)
		var desc := SkillBrief.describe(db, sk)
		if not why.is_empty():
			desc = Strings.t(why) + "  " + desc
		var pick := func() -> void:
			_skill_cursor[_unit.get_instance_id()] = at
			_skill_target(id, at)
		opts.append(_opt(JsonUtil.get_str(sk, "name_ko", id), sub, desc, pick, why.is_empty()))
	var flee := roundi(_battle.flee_chance(_unit) * 100.0)
	var flee_i := opts.size()
	var run := func() -> void:
		_skill_cursor[_unit.get_instance_id()] = flee_i
		_choose({"kind": "flee"})
	if lead:
		opts.append(_opt(Strings.t("combat.cmd_flee"), Strings.t("combat.sub_chance", {"chance": flee}),
			"" if flee > 0 else Strings.t("combat.reason_no_flee"), run, flee > 0))
	var back := func() -> void:
		_skill_cursor[_unit.get_instance_id()] = _list.cursor()
		_root(ROOT_SKILL)
	_sub(Strings.t("combat.menu_skill"), opts, back, start)


## 스킬 대상: 적 하나 → 무대의 적, 아무나 하나 → 적 + 아군, 아군 하나 → 파티 창의 아군. 그 밖은 바로 쓴다.
func _skill_target(skill_id: String, skill_index: int) -> void:
	var kind := JsonUtil.get_str(_battle.db.get_entry("skills", skill_id), "target")
	var list: Array[Combatant] = []
	match kind:
		"enemy_single", "enemy_row":
			list = _foes()
		"any_single":
			list = _foes()
			list.append_array(_battle.side_units(_unit.side))
		"ally_single":
			for u in _battle.side_units(_unit.side):
				if u == _unit or not _unit.actor.statuses.has_flag("no_ally_single"):  # 배신의 장막: 다른 아군을 알아볼 수 없다
					list.append(u)
		_:
			_choose({"kind": "skill", "skill": skill_id})
			return
	_pick(list, func(t: Combatant, _weak: bool) -> void: _choose({"kind": "skill", "skill": skill_id, "target": t}),
		func() -> void: _skills(skill_index))


func _items(start: int = 0) -> void:
	var opts: Array[Dictionary] = []
	var ids := _usable_items()
	for i in ids.size():
		var id := ids[i]
		var idx := i
		opts.append(_opt(DataNames.entry(_battle.db, "items", id), Strings.t("combat.sub_stack", {"n": _unit.actor.inventory.count(id)}),
			"", func() -> void: _item_pick(id, idx)))
	_sub(Strings.t("combat.menu_item"), opts, func() -> void: _root(ROOT_ITEM), start)


## 하나만 치는 아이템(성수 병 등 — RF27)은 무대에서 적 하나를 고른다(듣지 않는 적은 고를 수 없다 — 위쪽 창에 이유). 그 밖은 바로 쓴다.
func _item_pick(id: String, item_index: int) -> void:
	var e := BattleRules.single_smite(_battle.db, id)
	if e.is_empty():
		_choose({"kind": "item", "item": id})
		return
	var why := func(t: Combatant) -> String: return "" if BattleRules.smite_fits(e, t) else "combat.reason_item_no_effect"
	_pick(_foes(), func(t: Combatant, _weak: bool) -> void: _choose({"kind": "item", "item": id, "target": t}),
		func() -> void: _items(item_index), false, why)


## 무대에서 대상을 고른다(명령 칸·목록은 그대로 두고 키만 넘긴다). 마지막으로 고른 대상에 커서.
func _pick(list: Array[Combatant], on_pick: Callable, back: Callable, weak: bool = false, why: Callable = Callable()) -> void:
	_show_list(false)
	_cmds.active = false
	if list.is_empty():
		back.call()
		return
	var remember := func(t: Combatant, aim: bool) -> void:
		_last_target[_unit.get_instance_id()] = t
		on_pick.call(t, aim)
	var last: Variant = _last_target.get(_unit.get_instance_id())
	_picker.pick(list, remember, back, last as Combatant if last is Combatant and list.has(last) else null, weak, why)


## 고를 수 있는 적(은신은 빼고 — 다른 적이 없으면 BattleRules.targetable이 모두 돌려준다), 무대 왼쪽부터.
func _foes() -> Array[Combatant]:
	var out: Array[Combatant] = BattleRules.targetable(_battle, _unit)
	if _stage != null:
		out.sort_custom(func(a: Combatant, b: Combatant) -> bool: return _x(a) < _x(b))
	return out


func _x(u: Combatant) -> float:
	var v := _stage.view(u)
	return v.position.x + v.size.x * 0.5 if v != null else float(u.order) * 10000.0


func _usable_items() -> Array[String]:
	var out: Array[String] = []
	for id in _unit.actor.inventory.ids():
		if JsonUtil.get_bool(_battle.db.get_entry("items", id), "combat_usable"):
			out.append(id)
	return out


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


func _choose(action: Dictionary) -> void:
	if not _open:
		return
	close()
	chosen.emit(action)
