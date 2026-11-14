"""던전 에셋 키트 — 지역별 에셋 표(에셋 라이브러리 — docs/asset_library/REGIONAL_ASSET_PLAN.md가 이 표에서 나온다).
미궁 설정 문서(사용자 2026-11-14 「겜바바 미궁 설정」)의 층 · 필드 · 균열 · 히든 필드마다 "그 장소에 쓸 수 있는 키트 에셋"을 적는다.
  lore   설정 문서의 외형 묘사 정도: "specific" 구체적 · "partial" 일부 · "none" 이름 · 규칙뿐(= 에셋은 확장 후보 — 확정 설정이 아니다)
  src    문서에 적힌 외형 요소(짧게 — 문서에 없는 것은 쓰지 않는다)
  floor  바닥 타일 id 목록 · wall = 벽 종류(wall_<kind>) · assets = 에셋 id 또는 "id.변형"
  todo   문서에는 있는데 아직 에셋이 없는 것
게임 코드는 DungeonKit.region_assets(지역, 분류)로 꺼낸다. 새 지역 = 여기 한 항목."""

R = {}


def _r(id, name, where, lore, src, floor, wall, assets, todo=""):
    R[id] = {"name_ko": name, "where": where, "lore": lore, "src": src, "floor": floor.split(), "wall": wall, "assets": assets.split(), "todo": todo}


# ── 1층 ──
_r("f1_crystal_cave", "수정동굴", "1층", "partial", "벽 · 천장에 붙은 수정이 광원, 동굴, 급커브, 최외곽 암흑지대",
    "ground_rock floor_dirt", "cave", "crystal_wall crystal_ceiling rock_crystal crystal rock stalagmite stalactite column_natural boulder_mossy rubble gravel puddle moss_patch mushroom ground_crack")
_r("f1_monument", "대현자의 기념비", "1층 최중심부", "partial", "30m 공동의 기념비(기념석), 마석을 올리면 시커먼 포탈",
    "ground_rock.dark", "cave", "monument portal.dormant portal.violet rock stalagmite column_natural", "기념비의 생김새는 문서에 없다(지어낸 꼴)")
_r("f1_basement_gate", "지하 1층 입구", "1층", "partial", "10m 통로에 선 비석 하나(포탈 비석과 같은 꼴), 아래 고대어 글귀",
    "ground_rock", "cave", "portal_stele.idle portal_stele.active wall_writing")
# ── 2층 ──
_r("f2_beast_den", "짐승의 소굴", "2층 동", "partial", "협곡 지형, 갈림길이 많다",
    "ground_rock floor_dirt", "cave", "rock boulder_mossy rubble gravel nest bones ground_crack roots")
_r("f2_land_of_dead", "망자의 땅", "2층 남", "specific", "질척거리는 흑색 대지, 석조 건축물 잔해, 딱딱해지며 둔덕이 진 땅",
    "ground_mud ground_rock.dark", "stone", "mound ruin_wall pillar.broken pillar.fallen pillar.stump rubble wall_ruin arch.ruined skull bones puddle.murky")
_r("f2_rock_desert", "바위사막", "2층 서", "partial", "발밑 모래, 뜨거운 공기, 횃불에 음영을 드리우는 석조 잔해",
    "floor_sand ground_hardpan", "sandstone", "rock_sandstone ruin_wall.sunk ruin_wall.low pillar.fallen pillar.stump rubble drift.dust")
_r("f2_goblin_forest", "고블린 숲", "2층 북", "partial", "별빛, 어디에나 깔린 덫, 포탈 비석 8개(하나가 열리면 나머지는 돌덩이)",
    "ground_forest ground_grass", "cave", "tree_broadleaf bush stump log grass_tall portal_stele.idle portal_stele.active portal_stele.dead tripwire pit_trap spike_trap", "나무 · 바닥 묘사는 문서에 없다")
# ── 3층 ──
_r("f3_steelrock_hill", "강철바위 언덕", "3층", "specific", "고지대 — 산과 들, 강, 울창한 수풀림, 천장까지 이어진 첨탑(원경), 땅에서 떠오르는 은색 빛 구체",
    "ground_grass ground_rock ground_water.clear", "cave", "ledge ramp light_orb tree_broadleaf tree_pine bush grass_tall rock boulder_mossy", "천장까지 이어진 첨탑(원경 — 게임 3층에 이미 실루엣이 있다)")
_r("f3_black_estuary", "칠흑의 강어귀", "3층", "partial", "수십 갈래로 흐르는 옅은 도랑, 거무죽죽한 강어귀",
    "ground_water.black ground_mud ground_swamp", "cave", "cattail puddle.murky roots debris_wood")
_r("f3_sculpture_temple", "조각 사원", "3층", "specific", "무너진 석조 건물 잔해, 목이 부러진 조각상",
    "floor_old floor_broken floor_mossy", "ancient", "ruin_wall statue.headless statue.broken statue.ruined pillar arch.ruined rubble pedestal.broken wall_ruin")
_r("f3_thorn_reeds", "가시갈대 밭", "3층", "specific", "어깨까지 올라오는 가시갈대, 지형지물 없는 평평한 땅",
    "ground_grass.dry floor_dirt", "cave", "reed_thorn")
_r("f3_witch_forest", "마녀의 숲", "3층 중심부", "specific", "매마른 가시나무와 그 위를 휘감은 덩굴, 모든 것이 살아 움직인다, 지형지물은 나무뿐",
    "ground_forest", "cave", "tree_thorn.a tree_thorn.b tree_thorn.c tree_thorn.vined tree_thorn.vined_b tree_thorn.stir roots vines")
_r("f3_witch_hut", "마녀의 오두막", "3층", "specific", "껍질에서 보라색 광채가 나는 나무(입구), 보라색 안개, 들꽃 만개한 잔디밭, 잎이 풍성한 가시나무, 책장 · 식탁 · 카페트 · 난로 / 뒤에는 설원 · 마른 나무 · 눈",
    "ground_meadow ground_snow", "cave", "tree_thorn.glow tree_thorn.leafy mist.violet flowers bookshelf table chair carpet fireplace tree_broadleaf.bare drift.snow snow_drift", "오두막 겉모습")
_r("f3_orc_colony", "오크 군락지", "3층", "none", "(외형 묘사 없음)", "floor_dirt ground_grass.dry", "cave", "palisade tent.hide weapon_rack skull.pike brazier firepit supply_pile", "확장 후보 — 문서에 생김새가 없다")
_r("f3_greentail_swamp", "녹빛꼬리 습지", "3층", "none", "(이름뿐)", "ground_swamp ground_mud", "cave", "cattail grass_tall log.mossy puddle.murky roots", "확장 후보")
_r("f3_twilight_slope", "황혼의 비탈길", "3층", "none", "(이름뿐)", "ground_hardpan floor_sand", "sandstone", "rock_sandstone rubble", "확장 후보")
# ── 4층 ──
_r("f4_sky_tower", "천공의 탑", "4층", "partial", "40평 석실, 벽마다 굳게 닫힌 문에 음각된 문양(용기 · 지혜 · 운명 · 인내), 세 계단, 색이 변하는 포탈, 5층 포탈 스테이지의 포탈 비석, 인내의 계단 끝 상자",
    "floor_flag floor_old", "stone", "sealed_door.courage sealed_door.wisdom sealed_door.fate sealed_door.patience sealed_door.open stairs_up portal.violet portal.blue portal_stele chest torch_wall", "문양 도안은 문서에 없다(지어낸 도안)")
# ── 5층 ──
_r("f5_great_mirror", "대마경", "5층", "specific", "쟁반 모양 넓적한 바위와 끊긴 길, 로프로 넘는 곳, 필드마다 선 거울, 협곡, 절벽에 난 동굴",
    "ground_rock ground_rock.dark", "cave", "rope_crossing great_mirror cliff_drop.cave cliff_lip bridge.rope_h bridge.wood_h rock rubble ground_crack")
_r("f5_start_point", "스타트 포인트", "5층", "partial", "캠핑장 같은 모습, 정육점처럼 내리쬐는 빨간 조명",
    "ground_rock", "cave", "tent bedroll firepit backpack supply_pile magic_lamp.red crate barrel")
_r("f5_hellfire_canyon", "지옥불 협곡", "5층", "specific", "열기, 10m 너비의 길, 용암이 흐르는 낭떠러지",
    "ground_ash ground_lava", "basalt", "rock_basalt cliff_drop.basalt cliff_lip shore_rim drift.ember drift.ash scorch")
_r("f5_frost_canyon", "서리 협곡", "5층", "none", "(이름뿐)", "ground_ice ground_snow", "ice", "rock_ice snow_drift icicles drift.frost", "확장 후보")
_r("f5_wraith_canyon", "망령의 협곡", "5층", "partial", "몇 분마다 땅이 흔들린다", "ground_rock.dark", "cave", "ground_crack rubble rock")
# ── 6층 ──
_r("f6_great_sea", "대해", "6층", "specific", "백색에 가까운 모래사장, 에메랄드빛 바다, 자국이 새겨진 큰 바위, 암초, 붉은 바위섬",
    "ground_beach ground_water.sea ground_water.clear", "sandstone", "reef boat flotsam shore_rim rock rock_sandstone scratches", "유령선 · 마력 추진 장치")
_r("f6_jungle_isle", "아노스섬 · 인간섬(밀림)", "6층 · 지하 1층", "partial", "해안가를 뺀 밀림 / 열대우림, 무릎까지 오는 수풀, 괴상하게 생긴 거대한 나무, 뿌리의 옹이구멍",
    "ground_thicket ground_forest", "cave", "tree_giant grass_tall bush roots vines log.mossy")
_r("f6_treasure_isle", "피오네섬", "6층", "specific", "평평한 들판, 형형색색의 꽃밭", "ground_meadow ground_grass", "cave", "flowers bush.flowering")
_r("f6_arta_isle", "아르타 섬", "6층", "partial", "이상한 기둥 구조물 3개, 제단(피를 바치면 포탈)", "floor_sand ground_rock", "sandstone", "altar.bloody portal", "기둥 구조물의 생김새는 문서에 없다")
# ── 7층 ──
_r("f7_wraith_strait", "원귀의 협곡", "7층 암흑대륙", "specific", "석유가 덮인 듯 검게 물든 바다, 불길하고 음울한 안개", "ground_water.black", "basalt", "mist.grey mist.black boat cliff_drop.basalt")
_r("f7_red_estuary", "아리베오나 강어귀", "7층 암흑대륙", "specific", "드넓은 호수, 벽면에 쏟아지는 폭포, 피를 연상케 하는 적색 물", "ground_water.red ground_rock", "cave", "waterfall.red shore_rim rock cattail")
_r("f7_great_forest", "대수림", "7층 암흑대륙", "partial", "넓은 정글", "ground_thicket", "cave", "tree_giant bush grass_tall vines roots")
_r("f7_pantelion", "판텔리온 유적지", "7층 암흑대륙 · 지하 1층", "partial", "조각 사원과 비슷한 무너진 석조 잔해, 기계 몬스터 / 정글 속 사원 안의 공장(드론 · 레일 · 변환 장치)",
    "floor_old floor_broken", "ancient", "ruin_wall pillar.broken rubble overhead_rail drone_wreck ancient_machine gear_pile mine_track valve_wheel", "드론의 생김새는 문서에 없다(지어낸 꼴)")
_r("f7_grey_field", "회색 벌판", "7층 암흑대륙", "partial", "가뭄철 논밭처럼 벌어진 틈새", "ground_hardpan ground_rock.dark", "cave", "ground_crack.wide ground_crack")
_r("f7_losers_rest", "패자의 안식처", "7층 암흑대륙", "specific", "바람에도 흩어지지 않는 검은 안개, 벌판에 박힌 수만 자루의 낡은 검", "ground_rock.dark ground_ash", "basalt", "planted_sword mist.black broken_weapon")
_r("f7_dragon_depth", "용의 심처", "7층 암흑대륙", "specific", "널린 거대한 척추뼈, 두개골과 뼛조각으로 가득 찬 평야, 빛이 없다", "ground_bones", "cave", "giant_bone skull bones")
_r("f7_icerock", "아이스록", "7층", "partial", "추위, 주기적인 눈보라, 평야지대, 얼음산", "ground_snow ground_ice", "ice", "drift.snow snow_drift rock_ice.snowcap rock_ice.shards_a rock_ice.block tree_pine.snowy bush.snowy")
_r("f7_ice_cave", "얼음 동굴 · 빙하의 눈", "7층 아이스록", "specific", "사방이 유리처럼 투명한 얼음, 미로, 원기둥 싱크홀의 외벽 샛길(나선), 절벽에 난 동굴",
    "ground_ice.clear ground_ice", "ice", "rock_ice icicles rope_crossing cliff_drop.ice cliff_lip", "나선 샛길 · 싱크홀")
# ── 8~10층 ──
_r("f8_dawn_land", "여명의 땅", "8층", "specific", "우뚝 솟은 초록색 동산, 드넓은 초원, 가까이 보이는 균열 포탈", "ground_grass ground_meadow", "cave", "ledge.grass ledge.grass_b ledge.grass_end_l ledge.grass_end_r ramp.grass portal grass_tall flowers bush tree_broadleaf")
_r("f9_star_tomb", "별무덤", "9층", "partial", "운석 낙하 — 위에서 쏟아지는 붉은 빛 → 크레이터 → 벼락 줄기", "ground_rock.dark ground_ash", "basalt", "red_beam crater meteorite lightning")
_r("f9_fields", "태고의 땅 · 옛바위 초원 · 맹독 용암지 · 꿈결 폭포 · 용골산", "9층", "none", "(이름뿐)", "ground_redsoil ground_grass ground_lava.poison", "basalt", "giant_bone rock_basalt", "확장 후보 — 문서에 생김새가 없다")
_r("f10_abyss", "심연", "10층", "partial", "심연의 문, 문 근처에 즐비한 즉사 함정 타일", "floor_flag floor_cracked", "stone", "death_tile sealed_door.plain sealed_door.lit", "심연의 문 생김새는 문서에 없다(석문으로 대신)")
# ── 지하 1층 ──
_r("b1_archive_sea", "기록의 바다 · 석문섬 · 도서관섬", "지하 1층", "specific", "수은 같은 은색 바다, 비석처럼 생긴 거대한 문, 수호자 석상이 늘어선 복도, 원기둥 둘로 선 신전, 천장까지 닿는 책장, 테이블 같은 석판",
    "ground_water.silver floor_flag", "ancient", "sealed_door statue statue_gem pillar_white bookshelf_tall flotsam stone_tablet.glowing stairs_down", "곡선 책장 · 200단 계단")
# ── 균열 ──
_r("rift_bloody_castle", "핏빛성채", "1층 균열", "partial", "시커먼 포탈, 붉은 하늘, 흑빛 성채, 도개교, 핏물이 찬 해자, 가고일 석상", "floor_flag ground_water.red", "stone", "portal.violet gateway doorway.portcullis drawbridge drawbridge_raised crows shore_rim statue_robed magic_circle")
_r("rift_glacier_cave", "빙하굴", "1층 균열", "specific", "얼음 동굴, 일정 간격의 기둥(부술 수 있다), 얼음 계단, 얼음벽, 미끄러운 얼음 지면, 로프로 넘는 곳, 몬스터가 갇힌 얼음 기둥, 천장에서 떨어지는 얼음 가루",
    "ground_ice ground_ice.clear ground_snow.thin", "ice", "rock_ice.pillar rock_ice.pillar_frozen rock_ice.pillar_broken rock_ice icicles drift.frost rope_crossing snow_drift waterfall.clear cliff_drop.ice stairs_ice.ice stairs_ice.ice_cracked ledge.ice ramp.ice")
_r("rift_green_mine", "녹색 탄광", "1층 균열", "specific", "바닥의 철로, 나무 폐자재, 무너져 막힌 천장, 부술 수 있는 벽 너머 초록색 보석, 무너진 다리, 광물, 폭발물",
    "ground_rock floor_dirt", "cave", "mine_track mine_cart mine_support ore_vein bridge.wood_broken bridge.wood_h cliff_drop.cave powder_keg cracked_wall debris_wood rubble wall_breach lantern_hanging", "원형 계단")
_r("rift_steel_tomb", "강철의 묘", "1층 균열", "partial", "어둡고 좁은 복도, 벽화 같은 문양이 새겨진 금속 벽, 함정, 묘실", "floor_flag", "metal", "sarcophagus spear_wall dart_holes pressure_plate blade_trap")
_r("rift_gun_desert", "총포 사막", "2층 균열", "partial", "끝이 보이지 않는 드넓은 사막", "floor_sand ground_hardpan", "sandstone", "rock_sandstone")
_r("rift_white_temple", "백색신전", "3층 균열", "specific", "높은 천장, 새하얀 대리석 기둥, 벽을 따라 선 석상, 석상 손의 푸른 보석에서 안개처럼 퍼지는 빛, 돔 안의 인공 정원(수풀 · 과실이 맺힌 나무)",
    "floor_flag ground_grass", "stone", "pillar_white statue statue_gem.white statue_gem.broken mist.blue tree_broadleaf.fruit grass_tall bush doorway")
_r("rift_doppel_forest", "도플갱어 숲", "4층 균열", "partial", "거대한 철창(창살이 올라간다), 그림자 동굴, 제단, 통로를 막은 덩굴, 숲의 싱크홀, 봉인석",
    "ground_forest ground_rock.dark", "cave", "bars altar vines seal_device chest tree_broadleaf pit_trap")
_r("rift_soul_fortress", "영혼의 요새", "5층 균열", "specific", "세 갈래 미로, 정사각형 석실의 큰 마석, 저택 복도와 상자, 투명한 계단의 피라미드와 눈 모양 마석", "floor_flag floor_brick", "brick", "chest crystal.violet_large pedestal.orb stairs_ice.glass carpet", "저택 복도 · 살덩이 공간")
_r("rift_paradise_isle", "낙원의 섬", "5층 균열", "specific", "흑색 광채의 포탈, 섬 중심부의 빛나는 수정, 수로 같은 인공 지하, 검붉은 샘이 있는 석실, 종유석 가득한 공동",
    "floor_sand floor_cobble floor_wet", "sewer", "portal.violet crystal sewer_outlet stalactite puddle.bloody tree_broadleaf.fruit")
_r("rift_red_dragon", "적룡의 심처", "8층 균열", "partial", "사방이 불에 타오른다, 대리석 재질의 흑색 타일", "ground_ash.ember ground_lava", "basalt", "rock_basalt.molten drift.ember flame_jet", "흑색 대리석 타일")
# ── 히든 필드 ──
_r("hidden_larkaz", "라르카즈의 미로", "4층 히든", "specific", "일자 통로, 벽에 걸린 횃불, 막힌 벽, 바닥의 기하학 문양 마법진, 쇠창살, 기하학 문양이 음각된 석문(빛나며 열린다), 소환 마법진",
    "floor_flag floor_ritual", "stone", "torch_wall magic_circle sealed_door.plain sealed_door.lit doorway.portcullis doorway.bricked skull.pike portal")
_r("hidden_fire_mirror", "불의 거울", "5층 히든", "specific", "거울 너머 세계 — 드넓은 황야, 흑색 불꽃에 싸여 타는 나무(간격이 넓다), 거대한 비석, 검게 그을린 2층 벽돌집",
    "ground_ash ground_hardpan", "basalt", "great_mirror tree_burning burnt_house burnt_furniture portal_stele.giant stump.burnt log.burnt scorch")
_r("hidden_atlante", "아틀란테", "6층 히든", "specific", "물에 잠겨 부식된 유적, 다가가면 빛나는 기둥, 피라미드 구조 사원, 원형으로 선 거대한 기둥", "floor_old floor_wet", "ancient", "pyramid_temple pillar_white.sunken pillar_white.glowing ruin_wall.mossy rubble portal", "푸른 알 · 소용돌이")
_r("hidden_end_memory", "종말의 기억", "6층 히든", "partial", "온 섬이 불타고 용암이 대지에 흐른다", "ground_lava ground_ash.ember", "basalt", "rock_basalt tree_burning.charred drift.ember")
# ── 미궁 공통 ──
_r("common_collapse", "차원 붕괴 · 균열 발생", "모든 층", "specific", "세상에 작게 피어나 거미줄처럼 퍼지는 균열, 땅이 진동하고 생기는 포탈", "floor_flag", "stone", "collapse_crack rift portal ground_crack drift.dust")


def export(manifest):
    """kit.json에 실을 지역 표 — 없는 에셋 · 변형 · 벽 종류를 가리키면 여기서 멈춘다."""
    assets = manifest["assets"]
    for rid, r in R.items():
        assert r["lore"] in ("specific", "partial", "none"), rid
        assert ("wall_" + r["wall"]) in assets, "지역 %s: 없는 벽 %s" % (rid, r["wall"])
        for ref in r["floor"] + r["assets"]:
            aid, _, v = ref.partition(".")
            assert aid in assets, "지역 %s: 없는 에셋 %s" % (rid, aid)
            assert not v or v in assets[aid]["variants"], "지역 %s: %s에 없는 변형 %s" % (rid, aid, v)
        for f in r["floor"]:
            assert assets[f.partition(".")[0]]["layer"] == "floor", "지역 %s: %s는 바닥이 아니다" % (rid, f)
    return R
