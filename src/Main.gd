extends Control
## 진입점(Main.tscn). 테마·입력 설정을 입히고 화면 흐름을 맡는다(화면은 시그널만 낸다).
##   타이틀 → 새 탐험가 → 미궁(탐험) → 결과(강제 귀환/사망) → 타이틀
##   타이틀 → 기반 점검(개발용)

var _screen: Control = null


func _ready() -> void:
	theme = UiTheme.build(DataRegistry.db.render)
	UiTheme.apply_global_font()
	RenderingServer.set_default_clear_color(UiTheme.color("bg"))
	for problem: String in InputSetup.apply(DataRegistry.db.singletons.get("input", {})):
		push_warning("입력 설정: 알 수 없는 키 " + problem)
	var bg := ColorRect.new()
	bg.color = UiTheme.color("bg")
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if DataRegistry.has_errors():
		var err := DataErrorScreen.new()
		err.quit_requested.connect(_quit)
		_show(err)
	else:
		_show_title()


func current_screen() -> Control:
	return _screen


func _show(screen: Control) -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = screen
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_title() -> void:
	GameState.end_run()
	var t := TitleScreen.new()
	t.new_game_requested.connect(_show_create)
	t.foundation_requested.connect(_show_foundation)
	t.quit_requested.connect(_quit)
	_show(t)


func _show_create() -> void:
	var c := CharacterCreateScreen.new()
	c.confirmed.connect(_start_run)
	c.back_requested.connect(_show_title)
	_show(c)


func _show_foundation() -> void:
	var f := FoundationScreen.new()
	f.back_requested.connect(_show_title)
	_show(f)


func _start_run(pc: PlayerCharacter) -> void:
	GameState.start_run(pc)
	LogPanel.clear_history()
	_enter_floor(str(DataRegistry.db.bal("explore.start_floor", "")))


## 층을 새로 만들어 들어간다. seed_override가 0이면 세션 시드로 정한다.
func _enter_floor(floor_id: String, seed_override: int = 0) -> void:
	var db := DataRegistry.db
	var def := db.get_entry("floors", floor_id)
	var gen := DataRegistry.registries.generator(JsonUtil.get_str(def, "generator"))
	if def.is_empty() or gen == null:
		push_error("층 '%s'을(를) 만들 수 없다" % floor_id)
		_show_title()
		return
	var seed_value := seed_override if seed_override != 0 else GameState.next_floor_seed(JsonUtil.get_int(def, "floor", 1))
	var map := gen.generate(db, def, Rng.new(seed_value))
	var session := ExploreSession.new(db, def, map, GameState.player, TimeSystem.new_expedition(),
		Rng.new(seed_value + 1), DataRegistry.registries.effects)
	session.rifts.calendar = GameState.rift_calendar
	_show_session(session, floor_id)


## 탐험 화면을 세션에 붙여 띄운다. 균열 챕터 ↔ 바깥 층으로 넘어갈 때도 여기로 온다(세션은 그대로 이어진다).
func _show_session(session: ExploreSession, floor_id: String) -> void:
	var screen := ExploreScreen.new()
	screen.setup(session)
	screen.run_ended.connect(_on_run_ended)
	screen.regenerate_requested.connect(func(s: int) -> void: _enter_floor(floor_id, s))
	screen.session_switch.connect(func(t: ExploreSession) -> void: _show_session(t, floor_id))
	_show(screen)


func _on_run_ended(kind: String, info: Dictionary) -> void:
	var end := EndScreen.new()
	end.setup(kind, info)
	end.done.connect(_show_title)
	_show(end)


func _quit() -> void:
	get_tree().quit()
