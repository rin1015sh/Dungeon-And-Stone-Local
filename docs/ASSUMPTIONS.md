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
| R18 | (2026-10-12 DF9로 대체) 드레드피어 소환 최소 인원 3(원작 5) | 지시서 1차 테스트 기본값 | M5에서 `floors`/`rifts` 데이터에 `summon_min_party` |
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
| X17 | 탐험 시간은 실시간: 실제 1초 = 게임 0.1시간(6분). 가만히 있으면 1층 폐쇄(168h)까지 약 28분, 배부름 100 → 0까지 약 17분 | 사용자 요청(가만히 있어도 세계가 진행). 걷는 속도(민첩 10 ≈ 0.17초/칸)와 예전 한 걸음 시간(0.02h÷(1+민첩×0.02))이 맞물리는 값 | `balance.explore.realtime_hours_per_sec` |
| X18 | 실시간 틱 0.1초(몬스터 판정 초당 10회), 멈칫한 프레임은 최대 0.25초만 반영 | 몬스터 경로 계산 비용과 반응성의 균형, 창 이동·로딩 뒤 시간이 몰아 흐르지 않게 | `balance.explore.realtime_tick_sec`, `realtime_max_frame_sec` |
| X19 | 이동은 시간을 쓰지 않고 이동 간격(= 예전 한 걸음 시간)만 둔다. 계속 걸으면 남은 몫을 이어 받고, 2걸음분 넘게 서 있었으면 처음부터 센다 | 턴제 제거 + 연타로 빨라지는 것 방지 + 몬스터와 같은 속도 공식 | `ExploreSession.try_move/can_step` |
| X20 | 시간 정지: 전투·일시정지(Esc/P)·디버그 패널·입력칸 입력·창 포커스 잃음. 전투 시간은 끝날 때 차례 수 × 0.01시간으로 반영(기존 유지) | 메뉴를 보는 동안 죽지 않게, 전투는 턴제라 실시간과 겹치지 않게 | `RealtimeDriver` 정지 사유, `ExploreSession.resolve_encounter` |
| X21 | 대기(Space)는 "1시간 즉시 넘기기"로 남긴다 | 실시간이라도 시간을 빨리 보내는 수단이 필요(휴식 대기 등) | `ExploreScreen._unhandled_input` |

## 이동·충돌 (2026-10-11 부드러운 이동)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| V1 | Godot 물리 엔진(CharacterBody2D·TileMap 충돌)을 쓰지 않고 직접 만든 충돌(`Kinematics`)을 쓴다 | 규칙이 씬 트리 없는 순수 로직이라 헤드리스 테스트·시드 재현이 된다. 물리 서버는 고정 60Hz 물리 틱이라 게임 시간(전투 중 정지, 몬스터는 게임 시간으로 이동)과 따로 논다. 벽이 이미 격자라 칸 검사로 충분 | `src/explore/Kinematics.gd` |
| V2 | 몸 = 반폭 0.3칸 정사각형. 벽을 따라 미끄러지고, 한 칸 통로는 지나가고, 대각선으로 맞붙은 벽 틈은 못 지나간다 | 격자 벽과 자연스럽게 맞물리고, 발 위치가 늘 (북쪽 벽 줄, 남쪽 벽 줄) 사이라 3/4 시점 y 정렬이 뒤집히지 않는다 | `balance.explore.body_half_extent` |
| V3 | 터널링 방지: 한 번에 0.25칸 이하로 쪼개 움직인다. 모서리 걸림 보정 0.45칸 | 빠른 이동·큰 프레임에도 벽을 뚫지 않게, 통로 입구에서 걸리는 답답함 제거 | `explore.max_substep_tiles`, `explore.corner_assist` |
| V4 | 속도 = 1칸 / move_hours(게임 시간) — 예전 한 걸음 시간과 같은 공식. 대각선도 같은 속력(정규화) | 플레이어·몬스터가 같은 공식 | `explore.move_*` |
| V5 | 시야·안전지대·포탈·발견은 몸 중심이 있는 칸으로 판정(칸이 바뀔 때만 시야 재계산) | 기존 격자 규칙(FOV·지도) 유지, 매 프레임 FOV 비용 없음 | `ExploreSession.enter_cell` |
| V6 | 몬스터는 칸 길찾기로 다음 칸 중심(경유점)을 정해 연속으로 걷고, 2칸 안에서 보이면 곧장 다가가 1.05칸 거리에서 멈춘다. 다른 무리가 서 있거나 가는 중인 칸은 피한다 | 검증된 길찾기(거리 장)를 유지하면서 움직임만 부드럽게 | `MonsterSteering`, `monsters.direct_chase_tiles`, `contact_tiles` |
| V7 | 닿음 = 중심 거리 ≤ 1.05칸. 플레이어가 다가가며 닿으면 플레이어가 먼저 건 전투, 몬스터가 닿으면 몬스터가 먼저 | 예전 "옆 칸" 판정과 같은 거리감 | `FieldMonsters.touching/update` |
| V8 | 시간은 매 프레임 흘린다(큰 프레임은 0.05초 단위로 쪼갬). 몬스터 거리 장은 플레이어 칸이 바뀔 때만 다시 만든다 | 몬스터가 프레임마다 부드럽게 움직이도록 + 비용 절약 | `explore.realtime_max_step_sec`, `MonsterSteering.distance_field` |

## 성장·소지품 (M3)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| G1 | 레벨 n에 필요한 누적 공적: [0, 3, 8, 18, 40, 80, 150, 260, 420, 650, 1000], 1차 상한 5 | 원작: 1~4층을 다 잡아도 5레벨에 조금 못 미침(1층 4종 = 4). 수치 없음 → 임시값 | `balance.level.exp_table`, `max_initial` |
| G2 | 마석 드롭 확률 85%(등급 = magic_stone_grade), 9등급 20스톤·8등급 100스톤 | 원작 환율. 확률 수치 없음 | `balance.loot.magic_stone_chance`, `items/magic_stone_*.json` |
| G3 | 가방 10×6칸, 아이템 크기 1×1~2×3(창 1×4), 장비는 쌓이지 않음 | 스톤샤드식 공간 관리 | `balance.inventory`, 아이템 `size` |
| G4 | 장비 칸 11개(주무기·보조·머리·몸·망토·장갑·허리·신발·반지 2·목걸이), 양손 무기는 보조 칸을 막는다 | 스톤샤드 장비 인형 | `Equipment.SLOTS`, `tags.equip_slots` |
| G5 | 무기 공격력이 맨손 값(2)을 대신한다. 강철 무기 3~6 | 원작 장비 소재 1단계(강철). 수치 임시 | 아이템 `equip.weapon.attack` |
| G6 | 시작 장비는 템플릿별(start_equipment), 시작 돈 500스톤 | 빈손 시작은 너무 가혹 | `classes.json`, `char_creation.start_stones` |
| G7 | Knowledge: 마주침 = 이름·등급·계열·설명, 조사 = 생명력·스탯, 그 유형으로 쳐 봄 = 그 상성. 길드 정보 구매(M4) = 전부 | 원작 "정보의 가치" | `Knowledge`, `BattleKnowledge` |
| G8 | 소지품·캐릭터·도감 창이 열려 있으면 탐험 시간이 멈춘다 | 메뉴 규칙과 일관(X20) | `WindowManager.opened_changed` |
| G9 | 정수 드롭·흡수·삭제는 하지 않는다(캐릭터 창에 슬롯 수만) | 사용자 요청으로 정수 설정 보류 | `data/essences/` 채운 뒤 M4 이후 |
| G10 | 내구도·무게·상점은 아직 없다 | 범위 밖(상점 M4) | — |
| G11 | 아이템·UI 그림은 스프라이트 없이 코드로 그린다(`ItemIconPainter`, `GothicStyle`). 아이템 `sprite`가 있으면 그것을 쓴다 | 에셋 없음 | 아이템 json `sprite` |

## 전투 (M2 · 2026-10-11 행동창 재구성)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| C1 | 기본 행동창은 공격·방어·스킬·도주 4개. 약점 노리기는 공격의 대상 목록에, 아이템은 스킬 메뉴 맨 아래 "아이템…"으로 옮겼다 | 사용자 요청(4개 재구성) + 기존 기능 유지 | `CommandMenu` |
| C2 | 모든 몬스터는 말이 통하지 않는다. 대화하면 계열별 반응 문장만 나오고 차례를 쓴다(그 외 효과 없음) | 사용자 결정(2026-10-11) | 몬스터 데이터 `"talk": {"understands": true}` |
| C3 | 말이 통하는 상대(사람·장래 약탈자 등)와의 대화 결과: 머뭇거림(게이지 −40) · 무시 · 자극(게이지 +25) · 물러남(전투 이탈). 상대 생명력이 낮을수록 머뭇거림·물러남 쪽으로 기운다 | "통해도 반드시 전투가 끝나지는 않는다" — 임시값 | `skills/talk.json effects[0].outcomes` |
| C4 | 조사는 아무나 하나(적·아군)를 대상으로, 옛 정보와 같은 내용(등급·계열·생명력%·설명)을 알려 주고 차례를 쓴다(delay_cost 0) | 옛 정보 기능 유지 + 무료 행동 금지 | `skills/investigate.json`, `effects/investigate.gd` |
| C5 | 기본 스킬은 `"innate": true`로 표시해 잊을 수 없고(`Actor.forget_skill`), 다시 줘도 중복되지 않는다(불러오기 대비) | 앞으로의 스킬 습득·슬롯·삭제와 충돌하지 않게 | `PlayerCharacter.grant_innate_skills` |
| C6 | 잘못된 행동(모르는 스킬·코스트 부족·쿨타임·봉인·사라진 조사 대상·전투용이 아닌 아이템)은 차례를 쓰지 않는다. 고른 적이 이미 쓰러졌으면 다른 적을 친다 | 예외 처리 요구 | `ActionCheck`, `Battle._targets` |
| C8 | (G2에서 다시 봄 — L10) 장비가 생겨 1층이 쉬워졌다(테스트 캐릭터 기준 칼날늑대 둘 상대 승률 12/30 → 19/30, 단일 몬스터 30/30). 아직 조정하지 않음 | 실제 플레이로 확인 후 조정 | 무기 attack, 몬스터 stats |
| C9 | (2026-10-12) **CTB 유지**(사용자 결정, 명세 v2 §1의 라운드제·추가 행동은 쓰지 않음). 속도 = 민첩 + `speed_base` **5**. 민첩 10 vs 20이면 행동 1.67배(0이면 2배), 18 vs 12면 1.35배, 30 vs 12면 2.06배 — 작은 차이는 순서 위주, 큰 차이는 추가 행동이라는 명세 의도에 가깝게 | `tools/sim_battle.gd` 300회: speed_base 0에서 칼날늑대 둘 상대 승률이 가장 낮고(93%, 적/아군 행동 2.08) 5에서 98%(1.85). 10 이상은 민첩 투자 가치가 너무 줄어든다 | `balance.combat.speed_base` |
| C10 | (2026-10-12) Lv1 탐험가 민첩이 종족 범위상 5~10으로 명세 기준 탐험가(인간 Lv1 민첩 12)보다 낮다. G2에서 몬스터를 명세 수치(칼날늑대 민첩 18 등)로 바꾸면 차이가 커지므로 그때 종족 범위·speed_base를 시뮬레이터로 다시 맞춘다 | 몬스터는 아직 v1 임시 수치 | `races.json stat_ranges`, `speed_base` |
| C7 | 라운드 개념은 두지 않는다(CTB). 쿨타임·지속시간은 자기 차례 시작 때 줄고, 차례 종료 시 turn_end 사건을 낸다 | 민첩 기반 CTB와 일관 | `Battle.phase` |

## 정수 (2026-10-12, docs/PROMPT_FLOOR1_V2.md §2·§3·§6)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| J1 | 정수 데이터는 몬스터당 파일 하나(`essences/<몬스터 id>.json`), 색은 `actives[{color, skill}]`로 고른다. 사례(떨어진 정수) = `{essence, color, stats}` | 원작 규칙 "색이 액티브를 정한다"를 그대로 데이터로 | `EssenceDrop.make`, 템플릿 `_template.json` |
| J2 | 정수판 스킬은 별도 파일 `skills/ess_*.json`으로 만들고 수치를 미리 약화(위력 ×0.85·확률 ×0.75·지속 −1·비용 ×1.2)해 둔다. 실행 중 자동 약화는 하지 않는다 | 몬스터판(G2에서 만들 `ghoul_claw` 등)과 독립적으로 조정 가능, 기존 몬스터 전투를 바꾸지 않음 | `balance.essence.weaken`은 기준값 기록용 |
| J3 | 중복 흡수 판정 키 = 패시브 id + 스킬의 `essence_of`(원래 스킬 id). 같은 몬스터 다른 색은 패시브가 겹쳐 거부 | 원작 규칙 + 변이종 공유 스킬 id(§6.0) | `EssenceSet.conflict_keys` |
| J4 | 수호자 정수 = 색 `rainbow`, 액티브 전부(unique 제외) + 스탯 ×1.5. 같은 정수의 일반 → 무지갯빛은 그 자리를 바꾼다(업그레이드) | 원작 규칙 | `balance.essence.guardian_*`, `EssenceSet.upgrade_index` |
| J5 | 흡수하지 않은 정수가 사라지는 시간은 **게임 3시간**(원작 30분) | 실시간 1초 = 6분이라 30분이면 실제 5초 — 창을 열 틈이 없다. 실제 약 30초로 늘림 | `balance.essence.expire_hours` |
| J6 | (G2에서 대부분 해소 — 지금은 추적 후각의 냄새 흔적 오버레이만 남음) 패시브 중 표현할 수 없는 것은 `"implemented": false`로 두고 툴팁에 "일부만 들어가 있다"를 띄운다 | 적중 시 발동·우선도·맵 오버레이 체계가 아직 없음 | 해당 체계를 만든 뒤 `passive`에 필드 추가 |
| J7 | (G2: 실명은 명중률 −30, 일체화는 은신 + 공격 +30%) 덫 생성은 다음 차례에 고정 피해(`status.trap_damage` 6)를 주는 상태이상 `trap_set`, 실명은 민첩 −30%, 일체화는 주는 피해 +30% 1차례로 근사. 속박·은신·명중 감소는 없음 | 해당 전투 체계(속박·은신·명중 스탯)가 G4 범위 | `statuses.json` |
| J8 | 정수 스탯 `patience`(인내심)·`dexterity`(손재주)·`stealth`(인식방해)를 추가했지만 효과는 아직 없다 | 원작 정수 스탯 표기 | `stats.json` |
| J9 | 정수 드롭 확률: 등급별 2~4%(9→5등급), 무등급 0.5%, 중간 보스 10%, 수호자 33%, 균열 안 ×4. `drop_mode: "original"`이면 0.01% | 명세 §3 | `balance.essence.drop_*` |
| J10 | 정수 삭제(제거)는 로직과 비용(500만 → ×2)만 있고 버튼은 없다 — 대신전(M4)에서 붙인다 | 시설이 아직 없음 | `EssenceSet.remove/next_delete_cost` |

## 성장 체계 G1 (2026-10-12, docs/PROMPT_FLOOR1_V2.md §5)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| L1 | 레벨 표·경험치 획득원·예산은 `data/progression.json`(새 단일 파일, `db.prog()`), 레벨업 때 오르는 생명력·영혼력 수치는 자원 수식이 쓰는 `balance.hp`/`balance.soul`에 둔다 | 자원 수식(`{bal.…}`)이 balance만 읽는다 | `progression.json`, `balance.hp/soul` |
| L2 | 최대 생명력 = 50 + 레벨×10 + 근력×1.5 + 물리내성×3, 영혼력 Lv1 30 → 5레벨까지 +10 → 이후 +30 | 명세 §1·§5.1 | `balance.hp`, `balance.soul` |
| L3 | 몬스터의 `exp_first_kill` 필드를 없애고 경험치는 항상 계산(10 − 등급, `upper_variant` +1, `rank` ungraded/token 0) | 명세 §14 "경험치 = 10 − 등급" 검사와 한 곳에서 맞추기 | `Progression.first_kill_exp` |
| L4 | 레벨 하락 시 정수는 **사라지지 않고 잠긴다**(무작위, 효과 없음, 슬롯 차지), 레벨이 돌아오면 먼저 흡수한 순서대로 풀린다 | 명세 §5.1 본문(G1 항목의 "초과 정수 소실"보다 자세한 쪽을 따름) | `EssenceSet.sync_slots` |
| L5 | 포탈 경험치: 1~5층 포탈은 (포탈, 달)마다 첫 통과에 +2, 6층부터는 포탈마다 한 번. 몇 월인지는 호출하는 쪽이 넘긴다 | 달력은 M4 | `Progression.record_portal(db, id, floor, month)` |
| L6 | 포탈 통과·숨겨진 포탈·꿈꾸는 영혼은 API만 있고 아직 부르는 곳이 없다(2층 이동·히든 지역·아이템은 G4·M6) | 해당 콘텐츠가 없음 | `record_portal`, `record_hidden_portal`, `use_dreaming_soul` |
| L7 | 꿈꾸는 영혼: 먹으면 대기, 10레벨에 닿는 순간 +10,000(이미 10레벨이면 바로) | 명세 "복용 후 10레벨 도달 시" | `Progression.gain` |
| L8 | 몬스터 층 = `floor` 필드, 없으면 `floor_tags`의 `f<n>_` | 기존 데이터 호환 | `Progression.monster_floor` |
| L9 | 경험치 예산은 데이터가 목표보다 적은 층을 목표치로 대체해 '예상' 합산(지금 1층 실제 4 / 목표 110) | 명세 §5.5 | `ExpBudget` |
| L10 | 지금 1층 몬스터는 v1 수치라 새 생명력 공식으로 1층이 쉬워졌다(시뮬레이터 승률 98~100%). G2에서 명세 수치로 바꾸며 다시 맞춘다 | 몬스터 개편은 G2 범위 | `tools/sim_battle.gd` |

## 1층 필드 G2 (2026-10-12, docs/PROMPT_FLOOR1_V2.md §1·§6)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| F1 | 전투 공식을 명세 §1로 바꿨다(근력×2, 방어×4, 명중 95 × (1 + 민첩 차×0.005), 치명 5% + 민첩×0.3%). 명중 상한 100% | 명세 몬스터 수치가 이 공식 기준 | `balance.combat` |
| F2 | 몬스터 기본 공격 = `natural_weapon {attack, damage_type, ranged}` | 명세 "몬스터는 natural_weapon" | 몬스터 JSON |
| F3 | 패시브는 몬스터 `passives`와 정수 `passive`가 같은 형식(수정자·on_hit·on_crit·crit_bonus·power_vs_status·reflect_melee·status_immune·start_gauge·see_hidden·flee_penalty) | 정수판 = 몬스터판의 약화본이라 한 체계로 | `Passives.gd` |
| F4 | 우선도(+1)는 CTB라 없다. 구울 '첫 라운드 우선도 +1' = 전투 시작 게이지 +30, '다음 라운드 맨 뒤' = delay_cost 50 | 라운드가 없음(C7·C9) | `start_gauge`, `delay_cost` |
| F5 | 상태이상 지속시간은 자기 차례 시작 때 준다 → 자기 행동에 걸리는 상태(실명·공격 버프·은신)는 '효과 볼 차례 + 1'로 준다(명세 2R 실명 = 3) | 기존 StatusSet 규칙 유지 | `statuses.json duration` |
| F6 | 은신(hidden) = 다른 상대가 있으면 고를 수 없음. 추적 후각(see_hidden)은 꿰뚫음 | 명세 §6.3·§6.6 | `BattleRules.targetable` |
| F7 | 덫 생성 = 다음 차례 고정 피해(trap_damage) + 속박(도주 불가·민첩 −20%). 무리 사냥 = 고정 근력 +20%(정수판 +10%) | 상태이상 체계로 근사 | `statuses.json`, 스킬 JSON |
| F8 | 몬스터 계열은 새 필드 `lineage`(goblin·ghoul·blade_wolf·gnome). 기존 `family`(상성 태그 배열)와 이름이 겹쳐서 | 명세 §2의 family | 몬스터 JSON |
| F9 | 무리 크기는 v1 크기(고블린 2~3, 칼날늑대 1~2) 유지. 명세 "서너 마리"는 혼자인 Lv1에게 승률 10~40% | 동료(M4) 전까지 | `behavior.pack_size` |
| F10 | 변이종: 지역 `variants` — 3일 차부터, 지역 바깥쪽(중심에서 지역 최대 거리의 50% 이상) 무리의 각 마리가 20% 확률로 같은 계열 변이종 | 명세 §6.0 "외곽에서 무리의 20%" | 층 JSON `regions[].variants` |
| F11 | 필드 은신: 스킬 `field_stealth {still, moving}`을 가진 탐험가는 몬스터 인식 반경이 그만큼 준다. '서 있음' = 마지막 이동 뒤 게임 0.02시간(실제 약 0.2초) | 명세 도둑걸음·일체화 field_use | `explore.stealth_still_hours` |
| F12 | 무기 공격력과 종족 스탯 범위를 명세 기준 탐험가에 맞춰 올렸다(`docs/balance/floor1.md`) | 공식 변경으로 옛 수치가 너무 약함 | `items/*.json`, `races.json` |
| F13 | 도주 확률을 명세 §1로 맞춤: 50% + (아군 평균 민첩 − 적 평균 민첩)×2%p, 10~90%. 상대에 수호자·계층군주(`no_flee_ranks`)가 있거나 속박이면 0이고, 도주 명령은 차례를 쓰지 않고 거부(`combat.reason_no_flee`). 이전엔 "자기 민첩 − 가장 빠른 적"×3%, 5~95% | 2026-10-12 공식 점검에서 명세와 어긋난 유일한 항목 | `balance.combat.flee_*`, `BattleRules.flee_chance` |

## 균열 공통 G4 (2026-10-12, docs/PROMPT_FLOOR1_V2.md §4·§8·§15)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| RF1 | **1달 = 원정 1회**. 자연 개방 달력(`RiftCalendar`)은 원정을 시작할 때 굴린다. 달마다 확률: 0·1달 0, 2달 10%, 3달 20%, 4달 45%, 5달 60%, 6·7달 50%, 8달 이상 100%(대부분 4~5달). 새 탐험가는 "직전 개방 뒤 4달"에서 시작 | 도시 달력(M4) 전. 원작 "2주기 이후, 대부분 4~5주기, 8주기면 확정" | `balance.rift.open_chance_by_months`, `start_months_since_open` |
| RF2 | 자연 개방은 그 원정의 48시간 ~ 폐쇄 24시간 전 사이 무작위 시각. 포탈 3~5개(원작은 수천 개)를 서로 8칸 이상 떨어뜨려 놓고, 종류는 들어갈 때 4종 가중 무작위(지금 가중치 모두 1) | 명세 §8.1 [변] | `balance.rift.*`, `rifts/*.json weight` |
| RF3 | 강제 개방: 4종 모두 **대현자 기념비**에서 바친다(명세는 핏빛성채만 기념비, 나머지는 '제단'). 녹색 탄광은 홉고블린 마석 허용. 2층이 없어 마석은 디버그 "균열 개방 마석 4종 받기"로만 얻는다. 강제 개방은 자연 개방 달력에 영향 없음 | 1층에 제단 랜드마크가 없다 | `rifts.force_open.at`, 2층(M6) |
| RF4 | 균열 포탈에 들어가면 그 포탈은 닫힌다(다른 포탈은 층이 닫힐 때까지 남는다). 균열 안 시간도 층 시계로 흐르고, 층이 닫히면 균열 안에서도 강제 귀환 | 인스턴스지만 원정 시간은 하나 | `RiftRun.chapter_floor_def` |
| RF5 | 챕터 = 방 n개를 통로로 이은 작은 맵(`rift_chapter` 생성기) + 고정 조우. 조우를 모두 치워야 출구가 열린다. 조우 무리는 필드 몬스터처럼 다가온다(어그로 반경) | 명세 §8.3 [변] | 균열 JSON `chapters[].map`·`encounters` |
| RF6 | 생존 웨이브의 **라운드 = 아군 맨 앞 참가자의 차례 하나**. 라운드마다 증원(한 진영 최대 6), 버티면 적이 남아도 승리. 적을 먼저 다 잡아도 승리. 생존 전투는 도주 가능(필드 무리처럼 다시 다가온다) | CTB | `BattleObjective` |
| RF7 | 연전(chain)은 이기면 맵 시간 없이 곧바로 다음 전투(생명력·상태 그대로). 도망치면 그 무리가 남은 구성을 지닌 채 남는다 | "사이 휴식 없음" | `RiftRun.on_battle_end` |
| RF8 | 수호자 드롭: 정수는 랭크(guardian 33%, 정수 데이터가 있을 때), 균열석 66%·넘버스 33%(균열 `numbers`가 있을 때)는 균열 데이터. 수호자 +3은 랭크로(반복). 변종 수호자 3%(녹색 탄광·강철의 묘는 명세에 변종이 없어 없음) | 명세 §8.2·§8.3 | `rifts.guardian_drops`·`numbers`·`variant` |
| RF9 | **G4의 균열 내용은 임시**: 조우는 1층 필드 몬스터로, 수호자는 "균열 문지기(임시)"(예고 내려찍기·휩쓸기)·"뒤틀린 균열 문지기(임시)"로 대신한다. 몬스터 `placeholder_content: true`(경험치 예산 제외), 균열 `stand_in: true`. G5~G8에서 명세 몬스터·수호자로 바꾸고 임시 파일은 지운다 | 공통 시스템을 먼저 시험 | `rifts/*.json`, `monsters/rift_warden_standin*.json` |
| RF10 | 임시 수호자 수치는 파티 시뮬레이터로 맞췄다: 생명력 1100, 내려찍기 위력 4.5(쿨타임 3, 2라운드 뒤 찍힌 대상 — 막지 않으면 거의 쓰러짐). 예고 무시 45% / 방어로 대응 94% / 변종 0%(`docs/balance/rift.md`) | 명세 §15 "첫 시도 40~60%, 예고 대응 AI 75% 이상" | `tools/sim_parties.json` |
| RF11 | 상태이상 저항: 남이 건 것만, 확률 = min(60%, 저항 스탯 합 × 1%). 저항 스탯은 명세 표대로(기절·혼란 = 정신력·항마력/정신력, 마비 = 물리내성, 석화·진압 = 항마력, 서리·빙결 = 냉기 내성, 봉인 = 정신력). G2 이전 상태이상(고블린 마비독 등)은 저항 없음 그대로 | 명세 §4 '저항' 열, 수치 [창] | `balance.status.resist_*`, 상태 `resist` |
| RF12 | 진압 지속 3턴·혼란 3턴·원한 3턴·봉인 2턴은 [창]. 석화 해제는 `remove_status`(정화 스킬은 아직 없음). 원한의 징표(벤시)·제물(캠보르미어)은 상태만 — 효과는 G5 | 명세에 수치·주체 없음 | `statuses.json` |
| RF13 | 저체온증 수정자는 **걸릴 때** 냉기 내성으로 계산한다(도중에 냉기 내성이 바뀌어도 다음 챕터 진입 때 갱신) | 상태 수정자는 정적 | `StatusSet._mods` |
| RF14 | 빙하굴 3챕터 낙하 "전원 위력 40"은 고정 20 피해로 바꿨다(공격자가 없는 피해) + 폭포 최대 생명력 10% | 맵 사건이라 공격자 없음 | `balance.rift.fall_damage` |
| RF15 | 예고형 패턴 공통 = 효과 `delayed` + `"target": "cast"`(찍힌 대상에게 [예고] 상태). 시뮬레이터의 '예고 대응 AI'는 [예고]가 찍힌 차례에 방어 | 명세 §14 예고형 패턴 | `BattleDelayed`, `tools/sim_party.gd` |

## 계층군주 드레드피어 G3 (2026-10-12, docs/PROMPT_FLOOR1_V2.md §7)

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| DF1 | **라운드 = 보스 자신의 차례 하나**(CTB라 라운드가 없음). "라운드 종료" 처리(갉아먹는 공포·역병 확산·주기 소환·장막 순환)는 보스 차례가 끝날 때, 기절로 건너뛴 차례도 라운드로 센다. "라운드당 2회 행동"은 차례 뒤 게이지를 한 번 더 채워 곧바로 한 번 더(같은 라운드) | 사용자 결정 CTB 유지 | `BossHooks.turn_end`, `BossPattern.wants_extra_action` |
| DF2 | 탐험가 쪽 "nR" 지속(고립 2R 등)은 그 탐험가의 차례로 센다(기존 상태이상 규칙). 장막·그로기처럼 보스 순환에 묶인 것은 패턴이 보스 라운드로 걸고 푼다 | 기존 StatusSet 규칙 재사용 | `pattern_params.cycle` |
| DF3 | 분노 게이지 최대 50(명세엔 최대치 없음). 받은 피해 1%당 +1이라 100이면 죽을 때까지 안 찬다. 가득 차면 3라운드(+1) 동안 모든 피해 ×2 후 초기화 | "가득 차면 피해 ×2"가 의미 있으려면 한 번은 차야 함 | `meters.json dread_rage`, `statuses dread_rage` |
| DF4 | 증오 게이지는 P3부터 라운드마다 +5, '뼈에 새겨진 기억' 적중 시 +5. 가득 차면 증오 폭발(매 차례 적 전체 위력 200, 초기화 안 함) — P3 진입 뒤 약 20라운드가 사실상 제한 시간 | 명세는 "가득 차면 실패"만 있고 오르는 방법이 [원] 버프 하나뿐 | `pattern_params.hatred`, 버프 패시브 |
| DF5 | 버프 5종 중 [창] 4종(효과 "—")을 새로 정함: 밀랍 갑주 받는 물리 −30%, 응시하는 눈 명중 +20·치명 +10%, 구더기 둥지 라운드마다 구더기 1체, 원망의 메아리 적중 시 원망 +6 | 명세에 효과가 비어 있음 | `statuses.json dread_buff_*`, `pattern_params.buffs` |
| DF6 | 내면의 거울의 "우선도 +2"는 CTB에 우선도가 없어 뺐다(회피·방어 불가는 고정 피해로 구현) | CTB | 스킬 `delay_cost`/게이지 보너스 |
| DF7 | 공포(가득 참) = 기존 [공포] 상태(민첩 −10%, 3턴, 차례마다 30% 확률로 움직이지 못함 `combat.may_skip_chance`). 무기력증·탈진 지속 3턴 | 명세에 지속 없음 | `statuses.json` |
| DF8 | 탈진의 "행동 비용이 영혼력으로 전환"은 아직 없다(육체 스탯 −30%만) | 행동 비용 체계가 없음 | 후속 |
| DF9 | **소환 인원**: 명세대로 `min_party` 5. 동료(M4) 전에는 혼자라 자연 소환되지 않는다 → 디버그 "계층군주 소환"으로 시험. 전의 R18(최소 3)은 대체 | 명세 §7.1 | 층 JSON `lord.min_party` |
| DF10 | 소환 확률: 3일 차(48시간)부터, 처음 머문 자리 반경 5m 안에서 머문 시간 t에 시간당 위험률 0.01×2^(t/4) → 12시간 약 33%, 24시간 약 97%. 머문 지 3시간에 첫 전조 | "하루 안에 사실상 확정" | 층 JSON `lord.*` |
| DF11 | 소환되면 군주가 4칸쯤 떨어진 곳에 필드 무리로 나타나 다가온다(어그로 40m, 은신 무시). 소환 중 시야 2m, 화면 붉은빛(`lord.tint`). 쓰러뜨리면 6시간 재소환 대기, 수정 빛은 원래대로("처치 시 수정이 꺼진다"는 층 전체를 어둡게 하는 것으로 보지 않음) | 원작 묘사를 맵 규칙으로 | `LordWatch` |
| DF12 | 패배 = 소환 조건을 채운 탐험가만 사망, 나머지 생명력 1로 생존 — 지금은 혼자라 그냥 사망. 동료가 생기면 `LordWatch.on_battle_end`에서 처리 | 파티 없음 | M4 |
| DF13 | holy_fire 정화(공포 −30), 클랜 승급, 고독의 무저갱·순례자의 동굴은 아직 없다(P4 플래그 `old_memory`/`twisted_memory`와 메시지만) | 해당 시스템이 없음 | 사제 스킬·클랜(M4 이후) |
| DF14 | 드레드피어 등급 6은 [창](경험치에 쓰지 않음). 첫 처치 경험치 대신 군주 보너스 15만(`no_exp_ranks`에 lord) — 명세 §5.6 "드레드피어 15" | 명세 합계 108과 일치 | `progression.json` |
| DF15 | 혼자 싸우면 거의 진다(뼈 대검 한 번에 Lv4 기준 생명력의 80%대). 권장 Lv4~5 × 5인 레이드 보스라 그대로 둠. 파티 시뮬레이션은 G4의 `tools/sim_parties.json` 때 | 명세 수치 | — |

## 데이터·구조

| # | 가정 | 이유 | 바꾸는 방법 |
|---|---|---|---|
| D1 | `_`로 시작하는 데이터 파일/키는 템플릿·주석으로 보고 읽지 않는다 | JSON에는 주석이 없음 | `JsonUtil.list_json`, `Strings._flatten` |
| D2 | 데이터 항목 이름은 각 JSON의 `name_ko`, UI 문구는 `strings/ko.json` | 지시서 스키마 예시 | — |
| D3 | (2026-10-12 해소) 정수는 사용자 요청으로 `docs/PROMPT_FLOOR1_V2.md` 기준 1층 필드 원종 4종부터 채웠다. 몬스터 `essence_drops`는 비워 두면 등급별 확률로 자동 드롭 | — | 아래 "정수" 절 |
| D4 | (M1에서 해소) 상태이상 부여·해제는 `StatusSet`이 맡고, 기반 점검 화면도 `Actor`를 쓴다 | — | — |
| D5 | 오토로드에는 `class_name`을 두지 않는다 | 오토로드 이름과 충돌 | — |
| D6 | 효과 타입·층 생성기는 "폴더의 파일 하나 = 항목 하나"(파일 이름이 id) | 새 타입을 기존 코드 수정 없이 추가 | `ScriptRegistry` |
| D7 | 입력 키는 data/input.json에서 물리 키 위치로 등록 | 한글 입력 상태에서도 WASD 동작, 키 재설정 기반 | `InputSetup` |
