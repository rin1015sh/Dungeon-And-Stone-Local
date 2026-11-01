class_name Outline
extends RefCounted
## 상호작용 대상 검은 테두리(사용자 2026-11-01 "상호작용되는 요소들을 다른 사물들과 구분되게 살짝 — UI 강조선 말고 검은색으로", CT77).
##   Sprite2D·한 그림 노드 = material()(outline.gdshader — 그림 둘레 빈 픽셀을 검게),
##   여러 그림을 한 노드에 그리는 곳(탐험 소품·벽 소품·균열 물건) = polygon()·texture_rect(): 같은 그림을 검은 실루엣으로 여덟 방향 px만큼 비껴 먼저 그린다.
## 굵기 = render.json view.outline(texel = 셰이더 텍셀, world_px = 실루엣 비낌 세계 px), 색 = palette 없이 검정.

const SHADER := "res://assets/shaders/outline.gdshader"
const DIRS := [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071), Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071)]

static var _mats: Dictionary = {}  # 굵기 키 → 재질
static var _black := PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0)])  # floor_tex가 실루엣으로 알아본다


static func cfg(render: Dictionary, key: String, fallback: float) -> float:
	return JsonUtil.get_float(JsonUtil.get_dict(JsonUtil.get_dict(render, "view"), "outline"), key, fallback)


## 한 그림 노드용 재질(굵기 키마다 하나 — texel = 가구 그림, npc_texel = 사람 동작 그림).
static func material(render: Dictionary, key: String = "texel") -> ShaderMaterial:
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = load(SHADER) as Shader
		m.set_shader_parameter("width", cfg(render, key, 1.5))
		_mats[key] = m
	return _mats[key]


## draw_polygon 그림의 테두리(그 그림을 그리기 바로 전에 부른다). 꼭짓점 색 (0,0,0,0) = floor_tex 셰이더가 검은 실루엣으로 그린다(재질이 floor_tex인 노드에서만).
static func polygon(cv: CanvasItem, pts: PackedVector2Array, uvs: PackedVector2Array, tex: Texture2D, px: float) -> void:
	var moved := PackedVector2Array(pts)
	for d: Vector2 in DIRS:
		for i in pts.size():
			moved[i] = pts[i] + d * px
		cv.draw_polygon(moved, _black if pts.size() == 4 else PackedColorArray([Color(0, 0, 0, 0)]), uvs, tex)


## draw_texture_rect 그림의 테두리.
static func texture_rect(cv: CanvasItem, tex: Texture2D, r: Rect2, px: float) -> void:
	for d: Vector2 in DIRS:
		cv.draw_texture_rect(tex, Rect2(r.position + d * px, r.size), false, Color.BLACK)
