class_name TileDef
extends RefCounted
## 타일 정의(data/tiles.json 한 항목).
## kind: floor(평평함) / wall(높이가 있어 윗면·앞면이 보이는 덩어리).
## 이동·시야 판정은 바닥 평면 기준(walkable, blocks_sight). 높이는 그리기에만 쓴다.

var index: int = 0
var id: String = ""
var name_ko: String = ""
var kind: String = "floor"
var walkable: bool = true
var blocks_sight: bool = false
var color_floor: Color = Color.DIM_GRAY
var color_top: Color = Color.GRAY
var color_face: Color = Color.DIM_GRAY
var color_mark: Color = Color.TRANSPARENT
var face_px: int = -1           ## 앞면 높이(px). -1이면 render.json 기본값
var light_radius_m: float = 0.0
var light_color: Color = Color.WHITE
var light_intensity: float = 1.0
var interact: String = ""       ## portal / monument … (탐험 상호작용 종류)
var sprite: String = ""
var art_atlas: String = ""      ## 재질 아틀라스(tools/paint_floor.gd → assets/floor). 바닥 = 한 줄에 변형, 벽 = 윗면 줄 + 앞면 줄
var art_variants: int = 0       ## 아틀라스 한 줄의 변형 수(짝수 — FloorArtLayer)
var art_salt: int = 0           ## 변형 고르기 해시 소금(id에서 — 타일 순서를 바꿔도 그림이 그대로)


static func from_dict(d: Dictionary, p_index: int) -> TileDef:
	var t := TileDef.new()
	t.index = p_index
	t.id = JsonUtil.get_str(d, "id")
	t.name_ko = JsonUtil.get_str(d, "name_ko", t.id)
	t.kind = JsonUtil.get_str(d, "kind", "floor")
	t.walkable = JsonUtil.get_bool(d, "walkable", t.kind == "floor")
	t.blocks_sight = JsonUtil.get_bool(d, "blocks_sight", t.kind == "wall")
	var colors := JsonUtil.get_dict(d, "colors")
	t.color_floor = Color.from_string(JsonUtil.get_str(colors, "floor"), t.color_floor)
	t.color_top = Color.from_string(JsonUtil.get_str(colors, "top"), t.color_top)
	t.color_face = Color.from_string(JsonUtil.get_str(colors, "face"), t.color_face)
	t.color_mark = Color.from_string(JsonUtil.get_str(colors, "mark"), Color.TRANSPARENT)
	t.face_px = JsonUtil.get_int(d, "face_px", -1)
	var light := JsonUtil.get_dict(d, "light")
	t.light_radius_m = JsonUtil.get_float(light, "radius_m")
	t.light_color = Color.from_string(JsonUtil.get_str(light, "color"), Color.WHITE)
	t.light_intensity = JsonUtil.get_float(light, "intensity", 1.0)
	t.interact = JsonUtil.get_str(d, "interact")
	t.sprite = JsonUtil.get_str(d, "sprite")
	var art := JsonUtil.get_dict(d, "art")
	t.art_atlas = JsonUtil.get_str(art, "atlas")
	t.art_variants = JsonUtil.get_int(art, "variants", 0)
	t.art_salt = t.id.hash()
	return t


func is_wall() -> bool:
	return kind == "wall"


func emits_light() -> bool:
	return light_radius_m > 0.0
