class_name InteriorWorld
extends Node2D
## 시설 실내 그리기(InteriorView가 쓴다 — CT106). 그림은 tools/interior_bake.py가 구운 것(art_dir/index.json):
##   방마다 바닥 + 높이 있는 벽(북벽 앞면 · 옆벽 윗면 — 사람 뒤) 한 장(bg) · 낮게 자른 남벽 조각(front — 발 높이로 앞뒤) ·
##   벽에 붙은 활동 자리(책장 — bg 위, 검은 테두리) · 가구 덩어리(발 = 덩어리 아래 끝) · 사람(몸 그림 시트) · 플레이어.
## 지금 방만 보인다(set_room — 이전 방은 흐려 사라지고 새 방이 같은 시간에 밝아진다). 그림 파일이 없으면 그 자리는 비운다(걷기는 그대로).

var player: ActorView
var sorter: Node2D
var index: Dictionary = {}
var _tile: float = 32.0
var _items: Array[Array] = []  # 방 번호 → [CanvasItem …]
var _room := -1
var _tween: Tween


func build(inner: CityInterior, db: GameDatabase, pc: PlayerCharacter, tile: float) -> void:
	_tile = tile
	var dir := JsonUtil.get_str(inner.def, "art_dir")
	index = _read_index(dir.path_join("index.json"))
	var k := tile / maxf(1.0, JsonUtil.get_float(index, "tile", tile))
	for _i in inner.rooms.size():
		_items.append([])
	var ground := Node2D.new()
	add_child(ground)
	var walls := Node2D.new()  # 벽에 붙은 활동 자리(바닥 그림 위, 사람 뒤)
	add_child(walls)
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	add_child(sorter)
	var lined := Outline.material(db.render)
	var hot := inner.interactive_cells()
	var rooms_ix := JsonUtil.get_array(index, "rooms")
	for i in mini(rooms_ix.size(), inner.rooms.size()):
		var r: Dictionary = rooms_ix[i]
		_add(i, ground, _sprite(dir, JsonUtil.get_dict(r, "bg"), k, false))
		for f: Variant in JsonUtil.get_array(r, "front"):
			_add(i, sorter, _sprite(dir, f as Dictionary, k, true))
	for e: Variant in JsonUtil.get_array(index, "wallart"):
		var d: Dictionary = e
		var at := JsonUtil.get_array(d, "cell")
		var cell := Vector2i(int(at[0]), int(at[1]))
		var s := _sprite(dir, d, k, false)
		if s != null and hot.has(cell):
			s.material = lined
		_add(int(d.get("room", -1)), walls, s)
	var furn := JsonUtil.get_dict(index, "furniture")
	for f: Dictionary in inner.furniture:
		var rc: Rect2i = f["rect"]
		var d := JsonUtil.get_dict(furn, "%d,%d" % [rc.position.x, rc.position.y])
		var s := _sprite(dir, d, k, true)
		if s == null:
			continue
		for c in _cells(rc):
			if hot.has(c):
				s.material = lined  # 상호작용 대상 = 검은 테두리(CT77)
				break
		if bool(f.get("low", false)):
			s.z_index = -1  # 지나가는 낮은 것은 사람 발 아래
		_add(_room_of(inner, rc), sorter, s)
	for n: Dictionary in inner.npcs:
		var sheet := ActorSheet.load_for(db.render, str(n["look"]))
		if sheet == null:
			continue
		var person := _Standing.new()
		person.sheet = sheet
		person.facing = n["face"]
		person.position = (Vector2(n["at"]) + Vector2(0.5, 0.55)) * tile
		var a := InteriorView._num(db.render, "actor_scale", 1.0)
		person.scale = Vector2(a, a)
		_add(_room_of(inner, Rect2i(n["at"], Vector2i.ONE)), sorter, person)
	player = ActorView.new()
	sorter.add_child(player)
	player.setup_for(pc, db.render)
	player.drop_camera()
	var ps := InteriorView._num(db.render, "actor_scale", 1.0)
	player.scale = Vector2(ps, ps)
	for i in _items.size():
		for it: CanvasItem in _items[i]:
			it.visible = false
			it.modulate.a = 0.0


## 지금 방을 바꾼다(fade초 동안 겹쳐 바뀜 — 0이면 바로). 플레이어 밝기도 그 방 빛에 맞춘다.
func set_room(i: int, fade: float, tint: Color = Color.WHITE) -> void:
	if i == _room or i < 0 or i >= _items.size():
		return
	var old := _room
	_room = i
	if _tween != null:
		_tween.kill()
	for j in _items.size():
		if j != i and j != old:
			for it: CanvasItem in _items[j]:
				it.visible = false
				it.modulate.a = 0.0
	for it: CanvasItem in _items[i]:
		it.visible = true
	if fade <= 0.0:
		for it: CanvasItem in _items[i]:
			it.modulate.a = 1.0
		if old >= 0:
			for it: CanvasItem in _items[old]:
				it.visible = false
				it.modulate.a = 0.0
		player.modulate = tint
		return
	_tween = create_tween().set_parallel(true)
	for it: CanvasItem in _items[i]:
		_tween.tween_property(it, "modulate:a", 1.0, fade)
	if old >= 0:
		for it: CanvasItem in _items[old]:
			_tween.tween_property(it, "modulate:a", 0.0, fade)
	_tween.tween_property(player, "modulate", tint, fade)


func room() -> int:
	return _room


## 그 방에 보이는 것 수(시험).
func items_of(i: int) -> int:
	return _items[i].size() if i >= 0 and i < _items.size() else 0


func _add(i: int, parent: Node, it: CanvasItem) -> void:
	if it == null:
		return
	parent.add_child(it)
	if i >= 0 and i < _items.size():
		(_items[i] as Array).append(it)


## 구운 그림 한 장: d = {file, origin [x, y](그림 왼쪽 위 — 칸), foot(앞뒤 순서 y — 칸, sorted일 때)}.
func _sprite(dir: String, d: Dictionary, k: float, sorted: bool) -> Sprite2D:
	var file := JsonUtil.get_str(d, "file")
	var path := dir.path_join(file)
	if file.is_empty() or not ResourceLoader.exists(path):
		return null
	var s := Sprite2D.new()
	s.texture = load(path) as Texture2D
	s.centered = false
	s.scale = Vector2(k, k)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var o := JsonUtil.get_array(d, "origin")
	var origin := Vector2(float(o[0]), float(o[1])) * _tile if o.size() == 2 else Vector2.ZERO
	if sorted:
		var foot := JsonUtil.get_float(d, "foot", 0.0) * _tile
		s.position = Vector2(origin.x, foot)
		s.offset = Vector2(0, (origin.y - foot) / k)
	else:
		s.position = origin
	return s


static func _cells(rc: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(rc.position.y, rc.end.y):
		for x in range(rc.position.x, rc.end.x):
			out.append(Vector2i(x, y))
	return out


## 덩어리가 놓인 방(덩어리 칸 중 방 바닥인 첫 칸 — 가구 칸은 방 바닥에 든다).
static func _room_of(inner: CityInterior, rc: Rect2i) -> int:
	for c in _cells(rc):
		if inner.room_at(c) >= 0:
			return inner.room_at(c)
	return -1


static func _read_index(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d as Dictionary if d is Dictionary else {}


## 서 있는 사람(몸 그림 시트의 선 그림 한 칸) · 발밑 그림자.
class _Standing extends Node2D:
	var sheet: ActorSheet
	var facing: Vector2i = Vector2i(0, 1)

	func _draw() -> void:
		var w := sheet.world_size()
		draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.35), 0.0, Vector2(0, -1)))
		draw_circle(Vector2.ZERO, w.x * 0.3, Color(0, 0, 0, 0.45))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		sheet.draw(self, facing, sheet.stand)
