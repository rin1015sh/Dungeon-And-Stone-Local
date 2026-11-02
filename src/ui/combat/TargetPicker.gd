class_name TargetPicker
extends Node
## 전투 대상 고르기(사용자 2026-11-02 — 아래 창 목록 대신 무대에서, 피어 앤 헝거식): 적은 A/D(무대 왼쪽→오른쪽 순),
## 약점이 있는 적을 기본 공격으로 노릴 때는 W/S로 몸 ↔ 약점, 아군만 고를 때는 W/S·A/D 모두 파티 창 순서로.
## 커서가 놓인 대상은 hovered로 알린다(무대 흰빛·파티 창 테두리 — CommandMenu.target_hovered). 위쪽 작은 창(SkillBanner.hold)에
## 이름(약점이면 "이름 [부위]", 못 고르면 "이름 · 이유")만. Enter = 고름, Backspace = 뒤로(UI43).
## 고를 수 없는 대상(은신·장막 너머 동료)은 목록에서 뺀다. 아이템이 듣지 않는 적은 커서는 가되 Enter가 먹지 않는다.

signal hovered(target: Combatant)

var active: bool = false
var _list: Array[Combatant] = []
var _cursor: int = 0
var _weak: bool = false         ## 약점을 노리는 중
var _allow_weak: bool = false   ## 이번 고르기에서 약점 노리기가 되는가(기본 공격)
var _ally_only: bool = false
var _why: Callable = Callable() ## (Combatant) -> 못 고르는 이유 문자열 키("" = 고를 수 있다)
var _on_pick: Callable = Callable()  ## (Combatant, aim_weak: bool)
var _on_back: Callable = Callable()
var _tag: SkillBanner = null


func set_tag(tag: SkillBanner) -> void:
	_tag = tag


## 고르기를 연다. list = 고를 수 있는 대상(순서 그대로 — 적은 무대 x 순으로 넘긴다), start = 처음 커서 대상.
func pick(list: Array[Combatant], on_pick: Callable, on_back: Callable, start: Combatant = null,
		allow_weak: bool = false, why: Callable = Callable()) -> void:
	_list = list
	_on_pick = on_pick
	_on_back = on_back
	_allow_weak = allow_weak
	_why = why
	_weak = false
	_ally_only = not list.is_empty() and list.all(func(u: Combatant) -> bool: return u.side == list[0].side) \
		and list[0].side == Combatant.SIDE_PARTY
	_cursor = maxi(0, list.find(start)) if start != null else 0
	active = not list.is_empty()
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
	return _list[_cursor] if active and _cursor < _list.size() else null


func aiming_weak() -> bool:
	return _weak


func targets() -> Array[Combatant]:
	return _list


## 커서를 dir칸 옮긴다(끝에서 반대 끝으로 돈다).
func move(dir: int) -> void:
	if _list.is_empty():
		return
	_cursor = posmod(_cursor + dir, _list.size())
	_weak = false
	_show()


## 약점 ↔ 몸(약점이 있는 적을 기본 공격으로 노릴 때만).
func toggle_weak() -> bool:
	var t := current()
	if not _allow_weak or t == null or t.side == Combatant.SIDE_PARTY or t.actor.weak_point().is_empty():
		return false
	_weak = not _weak
	_show()
	return true


func confirm() -> void:
	var t := current()
	if t == null or not _reason(t).is_empty():
		return
	var cb := _on_pick
	var weak := _weak
	close()
	cb.call(t, weak)


func go_back() -> void:
	var cb := _on_back
	close()
	if cb.is_valid():
		cb.call()


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
		elif _weak:
			text = Strings.t("combat.tag_part", {"name": text, "part": JsonUtil.get_str(t.actor.weak_point(), "name_ko")})
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
				toggle_weak()
		"menu_confirm":
			confirm()
		"menu_back":
			go_back()
