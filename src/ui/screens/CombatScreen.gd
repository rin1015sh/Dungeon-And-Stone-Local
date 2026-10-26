class_name CombatScreen
extends Control
## 전투 화면(탐험 화면 위에 겹친다) — 피어 앤 헝거식으로 정면에서 맞닥뜨린다(2026-10-15 사용자 요청):
##   무대(BattleStage) = 어둠 속 빛 웅덩이 위 가운데에 적(정면), 아래 앞줄에 아군(뒷모습)
##   아래 창(CommandMenu) = 왼쪽 명령 칸(공격·스킬·방어·아이템) + 오른쪽 파티 창(PartyRoster: 이름·상태·생명력·영혼력)
##   안내(방금 일어난 일·결과·보상) = 대화창(DialogueBox) — 아래 창 전체를 덮고(2026-10-20) 한 쪽씩 Enter로 넘긴다(사용자 결정 2026-10-18).
##   대화창이 떠 있는 동안은 차례가 멈추고 아래 창은 숨어 조작되지 않는다(다 넘기면 다음 차례). 결과·보상도 대화창으로 보이고, 다 넘기면 탐험으로 돌아간다.
## 아군 행동은 피어 앤 헝거처럼 먼저 전원 정하고(행동 정하기) 차례가 오면 실행한다(_loop).
## 전투 규칙은 Battle, 이 화면은 차례 진행과 연출만. 행동 순서는 Battle/Timeline이 정하고, 지금 차례인 사람의 줄·발밑이 밝다.

signal finished(result: String, turns: int, killed: Array[String])

var battle: Battle
## 결과가 정해지면 부른다: (result, killed, colors) -> Array[{key, args, kind}] — 보상(공적·전리품·정수)을 주고 그 안내를 돌려준다.
## 결과 칸에 보이고, 탐험 기록에도 남는다(ExploreScreen이 세션에 맡긴다). 없으면 결과만 보인다.
var reward_provider: Callable = Callable()
## 전투 장면에서 줍는 드롭(DropPickup — reward_provider가 채운다). 비어 있으면 바로 결과 칸.
## drop_taker(drop, pc) -> 안내 · drop_leaver(drop, 못 받은 이유 키) -> 안내 — 둘 다 있어야 묻는다(CombatDrops).
var drops: Array[Dictionary] = []
var drop_taker: Callable = Callable()
var drop_leaver: Callable = Callable()
## 전투 뒷그림 경로와 통로 반 폭 m(층·균열 그림 설정 battleback — ExploreScreen이 채운다). 경로가 비면 어둠.
var backdrop: String = ""
var backdrop_width: float = 0.0

var _stage: BattleStage
var _roster: PartyRoster
var _looping: bool = false  # 차례 진행 루프가 도는 중(재진입 방지)
var _menu: CommandMenu
var _route: NoticeRoute
var _dialog: DialogueBox
var _banner: SkillBanner
var _finished: bool = false  # 계속을 두 번 눌러도 한 번만 끝낸다
var _plan: Dictionary = {}  # Combatant -> 정해 둔 행동(차례가 오면 한다)
var _planning: Array[Combatant] = []  # 지금 행동을 정하는 사람들(파티 창 순서)
var _plan_i: int = 0
var _just_planned: Combatant = null
var _spots: Array[Vector2] = []  # 쓰러뜨린 순서(battle.killed)대로 그 몬스터가 섰던 무대 자리 — 드롭이 놓인다


func setup(b: Battle) -> void:
	battle = b


func _ready() -> void:
	_stage = BattleStage.new()
	_stage.setup(battle.db, BattleKnowledge.knowers(battle))
	_stage.set_backdrop(backdrop, backdrop_width)
	add_child(_stage)
	_stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_roster = PartyRoster.new()
	_roster.setup(battle.db)
	_menu = CommandMenu.new()
	_menu.set_roster(_roster)
	_menu.chosen.connect(_on_chosen)
	_menu.root_back.connect(_on_root_back)
	_menu.target_hovered.connect(_on_target_hovered)
	_place_bottom(_menu)
	_menu.close()
	_dialog = DialogueBox.new()
	_dialog.instant = GameState.debug_fast_combat
	_place_bottom(_dialog)  # 아래 창과 같은 자리에 겹쳐 전부 덮는다
	_dialog.shown_changed.connect(_on_dialog_shown)
	_banner = SkillBanner.new()
	add_child(_banner)
	_banner.place_top()
	for u in battle.units:
		_add_unit(u)
	_route = NoticeRoute.new(battle.db)
	for h: Dictionary in battle.history:  # 화면이 열리기 전에 나온 안내(전투 시작·수호자 대사·몬스터 타입)
		_notify(str(h["key"]), h["args"], str(h["kind"]))
	battle.message.connect(_notify)
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


## 대화창이 뜨면 아래 창(명령·목록·파티 창)을 숨긴다 — 덮인 창이 키를 받지 않게.
func _on_dialog_shown(on: bool) -> void:
	_menu.visible = not on


## 전투 안내(문구 키): 기록에는 늘, 대화창에는 화면으로 알 수 없는 것만(피해·회피·쓰러짐·상태는 떠오르는 숫자·무대로 보인다 — NoticeRoute).
func _notify(key: String, args: Dictionary, kind: String) -> void:
	var text := Strings.t(key, args)
	match _route.of(key):
		NoticeRoute.SILENT:
			EventBus.log_message.emit(text, kind)
		NoticeRoute.BANNER:  # 스킬·아이템 이름 = 위쪽 작은 알림창(넘기지 않는다)
			EventBus.log_message.emit(text, kind)
			_banner.show_text(Strings.t(_route.banner_key(key), args))
		_:
			_say(text, kind)


## 전투 안내: 아래 대화창 + 탐험 기록.
func _say(text: String, kind: String) -> void:
	EventBus.log_message.emit(text, kind)
	_dialog.say(text, kind)


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
		if not await _read():  # 차례 시작에 나온 안내(상태 피해·풀림)를 다 넘긴 뒤
			return
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


## 행동 정하기: 지금 차례인 사람부터, 아직 정하지 않은 아군(직접 조종하는 사람만) 모두 — 추가 차례면 그 사람 혼자(PlanOrder).
func _begin_planning(first: Combatant) -> void:
	_planning = PlanOrder.who(battle, first, _plan)
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
		_menu.close()
		_say(Strings.t(why, {"name": u.label()}), "warn")
		if not await _read():
			return
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
				if not bool(e.get("hit")):  # 회피·면역·막힘도 피해 숫자처럼 크게(색만 다르게)
					v.float_text(Strings.t("combat.float_miss"), UiTheme.color("dmg_none"), true)
				elif bool(e.get("immune", false)):
					v.float_text(Strings.t("combat.float_immune"), UiTheme.color("dmg_none"), true)
				elif int(e.get("lost", e.get("amount", 0))) <= 0:
					v.float_text(Strings.t("combat.float_blocked"), UiTheme.color("dmg_none"), true)
				else:
					var foe := u.side != Combatant.SIDE_PARTY  # 적이 입은 피해 = 밝은 금빛, 아군이 입은 피해 = 붉게
					v.float_text(str(int(e.get("lost", e.get("amount", 0)))) + ("!" if bool(e.get("crit")) else ""), UiTheme.color("dmg_foe" if foe else "dmg_party"), true)
		"down", "fled":
			if str(e.get("type")) == "down" and u != null and u.side == Combatant.SIDE_ENEMY and u.actor is Monster:
				_spots.append(v.position + Vector2(v.size.x * 0.5, v.size.y) if v != null else _stage.size * Vector2(0.5, 0.6))
			if v != null:
				v.refresh()
				if _drops_view(u):
					_remove_unit.call_deferred(u)  # 떠오른 숫자를 잠깐 보인 뒤(다음 프레임) 치운다
		"summon":
			if u != null and v == null:
				_add_unit(u)
	_refresh()


## 쓰러지거나 물러난 참가자를 무대에서 치울지: 적(수호자·계층군주 포함 — 빛 먼지로 흩어진다)·소환수는 치운다. 탐험가 본인만 흐린 채 남긴다.
func _drops_view(u: Combatant) -> bool:
	return not (u.side == Combatant.SIDE_PARTY and not u.summoned)


func _remove_unit(u: Combatant) -> void:
	_stage.remove_unit(u)
	_roster.remove_unit(u)


func _on_target_hovered(t: Combatant) -> void:
	for u: Combatant in _stage.views():
		(_stage.views()[u] as BattlerView).set_targeted(u == t)
	_roster.set_target(t)


func _refresh() -> void:
	if _planning.any(func(u: Combatant) -> bool: return not u.is_active()):
		_drop_fallen()
	var now: Combatant = _planning[_plan_i] if not _planning.is_empty() else battle.current
	for u: Combatant in _stage.views():
		var v: BattlerView = _stage.views()[u]
		v.refresh()
		v.set_current(u == now)
	_roster.set_current(now)
	_roster.refresh()


## 행동을 정하던 중에 누가 쓰러졌다(밖에서 생명력이 0이 됨): 그 사람을 목록에서 빼고,
## 지금 차례인 사람이 쓰러졌거나 정할 사람이 없으면 행동창을 닫고 차례를 다시 돌린다(Battle.next_turn이 넘긴다).
func _drop_fallen() -> void:
	var was: Combatant = _planning[_plan_i] if _plan_i < _planning.size() else null
	for u: Combatant in _planning.duplicate():
		if not u.is_active():
			_planning.erase(u)
			_plan.erase(u)
			_roster.set_plan(u, "")
	if _planning.is_empty() or battle.current == null or not battle.current.is_active():
		_planning.clear()
		_menu.close()
		_loop.call_deferred()
		return
	_plan_i = clampi(_planning.find(was) if _planning.has(was) else _plan_i, 0, _planning.size() - 1)
	_open_plan()


## 결과 → (쓰러진 자리의 드롭 묻기) → 얻은 것(공적·레벨·전리품·정수)을 대화창으로 한 쪽씩 → 다 넘기면 탐험으로.
## 보상 안내는 세션이 탐험 기록에도 남기므로 여기서는 대화창에만 보인다.
func _show_result() -> void:
	_menu.close()
	if not await _read():
		return
	var key := "combat.result_" + (battle.result if not battle.result.is_empty() else Battle.RESULT_FLED)
	_dialog.say(Strings.t(key), {Battle.RESULT_VICTORY: "good", Battle.RESULT_DEFEAT: "danger"}.get(battle.result, "warn"))
	if not await _read():
		return
	var rewards: Array = reward_provider.call(battle.result, battle.killed, battle.killed_colors) if reward_provider.is_valid() else []
	if not drops.is_empty() and drop_taker.is_valid() and drop_leaver.is_valid():  # 쓰러진 자리의 정수·전리품을 하나씩 묻는다
		var takers: Array[PlayerCharacter] = []
		for u in battle.side_units(Combatant.SIDE_PARTY):
			if u.actor is PlayerCharacter and not u.summoned and not u.actor.dead:
				takers.append(u.actor as PlayerCharacter)
		if not takers.is_empty():
			rewards.append_array(await CombatDrops.collect(self, _stage, battle.db, drops, _spots, takers, drop_taker, drop_leaver))
		drops.clear()
		if not is_inside_tree():
			return
	for m: Dictionary in rewards:
		_dialog.say(Strings.t(str(m["key"]), m["args"]), str(m["kind"]))
	if not await _read():
		return
	_finish()


## 아래 대화창(테스트·캡처용).
func dialog() -> DialogueBox:
	return _dialog


func banner() -> SkillBanner:
	return _banner


func stage() -> BattleStage:
	return _stage


func _finish() -> void:
	if _finished:
		return
	_finished = true
	finished.emit(battle.result, battle.turns, battle.killed)


func _ai_delay() -> float:
	return 0.0 if GameState.debug_fast_combat else UiTheme.ui_float("combat_ai_delay_sec", 0.45)


## 대화창에 남은 안내를 다 넘길 때까지 기다린다. 화면이 사라졌으면 false.
func _read() -> bool:
	if _dialog.busy():
		await _dialog.wait()
	return is_inside_tree()


## 차례가 넘어가기 전 쉼: 안내가 떠 있으면 다 넘길 때까지, 없으면 잠깐(피해 숫자를 볼 틈). 화면이 사라졌으면 false.
func _turn_gap() -> bool:
	if _dialog.busy():
		return await _read()
	var sec := 0.0 if GameState.debug_fast_combat or not battle.result.is_empty() else UiTheme.ui_float("combat_turn_gap_sec", 0.7)
	if sec > 0.0:
		await get_tree().create_timer(sec).timeout
	return is_inside_tree()
