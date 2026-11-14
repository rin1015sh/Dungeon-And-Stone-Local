#!/usr/bin/env python3
"""3층 '순례자의 길' 타일(data/tiles.json — id가 f3_로 시작하는 것)을 만든다(몇 번 돌려도 같다 — f3_ 타일을 지우고 다시 넣는다).
그림은 1 · 2층 재질 아틀라스 · 소품 시트를 다시 쓴다(지역 구분은 층 art.macro 색조 · 메움 지형 · 소품 · 큰 구조물로 — 새 재질 그림은 아직 없다).
소품(서 있는 그림)은 3층 바닥 위에 서도록 under를 3층 바닥 id로 바꾼 사본을 둔다(FieldsRoute.under_ok — 같은 id면 늘 맞는다).
  python3 tools/f3_tiles.py
[창작] 임시값."""
import copy
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH = os.path.join(ROOT, "data", "tiles.json")
A = "res://assets/floor/"


def floor(tid, name, atlas, color, walk=True, sight=False, move=None, sunk=False, smooth=False, fringe=4, style=None, span=True, battle=None, notes="", **extra):
    art = {"atlas": A + atlas, "variants": 6}
    if span:
        art.update({"span": 4, "fringe": fringe})
        if style:
            art["fringe_style"] = style
    if sunk or smooth:
        art["shape"] = "smooth"
    if sunk:
        art["sunk"] = True
    t = {"id": tid, "name_ko": name, "kind": "floor", "walkable": walk, "blocks_sight": sight, "colors": {"floor": color}, "art": art,
         "source": "placeholder", "notes": "3층 순례자의 길 — " + notes}
    if move:
        t["move_mult"] = move
    if battle:
        t["battle"] = battle
    t.update(extra)
    return t


def wall(tid, name, atlas, top, face, sight=False, face_px=40, notes="", **extra):
    t = {"id": tid, "name_ko": name, "kind": "wall", "walkable": False, "blocks_sight": sight, "colors": {"top": top, "face": face},
         "art": {"atlas": A + atlas, "variants": 6, "shape": "round", "doors": ["none"], "top_tex": True}, "face_px": face_px,
         "source": "placeholder", "notes": "3층 순례자의 길 — " + notes}
    t.update(extra)
    return t


def prop(tid, src, under, name=None, notes="", **extra):
    t = copy.deepcopy(SRC[src])
    t["id"] = tid
    if name:
        t["name_ko"] = name
    if under:
        t["art"]["stand"]["under"] = under
    t["source"] = "placeholder"
    t["notes"] = "3층 순례자의 길 — %s 그림(%s)%s" % (SRC[src]["name_ko"], src, (" · " + notes) if notes else "")
    t.update(extra)
    return t


def spot(tid, src, atlas, color, name=None, notes="", **extra):
    """동굴 요소 · 상호작용 칸(바닥 + 1층 소품 그림): src의 prop을 그대로, 바닥 그림만 3층 바닥으로."""
    t = copy.deepcopy(SRC[src])
    t["id"] = tid
    if name:
        t["name_ko"] = name
    t["art"]["atlas"] = A + atlas
    t["colors"]["floor"] = color
    t["source"] = "placeholder"
    t["notes"] = "3층 순례자의 길 — " + notes
    t.update(extra)
    return t


def tiles():
    out = [
        # ── 공통 ──
        {"id": "f3_rise", "name_ko": "솟은 바위산", "kind": "floor", "walkable": False, "blocks_sight": False, "colors": {"floor": "#262629"},
         "void": True, "rise": True, "source": "original", "notes": "3층 바깥 둘레 · 바위 고지(솟은 외곽 — 그림은 층 art.abyss.rise)"},
        spot("f3_portal_up", "f2_portal_up", "f2d/flagstone.webp", "#5e6269", name="4층 포탈", notes="중심부 첨탑 아래 4층 포탈(4층이 없어 지금은 잠김)"),
        spot("f3_stone_down", "f2_stone_down", "f2d/flagstone.webp", "#5e6269", name="내려가는 비석", notes="도착 비석 — 올라온 2층으로"),
        # ── 강철바위 언덕 · 바람결 고개 ──
        floor("f3_hill_grass", "언덕 풀밭", "f3/steelgrass.webp", "#56663e", fringe=6, style=1, notes="강철바위 언덕 풀밭"),
        floor("f3_hill_rock", "바위 언덕", "f3/steelrock.webp", "#5c5f66", notes="강철바위 언덕 · 바람결 고개의 굳은 바위 땅"),
        floor("f3_hill_low", "언덕 아래 땅", "f3/steelrock.webp", "#4e5056", sunk=True, notes="언덕 아래 낮은 땅(절벽 밑 — 비탈로 드나든다)"),
        floor("f3_river", "흐르는 강", "f2g/brook.webp", "#2e4a50", move=0.55, smooth=True, span=False, battle="water", notes="강철바위 언덕을 흐르는 강(얕은 여울 — 걸을 수 있고 느리다)"),
        floor("f3_hill_scree", "절벽 밑 돌무더기", "f2d/rubble.webp", "#45474d", walk=False, sunk=True, fringe=2, style=2, notes="높은 땅과 맞닿은 낮은 칸(걷지 못함)"),
        floor("f3_hill_slope", "바위 비탈", "f2d/stairs.webp", "#55585e", span=False, ramp_art=True, notes="높낮이 사이 비탈"),
        # ── 오크 군락지 ──
        floor("f3_orc_ground", "짓밟힌 야영지", "f2g/trampled.webp", "#574634", move=0.9, battle="mud", notes="오크 군락지 바닥(짚 · 뼈 · 발자국)"),
        floor("f3_orc_earth", "군락지 외곽 흙", "f2d/dryearth.webp", "#5a5450", notes="오크 군락지 외곽(경계 시설 · 사냥터)"),
        wall("f3_orc_bank", "흙 둔덕", "f2d/bank.webp", "#3a3530", "#5a5048", notes="오크 군락지 길 밖(메움)"),
        # ── 칠흑의 강어귀 · 마른 강바닥 ──
        floor("f3_black_water", "검은 물", "f2d/blackwater.webp", "#33363b", walk=False, span=False, sunk=True, notes="칠흑의 강어귀 깊은 물(넘을 수 없다)"),
        floor("f3_ditch", "얕은 도랑", "f2d/flood.webp", "#3c3f44", move=0.45, span=False, smooth=True, battle="water", notes="강어귀의 얕은 검은 도랑(건널 수 있지만 느리다)"),
        floor("f3_estuary_mud", "썩은 뻘", "f2d/mudroad.webp", "#3f4044", move=0.8, fringe=3, battle="mud", notes="강어귀 둑의 뻘(악취)"),
        floor("f3_estuary_bank", "검은 둑", "f2d/dryearth.webp", "#45464b", notes="강어귀 둑 위 굳은 땅"),
        floor("f3_riverbed", "마른 강바닥", "f2g/pebbles.webp", "#5a5a50", fringe=2, style=2, notes="마른 강바닥 자갈"),
        # ── 녹빛꼬리 습지 ──
        floor("f3_marsh_floor", "이끼 진흙", "f3/marshfloor.webp", "#3f5230", move=0.85, fringe=5, style=1, notes="녹빛꼬리 습지 바닥"),
        floor("f3_marsh_water", "고인 물", "f2g/brook.webp", "#2e5040", move=0.5, span=False, smooth=True, battle="water", notes="녹빛꼬리 습지의 고인 물(걸을 수 있고 느리다)"),
        wall("f3_marsh_thicket", "뿌리 덤불", "f2g/undergrowth.webp", "#2c4a24", "#42382a", notes="녹빛꼬리 습지 길 밖(뿌리 · 덤불 둔덕)"),
        # ── 조각 사원 ──
        floor("f3_temple_floor", "깨진 사원 판석", "f2d/flagstone.webp", "#64666c", fringe=1, style=2, notes="조각 사원 바닥"),
        floor("f3_temple_grass", "사원 뜰", "f2d/graveearth.webp", "#585a5e", fringe=5, style=1, notes="조각 사원 무너진 뜰"),
        wall("f3_temple_wall", "무너진 석벽", "f2d/masonry.webp", "#585a62", "#686b74", sight=True, face_px=48, notes="조각 사원 무너진 벽 · 회랑"),
        # ── 가시갈대 밭 ──
        floor("f3_reed_path", "갈대 사이 흙길", "f3/reedground.webp", "#5a5a3a", fringe=6, style=1, notes="가시갈대 밭 좁은 길"),
        floor("f3_reed_thin", "성긴 갈대", "f3/reeds_floor.webp", "#5e5c3a", sight=True, move=0.8, fringe=6, style=1,
              notes="가시갈대 밭 — 헤치고 지나갈 수 있지만 시야를 가린다(어깨 높이)", cover=True),
        wall("f3_reed_wall", "가시갈대", "f3/reeds.webp", "#5a5634", "#4a4430", sight=True, face_px=40, notes="어깨 높이 가시갈대 숲(지나갈 수 없다 · 시야를 가린다)"),
        # ── 황혼의 비탈길 ──
        floor("f3_dusk_ground", "황혼 비탈", "f3/duskearth.webp", "#6a5650", notes="황혼의 비탈길 바위 땅"),
        floor("f3_dusk_low", "비탈 아래 협곡", "f3/duskearth.webp", "#584844", sunk=True, notes="황혼의 비탈길 낮은 협곡(절벽 아래)"),
        # ── 마녀의 숲 · 중심부 ──
        floor("f3_witch_floor", "마른 가시 숲 바닥", "f3/witchearth.webp", "#4e4a56", fringe=5, style=1, notes="마녀의 숲 바닥(마른 잎 · 엉킨 뿌리)"),
        floor("f3_witch_root", "엉킨 뿌리", "f3/witchroot.webp", "#46404e", move=0.75, fringe=5, style=1, notes="마녀의 숲 — 뿌리가 길을 덮은 곳(느리다)"),
        wall("f3_witch_thicket", "뒤엉킨 가시덩굴", "f3/thorns.webp", "#2c2834", "#3c3444", notes="마녀의 숲 길 밖(덩굴 · 가시 둔덕) — 그 위에 마른 거목"),
        floor("f3_heart_floor", "첨탑 앞 판석", "f2d/flagstone.webp", "#5e6068", fringe=1, style=2, notes="중심부 첨탑 앞 판석"),
        # ── 마녀의 오두막(따로 된 방) ──
        floor("f3_hut_meadow", "들꽃 잔디밭", "f2g/clearing.webp", "#5e7a40", fringe=6, style=1, notes="마녀의 오두막 바깥 — 들꽃이 핀 잔디밭"),
        floor("f3_hut_floor", "오두막 바닥", "f2d/flagstone.webp", "#6a645c", fringe=1, style=2, notes="마녀의 오두막 안 바닥"),
        floor("f3_hut_carpet", "오두막 카펫", "it/carpet.webp", "#6a3a3a", span=False, notes="마녀의 오두막 카펫"),
        wall("f3_hut_wall", "오두막 벽", "f2d/masonry.webp", "#5a5048", "#6e6052", sight=True, face_px=48, notes="마녀의 오두막 벽"),
        floor("f3_hut_snow", "눈밭", "gc/snow.webp", "#c8ccd4", span=False, notes="리아키스가 쓰러진 뒤의 오두막 바깥(설원)"),
        {"id": "f3_hut_mist", "name_ko": "보랏빛 안개", "kind": "floor", "walkable": True, "blocks_sight": False, "interact": "hut_exit",
         "colors": {"floor": "#5a4a6a", "mark": "#c8a0ff"}, "light": {"radius_m": 2.5, "color": "#b080ff", "intensity": 0.8},
         "art": {"atlas": A + "f2g/clearing.webp", "variants": 6, "span": 4, "fringe": 6, "fringe_style": 1},
         "source": "placeholder", "notes": "3층 순례자의 길 — 오두막 들판 끝의 안개(살피면 숲으로 나간다)"},
    ]
    # 소품: 서 있는 그림 사본(밑 바닥 = 3층 바닥)
    out += [
        prop("f3_hill_boulder", "f2d_rock", "f3_hill_rock", name="바위 군락"),
        prop("f3_hill_boulder_d", "f2d_rock", "f3_dusk_ground", name="바위 기둥", notes="황혼의 비탈길 — 시야를 가리는 바위", blocks_sight=True),
        prop("f3_hill_pine", "f2g_pine_g", "f3_hill_grass", name="전나무"),
        prop("f3_hill_oak", "f2g_oak_g", "f3_hill_grass", name="수풀림 나무"),
        prop("f3_hill_bush", "f2d_bush", None, name="덤불"),
        prop("f3_orc_tent_post", "f2g_totem", "f3_orc_ground", name="오크 토템"),
        prop("f3_orc_stakes", "f2g_stakes", "f3_orc_ground", name="목재 방벽"),
        prop("f3_orc_palisade", "f2d_palisade", "f3_orc_earth", name="목재 방벽"),
        prop("f3_orc_barricade", "f2d_barricade", "f3_orc_earth", name="경계 방책"),
        prop("f3_orc_armor", "f2d_armor", "f3_orc_earth", name="갑옷 걸이"),
        prop("f3_orc_banner", "f2d_banner", "f3_orc_earth", name="오크 깃발"),
        prop("f3_orc_wagon", "f2d_wagon", "f3_orc_earth", name="짐수레"),
        prop("f3_orc_cage", "f2d_cage", "f3_orc_earth", name="포로 우리"),
        prop("f3_orc_sack", "f2d_sack", "f3_orc_ground", name="자루 더미"),
        prop("f3_orc_fire", "f2r_fire", "f3_orc_ground", name="모닥불"),
        prop("f3_orc_altar", "f2d_altar", "f3_orc_ground", name="오크 제단", interact="orc_altar"),
        prop("f3_estuary_deadtree", "f2d_deadtree", "f3_estuary_mud", name="썩은 나무"),
        prop("f3_estuary_post", "f2d_post", "f3_estuary_mud", name="썩은 말뚝"),
        prop("f3_estuary_stake", "f2d_stake", "f3_estuary_mud", name="잠긴 잔해"),
        prop("f3_estuary_rock", "f2d_rock", "f3_estuary_bank", name="물 위로 드러난 돌"),
        prop("f3_marsh_tree", "f2g_tree", "f3_marsh_floor", name="낮은 나무"),
        prop("f3_marsh_bush", "f2g_bush", "f3_marsh_floor", name="습지 덤불"),
        prop("f3_marsh_log", "f2g_log", "f3_marsh_floor", name="쓰러진 통나무"),
        prop("f3_marsh_mush", "f2g_mush", "f3_marsh_floor", name="빛버섯"),
        prop("f3_marsh_oak_t", "f2g_oak_t", "f3_marsh_thicket", name="습지 나무"),
        prop("f3_marsh_giant_t", "f2g_giant_oak_t", "f3_marsh_thicket", name="이끼 거목"),
        prop("f3_marsh_dead_t", "f2g_dead_t", "f3_marsh_thicket", name="물에 잠긴 고목"),
        prop("f3_marsh_stump", "f2g_stump", "f3_marsh_floor", name="뿌리 그루터기"),
        prop("f3_temple_statue", "f2d_statue", "f3_temple_grass", name="목이 부러진 석상", cover=True),
        prop("f3_temple_statue_c", "f2d_statue_c", "f3_temple_floor", name="목이 부러진 석상", cover=True),
        prop("f3_temple_head", "f2d_rock", "f3_temple_grass", name="부서진 석상 머리", notes="그림은 바위(석상 머리 그림 없음)"),
        prop("f3_temple_altar", "f2d_altar", "f3_temple_floor", name="버려진 제단"),
        prop("f3_temple_pew", "f2d_pew", "f3_temple_floor", name="부서진 돌 의자"),
        prop("f3_temple_candles", "f2d_candles", "f3_temple_floor", name="꺼진 촛대"),
        prop("f3_temple_tablet", "f2d_epitaph", "f3_temple_grass", name="오래된 석판"),
        prop("f3_reed_rock", "f2d_rock", None, name="갈대 속 바위"),
        prop("f3_witch_deadtree", "f2d_deadtree_g", "f3_witch_floor", name="마른 가시나무"),
        prop("f3_witch_bush", "f2d_bush", "f3_witch_floor", name="가시덤불"),
        prop("f3_witch_twisted", "f2g_dead_t", "f3_witch_thicket", name="뒤틀린 거목"),
        prop("f3_witch_pale", "f2g_giant_pale_t", "f3_witch_thicket", name="껍질이 벗겨진 거목"),
        prop("f3_purple_tree", "f2d_deadtree_g", "f3_witch_floor", name="보랏빛 껍질의 나무", interact="witch_tree",
             light={"radius_m": 1.6, "color": "#b070ff", "intensity": 0.75}, notes="마녀의 오두막 입구(WitchHut — 살피면 손을 포갠다)"),
        prop("f3_purple_tree_false", "f2d_deadtree_g", "f3_witch_floor", name="보랏빛 껍질의 나무",
             light={"radius_m": 1.6, "color": "#b070ff", "intensity": 0.75}, notes="환각(WitchForest — 다가가면 그냥 마른 나무로 돌아간다)"),
        prop("f3_hut_oak", "f2g_oak_g", "f3_hut_meadow", name="잎이 무성한 가시나무"),
        prop("f3_hut_birch", "f2g_birch_g", "f3_hut_meadow", name="잎이 무성한 나무"),
        prop("f3_hut_bare", "f2g_dead_g", "f3_hut_snow", name="잎 없는 나무"),
        prop("f3_hut_pine_snow", "gc_pine", "f3_hut_snow", name="눈 덮인 나무"),
        prop("f3_hut_drift", "gc_drift", "f3_hut_snow", name="눈 더미"),
        prop("f3_hut_shelf", "bf_bookcase", "f3_hut_floor", name="책장"),
        prop("f3_hut_table", "bf_table", "f3_hut_floor", name="식탁"),
        prop("f3_hut_hearth", "f2d_fire", "f3_hut_floor", name="난로", interact="witch_hearth",
             notes="벽난로(리아키스가 쓰러진 뒤에 들어가면 히든 피스)"),
        prop("f3_hut_bonfire", "f2d_fire", "f3_hut_meadow", name="모닥불", interact="witch_bonfire", notes="시신을 바치면 오두막이 8시간 더 머문다"),
        prop("f3_hut_bonfire_snow", "f2d_fire", "f3_hut_snow", name="모닥불", interact="witch_bonfire"),
    ]
    return out


# ── 에셋 모음(1층 균열 넷 · 2층 소품)을 3층 바닥 위에: 바닥 약자 → 바닥 타일, 바닥마다 쓸 소품 ──
# 타일 id = f3k_<바닥 약자>_<원본 id>(밑 바닥만 3층 — 소품 그림은 원본 그대로). tools/f3_layout.py가 K(약자, 원본)으로 부른다.
KIT_GROUND = {"og": "f3_orc_ground", "oe": "f3_orc_earth", "hr": "f3_hill_rock", "hg": "f3_hill_grass", "tf": "f3_temple_floor",
              "tg": "f3_temple_grass", "eb": "f3_estuary_bank", "em": "f3_estuary_mud", "mf": "f3_marsh_floor", "dg": "f3_dusk_ground",
              "rp": "f3_reed_thin", "wf": "f3_witch_floor", "hf": "f3_heart_floor", "hu": "f3_hut_floor", "hm": "f3_hut_meadow", "rb": "f3_riverbed"}
KIT = {
    "og": ["bf_tent", "bf_rack", "bf_armor", "bf_barrel", "bf_crate", "bf_brazier", "bf_flag", "bf_sack", "bf_cage", "bf_stake", "gm_fire", "gm_tent",
           "gm_toolrack", "gm_bench", "gc_totem", "bf_torture", "bf_gallows", "bf_well", "bf_table", "gm_crate", "gm_barrel", "bf_stall"],
    "oe": ["bf_palisade", "bf_barricade", "bf_wagon", "bf_rack", "bf_flag", "bf_stake", "bf_cage", "gm_tent", "gm_fire", "bf_crate", "bf_barrel", "gm_lantern", "bf_post"],
    "hr": ["bf_rock", "gm_rock", "gm_ore", "it_debris", "it_statue", "it_armor", "bf_flag", "gm_tent", "gm_fire", "bf_crate", "gm_crystal"],
    "hg": ["bf_rock", "gm_rock", "bf_deadtree", "gm_tent", "gm_fire", "bf_crate"],
    "tf": ["it_statue", "it_debris", "it_urn", "it_candelabra", "it_sarcophagus", "bf_statue", "fountain_statue", "bf_candles", "bf_altar", "it_brazier", "it_railing"],
    "tg": ["it_debris", "bf_statue", "fountain_statue", "it_urn", "bf_grave", "bf_well", "it_statue"],
    "eb": ["bf_deadtree", "bf_post", "bf_rock", "bf_wagon", "bf_cage", "bf_sack", "bf_stake", "bf_crate"],
    "em": ["bf_deadtree", "bf_post", "bf_stake", "bf_wagon", "bf_cage"],
    "mf": ["gm_mushroom", "bf_rock", "bf_post"],
    "dg": ["bf_rock", "gm_rock", "it_debris", "gm_ore", "bf_grave", "bf_flag", "gm_tent", "gm_fire", "gc_totem", "bf_crate"],
    "rp": ["bf_post", "bf_rock", "bf_flag", "bf_grave"],
    "wf": ["bf_deadtree", "bf_cage", "bf_candles", "bf_gallows", "f2d_wisp", "bf_stake", "bf_grave", "gc_totem", "bf_well", "bf_altar", "bookshelf"],
    "hf": ["it_brazier", "it_statue", "it_candelabra", "bf_statue"],
    "hu": ["bf_bed", "bf_bookcase", "bf_table", "bf_candles", "bf_barrel", "it_urn", "gm_bench", "bf_crate"],
    "hm": ["bf_well", "bf_barrel", "bf_crate", "gm_bench"],
    "rb": ["bf_rock", "gm_rock", "bf_wagon", "it_debris"],
}
KIT_NAME = {  # 3층에서 다른 이름으로 부를 것
    ("og", "bf_stake"): "말뚝에 꿰인 사냥감", ("og", "gc_totem"): "오크 토템", ("og", "bf_torture"): "가죽 무두질 틀", ("og", "bf_stall"): "전리품 좌판",
    ("og", "bf_gallows"): "전리품 걸이", ("og", "bf_well"): "야영지 우물", ("hr", "it_statue"): "녹슨 수호병 석상", ("hr", "it_armor"): "버려진 강철 갑옷",
    ("hr", "gm_ore"): "강철 광석 더미", ("hr", "gm_crystal"): "쇳빛 결정", ("wf", "f2d_wisp"): "마녀의 등불", ("wf", "bf_cage"): "매달린 새장",
    ("wf", "bf_candles"): "녹아내린 촛대", ("wf", "gc_totem"): "뼈 장식 기둥", ("wf", "bookshelf"): "썩은 책장", ("tf", "it_statue"): "목이 부러진 기사상",
    ("tg", "it_statue"): "목이 부러진 기사상", ("tg", "bf_statue"): "목이 부러진 석상", ("tf", "bf_statue"): "목이 부러진 석상", ("dg", "bf_grave"): "순례자 무덤",
    ("dg", "gc_totem"): "길잡이 기둥", ("rp", "bf_flag"): "갈대에 걸린 깃발", ("rp", "bf_grave"): "길 잃은 이의 무덤", ("mf", "gm_mushroom"): "커다란 늪버섯",
}


def kit_tiles():
    out = []
    for g, srcs in KIT.items():
        for src in srcs:
            out.append(prop("f3k_%s_%s" % (g, src), src, KIT_GROUND[g], name=KIT_NAME.get((g, src))))
    return out


# ── 3층 전용 소품(tools/f2_art/models_f3.py → assets/floor/f3/stand.webp, 칸 순서 = STAND 순서) ──
F3_STAND = ["f3a_reeds", "f3a_reeds_low", "f3a_vines", "f3a_vine_tree", "f3a_orc_tent", "f3a_orc_totem", "f3a_hide_rack", "f3a_head", "f3a_headless", "f3a_column"]
F3_STAND_USE = {  # 그림: (이름, 시야를 가리나, 엄폐, 쓰는 바닥 약자들)
    "f3a_reeds": ("가시갈대 덤불", True, True, ["rp"]), "f3a_reeds_low": ("가시갈대", False, True, ["rp", "mf"]),
    "f3a_vines": ("꿈틀대는 가시덩굴", False, True, ["wf"]), "f3a_vine_tree": ("덩굴 감긴 가시나무", False, False, ["wf"]),
    "f3a_orc_tent": ("오크 가죽 천막", True, False, ["og", "oe"]), "f3a_orc_totem": ("오크 토템", False, False, ["og", "oe"]),
    "f3a_hide_rack": ("가죽 말림대", False, True, ["og", "oe"]), "f3a_head": ("부서진 석상 머리", False, True, ["tg", "tf", "rp"]),
    "f3a_headless": ("목이 부러진 석상", False, True, ["tg", "tf"]), "f3a_column": ("쓰러진 기둥", False, True, ["tg", "tf"]),
}


def f3_stand_tiles():
    out = []
    for k, name in enumerate(F3_STAND):
        nm, sight, cover, grounds = F3_STAND_USE[name]
        for g in grounds:
            t = {"id": "%s_%s" % (name.replace("f3a_", "f3s_"), g), "name_ko": nm, "kind": "wall", "walkable": False, "blocks_sight": sight,
                 "face_px": 40, "colors": {"top": "#2a2826", "face": "#4a4640"},
                 "art": {"stand": {"sheet": "res://assets/floor/f3/stand.webp", "cell": k, "cols": 10, "rows": 1, "size": [2, 3], "under": KIT_GROUND[g]}},
                 "source": "placeholder", "notes": "3층 전용 소품(tools/f2_art/models_f3.py %s)" % name}
            if cover:
                t["cover"] = True
            out.append(t)
    return out


# ── 큰 구조물을 3층 바닥 위에(FieldsRouteBuild.landmarks — 구조물마다 "prefix"/"unders"): <앞>_big_<종류>_<접미> · <앞>_block_<접미> ──
BIG_F2D = ["mausoleum", "angel", "tower", "tree", "knight"]   # f2d/big.webp → 앞 "f3b"
BIG_F2G = ["bigtree", "hut", "tent", "watch"]                # f2g/big.webp → 앞 "f3g"
BIG_UNDER = {"f3b": {"w": "f3_witch_floor", "r": "f3_hill_rock", "h": "f3_hill_grass", "d": "f3_dusk_ground", "t": "f3_temple_grass", "f": "f3_temple_floor", "e": "f3_estuary_bank"},
             "f3g": {"o": "f3_orc_earth", "h": "f3_hill_grass", "m": "f3_marsh_floor", "d": "f3_dusk_ground"}}


def big_tiles():
    out = []
    for pre, kinds, src_pre, src_suf in (("f3b", BIG_F2D, "f2d", "g"), ("f3g", BIG_F2G, "f2g", "g")):
        for suf, under in BIG_UNDER[pre].items():
            for kind in kinds + ["block"]:
                src = "%s_block_%s" % (src_pre, src_suf) if kind == "block" else "%s_big_%s_%s" % (src_pre, kind, src_suf)
                tid = "%s_block_%s" % (pre, suf) if kind == "block" else "%s_big_%s_%s" % (pre, kind, suf)
                out.append(prop(tid, src, under))
    return out


def main():
    global SRC
    data = json.load(open(PATH, encoding="utf-8"))
    SRC = {t["id"]: t for t in data}
    new = tiles() + kit_tiles() + f3_stand_tiles() + big_tiles()
    for t in new:
        if t.pop("ramp_art", False):
            t["art"]["ramp"] = True
    # 있는 글은 그대로 두고 맨 끝에 한 줄씩 붙인다(전에 붙인 f3_ 줄은 지운다 — 다른 타일의 줄 모양을 건드리지 않게)
    text = open(PATH, encoding="utf-8").read()
    lines = [ln for ln in text.rstrip().split("\n") if not ln.startswith('  {"id": "f3')]
    assert lines[-1].strip() == "]"
    body = "\n".join(lines[:-1]).rstrip().rstrip(",")
    text = body + ",\n" + ",\n".join("  " + json.dumps(t, ensure_ascii=False) for t in new) + "\n]\n"
    json.loads(text)
    open(PATH, "w", encoding="utf-8").write(text)
    print("3층 타일", len(new))


SRC = {}
main()
