# PROGRESS — 진행 상황

> 새 세션은 `CLAUDE.md` → 이 문서의 **현재 상태**와 **다음 할 일**부터 읽는다.

## 현재 상태 (2026-10-10)

- **M0 기반: 완료 · 검증됨**, **M1 탐험: 완료 · 검증됨** (Godot 4.7.2, Windows, `tools/check.sh` 전 단계 통과 + 스크린샷 확인)
- 실행하면 타이틀 → **새 탐험가**(이름·종족·템플릿·스탯 굴림) → **1층 수정동굴**(매번 새로 생성)을 3/4 시점으로 탐험한다. 시야·안개·횃불·허기·시간·층 폐쇄·아사가 작동하고, F1로 디버그 패널을 연다. 층이 닫히거나 죽으면 결과 화면 → 타이틀(도시는 M4).
- 원격 저장소: GitHub `rin1015sh/Dungeon-And-Stone-Local`의 `main`에 연결됨(바깥 폴더 저장소). 안쪽 `Dungeon And Stone/` 폴더는 예전 클론으로 이제 필요 없다(사용자가 지워도 된다).
- 다음: **M2 전투**.

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
- [x] 그리드 이동(4방향, 누르고 있으면 반복), 벽에 막히면 시간 0
- [x] FOV(그림자 투사) + 안개 기억 + 횃불(유효 시야 = min(층 상한, max(수정 빛, 광원, 최소) + 스탯))
- [x] TimeSystem·GameClock: 이동·대기·휴식이 시간 소모, 폐쇄 경고(24/6/1h)·강제 귀환, `EventBus.time_advanced`
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

### M2 전투 ⬜
- [ ] Timeline(CTB: 틱마다 gauge += agi, 100 이상이면 행동, delay_cost), 다음 10행동 미리보기
- [ ] CombatManager + 전투 화면(같은 3/4 무대에서 대열 마주보기), 커맨드 UI(공격·스킬·방어·아이템·도주·정보·약점 노리기)
- [ ] 전투 효과 핸들러: damage(§6.4 공식·치명타·치명상), flee 등 → `check_skill_effects = true`로 스킬 효과도 엄격 검사
- [ ] Monster(Actor 상속, overrides로 고정 최대치) / Party, 탐험 맵에 보이는 적·경계/추적·접촉 시 전투 시작
- [ ] 1층 몬스터 4종(칼날늑대·노움·구울·고블린) + 규칙 기반 AI(`ai: [{if, use}]` 조건 레지스트리), 상성·약점
- [ ] 바깥 휴식의 습격 위험, 디버그 몬스터 소환

### M3 성장 ⬜
- [ ] Bestiary·첫 처치 경험치, Leveling(경험치 테이블, 슬롯), 정수 드롭·흡수·슬롯·삭제(정수 설정은 사용자 자료 받은 뒤)
- [ ] 마석 드롭, 장비/인벤토리 UI/포션, Knowledge(`???` 공개), 포탈 최초 개방 경험치

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
| 2026-10-10 | M1 전체 | 〃 | check.sh 통과: 데이터 검증(오류 0, 경고 2: 스프라이트 없음 17·전투 효과 핸들러 M2), 단위 테스트 73/73(생성 약 0.1~0.15초, 한 걸음 약 0.8ms), UI 스모크 3흐름 통과(로그 153줄), 메인 씬 스모크 통과, 종료 시 누수 없음. 스크린샷으로 3/4 시점·횃불·안개·HUD·디버그 패널 확인 |

## 다음 할 일 (M2 시작 시)

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
- 탐험 화면의 성능: 한 걸음 처리 약 0.8ms(로직). 그리기는 바뀐 청크·벽 줄만 다시 그린다. 웹에서의 실측은 아직 없음.
