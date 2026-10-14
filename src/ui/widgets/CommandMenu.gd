class_name CommandMenu
extends VBoxContainer
## 전투 행동창. 모든 단계가 같은 고정 칸 선택판(ChoiceGrid — 한 쪽 6칸, 넘치면 쪽 넘김)을 쓴다.
##   맨 위: 공격 · 스킬 · 방어 · 아이템 · 도주
##   공격 → 대상(약점이 있는 적은 "약점 노리기"가 함께 나온다)
##   스킬 → 보유 스킬(대화·조사 포함, 칸 오른쪽 아래에 대가 또는 못 쓰는 이유) → 필요하면 대상
##   아이템 → 전투용 소지품
## 뒤로(menu_back)는 한 단계 위로, 돌아가면 커서는 들어갔던 칸에 있다. 스킬 칸 커서와 마지막 대상은 차례가 바뀌어도 기억한다.
## 고르면 chosen(action)을 한 번만 낸다(고른 즉시 메뉴를 닫아 중복 선택을 막는다).

signal chosen(action: Dictionary)

const ROOT_ATTACK := 0
const ROOT_SKILL := 1
const ROOT_GUARD := 2
const ROOT_ITEM := 3
const ROOT_FLEE := 4

var _battle: Battle
var _unit: Combatant
var _grid: ChoiceGrid
var _skill_cursor: Dictionary = {}  # 유닛 instance id -> 스킬 칸 커서
var _last_target: Dictionary = {}   # 유닛 instance id -> 마지막으로 고른 대상(Combatant)


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_grid = ChoiceGrid.new()
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_grid)


func open(battle: Battle, unit: Combatant) -> void:
	_battle = battle
	_unit = unit
	visible = true
	_root(ROOT_ATTACK)


func close() -> void:
	visible = false
	_grid.clear()


func grid() -> ChoiceGrid:
	return _grid


func _root(start: int) -> void:
	var items := _usable_items()
	var flee := roundi(_battle.flee_chance(_unit) * 100.0)
	var opts: Array[Dictionary] = [
		_opt(Strings.t("combat.cmd_attack"), "", Strings.t("combat.desc_attack"), _attack),
		_opt(Strings.t("combat.cmd_skill"), Strings.t("combat.sub_count", {"n": _unit.actor.skills.size()}),
			Strings.t("combat.desc_skill"), func() -> void: _skills(_skill_cursor.get(_unit.get_instance_id(), 0))),
		_opt(Strings.t("combat.cmd_guard"), "", Strings.t("combat.desc_guard"), func() -> void: _choose({"kind": "guard"})),
		_opt(Strings.t("combat.cmd_item"), Strings.t("combat.sub_count", {"n": items.size()}),
			Strings.t("combat.desc_item") if not items.is_empty() else Strings.t("combat.no_usable_item"), _items, not items.is_empty()),
		_opt(Strings.t("combat.cmd_flee"), Strings.t("combat.sub_chance", {"chance": flee}),
			Strings.t("combat.desc_flee") if flee > 0 else Strings.t("combat.reason_no_flee"),
			func() -> void: _choose({"kind": "flee"}), flee > 0),
	]
	_grid.show_choices(Strings.t("combat.menu_root", {"name": _unit.label()}), opts, Callable(), start)


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
			var weak := _target_opt(t, Strings.t("combat.target_weak", {"name": t.label()}), aim)
			weak["desc"] = Strings.t("combat.desc_weak")
			opts.append(weak)
	_grid.show_choices(Strings.t("combat.menu_target"), opts, func() -> void: _root(ROOT_ATTACK), start)


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
	var back := func() -> void:
		_skill_cursor[_unit.get_instance_id()] = _grid.cursor()
		_root(ROOT_SKILL)
	_grid.show_choices(Strings.t("combat.menu_skill"), opts, back, start)


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
	for t in list:
		if t == _last_target.get(_unit.get_instance_id()):
			start = opts.size()
		opts.append(_target_opt(t, t.label(), func() -> void: _choose_skill(skill_id, t)))
	_grid.show_choices(Strings.t("combat.menu_target"), opts, func() -> void: _skills(skill_index), start)


func _items() -> void:
	var opts: Array[Dictionary] = []
	for id in _usable_items():
		opts.append(_opt(DataNames.entry(_battle.db, "items", id), Strings.t("combat.sub_stack", {"n": _unit.actor.inventory.count(id)}),
			JsonUtil.get_str(_battle.db.get_entry("items", id), "desc_ko"), func() -> void: _choose({"kind": "item", "item": id})))
	_grid.show_choices(Strings.t("combat.menu_item"), opts, func() -> void: _root(ROOT_ITEM))


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
	return _opt(text, Strings.t("combat.sub_hp", {"hp": roundi(t.actor.pool.get_ratio("hp") * 100.0)}), desc, cb, ok)


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
	if not visible:
		return
	close()
	chosen.emit(action)
