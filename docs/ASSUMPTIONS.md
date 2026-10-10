# ASSUMPTIONS — 가정 기록

모호한 부분은 질문 대신 합리적으로 가정하고 여기에 남긴다. 형식: **가정 / 이유 / 바꾸는 방법**.

## 프로젝트·환경

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| E1 | 프로젝트 루트는 `C:\Users\kcw\Documents\dungeon-and-stone`(project.godot·godot_mcp 플러그인이 있는 곳)이고, 그 안의 `Dungeon And Stone/` 폴더(GitHub `Dungeon-And-Stone-Local` 클론, .gitattributes만 있음)는 건드리지 않는다 | 사용자가 편집기로 만든 Godot 프로젝트가 바깥 폴더에 있다 | 원격 저장소와 합치려면 바깥 저장소에 remote를 추가하고 `Dungeon And Stone/`을 정리한다(사용자 확인 후) |
| E2 | Godot **4.7.2**에 맞춘다 | 이 PC에 설치된 버전(`--version` 확인) | `project.godot` features와 CLAUDE.md 경로 수정 |
| E3 | 렌더러를 Forward+ → **GL Compatibility**로 바꿨다 | 웹 내보내기는 Compatibility만 지원, 2D 게임이라 손해 없음 | `project.godot [rendering] renderer/rendering_method` |
| E4 | 한글 폰트: `assets/fonts/`에 폰트가 없으면 시스템 한글 폰트(SystemFont: Noto Sans KR, 맑은 고딕 …)로 대체 | OFL 폰트 파일을 받으려면 사용자 허락이 필요. 데스크톱은 시스템 폰트로 정상 표시됨(스크린샷 확인) | `assets/fonts/`에 OFL 한글 폰트(.ttf/.otf)를 넣으면 자동 사용. 특정 파일은 `render.json font.path`. **웹 내보내기 전에는 반드시 번들** |
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

## 데이터·구조

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| D1 | `_`로 시작하는 데이터 파일/키는 템플릿·주석으로 보고 읽지 않는다 | JSON에는 주석이 없음 | `JsonUtil.list_json`, `Strings._flatten` |
| D2 | 데이터 항목 이름은 각 JSON의 `name_ko`, UI 문구는 `strings/ko.json` | 지시서 스키마 예시 | — |
| D3 | 정수 데이터는 사용자 요청으로 비워 두고, 칼날늑대의 `essence_drops`도 비움 | "정수 관련 설정은 우선 공백" | `data/essences/<id>.json` 추가 후 몬스터에 드롭 연결 |
| D4 | 상태이상의 실제 부여·해제는 M2 `StatusSet`이 맡고, M0 기반 점검 화면은 수정자만 임시로 붙였다 뗀다 | M0 범위는 자원·스탯까지 | M2에서 `FoundationScreen._set_status`를 StatusSet으로 교체 |
| D5 | 오토로드에는 `class_name`을 두지 않는다 | 오토로드 이름과 충돌 | — |
