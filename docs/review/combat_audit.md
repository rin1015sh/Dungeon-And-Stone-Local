# 전투·스탯·상태이상 정리와 결함 검토 (2026-10-13)

- 기준: `main` d0b380e(PR #3 병합, G1~G8 포함).
- 방법: 코드·데이터 **정적 읽기**. 이 검토 중에는 Godot을 실행하지 않았다. "확인"은 코드 경로를 끝까지 따라가서 재현 경로를 찾았다는 뜻이고, "의심"은 의도가 문서로 정해지지 않았거나 실행으로 확인해야 한다는 뜻이다.
- 범위: `src/core`(StatBlock·Formula·ResourcePool), `src/entities`(Actor·StatusSet·PlayerCharacter), `src/combat` 전체(effects·ai·patterns 포함), `data/{stats,statuses,resources,balance}.json`, 몬스터·스킬·정수 데이터, 명세 `docs/PROMPT_FLOOR1_V2.md`, `docs/ASSUMPTIONS.md`.

---

## 1. 시스템 정리

### 1.1 스탯

- 정의는 `data/stats.json`에 46종이 있다.
  - 신체(body): 근력, 민첩, 물리내성, 유연성, 골강도, 시각, 체중, 식욕, 소화력, 자연재생력, 후각, 지구력, 절삭력, 도약력, 시야, 근질량, 적응력, 수복력, 청각, 속성 내성 7종(화염·번개·대지·냉기·독·신성·어둠).
  - 정신(mind): 항마력, 정신력, 인지력, 고통내성, 투쟁심, 통제력, 인내심, 집착.
  - 능력(ability): 영혼 재생력, 감응도 4종(화염·냉기·번개·대지), 손재주, 명중률, 인식방해.
  - 특수(special): 육감, 행운, 명성, 지지도.
- 계산(`StatBlock`): `(기본 + Σflat + Σ자식×coef) × max(0, 1+Σpercent)`를 구한 뒤 범위 안으로 자른다. 수정자는 출처(`source_id`)별로 붙이고 뗀다. 출처 예: `essence:<id>`, `status:<id>`, 장비.
- 수정자 대상: 스탯 id, `max:<자원>`, `regen:<자원>`, `dmg_taken:<유형|physical|magical|all>`, `dmg_dealt:…`.
- 영구 강화(`permanent_stat`)는 `Actor.boons`에 쌓이고 `PlayerCharacter.progress_to_dict`에 저장된다.

### 1.2 자원

- 생명력: `50 + 레벨×10 + 근력×1.5 + 물리내성×3`. 0이 되면 죽는다(`on_zero: kill`). 코스트로는 0이 되지 않는다(`cost_strict`, R12).
- 영혼력: 30에서 시작해 5레벨까지 레벨당 +10, 그 뒤 +30. 재생은 차례당 최대치의 2%, 시간당 5%다. 0이 되면 영혼탈진.
- 허기: 미궁에서만 쓴다. 소화력이 재생에 들어간다.
- 임계값에 닿으면 시그널만 내고, 상태이상을 거는 것은 소유자 몫이다.

### 1.3 전투 흐름(CTB)

- 속도 = 민첩 + `speed_base` 5(최소 1). 게이지가 100에 닿으면 차례가 온다.
- 기습: 먼저 발견한 쪽 게이지에 +50.
- 단계: `await_input` → `executing` → `turn_end` → `ended`. 잘못된 행동은 `ActionCheck`가 막고 차례를 쓰지 않는다.
- 차례가 시작되면 턴 단위 상태가 1 줄어든다(`Actor.advance_turns`). 그 뒤 기절·공포면 차례를 건너뛴다.
- 행동: 공격·방어·스킬·아이템·도주(`CommandMenu`). 모든 아군에게 대화·조사 기본 스킬이 있다.
- 진영당 최대 6명. 전열·후열이 있고, `enemy_row` 대상이 있다.

### 1.4 피해·명중·치명 (`DamageCalc`)

| 항목 | 식 |
|---|---|
| 물리 공격력 | 무기(몬스터 `natural_weapon`, 맨손 2) + 근력×2 |
| 마법 공격력 | 기본값 + 정신력×2 |
| 방어 계수 | 100 / (100 + 방어×4) (물리 = 물리내성, 마법 = 항마력) |
| 편차 | ±10%, 최소 피해 1 |
| 명중 | (스킬 accuracy 기본 95 + 명중률 스탯) × (1 + 민첩 차×0.005), 30~100% |
| 치명타 | 5% + 민첩×0.3%p + 행운×1%p, 최대 60%, ×1.5 |
| 치명상(급소) | 치명타이고 피해 뒤 생명력이 30% 이하면 10% 확률로 즉사 |
| 약점 | 명중 ×0.6, 피해 ×2 (몬스터 `weak_points`, 상태 조건 가능) |
| 속성 | 내성 1점 −1%(최대 75%), 감응도 1점 +2% (G6, GC1) |
| 추가 키 | `rider`(추가 속성 피해), `str_bonus`, `defense_ignore`, `power_if_status`, `drain_if_status`, `always_hit` |
| 받는/주는 피해 | `dmg_taken:*`·`dmg_dealt:*` 수정자 |

- 피해는 `effects/damage.gd`의 `_hurt`를 거친다. 순서는 보호막 흡수(`StatusSet.absorb`), `revive_once`(`Passives.endure`), 생명력 감소, `break_on_damage` 해제, `on_hit`·`on_damaged_by`·반사·반격이다.

### 1.5 도주

- 확률 = 50% + (아군 평균 민첩 − 적 평균 민첩)×2%p, 10~90%.
- 수호자·변이 수호자·계층군주가 상대에 있으면 도주할 수 없다.

### 1.6 상태이상 (`StatusSet`, `data/statuses.json` 101종)

- 지속 단위는 `turn`(전투 차례) 또는 `hour`(게임 시간)이다. 중첩(`max_stacks`)과 `on_max_stacks`(예: 서리 → 빙결)를 지원한다.
- 걸리는 쪽 판정:
  - `resist {stats}`: 남이 건 것만 저항한다.
  - `immune_if {stat, at_least}`
  - 패시브 `status_immune`
  - 상태 `grants_immunity`
  - 패시브 `status_duration_cap`
- 효과 종류:
  - 수정자(값에 수식을 쓰면 걸릴 때 계산한다)
  - `periodic`(`{max_hp}` 같은 수식 가능)
  - `skip_turn`(기절·공포)
  - `heal_mult`(원한)
  - `misdirect`(혼란)
  - `barrier`(보호막 양)
  - `on_hit`(독성부여)
  - flag `always_hit`
  - `consume_on_attack`(진군 명령)
- 풀림 조건: `break_on_damage(_types)`(진압·빙결·자석), `battle_only`(전투가 끝나면 지운다).
- 종류(`kind`): buff / debuff. `remove_status {"kind": "debuff", "count"}`와 `pick_debuff`가 쓴다.

### 1.7 패시브·AI·보스

- 패시브(`Passives`, `BattlePassives`):
  - 적중·피격: on_hit, on_crit, on_damaged_by, reflect_melee, counter
  - 공격 보정: crit_bonus, power_vs_status, defense_ignore, hit_rider
  - 면역·탐지: status_immune, see_hidden, trap_watcher
  - 전투 시작 때: start_gauge, start_summons, foe_statuses_on_start, self_statuses_on_start
  - 라운드·차례마다: ally_aura(전체 가능), regen_per_round, turn_end_foe_status
  - 쓰러질 때·위기 때: death_effects, low_hp_summons, revive_once
  - 그 밖: dot_mult, mark_first_attacker, basic_attack_effects, flee_penalty
- AI(`MonsterAi`): 규칙은 `ai[{if, also[], use, target}]` 형식이다. 맞는 규칙이 없으면 `ai_cycle`, 그것도 없으면 기본 공격을 쓴다. 조건은 `src/combat/ai/<id>.gd`에 1파일씩 있고, 대상 값은 lowest_hp, highest_hp, with_status, without_status, ally_lowest_hp다.
- 보스:
  - 페이즈: `phases[{hp_above, …}]`. 앞으로만 넘어가고, 큰 피해로 여러 단계를 건너뛰면 사이 단계를 차례로 거친다.
  - 라운드 = 보스 자기 차례(기절로 건너뛰어도 센다).
  - 패턴: `patterns/<id>.gd`, 범용 `guardian`.
  - 예고 공격: `BattleDelayed`. `guarded_mult`가 있고, 추가 행동 차례에는 진행되지 않는다.
  - 게이지: `Meters`.
- 소환·분열·흡수: `BattleSpawns`. 만료된 유닛은 `is_active`에서 빠져 타임라인·승리 판정·보상에서 제외된다.
- 균열 전투 규칙: 생존 웨이브(`BattleObjective`), 수수께끼 결과(`BattleRules.set_objective` → `enemy_statuses`, `essence_mult`).

### 1.8 정상으로 확인한 것

- 스탯 계산 순서, 모든 변경 경로의 캐시 무효화, 출처 일치 제거.
- 턴 상태가 줄어드는 시점. 1턴 기절은 정확히 한 차례를 건너뛴다.
- 서리 → 빙결, `immune_if`·`grants_immunity`·저항 확률 식, `always_hit`, `consume_on_attack` 순서.
- 수정자 대상·수식 키·상태/스탯/자원 참조가 모두 데이터에 있다.
- 영혼력 최대치(Lv1 30, Lv5 70, Lv6 100), 공식 수치(방어·명중·치명·도주·CTB)가 명세·balance와 같다.
- 보스 페이즈 단방향, 건너뛴 보스 차례 카운트, 추가 행동 예고 면제, 예고 대상이 죽으면 다른 대상으로 바뀜.
- 몬스터 데이터의 패시브 키는 모두 코드가 읽는다. AI 조건·대상 값은 모두 등록되어 있고, 도달 불가능한 규칙이나 없는 스킬을 쓰는 규칙은 없다.
- 정수 공유 이능 묶음이 명세 §14와 같다. 수수께끼 6문항이 유효하고, 데이터·코드가 쓰는 문구 키가 `ko.json`에 모두 있다.

---

## 2. 의도대로 동작하지 않는 것

등급 기준:
- **높음**: 영구 손실(사망)이나 규칙 위반이 일반 플레이에서 일어난다.
- **중간**: 전투 결과가 명세·가정과 다르게 나온다.
- **낮음**: 드문 경우, 잠재 결함, 검증·문서 공백.

### 높음

| # | 내용 | 위치 | 재현 | 판정 |
|---|---|---|---|---|
| H1 | **정수 [분열]이 사용자를 죽일 수 있다.** 생명력 30%를 `restore_resource`(음수)로 깎는데, 이 경로에는 `cost_strict`가 걸리지 않는다. R12("스킬 사용으로 자살 방지")와 어긋난다. | `data/skills/ess_slime_split.json`, `effects/restore_resource.gd:12-14`, `ResourcePool.gd:237-240` | 생명력이 최대치의 30% 이하일 때 사용하면 사망(영구). | 확인 |

### 중간

| # | 내용 | 위치 | 재현 | 판정 |
|---|---|---|---|---|
| M1 | **턴 단위 상태가 전투 뒤에도 남는다.** 턴 상태는 전투 차례에서만 줄고, 전투 정리는 `battle_only`만 지운다. 방어 태세(받는 피해 −50%), 공포, 봉인 등 `battle_only`가 아닌 턴 상태는 다음 전투까지 그대로 남는다. | `BattleRules.gd:76-84`, `StatusSet.gd:190-197` | 방어한 직후 전투가 끝나면 다음 전투 첫 피해가 절반이 된다. | 확인 |
| M2 | **보호막이 다 막은 치명타도 즉사시킬 수 있다.** 치명상 판정이 보호막 흡수 전 생명력으로 계산되고, 즉사는 `_hurt`를 거치지 않고 생명력을 0으로 만든다. | `DamageCalc.gd:55-60`, `effects/damage.gd:52-55` | 보호막 80, 생명력 100/100, 치명타 80 → 보호막이 다 흡수했는데 10% 확률로 사망. | 확인 |
| M3 | **`revive_once`·보호막을 거치지 않는 피해 경로.** `pool.modify`를 직접 부르는 곳이 있다: `meter_damage`(드레드피어 내면의 거울), smite, 반사(reflect_melee), 반격(counter). GI7(부활은 피해 효과에 걸림)과 GC7(보호막이 먼저 받음)에 어긋난다. | `effects/meter_damage.gd:15`, `BattleRules.gd:103`, `Passives.gd:105,112` | 배리드언 정수를 가진 아군이 내면의 거울로 쓰러지면 부활 없이 사망. | 확인 |
| M4 | **죽은 지휘관의 오라가 남는다.** 쓰러짐 처리(`on_down`)가 `refresh_auras`를 부르지 않는다. | `Battle.gd:263-278`, `BattlePassives.gd:79-87` | 데드맨 지휘관이나 구울 군주가 죽어도 남은 아군의 근력 +15%가 다음 소환·분열·만료 때까지 유지된다. | 확인 |
| M5 | **부패·굶주림의 "재생 차단"이 전투 재생에는 안 걸린다.** `regen_per_round`는 `heal_mult`만 보고 `regen:hp` 수정자는 보지 않는다. | `BattlePassives.gd:57-62` | 재생 패시브 정수(데스핀드·킬두이 등)를 가진 아군이 부패에 걸려도 매 차례 4% 회복한다. | 확인 |
| M6 | **원한의 징표(grudge_mark)가 영구히 남는다.** `persist: "dungeon"` 값을 읽는 코드가 없고, 미궁이 닫힐 때 지우지도 않는다. 명세는 "미궁이 닫힐 때까지"다. | `statuses.json` grudge_mark, `StatusSet.gd:120` | 벤시를 먼저 때려 징표가 붙은 뒤 탈출해도 다음 미궁까지 남는다. | 확인 |
| M7 | **스켈레톤 메이지의 뼈 방벽이 항상 자기에게만 걸린다.** AI 규칙에 target이 없어 무작위 적을 고르고, `ally_single`은 아군이 아니면 시전자로 바뀐다. 명세 §9.3은 "아군 1명"이다. | `data/monsters/skeleton_mage.json`, `MonsterAi.gd:88`, `BattleTargets.gd:20-21` | 늘 자기 자신에게만 방벽을 건다. | 확인 |
| M8 | **적이 모두 도망쳐도 "승리"가 된다.** 적 진영이 비면 무조건 VICTORY이고, 탐험 쪽은 그 무리를 지운다. 처치·보상은 없다. 균열 연전이나 지도자 판정도 승리로 친다. | `Battle.gd:284-288`, `ExploreSession.gd:315-317` | 고블린이 도주 스킬로 다 빠지면 무리가 사라지고 처치 0. | 코드 확인, 의도는 의심 |
| M9 | **기습이 첫 차례를 보장하지 않는다.** 게이지 +50만 준다. 명세 §1은 "먼저 발견한 쪽이 1라운드를 먼저 행동"이다. | `Battle.gd:79-83` | 아군 민첩 10(속도 15)이 기습해도 적 민첩 35(속도 40)가 먼저 움직인다(3.33틱 대 2.5틱). | 계산 확인, 의도는 의심 |
| M10 | **방어 태세(1턴)가 예고 공격 전에 풀릴 수 있다.** 방어는 방어자의 다음 차례에 끝나는데, 예고는 시전자 차례에 터진다. 방어자가 더 빠르면 대응 수단(`guarded_mult`)이 소용없어진다. 블라터·킹슬라임·타룬바스·폭탄병이 해당된다. | `statuses.json` guarding, `BattleDelayed.gd:36` | 빠른 아군이 예고를 보고 방어해도 맞기 전에 방어가 풀린다. | 의심(실행 확인 필요) |

### 낮음

| # | 내용 | 위치 |
|---|---|---|
| L1 | 봉인(seal_skill)이 면역 검사 없이 스킬을 잠근다. 면역 대상도 잠기고, 게이지는 면역인데도 "가득 참"을 출력한다. | `effects/seal_skill.gd:13-21`, `BattleRules.gd:168-170`, `Meters.gd:31-37` |
| L2 | `foe_statuses_on_start`가 면역·저항·지속 상한을 무시한다. 블라터 정수를 가진 플레이어가 면역 몬스터와 싸우면 드러난다. `turn_end_foe_status`는 면역을 확인한다. | `BattlePassives.gd:25` |
| L3 | `break_on_damage`가 보호막 흡수 전 피해로 판정한다. 보호막이 다 막아도 진압·빙결·자석이 풀린다. | `effects/damage.gd:38-39` |
| L4 | 몬스터의 도주 스킬과 대화 물러남이 `no_flee`(아군 쪽 수호자)를 보지 않는다. 지금은 고블린만 쓴다. | `ActionCheck.gd:27-51`, `BattleRules.gd:52-53,140-145` |
| L5 | 도주는 한 사람만 이탈하는데 확률은 파티 평균으로 계산한다. 전원 도주인지 개인 도주인지 정해지지 않았다. | `Battle.gd:254-260` |
| L6 | 효과 없는 아이템(생명력이 가득 찰 때 회복약, 이미 켠 광원)도 차례를 쓴다. 아이템은 남는다. | `Battle.gd:164-171,241-247` |
| L7 | 다중 대상 스킬에서 진군 명령이 첫 대상 때 소모돼 나머지 대상은 보너스를 못 받는다. | `effects/damage.gd:21-23` |
| L8 | 지도자가 기절하면 생존 웨이브 라운드를 세지 않는다(보스 라운드는 센다, DF1과 불일치). | `Battle.gd:132-138,174` |
| L9 | 시전자가 죽으면 대기 중인 예고가 사라지고 대상의 `telegraphed` 표시는 남는다. | `BattleDelayed.gd:16-31` |
| L10 | 페이즈 시작 스킬로 쓰러진 경우 사망 메시지와 `death_effects`가 다음 행동 때 처리된다. 마지막 아군이 이렇게 쓰러지면 패배 메시지가 늦을 수 있다. | `Battle.gd:270-277` |
| L11 | 보호막 흡수에 올림(`ceil`)을 써서 부동소수점 오차가 있으면 보호막이 음수가 될 수 있다. | `StatusSet.gd:107` |
| L12 | 막고 찌르기(counter_stance)는 "근접 피해 −30%"인데 `dmg_taken:physical`이라 원거리 물리 피해도 줄인다. | `statuses.json` counter_stance |
| L13 | 최대 생명력이 줄어 죽으면 사망 원인이 직전 출처로 기록된다(`_last_source` 미갱신). | `ResourcePool.gd:206-218` |
| L14 | `MAX_SKIPS`(1000)를 다 쓰면 끝 판정 없이 null을 돌려준다. 매우 드물다. | `Battle.gd:117-143` |
| L15 | 저장이 굴림 기본 스탯·상태이상·수정자를 담지 않는다. 지금은 테스트만 부르지만 M4 저장을 연결하면 깨진다. | `PlayerCharacter.gd:108,128` |
| L16 | 불러오기에서 정의 없는 상태를 버려도 그 상태의 수정자는 StatBlock에 남는다. 임계값 상태도 다시 적용하지 않는다. | `StatusSet.gd:205-210`, `ResourcePool.gd:226-234` |
| L17 | 수정자별 duration을 기본값(영구)으로 덮는다. 지금 데이터에는 해당 사례가 없다. | `StatBlock.gd:89-94` |

### 명세와 다른데 ASSUMPTIONS에 기록이 없는 것

| # | 명세 | 현재 |
|---|---|---|
| S1 | 구울 §6.4: 도주 실패 시 추격 일격(위력 60) | 없음(`start_gauge`만 있음) |
| S2 | 드레드피어 뼈의 기억 §7.4: 흡수한 영혼을 보스가 얻고 증오가 흡수량에 비례 | 영혼은 제거만 되고, 증오는 +5 고정 |
| S3 | 노움 §6.9: "은신이 아니면 일체화" | AI에 50% 확률 관문이 있다 |
| S4 | 얼음 골렘 §10.3 | 명세에 없는 냉기 −50% 수정자가 있다 |
| S5 | 고블린 폭탄병 §11.3: 사망 폭발 | 명세에 없는 기본 피해 30이 더해진다 |
| S6 | 킹슬라임 §11.3: "슬라임이 있으면" 흡수 | `allies_at_least 2` 조건 |
| S7 | 배신의 장막 §7.4: 아군이 은신 | `no_ally_single`만 설정 |
| S8 | 데스핀드 §9.3: 방패를 "번갈아" | `was_hit` 조건 |

→ 의도한 조정이면 ASSUMPTIONS에 "가정 / 이유 / 바꾸는 방법"을 남기고, 아니면 데이터를 명세대로 고친다.

### 데이터·검증 공백

- **읽는 코드가 없는 데이터**
  - 상태 `burn`(화상): 아무것도 걸지 않는다.
  - `purifiable`(석화): 읽지 않으므로 정화로 석화가 풀린다.
  - `mental`: 읽지 않는다.
- **효과가 확인되지 않은 스탯**: `cutting_power`, `body_weight`, `pain_tolerance`, `control`은 `src`에서 직접 읽는 곳이 없다. 데이터의 `stat` 필드로 간접 사용될 가능성은 남아 있다(의심).
- **속성 스탯 누락**
  - 없는 스탯: `resist_sun`, `resist_arcane`, `affinity_poison/holy/dark/sun/arcane`
  - 결과: 해당 유형의 내성·감응도는 조용히 무효다.
- **검증기 공백**
  - 검증기와 핸들러의 기본값이 다르다: seal_skill rounds, delayed rounds, meter_damage mult, push_back amount. 생략하면 검증이 막는다(오탐).
  - smite에는 검증기가 없다. 잘못된 status id는 실행 중 `push_error`가 된다.
  - `damage_type` 오타는 조용히 물리 피해로 처리된다.
  - 상태 수정자의 `target`과 `immune_if.at_least`를 검사하지 않는다. `at_least`가 빠지면 0이 되어 항상 면역이다.
- **매직 넘버·대체값**
  - `DamageCalc.gd:66,69`의 대체값 1.0이 balance(2.0)와 달라서, 키가 빠지면 공격력이 절반이 된다.
  - `BattlePassives.gd:96`·`Passives.gd:128`에 0.3이 있다.
  - `meter_damage`에 `"dark"`, 감응 1.0이 고정되어 있다.
  - 분열의 hp/2, `soul_slash`의 기본값.
- **문서 불일치**: `stats.json` 항마력 설명은 "400 이상 제압 면역"인데 `immune_if`는 25다.

---

## 3. 고치는 순서 제안

1. **H1, M2, M3**: 영구 사망과 관련된 것부터 고친다. 생명력이 줄어드는 경로를 `_hurt`/`endure` 하나로 모으고, 자기 소모는 1 이하로 내려가지 않게 한다.
2. **M1, M6**: 전투가 끝날 때 턴 단위 상태를 지우고, 미궁이 닫힐 때 `persist: dungeon` 상태를 지운다.
3. **M4, M5, M7**: 쓰러질 때 오라를 다시 계산하고, 전투 재생에 재생 차단을 적용하고, 메이지 AI에 `ally_lowest_hp` 대상을 넣는다.
4. **M8, M9, M10**: 규칙 결정이 필요하다(적 전원 도주 결과, 기습 첫 차례 보장, 방어 지속을 "다음 피격까지" 또는 "라운드 끝까지"로 할지). 정한 뒤 ASSUMPTIONS에 기록한다.
5. S1~S8은 데이터 정리 또는 ASSUMPTIONS 기록, 검증기 공백과 매직 넘버는 한 번에 정리한다.

각 수정에는 재현 테스트를 먼저 `tests/`에 넣고 `tools/check.sh`로 확인한다.
