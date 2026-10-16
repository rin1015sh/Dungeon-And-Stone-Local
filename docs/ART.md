# ART — 그림을 같은 그림체로 그리는 법

이 게임의 그림은 **전부 코드가 그린다.** 그림 생성 AI나 손그림 원화가 없는 환경이라, 저장소 안의 그림 도구(GDScript)가
"정해진 방식"대로 칠하고 그 결과(WebP)를 커밋한다. 그래서 어느 세션이든 **같은 도구 + 같은 규칙**을 쓰면 같은 그림체가 나온다.
같은 설계·같은 시드로 다시 그리면 픽셀까지 같은 그림이 나온다.

새 그림을 그리기 전에 이 문서를 읽고, 이미 있는 그림 하나를 골라 그 설계 항목을 본보기로 삼는다.

그림을 코드 대신 ComfyUI(그림 생성 AI)로 바꿀 때의 프롬프트·교체 규칙은 `docs/COMFYUI_PROMPTS.md`.

## 1. 도구 지도

| 무엇 | 도구(실행) | 부품 | 결과 |
|---|---|---|---|
| 도시 거리·건물·실내·사람·차원광장 | `tools/paint_city.gd [-- --only=street\|buildings\|interiors\|plaza]` | `tools/city_art/` — Paint(캔버스·붓결)·Ink(잉크·빛·색 보정)·Mat(재질)·Parts·Buildings(2)·Backdrop·Street·Interiors·Npcs·NpcParts·Plaza | `assets/city/` (data가 가리키는 경로) |
| 몬스터 전투 그림(정면) | `tools/paint_monsters.gd [-- --only=<id,id>]` | `tools/monster_art/` — Clay(3D 덩어리)·Render·Pen(칠·잉크·빗금)·Rig·Anatomy·Face·Hair·Kit·Arms·Extras·Fur·Beast(Head)·Things(2)·Lord·Finish · 설계 Specs·Specs2 | `assets/monsters/<id>.webp` + `index.json`(몸 높이) |
| 아군 전투 그림(뒷모습) | `tools/paint_monsters.gd -- --only=party` | Back(몸 3D 좌표를 돌려 투영)·BackKit(옷)·BackHair·BackGear(갑옷·무기) · 설계 Party | `assets/party/<종족>_back\|_side.webp`, `assets/monsters/<id>_back.webp` |

실행은 모두 `godot --headless --path . --script <도구>`. 다 그린 뒤엔 `godot --headless --path . --import`.

## 2. 그림체 규칙(바꾸지 않는 "공식")

- (예외 — 2026-10-16 기준) **미궁 탐험 맵은 아직 손그림이 아니다**: 3/4 시점 바닥·벽은 색칠한 칸, 동굴 요소는 마름모 표식, `render.json view.texture_filter` nearest. 탐험 맵 그림 작업은 아래 §6과 `docs/plans/map_design.md`를 따른다.
- **참고 그림체 = 피어 앤 헝거(1·2)**. 손으로 칠한 어두운 일러스트 — 탁하고 채도 낮은 색, 짙은 그늘, 거친 펜 선과 빗금, 때·피. 픽셀아트·평면 도형·매끈한 그러데이션은 쓰지 않는다.
- **칠하는 순서는 늘 같다**: 형태를 3D 덩어리로 빚기 → 면 방향으로 3~4단 붓 칠(밝은 면 · 적갈색 그늘 `Render.SHADOW_TINT`) → 오목한 골은 어둡게 + 가는 잉크 → 가려진 경계·바깥 윤곽은 굵기가 바뀌는 잉크 선 → 그늘에 형태를 따라 도는 펜 빗금 → 털 붓결(`Fur`) → 피·때·색 보정·그레인(`Finish`). 이 순서는 `Render.render` + `Fur.comb` + `Finish.done`이 맡으니, 새 그림도 **이 셋을 그대로 부른다**(따로 칠하지 않는다).
- **빛은 왼쪽 위 앞**(`Render.LIGHT`). 도시는 광원(등롱·창·촛불)만 밝히고 나머지는 어둠에 묻는다.
- **재질은 정해진 종류만**: `Kinds.KINDS` — skin·fur·hair·cloth·leather·metal·bone·stone·wood·slime·glow·eye. 색은 설계에서 고르되 채도를 낮게(예: 가죽 `#5a3e28`, 천 `#4a4236`, 금속 `#70787f`).
- **색 보정 기본값**: `Finish.done`의 desat 0.18 · 그림자 `#1a1412` · 밝은 쪽 `#e0d2b0`. 그림마다 바꾸지 않는다(계층군주처럼 일부러 진하게 할 때만 spec에서).
- **모습은 데이터에서 정한다**: 원작 묘사가 없으면 이름·데이터 색·크기에서 모습을 정하고 ASSUMPTIONS(UI8 등)에 적는다. 원작 실명 인물 금지.

## 3. 크기·자르기 규칙

- **몬스터(정면)**: 사람 키 기준 `height` 560px로 그린다. 그림은 둘레만 남겨 자르고(발 = 그림 아래 끝), `index.json`에 **몸 높이**(발~정수리, 치켜든 무기·뿔 제외)를 적는다 — 전투 무대는 이 높이에 맞춰 키를 맞춘다. 네발짐승 = 그림 높이/0.8, 기는 것 /0.7, 덩어리 /0.78, 계층군주 ×0.8(`Specs.body_height`).
- **덩치는 데이터 `size`가 정한다**(무대 키 = 사람 키 × size). 보스 등급은 크기와 상관없이 무대를 채운다(ASSUMPTIONS UI9).
- **아군**: 탐험가는 사람 키 540px(`Party.REF_H`), 바바리안은 ×1.14로 크게 그리고 색인은 사람 키 그대로 — 그래서 무대에서도 크다. 뒷모습 `turn` 0, 옆모습 1.1라디안(오른쪽을 본다 — 무대 오른쪽 자리는 좌우 반전).
- **도시**: 화면 높이 720 기준 "거리 단위". 건물은 더 크게 그려 `building_scale` 0.85로 줄인다. WebP로 저장.

## 4. 새 그림을 넣는 절차

1. **본보기를 고른다** — 비슷한 기존 항목(예: 새 고블린 = `Specs.gd`의 `goblin_*`, 새 네발짐승 = `blade_wolf`, 새 아군 = `Party.gd`의 `soldier_deadman`).
2. **설계 한 항목을 추가**한다 — 몬스터는 `Specs.gd`/`Specs2.gd`의 id 한 항목(키 뜻은 각 파일 머리말: Figure·Rig·Anatomy·Face·Kit·Arms·Extras·Beast·Things), 아군은 `Party.gd`. 부품이 모자라면 해당 파일에 함수 하나를 더한다(새 재질을 만들지 말고 `Kinds` 안에서).
3. `--only=<id>`로 그리고, `--import` 후 **반드시 캡처해서 눈으로 본다**: `screenshot.tscn -- --screen=explore --combat --monster=<id>`(아군은 `--mate=종족` · `--ally_summon=id`). 헤드리스 테스트는 그림을 검증하지 못한다.
4. 여러 장을 비교할 땐 이름을 붙인 모음 그림(스크래치 파이썬 PIL)으로 나란히 본다.
5. 고칠 점을 적고 설계 값을 바꿔 다시 그린다 — 보통 2~4번 돈다.
6. `bash tools/check.sh` 통과(몬스터마다 그림·몸 높이가 있는지, 종족마다 아군 그림이 있는지 테스트가 본다) → ASSUMPTIONS에 모습을 정한 이유 → 커밋.

## 5. 겪은 함정

- 옷·갑옷은 몸 부위 기록(`cl.tag`)을 부풀려 씌운다(`shell`). **근육 혹·뼈 같은 잔손질도 부위 이름을 붙여야** 옷이 덮는다(이름 없이 빚으면 옷을 뚫고 살이 보인다).
- 옷 겹의 녹임 폭(k)이 몸보다 작으면 덩어리 이음매(엉덩이 아래·오금)에서 살이 비친다 → 몸과 같은 값(`BackKit.shell`은 그래서 k를 무시한다).
- 판(slab)이 뼈보다 앞에 있으면 뼈가 묻힌다(날개 막) — 뼈를 막보다 앞(z)으로.
- 화면 좌표로 그린 옷 단은 상자처럼 잘린다 → 몸 둘레를 따라 휘는 단(`BackKit.hem_poly`).
- 형태 단위는 `height` 비율로 쓴다(픽셀 숫자를 박지 않는다) — 크기를 바꿔도 같은 그림이 나온다.
- GDScript: 반복 변수는 타입을 적고(`for s: float in [-1.0, 1.0]`), 도구가 출력 없이 멈추면 `--check-only --script`로 파싱 오류를 찾는다.
- 사용자가 "되돌려"라고 하면 그림 파일과 그 도구 파일을 같은 커밋으로 함께 되돌린다(`git show <커밋>:<경로>`).

## 6. 탐험 맵 (작업 중 — `docs/PROMPT_ART_MAP.md`, 기획 `docs/plans/map_design.md`)

진행: A0(감사·문서·도구)·A1(렌더 기반 — 층 `art` 설정·시야 경계 감쇠·수정 맥동·입자·품질 설정) 끝. 아래는 A2~A5에서 지킬 규격이다. 아직 그림 파일은 없다.

- **렌더 기반(A1)**: 층 JSON `art`(균열 `look.art`) — `palette`(미탐험 순흑·근흑색·색조·기억 색), `post`(채도·비네트·그레인), `pulse`(빛나는 타일의 맥동 빛 번짐 — `GlowChunk` + `crystal_pulse` 셰이더), `particles`(`AmbientParticles`), `ambience`(`audio.json ambience`). 읽는 곳 `src/explore/view/FloorArt.gd`, 검사 `WorldRules.check_art`. 품질 low(`GraphicsSettings`)는 그레인·입자·맥동·횃불 흔들림을 끈다. 시야 경계는 `FloorView.vertex_color`(AM9).

- **도구**: `tools/paint_floor.gd [-- --only=<재질|장소>]` + `tools/floor_art/`(새 폴더) → `assets/floor/`(WebP, 투명이 필요하면 RGBA). 칠은 이미 있는 부품을 **재사용**한다 — `tools/city_art/Paint`(캔버스·붓결)·`Ink`(잉크·빛·색 보정)·`Mat`(재질), `tools/monster_art/Pen`(빗금)·`Finish`(피·때·그레인). 새 칠 방식을 만들지 않는다. 설계(재질·노이즈·변형 수·시드)는 도구의 설계 파일(`Specs` 형식).
- **게임이 읽는 값은 data에**: 어느 타일이 어느 아틀라스를 쓰는지 = `tiles.json`(`sprite`/새 `art` 키), 층 색조·근흑색·입자 = 층 JSON(새 그림 키), 칸·벽 크기 = `render.json view`. 코드에 색을 박지 않는다.
- **크기**: 1칸 = 1m = 바닥 32×32px, 벽 앞면 24px(벽 타일 32×56), 카메라 1.5배(`render.json view`). 그림은 2배(64px 칸)로 칠해 줄여 쓸지 A2에서 캡처로 정한다. `texture_filter`(지금 nearest)는 손그림이면 linear가 맞을 수 있다 — 비교 캡처 후 ASSUMPTIONS에.
- **아틀라스 형식**: 재질 하나 = 한 줄에 변형 6~8칸(칸 크기 = 바닥 칸 × 그림 배율, 여백 없음). 벽은 윗면 칸 줄 + 앞면 조각 줄(앞면 앵커 = 아래 끝 = 바닥 접점). 소품·데칼은 낱장 또는 시트(앵커 = 발/바닥 가운데). `FloorChunk`·`WallRow`가 아틀라스를 `draw_texture_rect_region` + 꼭짓점 색(빛)으로 그린다 — **TileMap/TileSet `.tres`로 바꾸지 않는다**.
- **색**: §2 규칙 그대로(채도 낮게, 그늘 `#1a1412` 쪽, 밝은 쪽 `#e0d2b0`). 예외 신호색 = 피·정수·마석/수정 발광·마법. 순흑은 미탐험 전용, 보이는 곳의 가장 어두운 색은 층 색조가 섞인 근흑색. 바깥 윤곽은 순흑이 아닌 굵기가 바뀌는 잉크 선.
- **빛**: 타일 그림은 **중립 밝기**로 칠한다(빛은 실행 중 꼭짓점 색 `LightField` + 시야 빛이 곱한다). 그림에 굽는 빛은 재질 자체의 발광(수정·버섯·광물)만.
- **반복 금지**: 같은 변형이 가로·세로 3칸 이상 이어지지 않게(좌표 해시), 벽 앞면 모양은 구간마다 다르게, 저주파 노이즈로 넓은 영역 변화. 검사 = `FloorArtCheck`(`tools/floor_map.gd` "그림 층 검사", `tests/test_floor_art.gd`).
- **지형은 그대로**: 1층 고정 지도(`data/maps/f1_crystal_cave.json`)를 다시 굽지 않는다(동굴 요소 좌표가 어긋남). 그림 층은 지도 파일 + 좌표에서 결정적으로 나온다.
- **성능**: 청크를 만들 때 그 청크만 계산한다(지도 전체를 매 프레임 훑지 않는다). 전후 걸음당 프레임은 `tools/shots/floor1.json`의 `bench`로 같은 PC에서 비교(2026-10-16 기준 이 PC 평균 47~56ms).
- **확인**: 장면 목록 일괄 캡처 `godot --path . res://tools/screenshot.tscn -- --screen=explore --seed=1 --shots=res://tools/shots/floor1.json --out=res://docs/screens/after` → `docs/screens/before/`와 나란히 본다(그림 작업 전 기준 12장 + `floor1_map.png`).
- **교체**: ComfyUI 등으로 바꿀 때의 아틀라스 칸 크기·순서·앵커 = `docs/COMFYUI_PROMPTS.md` §0-B.
