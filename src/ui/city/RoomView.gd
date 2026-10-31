class_name RoomView
extends FacilityView
## 시설 실내 방(탑뷰 — CityRoom, 사용자 결정 2026-10-31 "도서관 내부를 탐험 화면처럼 WASD로", CT62).
##   탐험처럼 W/A/S/D로 걷고(4방향, 가장 나중에 누른 키), 살필 자리를 바라보고 Enter = 그 자리 활동(결과는 대화창 — 서적은 펼친 책 그림이 덮었다가
##   다 넘기면 걷힌다). 자리에 활동이 여럿이면(사서 책상 — 고서 해독·이번 순 사건) 작은 선택 창.
##   문 칸을 밟거나 Esc = 나가기 — 행동력은 나올 때 1(CityState.leave_facility). 한 방문의 활동은 city.json room.activities_per_visit개,
##   다 하면 남은 자리는 못 하는 이유만 보인다. 바라보는 자리 위에 이름판(활동 이름 · 못 하면 짧은 이유 — 부연설명 없음).
## 그리기: 방 그림(바닥·벽·벽 가구 — tools/paint_rooms.gd) 위에 소품·사람·플레이어를 발 높이로 정렬(탐험과 같은 3/4 시점, 칸 = view.floor_tile_px).
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
var _done: int = 0      # 이번 방문에 한 활동 수
var _acting: bool = false  # 활동 결과를 넘기는 중 · 선택 창
var _plate: PanelContainer
var _plate_name: Label
var _plate_why: Label
var _focus: Dictionary = {}


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
	_build_plate()
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
	var art_scale := maxf(1.0, JsonUtil.get_float(view, "art_scale", 2.0))
	var world := Node2D.new()
	_vp.add_child(world)
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = _tex(JsonUtil.get_str(_room.def, "art"))
	bg.scale = Vector2.ONE / art_scale
	world.add_child(bg)
	var sorter := Node2D.new()  # 발 높이(y)로 앞뒤를 정한다
	sorter.y_sort_enabled = true
	world.add_child(sorter)
	for p: Dictionary in _room.props:
		sorter.add_child(_prop_node(p, art_scale))
	_player = ActorView.new()
	sorter.add_child(_player)
	_player.setup_for(_pc, _state.db.render)
	_player.drop_camera()
	_player.face(facing)
	_cam = Camera2D.new()
	var zoom := UiTheme.render_float("city.room.zoom", 1.6)
	_cam.zoom = Vector2(zoom, zoom)
	world.add_child(_cam)
	_cam.make_current()


## 소품: 그림(발 = rect 아래 가운데) 또는 서 있는 사람(몸 그림 시트 — 발 = rect 가운데).
func _prop_node(p: Dictionary, art_scale: float) -> Node2D:
	var rc: Rect2i = p["rect"]
	var sheet: ActorSheet = ActorSheet.load_for(_state.db.render, str(p["sprite"])) if not str(p["sprite"]).is_empty() else null
	if sheet != null:
		var person := _Standing.new()
		person.sheet = sheet
		person.facing = p["face"]
		person.position = (Vector2(rc.position) + Vector2(rc.size) * 0.5) * _tile
		return person
	var s := Sprite2D.new()
	s.texture = _tex(str(p["art"]))
	s.centered = false
	s.scale = Vector2.ONE / art_scale
	s.position = Vector2((rc.position.x + rc.size.x * 0.5) * _tile, rc.end.y * _tile)
	if s.texture != null:
		s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
	return s


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null


func _build_plate() -> void:
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	_plate.add_child(v)
	_plate_name = CityUi.label("", "body", "bone")
	_plate_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_plate_name)
	_plate_why = CityUi.label("", "small", "dim")
	_plate_why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_plate_why)
	_plate.visible = false
	add_child(_plate)
	move_child(_plate, _dialog.get_index())  # 대화창 아래


func _process(delta: float) -> void:
	if _room == null:
		return
	if _leaving or _acting or _dialog.busy():
		_held.clear()
	else:
		var dir := _input_dir()
		if dir != Vector2.ZERO:
			walk(dir, delta)
	_sync_view()


## dir 쪽으로 sec초만큼 걷는다(벽·소품에 막힌다 — 탐험과 같은 Kinematics). 문 칸에 들어서면 나간다.
func walk(dir: Vector2, sec: float) -> void:
	if _leaving or dir == Vector2.ZERO:
		return
	facing = PlayerMotion.facing_of(dir)
	var speed := CityRoom.rule(_state, "walk_tiles_per_sec", 4.5)
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
	var spot: Dictionary = {} if _leaving or _acting else _room.target(pos, facing)
	if spot != _focus:
		_focus = spot
		_refresh_plate()
	if _plate.visible:
		var rc: Rect2i = _focus["rect"]
		var top := (_vp.get_canvas_transform() * Vector2((rc.position.x + rc.size.x * 0.5) * _tile, rc.position.y * _tile))
		_plate.reset_size()
		var m := float(UiTheme.metric("margin", 16))
		_plate.position = Vector2(clampf(top.x - _plate.size.x * 0.5, m, size.x - _plate.size.x - m),
			clampf(top.y - _plate.size.y - UiTheme.render_float("city.plate_offset_px", 8.0), m, size.y - _plate.size.y - m))


func _refresh_plate() -> void:
	var acts: Array[String] = []
	if not _focus.is_empty():
		acts = _room.activities_at(_state, _focus)
	_plate.visible = not acts.is_empty()
	if acts.is_empty():
		return
	var why: String = reason(acts[0]) if acts.size() == 1 else ""
	_plate_name.text = JsonUtil.get_str(_state.activity(acts[0]), "name_ko") if acts.size() == 1 else JsonUtil.get_str(_state.db.get_entry("rooms", _room.id), "name_ko")
	_plate_why.text = Strings.t(why) if not why.is_empty() else CityActions.price_text(_state, _pc, acts[0])
	_plate_why.visible = not _plate_why.text.is_empty()
	_plate.add_theme_stylebox_override("panel", CityUi.plate_box(why.is_empty()))


## 이 활동을 지금 못 하는 이유(문자열 키, 할 수 있으면 ""): 이번 방문에 할 만큼 했다 → 활동 조건(CityActions.check).
func reason(act_id: String) -> String:
	if _done >= int(CityRoom.rule(_state, "activities_per_visit", 1.0)):
		return "city.reason_visit_done"
	if not JsonUtil.get_str(_state.activity(act_id), "panel").is_empty():
		return "city.reason_panel"
	return CityActions.check(_state, _pc, act_id)


func _unhandled_input(event: InputEvent) -> void:
	if _room == null or _leaving or _acting or _dialog.busy():
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()


## 바라보는 자리를 살핀다: 활동이 하나면 바로, 여럿이면 작은 선택 창(Esc = 그만두기).
func interact() -> void:
	var acts := _room.activities_at(_state, _room.target(pos, facing))
	if acts.is_empty():
		return
	var act_id := acts[0]
	if acts.size() > 1:
		_acting = true
		var opts: Array[Dictionary] = []
		for a in acts:
			var why := reason(a)
			opts.append({"text": JsonUtil.get_str(_state.activity(a), "name_ko"), "enabled": why.is_empty(),
				"sub": CityActions.price_text(_state, _pc, a), "desc": Strings.t(why) if not why.is_empty() else ""})
		var i: int = await ChoicePopup.ask(self, JsonUtil.get_str(_state.db.get_entry("rooms", _room.id), "name_ko"), opts, true)
		_acting = false
		if i < 0 or i >= acts.size() or not is_inside_tree():
			return
		act_id = acts[i]
	await use(act_id)


## 활동 한 번: 결과를 대화창에 쌓고(서적은 펼친 책 그림), 다 넘기면 그림을 걷고 다시 걷는다. 못 하면 이유 한 줄.
func use(act_id: String) -> void:
	var why := reason(act_id)
	if not why.is_empty():
		_dialog.say(Strings.t(why), "warn")
		return
	_acting = true
	_refresh_plate()
	var ctx := CityActions.perform(_state, _pc, act_id, _registry)
	show_result(ctx)
	if ctx.ok:
		_done += 1
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


## 나가기(문 칸·Esc). 결과를 넘기는 중이면 다 넘긴 뒤에.
func try_leave() -> void:
	if _acting:
		return
	super.try_leave()


## 서 있는 사람(몸 그림 시트의 선 그림 한 칸 — 사서 등). 발밑 그림자.
class _Standing extends Node2D:
	var sheet: ActorSheet
	var facing: Vector2i = Vector2i(0, 1)

	func _draw() -> void:
		var w := sheet.world_size()
		draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.35), 0.0, Vector2(0, -1)))
		draw_circle(Vector2.ZERO, w.x * 0.3, Color(0, 0, 0, 0.45))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		sheet.draw(self, facing, sheet.stand)
