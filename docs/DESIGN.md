# DESIGN — 던전 앤 스톤 설계 요약

> 원본 지시서: `docs/PROMPT.md`(§ 번호는 그 문서 기준). 이 문서는 요약 + **구현하면서 확정한 결정**을 담는다.
> 가정은 `docs/ASSUMPTIONS.md`, 진행 상황은 `docs/PROGRESS.md`.

## 1. 정체성

- 작중 게임 「던전 앤 스톤」 그 자체를 만든다. 플레이어는 게임 속 탐험가. 비상업 팬 프로젝트.
- 2D **3/4 오블리크 탑다운**(『피어 앤 헝거』식) 던전 크롤러 + **민첩이 순서·횟수를 정하는 CTB 턴제**(『33원정대』식) + 하드코어 로그라이크.
- 어둡고 잔혹하고 불친절하지만, **모든 것은 공략 가능**하다. 히든 피스·숨은 조건·정보의 가치가 핵심 재미. 불합리한 즉사는 금지.
- 원작 인물·현실 쪽 설정·원작 문장은 넣지 않는다. 설정(규칙·수치·명칭)만 쓴다.

## 2. 게임 루프 (§5)

도시(라프도니아: 정보·상점·정수 정리·휴식) → 월 1회 포탈 개방일에 차원광장에서 입장(시작 위치 랜덤) → 층 탐험·사냥·히든 피스(시간·허기·시야 제약) → 다음 층 포탈 또는 폐쇄 시간까지 버티기 → 강제 귀환(항상 **다음 날 정오**) → 환전·정수 흡수·정비 → 반복. **사망 = 캐릭터 영구 삭제**, 묘비 목록에 기록.

## 3. 스탯과 자원 (§6) — 구현됨(M0)

**스탯(능력치)과 자원(게이지)은 완전히 분리**한다.

### 스탯 레지스트리 (`data/stats.json` → `StatDef`, 계산은 `StatBlock`)
- 핵심 5종: `str` 근력, `agi` 민첩, `p_res` 물리내성, `m_res` 항마력, `int` 정신력(이 프로젝트에선 마법 공격력).
- 세부 스탯 35종을 **정의만** 등록(유연성, 골강도, 시각, 체중, 식욕, … 지지도). `implemented: true`인 것만 규칙에 연결됨(현재: 골강도→물리내성, 근질량→근력, 식욕→허기 감소, 자연재생력→생명력 재생, 영혼 재생력→영혼력 재생).
- 필드: `id, name_ko, group(body/mind/ability/special), tier(core/sub), rarity, parent, coef, visible(false=투명), implemented, default, min, max, desc_ko`.
- 계산: `클램프((기본 + Σflat + Σ(자식 값 × coef)) × max(0, 1 + Σpercent))`. percent는 **합산 후 한 번** 곱한다.
- `Modifier{source_id, target, flat, percent, duration, unit(turn/hour)}` — 출처별 추가/제거, `tick(unit, amount)`로 만료.
- 새 스탯 = stats.json 한 줄. 효과가 필요하면 그 스탯을 읽는 수식/규칙 하나만 추가.

### 자원 (`data/resources.json` → `ResourceDef`, 컴포넌트 `ResourcePool`)
| id | 이름 | 최대치 | 재생/감소 | 임계·0 |
|---|---|---|---|---|
| hp | 생명력 | `base + level×a + p_res×b + str×c` | 시간당 자연재생력×계수, 휴식 시 비율 | 0 → kill(치명상 규칙은 M2) |
| soul | 영혼력 | 레벨 테이블(Lv1=10, Lv5까지 +10, 이후 +30) + `max:soul` 수정자(업적·정수) | 턴/시간당 최대치 비율(영혼 재생력 보정), 휴식 | 0 → 영혼탈진(스킬 불가) |
| hunger | 허기 | 100 | 미궁 안에서만 시간당 감소(식욕 보정) | ≤30% 허기, ≤10% 굶주림, 0 → 아사 |
- 예약(정의만, `enabled:false`): 기력·마력·신성력·스트레스.
- 필드: `id, name_ko, color, max_formula|max, start(full/empty/비율), scope(always/dungeon_only/combat_only), regen[{trigger: turn|time|rest, basis: max_ratio|flat, rate}], thresholds[{at_ratio, direction: down|up, apply_status|event}], on_zero("kill" | {status, recover_at_ratio} | {event}), visible, enabled, display_inverted, cost_strict`.
- `ResourcePool`: `get_current/get_max/get_ratio`, `modify(id, delta, source)`, `set_current`, `can_afford(costs)`, `spend(costs)`(원자적), `tick(trigger, amount)`, `set_level`, `set_context("dungeon"|"combat", bool)`, `to_dict/load_dict`. 시그널 `changed`, `threshold_crossed(id, threshold, entered)`, `depleted`, `recovered`, `context_changed`.
- 스탯이 바뀌면 최대치를 다시 계산하고 **현재값은 유지**(넘치면 클램프).
- 코스트는 어떤 자원이든 `{"soul": 5, "hp": 10}`. `cost_strict`(생명력)는 코스트로 0이 될 수 없다.

### 수식 문법 (`Formula`)
`{키}` + 사칙연산·괄호·`min`/`max`/`floor` 등. 키 = `level`, `bal.<balance.json 경로>`, `<스탯 id>`. 검증기가 모든 키의 존재를 확인한다.

### 파생 수치 (§6.4, M2에서 연결 — 계수는 `balance.json.combat`)
물리 공격력 = 무기 + str×계수, 마법 공격력 = 스킬 기본 + int×계수, 피해 = 공격력 × 배율 × 100/(100+방어), 치명타율 = 기본 + agi×계수(배율 1.5), 이동 시간 = 기본/(1+agi×계수).

## 4. 레벨·정수·경험치 (§7) — M3

- 경험치는 **몬스터 종류별 최초 처치 시에만**(도감). 지급 = 10 − 등급(+변이 1, 균열 수호자 3(반복), 8층+ 수호자 5, 계층군주 15, 포탈 최초 개방 약 2).
- 레벨업: 영혼력 최대치 상승 + 정수 슬롯 +1. 1차 상한 Lv5, 데이터상 11까지.
- 정수: 9등급(최하)~1등급. 흡수는 되돌릴 수 없음(삭제는 대신전 유료). **설정은 사용자 요청으로 보류** — `data/essences/_template.json`만 존재.
- 정보의 가치: 몬스터 스탯·정수 효과·히든 피스는 `???` → 관찰/길드 정보 구매로 공개(`Knowledge`).

## 5. 전투 (§8) — M2

- 맵에서 적과 접촉/발각 시 시작(랜덤 인카운터 없음). CTB: 틱마다 `gauge += agi`, 임계값(100) 이상이면 행동 후 `gauge -= 100 + delay_cost`. 상단에 다음 행동 10개 타임라인.
- 커맨드: 공격, 스킬(코스트는 임의 자원), 방어, 아이템, 도주, 정보, 약점 노리기.
- 하드코어: 치명상(`lethal_chance`)은 끌 수 없다(확률만 데이터).
- 스킬/효과 데이터 기반: `SkillDef{target, cost, delay_cost, cooldown, effects[]}`, 효과 타입 = `src/combat/effects/` 1파일 1타입 핸들러 레지스트리. 검증기는 `effect_types`가 주어지면 효과 type도 검사한다.
- 상태이상(`statuses.json`): `modifiers[]`, `periodic[{trigger, resource, amount}]`, `flags[]`(no_skills, skip_turn …), `duration{amount, unit}`, `stackable`.
- 상성: 몬스터 `type`(ability/spirit/body), `family[]`, `immunities[]`, `weaknesses{피해유형: 배율}`, `weak_point`. 항상 공략법이 존재해야 한다.

## 6. 탐험·맵·시간·시야 (§9) — M1

- 4방향 그리드, 1타일 = 1m(`balance.explore.meters_per_tile`). 로직은 바닥 평면, **렌더링만 3/4 시점**(벽 윗면+앞면, Y-정렬, 가려지면 반투명/실루엣). 수치는 `render.json.view`.
- 시야: 층 `visibility_cap_m`(광원이 있어도 넘지 못하는 상한) vs 광원 `light_radius_m` → **유효 시야 = min(상한, 광원)**. 원문 수치가 없으면 `"source": "placeholder"`. 드레드피어 소환 중 2m.
- 시간: 이동·전투·휴식이 시간을 쓴다. 층 폐쇄(1층 168h, 2층 240h, 3층 15일 …) 시 강제 귀환. 1~5층은 입장마다 리셋.
- 맵: 층 입장마다 절차 생성(`FloorGenerator` 인터페이스). 수정동굴 = 셀룰러 오토마타 + 고정 랜드마크 + 중심 대현자 기념비(안전지대) + 동서남북 2층 포탈.
- 저장: 단일 슬롯, 사망 시 삭제, 버전 필드 + 마이그레이션. 저장은 id 참조와 롤된 값만.

## 7. 도시·콘텐츠 (§10, §11) — M4~M6

시설은 데이터(`facilities/`)로: 길드, 환전소, 잡화점, 대장간, 대신전, 여관, 훈련장. 1층 수정동굴(칼날늑대·노움·구울·고블린), 2층 4필드, 1층 균열(빙하굴·녹색 탄광 우선), 계층군주 드레드피어, 넘버스 아이템. 세부는 PROMPT §11.

## 8. 아키텍처 결정 (M0에서 확정)

- **데이터 주도**: `data/manifest.json`이 읽을 파일을 정한다. `singletons`(balance, render, tags, audio) + `collections`(file = 배열 파일 / dir = 폴더의 *.json, 파일 하나에 객체 또는 배열). `_`로 시작하는 파일은 스키마 템플릿이라 읽지 않는다.
- **GameDatabase**(순수 저장소, 오토로드 비의존) ← **DataRegistry**(오토로드, 시작 시 로드+검증). 검증 실패 시 DataErrorScreen이 오류 목록을 보여 준다.
- **DataValidator**(컬렉션별 규칙) + **ValidatorBase**(수식 키·수정자 대상·참조·범위 도구). 도구 `tools/validate_data.gd`, 테스트, DataRegistry가 공용.
- **태그 목록**(`tags.json`): damage_types(+categories physical/magical), monster_types, families, body_parts, roles, skill_targets. 검증기가 참조한다.
- **문자열**: `Strings.t(key, args)`, ko.json은 중첩 객체 → "a.b.c" 키. 없으면 `[키]` 표시 + 경고 1회.
- **UI**: 테마는 `UiTheme.build(render.json)`로 코드 생성. 폰트 = `render.font.path` → `assets/fonts/` 첫 폰트 → 시스템 한글 폰트(SystemFont). 웹은 번들 폰트 필수.
- **오토로드**: EventBus(전역 시그널), DataRegistry, GameState(세션 시드; 이후 캐릭터·층·시간), AudioBus(키 → 파일, 없으면 무시).
- **테스트**: `TestCase` + `run_tests.gd`(로직, `--script`), `smoke_ui.tscn`(오토로드·UI, 씬 모드). 단언 0개 테스트는 실패 처리.

## 9. 데이터 스키마 (확정분)

- 몬스터: `id, name_ko, grade, floor_tags[], type, family[], immunities[], weaknesses{}, weak_point, stats{}, resources{hp, soul}(숫자|수식 — ResourcePool overrides), behavior{}, exp_first_kill, magic_stone_grade, essence_drops[{essence, chance}], skills[], ai[{if, use}], sprite, source`.
- 스킬: `id, name_ko, target(tags.skill_targets), cost{자원: 양}, delay_cost, cooldown, effects[{type, …}]`.
- 종족: `id, name_ko, enabled, stat_ranges{스탯: [최소, 최대]}(세부 스탯 가능), sprite`. 템플릿(classes): `id, name_ko, role, enabled, stat_bonus_ranges{}, start_items[], allowed_races[]`.
- 부상: `id, name_ko, parts[](tags.body_parts | any), applies_status, modifiers_by_part{부위: [수정자]}, heal{}`.
- 나머지(정수·아이템·층·균열·이벤트·시설)는 각 폴더의 `_template.json`이 초안 스키마.
