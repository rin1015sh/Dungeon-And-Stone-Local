class_name FloorTextures
extends RefCounted
## FloorView가 쓰는 그림 파일 읽기: 타일 재질 아틀라스(art.atlas)·소품 시트(art.prop)·데칼 시트(층 art.decor)·
## 재질 셰이더(floor_tex). 파일이 없으면 그 타일은 색칠한 칸으로 남는다. 그리기에서 칸마다 사전을 찾지 않게 타일 번호 배열로 둔다.

const TEX_SHADER := "res://assets/shaders/floor_tex.gdshader"
## 벽 타일 art.shape -> WallShape 모양(smooth = 1층 암벽 · round = 균열 자연 암벽 · bevel = 균열 지은 벽의 계단 사선만).
const WALL_SHAPES := {"smooth": WallShape.SMOOTH, "round": WallShape.ROUND, "bevel": WallShape.BEVEL}


static func load_into(v: FloorView, cfg: Dictionary) -> void:
	var map := v.map
	var n := map.defs.size()
	v.tile_tex.resize(n)
	v.prop_by_def.resize(n)
	v.smooth_by_def.resize(n)
	v.stand_by_def.resize(n)
	v.under_by_def.resize(n)
	v.blend_by_def.resize(n)
	v.stand_rect.resize(n)
	var bounds := {}  # 시트 경로 -> 칸마다 그림이 있는 네모(tools/sheet_bounds.py가 만든 <시트>.json)
	var any := false
	for i in n:
		var def := map.defs[i]
		if not def.art_atlas.is_empty() and def.art_variants > 0 and ResourceLoader.exists(def.art_atlas):
			v.tile_tex[i] = load(def.art_atlas) as Texture2D
			any = true
		if not def.prop_sheet.is_empty() and not v.prop_tex.has(def.prop_sheet) and ResourceLoader.exists(def.prop_sheet):
			v.prop_tex[def.prop_sheet] = load(def.prop_sheet) as Texture2D
			any = true
		if not def.stand_sheet.is_empty() and ResourceLoader.exists(def.stand_sheet):
			if not v.prop_tex.has(def.stand_sheet):
				v.prop_tex[def.stand_sheet] = load(def.stand_sheet) as Texture2D
			v.stand_by_def[i] = v.prop_tex[def.stand_sheet]
			if not bounds.has(def.stand_sheet):
				bounds[def.stand_sheet] = _sheet_bounds(def.stand_sheet, def.stand_cols, def.stand_rows)
			var bl: Array = bounds[def.stand_sheet]
			v.stand_rect[i] = bl[def.stand_cell] if def.stand_cell < bl.size() else Rect2(0, 0, 1, 1)
			any = true
		v.under_by_def[i] = map.index_of(def.stand_under) if not def.stand_under.is_empty() else -1
		v.smooth_by_def[i] = WALL_SHAPES.get(def.art_shape, 0) if def.is_wall() and v.tile_tex[i] != null else 0
		v.blend_by_def[i] = 1 if not def.is_wall() and def.art_shape == "smooth" and v.tile_tex[i] != null else 0
		v.blend_any = v.blend_any or v.blend_by_def[i] != 0
		v.smooth_any = v.smooth_any or v.smooth_by_def[i] != 0
	for i in n:
		v.prop_by_def[i] = v.prop_tex.get(map.defs[i].prop_sheet)
	v.decor = FloorDecor.compile(map, v.session.floor_def)
	v.tint.setup(map, v.session.floor_def)
	if not v.decor.is_empty() and ResourceLoader.exists(v.decor.sheet):
		v.decor_sheet = load(v.decor.sheet) as Texture2D
		any = true
	v.prop_highlight = JsonUtil.get_float(cfg, "prop_highlight", 1.15)
	v.outline_px = Outline.cfg(v.session.db.render, "world_px", 0.9)
	v.outline_skip = JsonUtil.get_array(JsonUtil.get_dict(JsonUtil.get_dict(v.session.db.render, "view"), "outline"), "skip_events")
	v.wall_skirt = JsonUtil.get_int(cfg, "wall_skirt_px", 0)
	v.wall_round = JsonUtil.get_float(cfg, "wall_round", 0.5)
	v.base_floor = map.index_of(JsonUtil.get_str(JsonUtil.get_dict(JsonUtil.get_dict(v.session.floor_def, "gen"), "tiles"), "floor", "cave_floor"))
	v.wall_bulge = JsonUtil.get_float(cfg, "wall_bulge", 0.06)
	WallDoors.configure(JsonUtil.get_dict(cfg, "door"))
	for i in n:
		if v.under_by_def[i] < 0:
			v.under_by_def[i] = v.base_floor
	v.abyss_material = Abyss.material(v.art, map, v.tile)
	apply_detail(v)
	if any:
		v.tex_material = ShaderMaterial.new()
		v.tex_material.shader = load(TEX_SHADER) as Shader
		v.memory_desat = v.art.memory_desat if v.art.memory_desat >= 0.0 else JsonUtil.get_float(cfg, "memory_desat", 0.65)
		v.tex_material.set_shader_parameter("memory_desat", v.memory_desat)
		v.fringe_material = FloorFringe.material(v)


## 서 있는 소품 시트의 칸마다 그림이 있는 네모(칸 비율). 시트 옆 json이 없거나 칸 수가 다르면 빈 목록(칸 전체를 그린다).
static func _sheet_bounds(sheet: String, cols: int, rows: int) -> Array:
	var path := sheet.get_basename() + ".json"
	if not FileAccess.file_exists(path):
		return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary or int((d as Dictionary).get("cols", 0)) != cols or int((d as Dictionary).get("rows", 0)) != rows:
		return []
	var out: Array = []
	for b: Variant in (d as Dictionary).get("bounds", []):
		var a: Array = b
		out.append(Rect2(float(a[0]), float(a[1]), float(a[2]) - float(a[0]), float(a[3]) - float(a[1])) if a.size() == 4 else Rect2(0, 0, 1, 1))
	return out


## 그래픽 품질 low면 데칼을 그리지 않는다(소품·재질 그림은 남긴다 — 상호작용 대상이 보여야 한다).
static func apply_detail(v: FloorView) -> void:
	v.decor_tex = null if v.art.low_quality else v.decor_sheet
