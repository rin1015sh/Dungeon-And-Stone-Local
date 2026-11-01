class_name RoomView
extends FacilityView
## 시설 실내 방(탑뷰 — CityRoom, 사용자 결정 2026-10-31 "도서관 내부를 탐험 화면처럼 WASD로", CT62).
##   탐험처럼 W/A/S/D로 걷고(4방향, 가장 나중에 누른 키), 살필 자리를 바라보고 Enter = 그 자리 활동(결과는 대화창 — 서적·요리는 그림이 덮었다가
##   다 넘기면 걷힌다). 자리에 칸이 여럿이면(여관 주인 — 요기·식사, 상점 계산대 — 구매·판매) 작은 선택 창, 창구(상점·대장간·은행·정수 제거)는
##   오른쪽 아래 카드로 열고(Esc·나가기 = 창구만 닫기).
##   문 칸을 밟거나 Esc = 나가기 — 행동력은 들어갈 때 1(CityState.enter_facility, CT72). 안에서는 활동을 몇 번이든(도서관 서적은 분야마다 한 번).
##   이름판은 띄우지 않는다(사용자 2026-11-01) — 살필 수 있는 가구·벽 장식·사람은 검은 테두리(RoomWorld, CT77). 못 하면 Enter 때 짧은 이유.
## 지도는 한 장에 층이 다 있다(위층 북쪽·지하 남쪽, 계단·사다리 줄로 이어짐 — CT66). 그리기는 RoomWorld(바닥 그림 + 발 높이로 정렬한 벽 줄·가구·사람·플레이어).
## 방이 화면보다 작으면 고정(왼쪽 위 달력 카드를 비켜 오른쪽 빈 곳 가운데), 크면 플레이어를 따라간다(render.json city.room.zoom).

signal art_hidden  ## 결과 그림이 걷혔다 — 도시 화면이 귀퉁이 카드를 다시 보인다

const MOVE_DIRS := {"move_up": Vector2.UP, "move_down": Vector2.DOWN, "move_left": Vector2.LEFT, "move_right": Vector2.RIGHT}

## 몸 중심(칸 좌표) · 보는 방향 — 테스트·캡처가 옮긴다.
var pos: Vector2 = Vector2.ZERO
var facing: Vector2i = Vector2i(0, -1)

var _room: CityRoom
var _vp: SubViewport
var _cam: Camera2D
var _player: ActorView
var _tile: float = 32.0
var _held: Array[String] = []
var _acting: bool = false  # 활동 결과를 넘기는 중 · 선택 창
## Tab 메뉴·도감이 열려 있는 동안 걷기·살피기를 멈춘다(CityScreen이 켠다 — CT74).
var paused: bool = false
var _focus: Dictionary = {}
var _world: RoomWorld
var _talked: Dictionary = {}  # 사람 칸 → 다음에 할 줄(이 방문 안에서만)


func _ready() -> void:
	var f := _state.db.get_entry("facilities", _facility_id)
	_room = CityRoom.load_for(_state, _facility_id)
	var view := JsonUtil.get_dict(_state.db.render, "view")
	var ft := JsonUtil.get_array(view, "floor_tile_px")
	_tile = float(ft[0]) if ft.size() == 2 else _tile
	pos = _room.start
	_build_world(view)
	_dialog = DialogueBox.new()  # 전투와 같은 대화창(UI36) — 줄이 없으면 숨는다(방에는 정보 줄이 없다)
	DialogueBox.place_bottom(_dialog, self)
	_dialog.set_speaker(JsonUtil.get_str(f, "name_ko", _facility_id))
	_sync_view()


func room() -> CityRoom:
	return _room


## 지금 바라보는 살필 자리({rect, activity, rest} — 없으면 {}).
func focus() -> Dictionary:
	return _focus


func _build_world(view: Dictionary) -> void:
	var box := SubViewportContainer.new()
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp = SubViewport.new()
	var linear := JsonUtil.get_str(view, "texture_filter", "nearest") == "linear"
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR if linear \
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	box.add_child(_vp)
	var world := RoomWorld.new()
	_vp.add_child(world)
	world.build(_room, _state.db, _pc, _tile)
	_world = world
	_player = world.player
	_player.face(facing)
	_cam = Camera2D.new()
	var zoom := UiTheme.render_float("city.room.zoom", 1.6)
	_cam.zoom = Vector2(zoom, zoom)
	world.add_child(_cam)
	_cam.make_current()




func _process(delta: float) -> void:
	if paused:
		return
	if _room == null:
		return
	if _leaving or _acting or _dialog.busy():
		_held.clear()
	else:
		var dir := _input_dir()
		if dir != Vector2.ZERO:
			walk(dir, delta)
	_sync_view()


## dir 쪽으로 sec초만큼 걷는다(벽·가구에 막힌다 — 탐험과 같은 Kinematics). 문 칸에 들어서면 나간다.
## 계단·사다리 칸 위에서는 좌우를 막고(CT65) 느리게 — 계단은 오르면 뒷모습·내리면 앞모습, 사다리는 늘 뒷모습(피어 앤 헝거 1처럼 걷기 그림을 그대로).
func walk(dir: Vector2, sec: float) -> void:
	if _leaving or dir == Vector2.ZERO:
		return
	var speed := CityRoom.rule(_state, "walk_tiles_per_sec", 4.5)
	var cell := Kinematics.cell_of(pos)
	var k := _room.kind_at(cell)
	if k == "stairs" or k == "ladder":
		if dir.y == 0.0:
			return
		dir = Vector2(0.0, signf(dir.y))
		pos.x = move_toward(pos.x, cell.x + 0.5, sec * speed)  # 칸 가운데로 붙는다
		speed *= CityRoom.rule(_state, "ladder_speed" if k == "ladder" else "stairs_speed", 0.6)
		facing = Vector2i.UP if k == "ladder" or dir.y < 0.0 else Vector2i.DOWN
	else:
		facing = PlayerMotion.facing_of(dir)
	pos = Kinematics.move(_room.map, pos, dir.normalized() * speed * sec, CityRoom.rule(_state, "body_half", 0.3),
		CityRoom.rule(_state, "corner_assist", 0.45), 0.25)
	if _room.is_door(Kinematics.cell_of(pos)):
		try_leave()


## 이동 방향: 4방향만(탐험과 같다 — 사용자 결정 2026-10-24). 여러 키를 누르고 있으면 가장 나중에 누른 키.
func _input_dir() -> Vector2:
	for a: String in MOVE_DIRS:
		if not Input.is_action_pressed(a):
			_held.erase(a)
		elif not _held.has(a):
			_held.append(a)
	return MOVE_DIRS[_held.back()] if not _held.is_empty() else Vector2.ZERO


## 플레이어 그림·카메라·바라보는 자리의 이름판을 맞춘다.
func _sync_view() -> void:
	_player.position = pos * _tile
	_player.face(facing)
	var room_px := Vector2(_room.width, _room.height) * _tile
	var left := (UiTheme.render_float("city.calendar_width", 300.0) + UiTheme.metric("margin", 16) * 2.0) / _cam.zoom.x  # 왼쪽 위 달력 카드 자리
	var view := Vector2(_vp.size) / _cam.zoom
	var at := _player.position
	var cx := room_px.x * 0.5 - left * 0.5 if room_px.x <= view.x - left else clampf(at.x, view.x * 0.5 - left, room_px.x - view.x * 0.5)
	if room_px.x > view.x - left and room_px.x <= view.x:
		cx = room_px.x * 0.5
	_cam.position = Vector2(cx, room_px.y * 0.5 if room_px.y <= view.y else clampf(at.y, view.y * 0.5, room_px.y - view.y * 0.5))
	_focus = {} if _leaving or _acting else _room.target(pos, facing)  # 바라보는 자리(이름판은 띄우지 않는다 — 사용자 2026-11-01, 대상은 검은 테두리 CT77)




## 자리에서 고를 칸: [활동 id, 창구 쪽("" 또는 buy·sell)] — 상점·대장간 창구는 [구매]·[판매] 두 칸(메뉴 시설과 같다, CT49).
func entries(spot: Dictionary) -> Array[Array]:
	var out: Array[Array] = []
	for act_id in _room.activities_at(_state, spot):
		if JsonUtil.get_str(_state.activity(act_id), "panel") == "shop":
			for tab in CityShop.tabs(_state, act_id):
				out.append([act_id, tab])
		else:
			out.append([act_id, ""])
	return out


func _entry_text(e: Array) -> String:
	return Strings.t("city.shop_tab_" + str(e[1])) if not str(e[1]).is_empty() else JsonUtil.get_str(_state.activity(str(e[0])), "name_ko")


## Tab 메뉴·도감을 열어도 되는가: 걷는 중(활동 결과·선택 창·창구·대화가 없을 때 — CT74).
func menu_ok() -> bool:
	return _room != null and not _leaving and not _acting and _menu == null and not _dialog.busy()


## 이 활동을 지금 못 하는 이유(문자열 키, 할 수 있으면 "") — 활동 조건(CityActions.check — 도서관 분야는 한 방문에 한 번).
func reason(act_id: String) -> String:
	return CityActions.check(_state, _pc, act_id)


func _unhandled_input(event: InputEvent) -> void:
	if _room == null or _leaving or _acting or paused or _dialog.busy():
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()


## 바라보는 자리를 살핀다: 칸이 하나면 바로, 여럿이면 작은 선택 창(Esc = 그만두기). 창구면 그 패널을 연다.
func interact() -> void:
	var at := _room.target(pos, facing)
	if at.has("talk"):
		await talk(at)
		return
	if at.has("search"):  # 가구 뒤지기(CT74)
		var r := CityScavenge.run(_state, _pc, at)
		_dialog.say(Strings.t(str(r["key"]), r["args"] as Dictionary), str(r["tone"]))
		return
	var opts := entries(at)
	if opts.is_empty():
		return
	var pick: Array = opts[0]
	if opts.size() > 1:
		_acting = true
		var rows: Array[Dictionary] = []
		for e in opts:
			var why := reason(str(e[0]))
			rows.append({"text": _entry_text(e), "enabled": why.is_empty(), "sub": CityActions.price_text(_state, _pc, str(e[0])),
				"desc": Strings.t(why) if not why.is_empty() else ""})
		var title := str(_focus.get("name_ko", "")) if not str(_focus.get("name_ko", "")).is_empty() else JsonUtil.get_str(_state.db.get_entry("facilities", _facility_id), "name_ko")
		var i: int = await ChoicePopup.ask(self, title, rows, true)
		_acting = false
		if i < 0 or i >= opts.size() or not is_inside_tree():
			return
		pick = opts[i]
	if JsonUtil.get_str(_state.activity(str(pick[0])), "panel").is_empty():
		await use(str(pick[0]))
	else:
		open_panel(str(pick[0]), str(pick[1]))


## 사람에게 말 걸기(CT76): 그 사람이 이쪽을 보고 한 문장(대화창 이름판 = 그 사람). 걸 때마다 다음 줄, 다 넘기면 하던 일로 돌아간다.
func talk(who: Dictionary) -> void:
	var base := "city.npc." + str(who["talk"])
	var n := 0
	while Strings.has("%s.%d" % [base, n + 1]):
		n += 1
	if n == 0:
		return
	var at: Vector2i = who["at"]
	var said: int = _talked.get(at, absi(hash([at, _state.month, _state.period])) % n)
	_talked[at] = said + 1
	_acting = true
	_world.face_npc(at, -facing)
	_dialog.set_speaker(str(who["name_ko"]))
	_dialog.say(Strings.t("%s.%d" % [base, said % n + 1]), "info")
	await _dialog.wait()
	if not is_inside_tree():
		return
	_dialog.set_speaker(JsonUtil.get_str(_state.db.get_entry("facilities", _facility_id), "name_ko", _facility_id))
	_world.face_npc(at)
	_acting = false
	_focus = {}


## 창구(상점·대장간·은행·정수 제거)를 오른쪽 아래 카드로 연다. 거래 결과는 대화창 평소 글, 나가기·돌아가기·Esc = 창구만 닫고 다시 걷는다.
func open_panel(act_id: String, tab: String = "") -> void:
	var why := reason(act_id)
	if not why.is_empty():
		_dialog.say(Strings.t(why), "warn")
		return
	var p := new_panel(act_id, tab)
	if p == null:
		return
	p.leave = close_panel
	if p is ShopPanel:
		(p as ShopPanel).back = close_panel
	p.result.connect(_on_trade)
	_menu = CityUi.card()
	_menu.custom_minimum_size.x = UiTheme.render_float("city.interior_panel_width", 440.0)
	add_child(_menu)
	move_child(_menu, _dialog.get_index())
	_menu.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu.add_child(p)
	_menu.minimum_size_changed.connect(_place_panel)
	_place_panel()
	_acting = true


## 창구 카드 자리: 대화창 위 오른쪽 아래 귀퉁이에 제 크기만큼(위로 자라도 화면 위 여백까지).
## set_anchors_preset만 하면 0 크기 카드의 오프셋이 화면 전체로 남아 왼쪽 위 달력 카드까지 덮었다(2026-10-31 사용자 "위에 고정돼 너무 크고 글자가 안 보임").
func _place_panel() -> void:
	if _menu == null:
		return
	var m := float(UiTheme.metric("margin", 16))
	var sz := _menu.get_combined_minimum_size()
	_menu.offset_right = -m
	_menu.offset_left = -m - sz.x
	_menu.offset_bottom = _dialog.offset_top - m * 0.5
	_menu.offset_top = maxf(_menu.offset_bottom - sz.y, -size.y + m)


## 지금 열린 창구(없으면 null).
func panel() -> CityPanel:
	return _menu.get_child(0) as CityPanel if _menu != null and _menu.get_child_count() > 0 else null


func close_panel() -> void:
	if _menu == null:
		return
	_menu.queue_free()
	_menu = null
	_dialog.idle_text = ""
	_acting = false
	_focus = {}


## 활동 한 번: 결과를 대화창에 쌓고(서적·요리는 그림이 덮는다), 다 넘기면 그림을 걷고 다시 걷는다. 못 하면 이유 한 줄.
func use(act_id: String) -> void:
	var why := reason(act_id)
	if not why.is_empty():
		_dialog.say(Strings.t(why), "warn")
		return
	_acting = true
	var ctx := CityActions.perform(_state, _pc, act_id, _registry)
	show_result(ctx)
	await _dialog.wait()
	if not is_inside_tree():
		return
	if _art_pic != null:
		var pic := _art_pic
		_art_pic = null
		var tw := create_tween()
		tw.tween_property(pic, "modulate:a", 0.0, UiTheme.render_float("city.meal_art.fade_sec", 0.35))
		tw.tween_callback(pic.queue_free)
		art_hidden.emit()
	_acting = false
	_focus = {}


## 나가기(문 칸·Esc). 창구가 열려 있으면 창구만 닫는다. 결과를 넘기는 중이면 다 넘긴 뒤에.
func try_leave() -> void:
	if _menu != null:
		close_panel()
		return
	if _acting:
		return
	super.try_leave()
