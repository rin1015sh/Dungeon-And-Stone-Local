class_name CombatScreen
extends Control
## 전투 화면(탐험 화면 위에 겹친다): 가운데 무대(아군과 적이 마주 봄) ·
## 아래 왼쪽 파티 상태 · 가운데 행동창 · 오른쪽 기록. 전투 규칙은 Battle, 이 화면은 차례 진행과 연출만.
## 행동 순서는 Battle/Timeline이 정하고 화면에는 순서 목록을 띄우지 않는다(현재 차례 카드만 강조).

signal finished(result: String, turns: int, killed: Array[String])

var battle: Battle

var _cards: Dictionary = {}  # Combatant -> CombatantCard
var _looping: bool = false  # 차례 진행 루프가 도는 중(재진입 방지)
var _menu: CommandMenu
var _party_panel: VBoxContainer
var _result_box: VBoxContainer


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
	battle.message.connect(func(key: String, args: Dictionary, kind: String) -> void:
		EventBus.log_message.emit(Strings.t(key, args), kind))
	battle.event.connect(_on_event)
	_refresh()
	_loop.call_deferred()


func _build_stage() -> Control:
	var stage := HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.alignment = BoxContainer.ALIGNMENT_CENTER
	var party := HBoxContainer.new()
	var foes := HBoxContainer.new()
	for u in battle.units:
		var card := CombatantCard.new()
		card.setup(u, battle.db)
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		(party if u.side == Combatant.SIDE_PARTY else foes).add_child(card)
		_cards[u] = card
	stage.add_child(party)
	var gap := Control.new()
	gap.custom_minimum_size.x = UiTheme.metric("combat_stage_gap", 160)
	stage.add_child(gap)
	stage.add_child(foes)
	return stage


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
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	_menu = CommandMenu.new()
	_menu.visible = false
	_menu.chosen.connect(_on_chosen)
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
				else:
					card.float_text(str(e.get("amount")) + ("!" if bool(e.get("crit")) else ""), UiTheme.color("bad"))
		"down", "fled":
			if card != null:
				card.refresh()
	_refresh()


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
	var go := UiTheme.button(Strings.t("combat.continue"), func() -> void: finished.emit(battle.result, battle.turns, battle.killed))
	_result_box.add_child(go)
	go.grab_focus.call_deferred()


func _ai_delay() -> float:
	return 0.0 if GameState.debug_fast_combat else UiTheme.ui_float("combat_ai_delay_sec", 0.45)
