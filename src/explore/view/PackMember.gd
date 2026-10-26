class_name PackMember
extends RefCounted
## 탐험 맵 무리 그림의 한 마리(MonsterView가 무리 대형으로 늘어놓는다 — 사용자 2026-10-26 "×N 대신 몇 마리인지·무슨 몬스터인지 보이게").
## 걷기 시트(ActorSheet — 걸으면 가는 쪽, 멈추면 플레이어 쪽) / 한 장 그림(걸음마다 들썩이고 기우뚱 — 위로 가면 뒷모습, 왼쪽이면 좌우 반전, AM28)
## / 보스가 방에서 기다리는 자세(크게 — paint_actors MapMonster.BOSSES) / 그림이 없으면 FigurePainter 임시 도형.

const BOB_PX := 1.5      ## 걸음마다 들썩이는 높이(월드 px)
const SWAY_RAD := 0.05   ## 좌우로 기우뚱하는 각도

var id: String = ""
var sheet: ActorSheet = null
var texture: Texture2D = null
var back: Texture2D = null
var shape: String = "humanoid"
var scale: float = 1.0
var color: Color = Color.GRAY
var tint: Color = Color.WHITE
var art_scale: float = 0.5
var fps: float = 7.0


## 몬스터 한 마리. idle = 보스가 기다리는 자세(걷기 시트를 쓰지 않는다).
static func for_monster(db: GameDatabase, monster_id: String, idle: bool) -> PackMember:
	var m := PackMember.new()
	m.id = monster_id
	var def := db.get_entry("monsters", monster_id)
	m.shape = JsonUtil.get_str(def, "shape", "humanoid")
	m.scale = JsonUtil.get_float(def, "size", 1.0)
	m.color = Color.from_string(JsonUtil.get_str(def, "color"), Color.GRAY)
	m._read_cfg(db.render)
	var dir := JsonUtil.get_str(_cfg(db.render), "monster_dir", "res://assets/actors/monsters")
	if not idle:
		m.sheet = ActorSheet.load_monster(db.render, monster_id)
	for path: String in [dir.path_join(monster_id + ".webp"), JsonUtil.get_str(def, "sprite")]:
		if not path.is_empty() and ResourceLoader.exists(path):
			m.texture = load(path) as Texture2D
			break
	var back_path := dir.path_join(monster_id + "_back.webp")
	if ResourceLoader.exists(back_path):
		m.back = load(back_path) as Texture2D
	return m


## 사람 몸 시트 한 장(탐험가·약탈자).
static func for_sheet(db: GameDatabase, p_sheet: ActorSheet, p_tint: Color = Color.WHITE) -> PackMember:
	var m := PackMember.new()
	m.sheet = p_sheet
	m.tint = p_tint
	m._read_cfg(db.render)
	return m


static func _cfg(render: Dictionary) -> Dictionary:
	return JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "actor_sheet")


func _read_cfg(render: Dictionary) -> void:
	art_scale = 1.0 / maxf(1.0, JsonUtil.get_float(_cfg(render), "art_scale", 2.0))
	fps = JsonUtil.get_float(_cfg(render), "walk_fps", 7.0)


## 월드 크기(발 ~ 머리).
func size() -> Vector2:
	if sheet != null:
		return sheet.world_size()
	if texture != null:
		return texture.get_size() * art_scale
	return Vector2(32.0, 52.0) * scale


func has_art() -> bool:
	return sheet != null or texture != null


## at(발, 노드 좌표)에 그린다. walk_t = 걸은 시간(마리마다 조금씩 어긋나게 받는다).
func draw(c: CanvasItem, at: Vector2, facing: Vector2i, walk_t: float, walking: bool, up: bool) -> void:
	if sheet != null:
		_shadow(c, at, sheet.world_size().x * 0.3)
		c.draw_set_transform(at)
		sheet.draw(c, facing, sheet.col_at(walk_t, walking), tint)
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	if texture == null:
		c.draw_set_transform(at)
		FigurePainter.paint(c, shape, scale, color, facing)
		c.draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var tex := back if up and back != null else texture
	var sz := tex.get_size() * art_scale
	var ph := walk_t * fps * PI
	var bob := absf(sin(ph)) * BOB_PX if walking else 0.0
	var sway := sin(ph) * SWAY_RAD if walking else 0.0
	_shadow(c, at, sz.x * 0.32)
	var flip := -1.0 if facing.x < 0 else 1.0
	c.draw_set_transform_matrix(Transform2D(sway, Vector2(flip, 1.0), 0.0, at + Vector2(0, -bob)))
	c.draw_texture_rect(tex, Rect2(-sz.x * 0.5, -sz.y, sz.x, sz.y), false, tint)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _shadow(c: CanvasItem, at: Vector2, r: float) -> void:
	c.draw_set_transform_matrix(Transform2D(0.0, Vector2(1.0, 0.35), 0.0, at + Vector2(0, -1)))
	c.draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.45))
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
