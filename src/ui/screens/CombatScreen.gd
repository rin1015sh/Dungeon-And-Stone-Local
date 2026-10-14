class_name CombatScreen
extends Control
## 전투 화면(탐험 화면 위에 겹친다): 가운데 무대(아군과 적이 마주 봄) ·
## 아래 왼쪽 파티 상태 · 가운데 행동창 · 오른쪽 기록. 전투 규칙은 Battle, 이 화면은 차례 진행과 연출만.
## 행동 순서는 Battle/Timeline이 정하고 화면에는 순서 목록을 띄우지 않는다(현재 차례 카드만 강조).

signal finished(result: String, turns: int, killed: Array[String])

var battle: Battle
## 결과가 정해지면 부른다: (result, killed, colors) -> Array[{key, args, kind}] — 보상(공적·전리품·정수)을 주고 그 안내를 돌려준다.
## 결과 칸에 보이고, 탐험 기록에도 남는다(ExploreScreen이 세션에 맡긴다). 없으면 결과만 보인다.
var reward_provider: Callable = Callable()

var _cards: Dictionary = {}  # Combatant -> CombatantCard
var _foe_row: HBoxContainer   # 증원(summon)된 적 카드를 붙일 줄
var _party_row: HBoxContainer
var _looping: bool = false  # 차례 진행 루프가 도는 중(재진입 방지)
var _menu: CommandMenu
var _party_panel: VBoxContainer
var _result_box: VBoxContainer
var _gap: Control
var _finished: bool = false  # 계속을 두 번 눌러도 한 번만 끝낸다


func setup(b: Battle) -> void:
	battle = b


func _ready() -> void:
	var dim := ColorRect.new()
	var bg := UiTheme.color("bg")
	bg.a = UiTheme.ui_float("combat_dim_alpha", 0.9)
	dim.color = bg
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UiTheme.metric("margin", 16)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, m)
	var col := VBoxContainer.new()
	margin.add_child(col)
	col.add_child(_build_stage())
	col.add_child(_build_bottom())
	for h: Dictionary in battle.history:  # 화면이 열리기 전에 나온 안내(전투 시작·수호자 대사·몬스터 타입)
		EventBus.log_message.emit(Strings.t(str(h["key"]), h["args"]), str(h["kind"]))
	battle.message.connect(func(key: String, args: Dictionary, kind: String) -> void:
		EventBus.log_message.emit(Strings.t(key, args), kind))
	battle.event.connect(_on_event)
	_refresh()
	_loop.call_deferred()


func _build_stage() -> Control:
	var stage := HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	stage.add_theme_constant_override("separation", UiTheme.metric("combat_card_sep", 4))  # _fit_cards 계산과 같게
	var party := HBoxContainer.new()
	var foes := HBoxContainer.new()
	_party_row = party
	_foe_row = foes
	for u in battle.units:
		_add_card(u)
	stage.add_child(party)
	_gap = Control.new()
	stage.add_child(_gap)
	stage.add_child(foes)
	_fit_cards()
	return stage


func _add_card(u: Combatant) -> void:
	var card := CombatantCard.new()
	card.setup(u, battle.db)
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	(_party_row if u.side == Combatant.SIDE_PARTY else _foe_row).add_child(card)
	_cards[u] = card


func _build_bottom() -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UiTheme.metric("combat_bottom_height", 230)
	_party_panel = UiTheme.section(row, Strings.t("combat.party"))
	_party_panel.custom_minimum_size.x = UiTheme.metric("hud_panel_width", 360)
	for u in battle.units:
		if u.side == Combatant.SIDE_PARTY:
			var rp := ResourcePanel.new()
			_party_panel.add_child(rp)
			rp.bind(u.actor.pool)
	var mid_panel := PanelContainer.new()  # 행동창 배경(뒤의 탐험 화면이 비치지 않게)
	mid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid_panel)
	var mid := VBoxContainer.new()
	mid_panel.add_child(mid)
	_menu = CommandMenu.new()
	_menu.visible = false
	_menu.chosen.connect(_on_chosen)
	_menu.target_hovered.connect(_on_target_hovered)
	mid.add_child(_menu)
	_result_box = VBoxContainer.new()
	_result_box.visible = false
	mid.add_child(_result_box)
	var log_panel := LogPanel.new()
	log_panel.custom_minimum_size.x = UiTheme.metric("explore_log_width", 380)
	row.add_child(log_panel)
	return row


## 차례를 돌린다. 아군 차례면 행동창을 열고 멈추고(행동 선택 대기), 적 차례면 잠깐 쉬었다가 AI 행동을 적용한다.
## 한 번에 하나만 돈다(_looping). 적의 행동이 잘못됐으면 기본 공격 → 방어 순으로 바꾼다.
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
			_menu.open(battle, c)
			_looping = false
			return
		await get_tree().create_timer(_ai_delay()).timeout
		if not is_inside_tree():
			return
		if not battle.act(c, battle.ai_action(c)):
			if not battle.act(c, {"kind": "skill", "skill": Battle.BASIC_ATTACK, "target": null}):
				battle.act(c, {"kind": "guard"})
		_refresh()
	_looping = false
	_show_result()


## 아군 행동 확정. 잘못된 행동(대상 소멸·코스트 부족 등)이면 차례를 쓰지 않고 행동창을 다시 연다.
func _on_chosen(action: Dictionary) -> void:
	var c := battle.current
	if c == null or battle.phase != Battle.PHASE_AWAIT:
		return
	if not battle.act(c, action):
		_menu.open(battle, c)
		return
	_refresh()
	_loop()


func _on_event(e: Dictionary) -> void:
	var u: Combatant = e.get("unit")
	var card: CombatantCard = _cards.get(u) if u != null else null
	match str(e.get("type")):
		"damage":
			if card != null:
				if not bool(e.get("hit")):
					card.float_text(Strings.t("combat.float_miss"), UiTheme.color("text_dim"))
				elif bool(e.get("immune", false)):
					card.float_text(Strings.t("combat.float_immune"), UiTheme.color("text_dim"))
				elif int(e.get("lost", e.get("amount", 0))) <= 0:
					card.float_text(Strings.t("combat.float_blocked"), UiTheme.color("text_dim"))
				else:
					card.float_text(str(int(e.get("lost", e.get("amount", 0)))) + ("!" if bool(e.get("crit")) else ""), UiTheme.color("bad"))
		"down", "fled":
			if card != null:
				card.refresh()
				if _drops_card(u):
					_remove_card.call_deferred(u)  # 떠오른 숫자를 잠깐 보인 뒤(다음 프레임) 치운다
		"summon":
			if u != null and card == null:
				_add_card(u)
				_fit_cards()
	_refresh()


## 쓰러지거나 물러난 참가자의 카드를 치울지: 적·소환수는 치운다(웨이브·증원으로 카드가 화면 밖으로 밀리지 않게).
## 탐험가 본인과 수호자·계층군주급은 흐린 채 남긴다.
func _drops_card(u: Combatant) -> bool:
	if u.side == Combatant.SIDE_PARTY and not u.summoned:
		return false
	return not (u.actor is Monster and JsonUtil.get_str((u.actor as Monster).def, "rank", "normal") != "normal")


func _remove_card(u: Combatant) -> void:
	var card: CombatantCard = _cards.get(u)
	if card == null:
		return
	_cards.erase(u)
	card.queue_free()
	_fit_cards()


## 카드 폭을 참가자 수에 맞춘다(기본 폭 ~ 최소 폭). 넘치면 가운데 틈부터 줄인다.
## 간격 수 = 카드 수(줄 안 (p−1)+(f−1) + 무대의 두 틈) — 합이 화면 폭을 넘지 않는다.
func _fit_cards() -> void:
	var n := _cards.size()
	if n == 0:
		return
	var sep := UiTheme.metric("combat_card_sep", 4)
	var avail := get_viewport_rect().size.x - UiTheme.metric("margin", 16) * 2.0
	var gap := UiTheme.metric("combat_stage_gap", 160)
	var full := UiTheme.metric("combat_card_width", 150)
	var need := n * (full + sep) + gap
	if need > avail:
		gap = maxi(UiTheme.metric("combat_stage_gap_min", 24), gap - int(need - avail))
	var w := clampi(int((avail - gap) / n) - sep, UiTheme.metric("combat_card_min_width", 88), full)
	_gap.custom_minimum_size.x = gap
	for row: HBoxContainer in [_party_row, _foe_row]:
		row.add_theme_constant_override("separation", sep)
	for c: CombatantCard in _cards.values():
		c.set_width(w)


func _on_target_hovered(t: Combatant) -> void:
	for u: Combatant in _cards:
		(_cards[u] as CombatantCard).set_targeted(u == t)


func _refresh() -> void:
	for u: Combatant in _cards:
		var card: CombatantCard = _cards[u]
		card.refresh()
		card.set_current(u == battle.current)


func _show_result() -> void:
	_menu.close()
	_result_box.visible = true
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
