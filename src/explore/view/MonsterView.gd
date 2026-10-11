class_name MonsterView
extends Node2D
## 탐험 맵의 몬스터 무리 그림(대표 한 마리 + 무리 수 표시). 노드 원점 = 발 위치(y 정렬 기준).
## 스프라이트 파일(monsters/<id>.json sprite)이 있으면 그것을, 없으면 FigurePainter 임시 도형을 쓴다.

var group: FieldMonsters.Group
var facing: Vector2i = Vector2i(-1, 0)

var _shape: String = "humanoid"
var _scale: float = 1.0
var _color: Color = Color.GRAY
var _texture: Texture2D = null
var _count_label: Label


func setup(p_group: FieldMonsters.Group, db: GameDatabase) -> void:
	group = p_group
	var def := db.get_entry("monsters", group.leader())
	_shape = JsonUtil.get_str(def, "shape", "humanoid")
	_scale = JsonUtil.get_float(def, "size", 1.0)
	_color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
	var sprite := JsonUtil.get_str(def, "sprite")
	if not sprite.is_empty() and ResourceLoader.exists(sprite):
		_texture = load(sprite) as Texture2D
	if group.monster_ids.size() > 1:
		_count_label = UiTheme.label("×%d" % group.monster_ids.size(), "small", "warn")
		_count_label.position = Vector2(8, -52 * _scale)
		add_child(_count_label)


func face_toward(target: Vector2) -> void:
	var dir := Vector2i(1, 0) if target.x >= position.x else Vector2i(-1, 0)
	if dir != facing:
		facing = dir
		queue_redraw()


func _draw() -> void:
	if _texture != null:
		var sz := _texture.get_size()
		draw_texture(_texture, Vector2(-sz.x * 0.5, -sz.y))
		return
	FigurePainter.paint(self, _shape, _scale, _color, facing)
