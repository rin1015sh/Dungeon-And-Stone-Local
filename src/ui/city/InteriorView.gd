class_name InteriorView
extends FacilityView
## 시설 실내(CT106 — 사용자 2026-11-04 "만들어봐 — 외부 도시나 건물 형태 분위기랑 비교해서 이질감 안 느껴지게"):
##   W/A/S/D로 걷고(4방향, 가장 나중에 누른 키), 활동 자리(사람 · 카운터 · 책장 · 제단 · 침대 …)를 바라보고 Enter = 그 자리 활동
##   (칸이 여럿이면 작은 선택 창, 창구는 오른쪽 아래 카드 — 판매는 소지품 창). 결과는 아래 대화창(요리 그림은 덮었다가 걷힌다).
##   바깥 문(D)을 밟거나 Esc = 나가기(창구 · 선택 창이 열려 있으면 그것만 닫는다). 행동력은 들어갈 때 1(CT72).
## 방이 여럿이면 플레이어가 있는 방만 보인다(InteriorWorld.set_room — 방 사이 문을 지나 다음 방 칸에 들어선 순간, 겹쳐 바뀜) ·
## 카메라는 그 방 가운데(방을 넘으면 미끄러진다). 이름판은 띄우지 않는다 — 활동 자리는 검은 테두리(CT77).
## 수치(겹쳐 바뀜 · 카메라 초)는 render.json city.interior.

const MOVE_DIRS := {"move_up": Vector2.UP, "move_down": Vector2.DOWN, "move_left": Vector2.LEFT, "move_right": Vector2.RIGHT}

## 몸 중심(칸 좌표) · 보는 방향 — 시험 · 캡처가 옮긴다.
var pos: Vector2 = Vector2.ZERO
var facing: Vector2i = Vector2i(0, -1)
## Tab 메뉴 · 도감이 열려 있는 동안 걷기 · 살피기를 멈춘다(CityScreen이 켠다).
var paused: bool = false

var _inner: CityInterior
var _vp: SubViewport
var _cam: Camera2D
var _world: InteriorWorld
var _tile: float = 32.0
var _held: Array[String] = []
var _acting: bool = false  # 결과를 넘기는 중 · 선택 창 · 창구
var _sell: ItemPickWindow
var _cam_tween: Tween


func _ready() -> void:
	var f := _state.db.get_entry("facilities", _facility_id)
	_inner = CityInterior.load_for(_state, _facility_id)
	var view := JsonUtil.get_dict(_state.db.render, "view")
	var ft := JsonUtil.get_array(view, "floor_tile_px")
	_tile = float(ft[0]) if ft.size() == 2 else _tile
	pos = _inner.start()
	_build_world(view)
	_dialog = DialogueBox.new()  # 전투와 같은 대화창(UI36) — 줄이 없으면 숨는다
	DialogueBox.place_bottom(_dialog, self)
	_dialog.set_speaker(JsonUtil.get_str(f, "name_ko", _facility_id))
	_enter_room(_inner.room_at(Kinematics.cell_of(pos)), true)
	_sync_view()


## 그 자리에 세운다(시험 · 캡처 — 그 방이 보이고 카메라도 그 방으로).
func place(p: Vector2, f: Vector2i = Vector2i.UP) -> void:
	pos = p
	facing = f
	var r := _inner.room_at(Kinematics.cell_of(pos))
	if r >= 0:
		_enter_room(r, true)
	_sync_view()


func interior() -> CityInterior:
	return _inner


func world() -> InteriorWorld:
	return _world


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
	_world = InteriorWorld.new()
	_vp.add_child(_world)
	_world.build(_inner, _state.db, _pc, _tile)
	_cam = Camera2D.new()
	var zoom := _num(_state.db.render, "zoom", TownBrush.num(_state.db.render, "zoom", 1.0))  # 실내는 동네와 따로(사람 · 벽 비율이 다르다)
	_cam.zoom = Vector2(zoom, zoom)
	_world.add_child(_cam)
	_cam.make_current()


## 걷기 규칙(city.json interior — 동네 town과 따로).
func _rule(key: String, fallback: float) -> float:
	var v := CityValues.num(CityValues.city_section(_state.db, _state.overrides, "interior"), key)
	return v if v > 0.0 else fallback


static func _num(render: Dictionary, key: String, fallback: float) -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(JsonUtil.get_dict(render, "city"), "interior"), key, fallback)


func _process(delta: float) -> void:
	if paused or _inner == null:
		_held.clear()
		return
	if _leaving or _acting or _dialog.busy():
		_held.clear()
	else:
		var dir := _input_dir()
		if dir != Vector2.ZERO:
			walk(dir, delta)
	_sync_view()


## dir 쪽으로 sec초만큼 걷는다(벽 · 가구 · 사람에 막힌다 — Kinematics). 다른 방 칸에 들어서면 그 방만 보인다. 바깥 문 칸이면 나간다.
func walk(dir: Vector2, sec: float) -> void:
	if _leaving or dir == Vector2.ZERO:
		return
	facing = PlayerMotion.facing_of(dir)
	var speed := _rule("walk_tiles_per_sec", 4.5)
	pos = Kinematics.move(_inner.map, pos, dir.normalized() * speed * sec, _rule("body_half", 0.3), _rule("corner_assist", 0.8), 0.25)
	var cell := Kinematics.cell_of(pos)
	var r := _inner.room_at(cell)
	if r >= 0 and r != _world.room():
		_enter_room(r, false)
	if _inner.is_exit(cell):
		try_leave()


## 방 하나만 보이게 + 카메라를 그 방 가운데로.
func _enter_room(r: int, now: bool) -> void:
	if r < 0:
		return
	var rd: Dictionary = _inner.rooms[r]["def"]
	var amb := JsonUtil.get_float(rd, "ambient", 0.7)
	var tint := Color.WHITE.lerp(Color(amb, amb * 0.96, amb * 0.9), _num(_state.db.render, "actor_tint", 0.55))
	_world.set_room(r, 0.0 if now else _num(_state.db.render, "fade_sec", 0.2), tint)
	var at := _room_center(r)
	if _cam_tween != null:
		_cam_tween.kill()
	if now:
		_cam.position = at
	else:
		_cam_tween = create_tween()
		_cam_tween.tween_property(_cam, "position", at, _num(_state.db.render, "camera_sec", 0.3)).set_trans(Tween.TRANS_SINE)


## 방 가운데(세계 px): 둘레 벽 한 칸 + 북벽 앞면 높이(index.json wall_h)까지 넣은 상자의 가운데.
## 방이 왼쪽 위 달력 카드를 비켜 들어갈 만큼 좁으면 카드 오른쪽 빈 곳의 가운데에 둔다.
func _room_center(r: int) -> Vector2:
	var rc: Rect2i = _inner.rooms[r]["rect"]
	var wall_h := JsonUtil.get_float(_world.index, "wall_h", 2.4)
	var top := rc.position.y - 1.0 - wall_h
	var bottom := rc.end.y + 1.0
	var c := Vector2(rc.position.x + rc.size.x * 0.5, (top + bottom) * 0.5) * _tile
	var view := get_viewport_rect().size / _cam.zoom  # 하위 뷰포트 크기는 처음엔 기본값(512)이라 창 크기로 잰다
	var left := (UiTheme.render_float("city.calendar_width", 300.0) + UiTheme.metric("margin", 16) * 2.0) / _cam.zoom.x
	var room_w := (rc.size.x + 2.0) * _tile
	if room_w <= view.x - left:
		c.x -= left * 0.5
	return c


## 이동 방향: 4방향만. 여러 키를 누르고 있으면 가장 나중에 누른 키.
func _input_dir() -> Vector2:
	for a: String in MOVE_DIRS:
		if not Input.is_action_pressed(a):
			_held.erase(a)
		elif not _held.has(a):
			_held.append(a)
	return MOVE_DIRS[_held.back()] if not _held.is_empty() else Vector2.ZERO


func _sync_view() -> void:
	_world.player.position = pos * _tile
	_world.player.face(facing)


## 자리에서 고를 칸: [활동 id, 창구 쪽("" 또는 buy·sell)].
func spot_entries(spot: Dictionary) -> Array[Array]:
	var out: Array[Array] = []
	for act_id: String in spot.get("acts", []):
		if JsonUtil.get_str(_state.activity(act_id), "panel") == "shop":
			for tab in CityShop.tabs(_state, act_id):
				out.append([act_id, tab])
		else:
			out.append([act_id, ""])
	return out


func _entry_text(e: Array) -> String:
	return Strings.t("city.shop_tab_" + str(e[1])) if not str(e[1]).is_empty() else JsonUtil.get_str(_state.activity(str(e[0])), "name_ko")


## 지금 바라보는 것(활동 자리 · 잠긴 문 — 없으면 {}).
func focus() -> Dictionary:
	return {} if _leaving or _acting else _inner.target(pos, facing)


## Tab 메뉴 · 도감을 열어도 되는가: 걷는 중(결과 · 선택 창 · 창구 · 대화가 없을 때).
func menu_ok() -> bool:
	return _inner != null and not _leaving and not _acting and _menu == null and not _dialog.busy()


func _unhandled_input(event: InputEvent) -> void:
	if _inner == null or _leaving or _acting or paused or _dialog.busy():
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()


## 바라보는 자리를 살핀다: 칸이 하나면 바로, 여럿이면 작은 선택 창(Esc = 그만두기). 창구면 그 카드를, 판매면 소지품 창을 연다.
func interact() -> void:
	var at := _inner.target(pos, facing)
	if bool(at.get("locked", false)):
		_dialog.say(Strings.t("city.interior.locked"), "info")
		return
	var opts := spot_entries(at)
	if opts.is_empty():
		return
	_dialog.set_speaker(str(at.get("name_ko", "")) if not str(at.get("name_ko", "")).is_empty() else JsonUtil.get_str(_state.db.get_entry("facilities", _facility_id), "name_ko"))
	var pick: Array = opts[0]
	if opts.size() > 1:
		_acting = true
		var rows: Array[Dictionary] = []
		for e in opts:
			var why := CityActions.check(_state, _pc, str(e[0]))
			rows.append({"text": _entry_text(e), "enabled": why.is_empty(),
				"sub": Strings.t(why) if not why.is_empty() else CityActions.price_text(_state, _pc, str(e[0]))})
		var i: int = await ChoicePopup.ask(self, str(at.get("name_ko", "")), rows, true)
		_acting = false
		if i < 0 or i >= opts.size() or not is_inside_tree():
			return
		pick = opts[i]
	var act_id := str(pick[0])
	var why2 := CityActions.check(_state, _pc, act_id)
	if not why2.is_empty():
		_dialog.say(Strings.t(why2), "warn")
		return
	var panel := JsonUtil.get_str(_state.activity(act_id), "panel")
	if panel.is_empty():
		await use(act_id)
	elif panel == "shop" and str(pick[1]) == "sell":
		_open_sell_here(act_id)
	else:
		open_panel(act_id, str(pick[1]))


## 활동 한 번: 결과를 대화창에 쌓고(요리 그림은 덮는다), 다 넘기면 그림을 걷고 다시 걷는다.
func use(act_id: String) -> void:
	_acting = true
	var ctx := CityActions.perform(_state, _pc, act_id, _registry)
	show_result(ctx)
	await _dialog.wait()
	if not is_inside_tree():
		return
	_hide_art()
	_acting = false


## 판매: 소지품 창(하나씩 — Esc = 닫고 다시 걷는다).
func _open_sell_here(act_id: String) -> void:
	_acting = true
	_sell = ItemPickWindow.open(self, _pc, Strings.t("city.shop_tab_sell"),
		func(id: String) -> bool: return CityShop.can_sell(_state, id, act_id),
		func(id: String) -> int: return CityShop.sell_price(_state, id, act_id))
	_sell.picked.connect(func(id: String) -> void:
		_on_trade(CityShop.sell(_state, _pc, act_id, id, 1))
		_sell.refresh())
	_sell.closed.connect(func() -> void:
		_sell = null
		_dialog.idle_text = ""
		_acting = false)


## 창구(상점 · 대장간 구매 · 은행 · 정수 제거) 카드를 오른쪽 아래에 연다. 나가기 · 돌아가기 · Esc = 창구만 닫는다.
func open_panel(act_id: String, tab: String = "") -> void:
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
	_menu.minimum_size_changed.connect(_place_menu)
	_place_menu()
	p.active = true
	_acting = true


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


## 나가기(바깥 문 · Esc). 창구가 열려 있으면 창구만 닫는다. 결과를 넘기는 중이거나 선택 창 · 소지품 창이 떠 있으면 아무것도 하지 않는다(그 창이 Esc를 받는다).
func try_leave() -> void:
	if _menu != null:
		close_panel()
		return
	if _acting or _sell != null:
		return
	super.try_leave()


func _sync_menu() -> void:
	pass


func _refresh_info() -> void:
	pass
