class_name ActorView
extends Node2D
## 캐릭터 그림(4방향). 노드 원점 = 발 위치(y 정렬 기준).
## 스프라이트 파일(종족 sprite)이 있으면 가로로 [아래, 왼쪽, 오른쪽, 위] 4프레임 시트로 쓰고,
## 없으면 임시 도형(머리·몸·다리 + 방향 표시)을 그린다.
## 남쪽 벽에 가려지면 맨 위에 반투명 실루엣(_ghost)을 겹쳐 위치를 잃지 않게 한다.
## 횃불을 들면 손에 불꽃을 그리고, PointLight2D로 따뜻한 빛 번짐을 더한다.

const FRAME_ORDER: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
const GLOW_TEXTURE_SIZE := 256

var facing: Vector2i = Vector2i(0, 1)
var body_color: Color = Color(0.7, 0.6, 0.5)
var size: Vector2 = Vector2(32, 48)
var holding_torch: bool = false

var _texture: Texture2D = null
var _ghost: Node2D
var _glow: PointLight2D
var _camera: Camera2D
var _tween: Tween
var _glow_energy: float = 0.35
var _flicker: float = 0.06
var _time: float = 0.0


func setup_for(actor: Actor, render: Dictionary) -> void:
	var view := JsonUtil.get_dict(render, "view")
	var lighting := JsonUtil.get_dict(render, "lighting")
	var px := JsonUtil.get_array(view, "actor_sprite_px")
	if px.size() == 2:
		size = Vector2(float(px[0]), float(px[1]))
	var race := {}
	if actor is PlayerCharacter:
		race = actor.db.get_entry("races", (actor as PlayerCharacter).race_id)
	body_color = Color.from_string(JsonUtil.get_str(race, "color"), body_color)
	var sprite := JsonUtil.get_str(race, "sprite")
	if not sprite.is_empty() and ResourceLoader.exists(sprite):
		_texture = load(sprite) as Texture2D
	_glow_energy = JsonUtil.get_float(lighting, "torch_glow_energy", 0.35)
	_flicker = JsonUtil.get_float(lighting, "torch_flicker", 0.06)
	_ghost = _GhostNode.new()
	_ghost.z_index = 100
	_ghost.modulate = Color(0.75, 0.8, 1.0, JsonUtil.get_float(view, "occluded_actor_alpha", 0.4))
	_ghost.visible = false
	add_child(_ghost)
	_glow = PointLight2D.new()
	_glow.texture = _make_glow_texture()
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.position = Vector2(0, -size.y * 0.5)
	add_child(_glow)
	_camera = Camera2D.new()
	var zoom := JsonUtil.get_float(view, "camera_zoom", 2.0)
	_camera.zoom = Vector2(zoom, zoom)
	_camera.position = Vector2(0, -size.y * 0.4)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 10.0
	add_child(_camera)


func _process(delta: float) -> void:
	if _glow == null or not _glow.enabled:
		return
	_time += delta
	_glow.energy = _glow_energy * (1.0 + sin(_time * 11.0) * _flicker + sin(_time * 23.7) * _flicker * 0.5)


func face(dir: Vector2i) -> void:
	if dir != Vector2i.ZERO and dir != facing:
		facing = dir
		_redraw_all()


func move_to(target: Vector2, seconds: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if seconds <= 0.0 or not is_inside_tree():
		position = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "position", target, seconds)


func set_occluded(on: bool) -> void:
	if _ghost != null:
		_ghost.visible = on


## 빛: 횃불이면 손에 불꽃 + 따뜻한 빛 번짐. radius_px = 시야 반경(px).
func set_light(color: Color, torch: bool, radius_px: float) -> void:
	if holding_torch != torch:
		holding_torch = torch
		_redraw_all()
	_glow.enabled = torch
	_glow.color = color
	_glow.texture_scale = maxf(0.1, radius_px / (GLOW_TEXTURE_SIZE * 0.5))


func _draw() -> void:
	paint(self, false)


## canvas에 캐릭터를 그린다. silhouette이면 그림자·불꽃 없이 단색 윤곽만.
func paint(canvas: CanvasItem, silhouette: bool) -> void:
	if _texture != null:
		var frame := maxi(0, FRAME_ORDER.find(facing))
		var src := Rect2(frame * size.x, 0, size.x, size.y)
		canvas.draw_texture_rect_region(_texture, Rect2(-size.x * 0.5, -size.y, size.x, size.y), src,
			Color.WHITE if not silhouette else Color(1, 1, 1, 1))
		return
	FigurePainter.paint(canvas, "humanoid", size.y / 48.0, body_color, facing, silhouette, holding_torch)


func _redraw_all() -> void:
	queue_redraw()
	if _ghost != null:
		_ghost.queue_redraw()


static func _make_glow_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = GLOW_TEXTURE_SIZE
	tex.height = GLOW_TEXTURE_SIZE
	return tex


## 가려졌을 때 맨 위에 겹치는 실루엣(부모의 paint를 빌려 그린다).
class _GhostNode extends Node2D:
	func _draw() -> void:
		(get_parent() as ActorView).paint(self, true)
