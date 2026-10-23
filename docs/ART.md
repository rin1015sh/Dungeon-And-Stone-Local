# ART — 그림을 같은 그림체로 그리는 법

이 게임의 그림은 **전부 코드가 그린다.** 그림 생성 AI나 손그림 원화가 없는 환경이라, 저장소 안의 그림 도구(GDScript)가
"정해진 방식"대로 칠하고 그 결과(WebP)를 커밋한다. 그래서 어느 세션이든 **같은 도구 + 같은 규칙**을 쓰면 같은 그림체가 나온다.
같은 설계·같은 시드로 다시 그리면 픽셀까지 같은 그림이 나온다.

새 그림을 그리기 전에 이 문서를 읽고, 이미 있는 그림 하나를 골라 그 설계 항목을 본보기로 삼는다.

그림을 코드 대신 ComfyUI(그림 생성 AI)로 바꿀 때의 프롬프트·교체 규칙은 `docs/COMFYUI_PROMPTS.md`.

## 0. 그림 도구 명령 (CLAUDE.md에서 옮김, 2026-10-20)

- 도시 그림 다시 만들기(약 2분): `godot --headless --path . --script res://tools/paint_city.gd [-- --only=street|buildings|interiors|plaza]` → `assets/city/`(데이터가 가리키는 경로, WebP). 그림체 = 피어 앤 헝거 2풍 손그림 일러스트(ASSUMPTIONS CT21~CT25).
  - 렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다).
- 탐험 맵 몸 그림 다시 만들기(약 1분): `godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|id>]` → `assets/actors/<종족>.webp`(4방향 × 걸음 5장 시트 — 걸음·반걸음·섬·반걸음·걸음, 재생 순서 `render.json view.actor_sheet.walk_cycle`, `ActorSheet` — 탐험가는 전투 그림의 3D 몸에 피어 앤 헝거 맵 그림 비율·자세·깎은 얼굴·머리 타래를 붙여 그린다, 값은 `paint_actors.gd` 맨 위 상수, 시험은 `--set=<상수 소문자>=<값> --out=<폴더>`로 게임 그림을 건드리지 않고) + `assets/actors/monsters/<id>.webp`(전투 그림 축소). 전투 그림을 다시 그렸으면 이것도. 설정 `render.json view.actor_sheet`(ASSUMPTIONS AM27~AM28·AM31 걸음 각도). 몬스터 걷기 시트는 `<id>_walk.webp` + `sheets.json`(설계 `tools/monster_art/MapMonster.gd`, 35종 — AM35). 보스·중간보스는 걷기 대신 기다리는 자세 한 장(`MapMonster.BOSSES`·`BackPose`, 크게 — `--idle=<id>`로 그것만, AM34).
- 탐험 맵 재질 그림 다시 만들기(몇 초): `godot --headless --path . --script res://tools/paint_floor.gd [-- --only=<장소|style>]` → `assets/floor/<장소>/<재질>.webp`(`data/tiles.json art`가 가리킴, 설계 `tools/floor_art/Specs.gd`). 그린 뒤 `--import`하고 `--shots`로 캡처해서 본다.
- 아이템 그림 다시 만들기(약 2분): `godot --headless --path . --script res://tools/paint_items.gd [-- --only=<id,id> | --kind=<종류 id>]` → `assets/items/<id>.webp`(가방 칸 × 80px, 투명). 새 아이템·소재·종류를 넣었으면 그 아이템을 그린다(`tests/test_item_art.gd`가 모든 아이템의 그림·크기를 본다). 확인: 캡처 `--screen=explore --menu=inventory --give=<id,id>`.
- 몬스터 전투 그림 다시 만들기(약 4분): `godot --headless --path . --script res://tools/paint_monsters.gd [-- --only=<id,id>]` → `assets/monsters/<id>.webp` + `index.json`(몸 높이). 그림체 = 피어 앤 헝거 몬스터 그림풍(ASSUMPTIONS UI8), 설계는 `tools/monster_art/Specs.gd`·`Specs2.gd`. 새로 그렸으면 `--import` 후 `screenshot.tscn -- --screen=explore --combat --monster=<id>`로 본다. 아군 그림(탐험가 뒷/옆모습·소환수 뒷모습, `tools/monster_art/Party.gd`)은 `-- --only=party`, 캡처는 `--mate=barbarian,human --ally_summon=ghoul,slime`(ASSUMPTIONS UI11).
  - `--script` 도구가 파싱 오류로 멈추면(출력 없이 시간 초과) `--check-only --script res://tools/monster_art/<파일>.gd`로 찾는다.

## 1. 도구 지도

| 무엇 | 도구(실행) | 부품 | 결과 |
|---|---|---|---|
| 도시 거리·건물·실내·사람·차원광장 | `tools/paint_city.gd [-- --only=street\|buildings\|interiors\|plaza]` | `tools/city_art/` — Paint(캔버스·붓결)·Ink(잉크·빛·색 보정)·Mat(재질)·Parts·Buildings(2)·Backdrop·Street·Interiors·Npcs·NpcParts·Plaza | `assets/city/` (data가 가리키는 경로) |
| 거리 사건 일러스트(960×540, 사건마다 한 장 — CT45) | `tools/paint_city.gd -- --only=events [--event=<id>]`(장당 약 20초) | `tools/city_art/` Events(교수형·포고·소매치기·검문·현상수배)·Events2(마석 넘침·매집·품귀·약장수·외팔이)·Events3(술주정·심부름·화재·역병)·EventKit(하늘·뒤 집·포석·사람·벽보·화로) + 위 부품 | `assets/city/events/<id>.webp` (`street_events` art) |
| 몬스터 전투 그림(정면) | `tools/paint_monsters.gd [-- --only=<id,id>]` | `tools/monster_art/` — Clay(3D 덩어리)·Render·Pen(칠·잉크·빗금)·Rig·Anatomy·Face·Hair·Kit·Arms·Extras·Fur·Beast(Head)·Things(2)·Lord·Finish · 설계 Specs·Specs2 | `assets/monsters/<id>.webp` + `index.json`(몸 높이) |
| 탐험 맵 재질·데칼·소품 | `tools/paint_floor.gd [-- --only=<장소\|style>]` | `tools/floor_art/` — Specs(설계)·Seam(주기 잡음·빛 받은 높이·가장자리 마스크)·Cave(1층 재질 칠·벽 턱)·Decals(데칼)·Props(동굴 요소·포탈 소품)·Marks(기념비·네모 수정) + city_art Paint·Ink | `assets/floor/<장소>/*.webp` (data/tiles.json art · 층 JSON art.decor) |
| 아이템(가방·장비 인형·전투 드롭 — AM40) | `tools/paint_items.gd [-- --only=<id,id> \| --kind=<종류>]`(359장 약 2분) | `tools/item_art/` — ItemArt(캔버스·소재 색·마감)·Frame(좌표)·Style(소재마다 생김새 — AM41)·Hilt(손잡이·날밑·자루 끝)·Surface(표면 무늬·둘레 장식·빛)·Blades(날붙이)·Hafts(둔기·활·지팡이)·Wear(방패·갑옷)·Wear2(머리·손·발·허리·망토·장신구)·Goods(포션·마석·음식·도구) + monster_art Clay·Render·Finish | `assets/items/<id>.webp`(칸 × 80px) |
| 아군 전투 그림(뒷모습) | `tools/paint_monsters.gd -- --only=party` | Back(몸 3D 좌표를 돌려 투영)·BackKit(옷)·BackHair·BackGear(갑옷·무기) · 설계 Party | `assets/party/<종족>_back\|_side.webp`, `assets/monsters/<id>_back.webp` |

실행은 모두 `godot --headless --path . --script <도구>`. 다 그린 뒤엔 `godot --headless --path . --import`.

## 2. 그림체 규칙(바꾸지 않는 "공식")

- (2026-10-18 기준) **미궁 탐험 1층은 손그림 재질·데칼·소품·랜드마크**(A2·A3), **균열 4종은 손 설계 공간 + 장소별 재질·서 있는 소품·뒷배경**(A5, §6). 탐험 화면의 몸은 전투 그림에서 만든 맵 그림(A4 — `tools/paint_actors.gd` → `assets/actors/`). `texture_filter` linear. 탐험 맵 그림 작업은 아래 §6과 `docs/plans/map_design.md`를 따른다.
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

진행: A0(감사·문서·도구)·A1(렌더 기반 — 층 `art` 설정·시야 경계 감쇠·수정 맥동·입자·품질 설정)·A2(1층 재질 아틀라스 `assets/floor/f1/`)·A3(데칼·벽 밑동/턱·거시 색조·랜드마크·소품)·A4(몸 그림·빛 먼지) 끝. 아래는 A4~A5에서도 지킬 규격이다.

- **균열 장소(A5 — 2026-10-18)**: 공간은 손 설계 지도(`data/maps/rifts/`, `docs/plans/rift_spaces.md`), 그림 계약은 `tools/floor_art/rift/specs.json`(장소 bf·gc·gm·it마다 바닥·벽 style 목록과 소품 순서) → `tools/paint_floor.gd -- --only=<장소>[:atlas|stand|backdrop]`(장소당 수 초) → `assets/floor/<장소>/`. 칠은 장소 모듈 `tools/floor_art/rift/<장소>.gd`(`base`·`detail`·`stand`·`backdrop` — 계약은 `Common.gd` 머리말), 소품 부품 `Kit.gd`(3/4 상자·원통·기둥·원뿔·그림자·불꽃). **서 있는 소품**(탁자·무기대·광차…) = 벽 종류 타일 + `art.stand {sheet, cell, cols, rows, size [2, 3], under}` — `WallRow`가 칸 아래 가운데에 그림을 세워 캐릭터와 y 정렬, 밑 바닥은 `FloorChunk`가 `under`(없으면 기본 바닥)로. 줄로 늘어서는 물건(탁자·울타리·창살·난간)은 칸 끝까지 그려 이웃과 이어진다. **낭떠러지**(void 타일) = 바닥을 그리지 않고 `VoidChunk`가 뒷배경(`look.art.backdrop` — 화면 고정 + `drift` 시차 셰이더 `backdrop.gdshader`)을 비추며, 위가 땅인 칸엔 절벽 면(`cliff_color`·`cliff_depth`)을 얹는다. 뒷배경은 내려다본 낭떠러지 아래(하늘 아님), 가로로 이어 붙여도 이음매 없게. 가정 AM36~AM37.
- **몸 그림(A4)**: `godot --headless --path . --script res://tools/paint_actors.gd [-- --only=<종족|monsters|id>]`(약 1분). 탐험가 = 전투 그림의 3D 몸을 곧게 세워(큰 머리·마른 몸·붙인 다리·눈구멍 얼굴) 걸음 다섯 장 × 4방향으로 그린 시트(`ActorSheet` 줄 아래·왼·오·위, 칸 걸음A·반걸음A·섬·반걸음B·걸음B — 팔다리는 마디 각도로 돌린다, AM31), 몬스터 = 전투 일러스트를 몸 높이 × size로 줄임(`MonsterView`가 들썩임·반전·뒷모습). 피어 앤 헝거 맵 그림처럼 사람 키 ≈ 1.3칸·약 3.3등신·움푹한 눈구멍(점 눈 금지)·입 없음·붙어 선 다리, 대비 1.3배·1px 잉크 바깥선, 장비는 그리지 않는다(AM27~AM28). 전투 그림을 다시 그렸으면 이것도 다시 돌린다. 캡처: `--screen=explore`, 빛 먼지는 `--combat --monster=<id> --dust=<초>`.
- **그림 층(A3)**: 데칼 = 층 JSON `art.decor`(규칙 → `FloorDecor` → `DecorChunk`, 시트 줄 순서 = `Specs.DECALS.kinds`), 소품 = 타일 `art.prop {sheet, cell, cols, size}`(시트 칸 순서 = `Props.ORDER`), 거시 색조 = 층 `art.macro`(`FloorTint`). 데칼 자리는 `tools/bake_decor.gd`로 구워 `data/maps/*_decor.json`에서 읽는다(규칙을 바꾸면 다시 굽기).
- **암벽(2026-10-17 사용자 결정)**: 타일 `art.shape: "smooth"` — 모서리는 사선으로 깎고·메우며(`WallShape`), 바위 덩어리 윗면은 검게 숨기고 남쪽을 향한 앞면만 그린다. 그래서 암벽 아틀라스의 **윗면 줄은 화면에 나오지 않는다**(형식 때문에 남겨 둠). 수정은 암벽 앞면에 박힌 작은 결정(`Cave._gem`)이지 블록이 아니다. 투명 그림은 가장자리를 투명하게 녹이고(`Decals._soft_edge`), 방향이 있는 데칼(물가)은 그림 위쪽 = 바라보는 쪽으로 칠한다. 새 데칼 종류는 Specs·데이터 kinds·Decals 세 곳을 같이 고친다(테스트가 순서를 본다).

- **재질 칸 칠하는 법(A2)**: `Cave.cell` = 가장자리 띠는 모든 변형이 같은 주기 바탕(`Seam.field` — `FastNoiseLite.get_seamless_image`) + 안쪽은 변형마다 다른 시드 바탕과 잔손질, `Seam.mask`로 녹인다. **바탕에 주기가 아닌 칠(붓 자국 `Ink.strokes`, `Paint.nz`, `Paint.vary`)을 넣지 않는다** — 칸 격자가 보인다(잔손질에서만). 덩어리 밝기는 높이장 기울기(`Seam.relief`, 왼쪽 위 빛). 색 보정 → 평균 색을 타일 data 색에 맞춤(`paint_floor._row`). 확인은 스크래치 파이썬으로 아틀라스 확대 + 무작위로 이어 붙인 판을 본 뒤 게임 캡처.

- **렌더 기반(A1)**: 층 JSON `art`(균열 `look.art`) — `palette`(미탐험 순흑·근흑색·색조·기억 색), `post`(채도·비네트·그레인), `pulse`(빛나는 타일의 맥동 빛 번짐 — `GlowChunk` + `crystal_pulse` 셰이더), `particles`(`AmbientParticles`), `ambience`(`audio.json ambience`). 읽는 곳 `src/explore/view/FloorArt.gd`, 검사 `WorldRules.check_art`. 품질 low(`GraphicsSettings`)는 그레인·입자·맥동·횃불 흔들림을 끈다. 시야 경계는 `FloorView.vertex_color`(AM9).

- **도구**: `tools/paint_floor.gd [-- --only=<재질|장소>]` + `tools/floor_art/`(새 폴더) → `assets/floor/`(WebP, 투명이 필요하면 RGBA). 칠은 이미 있는 부품을 **재사용**한다 — `tools/city_art/Paint`(캔버스·붓결)·`Ink`(잉크·빛·색 보정)·`Mat`(재질), `tools/monster_art/Pen`(빗금)·`Finish`(피·때·그레인). 새 칠 방식을 만들지 않는다. 설계(재질·노이즈·변형 수·시드)는 도구의 설계 파일(`Specs` 형식).
- **게임이 읽는 값은 data에**: 어느 타일이 어느 아틀라스를 쓰는지 = `tiles.json`(`sprite`/새 `art` 키), 층 색조·근흑색·입자 = 층 JSON(새 그림 키), 칸·벽 크기 = `render.json view`. 코드에 색을 박지 않는다.
- **크기**: 1칸 = 1m = 바닥 32×32px, 벽 앞면 24px(벽 타일 32×56), 카메라 1.5배(`render.json view`). 그림은 2배(`view.art_scale` — 64px 칸, 앞면 48px)로 칠해 줄여 쓴다(AM14). `texture_filter` linear(AM15).
- **아틀라스 형식**: 재질 하나 = 한 줄에 변형 6~8칸(칸 크기 = 바닥 칸 × 그림 배율, 여백 없음). 벽은 윗면 칸 줄 + 앞면 조각 줄(앞면 앵커 = 아래 끝 = 바닥 접점). 소품·데칼은 낱장 또는 시트(앵커 = 발/바닥 가운데). `FloorChunk`·`WallRow`가 아틀라스를 `draw_polygon`(UV + 꼭짓점 색 = `FloorView.vertex_mul`, 셰이더 `floor_tex`)으로 그린다 — **TileMap/TileSet `.tres`로 바꾸지 않는다**.
- **색**: §2 규칙 그대로(채도 낮게, 그늘 `#1a1412` 쪽, 밝은 쪽 `#e0d2b0`). 예외 신호색 = 피·정수·마석/수정 발광·마법. 순흑은 미탐험 전용, 보이는 곳의 가장 어두운 색은 층 색조가 섞인 근흑색. 바깥 윤곽은 순흑이 아닌 굵기가 바뀌는 잉크 선.
- **빛**: 타일 그림은 **중립 밝기**로 칠한다(빛은 실행 중 꼭짓점 색 `LightField` + 시야 빛이 곱한다). 그림에 굽는 빛은 재질 자체의 발광(수정·버섯·광물)만.
- **반복 금지**: 같은 변형이 가로·세로 3칸 이상 이어지지 않게(좌표 해시), 벽 앞면 모양은 구간마다 다르게, 저주파 노이즈로 넓은 영역 변화. 검사 = `FloorArtCheck`(`tools/floor_map.gd` "그림 층 검사", `tests/test_floor_art.gd`).
- **지형은 그대로**: 1층 고정 지도(`data/maps/f1_crystal_cave.json`)를 다시 굽지 않는다(동굴 요소 좌표가 어긋남). 그림 층은 지도 파일 + 좌표에서 결정적으로 나온다.
- **성능**: 청크를 만들 때 그 청크만 계산한다(지도 전체를 매 프레임 훑지 않는다). 전후 걸음당 프레임은 `tools/shots/floor1.json`의 `bench`로 같은 PC에서 비교(2026-10-16 기준 이 PC 평균 47~56ms).
- **확인**: 장면 목록 일괄 캡처 `godot --path . res://tools/screenshot.tscn -- --screen=explore --seed=1 --shots=res://tools/shots/floor1.json --out=res://docs/screens/after` → `docs/screens/before/`와 나란히 본다(그림 작업 전 기준 12장 + `floor1_map.png`).
- **교체**: ComfyUI 등으로 바꿀 때의 아틀라스 칸 크기·순서·앵커 = `docs/COMFYUI_PROMPTS.md` §0-B.
