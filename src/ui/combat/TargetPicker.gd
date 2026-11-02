class_name TargetPicker
extends Node
## 전투 대상 고르기(사용자 2026-11-02 — 아래 창 목록 대신 무대에서, 피어 앤 헝거식, UI52).
## 적은 줄(앞줄·뒷줄 — 무대의 원근 줄)로 나뉜다: A/D = 같은 줄에서 왼쪽·오른쪽, W = 더 뒷줄, S = 더 앞줄(옮긴 줄에서 가로로 가장 가까운 대상).
## 아군이 섞이면(아무나 하나 — 조사) 아군은 앞줄보다 더 앞의 줄(앞줄에서 S). 아군만 고를 때는 W/S·A/D 모두 파티 창 순서로.
## 커서가 놓인 대상은 hovered로 알린다(무대 흰빛·파티 창 테두리 — CommandMenu.target_hovered). 위쪽 작은 창(SkillBanner.hold)에
## 이름만(못 고르면 "이름 · 이유"). Enter = 고름, Backspace = 뒤로(UI43).
## 고를 수 없는 대상(은신·장막 너머 동료)은 넘길 때 빼 둔다. 아이템이 듣지 않는 적은 커서는 가되 Enter가 먹지 않는다.

signal hovered(target: Combatant)

const ALLY_ROW := -1  ## 아군의 줄(적 앞줄 0보다 앞)

var active: bool = false
var _list: Array[Combatant] = []
var _cursor: int = 0
var _ally_only: bool = false
var _why: Callable = Callable()      ## (Combatant) -> 못 고르는 이유 문자열 키("" = 고를 수 있다)
var _on_pick: Callable = Callable()  ## (Combatant)
var _on_back: Callable = Callable()
var _x_of: Callable = Callable()     ## (Combatant) -> 무대 가로 자리
var _row_of: Callable = Callable()   ## (Combatant) -> 적 줄(0 = 앞줄, 클수록 뒤)
var _tag: SkillBanner = null


func set_tag(tag: SkillBanner) -> void:
	_tag = tag


## 무대 자리를 읽는 함수(CommandMenu가 BattleStage로 잇는다). 없으면 모두 한 줄, 넘긴 순서대로.
func set_space(x_of: Callable, row_of: Callable) -> void:
	_x_of = x_of
	_row_of = row_of


## 고르기를 연다. list = 고를 수 있는 대상, start = 처음 커서 대상(없으면 앞줄 가운데에 가까운 적).
func pick(list: Array[Combatant], on_pick: Callable, on_back: Callable, start: Combatant = null, why: Callable = Callable()) -> void:
	_list = list.duplicate()
	_list.sort_custom(func(a: Combatant, b: Combatant) -> bool: return _x(a) < _x(b))
	_on_pick = on_pick
	_on_back = on_back
	_why = why
	_ally_only = not _list.is_empty() and _list.all(func(u: Combatant) -> bool: return u.side == Combatant.SIDE_PARTY)
	if _ally_only:
		_list = list.duplicate()  # 아군은 파티 창 순서
	_cursor = _list.find(start) if start != null and _list.has(start) else _first()
	active = not _list.is_empty()
	_show()


func close() -> void:
	if not active:
		return
	active = false
	_list.clear()
	if _tag != null:
		_tag.release()
	hovered.emit(null)


func current() -> Combatant:
	return _list[_cursor] if active and _cursor >= 0 and _cursor < _list.size() else null


func targets() -> Array[Combatant]:
	return _list


## 같은 줄에서 dir칸(끝에서 반대 끝으로 돈다). 아군만 고를 때는 목록 전체에서.
func move(dir: int) -> void:
	if _list.is_empty():
		return
	if _ally_only:
		_cursor = posmod(_cursor + dir, _list.size())
	else:
		var same := _in_row(_row(current()))
		_cursor = _list.find(same[posmod(same.find(current()) + dir, same.size())])
	_show()


## 줄 옮기기: deeper = true면 더 뒷줄(W), false면 더 앞줄(S). 옮길 줄이 없으면 false.
func change_row(deeper: bool) -> bool:
	var t := current()
	if t == null:
		return false
	var now := _row(t)
	var best_row := 0
	var found := false
	for u in _list:
		var r := _row(u)
		if (r > now if deeper else r < now) and (not found or (r < best_row if deeper else r > best_row)):
			best_row = r
			found = true
	if not found:
		return false
	var x := _x(t)
	var pick_u: Combatant = null
	for u in _in_row(best_row):
		if pick_u == null or absf(_x(u) - x) < absf(_x(pick_u) - x):
			pick_u = u
	_cursor = _list.find(pick_u)
	_show()
	return true


func confirm() -> void:
	var t := current()
	if t == null or not _reason(t).is_empty():
		return
	var cb := _on_pick
	close()
	cb.call(t)


func go_back() -> void:
	var cb := _on_back
	close()
	if cb.is_valid():
		cb.call()


func _row(u: Combatant) -> int:
	if u == null:
		return 0
	if u.side == Combatant.SIDE_PARTY:
		return ALLY_ROW
	return int(_row_of.call(u)) if _row_of.is_valid() else 0


func _x(u: Combatant) -> float:
	return float(_x_of.call(u)) if _x_of.is_valid() else float(u.order)


## 그 줄의 대상(가로 순서).
func _in_row(r: int) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for u in _list:
		if _row(u) == r:
			out.append(u)
	return out


## 처음 커서: 적 앞줄(가장 앞의 적 줄)에서 무대 가운데에 가장 가까운 대상. 아군만이면 첫 사람.
func _first() -> int:
	if _list.is_empty() or _ally_only:
		return 0
	var front := 1 << 30
	for u in _list:
		if u.side != Combatant.SIDE_PARTY:
			front = mini(front, _row(u))
	if front == 1 << 30:
		return 0
	var row := _in_row(front)
	var mid := 0.0
	for u in row:
		mid += _x(u)
	mid /= float(row.size())
	var best: Combatant = row[0]
	for u in row:
		if absf(_x(u) - mid) < absf(_x(best) - mid):
			best = u
	return _list.find(best)


func _reason(t: Combatant) -> String:
	return str(_why.call(t)) if _why.is_valid() else ""


func _show() -> void:
	var t := current()
	if t == null:
		return
	if _tag != null:
		var text := t.label()
		var why := _reason(t)
		if not why.is_empty():
			text = Strings.t("combat.tag_blocked", {"name": text, "why": Strings.t(why)})
		_tag.hold(text, why.is_empty())
	hovered.emit(t)


func _input(event: InputEvent) -> void:
	if not active or not event.is_pressed():
		return
	var act := ""
	for a: String in ["menu_left", "menu_right", "menu_up", "menu_down", "menu_confirm", "menu_back"]:
		if InputMap.has_action(a) and event.is_action_pressed(a, a != "menu_confirm" and a != "menu_back"):
			act = a
			break
	if act.is_empty():
		return
	get_viewport().set_input_as_handled()
	match act:
		"menu_left":
			move(-1)
		"menu_right":
			move(1)
		"menu_up", "menu_down":
			if _ally_only:
				move(-1 if act == "menu_up" else 1)
			else:
				change_row(act == "menu_up")
		"menu_confirm":
			confirm()
		"menu_back":
			go_back()
