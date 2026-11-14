# ASSET_CATALOG — 에셋 목록

> `python3 tools/dungeon_kit/catalog.py`가 `assets/dungeon_kit/kit.json`에서 만든다 — **손으로 고치지 않는다**. 쓰는 법은 `GENERATION_GUIDE.md`, 지역별 묶음은 `REGIONAL_ASSET_PLAN.md`, 그림은 `docs/screens/asset_library/` · `docs/screens/dungeon_kit/`.

에셋 **268종** · 변형 1140개 · 그림 1474장 — 공용 241 · 지역 확장형 9 · 지역 전용 18. 지역 55곳.

- **재사용성**: 공용 = 어느 지역에나 · 지역 확장형 = 공용 에셋의 틀(`base`)을 지역 재질 · 형태로 넓힌 것 · 지역 전용 = 그 장소의 정체성.
- **우선순위**: 쓰는 지역 수로 매긴다(4곳 이상 높음 · 2~3곳 중간 · 그 밖 낮음) — 모두 만들어진 에셋이다. 아직 없는 것은 맨 아래 표.
- **기능**: 이동 방해 = `collide`가 있다 · 상호작용 = `interact` 귀띔 · 광원 = `light` · 애니메이션 = 여러 프레임.

## A. 공용 기본 · 지형

### 바닥 (`floor`) — 45종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 암반 | `ground_rock` | a · b · dark | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 대현자의 기념비, 지하 1층 입구 외 13 | 높음 |
| 석재 바닥 | `floor_flag` | b · a | 타일 | 공용 | 넓은 타일 그림 | 천공의 탑, 심연, 기록의 바다 외 6 | 높음 |
| 풀밭 | `ground_grass` | a · b · dry | 타일 | 공용 | 넓은 타일 그림 | 고블린 숲, 강철바위 언덕, 가시갈대 밭 외 5 | 높음 |
| 얕은 물 | `ground_water` | clear · black · red · silver | 타일 · 위험 바닥 · 애니메이션 | 공용 | 넓은 타일 그림 | 강철바위 언덕, 칠흑의 강어귀, 대해 외 4 | 높음 |
| 모래 바닥 | `floor_sand` | a | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 대해 외 3 | 높음 |
| 검게 탄 땅 | `ground_ash` | b · a · ember | 타일 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 패자의 안식처, 별무덤 외 3 | 높음 |
| 흙바닥 | `floor_dirt` | a · b | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 짐승의 소굴, 가시갈대 밭 외 2 | 높음 |
| 갈라진 마른 땅 | `ground_hardpan` | a · b | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 회색 벌판 외 2 | 높음 |
| 오래된 석재 바닥 | `floor_old` | b · a | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 천공의 탑, 판텔리온 유적지 외 1 | 높음 |
| 숲 바닥 | `ground_forest` | a · b | 타일 | 공용 | 넓은 타일 그림 | 고블린 숲, 마녀의 숲, 아노스섬 외 1 | 높음 |
| 얼음 바닥 | `ground_ice` | b · a · clear | 타일 | 공용 | 넓은 타일 그림 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 용암 | `ground_lava` | flow · poison | 타일 · 위험 바닥 · 애니메이션 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 태고의 땅, 적룡의 심처 외 1 | 높음 |
| 눈밭 | `ground_snow` | a · b · thin | 타일 | 공용 | 넓은 타일 그림 | 마녀의 오두막, 서리 협곡, 아이스록 외 1 | 높음 |
| 들꽃 핀 잔디밭 | `ground_meadow` | a · b | 타일 | 공용 | 넓은 타일 그림 | 마녀의 오두막, 피오네섬, 여명의 땅 | 중간 |
| 검은 진흙 | `ground_mud` | a · b | 타일 | 공용 | 넓은 타일 그림 | 망자의 땅, 칠흑의 강어귀, 녹빛꼬리 습지 | 중간 |
| 물가 · 용암가 테 | `shore_rim` | water_n · water_e · water_s · water_se · water_ne · water_sw · water_w … (24) | 바닥 장식 | 공용 | 코드 생성 | 지옥불 협곡, 아리베오나 강어귀, 핏빛성채 | 중간 |
| 깨진 바닥 | `floor_broken` | a | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 판텔리온 유적지 | 중간 |
| 물이 고인 바닥 | `floor_wet` | a | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬, 아틀란테 | 중간 |
| 습지 | `ground_swamp` | a · b | 타일 | 공용 | 넓은 타일 그림 | 칠흑의 강어귀, 녹빛꼬리 습지 | 중간 |
| 덤불 우거진 숲 바닥 | `ground_thicket` | a | 타일 | 공용 | 넓은 타일 그림 | 아노스섬, 대수림 | 중간 |
| 벽돌 바닥 | `floor_brick` | a · b | 타일 | 공용 | 넓은 타일 그림 | 영혼의 요새 | 낮음 |
| 불규칙한 돌바닥 | `floor_cobble` | a · b | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬 | 낮음 |
| 금이 간 바닥 | `floor_cracked` | a | 타일 | 공용 | 넓은 타일 그림 | 심연 | 낮음 |
| 이끼가 낀 바닥 | `floor_mossy` | a | 타일 | 공용 | 넓은 타일 그림 | 조각 사원 | 낮음 |
| 의식용 문양 바닥 | `floor_ritual` | a | 타일 | 공용 | 넓은 타일 그림 | 라르카즈의 미로 | 낮음 |
| 뼈가 깔린 땅 | `ground_bones` | a · b | 타일 | 공용 | 넓은 타일 그림 | 용의 심처 | 낮음 |
| 붉은 땅 | `ground_redsoil` | a · b | 타일 | 공용 | 넓은 타일 그림 | 태고의 땅 | 낮음 |
| 피가 묻은 바닥 | `floor_bloody` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 마법에 오염된 바닥 | `floor_corrupt` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 얼룩진 바닥 | `floor_stained` | a | 타일 | 공용 | 넓은 타일 그림 | — | 낮음 |
| 검게 탄 땅 번짐 띠 | `fringe_ash` | n_a · n_b · e_a · s_a · s_b · e_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 뼈가 깔린 땅 번짐 띠 | `fringe_bones` | n_a · n_b · e_b · e_a · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 흙바닥 번짐 띠 | `fringe_dirt` | n_a · e_a · n_b · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 숲 바닥 번짐 띠 | `fringe_forest` | n_b · e_a · n_a · s_a · s_b · e_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 풀밭 번짐 띠 | `fringe_grass` | n_a · n_b · e_a · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 갈라진 마른 땅 번짐 띠 | `fringe_hardpan` | n_a · n_b · e_a · e_b · s_a · s_b · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 얼음 바닥 번짐 띠 | `fringe_ice` | n_a · e_a · e_b · n_b · s_b · s_a · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 들꽃 핀 잔디밭 번짐 띠 | `fringe_meadow` | n_a · n_b · e_a · e_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 진흙 번짐 띠 | `fringe_mud` | n_a · n_b · e_b · s_a · e_a · s_b · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 붉은 땅 번짐 띠 | `fringe_redsoil` | n_a · n_b · e_b · s_b · e_a · s_a · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 암반 번짐 띠 | `fringe_rock` | e_a · e_b · n_a · n_b · s_a · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 모래 바닥 번짐 띠 | `fringe_sand` | n_a · e_b · n_b · s_a · e_a · s_b · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 눈밭 번짐 띠 | `fringe_snow` | n_a · n_b · e_a · s_a · e_b · s_b · w_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 습지 번짐 띠 | `fringe_swamp` | n_a · n_b · e_b · e_a · w_a · s_b · s_a … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 덤불 우거진 숲 바닥 번짐 띠 | `fringe_thicket` | n_a · e_b · e_a · n_b · s_a · s_b · w_b … (12) | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |

### 벽 · 절벽 (`wall`) — 23종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 동굴 암벽 | `wall_cave` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 수정동굴, 대현자의 기념비, 지하 1층 입구 외 21 | 높음 |
| 검은 현무암 절벽 | `wall_basalt` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 지옥불 협곡, 원귀의 협곡, 패자의 안식처 외 5 | 높음 |
| 석벽 | `wall_stone` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 망자의 땅, 천공의 탑, 심연 외 4 | 높음 |
| 낭떠러지 벽 | `cliff_drop` | ice · basalt · sandstone · cave · stone | 바닥 장식 | 공용 | 코드 생성 | 대마경, 지옥불 협곡, 얼음 동굴 외 2 | 높음 |
| 사암 절벽 | `wall_sandstone` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 바위사막, 황혼의 비탈길, 대해 외 2 | 높음 |
| 문양 새긴 석문 | `sealed_door` | plain · courage · wisdom · fate · patience · lit · open | 이동 방해 · 상호작용(door) · 광원 · 애니메이션 | 공용 | 코드 생성 · 조합형 | 천공의 탑, 심연, 기록의 바다 외 1 | 높음 |
| 고대 유적 벽 | `wall_ancient` | clean · cracked · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 조각 사원, 판텔리온 유적지, 기록의 바다 외 1 | 높음 |
| 얼음벽 | `wall_ice` | cracked · clean · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 낭떠러지 턱 | `cliff_lip` | n_a · n_b · e_a · e_b · w_a · w_b · ne … (8) | 바닥 장식 | 공용 | 코드 생성 | 대마경, 지옥불 협곡, 얼음 동굴 | 중간 |
| 문틀과 문 | `doorway` | wood · wood_broken · wood_ajar · iron · open · iron_ajar · portcullis … (9) | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 핏빛성채, 백색신전, 라르카즈의 미로 | 중간 |
| 무너진 벽 | `wall_ruin` | left · right · low · heap · gap | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 조각 사원 | 중간 |
| 감옥 철창 | `bars` | panel · bent · rusty · door · door_open · post | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 도플갱어 숲 | 낮음 |
| 아치형 통로 | `gateway` | open · barred · doors_open · doors · collapsed | 이동 방해 · 상호작용(door) | 공용 | 코드 생성 · 조합형 | 핏빛성채 | 낮음 |
| 수로 배수구 | `sewer_outlet` | dry · flow · grate · grate_flow | 애니메이션 | 공용 | 코드 생성 | 낙원의 섬 | 낮음 |
| 무너져 뚫린 벽 | `wall_breach` | a · b | 벽 장식 | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 벽돌벽 | `wall_brick` | cracked · clean · mossy · damaged | 타일 | 공용 | 넓은 타일 그림 | 영혼의 요새 | 낮음 |
| 문양 새긴 금속 벽 | `wall_metal` | cracked · damaged · mossy · clean | 타일 | 공용 | 넓은 타일 그림 | 강철의 묘 | 낮음 |
| 지하수로 벽 | `wall_sewer` | clean · cracked · damaged · mossy | 타일 | 공용 | 넓은 타일 그림 | 낙원의 섬 | 낮음 |
| 벽 끝(모서리돌) | `wall_end` | l · r | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽의 구멍 | `wall_hole` | a · b · c · high | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽기둥(버팀기둥) | `wall_pilaster` | plain · broken | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 안쪽 모서리 그늘 | `wall_shadow` | l · r | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 윗면(자동 연결 16가지) | `wall_top` | a · cave · b · sandstone · ice · basalt · metal | 타일 | 공용 | 넓은 타일 그림 · 조합형 | — | 낮음 |

### 지형 (`terrain`) — 15종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 현무암 바위 | `rock_basalt` | columns_a · columns_b · scorched · columns_low · molten · spire | 이동 방해 · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 지옥불 협곡, 태고의 땅, 적룡의 심처 외 1 | 높음 |
| 얼음 덩이 | `rock_ice` | shards_a · shards_b · block · block_cracked · pillar · snowcap · pillar_frozen … (8) | 이동 방해 | 지역 확장형 ← `rock` | 코드 생성 | 서리 협곡, 아이스록, 얼음 동굴 외 1 | 높음 |
| 사암 바위 | `rock_sandstone` | strata_a · strata_b · hoodoo · hoodoo_b · stack · arch · buried | 이동 방해 | 지역 확장형 ← `rock` | 코드 생성 | 바위사막, 황혼의 비탈길, 대해 외 1 | 높음 |
| 눈 더미 | `snow_drift` | a · b · c · long | 장식 | 공용 | 코드 생성 | 마녀의 오두막, 서리 협곡, 아이스록 외 1 | 높음 |
| 고드름 | `icicles` | b · a · sparse | 머리 위 전경 | 지역 확장형 ← `stalactite` | 코드 생성 | 서리 협곡, 얼음 동굴, 빙하굴 | 중간 |
| 로프 건널목 | `rope_crossing` | anchor · taut_w · taut_e · cut · coiled | 상호작용(rope) | 공용 | 코드 생성 | 대마경, 얼음 동굴, 빙하굴 | 중간 |
| 거대한 뼈 | `giant_bone` | vertebra · rib_single · rib_arch · skull · spine · femur · shards | 장식 | 지역 전용 | 코드 생성 | 용의 심처, 태고의 땅 | 중간 |
| 운석 구덩이 | `crater` | cold · fresh · small | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 천장 수정 | `crystal_ceiling` | a · b | 광원 | 지역 전용 | 코드 생성 | 수정동굴 | 낮음 |
| 벽에 붙은 수정 | `crystal_wall` | c · b · a · cluster · dim | 광원 | 지역 전용 | 코드 생성 | 수정동굴 | 낮음 |
| 운석 | `meteorite` | cold · glowing · shards | 이동 방해 · 광원 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 굳은 둔덕 | `mound` | b · a · ruin · long | 이동 방해 | 지역 전용 | 코드 생성 | 망자의 땅 | 낮음 |
| 광맥 바위 | `ore_vein` | green · green_b · iron · mined | 이동 방해 · 상호작용(breakable) · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 녹색 탄광 | 낮음 |
| 땅에 박힌 낡은 검 | `planted_sword` | a · c · b · cluster · broken · cluster_b | 장식 | 지역 전용 | 코드 생성 | 패자의 안식처 | 낮음 |
| 수정 박힌 바위 | `rock_crystal` | a · large · b · dim | 이동 방해 · 광원 | 지역 확장형 ← `rock` | 코드 생성 | 수정동굴 | 낮음 |

### 자연물 (`nature`) — 18종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 돌무더기 | `rubble` | small · small_b · brick · large_b · large · brick_large · scatter | 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 망자의 땅 외 8 | 높음 |
| 바위 | `rock` | small_b · medium_a · small_a · large_b · large_a · medium_b · slab_b … (9) | 장식 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비, 짐승의 소굴 외 5 | 높음 |
| 바닥 균열 | `ground_crack` | a · b · c · wide | 바닥 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 대마경 외 3 | 높음 |
| 바닥을 기는 뿌리 | `roots` | a · b · c · knot | 장식 | 공용 | 코드 생성 | 짐승의 소굴, 칠흑의 강어귀, 마녀의 숲 외 3 | 높음 |
| 웅덩이 | `puddle` | small · murky · large · medium · ripple · bloody | 애니메이션 | 공용 | 코드 생성 | 수정동굴, 망자의 땅, 칠흑의 강어귀 외 2 | 높음 |
| 덩굴 | `vines` | ivy_a · hang_long · hang_short · hang_mid · ivy_b · dead | 벽 장식 | 공용 | 코드 생성 | 마녀의 숲, 아노스섬, 대수림 외 1 | 높음 |
| 이끼 낀 큰 바위 | `boulder_mossy` | b · a | 이동 방해 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴, 강철바위 언덕 | 중간 |
| 돌기둥(종유석과 석순이 이어진) | `column_natural` | a · b | 이동 방해 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비 | 중간 |
| 자갈 | `gravel` | b · a · c · sparse | 바닥 장식 | 공용 | 코드 생성 | 수정동굴, 짐승의 소굴 | 중간 |
| 종유석 | `stalactite` | large · small · cluster · cluster_b · dripping | 머리 위 전경 | 공용 | 코드 생성 | 수정동굴, 낙원의 섬 | 중간 |
| 석순 | `stalagmite` | small · tall · broken · cluster · cluster_b | 장식 | 공용 | 코드 생성 | 수정동굴, 대현자의 기념비 | 중간 |
| 이끼 | `moss_patch` | a · b · c · d · dry | 바닥 장식 | 공용 | 코드 생성 | 수정동굴 | 낮음 |
| 버섯 | `mushroom` | cluster_a · cluster_c · cluster_b · big · pale | 장식 | 공용 | 코드 생성 | 수정동굴 | 낮음 |
| 벽에 난 선반버섯 | `mushroom_shelf` | a · b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 독버섯 | `toadstool` | red_a · red_b · glow_a · glow_violet · glow_b | 광원 | 공용 | 코드 생성 | — | 낮음 |
| 벽 이끼 | `wall_moss` | base_a · base_b · top_b · top_a · patch | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽을 뚫고 나온 뿌리 | `wall_roots` | a · c · b | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 잡초 | `weeds` | tuft_a · tuft_b · tuft_dry · dead_bush · bramble · sprouts · fern | 장식 | 공용 | 코드 생성 | — | 낮음 |

## B. 식생

### 식생 (`flora`) — 12종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 덤불 | `bush` | flowering · b · wide · a · snowy · dry | 장식 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 아노스섬 외 5 | 높음 |
| 키 큰 풀 | `grass_tall` | b · a · dry · c · wide | 장식 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 녹빛꼬리 습지 외 4 | 높음 |
| 활엽수 | `tree_broadleaf` | a · young · bare · c · fruit · b · autumn | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 강철바위 언덕, 마녀의 오두막 외 4 | 높음 |
| 쓰러진 통나무 | `log` | a · mossy · hollow · burnt | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 녹빛꼬리 습지, 아노스섬 외 1 | 높음 |
| 부들 | `cattail` | a · c · b | 장식 | 공용 | 코드 생성 | 칠흑의 강어귀, 녹빛꼬리 습지, 아리베오나 강어귀 | 중간 |
| 들꽃 무더기 | `flowers` | white · violet · mixed_a · red · yellow · mixed_b | 장식 | 공용 | 코드 생성 | 마녀의 오두막, 피오네섬, 여명의 땅 | 중간 |
| 그루터기 | `stump` | burnt · mossy · a · axe | 이동 방해 | 공용 | 코드 생성 | 고블린 숲, 불의 거울 | 중간 |
| 검은 불에 타는 나무 | `tree_burning` | black_flame · black_flame_b · charred | 이동 방해 · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 불의 거울, 종말의 기억 | 중간 |
| 밀림의 거목 | `tree_giant` | b · a · hollow | 이동 방해 · 상호작용(entrance) | 지역 확장형 ← `tree_broadleaf` | 코드 생성 | 아노스섬, 대수림 | 중간 |
| 침엽수 | `tree_pine` | a · b · dead · young · snowy | 이동 방해 | 공용 | 코드 생성 | 강철바위 언덕, 아이스록 | 중간 |
| 매마른 가시나무 | `tree_thorn` | a · b · c · vined · leafy · vined_b · stir … (8) | 이동 방해 · 광원 · 애니메이션 | 지역 확장형 ← `tree_broadleaf` | 코드 생성 | 마녀의 숲, 마녀의 오두막 | 중간 |
| 가시갈대 | `reed_thorn` | a · b · c · sparse · dense · trampled | 시야 덮개 | 지역 전용 | 코드 생성 | 가시갈대 밭 | 낮음 |

## C. 건축 · 구조물

### 구조물 (`structure`) — 21종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 폐허 담 | `ruin_wall` | low · straight_a · straight_b · window · doorway · corner · stub … (9) | 이동 방해 | 공용 | 코드 생성 · 조합형 | 망자의 땅, 바위사막, 조각 사원 외 2 | 높음 |
| 기둥 | `pillar` | intact · mossy · broken · cracked · stump · fallen | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 바위사막, 조각 사원 외 1 | 높음 |
| 포탈 비석 | `portal_stele` | active · idle · active_dark · dead · leaning · giant | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 지하 1층 입구, 고블린 숲, 천공의 탑 외 1 | 높음 |
| 다리 | `bridge` | wood_h · wood_v · wood_broken · wood_end · stone_h · stone_v · stone_broken … (8) | 바닥 장식 | 공용 | 코드 생성 · 조합형 | 대마경, 핏빛성채, 녹색 탄광 | 중간 |
| 흰 대리석 기둥 | `pillar_white` | intact · broken · cracked · glowing · sunken | 이동 방해 · 광원 · 애니메이션 | 지역 확장형 ← `pillar` | 코드 생성 | 기록의 바다, 백색신전, 아틀란테 | 중간 |
| 석상 | `statue` | intact · mossy · broken · headless · ruined | 이동 방해 | 공용 | 코드 생성 | 조각 사원, 기록의 바다, 백색신전 | 중간 |
| 제단 | `altar` | plain · bloody · ritual · broken | 이동 방해 · 상호작용(altar) · 애니메이션 | 공용 | 코드 생성 | 아르타 섬, 도플갱어 숲 | 중간 |
| 아치 | `arch` | mossy · intact · ruined | 이동 방해 | 공용 | 코드 생성 | 망자의 땅, 조각 사원 | 중간 |
| 철로 | `mine_track` | curve · straight_v · straight_h · end · broken | 바닥 장식 | 지역 전용 | 코드 생성 · 조합형 | 판텔리온 유적지, 녹색 탄광 | 중간 |
| 받침대 | `pedestal` | empty · orb_red · idol · orb · broken | 이동 방해 · 상호작용(pedestal) · 광원 | 공용 | 코드 생성 | 조각 사원, 영혼의 요새 | 중간 |
| 두건 쓴 석상 | `statue_robed` | weeping · intact | 이동 방해 | 공용 | 코드 생성 | 핏빛성채, 백색신전 | 중간 |
| 천막 | `tent` | canvas_b · canvas · hide · collapsed | 이동 방해 | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 광차 | `mine_cart` | empty · ore · rubble · tipped | 이동 방해 · 상호작용(container) | 지역 전용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 갱도 버팀목 | `mine_support` | intact · collapsed · sagging | 이동 방해 | 지역 전용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 기념비 | `monument` | plain · offered · worn | 이동 방해 · 상호작용(altar) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 대현자의 기념비 | 낮음 |
| 말뚝 울타리 | `palisade` | straight_b · straight_a · corner · gate · broken · gate_open · spiked | 이동 방해 | 공용 | 코드 생성 · 조합형 | 오크 군락지 | 낮음 |
| 석관 | `sarcophagus` | closed · ajar · open · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 내려가는 계단 | `stairs_down` | stone | 상호작용(stairs) | 공용 | 코드 생성 | 기록의 바다 | 낮음 |
| 올라가는 계단 | `stairs_up` | worn · stone | 이동 방해 · 상호작용(stairs) | 공용 | 코드 생성 | 천공의 탑 | 낮음 |
| 사다리 | `ladder` | wall · broken · hatch | 상호작용(ladder) | 공용 | 코드 생성 | — | 낮음 |
| 난간 | `railing` | post · straight · broken · side | 이동 방해 | 공용 | 코드 생성 · 조합형 | — | 낮음 |

## D. 장식 · 환경 흔적

### 가구 · 생활 (`furniture`) — 33종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 보물상자 | `chest` | closed · open · locked · empty · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 천공의 탑, 도플갱어 숲, 영혼의 요새 | 중간 |
| 책장 | `bookshelf` | half · empty · broken · full | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 마녀의 오두막, 기록의 바다 | 중간 |
| 보급품 더미 | `supply_pile` | a · b | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 배낭 | `backpack` | opened · standing | 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 나무통 | `barrel` | intact · water · toppled · stack · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 침낭 | `bedroll` | rolled · used · out | 장식 | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 깔개 | `carpet` | red · blue · green · torn · worn · round | 바닥 장식 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 의자 | `chair` | s · n · e · w · broken · toppled | 이동 방해 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 나무 상자 | `crate` | intact · open · stack · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 스타트 포인트 | 낮음 |
| 탁자 | `table` | intact · set · broken · toppled | 이동 방해 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 무기 거치대 | `weapon_rack` | half · full · empty · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | 오크 군락지 | 낮음 |
| 모루 | `anvil` | base · hammer | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 갑옷 거치대 | `armor_stand` | fallen · armor · empty | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 바구니 | `basket` | empty · food · toppled | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 침대 | `bed` | messy · bare · broken · made | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 긴 의자 | `bench` | base · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 책 | `books` | stack · open · scattered · tall | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 병 | `bottles` | group · fallen · potion_red · potion_blue · wine | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 캐비닛 | `cabinet` | closed · open · broken | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 솥 | `cooking_pot` | stew · cold · ground | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 책상 | `desk` | intact · cluttered · broken | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 식기 | `dishes` | set · bowls · dirty | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 서랍장 | `dresser` | open · closed | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 음식 잔해 | `food_scraps` | b · a | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 숫돌 바퀴 | `grindstone` | base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 흩어진 문서 | `papers` | a · b · stack | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 자루 | `sack` | full · open · slumped · pile | 이동 방해 · 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 두루마리 | `scrolls` | pile · case · open | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 걸상 | `stool` | toppled · base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 짚 더미 | `straw_pile` | b · a | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 연장통 | `toolbox` | full · empty | 상호작용(container) | 공용 | 코드 생성 | — | 낮음 |
| 벽 선반 | `wall_shelf` | empty · bottles · books · skull | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 작업대 | `workbench` | tools · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |

### 환경 흔적 (`trace`) — 35종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 해골 | `skull` | single · pike · pair · cracked · heap · side | 장식 | 공용 | 코드 생성 | 망자의 땅, 오크 군락지, 용의 심처 외 1 | 높음 |
| 뼈 | `bones` | scatter_a · scatter_b · crossed · ribcage · spine · pile | 장식 | 공용 | 코드 생성 | 짐승의 소굴, 망자의 땅, 용의 심처 | 중간 |
| 나무 잔해 | `debris_wood` | planks · splinters · furniture | 장식 | 공용 | 코드 생성 | 칠흑의 강어귀, 녹색 탄광 | 중간 |
| 그을음 | `scorch` | a · b · blast | 바닥 장식 | 공용 | 코드 생성 | 지옥불 협곡, 불의 거울 | 중간 |
| 부서진 무기 | `broken_weapon` | sword · spear · helmet · arrows · mace · axe · pile … (8) | 장식 | 공용 | 코드 생성 | 패자의 안식처 | 낮음 |
| 뼈와 넝마 둥지 | `nest` | base · eggs | 장식 | 공용 | 코드 생성 | 짐승의 소굴 | 낮음 |
| 긁힌 자국 | `scratches` | a · b · c · deep | 바닥 장식 | 공용 | 코드 생성 | 대해 | 낮음 |
| 벽에 새긴 글 | `wall_writing` | b · a · c · worn | 벽 장식 | 공용 | 코드 생성 | 지하 1층 입구 | 낮음 |
| 잿더미 | `ash_pile` | campfire · ash · pyre | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 점액 | `black_slime` | a · b · trail · c | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 피 웅덩이 | `blood_pool` | fresh_b · fresh · dried · dried_b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 핏자국 | `blood_splat` | a · b · c · d · drops | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 끌린 핏자국 | `blood_trail` | straight · curved · hand · vertical | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽에 튄 피 | `blood_wall` | a · b · hand · c · smear | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 깨진 병 | `bottle_broken` | green · brown · red | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 유리 조각 | `bottle_shards` | green · brown · clear | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 부서진 갑옷 | `broken_armor` | breastplate · mail · pieces | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 거미줄 | `cobweb` | corner_l · corner_r · torn · floor · span | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 시체 | `corpse` | shrouded · rotten · explorer_b · explorer | 상호작용(search) | 공용 | 코드 생성 | — | 낮음 |
| 끌린 자국 | `drag_marks` | a · b · curved | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 먼지 | `dust` | c · b · a · drift | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 발자국 | `footprints` | bloody · bloody_fade · dust · wet | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 매달린 쇠우리 | `gibbet` | skeleton · empty | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 의식 표식 | `ritual_marks` | sigil_a · chalk_circle · salt_line · sigil_b · salt_ring | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 의식의 흔적 | `ritual_remains` | offering · bone_circle · candle_ring | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 썩은 자국 | `rot_stain` | a · c · b | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 유골 | `skeleton` | sitting · lying · armored · chained | 상호작용(search) | 공용 | 코드 생성 | — | 낮음 |
| 쇠고랑에 매달린 유골 | `skeleton_chained` | base | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 검은 점액 덩이 | `slime_blob` | a · b | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 낙서 | `wall_graffiti` | chalk_a · chalk_b · chalk_c · chalk_d · blood_b · blood_a · blood_c | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 긁힌 자국 | `wall_scratches` | claw_a · claw_b · tally · tally_many · nails | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽을 타고 흐르는 점액 | `wall_slime` | b · a | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 물자국 | `wall_stain` | a · b · c | 벽 장식 | 공용 | 코드 생성 | — | 낮음 |
| 물 얼룩 | `water_stain` | b · a · c | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 거미줄 고치 | `web_cocoon` | hanging · standing · cluster | 장식 | 공용 | 코드 생성 | — | 낮음 |

### 조명 (`light`) — 16종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 모닥불 | `firepit` | lit · embers · cold | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 오크 군락지, 스타트 포인트 | 중간 |
| 마법 등 | `magic_lamp` | blue · red · violet · dead | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 스타트 포인트, 백색신전 | 중간 |
| 벽 횃불 | `torch_wall` | lit · unlit · stub | 광원 · 애니메이션 | 공용 | 코드 생성 | 천공의 탑, 라르카즈의 미로 | 중간 |
| 화로 | `brazier` | lit · embers · cold · toppled | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | 오크 군락지 | 낮음 |
| 벽난로 | `fireplace` | lit · dying · cold | 이동 방해 · 상호작용(fire) · 광원 · 애니메이션 | 공용 | 코드 생성 | 마녀의 오두막 | 낮음 |
| 걸린 랜턴 | `lantern_hanging` | lit · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | 녹색 탄광 | 낮음 |
| 세 갈래 촛대 | `candelabra` | lit · unlit | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 양초 무더기 | `candles` | lit · stubs · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 촛대 | `candlestick` | lit · unlit | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 샹들리에 | `chandelier` | lit · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 떨어진 샹들리에 | `chandelier_fallen` | base | 이동 방해 | 공용 | 코드 생성 | — | 낮음 |
| 빛나는 균열 | `glow_crack` | blue · red · dead · blue_b · dead_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 빛나는 룬 | `glow_rune` | a_off · b_off · c_off · d_off · a_blue · b_blue · c_blue … (10) | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 랜턴 | `lantern` | lit · broken · unlit | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 바닥 횃불 | `torch_stand` | lit · fallen · unlit | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽 룬 글줄 | `wall_rune` | off · blue · red · blue_b · off_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

## E. 상호작용 · 기믹

### 특수 · 기믹 (`special`) — 19종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 포털 | `portal` | dormant · violet · blue · shattered | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 대현자의 기념비, 천공의 탑, 아르타 섬 외 6 | 높음 |
| 수정 | `crystal` | blue_small · blue_large · red_small · red_large · violet_small · violet_large · dead … (8) | 이동 방해 · 광원 | 공용 | 코드 생성 | 수정동굴, 영혼의 요새, 낙원의 섬 | 중간 |
| 거울 | `great_mirror` | dormant · active · broken | 이동 방해 · 상호작용(portal) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 대마경, 불의 거울 | 중간 |
| 마법진 | `magic_circle` | a_blood · a_chalk · a_blue · a_red · b_chalk · b_blood · b_blue … (12) | 상호작용(circle) · 광원 · 애니메이션 | 공용 | 코드 생성 | 핏빛성채, 라르카즈의 미로 | 중간 |
| 고대 기계 장치 | `ancient_machine` | dormant · active · wrecked | 이동 방해 · 상호작용(machine) · 광원 · 애니메이션 | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 톱니바퀴 더미 | `gear_pile` | a · b | 장식 | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 압력판 | `pressure_plate` | up · pressed · rune · rune_pressed | 상호작용(plate) · 애니메이션 | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 차원 균열 | `rift` | active · dormant · active_b | 상호작용(rift) · 광원 · 애니메이션 | 공용 | 코드 생성 | 차원 붕괴 | 낮음 |
| 봉인 장치 | `seal_device` | sealed · weakened · broken | 이동 방해 · 상호작용(seal) · 광원 · 애니메이션 | 공용 | 코드 생성 | 도플갱어 숲 | 낮음 |
| 석판 | `stone_tablet` | intact · mossy · glowing · broken | 이동 방해 · 상호작용(read) · 광원 · 애니메이션 | 공용 | 코드 생성 | 기록의 바다 | 낮음 |
| 밸브 바퀴 | `valve_wheel` | idle · rusted · turned | 상호작용(valve) | 공용 | 코드 생성 | 판텔리온 유적지 | 낮음 |
| 사슬 자물쇠 | `chained_lock` | locked · broken | 상호작용(lock) | 공용 | 코드 생성 | — | 낮음 |
| 레버 | `lever` | left · right · broken | 이동 방해 · 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 잠금 받침대 | `lock_pedestal` | locked · unlocked · keyhole · empty | 이동 방해 · 상호작용(lock) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 마력 잔류물 | `mana_residue` | blue · violet · green · blue_b | 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 룬석 | `rune_stone` | blue · dormant · red · dormant_b · blue_b · violet_c · dormant_c | 이동 방해 · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽 레버 | `wall_lever` | up · down | 상호작용(lever) | 공용 | 코드 생성 | — | 낮음 |
| 벽 석판 | `wall_tablet` | b · a · c | 상호작용(read) | 공용 | 코드 생성 | — | 낮음 |
| 감는 틀 | `winch` | idle · turned2 · turned | 이동 방해 · 상호작용(winch) | 공용 | 코드 생성 | — | 낮음 |

### 함정 (`trap`) — 24종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 구덩이 함정 | `pit_trap` | covered · bloody · open · empty | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲, 도플갱어 숲 | 중간 |
| 회전 칼날 | `blade_trap` | spin · still · bloody · jammed | 이동 방해 · 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 화살 구멍 | `dart_holes` | idle · fired | 상호작용(trap) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 즉사 함정 타일 | `death_tile` | hidden · revealed · hidden_b · armed · sprung | 상호작용(trap) · 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 심연 | 낮음 |
| 화염 분사 | `flame_jet` | firing · low | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | 적룡의 심처 | 낮음 |
| 벽 창 함정 | `spear_wall` | idle · bloody · out | 상호작용(trap) | 공용 | 코드 생성 | 강철의 묘 | 낮음 |
| 가시 함정(솟음) | `spike_trap` | extended · half · bloody · rusted | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲 | 낮음 |
| 인계철선 | `tripwire` | set · side · tripped | 상호작용(trap) | 공용 | 코드 생성 | 고블린 숲 | 낮음 |
| 칼날 홈 | `blade_slot` | idle · bloody | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 떨어진 낙하석 | `ceiling_block` | dust · bloody · fallen | 이동 방해 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 매달린 낙하석 | `ceiling_chain` | hang · falling | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 낙하 함정 자리 | `ceiling_warn` | a · b | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 무너지는 바닥 | `collapse_floor` | cracked · sagging · half · pit | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 쏘고 남은 화살 | `darts_spent` | b · a · bloody | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 화염 분사구 | `flame_nozzle` | idle · scorched · pilot | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 독가스 분출구 | `gas_grate` | idle · stained | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 독가스 분출 | `gas_vent` | venting · thin | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 벽 독가스 구멍 | `gas_vent_wall` | venting · idle | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 진자 도끼 | `pendulum` | swing · still · bloody | 상호작용(trap) · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 룬 함정 | `rune_trap` | faint · armed · spent | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |
| 그을린 자국 | `scorch_mark` | streak · b · a | 바닥 장식 | 공용 | 코드 생성 | — | 낮음 |
| 가시 함정(숨음) | `spike_plate` | bloody · idle | 상호작용(trap) | 공용 | 코드 생성 | — | 낮음 |
| 함정의 흔적 | `trap_remains` | rusty_spikes · snapped_blade · sprung_spears · skeleton_spikes | 장식 | 공용 | 코드 생성 | — | 낮음 |
| 벽 화염 분사구 | `wall_flame` | idle · firing · scorched | 상호작용(trap) · 광원 · 애니메이션 | 공용 | 코드 생성 | — | 낮음 |

## F. 환경 연출

### 환경 연출 (`fx`) — 7종

| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 흩날리는 입자 | `drift` | snow · ember · ash · dust · frost | 애니메이션 | 공용 | 코드 생성 | 바위사막, 마녀의 오두막, 지옥불 협곡 외 6 | 높음 |
| 안개 | `mist` | grey · black · violet · blue · grey_b · black_b | 애니메이션 | 공용 | 코드 생성 | 마녀의 오두막, 원귀의 협곡, 패자의 안식처 외 1 | 높음 |
| 폭포 | `waterfall` | clear · red · black · clear_wide | 애니메이션 | 공용 | 코드 생성 | 아리베오나 강어귀, 빙하굴 | 중간 |
| 퍼지는 공간 균열(차원 붕괴) | `collapse_crack` | seed · spread · web · web_b | 광원 · 애니메이션 | 공용 | 코드 생성 | 차원 붕괴 | 낮음 |
| 은빛 구체 | `light_orb` | rise · rise_b · cluster | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 강철바위 언덕 | 낮음 |
| 벼락 줄기 | `lightning` | strike · strike_b | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |
| 붉은 빛(낙하 예고) | `red_beam` | pulse | 광원 · 애니메이션 | 지역 전용 | 코드 생성 | 별무덤 | 낮음 |

## 아직 없는 에셋(기획)

설정 문서에 나오지만 아직 만들지 않은 것 · 여러 지역에 필요한 기반. 다음 제작 단계는 위에서부터.

| 에셋 이름 | 분류 | 사용 지역 | 형태 | 기능 | 재사용성 | 제작 방식 | 우선순위 |
|---|---|---|---|---|---|---|---|
| 경사면 · 높낮이 단 | 지형 | 8층 동산 · 강철바위 언덕 · 급경사(빙하굴 3챕터) | 바닥이 한 단 올라가는 턱(오르는 비탈 조각 + 단 옆면) | 이동 통로 · 방해 | 공용 | 코드 생성(타일) | 높음 |
| 도개교 · 해자 | 구조물 | 핏빛성채 | 내려오는 도개교(올림 · 내림), 핏물이 찬 해자 가장자리 | 상호작용 | 지역 전용 | 조합형 | 중간 |
| 깊은 바다 · 백색 모래사장 · 암초 | 바닥 · 지형 | 6층 대해 | 흰 모래 바닥, 에메랄드빛 깊은 물, 물 위로 솟은 암초 · 붉은 바위 | 이동 방해 | 지역 확장형 | 코드 생성 | 중간 |
| 배 · 부서진 배 · 선착장 | 구조물 | 6층 대해 · 원귀의 협곡 · 유령섬 | 현지에서 만든 작은 배, 난파선 조각 | 상호작용 | 지역 전용 | 개별 제작 | 중간 |
| 얼음 계단 · 투명한 계단 | 구조물 | 빙하굴 2챕터 · 영혼의 요새 | 아래로 내려가는 얼음 계단, 유리 같은 계단 | 이동 통로 | 지역 확장형 | 코드 생성 | 중간 |
| 공장 레일 · 드론 잔해 | 구조물 | 판텔리온 유적지(사원 안 공장) | 천장 레일, 멈춘 드론, 변환 장치 | 장식 · 기믹 | 지역 전용 | 코드 생성 | 중간 |
| 폭발물 · 부술 수 있는 벽 | 기믹 | 녹색 탄광 | 숨겨진 폭발물 통, 금 간 벽(부수면 샛길) | 상호작용 | 공용 | 코드 생성 | 중간 |
| 수호자 석상 줄 · 보석 쥔 석상 | 구조물 | 석문섬 · 백색신전 | 손에 푸른 보석을 든 석상(빛 4프레임) | 상호작용 | 지역 확장형 | 코드 생성 | 중간 |
| 동 · 서 · 남쪽을 보는 벽면 | 벽 | 모든 실내 | 지금은 북쪽 벽면만 — 옆 · 아래 벽과 옆으로 난 문 | 이동 방해 | 공용 | 코드 생성(타일) | 중간 |
| 천장까지 닿는 책장 · 곡선 책장 | 가구 | 도서관섬 | 벽 높이를 넘는 큰 책장, 원형 방 둘레에 맞는 굽은 조각 | 이동 방해 | 지역 전용 | 조합형 | 낮음 |
| 나선 샛길 · 원형 계단 | 지형 | 빙하의 눈 · 녹색 탄광 3챕터 | 원기둥 벽을 따라 도는 좁은 길 | 이동 통로 | 지역 전용 | 조합형 | 낮음 |
| 2층 벽돌집(불탄) | 구조물 | 불의 거울 불타는 숲 | 검게 그을린 나무 문, 불타 뼈대만 남은 가구 | 상호작용 | 지역 전용 | 조합형 | 낮음 |
| 오크 거주 구조물 | 구조물 | 3층 오크 군락지 | 문서에 생김새가 없다 — 원문을 받으면 만든다(지금은 울타리 · 천막으로 대신) | — | 지역 전용 | — | 낮음 |
| 피라미드 사원 · 거대한 기둥 고리 | 구조물 | 아틀란테 | 계단식 사원, 빌딩만 한 기둥(원경) | 랜드마크 | 지역 전용 | 개별 제작 | 낮음 |
| 첨탑(원경) | 구조물 | 3층 강철바위 언덕 | 천장까지 이어진 첨탑 — 멀리 보이는 그림 | 랜드마크 | 지역 전용 | 개별 제작 | 낮음 |
| 까마귀 · 유령선 · 떠다니는 부산물 | 환경 연출 | 핏빛성채 · 유령섬 · 기록의 바다 | 배경에서 움직이는 것 | 장식 | 지역 전용 | 개별 제작 | 낮음 |

