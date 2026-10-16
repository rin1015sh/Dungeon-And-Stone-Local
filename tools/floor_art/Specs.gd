extends RefCounted
## 탐험 맵 재질 아틀라스 설계(tools/paint_floor.gd). 한 항목 = 아틀라스 한 장.
##   path     결과 WebP(data/tiles.json art.atlas가 같은 경로를 가리킨다)
##   style    Cave.gd 재질(limestone · rock · crystal · water · mud)
##   kind     floor(한 줄 — 변형 칸) / wall(윗면 줄 + 앞면 줄)
##   tile     평균 색을 맞출 타일 id(data/tiles.json colors — 그림 평균 = 그 색, 빛은 게임이 곱한다)
##   variants 한 줄의 변형 수(짝수 — FloorArtLayer), seed 칠 시드
## --only=<장소|style>로 일부만(예: --only=f1, --only=crystal).

const ATLASES := [
	{"place": "f1", "path": "res://assets/floor/f1/limestone.webp", "style": "limestone", "kind": "floor", "tile": "cave_floor", "variants": 8, "seed": 101},
	{"place": "f1", "path": "res://assets/floor/f1/rock.webp", "style": "rock", "kind": "wall", "tile": "rock_wall", "variants": 6, "seed": 201},
	{"place": "f1", "path": "res://assets/floor/f1/crystal.webp", "style": "crystal", "kind": "wall", "tile": "crystal_wall", "variants": 6, "seed": 301},
	{"place": "f1", "path": "res://assets/floor/f1/water.webp", "style": "water", "kind": "floor", "tile": "pond_water", "variants": 6, "seed": 401},
	{"place": "f1", "path": "res://assets/floor/f1/mud.webp", "style": "mud", "kind": "floor", "tile": "feat_mud", "variants": 6, "seed": 501},
]
