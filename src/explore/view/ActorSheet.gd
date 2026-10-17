class_name ActorSheet
extends RefCounted
## 탐험 맵 몸 그림 시트(tools/paint_actors.gd → assets/actors/<종족>.webp): 줄 = 아래·왼쪽·오른쪽·위, 칸 = 걸음 A·섬·걸음 B.
## 칸 크기·그림 배율·발 위치·걷기 속도는 render.json view.actor_sheet. 원점 = 발.
## 걷는 동안 칸 순서 [A, 섬, B, 섬]을 walk_fps로 돌고, 멈추면 섬.

const WALK_CYCLE := [0, 1, 2, 1]
const STAND := 1

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
	s.fps = JsonUtil.get_float(cfg, "walk_fps", 7.0)
	if s.texture == null or s.texture.get_width() < s.cell.x * 3 or s.texture.get_height() < s.cell.y * 4:
		return null
	return s


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
	return int(WALK_CYCLE[int(t * fps) % WALK_CYCLE.size()]) if walking else STAND


func draw(canvas: CanvasItem, facing: Vector2i, col: int, modulate: Color = Color.WHITE) -> void:
	var src := Rect2(col * cell.x, row_for(facing) * cell.y, cell.x, cell.y)
	var w := cell * scale
	canvas.draw_texture_rect_region(texture, Rect2(-w.x * 0.5, -(cell.y - foot) * scale, w.x, w.y), src, modulate)
