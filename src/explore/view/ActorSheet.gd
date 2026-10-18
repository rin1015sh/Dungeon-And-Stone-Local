class_name ActorSheet
extends RefCounted
## 탐험 맵 몸 그림 시트(tools/paint_actors.gd → assets/actors/<종족>.webp): 줄 = 아래·왼쪽·오른쪽·위,
## 칸 = 걸음 A·반걸음 A·섬·반걸음 B·걸음 B. 칸 수·재생 순서·크기·그림 배율·발 위치·걷기 속도는 render.json view.actor_sheet. 원점 = 발.
## 걷는 동안 walk_cycle(섬 → 반걸음 → 걸음 → 반걸음 → 섬 → …, 섬이 한 바퀴에 두 번)을 walk_fps로 돌고, 멈추면 stand_col.

var cols: int = 5
var stand: int = 2
var cycle: Array[int] = [2, 1, 0, 1, 2, 3, 4, 3]

var texture: Texture2D
var cell: Vector2 = Vector2(72, 108)  ## 그림 px
var scale: float = 0.5                ## 그림 px → 월드 px
var foot: float = 4.0
var fps: float = 7.0


static func load_for(render: Dictionary, path: String) -> ActorSheet:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "actor_sheet")
	var s := ActorSheet.new()
	s.texture = load(path) as Texture2D
	var c := JsonUtil.get_array(cfg, "cell")
	if c.size() == 2:
		s.cell = Vector2(float(c[0]), float(c[1]))
	s.scale = 1.0 / maxf(1.0, JsonUtil.get_float(cfg, "art_scale", 2.0))
	s.foot = JsonUtil.get_float(cfg, "foot_px", 4.0)
	s.fps = JsonUtil.get_float(cfg, "walk_fps", 12.0)
	s.cols = JsonUtil.get_int(cfg, "cols", 5)
	s.stand = JsonUtil.get_int(cfg, "stand_col", 2)
	var cyc := JsonUtil.get_array(cfg, "walk_cycle")
	if not cyc.is_empty():
		s.cycle.clear()
		for v: Variant in cyc:
			s.cycle.append(clampi(int(v), 0, s.cols - 1))
	if s.texture == null or s.texture.get_width() < s.cell.x * s.cols or s.texture.get_height() < s.cell.y * 4:
		return null
	return s


## 몬스터 걷기 시트(tools/paint_actors.gd → <monster_dir>/<id>_walk.webp + sheets.json {id: {cell, foot}}) — 칸 크기는 몬스터마다.
## 시트가 없으면 null(전투 그림을 줄인 한 장을 쓴다).
static func load_monster(render: Dictionary, id: String) -> ActorSheet:
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "actor_sheet")
	var dir := JsonUtil.get_str(cfg, "monster_dir", "res://assets/actors/monsters")
	var meta := JsonUtil.get_dict(_monster_index(dir), id)
	var c := JsonUtil.get_array(meta, "cell")
	var path := dir.path_join(id + "_walk.webp")
	if c.size() != 2 or not ResourceLoader.exists(path):
		return null
	var s := ActorSheet.new()
	s.texture = load(path) as Texture2D
	s.cell = Vector2(float(c[0]), float(c[1]))
	s.foot = JsonUtil.get_float(meta, "foot", 4.0)
	s.scale = 1.0 / maxf(1.0, JsonUtil.get_float(cfg, "art_scale", 2.0))
	s.fps = JsonUtil.get_float(cfg, "walk_fps", 12.0)
	s.cols = JsonUtil.get_int(cfg, "cols", 5)
	s.stand = JsonUtil.get_int(cfg, "stand_col", 2)
	var cyc := JsonUtil.get_array(cfg, "walk_cycle")
	if not cyc.is_empty():
		s.cycle.clear()
		for v: Variant in cyc:
			s.cycle.append(clampi(int(v), 0, s.cols - 1))
	if s.texture == null or s.texture.get_width() < s.cell.x * s.cols or s.texture.get_height() < s.cell.y * 4:
		return null
	return s


static var _index_cache: Dictionary = {}


static func _monster_index(dir: String) -> Dictionary:
	if not _index_cache.has(dir):
		var path := dir.path_join("sheets.json")
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_index_cache[dir] = v if v is Dictionary else {}
	return _index_cache[dir]


## 월드 크기(발~칸 위).
func world_size() -> Vector2:
	return cell * scale


## 방향 → 줄. 대각선은 옆모습(피어 앤 헝거처럼 좌우를 우선).
static func row_for(facing: Vector2i) -> int:
	if facing.x < 0:
		return 1
	if facing.x > 0:
		return 2
	return 3 if facing.y < 0 else 0


## 걷기 시간 t(초)의 칸. walking이 아니면 섬.
func col_at(t: float, walking: bool) -> int:
	return cycle[int(t * fps) % cycle.size()] if walking and not cycle.is_empty() else stand


func draw(canvas: CanvasItem, facing: Vector2i, col: int, modulate: Color = Color.WHITE) -> void:
	var src := Rect2(col * cell.x, row_for(facing) * cell.y, cell.x, cell.y)
	var w := cell * scale
	canvas.draw_texture_rect_region(texture, Rect2(-w.x * 0.5, -(cell.y - foot) * scale, w.x, w.y), src, modulate)
