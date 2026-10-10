# ASSUMPTIONS — 가정 기록

모호한 부분은 질문 대신 합리적으로 가정하고 여기에 남긴다. 형식: **가정 / 이유 / 바꾸는 방법**.

## 프로젝트·환경

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| E1 | 프로젝트 루트는 `C:\Users\kcw\Documents\dungeon-and-stone`(project.godot·godot_mcp 플러그인이 있는 곳)이고, 그 안의 `Dungeon And Stone/` 폴더(GitHub `Dungeon-And-Stone-Local` 클론, .gitattributes만 있음)는 건드리지 않는다 | 사용자가 편집기로 만든 Godot 프로젝트가 바깥 폴더에 있다 | 원격 저장소와 합치려면 바깥 저장소에 remote를 추가하고 `Dungeon And Stone/`을 정리한다(사용자 확인 후) |
| E2 | Godot **4.7.2**에 맞춘다 | 이 PC에 설치된 버전(`--version` 확인) | `project.godot` features와 CLAUDE.md 경로 수정 |
| E3 | 렌더러를 Forward+ → **GL Compatibility**로 바꿨다 | 웹 내보내기는 Compatibility만 지원, 2D 게임이라 손해 없음 | `project.godot [rendering] renderer/rendering_method` |
| E4 | 한글 폰트는 **Noto Sans KR Regular(한국어 서브셋 OTF, 4.6MB, OFL 1.1)** — 출처 notofonts/noto-cjk `Sans/SubsetOTF/KR`. 폰트가 없으면 시스템 한글 폰트로 대체 | Google Fonts 변수 폰트(10.4MB)보다 웹 내보내기 용량이 절반 이하. 굵은 글씨가 필요하면 같은 폴더의 Bold를 추가 | `render.json font.path`를 다른 파일로. 폴더에 넣은 첫 폰트가 기본값 |
| E5 | 기본 해상도 1280×720, stretch `canvas_items`/`expand` | 2D UI 기본값 | `project.godot [display]` |
| E6 | `untyped_declaration` 경고를 켰다(오류 아님) | 정적 타이핑 강제를 돕되 addons는 제외 | `project.godot [debug]` |

## 규칙·수치 (임시값은 데이터에 `source: placeholder`)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| R1 | 1타일 = 1m | 지시서 기본값 | `balance.explore.meters_per_tile` |
| R2 | 영혼력 Lv1 = 10, Lv5까지 레벨당 +10, 이후 +30 | 원작 규칙은 증가폭만 있고 시작값이 없음 | `balance.soul.*`, `resources.json soul.max_formula` |
| R3 | 최대 생명력 = 50 + 레벨×5 + 물리내성×2 + 근력×1 | 수치 근거 없음(임시) | `balance.hp.*` |
| R4 | 수정자 percent는 **합산 후 한 번** 곱하고, 배율 하한은 0 | 중첩 버프 폭주 방지, 직관적 | `StatBlock.apply_modifiers` |
| R5 | 세부 스탯의 상위 기여(parent×coef)는 상위 스탯의 **합연산 단계**에 들어간다 | 세부 스탯도 percent 버프 영향을 받게 | `StatBlock._value` |
| R6 | 스탯 그룹: 근력·민첩·물리내성 = 육체, **항마력·정신력 = 정신**, 감응도·영혼 재생력 = 이능, 육감·행운·명성·지지도 = 특수, 속성 내성 = 육체 | 원작 분류 미확인 | `stats.json group` |
| R7 | 투명 스탯 = 육감, 행운 | 숨은 탐지·확률 보정은 숨기는 편이 분위기에 맞음 | `stats.json visible` |
| R8 | 허기는 **포만도**(100=배부름)로 저장, 게이지도 포만도 방향으로 표시. 이름은 '허기' | 지시서 | `resources.json hunger.display_inverted: true`면 '허기도' 방향으로 표시 |
| R9 | 허기 감소 시간당 1(식욕 1당 +1%) → 100시간이면 0 | 1층 168시간 동안 식사 1~2회 필요 | `balance.hunger.*` |
| R10 | 허기 상태 이름: ≤30% '허기', ≤10% '굶주림', 0 '아사'(시간당 생명력 −2) | 지시서 명칭 | `statuses.json` |
| R11 | 최대치가 바뀌어도 현재값은 유지(넘치면 클램프) | 레벨업으로 회복되지 않는 하드코어 감각 | `ResourcePool.recompute_max` |
| R12 | 생명력은 코스트로 0이 될 수 없다(`cost_strict`) | 스킬 사용으로 자살하는 불합리 방지 | `resources.json hp.cost_strict` |
| R13 | 영혼탈진은 영혼력이 0보다 커지면 풀린다 | 원작 근거 없음 | `resources.json soul.on_zero.recover_at_ratio` |
| R14 | 영혼력 재생: 턴당 최대치의 2%, 시간당 5%, 휴식 시간당 +10% | 임시 | `balance.soul.*`, `balance.rest.*` |
| R15 | 시작 스탯 범위(인간 균형형, 바바리안 근력·물리내성↑ 정신력↓ 식욕↑) | 원작 분위기 반영 임시값 | `races.json`, `classes.json` |
| R16 | 리롤 3회, 종족·템플릿을 바꾸면 새 캐릭터로 보고 리롤 횟수 초기화 | 지시서 "제한된 횟수" | `balance.char_creation.max_rerolls` |
| R17 | 정수 슬롯 = 레벨 × 1 | 지시서 가정 | `balance.level.essence_slots_per_level` |
| R18 | 드레드피어 소환 최소 인원 3(원작 5) | 지시서 1차 테스트 기본값 | M5에서 `floors`/`rifts` 데이터에 `summon_min_party` |
| R19 | 지속시간 단위는 `turn`(전투)과 `hour`(게임 내 시간) 두 가지 | 전투 버프와 비약류를 모두 표현 | `Modifier.unit`, `statuses.json duration.unit` |
| R20 | 피해 유형: 참격·관통·타격(물리) + 화염·냉기·번개·대지·독·신성·어둠·태양(마법). 몬스터 계열에 인간형·구조체·슬라임 추가 | 둔기 약점(스톤골렘), 태양 약점(어둠 계열), 골렘·고블린·슬라임 분류 필요 | `tags.json` |

## 탐험 (M1)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| X1 | 1층 지도 72×72칸 | 생성 0.1~0.2초, 탐험 수십 시간 분량. 원작 규모 수치 없음 | `floors/f1_crystal_cave.json gen.size` |
| X2 | 1층 시야 상한 9m, 수정 빛(주변광) 6m, 횃불 7m — 모두 임시값 | 원문: "광원이 있어도 10m 미만", 1층은 수정 빛으로 횃불이 필요 없음, 횃불 반경 수치 없음 | `visibility_cap_m`, `ambient_light_m`, `items/torch.json radius_m` |
| X3 | 암흑지대 2~3곳, 반경 4~6칸. 그 안에서는 맨몸 시야 1m | 원문: 1층 암흑지대는 "극히 일부" | `gen.dark_zone_*`, `balance.explore.min_vision_m` |
| X4 | 한 칸 이동 = 0.02시간(1.2분) ÷ (1 + 민첩×0.02) | 168시간 폐쇄 안에서 탐험 분량이 의미 있게 | `balance.explore.move_*` |
| X5 | 미궁 시계는 입장 시 0부터. 도시 달력과 분리 | 원작: 도시 귀환은 항상 입장 다음 날 정오 | M4 `TimeSystem`에 도시 달력 추가 |
| X6 | 휴식(8시간)은 기념비 안전지대에서만 회복이 붙는다. 바깥 휴식의 습격 위험은 M2 | 안전지대의 의미 | `ExploreSession.rest`, `balance.rest.*` |
| X7 | 횃불은 한 번 켜면 끌 수 없고(약 72시간), 이미 타고 있으면 새로 켜지 않는다 | 원문: 한 번 켜면 약 3일 | `light_source` 효과 |
| X8 | 마른 식량 = 허기 +40, 300스톤. 모든 시작 템플릿이 횃불 2·식량 3을 가진다 | 원작 경제(한 끼 300스톤) 기준, 식량 없이 1층에 버티면 굶어 죽게(약 128시간) | `items/ration.json`, `classes.json start_items` |
| X9 | 층 폐쇄 경고는 24·6·1시간 전, 폐쇄되면 임시 결과 화면 → 타이틀(도시는 M4) | 강제 귀환 체감 | `balance.explore.closing_warning_hours` |
| X10 | 포탈은 동서남북 방향으로 가장 멀리 나간 바닥 칸 근처. 2층은 M6에서 열리므로 지금은 살피기만 가능 | 원작: 동서남북 4개의 2층 포탈 | `gen.portal_pick_band`, M6 |
| X11 | 층 시드 = 세션 시드·층 번호·입장 횟수의 해시. 디버그로 고정 가능 | 입장마다 지형이 바뀌되 재현 가능 | `GameState.next_floor_seed` |
| X12 | 그리기: 어둠은 CanvasModulate가 아니라 칸 꼭짓점 색으로 만들고(안개 기억과 함께 다루기 쉬움), PointLight2D는 횃불 빛 번짐만, CanvasModulate는 약한 색조만 | 셰이더·광원 차폐 없이 웹 호환, FOV와 일관 | `render.json view/lighting`, `FloorView` |
| X13 | 벽 타일 32×56(앞면 24px), 카메라 1.5배 | 지시서 "32×48 이상", 시야 원 전체가 화면에 들어오게 | `render.json view` |
| X14 | 캐릭터 스프라이트 시트는 가로 4프레임 [아래, 왼쪽, 오른쪽, 위] | 4방향 최소 | `ActorView.FRAME_ORDER` |
| X15 | 같은 상태이상을 두 출처가 걸어도 하나로 관리(먼저 풀리는 쪽이 해제) | 1차 단순화 | M2 StatusSet에서 출처별 관리 |
| X16 | 디버그 무적 = 생명력 하한 1 | 죽지 않되 규칙은 그대로 체감 | `DebugPanel` |

## 데이터·구조

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| D1 | `_`로 시작하는 데이터 파일/키는 템플릿·주석으로 보고 읽지 않는다 | JSON에는 주석이 없음 | `JsonUtil.list_json`, `Strings._flatten` |
| D2 | 데이터 항목 이름은 각 JSON의 `name_ko`, UI 문구는 `strings/ko.json` | 지시서 스키마 예시 | — |
| D3 | 정수 데이터는 사용자 요청으로 비워 두고, 칼날늑대의 `essence_drops`도 비움 | "정수 관련 설정은 우선 공백" | `data/essences/<id>.json` 추가 후 몬스터에 드롭 연결 |
| D4 | (M1에서 해소) 상태이상 부여·해제는 `StatusSet`이 맡고, 기반 점검 화면도 `Actor`를 쓴다 | — | — |
| D5 | 오토로드에는 `class_name`을 두지 않는다 | 오토로드 이름과 충돌 | — |
| D6 | 효과 타입·층 생성기는 "폴더의 파일 하나 = 항목 하나"(파일 이름이 id) | 새 타입을 기존 코드 수정 없이 추가 | `ScriptRegistry` |
| D7 | 입력 키는 data/input.json에서 물리 키 위치로 등록 | 한글 입력 상태에서도 WASD 동작, 키 재설정 기반 | `InputSetup` |
