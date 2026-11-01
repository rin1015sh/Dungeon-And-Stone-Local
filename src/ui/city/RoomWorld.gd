class_name RoomWorld
extends Node2D
## 시설 실내 지도 그리기(RoomView가 쓴다 — CT66): 바닥 그림 한 장(floor.webp — 바닥·깔개·바닥 장식) 위에 발 높이로 앞뒤를 정하는 것들 —
##   벽 줄(walls.webp를 칸 줄마다 잘라 그 줄 아래 끝에 세운다 — 벽 북쪽에 선 사람은 벽에 가린다) · 가구 무리 그림(f_<글자>_<w>x<h>.webp, 발 = 무리 아래 가운데) ·
##   잠긴 문(지금 잠겨 있을 때만) · 사람(몸 그림 시트의 선 그림, 동작 act가 있으면 NpcActSheet 칸을 돌린다) · 플레이어. 그림은 tools/paint_rooms.gd가 그린다(칸 = view.floor_tile_px × city.json room.art_scale px).
## 그림 파일이 없으면 그 자리는 비운다(걷기·살피기는 그대로).

var player: ActorView
var sorter: Node2D
var _tile: float = 32.0
var _people: Dictionary = {}  # 칸 → 사람(_Standing)


func build(room: CityRoom, db: GameDatabase, pc: PlayerCharacter, tile: float) -> void:
	_tile = tile
	var art_scale := maxf(1.0, JsonUtil.get_float(JsonUtil.get_dict(db.singletons.get("city", {}), "room"), "art_scale", 1.5))
	var dir := JsonUtil.get_str(room.def, "art_dir")
	var bg := Sprite2D.new()
	bg.centered = false
	bg.texture = _tex(dir.path_join("floor.webp"))
	bg.scale = Vector2.ONE / art_scale
	add_child(bg)
	var low := Node2D.new()  # 지나가는 낮은 가구(책 더미·의자 …)는 사람 발 아래 — 밟고 선 사람을 가리지 않게
	add_child(low)
	sorter = Node2D.new()
	sorter.y_sort_enabled = true
	add_child(sorter)
	var walls := _tex(dir.path_join("walls.webp"))
	if walls != null:
		var ta := tile * art_scale
		for y in room.height:
			if not _has_wall(room, y):
				continue
			var s := Sprite2D.new()
			s.texture = walls
			s.centered = false
			s.region_enabled = true
			s.region_rect = Rect2(0, y * ta, walls.get_width(), ta)
			s.scale = Vector2.ONE / art_scale
			s.position = Vector2(0, (y + 1) * tile)
			s.offset = Vector2(0, -ta)
			sorter.add_child(s)
	var hot := room.interactive_rects()
	var lined := Outline.material(db.render)
	for f: Dictionary in room.furniture:
		var rc: Rect2i = f["rect"]
		var s := Sprite2D.new()
		if hot.any(func(h: Rect2i) -> bool: return h.intersects(rc)):
			s.material = lined  # 상호작용 대상 = 검은 테두리(CT77)
		s.texture = _tex(CityRoom.furniture_art(room.def, str(f["char"]), rc.size))
		if s.texture == null:
			continue
		s.centered = false
		s.scale = Vector2.ONE / art_scale
		s.position = Vector2((rc.position.x + rc.size.x * 0.5) * tile, rc.end.y * tile)
		s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
		(low if bool(f.get("low", false)) else sorter).add_child(s)
	for g: Dictionary in CityRoom.groups(room.rows, room.legend, ["walldeco"]):  # 벽 장식(책장 …) 중 상호작용 대상 = 둘레 검은 선
		var rc: Rect2i = g["rect"]
		if room.kind_at(rc.position) == "walldeco" and hot.any(func(h: Rect2i) -> bool: return h.intersects(rc)):
			var frame := _Frame.new()
			frame.size = Vector2(rc.size) * tile
			frame.width = Outline.cfg(db.render, "rect_px", 1.5)
			frame.position = Vector2(rc.position.x, rc.end.y) * tile
			sorter.add_child(frame)
	for y in room.height:  # 잠긴 문(이번 순 사건이 열면 그냥 문간 — 그림 없음)
		for x in room.width:
			if room.kind_at(Vector2i(x, y)) == "locked":
				var d := Sprite2D.new()
				d.texture = _tex(CityRoom.furniture_art(room.def, room.rows[y][x], Vector2i.ONE))
				d.centered = false
				d.scale = Vector2.ONE / art_scale
				d.position = Vector2((x + 0.5) * tile, (y + 1) * tile)
				if d.texture != null:
					d.offset = Vector2(-d.texture.get_width() * 0.5, -d.texture.get_height())
					sorter.add_child(d)
	for n: Dictionary in room.npcs:
		var sheet := ActorSheet.load_for(db.render, str(n["look"]))
		if sheet == null:
			continue
		var person := _Standing.new()
		person.sheet = sheet
		person.act = NpcActSheet.load_for(db.render, str(n["look"]), str(n.get("act", "")))
		person.phase = float(absi(hash(n["at"])) % 997) / 997.0 * 10.0  # 사람마다 동작이 엇갈리게(위치로 정한 값 — 무작위가 아니다)
		person.facing = n["face"]
		person.home = n["face"]
		_people[n["at"]] = person
		person.position = (Vector2(n["at"]) + Vector2(0.5, 0.5)) * tile
		sorter.add_child(person)
	player = ActorView.new()
	sorter.add_child(player)
	player.setup_for(pc, db.render)
	player.drop_camera()


## 사람이 dir 쪽을 보게(말 걸 때 — 0이면 원래 보던 쪽으로).
func face_npc(at: Vector2i, dir: Vector2i = Vector2i.ZERO) -> void:
	var p: _Standing = _people.get(at)
	if p != null:
		p.facing = dir if dir != Vector2i.ZERO else p.home
		p.queue_redraw()


static func _has_wall(room: CityRoom, y: int) -> bool:
	for x in room.width:
		if room.kind_at(Vector2i(x, y)) in ["wall", "walldeco"]:
			return true
	return false


static func _tex(path: String) -> Texture2D:
	return load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null


## 벽 장식 둘레 검은 선(발 = 아래 왼쪽 — 벽 줄과 같은 y로 정렬, CT77).
class _Frame extends Node2D:
	var size: Vector2
	var width: float = 1.5

	func _draw() -> void:
		var h := width * 0.5
		draw_rect(Rect2(Vector2(h, -size.y + h), size - Vector2(width, width)), Color.BLACK, false, width)


## 사람(몸 그림 시트의 선 그림 한 칸 — 동작 그림(act)이 있으면 그 칸을 돌린다, CT69). 발밑 그림자.
class _Standing extends Node2D:
	var sheet: ActorSheet
	var act: NpcActSheet
	var facing: Vector2i = Vector2i(0, 1)
	var home: Vector2i = Vector2i(0, 1)
	var phase: float = 0.0
	var _t: float = 0.0
	var _col: int = -1

	func _ready() -> void:
		set_process(act != null)

	func _process(delta: float) -> void:
		_t += delta
		var c := act.col_at(_t + phase)
		if c != _col:
			_col = c
			queue_redraw()

	func _draw() -> void:
		var w := sheet.world_size()
		draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.35), 0.0, Vector2(0, -1)))
		draw_circle(Vector2.ZERO, w.x * 0.3, Color(0, 0, 0, 0.45))
		draw_set_transform_matrix(Transform2D.IDENTITY)
		if act != null:
			act.draw(self, facing, act.col_at(_t + phase))
		else:
			sheet.draw(self, facing, sheet.stand)
