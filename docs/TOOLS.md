# TOOLS — 검증 밖의 도구 명령 (CLAUDE.md에서 옮김, 2026-10-28)

> 전체 검증(`tools/check.sh`)과 클라우드 세션·Godot 없는 환경 규칙은 `CLAUDE.md` "실행·검증". 그림 도구는 `docs/ART.md` §0.
> `godot` = Godot 4.7.2 실행 파일(사용자 PC 경로는 CLAUDE.md, 클라우드는 내려받은 리눅스판).

## 시뮬레이터 · 점검

- 1층 걷기 리듬(헤드리스): `godot --headless --path . --script res://tools/sim_walk.gd -- [--seeds=1,2,3] [--day=n] [--no-parties]` → 포탈까지 걸으며 전투·탐험가·동굴 요소·소리를 만나는 간격(실제 초). 밀도·탐험가 수치를 바꿨으면 돌려 본다.
- 균열 통과 점검(헤드리스, 1~2분): `godot --headless --path . --script res://tools/sim_rift.gd -- [--rift=<id>] [--seeds=1,2,3]` → 모든 균열을 실제 이동(충돌)으로 걸어 조우·출구 물건·길목 앞뒤·탈출까지. 균열 지도·길목·조우·출구 조건을 바꿨으면 돌려 본다("모두 통과"여야 한다).
- 1층 원정 한 번 벌이(헤드리스, 몇 분): `godot --headless --path . --script res://tools/sim_income.gd -- [--seeds=1,2,3] [--hours=60] [--bag=10x6]` → 출처별(몬스터·약탈자·탐험가·동굴 요소) 스톤·정수·요소별 벌이. 값·드롭을 바꿨으면 돌려 보고 `docs/balance/city.md`에 적는다(CT43).
- 층 전체 지도(디버그 미니맵, 헤드리스): `godot --headless --path . --script res://tools/floor_map.gd -- --seed=<시드> --out=<png 경로> [--procedural]` → 구역 색·암흑지대·고정 장소·무리 + 검사 결과. 1층은 고정 지도라 시드는 시작 위치·무리만 바꾼다(`--procedural` = 고정 지도 무시하고 그 시드로 새로).

## 굽기 (데이터를 바꿨으면 필수 — 테스트가 파일과 규칙 결과를 비교한다)

- **1층 고정 지도 굽기**(생성기·`gen` 값을 바꿨으면 필수 — 테스트가 파일과 시드 결과를 비교한다): `godot --headless --path . --script res://tools/bake_floor.gd [-- --seed=<시드>]` → `data/maps/f1_crystal_cave.json`(한 글자 = 한 칸, rows[y][x]). 시드를 바꾸면 층 JSON `fixed_map.seed`도 고친다. **이벤트를 좌표로 놓은 뒤에는 다시 구우면 좌표가 어긋난다**(손으로 넣은 `dark_crystal` [31,360]은 다시 구우면 빠진다 — features 맨 앞에 되돌려 넣는다, CR25).
- **데칼 좌표 굽기**(층 JSON `art.decor` 규칙·kinds를 바꿨으면 필수 — 테스트가 파일과 규칙 결과를 비교한다): `godot --headless --path . --script res://tools/bake_decor.gd` → `data/maps/f1_crystal_cave_decor.json`(한 줄 = [x, y, 종류, 변형, 방향, 뒤집기, 크기×100, 흔들림×100 ×2] — 손으로 고쳐도 된다).

## 문서 만들기 (손으로 고치지 않는다)

- **게임 글 md**(사용자가 글을 고치는 곳): `godot --headless --path . --script res://tools/strings_md.gd` → `docs/STRINGS.md`(ko.json 전부, 한 줄 = ``- `키` 글``) · 사용자가 고친 md를 넣기 `… -- --apply`(있는 키의 글만 바꾼다). **ko.json 문구를 추가·수정했으면 다시 만든다**(md가 낡으면 사용자가 옛 글을 고치게 된다).
- **정수 표**: `python3 tools/essences_md.py` → `docs/balance/essences.md`(정수·정수 스킬을 바꿨으면 다시 만든다 — 손으로 고치지 않는다).

## 화면 캡처 · 그림

- 화면 캡처(시각 확인, 창이 잠깐 뜸): `godot --path . res://tools/screenshot.tscn -- --screen=title|foundation|create|city|plaza|explore --out=<png 경로>`
  - explore 옵션: `--seed=<층 시드> --walk=<걸음 수> --at=<x>,<y>(그 칸으로 순간이동) --interact(그 자리에서 살피기) --torch --reveal --debug`
  - **장면 목록 일괄 캡처**(탐험 맵 그림 전후 비교): `--screen=explore --seed=1 --shots=res://tools/shots/floor1.json --out=res://docs/screens/<before|after>` → 장면마다 PNG + 걸음당 프레임(`bench`). 기준은 `docs/screens/before/`(`tools/ShotList.gd`).
  - city 옵션: `--scroll=<화면 px> --facility=<id> --activity=<id> --debug --weather=<id>` · plaza(차원광장) 옵션: `--opening`(포탈이 열리는 중) `--weather=<id>`
  - 그 밖의 옵션(전투 `--combat --monster=<id> --summon=… --summon_each --god`, 균열 `--rift=<id> --chapter=n --engage --near=boss|guardian --spotted`, 메뉴 `--menu=… --keys=…`, 대화창 `--dialog`, 귀환 정산 `--screen=plaza --returning=<쪽>` …)은 `tools/screenshot.gd` 맨 위 주석.
- **그림 다시 만들기**(도시·몬스터 전투·전투 뒷그림·아군 뒷모습·탐험 맵 재질·몸 그림·아이템·여관 요리·도서관 서적·상태이상 아이콘): 명령·옵션·걸리는 시간은 **`docs/ART.md` §0**. 그림·렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다). `--script` 도구가 출력 없이 멈추면 `--check-only --script <파일>`로 파싱 오류를 찾는다.

- **전투 아군 숨쉬기 미리보기**(게임 밖 — UI40): `python3 tools/idle_breathe_preview.py assets/party/human_back.webp <out.gif> <배경 png>` → 숨 한 번(2.8초) GIF.

## 웹 내보내기

- **웹(itch.io) 내보내기**: `GODOT=<godot 경로> bash tools/export_web.sh` → `build/web/`·`build/dungeon_and_stone_web.zip`(내보내기 템플릿 필요, 설정 `export_presets.cfg` "Web" — 스레드 끔). 올리는 법·웹에서 다른 점은 `docs/DEPLOY.md`. 브라우저 확인은 `build/web`을 `python3 -m http.server`로 띄워 Playwright(크로미움)로 누른다.
  - 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 글꼴(Noto Sans KR)에 있는 것만(▸ ✕ 같은 기호 금지, `tests/test_web.gd`가 검사). `OS.has_feature("web")`에서 종료 버튼 숨김.
