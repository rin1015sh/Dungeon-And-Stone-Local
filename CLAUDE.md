# CLAUDE.md — 던전 앤 스톤 (Godot 4)

소설 『게임 속 바바리안으로 살아남기』의 작중 게임 「던전 앤 스톤」을 구현하는 **비상업 팬 프로젝트**.
2D 3/4 쿼터뷰 던전 크롤러 + 민첩 기반 CTB 턴제 + 하드코어 로그라이크 RPG.

## 세션 시작 시 (어느 환경이든)

0. **작업 전에 최신 main을 받아 합친다**(`git fetch origin main` → 브랜치가 뒤처졌으면 `git merge origin/main`). 다른 세션이 main에 병합한 작업(예: 2026-10-16 전투 그림)이 빠진 채 진행되는 일이 있었다.
1. **이 파일과 `docs/PROGRESS.md`만 읽으면 이어갈 수 있다**(PROGRESS = 지금 상태 · 다음 할 일 · 최근 작업 한 줄씩, 짧게 유지). 어떤 문서를 언제 읽는지는 **`docs/README.md`(문서 지도)**. 자주 쓰는 것: 확정된 기획·설정 요약 `docs/CANON.md`, 데이터 키 사전·파일 구조 `docs/REFERENCE.md`, 가정·결정 근거 `docs/ASSUMPTIONS.md`(번호로 검색), 옛 작업 기록 `docs/archive/PROGRESS_LOG.md`(날짜·키워드로 검색). **문서끼리 어긋나면 날짜가 늦은 사용자 결정이 이긴다**(우선순위는 CANON.md 맨 위). **그림 작업이면 `docs/ART.md`(그림체 규칙·도구 명령·절차)를 먼저 읽는다.**
2. PROGRESS.md의 **"다음 할 일"**부터 진행한다. 질문하지 말고 진행하되, 모호한 부분은 합리적으로 가정하고 ASSUMPTIONS.md에 "가정 / 이유 / 바꾸는 방법"을 남긴다.
   - 예외: 세계관·원작 설정 질문은 문서를 검색하지 말고 사용자에게 원문 텍스트를 요청한다(그동안은 DESIGN.md 요약으로 진행).
3. 작업이 끝날 때마다 기록한다: 자세한 기록(한 일·수치·남은 것)은 `docs/archive/PROGRESS_LOG.md` "작업 기록" 맨 위, PROGRESS.md에는 "최근 작업" 한 줄 + "다음 할 일" 갱신(PROGRESS.md §5). 정해진 기획이 바뀌었으면 CANON.md, 새 데이터 키는 REFERENCE.md. 마일스톤 단위로 **항상 실행 가능한 상태**에서 커밋한다(커밋 메시지는 한국어로 짧게).
4. 큰 작업 시작 시 PROGRESS_LOG 맨 위에 "범위 / 완료 기준 / 테스트 방법"을 먼저 쓰고, 끝나면 `docs/PLAYTEST.md` 맨 위에 사용자용 테스트 플레이 체크리스트를 추가한다.

## 실행·검증

- 엔진: **Godot 4.7.2** (`project.godot`의 features "4.7"). 이 PC의 실행 파일(2026-10-14):
  `C:\Users\kcw\Desktop\Godot_v4.7.2-stable_win64.exe` — Downloads의 `_console.exe` 래퍼는 본체가 옮겨져 실행되지 않는다.
- **전체 검증(완료 판정 기준)**: `GODOT=<godot 경로> bash tools/check.sh` → "모든 검증 통과"여야 한다. 내부 단계:
  1. `godot --headless --path . --import` — 클래스 캐시 갱신(새 `class_name` 추가 후 필수)
  2. `godot --headless --path . --script res://tools/validate_data.gd` — 데이터 스키마·참조 검사
  3. `godot --headless --path . --script res://tests/run_tests.gd` — 단위 테스트(`tests/test_*.gd`)
  4. `godot --headless --path . res://tests/smoke_ui.tscn` — UI를 실제로 눌러 보는 스모크
  5. `godot --headless --path . --quit-after 120` — 메인 씬 스모크
  - 출력에 `SCRIPT ERROR` / `Parse Error` / `ERROR:`가 있으면 실패로 본다.
- 층 전체 지도(디버그 미니맵, 헤드리스): `godot --headless --path . --script res://tools/floor_map.gd -- --seed=<시드> --out=<png 경로> [--procedural]` → 구역 색·암흑지대·고정 장소·무리 + 검사 결과. 1층은 고정 지도라 시드는 시작 위치·무리만 바꾼다(`--procedural` = 고정 지도 무시하고 그 시드로 새로).
- **1층 고정 지도 굽기**(생성기·`gen` 값을 바꿨으면 필수 — 테스트가 파일과 시드 결과를 비교한다): `godot --headless --path . --script res://tools/bake_floor.gd [-- --seed=<시드>]` → `data/maps/f1_crystal_cave.json`(한 글자 = 한 칸, rows[y][x]). 시드를 바꾸면 층 JSON `fixed_map.seed`도 고친다. **이벤트를 좌표로 놓은 뒤에는 다시 구우면 좌표가 어긋난다.**
- 화면 캡처(시각 확인, 창이 잠깐 뜸): `godot --path . res://tools/screenshot.tscn -- --screen=title|foundation|create|city|plaza|explore --out=<png 경로>`
  - explore 옵션: `--seed=<층 시드> --walk=<걸음 수> --at=<x>,<y>(그 칸으로 순간이동) --interact(그 자리에서 살피기) --torch --reveal --debug`
  - **장면 목록 일괄 캡처**(탐험 맵 그림 전후 비교): `--screen=explore --seed=1 --shots=res://tools/shots/floor1.json --out=res://docs/screens/<before|after>` → 장면마다 PNG + 걸음당 프레임(`bench`). 기준은 `docs/screens/before/`(`tools/ShotList.gd`).
  - city 옵션: `--scroll=<화면 px> --facility=<id> --activity=<id> --debug --weather=<id>` · plaza(차원광장) 옵션: `--opening`(포탈이 열리는 중) `--weather=<id>`
- **데칼 좌표 굽기**(층 JSON `art.decor` 규칙·kinds를 바꿨으면 필수 — 테스트가 파일과 규칙 결과를 비교한다): `godot --headless --path . --script res://tools/bake_decor.gd` → `data/maps/f1_crystal_cave_decor.json`(한 줄 = [x, y, 종류, 변형, 방향, 뒤집기, 크기×100, 흔들림×100 ×2] — 손으로 고쳐도 된다).
- **그림 다시 만들기**(도시·몬스터 전투·아군 뒷모습·탐험 맵 재질·몸 그림): 명령·옵션·걸리는 시간은 **`docs/ART.md` §0**. 그림·렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다). `--script` 도구가 출력 없이 멈추면 `--check-only --script <파일>`로 파싱 오류를 찾는다.
- **클라우드(리눅스) 세션**: Godot 4.7.2 리눅스판을 내려받아 검증할 수 있다(`curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`, 압축 해제 후 `GODOT=<경로> bash tools/check.sh`). 화면 캡처는 `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . res://tools/screenshot.tscn -- …`.
- **웹(itch.io) 내보내기**: `GODOT=<godot 경로> bash tools/export_web.sh` → `build/web/`·`build/dungeon_and_stone_web.zip`(내보내기 템플릿 필요, 설정 `export_presets.cfg` "Web" — 스레드 끔). 올리는 법·웹에서 다른 점은 `docs/DEPLOY.md`. 브라우저 확인은 `build/web`을 `python3 -m http.server`로 띄워 Playwright(크로미움)로 누른다.
  - 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 글꼴(Noto Sans KR)에 있는 것만(▸ ✕ 같은 기호 금지, `tests/test_web.gd`가 검사). `OS.has_feature("web")`에서 종료 버튼 숨김.
- **Godot이 없는 환경**(모바일 웹 등): 정적 검토만 하고 PROGRESS.md에 **"미검증(Godot 실행 필요)"**을 명시한다. 검증하지 않은 것을 검증했다고 쓰지 않는다.

## 코드 규칙

- GDScript **정적 타이핑 필수**(`var hp: int`, `func f(a: int) -> void`). 주요 클래스엔 `class_name`. 오토로드는 `class_name`을 두지 않는다(이름 충돌).
- 한 스크립트 = 한 책임, **300줄 이내** 지향.
- `.tscn` 최소화. UI·노드 트리는 코드로 만든다. 현재 `.tscn`은 `src/Main.tscn`, `tests/smoke_ui.tscn`, `tools/screenshot.tscn`뿐.
- 키 입력은 `data/input.json`(액션 → 키 이름)에서 `InputSetup`이 등록한다. project.godot의 [input]은 쓰지 않는다. **선택(확인) = Enter**(`menu_confirm`, 포커스 버튼 `ui_accept`), **취소 = Backspace**(`menu_back` — Esc로 하던 창 닫기·시설 나가기도), 커서 = W/S/A/D(사용자 결정 2026-10-16, ASSUMPTIONS UI14). 고르는 작은 창은 `ChoicePopup`.
- **마우스·터치 금지(사용자 결정 2026-10-19, UI17)**: 게임은 키보드로만 다룬다 — `Main._input`이 마우스·터치 입력을 모두 막고 커서를 숨긴다. 새 UI에 클릭·끌어놓기·마우스 올림(툴팁) 조작을 넣지 않는다. 고르기는 `ChoiceGrid`(W/A/S/D·Enter·Backspace) 또는 포커스 버튼(`ui_up/down/left/right`도 W/A/S/D — 디버그 패널은 `UiTheme.keyboard_panel`). 설명은 커서가 놓인 것을 화면에 바로 보인다(소지품 아이템 설명 등). **소지품·캐릭터·도감은 Tab 하나**(`GameMenu` — 세 쪽을 한 화면에, I·C·B 없음). **아이템은 Tab 메뉴에서만 쓴다** — 단축칸(hotbar)·횃불 T·식사 E 키 없음(UI18).
- **콘텐츠는 `data/*.json`만 편집해서 추가**하는 것이 정상 경로다. 코드에 매직 넘버 금지:
  규칙 수치 → `data/balance.json`, 시점·UI 수치·팔레트·폰트 → `data/render.json`.
- **UI 문자열은 `Strings.t("키", {인자})` + `data/strings/ko.json`**. 하드코딩 금지(테스트가 코드 속 키의 존재를 검사한다). 데이터 항목의 이름은 각 JSON의 `name_ko`.
- **부연설명 금지(사용자 결정 2026-10-15)**: 화면에 "무엇인지·어떻게 하는지"를 풀어 쓰는 문장을 넣지 않는다 — 시설·활동 소개, 조작 키 안내줄, "행동력을 다 쓰면~" 같은 규칙 안내, 창 아래 주석, 명령 설명줄, 툴팁 설명 모두. 데이터에 `desc_ko`(소개 문장)도 새로 만들지 않는다. 화면에는 이름·수치·상태·못 하는 이유(짧게)만. 보스 등장 대사·결과 문구 같은 장면 묘사는 괜찮다.
- **간접 체험 — 화면으로 알 수 있는 건 글로 알리지 않는다(사용자 결정 2026-10-19, UI19)**: 피어 앤 헝거처럼 몰입이 먼저다. 횃불 켬·꺼짐, 포션·식사 결과, 상태 변화, 대기·휴식, 안전지대·어둠 드나듦, 버리기, 전투의 피해·회피·쓰러짐(떠오르는 숫자·무대로 보인다)은 문구를 띄우지 않는다(render.json `ui.notice.silent`, 기록에만). 대화창에는 화면으로 알 수 없는 것만 — 얻은 물건·발견·경고·못 하는 이유·장면. 위 알림 띠는 없다. 새 알림 문구를 만들면 먼저 "화면에 이미 보이는가?"를 따지고, 보이면 silent에 넣거나 그림·연출(예: 대기·휴식의 화면 어두워짐)로 바꾼다.
- **결과 문구는 서술형**: "능력치는 오르지 않았다" 같은 게임 말투·수치 나열 대신 장면으로 쓴다("고된 훈련으로 근육통만 생겼다"). 도시 활동은 `city.lines.<활동>.<결과>.<번호>`(여러 개면 `CityLines`가 하나 고름).
- 모든 무작위는 `Rng`(시드 고정 가능)를 거친다.
- 시스템 간 통신은 `EventBus` 시그널. 레지스트리/핸들러 패턴(효과·이벤트·생성기·시설·AI 조건 = id → 핸들러 1파일).
- GDExtension / 외부 플러그인 / 스레드 금지(웹 내보내기 호환). 렌더러는 GL Compatibility.
- `addons/godot_mcp`는 사용자의 편집기 연동 플러그인이다. 게임 코드는 의존하지 않는다.

## 원작 반영 규칙

- 원작 실명 인물 등장 금지(NPC는 "길드 접수원"처럼 직함만). 현실 쪽 설정(빙의·커뮤니티·GM 등) 금지.
- 원작 문장·대사 복사 금지. 설정(규칙·수치·명칭)만 가져오고 문장은 새로 쓴다.
- 원문에 수치가 없는 값은 임시값을 쓰고 데이터에 `"source": "placeholder"`로 표기한다.
- **정수(essence)는 `docs/PROMPT_FLOOR1_V2.md`(사용자 제공 1계층 v2 명세) 기준으로 채운다**(2026-10-12~). 지금은 50종 = 1층 필드 10종(원종 4 + 변이종 6 — 변이종은 1층 지역 표에서 빠져 지금 얻을 수 없다, CR7) + 핏빛성채 15종 + 빙하굴 11종 + 녹색 탄광 7종 + 강철의 묘 7종(수호자 정수 6). 공유 이능은 같은 정수판 스킬 파일(`essence_of`)을 쓴다. 규칙은 `EssenceSet`·`EssenceDrop`, 가정은 ASSUMPTIONS J1~J10.

## 함정 (실제로 겪은 것)

- **`--script` 모드는 오토로드가 전역 등록되기 전에 스크립트를 컴파일한다.** 오토로드 이름(EventBus, DataRegistry …)을 참조하는 스크립트가 `--script` 진입점에서 불려 오면 `Identifier not found`로 컴파일 실패. 그래서:
  - `src/core/`, `src/entities/`의 로직은 **오토로드를 직접 참조하지 않는다**(`GameDatabase` 등을 인자로 받는다).
  - 오토로드/UI가 필요한 테스트는 **씬으로 실행**한다(`tests/smoke_ui.tscn` 방식).
- `:=`로 Variant(`Dictionary.get()`, 배열 원소, `JSON` 결과)를 추론하면 컴파일 오류 → 명시 타입을 쓴다.
- JSON 숫자는 전부 float. 표시용 인자는 `int`로 넘겨야 "10.0"이 안 나온다.
- 새 `class_name`을 추가했으면 `--import`로 클래스 캐시를 갱신해야 헤드리스 실행에서 보인다.
- **스크립트끼리 클래스 이름으로 서로 참조하면(예: Progression ↔ PlayerCharacter) 종료 시 "resources still in use" 오류**가 난다. 한쪽은 `has_method`/`call`로 부른다(`Progression._apply_level`).
- **RefCounted 객체가 자기 자식(컴포넌트)의 시그널에 `self`를 쓰는 람다를 연결하면 순환 참조로 누수**된다(종료 시 "ObjectDB instances were leaked"). 메서드로 연결한다(`Actor._on_status_applied` 참고). Node는 해당 없음.
- `await`와 `as`를 함께 쓸 때는 괄호: `(await f()) as T`.
- SubViewport의 빈 곳은 기본 배경색(회색)으로 칠해진다 → `RenderingServer.set_default_clear_color()`를 Main에서 팔레트 bg로 맞춘다.
- 테스트에서 일부러 오류를 내는 호출(push_error)을 하지 않는다 — check.sh가 출력의 `ERROR:`를 실패로 본다.
- **멈춘 Godot을 `pkill -f <패턴>`으로 죽이지 않는다** — 같은 셸 명령줄에 그 문자열(예: Godot 경로)이 있으면 셸 자신이 죽는다(exit 144). `for p in $(pgrep -f "[G]odot_v4"); do kill $p; done`을 **경로가 없는 별도 명령**으로 실행한다.
- UI 스크립트에 파싱 오류가 있으면 UI 스모크가 끝나지 않고 멈춘다(check.sh가 타임아웃까지 대기). 멈추면 `godot --headless --path . --check-only --script res://<파일>`로 파싱 오류를 찾는다(오토로드 이름 오류는 무시).
- **탐험 맵 그리기에서 칸·데칼마다 `draw_polygon`을 부르지 않는다** — 부를 때마다 삼각분할 + 그리기 명령이라 칸 수백 개인 청크가 수십 ms였다(균열에서 걸음마다 0.5초 멈춤). `QuadBatch`로 그림마다 모아 한 번에. 시야가 바뀔 때 다시 그리는 범위는 `VertexDiff`(값이 바뀐 곳만)·화면 반경으로 줄여 둔 것을 넓히지 않는다. 큰 지도 전체를 스크립트로 훑는 계산(예: `LightField.build`)을 실행 중에 다시 부르지 않는다.
- `--import` 중 `[Godot MCP] Failed to start server on port 6505` 오류가 나올 수 있다(편집기가 이미 포트를 쓰는 중). 게임과 무관하며 check.sh는 이 출력을 무시한다.

## 구조

```
project.godot   오토로드: EventBus, DataRegistry, GameState, TimeSystem, AudioBus
CLAUDE.md README.md   docs/ (문서 지도 = docs/README.md)
data/      콘텐츠 JSON만 (manifest.json이 읽을 목록, '_' 파일 = 템플릿, maps/ = 고정·설계 지도, strings/ko.json)
src/core/       데이터·수식·스탯·자원·Rng·검증기 (오토로드 비의존)
src/entities/   Actor·PlayerCharacter·Monster·StatusSet·LightSource·Fatigue
src/combat/     Battle·Timeline·DamageCalc·Passives·MonsterAi(+ai/)·BossHooks(+patterns/)·effects/<type>.gd
src/explore/    지도·생성기(generators/)·ExploreSession·이동·시야·몬스터·균열(Rift*)·동굴 요소, view/ = 탐험 화면 그리기
src/progress/   성장·정수·전리품·드롭·저장      src/items/  가방·장비      src/city/  도시 규칙(+effects/)
src/ui/         InputSetup·theme/·widgets/·windows/(Tab 메뉴)·city/·combat/·screens/
tests/          test_*.gd(단위) · smoke_ui(UI 스모크)
tools/          check.sh · validate_data · screenshot · bake_floor/bake_decor · paint_*(그림 도구) · sim_*(밸런스 시뮬레이터)
assets/         fonts/ shaders/ floor/ city/ monsters/ party/ actors/ (그림은 코드가 그린 WebP)
```
파일 하나하나의 역할은 **`docs/REFERENCE.md` "파일 구조(자세히)"**.

## 핵심 개념 빠른 참조

- **수식**: `{키}` 자리표시자 + 사칙연산/`min`/`max`/`floor`(Godot Expression). 키 = `level`, `bal.<balance 경로>`, `<스탯 id>`. 예(생명력 — `resources.json`): `"floor({bal.hp.base} + {level} * {bal.hp.per_level} + {p_res} * {bal.hp.per_p_res})"` = 50 + 레벨×10 + 물리내성×3 (+ 정수 `resources.hp`가 `max:hp` 수정자로 — 근력은 생명력에 안 들어감, J12).
- **스탯 계산**: `(기본 + Σflat + Σ자식×coef) × max(0, 1+Σpercent)` → 클램프. 수정자는 출처(`source_id`)별로 붙이고 뗀다.
- **스탯 구성(2026-10-14)**: 주 스탯 5종(근력·민첩·물리내성·항마력·정신력) + 주 스탯으로 대체할 수 없는 세부 스탯 12종(시각·식욕·소화력·자연재생력·영혼 재생력·명중률·감응도 2(화염·냉기)·내성 4(화염·냉기·독·어둠))만 둔다. 새 세부 스탯은 고유 효과가 있을 때만 추가하고 규칙에 연결한다(`tests/test_sub_stats.gd`가 남은 목록·연결을 검사). 가정 ST1~ST5.
- **수정자 대상**: 스탯 id / `max:<자원>` / `regen:<자원>` / `dmg_taken:<피해유형|physical|magical|all>` / `dmg_dealt:…`.
- **자원(ResourcePool)**: 최대치 = 수식 → `max:<id>` 수정자. 코스트는 `{"soul": 5}`처럼 아무 자원이나. 임계값·고갈·회복은 시그널만 낸다(상태이상 부여는 소유자 몫). scope `dungeon_only`(허기)는 미궁 밖에서 정지·숨김.
- **시야**: 유효 시야 = min(층 상한 `visibility_cap_m`, max(주변광 `ambient_light_m`(암흑지대 0), 광원, 최소 시야) + 시야 스탯 보정). `Vision`.
- **3/4 시점 그리기**: 로직은 바닥 그리드, 벽은 윗면(앞면 높이만큼 위로) + 앞면. 바닥=FloorChunk(z 아래), 벽=WallRow(줄 단위 y-정렬) — 타일에 `art`(재질 아틀라스)가 있으면 그림 칸(`FloorArtLayer` 변형 × `vertex_mul` 빛 배율), 없으면 색칠한 칸, 캐릭터 발=정렬 기준, 남쪽 벽에 가려지면 실루엣. 밝기는 꼭짓점 색(정적 광원 LightField + 시야 빛, 시야 경계는 꼭짓점 둘레 칸 수로 감쇠 — 미탐험 순흑, 보이는 곳 최저 = 층 근흑색). 층 그림 설정은 층 JSON `art`(균열 `look.art` — palette·post·pulse·particles·ambience·decor(데칼 규칙 `FloorDecor`)·macro(구역 색조 `FloorTint`), `FloorArt`), 타일 `art`는 atlas·variants·shape("smooth" = 부드러운 암벽: 모서리 사선·윗면 검게·남쪽 앞면만 — `WallShape`)·prop(소품 — 동굴 요소·포탈, 마름모 대신). 데칼 자리는 구운 파일(`art.decor.baked`)에서 읽는다. 그래픽 품질 low는 그레인·입자·맥동·흔들림·데칼 끔(`GraphicsSettings`, 일시정지 메뉴). 탐험 맵 그림이 무거우면 데칼 확률부터 낮춘다.
- **1층 지도(2026-10-16)**: 733×733 십자가 안의 미로 동굴(꼬인 곁가지 굴 + 중간 크기 공동·방 + 지하 호수·기둥·수정 무리, 거대 공동 없음 — 사용자 결정), **모든 게임에서 같은 고정 지도**(층 JSON `fixed_map` → `data/maps`), 시작 위치만 무작위. 화면은 플레이어 둘레 청크만 노드로(`view.stream_chunks`), 80칸 밖 무리는 쉰다(`monsters.active_radius_tiles`). 큰 지도에서 지도 전체를 매 프레임 훑는 코드를 넣지 않는다. 가정 CR14~CR24.
- **탐험 규칙**: `ExploreSession`(순수 로직) — 시간은 실시간(`RealtimeDriver`: 실제 1초 = `realtime_hours_per_sec`시간, 전투·일시정지·디버그 패널·포커스 잃음이면 정지). 이동은 부드러운 연속 좌표(8방향, `fpos`)이고 시간을 쓰지 않는다. 속도 = 1칸 / `move_hours_base` 게임 시간(민첩과 무관 — 2026-10-17, 몬스터도 같은 값), 충돌은 `Kinematics`. 폐쇄 시각에서 자르고 경고(24/6/1h), 안전지대 휴식만 회복.
- **성장**: `data/progression.json`(레벨 표 0/8/50/250/660/…/18000, 만렙 11, 획득원) → `db.prog("경로")`. 레벨 변경은 `PlayerCharacter.set_level/change_level`(정수 슬롯 잠금 동기화). 레벨업 생명력·영혼력은 `balance.hp/soul` 수식.
- **피해 공식(명세 §1)**: 물리 = 무기(몬스터 `natural_weapon`) + 근력×2, 마법 = base + 정신력×2, 방어 100/(100+방어×4), 명중 = (스킬 accuracy 95 + 명중률 스탯) × (1 + 민첩 차×0.005). 효과 키: `accuracy`·`crit_bonus`·`ranged`·`power_if_status`·`drain_if_status`. 도주 = 50% + (아군 평균 − 적 평균 민첩)×2%p(10~90%), 수호자·군주전 불가.
- **전투**: CTB 속도 = 민첩 + `combat.speed_base`(5). `Battle`(phase: await_input → executing → turn_end → ended, 잘못된 행동은 `ActionCheck`가 막고 차례 미소모), 화면은 피어 앤 헝거식 정면 구도(`ui/combat/`: `BattleStage` 무대 — 적 정면·아군 뒷모습, `CombatFigure` 몸, `PartyRoster` 파티 창) + 아래 창 `CommandMenu`(명령 공격·스킬·방어·아이템, 도주는 스킬 목록 맨 끝), 모든 아군 기본 스킬 대화·조사(`balance.party.innate_skills`, `"innate": true`).
- **정수**: `essences/<몬스터 id>.json` = 패시브 1 + `actives[{color, skill}]`(정수판 스킬 `skills/ess_*.json`, `essence_of` = 원래 스킬 id) + 고정값 `stats`·`resources`(생명력 — J13, 굴림 없음). 사례 `{essence, color, stats, resources}`, 무지갯빛 = 수호자(액티브 전부·스탯·생명력 ×1.5). 슬롯 = 레벨, 패시브·`essence_of`가 겹치면 거부. 수정자 출처 `essence:<id>`.
- **하단 대화창(2026-10-18, UI15)**: 탐험 알림(`EventBus.log_message`)·전투 안내·시설 결과는 `DialogueBox`에 한 쪽씩 뜨고 Enter로 넘긴다. 떠 있는 동안 탐험 시간 정지(`realtime` 사유 "dialog")·전투 차례 정지(`CombatScreen._read`). 테스트·캡처는 `DialogueBox.auto_skip`(캡처 `--dialog`면 띄운 채), 전투 빨리 감기 디버그면 전투 대화창만 `instant`. 알림은 문구 키로 두 갈래(`NoticeRoute` — render.json `ui.notice` silent 안 보임 · 나머지 대화창, UI19 — 탐험·전투·도시 거리 모두, 위 알림 띠·도시 위 알림 카드 없음). 키가 있는 알림은 `session.message`·`EventBus.notice`로 보낸다(`log_message`는 키가 없어 대화창으로). **사망하면 결과 화면 없이 바로 타이틀**(UI16).
- **전투 드롭(2026-10-16)**: 정수·전리품은 쓰러진 무대 자리에 남고 전투가 끝나면 하나씩 "획득할까?" → 받을 사람(`CombatDrops`·`DropPickup`, `ExploreSession.grant_battle_rewards(…, defer_drops=true)`·`take_drop`·`leave_drop`). **정수를 얻는 길은 이것뿐** — 두고 가거나 아무도 못 받으면 사라진다(흡수 대기·캐릭터 창 흡수 없음). 가정 UI13.
- **아이템**: `size` [w,h] · `stack` · `equip` {slot, two_handed, modifiers, weapon{damage_type, attack}} · `icon`/`color`/`rarity`. 장비 칸 이름은 `tags.equip_slots`.
- **균열·도시·동굴 요소 요약**: 균열 = `rifts/<id>.json` 챕터마다 새 `ExploreSession`(손 설계 지도 `data/maps/rifts/`), 챕터 사이는 길목(`RiftPassage` — 걸어 들어가면 넘어가고 되돌아간다, 길목은 지도 가장자리·출구와 다음 입구는 반대쪽). 도시 = 순 × 행동력(시설 입장에만 1), 시설 활동 → `activities/<id>`, 하순이 끝나면 차원광장 → 미궁. 동굴 요소 = `data/events/<id>.json`(type feature), 자리는 고정 지도 `features`.
- **데이터 키 사전(자세히)**: 패시브·몬스터 AI·보스 패턴·균열·핏빛성채~강철의 묘에서 생긴 키·감사 규칙·상태이상 키·재기획 키·동굴 요소·도시 규칙은 **`docs/REFERENCE.md`**. 새 키를 만들면 거기에 적는다.
- **새 콘텐츠**: JSON 한 파일/한 항목 추가 → `tools/validate_data.gd`로 확인. 새 효과 타입 = `src/combat/effects/<type>.gd`, 새 층 생성기 = `src/explore/generators/<id>.gd` 파일 하나, 새 도시 활동 효과 = `src/city/effects/<type>.gd`, 새 시설·활동 = `data/facilities`·`data/activities` JSON.
