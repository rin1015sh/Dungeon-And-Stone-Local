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
- 세부 스탯은 **주 스탯 5종(근력·민첩·물리내성·항마력·정신력)으로 대체할 수 없는 17종만** 남긴다(2026-10-14, ASSUMPTIONS ST1~ST4): 시각(시야) · 식욕·소화력(허기) · 자연재생력·영혼 재생력(재생) · 명중률(명중·실명) · 감응도 4(화염·냉기·번개·대지 피해 +) · 내성 7(화염·번개·대지·냉기·독·신성·어둠 피해 −, 냉기·독은 상태 저항도). 나머지(근질량·골강도·절삭력·유연성·후각·육감·손재주·행운 …)는 지우고 주 스탯 ×0.5로 옮겼다. 모두 `implemented: true`.
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

## 4. 레벨·정수·경험치 (§7) — M3 → G1·정수 1차(2026-10-12, `docs/PROMPT_FLOOR1_V2.md` §3·§5)

- 경험치(`data/progression.json`): 종별 첫 처치 = 10 − 등급(상위 변이종 +1, 무등급·토큰 0), 수호자 +3(반복, 8층+ +5), 계층군주 +15(군주별 1회), 포탈 +2(1~5층은 매달 포탈마다 첫 통과), 숨겨진 포탈 +99(1회), 꿈꾸는 영혼 +10,000(10레벨 도달 시).
- 레벨 표(누적): 0 / 8 / 50 / 250 / 660 / 1000 / 1400 / 2600 / 3400 / 4400 / 18000, 만렙 11. 1~4층 전 종 처치로는 5레벨에 조금 못 미치게(`tools/exp_budget.gd`가 93~99% 검사).
- 레벨업: 정수 슬롯 = 레벨, 영혼력 Lv1 30 → 5레벨까지 +10 → 이후 +30, 생명력 = 50 + 레벨×10 + 근력×1.5 + 물리내성×3. 레벨 하락 시 정수가 무작위로 잠긴다(다시 오르면 풀림).
- 정수: 몬스터당 1파일, 패시브 1 + 색 → 액티브(정수판 스킬), 수호자 정수 = 무지갯빛(액티브 전부·×1.5), 패시브·스킬이 겹치면 흡수 불가. 흡수는 되돌릴 수 없음(삭제는 대신전 유료, M4).
- 정보의 가치: 몬스터 스탯·정수 효과·히든 피스는 `???` → 관찰/길드 정보 구매로 공개(`Knowledge`).

## 4b. 성장·소지품 (§7) — M3

- **Progression**(캐릭터 영구): 공적(위 획득원), 처치 수(도감), 레벨 = `progression.json level.exp_table`. **Knowledge**: seen/stats/affinity → 도감·조사에서 `???` 공개. **Loot/Rewards**: 승리 시 마석·drops를 가방에, 공적·레벨업 메시지.
- **Inventory**: 격자 가방(크기 w×h, 쌓기, 자리 찾기, 옮기기, 돈). **Equipment**: 11칸, 양손, 반지 2, `equip:<칸>` 수정자. **InventoryActions**: 가방↔장비(자리 없으면 실패, 아이템을 잃지 않음).
- **UI(스톤샤드풍)**: `GothicWindow`(돌판 테두리 + 아치 머리 + 이름판), `InventoryWindow`(장비 인형 + 격자 + 끌어놓기 + 툴팁 비교), `CharacterWindow`, `BestiaryWindow`, `BottomBar`(큰 막대 + 단축칸 1~0 + 버튼), `WindowManager`(I/C/B, 열려 있으면 시간 정지).

## 5. 전투 (§8) — M2

- 맵에서 적과 접촉/발각 시 시작(랜덤 인카운터 없음). CTB: 틱마다 `gauge += agi`, 임계값(100) 이상이면 행동 후 `gauge -= 100 + delay_cost`. 아군·몬스터 구분 없이 민첩 순. **화면에 순서 목록은 띄우지 않는다**(현재 차례 카드만 강조, `Battle.preview()`는 로직·테스트용으로 남김).
- 기본 행동창(2026-10-11 재구성): **공격**(대상 선택, 약점이 있는 적은 "약점 노리기"도) · **방어** · **스킬**(보유 스킬 하위 메뉴, 맨 아래 "아이템…") · **도주**.
- 기본 스킬: 모든 아군(플레이어·동료)이 시작부터 **대화**·**조사**를 가진다(`balance.party.innate_skills`, 스킬 데이터 `"innate": true` → 잊을 수 없음). 조사는 옛 '정보' 커맨드를 대신하며 차례를 쓴다. 대화는 말이 통하는 상대(`Actor.understands_speech()`)에게만 결과(머뭇거림·무시·자극·물러남)가 있고, **마수는 전부 통하지 않는다**(계열별 반응 문장만, 차례 소모).
- 전투 상태: `Battle.phase` idle → await_input → executing → turn_end → … → ended. `act()`는 현재 차례·await_input일 때 한 번만 적용, 잘못된 행동(모르는 스킬·코스트·쿨타임·봉인·사라진 대상)은 차례를 쓰지 않고 false(`ActionCheck`). 몬스터 AI는 `MonsterAi`.
- 하드코어: 치명상(`lethal_chance`)은 끌 수 없다(확률만 데이터).
- 스킬/효과 데이터 기반: `SkillDef{target, cost, delay_cost, cooldown, effects[]}`, 효과 타입 = `src/combat/effects/` 1파일 1타입 핸들러 레지스트리. 검증기는 `effect_types`가 주어지면 효과 type도 검사한다.
- 상태이상(`statuses.json`): `modifiers[]`, `periodic[{trigger, resource, amount}]`, `flags[]`(no_skills, skip_turn …), `duration{amount, unit}`, `stackable`.
- 상성: 몬스터 `type`(ability/spirit/body), `family[]`, `immunities[]`, `weaknesses{피해유형: 배율}`, `weak_point`. 항상 공략법이 존재해야 한다.

## 6. 탐험·맵·시간·시야 (§9) — 구현됨(M1)

- 이동(2026-10-11): **부드러운 연속 이동**(8방향, 칸 단위 연속 좌표 `fpos`). 충돌은 `Kinematics`(반폭 0.3칸 몸 vs 걸을 수 없는 칸, 축 분리 미끄러짐, 터널링 방지 분할, 모서리 보정). 몬스터는 `MonsterSteering`이 칸 길찾기로 경유점을 정해 연속으로 걷는다. 시야·발견·안전지대는 몸 중심 칸.
- 지도는 격자(1타일 = 1m)(`balance.explore.meters_per_tile`). 로직은 바닥 평면, **렌더링만 3/4 시점**(벽 윗면+앞면, Y-정렬, 가려지면 반투명/실루엣). 수치는 `render.json.view`.
- 시야: 층 `visibility_cap_m`(광원이 있어도 넘지 못하는 상한) vs 광원 `light_radius_m` → **유효 시야 = min(상한, 광원)**. 원문 수치가 없으면 `"source": "placeholder"`. 드레드피어 소환 중 2m.
- 시간(2026-10-11 실시간화): 탐험 중 시간은 **실시간으로 흐른다**(`RealtimeDriver`, 실제 1초 = 게임 `realtime_hours_per_sec`시간, 고정 틱 `realtime_tick_sec`, 프레임당 최대 `realtime_max_frame_sec`). 가만히 있어도 허기·광원·몬스터가 진행된다. 이동은 시간을 쓰지 않고 민첩에 따른 **이동 간격**(`move_hours`)만 둔다(몬스터와 같은 공식, 연타해도 빨라지지 않음). 시간이 멈추는 때: 전투 중(끝나면 차례 수 × `hours_per_turn` 반영) · 일시정지(Esc/P) · 디버그 패널 · 입력칸 입력 · 창 포커스 잃음 · 탐험 종료. 대기(Space, 1시간)·휴식(Z, 8시간)은 즉시 넘기기. 층 폐쇄(1층 168h, 2층 240h, 3층 15일 …) 시 강제 귀환. 1~5층은 입장마다 리셋.
- 맵: 층 입장마다 절차 생성(`FloorGenerator` 인터페이스). 수정동굴(2026-10-12 재설계) = 거대한 두꺼운 십자가(중심부 + 동·서·남·북 팔, 바깥은 암반). 중심부에 대현자 기념비(안전지대), 팔 안은 급커브 많은 스파게티 굴(폭 2~3칸, 막다른 길 없이 모두 순환로), 팔 끝에 암흑지대 + 2층 포탈(위치 고정). 구역마다 스폰 표(중심부 4종, 팔마다 1종).
- 저장: 단일 슬롯, 사망 시 삭제, 버전 필드 + 마이그레이션. 저장은 id 참조와 롤된 값만.

### M1에서 확정한 탐험 구조
- **FloorMap**: 칸마다 타일 인덱스(`tiles.json` → `TileDef`: kind floor/wall, walkable, blocks_sight, colors, face_px, light, interact, sprite), 암흑지대·구역(zones)·탐험 기록·현재 시야 배열, 랜드마크·포탈(dest)·안전지대 목록. 이동·충돌·시야는 전부 이 평면 기준.
- **생성기 레지스트리**: `src/explore/generators/<id>.gd` 파일 하나 = 생성기 하나(`ScriptRegistry`가 폴더를 훑는다). 층 정의의 `generator`가 id. 생성기마다 `validate(floor_def, db)`로 자기 전용 값을 검사한다.
- **수정동굴(crystal_cave)** — 십자가(2026-10-12):
  - `CrossLayout`(고정 뼈대): 중심부 정사각형(core_size) + 팔 4개(arm_length × arm_width). 칸 → 구역(center/east/west/south/north/암반), 팔 깊이, 암흑지대(팔 끝 dark_depth칸), 포탈 자리(팔 끝에서 portal_inset칸 안쪽). 북 = 지도 위.
  - `CrossTerrain` + `CaveCarver`(시드): 팔 수 있는 칸(윤곽 ±2칸 흔들림) → 중심부 셀룰러 오토마타 → 기념비 공터 → **등뼈 길**(기념비 → 포탈, 앞·옆·계단 구간을 번갈아 급커브, 절대 뒤로 가지 않음 = 나침반 경로 보장) → **곁가지**(빈 땅을 골라 가장 가까운 굴에서 그쪽으로, 다른 굴에 닿으면 합류 = 순환, 못 닿으면 다른 굴로 다시 잇기 또는 되돌리기) → 벽 깎기 → 포탈 공동 → 떨어진 굴은 십자가 안으로만 잇거나 메움 → `GridWiden`(통로 폭 최소 2). 굴은 2~3칸 정사각 붓으로 판다.
  - 생성기: 타일·구역·암흑지대 → 기념비(안전지대) → 포탈(dest) → 무작위 랜드마크(십자가 안·암흑지대 밖, 벽 없는 도장) → 폭 다시 맞추기 → **막다른 곳 메우기**(`GridSpurs`: 2×2 블록 그래프를 깎아 순환로·거점 사이 길에 속하지 않는 칸) → 수정벽(암흑지대 둘레 제외) → 시작 위치(팔 안).
  - 검사 `CrossLayoutCheck`(테스트·`tools/floor_map.gd` 공용): 네 포탈 도달·나침반 경로·연결·암흑지대 위치·통로 폭·막다른 길·구역 스폰. `tools/floor_map.gd`가 층 전체를 PNG로 그린다(구역 색·암흑지대·고정 장소·무리).
- **랜드마크**: `landmarks.json`의 문자열 도장(stamp) + legend(글자 → 타일, null = 유지) + anchor(위치 기준 글자). 층 정의의 `landmarks`가 배치(center/random, count, safe_zone_radius).
- **시야(FOV)**: 재귀 그림자 투사 8분면. 반경 = 유효 시야(m) / meters_per_tile.
- **ExploreSession**(순수 로직): 이동·대기·휴식·아이템·살피기, 시간 흐름(층 폐쇄 시각에서 자름), 폐쇄 경고(24/6/1시간 전)·강제 귀환, 발견(랜드마크·포탈은 처음 보일 때), 안전지대·암흑지대 진입 알림, 사망. 메시지는 문자열 키로만 내고 화면이 번역한다.
- **시간**: `GameClock`은 미궁 경과 시간(입장 시 0). `TimeSystem` 오토로드가 원정 시계를 갖고 `EventBus.time_advanced`를 낸다. 도시 달력(포탈 개방일, 다음 날 정오 귀환)은 M4.
- **개체(Actor)**: StatBlock·ResourcePool·StatusSet·Inventory·LightSource 조합. 자원 임계값 → 상태이상(허기·굶주림), 0 → on_zero(아사·영혼탈진·사망). 사인은 마지막으로 생명력을 바꾼 출처(`status:starvation` 등).
- **상태이상(StatusSet)**: 부여 시 modifiers를 `status:<id>` 출처로 붙이고, periodic(턴/시간)으로 자원을 바꾸고, duration이 다하면 해제, stackable이면 중첩.
- **효과 레지스트리**: `src/combat/effects/<type>.gd`(EffectHandler) 1파일 = 1타입. 현재 restore_resource, light_source, apply_status, remove_status. 아이템 use_effects는 엄격 검사, 스킬 effects 타입 검사는 전투 핸들러가 생기는 M2부터(`check_skill_effects`).
- **아이템 사용**: `ItemUser` — 효과가 실제로 일어났고 consumable이면 하나 소모(배부르면 식량을 먹지 않고, 횃불이 타고 있으면 새로 켜지 않는다).
- **그리기(3/4 시점)**: FloorView = 바닥 청크(FloorChunk, 항상 아래) + 벽 줄(WallRow, 줄 단위 y-정렬) + 캐릭터(ActorView, 발 위치 정렬). 벽 = 윗면(바닥 칸에서 앞면 높이만큼 위로) + 앞면(돌 줄눈) + 모서리·테두리 선. 남쪽 벽에 가려지면 반투명 실루엣을 맨 위에 겹친다. 밝기는 칸 꼭짓점 색으로 섞는다(정적 광원 LightField + 시야 빛, 셰이더 없이). 안개 기억은 어둡고 차갑게, 미탐험은 그리지 않는다. 횃불이면 PointLight2D로 따뜻한 빛 번짐, CanvasModulate는 약한 색조만, 후처리 셰이더(채도·비네트·그레인). 수치는 `render.json`.
- **입력**: `data/input.json`(액션 → 키 이름, 물리 키 위치) → `InputSetup`이 InputMap에 등록. 이동은 누르고 있으면 반복.
- **흐름**: 타이틀 → 새 탐험가(이름·종족·템플릿·스탯 굴림) → 1층 생성·입장 → 탐험 → 폐쇄(강제 귀환) 또는 사망 → 결과 화면 → 타이틀. (도시 귀환·저장·묘비는 M4)

## 7. 도시·콘텐츠 (§10, §11) — M4~M6

시설은 데이터(`facilities/`)로: 길드, 환전소, 잡화점, 대장간, 대신전, 여관, 훈련장. 1층 수정동굴(칼날늑대·노움·구울·고블린), 2층 4필드, 1층 균열(빙하굴·녹색 탄광 우선), 계층군주 드레드피어, 넘버스 아이템. 세부는 PROMPT §11.

## 8. 아키텍처 결정 (M0에서 확정)

- **데이터 주도**: `data/manifest.json`이 읽을 파일을 정한다. `singletons`(balance, render, tags, audio) + `collections`(file = 배열 파일 / dir = 폴더의 *.json, 파일 하나에 객체 또는 배열). `_`로 시작하는 파일은 스키마 템플릿이라 읽지 않는다.
- **GameDatabase**(순수 저장소, 오토로드 비의존) ← **DataRegistry**(오토로드, 시작 시 로드+검증). 검증 실패 시 DataErrorScreen이 오류 목록을 보여 준다.
- **DataValidator**(진입점) + **ValidatorBase**(수식 키·수정자 대상·참조·범위·효과 검사 도구) + 규칙 그룹 `CoreRules`/`ContentRules`/`WorldRules`. 검증기는 `ContentRegistries.make_validator()`로 만든다(효과 타입·생성기 정보를 채움). 도구 `tools/validate_data.gd`, 테스트, DataRegistry가 공용.
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
- 타일: `id, name_ko, kind(floor|wall), walkable, blocks_sight, colors{floor|top,face,mark}, face_px, light{radius_m,color,intensity}, interact, sprite`.
- 랜드마크: `id, name_ko, desc_ko, stamp[문자열], legend{글자: 타일 id | null}, anchor`.
- 층: `id, name_ko, floor, generator, close_hours, resets_each_entry, visibility_cap_m, ambient_light_m, ambient_color, open_sky?, gen{size, …생성기 값, tiles{floor,wall,crystal,portal}}, landmarks[{id, placement, count, safe_zone_radius}], regions[{id, dir, monsters[]}], portals[{id, dir, to_floor}]`.
- 아이템: `id, name_ko, category(tags.item_categories), price, stack, consumable, use_effects[효과], tags, sprite`. 템플릿 start_items는 `[{id, count}]`.
- 입력(`input.json`): `actions{액션: [키 이름…]}`.
- 나머지(정수·균열·이벤트·시설)는 각 폴더의 `_template.json`이 초안 스키마.
