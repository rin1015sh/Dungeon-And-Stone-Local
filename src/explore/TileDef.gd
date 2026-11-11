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
var art_shape: String = ""      ## 벽: "smooth" = 부드러운 암벽(WallShape — 둥근 윤곽, 윗면은 검게, 남쪽 앞면만) · "round" = 같은 윤곽 + 벽 그림 윗면(균열 자연 암벽) · "bevel" = 계단만 곧은 사선(균열 지은 벽). 바닥: "smooth" = 가장자리 사선(물)
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
var is_rise: bool = false       ## 솟은 외곽(void + "rise": true): 낭떠러지 대신 위로 솟은 벽·절벽 면과 그 너머 풍경(Abyss rise — 균열 지도 바깥 둘레)
var void_edge: String = ""      ## 허공에 닿는 가장자리(art.void_edge): "" = 들쭉날쭉 깎인 땅, "beam" = 나무 발판(곧은 들보 면 + 난간)
var art_doors: PackedStringArray = PackedStringArray()  ## 이 벽에 뚫린 문의 모양 후보(art.doors — DoorArt: square·round·pointed·gate·rough·cave·timber)
var art_top_tex: bool = false  ## 모양 벽(art.shape)의 윗면을 검게 대신 아틀라스 윗줄 그림으로(art.top_tex — 망자의 땅 덤불 둔덕, FL11)
var art_directional: bool = false  ## 한 방향 무늬(art.directional — 철로): 세로로 더 길게 이어진 칸은 그림을 90° 돌린다(FloorChunk)
var ramp: bool = false          ## 높은 땅 ↔ 낮은 땅(sunk) 사이 비탈 · 계단(art.ramp — 물가 절벽을 그리지 않는다, FieldsRouteBuild.levels — FL12)
var sunk: bool = false          ## 땅보다 낮은 물(art.sunk — 핏물 해자): 그 위를 건너는 나무 발판(void_edge "beam")은 낭떠러지 위처럼 들보 면·그림자·받침·난간(VoidChunk)
var move_mult: float = 1.0       ## 이 칸에서 걷는 빠르기 배율(진창 0.7 — 망자의 땅, floor2.md §3). 몬스터 behavior.mud_walker면 무시
var art_span: int = 0          ## 넓은 재질 그림(art.span — 아틀라스 한 장이 span × span 칸을 덮는 이어지는 그림, 칸 좌표로 자른다): 칸마다 같은 무늬가 되풀이되지 않는다(AM64)
var fringe: int = 0            ## 바닥 재질 번짐 순위(art.fringe — 0 = 없음, art.span 재질만): 맞닿은 순위 높은 재질이 이 칸으로 들쭉날쭉 스며든다(FloorFringe)
var fringe_style: int = 0      ## 번짐 띠 생김새(art.fringe_style — 0 흙 · 1 풀 · 2 깨진 돌 · 3 모래, 띠 그림 fringe_mask.webp의 줄 묶음)
var ground_around: bool = false ## 바닥 그림을 둘레 바닥에서 빌린다(art.ground "around" — 포탈 · 동굴 요소 칸이 네모나게 뜨지 않게)
var art_overlay: bool = false  ## 이 타일의 아틀라스는 투명 덧그림(art.overlay — 올가미 · 금 간 자리): 둘레 바닥 위에 얹는다(ground "around"와 함께)
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
	t.move_mult = clampf(JsonUtil.get_float(d, "move_mult", 1.0), 0.1, 2.0)
	var light := JsonUtil.get_dict(d, "light")
	t.light_radius_m = JsonUtil.get_float(light, "radius_m")
	t.light_color = Color.from_string(JsonUtil.get_str(light, "color"), Color.WHITE)
	t.light_intensity = JsonUtil.get_float(light, "intensity", 1.0)
	t.interact = JsonUtil.get_str(d, "interact")
	t.scavenge = JsonUtil.get_str(d, "scavenge")
	t.is_void = JsonUtil.get_bool(d, "void")
	t.is_rise = t.is_void and JsonUtil.get_bool(d, "rise")
	t.sprite = JsonUtil.get_str(d, "sprite")
	var art := JsonUtil.get_dict(d, "art")
	t.art_atlas = JsonUtil.get_str(art, "atlas")
	t.art_variants = JsonUtil.get_int(art, "variants", 0)
	t.art_salt = t.id.hash()
	t.art_shape = JsonUtil.get_str(art, "shape")
	t.art_top_tex = JsonUtil.get_bool(art, "top_tex")
	t.void_edge = JsonUtil.get_str(art, "void_edge")
	t.sunk = JsonUtil.get_bool(art, "sunk")
	t.ramp = JsonUtil.get_bool(art, "ramp")
	t.art_span = JsonUtil.get_int(art, "span", 0)
	t.fringe = JsonUtil.get_int(art, "fringe", 0)
	t.fringe_style = JsonUtil.get_int(art, "fringe_style", 0)
	t.art_overlay = JsonUtil.get_bool(art, "overlay")
	t.ground_around = t.art_overlay or JsonUtil.get_str(art, "ground") == "around"
	t.art_directional = JsonUtil.get_bool(art, "directional")
	for k: Variant in JsonUtil.get_array(art, "doors"):
		t.art_doors.append(str(k))
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
