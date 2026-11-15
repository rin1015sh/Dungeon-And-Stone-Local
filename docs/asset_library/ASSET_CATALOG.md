# ASSET_CATALOG — 에셋 목록

> `python3 tools/dungeon_kit/catalog.py`가 `assets/dungeon_kit/kit.json`에서 만든다 — **손으로 고치지 않는다**. 쓰는 법은 `GENERATION_GUIDE.md`, 지역별 묶음은 `REGIONAL_ASSET_PLAN.md`, 그림은 `docs/screens/asset_library/` · `docs/screens/dungeon_kit/`.

에셋 **583종** · 변형 2215개 · 그림 2864장 — 공용 544 · 지역 확장형 12 · 지역 전용 27. 지역 55곳.

- **재사용성**: 공용 = 어느 지역에나 · 지역 확장형 = 공용 에셋의 틀(`base`)을 지역 재질 · 형태로 넓힌 것 · 지역 전용 = 그 장소의 정체성.
- **우선순위**: 쓰는 지역 수로 매긴다(4곳 이상 높음 · 2~3곳 중간 · 그 밖 낮음) — 모두 만들어진 에셋이다. 아직 없는 것은 맨 아래 표.
- **기능**: 이동 방해 = `collide`가 있다 · 상호작용 = `interact` 귀띔 · 광원 = `light` · 애니메이션 = 여러 프레임.

## A. 공용 기본 · 지형

### 바닥 (`floor`) — 57종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 암반 | `ground_rock` | b · a · dark | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 대현자의 기념비, 지하 1층 입구 외 13 | 높음 |
| 석재 바닥 | `floor_flag` | a · b | 타일 | 공용 | 넓은 타일 그림 | 천공의 탑, 심연, 기록의 바다 외 6 | 높음 |
| 풀밭 | `ground_grass` | b · a · dry | 타일 | 공용 | 넓은 타일 그림 | 고블린 숲, 강철바위 언덕, 가시갈대 밭 외 5 | 높음 |
| 얕은 물 | `ground_water` | clear · black · red · silver · sea | 타일 · 위험 바닥 · 애니메이션 | 공용 | 넓은 타일 그림 | 강철바위 언덕, 칠흑의 강어귀, 대해 외 4 | 높음 |
| 검게 탄 땅 | `ground_ash` | a · b · ember | 타일 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 패자의 안식처, 별무덤 외 3 | 높음 |
| 흙바닥 | `floor_dirt` | a · b | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 짐승의 소굴, 가시갈대 밭 외 2 | 높음 |
| 모래 바닥 | `floor_sand` | a | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 아르타 섬 외 2 | 높음 |
| 갈라진 마른 땅 | `ground_hardpan` | b · a | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 회색 벌판 외 2 | 높음 |
| 오래된 석재 바닥 | `floor_old` | a · b | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 천공의 탑, 판텔리온 유적지 외 1 | 높음 |
| 숲 바닥 | `ground_forest` | a · b | 타일 | 공용 | 넓은 타일 그림 | 고블린 숲, 마녀의 숲, 아노스섬 외 1 | 높음 |
| 얼음 바닥 | `ground_ice` | a · b · clear | 타일 | 공용 | 넓은 타일 그림 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 용암 | `ground_lava` | flow · poison | 타일 · 위험 바닥 · 애니메이션 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 태고의 땅, 적룡의 심처 외 1 | 높음 |
| 눈밭 | `ground_snow` | a · b · thin | 타일 | 공용 | 넓은 타일 그림 | 마녀의 오두막, 서리 협곡, 아이스록 외 1 | 높음 |
| 물가 · 용암가 테 | `shore_rim` | water_e · water_ne · water_s · water_w · water_n · water_se · water_sw … (24) | 바닥 장식 | 공용 | 코드 생성 | 지옥불 협곡, 대해, 아리베오나 강어귀 외 1 | 높음 |
| 들꽃 핀 잔디밭 | `ground_meadow` | b · a | 타일 | 공용 | 넓은 타일 그림 | 마녀의 오두막, 피오네섬, 여명의 땅 | 중간 |
| 검은 진흙 | `ground_mud` | b · a | 타일 | 공용 | 넓은 타일 그림 | 망자의 땅, 칠흑의 강어귀, 녹빛꼬리 습지 | 중간 |
| 깨진 바닥 | `floor_broken` | a | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 판텔리온 유적지 | 중간 |
| 물이 고인 바닥 | `floor_wet` | a | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬, 아틀란테 | 중간 |
| 습지 | `ground_swamp` | a · b | 타일 | 공용 | 넓은 타일 그림 | 칠흑의 강어귀, 녹빛꼬리 습지 | 중간 |
| 덤불 우거진 숲 바닥 | `ground_thicket` | a | 타일 | 공용 | 넓은 타일 그림 | 아노스섬, 대수림 | 중간 |
| 벽돌 바닥 | `floor_brick` | b · a | 타일 | 공용 | 넓은 타일 그림 | 영혼의 요새 | 낮음 |
| 불규칙한 돌바닥 | `floor_cobble` | b · a | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬 | 낮음 |
| 금이 간 바닥 | `floor_cracked` | a | 타일 | 공용 | 넓은 타일 그림 | 심연 | 낮음 |
| 이끼가 낀 바닥 | `floor_mossy` | a | 타일 | 공용 | 넓은 타일 그림 | 조각 사원 | 낮음 |
| 의식용 문양 바닥 | `floor_ritual` | a | 타일 | 공용 | 넓은 타일 그림 | 라르카즈의 미로 | 낮음 |
| 흰 모래사장 | `ground_beach` | a · b · wet | 타일 | 공용 | 넓은 타일 그림 | 대해 | 낮음 |
| 뼈가 깔린 땅 | `ground_bones` | a · b | 타일 | 공용 | 넓은 타일 그림 | 용의 심처 | 낮음 |
| 붉은 땅 | `ground_redsoil` | a · b | 타일 | 공용 | 넓은 타일 그림 | 태고의 땅 | 낮음 |
| 피가 묻은 바닥 | `floor_bloody` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 마법에 오염된 바닥 | `floor_corrupt` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 얼룩진 바닥 | `floor_stained` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 검게 탄 땅 번짐 띠 | `fringe_ash` | n_b · e_b · e_a · n_a · w_a · w_b · se … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 흰 모래사장 번짐 띠 | `fringe_beach` | n_a · e_b · e_a · s_a · n_b · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 뼈가 깔린 땅 번짐 띠 | `fringe_bones` | e_a · n_a · n_b · e_b · s_b · s_a · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 흙바닥 번짐 띠 | `fringe_dirt` | n_a · n_b · e_a · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 숲 바닥 번짐 띠 | `fringe_forest` | n_a · n_b · e_a · s_a · e_b · w_a · s_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 풀밭 번짐 띠 | `fringe_grass` | e_a · e_b · s_a · n_b · s_b · n_a · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 갈라진 마른 땅 번짐 띠 | `fringe_hardpan` | n_b · n_a · e_a · e_b · s_a · w_b · ne … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 얼음 바닥 번짐 띠 | `fringe_ice` | n_a · e_a · e_b · s_b · w_a · s_a · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 들꽃 핀 잔디밭 번짐 띠 | `fringe_meadow` | n_a · n_b · e_a · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 진흙 번짐 띠 | `fringe_mud` | n_a · n_b · e_a · e_b · s_b · w_a · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 붉은 땅 번짐 띠 | `fringe_redsoil` | n_a · n_b · e_a · e_b · s_a · w_a · ne … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 암반 번짐 띠 | `fringe_rock` | n_a · e_a · n_b · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 모래 바닥 번짐 띠 | `fringe_sand` | n_a · n_b · s_a · e_b · s_b · ne · e_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 눈밭 번짐 띠 | `fringe_snow` | n_a · e_a · n_b · e_b · w_a · s_b · ne … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 습지 번짐 띠 | `fringe_swamp` | n_a · e_a · s_a · e_b · n_b · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 덤불 우거진 숲 바닥 번짐 띠 | `fringe_thicket` | n_b · n_a · e_a · e_b · s_a · w_a · s_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 무늬 타일 바닥 | `room_tile` | checker · inlay | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 목재 마루 | `room_wood` | a · b | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 낡은 마루 | `room_wood_old` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 자갈길 | `street_gravel` | a · b | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 풀이 자란 돌바닥 | `street_overgrown` | a · b | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 광장 판석 | `street_plaza` | b · a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 바큇자국 난 흙길 | `street_rutted` | h · v · h_b | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 큰길 포석 | `street_setts` | b · a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 판석 보도 | `street_sidewalk` | a · b | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 낡고 꺼진 포석 | `street_worn_setts` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |

### 벽 · 절벽 (`wall`) — 27종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 동굴 암벽 | `wall_cave` | clean · mossy · damaged · cracked | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 대현자의 기념비, 지하 1층 입구 외 21 | 높음 |
| 검은 현무암 절벽 | `wall_basalt` | clean · cracked · damaged · mossy | 타일 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 원귀의 협곡, 패자의 안식처 외 5 | 높음 |
| 석벽 | `wall_stone` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 망자의 땅, 천공의 탑, 심연 외 4 | 높음 |
| 낭떠러지 벽 | `cliff_drop` | cave · ice · stone · sandstone · basalt | 바닥 장식 | 공용 | 코드 생성 | 대마경, 지옥불 협곡, 원귀의 협곡 외 3 | 높음 |
| 사암 절벽 | `wall_sandstone` | clean · mossy · cracked · damaged | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 대해 외 2 | 높음 |
| 문양 새긴 석문 | `sealed_door` | plain · fate · courage · wisdom · patience · lit · open | 이동 방해 · 상호작용(door) · 광원 · 애니메이션 | 공용 | 코드 생성 · 조합형 | 천공의 탑, 심연, 기록의 바다 외 1 | 높음 |
| 고대 유적 벽 | `wall_ancient` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 판텔리온 유적지, 기록의 바다 외 1 | 높음 |
| 얼음벽 | `wall_ice` | cracked · clean · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 낭떠러지 턱 | `cliff_lip` | n_a · e_a · n_b · w_a · e_b · nw · w_b … (8) | 바닥 장식 | 공용 | 코드 생성 | 대마경, 지옥불 협곡, 얼음 동굴 | 중간 |
| 문틀과 문 | `doorway` | open · wood · wood_ajar · wood_broken · iron · portcullis · iron_ajar … (9) | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 핏빛성채, 백색신전, 라르카즈의 미로 | 중간 |
| 무너진 벽 | `wall_ruin` | left · right · heap · low · gap | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 조각 사원 | 중간 |
| 감옥 철창 | `bars` | panel · bent · door_open · rusty · door · post | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 도플갱어 숲 | 낮음 |
| 금 간 벽 | `cracked_wall` | loose · broken · cracked · cracked_b | 상호작용(breakable) | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 아치형 통로 | `gateway` | open · doors_open · barred · collapsed · doors | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 핏빛성채 | 낮음 |
| 수로 배수구 | `sewer_outlet` | dry · flow · grate · grate_flow | 애니메이션 | 공용 | 코드 생성 | 낙원의 섬 | 낮음 |
| 무너져 뚫린 벽 | `wall_breach` | a · b | 벽 장식 | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 벽돌벽 | `wall_brick` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 영혼의 요새 | 낮음 |
| 문양 새긴 금속 벽 | `wall_metal` | clean · mossy · cracked · damaged | 타일 | 공용 | 넓은 타일 그림 | 강철의 묘 | 낮음 |
| 지하수로 벽 | `wall_sewer` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬 | 낮음 |
| 벽 끝(모서리돌) | `wall_end` | r · l | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽의 구멍 | `wall_hole` | b · a · c · high | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 장식 판벽 | `wall_panel` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 벽기둥(버팀기둥) | `wall_pilaster` | plain · broken | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 회벽 | `wall_plaster` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 안쪽 모서리 그늘 | `wall_shadow` | l · r | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 윗면(자동 연결 16가지) | `wall_top` | a · sandstone · cave · b · ice · basalt · metal | 타일 | 공용 | 넓은 타일 그림 · 조합형 | — | 낮음 |
| 목재 벽 | `wall_wood` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |

### 지형 (`terrain`) — 18종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 현무암 바위 | `rock_basalt` | columns_a · columns_low · columns_b · scorched · molten · spire | 이동 방해 · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 지옥불 협곡, 태고의 땅, 적룡의 심처 외 1 | 높음 |
| 얼음 덩이 | `rock_ice` | shards_a · shards_b · block · snowcap · pillar · block_cracked · pillar_broken … (8) | 이동 방해 | 지역 확장형 ← `rock` | 코드 생성 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 사암 바위 | `rock_sandstone` | strata_a · hoodoo_b · hoodoo · arch · stack · strata_b · buried | 이동 방해 | 지역 확장형 ← `rock` | 코드 생성 | 바위사막, 황혼의 비탈길, 대해 외 1 | 높음 |
| 눈 더미 | `snow_drift` | a · b · long · c | 장식 | 공용 | 코드 생성 | 마녀의 오두막, 서리 협곡, 아이스록 외 1 | 높음 |
| 고드름 | `icicles` | a · b · sparse | 머리 위 전경 | 지역 확장형 ← `stalactite` | 코드 생성 | 서리 협곡, 얼음 동굴, 빙하굴 | 중간 |
| 높낮이 단 | `ledge` | rock · rock_b · grass_b · sand_b · sand · grass · ice … (15) | 이동 방해 | 공용 | 코드 생성 · 조합형 | 강철바위 언덕, 여명의 땅, 빙하굴 | 중간 |
| 비탈길 | `ramp` | rock · grass · sand · ash · ice | 이동 방해 | 공용 | 코드 생성 | 강철바위 언덕, 여명의 땅, 빙하굴 | 중간 |
| 로프 건널목 | `rope_crossing` | anchor · taut_e · taut_w · cut · coiled | 상호작용(rope) | 공용 | 코드 생성 | 대마경, 얼음 동굴, 빙하굴 | 중간 |
| 거대한 뼈 | `giant_bone` | rib_arch · vertebra · rib_single · spine · femur · shards · skull | 장식 | 지역 전용 | 코드 생성 | 용의 심처, 태고의 땅 | 중간 |
| 운석 구덩이 | `crater` | cold · fresh · small | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 천장 수정 | `crystal_ceiling` | a · b | 광원 | 지역 전용 | 코드 생성 | 수정동굴 | 낮음 |
| 벽에 붙은 수정 | `crystal_wall` | a · c · dim · b · cluster | 광원 | 지역 전용 | 코드 생성 | 수정동굴 | 낮음 |
| 운석 | `meteorite` | cold · glowing · shards | 이동 방해 · 광원 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 굳은 둔덕 | `mound` | a · b · long · ruin | 이동 방해 | 지역 전용 | 코드 생성 | 망자의 땅 | 낮음 |
| 광맥 바위 | `ore_vein` | green_b · mined · green · iron | 이동 방해 · 상호작용(breakable) · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 녹색 탄광 | 낮음 |
| 땅에 박힌 낡은 검 | `planted_sword` | a · b · broken · c · cluster_b · cluster | 장식 | 지역 전용 | 코드 생성 | 패자의 안식처 | 낮음 |
| 암초 | `reef` | a · b · large · red · red_large | 이동 방해 | 지역 전용 | 코드 생성 | 대해 | 낮음 |
| 수정 박힌 바위 | `rock_crystal` | large · b · a · dim | 이동 방해 · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 수정동굴 | 낮음 |

### 자연물 (`nature`) — 18종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 돌무더기 | `rubble` | small · small_b · large_b · scatter · brick · brick_large · large | 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 망자의 땅 외 8 | 높음 |
| 바위 | `rock` | small_b · small_a · medium_b · large_b · medium_a · large_a · slab_b … (9) | 장식 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비, 짐승의 소굴 외 5 | 높음 |
| 바닥 균열 | `ground_crack` | b · a · c · wide | 바닥 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 대마경 외 3 | 높음 |
| 바닥을 기는 뿌리 | `roots` | a · b · knot · c | 장식 | 공용 | 코드 생성 | 짐승의 소굴, 칠흑의 강어귀, 마녀의 숲 외 3 | 높음 |
| 웅덩이 | `puddle` | small · medium · murky · ripple · bloody · large | 애니메이션 | 공용 | 코드 생성 | 수정동굴, 망자의 땅, 칠흑의 강어귀 외 2 | 높음 |
| 덩굴 | `vines` | hang_short · hang_mid · hang_long · ivy_a · ivy_b · dead | 벽 장식 | 공용 | 코드 생성 | 마녀의 숲, 아노스섬, 대수림 외 1 | 높음 |
| 이끼 낀 큰 바위 | `boulder_mossy` | a · b | 이동 방해 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 강철바위 언덕 | 중간 |
| 돌기둥(종유석과 석순이 이어진) | `column_natural` | a · b | 이동 방해 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비 | 중간 |
| 자갈 | `gravel` | b · a · c · sparse | 바닥 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴 | 중간 |
| 종유석 | `stalactite` | small · cluster_b · large · cluster · dripping | 머리 위 전경 | 공용 | 코드 생성 | 수정동굴, 낙원의 섬 | 중간 |
| 석순 | `stalagmite` | small · tall · cluster · cluster_b · broken | 장식 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비 | 중간 |
| 이끼 | `moss_patch` | a · b · c · dry · d | 바닥 장식 | 공용 | 코드 생성 | 수정동굴 | 낮음 |
| 버섯 | `mushroom` | cluster_a · big · cluster_c · pale · cluster_b | 장식 | 공용 | 코드 생성 | 수정동굴 | 낮음 |
| 벽에 난 선반버섯 | `mushroom_shelf` | a · b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 독버섯 | `toadstool` | red_a · red_b · glow_b · glow_violet · glow_a | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽 이끼 | `wall_moss` | base_a · base_b · top_b · patch · top_a | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽을 뚫고 나온 뿌리 | `wall_roots` | b · c · a | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 잡초 | `weeds` | tuft_a · dead_bush · tuft_dry · fern · sprouts · bramble · tuft_b | 장식 | 공용 | 코드 생성 | — | 낮음 |

## B. 식생

### 식생 (`flora`) — 12종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 덤불 | `bush` | a · b · wide · flowering · snowy · dry | 장식 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 아노스섬 외 5 | 높음 |
| 키 큰 풀 | `grass_tall` | a · b · c · dry · wide | 장식 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 녹빛꼬리 습지 외 4 | 높음 |
| 활엽수 | `tree_broadleaf` | b · young · a · c · autumn · fruit · bare | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 마녀의 오두막 외 4 | 높음 |
| 쓰러진 통나무 | `log` | mossy · a · hollow · burnt | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 녹빛꼬리 습지, 아노스섬 외 1 | 높음 |
| 부들 | `cattail` | a · b · c | 장식 | 공용 | 코드 생성 | 칠흑의 강어귀, 녹빛꼬리 습지, 아리베오나 강어귀 | 중간 |
| 들꽃 무더기 | `flowers` | white · violet · yellow · mixed_a · mixed_b · red | 장식 | 공용 | 코드 생성 | 마녀의 오두막, 피오네섬, 여명의 땅 | 중간 |
| 그루터기 | `stump` | axe · burnt · mossy · a | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 불의 거울 | 중간 |
| 검은 불에 타는 나무 | `tree_burning` | black_flame · black_flame_b · charred | 이동 방해 · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 불의 거울, 종말의 기억 | 중간 |
| 밀림의 거목 | `tree_giant` | a · b · hollow | 이동 방해 · 상호작용(entrance) | 지역 확장형 ← `tree_broadleaf` | 코드 생성 | 아노스섬, 대수림 | 중간 |
| 침엽수 | `tree_pine` | young · b · dead · a · snowy | 이동 방해 | 공용 | 코드 생성 | 강철바위 언덕, 아이스록 | 중간 |
| 매마른 가시나무 | `tree_thorn` | b · c · a · vined · vined_b · leafy · stir … (8) | 이동 방해 · 광원 · 애니메이션 | 지역 확장형 ← `tree_broadleaf` | 코드 생성 | 마녀의 숲, 마녀의 오두막 | 중간 |
| 가시갈대 | `reed_thorn` | a · b · c · dense · sparse · trampled | 시야 덮개 | 지역 전용 | 코드 생성 | 가시갈대 밭 | 낮음 |

## C. 건축 · 구조물

### 구조물 (`structure`) — 30종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 폐허 담 | `ruin_wall` | window · low · straight_b · straight_a · doorway · corner · mossy … (9) | 이동 방해 | 공용 | 코드 생성 · 조합형 | 망자의 땅, 바위사막, 조각 사원 외 2 | 높음 |
| 기둥 | `pillar` | intact · cracked · mossy · broken · stump · fallen | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 바위사막, 조각 사원 외 1 | 높음 |
| 포탈 비석 | `portal_stele` | idle · active · active_dark · dead · giant · leaning | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 지하 1층 입구, 고블린 숲, 천공의 탑 외 1 | 높음 |
| 흰 대리석 기둥 | `pillar_white` | intact · cracked · glowing · broken · sunken | 이동 방해 · 광원 · 애니메이션 | 지역 확장형 ← `pillar` | 코드 생성 | 기록의 바다, 백색신전, 아틀란테 | 중간 |
| 석상 | `statue` | intact · mossy · headless · broken · ruined | 이동 방해 | 공용 | 코드 생성 | 조각 사원, 기록의 바다, 백색신전 | 중간 |
| 제단 | `altar` | plain · bloody · ritual · broken | 이동 방해 · 상호작용(altar) · 애니메이션 | 공용 | 코드 생성 | 아르타 섬, 도플갱어 숲 | 중간 |
| 아치 | `arch` | intact · mossy · ruined | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 조각 사원 | 중간 |
| 작은 배 | `boat` | oars · wreck · mast · beached | 이동 방해 · 상호작용(boat) | 지역 전용 | 코드 생성 | 대해, 원귀의 협곡 | 중간 |
| 다리 | `bridge` | wood_h · wood_v · wood_broken · wood_end · stone_h · stone_v · stone_broken … (8) | 바닥 장식 | 공용 | 코드 생성 · 조합형 | 대마경, 녹색 탄광 | 중간 |
| 철로 | `mine_track` | straight_h · straight_v · end · broken · curve | 바닥 장식 | 지역 전용 | 코드 생성 · 조합형 | 판텔리온 유적지, 녹색 탄광 | 중간 |
| 받침대 | `pedestal` | empty · orb_red · broken · idol · orb | 이동 방해 · 상호작용(pedestal) · 광원 | 공용 | 코드 생성 | 조각 사원, 영혼의 요새 | 중간 |
| 얼음 · 유리 계단 | `stairs_ice` | ice · ice_cracked · glass | 이동 방해 · 상호작용(stairs) | 지역 확장형 ← `stairs_up` | 코드 생성 | 빙하굴, 영혼의 요새 | 중간 |
| 보석을 쥔 석상 | `statue_gem` | lit · dark · white · broken | 이동 방해 · 상호작용(statue) · 광원 · 애니메이션 | 지역 확장형 ← `statue_robed` | 코드 생성 | 기록의 바다, 백색신전 | 중간 |
| 천막 | `tent` | canvas · canvas_b · hide · collapsed | 이동 방해 | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 불탄 2층 벽돌집 | `burnt_house` | ruin · door_open | 이동 방해 · 상호작용(door) | 지역 전용 | 코드 생성 | 불의 거울 | 낮음 |
| 도개교 | `drawbridge` | down · down_bloody | 상호작용(bridge) | 지역 전용 | 코드 생성 | 핏빛성채 | 낮음 |
| 올린 도개교 | `drawbridge_raised` | up | 이동 방해 · 상호작용(bridge) | 지역 전용 | 코드 생성 | 핏빛성채 | 낮음 |
| 드론 잔해 | `drone_wreck` | a · b · sparking | 이동 방해 · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 광차 | `mine_cart` | ore · empty · rubble · tipped | 이동 방해 · 상호작용(container) | 지역 전용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 갱도 버팀목 | `mine_support` | intact · sagging · collapsed | 이동 방해 | 지역 전용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 기념비 | `monument` | plain · offered · worn | 이동 방해 · 상호작용(altar) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 대현자의 기념비 | 낮음 |
| 천장 레일 | `overhead_rail` | carriage · hook · broken · straight | 머리 위 전경 | 지역 전용 | 코드 생성 · 조합형 | 판텔리온 유적지 | 낮음 |
| 말뚝 울타리 | `palisade` | straight_b · broken · corner · straight_a · gate · spiked · gate_open | 이동 방해 | 공용 | 코드 생성 · 조합형 | 오크 군락지 | 낮음 |
| 계단식 사원 | `pyramid_temple` | intact · sunken · lit | 이동 방해 · 상호작용(entrance) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 아틀란테 | 낮음 |
| 석관 | `sarcophagus` | open · ajar · closed · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 내려가는 계단 | `stairs_down` | stone | 상호작용(stairs) | 공용 | 코드 생성 | 기록의 바다 | 낮음 |
| 올라가는 계단 | `stairs_up` | stone · worn | 이동 방해 · 상호작용(stairs) | 공용 | 코드 생성 | 천공의 탑 | 낮음 |
| 두건 쓴 석상 | `statue_robed` | intact · weeping | 이동 방해 | 공용 | 코드 생성 | 핏빛성채 | 낮음 |
| 사다리 | `ladder` | wall · broken · hatch | 상호작용(ladder) | 공용 | 코드 생성 | — | 낮음 |
| 난간 | `railing` | straight · post · side · broken | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |

## D. 장식 · 환경 흔적

### 가구 · 생활 (`furniture`) — 35종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 보물상자 | `chest` | closed · open · locked · broken · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 천공의 탑, 도플갱어 숲, 영혼의 요새 | 중간 |
| 깔개 | `carpet` | blue · red · green · round · worn · torn | 바닥 장식 | 공용 | 코드 생성 | 마녀의 오두막, 영혼의 요새 | 중간 |
| 보급품 더미 | `supply_pile` | a · b | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 배낭 | `backpack` | standing · opened | 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 나무통 | `barrel` | intact · broken · toppled · water · stack | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 침낭 | `bedroll` | rolled · used · out | 장식 | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 책장 | `bookshelf` | half · empty · full · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 천장까지 닿는 책장 | `bookshelf_tall` | full_b · full · half · empty · ladder | 이동 방해 · 상호작용(container) | 지역 확장형 ← `bookshelf` | 코드 생성 | 기록의 바다 | 낮음 |
| 불타 뼈대만 남은 가구 | `burnt_furniture` | table · shelf · bed · chair | 장식 | 공용 | 코드 생성 | 불의 거울 | 낮음 |
| 의자 | `chair` | s · e · w · n · toppled · broken | 이동 방해 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 나무 상자 | `crate` | intact · open · broken · stack | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 탁자 | `table` | intact · set · toppled · broken | 이동 방해 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 무기 거치대 | `weapon_rack` | full · half · broken · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 오크 군락지 | 낮음 |
| 모루 | `anvil` | base · hammer | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 갑옷 거치대 | `armor_stand` | armor · empty · fallen | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 바구니 | `basket` | empty · food · toppled | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 침대 | `bed` | made · messy · bare · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 긴 의자 | `bench` | base · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 책 | `books` | open · stack · scattered · tall | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 병 | `bottles` | group · potion_red · potion_blue · fallen · wine | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 캐비닛 | `cabinet` | open · closed · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 솥 | `cooking_pot` | cold · ground · stew | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 책상 | `desk` | intact · broken · cluttered | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 식기 | `dishes` | set · bowls · dirty | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 서랍장 | `dresser` | open · closed | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 음식 잔해 | `food_scraps` | a · b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 숫돌 바퀴 | `grindstone` | base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 흩어진 문서 | `papers` | b · a · stack | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 자루 | `sack` | slumped · full · open · pile | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 두루마리 | `scrolls` | pile · open · case | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 걸상 | `stool` | base · toppled | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 짚 더미 | `straw_pile` | b · a | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 연장통 | `toolbox` | full · empty | 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 벽 선반 | `wall_shelf` | bottles · empty · skull · books | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 작업대 | `workbench` | tools · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |

### 환경 흔적 (`trace`) — 48종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 해골 | `skull` | single · cracked · pair · side · heap · pike | 장식 | 공용 | 코드 생성 | 망자의 땅, 오크 군락지, 용의 심처 외 1 | 높음 |
| 뼈 | `bones` | scatter_a · scatter_b · pile · crossed · ribcage · spine | 장식 | 공용 | 코드 생성 | 짐승의 소굴, 망자의 땅, 용의 심처 | 중간 |
| 나무 잔해 | `debris_wood` | planks · splinters · furniture | 장식 | 공용 | 코드 생성 | 칠흑의 강어귀, 녹색 탄광 | 중간 |
| 그을음 | `scorch` | a · b · blast | 바닥 장식 | 공용 | 코드 생성 | 지옥불 협곡, 불의 거울 | 중간 |
| 부서진 무기 | `broken_weapon` | sword · spear · mace · helmet · arrows · pile · axe … (8) | 장식 | 공용 | 코드 생성 | 패자의 안식처 | 낮음 |
| 뼈와 넝마 둥지 | `nest` | base · eggs | 장식 | 공용 | 코드 생성 | 짐승의 소굴 | 낮음 |
| 긁힌 자국 | `scratches` | b · a · c · deep | 바닥 장식 | 공용 | 코드 생성 | 대해 | 낮음 |
| 벽에 새긴 글 | `wall_writing` | a · b · worn · c | 벽 장식 | 공용 | 코드 생성 | 지하 1층 입구 | 낮음 |
| 방치된 물건 | `abandoned_things` | boot · bundle · bucket · coins · satchel | 상호작용(search) | 공용 | 코드 생성 | — | 낮음 |
| 잿더미 | `ash_pile` | campfire · ash · pyre | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 점액 | `black_slime` | a · b · c · trail | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 피 웅덩이 | `blood_pool` | fresh · fresh_b · dried · dried_b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 핏자국 | `blood_splat` | b · d · a · c · drops | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 끌린 핏자국 | `blood_trail` | curved · hand · straight · vertical | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽에 튄 피 | `blood_wall` | a · b · hand · smear · c | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 깨진 병 | `bottle_broken` | brown · red · green | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 유리 조각 | `bottle_shards` | green · brown · clear | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 부서진 갑옷 | `broken_armor` | breastplate · mail · pieces | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 거미줄 | `cobweb` | corner_l · torn · floor · corner_r · span | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 무너진 선반 | `collapsed_shelf` | goods · books · bare | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 무너진 목재 구조물 | `collapsed_timber` | rafters · scaffold | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 시체 | `corpse` | shrouded · explorer · rotten · explorer_b | 상호작용(search) | 공용 | 코드 생성 | — | 낮음 |
| 끌린 자국 | `drag_marks` | curved · b · a | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 먼지 | `dust` | a · b · c · drift | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 무너진 천장 회반죽 | `fallen_plaster` | lath · heap | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 바닥 파편 | `floor_debris` | plaster · tile · slate | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 발자국 | `footprints` | bloody · dust · wet · bloody_fade | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 매달린 쇠우리 | `gibbet` | skeleton · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 손자국 | `handprints` | mud · dust · soot | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 흙 얼룩 | `mud_stain` | a · b · smear · wet | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 낡은 문 | `old_door` | fallen · boarded · leaning | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 의식 표식 | `ritual_marks` | sigil_a · chalk_circle · salt_line · sigil_b · salt_ring | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 의식의 흔적 | `ritual_remains` | bone_circle · candle_ring · offering | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 썩은 자국 | `rot_stain` | a · c · b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 유골 | `skeleton` | lying · sitting · armored · chained | 상호작용(search) | 공용 | 코드 생성 | — | 낮음 |
| 쇠고랑에 매달린 유골 | `skeleton_chained` | base | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 점액 덩이 | `slime_blob` | a · b | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 쏟은 자국 | `spill_stain` | wine · ale · oil · wine_dried | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 쓰레기 더미 | `trash_heap` | small · large · rotten | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 낙서 | `wall_graffiti` | chalk_c · chalk_a · chalk_b · chalk_d · blood_a · blood_c · blood_b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 손자국 | `wall_handprints` | soot · smear · dust | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 긁힌 자국 | `wall_scratches` | claw_a · tally · tally_many · nails · claw_b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽을 타고 흐르는 점액 | `wall_slime` | a · b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 물자국 | `wall_stain` | a · b · c | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 물 얼룩 | `water_stain` | b · a · c | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 촛농 | `wax_drips` | a · pool · trail | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 거미줄 고치 | `web_cocoon` | hanging · cluster · standing | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 깨진 창유리 조각 | `window_shards` | a · frame · few | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |

### 조명 (`light`) — 18종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 모닥불 | `firepit` | lit · embers · cold | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 벽 횃불 | `torch_wall` | lit · stub · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | 천공의 탑, 라르카즈의 미로 | 중간 |
| 화로 | `brazier` | lit · embers · cold · toppled | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 오크 군락지 | 낮음 |
| 벽난로 | `fireplace` | lit · dying · cold | 이동 방해 · 상호작용(fire) · 광원 · 애니메이션 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 걸린 랜턴 | `lantern_hanging` | lit · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 마법 등 | `magic_lamp` | blue · red · violet · dead | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 세 갈래 촛대 | `candelabra` | lit · unlit | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 양초 무더기 | `candles` | lit · unlit · stubs | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 촛대 | `candlestick` | lit · unlit | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 샹들리에 | `chandelier` | lit · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 떨어진 샹들리에 | `chandelier_fallen` | base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 빛나는 균열 | `glow_crack` | blue · red · dead · blue_b · dead_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 빛나는 룬 | `glow_rune` | a_off · b_off · c_off · a_blue · d_off · b_blue · c_blue … (10) | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 랜턴 | `lantern` | lit · unlit · broken | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 신비로운 빛기둥 | `light_shaft` | warm · pale · blue · narrow | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 작은 마력 구체 | `mana_orb` | blue · violet · red · gold | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 바닥 횃불 | `torch_stand` | lit · unlit · fallen | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽 룬 글줄 | `wall_rune` | off · blue · red · blue_b · off_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

## E. 상호작용 · 기믹

### 특수 · 기믹 (`special`) — 36종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 포털 | `portal` | dormant · violet · blue · shattered | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 대현자의 기념비, 천공의 탑, 아르타 섬 외 6 | 높음 |
| 수정 | `crystal` | blue_small · blue_large · violet_small · red_large · violet_large · red_small · dead … (8) | 이동 방해 · 광원 | 공용 | 코드 생성 | 수정동굴, 영혼의 요새, 낙원의 섬 | 중간 |
| 거울 | `great_mirror` | dormant · active · broken | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 대마경, 불의 거울 | 중간 |
| 마법진 | `magic_circle` | a_chalk · a_blood · a_blue · a_red · b_blue · b_blood · b_chalk … (12) | 상호작용(circle) · 광원 · 애니메이션 | 공용 | 코드 생성 | 핏빛성채, 라르카즈의 미로 | 중간 |
| 고대 기계 장치 | `ancient_machine` | dormant · active · wrecked | 이동 방해 · 상호작용(machine) · 광원 · 애니메이션 | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 톱니바퀴 더미 | `gear_pile` | a · b | 장식 | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 압력판 | `pressure_plate` | up · pressed · rune · rune_pressed | 상호작용(plate) · 애니메이션 | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 차원 균열 | `rift` | active · dormant · active_b | 상호작용(rift) · 광원 · 애니메이션 | 공용 | 코드 생성 | 차원 붕괴 | 낮음 |
| 봉인 장치 | `seal_device` | sealed · weakened · broken | 이동 방해 · 상호작용(seal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 도플갱어 숲 | 낮음 |
| 석판 | `stone_tablet` | intact · glowing · mossy · broken | 이동 방해 · 상호작용(read) · 광원 · 애니메이션 | 공용 | 코드 생성 | 기록의 바다 | 낮음 |
| 밸브 바퀴 | `valve_wheel` | turned · idle · rusted | 상호작용(valve) | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 사슬 자물쇠 | `chained_lock` | locked · broken | 상호작용(lock) | 공용 | 코드 생성 | — | 낮음 |
| 마법진 파편 | `circle_fragments` | dead_a · dead_b · faint_blue · faint_violet | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 문 봉인 | `door_seal` | sealed · broken | 상호작용(seal) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 수상한 자리 | `examine_spot` | odd_slab · loose_brick · pinned_note · curio | 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 바닥 버튼 | `floor_button` | idle · pressed · glow | 상호작용(button) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 손을 얹는 비석 | `hand_stele` | idle · glowing · spent · broken | 이동 방해 · 상호작용(touch) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 열쇠 구멍 판 | `keyhole_plate` | plain · ornate · glow · key | 상호작용(keyhole) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 레버 | `lever` | left · right · broken | 이동 방해 · 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 잠금 받침대 | `lock_pedestal` | locked · unlocked · empty · keyhole | 이동 방해 · 상호작용(lock) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 잠긴 문 | `locked_door` | wood_chained · wood_unlocked · iron_barred · open · iron_unbarred | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 | — | 낮음 |
| 마법 에너지 | `magic_energy` | arc_blue · arc_violet · arc_red · wisp_blue · wisp_violet · wisp_gold | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 마력 잔류물 | `mana_residue` | blue · violet · green · blue_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 당기는 사슬 | `pull_chain` | up · pulled | 상호작용(secret) | 공용 | 코드 생성 | — | 낮음 |
| 룬 고리 | `rune_ring` | off_b · off · blue · violet · gold | 상호작용(circle) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 룬석 | `rune_stone` | dormant · blue · red · dormant_b · blue_b · dormant_c · violet_c | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 기울이는 횃대 | `sconce_switch` | upright · tilted | 상호작용(secret) | 공용 | 코드 생성 | — | 낮음 |
| 봉인 장막 | `seal_barrier` | blue · gold · violet · breaking | 이동 방해 · 상호작용(seal) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 봉인된 길목(빛의 벽) | `seal_wall` | blue · gold · red · breaking | 이동 방해 · 상호작용(seal) · 광원 · 애니메이션 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 숨은 벽 문 | `secret_panel` | closed · ajar · open | 상호작용(secret) | 공용 | 코드 생성 | — | 낮음 |
| 보물 궤짝 | `treasure_coffer` | closed · open · empty | 이동 방해 · 상호작용(container) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽 버튼 | `wall_button` | idle · pressed · glow | 상호작용(button) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽 레버 | `wall_lever` | up · down | 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 벽 스위치 | `wall_switch` | knife_off · knife_on · rune_on · rune_off | 상호작용(switch) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽 석판 | `wall_tablet` | c · b · a | 상호작용(read) | 공용 | 코드 생성 | — | 낮음 |
| 감는 틀 | `winch` | idle · turned · turned2 | 이동 방해 · 상호작용(winch) | 공용 | 코드 생성 | — | 낮음 |

### 함정 (`trap`) — 25종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 구덩이 함정 | `pit_trap` | covered · open · bloody · empty | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲, 도플갱어 숲 | 중간 |
| 회전 칼날 | `blade_trap` | spin · bloody · still · jammed | 이동 방해 · 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 화살 구멍 | `dart_holes` | idle · fired | 상호작용(trap) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 즉사 함정 타일 | `death_tile` | hidden · revealed · hidden_b · armed · sprung | 상호작용(trap) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 심연 | 낮음 |
| 화염 분사 | `flame_jet` | firing · low | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | 적룡의 심처 | 낮음 |
| 화약통 | `powder_keg` | hidden · intact · lit · cluster · exploded | 이동 방해 · 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 벽 창 함정 | `spear_wall` | bloody · out · idle | 상호작용(trap) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 가시 함정(솟음) | `spike_trap` | half · extended · bloody · rusted | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲 | 낮음 |
| 인계철선 | `tripwire` | set · side · tripped | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲 | 낮음 |
| 칼날 홈 | `blade_slot` | idle · bloody | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 떨어진 낙하석 | `ceiling_block` | fallen · bloody · dust | 이동 방해 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 매달린 낙하석 | `ceiling_chain` | hang · falling | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 낙하 함정 자리 | `ceiling_warn` | a · b | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 무너지는 바닥 | `collapse_floor` | half · sagging · cracked · pit | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 쏘고 남은 화살 | `darts_spent` | b · a · bloody | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 화염 분사구 | `flame_nozzle` | idle · scorched · pilot | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 독가스 분출구 | `gas_grate` | stained · idle | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 독가스 분출 | `gas_vent` | venting · thin | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽 독가스 구멍 | `gas_vent_wall` | venting · idle | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 진자 도끼 | `pendulum` | swing · still · bloody | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 룬 함정 | `rune_trap` | faint · armed · spent | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 그을린 자국 | `scorch_mark` | b · streak · a | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 가시 함정(숨음) | `spike_plate` | idle · bloody | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 함정의 흔적 | `trap_remains` | rusty_spikes · skeleton_spikes · snapped_blade · sprung_spears | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 화염 분사구 | `wall_flame` | idle · firing · scorched | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

## F. 환경 연출

### 환경 연출 (`fx`) — 20종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 흩날리는 입자 | `drift` | snow · ember · ash · dust · frost | 애니메이션 | 공용 | 코드 생성 | 바위사막, 마녀의 오두막, 지옥불 협곡 외 6 | 높음 |
| 안개 | `mist` | grey · black · violet · blue · grey_b · black_b | 애니메이션 | 공용 | 코드 생성 | 마녀의 오두막, 원귀의 협곡, 패자의 안식처 외 1 | 높음 |
| 떠다니는 부산물 | `flotsam` | planks · barrel · mixed | 애니메이션 | 공용 | 코드 생성 | 대해, 기록의 바다 | 중간 |
| 폭포 | `waterfall` | clear · red · black · clear_wide | 애니메이션 | 공용 | 코드 생성 | 아리베오나 강어귀, 빙하굴 | 중간 |
| 퍼지는 공간 균열(차원 붕괴) | `collapse_crack` | seed · spread · web · web_b | 광원 · 애니메이션 | 공용 | 코드 생성 | 차원 붕괴 | 낮음 |
| 까마귀 떼 | `crows` | flock · flock_b · few | 애니메이션 | 지역 전용 | 코드 생성 | 핏빛성채 | 낮음 |
| 은빛 구체 | `light_orb` | rise · rise_b · cluster | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 강철바위 언덕 | 낮음 |
| 벼락 줄기 | `lightning` | strike · strike_b | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 붉은 빛(낙하 예고) | `red_beam` | pulse | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 촛불 불꽃 | `candle_flame` | steady · guttering | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 먼지 구름 | `dust_puff` | impact · step · crumble | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 불꽃(낱 효과) | `flame` | small · medium · large · wide · blue | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 일렁이는 불빛(바닥) | `light_flicker` | fire · candle · cold · forge | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 빛 알갱이 | `light_motes` | warm · firefly · spore | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 연기 | `smoke` | wisp · column · black · chimney | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 횃불 불꽃 | `torch_flame` | steady · windblown · dying | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 떨어지는 물방울 | `water_drip` | fall · splash · trickle | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 물 반짝임 | `water_glint` | day · day_b · moon · torch | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 잔물결 고리 | `water_ripple` | single · double · rain | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 창으로 든 빛(바닥) | `window_light` | day · moon · arched · dusty | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

## G. 도시 · 건물 실내(AM69 — 자세한 표는 CITY_LIBRARY.md)

### 도시 외부 (`city`) — 68종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 발코니 | `balcony` | wood · wood_plants · stone · wood_broken | 벽 장식 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 세로 현수막 | `banner_hanging` | chevron · border · plain · torn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 돌말뚝 | `bollard` | stone · chained · iron · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 줄 깃발 | `bunting` | sparse · tattered · festive | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 짐수레 | `cart` | sacks · empty · barrels · hay · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 수레바퀴 자국 | `cart_ruts` | h · v · curve | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 닭장 | `chicken_coop` | closed · open · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 굴뚝 | `chimney` | stone_smoke · brick · stone · brick_smoke · broken | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 성문 | `city_gate` | open · open_banner · shut · portcullis | 이동 방해 · 상호작용(gate) | 공용 | 코드 생성 | — | 낮음 |
| 성벽 | `city_wall` | straight · torch · damaged · drain | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 성벽 탑 | `city_wall_tower` | intact · lit · damaged | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 빨랫줄 | `clothesline` | laundry · sheets · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 골목 위 빨랫줄 | `clothesline_hanging` | laundry · sparse | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 연석 | `curb` | h · v · corner_ne · corner_nw · corner_se · corner_sw · end … (9) | 바닥 장식 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 길바닥 배수구 | `drain_grate` | grate · clogged · open | 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 낙엽 | `fallen_leaves` | autumn · wet · pile · scatter | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 깃대 | `flag_pole` | stripes · quartered · chevron · tattered · bare | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 창가 꽃상자 | `flower_box` | herb · flowers · dead · empty | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 분수 | `fountain` | running · broken · dry | 이동 방해 · 상호작용(examine) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 배수로 | `gutter` | v · h · corner_ne · corner_nw · corner_se · corner_sw · end … (9) | 애니메이션 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 손수레 | `handcart` | empty · tipped · loaded | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 건초 더미 | `hay_bale` | stack · bale · loose · fork | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 다듬은 생울타리 | `hedge` | end · corner · overgrown · gap · straight | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 말 매는 말뚝 | `hitching_post` | rail · post · rail_rope · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 물구유 | `horse_trough` | stone · wood_dry · wood | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 층 사이 띠(돌림띠 · 내민 들보) | `house_band` | stone · timber · stone_dentil | 벽 장식 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 집 벽 모서리 | `house_corner` | stone · timber · plaster · stone_worn | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 집 나무 문 | `house_door` | plain · plain_ajar · reinforced · reinforced_ajar · double_ajar · double | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 | — | 낮음 |
| 집 쇠 문 | `house_iron_door` | rusted · ajar · closed | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 | — | 낮음 |
| 집 벽 끝 | `house_wall_end` | timber_r · stone_l · stone_r · plaster_l · plaster_r · timber_l | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 회벽 집 벽 | `house_wall_plaster` | worn · plain_b · cracked · window · window_open · window_lit · plain … (8) | 이동 방해 · 광원 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 석조 집 벽 | `house_wall_stone` | plain · plain_b · cracked · window · worn · window_lit · door … (8) | 이동 방해 · 광원 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 목골 집 벽 | `house_wall_timber` | plain · plain_b · worn · window · cracked · window_open · window_lit … (8) | 이동 방해 · 광원 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 집 창문 | `house_window` | square_shut · square_open · square_lit · square_broken · square_boarded · arch · round … (10) | 상호작용(window) · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 안내판 | `info_board` | stone · wood · wall | 이동 방해 · 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 쇠 울타리 | `iron_fence` | straight · gate_open · post · gate_shut · bent | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 버려진 물건 더미 | `junk_pile` | large · small · alley | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 맨홀 | `manhole` | closed · open · ajar | 상호작용(hatch) | 공용 | 코드 생성 | — | 낮음 |
| 차양 천막 | `market_awning` | striped · torn · plain | 이동 방해 · 시야 덮개 | 공용 | 코드 생성 | — | 낮음 |
| 시장 좌판 | `market_stall` | produce · bread · pottery · fish · wrecked · cloth · empty | 이동 방해 · 상호작용(shop) | 공용 | 코드 생성 | — | 낮음 |
| 게시판 | `notice_board` | notices · empty · torn | 이동 방해 · 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 바깥 계단 | `outside_stairs` | wood · stoop · wood_l · stoop_worn | 이동 방해 · 상호작용(stairs) | 공용 | 코드 생성 | — | 낮음 |
| 화분 | `planter` | herb · flowers · shrub · dead · broken · empty · group | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 광장 기념 돌 | `plaza_monument` | obelisk_worn · obelisk · sundial | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 돌 아치 들머리 | `porch_arch` | open · worn · door | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 처마 기둥 | `porch_post` | wood · stone_worn · stone · wood_brace | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 청과 상자 | `produce_crate` | greens · apples · roots · stack | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 빗물 통 | `rain_barrel` | full · overflow · dry | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 길 꺼진 자리 | `road_patch` | sunken · sunken_b · dirt_b · dirt | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 앞으로 향한 박공 | `roof_gable_front` | plaster · timber · stone · timber_window | 머리 위 전경 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 돌 너와 지붕 | `roof_slate` | eave · eave_b · worn · damaged · end_l · end_r | 머리 위 전경 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 나무 너와 지붕 | `roof_wood` | eave_b · eave · damaged · end_l · end_r · worn | 머리 위 전경 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 돌출 간판 | `shop_sign` | inn · shop · smithy · bank · guild · library · blank … (8) | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 세움 간판 | `sign_aframe` | inn · shop · fallen · blank | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 갈림길 표지판 | `signpost` | two · three · one · leaning | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 흩어진 짚 | `straw_scatter` | a · dung · b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 가로등 | `street_lamp` | lit · unlit · bent | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 작은 경사로 | `street_ramp` | stone · plank · plank_broken | 상호작용(stairs) | 공용 | 코드 생성 | — | 낮음 |
| 돌계단 | `street_steps` | wide · narrow · worn · grand | 상호작용(stairs) | 공용 | 코드 생성 | — | 낮음 |
| 가로수 | `street_tree` | ring · trimmed · guard · bare | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 벽 차양 | `wall_awning` | striped · plain · torn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 깃발 | `wall_flag` | stripes · chevron · tattered | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 빨래 함지 | `washtub` | laundry · water · empty · board | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 나무 망루 | `watchtower` | lit · intact · ruined | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 물지게 | `water_yoke` | full · empty · set_down | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 우물 | `well` | roofed · plain · broken | 이동 방해 · 상호작용(well) | 공용 | 코드 생성 | — | 낮음 |
| 나무 울타리 | `wood_fence` | rail · corner · gate · picket · gate_open · broken | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 집 나무 난간 | `wood_railing` | straight · post · broken · corner | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |

### 공통 실내 (`interior`) — 26종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 안락의자 | `armchair` | s · e · w · worn · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 나무 난간 | `banister` | straight · post · broken | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 이층 침대 | `bunk_bed` | made · messy | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 카운터 | `counter` | straight · side · corner · end_closed · end_open | 이동 방해 · 상호작용(counter) | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 장식장 | `display_cabinet` | empty · broken · curios | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 잔 | `drinkware` | tankards · cups · goblets · toppled | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 걸이 화분 | `hanging_pot` | vines · dry | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 사냥 기념물 | `hunting_trophy` | boar_head · antlers · fish | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 긴 테이블 | `long_table` | broken · empty · set | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 장식 문양판 | `motif_plaque` | rosette · parted_shield · frieze | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 협탁 | `nightstand` | plain · candle · open | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 그림 액자 | `painting` | landscape · portrait · still_life · empty_frame · slashed · crooked | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 짐승 가죽 깔개 | `pelt_rug` | wolf · bear | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 깃발 줄 | `pennant_row` | faded · bright · torn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 장식 접시 걸이 | `plate_rack` | full · sparse | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 실내 화분 | `potted_plant` | fern · tree · dead | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 실내 창문 | `room_window` | day · night · broken · shuttered · curtained | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 작은 원탁 | `round_table` | candle · cloth · plain | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 차린 음식 | `served_food` | loaves · cheese · fruit · roast · pie | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 저장 항아리 | `storage_jar` | jar · amphora · crock · group · cracked · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 태피스트리 | `tapestry` | foliage · bands · hunt · torn · worn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 작은 장식품 | `trinket` | vase · figurine · hourglass · box | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽걸이 천 | `wall_cloth` | red · faded · blue | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽걸이 장식 | `wall_ornament` | horseshoe · wreath · farm_tools · oars | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 나무 기둥 | `wood_post` | plain · cracked · braced | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 나무 계단 | `wood_stairs` | up · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |

### 대장간 (`smithy`) — 23종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 도끼 진열대 | `axe_display` | full · sparse · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 풀무 | `bellows` | idle · compressed · torn | 이동 방해 · 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 벼리다 만 칼날 | `blade_blanks` | bundle · bucket | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 주물 틀 | `casting_mold` | empty · stack · poured | 이동 방해 · 광원 | 공용 | 코드 생성 | — | 낮음 |
| 석탄 더미 | `coal_pile` | pile · shovel · bin | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 도가니 | `crucible` | molten · cold · spilled | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 장작 | `firewood` | cord · pile · block | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 대장간 화덕 | `forge` | lit · embers · cold | 이동 방해 · 상호작용(fire) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 대장간 연기 | `forge_smoke` | thin · thick | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 대장간 불티 | `forge_sparks` | hammer · rising | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 금속 주괴 | `ingots` | iron_stack · copper_pallet · steel_bars · loose | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 철광석 | `iron_ore` | pile · sacks · crate | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 편자와 못 | `ironware_heap` | horseshoes · nail_keg · chains | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 기둥 바이스 | `post_vise` | work · base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 담금질 통 | `quench_tub` | still · steam · dry | 이동 방해 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 방패 거치대 | `shield_rack` | empty · half · full | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 망치와 집게 | `smith_tools` | block · hot_iron · scattered | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽에 건 편자와 사슬 | `smithy_wall_hang` | horseshoes · chains · apron | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 창 진열대 | `spear_display` | full · empty · sparse | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 검 진열대 | `sword_display` | sparse · full · empty | 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 벽 연장걸이 | `tool_rack_wall` | empty · full · sparse | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 그을음 | `wall_soot` | heavy · streak · plume | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 물 양동이 | `water_bucket` | full · empty · toppled | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |

### 여관 (`inn`) — 14종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 침구 더미 | `bedding` | stack · pillows | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 담요 | `blanket` | crumpled · draped · folded | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 외투 걸이 | `coat_pegs` | cloaks · empty · hats | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 식기 선반 | `dish_hutch` | broken · full · sparse | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 여관 카운터 | `inn_bar` | straight · taps · corner · mugs | 이동 방해 · 상호작용(counter) | 공용 | 코드 생성 | — | 낮음 |
| 꼭지 단 술통 | `inn_keg` | tapped · plain · drip | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 술통 거치대 | `keg_rack` | empty · full · tapped | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 열쇠 걸이 판 | `key_rack` | full · few | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 걸어 둔 부엌살림 | `kitchen_hangings` | sausages · pots · onions | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 주방 작업대 | `kitchen_table` | clean · messy | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 꼬치 굽는 화덕 | `spit_hearth` | lit · cold | 이동 방해 · 상호작용(fire) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 음식이 놓인 테이블 | `tavern_table` | meal · after · candle | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 세면대 | `washstand` | used · jug | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 술병 선반 | `wine_rack` | full · half | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |

### 신전 (`shrine`) — 23종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 세운 향로 | `censer` | smoking · cold | 이동 방해 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 매단 향로 | `censer_hanging` | smoking · cold | 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 성배 받침 | `chalice_stand` | single · set · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 독경대 | `lectern` | open · closed · empty | 이동 방해 · 상호작용(read) | 공용 | 코드 생성 | — | 낮음 |
| 헌금함 | `offering_box` | open · chest · post | 이동 방해 · 상호작용(offer) | 공용 | 코드 생성 | — | 낮음 |
| 봉헌물 | `offerings` | flowers · candles · fruit · coins · cloth | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 신도석 | `pew` | facing_n · facing_s · books · short | 이동 방해 · 상호작용(sit) | 공용 | 코드 생성 | — | 낮음 |
| 신도석(옆으로 놓인) | `pew_side` | facing_w · facing_e | 이동 방해 · 상호작용(sit) | 공용 | 코드 생성 | — | 낮음 |
| 기도서 | `prayer_books` | row · stack · open | 상호작용(read) | 공용 | 코드 생성 | — | 낮음 |
| 기도대 | `prayer_kneeler` | plain · cushion · book | 이동 방해 · 상호작용(pray) | 공용 | 코드 생성 | — | 낮음 |
| 성물함 | `reliquary` | closed · open · grille | 이동 방해 · 상호작용(examine) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 둥근 장미창 | `rose_window` | dim · glowing | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 신전 제단 | `shrine_altar` | plain · lit · dressed · festival | 이동 방해 · 상호작용(altar) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 제단 단(세 단 계단) | `shrine_dais` | straight · runner · corner · end | 바닥 장식 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 봉헌상(그릇을 받쳐 든 석상) | `shrine_statue` | plain · offerings · lamp | 이동 방해 · 상호작용(examine) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 작은 석상(받침 위) | `shrine_statuette` | single · pair · gilded | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 신전 벽 장식 | `shrine_wall_panel` | arcade · plaque · stoup | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 색유리 창 | `stained_glass` | dim · pair · pair_glowing · glowing | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 신전 종 | `temple_bell` | rope · frame | 이동 방해 · 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 신전 장식 기둥 | `temple_column` | clustered · fluted · banner | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 성수반 | `temple_font` | water · dry | 이동 방해 · 상호작용(examine) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 봉헌 촛대 | `votive_rack` | lit · half · out | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽감 | `wall_niche` | candle · vessel · empty | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

### 상점 (`shop`) — 22종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 약재 서랍장 | `apothecary_drawers` | closed · open · mortar | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 빵과 치즈 판매대 | `bread_board` | full · picked | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 돈통 | `coin_box` | closed · open | 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 탐험 장비 진열대 | `gear_table` | full · picked | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 상품 상자 | `goods_crate` | produce · bottles · herbs · candles | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 상품 선반 | `goods_shelf` | provisions · potions · sparse · empty · hardware | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 계단식 상품 진열대 | `goods_stand` | food · potions · empty · mixed | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 곡물 통 | `grain_bin` | full · low · lidded | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 걸어 둔 가방과 주머니 | `hanging_bags` | full · few | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 매단 약초 다발 | `herb_bundles` | full · mixed · sparse | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 약초 쟁반 | `herb_tray` | sorted · fresh · dried | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 장부 | `ledger` | closed · open · stack | 상호작용(read) | 공용 | 코드 생성 | — | 낮음 |
| 말린 고기 걸이 | `meat_rail` | empty · few · full | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 포장한 꾸러미 | `parcels` | single · cloth · stack | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 물약 꽂이 | `potion_rack` | tidy · half_sold · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 가격표와 상품 라벨 | `price_tags` | tag · tags_row · label_strip · chalk_board · chalk_board_worn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 밧줄 타래 | `rope_coil` | single · stack · spool | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 양팔저울 | `scale` | level · weights · coins | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 상점 카운터 | `shop_counter` | busy · closed · tidy | 이동 방해 · 상호작용(counter) | 공용 | 코드 생성 | — | 낮음 |
| 연장 걸이판 | `tool_board` | gaps · full | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 연장 묶음 | `tool_bundle` | barrel · leaning | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 횃불 통 | `torch_bin` | full · few | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |

### 은행 (`bank`) — 16종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 은행 서류 더미 | `bank_documents` | pigeonholes · bundles · stacks | 이동 방해 · 상호작용(examine) | 공용 | 코드 생성 | — | 낮음 |
| 은행 문양 판 | `bank_emblem` | plaque · worn | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 은행 창살 칸막이 | `bank_grille` | panel · gate · slot · gate_open | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |
| 바닥 놋 문양 | `bank_inlay` | bright · worn | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 대형 금고 | `big_safe` | closed · open | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 금화 더미 | `coin_piles` | small · stacks · heap · sack · tray · silver | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 철제 보관함 | `deposit_lockers` | one_open · looted · closed | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 보석 보관함 | `gem_case` | tray · coffer_closed · coffer_open | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 금고 잠금장치 | `lock_mechanism` | wall_open · dial · wall_locked | 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 줄 세우는 말뚝 | `queue_posts` | rope · single · down | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 봉인 도구 | `sealing_kit` | tray · letters | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 보안용 철문 | `security_door` | open · closed | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 | — | 낮음 |
| 소형 금고 | `strongbox` | closed · pried · open | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 은행 접수대 | `teller_counter` | open · closed · plain · end | 이동 방해 · 상호작용(counter) | 공용 | 코드 생성 | — | 낮음 |
| 귀중품 진열장 | `valuables_case` | full · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 금고 문 | `vault_door` | closed · ajar · open | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 | — | 낮음 |

## H. 아이템 · 아이콘

### 아이템 (`item`) — 29종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 붕대 두루마리 | `item_bandage_roll` | roll · pair · pad | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 뼈 재료 | `item_bone` | bone · fang · horn | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 책(아이템) | `item_book` | closed · clasp · tome | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 옷감 | `item_cloth` | bolt · folded · rag | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 문서(아이템) | `item_document` | letter · contract · note | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 음료(아이템) | `item_drink` | tankard · wine · waterskin | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 음식(아이템) | `item_food` | meat · stew · cheese · apple | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 보석(아이템) | `item_gem` | round_red · emerald_green · teardrop_blue · raw_violet | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 보석 주머니 | `item_gem_pouch` | open · closed | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 금화(아이템) | `item_gold_coin` | single · stack · pile | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 치료 도구 | `item_healer_tools` | salve · needle · mortar · splint | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 약초 다발 | `item_herb` | bundle · sprig · dried | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 가죽(아이템) | `item_hide` | strap · pelt · roll | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 금속 주괴(아이템) | `item_ingot` | iron · gold · steel_stack · copper_pair | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 열쇠(아이템) | `item_key` | ornate · iron · small | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 낡은 열쇠 | `item_key_old` | rusty · broken · bent | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 마법석(아이템) | `item_magic_stone` | raw_small · raw · cut · raw_large | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 지도(아이템) | `item_map` | fragment · unrolled · folded | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 광석 덩어리 | `item_ore` | copper · iron · silver | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 물약병(아이템) | `item_potion` | tall_blue · round_red · square_green · gourd_amber | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 휴대 식량 | `item_ration` | pack · hardtack · jerky | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 약초 재료 | `item_reagent_herb` | mushroom · flower · berries · root | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 마법 재료 | `item_reagent_magic` | dust_vial · shard · feather · rune_chip · bead | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 유물(아이템) | `item_relic` | device · disc · crown_piece | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 두루마리(아이템) | `item_scroll` | rolled · sealed · open | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 보물 상자(아이템) | `item_treasure_box` | closed · open · jeweled | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 장신구(아이템) | `item_trinket` | ring · necklace · bracelet · brooch | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 작은 물약병 | `item_vial` | tube_red · drop_blue · facet_green | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 목재(아이템) | `item_wood` | log · planks · branch | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |

### UI 아이콘 (`icon`) — 18종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 은행 아이콘 | `icon_bank` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 상자 아이콘 | `icon_chest` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 도시 입구 아이콘 | `icon_city_gate` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 장비 아이콘 | `icon_equipment` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 탐험가 길드 아이콘 | `icon_guild` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 여관 아이콘 | `icon_inn` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 상호작용 아이콘 | `icon_interact` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 열쇠 아이콘 | `icon_key` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 도서관 아이콘 | `icon_library` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 잠긴 문 아이콘 | `icon_locked_door` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 마석 아이콘 | `icon_magic_stone` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 재료 아이콘 | `icon_material` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 차원광장 아이콘 | `icon_plaza` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 물약 아이콘 | `icon_potion` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 상점 아이콘 | `icon_shop` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 신전 아이콘 | `icon_shrine` | plain · plate | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 대장간 아이콘 | `icon_smithy` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |
| 보물 아이콘 | `icon_treasure` | plate · plain | 머리 위 전경 | 공용 | 코드 생성 | — | 낮음 |

## 아직 없는 에셋(기획)

설정 문서에 나오지만 아직 만들지 않은 것 · 여러 지역에 필요한 기반. 다음 제작 단계는 위에서부터.

| 에셋 이름 | 분류 | 사용 지역 | 형태 | 기능 | 재사용성 | 제작 방식 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 동 · 서 · 남쪽을 보는 벽면 | 벽 | 모든 실내 | 지금은 북쪽 벽면만 — 옆 · 아래 벽과 옆으로 난 문 | 이동 방해 | 공용 | 코드 생성(타일) | 중간 |
| 곡선 책장 · 200단 계단 | 가구 · 구조물 | 도서관섬 | 원형 방 둘레에 맞는 굽은 책장 조각, 거대한 존재용 넓은 계단 | 이동 방해 · 통로 | 지역 전용 | 조합형 | 낮음 |
| 유령선 · 선착장 | 구조물 | 유령섬 · 대해 | 섬 둘레를 지나는 배(원경), 배를 대는 잔교 | 장식 | 지역 전용 | 개별 제작 | 낮음 |
| 저택 복도 · 살덩이 공간 | 바닥 · 벽 | 영혼의 요새 2 · 3페이즈 | 고풍스러운 저택 벽 · 마루, 꿈틀거리는 물컹한 바닥과 산성액 | 타일 | 지역 전용 | 코드 생성(타일) | 낮음 |
| 거대한 기둥 고리 · 푸른 알 | 구조물 | 아틀란테 중심부 | 빌딩만 한 기둥이 원형으로 선 공터(원경), 가운데 큰 알 | 랜드마크 | 지역 전용 | 개별 제작 | 낮음 |
| 나선 샛길 · 원형 계단 | 지형 | 빙하의 눈 · 녹색 탄광 3챕터 | 원기둥 벽을 따라 도는 좁은 길 | 이동 통로 | 지역 전용 | 조합형 | 낮음 |
| 오크 거주 구조물 | 구조물 | 3층 오크 군락지 | 문서에 생김새가 없다 — 원문을 받으면 만든다(키트는 울타리 · 천막으로 대신 · 게임 3층에는 따로 그린 천막 · 토템이 있다) | — | 지역 전용 | — | 낮음 |

