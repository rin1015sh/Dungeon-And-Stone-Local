# DUNGEON_KIT — 던전 에셋 키트 (2026-11-13, AM65)

여러 층 · 테마의 미궁을 만들 때 계속 꺼내 쓰는 **재사용 그림 묶음 + 그것을 굽는 생성 시스템**.
그림 기법은 2층 소품(AM64)과 같다 — 덩어리를 빚어(`tools/f2_art/sdf.py`) 3/4 시점으로 찍고 손그림으로 마감(`solid.py`), 바닥 · 벽면은 이어지는 넓은 재질(`tex.py`).
**야외 · 자연 · 지역 · 가장자리 에셋 87종과 지역 표는 `docs/asset_library/`(AM68, 2026-11-14 — 같은 키트를 넓힌 것: 쓰는 법 `GENERATION_GUIDE.md` · 전체 표 `ASSET_CATALOG.md` · 지역 55곳 `REGIONAL_ASSET_PLAN.md`). 아래 §1 표는 처음 181종이다.**
**게임에 연결된 것(AM66, 2026-11-13)**: 탐험 화면의 동굴 요소 소품 9칸(꺼진 모닥불 · 부서진 장비 · 석순 · 수정 버섯 · 뼈와 털 무더기 · 고블린 모닥불 · 오래된 해골 · 2층 궤짝 둘) — §3.1. 바닥 · 벽 타일과 나머지 물건은 아직 지도에 쓰이지 않는다.

| 무엇 | 어디 |
|---|---|
| 생성 코드(파이썬 numpy + PIL) | `tools/dungeon_kit/` |
| 구운 결과(묶음 그림 11장 + 목록) | `assets/dungeon_kit/*.webp` · `assets/dungeon_kit/kit.json` |
| 게임 쪽 창구(GDScript) | `src/kit/DungeonKit.gd` |
| 엔진에서 쌓아 찍기 | `tools/kit_demo.gd` |
| 눈으로 보는 그림 | `docs/screens/dungeon_kit/` — `sheet_<분류>.jpg`(이름표 붙은 전체 목록) · `set_<세트>.jpg` · `set_<세트>_dark.jpg` |
| 테스트 | `tests/test_dungeon_kit.gd` |

## 1. 들어 있는 것 (에셋 181종 · 변형 628개 · 그림 829장)

| 분류(cat) | 종 | 내용 |
|---|---|---|
| floor 바닥 | 14 | 석재 `floor_flag` · 오래된 `floor_old` · 금 `floor_cracked` · 깨진 `floor_broken` · 불규칙 `floor_cobble` · 벽돌 `floor_brick` · 이끼 `floor_mossy` · 얼룩 `floor_stained` · 피 `floor_bloody` · 물 `floor_wet` · 흙 `floor_dirt` · 모래 `floor_sand` · 의식 문양 `floor_ritual` · 마력 오염 `floor_corrupt` |
| wall 벽 | 15 | 벽면 4종(`wall_stone` · `wall_brick` · `wall_sewer` · `wall_ancient`) × 상태 4(clean · cracked · mossy · damaged) · 윗면 자동 연결 `wall_top`(16가지 — 모서리 · 끝 · T자 · 십자) · 벽 끝 `wall_end` · 안쪽 모서리 그늘 `wall_shadow` · 벽기둥 `wall_pilaster` · 구멍 `wall_hole` · 터진 틈 `wall_breach` · 무너진 벽 `wall_ruin` · 감옥 철창 `bars`(문 여닫힘) · 문틀과 문 `doorway`(나무 · 쇠 · 쇠살문 · 부서짐 · 막힘) · 아치 통로 `gateway` · 수로 배수구 `sewer_outlet` |
| structure 구조물 | 11 | 기둥(온전 · 금 · 이끼 · 부러짐 · 밑동 · 쓰러짐) · 석상 2종(머리 없음 · 부서짐 · 피눈물) · 제단(피 · 의식) · 계단(오름 · 내림) · 사다리 · 석관(닫힘 · 비껴 열림 · 열림 · 깨짐) · 받침대(보주 · 우상) · 난간 · 아치 |
| furniture 가구 · 생활 | 32 | 책상 · 탁자 · 의자(네 방향 · 쓰러짐 · 부서짐) · 걸상 · 긴 의자 · 침대 · 침낭 · 짚더미 · 책장 · 벽 선반 · 서랍장 · 캐비닛 · 나무 상자 · 보물상자(닫힘 · 열림 · 잠김 · 부서짐) · 나무통 · 바구니 · 무기 거치대 · 갑옷 거치대 · 작업대 · 모루 · 연장통 · 숫돌 · 책 · 문서 · 두루마리 · 병 · 식기 · 음식 잔해 · 솥 · 자루 · 배낭 · 보급품 더미 |
| light 조명 | 15 | 벽 횃불 · 세운 횃불 · 촛대 · 가지 촛대 · 양초 무더기 · 샹들리에(매달림 · 떨어짐) · 랜턴(바닥 · 벽걸이) · 화로 · 모닥불 · 마법등(푸른 · 붉은 · 보라) · 빛나는 룬 · 빛나는 균열 · 벽 룬 글줄 — 켜진 것은 4프레임 일렁임, 꺼진 · 타 버린 변형 따로 |
| trace 환경 흔적 | 35 | 해골 · 뼈 · 유골(누움 · 앉음 · 사슬) · 시체 · 교수 우리 · 부패 자국 · 혈흔(튐 · 웅덩이 · 끌린 · 발자국 · 벽) · 긁힌 자국(바닥 · 벽 · 날짜 금) · 끌린 자국 · 부서진 무기 · 갑옷 · 깨진 병 · 나무 잔해 · 벽 낙서 · 벽 글씨(지어낸 글자) · 먼지 · 거미줄 · 물 얼룩 · 검은 점액(바닥 · 벽 · 덩이) · 그을음 · 재 · 의식 흔적(분필 원 · 피 문양 · 소금 줄 · 촛불 고리 · 뼈 배열) · 고치 · 둥지 |
| nature 자연물 | 18 | 바위 · 잔해 · 이끼 바위 · 석순 · 종유석 · 돌기둥 · 잡초 · 뿌리 · 버섯 · 선반버섯 · 독버섯(붉은 · 빛나는) · 이끼(바닥 · 벽) · 덩굴 · 벽을 뚫은 뿌리 · 웅덩이(잔물결 4프레임) · 땅의 금 · 자갈 |
| special 특수 | 18 | 마법진 3도안 × (분필 · 피 · 푸른 빛 · 붉은 빛) · 봉인 장치 · 석판 · 벽 석판 · 룬 돌 · 고대 기계 · 톱니 더미 · 레버(바닥 · 벽) · 권양기 · 밸브 · 균열 · 포털 · 수정 · 마력 잔류물 · 압력판 · 잠금 받침대 · 사슬 자물쇠 |
| trap 함정 | 23 | 바닥 가시(판 · 반쯤 · 솟음 · 피 · 녹) · 벽 창 · 천장 낙하물(경고 자국 · 매달림 · 떨어진 돌) · 회전 칼날 · 진자 도끼 · 독가스 분출구(바닥 · 벽) · 화염 분사구(바닥 · 벽) · 무너지는 바닥(금 · 처짐 · 반 · 구덩이) · 가시 구덩이 · 화살 구멍 · 쓴 화살 · 인계철선 · 룬 함정 · 그을린 자국 · 작동한 함정 잔해 |

테마 세트(`kit.json` `sets` — 설계는 `tools/dungeon_kit/sets.py`): `ritual` 제단과 의식 공간 · `camp` 탐험가의 야영지 · `prison` 감옥 · `lab` 지하 연구실 · `battle` 전투가 벌어진 흔적 · `ruins` 고대 유적 · `sewer` 지하수로.
세트는 조합 본보기다 — 물건은 모두 낱개라 따로 놓을 수 있다.

## 2. 규칙 (좌표 · 층 · 충돌)

- **크기**: 그림 64px = 한 칸(게임 세계 32px × `art_scale` 2 — 기존 탐험 그림과 같다). 벽 높이 2.5칸(160px). 깊이는 화면에서 0.72배로 눌린다(`depth_k`).
- **원점 = 발**: 낱 그림마다 원점(바닥에 닿는 가운데)이 `kit.json`에 있다. 벽 부착물의 원점은 벽 밑동 선(뜨는 것은 `up` 칸만큼 올린다).
- **층(layer)** — 그리는 순서와 Y-정렬:
  | layer | 뜻 | 정렬 |
  |---|---|---|
  | `floor` · `wall` | TileSet 타일 | 맨 아래 |
  | `decal` | 바닥에 붙는 자국(몸 아래) | 바닥 위 고정 |
  | `wall_decal` | 벽면 부착물(횃불 · 낙서 · 덩굴) | 벽 밑동 y로 Y-정렬 |
  | `stand` | 서 있는 것(배경이면서 몸을 가린다) | 발 y로 Y-정렬 |
  | `over` | 머리 위 전경(샹들리에 · 종유석 · 진자) | 맨 위 |
- **충돌(`collide`)**: 칸 단위 네모 목록 `[x, y, 폭, 깊이]`(원점 기준 · y는 북쪽 +). 없으면 지나갈 수 있는 장식. 문 · 아치는 양쪽 기둥만 막는다.
- **상태 바꾸기**: 같은 에셋의 변형이 정상 · 파손 · 작동 전후다(`door`/`door_open`, `idle`/`active`/`spent`). 함정 · 문은 `meta.states`에 짝이 적혀 있다.
- **빛**: 빛을 내는 변형은 `light`(색 · 반지름 칸 · 위치 · 일렁임). 그림에는 빛 무리만 — 실제 밝히기는 게임의 빛 계산 몫.
- **애니메이션**: `frames`가 여러 장인 변형(불 · 가스 · 마법진 · 포털 · 잔물결 · 룬)은 `fps`로 돈다. 프레임을 늘리려면 에셋 함수의 `"frames": n`만 바꾼다.
- **바닥 이음**: 바닥은 4 × 4칸 넓은 그림 — 칸 좌표를 4로 나눈 나머지 조각을 깐다. `meta.base`가 같은 바닥(`floor_cracked` · `broken` · `mossy` · `stained` · `bloody` · `wet` · `corrupt` ← `floor_flag`)은 돌 줄눈이 같아 칸 단위로 섞어도 돌이 이어진다(얼룩 자체는 칸 경계에서 끊긴다 — 한 군데만 놓을 때는 낱 자국 decal을 쓴다). 벽면도 같은 종류 안에서는 상태를 칸마다 바꿔도 줄눈이 이어진다.
- **벽 연결**: 벽 칸마다 윗면 타일(이웃 벽 비트 북 1 · 동 2 · 남 4 · 서 8 → 16가지), 남쪽이 벽이 아닌 칸에만 벽면(위로 2.5칸 — 북쪽 벽은 3칸 두께로). 줄 끝은 `wall_end`, 안쪽 모서리는 `wall_shadow`, 이음매 · T자는 `wall_pilaster`.

## 3. 게임에 쓰기 (`DungeonKit`)

```gdscript
var kit := DungeonKit.open()                                   # kit.json 읽기(오토로드 아님 — 어디서나)
add_child(kit.make("pillar", "broken", {"scale": 0.5}))        # Sprite2D + StaticBody2D(충돌) — 노드 위치 = 발
add_child(kit.make("torch_wall", "lit", {"light": true}))      # AnimatedSprite2D(4프레임) + PointLight2D
var v := kit.pick("rock", cell.x * 31 + cell.y)                # 되풀이 배치: 칸마다 다른 변형
layer.tile_set = kit.tileset()                                 # 소스 0 바닥 · 1 벽 윗면(충돌) · 2 벽면(64 × 160)
kit.put_floor(layer, cell, "floor_mossy")
kit.put_walls(tops, faces, walls, "brick", {cell: "cracked"})  # 윗면 자동 연결 + 벽면
add_child(kit.build_set("prison", {"scale": 0.5}))             # 테마 세트 한 방(Y-정렬 켜짐)
kit.ids("trap") · kit.ids("", "wall_decal") · kit.variants(id) · kit.texture(id, v, frame) · kit.origin(…) · kit.light_of(…)
```

지금 탐험 화면(`src/explore/view/` — `QuadBatch`로 직접 그린다)에 넣을 때는 노드를 만들지 말고 `kit.texture()` · `kit.origin()` · `kit.info(id)["collide"]`만 꺼내 기존 그리기에 태운다(큰 지도에서 물건마다 노드를 만들지 않는다 — CLAUDE.md 함정).

### 3.1 지금 게임에 연결된 것 — 소품 시트 (AM66)

- 게임은 칸 크기가 같은 소품 시트에서 칸 번호로 그린다(타일 `art.prop` — `DecorChunk`). 그 틀을 그대로 두고 **새 시트 `assets/floor/kit/props.webp`**(8열 · 칸 128px · 5줄)를 만들었다: 옛 시트(`assets/floor/f1/props.webp` — 그대로 있다)를 바탕으로, `tools/dungeon_kit/game_props.py`의 `PROPS` 표에 적은 칸만 키트 그림으로 갈아 끼운다(포탈 · 덫 · 노움 물건 · 발자국 · 샘 · 공물 · 돌탑은 옛 그림 그대로 — **시체 둘(탐험가의 시체 · 갉아먹힌 시체 더미)도 옛 그림**: 사용자 2026-11-13 "시체는 원래 거로 롤백해").
- `data/tiles.json`의 소품 타일 61개가 새 시트를 가리킨다(칸 번호는 같다). 2층 궤짝 다섯은 새 칸 32 · 33(옛 시트에서는 1층 돌무더기 그림을 같이 썼다).
- 키트 그림은 시트에 넣을 때 바닥 그림자 · 빛 무리를 뺀다 — 살필 수 있는 소품에 두르는 검은 테두리가 그림자까지 감싸 덩어리로 보였다.
- 더 바꾸려면: `PROPS`에 `칸: (키트 id, 변형, 프레임, 폭 px)` 한 줄 → `python3 tools/dungeon_kit/game_props.py` → `texture_compress.py` → `--import` → 캡처(`--screen=explore --at=x,y --torch --reveal` — 자리는 `data/maps/f1_crystal_cave.json` features). 되돌리기 = tiles.json의 `kit/props.webp`를 `f1/props.webp`로(궤짝 칸은 17).
- 키트 에셋 함수를 고쳤으면 `build.py` 뒤에 `game_props.py`도 다시 돌린다.

## 4. 다시 굽기 · 새 에셋 더하기

```
python3 tools/dungeon_kit/build.py                         전부 굽기(바뀐 것만 다시 그린다 · 처음 약 4분) → assets/dungeon_kit/
python3 tools/dungeon_kit/build.py <분류|id 앞머리> --sheet=<png>   그것만 그려 이름표 붙은 모음 그림으로(묶지 않는다)
python3 tools/dungeon_kit/compose.py [세트 …] [--dark] [--out=<폴더>]   세트를 한 장으로(기본 docs/screens/dungeon_kit/)
python3 tools/texture_compress.py → godot --headless --path . --import
xvfb-run -a -s "-screen 0 1280x800x24" godot --rendering-driver opengl3 --path . --script res://tools/kit_demo.gd -- --set=all --out=<폴더> [--shapes]
```

- **에셋 하나 = 함수 하나**(`tools/dungeon_kit/a_<분류>.py`). 덩어리는 `@prop(id, 분류, cell=…, collide=…, variants={…})` + `k.add(거리 함수, 재질)`, 평면 자국은 `@flat(…)` + `paint2d.Canvas`(마스크 → 색). 변형 = 인자 dict(`state` · `seed` · `yaw` 회전 · `frames`). 본보기: `a_structure.py`의 `pillar`.
- 부품: `kit.py`(등록 · 덩어리 도우미 `rough` · `chip` · `cut_above` · `pool` · 공통 재질 `palette()`) · `paint2d.py`(평면 판) · `fx.py`(불꽃 · 연기 · 빛 무리 — 색 정리 뒤에 얹는다) · `surf.py`(이어지는 돌 쌓기 · 금 · 색 맞춤) · `build.py`(굽기 · 묶기) · `sets.py`(세트 설계) · `compose.py`(세트 미리보기).
- 같은 시드 = 픽셀까지 같은 그림. 시드만 바꾼 변형(`"b": {"seed": 2}`)으로 되풀이를 줄인다.
- 새 층 테마: 바닥 · 벽 색만 바꾼 종류는 `a_wall.py` `KINDS` 한 줄, `a_floor.py` 함수 하나. 물건의 돌 색은 `kit.palette()`의 재질을 `k.mat()`으로 갈아 끼운다.
- 얇은 `ell()`(타원체)로 바닥 얼룩을 만들면 그림자가 판 전체로 번진다 → `kit.pool()`.

## 5. 아직 없는 것

- 바닥 · 벽 타일과 소품 9칸 밖의 물건을 게임 지도에 쓰는 것(층 · 균열을 정해야 한다), 동 · 서 · 남쪽을 보는 벽면과 옆으로 난 문(지금 게임처럼 북쪽 벽면만), 벽 윗면의 안쪽 대각 모서리 조각.
- (서로 다른 바닥 사이의 번짐 띠 · 물가 테 · 낭떠러지는 AM68에서 더했다 — `KitEdges`, `docs/asset_library/GENERATION_GUIDE.md` §2.)
- 물 · 용암이 흐르는 바닥 타일 애니메이션, 열리는 동작의 중간 프레임(문 · 상자는 닫힘/열림 두 상태뿐), 불빛이 물건에 드리우는 색.
- 큰 구조물(다리 · 탑 · 무너진 천장), 방향이 넷인 가구는 의자뿐. (층 테마별 바닥 · 암벽 · 바위 · 식생은 AM68에서 더했다 — 아직 없는 것의 전체 표는 `docs/asset_library/ASSET_CATALOG.md` 맨 아래.)
