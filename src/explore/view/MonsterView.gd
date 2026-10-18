class_name MonsterView
extends Node2D
## 탐험 맵의 몬스터 무리 그림(대표 한 마리 + 무리 수 표시). 노드 원점 = 발 위치(y 정렬 기준).
## 맵 그림(tools/paint_actors.gd → render.json view.actor_sheet.monster_dir/<id>.webp — 전투 일러스트를 데이터 size에 맞춰 줄인 정면)
## 이 있으면 그것을: 위로 걸어가면 뒷모습(<id>_back)이 있을 때 그것, 왼쪽으로 가면 좌우 반전, 걷는 동안 걸음마다 들썩이고
## 좌우로 기우뚱한다(걷기 그림 대신 — ASSUMPTIONS AM28). 없으면 monsters/<id>.json sprite, 그것도 없으면 FigurePainter 임시 도형.
## 보스가 기다리는 방(group.boss)은 그 보스의 기다리는 자세 그림(크게 — paint_actors MapMonster.BOSSES)을 그린다.

const BOB_PX := 1.5      ## 걸음마다 들썩이는 높이(월드 px)
const SWAY_RAD := 0.05   ## 좌우로 기우뚱하는 각도

var group: FieldMonsters.Group
var facing: Vector2i = Vector2i(-1, 0)

var _shape: String = "humanoid"
var _scale: float = 1.0
var _color: Color = Color.GRAY
var _texture: Texture2D = null
var _back: Texture2D = null
var _art_scale: float = 0.5
var _fps: float = 7.0
var _count_label: Label
var _walk_t: float = 0.0
var _still: float = 1.0
var _last_pos: Vector2 = Vector2.INF
var _up: bool = false


func setup(p_group: FieldMonsters.Group, db: GameDatabase) -> void:
	group = p_group
	var id := group.boss if not group.boss.is_empty() else group.leader()
	var def := db.get_entry("monsters", id)
	_shape = JsonUtil.get_str(def, "shape", "humanoid")
	_scale = JsonUtil.get_float(def, "size", 1.0)
	_color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
	var cfg := JsonUtil.get_dict(JsonUtil.get_dict(db.render, "view"), "actor_sheet")
	_art_scale = 1.0 / maxf(1.0, JsonUtil.get_float(cfg, "art_scale", 2.0))
	_fps = JsonUtil.get_float(cfg, "walk_fps", 7.0)
	var dir := JsonUtil.get_str(cfg, "monster_dir", "res://assets/actors/monsters")
	for path: String in [dir.path_join(id + ".webp"), JsonUtil.get_str(def, "sprite")]:
		if not path.is_empty() and ResourceLoader.exists(path):
			_texture = load(path) as Texture2D
			break
	var back := dir.path_join(id + "_back.webp")
	if ResourceLoader.exists(back):
		_back = load(back) as Texture2D
	if group.monster_ids.size() > 1:
		_count_label = UiTheme.label("×%d" % group.monster_ids.size(), "small", "warn")
		var top := _texture.get_height() * _art_scale if _texture != null else 52.0 * _scale
		_count_label.position = Vector2(8, -top - 4)
		add_child(_count_label)


func face_toward(target: Vector2) -> void:
	var dir := Vector2i(1, 0) if target.x >= position.x else Vector2i(-1, 0)
	if dir != facing:
		facing = dir
		queue_redraw()


func _process(delta: float) -> void:
	if _texture == null:
		return
	if position != _last_pos and _last_pos != Vector2.INF:
		_up = position.y < _last_pos.y - 0.01 and absf(position.y - _last_pos.y) > absf(position.x - _last_pos.x)
		_walk_t += delta
		_still = 0.0
		queue_redraw()
	elif _still < 0.2:
		_still += delta
		if _still >= 0.12:
			queue_redraw()  # 멈추면 바로 선다
	_last_pos = position


func _draw() -> void:
	if _texture == null:
		FigurePainter.paint(self, _shape, _scale, _color, facing)
		return
	var tex := _back if _up and _back != null else _texture
	var sz := tex.get_size() * _art_scale
	var walking := _still < 0.12
	var ph := _walk_t * _fps * PI
	var bob := absf(sin(ph)) * BOB_PX if walking else 0.0
	var sway := sin(ph) * SWAY_RAD if walking else 0.0
	draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.35), 0.0, Vector2(0, -1)))  # 발밑 그림자
	draw_circle(Vector2.ZERO, sz.x * 0.32, Color(0, 0, 0, 0.45))
	var flip := -1.0 if facing.x < 0 else 1.0
	draw_set_transform_matrix(Transform2D(sway, Vector2(flip, 1.0), 0.0, Vector2(0, -bob)))
	draw_texture_rect(tex, Rect2(-sz.x * 0.5, -sz.y, sz.x, sz.y), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
