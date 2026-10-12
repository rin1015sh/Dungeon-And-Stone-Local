# PROGRESS — 진행 상황

> 새 세션은 `CLAUDE.md` → 이 문서의 **현재 상태**와 **다음 할 일**부터 읽는다.

## 현재 상태 (2026-10-12)

- **M0 기반: 완료 · 검증됨**, **M1 탐험: 완료 · 검증됨** (Godot 4.7.2, Windows, `tools/check.sh` 전 단계 통과 + 스크린샷 확인)
- 실행하면 타이틀 → **새 탐험가**(이름·종족·템플릿·스탯 굴림) → **1층 수정동굴**(매번 새로 생성)을 3/4 시점으로 탐험한다. 시야·안개·횃불·허기·시간·층 폐쇄·아사가 작동하고, F1로 디버그 패널을 연다. 층이 닫히거나 죽으면 결과 화면 → 타이틀(도시는 M4).
- 원격 저장소: GitHub `rin1015sh/Dungeon-And-Stone-Local`. 2026-10-11 커밋(M2·이동·M3)은 `main`에 있다. **2026-10-12 클라우드 세션 작업(정수 1차·G1)은 `main`이 아니라 브랜치 `claude/godot-github-desktop-integration-p3rs6d`에 있다** — GitHub 첫 화면(main)에는 안 보인다. 데스크톱에서 이어가려면 이 브랜치를 체크아웃/pull하거나 main에 병합한다(PR 또는 `git merge`). 안쪽 `Dungeon And Stone/` 폴더는 예전 클론으로 이제 필요 없다(사용자가 지워도 된다).
- **사용자 결정 (2026-10-12)**: ① 전투는 **CTB 유지**(명세 v2 §1의 라운드제는 쓰지 않음) — 민첩 차이를 완화하는 `speed_base` 5 도입 ② **도시(M4)는 미궁 1층을 완전히 완성한 뒤**에 한다 → 순서는 G1 → G2 → G3 → G4 → G5~G8 → M4.
- **G2 1층 필드 10종: 완료 · 검증됨 (2026-10-12)** — 명세 전투 공식, 패시브 체계, 은신·속박·증원·반격·흡혈, AI 규칙 확장, 몬스터 10종(변이종 6 포함)·정수 10종, 변이종 출현, 필드 은신, 도감 공유 이능, 시뮬레이터 목표 충족. 아래 "G2" 절.
- **G1 성장 체계: 완료 · 검증됨 (2026-10-12)** — 레벨 표·만렙 11·획득원(`data/progression.json`), 레벨업 보상(생명력·영혼력 공식), 레벨 하락 시 정수 슬롯 잠금, 경험치 예산 도구, 전투 시뮬레이터. 아래 "G1" 절.
- **정수 1차: 완료 · 검증됨 (2026-10-12, 클라우드 리눅스 Godot 4.7.2)** — 사용자 제공 명세 `docs/PROMPT_FLOOR1_V2.md`를 기준으로 정수 시스템(드롭·흡수 대기·흡수·중복 거부·수호자 업그레이드·제거/삭제 비용·저장)과 1층 필드 원종 4종(고블린·구울·칼날늑대·노움)의 정수 데이터를 넣었다. 기존 몬스터 전투·레벨 표는 건드리지 않았다(G1·G2 범위로 남김). 아래 "정수 1차" 절.
- **M3 성장: 완료 · 검증됨 (2026-10-11)** — 부드러운 이동(연속 좌표·충돌), 경험치·도감·레벨업, Knowledge(`???`), 마석 드롭, 장비 11칸·격자 가방, 스톤샤드풍 UI(소지품·캐릭터·도감 창, 하단 바·단축칸). 정수는 2026-10-12 "정수 1차"에서 붙였다.
- **M2 전투: 완료 · 검증됨** — 전투·필드 몬스터 구현 위에 2026-10-11 사용자 요청으로 **탐험 실시간화 · 전투 행동창 4개 · 기본 스킬(대화·조사) · 상단 순서 표시 제거**를 반영했다. check.sh 전 단계 통과(테스트 102/102, UI 스모크 4흐름) + 전투·일시정지 스크린샷 확인.

## 마일스톤 체크리스트

### M0 기반 ✅
- [x] 프로젝트 골격(§13 폴더), 오토로드(EventBus, DataRegistry, GameState, AudioBus)
- [x] 렌더러 GL Compatibility(웹 호환), 1280×720, nearest 필터
- [x] 한글 폰트/테마: `UiTheme`(render.json 팔레트), Noto Sans KR 번들(OFL)
- [x] DataRegistry/GameDatabase: manifest 기반 로드(singletons + collections, `_` 템플릿 제외)
- [x] StatDef/StatBlock/Modifier: 레지스트리, 계산 순서, 출처별 제거, 지속시간(turn/hour), 세부→상위 기여, 저장
- [x] ResourceDef/ResourcePool: 생명력·영혼력·허기 + 예약 자원 4종, 수식 최대치, 코스트, 임계값, 범위, 재생, 저장
- [x] Formula(`{키}` 수식), Rng(시드 고정), Strings(ko.json 로더)
- [x] 데이터 검증기, `tools/validate_data.gd`, 테스트 러너, UI 스모크, `tools/check.sh`
- [x] 기반 점검 화면, 데이터 오류 화면, `tools/screenshot.tscn`
- [x] 문서: CLAUDE.md, docs/DESIGN.md, PROGRESS.md, ASSUMPTIONS.md, PROMPT.md(원본), README.md

### M1 탐험 ✅
- [x] 3/4 시점 렌더링: 벽 윗면(어두운 천장)+앞면(돌 줄눈)+모서리·테두리 선, 줄 단위 Y-정렬, 남쪽 벽에 가려지면 실루엣 — 수치는 `render.json.view`
- [x] FloorGenerator 인터페이스 + 생성기 레지스트리(`src/explore/generators/` 파일 하나 = 생성기 하나)
- [x] 수정동굴 생성기: 셀룰러 오토마타, 영역 잇기, 고정 랜드마크(대현자 기념비·네모 수정 삼거리·큰바위 옆 연못), 동서남북 포탈, 암흑지대, 빛나는 수정벽, 무작위 시작 위치. 시드 결정적·전부 연결됨(테스트)
- [x] 그리드 이동(4방향, 누르고 있으면 반복), 벽에 막히면 시간 0 — **2026-10-11 부드러운 8방향 연속 이동·실시간 시간으로 대체됨**(아래 세션 기록)
- [x] FOV(그림자 투사) + 안개 기억 + 횃불(유효 시야 = min(층 상한, max(수정 빛, 광원, 최소) + 스탯))
- [x] TimeSystem·GameClock: 이동·대기·휴식이 시간 소모(2026-10-11부터 이동은 시간 소모 없음, 시간은 실시간으로 흐름), 폐쇄 경고(24/6/1h)·강제 귀환, `EventBus.time_advanced`
- [x] 포탈(발견·살피기, 2층은 M6), 기념비(살피기), 안전지대(휴식 회복)
- [x] 디버그 패널(F1): 시간 스킵, 폐쇄 직전, 안개 걷기, 기념비/포탈로 이동, 레벨·근력·민첩, 허기 0, 회복, 무적, 시드 지정 재생성. (정수 지급 M3·몬스터 소환 M2·포탈 개방일 M4는 자리만)
- [x] 연출: 꼭짓점 색 조명(정적 광원 LightField + 시야 빛), 횃불 PointLight2D 빛 번짐·불꽃 흔들림, 약한 CanvasModulate, 후처리 셰이더(채도·비네트·필름 그레인)
- [x] 탐험 HUD: 층·미궁 n일차 시각·폐쇄까지, 빛 종류·시야, 안전지대, 발견 현황, 자원 게이지, 상태이상, 소지품, 조작 안내
- [x] 1층 데이터: `floors/f1_crystal_cave.json`, `tiles.json`, `landmarks.json`, 횃불·마른 식량, `input.json`
- [x] (플레이 흐름용 추가) 새 탐험가 화면, Actor/PlayerCharacter/StatusSet/Inventory/LightSource, 효과 레지스트리(restore_resource·light_source·apply_status·remove_status), 결과 화면(강제 귀환/사망)

**M1 범위 / 완료 기준 / 테스트 방법** (2026-10-10)
- 범위: 위 항목 전부. 도시·저장·묘비는 M4.
- 완료 기준: ① check.sh 전 단계 통과 ② 생성기 결정성·연결성 테스트 ③ FOV·시야 규칙 테스트 ④ 탐험 규칙(이동 시간·허기·폐쇄·아사) 테스트 ⑤ UI 스모크: 새 탐험가 → 입장 → 이동 → 디버그 → 강제 귀환, 아사 → 사망 화면 ⑥ 스크린샷으로 3/4 시점·한글 확인. — **모두 충족**
- 테스트 방법: `GODOT=<경로> bash tools/check.sh`, `tools/screenshot.tscn -- --screen=explore --torch --debug`, README의 M1 체크리스트.

### M2 전투 ✅
- [x] Timeline(CTB: 틱마다 gauge += agi, 100 이상이면 행동, delay_cost), 다음 10행동 미리보기(로직만 — 화면 표시는 2026-10-11 제거)
- [x] CombatManager + 전투 화면(같은 3/4 무대에서 대열 마주보기), 커맨드 UI(2026-10-11 공격·방어·스킬·도주 4개로 재구성: 약점 노리기 → 공격 대상 목록, 아이템 → 스킬 메뉴 "아이템…", 정보 → 기본 스킬 '조사')
- [x] 전투 효과 핸들러: damage(§6.4 공식·치명타·치명상), flee 등 → `check_skill_effects = true`로 스킬 효과도 엄격 검사
- [x] Monster(Actor 상속, overrides로 고정 최대치) / Party, 탐험 맵에 보이는 적·경계/추적·접촉 시 전투 시작
- [x] 1층 몬스터 4종(칼날늑대·노움·구울·고블린) + 규칙 기반 AI(`ai: [{if, use}]` 조건 레지스트리), 상성·약점
- [x] 바깥 휴식의 습격 위험, 디버그 몬스터 소환

**M2 범위 / 완료 기준 / 테스트 방법** (2026-10-10 시작)
- 범위: 위 항목 전부. 경험치·드롭·정수·Knowledge(정보의 `???` 공개)는 M3, 동료 파티는 M4. 전투는 플레이어 단독 파티.
- 완료 기준: ① check.sh 통과 ② Timeline 테스트(민첩 2배 ≈ 행동 2배, delay_cost, 미리보기 = 실제 순서) ③ 피해 공식 테스트(방어·약점·면역·dmg_taken·방어 태세·치명타·치명상) ④ 전투 테스트(끝까지 진행, 도주, 스킬 코스트·쿨타임·영혼탈진 봉인, 몬스터 AI) ⑤ 필드 몬스터 테스트(지역 스폰, 추적·영역 이탈, 접촉 시 전투, 노움 은신, 휴식 습격, 리스폰) ⑥ UI 스모크로 탐험 → 몬스터 접촉 → 전투 화면 → 승리/도주 → 탐험 복귀 ⑦ 스크린샷으로 필드 몬스터·전투 화면 확인.
- 테스트 방법: check.sh, `tools/screenshot.tscn -- --screen=explore --combat`, README M2 체크리스트.

**2026-10-11 변경 요청(실시간 탐험 · 전투 행동창) — 범위 / 완료 기준 / 테스트 방법**
- 범위: ① 탐험 시간 실시간 진행(가만히 있어도 시간·허기·몬스터 진행, 이동은 시간 대신 민첩 이동 간격) ② 일시정지·디버그·입력·포커스·전투 중 시간 정지, 전투 끝나면 차례 수만큼 반영 ③ 행동창 공격/방어/스킬/도주(약점 노리기 → 공격 안, 아이템 → 스킬 안) ④ 모든 아군 기본 스킬 대화·조사(조사 = 옛 정보, 차례 소모 / 대화 = 마수에게 무효) ⑤ 상단 순서 표시 제거(로직 유지) ⑥ 전투 상태(phase)·중복 실행 방지·잘못된 행동은 차례 미소모.
- 완료 기준과 결과(모두 실행해 확인):
  - [x] 가만히 있어도 시간이 흐른다 — `test_time_flows_while_standing_still`, UI 스모크 "가만히 있어도 시간이 흐른다"
  - [x] 플레이어가 정지해도 적이 움직이고 붙으면 전투 — `test_monsters_move_in_realtime_while_player_stands_still`
  - [x] 전투 진입 시 시간 정지, 이탈 시 차례 수만큼 반영 후 다시 흐름 — 같은 테스트 + UI 스모크
  - [x] 일시정지·디버그·입력·포커스 정지, 프레임 시간 자르기 — `test_realtime_frame_clamp_and_pause`, UI 스모크(Esc)
  - [x] 이동 속도는 민첩 비례(처음엔 "이동 간격"이었으나 부드러운 이동으로 바뀜) — 현재 `test_move_speed_by_agility`, `test_diagonal_is_not_faster`
  - [x] 행동창 네 항목 — UI 스모크(버튼 = 공격·방어·스킬·도주, 스킬 → 조사 → 대상, 공격 → 대상 반복으로 승리), 기존 방어·도주 테스트
  - [x] 모든 아군이 대화·조사 보유(동료 템플릿 포함), 잊을 수 없음, 중복 없음, 몬스터 미보유 — `test_party_has_innate_talk_and_investigate`
  - [x] 조사가 행동 기회를 쓴다 — `test_investigate_uses_a_turn`, UI 스모크
  - [x] 대화: 마수에게 효과 없음·차례 소모 / 말이 통하는 상대(테스트용 데이터)에게 여러 결과 — `test_talk_*`
  - [x] 상단 순서 표시 제거 — `TimelineBar` 삭제, UI 스모크 확인, 스크린샷
  - [x] 아군(2명)과 몬스터가 민첩 순서로 행동 — `test_party_and_monsters_act_in_agility_order`
  - [x] 잘못된 행동은 차례를 쓰지 않음, 같은 차례 두 번 행동 불가 — `test_invalid_actions_do_not_use_the_turn`
- 테스트 방법: `GODOT=<경로> bash tools/check.sh`, `tools/screenshot.tscn -- --screen=explore --torch --combat`(전투), `--pause`(일시정지), README "M2 추가" 체크리스트.
- 아직 확인하지 않은 것: 실제 사람이 키보드로 오래 플레이했을 때의 체감 속도(실제 1초 = 6분이 적당한지), 웹 내보내기에서의 실시간 성능.

### M3 성장 ✅ (2026-10-11)
- [x] 도감(Bestiary)·첫 처치 경험치, 레벨업(경험치 테이블, 정수 슬롯 수 표시)
- [x] Knowledge: 몬스터 정보 `???` → 조사(스탯)·직접 겪음(약점·면역)으로 공개
- [x] 마석 드롭(등급별 아이템) + 몬스터별 drops, 전투 승리 시 전리품 기록
- [x] 장비(11칸: 주무기·보조·머리·몸·망토·장갑·허리·신발·반지 2·목걸이), 무기 공격력·피해 유형, 장비 수정자
- [x] 격자 인벤토리(아이템 크기 w×h, 겹침·자리 찾기), 스톤(돈), 포션·식량 추가
- [x] 스톤샤드풍 UI: 하단 바(생명력·영혼력·허기 + 단축칸 1~0 + 창 버튼), 소지품 창(장비 인형 + 격자, 끌어놓기, 툴팁·장착품 비교), 캐릭터 창, 도감 창, 기록창 왼쪽 아래
- [x] (선행) 부드러운 이동 + 충돌 검토 — 완료(아래 기록)
- 보류: 정수 드롭·흡수·삭제(사용자 요청으로 설정 비움 — 캐릭터 창에 슬롯 수만), 포탈 최초 개방 경험치(포탈 개방은 M6 — 지급 함수만), 내구도·무게, 상점(M4)

**M3 범위 / 완료 기준 / 테스트 방법** (2026-10-11)
- 범위: 위 항목. 레퍼런스: 스톤샤드 인벤토리(장비 인형 + 크기 있는 격자 + 돈 + 툴팁 비교)와 하단 바(체력·에너지 막대 + 단축칸 + 좌우 창 버튼), 사용자 첨부 스크린샷 4장.
- 완료 기준: ① check.sh 통과 ② 인벤토리 테스트(격자 배치·겹침·쌓기·자리 없음·이동·저장 왕복) ③ 장비 테스트(슬롯·양손·반지 2칸·수정자 부착/해제·무기 피해) ④ 성장 테스트(같은 몬스터는 첫 처치만 경험치, 레벨업·영혼력 증가, 상한) ⑤ Knowledge 테스트(조사·상성 공개, `???`) ⑥ 전리품 테스트(마석 등급·확률, 가방이 가득 찼을 때) ⑦ UI 스모크: I/C/B 창 열기(시간 정지), 장착·해제, 단축칸 사용, 전투 승리 후 경험치·마석 ⑧ 스크린샷으로 소지품 창·하단 바 확인.
- 테스트 방법: check.sh, `tools/screenshot.tscn -- --screen=explore --loot --inventory --character`(또는 `--bestiary`, `--tooltip`), README M3 체크리스트.

## 2026-10-11 세션 작업 기록 (다른 세션 이어받기용)

사용자 요청 순서: ① 실시간 탐험 + 행동창 4개 + 기본 스킬 대화·조사 + 상단 순서 표시 제거 ② 플레이어·몬스터 부드러운 이동 + 물리 검토 ③ M3(인벤토리·UI는 스톤샤드와 첨부 스크린샷 참고). 사용자 결정: **모든 몬스터는 대화가 통하지 않는다**, **정수 설정은 계속 보류**.

**A. 실시간 탐험 · 전투 행동창 (커밋 b807905에 포함)**
- `src/explore/RealtimeDriver.gd`: 정지 사유(menu·debug·typing·focus·window) 모음, 매 프레임 `pass_time`(프레임 최대 `realtime_max_frame_sec` 0.25초, `realtime_max_step_sec` 0.05초로 쪼갬), 실제 1초 = `realtime_hours_per_sec` 0.1시간. 세션을 필드로 들지 않는다(순환 참조 누수 방지 — 실제로 겪음).
- 일시정지 키 `pause`(Esc/P) + 화면 가운데 표시. 대기(Space)=1시간 즉시, 휴식(Z)=8시간 유지. 전투 시간은 끝날 때 차례 수 × `combat.hours_per_turn`.
- `Battle.phase`(idle → await_input → executing → turn_end → ended), `act()`는 bool, 잘못된 행동은 `ActionCheck`가 막고 차례 미소모. 몬스터 AI는 `MonsterAi`로 분리. 
- 기본 스킬: `data/skills/talk.json`, `investigate.json`(`"innate": true`), 효과 `effects/talk.gd`(말이 통하는지 = `Actor.understands_speech()`, Monster는 데이터 `talk.understands`, 기본 false → 계열별 `combat.talk_no_reply_<계열>` 문장만), `effects/investigate.gd`. 부여 = `balance.party.innate_skills` + `PlayerCharacter.grant_innate_skills`(중복 없음), `Actor.forget_skill`은 innate 거부.
- `CommandMenu` 4개 버튼, `CombatScreen`에서 `TimelineBar` 삭제(파일도 삭제), 재진입 방지 `_looping`, AI 실패 시 기본 공격 → 방어.
- 덤으로 고친 버그: 전투 카드 도형 위치(`FigurePainter.paint`에 `base` 변환 인자), 행동창 지연 포커스 오류(`CommandMenu._grab_first`).

**B. 부드러운 이동 (커밋 83e890a)**
- `src/explore/Kinematics.gd`: 반폭 0.3칸 AABB vs 걸을 수 없는 칸, 축 분리 미끄러짐, 0.25칸 분할(터널링 방지), 모서리 보정 0.45칸. **Godot 물리 엔진은 쓰지 않음**(이유: ASSUMPTIONS V1).
- `ExploreSession`: `fpos`(연속 좌표, 칸 중심 = x+0.5) + `pos`(중심 칸), `move_dir(dir, real_sec)`(실시간 입력), `try_move(dir)`(1칸 거리, 테스트·디버그·캡처용), `enter_cell`, 시그널 `body_moved`. 이동 로직은 `src/explore/PlayerMotion.gd`.
- 몬스터: `src/explore/MonsterSteering.gd`(decide/walk/거리 장 캐시/경유점), `FieldMonsters.Group`에 `fpos`·`waypoint`·`place(cell)`, `update(player: Vector2, …)`, `touching(player, delta)`. 닿음 = `monsters.contact_tiles` 1.05, 직접 추적 `direct_chase_tiles` 2.0.
- 그리기: `FloorView.feet_of(fpos)`, ActorView 트윈 제거, MonsterView는 매 갱신 위치 직접 설정. 입력 8방향(`ExploreScreen._input_dir`).
- 새 balance 키: `explore.body_half_extent/corner_assist/max_substep_tiles/realtime_max_step_sec`, `monsters.contact_tiles/direct_chase_tiles/body_half_extent`. render `move_tween_sec/move_first_delay_sec/move_repeat_sec` 삭제.

**C. M3 로직 (커밋 bdd38b7)**
- `src/items/`: `ItemInfo`(size/stack/equip/icon/color/price), `Inventory`(격자 10×6, 쌓기·자리 찾기·move_stack·place·take_stack·fits·money, 옛 API 유지), `Equipment`(11칸, 양손, 반지 l/r, `equip:<칸>` 수정자), `InventoryActions`(가방↔장비, 자리 없으면 실패).
- `src/progress/`: `Progression`(exp_total·kills·portals_opened, `level.exp_table`, 상한 `max_initial` 5), `Knowledge`(seen/stats/aff), `Loot`(마석 `magic_stone_<등급>` 확률 `loot.magic_stone_chance` 0.85 + 몬스터 `drops`), `Rewards.grant`(공적·전리품·레벨업 메시지).
- 연결: `Actor.equipment`·`weapon_attack()`·`base_attack_type()`, `DamageCalc.attack_power`가 무기 공격력 사용, `BattleKnowledge`(전투 시작 = seen, 명중 = 상성 기록), 조사 메시지에 스탯·상성(모르면 ???), `ExploreSession.resolve_encounter(group, result, turns, killed)`가 보상 지급.
- `PlayerCharacter`: `progression`·`knowledge`·`hotbar`(10칸, `auto_fill_hotbar`, `set_hotbar`), 시작 장비 착용(`classes.json start_equipment`), 시작 돈 `char_creation.start_stones` 500, 저장용 `progress_to_dict/progress_load_dict`(M4 저장 시스템이 쓸 것).
- 데이터: 아이템 20개 추가(무기 5·방어구 11·마석 2·돌빵·중급 포션), 기존 3개에 size/icon/color, `tags.equip_slots`·`tags.rarities`, 몬스터 `drops`, balance `inventory`·`loot`·`level.exp_table`. 검증 규칙(크기·장비 칸·무기 유형·drops·start_equipment) 추가.

**D. M3 UI (커밋 bf2dc37)**
- `src/ui/theme/GothicStyle.gd`(돌판·칸·이름판·아치 그리기), `ui/widgets/`: `GothicWindow`, `InventoryGrid`(끌어놓기·툴팁·오른쪽 클릭), `PaperDoll`(+`EquipSlot`), `ItemTooltip`(비교), `ItemIconPainter`(아이템 그림 코드로), `ItemDragPreview`, `BottomBar`(+`HotbarSlot`), `ui/windows/`: `InventoryWindow`(정렬 포함), `CharacterWindow`, `BestiaryWindow`, `WindowManager`(창 열리면 시간 정지 "window").
- `ExploreHud`는 왼쪽 위 정보만(자원·소지품 패널 제거 → 하단 바), 기록창은 왼쪽 아래. 새 키: `inventory`(I/Tab), `character`(C), `bestiary`(B), `hotbar_1`~`hotbar_0`(1~0), Esc = 창 닫기 우선. 새 탐험가 화면에 "(착용)" 장비 표시.
- `tools/screenshot.gd` 옵션: `--combat --pause --loot --inventory --character --bestiary --tooltip`(`--walk`는 1칸씩 `try_move`).
- 스모크: `_realtime_combat_flow`(실시간·일시정지·행동창·조사·승리 공적), `_inventory_flow`(창·끌어놓기 장착/해제·오른쪽 클릭·단축칸·C/B).

**테스트 목록(추가·변경)**: `test_kinematics.gd` 5개, `test_items.gd` 7개, `test_progress.gd` 7개, `test_explore_rules`의 `test_move_speed_by_agility`·`test_diagonal_is_not_faster`·`test_time_flows_while_standing_still`·`test_realtime_frame_clamp_and_pause`, `test_field_monsters`의 `test_monsters_move_in_realtime_while_player_stands_still`, `test_combat`의 대화·조사·잘못된 행동·민첩 순서 테스트. 합계 122개 통과.

**미확인·남은 문제**
- 실제 키보드 플레이 체감(실시간 속도 1초=6분, 이동 속도, 모서리 보정), 웹 내보내기 성능 — 미확인.
- 밸런스: 장비로 1층이 쉬워짐(ASSUMPTIONS C8) — 미조정.
- 하단 바 폭이 넓다(화면의 약 77%) — 사용자 판단 대기.
- 300줄 초과: `ExploreSession.gd` 355줄, `Battle.gd` 317줄(분리 후보: 휴식·습격, 보상 처리).
- 내구도·무게·상점·정수·포탈 최초 개방 공적 호출 — 미구현(범위 밖/보류).

### G2 1층 필드 10종 ✅ (2026-10-12, 명세 §1·§4·§6·§15)

**범위 / 완료 기준 / 테스트 방법**
- 범위:
  1. 전투 공식을 명세 §1에 맞춤: 물리 공격력 = 근력×2 + 무기(몬스터 `natural_weapon`), 마법 = 정신력×2 + 기본값, 방어 계수 100/(100+방어×4), 명중 = 스킬 명중 × (1 + 민첩 차 × 0.005)(30~100%), 치명 5% + 민첩×0.3%. 명중률 스탯 `accuracy`.
  2. 패시브 체계(몬스터 `passives` · 정수 패시브 공통): 수정자, 적중 시 상태이상(on_hit), 상태이상 면역, 첫 차례 선공(start_gauge), 근접 반사, 치명 보정, 은신 대상 지정.
  3. 전투 규칙 추가: 은신(hidden)·속박(snare)·고블린 마비독·마비·부패, 조건부 위력(대상 상태이상), 흡혈, 증원(summon), 스킬별 명중·치명 보정. AI 조건(첫 차례·대상 상태·아군 수·순환 등)과 대상 고르기(생명력 높은/낮은, 상태 없는).
  4. 몬스터 10종 데이터(원종 4종 교체 + 변이종 6종, `variant_of`·`lineage`), 몬스터판 스킬(정수판 `essence_of`와 같은 id), 변이종 정수 6종(공유 스킬은 같은 정수판 스킬 파일).
  5. 필드: 변이종은 3일 차 이후 해당 방위 외곽에서 무리의 20%, 구울 2칸 비선공, 은신 정수(도둑걸음·일체화)의 필드 효과(몬스터 인식 반경 감소), 칼날늑대는 은신 무시.
  6. 도감에 계열·공유 이능 안내.
  7. 시뮬레이터 목표(인간 Lv1 vs 고블린 1체 95%+ 등)로 수치 조정 → `docs/balance/floor1.md`. 종족 스탯 범위를 명세 기준 탐험가에 맞춤.
- 완료 기준: check.sh 통과, 새 단위 테스트(공식·패시브·은신·AI·스폰·정수 중복), 시뮬레이터 목표 충족, 스크린샷 확인.
- 테스트 방법: check.sh, `tools/sim_battle.gd`, README "G2" 체크리스트.
- 하지 않는 것: 맵 위 고블린 덫 오브젝트, 칼날늑대 냄새 흔적 오버레이(정수판), 우선도(CTB라 없음 — 선공 게이지로 대체).

**결과 (모두 실행해 확인)**
- [x] check.sh 전 단계 통과 — 데이터 검증 오류 0, 단위 테스트 **150/150**, UI 스모크, 메인 씬 스모크, 누수 없음
- [x] `tests/test_floor1.gd` 11개: 명세 공식(명중 95·민첩 보정·근력×2·natural_weapon·실명), 적중 시 패시브와 근접/원거리 필터, 출혈 면역·칼날털 반사·막고 찌르기 반격·피 핥기 흡혈, 은신 대상 규칙(추적 후각은 꿰뚫음), 하울링 증원·한 진영 최대 6·속박 도주 불가, 구울 순환·선공 게이지, 늑대 무리 사냥 AI, 변이종 3일 차 외곽 출현, 도둑걸음 필드 은신(정지 −70%·이동 −30%), 공유 이능 정수 중복 거부 4쌍, 정수 패시브(마비독)가 플레이어에게 작동·제거 시 사라짐
- [x] 시뮬레이터 목표 충족(무작위 종족·템플릿, 시나리오 15종) — `docs/balance/floor1.md`. 명세 "인간 Lv1 vs 고블린 1체 95%+" 충족
- [x] 스크린샷: 전투 화면 증원 카드(고블린 +), 거대 칼날늑대 전투, 도감 공유 이능 안내

**바뀐 파일**
- 전투: `DamageCalc`(명세 공식·조건부 위력·치명 보정), `Passives`(새), `BattleRules`(새: 은신 대상·증원·선공·전투당 횟수·도주 보정·사건 반영 — Battle.gd에서 분리), `MonsterAi`(also·대상 고르기·ai_cycle), AI 조건 6종(`first_turn`·`allies_at_least`·`alone`·`self_status`·`foe_status`·`was_hit`), 효과 `summon`, `damage`(흡혈·패시브 연결), `apply_status`(면역), `Combatant`(uses·acted·was_hit), `ActionCheck`(은신 대상), `StatusSet.counter_power`, `EffectContext.registry`
- 개체: `Actor.passives/add_passive/remove_passive/weapon_is_ranged`, `Monster`(natural_weapon·passives·lineage), `EssenceSet`(정수 패시브를 Actor에 붙임)
- 탐험: `FieldMonsters`(변이종 섞기·은신 값), `MonsterSteering`(인식 반경 × (1 − 은신), ignores_stealth), `FieldStealth`(새), `ExploreSession.last_move_hours`, `PlayerMotion`
- UI: `CombatScreen`(증원 카드), `BestiaryWindow`(변이종·공유 이능), `Lineage`(새)
- 데이터: 몬스터 10종(원종 4 교체 + 변이종 6), 몬스터판 스킬 26개(옛 `claw`·`bite`·`pounce`·`dagger_stab`·`poison_stab`·`mud_fist` 삭제), 정수판 스킬 25개, 정수 10종, 상태이상 11개 추가(goblin_paralysis·paralysis·snare·hidden·rot·counter_stance·wolf_pack·intimidated·mud_hardened·mud_merged·cursed_mud, blind는 명중률 −30으로), 스탯 `accuracy`·`obsession`, 무기 공격력, 종족 범위, 1층 지역 `variants`, balance(combat 공식·max_side_units·explore.stealth_still_hours·status.rot_per_turn), 생명력 수식 floor
- 도구: `tools/sim_battle.gd`(시나리오별 목표·`--bench`), `tools/screenshot.gd`(`--monster`·`--summon`), 리포트 `docs/balance/floor1.md`
- 가정: ASSUMPTIONS **F1~F12**

**아직 안 된 것(G2 관련)**
- 맵 위 고블린 덫(무리 근처 덫 1~2개), 칼날늑대 정수의 냄새 흔적 오버레이, 구울의 "도주 실패 대상 추격 일격", 고블린 궁수 도둑걸음 "다른 행동 없이 쓰면 2R", 노움 "은신 중 도주 불가", 정수 일체화의 아군 동반 은신
- 상태이상 저항 판정(정신력·항마력 등으로 확률 감소)은 아직 없다 — G4 신규 상태이상과 함께
- 우선도는 CTB라 없다(선공 게이지 `start_gauge`·`delay_cost`로 대체)


### G1 성장 체계 ✅ (2026-10-12, 명세 §5 · §13 G1)

**범위 / 완료 기준 / 테스트 방법**
- 범위: ① v1 삭제 항목 정리(확인 결과 이 저장소엔 심연·베르자크 관련 데이터·코드가 없음 — 할 일 없음) ② `data/progression.json`(레벨 표 0/8/50/250/660/1000/1400/2600/3400/4400/18000, 만렙 11, 획득원, 예산) ③ 경험치 지급: 종별 첫 처치(10 − 등급, 상위 변이종 +1, 무등급·토큰 0), 수호자 +3 반복(8층+ +5), 군주 +15 1회, 포탈 월간 첫 통과 +2, 숨겨진 포탈 +99, 꿈꾸는 영혼 ④ 레벨업 보상: 슬롯 = 레벨, 영혼력 30 → +10(~5) → +30, 생명력 50 + 레벨×10 + 근력×1.5 + 물리내성×3 ⑤ 레벨 하락: 경험치 손실(`Progression.lose`) → 정수 슬롯 무작위 잠금, 재상승 시 해제 ⑥ `tools/exp_budget.gd` ⑦ (사용자 요청) CTB 민첩 밸런스 점검 — `tools/sim_battle.gd`, `combat.speed_base`
- 완료 기준과 결과(모두 실행해 확인):
  - [x] check.sh 전 단계 통과 — 데이터 검증 오류 0, 단위 테스트 **139/139**, UI 스모크, 메인 씬 스모크, 종료 시 누수 없음
  - [x] `tests/test_growth.gd` 7개: 레벨 문턱 경계값, 레벨업 보상량(Lv1 생명력 102·영혼력 30/40/70/100/250·슬롯), 획득원(상위 변이종·무등급·토큰·수호자 3/5·포탈 월간 리셋·6층 이상 1회·숨겨진 포탈), 수호자 반복·군주 1회, 꿈꾸는 영혼, 레벨 하락 슬롯 잠금(시드 고정 재현·잠긴 정수 이능 제거·슬롯 차지·재상승 해제·저장), 경험치 예산(1~4층 640/660 = 97%)
  - [x] `test_combat`의 `test_timeline_speed_base_softens_agility_gap`
  - [x] `tools/exp_budget.gd` → `docs/balance/exp_budget.md` "97.0% → 통과"
- 테스트 방법: check.sh, `tools/exp_budget.gd`, `tools/sim_battle.gd -- --n=300 [--speed_base=N]`, README "G1" 체크리스트.

**CTB 밸런스 점검 결과 (sim_battle, Lv1 무작위 종족·템플릿, 기본 공격만, 시나리오당 300회)**

| 시나리오 | speed_base 0 (이전) | speed_base 5 (채택) | 적/아군 행동 0 → 5 |
|---|---|---|---|
| 고블린 3 | 97% | 99% | 1.80 → 1.83 |
| 칼날늑대 1 | 100% | 100% | 1.21 → 1.10 |
| 칼날늑대 2 | 93% | 98% | 2.08 → 1.85 |
| 노움 2 | 100% | 100% | 0.82 → 1.00 |
| 고블린·구울·노움 1 | 100% | 100% | — |

- 판단: 민첩을 그대로 속도로 쓰면 민첩 14인 칼날늑대가 민첩 5~10인 탐험가보다 최대 2.8배 행동해 무리 전투가 가장 위험했다. 속도 = 민첩 + 5로 작은 차이는 순서 위주로, 큰 차이(민첩 2.5배 이상)는 여전히 2배 넘게 행동하도록 완화(ASSUMPTIONS C9). 10 이상은 민첩 투자 가치가 너무 줄어 제외.
- 주의: 새 생명력 공식으로 1층이 전체적으로 쉬워졌다(승률 98~100%). 1층 몬스터가 아직 v1 임시 수치라서이며, **G2에서 명세 수치로 바꾼 뒤 시뮬레이터 목표(인간 Lv1 vs 고블린 1체 95%+ 등)로 다시 맞춘다**(ASSUMPTIONS C10·L10).

**바뀐 파일**
- 데이터: `progression.json`(새 파일, manifest 등록), `balance.json`(level·exp 절 → progression.json으로 이동, hp per_level 10·per_p_res 3·per_str 1.5, soul base 30, combat.speed_base 5), `tags.json`(`monster_ranks`), 몬스터 4종 `exp_first_kill` 삭제, `render.json`(`essence_locked_darken`), `strings/ko.json`(`reward.guardian_bonus/lord_bonus/level_down`, `essence.locked_suffix`)
- 코드: `Progression.gd`(전면 개편), `ExpBudget.gd`(새), `EssenceSet`(sync_slots·잠금), `PlayerCharacter`(set_level/change_level 재정의, essence_rng), `GameDatabase.prog()/single()`, `Rewards`(수호자·군주 메시지), `Timeline/Combatant/Battle`(speed_base), `CoreRules._progression`, `ContentRules`(rank·upper_variant·variant_of·floor 검사), `EssencePanel`(잠긴 정수 표시), `CharacterWindow`·`DebugPanel`·`FoundationScreen`(레벨 값 출처)
- 도구: `tools/exp_budget.gd`, `tools/sim_battle.gd`
- 가정: ASSUMPTIONS **L1~L10, C9, C10**

**아직 안 된 것(G1 관련)**
- 포탈 통과(+2)·숨겨진 포탈(+99)·꿈꾸는 영혼은 API만 — 2층 이동(G4/M6)·히든 지역·아이템이 생기면 연결
- 경험치를 깎는 함정·스킬(영혼 베기)은 아직 없음 — `Progression.lose`만 준비
- 레벨 하락 메시지 문자열(`reward.level_down`)은 있지만 부르는 곳 없음

### 정수 1차 ✅ (2026-10-12, 명세 `docs/PROMPT_FLOOR1_V2.md`)

사용자 요청: "업로드한 1계층 v2 명세를 토대로 정수 관련 작업 진행, 기존 작업을 크게 해치지 않는 선에서." → 명세 §2·§3(정수 규칙·드롭률)과 §6의 **기존 4종 원종** 정수만 구현. 몬스터 kit 개편·변이종 6종·레벨 표 교체(G1·G2)와 균열(G4~)은 하지 않았다.

**범위 / 완료 기준 / 테스트 방법**
- 범위: ① 정수 데이터 스키마(몬스터당 1파일, 패시브 1 + 색→액티브, stat_ranges) ② 정수판 스킬 11개(`skills/ess_*.json`, `essence_of`) ③ 드롭(등급·rank·균열·original 모드) ④ 흡수 대기·만료 ⑤ 흡수(슬롯 = 레벨, 패시브·스킬 중복 거부, 수호자 무지갯빛 = 액티브 전부·×1.5, 일반 → 수호자 업그레이드) ⑥ 제거·삭제 비용(500만, ×2) ⑦ 저장 왕복 ⑧ 캐릭터 창 정수 칸·흡수 버튼, 디버그 정수 지급 ⑨ 검증 규칙
- 완료 기준과 결과(모두 실행해 확인):
  - [x] check.sh 전 단계 통과 — 데이터 검증 오류 0(경고 1: 스프라이트 없음), 단위 테스트 **131/131**, UI 스모크, 메인 씬 스모크
  - [x] `tests/test_essence.gd` 9개: 흡수 효과(패시브 수정자·색 액티브·스탯), 슬롯 제한, 같은 몬스터 다른 색 거부, 공유 스킬(essence_of) 거부, 수호자 정수·업그레이드·×1.5, 제거·삭제 비용 2배, 드롭 확률·Rewards 연결·만료, 대기 흡수·저장 왕복, 전투에서 정수 스킬 사용
  - [x] 스크린샷(`--screen=explore --essence --character`)으로 캐릭터 창 정수 칸(색 슬롯·흡수 대기·스크롤, 하단 바와 겹치지 않음) 확인
- 테스트 방법: `GODOT=<경로> bash tools/check.sh`, `tools/screenshot.tscn -- --screen=explore --essence --character`, README "정수 1차" 체크리스트.

**바뀐 파일**
- 데이터: `essences/{goblin,ghoul,blade_wolf,gnome}.json`(+ `_template.json` 새 스키마), `skills/ess_*.json` 11개, `statuses.json`(blind·trap_set·hardened·pack_hunt·merged), `stats.json`(patience·dexterity·stealth), `tags.json`(`essence_colors` 8색), `balance.json`(`essence` 절, `status.trap_damage`), `render.json`(`ui.essence_panel_height`), `strings/ko.json`(`essence.*`, `reward.essence`, `debug.give_essence`; `debug.essence_locked` 삭제)
- 코드: `src/progress/EssenceSet.gd`(흡수·중복·업그레이드·제거·대기·만료·저장), `src/progress/EssenceDrop.gd`(드롭 확률·정수 사례 만들기·스탯 굴림), `src/ui/widgets/EssencePanel.gd`, `Rewards.grant(…, now_hours)`가 정수를 대기 목록에, `ExploreSession.pass_time`이 만료 처리, `PlayerCharacter.essences` + 저장, `CharacterWindow`(정수 칸 → EssencePanel, 스크롤), `DebugPanel`(정수 지급 버튼), `ContentRules._essences`(새 스키마 검사), `tools/screenshot.gd --essence`
- 가정: ASSUMPTIONS **J1~J10**(정수판 약화는 데이터에 미리, 중복 키, 만료 3시간, 미구현 패시브 표기 등)

**아직 안 된 것(정수 관련)**
- 미구현 패시브: 마비독 칼날(적중 시 발동), 네 발 짐승(우선도), 추적 후각(맵 오버레이·은신 대상 지정) — `"implemented": false`, 툴팁에 표시
- 정수판 스킬의 세부: 비열한 찌르기 치명타 보정·조건부 위력, 덫의 속박, 일체화의 은신·`field_use`, 모래 뿌리기의 명중 감소(민첩 감소로 근사)
- 정수 삭제 버튼(대신전, M4), 레벨 하락 시 슬롯 잠금(G1), 도서관·길드 정수 정보(M4)
- 변이종 6종·균열 몬스터 정수(G2·G5~G8), 스킬 공유 안내 문구를 도감에 띄우기(G2)

### M4 도시 ⬜
- [ ] 길드(정보·고용), 환전, 잡화점, 대장간, 대신전, 여관, 월 달력(포탈 개방일)
- [ ] 강제 귀환(다음 날 정오), 저장/사망 삭제/묘비 목록, export_presets(json 포함)

### M5 계층군주·균열 ⬜
- [ ] 드레드피어(소환 조건·페이즈·오오라·그로기·시야 2m), 균열(챕터·필드 효과·수호자), 빙하굴·녹색 탄광, 넘버스·귀속·부적, 히든 피스

### M6 2층 ⬜
- [ ] 4필드 생성기·몬스터·덫·무리 AI, 균열 열기용 마석 제단, 1층 포탈 → 2층 필드 연결, 3층 포탈

### M7 확장 훅(선택) ⬜
- [ ] 베르자크·심연의 안개, 차원 붕괴, 동료 배신, 약탈자, 세금 모드, 반응형 회피/패링, 부위 부상, 추가 종족, 3층 이상

## 검증 기록

| 날짜 | 범위 | 환경 | 결과 |
|---|---|---|---|
| 2026-10-10 | M0 전체 | Godot 4.7.2 / Windows 11 | check.sh 통과: 데이터 검증(오류 0), 단위 테스트 43/43, UI 스모크, 메인 씬 스모크. 스크린샷으로 한글 확인 |
| 2026-10-10 | 폰트 번들 | 〃 | Noto Sans KR Regular 적용 스크린샷 확인 |
| 2026-10-12 | G2 1층 필드 10종 | Godot 4.7.2 / Linux(클라우드, Xvfb) | check.sh 통과: 데이터 검증 오류 0(경고 1: 스프라이트 없음 27), 단위 테스트 150/150, UI 스모크, 메인 씬 스모크, 누수 없음. sim_battle 목표 15/15(무작위), 스크린샷(증원 카드·변이종 전투·도감) 확인 |
| 2026-10-12 | G1 성장 체계 + CTB speed_base | Godot 4.7.2 / Linux(클라우드) | check.sh 통과: 데이터 검증 오류 0, 단위 테스트 139/139(G1 7 + 속도 1 추가), UI 스모크, 메인 씬 스모크, 누수 없음. exp_budget 97% 통과, sim_battle 시나리오 7종 |
| 2026-10-12 | 정수 1차 | Godot 4.7.2 / Linux(클라우드 세션, Xvfb) | check.sh 통과: 데이터 검증(오류 0, 경고 1: 스프라이트 없음 21), 단위 테스트 131/131(정수 9 추가), UI 스모크, 메인 씬 스모크. 스크린샷으로 캐릭터 창 정수 칸 확인. 실제 플레이로 정수 드롭·흡수 체감은 미확인 |
| 2026-10-11 | 부드러운 이동 + M3 전체 | Godot 4.7.2 / Windows 11 | check.sh 통과: 데이터 검증(오류 0, 경고 1: 스프라이트 없음), 단위 테스트 122/122(충돌 5·인벤토리/장비 7·성장/정보/전리품 7 추가), UI 스모크 5흐름(소지품 창 끌어놓기 장착·해제, 오른쪽 클릭 장착, 단축칸 키, 캐릭터·도감 창, 창 열림 중 시간 정지, 전투 승리 후 공적), 메인 씬 스모크. 스크린샷으로 소지품·캐릭터·도감 창, 툴팁 비교, 하단 바, 연속 좌표 이동 확인. 실제 키보드 조작의 이동 체감은 미확인 |
| 2026-10-11 | 실시간 탐험·전투 행동창·기본 스킬 | Godot 4.7.2 / Windows 11 | check.sh 통과: 데이터 검증(오류 0, 경고 1: 스프라이트 없음 21), 단위 테스트 102/102, UI 스모크 4흐름(실시간·일시정지·전투 행동창·조사·복귀), 메인 씬 스모크, 누수 없음. 스크린샷으로 전투 화면(순서 표시 없음, 행동창 4개, 카드 도형)·일시정지 확인 |
| 2026-10-10 | M1 전체 | 〃 | check.sh 통과: 데이터 검증(오류 0, 경고 2: 스프라이트 없음 17·전투 효과 핸들러 M2), 단위 테스트 73/73(생성 약 0.1~0.15초, 한 걸음 약 0.8ms), UI 스모크 3흐름 통과(로그 153줄), 메인 씬 스모크 통과, 종료 시 누수 없음. 스크린샷으로 3/4 시점·횃불·안개·HUD·디버그 패널 확인 |

## 다음 할 일

순서(사용자 결정 2026-10-12): **G2 → G3 → G4 → G5~G8로 미궁 1층을 완성한 뒤 M4 도시.** 전투는 CTB 유지.

1. **G3 드레드피어와 구더기**(명세 §7) — PROGRESS에 범위/완료 기준/테스트 방법부터. 명세 §7을 읽고 소환 조건을 맵 로직에 연결, 게이지 5종·페이즈·토큰, 군주 +15 경험치(`rank: lord`) 확인. 베르자크·심연 관련은 넣지 않는다(명세 §0). 패시브·AI 규칙·증원(summon)·BattleRules를 재사용.
2. **G4 균열 공통** — 자연·강제 개방, 인스턴스, 챕터(연전·생존 웨이브·예고형 패턴), 수호자 드롭(정수 33%·넘버스·균열석), 변종 3%, 탈출 포탈, 신규 상태이상 12종·저체온증, 디버그 강제 개방. 포탈 경험치(`record_portal`) 연결.
3. **G5 핏빛성채 → G6 빙하굴 → G7 녹색 탄광 → G8 강철의 묘**
4. 그 다음 **M4 도시**(저장/불러오기, 대신전 정수 삭제, 길드 정보 등).
5. 실제 플레이 확인 거리: 실시간 속도(X17), 정수 만료 3시간(J5), CTB 체감(C9), 1층 무리 난이도(F9).
6. G2에서 남긴 것(위 "아직 안 된 것"): 맵 위 고블린 덫, 상태이상 저항 판정 등 — G4 신규 상태이상 작업 때 함께.

## (참고) 처음 세운 M2 순서

1. PROGRESS.md에 M2 "범위 / 완료 기준 / 테스트 방법"을 먼저 쓴다.
2. `data/monsters/`에 1층 4종(칼날늑대 외 노움·구울·고블린) — PROMPT §11.4 특징(노움 [일체화] 3m 안에서만 보임, 구울 접근 전 비선공 등)을 데이터 필드로.
3. `src/combat/`: `Timeline`(순수 로직, Rng 주입, 다음 N행동 시뮬레이션) → 테스트(민첩 2배 ≈ 행동 2배, delay_cost) → `CombatManager` → `effects/damage.gd`·`flee.gd` → `check_skill_effects = true`.
4. `Monster`(Actor 상속), AI 조건 레지스트리(`src/combat/ai/<조건>.gd`), 탐험 맵의 적 표시·경계/추적·접촉 시 전투 시작(ExploreSession에 훅).
5. 전투 화면(3/4 무대, 상단 타임라인, 좌하단 파티, 우측 기록, 하단 커맨드) + UI 스모크.
6. 끝나면 README에 M2 테스트 플레이 체크리스트, check.sh·스크린샷 검증 후 커밋·푸시.

## 메모 / 알려진 이슈

- 한글 폰트: `assets/fonts/NotoSansKR-Regular.otf`(OFL, 라이선스 `assets/fonts/OFL.txt`)를 번들했다. (ASSUMPTIONS E4)
- 내보내기 시 `data/**/*.json`이 포함되도록 export 필터 확인 필요(M4 무렵 export_presets.cfg 작성).
- `--import` 중 godot_mcp 플러그인의 포트 오류 메시지는 무시해도 된다.
- 스킬 effects의 타입 검사는 M2까지 경고로만(전투 효과 핸들러 없음). 아이템 use_effects는 엄격 검사.
- 같은 상태이상을 여러 출처가 걸 때 출처별 관리가 없다(ASSUMPTIONS X15) — M2에서 보완.
- 전투 카드의 도형이 카드 위쪽 바깥에 그려지던 문제를 고쳤다(`FigurePainter.paint`가 변환을 초기화 → `base` 변환 인자 추가).
- 탐험 화면의 성능: 한 걸음 처리 약 0.8ms(로직). 그리기는 바뀐 청크·벽 줄만 다시 그린다. 웹에서의 실측은 아직 없음.
