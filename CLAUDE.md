# CLAUDE.md — 던전 앤 스톤 (Godot 4)

소설 『게임 속 바바리안으로 살아남기』의 작중 게임 「던전 앤 스톤」을 구현하는 **비상업 팬 프로젝트**.
2D 3/4 쿼터뷰 던전 크롤러 + 민첩 기반 CTB 턴제 + 하드코어 로그라이크 RPG.

## 세션 시작 시 (어느 환경이든)

1. **이 파일과 `docs/PROGRESS.md`만 읽으면 이어갈 수 있다.** 설계 요약은 `docs/DESIGN.md`, 원본 지시서는 `docs/PROMPT.md`, 가정 목록은 `docs/ASSUMPTIONS.md`.
2. PROGRESS.md의 **"다음 할 일"**부터 진행한다. 질문하지 말고 진행하되, 모호한 부분은 합리적으로 가정하고 ASSUMPTIONS.md에 "가정 / 이유 / 바꾸는 방법"을 남긴다.
   - 예외: 세계관·원작 설정 질문은 문서를 검색하지 말고 사용자에게 원문 텍스트를 요청한다(그동안은 DESIGN.md 요약으로 진행).
3. 작업이 끝날 때마다 PROGRESS.md를 갱신한다. 마일스톤 단위로 **항상 실행 가능한 상태**에서 커밋한다(커밋 메시지는 한국어로 짧게).
4. 마일스톤 시작 시 PROGRESS.md에 "범위 / 완료 기준 / 테스트 방법"을 먼저 쓰고, 끝나면 README.md에 사용자용 테스트 플레이 체크리스트를 추가한다.

## 실행·검증

- 엔진: **Godot 4.7.2** (`project.godot`의 features "4.7"). 이 PC의 실행 파일:
  `C:\Users\kcw\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`
- **전체 검증(완료 판정 기준)**: `GODOT=<godot 경로> bash tools/check.sh` → "모든 검증 통과"여야 한다. 내부 단계:
  1. `godot --headless --path . --import` — 클래스 캐시 갱신(새 `class_name` 추가 후 필수)
  2. `godot --headless --path . --script res://tools/validate_data.gd` — 데이터 스키마·참조 검사
  3. `godot --headless --path . --script res://tests/run_tests.gd` — 단위 테스트(`tests/test_*.gd`)
  4. `godot --headless --path . res://tests/smoke_ui.tscn` — UI를 실제로 눌러 보는 스모크
  5. `godot --headless --path . --quit-after 120` — 메인 씬 스모크
  - 출력에 `SCRIPT ERROR` / `Parse Error` / `ERROR:`가 있으면 실패로 본다.
- 화면 캡처(시각 확인, 창이 잠깐 뜸): `godot --path . res://tools/screenshot.tscn -- --screen=title|foundation|create|explore --out=<png 경로>`
  - explore 옵션: `--seed=<층 시드> --walk=<걸음 수> --torch --reveal --debug`
  - 렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다).
- **Godot이 없는 환경**(모바일 웹 등): 정적 검토만 하고 PROGRESS.md에 **"미검증(Godot 실행 필요)"**을 명시한다. 검증하지 않은 것을 검증했다고 쓰지 않는다.

## 코드 규칙

- GDScript **정적 타이핑 필수**(`var hp: int`, `func f(a: int) -> void`). 주요 클래스엔 `class_name`. 오토로드는 `class_name`을 두지 않는다(이름 충돌).
- 한 스크립트 = 한 책임, **300줄 이내** 지향.
- `.tscn` 최소화. UI·노드 트리는 코드로 만든다. 현재 `.tscn`은 `src/Main.tscn`, `tests/smoke_ui.tscn`, `tools/screenshot.tscn`뿐.
- 키 입력은 `data/input.json`(액션 → 키 이름)에서 `InputSetup`이 등록한다. project.godot의 [input]은 쓰지 않는다.
- **콘텐츠는 `data/*.json`만 편집해서 추가**하는 것이 정상 경로다. 코드에 매직 넘버 금지:
  규칙 수치 → `data/balance.json`, 시점·UI 수치·팔레트·폰트 → `data/render.json`.
- **UI 문자열은 `Strings.t("키", {인자})` + `data/strings/ko.json`**. 하드코딩 금지(테스트가 코드 속 키의 존재를 검사한다). 데이터 항목의 이름은 각 JSON의 `name_ko`.
- 모든 무작위는 `Rng`(시드 고정 가능)를 거친다.
- 시스템 간 통신은 `EventBus` 시그널. 레지스트리/핸들러 패턴(효과·이벤트·생성기·시설·AI 조건 = id → 핸들러 1파일).
- GDExtension / 외부 플러그인 / 스레드 금지(웹 내보내기 호환). 렌더러는 GL Compatibility.
- `addons/godot_mcp`는 사용자의 편집기 연동 플러그인이다. 게임 코드는 의존하지 않는다.

## 원작 반영 규칙

- 원작 실명 인물 등장 금지(NPC는 "길드 접수원"처럼 직함만). 현실 쪽 설정(빙의·커뮤니티·GM 등) 금지.
- 원작 문장·대사 복사 금지. 설정(규칙·수치·명칭)만 가져오고 문장은 새로 쓴다.
- 원문에 수치가 없는 값은 임시값을 쓰고 데이터에 `"source": "placeholder"`로 표기한다.
- **정수(essence) 설정은 사용자 요청으로 당분간 비워 둔다**(`data/essences/`는 템플릿만).

## 함정 (실제로 겪은 것)

- **`--script` 모드는 오토로드가 전역 등록되기 전에 스크립트를 컴파일한다.** 오토로드 이름(EventBus, DataRegistry …)을 참조하는 스크립트가 `--script` 진입점에서 불려 오면 `Identifier not found`로 컴파일 실패. 그래서:
  - `src/core/`, `src/entities/`의 로직은 **오토로드를 직접 참조하지 않는다**(`GameDatabase` 등을 인자로 받는다).
  - 오토로드/UI가 필요한 테스트는 **씬으로 실행**한다(`tests/smoke_ui.tscn` 방식).
- `:=`로 Variant(`Dictionary.get()`, 배열 원소, `JSON` 결과)를 추론하면 컴파일 오류 → 명시 타입을 쓴다.
- JSON 숫자는 전부 float. 표시용 인자는 `int`로 넘겨야 "10.0"이 안 나온다.
- 새 `class_name`을 추가했으면 `--import`로 클래스 캐시를 갱신해야 헤드리스 실행에서 보인다.
- **RefCounted 객체가 자기 자식(컴포넌트)의 시그널에 `self`를 쓰는 람다를 연결하면 순환 참조로 누수**된다(종료 시 "ObjectDB instances were leaked"). 메서드로 연결한다(`Actor._on_status_applied` 참고). Node는 해당 없음.
- `await`와 `as`를 함께 쓸 때는 괄호: `(await f()) as T`.
- SubViewport의 빈 곳은 기본 배경색(회색)으로 칠해진다 → `RenderingServer.set_default_clear_color()`를 Main에서 팔레트 bg로 맞춘다.
- 테스트에서 일부러 오류를 내는 호출(push_error)을 하지 않는다 — check.sh가 출력의 `ERROR:`를 실패로 본다.
- `--import` 중 `[Godot MCP] Failed to start server on port 6505` 오류가 나올 수 있다(편집기가 이미 포트를 쓰는 중). 게임과 무관하며 check.sh는 이 출력을 무시한다.

## 구조

```
project.godot            오토로드: EventBus, DataRegistry, GameState, TimeSystem, AudioBus
CLAUDE.md  README.md  docs/{PROMPT,DESIGN,PROGRESS,ASSUMPTIONS}.md
data/                    ← 콘텐츠는 여기에만 (manifest.json이 읽을 파일 목록을 정함)
  manifest.json balance.json render.json tags.json audio.json input.json
  stats.json resources.json statuses.json injuries.json races.json classes.json tiles.json landmarks.json
  monsters/ essences/ skills/ items/ floors/ rifts/ events/ facilities/   ('_'로 시작하는 파일 = 스키마 템플릿, 로드 안 함)
  strings/ko.json
src/
  Main.gd/.tscn          진입점, 화면 전환
  autoload/              EventBus, DataRegistry, GameState, AudioBus
  core/                  JsonUtil, Formula, StatDef, StatBlock, Modifier, ResourceDef, ResourcePool, Rng, Strings,
                         GameClock, DataNames, GameDatabase, ScriptRegistry, ContentRegistries,
                         ValidatorBase, DataValidator, validation/{Core,Content,World}Rules   (오토로드 비의존)
  entities/              Actor(StatBlock·ResourcePool·StatusSet·Inventory·LightSource), PlayerCharacter, StatusSet,
                         LightSource, CharacterRoller
  combat/                EffectHandler, EffectContext, EffectRegistry, effects/<type>.gd(효과 1파일=1타입)
  items/                 Inventory, ItemUser
  explore/               TileDef, FloorMap, GridAlgo, FloorGenerator, generators/<id>.gd(생성기 1파일=1종),
                         Fov, Vision, LightField, ExploreSession(탐험 규칙), view/{FloorView,FloorChunk,WallRow,ActorView}
  progress/ city/        (M3~M4에서 채움)
  ui/InputSetup.gd       data/input.json → InputMap
  ui/theme/UiTheme.gd    render.json → Theme, 위젯 생성 도우미
  ui/widgets/            ResourceBar, ResourcePanel, StatPanel, LogPanel, DataSummary, ExploreHud, DebugPanel
  ui/screens/            TitleScreen, CharacterCreateScreen, ExploreScreen, EndScreen, FoundationScreen(기반 점검), DataErrorScreen
tests/                   TestCase, run_tests.gd, test_*.gd, smoke_ui.gd/.tscn
tools/                   check.sh, validate_data.gd, screenshot.gd/.tscn
assets/                  fonts/ sprites/ audio/ shaders/
```

## 핵심 개념 빠른 참조

- **수식**: `{키}` 자리표시자 + 사칙연산/`min`/`max`/`floor`(Godot Expression). 키 = `level`, `bal.<balance 경로>`, `<스탯 id>`. 예: `"{bal.hp.base} + {level} * {bal.hp.per_level} + {str} * {bal.hp.per_str}"`.
- **스탯 계산**: `(기본 + Σflat + Σ자식×coef) × max(0, 1+Σpercent)` → 클램프. 수정자는 출처(`source_id`)별로 붙이고 뗀다.
- **수정자 대상**: 스탯 id / `max:<자원>` / `regen:<자원>` / `dmg_taken:<피해유형|physical|magical|all>` / `dmg_dealt:…`.
- **자원(ResourcePool)**: 최대치 = 수식 → `max:<id>` 수정자. 코스트는 `{"soul": 5}`처럼 아무 자원이나. 임계값·고갈·회복은 시그널만 낸다(상태이상 부여는 소유자 몫). scope `dungeon_only`(허기)는 미궁 밖에서 정지·숨김.
- **시야**: 유효 시야 = min(층 상한 `visibility_cap_m`, max(주변광 `ambient_light_m`(암흑지대 0), 광원, 최소 시야) + 시야 스탯 보정). `Vision`.
- **3/4 시점 그리기**: 로직은 바닥 그리드, 벽은 윗면(앞면 높이만큼 위로) + 앞면. 바닥=FloorChunk(z 아래), 벽=WallRow(줄 단위 y-정렬), 캐릭터 발=정렬 기준, 남쪽 벽에 가려지면 실루엣. 밝기는 꼭짓점 색(정적 광원 LightField + 시야 빛).
- **탐험 규칙**: `ExploreSession`(순수 로직) — 이동 시간 = 기본/(1+민첩×계수), 벽에 막히면 시간 0, 폐쇄 시각에서 자르고 경고(24/6/1h), 안전지대 휴식만 회복.
- **새 콘텐츠**: JSON 한 파일/한 항목 추가 → `tools/validate_data.gd`로 확인. 새 효과 타입 = `src/combat/effects/<type>.gd`, 새 층 생성기 = `src/explore/generators/<id>.gd` 파일 하나.
