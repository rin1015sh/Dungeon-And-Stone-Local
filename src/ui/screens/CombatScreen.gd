class_name CombatScreen
extends Control
## 전투 화면(탐험 화면 위에 겹친다) — 피어 앤 헝거식으로 정면에서 맞닥뜨린다(2026-10-15 사용자 요청):
##   무대(BattleStage) = 어둠 속 빛 웅덩이 위 가운데에 적(정면), 아래 앞줄에 아군(뒷모습)
##   아래 창(CommandMenu) = 왼쪽 명령 칸(공격·스킬·방어·아이템) + 오른쪽 파티 창(PartyRoster: 이름·상태·생명력·영혼력)
##   위 가운데 = 방금 일어난 일 한두 줄(전투 기록은 탐험 기록에도 남는다).
## 아군 행동은 피어 앤 헝거처럼 먼저 전원 정하고(행동 정하기) 차례가 오면 실행한다(_loop).
## 전투 규칙은 Battle, 이 화면은 차례 진행과 연출만. 행동 순서는 Battle/Timeline이 정하고, 지금 차례인 사람의 줄·발밑이 밝다.

signal finished(result: String, turns: int, killed: Array[String])

var battle: Battle
## 결과가 정해지면 부른다: (result, killed, colors) -> Array[{key, args, kind}] — 보상(공적·전리품·정수)을 주고 그 안내를 돌려준다.
## 결과 칸에 보이고, 탐험 기록에도 남는다(ExploreScreen이 세션에 맡긴다). 없으면 결과만 보인다.
var reward_provider: Callable = Callable()

var _stage: BattleStage
var _roster: PartyRoster
var _looping: bool = false  # 차례 진행 루프가 도는 중(재진입 방지)
var _menu: CommandMenu
var _result_panel: PanelContainer
var _result_box: VBoxContainer
var _banner: Label
var _banner_box: PanelContainer
var _banner_timer: Timer
var _banner_lines: PackedStringArray = []
var _finished: bool = false  # 계속을 두 번 눌러도 한 번만 끝낸다
var _plan: Dictionary = {}  # Combatant -> 정해 둔 행동(차례가 오면 한다)
var _planning: Array[Combatant] = []  # 지금 행동을 정하는 사람들(파티 창 순서)
var _plan_i: int = 0
var _just_planned: Combatant = null


func setup(b: Battle) -> void:
	battle = b


func _ready() -> void:
	_stage = BattleStage.new()
	_stage.setup(battle.db)
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.unit_clicked.connect(func(u: Combatant) -> void: _menu.pick_target(u))
	_roster = PartyRoster.new()
	_roster.setup(battle.db)
	_roster.clicked.connect(func(u: Combatant) -> void: _menu.pick_target(u))
	_menu = CommandMenu.new()
	_menu.set_roster(_roster)
	_menu.chosen.connect(_on_chosen)
	_menu.root_back.connect(_on_root_back)
	_menu.target_hovered.connect(_on_target_hovered)
	_place_bottom(_menu)
	_menu.close()
	_result_panel = CommandMenu._window()
	_result_panel.visible = false
	_place_bottom(_result_panel, UiTheme.metric("combat_result_height", 280))
	_result_box = VBoxContainer.new()
	_result_panel.add_child(_result_box)
	_build_banner()
	for u in battle.units:
		_add_unit(u)
	for h: Dictionary in battle.history:  # 화면이 열리기 전에 나온 안내(전투 시작·수호자 대사·몬스터 타입)
		_say(Strings.t(str(h["key"]), h["args"]), str(h["kind"]))
	battle.message.connect(func(key: String, args: Dictionary, kind: String) -> void: _say(Strings.t(key, args), kind))
	battle.event.connect(_on_event)
	_refresh()
	_loop.call_deferred()


## 아래 창 자리: 가운데, 폭 combat_bottom_width(화면이 좁으면 여백만 남기고), 높이 combat_bottom_height.
func _place_bottom(c: Control, height: int = 0) -> void:
	add_child(c)
	var m := UiTheme.metric("margin", 16)
	var w := UiTheme.metric("combat_bottom_width", 1040)
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = -w / 2.0
	c.offset_right = w / 2.0
	c.offset_top = -m - (height if height > 0 else UiTheme.metric("combat_bottom_height", 200))
	c.offset_bottom = -m
	resized.connect(func() -> void:
		var half := minf(w / 2.0, size.x / 2.0 - m)
		c.offset_left = -half
		c.offset_right = half)


func _build_banner() -> void:
	_banner_box = CommandMenu._window()
	_banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_box.visible = false
	add_child(_banner_box)
	_banner_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, UiTheme.metric("margin", 16))
	_banner_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner = UiTheme.label("", "body", "text_title")
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.custom_minimum_size.x = UiTheme.metric("combat_banner_width", 560)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_box.add_child(_banner)
	_banner_timer = Timer.new()
	_banner_timer.one_shot = true
	_banner_timer.timeout.connect(func() -> void:
		_banner_lines.clear()
		_banner_box.visible = false)
	add_child(_banner_timer)


## 전투 안내: 위 가운데에 최근 몇 줄(잠깐 뒤 사라짐) + 탐험 기록.
func _say(text: String, kind: String) -> void:
	EventBus.log_message.emit(text, kind)
	_banner_lines.append(text)
	while _banner_lines.size() > UiTheme.metric("combat_banner_lines", 2):
		_banner_lines.remove_at(0)
	_banner.text = "\n".join(_banner_lines)
	_banner_box.visible = true
	_banner_timer.start(UiTheme.ui_float("combat_banner_sec", 2.6))


func _add_unit(u: Combatant) -> void:
	_stage.add_unit(u)
	_roster.add_unit(u)


## 차례를 돌린다(행동 순서는 CTB 그대로). 아군 차례인데 그 사람의 정해 둔 행동이 없으면 멈추고 "행동 정하기"를 연다 —
## 피어 앤 헝거처럼 그때 행동을 정하지 않은 아군 전원의 행동을 차례로 먼저 고르고(파티 창 순서, 뒤로 = 앞사람 다시),
## 그다음부터 각자 차례가 오면 정해 둔 행동을 한다. 적 차례면 잠깐 쉬었다가 AI 행동.
## 정해 둔 행동이 그때 와서 안 되면(대상이 쓰러짐 등) 다른 적 → 기본 공격 → 방어 순으로 바꾼다.
func _loop() -> void:
	if _looping:
		return
	_looping = true
	while battle.result.is_empty():
		var c := battle.next_turn()
		_refresh()
		if c == null:
			break
		if battle.is_player_controlled(c):
			if not _plan.has(c):
				_begin_planning(c)
				_looping = false
				return
			if c != _just_planned:  # 방금 정한 사람은 바로 움직인다(정하고 또 기다리지 않게)
				await get_tree().create_timer(_ai_delay()).timeout
				if not is_inside_tree():
					return
			_just_planned = null
			var action: Dictionary = _plan[c]
			_plan.erase(c)
			_roster.set_plan(c, "")
			if not battle.act(c, action):
				_fallback(c, action)
			_refresh()
			if not await _turn_gap():
				return
			continue
		await get_tree().create_timer(_ai_delay()).timeout
		if not is_inside_tree():
			return
		if not battle.act(c, battle.ai_action(c)):
			if not battle.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null}):
				battle.act(c, {"kind": "guard"})
		_refresh()
		if not await _turn_gap():
			return
	_looping = false
	_show_result()


## 정해 둔 행동이 안 될 때: 같은 스킬을 다른 적에게 → 기본 공격 → 방어.
func _fallback(c: Combatant, action: Dictionary) -> void:
	if str(action.get("kind")) == "skill":
		var t: Variant = action.get("target")
		if t is Combatant and not (t as Combatant).is_active() and (t as Combatant).side != c.side:
			for o: Combatant in battle.opponents(c):
				var again := action.duplicate()
				again["target"] = o
				if battle.act(c, again):
					return
	if not battle.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null}):
		battle.act(c, {"kind": "guard"})


## 행동 정하기: 아직 정하지 않은 아군(직접 조종하는 사람만) 모두 — first(지금 차례인 사람)는 꼭 들어간다.
func _begin_planning(first: Combatant) -> void:
	_planning.clear()
	for u in battle.side_units(Combatant.SIDE_PARTY):
		if battle.is_player_controlled(u) and u.is_active() and not _plan.has(u):
			_planning.append(u)
	if not _planning.has(first):
		_planning.push_front(first)
	_plan_i = 0
	_open_plan()


func _open_plan() -> void:
	var u: Combatant = _planning[_plan_i]
	_roster.set_current(u)
	for v: Combatant in _stage.views():
		(_stage.views()[v] as BattlerView).set_current(v == u)
	_menu.open(battle, u)


## 한 사람의 행동을 정했다: 그 자리에서 쓸 수 없는 행동(대가 부족 등)이면 이유를 보이고 다시 고른다.
func _on_chosen(action: Dictionary) -> void:
	if _planning.is_empty():
		return
	var u: Combatant = _planning[_plan_i]
	var why := ActionCheck.reason(battle, u, action)
	if not why.is_empty():
		_say(Strings.t(why, {"name": u.label()}), "warn")
		_menu.open(battle, u)
		return
	_plan[u] = action
	_roster.set_plan(u, _plan_text(action))
	_plan_i += 1
	if _plan_i < _planning.size():
		_open_plan()
		return
	_planning.clear()
	_just_planned = battle.current
	_loop()


## 명령 칸에서 뒤로(Enter): 앞사람의 행동을 다시 고른다.
func _on_root_back() -> void:
	if _planning.is_empty() or _plan_i == 0:
		return
	_plan_i -= 1
	_plan.erase(_planning[_plan_i])
	_roster.set_plan(_planning[_plan_i], "")
	_open_plan()


## 파티 창에 보일 정해 둔 행동(짧게): "공격 → 고블린 A" · "방어" · "포션".
func _plan_text(action: Dictionary) -> String:
	var t: Variant = action.get("target")
	var what := ""
	match str(action.get("kind")):
		"skill":
			var id := str(action.get("skill", Battle.BASIC_ATTACK))
			what = Strings.t("combat.cmd_attack") if id == Battle.BASIC_ATTACK else DataNames.entry(battle.db, "skills", id)
		"guard":
			what = Strings.t("combat.cmd_guard")
		"item":
			what = DataNames.entry(battle.db, "items", str(action.get("item")))
		"flee":
			what = Strings.t("combat.cmd_flee")
	return Strings.t("combat.plan_target", {"act": what, "target": (t as Combatant).label()}) if t is Combatant else what


func _on_event(e: Dictionary) -> void:
	var u: Combatant = e.get("unit")
	var v: BattlerView = _stage.view(u) if u != null else null
	match str(e.get("type")):
		"damage":
			if v != null:
				if not bool(e.get("hit")):
					v.float_text(Strings.t("combat.float_miss"), UiTheme.color("text_dim"))
				elif bool(e.get("immune", false)):
					v.float_text(Strings.t("combat.float_immune"), UiTheme.color("text_dim"))
				elif int(e.get("lost", e.get("amount", 0))) <= 0:
					v.float_text(Strings.t("combat.float_blocked"), UiTheme.color("text_dim"))
				else:
					var foe := u.side != Combatant.SIDE_PARTY  # 적이 입은 피해 = 밝은 금빛, 아군이 입은 피해 = 붉게
					v.float_text(str(int(e.get("lost", e.get("amount", 0)))) + ("!" if bool(e.get("crit")) else ""), UiTheme.color("dmg_foe" if foe else "dmg_party"), true)
		"down", "fled":
			if v != null:
				v.refresh()
				if _drops_view(u):
					_remove_unit.call_deferred(u)  # 떠오른 숫자를 잠깐 보인 뒤(다음 프레임) 치운다
		"summon":
			if u != null and v == null:
				_add_unit(u)
	_refresh()


## 쓰러지거나 물러난 참가자를 무대에서 치울지: 적·소환수는 치운다(웨이브·증원으로 무대가 넘치지 않게).
## 탐험가 본인과 수호자·계층군주급은 흐린 채 남긴다.
func _drops_view(u: Combatant) -> bool:
	if u.side == Combatant.SIDE_PARTY and not u.summoned:
		return false
	return not (u.actor is Monster and JsonUtil.get_str((u.actor as Monster).def, "rank", "normal") != "normal")


func _remove_unit(u: Combatant) -> void:
	_stage.remove_unit(u)
	_roster.remove_unit(u)


func _on_target_hovered(t: Combatant) -> void:
	for u: Combatant in _stage.views():
		(_stage.views()[u] as BattlerView).set_targeted(u == t)
	_roster.set_target(t)


func _refresh() -> void:
	var now: Combatant = _planning[_plan_i] if not _planning.is_empty() else battle.current
	for u: Combatant in _stage.views():
		var v: BattlerView = _stage.views()[u]
		v.refresh()
		v.set_current(u == now)
	_roster.set_current(now)
	_roster.refresh()


func _show_result() -> void:
	_menu.close()
	_menu.visible = false
	_result_panel.visible = true
	for c in _result_box.get_children():
		c.queue_free()
	var key := "combat.result_" + (battle.result if not battle.result.is_empty() else Battle.RESULT_FLED)
	_result_box.add_child(UiTheme.label(Strings.t(key), "header", "good" if battle.result == Battle.RESULT_VICTORY else "bad"))
	var rewards: Array = reward_provider.call(battle.result, battle.killed, battle.killed_colors) if reward_provider.is_valid() else []
	if not rewards.is_empty():  # 이번 전투로 얻은 것(공적·레벨·전리품·정수) — 웨이브가 이어져도 여기서 한 번 본다
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = UiTheme.metric("combat_reward_height", 150)
		_result_box.add_child(scroll)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(list)
		for m: Dictionary in rewards:
			var l := UiTheme.label(Strings.t(str(m["key"]), m["args"]), "small", "log_" + str(m["kind"]))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			list.add_child(l)
	var go := UiTheme.button(Strings.t("combat.continue"), _finish)
	_result_box.add_child(go)
	go.grab_focus.call_deferred()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit(battle.result, battle.turns, battle.killed)


func _ai_delay() -> float:
	return 0.0 if GameState.debug_fast_combat else UiTheme.ui_float("combat_ai_delay_sec", 0.45)


## 차례가 넘어가기 전 쉼(피해 숫자·안내를 볼 틈). 화면이 사라졌으면 false.
func _turn_gap() -> bool:
	var sec := 0.0 if GameState.debug_fast_combat or not battle.result.is_empty() else UiTheme.ui_float("combat_turn_gap_sec", 0.7)
	if sec > 0.0:
		await get_tree().create_timer(sec).timeout
	return is_inside_tree()
