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

- 엔진: **Godot 4.7.2** (`project.godot`의 features "4.7"). 이 PC의 실행 파일(2026-10-14):
  `C:\Users\kcw\Desktop\Godot_v4.7.2-stable_win64.exe` — Downloads의 `_console.exe` 래퍼는 본체가 옮겨져 실행되지 않는다.
- **전체 검증(완료 판정 기준)**: `GODOT=<godot 경로> bash tools/check.sh` → "모든 검증 통과"여야 한다. 내부 단계:
  1. `godot --headless --path . --import` — 클래스 캐시 갱신(새 `class_name` 추가 후 필수)
  2. `godot --headless --path . --script res://tools/validate_data.gd` — 데이터 스키마·참조 검사
  3. `godot --headless --path . --script res://tests/run_tests.gd` — 단위 테스트(`tests/test_*.gd`)
  4. `godot --headless --path . res://tests/smoke_ui.tscn` — UI를 실제로 눌러 보는 스모크
  5. `godot --headless --path . --quit-after 120` — 메인 씬 스모크
  - 출력에 `SCRIPT ERROR` / `Parse Error` / `ERROR:`가 있으면 실패로 본다.
- 층 전체 지도(디버그 미니맵, 헤드리스): `godot --headless --path . --script res://tools/floor_map.gd -- --seed=<시드> --out=<png 경로>` → 구역 색·암흑지대·고정 장소·무리 + 검사 결과.
- 화면 캡처(시각 확인, 창이 잠깐 뜸): `godot --path . res://tools/screenshot.tscn -- --screen=title|foundation|create|city|explore --out=<png 경로>`
  - explore 옵션: `--seed=<층 시드> --walk=<걸음 수> --torch --reveal --debug`
  - city 옵션: `--scroll=<화면 px> --facility=<id> --activity=<id> --debug --weather=<id>` · plaza(차원광장) 옵션: `--opening`(포탈이 열리는 중) `--weather=<id>`
- 도시 그림 다시 만들기(약 2분): `godot --headless --path . --script res://tools/paint_city.gd [-- --only=street|buildings|interiors|plaza]` → `assets/city/`(데이터가 가리키는 경로, WebP). 그림체 = 피어 앤 헝거 2풍 손그림 일러스트(ASSUMPTIONS CT21~CT25).
  - 렌더링을 바꿨으면 반드시 캡처해서 직접 본다(헤드리스 테스트는 그림을 검증하지 못한다).
- 몬스터 전투 그림 다시 만들기(약 4분): `godot --headless --path . --script res://tools/paint_monsters.gd [-- --only=<id,id>]` → `assets/monsters/<id>.webp` + `index.json`(몸 높이). 그림체 = 피어 앤 헝거 몬스터 그림풍(ASSUMPTIONS UI8), 설계는 `tools/monster_art/Specs.gd`·`Specs2.gd`. 새로 그렸으면 `--import` 후 `screenshot.tscn -- --screen=explore --combat --monster=<id>`로 본다. 아군 그림(탐험가 뒷/옆모습·소환수 뒷모습, `tools/monster_art/Party.gd`)은 `-- --only=party`, 캡처는 `--mate=barbarian,human --ally_summon=ghoul,slime`(ASSUMPTIONS UI11).
  - `--script` 도구가 파싱 오류로 멈추면(출력 없이 시간 초과) `--check-only --script res://tools/monster_art/<파일>.gd`로 찾는다.
- **클라우드(리눅스) 세션**: Godot 4.7.2 리눅스판을 내려받아 검증할 수 있다(`curl -L -o g.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`, 압축 해제 후 `GODOT=<경로> bash tools/check.sh`). 화면 캡처는 `xvfb-run -a -s "-screen 0 1280x720x24" <godot> --rendering-driver opengl3 --path . res://tools/screenshot.tscn -- …`.
- **웹(itch.io) 내보내기**: `GODOT=<godot 경로> bash tools/export_web.sh` → `build/web/`·`build/dungeon_and_stone_web.zip`(내보내기 템플릿 필요, 설정 `export_presets.cfg` "Web" — 스레드 끔). 올리는 법·웹에서 다른 점은 `docs/DEPLOY.md`. 브라우저 확인은 `build/web`을 `python3 -m http.server`로 띄워 Playwright(크로미움)로 누른다.
  - 웹에는 시스템 글꼴이 없다 → 화면 글자는 동봉 글꼴(Noto Sans KR)에 있는 것만(▸ ✕ 같은 기호 금지, `tests/test_web.gd`가 검사). `OS.has_feature("web")`에서 종료 버튼 숨김.
- **Godot이 없는 환경**(모바일 웹 등): 정적 검토만 하고 PROGRESS.md에 **"미검증(Godot 실행 필요)"**을 명시한다. 검증하지 않은 것을 검증했다고 쓰지 않는다.

## 코드 규칙

- GDScript **정적 타이핑 필수**(`var hp: int`, `func f(a: int) -> void`). 주요 클래스엔 `class_name`. 오토로드는 `class_name`을 두지 않는다(이름 충돌).
- 한 스크립트 = 한 책임, **300줄 이내** 지향.
- `.tscn` 최소화. UI·노드 트리는 코드로 만든다. 현재 `.tscn`은 `src/Main.tscn`, `tests/smoke_ui.tscn`, `tools/screenshot.tscn`뿐.
- 키 입력은 `data/input.json`(액션 → 키 이름)에서 `InputSetup`이 등록한다. project.godot의 [input]은 쓰지 않는다. **선택(확인) = Enter**(`menu_confirm`, 포커스 버튼 `ui_accept`), **취소 = Backspace**(`menu_back` — Esc로 하던 창 닫기·시설 나가기도), 커서 = W/S/A/D(사용자 결정 2026-10-16, ASSUMPTIONS UI14). 고르는 작은 창은 `ChoicePopup`.
- **콘텐츠는 `data/*.json`만 편집해서 추가**하는 것이 정상 경로다. 코드에 매직 넘버 금지:
  규칙 수치 → `data/balance.json`, 시점·UI 수치·팔레트·폰트 → `data/render.json`.
- **UI 문자열은 `Strings.t("키", {인자})` + `data/strings/ko.json`**. 하드코딩 금지(테스트가 코드 속 키의 존재를 검사한다). 데이터 항목의 이름은 각 JSON의 `name_ko`.
- **부연설명 금지(사용자 결정 2026-10-15)**: 화면에 "무엇인지·어떻게 하는지"를 풀어 쓰는 문장을 넣지 않는다 — 시설·활동 소개, 조작 키 안내줄, "행동력을 다 쓰면~" 같은 규칙 안내, 창 아래 주석, 명령 설명줄, 툴팁 설명 모두. 데이터에 `desc_ko`(소개 문장)도 새로 만들지 않는다. 화면에는 이름·수치·상태·못 하는 이유(짧게)만. 보스 등장 대사·결과 문구 같은 장면 묘사는 괜찮다.
- **결과 문구는 서술형**: "능력치는 오르지 않았다" 같은 게임 말투·수치 나열 대신 장면으로 쓴다("고된 훈련으로 근육통만 생겼다"). 도시 활동은 `city.lines.<활동>.<결과>.<번호>`(여러 개면 `CityLines`가 하나 고름).
- 모든 무작위는 `Rng`(시드 고정 가능)를 거친다.
- 시스템 간 통신은 `EventBus` 시그널. 레지스트리/핸들러 패턴(효과·이벤트·생성기·시설·AI 조건 = id → 핸들러 1파일).
- GDExtension / 외부 플러그인 / 스레드 금지(웹 내보내기 호환). 렌더러는 GL Compatibility.
- `addons/godot_mcp`는 사용자의 편집기 연동 플러그인이다. 게임 코드는 의존하지 않는다.

## 원작 반영 규칙

- 원작 실명 인물 등장 금지(NPC는 "길드 접수원"처럼 직함만). 현실 쪽 설정(빙의·커뮤니티·GM 등) 금지.
- 원작 문장·대사 복사 금지. 설정(규칙·수치·명칭)만 가져오고 문장은 새로 쓴다.
- 원문에 수치가 없는 값은 임시값을 쓰고 데이터에 `"source": "placeholder"`로 표기한다.
- **정수(essence)는 `docs/PROMPT_FLOOR1_V2.md`(사용자 제공 1계층 v2 명세) 기준으로 채운다**(2026-10-12~). 지금은 1층 필드 10종(원종 4 + 변이종 6) + 핏빛성채 14종 + 빙하굴 11종 + 녹색 탄광 7종 + 강철의 묘 7종(수호자 정수 6). 공유 이능은 같은 정수판 스킬 파일(`essence_of`)을 쓴다. 규칙은 `EssenceSet`·`EssenceDrop`, 가정은 ASSUMPTIONS J1~J10.

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
- `--import` 중 `[Godot MCP] Failed to start server on port 6505` 오류가 나올 수 있다(편집기가 이미 포트를 쓰는 중). 게임과 무관하며 check.sh는 이 출력을 무시한다.

## 구조

```
project.godot            오토로드: EventBus, DataRegistry, GameState, TimeSystem, AudioBus
CLAUDE.md  README.md  docs/{PROMPT,PROMPT_FLOOR1_V2,DESIGN,PROGRESS,ASSUMPTIONS}.md
data/                    ← 콘텐츠는 여기에만 (manifest.json이 읽을 파일 목록을 정함)
  manifest.json balance.json progression.json(레벨·경험치) render.json tags.json audio.json input.json
  stats.json resources.json statuses.json meters.json(전투 게이지) injuries.json races.json classes.json tiles.json landmarks.json
  city.json(도시 규칙 — 미정 null)
  monsters/ essences/ skills/ items/ floors/ rifts/ riddles/ events/ facilities/ activities/ city_info/   ('_'로 시작하는 파일 = 스키마 템플릿, 로드 안 함)
  strings/ko.json
src/
  Main.gd/.tscn          진입점, 화면 전환
  autoload/              EventBus, DataRegistry, GameState, AudioBus
  core/                  JsonUtil, Formula, StatDef, StatBlock, Modifier, ResourceDef, ResourcePool, Rng, Strings,
                         GameClock, DataNames, GameDatabase, ScriptRegistry, ContentRegistries,
                         ValidatorBase, DataValidator, validation/{Core,Content,World,Boss,Rift,Effect,Passive,BossParam,City}Rules   (오토로드 비의존)
  entities/              Actor(StatBlock·ResourcePool·StatusSet·Inventory·LightSource), PlayerCharacter, StatusSet,
                         LightSource, CharacterRoller, Fatigue(피로도 — 도시·미궁 공용)
  combat/                Battle, BattleRules(은신·증원·도주·사건·정리), BattleTargets(대상·오인), Timeline, DamageCalc, Passives,
                         MonsterAi + ai/<조건>.gd, Meters(전투 게이지), BossHooks + BossPattern + patterns/<id>.gd(보스 페이즈·라운드),
                         BattleDelayed(예고 공격), BattleTargets, BattleObjective(생존 웨이브), BattlePassives(전투 단위 패시브),
                         BattleSpawns(분열·흡수·소환 만료),
                         DamageApply(모든 피해 공통: 보호막→버티기→생명력→피해로 풀리는 상태),
                         EffectHandler, EffectContext, EffectRegistry, effects/<type>.gd(효과 1파일=1타입)
  explore/               TileDef, FloorMap, GridAlgo, FloorGenerator, generators/<id>.gd(생성기 1파일=1종),
                         CrossLayout·CrossTerrain·CaveCarver·CrossLayoutCheck(1층 십자가 뼈대·굴 파기·검사), GridWiden(통로 폭 ≥ 2)·GridSpurs(막다른 길),
                         Fov, Vision, LightField, ExploreSession(탐험 규칙), RealtimeDriver(실시간), Kinematics(충돌),
                         PlayerMotion, FieldMonsters + MonsterSteering(몬스터 이동·변이종·은신), FieldStealth, LordWatch(계층군주 소환),
                         RiftCalendar·RiftWatch·RiftRun(균열 개방·챕터), RiftHazards(챕터 탐험 위험·함정), RiftHidden(히든 피스·벽화), RiftRiddle(수수께끼 문지기), ExploreInteract(살피기·포탈), view/{FloorView,FloorChunk,WallRow,ActorView,MonsterView}
  progress/              Progression(공적·레벨·획득원), ExpBudget, Lineage(계열·공유 이능), Knowledge(???), Loot, Rewards, EssenceSet(흡수·중복·삭제·슬롯 잠금), EssenceDrop(드롭), DropPickup(전투 장면에서 줍는 드롭 — 굴림·받기·두기), SaveGame(한 칸 저장)
  items/                 Inventory(격자 가방), Equipment(11칸), InventoryActions, ItemInfo, ItemUser
  city/                  CityState(순 달력·행동력·공적치·잔액·소문/정보·디버그 임시값), CityValues(null 경로·임시값), CityActions(활동 실행),
                         CityEffect + effects/<type>.gd(fatigue·stat_chance·learn_info·temple_merit·restore·give_item), CityShop·CityBank·CityTemple(패널형), CityContext, CityInfo
  ui/InputSetup.gd       data/input.json → InputMap
  ui/theme/UiTheme.gd    render.json → Theme, 위젯 생성 도우미
  ui/theme/GothicStyle   스톤샤드풍 창 꾸밈(돌판·칸·이름판·아치)
  ui/widgets/            ResourceBar, ResourcePanel, StatPanel, LogPanel(탐험 기록 이어 보기), DataSummary, ExploreHud, DebugPanel, BottomBar, ChoiceGrid(전투 고정 칸 선택판), SkillBrief, StatusTips, PauseMenu,
                         GothicWindow, InventoryGrid, PaperDoll, ItemTooltip, ItemIconPainter, ItemDragPreview, CommandMenu, EssencePanel, RiddleDialog, ChoicePopup(작은 선택 창 — W/S·Enter·Backspace) …
  ui/windows/            InventoryWindow, CharacterWindow, BestiaryWindow, WindowManager
  ui/city/               CityStreet(레이어 시차 스크롤 거리 + 강조 셰이더), CityHud(귀퉁이 카드 — 달력·탐험가·메뉴), CityUi(카드 스타일),
                         FacilityView(시설 내부), CityPanel + ShopPanel·BankPanel·EssenceRemovePanel, CityDebugPanel
  ui/combat/             BattleStage(전투 무대 — 어둠·빛 웅덩이, 적 정면·아군 뒷모습 배치), BattlerView, MonsterArt(몬스터 그림·몸 높이 색인), CombatFigure(그림 없을 때 몸 그리기), PartyRoster(파티 창), DropMark(쓰러진 자리의 드롭)·CombatDrops(전투 뒤 드롭 묻기)
  ui/screens/            TitleScreen(이어하기), CharacterCreateScreen, CityScreen, PlazaScreen(차원광장·포탈·저장), ExploreScreen, EndScreen, FoundationScreen(기반 점검), DataErrorScreen
tests/                   TestCase, run_tests.gd, test_*.gd(test_save 저장 · test_web 웹 배포 점검), smoke_ui.gd/.tscn
tools/                   check.sh, export_web.sh(웹 내보내기), validate_data.gd, screenshot.gd/.tscn, paint_city.gd + city_art/(도시 일러스트 생성 → assets/city/: Paint 캔버스·Ink 잉크/빛/색 보정·Mat 재질·Parts 건물 부품·Buildings(2)·Backdrop 뒷배경·Street 거리·Interiors 실내·Npcs·NpcParts 사람(피어 앤 헝거 인물화풍 — 따로 그려 바깥선·테두리 빛을 입혀 얹는다)·Plaza 차원광장), paint_monsters.gd + monster_art/(몬스터 전투 그림 → assets/monsters/: Clay 3D 덩어리 조형·Render 붓 칠/잉크/빗금·Rig 뼈대·Anatomy 몸·Face 얼굴·Hair·Kit 옷·Arms 무기·Extras 날개/꼬리·Fur 털·Beast(Head) 네발짐승·Things(2) 기괴체·Lord 계층군주 드레드피어·Finish 피/마감·Specs(2) 52종 설계 · 아군 뒷모습: Back 3D 몸을 돌려 투영·BackKit 옷·BackHair 머리·BackGear 갑옷/무기·Party 탐험가(종족×뒷/옆모습)·소환수 설계), floor_map.gd(층 전체 지도 PNG + 검사), sim_battle.gd(전투 승률), sim_party.gd + sim_parties.json(균열 4인 파티 → docs/balance/rift.md), exp_budget.gd(경험치 예산 → docs/balance/), formula_check.gd(평균 피해·처치 타수 → docs/balance/formula.md)
assets/                  fonts/ sprites/ audio/ shaders/(portal 포탈) city/(layers/ 거리 레이어 · buildings/ · interiors/ · plaza.webp — WebP) monsters/(<id>.webp 전투 그림 · <id>_back.webp 아군 소환수 뒷모습 + index.json 몸 높이) party/(<종족>_back|_side.webp 탐험가 전투 그림 + index.json)
```

## 핵심 개념 빠른 참조

- **수식**: `{키}` 자리표시자 + 사칙연산/`min`/`max`/`floor`(Godot Expression). 키 = `level`, `bal.<balance 경로>`, `<스탯 id>`. 예: `"{bal.hp.base} + {level} * {bal.hp.per_level} + {str} * {bal.hp.per_str}"`.
- **스탯 계산**: `(기본 + Σflat + Σ자식×coef) × max(0, 1+Σpercent)` → 클램프. 수정자는 출처(`source_id`)별로 붙이고 뗀다.
- **스탯 구성(2026-10-14)**: 주 스탯 5종(근력·민첩·물리내성·항마력·정신력) + 주 스탯으로 대체할 수 없는 세부 스탯 12종(시각·식욕·소화력·자연재생력·영혼 재생력·명중률·감응도 2(화염·냉기)·내성 4(화염·냉기·독·어둠))만 둔다. 새 세부 스탯은 고유 효과가 있을 때만 추가하고 규칙에 연결한다(`tests/test_sub_stats.gd`가 남은 목록·연결을 검사). 가정 ST1~ST5.
- **수정자 대상**: 스탯 id / `max:<자원>` / `regen:<자원>` / `dmg_taken:<피해유형|physical|magical|all>` / `dmg_dealt:…`.
- **자원(ResourcePool)**: 최대치 = 수식 → `max:<id>` 수정자. 코스트는 `{"soul": 5}`처럼 아무 자원이나. 임계값·고갈·회복은 시그널만 낸다(상태이상 부여는 소유자 몫). scope `dungeon_only`(허기)는 미궁 밖에서 정지·숨김.
- **시야**: 유효 시야 = min(층 상한 `visibility_cap_m`, max(주변광 `ambient_light_m`(암흑지대 0), 광원, 최소 시야) + 시야 스탯 보정). `Vision`.
- **3/4 시점 그리기**: 로직은 바닥 그리드, 벽은 윗면(앞면 높이만큼 위로) + 앞면. 바닥=FloorChunk(z 아래), 벽=WallRow(줄 단위 y-정렬), 캐릭터 발=정렬 기준, 남쪽 벽에 가려지면 실루엣. 밝기는 꼭짓점 색(정적 광원 LightField + 시야 빛).
- **탐험 규칙**: `ExploreSession`(순수 로직) — 시간은 실시간(`RealtimeDriver`: 실제 1초 = `realtime_hours_per_sec`시간, 전투·일시정지·디버그 패널·포커스 잃음이면 정지). 이동은 부드러운 연속 좌표(8방향, `fpos`)이고 시간을 쓰지 않는다. 속도 = 1칸 / (기본/(1+민첩×계수)) 게임 시간(몬스터와 같은 공식), 충돌은 `Kinematics`. 폐쇄 시각에서 자르고 경고(24/6/1h), 안전지대 휴식만 회복.
- **성장**: `data/progression.json`(레벨 표 0/8/50/250/660/…/18000, 만렙 11, 획득원) → `db.prog("경로")`. 레벨 변경은 `PlayerCharacter.set_level/change_level`(정수 슬롯 잠금 동기화). 레벨업 생명력·영혼력은 `balance.hp/soul` 수식.
- **피해 공식(명세 §1)**: 물리 = 무기(몬스터 `natural_weapon`) + 근력×2, 마법 = base + 정신력×2, 방어 100/(100+방어×4), 명중 = (스킬 accuracy 95 + 명중률 스탯) × (1 + 민첩 차×0.005). 효과 키: `accuracy`·`crit_bonus`·`ranged`·`power_if_status`·`drain_if_status`. 도주 = 50% + (아군 평균 − 적 평균 민첩)×2%p(10~90%), 수호자·군주전 불가.
- **패시브**: 몬스터 `passives[]`·정수 `passive` 같은 형식 → `Actor.passives`(`Passives.gd`: on_hit/on_crit/crit_bonus/power_vs_status/reflect_melee/status_immune/start_gauge/see_hidden/flee_penalty, 수정자는 소유자가 붙임).
- **몬스터 AI**: `ai: [{if, also[], use, target(lowest_hp|highest_hp|with_status|without_status), target_status}]` → 없으면 `ai_cycle` → 기본 공격. 상태 지속은 자기 차례 시작 때 준다(자기 행동에 거는 상태는 +1).
- **보스(G3)**: 몬스터 `pattern`(`src/combat/patterns/<id>.gd`, 수치는 `pattern_params`) + `phases`[{id, hp_above, message, self/foe_statuses, self_passives, target_rule, round_effects}]. **라운드 = 보스 자기 차례**(`BossHooks.turn_end`, 기절로 건너뛰어도 센다). 게이지는 `Actor.meters`(전투 끝에 비움), 전투 한정 상태는 `"battle_only": true`. 계층군주 소환은 층 JSON `lord` → `LordWatch`(혼자면 자연 소환 안 됨 — 디버그 버튼). 가정 DF1~DF15.
- **균열(G4)**: `rifts/<id>.json` = 개방 마석 `force_open`·`look` 타일·`chapters[]{map, encounters[battle|chain|waves|guardian], field_effects, on_enter}`·`guardian`·`variant`·`guardian_drops`·`numbers`. 입장하면 챕터마다 새 `ExploreSession`(생성기 `rift_chapter`)을 만들어 `transfer` 시그널 → Main이 화면을 바꾼다. 챕터 세션이 `rift_run`을 붙잡고 `RiftRun.session`은 약한 참조(순환 누수 방지). G8로 1층 균열 4개가 모두 명세 몬스터다(임시 문지기 삭제). 가정 RF1~RF15.
- **핏빛성채(G5)에서 생긴 키**: 패시브 `ally_aura`·`start_summons`·`foe_statuses_on_start`·`regen_per_round`·`status_duration_cap`·`dot_mult`·`mark_first_attacker`·`basic_attack_effects`, 몬스터 `types`(본 나이트)·`magic_stone_chance`·약점 `{multiplier, ignore_reduction, requires_status, on_hit_status}`, 범용 보스 패턴 `guardian`(`every`·`extra_status`·`mumbles`·`force_phase`·`per_foe_status`·`intro`), 예고 `guarded_mult`(추가 행동 차례엔 예고가 진행되지 않음), 균열 챕터 `exit_requires`·`hidden`, 아이템 `rift_bound`. **명세 수치가 시뮬레이터 목표를 벗어나면 몬스터 수치를 바꾸고 notes에 원래 값을 남긴다**(ASSUMPTIONS BF1). 대량 데이터는 스크래치 파이썬 생성기로 만들고 커밋하지 않는다.
- **빙하굴(G6)에서 생긴 키**: 효과 `barrier`(보호막 상태 `barrier: true`, 양 = 시전자 스탯 수식)·`permanent_stat`(영구 스탯, `key`·`max_times` — `Actor.boons`), `remove_status` `{"kind": "debuff", "count"}`, 피해 `rider {damage_type, ratio|flat}`·`str_bonus`·`defense_ignore`, 패시브 `hit_rider`·`self_statuses_on_start`·`turn_end_foe_status {status, target: all|random}`, `ally_aura {"all": true}`, 상태 `grants_immunity`·`crit_bonus`, AI 조건 `ally_hp_below`·대상 `ally_lowest_hp`, 예고 `warn`/`fire` 문구 키(대상이 여럿이어도 안내 한 번), 챕터 `hazards`(RiftHazards)·히든 피스 `near_entry`, 시뮬레이터 시나리오 `party_statuses`. **속성 내성·감응도**(`resist_<유형>`·`affinity_<유형>`)가 피해에 들어간다(GC1). 저체온증 민첩은 −30%(CTB, GC2).
- **녹색 탄광(G7)에서 생긴 키**: 효과 `split`(분열 — 같은 몬스터, 생명력 반씩)·`absorb_ally {monsters, heal_ratio}`, `summon` `rounds`(소환수 유지 차례), 패시브 `defense_ignore`·`on_damaged_by {damage_types, chance, self_damage_ratio}`·`death_effects`(쓰러지면 상대 전원)·`low_hp_summons {ratio, monsters}`, 상태 정의 `on_hit`(상태가 주는 적중 효과 — 독성부여), 챕터 `exit_requires.bypass {stat, at_least}`, 세부 스탯 `digestion`(소화력 → 허기). 수식 키 `{max_<자원>}`은 상태 periodic에서도 된다.
- **강철의 묘(G8)에서 생긴 키**: 함정 `hazards[].hidden·detect·disarm·bypass`(육감 탐지·손재주 해제·물리내성으로 밟아 부숨), 패시브 `trap_watcher`·`revive_once {ratio|hp}`, 상태 flag `always_hit`, `push_back` `chance`, `summon` `pick`, 균열 `riddle {set, weakened_status, empowered_status, essence_mult}` + 조우 `"riddle": true` + 벽화 `hidden[].mural` + 컬렉션 `riddles`(data/riddles), `Knowledge` 사실(`learn_fact`), 전투 규칙 `enemy_statuses`·`essence_mult`(`BattleRules.set_objective`), 피해 유형 `arcane`(무속성).
- **감사 수정(2026-10-13)에서 생긴 규칙**: 상태 `lingers`(전투 뒤 남음 — 나머지 차례 단위 상태는 전투 끝에 풀림, 탐험 중 `status.linger_hours_per_turn`시간 = 1차례), 아군 소환수 `Combatant.summoned`(AI·처치 아님·승패 제외), 피해가 빗나가거나 면역이면 딸린 효과 생략(`EffectContext.landed`, 효과 `always`/`to: self` 예외), 상태 부여는 `Passives.try_status`(면역·저항·지속 상한), 피해는 `DamageApply.hurt`, 효과 `apply_status` `to: self`·`unless_target_status`, `restore_resource` `non_lethal`, 스킬 `min_hp_ratio`, 수정자 `regen:<자원>:<기준>`. 가정 AU1~AU26.
- **상태이상 키(G4)**: `resist {stats}`(남이 건 것만 저항), `immune_if {stat, at_least}`, `on_max_stacks {status}`, `break_on_damage(_types)`, `heal_mult`, `misdirect {chance, pool, power_mult, ignore_defense}`, `battle_only`, 수정자 값에 수식 문자열(걸릴 때 계산).
- **전투**: CTB 속도 = 민첩 + `combat.speed_base`(5). `Battle`(phase: await_input → executing → turn_end → ended, 잘못된 행동은 `ActionCheck`가 막고 차례 미소모), 화면은 피어 앤 헝거식 정면 구도(`ui/combat/`: `BattleStage` 무대 — 적 정면·아군 뒷모습, `CombatFigure` 몸, `PartyRoster` 파티 창) + 아래 창 `CommandMenu`(명령 공격·스킬·방어·아이템, 도주는 스킬 목록 맨 끝), 모든 아군 기본 스킬 대화·조사(`balance.party.innate_skills`, `"innate": true`).
- **정수**: `essences/<몬스터 id>.json` = 패시브 1 + `actives[{color, skill}]`(정수판 스킬 `skills/ess_*.json`, `essence_of` = 원래 스킬 id) + `stat_ranges`. 사례 `{essence, color, stats}`, 무지갯빛 = 수호자(액티브 전부·스탯 ×1.5). 슬롯 = 레벨, 패시브·`essence_of`가 겹치면 거부. 수정자 출처 `essence:<id>`.
- **전투 드롭(2026-10-16)**: 정수·전리품은 쓰러진 무대 자리에 남고 전투가 끝나면 하나씩 "획득할까?" → 받을 사람(`CombatDrops`·`DropPickup`, `ExploreSession.grant_battle_rewards(…, defer_drops=true)`·`take_drop`·`leave_drop`). 두고 간 정수는 흡수 대기(흩어짐). 가정 UI13.
- **아이템**: `size` [w,h] · `stack` · `equip` {slot, two_handed, modifiers, weapon{damage_type, attack}} · `icon`/`color`/`rarity`. 장비 칸 이름은 `tags.equip_slots`.
- **도시(M4, 2026-10-14)**: 흐름 = 새 게임·귀환 → `CityScreen`(사망만 타이틀). 거리 좌표 = 화면 높이 720 기준 거리 단위(`render.json city`), 거리 = `city.json street.layers`(시차) 위에 시설 건물. 거리에서 시설을 고르면 행동력 `facility_entry_cost`(1) — **행동력은 입장에만 쓰고 시설 안 활동은 쓰지 않는다**, 활동은 `activities/<id>`(`cost_stones`·`effects[]`·`panel`). 순(상·중·하) × 12달, 순당 행동력 3, 다 쓰고 거리로 나오면 다음 순, **하순이 끝나면 저절로 차원광장 → 미궁**(`expedition_due`), 귀환하면 다음 달 상순(`return_from_dungeon`) (`CityState`, `GameState.city`). **시설 안 활동 한 번 → 저절로 거리로**(나가기 버튼 없음 — 창구형은 Esc·빈 곳 오른쪽 클릭으로 마침, 할 게 없으면 바로 나옴). 규칙 값은 2026-10-15 모두 임시값(`docs/balance/city.md`, CT26) — null로 되돌리면 효과 없음(검증기 경고 `CityValues.nulls`), 디버그 F1은 `CityValues.tunables`를 `CityState.overrides`로 임시 변경(저장 안 됨). 피로도 = `PlayerCharacter.fatigue`(`Fatigue`, 미궁 연결 지점 `on_dungeon` 4곳, 단계 효과 `effects()` → 수정자 출처 `fatigue`). 상점은 아이템 price, 정수 제거는 `EssenceSet.remove`. 한 칸 저장은 차원광장에서만(`SaveGame`, 사망 시 삭제), 하순이 끝나면 차원광장(`PlazaScreen`, 포탈은 한 달에 한 번 `expedition_month`). 가정 CT1~CT33.
- **새 콘텐츠**: JSON 한 파일/한 항목 추가 → `tools/validate_data.gd`로 확인. 새 효과 타입 = `src/combat/effects/<type>.gd`, 새 층 생성기 = `src/explore/generators/<id>.gd` 파일 하나, 새 도시 활동 효과 = `src/city/effects/<type>.gd`, 새 시설·활동 = `data/facilities`·`data/activities` JSON.
