extends RefCounted
## 탐험 맵 재질 아틀라스 설계(tools/paint_floor.gd). 한 항목 = 아틀라스 한 장.
##   path     결과 WebP(data/tiles.json art.atlas가 같은 경로를 가리킨다)
##   style    Cave.gd 재질(limestone · rock · crystal · water · mud)
##   kind     floor(한 줄 — 변형 칸) / wall(윗면 줄 + 앞면 줄)
##   tile     평균 색을 맞출 타일 id(data/tiles.json colors — 그림 평균 = 그 색, 빛은 게임이 곱한다)
##   variants 한 줄의 변형 수(짝수 — FloorArtLayer), seed 칠 시드
##   painter  marks면 Marks.gd(랜드마크 전용 그림), 없으면 Cave.gd   face_px 벽 앞면 높이(타일 face_px와 같게 — 없으면 render.json 기본)
## --only=<장소|style>로 일부만(예: --only=f1, --only=crystal, --only=decals).
## DECALS = 데칼 시트(Decals.gd): 줄 = kinds 순서(층 JSON art.decor.kinds와 같아야 한다 — 테스트가 본다), 칸 = 변형.

const ATLASES := [
	{"place": "f1", "path": "res://assets/floor/f1/limestone.webp", "style": "limestone", "kind": "floor", "tile": "cave_floor", "variants": 8, "seed": 101},
	{"place": "f1", "path": "res://assets/floor/f1/rock.webp", "style": "rock", "kind": "wall", "tile": "rock_wall", "variants": 6, "seed": 201},
	{"place": "f1", "path": "res://assets/floor/f1/crystal.webp", "style": "crystal", "kind": "wall", "tile": "crystal_wall", "variants": 6, "seed": 301},
	{"place": "f1", "path": "res://assets/floor/f1/water.webp", "style": "water", "kind": "floor", "tile": "pond_water", "variants": 6, "seed": 401},
	{"place": "f1", "path": "res://assets/floor/f1/mud.webp", "style": "mud", "kind": "floor", "tile": "feat_mud", "variants": 6, "seed": 501},
	{"place": "f1", "path": "res://assets/floor/f1/boulder.webp", "style": "rock", "kind": "wall", "tile": "boulder", "variants": 2, "seed": 921, "face_px": 14},
	{"place": "f1", "path": "res://assets/floor/f1/monument.webp", "style": "monument", "painter": "marks", "kind": "wall", "tile": "monument", "variants": 2, "seed": 901, "face_px": 40},
	{"place": "f1", "path": "res://assets/floor/f1/square_crystal.webp", "style": "square_crystal", "painter": "marks", "kind": "wall", "tile": "square_crystal", "variants": 2, "seed": 911, "face_px": 28},
]

const DECALS := [
	{"place": "f1", "path": "res://assets/floor/f1/decals.webp", "style": "decals", "variants": 4, "seed": 701,
		"kinds": ["shore", "gravel", "moss", "wet", "crystal_bits", "claws", "mud", "rot", "trash", "bones"]},
]


## 소품 시트(Props.gd — tiles.json art.prop.cell = Props.ORDER 번호): 칸 = 바닥 칸 × art_scale × 1.5, 가로 cols칸.
const PROPS := [
	{"place": "f1", "path": "res://assets/floor/f1/props.webp", "style": "props", "cols": 8, "seed": 1001, "size": 1.5},
]
