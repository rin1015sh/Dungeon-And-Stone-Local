# PROGRESS — 진행 상황

> 새 세션은 `CLAUDE.md` → 이 문서의 **현재 상태**와 **다음 할 일**부터 읽는다.

## 현재 상태 (2026-10-10)

- **M0 기반: 완료 · 검증됨** (Godot 4.7.2, Windows, `tools/check.sh` 전 단계 통과)
- 실행하면 타이틀 → **기반 점검** 화면에서 스탯 굴림·수정자·생명력/영혼력/허기를 직접 조작할 수 있다. "새 탐험가"는 M1 이후 열린다.
- 다음: **M1 탐험**.

## 마일스톤 체크리스트

### M0 기반 ✅
- [x] 프로젝트 골격(§13 폴더), 오토로드 4종(EventBus, DataRegistry, GameState, AudioBus)
- [x] 렌더러 GL Compatibility(웹 호환), 1280×720, nearest 필터
- [x] 한글 폰트/테마: `UiTheme`(render.json 팔레트), 폰트 폴백(번들 → 시스템 한글 폰트)
- [x] DataRegistry/GameDatabase: manifest 기반 로드(singletons + collections, `_` 템플릿 제외)
- [x] StatDef/StatBlock/Modifier: 레지스트리, 계산 순서, 출처별 제거, 지속시간(turn/hour), 세부→상위 기여, 저장
- [x] ResourceDef/ResourcePool: 생명력·영혼력·허기 + 예약 자원 4종, 수식 최대치, 코스트, 임계값, 범위, 재생, 저장
- [x] Formula(`{키}` 수식), Rng(시드 고정), Strings(ko.json 로더)
- [x] DataValidator(+ValidatorBase), `tools/validate_data.gd`
- [x] 테스트: `tests/run_tests.gd`(43개), `tests/smoke_ui.tscn`(버튼 구동), `tools/check.sh`
- [x] 기반 점검 화면(FoundationScreen), 데이터 오류 화면, `tools/screenshot.tscn`
- [x] 문서: CLAUDE.md, docs/DESIGN.md, PROGRESS.md, ASSUMPTIONS.md, PROMPT.md(원본), README.md

### M1 탐험 ⬜
- [ ] 3/4 시점 렌더링(벽 윗면·앞면 두 색 도형, Y-정렬, 가림 반투명/실루엣) — 수치는 `render.json.view`
- [ ] FloorGenerator 인터페이스 + 수정동굴 생성기(셀룰러 오토마타, 고정 랜드마크, 중심 기념비, 동서남북 포탈)
- [ ] 그리드 이동(4방향), 충돌은 벽 발치 기준
- [ ] FOV + 안개(탐험한 곳 흐리게 기억) + 횃불(유효 시야 = min(층 상한, 광원))
- [ ] TimeSystem(이동·휴식 시간 소모, 층 폐쇄 카운트다운, `EventBus.time_advanced`)
- [ ] 포탈·기념비·안전지대
- [ ] 디버그 패널(F1): 시간 스킵, 포탈 즉시 개방, 무적, 시드 고정, 스탯/레벨 조정
- [ ] 연출: CanvasModulate + PointLight2D, 비네트·필름 그레인 셰이더
- [ ] 탐험 HUD: 시간/날짜, 허기, 횃불 잔량, 폐쇄까지 남은 시간
- [ ] 1층 데이터: `data/floors/f1_crystal_cave.json`, 횃불 아이템

### M2 전투 ⬜
- [ ] Timeline(CTB, 다음 10행동 미리보기), CombatManager, 커맨드 UI
- [ ] 스킬/효과 핸들러 레지스트리(`src/combat/effects/` 1파일 1타입) → DataValidator.effect_types 연결
- [ ] StatusSet(상태이상 부여/해제/주기 효과) → FoundationScreen 임시 연결 교체
- [ ] Actor/PlayerCharacter/Monster/Party 컴포넌트 조합
- [ ] 1층 몬스터 4종(칼날늑대·노움·구울·고블린) + 규칙 기반 AI, 상성·약점 노리기, 치명상 판정

### M3 성장 ⬜
- [ ] Bestiary·첫 처치 경험치, Leveling(경험치 테이블, 슬롯), 정수 드롭·흡수·슬롯·삭제(정수 설정은 사용자 자료 받은 뒤)
- [ ] 마석 드롭, 장비/인벤토리/포션/허기 소모품, Knowledge(`???` 공개)

### M4 도시 ⬜
- [ ] 길드(정보·고용), 환전, 잡화점, 대장간, 대신전, 여관, 월 달력
- [ ] 층 폐쇄·강제 귀환(다음 날 정오), 저장/사망 삭제/묘비 목록

### M5 계층군주·균열 ⬜
- [ ] 드레드피어(소환 조건·페이즈·오오라·그로기), 균열(챕터·필드 효과·수호자), 빙하굴·녹색 탄광, 넘버스·귀속·부적, 히든 피스

### M6 2층 ⬜
- [ ] 4필드 생성기·몬스터·덫·무리 AI, 균열 열기용 마석 제단, 3층 포탈

### M7 확장 훅(선택) ⬜
- [ ] 베르자크·심연의 안개, 차원 붕괴, 동료 배신, 약탈자, 세금 모드, 반응형 회피/패링, 부위 부상, 추가 종족, 3층 이상

## M0 범위 / 완료 기준 / 테스트 방법

- **범위**: §16 M0 — 골격, 폰트/테마, DataRegistry, StatDef/StatBlock/Modifier, ResourceDef/ResourcePool(생명력·영혼력·허기), 문자열 로더, 테스트·검증 스크립트, 문서.
- **완료 기준**: ① 데이터 검증 오류 0 ② 단위 테스트 전부 통과 ③ UI 스모크(버튼으로 허기 임계값·영혼탈진·사망 판정까지) 통과 ④ 메인 씬이 오류 없이 실행 ⑤ 한글이 깨지지 않음.
- **테스트 방법**: `GODOT=<경로> bash tools/check.sh`, 시각 확인은 `tools/screenshot.tscn`. 사용자용 체크리스트는 README.md.

## 검증 기록

| 날짜 | 범위 | 환경 | 결과 |
|---|---|---|---|
| 2026-10-10 | M0 전체 | Godot 4.7.2 / Windows 11 | check.sh 통과: 데이터 검증(오류 0, 경고 2: 효과 핸들러 미구현·스프라이트 없음 7), 단위 테스트 43/43, UI 스모크 통과(로그 136줄), 메인 씬 스모크 통과. 스크린샷으로 한글 렌더링(시스템 폰트) 확인 |

## 다음 할 일 (M1 시작 시)

1. PROGRESS.md에 M1 "범위 / 완료 기준 / 테스트 방법"을 먼저 쓴다.
2. `data/floors/f1_crystal_cave.json`(`_template.json` 참고), 횃불 `data/items/torch.json`부터 만든다.
3. `src/explore/`: `FloorMap`(그리드 데이터: 바닥/벽/랜드마크/포탈), `FloorGenerator`(인터페이스, id → 생성기 레지스트리), `generators/CrystalCaveGenerator.gd`(Rng로 결정적), `Fov.gd`(그림자 캐스팅), `ExploreController.gd`.
4. 렌더러: 벽은 윗면+앞면 두 색 사각형(`render.json.view` 크기), 캐릭터는 4방향 임시 도형, `y_sort_enabled`, 벽 뒤 가림 시 반투명.
5. `TimeSystem` 오토로드 + 디버그 패널(F1, `src/ui/screens/DebugPanel.gd`).
6. 생성기·FOV·시간은 `tests/`에 결정성·경계 테스트를 추가하고, 탐험 화면 UI 스모크도 추가한다.

## 메모 / 알려진 이슈

- 번들 한글 폰트가 아직 없다(시스템 폰트 사용). **웹 내보내기 전에 OFL 폰트를 `assets/fonts/`에 넣어야 한다.** (ASSUMPTIONS E4)
- 내보내기 시 `data/**/*.json`이 포함되도록 export 필터 확인 필요(M4 무렵 export_presets.cfg 작성).
- `--import` 중 godot_mcp 플러그인의 포트 오류 메시지는 무시해도 된다.
- 원격 저장소 연결 미정: 바깥 폴더 저장소에는 remote가 없고, 안쪽 `Dungeon And Stone/`이 GitHub 클론이다(ASSUMPTIONS E1).
