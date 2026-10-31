class_name NpcActSheet
extends RefCounted
## 도시 실내 사람의 동작 그림(tools/paint_actors.gd --acts → assets/actors/acts/<옷차림>__<동작>.webp + index.json — CT69):
## 줄 = 아래·왼쪽·오른쪽·위(ActorSheet.row_for), 칸 = 동작 칸. index.json {이름: {cell, foot, frames, seq(재생 칸 순서), fps}}. 원점 = 발.

const DIR := "res://assets/actors/acts"

var texture: Texture2D
var cell: Vector2 = Vector2(72, 108)
var foot: float = 4.0
var seq: Array[int] = [0]
var fps: float = 3.0
var scale: float = 0.5

static var _index: Dictionary = {}
static var _index_read: bool = false


## look = 몸 그림 경로(looks/<id>.webp 또는 종족 시트), act = 동작 id. 그림이 없으면 null.
static func load_for(render: Dictionary, look: String, act: String) -> NpcActSheet:
	if act.is_empty() or look.is_empty():
		return null
	var key := look.get_file().get_basename() + "__" + act
	var meta := JsonUtil.get_dict(_meta(), key)
	var path := DIR.path_join(key + ".webp")
	var c := JsonUtil.get_array(meta, "cell")
	if c.size() != 2 or not ResourceLoader.exists(path):
		return null
	var s := NpcActSheet.new()
	s.texture = load(path) as Texture2D
	s.cell = Vector2(float(c[0]), float(c[1]))
	s.foot = JsonUtil.get_float(meta, "foot", 4.0)
	s.fps = maxf(0.1, JsonUtil.get_float(meta, "fps", 3.0))
	var frames := maxi(1, JsonUtil.get_int(meta, "frames", 1))
	s.seq.clear()
	for v: Variant in JsonUtil.get_array(meta, "seq"):
		s.seq.append(clampi(int(v), 0, frames - 1))
	if s.seq.is_empty():
		s.seq.append(0)
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "actor_sheet")
	s.scale = 1.0 / maxf(1.0, JsonUtil.get_float(cfg, "art_scale", 2.0))
	if s.texture == null or s.texture.get_width() < s.cell.x * frames or s.texture.get_height() < s.cell.y * 4:
		return null
	return s


static func _meta() -> Dictionary:
	if not _index_read:
		_index_read = true
		var path := DIR.path_join("index.json")
		var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {}
		_index = v if v is Dictionary else {}
	return _index


## 시간 t(초)의 칸.
func col_at(t: float) -> int:
	return seq[int(t * fps) % seq.size()]


func world_size() -> Vector2:
	return cell * scale


func draw(canvas: CanvasItem, facing: Vector2i, col: int) -> void:
	var src := Rect2(col * cell.x, ActorSheet.row_for(facing) * cell.y, cell.x, cell.y)
	var w := cell * scale
	canvas.draw_texture_rect_region(texture, Rect2(-w.x * 0.5, -(cell.y - foot) * scale, w.x, w.y), src)
