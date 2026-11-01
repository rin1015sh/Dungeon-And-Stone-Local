# CLAUDE.md — 던전 앤 스톤 (Godot 4)

소설 『게임 속 바바리안으로 살아남기』의 작중 게임 「던전 앤 스톤」을 구현하는 **비상업 팬 프로젝트**.
2D 3/4 쿼터뷰 던전 크롤러 + 민첩 기반 CTB 턴제 + 하드코어 로그라이크 RPG.

## 세션 시작 시 (어느 환경이든)

0. **작업 전에 최신 main을 받아 합친다**(`git fetch origin main` → 브랜치가 뒤처졌으면 `git merge origin/main`). 다른 세션이 main에 병합한 작업(예: 2026-10-16 전투 그림)이 빠진 채 진행되는 일이 있었다.
1. **이 파일과 `docs/PROGRESS.md`만 읽으면 이어갈 수 있다**(PROGRESS = 지금 상태 · 다음 할 일 · 최근 작업 10줄, 8KB 안). 어떤 문서를 언제 읽는지는 **`docs/README.md`(문서 지도)**. 자주 쓰는 것: 확정된 기획·설정 요약 `docs/CANON.md`, 핵심 개념·데이터 키 사전·파일 구조 `docs/REFERENCE.md`, 도구 명령 `docs/TOOLS.md`, 가정·결정 근거 `docs/ASSUMPTIONS.md`(번호로 검색), 옛 작업 기록 `docs/archive/PROGRESS_LOG.md`(날짜·키워드로 검색). **문서끼리 어긋나면 날짜가 늦은 사용자 결정이 이긴다**(우선순위는 CANON.md 맨 위). **그림 작업이면 `docs/ART.md`(그림체 규칙·도구 명령·절차)를 먼저 읽는다.**
2. PROGRESS.md의 **"다음 할 일"**부터 진행한다. 질문하지 말고 진행하되, 모호한 부분은 합리적으로 가정하고 ASSUMPTIONS.md에 "가정 / 이유 / 바꾸는 방법"을 남긴다.
   - 예외: 세계관·원작 설정 질문은 문서를 검색하지 말고 사용자에게 원문 텍스트를 요청한다(그동안은 CANON.md 요약으로 진행). 사용자가 준 원작 정리 `docs/LORE.md`는 참고용 — 우리 게임과 다른 곳이 많고 어긋나면 우리 쪽이 이긴다(FL2).
3. 작업이 끝날 때마다 기록한다: 자세한 기록(한 일·수치·남은 것)은 `docs/archive/PROGRESS_LOG.md` "작업 기록" 맨 위, PROGRESS.md에는 "최근 작업" 한 줄 + "다음 할 일" 갱신(PROGRESS.md §5). 정해진 기획이 바뀌었으면 CANON.md, 새 데이터 키는 REFERENCE.md. 마일스톤 단위로 **항상 실행 가능한 상태**에서 커밋한다(커밋 메시지는 한국어로 짧게).
4. 큰 작업 시작 시 PROGRESS_LOG 맨 위에 "범위 / 완료 기준 / 테스트 방법"을 먼저 쓰고, 끝나면 `docs/PLAYTEST.md` 맨 위에 사용자용 테스트 플레이 체크리스트를 추가한다(최근 여섯 절만 — 밀려난 절은 `docs/archive/PLAYTEST_OLD.md`로).

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
- **도구 명령**(시뮬레이터 `sim_walk`·`sim_rift`·`sim_income`, 층 지도, 굽기, 글 md, 정수 표, 화면 캡처, 그림, 웹 내보내기)은 **`docs/TOOLS.md`**. 바꾼 것에 따라 반드시:
  - 1층 생성기·`gen` → `bake_floor.gd` · 층 `art.decor` → `bake_decor.gd` · `ko.json` → `strings_md.gd` · 글(서적·`desc_ko`·`flavor_ko`·ko.json 문장) → `texts_md.py`(→ `docs/TEXTS.md` · 서적+아이템만 `docs/TEXTS_BOOKS_ITEMS.md` — 사용자가 고쳐 보내면 `--apply --md=<파일>`) · 정수 → `essences_md.py` · 아이템 소재·종류·배율 → `item_pool.py`
  - 층·몬스터·정수·균열·서적을 더함 → `python3 tools/floor_status.py`(2~10층 찍는 틀 `docs/plans/floors_2_10.md`)
  - 밀도·탐험가 → `sim_walk` · 균열 지도·조우·길목 → `sim_rift`("모두 통과") · 값·드롭 → `sim_income`(→ `docs/balance/city.md`)
  - **그림·렌더링을 바꿨으면 반드시 캡처해서 직접 본다**(헤드리스 테스트는 그림을 검증하지 못한다 — 명령은 `docs/ART.md` §0·TOOLS.md). `--script` 도구가 출력 없이 멈추면 `--check-only --script <파일>`로 파싱 오류를 찾는다.
- **클라우드(리눅스) 세션**: Godot 4.7.2 리눅스판을 내려받아 검증할 수 있다(`curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`, 압축 해제 후 `GODOT=<경로> bash tools/check.sh`). 화면 캡처는 `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . res://tools/screenshot.tscn -- …`.
- **웹(itch.io)**: 내보내기 명령은 `docs/TOOLS.md`, 올리는 법·웹에서 다른 점은 `docs/DEPLOY.md`.
  - 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 글꼴(본 폰트 송명 + 대신 채우는 Noto Sans KR — render.json `font`, UI47)에 있는 것만(▸ ✕ 같은 기호 금지, `tests/test_web.gd`가 검사). `OS.has_feature("web")`에서 종료 버튼 숨김.
- **Godot이 없는 환경**(모바일 웹 등): 정적 검토만 하고 PROGRESS.md에 **"미검증(Godot 실행 필요)"**을 명시한다. 검증하지 않은 것을 검증했다고 쓰지 않는다.

## 코드 규칙

- GDScript **정적 타이핑 필수**(`var hp: int`, `func f(a: int) -> void`). 주요 클래스엔 `class_name`. 오토로드는 `class_name`을 두지 않는다(이름 충돌).
- 한 스크립트 = 한 책임, **300줄 이내** 지향.
- `.tscn` 최소화. UI·노드 트리는 코드로 만든다. 현재 `.tscn`은 `src/Main.tscn`, `tests/smoke_ui.tscn`, `tools/screenshot.tscn`뿐.
- 키 입력은 `data/input.json`(액션 → 키 이름)에서 `InputSetup`이 등록한다. project.godot의 [input]은 쓰지 않는다. **선택(확인) = Enter**(`menu_confirm`, 포커스 버튼 `ui_accept`), **취소 = Esc**(`pause` — 창 닫기·시설 나가기·선택 창 뒤로), **상호작용(살피기·줍기) = Enter**(`interact` — F 없음), **Backspace는 전투 행동창 뒤로에만**(`menu_back`, `CommandMenu`의 `ChoiceGrid.back_action`), 커서 = W/S/A/D(사용자 결정 2026-10-16·2026-10-30, ASSUMPTIONS UI14·UI43). 고르는 작은 창은 `ChoicePopup`.
- **마우스·터치 금지(사용자 결정 2026-10-19, UI17)**: 게임은 키보드로만 다룬다 — `Main._input`이 마우스·터치 입력을 모두 막고 커서를 숨긴다. 새 UI에 클릭·끌어놓기·마우스 올림(툴팁) 조작을 넣지 않는다. 고르기는 `ChoiceGrid`(W/A/S/D·Enter·Esc) 또는 포커스 버튼(`ui_up/down/left/right`도 W/A/S/D — 디버그 패널은 `UiTheme.keyboard_panel`). 설명은 커서가 놓인 것을 화면에 바로 보인다(소지품 아이템 설명 등). **Tab 메뉴**(`GameMenu` — 왼쪽 아군 목록(W/S·Enter로 볼 아군, 짧은 생명력·영혼력·허기·피로) · 가운데 고른 아군 정보·정수 · 오른쪽 그 아군 장비 + 공용 가방, I·C 없음, 탐험 하단 바 없음 — UI26) · **도감 B**(`CodexMenu` — 몬스터 · 도서관 서적 분야, UI32). **아이템은 Tab 메뉴에서만 쓴다** — 단축칸(hotbar)·횃불 T·식사 E 키 없음(UI18).
- **콘텐츠는 `data/*.json`만 편집해서 추가**하는 것이 정상 경로다. 코드에 매직 넘버 금지:
  규칙 수치 → `data/balance.json`, 시점·UI 수치·팔레트·폰트 → `data/render.json`.
- **UI 색(사용자 결정 2026-10-29, UI45)**: 선택·커서·지금 차례 = `palette.select`(뼈빛), 노란 `gold`는 스톤·값에만. 창 판은 `UiTheme.panel_box` 하나(Tab 쪽도). 채도 높은 색을 새로 넣지 않는다.
- **UI 문자열은 `Strings.t("키", {인자})` + `data/strings/ko.json`**. 하드코딩 금지(테스트가 코드 속 키의 존재를 검사한다). 데이터 항목의 이름은 각 JSON의 `name_ko`. **스톤 금액**은 문구에 `{n} 스톤`으로 쓰면 `Strings.t`가 만 단위로 바꾼다(1만 5000 · 1억 5000만), "스톤" 글자가 없는 자리는 `Strings.stones(n)`(UI31).
- **부연설명 금지(사용자 결정 2026-10-15)**: 화면에 "무엇인지·어떻게 하는지"를 풀어 쓰는 문장을 넣지 않는다 — 시설·활동 소개, 조작 키 안내줄, "행동력을 다 쓰면~" 같은 규칙 안내, 창 아래 주석, 명령 설명줄, 툴팁 설명 모두. 데이터에 `desc_ko`(소개 문장)도 새로 만들지 않는다 — **예외: 아이템의 짧은 플레이버 텍스트**(사용자 요청 2026-10-25, IT7 — 몰입용 한두 문장, 쓰는 법·수치 설명은 넣지 않는다. 장비는 종류·소재 `flavor_ko`를 ItemForge가 잇는다. 문체는 엘든링식 — 생김새·내력 + 여운 한 줄, 서적은 권마다 쓴 사람의 말투가 다르게, 스탯을 "몸놀림" 같은 말로 돌려 쓰지 않는다 — IT14). 화면에는 이름·수치·상태·못 하는 이유(짧게)만. 보스 등장 대사·결과 문구 같은 장면 묘사는 괜찮다.
- **간접 체험 — 화면으로 알 수 있는 건 글로 알리지 않는다(사용자 결정 2026-10-19, UI19)**: 피어 앤 헝거처럼 몰입이 먼저다. 횃불 켬·꺼짐, 포션·식사 결과, 상태 변화, 대기·휴식, 안전지대·어둠 드나듦, 버리기, 전투의 피해·회피·쓰러짐(떠오르는 숫자·무대로 보인다)은 문구를 띄우지 않는다(render.json `ui.notice.silent`, 기록에만). 대화창에는 화면으로 알 수 없는 것만 — 얻은 물건·발견·경고·못 하는 이유·장면. 위 알림 띠는 없다(예외: 전투 스킬·아이템 이름은 무대 위 작은 알림창 `SkillBanner` — render.json `ui.notice.banner`, UI21). 새 알림 문구를 만들면 먼저 "화면에 이미 보이는가?"를 따지고, 보이면 silent에 넣거나 그림·연출(예: 대기·휴식의 화면 어두워짐)로 바꾼다. **소리(비명·싸움·외침·의성어)는 글로 쓰지 않는다** — 소리 키(`ExploreSession.sound` → `AudioBus.play_sfx`, `data/audio.json sfx`)로(사용자 결정 2026-10-22, UI20). 장면 묘사·결과 문구도 꼭 필요한 정보가 있을 때만 — 문구를 늘리지 않는다. **대화창은 한 번에 한 문장**(사용자 결정 2026-10-31, UI44 — `DialogueBox`가 `DialogueSplit`으로 문장마다 쪽을 나눈다. 이 규칙을 끄거나 여러 문장을 한 쪽에 몰아 보이는 코드를 넣지 않는다).
- **아이템 획득 문구는 하나(사용자 결정 2026-11-01)**: 어디서 얻든 `item.got(_n)` "{item}을(를) 얻었다." / "{item} {n}개를 얻었다."(받을 사람을 고르면 `item.got_by(_n)`) — `ItemInfo.got_key(n, by)`로 키를 고른다. "주웠다·챙겼다·꺼냈다·건졌다" 같은 새 획득 문구를 만들지 않고, 장면 문장에는 아이템 이름을 넣지 않는다(장면 한 줄 뒤에 통일 문구). 같은 일을 하는 문구는 새로 쓰기 전에 ko.json에서 같은 말투가 있는지 찾아 그것을 쓴다. `tests/test_item_lines.gd`가 본다.
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
tools/          check.sh · validate_data · screenshot · bake_floor/bake_decor · paint_*(그림 도구 — paint_items + item_art/, paint_battlebacks + battle_art/, paint_books + book_art/, paint_rooms + city_art/Room*) · sim_*(밸런스 시뮬레이터)
assets/         fonts/ shaders/ floor/ city/ monsters/ party/ actors/ items/ battle/(전투 뒷그림) (그림은 코드가 그린 WebP)
```
파일 하나하나의 역할은 **`docs/REFERENCE.md` "파일 구조(자세히)"**.

## 핵심 개념

수식·스탯·자원·시야·3/4 시점·1층 지도·탐험·성장·피해 공식·전투·정수·대화창·드롭·아이템·다른 탐험가·균열·도시의 요약은 **`docs/REFERENCE.md` §0**(기획 정본은 `docs/CANON.md`, 데이터 키는 REFERENCE 아래). 꼭 지킬 것만 여기에:

- **"1점당 몇 %" 공식을 새로 만들지 않는다** — 스탯이 10층에서 수백~천이 된다(10층 비율 공식, `docs/plans/balance_10floors.md`).
- **정수 스킬의 위력을 줄이지 않는다**(사용자 결정 2026-10-24, C15 — 몬스터판보다 약하게 만들지 않고, 하한은 `tests/test_skill_value.gd`).
- **큰 지도(1층 733×733)에서 지도 전체를 매 프레임 훑는 코드를 넣지 않는다** — 화면은 플레이어 둘레 청크만, 80칸 밖 무리는 쉰다.
- **아이템은 Tab 메뉴에서만**, 장비 수치는 JSON에 손으로 쓰지 않는다(종류 × 소재 → `ItemForge`, IT1). 새 아이템은 그림(`assets/items/<id>.webp`)까지.
- **정수를 얻는 길은 전투 드롭 "획득할까?"뿐**(UI13). 마석은 어느 상점도 사지 않는다 — 귀환 정산(CT58).
- **새 콘텐츠**: JSON 한 파일/한 항목 추가 → `tools/validate_data.gd`로 확인. 새 효과 타입 = `src/combat/effects/<type>.gd`, 새 층 생성기 = `src/explore/generators/<id>.gd` 파일 하나, 새 도시 활동 효과 = `src/city/effects/<type>.gd`, 새 시설·활동 = `data/facilities`·`data/activities` JSON.
