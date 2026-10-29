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
var scavenge: String = ""  ## 균열 장식 잡템 표(data/scavenge.json id) — 옆에서 살피면 한 번 뒤진다(RiftScavenge, RF19)
var sprite: String = ""
var art_atlas: String = ""      ## 재질 아틀라스(tools/paint_floor.gd → assets/floor). 바닥 = 한 줄에 변형, 벽 = 윗면 줄 + 앞면 줄
var art_variants: int = 0       ## 아틀라스 한 줄의 변형 수(짝수 — FloorArtLayer)
var art_shape: String = ""      ## "smooth" = 부드러운 암벽(WallShape — 둥근 윤곽, 윗면은 검게, 남쪽 앞면만)
var prop_sheet: String = ""     ## 소품 그림 시트(art.prop — 동굴 요소·포탈: 바닥 위에 얹는 그림, 마름모 대신)
var prop_cell: int = 0          ## 시트 칸 번호(왼쪽 위부터 가로로)
var prop_cols: int = 0          ## 시트 가로 칸 수(0 = 정사각 칸으로 계산)
var prop_size: float = 1.0      ## 그리는 크기(칸 단위 — 아래 끝이 칸 아래쪽)
var stand_sheet: String = ""    ## 서 있는 소품 그림 시트(art.stand — 균열 탁자·무기대·광차…): 벽 덩어리 대신 그림, 캐릭터와 y 정렬
var stand_cell: int = 0         ## 시트 칸 번호(왼쪽 위부터 가로로)
var stand_cols: int = 1         ## 시트 가로 칸 수
var stand_rows: int = 1         ## 시트 세로 칸 수
var stand_size: Vector2 = Vector2.ONE  ## 그리는 크기(칸 단위 — 아래 가운데 = 칸 아래쪽 가운데)
var stand_under: String = ""    ## 소품 밑 바닥 타일(없으면 층 기본 바닥)
var is_void: bool = false       ## 낭떠러지·구덩이(균열 — "void": true): 바닥을 그리지 않고 절벽 면·어둠을 칠한다(Abyss)
var void_edge: String = ""      ## 허공에 닿는 가장자리(art.void_edge): "" = 들쭉날쭉 깎인 땅, "beam" = 나무 발판(곧은 들보 면 + 난간)
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
	t.scavenge = JsonUtil.get_str(d, "scavenge")
	t.is_void = JsonUtil.get_bool(d, "void")
	t.sprite = JsonUtil.get_str(d, "sprite")
	var art := JsonUtil.get_dict(d, "art")
	t.art_atlas = JsonUtil.get_str(art, "atlas")
	t.art_variants = JsonUtil.get_int(art, "variants", 0)
	t.art_salt = t.id.hash()
	t.art_shape = JsonUtil.get_str(art, "shape")
	t.void_edge = JsonUtil.get_str(art, "void_edge")
	var prop := JsonUtil.get_dict(art, "prop")
	t.prop_sheet = JsonUtil.get_str(prop, "sheet")
	t.prop_cell = JsonUtil.get_int(prop, "cell", 0)
	t.prop_cols = JsonUtil.get_int(prop, "cols", 0)
	t.prop_size = JsonUtil.get_float(prop, "size", 1.0)
	var stand := JsonUtil.get_dict(art, "stand")
	t.stand_sheet = JsonUtil.get_str(stand, "sheet")
	t.stand_cell = JsonUtil.get_int(stand, "cell", 0)
	t.stand_cols = maxi(1, JsonUtil.get_int(stand, "cols", 1))
	t.stand_rows = maxi(1, JsonUtil.get_int(stand, "rows", 1))
	var sz := JsonUtil.get_array(stand, "size")
	t.stand_size = Vector2(float(sz[0]), float(sz[1])) if sz.size() == 2 else Vector2.ONE
	t.stand_under = JsonUtil.get_str(stand, "under")
	return t


func is_wall() -> bool:
	return kind == "wall"


func emits_light() -> bool:
	return light_radius_m > 0.0
