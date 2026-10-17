class_name FloorTextures
extends RefCounted
## FloorView가 쓰는 그림 파일 읽기: 타일 재질 아틀라스(art.atlas)·소품 시트(art.prop)·벽 턱(art.rim)·데칼 시트(층 art.decor)·
## 재질 셰이더(floor_tex). 파일이 없으면 그 타일은 색칠한 칸으로 남는다. 그리기에서 칸마다 사전을 찾지 않게 타일 번호 배열로 둔다.

const TEX_SHADER := "res://assets/shaders/floor_tex.gdshader"


static func load_into(v: FloorView, cfg: Dictionary) -> void:
	var map := v.map
	var n := map.defs.size()
	v.tile_tex.resize(n)
	v.prop_by_def.resize(n)
	v.rim_by_def.resize(n)
	var any := false
	for i in n:
		var def := map.defs[i]
		if not def.art_atlas.is_empty() and def.art_variants > 0 and ResourceLoader.exists(def.art_atlas):
			v.tile_tex[i] = load(def.art_atlas) as Texture2D
			any = true
		for ps: String in [def.prop_sheet, def.rim_sheet]:
			if not ps.is_empty() and not v.prop_tex.has(ps) and ResourceLoader.exists(ps):
				v.prop_tex[ps] = load(ps) as Texture2D
				any = true
	for i in n:
		v.prop_by_def[i] = v.prop_tex.get(map.defs[i].prop_sheet)
	v.decor = FloorDecor.compile(map, v.session.floor_def)
	v.tint.setup(map, v.session.floor_def)
	if not v.decor.is_empty() and ResourceLoader.exists(v.decor.sheet):
		v.decor_sheet = load(v.decor.sheet) as Texture2D
		any = true
	v.prop_highlight = JsonUtil.get_float(cfg, "prop_highlight", 1.15)
	v.wall_skirt = JsonUtil.get_int(cfg, "wall_skirt_px", 0)
	v.rim_out = JsonUtil.get_float(cfg, "wall_rim_out", 0.2)
	v.rim_in = JsonUtil.get_float(cfg, "wall_rim_in", 0.18)
	apply_detail(v)
	if any:
		v.tex_material = ShaderMaterial.new()
		v.tex_material.shader = load(TEX_SHADER) as Shader
		v.tex_material.set_shader_parameter("memory_desat", JsonUtil.get_float(cfg, "memory_desat", 0.65))


## 그래픽 품질 low면 데칼·벽 턱을 그리지 않는다(소품·재질 그림은 남긴다 — 상호작용 대상이 보여야 한다).
static func apply_detail(v: FloorView) -> void:
	var low := v.art.low_quality
	v.decor_tex = null if low else v.decor_sheet
	for i in v.map.defs.size():
		v.rim_by_def[i] = null if low else v.prop_tex.get(v.map.defs[i].rim_sheet)
