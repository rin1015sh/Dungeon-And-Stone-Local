# TOOLS — 검증 밖의 도구 명령 (CLAUDE.md에서 옮김, 2026-10-28)

> 전체 검증(`tools/check.sh`)과 클라우드 세션·Godot 없는 환경 규칙은 `CLAUDE.md` "실행·검증". 그림 도구는 `docs/ART.md` §0.
> `godot` = Godot 4.7.2 실행 파일(사용자 PC 경로는 CLAUDE.md, 클라우드는 내려받은 리눅스판).

## 시뮬레이터 · 점검

- 1층 걷기 리듬(헤드리스): `godot --headless --path . --script res://tools/sim_walk.gd -- [--seeds=1,2,3] [--day=n] [--no-parties]` → 포탈까지 걸으며 전투·탐험가·동굴 요소·소리를 만나는 간격(실제 초). 밀도·탐험가 수치를 바꿨으면 돌려 본다.
- 균열 통과 점검(헤드리스, 1~2분): `godot --headless --path . --script res://tools/sim_rift.gd -- [--rift=<id>] [--seeds=1,2,3]` → 모든 균열을 실제 이동(충돌)으로 걸어 조우·출구 물건·길목 앞뒤·탈출까지. 균열 지도·길목·조우·출구 조건을 바꿨으면 돌려 본다("모두 통과"여야 한다).
- 균열 줄무늬 바닥 어긋남(파이썬, 1초): `python3 tools/rift_strip_check.py [타일id,…]` — 카펫·레일·발판·계단·홈이 이웃 줄에서 폭·위치가 갑자기 바뀌는 곳(벽이 아닌 칸만)을 적는다. 광차·분기·잔해처럼 일부러 끊은 곳도 나오니 지도를 보고 판단. 설계도를 고쳤으면 돌려 본다.
- 몬스터 스킬 실전 점검(헤드리스, 약 1분): `godot --headless --path . --script res://tools/sim_skills.gd`(`MON=<id>` 환경 변수면 그 몬스터만 + 쓴 횟수) → 몬스터마다 AI + 보스 패턴으로 16판, 가진 스킬을 한 번이라도 꺼내 쓰는지. 몬스터 스킬·AI 규칙·보스 패턴을 바꿨으면 돌린다("모두 씀"이어야 한다). 스킬이 효과를 내는지는 단위 테스트 `test_monster_skills`.
- 1층 원정 한 번 벌이(헤드리스, 몇 분): `godot --headless --path . --script res://tools/sim_income.gd -- [--seeds=1,2,3] [--hours=60] [--bag=10x6]` → 출처별(몬스터·약탈자·탐험가·동굴 요소) 스톤·정수·요소별 벌이. 값·드롭을 바꿨으면 돌려 보고 `docs/balance/city.md`에 적는다(CT43).
- 걷기 프레임 시간(렉 찾기, 약 15초): `xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . res://tools/screenshot.tscn -- --screen=explore [--rift=<균열 id>] --prof=12` → 평균·95%·최대 ms·50 ms 넘는 프레임·그리기 호출(CT73). 같은 명령을 `--headless`로 돌리면 스크립트만(그리기 빼고) — 둘을 견줘 원인이 그리기인지 스크립트인지 가른다.
- 도시 실내 걷기 시뮬(몇 초): `godot --headless --path . --script res://tools/sim_room_walk.gd [-- --only=<방 id>]` → 모든 통로(문간·문·계단·사다리·한 칸 길)에 진짜 이동 규칙으로 ±0.45칸 비껴 들어가 보고 "모두 통과"(CT71). 방 지도·body_half·corner_assist를 바꾸면 돌린다.
- **집 바리에이션(CT86)**: `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_variants.gd [-- --only=v01,v05] [--view=front]`(16채 약 2분 반, `--view=front` = 정면 판 → variants/front/ — CT88) → `python3 tools/town_variants_sheet.py [--front]` → `docs/plans/town/variants/sheet.png` · 손그림 마감 `python3 tools/town_handdrawn.py [--front] [v01 …]`(몇 초, numpy — variants/raw/의 날 그림·면 번호 그림 — 커밋하지 않는다(.gitignore), town_variants.gd를 먼저 돌린다) → `<id>_hand.png`·`sheet_hand.png`. 새 집 = `tools/town_kit/Designs.gd` LIST 한 줄 + 짓는 함수(Kit.box·gable_roof·hip_roof·shed_roof·pyramid·cylinder·cone·face + Facade 그림).
- **도시 구상 그림(CT89)**: `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_concept.gd`(약 2분 — 배치 `tools/town_kit/Concept.gd`, 집은 Designs를 줄 yaw 0/±28.8로 세움) → `python3 tools/town_handdrawn.py --dir=concept`(손그림) → `python3 tools/town_concept_board.py` → `docs/plans/town/concept/view_labeled.jpg`(이름표) · `plan_labeled.jpg`(위에서 본 배치) · `district.png`(7구역 전체 도식). raw/·district_hand·plan.png는 커밋하지 않는다.
- **도시 짜임 구상안(CT90)**: `python3 tools/town_layouts.py` → `docs/plans/town/layouts/{a,b,c,d,overview}.png`(사각형 배치도 + 가려진 땅 빗금 + 남북 자른 면 — 안마다 `plan_a`~`plan_d`).
- **둘러싼 차원광장(CT91)**: `python3 tools/town_plaza.py` → `docs/plans/town/layouts/plaza_{arcade,shops,raised}.png`(배치 + 게임 카메라 상자 그림) · `plaza_views.png` · `c2.png`(안 3 + 광장 B 전체) · `c2_view.png`(7구역 3/4 상자 그림). 카메라 그림은 탐험 화면과 같은 3/4(CT92).
- **안 2 + 둘러싼 광장 · 3/4 화면(CT92)**: `python3 tools/town_comb.py` → `docs/plans/town/layouts/b2.png`(배치도) · `b2_view.png`(7구역을 탐험 화면 3/4로 본 상자 그림) · `b2_plaza.png`(광장 가까이).
- **동네 집 그림 방식 비교판**: `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . --script res://tools/town_styles.gd [-- --only=A,B,C,D]`(약 5분) → `python3 tools/town_styles_sheet.py` → `docs/plans/town/styles/sheet.png`(A 정면 · B 비스듬히 · C 등각 · D 3D 렌더 · E 픽셀아트 × 집 다섯).
- **도시 동네 집 그림 굽기(CT85)**: `godot --headless --path . --script res://tools/paint_town_houses.gd -- --part=<i>/4`를 i = 0~3 넷 동시에(약 15분, `--only=h12,h40` = 그 집만 시험) → `user://town_bake/` → `-- --pack` → `assets/town/houses/p<k>.webp` + `index.json`. 거리 소품(가로등·통·상자·자루·공시판·천막·광장 돌 단)은 `-- --props` → `assets/town/props/<kind>.webp`(몇 초, `tools/town_art/PropArt.gd`). 집 면을 횡스크롤 건물 붓(Paint·Mat·Parts·Ink)으로 입면도처럼 그려 기운 면으로 옮긴다(`tools/town_art/` Geo·Elev·Landmarks·Warp). **동네 지도(`data/town`)·`TownMap` 집 크기·`render.json city.town` storey·base·roof_pitch·overhang을 바꿨으면 다시 굽는다**(`tests/test_town.gd`가 모양 값으로 본다). 그린 뒤 `--import`하고 캡처로 본다.
- 도시 동네 지도(CT82): 재질 그림(몇 초) `godot --headless --path . --script res://tools/paint_town.gd [-- --only=<id,id>]` → `assets/town/mat/<id>.webp`(무채색 128px 이음매 없음 — 게임이 render.json `city.town.colors`를 곱한다) · 배치도(파이썬) `python3 tools/town_board.py` → `docs/plans/town/district7.png`(data/town 그대로 + 집 줄 스케치). 지도를 바꾸면 `validate_data`(문 앞이 닿는가)와 캡처로 본다.
- 균열 배치도(파이썬, 몇 초): `python3 tools/rift_boards.py [--out=docs/plans/rift_boards/current] [--cell=12]` → 설계도(`data/maps/rifts/`)를 칸 종류(바닥·벽·소품·못 걷는 바닥·낭떠러지·솟은 외곽)와 표시(시작·입구·출구·조우·수호자·히든 피스·위험)로 그린 PNG — 챕터별 + 균열별 모음. 설계도·조우·히든 피스를 바꿨으면 다시 그린다.
- 층 전체 지도(디버그 미니맵, 헤드리스): `godot --headless --path . --script res://tools/floor_map.gd -- --seed=<시드> --out=<png 경로> [--procedural]` → 구역 색·암흑지대·고정 장소·무리 + 검사 결과. 1층은 고정 지도라 시드는 시작 위치·무리만 바꾼다(`--procedural` = 고정 지도 무시하고 그 시드로 새로).

## 굽기 (데이터를 바꿨으면 필수 — 테스트가 파일과 규칙 결과를 비교한다)

- **1층 고정 지도 굽기**(생성기·`gen` 값을 바꿨으면 필수 — 테스트가 파일과 시드 결과를 비교한다): `godot --headless --path . --script res://tools/bake_floor.gd [-- --seed=<시드>]` → `data/maps/f1_crystal_cave.json`(한 글자 = 한 칸, rows[y][x]). 시드를 바꾸면 층 JSON `fixed_map.seed`도 고친다. **이벤트를 좌표로 놓은 뒤에는 다시 구우면 좌표가 어긋난다**(손으로 넣은 `dark_crystal` [31,360]은 다시 구우면 빠진다 — features 맨 앞에 되돌려 넣는다, CR25).
- **데칼 좌표 굽기**(층 JSON `art.decor` 규칙·kinds를 바꿨으면 필수 — 테스트가 파일과 규칙 결과를 비교한다): `godot --headless --path . --script res://tools/bake_decor.gd` → `data/maps/f1_crystal_cave_decor.json`(한 줄 = [x, y, 종류, 변형, 방향, 뒤집기, 크기×100, 흔들림×100 ×2] — 손으로 고쳐도 된다).

## 문서 만들기 (손으로 고치지 않는다)

- **게임 글 md**(사용자가 글을 고치는 곳): `godot --headless --path . --script res://tools/strings_md.gd` → `docs/STRINGS.md`(ko.json 전부, 한 줄 = ``- `키` 글``) · 사용자가 고친 md를 넣기 `… -- --apply`(있는 키의 글만 바꾼다). **ko.json 문구를 추가·수정했으면 다시 만든다**(md가 낡으면 사용자가 옛 글을 고치게 된다).
- **게임 글 모음 ↔ 데이터**(파이썬, 1초): `python3 tools/texts_md.py` → `docs/TEXTS.md`(도서관 책 · 플레이버·설명 글(아이템·소재·종류·몬스터·정수·스킬·상태·균열·수수께끼 …) · 상황 문구(ko.json의 문장) — 약 1,180개). 사용자가 고친 파일 적용: `python3 tools/texts_md.py --apply --md=<파일> [--dry]` — 바뀐 글만 그 자리에서 바꾼다(파일 모양 유지, ko.json `{자리표시자}`가 달라진 줄은 건너뜀). 적용 뒤 ko.json을 바꿨으면 `strings_md.gd`, 그리고 `texts_md.py`로 다시 만들고 `check.sh`.
- **층 찍어내기 점검표**(파이썬, 1초): `python3 tools/floor_status.py` → `docs/balance/floor_status.md`(1~10층 × 부품 17 — ● 갖춤 · ◐ 일부 · ○ 없음) · `--floor=<n>`이면 그 층만 자세히(파일을 쓰지 않는다). 층 데이터·몬스터·정수·균열·서적을 더했으면 다시 돌린다(부품 목록 `docs/plans/floors_2_10.md` §1).
- **밸런스 총정리**: `python3 tools/balance_sheet.py` → `docs/balance/all_stats.md` + **`all_stats.html`(종류별 탭 화면 — 브라우저로 연다: 검색·거르기·열 눌러 정렬)** + `all_stats.xlsx`(시트별 정렬·필터). 쓰는 부분 `balance_sheet_out.py`, 화면 틀 `balance_sheet_view.html`(Artifact용 조각 — html 파일은 도구가 `<!doctype>`·`<meta charset>` 껍데기를 씌워 내려받아 바로 열린다, 게시용 조각은 `--artifact=<경로>`) — 몬스터(등급×구분 평균·보스·전체·스킬·패시브, 곡선 목표 대비·한 대 %·몇 대)·정수(등급별 평균·전체·스킬)·상태이상 87종·장비(종류×단계)·쓰는 아이템·플레이어 기준·공식·자동 점검. 몬스터·정수·상태·아이템·`balance.json`을 바꿨으면 다시 만든다(openpyxl 없으면 md만).
- **정수 표**: `python3 tools/essences_md.py` → `docs/balance/essences.md`(정수·정수 스킬을 바꿨으면 다시 만든다 — 손으로 고치지 않는다).

## 화면 캡처 · 그림

- 화면 캡처(시각 확인, 창이 잠깐 뜸): `godot --path . res://tools/screenshot.tscn -- --screen=title|foundation|create|city|plaza|explore --out=<png 경로>`
  - explore 옵션: `--seed=<층 시드> --walk=<걸음 수> --at=<x>,<y>(그 칸으로 순간이동) --interact(그 자리에서 살피기) --torch --reveal --debug`
  - **장면 목록 일괄 캡처**(탐험 맵 그림 전후 비교): `--screen=explore --seed=1 --shots=res://tools/shots/floor1.json --out=res://docs/screens/<before|after>` → 장면마다 PNG + 걸음당 프레임(`bench`). 기준은 `docs/screens/before/`(`tools/ShotList.gd`).
  - city 옵션: `--town_at=x,y(칸) --face=up|down|left|right · --door=<시설 id>(그 문 앞) · --facility=<id> --activity=<id> --debug --weather=<id>`
  - 그 밖의 옵션(전투 `--combat --monster=<id> --summon=… --summon_each --god`, 균열 `--rift=<id> --chapter=n --engage --near=boss|mon:<몬스터 id>|guardian|<x>,<y> --spotted --chase=N`(매복 무리가 N걸음 쫓아온 뒤), 메뉴 `--menu=… --keys=…`, 대화창 `--dialog`, 귀환 정산 `--screen=plaza --returning=<쪽>` …)은 `tools/screenshot.gd` 맨 위 주석.
- **그림 다시 만들기**(도시·시설 실내 방·몬스터 전투·전투 뒷그림·아군 뒷모습·탐험 맵 재질·몸 그림·아이템·여관 요리·도서관 서적·상태이상 아이콘): 명령·옵션·걸리는 시간은 **`docs/ART.md` §0**. 그림·렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다). `--script` 도구가 출력 없이 멈추면 `--check-only --script <파일>`로 파싱 오류를 찾는다.

- **전투 탐험가 동작 시트**(UI41 — 게임이 쓴다): `godot --headless --path . --script res://tools/paint_motions.gd [-- --only=human_back,… --motions=idle,swing]` → `assets/party/<id>_motions.webp`(줄 = render.json `ui.combat_party_motion.rows` 순서 7동작, 칸 3 — 대기는 들썩임) + `<id>_dead.webp`(누운 몸). 미리보기 png는 `--out=<폴더> --png`. 동작 관절 = `tools/monster_art/party_motions.json`(참고 시트 120px 칸에서 잰 2D 점 → `PartyMotion`이 3D 뼈대로). **아군 그림(`paint_monsters --only=party`)·옷을 바꿨으면 이것도 다시**(약 3분). 고정한 줄: `tools/monster_art/pinned/<id>_<동작>.png`가 있으면 그 줄은 다시 그리지 않고 그 그림을 넣는다(지금 `human_back_wait` — 사용자가 고른 예전 그림, AM48). 캡처: `screenshot.tscn -- --screen=explore --combat --mate=human,barbarian,human --motions=swing,damage,stance,fall --motion_t=0.2`.
- **옷차림·새 종족 후보 그림**(AM42·AM59 — 게임은 안 쓴다): 시안 `paint_look_preview.gd -- --look=<id,…> --out=<폴더>`(전투 그림 크기 앞·옆·뒤 `<id>_views.png`) · 맵 `paint_actors.gd -- --look=<id,…> --out=<폴더>` → 비교 그림 `python3 tools/looks_sheet.py --map <폴더> --views <폴더> --out <png> [--title 제목] [--cols N] <id …>`(제목·부제 = `MapLooks` name·note). 고른 하나만 전투 동작 `paint_motions.gd -- --look=<id> --out=<폴더> --png`(약 1분 반, `--combat <폴더>`로 비교 그림에).
- **종족 그림 확인 시트**(AM59 — 사용자 확인용): `python3 tools/art_review.py --out docs/screens/race_looks <종족 …>` → `review_<종족>.png`(맵 걷기 시트 전체 ×2 + 게임 크기 + 전투 뒷모습 + 전투 동작 시트 전체 + 쓰러짐, 줄·칸 이름표).

## 웹 내보내기

- **웹(itch.io) 내보내기**: `GODOT=<godot 경로> bash tools/export_web.sh` → `build/web/`·`build/dungeon_and_stone_web.zip`(내보내기 템플릿 필요, 설정 `export_presets.cfg` "Web" — 스레드 끔). 올리는 법·웹에서 다른 점은 `docs/DEPLOY.md`. 브라우저 확인은 `build/web`을 `python3 -m http.server`로 띄워 Playwright(크로미움)로 누른다.
  - 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 글꼴(Noto Sans KR)에 있는 것만(▸ ✕ 같은 기호 금지, `tests/test_web.gd`가 검사). `OS.has_feature("web")`에서 종료 버튼 숨김.
