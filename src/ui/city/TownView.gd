class_name TownView
extends Control
## 도시 동네 지도 화면(CT82 — 횡스크롤 거리 CityStreet 대신, 2026-11-02 사용자 "횡스크롤을 버리자 · 7구역 전체 · M0"):
##   라비기온 7구역(TownMap)을 탐험·옛 실내처럼 W/A/S/D로 걷고(4방향, 가장 나중에 누른 키), 시설 문 앞에서 위를 보고 Enter = 들어가기
##   (facility_chosen — 행동력은 CityScreen이 들어갈 때 1, CT72), 구역문을 바라보고 Enter = 특별 시설 창(travel_requested),
##   광장 돌 고리를 바라보고 Enter = 닫혀 있다는 한 줄(포탈은 하순이 끝나면 차원광장 화면에서 — M3에서 이 광장으로 옮긴다).
## 계단 칸 위에서는 위아래로만 걷고 느리다. 거리의 통·상자는 뒤지지 않는다(사용자 2026-11-02).
## 키보드만. CityScreen이 paused를 켜면(메뉴·대화창·시설 창·거리 사건) 걷지 않는다.

signal facility_chosen(facility_id: String)
signal travel_requested
signal told(key: String)  ## 화면으로 알 수 없는 짧은 한 줄(문구 키) — 도시 대화창에

const MOVE_DIRS := {"move_up": Vector2.UP, "move_down": Vector2.DOWN, "move_left": Vector2.LEFT, "move_right": Vector2.RIGHT}

## 몸 중심(칸 좌표) · 보는 방향 — 시험·캡처가 옮긴다.
var pos: Vector2 = Vector2.ZERO
var facing: Vector2i = Vector2i(0, -1)
var paused: bool = false

var _state: CityState
var _pc: PlayerCharacter
var _town: TownMap
var _vp: SubViewport
var _cam: Camera2D
var _world: TownWorld
var _tile: float = 32.0
var _held: Array[String] = []


func setup(state: CityState, pc: PlayerCharacter) -> void:
	_state = state
	_pc = pc


func _ready() -> void:
	_town = TownMap.load_for(_state.db, _state.overrides)
	var view := JsonUtil.get_dict(_state.db.render, "view")
	var ft := JsonUtil.get_array(view, "floor_tile_px")
	_tile = float(ft[0]) if ft.size() == 2 else _tile
	pos = Vector2(_town.start) + Vector2(0.5, 0.5)
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
	_world = TownWorld.new()
	_vp.add_child(_world)
	_world.build(_town, _state.db, _pc, _tile)
	_cam = Camera2D.new()
	var zoom := TownBrush.num(_state.db.render, "zoom", 1.0)
	_cam.zoom = Vector2(zoom, zoom)
	_world.add_child(_cam)
	_cam.make_current()
	refresh_weather()
	_sync_view()


func town() -> TownMap:
	return _town


func world() -> TownWorld:
	return _world


## 순이 바뀌었다 — 날씨 색.
func refresh_weather() -> void:
	if _world != null:
		_world.set_tint(CityStreet._rgb(_state.weather_def().get("tint")))


## 시설에서 나왔다: 그 문 앞에 남쪽을 보고 선다.
func place_at_door(facility_id: String) -> void:
	pos = _town.door_front(facility_id)
	facing = Vector2i.DOWN
	_sync_view()


## 그 시설 문 앞에서 문을 바라본다(시험·캡처).
func stand_before(facility_id: String) -> void:
	pos = _town.door_front(facility_id)
	facing = Vector2i.UP
	_sync_view()


func focus() -> Dictionary:
	return _town.target(pos, facing)


func _process(delta: float) -> void:
	if paused or _town == null:
		_held.clear()
		return
	var dir := _input_dir()
	if dir != Vector2.ZERO:
		walk(dir, delta)
	_sync_view()


## dir 쪽으로 sec초만큼 걷는다(집·벽·물에 막힌다 — Kinematics). 계단 칸 위에서는 위아래로만, 느리게.
func walk(dir: Vector2, sec: float) -> void:
	if dir == Vector2.ZERO:
		return
	var speed := TownMap.rule(_state.db, _state.overrides, "walk_tiles_per_sec", 4.5)
	var cell := Kinematics.cell_of(pos)
	if _town.kind_at(cell) == "stairs":
		if dir.y == 0.0:
			facing = PlayerMotion.facing_of(dir)
			return
		dir = Vector2(0.0, signf(dir.y))
		speed *= TownMap.rule(_state.db, _state.overrides, "stairs_speed", 0.75)
	facing = PlayerMotion.facing_of(dir)
	pos = Kinematics.move(_town.map, pos, dir.normalized() * speed * sec, TownMap.rule(_state.db, _state.overrides, "body_half", 0.3),
		TownMap.rule(_state.db, _state.overrides, "corner_assist", 0.8), 0.25)


func _input_dir() -> Vector2:
	for a: String in MOVE_DIRS:
		if not Input.is_action_pressed(a):
			_held.erase(a)
		elif not _held.has(a):
			_held.append(a)
	return MOVE_DIRS[_held.back()] if not _held.is_empty() else Vector2.ZERO


func _sync_view() -> void:
	if _world == null:
		return
	var p := _world.player
	var lift := _town.elevation(pos) * _tile
	_world.player_root.position = pos * _tile
	p.position = Vector2(0, -lift)
	p.face(facing)
	var map_px := Vector2(_town.width, _town.height) * _tile
	var top := -_town.max_height() * _tile  # 높은 단은 위로 올라가 그려진다
	var view := Vector2(_vp.size) / _cam.zoom
	var at := pos * _tile - Vector2(0, lift + _tile * 0.3)  # 몸 가운데쯤(사람 키 ≈ 1칸 — CT107)
	_cam.position = Vector2(clampf(at.x, view.x * 0.5, maxf(view.x * 0.5, map_px.x - view.x * 0.5)),
		clampf(at.y, top + view.y * 0.5, maxf(top + view.y * 0.5, map_px.y - view.y * 0.5)))
	_world.stream(_cam.position + Vector2(0, lift))
	_world.update_fade(pos * _tile, lift)


func _unhandled_input(event: InputEvent) -> void:
	if paused or _town == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()


## 바라보는 것을 살핀다: 시설 문 = 들어가기 · 구역문 = 특별 시설 창 · 돌 고리 = 닫혀 있다.
func interact() -> void:
	var t := focus()
	if t.has("door"):
		facility_chosen.emit(str(t["door"]))
	elif t.has("gate"):
		if bool(t.get("travel", false)):
			travel_requested.emit()
	elif t.has("ring"):
		told.emit("city.town.portal_closed")
