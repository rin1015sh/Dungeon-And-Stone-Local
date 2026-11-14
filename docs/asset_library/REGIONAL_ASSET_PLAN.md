# REGIONAL_ASSET_PLAN — 지역별 에셋 묶음

> `python3 tools/dungeon_kit/catalog.py`가 `tools/dungeon_kit/regions.py`에서 만든다 — **손으로 고치지 않는다**(지역을 더하거나 고치려면 regions.py).

미궁 설정 문서(사용자 2026-11-14 「겜바바 미궁 설정」)의 장소마다 쓸 수 있는 키트 에셋. 게임 코드는 `DungeonKit.region_assets(지역 id, 분류)`.

- **묘사 정도**: 구체적 = 문서에 생김새가 적혀 있다 · 일부 = 몇 가지만 · **없음(확장 후보)** = 이름 · 규칙뿐 — 그 지역의 에셋은 임시 후보이고 확정 설정이 아니다(원문을 받으면 고친다).
- 문서에 없는 생김새를 지어낸 곳은 '남은 것' 칸에 적었다. 우리 게임의 기획(`docs/CANON.md`)과 어긋나면 우리 쪽이 이긴다(FL2).

| 묘사 정도 | 지역 수 |
|---|---|
| 구체적 | 26 |
| 일부 | 24 |
| 없음(확장 후보) | 5 |

## 1층

### 수정동굴 (`f1_crystal_cave`) — 1층

- 묘사 정도: **일부** — 벽 · 천장에 붙은 수정이 광원, 동굴, 급커브, 최외곽 암흑지대
- 바닥: `ground_rock` `floor_dirt` · 벽: `wall_cave`
- 지역 확장 · 전용: `crystal_wall` `crystal_ceiling` `rock_crystal`
- 공용: `crystal` `rock` `stalagmite` `stalactite` `column_natural` `boulder_mossy` `rubble` `gravel` `puddle` `moss_patch` `mushroom` `ground_crack`

### 대현자의 기념비 (`f1_monument`) — 1층 최중심부

- 묘사 정도: **일부** — 30m 공동의 기념비(기념석), 마석을 올리면 시커먼 포탈
- 바닥: `ground_rock.dark` · 벽: `wall_cave`
- 지역 확장 · 전용: `monument`
- 공용: `portal.dormant` `portal.violet` `rock` `stalagmite` `column_natural`
- 남은 것: 기념비의 생김새는 문서에 없다(지어낸 꼴)

### 지하 1층 입구 (`f1_basement_gate`) — 1층

- 묘사 정도: **일부** — 10m 통로에 선 비석 하나(포탈 비석과 같은 꼴), 아래 고대어 글귀
- 바닥: `ground_rock` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `portal_stele.idle` `portal_stele.active` `wall_writing`

## 2층

### 짐승의 소굴 (`f2_beast_den`) — 2층 동

- 묘사 정도: **일부** — 협곡 지형, 갈림길이 많다
- 바닥: `ground_rock` `floor_dirt` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `rock` `boulder_mossy` `rubble` `gravel` `nest` `bones` `ground_crack` `roots`

### 망자의 땅 (`f2_land_of_dead`) — 2층 남

- 묘사 정도: **구체적** — 질척거리는 흑색 대지, 석조 건축물 잔해, 딱딱해지며 둔덕이 진 땅
- 바닥: `ground_mud` `ground_rock.dark` · 벽: `wall_stone`
- 지역 확장 · 전용: `mound`
- 공용: `ruin_wall` `pillar.broken` `pillar.fallen` `pillar.stump` `rubble` `wall_ruin` `arch.ruined` `skull` `bones` `puddle.murky`

### 바위사막 (`f2_rock_desert`) — 2층 서

- 묘사 정도: **일부** — 발밑 모래, 뜨거운 공기, 횃불에 음영을 드리우는 석조 잔해
- 바닥: `floor_sand` `ground_hardpan` · 벽: `wall_sandstone`
- 지역 확장 · 전용: `rock_sandstone`
- 공용: `ruin_wall.sunk` `ruin_wall.low` `pillar.fallen` `pillar.stump` `rubble` `drift.dust`

### 고블린 숲 (`f2_goblin_forest`) — 2층 북

- 묘사 정도: **일부** — 별빛, 어디에나 깔린 덫, 포탈 비석 8개(하나가 열리면 나머지는 돌덩이)
- 바닥: `ground_forest` `ground_grass` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `tree_broadleaf` `bush` `stump` `log` `grass_tall` `portal_stele.idle` `portal_stele.active` `portal_stele.dead` `tripwire` `pit_trap` `spike_trap`
- 남은 것: 나무 · 바닥 묘사는 문서에 없다

## 3층

### 강철바위 언덕 (`f3_steelrock_hill`) — 3층

- 묘사 정도: **구체적** — 고지대 — 산과 들, 강, 울창한 수풀림, 천장까지 이어진 첨탑(원경), 땅에서 떠오르는 은색 빛 구체
- 바닥: `ground_grass` `ground_rock` `ground_water.clear` · 벽: `wall_cave`
- 지역 확장 · 전용: `light_orb`
- 공용: `ledge` `ramp` `tree_broadleaf` `tree_pine` `bush` `grass_tall` `rock` `boulder_mossy`
- 남은 것: 천장까지 이어진 첨탑(원경 — 게임 3층에 이미 실루엣이 있다)

### 칠흑의 강어귀 (`f3_black_estuary`) — 3층

- 묘사 정도: **일부** — 수십 갈래로 흐르는 옅은 도랑, 거무죽죽한 강어귀
- 바닥: `ground_water.black` `ground_mud` `ground_swamp` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `cattail` `puddle.murky` `roots` `debris_wood`

### 조각 사원 (`f3_sculpture_temple`) — 3층

- 묘사 정도: **구체적** — 무너진 석조 건물 잔해, 목이 부러진 조각상
- 바닥: `floor_old` `floor_broken` `floor_mossy` · 벽: `wall_ancient`
- 지역 확장 · 전용: —
- 공용: `ruin_wall` `statue.headless` `statue.broken` `statue.ruined` `pillar` `arch.ruined` `rubble` `pedestal.broken` `wall_ruin`

### 가시갈대 밭 (`f3_thorn_reeds`) — 3층

- 묘사 정도: **구체적** — 어깨까지 올라오는 가시갈대, 지형지물 없는 평평한 땅
- 바닥: `ground_grass.dry` `floor_dirt` · 벽: `wall_cave`
- 지역 확장 · 전용: `reed_thorn`
- 공용: —

### 마녀의 숲 (`f3_witch_forest`) — 3층 중심부

- 묘사 정도: **구체적** — 매마른 가시나무와 그 위를 휘감은 덩굴, 모든 것이 살아 움직인다, 지형지물은 나무뿐
- 바닥: `ground_forest` · 벽: `wall_cave`
- 지역 확장 · 전용: `tree_thorn.a` `tree_thorn.b` `tree_thorn.c` `tree_thorn.vined` `tree_thorn.vined_b` `tree_thorn.stir`
- 공용: `roots` `vines`

### 마녀의 오두막 (`f3_witch_hut`) — 3층

- 묘사 정도: **구체적** — 껍질에서 보라색 광채가 나는 나무(입구), 보라색 안개, 들꽃 만개한 잔디밭, 잎이 풍성한 가시나무, 책장 · 식탁 · 카페트 · 난로 / 뒤에는 설원 · 마른 나무 · 눈
- 바닥: `ground_meadow` `ground_snow` · 벽: `wall_cave`
- 지역 확장 · 전용: `tree_thorn.glow` `tree_thorn.leafy`
- 공용: `mist.violet` `flowers` `bookshelf` `table` `chair` `carpet` `fireplace` `tree_broadleaf.bare` `drift.snow` `snow_drift`
- 남은 것: 오두막 겉모습

### 오크 군락지 (`f3_orc_colony`) — 3층

- 묘사 정도: **없음(확장 후보)** — (외형 묘사 없음)
- 바닥: `floor_dirt` `ground_grass.dry` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `palisade` `tent.hide` `weapon_rack` `skull.pike` `brazier` `firepit` `supply_pile`
- 남은 것: 확장 후보 — 문서에 생김새가 없다

### 녹빛꼬리 습지 (`f3_greentail_swamp`) — 3층

- 묘사 정도: **없음(확장 후보)** — (이름뿐)
- 바닥: `ground_swamp` `ground_mud` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `cattail` `grass_tall` `log.mossy` `puddle.murky` `roots`
- 남은 것: 확장 후보

### 황혼의 비탈길 (`f3_twilight_slope`) — 3층

- 묘사 정도: **없음(확장 후보)** — (이름뿐)
- 바닥: `ground_hardpan` `floor_sand` · 벽: `wall_sandstone`
- 지역 확장 · 전용: `rock_sandstone`
- 공용: `rubble`
- 남은 것: 확장 후보

## 4층

### 천공의 탑 (`f4_sky_tower`) — 4층

- 묘사 정도: **일부** — 40평 석실, 벽마다 굳게 닫힌 문에 음각된 문양(용기 · 지혜 · 운명 · 인내), 세 계단, 색이 변하는 포탈, 5층 포탈 스테이지의 포탈 비석, 인내의 계단 끝 상자
- 바닥: `floor_flag` `floor_old` · 벽: `wall_stone`
- 지역 확장 · 전용: —
- 공용: `sealed_door.courage` `sealed_door.wisdom` `sealed_door.fate` `sealed_door.patience` `sealed_door.open` `stairs_up` `portal.violet` `portal.blue` `portal_stele` `chest` `torch_wall`
- 남은 것: 문양 도안은 문서에 없다(지어낸 도안)

## 5층

### 대마경 (`f5_great_mirror`) — 5층

- 묘사 정도: **구체적** — 쟁반 모양 넓적한 바위와 끊긴 길, 로프로 넘는 곳, 필드마다 선 거울, 협곡, 절벽에 난 동굴
- 바닥: `ground_rock` `ground_rock.dark` · 벽: `wall_cave`
- 지역 확장 · 전용: `great_mirror`
- 공용: `rope_crossing` `cliff_drop.cave` `cliff_lip` `bridge.rope_h` `bridge.wood_h` `rock` `rubble` `ground_crack`

### 스타트 포인트 (`f5_start_point`) — 5층

- 묘사 정도: **일부** — 캠핑장 같은 모습, 정육점처럼 내리쬐는 빨간 조명
- 바닥: `ground_rock` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `tent` `bedroll` `firepit` `backpack` `supply_pile` `magic_lamp.red` `crate` `barrel`

### 지옥불 협곡 (`f5_hellfire_canyon`) — 5층

- 묘사 정도: **구체적** — 열기, 10m 너비의 길, 용암이 흐르는 낭떠러지
- 바닥: `ground_ash` `ground_lava` · 벽: `wall_basalt`
- 지역 확장 · 전용: `rock_basalt`
- 공용: `cliff_drop.basalt` `cliff_lip` `shore_rim` `drift.ember` `drift.ash` `scorch`

### 서리 협곡 (`f5_frost_canyon`) — 5층

- 묘사 정도: **없음(확장 후보)** — (이름뿐)
- 바닥: `ground_ice` `ground_snow` · 벽: `wall_ice`
- 지역 확장 · 전용: `rock_ice` `icicles`
- 공용: `snow_drift` `drift.frost`
- 남은 것: 확장 후보

### 망령의 협곡 (`f5_wraith_canyon`) — 5층

- 묘사 정도: **일부** — 몇 분마다 땅이 흔들린다
- 바닥: `ground_rock.dark` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `ground_crack` `rubble` `rock`

## 6층

### 대해 (`f6_great_sea`) — 6층

- 묘사 정도: **구체적** — 백색에 가까운 모래사장, 에메랄드빛 바다, 자국이 새겨진 큰 바위, 암초, 붉은 바위섬
- 바닥: `ground_beach` `ground_water.sea` `ground_water.clear` · 벽: `wall_sandstone`
- 지역 확장 · 전용: `reef` `boat` `rock_sandstone`
- 공용: `flotsam` `shore_rim` `rock` `scratches`
- 남은 것: 유령선 · 마력 추진 장치

### 아노스섬 · 인간섬(밀림) (`f6_jungle_isle`) — 6층 · 지하 1층

- 묘사 정도: **일부** — 해안가를 뺀 밀림 / 열대우림, 무릎까지 오는 수풀, 괴상하게 생긴 거대한 나무, 뿌리의 옹이구멍
- 바닥: `ground_thicket` `ground_forest` · 벽: `wall_cave`
- 지역 확장 · 전용: `tree_giant`
- 공용: `grass_tall` `bush` `roots` `vines` `log.mossy`

### 피오네섬 (`f6_treasure_isle`) — 6층

- 묘사 정도: **구체적** — 평평한 들판, 형형색색의 꽃밭
- 바닥: `ground_meadow` `ground_grass` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `flowers` `bush.flowering`

### 아르타 섬 (`f6_arta_isle`) — 6층

- 묘사 정도: **일부** — 이상한 기둥 구조물 3개, 제단(피를 바치면 포탈)
- 바닥: `floor_sand` `ground_rock` · 벽: `wall_sandstone`
- 지역 확장 · 전용: —
- 공용: `altar.bloody` `portal`
- 남은 것: 기둥 구조물의 생김새는 문서에 없다

## 7층

### 원귀의 협곡 (`f7_wraith_strait`) — 7층 암흑대륙

- 묘사 정도: **구체적** — 석유가 덮인 듯 검게 물든 바다, 불길하고 음울한 안개
- 바닥: `ground_water.black` · 벽: `wall_basalt`
- 지역 확장 · 전용: `boat`
- 공용: `mist.grey` `mist.black` `cliff_drop.basalt`

### 아리베오나 강어귀 (`f7_red_estuary`) — 7층 암흑대륙

- 묘사 정도: **구체적** — 드넓은 호수, 벽면에 쏟아지는 폭포, 피를 연상케 하는 적색 물
- 바닥: `ground_water.red` `ground_rock` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `waterfall.red` `shore_rim` `rock` `cattail`

### 대수림 (`f7_great_forest`) — 7층 암흑대륙

- 묘사 정도: **일부** — 넓은 정글
- 바닥: `ground_thicket` · 벽: `wall_cave`
- 지역 확장 · 전용: `tree_giant`
- 공용: `bush` `grass_tall` `vines` `roots`

### 판텔리온 유적지 (`f7_pantelion`) — 7층 암흑대륙 · 지하 1층

- 묘사 정도: **일부** — 조각 사원과 비슷한 무너진 석조 잔해, 기계 몬스터 / 정글 속 사원 안의 공장(드론 · 레일 · 변환 장치)
- 바닥: `floor_old` `floor_broken` · 벽: `wall_ancient`
- 지역 확장 · 전용: `overhead_rail` `drone_wreck` `mine_track`
- 공용: `ruin_wall` `pillar.broken` `rubble` `ancient_machine` `gear_pile` `valve_wheel`
- 남은 것: 드론의 생김새는 문서에 없다(지어낸 꼴)

### 회색 벌판 (`f7_grey_field`) — 7층 암흑대륙

- 묘사 정도: **일부** — 가뭄철 논밭처럼 벌어진 틈새
- 바닥: `ground_hardpan` `ground_rock.dark` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `ground_crack.wide` `ground_crack`

### 패자의 안식처 (`f7_losers_rest`) — 7층 암흑대륙

- 묘사 정도: **구체적** — 바람에도 흩어지지 않는 검은 안개, 벌판에 박힌 수만 자루의 낡은 검
- 바닥: `ground_rock.dark` `ground_ash` · 벽: `wall_basalt`
- 지역 확장 · 전용: `planted_sword`
- 공용: `mist.black` `broken_weapon`

### 용의 심처 (`f7_dragon_depth`) — 7층 암흑대륙

- 묘사 정도: **구체적** — 널린 거대한 척추뼈, 두개골과 뼛조각으로 가득 찬 평야, 빛이 없다
- 바닥: `ground_bones` · 벽: `wall_cave`
- 지역 확장 · 전용: `giant_bone`
- 공용: `skull` `bones`

### 아이스록 (`f7_icerock`) — 7층

- 묘사 정도: **일부** — 추위, 주기적인 눈보라, 평야지대, 얼음산
- 바닥: `ground_snow` `ground_ice` · 벽: `wall_ice`
- 지역 확장 · 전용: `rock_ice.snowcap` `rock_ice.shards_a` `rock_ice.block`
- 공용: `drift.snow` `snow_drift` `tree_pine.snowy` `bush.snowy`

### 얼음 동굴 · 빙하의 눈 (`f7_ice_cave`) — 7층 아이스록

- 묘사 정도: **구체적** — 사방이 유리처럼 투명한 얼음, 미로, 원기둥 싱크홀의 외벽 샛길(나선), 절벽에 난 동굴
- 바닥: `ground_ice.clear` `ground_ice` · 벽: `wall_ice`
- 지역 확장 · 전용: `rock_ice` `icicles`
- 공용: `rope_crossing` `cliff_drop.ice` `cliff_lip`
- 남은 것: 나선 샛길 · 싱크홀

## 8층

### 여명의 땅 (`f8_dawn_land`) — 8층

- 묘사 정도: **구체적** — 우뚝 솟은 초록색 동산, 드넓은 초원, 가까이 보이는 균열 포탈
- 바닥: `ground_grass` `ground_meadow` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `ledge.grass` `ledge.grass_b` `ledge.grass_end_l` `ledge.grass_end_r` `ramp.grass` `portal` `grass_tall` `flowers` `bush` `tree_broadleaf`

## 9층

### 별무덤 (`f9_star_tomb`) — 9층

- 묘사 정도: **일부** — 운석 낙하 — 위에서 쏟아지는 붉은 빛 → 크레이터 → 벼락 줄기
- 바닥: `ground_rock.dark` `ground_ash` · 벽: `wall_basalt`
- 지역 확장 · 전용: `red_beam` `crater` `meteorite` `lightning`
- 공용: —

### 태고의 땅 · 옛바위 초원 · 맹독 용암지 · 꿈결 폭포 · 용골산 (`f9_fields`) — 9층

- 묘사 정도: **없음(확장 후보)** — (이름뿐)
- 바닥: `ground_redsoil` `ground_grass` `ground_lava.poison` · 벽: `wall_basalt`
- 지역 확장 · 전용: `giant_bone` `rock_basalt`
- 공용: —
- 남은 것: 확장 후보 — 문서에 생김새가 없다

## 10층

### 심연 (`f10_abyss`) — 10층

- 묘사 정도: **일부** — 심연의 문, 문 근처에 즐비한 즉사 함정 타일
- 바닥: `floor_flag` `floor_cracked` · 벽: `wall_stone`
- 지역 확장 · 전용: `death_tile`
- 공용: `sealed_door.plain` `sealed_door.lit`
- 남은 것: 심연의 문 생김새는 문서에 없다(석문으로 대신)

## 지하 1층

### 기록의 바다 · 석문섬 · 도서관섬 (`b1_archive_sea`) — 지하 1층

- 묘사 정도: **구체적** — 수은 같은 은색 바다, 비석처럼 생긴 거대한 문, 수호자 석상이 늘어선 복도, 원기둥 둘로 선 신전, 천장까지 닿는 책장, 테이블 같은 석판
- 바닥: `ground_water.silver` `floor_flag` · 벽: `wall_ancient`
- 지역 확장 · 전용: `statue_gem` `pillar_white` `bookshelf_tall`
- 공용: `sealed_door` `statue` `flotsam` `stone_tablet.glowing` `stairs_down`
- 남은 것: 곡선 책장 · 200단 계단

## 균열

### 핏빛성채 (`rift_bloody_castle`) — 1층 균열

- 묘사 정도: **일부** — 시커먼 포탈, 붉은 하늘, 흑빛 성채, 도개교, 핏물이 찬 해자, 가고일 석상
- 바닥: `floor_flag` `ground_water.red` · 벽: `wall_stone`
- 지역 확장 · 전용: `drawbridge` `drawbridge_raised` `crows`
- 공용: `portal.violet` `gateway` `doorway.portcullis` `shore_rim` `statue_robed` `magic_circle`

### 빙하굴 (`rift_glacier_cave`) — 1층 균열

- 묘사 정도: **구체적** — 얼음 동굴, 일정 간격의 기둥(부술 수 있다), 얼음 계단, 얼음벽, 미끄러운 얼음 지면, 로프로 넘는 곳, 몬스터가 갇힌 얼음 기둥, 천장에서 떨어지는 얼음 가루
- 바닥: `ground_ice` `ground_ice.clear` `ground_snow.thin` · 벽: `wall_ice`
- 지역 확장 · 전용: `rock_ice.pillar` `rock_ice.pillar_frozen` `rock_ice.pillar_broken` `rock_ice` `icicles` `stairs_ice.ice` `stairs_ice.ice_cracked`
- 공용: `drift.frost` `rope_crossing` `snow_drift` `waterfall.clear` `cliff_drop.ice` `ledge.ice` `ramp.ice`

### 녹색 탄광 (`rift_green_mine`) — 1층 균열

- 묘사 정도: **구체적** — 바닥의 철로, 나무 폐자재, 무너져 막힌 천장, 부술 수 있는 벽 너머 초록색 보석, 무너진 다리, 광물, 폭발물
- 바닥: `ground_rock` `floor_dirt` · 벽: `wall_cave`
- 지역 확장 · 전용: `mine_track` `mine_cart` `mine_support` `ore_vein`
- 공용: `bridge.wood_broken` `bridge.wood_h` `cliff_drop.cave` `powder_keg` `cracked_wall` `debris_wood` `rubble` `wall_breach` `lantern_hanging`
- 남은 것: 원형 계단

### 강철의 묘 (`rift_steel_tomb`) — 1층 균열

- 묘사 정도: **일부** — 어둡고 좁은 복도, 벽화 같은 문양이 새겨진 금속 벽, 함정, 묘실
- 바닥: `floor_flag` · 벽: `wall_metal`
- 지역 확장 · 전용: —
- 공용: `sarcophagus` `spear_wall` `dart_holes` `pressure_plate` `blade_trap`

### 총포 사막 (`rift_gun_desert`) — 2층 균열

- 묘사 정도: **일부** — 끝이 보이지 않는 드넓은 사막
- 바닥: `floor_sand` `ground_hardpan` · 벽: `wall_sandstone`
- 지역 확장 · 전용: `rock_sandstone`
- 공용: —

### 백색신전 (`rift_white_temple`) — 3층 균열

- 묘사 정도: **구체적** — 높은 천장, 새하얀 대리석 기둥, 벽을 따라 선 석상, 석상 손의 푸른 보석에서 안개처럼 퍼지는 빛, 돔 안의 인공 정원(수풀 · 과실이 맺힌 나무)
- 바닥: `floor_flag` `ground_grass` · 벽: `wall_stone`
- 지역 확장 · 전용: `pillar_white` `statue_gem.white` `statue_gem.broken`
- 공용: `statue` `mist.blue` `tree_broadleaf.fruit` `grass_tall` `bush` `doorway`

### 도플갱어 숲 (`rift_doppel_forest`) — 4층 균열

- 묘사 정도: **일부** — 거대한 철창(창살이 올라간다), 그림자 동굴, 제단, 통로를 막은 덩굴, 숲의 싱크홀, 봉인석
- 바닥: `ground_forest` `ground_rock.dark` · 벽: `wall_cave`
- 지역 확장 · 전용: —
- 공용: `bars` `altar` `vines` `seal_device` `chest` `tree_broadleaf` `pit_trap`

### 영혼의 요새 (`rift_soul_fortress`) — 5층 균열

- 묘사 정도: **구체적** — 세 갈래 미로, 정사각형 석실의 큰 마석, 저택 복도와 상자, 투명한 계단의 피라미드와 눈 모양 마석
- 바닥: `floor_flag` `floor_brick` · 벽: `wall_brick`
- 지역 확장 · 전용: `stairs_ice.glass`
- 공용: `chest` `crystal.violet_large` `pedestal.orb` `carpet`
- 남은 것: 저택 복도 · 살덩이 공간

### 낙원의 섬 (`rift_paradise_isle`) — 5층 균열

- 묘사 정도: **구체적** — 흑색 광채의 포탈, 섬 중심부의 빛나는 수정, 수로 같은 인공 지하, 검붉은 샘이 있는 석실, 종유석 가득한 공동
- 바닥: `floor_sand` `floor_cobble` `floor_wet` · 벽: `wall_sewer`
- 지역 확장 · 전용: —
- 공용: `portal.violet` `crystal` `sewer_outlet` `stalactite` `puddle.bloody` `tree_broadleaf.fruit`

### 적룡의 심처 (`rift_red_dragon`) — 8층 균열

- 묘사 정도: **일부** — 사방이 불에 타오른다, 대리석 재질의 흑색 타일
- 바닥: `ground_ash.ember` `ground_lava` · 벽: `wall_basalt`
- 지역 확장 · 전용: `rock_basalt.molten`
- 공용: `drift.ember` `flame_jet`
- 남은 것: 흑색 대리석 타일

## 히든 필드

### 라르카즈의 미로 (`hidden_larkaz`) — 4층 히든

- 묘사 정도: **구체적** — 일자 통로, 벽에 걸린 횃불, 막힌 벽, 바닥의 기하학 문양 마법진, 쇠창살, 기하학 문양이 음각된 석문(빛나며 열린다), 소환 마법진
- 바닥: `floor_flag` `floor_ritual` · 벽: `wall_stone`
- 지역 확장 · 전용: —
- 공용: `torch_wall` `magic_circle` `sealed_door.plain` `sealed_door.lit` `doorway.portcullis` `doorway.bricked` `skull.pike` `portal`

### 불의 거울 (`hidden_fire_mirror`) — 5층 히든

- 묘사 정도: **구체적** — 거울 너머 세계 — 드넓은 황야, 흑색 불꽃에 싸여 타는 나무(간격이 넓다), 거대한 비석, 검게 그을린 2층 벽돌집
- 바닥: `ground_ash` `ground_hardpan` · 벽: `wall_basalt`
- 지역 확장 · 전용: `great_mirror` `tree_burning` `burnt_house`
- 공용: `burnt_furniture` `portal_stele.giant` `stump.burnt` `log.burnt` `scorch`

### 아틀란테 (`hidden_atlante`) — 6층 히든

- 묘사 정도: **구체적** — 물에 잠겨 부식된 유적, 다가가면 빛나는 기둥, 피라미드 구조 사원, 원형으로 선 거대한 기둥
- 바닥: `floor_old` `floor_wet` · 벽: `wall_ancient`
- 지역 확장 · 전용: `pyramid_temple` `pillar_white.sunken` `pillar_white.glowing`
- 공용: `ruin_wall.mossy` `rubble` `portal`
- 남은 것: 푸른 알 · 소용돌이

### 종말의 기억 (`hidden_end_memory`) — 6층 히든

- 묘사 정도: **일부** — 온 섬이 불타고 용암이 대지에 흐른다
- 바닥: `ground_lava` `ground_ash.ember` · 벽: `wall_basalt`
- 지역 확장 · 전용: `rock_basalt` `tree_burning.charred`
- 공용: `drift.ember`

## 미궁 공통

### 차원 붕괴 · 균열 발생 (`common_collapse`) — 모든 층

- 묘사 정도: **구체적** — 세상에 작게 피어나 거미줄처럼 퍼지는 균열, 땅이 진동하고 생기는 포탈
- 바닥: `floor_flag` · 벽: `wall_stone`
- 지역 확장 · 전용: —
- 공용: `collapse_crack` `rift` `portal` `ground_crack` `drift.dust`

