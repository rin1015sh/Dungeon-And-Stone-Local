# GENERATION_GUIDE — 에셋 라이브러리 쓰는 법 · 더하는 법 (2026-11-14, AM68)

미궁의 여러 층 · 필드 · 균열 · 히든 필드에서 되풀이해 쓰는 그림 묶음. **던전 에셋 키트(`docs/DUNGEON_KIT.md` — AM65)를 그대로 넓힌 것**이다: 그림 기법 · 좌표 · 층 · 충돌 규칙 · 굽는 도구가 모두 같고, 여기에 야외 · 자연 · 지역 에셋과 "지역 표"가 더해졌다.
원본 자료는 사용자가 준 미궁 설정 문서(「겜바바 미궁 설정」, 2026-11-14) — 문서에 없는 생김새는 확정 설정으로 쓰지 않는다(§5).

| 문서 | 무엇 |
|---|---|
| `ASSET_CATALOG.md` | 에셋 전체 표(이름 · 분류 · 형태 · 기능 · 재사용성 · 제작 방식 · 쓰는 지역 · 우선순위) + 아직 없는 에셋 — **자동 생성** |
| `REGIONAL_ASSET_PLAN.md` | 지역 55곳마다 쓸 바닥 · 벽 · 에셋, 설정 문서의 묘사 정도, 남은 것 — **자동 생성** |
| 이 문서 | 쓰는 법 · 새 에셋 · 새 지역 더하는 법 · 이름 규칙 · 검증 |
| `docs/screens/asset_library/` | `sheet_<분류>.jpg` 이름표 붙은 모음 그림 · `set_<세트>.jpg` 지역 본보기 장면 |

## 1. 무엇이 더해졌나 (65종 — 키트 181 → 246종 · 그림 1218장)

| 묶음 | 파일 | 에셋 |
|---|---|---|
| 야외 바닥 19 | `a_ground.py` | 풀밭 · 들꽃 잔디밭 · 숲 바닥 · 덤불 우거진 숲 바닥 · 검은 진흙 · 습지 · 갈라진 마른 땅 · 붉은 땅 · 암반 · 뼈가 깔린 땅 · 눈밭 · 얼음 · 검게 탄 땅 · **용암(4프레임 · 맹독)** · **얕은 물(4프레임 — 맑은 · 검은 · 붉은 · 은빛)** |
| 자연 암벽 5 + 윗면 5 | `a_wall.py` `KINDS` | 동굴 암벽 · 사암 절벽(지층) · 얼음벽 · 현무암 절벽(기둥 다발) · 문양 새긴 금속 벽 — 상태 넷(clean · cracked · mossy(= 눈 · 모래 · 재 · 녹) · damaged), 종류별 벽 윗면 |
| 지형 14 | `a_terrain.py` | 사암 바위 · 얼음 덩이(기둥 · 속에 갇힌 그림자 · 부서진 밑동) · 현무암 바위(달아오른 것) · 수정 박힌 바위 · 벽에 붙은 수정 · 천장 수정 · 눈 더미 · 고드름 · 운석 구덩이 · 운석 · 거대한 뼈 · 땅에 박힌 낡은 검 · 로프 건널목 · (+ `a_ruin.py`의 굳은 둔덕 · 광맥 바위) |
| 식생 13 | `a_flora.py` | 활엽수 · 침엽수 · 매마른 가시나무(덩굴 · 잎 · 살아 움직임 · 보랏빛 광채) · 밀림의 거목(옹이구멍) · 검은 불에 타는 나무 · 덤불 · 키 큰 풀 · 가시갈대 · 들꽃 무더기 · 부들 · 그루터기 · 통나무 |
| 구조물 11 | `a_ruin.py` | 폐허 담(모듈 9조각) · 포탈 비석(켜짐 · 돌덩이 · 거대) · 기념비 · 문양 새긴 석문(용기 · 지혜 · 운명 · 인내 · 빛남 · 열림) · 흰 대리석 기둥 · 말뚝 울타리(모듈) · 천막 · 철로 · 광차 · 갱도 버팀목 · 거울 |
| 환경 연출 7 + 함정 1 | `a_fx.py` | 안개(잿빛 · 검은 · 보랏빛 · 푸른) · 은빛 구체 · 흩날리는 입자(눈 · 얼음 가루 · 불티 · 재 · 먼지) · 퍼지는 공간 균열 · 붉은 빛(낙하 예고) · 벼락 줄기 · 즉사 함정 타일 |

**공용 → 지역 확장의 틀**(색만 바꾸지 않는다 — 덩어리의 꼴이 다르다):

| 공용(틀) | 지역 확장형 |
|---|---|
| `rock` 바위 | `rock_sandstone`(지층 켜 · 버섯바위 · 돌문 · 판바위 탑) · `rock_ice`(모난 결정 · 쪼개진 덩이 · 기둥) · `rock_basalt`(육각 기둥 다발 · 달아오른 금) · `rock_crystal`(빛나는 수정) · `ore_vein`(부수는 광맥) |
| `stalactite` 종유석 | `icicles` 고드름 |
| `tree_broadleaf` 활엽수 | `tree_thorn`(가시 · 덩굴 · 4프레임) · `tree_giant`(버팀뿌리 · 옹이구멍) |
| `pillar` 기둥 | `pillar_white`(배흘림 · 홈 · 빛남 · 물에 삭음) |
| `wall_stone` 등 돌 쌓기 벽 | `wall_cave` · `wall_sandstone` · `wall_ice` · `wall_basalt` · `wall_metal`(같은 상태 넷 · 같은 `put_walls`) |
| `floor_*` 실내 바닥 | `ground_*` 야외 바닥(같은 4 × 4칸 넓은 그림 · 같은 `put_floor`) |

## 2. 게임에서 쓰기

```gdscript
var kit := DungeonKit.open()
kit.region_names()                                   # 지역 55곳 — "f3_witch_forest" · "rift_glacier_cave" …
kit.region("f2_land_of_dead")                        # {name_ko, where, lore, src, floor[], wall, assets[], todo}
kit.region_assets("rift_glacier_cave", "terrain")    # ["rock_ice.pillar", "rock_ice.pillar_frozen", …, "icicles", "snow_drift"]
kit.region_assets("f5_hellfire_canyon", "floor")     # ["ground_ash", "ground_lava"]
add_child(kit.make_ref("rock_ice.pillar_frozen"))    # 참조("id" 또는 "id.변형")로 노드 — 변형이 없으면 seed로 고른다
add_child(kit.make_ref("reed_thorn", cell.x * 31 + cell.y))
kit.put_floor(layer, cell, "ground_grass")           # 야외 바닥도 TileSet 소스 0
kit.put_walls(tops, faces, walls, "ice", states)     # 자연 암벽 — 윗면은 종류별(wall_top.ice)로 저절로
kit.reuse_of("tree_thorn")                           # "ext" (틀 = kit.info("tree_thorn")["base"] → "tree_broadleaf")
add_child(kit.build_set("witch_forest"))             # 지역 본보기 세트 11(아래) — 시험 장면
```

- **장식 / 막는 것 / 상호작용 구분**: `kit.info(id)`의 `collide`(없으면 지나간다) · `interact`(portal · door · altar · rope · trap · container · breakable · entrance) · `light` · `meta.states`(idle → active → spent 변형 짝) · `meta.blocks`(닫힌 석문처럼 변형에 따라 가운데가 막힌다) · `meta.cover`(가시갈대 — 막지 않고 시야만 가린다) · `meta.hazard`(용암 · 물 바닥 — 지나갈 수 있는지는 놓는 쪽 지도가 정한다).
- **애니메이션 바닥**(용암 · 물)은 TileSet에 첫 프레임만 실린다. 움직이게 하려면 `kit.texture(id, 변형, 프레임)` 4장을 직접 돌린다(탐험 화면이면 셰이더의 시간 값으로 프레임 고르기 — 타일마다 노드를 만들지 않는다).
- **환경 연출**(`fx`)은 그림 몇 장이 도는 낱 그림이다. 화면에 보이는 칸에만 놓고, `drift`(눈 · 불티)는 2 × 2칸 한 장을 화면 크기만큼만 깐다. 큰 지도 전체에 깔지 않는다(CLAUDE.md 함정 — 화면 둘레 청크만).
- 탐험 화면(`src/explore/view/` — `QuadBatch`)에 넣을 때는 노드를 만들지 말고 `kit.texture()` · `kit.origin()` · `collide`만 꺼내 기존 그리기에 태운다(`DUNGEON_KIT.md` §3). 게임 소품 시트로 옮기는 본보기 = `tools/dungeon_kit/f3_stand.py`.
- **지금 게임 지도에는 새 에셋이 연결되어 있지 않다** — 기존 맵 · 전투 · 저장은 그대로다. 층을 만들 때 그 지역 표에서 꺼내 쓴다.

지역 본보기 세트(`kit.json` `sets` — 설계 `tools/dungeon_kit/sets_wild.py`): `crystal_cave` · `dead_land` · `desert_ruins` · `witch_forest` · `thorn_reeds` · `hellfire` · `ice_cave` · `bone_plain` · `green_mine` · `trial_hall` · `dawn_meadow`.

## 3. 이름 규칙

- id = 영어 소문자 · 밑줄, **무엇인지가 먼저**: `<무엇>[_<재질 · 지역 꼴>]` — `rock_ice` · `tree_thorn` · `pillar_white` · `wall_basalt`. 바닥은 실내 `floor_*` · 야외 `ground_*`, 벽면은 `wall_<종류>`.
- 변형 = 꼴 · 상태 · 순번: `strata_a` · `hoodoo` · `pillar_frozen` · `gate_open` · `mossy` · `a`/`b`/`c`(시드만 다른 것). 상태 짝은 `meta.states`에.
- `name_ko`는 겹치지 않게(검사가 잡는다). 지역 이름을 에셋 이름에 넣지 않는다(`tree_thorn`이지 `witch_tree`가 아니다) — 다른 지역에서도 쓰기 위해서다. 어느 지역 것인지는 지역 표가 말한다.
- 재사용성은 에셋에 적는다: `reuse="ext", base="rock"`(지역 확장형) · `reuse="region"`(지역 전용) · 없으면 공용.

## 4. 새 에셋 · 새 지역 더하기

```
1. tools/dungeon_kit/a_<분류>.py 에 함수 하나(@prop 덩어리 · @flat 평면 · 바닥은 a_ground.py의 @_ground)   — 본보기: a_terrain.py rock_sandstone
2. python3 tools/dungeon_kit/build.py <id 앞머리> --sheet=<png>     그것만 그려 눈으로 본다(묶지 않는다)
3. tools/dungeon_kit/regions.py 의 지역 항목에 id를 적는다(새 지역이면 _r(...) 한 줄)
4. python3 tools/dungeon_kit/build.py                                전부 묶기(바뀐 것만 다시 그린다) → assets/dungeon_kit/
5. python3 tools/dungeon_kit/catalog.py --check                      중복 검사(같은 이름 · 픽셀까지 같은 그림 · 지역에서 안 쓰는 지역 에셋)
6. python3 tools/dungeon_kit/catalog.py                              ASSET_CATALOG.md · REGIONAL_ASSET_PLAN.md 다시 쓰기
7. python3 tools/dungeon_kit/catalog.py --sheets                     docs/screens/asset_library/ 모음 그림 · 세트 그림
8. python3 tools/texture_compress.py → godot --headless --path . --import → kit_demo.gd --set=<세트> 로 엔진에서 확인
```

- **지역 확장형을 만들 때**: 공용 에셋의 도우미를 가져다 쓴다(`from a_nature import _rock, _spike` · `trees.py`의 가지 · 수관 · `kit.palette()` 재질). 재질은 `k.mat(이름, M.stone(색))`으로 갈아 끼우고, **꼴을 바꾸는 손질을 하나 더한다**(`_strata` 지층 · `_hexcol` 육각 기둥 · `shard` 결정 · `cut_above` 부러뜨리기 · `chip` 뜯기).
- **모듈식 구조물**(`ruin_wall` · `palisade` · `mine_track`)은 `meta.module = [폭, 깊이]`칸 조각 — 옆으로 이어 놓고 `corner`로 꺾는다. 새 조각은 변형 하나.
- **새 벽 종류** = `a_wall.py` `KINDS` 한 줄(자연 암벽이면 `"natural"`에 `chunk` · `strata` · `column` · `ice` 가운데 하나, `"moss"` = mossy 상태에 덮이는 것의 색) + `TOPS` 한 줄.
- 빛나는 것은 색 정리 뒤에 얹는다(`post` · `c.graded = False`). 채도는 낮게(ART.md §2) — 용암 · 불꽃도 화면에서 튀지 않게 낮췄다.
- 무작위는 시드뿐이다 — 같은 시드 = 같은 그림. 변형은 시드만 바꾼 것(`a`/`b`)과 꼴이 다른 것(`form`)을 함께 둔다.

## 5. 설정 문서를 다루는 규칙

- 지역 표의 `lore`: **specific**(문서에 생김새가 있다) 26곳 · **partial**(몇 가지만) 24곳 · **none**(이름 · 규칙뿐) 5곳. none인 지역(오크 군락지 · 녹빛꼬리 습지 · 황혼의 비탈길 · 서리 협곡 · 9층 하위 필드 …)의 에셋은 **확장 후보**다 — 확정 설정으로 쓰지 않는다.
- 문서에 없어 지어낸 생김새(가정 AM68): 시련의 문 문양 네 도안 · 대현자의 기념비 꼴 · 포탈 비석 꼴 · 심연의 문(석문으로 대신) · 거울의 테. 원문을 받으면 그 에셋 함수만 고친다.
- 우리 게임의 기획(`docs/CANON.md`)과 설정 문서가 어긋나면 우리 쪽이 이긴다(FL2) — 예: 2층 망자의 땅은 이미 게임에 묘비 · 묘실이 있다.

## 6. 검증 (2026-11-14 클라우드 리눅스)

- `catalog.py --check` 통과(246종 — 같은 이름 · 같은 그림 없음. 처음에 `rift`와 이름이 겹친 새 균열을 잡아 `collapse_crack`으로 나눴다).
- Godot 4.7.2에서 `kit_demo.gd --set=all`: 세트 18개(옛 7 + 지역 11)가 TileSet · 스프라이트 · 애니메이션 · 충돌로 쌓인다. `tests/test_dungeon_kit.gd`가 지역 표 · 재사용성 · 참조로 만들기 · 용암 4프레임 · 수정 광원을 본다.
- 옛 에셋 181종은 다시 구워도 그림이 같다(829장 중 758장 픽셀 일치, 나머지 71장은 테두리 1px — numpy 판이 달라 생긴 차이, 눈으로 같다). 묶음 그림 안의 자리는 바뀌었다(`kit.json`이 가리킨다 — 게임 소품 시트 `assets/floor/kit/props.webp` · 3층 `kit_stand.webp`는 따로 구운 그림이라 그대로).
- **게임 화면(탐험 지도) 안에서의 모습은 확인하지 못했다** — 아직 어느 층에도 연결하지 않았다. 빛은 게임의 빛 계산 몫이라 어둠 속 모습도 층에 넣을 때 본다.
