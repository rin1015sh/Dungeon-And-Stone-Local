# 밸런스 조절 다이얼 (도구가 만든 것 — 손으로 고치지 않는다)

`python3 tools/balance_knobs.py`가 `data/balance.json`의 현재 값을 읽어 만든다. 다이얼을 바꾸면 "다시 돌릴 것"의 도구로 영향을 확인한다(도구 명령은 `docs/TOOLS.md`).
수치를 바꾸고 나면 `docs/ASSUMPTIONS.md`에 가정·이유·바꾸는 법을 남긴다(규칙은 CLAUDE.md).

## 난이도 점검 순서 (지속적인 도전을 위해)

1. `tools/sim_survive.gd` — 1인 1층 원정 생존율(정수 없는 구간이 가장 위험한지). `--drops=on`으로 정수 드롭(연속 실패 보정)까지, `--pack=1,2`로 날짜별 무리 크기.
2. `tools/sim_battle.gd` — Lv1 한 판 승률(목표 표 안에 들어 있다).
3. `tools/sim_party.gd` — 균열 5인 파티 승률(일반·중간 보스·수호자 첫 시도/예고 대응·변종). 결과는 `docs/balance/rift.md`.
4. `tools/formula_check.gd` — 몬스터 한 대 = 탐험가 생명력의 몇 %(등급 목표 10~16%).
5. `python3 tools/balance_sheet.py` · `python3 tools/balance_curve.py` — 총정리·10층 곡선 다시 뽑기.

목표 구간: 1층 혼자 정수 없이도 20판 정도는 절반 이상 넘기고, 첫 정수 뒤엔 크게 안정. 균열 일반 전투는 쓸모 있는 소모를 주되 거의 이김, 수호자 첫 시도 25~75%·예고 대응 75~100%, 변종·군주는 한 단계 위 파티 몫(0~10%).

## 플레이어가 강해지는 길 — 성장

| 다이얼(balance.json) | 현재 값 | 무엇 | 올리면 | 바꾼 뒤 돌릴 것 |
|---|---|---|---|---|
| `hp.base / per_level / per_p_res / per_m_res` | base=50 · per_level=10 · per_p_res=3.0 · per_m_res=3.0 | 최대 생명력 = base + 레벨×per_level + 물리내성×per_p_res + 항마력×per_m_res + 정수 생명력 | 생존력 전반 ↑. per_p_res·per_m_res가 가장 크다(10층 기준 생명력의 절반 이상) | formula_check · balance_curve.py · sim_survive |
| `soul.base / per_level_early / per_level_late` | base=30 · per_level_early=10 · per_level_late=30 | 최대 영혼력(이능 연료) | 정수 스킬을 더 많이 쓴다 | sim_party |
| `soul.regen_ratio_per_turn / regen_ratio_per_hour / regen_stat_coef` | regen_ratio_per_turn=0.02 · regen_ratio_per_hour=0.05 · regen_stat_coef=0.03 | 영혼력 재생(전투 차례당·시간당 비율, 영혼 재생력 스탯 1점당 계수) | 이능 사용 빈도 ↑ | sim_party |
| `hp.regen_ratio_per_natural_regen_per_hour` | regen_ratio_per_natural_regen_per_hour=0.002 | 자연재생력 1점당 시간당 생명력 비율 | 걷는 동안 회복 ↑(휴식은 rest.hp_ratio_per_hour) |  |
| `essence.drop_chance_by_grade` | drop_chance_by_grade={"9": 0.045, "8": 0.05, "7": 0.055, "6": 0.06, "5": 0.065, "4": 0.0… | 일반 몬스터 정수 드롭 확률(등급별) | 정수가 빨리·많이 모인다 → 성장 속도 ↑ | sim_income · sim_survive |
| `essence.pity.enabled / step / max_mult` | enabled=true · step=0.25 · max_mult=5.0 | 연속 실패 보정 — 빈 칸이 있는 동안 못 얻을 때마다 확률 배율이 step씩 오른다(max_mult까지), 얻으면 리셋 | 초반 첫 정수가 빨라진다. 칸이 차면 멈춘다 | sim_survive --drops=on [--pity=off로 비교] |
| `essence.drop_chance_by_rank` | drop_chance_by_rank={"ungraded": 0.005, "midboss": 0.1, "guardian": 0.33, "variant_guar… | 중간 보스·수호자·변이종·군주 정수 확률 | 보스 보상 ↑ |  |
| `essence.rift_mult` | rift_mult=2.2 | 균열 안 일반 몬스터 정수 확률 배율 | 균열 성장 ↑ | sim_rift |
| `essence.guardian_stat_mult` | guardian_stat_mult=1.5 | 수호자 정수(무지갯빛) 스탯·생명력 배율 | 후반 과성장 위험 ↑(곡선을 앞지르는 주범) | balance_curve.py · sim_party |
| `items.attack_by_tier / grow_by_tier` | attack_by_tier=[1.0, 3.5, 7.5, 13, 20, 30] · grow_by_tier=[1.0, 2.2, 4.0, 6.5, 9.5, 13] | 장비 단계별 공격력·증가 스탯 배율 | 장비가 정수보다 중요해진다 | item_pool.py · balance_curve.py |
| `items.rift_gear.attack_mult / grow_mult / bonus_mult` | attack_mult=1.3 · grow_mult=1.5 · bonus_mult=2.0 | 균열 장비가 대장간 같은 종류보다 센 정도 | 균열 보상 ↑(과성장 위험) | item_pool.py |

## 적이 강해지는 길 — 몬스터·조우

| 다이얼(balance.json) | 현재 값 | 무엇 | 올리면 | 바꾼 뒤 돌릴 것 |
|---|---|---|---|---|
| `combat.rank_speed` | rank_speed={"elite": 1.1, "midboss": 1.15, "guardian": 1.25, "variant_guardian… | 랭크별 CTB 속도 배율(엘리트~군주) | 보스가 더 자주 행동 → 보스전 난이도 ↑ | sim_party |
| `combat.enrage.after_turns / per_turn` | after_turns={"guardian": 25, "variant_guardian": 30, "lord": 37} · per_turn=0.1 | 보스 광폭화 시작 차례·차례마다 주는 피해 증가 | 장기전 압박 ↑(예고 대응 느리면 죽는다) | sim_party |
| `combat.front_aggro` | front_aggro=3.0 | 무작위 적 공격이 전위를 노리는 무게(후위 = 1) | 전위 부담 ↑ | sim_party |
| `combat.taunt_chance` | taunt_chance=0.75 | 끌어들이기 성공 시 먼저 노리는 확률 | 탱커 효용 ↑ |  |
| `combat.first_strike_gauge` | first_strike_gauge=50 | 맵 조우 선공 시작 게이지 |  |  |
| `combat.max_side_units` | max_side_units=6 | 한 전투 한쪽 최대 마릿수 | 무리 전투 최대 규모 ↑ |  |
| `rift.* (posts / roam / chain)` | (코드·데이터 참조) | 균열 무리 배치: 대기·떠도는 무리·연쇄 조우 수·간격 | 균열 조우 밀도 ↑ | sim_rift |
| `monsters.rest_ambush_chance_per_hour` | rest_ambush_chance_per_hour=0.04 | 휴식 중 매복 확률(시간당) | 휴식이 위험해진다 → 자원 압박 ↑ | sim_survive |
| `monsters.ai.* / screen_margin_tiles / chase_*` | (코드·데이터 참조) | 몬스터 감지·추적·수색 규칙 | 도망·회피 난이도 ↑ | sim_walk |
| `(몬스터 JSON) stats / resources / natural_weapon / skills / passives / status_immune` | (코드·데이터 참조) | 몬스터 개별 수치(등급표 기준은 docs/balance/curve.md §4) | 그 몬스터만 | balance_sheet.py · formula_check · sim_party |
| `(층 JSON) spawn.pack_by_day / groups_per_region / explorers` | (코드·데이터 참조) | 1층 날짜별 무리 크기·수·다른 탐험가 | 필드 압박 ↑ | sim_walk · sim_income · sim_survive --pack= |

## 전투 공식

| 다이얼(balance.json) | 현재 값 | 무엇 | 올리면 | 바꾼 뒤 돌릴 것 |
|---|---|---|---|---|
| `combat.defense_ratio` | defense_ratio=2.0 | 방어 비율 계수: 방어 배율 = 공격력/(공격력+방어×이 값) | 방어 스탯 가치 ↑(받는 피해 ↓) | formula_check · sim_party |
| `combat.phys_atk_per_str / mag_atk_per_int / unarmed_atk` | phys_atk_per_str=2.0 · mag_atk_per_int=2.0 · unarmed_atk=2 | 공격력 = 무기(스킬 base) + 스탯 × 계수 | 스탯이 피해에 미치는 몫 ↑ | formula_check |
| `combat.hit_agi_exp / agi_offset / default_accuracy / hit_min / hit_max` | hit_agi_exp=0.5 · agi_offset=10 · default_accuracy=95 · hit_min=0.3 · hit_max=1.0 | 명중 = (95+명중률)% × 민첩비^exp, 30~100% | exp ↑ = 민첩이 높을수록 맞히기·피하기 쉬움 | formula_check · sim_battle |
| `combat.crit_base / crit_agi_share / crit_mult` | crit_base=0.04 · crit_agi_share=0.12 · crit_mult=1.5 | 치명타율 = base + share × 민첩비, 배율 | 치명 의존 빌드 ↑ |  |
| `combat.lethal_chance_base / lethal_hp_ratio / lethal_immune_ranks` | lethal_chance_base=0.1 · lethal_hp_ratio=0.3 · lethal_immune_ranks=["midboss", "guardian", "variant_guardian", "lord"] | 치명상(즉사): 치명타로 생명력 ratio 이하가 되면 확률로 즉사, 보스급 면역 | 후반 급사 위험 ↑ |  |
| `combat.speed_base / speed_exp / max_streak` | speed_base=5 · speed_exp=0.75 · max_streak=2 | CTB 속도 = (민첩+base)^exp, 연속 행동 상한 | exp ↑ = 민첩이 행동 횟수에 더 반영 | sim_party |
| `combat.taken_build_min / taken_total_min / taken_total_max / dealt_total_max` | taken_build_min=0.4 · taken_total_min=0.2 · taken_total_max=2.5 · dealt_total_max=3.0 | 피해 수정자 곱연산의 상·하한(정수·장비 곱 최소 ×0.4 등) | 상한 완화 = 방어 빌드 쏠림 ↑ | sim_party |
| `combat.regen_per_round_max` | regen_per_round_max=0.04 | 정수 차례당 재생 합 상한(최대 생명력 비율) | 장기전 회복 ↑ |  |
| `combat.element_resist_per_point / element_resist_max / affinity_per_point` | element_resist_per_point=0.01 · element_resist_max=0.75 · affinity_per_point=0.02 | 속성 내성·감응도 1점당 효과 | 속성 빌드 ↑ |  |
| `combat.rev.max / power / basic_bonus / guard_bonus` | max=3 · power=[1.0, 1.3, 1.6, 2.0] · basic_bonus=1 · guard_bonus=1 | 기세: 최대 개수·개수별 위력 배율·기본 공격·방어로 쌓이는 양 | 플레이어 화력 ↑(보스 승률 ↑) | sim_party --rev=full |
| `combat.flee_base / flee_agi_share` | flee_base=0.5 · flee_agi_share=0.8 | 도주 확률 | 도망이 쉬워짐 → 위험 회피 ↑ |  |

## 상태이상·시간 압박

| 다이얼(balance.json) | 현재 값 | 무엇 | 올리면 | 바꾼 뒤 돌릴 것 |
|---|---|---|---|---|
| `status.bleed_ratio / poison_ratio / burn_ratio / rot_ratio / trap_ratio` | bleed_ratio=0.035 · poison_ratio=0.025 · burn_ratio=0.045 · rot_ratio=0.025 · trap_ratio=0.05 | 지속 피해 비율(중첩마다, 출혈·중독·화상·부패는 현재 생명력, 덫은 최대 생명력) — 고정값(*_per_turn)과 중 센 쪽 | 지속 피해 ↑ | sim_party |
| `status.monster_dot_scale` | monster_dot_scale=0.25 | 몬스터가 받는 비율 지속 피해 배율 | 독·출혈로 보스 깎기 ↑ |  |
| `status.resist_max` | resist_max=0.6 | 상태이상 저항 확률 상한(저항/(저항+거는 쪽 힘) × max) | 컨트롤을 버티기 쉬워진다 |  |
| `(statuses.json) duration / modifiers / skip_chance / after_immune` | (코드·데이터 참조) | 상태별 지속 시간·수치·건너뜀 확률·풀린 뒤 면역 | 그 상태만 | balance_sheet.py |
| `hunger.decay_per_hour / appetite_coef / starvation_*` | (코드·데이터 참조) | 허기 감소 속도·아사 피해 | 원정 시간 압박 ↑ |  |
| `(city.json) fatigue.dungeon / effects` | (코드·데이터 참조) | 피로: 시간당·전투 차례당 증가, 단계 효과 | 장기 원정 압박 ↑ |  |
| `rift.open_chance_by_months / open_after_hours` | open_chance_by_months={"0": 0.0, "1": 0.0, "2": 0.1, "3": 0.2, "4": 0.45, "5": 0.6, "6": … · open_after_hours=48 | 균열 개방 빈도·시각 | 도전 기회 빈도 |  |
| `(floor JSON) close_hours` | (코드·데이터 참조) | 층 닫힘까지 시간 | 시간 압박 ↑(짧을수록) | sim_income |
