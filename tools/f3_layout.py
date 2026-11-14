#!/usr/bin/env python3
"""3층 '순례자의 길' 지도와 층 정의(data/floors/f3_pilgrim_road.json)를 만든다(몇 번 돌려도 같다 — 손으로 고치지 말고 이 스크립트를 고쳐 다시 돌린다).
오픈 필드(사용자 2026-11-14 "동굴형보다 오픈필드에 가깝게"): 필드 11곳(= 구역 11개)은 넓게 트인 땅이고(구간 kind "cover" — 들판을 덮는 터),
그 위에 장애물(강 · 도랑 · 능선 · 바위 · 갈대 · 덩굴 둔덕 · 방벽 — gen "strokes" · 소품)을 흩는다. 필드와 필드 사이만 자연 경계
(바위산 · 검은 물 · 덤불 띠 — 메움)로 나누고, 넓은 고개 · 둑길(구역을 건너는 길 edges)로 잇는다. 구역 나누기 = gen "zone_seeds".
  python3 tools/f3_tiles.py && python3 tools/f3_layout.py
  지도 그림: godot --headless --path . --script res://tools/floor_map.gd -- --floor=f3_pilgrim_road --out=<png> --scale=3
배치(동 = x 큼, 남 = y 큼, 지도 440 × 470 — 맨 아래 띠는 마녀의 오두막(따로 된 방)):
  북 녹빛꼬리 습지(고블린 숲 길 출발) · 북서 조각 사원(습지 옆 막다른 폐허) · 북동 바람결 고개(연결)
  동 강철바위 언덕(짐승의 소굴 길 출발) · 남동 오크 군락지 · 남 칠흑의 강어귀(망자의 땅 길 출발) · 남서 마른 강바닥(연결)
  남서 끝 황혼의 비탈길(바위사막 길 출발) · 서 가시갈대 밭 · 가운데 마녀의 숲(고리) · 한가운데 첨탑 공터(4층 포탈)
docs/plans/floor3.md. [창작] 임시값."""
import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "floors", "f3_pilgrim_road.json")
W, H = 440, 470
C = (220, 220)
RNG = random.Random(3)

ZONES = {  # 구역: (이름, 기본 바닥, 메움(경계), 색조)
    "f3_steel": ("강철바위 언덕", "f3_hill_grass", "f3_rise", "#e8ecf4"),
    "f3_windpass": ("바람결 고개", "f3_hill_rock", "f3_rise", "#e0e4ec"),
    "f3_orc": ("오크 군락지", "f3_orc_earth", "f3_orc_bank", "#f4dcc0"),
    "f3_estuary": ("칠흑의 강어귀", "f3_estuary_bank", "f3_black_water", "#b4b8c0"),
    "f3_riverbed": ("마른 강바닥", "f3_riverbed", "f3_rise", "#e8e0d0"),
    "f3_dusk": ("황혼의 비탈길", "f3_dusk_ground", "f3_rise", "#ffc8a8"),
    "f3_reeds": ("가시갈대 밭", "f3_reed_thin", "f3_reed_wall", "#fff0b0"),
    "f3_temple": ("조각 사원", "f3_temple_grass", "f3_temple_wall", "#d4d4dc"),
    "f3_greentail": ("녹빛꼬리 습지", "f3_marsh_floor", "f3_marsh_thicket", "#c8f0b4"),
    "f3_witch": ("마녀의 숲", "f3_witch_floor", "f3_witch_thicket", "#d0c0e4"),
    "f3_heart": ("첨탑 공터", "f3_heart_floor", "f3_witch_thicket", "#e4dcec"),
    "f3_hut": ("마녀의 오두막", "f3_hut_meadow", "f3_rise", "#ffffff"),
}


def polar(deg, r, c=C):
    a = math.radians(deg)
    return c[0] + math.cos(a) * r, c[1] + math.sin(a) * r


# ── 구역 기준점(가까운 점의 구역 — 보로노이) ─────────────────────
SEEDS = [(220, 220, "f3_heart")]
SEEDS += [(*polar(k * 30, 82), "f3_witch") for k in range(12)]
SEEDS += [(60, 175, "f3_reeds"), (58, 226, "f3_reeds"), (62, 272, "f3_reeds"),
          (82, 60, "f3_temple"), (42, 108, "f3_temple"),
          (214, 46, "f3_greentail"), (266, 58, "f3_greentail"), (170, 70, "f3_greentail"),
          (360, 44, "f3_windpass"), (412, 84, "f3_windpass"),
          (396, 162, "f3_steel"), (396, 246, "f3_steel"), (366, 204, "f3_steel"),
          (372, 372, "f3_orc"), (330, 336, "f3_orc"), (412, 412, "f3_orc"), (408, 326, "f3_orc"),
          (220, 396, "f3_estuary"), (176, 386, "f3_estuary"), (266, 396, "f3_estuary"),
          (124, 386, "f3_riverbed"),
          (56, 378, "f3_dusk"), (44, 322, "f3_dusk"),
          (40, 462, "f3_hut")]
SEEDS = [(round(x), round(y), z) for x, y, z in SEEDS]


def zone_at(x, y):
    return min(SEEDS, key=lambda s: (s[0] - x) ** 2 + (s[1] - y) ** 2)[2]


ZGRID = {}
for gy in range(0, H, 2):
    for gx in range(0, W, 2):
        ZGRID[(gx, gy)] = zone_at(gx, gy)


def clear_of_border(x, y, reach):
    """(x, y) 둘레 reach칸 안이 모두 같은 구역인가(필드 사이 경계 띠를 남긴다)."""
    z = zone_at(x, y)
    r2 = reach * reach
    for gy in range(int(y - reach) // 2 * 2, int(y + reach) + 2, 2):
        for gx in range(int(x - reach) // 2 * 2, int(x + reach) + 2, 2):
            if (gx - x) ** 2 + (gy - y) ** 2 <= r2 and ZGRID.get((gx, gy), "") != z:
                return False
    return True


nodes = []
edges = []
strokes = []


def N(nid, x, y, r, zone, kind="place", tile=None, level=None, props=None, **extra):
    d = {"id": nid, "at": [int(round(x)), int(round(y))], "r": r, "zone": zone, "kind": kind}
    if tile:
        d["tile"] = tile
    if level:
        d["level"] = level
    if props:
        d["props"] = props
    d.update(extra)
    nodes.append(d)
    return nid


def E(a, b, width=10, wiggle=4, tile=None, **extra):
    d = {"a": a, "b": b, "width": width, "wiggle": wiggle}
    if tile:
        d["tile"] = tile
    d.update(extra)
    edges.append(d)


def K(g, src):
    """에셋 모음 소품(tools/f3_tiles.py KIT — 1층 균열 넷 · 2층 소품을 3층 바닥 위에). "@f3s_…"면 3층 전용 소품(models_f3 — f3s_<이름>_<약자>)."""
    return "%s_%s" % (src[1:], g) if src.startswith("@") else "f3k_%s_%s" % (g, src)


def SC(nid, x, y, zone, tile, items, r=4):
    """장면: 작은 터 하나에 소품을 정해진 자리로(items = [(약자, 원본, [[dx, dy], …])]) — 생활 흔적 · 초소 · 의식 자리."""
    return N(nid, x, y, r, zone, tile=tile, props=[{"tile": K(g, src), "at": at} for g, src, at in items])


ZPROPS = []  # 구역 무작위 소품(에셋 모음)


def ZP(zone, g, src, count):
    ZPROPS.append({"zone": zone, "tile": K(g, src), "count": count})


def S(points, width, tile, wiggle=0.0, gaps=None):
    d = {"points": [[int(round(x)), int(round(y))] for x, y in points], "width": width, "tile": tile, "wiggle": wiggle}
    if gaps:
        d["gaps"] = gaps
    strokes.append(d)


# ── 들판을 덮는 터(cover): 격자 점마다 — 경계 띠(BORDER칸)는 남긴다 ──────────
STEP, BORDER = 14, 7
k = 0
for gy in range(10, 432, STEP):
    for gx in range(10, W - 8, STEP):
        x, y = gx + RNG.uniform(-3, 3), gy + RNG.uniform(-3, 3)
        z = zone_at(x, y)
        if z == "f3_hut":
            continue
        r = 10 + RNG.uniform(-1.0, 1.5)
        if not clear_of_border(x, y, r + BORDER):
            continue
        N("cv%d" % k, x, y, round(r, 1), z, kind="cover")
        k += 1

# ── 첨탑 공터(4층 포탈) ────────────────────────────────
N("heart", *C, 16, "f3_heart", kind="exit", props=[{"tile": "f3_witch_bush", "count": 4}])

# ── 마녀의 숲(고리): 이름 붙은 빈터 + 덩굴 둔덕 고리 · 끊긴 길 ─────────────
WP = [{"tile": "f3_witch_deadtree", "count": 6}, {"tile": "f3_witch_bush", "count": 3}]
outer = [N("wo%d" % i, *polar(i * 30 + (7 if i % 2 else -5), 102 + (5 if i % 3 == 0 else -3)), 9, "f3_witch", props=WP) for i in range(12)]
inner = [N("wi%d" % i, *polar(22.5 + i * 45, 62 + (4 if i % 2 else 0)), 8, "f3_witch", props=WP) for i in range(8)]
for j in (0, 2, 4, 6):  # 안 빈터 → 첨탑(경계 덤불 띠를 넘는 길)
    E(inner[j], "heart", 7, 6, tile="f3_witch_root")
# 덩굴 둔덕 고리(바깥 r 84 · 안 r 74 쪽 — 틈으로만 지나간다, 틈 자리는 고리마다 다르다): 숲이 길을 삼킨 듯 끊긴 길
for rr, n_gaps, width in ((86, 4, 4), (74, 3, 3)):
    pts = [polar(a, rr + 4 * math.sin(math.radians(a * 5))) for a in range(0, 361, 6)]
    gaps = []
    for g in range(n_gaps):
        t = (g + RNG.uniform(0.15, 0.85)) / n_gaps
        gaps.append([round(t - 0.018, 3), round(t + 0.018, 3)])
    S(pts, width, "f3_witch_thicket", 2.0, gaps)
for a in range(15, 360, 40):  # 갈래 둔덕(바깥에서 안으로 뻗은 덩굴 — 빈터를 나눈다)
    S([polar(a, 96), polar(a + 8, 112)], 3, "f3_witch_thicket", 1.5)
for a in range(0, 360, 50):  # 엉킨 뿌리 띠(느린 땅)
    S([polar(a, 95), polar(a + 20, 98), polar(a + 35, 92)], 4, "f3_witch_root", 2.0)

# ── 녹빛꼬리 습지(북) ─────────────────────────────────
MP = [{"tile": "f3_marsh_tree", "count": 4}, {"tile": "f3_marsh_bush", "count": 3}, {"tile": "f3_marsh_mush", "count": 2}, {"tile": "f3_marsh_log", "count": 1}]
N("gt_arrival", 220, 22, 8, "f3_greentail", kind="arrival", dest="floor3_from_forest", props=[{"tile": "f3_marsh_stump", "at": [[-6, -3], [6, 4]]}])
N("gt_west", 166, 74, 9, "f3_greentail", props=MP)
N("gt_east", 266, 54, 9, "f3_greentail", props=MP)
N("gt_south", 222, 92, 7, "f3_greentail", props=MP)
N("gt_hollow", 292, 92, 6, "f3_greentail", kind="pocket", props=MP)
for pts in ([(150, 40), (180, 50), (205, 62), (240, 60)], [(190, 95), (215, 80), (250, 86), (285, 78)], [(240, 30), (262, 40), (300, 36)]):
    S(pts, 7, "f3_marsh_water", 5)    # 고인 물 줄기(걸을 수 있고 느리다)
for i in range(16):  # 뿌리 덤불 무더기(지나갈 수 없다 · 길을 좁힌다)
    x, y = RNG.uniform(150, 300), RNG.uniform(30, 100)
    if zone_at(x, y) == "f3_greentail":
        S([(x, y), (x + RNG.uniform(-8, 8), y + RNG.uniform(-5, 5))], 4, "f3_marsh_thicket", 1)

# ── 조각 사원(북서 — 습지 옆 막다른 폐허) ─────────────────────
N("tp_gate", 124, 92, 6, "f3_temple", props=[{"tile": "f3_temple_statue", "count": 3}, {"tile": "f3s_head_tg", "count": 3}])
N("tp_court", 92, 72, 14, "f3_temple", props=[{"tile": "f3_temple_statue", "count": 8}, {"tile": "f3s_head_tg", "count": 6}, {"tile": "f3_temple_tablet", "count": 3}])
N("tp_colonnade", 100, 34, 8, "f3_temple", tile="f3_temple_floor",
  props=[{"tile": "f3_temple_statue_c", "at": [[-6, -3], [-2, -3], [2, -3], [6, -3], [-6, 3], [-2, 3], [2, 3], [6, 3]]}])
N("tp_hall", 52, 50, 10, "f3_temple", tile="f3_temple_floor")
N("tp_garden", 40, 104, 9, "f3_temple", props=[{"tile": "f3_temple_statue", "count": 6}, {"tile": "f3s_head_tg", "count": 5}])
for pts in ([(70, 20), (70, 40)], [(122, 50), (140, 56)], [(20, 80), (40, 76)], [(110, 110), (96, 120)], [(64, 90), (74, 98)]):
    S(pts, 2, "f3_temple_wall")      # 무너진 벽 조각

# ── 가시갈대 밭(서 — 어깨 높이 갈대(성긴 갈대 — 지나가지만 보이지 않는다) 사이 좁은 흙길) ─────
REED = [(104, 214), (88, 186), (82, 240), (60, 168), (56, 214), (62, 262), (34, 190), (32, 238), (98, 152), (44, 292), (96, 276), (76, 136),
        (18, 160), (112, 248), (18, 266), (66, 238)]
for i, (x, y) in enumerate(REED):
    N("rd%d" % i, x, y, 3, "f3_reeds", tile="f3_reed_path", props=[{"tile": "f3_reed_rock", "count": 1}])
for a, b in [(0, 1), (0, 2), (1, 3), (1, 4), (2, 4), (2, 5), (3, 6), (4, 6), (4, 7), (5, 7), (3, 8), (8, 0), (5, 9), (7, 9), (5, 10),
             (10, 2), (3, 11), (8, 11), (12, 6), (12, 3), (13, 2), (13, 0), (14, 7), (14, 9), (15, 4), (15, 2)]:
    (x0, y0), (x1, y1) = REED[a], REED[b]
    mx, my = (x0 + x1) / 2 + RNG.uniform(-6, 6), (y0 + y1) / 2 + RNG.uniform(-6, 6)
    S([(x0, y0), (mx, my), (x1, y1)], 2, "f3_reed_path", 3)
for i in range(14):  # 빽빽한 갈대 숲(지나갈 수 없다)
    x, y = RNG.uniform(20, 110), RNG.uniform(140, 295)
    if zone_at(x, y) == "f3_reeds":
        S([(x, y), (x + RNG.uniform(-10, 10), y + RNG.uniform(-10, 10))], 5, "f3_reed_wall", 2)

# ── 황혼의 비탈길(남서 — 낮은 협곡에서 바위턱으로) ─────────────────
DP = [{"tile": "f3_hill_boulder_d", "count": 4}]
N("du_arrival", 40, 404, 8, "f3_dusk", kind="arrival", dest="floor3_from_desert", level="low")
N("du_canyon", 74, 390, 7, "f3_dusk", level="low", props=DP)
N("du_gully", 28, 358, 6, "f3_dusk", level="low", props=DP)
N("du_ledge", 90, 356, 9, "f3_dusk", props=DP)
N("du_pillars", 58, 320, 11, "f3_dusk", props=[{"tile": "f3_hill_boulder_d", "count": 10}])
N("du_crest", 96, 300, 7, "f3_dusk", props=DP)
E("du_arrival", "du_canyon", 6, 3, level="low", ramp=True)
E("du_arrival", "du_gully", 6, 4, level="low", ramp=True)
E("du_canyon", "du_ledge", 6, 3, ramp=True)
E("du_gully", "du_pillars", 6, 4, ramp=True)
for pts in ([(20, 340), (50, 345), (80, 338)], [(60, 300), (80, 290)], [(110, 330), (100, 345)]):
    S(pts, 3, "f3_rise", 2)          # 바위 능선(시야 · 길을 가르는 등성이)

# ── 마른 강바닥(남서 연결) ─────────────────────────────
N("rb_n", 126, 360, 8, "f3_riverbed", props=[{"tile": "f3_hill_boulder_d", "count": 3}])
N("rb_s", 128, 410, 9, "f3_riverbed")

# ── 칠흑의 강어귀(남 — 둑 위 트인 뻘, 수십 갈래 검은 도랑) ─────────────
EP = [{"tile": "f3_estuary_deadtree", "count": 2}, {"tile": "f3_estuary_post", "count": 2}, {"tile": "f3_estuary_stake", "count": 1}]
N("es_arrival", 215, 424, 8, "f3_estuary", kind="arrival", dest="floor3_from_dead", props=EP)
N("es_reach", 214, 352, 5, "f3_estuary", props=EP)
N("es_west", 168, 384, 6, "f3_estuary", props=EP)
N("es_east", 266, 380, 6, "f3_estuary", props=EP)
for i, x in enumerate(range(150, 296, 11)):   # 남북으로 흐르는 깊은 도랑(넘을 수 없다) — 틈(여울)으로만 건넌다
    top = 350 + RNG.uniform(0, 10)
    pts = [(x + RNG.uniform(-3, 3), top), (x + RNG.uniform(-6, 6), 375), (x + RNG.uniform(-6, 6), 400), (x + RNG.uniform(-3, 3), 432)]
    t0 = RNG.uniform(0.15, 0.75)
    S(pts, 3, "f3_black_water", 2, gaps=[[round(t0, 2), round(t0 + 0.07, 2)]])
for y in (366, 392, 414):                      # 동서로 가로지르는 얕은 도랑(건널 수 있지만 느리다)
    S([(148, y + RNG.uniform(-4, 4)), (220, y + RNG.uniform(-6, 6)), (296, y + RNG.uniform(-4, 4))], 3, "f3_ditch", 4)
S([(205, 432), (212, 400), (216, 360)], 4, "f3_estuary_mud", 3)   # 가운데 둑길(마른 길 — 도랑을 가로질러 북으로)

# ── 오크 군락지(남동 — 방벽 고리 안 야영지 · 감시탑 · 무기고 · 제단) ─────────────
OP = [{"tile": "f3_orc_sack", "count": 2}, {"tile": "f3_orc_fire", "count": 1}]
N("or_hunt", 314, 334, 9, "f3_orc", props=[{"tile": "f3_orc_barricade", "count": 3}, {"tile": "f3_orc_cage", "count": 1}])
N("or_watch", 352, 316, 7, "f3_orc", props=[{"tile": "f3_orc_palisade", "count": 4}, {"tile": "f3_orc_banner", "count": 2}])
N("or_gate", 346, 350, 7, "f3_orc", tile="f3_orc_ground", props=[{"tile": "f3_orc_stakes", "at": [[-5, -2], [-5, 2], [5, -2], [5, 2]]}])
RING = []  # 목재 방벽 말뚝(2칸마다 하나 — 문 넷은 비운다): 야영지 가운데에서 반지름 31
for k in range(90):
    a = k * 4.0
    if any(lo <= a <= hi for lo, hi in ((25, 40), (105, 125), (215, 235), (300, 318))):
        continue
    x, y = polar(a, 31, (0, 0))
    RING.append([int(round(x)), int(round(y))])
N("or_camp", 376, 384, 20, "f3_orc", tile="f3_orc_ground", props=OP + [{"tile": "f3_orc_sack", "count": 4}, {"tile": "f3_orc_tent_post", "count": 3}])
nodes[-1]["props"].append({"tile": "f3k_oe_bf_palisade", "at": RING})
N("or_armory", 414, 336, 9, "f3_orc", props=[{"tile": "f3_orc_armor", "count": 5}, {"tile": "f3_orc_wagon", "count": 2}, {"tile": "f3_orc_banner", "count": 1}])
N("or_pit", 334, 404, 8, "f3_orc", tile="f3_orc_ground", props=OP + [{"tile": "f3_orc_cage", "count": 2}])
N("or_altar", 414, 418, 8, "f3_orc", tile="f3_orc_ground", props=[{"tile": "f3_orc_altar", "at": [[0, -1]]}, {"tile": "f3_orc_tent_post", "at": [[-5, -3], [5, -3]]}, {"tile": "f3_orc_fire", "at": [[-4, 3], [4, 3]]}])

for pts in ([(322, 318), (340, 310)], [(300, 370), (312, 360)], [(400, 300), (420, 310)]):
    S(pts, 2, "f3_orc_barricade")      # 외곽 경계 방책

# ── 강철바위 언덕(동 — 트인 언덕 · 흐르는 강 · 바위 능선 · 낭떠러지) ─────────────
HP = [{"tile": "f3_hill_boulder", "count": 4}]
N("st_arrival", 418, 210, 9, "f3_steel", kind="arrival", dest="floor3_from_den", props=[{"tile": "f3_hill_pine", "count": 2}])
N("st_lookout", 404, 170, 9, "f3_steel", tile="f3_hill_rock", props=HP, view=True)
N("st_pines", 400, 132, 10, "f3_steel", props=[{"tile": "f3_hill_pine", "count": 8}, {"tile": "f3_hill_oak", "count": 4}])
N("st_rocks", 358, 156, 11, "f3_steel", tile="f3_hill_rock", props=[{"tile": "f3_hill_boulder", "count": 10}],
  terraces=[{"at": [5, 5], "r": 6, "level": "low", "ramp": [1, 0]}])
N("st_crest", 352, 206, 9, "f3_steel", tile="f3_hill_rock", props=HP, view=True)
N("st_meadow", 392, 250, 11, "f3_steel", props=[{"tile": "f3_hill_oak", "count": 4}, {"tile": "f3_hill_pine", "count": 2}])
N("st_valley", 356, 276, 10, "f3_steel", level="low", props=HP)
E("st_meadow", "st_valley", 7, 3, ramp=True)
S([(434, 120), (412, 150), (386, 196), (378, 232), (400, 270), (414, 296)], 5, "f3_river", 4)     # 흐르는 강(얕다 — 느리게 건넌다)
for pts in ([(340, 180), (346, 160)], [(380, 140), (372, 120)], [(420, 230), (432, 242)], [(340, 240), (330, 252)], [(372, 300), (392, 306)]):
    S(pts, 3, "f3_rise", 1.5)          # 바위 능선 · 작은 절벽

# ── 바람결 고개(북동 연결) ─────────────────────────────
N("wp_west", 318, 44, 7, "f3_windpass", props=HP)
N("wp_saddle", 360, 36, 9, "f3_windpass", props=HP, view=True)
N("wp_down", 410, 92, 6, "f3_windpass", tile="f3_hill_grass")
S([(340, 60), (380, 66)], 3, "f3_rise", 2)

# ── 에셋 모음으로 채우기(장면 · 무작위 소품) ─────────────────────
# 오크 군락지: 야영지 고리 안 = 잠자리 · 모닥불 · 우물 · 좌판, 무기고 = 대장간(공구대 · 작업대 · 무기대 · 갑옷), 사냥터 = 무두질 · 꿰인 사냥감, 구덩이 = 포로 우리 · 교수대
SC("or_sleep", 362, 372, "f3_orc", "f3_orc_ground", [("og", "@f3s_orc_tent", [[-5, -2], [0, -4], [5, -2]]), ("og", "gm_fire", [[0, 1]]), ("og", "bf_sack", [[-3, 3], [4, 3]])], 7)
SC("or_well", 388, 392, "f3_orc", "f3_orc_ground", [("og", "bf_well", [[0, 0]]), ("og", "bf_barrel", [[-3, 1], [3, 1]]), ("og", "bf_stall", [[0, 4]])], 6)
SC("or_feast", 384, 368, "f3_orc", "f3_orc_ground", [("og", "bf_table", [[-2, 0], [2, 0]]), ("og", "bf_brazier", [[0, -3]]), ("og", "gm_crate", [[4, 2]])], 5)
SC("or_smithy", 418, 352, "f3_orc", "f3_orc_ground", [("og", "gm_toolrack", [[-4, -2]]), ("og", "gm_bench", [[0, -2]]), ("og", "bf_rack", [[4, -2], [-4, 2]]),
                                                     ("og", "bf_armor", [[0, 3], [3, 3]]), ("og", "bf_brazier", [[4, 1]])], 6)
SC("or_tanning", 306, 322, "f3_orc", "f3_orc_ground", [("og", "@f3s_hide_rack", [[-3, 0], [3, 0]]), ("og", "bf_stake", [[0, -3], [-5, 3], [5, 3]]), ("og", "gm_fire", [[0, 2]])], 6)
SC("or_prison", 330, 414, "f3_orc", "f3_orc_ground", [("og", "bf_cage", [[-4, -1], [0, -2], [4, -1]]), ("og", "bf_gallows", [[0, 3]]), ("og", "bf_flag", [[-5, 3], [5, 3]])], 6)
SC("or_totems", 398, 410, "f3_orc", "f3_orc_ground", [("og", "@f3s_orc_totem", [[-4, 0], [4, 0]]), ("og", "bf_flag", [[0, -3]])], 5)
for i, (x, y) in enumerate([(342, 300), (296, 364), (300, 392), (404, 304), (424, 392)]):   # 외곽 경계 초소(방책 · 깃발 · 랜턴)
    SC("or_post%d" % i, x, y, "f3_orc", None, [("oe", "bf_barricade", [[-2, 0], [2, 0]]), ("oe", "bf_flag", [[0, -2]]), ("oe", "gm_lantern", [[3, -2]])], 4)
ZP("f3_orc", "oe", "bf_stake", 25)
ZP("f3_orc", "oe", "bf_crate", 20)
ZP("f3_orc", "oe", "bf_barrel", 20)
ZP("f3_orc", "oe", "gm_tent", 10)
ZP("f3_orc", "oe", "bf_wagon", 6)
# 강철바위 언덕 · 바람결 고개: 옛 수호병 초소(녹슨 석상 · 갑옷) · 광석 더미 · 탐험가 야영 흔적
SC("st_post", 372, 186, "f3_steel", "f3_hill_rock", [("hr", "it_statue", [[-3, -2], [3, -2]]), ("hr", "it_armor", [[0, 2]]), ("hr", "it_debris", [[-4, 3], [4, 2]])], 6)
SC("st_ore", 336, 160, "f3_steel", "f3_hill_rock", [("hr", "gm_ore", [[-2, 0], [2, 1]]), ("hr", "gm_crystal", [[0, -3]]), ("hr", "gm_rock", [[4, -2]])], 5)
SC("st_camp", 408, 228, "f3_steel", "f3_hill_grass", [("hg", "gm_tent", [[-2, -2]]), ("hg", "gm_fire", [[1, 1]]), ("hg", "bf_crate", [[3, -1]])], 4)
SC("wp_cairn", 384, 48, "f3_windpass", "f3_hill_rock", [("hr", "bf_flag", [[0, -2]]), ("hr", "gm_rock", [[-2, 1], [2, 1]])], 4)
ZP("f3_steel", "hr", "gm_rock", 60)
ZP("f3_steel", "hr", "bf_rock", 60)
ZP("f3_steel", "hr", "gm_ore", 12)
ZP("f3_steel", "hg", "bf_deadtree", 10)
ZP("f3_windpass", "hr", "gm_rock", 50)
ZP("f3_windpass", "hr", "it_debris", 10)
# 조각 사원: 분수 · 석관 · 촛대 · 항아리 · 쓰러진 기사상
SC("tp_fountain", 78, 86, "f3_temple", "f3_temple_grass", [("tg", "fountain_statue", [[0, 0]]), ("tg", "it_urn", [[-3, 2], [3, 2]]), ("tg", "bf_statue", [[-4, -2], [4, -2]])], 6)
SC("tp_crypt", 46, 28, "f3_temple", "f3_temple_floor", [("tf", "it_sarcophagus", [[-3, 0], [3, 0]]), ("tf", "it_candelabra", [[0, -3]]), ("tf", "it_debris", [[0, 3]])], 5)
SC("tp_shrine", 128, 40, "f3_temple", "f3_temple_floor", [("tf", "bf_altar", [[0, -2]]), ("tf", "bf_candles", [[-2, -2], [2, -2]]), ("tf", "it_statue", [[-4, 1], [4, 1]])], 5)
SC("tp_hallway", 52, 50, "f3_temple", "f3_temple_floor", [("tf", "it_statue", [[-6, -4], [-6, 0], [-6, 4], [6, -4], [6, 0], [6, 4]]), ("tf", "bf_altar", [[0, -7]]),
                                                         ("tf", "it_candelabra", [[-3, -7], [3, -7]]), ("tf", "it_urn", [[-8, 7], [8, 7]])], 8)
ZP("f3_temple", "tg", "it_debris", 40)
ZP("f3_temple", "tg", "bf_statue", 20)
ZP("f3_temple", "tg", "it_urn", 10)
ZP("f3_temple", "tg", "bf_grave", 8)
# 칠흑의 강어귀: 가라앉은 짐수레 · 썩은 나무 · 잠긴 우리
SC("es_wreck", 190, 360, "f3_estuary", "f3_estuary_bank", [("eb", "bf_wagon", [[0, 0]]), ("eb", "bf_sack", [[-2, 2], [3, 1]]), ("eb", "bf_crate", [[2, -2]])], 4)
SC("es_cage", 250, 410, "f3_estuary", "f3_estuary_bank", [("eb", "bf_cage", [[0, 0]]), ("eb", "bf_stake", [[-3, 1], [3, 1]])], 4)
ZP("f3_estuary", "eb", "bf_deadtree", 40)
ZP("f3_estuary", "eb", "bf_post", 40)
ZP("f3_estuary", "eb", "bf_rock", 30)
ZP("f3_estuary", "eb", "bf_stake", 15)
# 녹빛꼬리 습지: 커다란 늪버섯 · 낡은 말뚝
ZP("f3_greentail", "mf", "gm_mushroom", 50)
ZP("f3_greentail", "mf", "bf_post", 15)
# 황혼의 비탈길: 순례자 무덤 · 길잡이 기둥 · 바위 · 광석
SC("du_graves", 70, 350, "f3_dusk", "f3_dusk_ground", [("dg", "bf_grave", [[-3, 0], [0, -1], [3, 0], [-2, 3], [2, 3]]), ("dg", "bf_flag", [[0, 4]])], 5)
SC("du_camp", 100, 330, "f3_dusk", "f3_dusk_ground", [("dg", "gm_tent", [[-2, -1]]), ("dg", "gm_fire", [[1, 1]]), ("dg", "bf_crate", [[3, -1]])], 4)
for i, (x, y) in enumerate([(52, 392), (86, 376), (40, 334), (80, 312), (104, 292)]):   # 비탈을 오르는 길잡이 기둥
    SC("du_guide%d" % i, x, y, "f3_dusk", "f3_dusk_ground", [("dg", "gc_totem", [[0, 0]])], 3)
ZP("f3_dusk", "dg", "gm_rock", 60)
ZP("f3_dusk", "dg", "bf_rock", 50)
ZP("f3_dusk", "dg", "it_debris", 20)
ZP("f3_riverbed", "rb", "gm_rock", 30)
ZP("f3_riverbed", "rb", "bf_wagon", 3)
# 가시갈대 밭: 길 잃은 이의 무덤 · 갈대에 걸린 깃발 · 말뚝(어디나 비슷하다 — 길잡이가 되지 못한다)
ZP("f3_reeds", "rp", "bf_post", 25)
ZP("f3_reeds", "rp", "bf_flag", 10)
ZP("f3_reeds", "rp", "bf_grave", 12)
ZP("f3_reeds", "rp", "bf_rock", 20)
# 마녀의 숲: 의식 자리(촛대 · 제단 · 뼈 기둥) · 매달린 새장 · 마녀의 등불 · 교수대 · 썩은 책장 · 우물
for i, a in enumerate(range(20, 360, 60)):
    x, y = polar(a, 92)
    SC("wr%d" % i, x, y, "f3_witch", "f3_witch_floor", [("wf", "bf_altar", [[0, -2]]), ("wf", "bf_candles", [[-3, -1], [3, -1], [-2, 2], [2, 2]]), ("wf", "gc_totem", [[0, 3]])], 4)
SC("w_gallows", *polar(140, 108), "f3_witch", "f3_witch_floor", [("wf", "bf_gallows", [[0, 0]]), ("wf", "bf_cage", [[-3, 1], [3, 1]])], 4)
SC("w_well", *polar(300, 66), "f3_witch", "f3_witch_floor", [("wf", "bf_well", [[0, 0]]), ("wf", "bookshelf", [[-3, -1]]), ("wf", "bf_grave", [[3, 1]])], 4)
ZP("f3_witch", "wf", "f2d_wisp", 70)
ZP("f3_witch", "wf", "bf_cage", 30)
ZP("f3_witch", "wf", "bf_stake", 25)
ZP("f3_witch", "wf", "bf_grave", 20)
ZP("f3_witch", "wf", "bf_candles", 15)
# 첨탑 공터: 화로 · 기사상 고리
SC("heart_ring", 220, 232, "f3_heart", "f3_heart_floor", [("hf", "it_brazier", [[-8, -4], [8, -4], [-8, 4], [8, 4]]), ("hf", "it_statue", [[-11, 0], [11, 0]]),
                                                         ("hf", "it_candelabra", [[-4, 6], [4, 6]])], 4)

# ── 3층 전용 소품(models_f3) · 큰 구조물 사본(f3b · f3g) ─────────────────
ZP("f3_reeds", "rp", "@f3s_reeds", 140)
ZP("f3_reeds", "rp", "@f3s_reeds_low", 120)
ZP("f3_reeds", "rp", "@f3s_head", 6)
ZP("f3_greentail", "mf", "@f3s_reeds_low", 40)
ZP("f3_witch", "wf", "@f3s_vines", 220)
ZP("f3_witch", "wf", "@f3s_vine_tree", 160)
ZP("f3_orc", "oe", "@f3s_orc_tent", 12)
ZP("f3_orc", "oe", "@f3s_hide_rack", 10)
ZP("f3_orc", "oe", "@f3s_orc_totem", 8)
ZP("f3_temple", "tg", "@f3s_headless", 25)
ZP("f3_temple", "tg", "@f3s_column", 20)
ZP("f3_temple", "tg", "@f3s_head", 20)
SC("tp_heads", 108, 100, "f3_temple", "f3_temple_grass", [("tg", "@f3s_headless", [[-4, -3], [0, -4], [4, -3]]), ("tg", "@f3s_head", [[-3, 1], [2, 2], [5, 0]]),
                                                          ("tg", "@f3s_column", [[-1, 4]])], 6)
for i, a in enumerate((10, 70, 130, 190, 250, 310)):   # 덩굴 감긴 가시나무가 엉킨 빈터
    x, y = polar(a, 104)
    SC("wv%d" % i, x, y, "f3_witch", "f3_witch_floor", [("wf", "@f3s_vine_tree", [[-3, -2], [3, -1]]), ("wf", "@f3s_vines", [[0, 2], [-4, 2], [4, 3]])], 5)
BIG_EXTRA = [
    {"node": "wo1", "at": [0, -5], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"w": "f3_witch_floor"}},
    {"node": "wo4", "at": [3, -4], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"w": "f3_witch_floor"}},
    {"node": "wo7", "at": [-3, -4], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"w": "f3_witch_floor"}},
    {"node": "wo10", "at": [0, -5], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"w": "f3_witch_floor"}},
    {"node": "w_well", "at": [0, -6], "kind": "mausoleum", "foot": [4, 3], "prefix": "f3b", "unders": {"w": "f3_witch_floor"}},
    {"node": "st_post", "at": [0, -5], "kind": "knight", "foot": [2, 2], "prefix": "f3b", "unders": {"r": "f3_hill_rock"}},
    {"node": "st_lookout", "at": [-4, -5], "kind": "knight", "foot": [2, 2], "prefix": "f3b", "unders": {"r": "f3_hill_rock"}},
    {"node": "st_meadow", "at": [6, -6], "kind": "bigtree", "foot": [3, 2], "prefix": "f3g", "unders": {"h": "f3_hill_grass"}},
    {"node": "du_pillars", "at": [0, -7], "kind": "tower", "foot": [4, 3], "prefix": "f3b", "unders": {"d": "f3_dusk_ground"}},
    {"node": "du_graves", "at": [0, -6], "kind": "angel", "foot": [3, 2], "prefix": "f3b", "unders": {"d": "f3_dusk_ground"}},
    {"node": "es_west", "at": [0, -4], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"e": "f3_estuary_bank"}},
    {"node": "es_east", "at": [0, -4], "kind": "tree", "foot": [2, 2], "prefix": "f3b", "unders": {"e": "f3_estuary_bank"}},
    {"node": "or_watch", "at": [4, -3], "kind": "watch", "foot": [3, 2], "prefix": "f3g", "unders": {"o": "f3_orc_earth"}},
    {"node": "or_hunt", "at": [-5, -4], "kind": "tent", "foot": [3, 2], "prefix": "f3g", "unders": {"o": "f3_orc_earth"}},
    {"node": "or_armory", "at": [6, 4], "kind": "hut", "foot": [4, 2], "prefix": "f3g", "unders": {"o": "f3_orc_earth"}},
    {"node": "gt_west", "at": [0, -5], "kind": "bigtree", "foot": [3, 2], "prefix": "f3g", "unders": {"m": "f3_marsh_floor"}},
    {"node": "gt_east", "at": [4, -4], "kind": "bigtree", "foot": [3, 2], "prefix": "f3g", "unders": {"m": "f3_marsh_floor"}},
]

# ── 필드를 건너는 길(고개 · 둑길 · 숲 어귀 — 경계 띠를 넘는 곳만) ──────────────
for a, b, w, t in [
    ("gt_south", outer[9], 9, None), ("gt_west", outer[8], 7, None), ("gt_west", "tp_gate", 8, None), ("gt_east", "wp_west", 8, None),
    ("wp_down", "st_pines", 9, None), ("wp_west", outer[10], 6, None), ("st_crest", outer[0], 9, None), ("st_rocks", outer[11], 7, None),
    ("st_valley", "or_watch", 8, None), ("or_hunt", outer[2], 8, None), ("or_pit", "es_east", 7, "f3_estuary_mud"), ("or_hunt", "es_east", 6, None),
    ("es_reach", outer[3], 8, None), ("es_west", "rb_n", 7, "f3_estuary_mud"), ("es_arrival", "rb_s", 7, "f3_estuary_mud"),
    ("du_ledge", "rb_n", 7, None), ("du_canyon", "rb_s", 6, None), ("du_crest", outer[4], 7, None), ("du_pillars", "rd9", 5, "f3_reed_path"),
    ("rd0", outer[6], 5, "f3_reed_path"), ("rd8", outer[7], 5, "f3_reed_path"), ("rd11", "tp_garden", 5, "f3_reed_path"), ("rd13", outer[5], 5, "f3_reed_path"),
]:
    E(a, b, w, 5, tile=t, ramp=True)

# ── 마녀의 오두막(따로 된 방 — 길이 없다, 보랏빛 나무로만) ─────
N("hut", 40, 455, 1, "f3_hut", kind="pocket")


# ── 오두막 그림판(crypts — 메운 뒤에 판다, 밝다) ─────────────
HUT_ROWS = [
    "  mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm  ",
    " mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm ",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWWWWWWWWWWWWWWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWffffffffffffWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWffccccccccffWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWffccccccccffWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWffccccccccffWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWffffffffffffWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmWWWWWWffWWWWWWmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmffmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    "mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm",
    " mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm ",
    "  mmmmmmmmmmmmmmmmmmmmmmmmmmmmMMMmmmmmmmmmmmmmmmmmmmmm  ",
]
HUT_AT = (12, 444)
HUT = {"at": list(HUT_AT), "lit": True, "legend": {"m": "f3_hut_meadow", "W": "f3_hut_wall", "f": "f3_hut_floor", "c": "f3_hut_carpet", "M": "f3_hut_mist"},
       "rows": HUT_ROWS, "marks": {"hut_in": [29, 16], "hut_door": [28, 10], "hut_hearth": [28, 4], "hut_shelf_a": [24, 4], "hut_shelf_b": [33, 4],
                                   "hut_table": [29, 6], "hut_bonfire": [29, 13], "hut_center": [28, 9],
                                   "hut_bed": [34, 7], "hut_candles": [23, 5], "hut_barrel": [23, 8], "hut_urn": [34, 4], "hut_well": [40, 12],
                                   "hut_crates": [17, 12], "hut_bench": [36, 14]}}
# 오두막 안 · 둘레 고정 소품(WitchHut이 입장 때 놓는다 — 설원이면 다른 그림)
HUT_PROPS = {
    "fixed": {"hut_bed": "f3k_hu_bf_bed", "hut_candles": "f3k_hu_bf_candles", "hut_barrel": "f3k_hu_bf_barrel", "hut_urn": "f3k_hu_it_urn",
              "hut_well": "f3k_hm_bf_well", "hut_crates": "f3k_hm_bf_crate", "hut_bench": "f3k_hm_gm_bench"},
    "spring": {"trees": "f3_hut_oak", "trees2": "f3_hut_birch", "ground": "f3_hut_meadow", "bonfire": "f3_hut_bonfire"},
    "winter": {"trees": "f3_hut_bare", "trees2": "f3_hut_pine_snow", "ground": "f3_hut_snow", "bonfire": "f3_hut_bonfire_snow", "drift": "f3_hut_drift"},
}


# 필드마다 터 · 길 넓이 배율(넓은 야외 — 언덕 · 고개 · 군락지는 넓게, 갈대 · 습지는 좁게). 도랑 · 강 길은 그대로
def floor_json():
    marks = [{"name": n["id"], "node": n["id"], "at": [0, 0]} for n in nodes if n["kind"] != "cover"]
    gen = {
        "_comment": "3층 손으로 짠 길 그래프(tools/f3_layout.py — 다시 만들려면 스크립트를 고쳐 다시 돌린다). [창작] 임시값",
        "grammar": "route", "size": [W, H], "seed": 3,
        "tiles": {"rise": "f3_rise", "floor": "f3_hill_grass", "down": "f3_stone_down", "up": "f3_portal_up"},
        "zone_fill": {z: v[2] for z, v in ZONES.items()},
        "zone_floor": {z: v[1] for z, v in ZONES.items()},
        "zone_low": {"f3_steel": "f3_hill_low", "f3_dusk": "f3_dusk_low", "f3_windpass": "f3_hill_low", "f3_riverbed": "f3_dusk_low"},
        "levels": {"scree": "f3_hill_scree", "ramp": "f3_hill_slope"},
        "zone_seeds": [list(sd) for sd in SEEDS],
        "nodes": nodes, "edges": edges, "strokes": strokes,
        "props": [
            {"zone": "f3_witch", "tile": "f3_witch_deadtree", "count": 900}, {"zone": "f3_witch", "tile": "f3_witch_bush", "count": 500},
            {"zone": "f3_heart", "tile": "f3_witch_deadtree", "count": 30},
            {"zone": "f3_steel", "tile": "f3_hill_boulder", "count": 140}, {"zone": "f3_steel", "tile": "f3_hill_pine", "count": 120},
            {"zone": "f3_steel", "tile": "f3_hill_oak", "count": 90}, {"zone": "f3_windpass", "tile": "f3_hill_boulder", "count": 80},
            {"zone": "f3_greentail", "tile": "f3_marsh_tree", "count": 160}, {"zone": "f3_greentail", "tile": "f3_marsh_bush", "count": 160},
            {"zone": "f3_greentail", "tile": "f3_marsh_mush", "count": 60}, {"zone": "f3_greentail", "tile": "f3_marsh_log", "count": 30},
            {"zone": "f3_estuary", "tile": "f3_estuary_post", "count": 70}, {"zone": "f3_estuary", "tile": "f3_estuary_deadtree", "count": 50},
            {"zone": "f3_estuary", "tile": "f3_estuary_stake", "count": 40},
            {"zone": "f3_dusk", "tile": "f3_hill_boulder_d", "count": 140},
            {"zone": "f3_temple", "tile": "f3_temple_statue", "count": 60}, {"zone": "f3_temple", "tile": "f3s_head_tg", "count": 60},
            {"zone": "f3_temple", "tile": "f3_temple_tablet", "count": 15},
            {"zone": "f3_orc", "tile": "f3_orc_palisade", "count": 30}, {"zone": "f3_orc", "tile": "f3_orc_sack", "count": 30},
            {"zone": "f3_orc", "tile": "f3_orc_fire", "count": 12}, {"zone": "f3_orc", "tile": "f3_orc_armor", "count": 10},
            {"zone": "f3_riverbed", "tile": "f3_hill_boulder_d", "count": 40},
        ] + ZPROPS + [
        ],
        "outer_props": [
            {"zone": "f3_witch", "tile": "f3_witch_twisted", "count": 560, "near": 10, "clear": [3, 19]},
            {"zone": "f3_heart", "tile": "f3_witch_twisted", "count": 40, "near": 10, "clear": [3, 19]},
            {"zone": "f3_greentail", "tile": "f3_marsh_oak_t", "count": 140, "near": 9, "clear": [3, 19]},
            {"zone": "f3_greentail", "tile": "f3_marsh_giant_t", "count": 40, "near": 9, "clear": [3, 19]},
            {"zone": "f3_greentail", "tile": "f3_marsh_dead_t", "count": 40, "near": 9, "clear": [3, 19]},
        ],
        "landmarks_prefix": "f2g",
        "landmarks_under": {"v": "f2g_village", "g": "f2g_grass", "f": "f2g_floor"},
        "landmarks": [
            {"node": "or_camp", "at": [-10, -8], "kind": "tent", "foot": [3, 2]}, {"node": "or_camp", "at": [8, -10], "kind": "tent", "foot": [3, 2]},
            {"node": "or_camp", "at": [-14, 6], "kind": "hut", "foot": [4, 2]}, {"node": "or_camp", "at": [12, 8], "kind": "hut", "foot": [4, 2]},
            {"node": "or_camp", "at": [0, 14], "kind": "tent", "foot": [3, 2]}, {"node": "or_camp", "at": [-4, -16], "kind": "watch", "foot": [3, 2]},
            {"node": "or_gate", "at": [0, -4], "kind": "watch", "foot": [3, 2]}, {"node": "or_pit", "at": [-4, -4], "kind": "tent", "foot": [3, 2]},
            {"node": "or_altar", "at": [0, -6], "kind": "watch", "foot": [3, 2]},
            {"node": "st_pines", "at": [0, -4], "kind": "bigtree", "foot": [3, 2]},
            {"node": "heart", "at": [0, -7], "kind": "tower", "foot": [4, 3], "prefix": "f2d", "unders": {"s": "f2d_bridge"}},
            {"node": "heart", "at": [-9, 2], "kind": "tower", "foot": [4, 3], "prefix": "f2d", "unders": {"s": "f2d_bridge"}},
            {"node": "heart", "at": [9, 2], "kind": "tower", "foot": [4, 3], "prefix": "f2d", "unders": {"s": "f2d_bridge"}},
            {"node": "tp_court", "at": [-6, -6], "kind": "angel", "foot": [3, 2], "prefix": "f2d", "unders": {"g": "f2d_grass"}},
            {"node": "tp_court", "at": [7, 5], "kind": "knight", "foot": [2, 2], "prefix": "f2d", "unders": {"g": "f2d_grass"}},
            {"node": "tp_garden", "at": [0, -3], "kind": "angel", "foot": [3, 2], "prefix": "f2d", "unders": {"g": "f2d_grass"}},
            {"node": "tp_hall", "at": [-7, 6], "kind": "knight", "foot": [2, 2], "prefix": "f2d", "unders": {"s": "f2d_bridge"}},
        ] + BIG_EXTRA,
        "ruins": [{"zone": "f3_temple", "tile": "f3_temple_wall", "count": 40}],
        "buildings": [
            {"node": "tp_hall", "at": [-13, -11], "size": [27, 23], "door": "e", "wall": "f3_temple_wall", "floor": "f3_temple_floor"},
            {"node": "tp_court", "at": [12, -16], "size": [7, 6], "door": "s", "wall": "f3_temple_wall", "floor": "f3_temple_floor"},
            {"node": "or_armory", "at": [-4, -9], "size": [8, 5], "door": "s", "wall": "f3_orc_bank", "floor": "f3_orc_ground"},
        ],
        "marks": marks,
        "crypts": [HUT],
    }
    zones_ko = {z: v[0] for z, v in ZONES.items()}
    regions = REGIONS
    witch_nodes = [n["id"] for n in nodes if n["zone"] == "f3_witch" and n["kind"] == "place"]
    return {
        "_comment": "3층 순례자의 길(docs/plans/floor3.md — 사용자 2026-11-14 명세): 2층 네 길(소굴 · 사막 · 망자 · 고블린 숲)의 포탈이 각각 다른 출발점으로 와서, 여러 필드를 지나 중심 첨탑의 4층 포탈로 간다. 지도 = tools/f3_layout.py, 타일 = tools/f3_tiles.py. 마녀의 숲 규칙(witch_forest) = WitchForest · 마녀의 오두막(witch_hut) = WitchHut · 밤하늘(sky_event) = SkyLanterns · 오크 제단(orc_altar) = OrcAltar. 원문에 없는 수치는 모두 임시값(source placeholder)",
        "id": "f3_pilgrim_road", "name_ko": "순례자의 길", "floor": 3,
        "arrival": "floor3_from_forest",
        "arrivals": ["floor3_from_forest", "floor3_from_den", "floor3_from_dead", "floor3_from_desert"],
        "generator": "fields", "close_hours": 240,
        "visibility_cap_m": 9.5, "visibility_source": "placeholder", "ambient_light_m": 7.5, "ambient_source": "placeholder", "ambient_color": "#d8d4e4",
        "zones_ko": zones_ko,
        "zone_vision": {"_comment": "구역마다 시야 배율(높은 언덕은 멀리, 갈대 · 숲은 가깝게) — Floor3Rules. [창작] 임시값",
                        "f3_steel": 1.35, "f3_windpass": 1.25, "f3_reeds": 0.6, "f3_witch": 0.75, "f3_greentail": 0.85, "f3_estuary": 0.9},
        "art": ART,
        "gen": gen,
        "regions": regions,
        "spawn": {"_comment": "2층과 같은 키(원정 날짜 10일). 오크 군락지가 가장 붐빈다(지역 groups). 3일 차가 개체 수 최고점(pack_by_day)",
                  "groups_per_region": [4, 6], "pack_by_day": [[3, 5], [4, 6], [5, 8], [5, 7], [5, 7], [5, 8], [6, 8], [6, 9], [6, 9], [7, 10]],
                  "respawn_hours": 24, "growth_every_hours": 24, "max_extra_groups": 3},
        "features_gap": 6, "features": [], "landmarks": [],
        "portals": [{"id": "to_f4", "dir": "north", "to_floor": 4, "dest": "floor4_from_f3"}],
        "route_spots": ROUTE_SPOTS,
        "witch_forest": dict(WITCH, hut_nodes=witch_nodes),
        "witch_hut": dict(WITCH_HUT, props=HUT_PROPS),
        "sky_event": SKY,
        "orc_altar": ORC_ALTAR,
        "source": "placeholder",
    }




ART = {
    "_comment": "그림: 1 · 2층 재질 · 소품을 다시 쓰고(tools/f3_tiles.py) 구역마다 색조(macro)로 나눈다. 외곽 = 회색 바위산(f2d). 새 재질 그림은 아직 없다(PROGRESS). [창작] 임시값",
    "battleback": {"image": "res://assets/battle/f2_goblin_forest.webp", "half_width": 3.6},
    "palette": {"unexplored": "#000000", "near_black": "#24222a", "tone": "#ece6f4", "memory_tint": "#8c8698", "memory_brightness": 0.5, "memory_desat": 0.3, "keep_hue": True},
    "torch_color": "#ffd0a0",
    "post": {"saturation": 0.8, "vignette_strength": 0.42, "vignette_radius": 0.5, "grain_strength": 0.05},
    "particles": [{"id": "motes", "amount": 30, "lifetime": 12.0, "color": "#d8d0f0", "alpha": 0.22, "scale": [1.0, 2.0], "velocity": [2.0, 5.0],
                   "direction": [0.2, -1.0], "spread": 40.0, "gravity": [0.0, 0.0]}],
    "ambience": {"loop": "f2_forest"},
    "macro": {"_comment": "구역마다 빛깔(지역을 이름 없이도 알아보게). [창작] 임시값", "zones": {z: v[3] for z, v in ZONES.items()},
              "noise": {"freq": 0.04, "amount": 0.18}},
    "abyss": {"cliff": "res://assets/floor/f2d/chasm.webp", "cliff_tiles": 8, "cliff_depth": 2.25, "jag": 0.35, "abyss_color": "#141418",
              "mist_color": "#34303c", "rim_color": "#9c98a4",
              "rise": {"face": "res://assets/floor/f2d/rise_face.webp", "top": "res://assets/floor/f2d/rise_top.webp", "face_tiles": 8, "face_depth": 3,
                       "top_tiles": 8, "jag": 0.3, "soft": 0.55, "fog": 6, "dark": "#1a1a20"},
              "bank": {"depth_tiles": 1.3, "shadow_tiles": 0.9, "shadow_alpha": 0.6}},
}

P = "placeholder"
REGIONS = [
    # 강철바위 언덕 · 바람결 고개
    {"id": "f3_steel_a", "zone": "f3_steel", "name_ko": "강철바위 언덕", "monsters": ["wormstone", "iron_falcon", "steel_hill_guard"],
     "weights": {"wormstone": 3, "iron_falcon": 3, "steel_hill_guard": 2}, "groups": [4, 5], "entry_dist": [25, 0]},
    {"id": "f3_steel_iantro", "zone": "f3_steel", "name_ko": "강철바위 언덕", "monsters": ["iantro"], "weights": {"iantro": 1}, "groups": [1, 2], "pack": [2, 3], "entry_dist": [40, 0]},
    {"id": "f3_windpass", "zone": "f3_windpass", "name_ko": "바람결 고개", "monsters": ["iron_falcon", "wormstone"], "weights": {"iron_falcon": 2, "wormstone": 1}, "groups": [2, 3]},
    # 오크 군락지 — 가장 붐빈다
    {"id": "f3_orc_camp", "zone": "f3_orc", "name_ko": "오크 군락지", "monsters": ["orc_warrior", "orc_archer", "orc_shaman", "orc_great_warrior"],
     "weights": {"orc_warrior": 4, "orc_archer": 3, "orc_shaman": 2, "orc_great_warrior": 1}, "groups": [9, 11], "horde": True,
     "escort": {"orc_great_warrior": {"monster": "orc_warrior", "count": [2, 2]}, "orc_shaman": {"monster": "orc_warrior", "count": [1, 2]}}},
    {"id": "f3_orc_patrol", "zone": "f3_orc", "name_ko": "오크 군락지", "monsters": ["orc_warrior", "orc_archer"], "weights": {"orc_warrior": 2, "orc_archer": 1},
     "groups": [4, 5], "pack": [2, 3]},
    # 칠흑의 강어귀 · 마른 강바닥
    {"id": "f3_estuary", "zone": "f3_estuary", "name_ko": "칠흑의 강어귀", "monsters": ["frogman"], "weights": {"frogman": 1}, "groups": [5, 6], "entry_dist": [20, 0]},
    {"id": "f3_riverbed", "zone": "f3_riverbed", "name_ko": "마른 강바닥", "monsters": ["frogman", "desert_vulture"], "weights": {"frogman": 1, "desert_vulture": 1}, "groups": [1, 2], "pack": [1, 2], "source": P},
    # 녹빛꼬리 습지
    {"id": "f3_greentail", "zone": "f3_greentail", "name_ko": "녹빛꼬리 습지", "monsters": ["lizardman"], "weights": {"lizardman": 1}, "groups": [5, 6], "entry_dist": [20, 0]},
    # 황혼의 비탈길 — 원문 몬스터 없음: 바위사막에서 이어지는 2층 몬스터(임시)
    {"id": "f3_dusk", "zone": "f3_dusk", "name_ko": "황혼의 비탈길", "monsters": ["desert_vulture", "stone_golem", "monolith_soldier"],
     "weights": {"desert_vulture": 3, "stone_golem": 2, "monolith_soldier": 1}, "groups": [3, 4], "entry_dist": [20, 0], "source": P,
     "notes": "원문에 황혼의 비탈길 몬스터가 없다 — 바위사막 몬스터로 임시(사용자 결정 필요)"},
    # 가시갈대 밭 — 원문 몬스터 없음: 마녀의 숲 가장자리 무리(임시)
    {"id": "f3_reeds", "zone": "f3_reeds", "name_ko": "가시갈대 밭", "monsters": ["woodman", "fairy"], "weights": {"woodman": 2, "fairy": 1},
     "groups": [2, 3], "pack": [1, 3], "source": P, "notes": "원문에 가시갈대 밭 몬스터가 없다 — 마녀의 숲 9등급으로 임시"},
    # 마녀의 숲 — 절반 넘게 영체류(물리 면역)
    {"id": "f3_witch", "zone": "f3_witch", "name_ko": "마녀의 숲",
     "monsters": ["fairy", "witch_wraith", "witch_lamp", "woodman", "snetree", "dirouter", "mutant_spirit", "homunculus", "owlbear"],
     "weights": {"fairy": 3, "witch_wraith": 3, "witch_lamp": 3, "woodman": 2, "snetree": 2, "dirouter": 1, "mutant_spirit": 2, "homunculus": 2, "owlbear": 1},
     "groups": [9, 11]},
    {"id": "f3_witch_troll", "zone": "f3_witch", "name_ko": "마녀의 숲", "monsters": ["half_troll"], "weights": {"half_troll": 1}, "groups": [2, 3], "pack": [1, 1]},
    {"id": "f3_witch_dryad", "zone": "f3_witch", "name_ko": "마녀의 숲", "monsters": ["dryad"], "weights": {"dryad": 1}, "groups": [0, 1], "pack": [1, 1],
     "notes": "드라이어드 — 극히 드묾"},
]

ROUTE_SPOTS = {
    "_comment": "지키는 무리(guards — 입장 때 그 구간 가운데에) · 동굴 요소(features) · 매복(ambush — 무명 조각상은 석상 곁에서 일어선다). [창작] 임시값",
    "guards": [
        {"node": "or_gate", "monsters": ["orc_great_warrior", "orc_warrior", "orc_warrior", "orc_archer"]},
        {"node": "or_altar", "monsters": ["orc_great_warrior", "orc_shaman", "orc_warrior", "orc_warrior"]},
        {"node": "or_watch", "monsters": ["orc_archer", "orc_archer", "orc_warrior"]},
        {"node": "or_armory", "monsters": ["orc_warrior", "orc_warrior", "orc_shaman"]},
        {"node": "st_lookout", "monsters": ["steel_hill_guard", "steel_hill_guard"]},
        {"node": "tp_hall", "monsters": ["nameless_statue"]},
        {"node": "tp_colonnade", "monsters": ["nameless_statue"]},
    ],
    "features": [
        {"node": "st_meadow", "event": "dead_campfire", "at": [3, 2], "tile": "f2g_campfire"},
        {"node": "wo3", "event": "f3_explorer_corpse", "at": [2, -2], "tile": "f2d_corpse_g"},
        {"node": "wo9", "event": "f3_explorer_corpse", "at": [-2, 2], "tile": "f2d_corpse_g"},
        {"node": "wi4", "event": "old_skeleton", "at": [2, 1], "tile": "f2d_skeleton"},
        {"node": "tp_hall", "event": "f3_explorer_corpse", "at": [3, -2], "tile": "f2d_corpse_g"},
        {"node": "gt_hollow", "event": "f3_explorer_corpse", "at": [0, 2], "tile": "f2g_corpse"},
        {"node": "du_overlook", "event": "dead_campfire", "at": [1, 1], "tile": "f2g_campfire"},
        {"node": "rb_s", "event": "dead_campfire", "at": [2, 1], "tile": "f2g_campfire"},
        {"node": "es_h", "event": "f3_explorer_corpse", "at": [1, 1], "tile": "f2d_corpse_g"},
    ],
    "ambush": [
        {"on_tiles": ["f3_temple_statue", "f3_temple_statue_c"], "near": 2, "chance": 0.06, "max": 4, "monsters": ["nameless_statue"],
         "line": "field.ambush_statue", "sound": "crumble"},
    ],
}

WITCH = {
    "_comment": "마녀의 숲(WitchForest — docs/plans/floor3.md §4). zone 안에 있으면 statuses가 걸리고 나가면 풀린다. 마녀의 눈 단계는 숲에 처음 든 뒤 흐른 시간(숲 시계 — 숲 밖에서도 흐른다)으로 오른다. 한곳 판정 = 처음 선 칸에서 dwell_radius 칸 안(벗어나면 그 자리에서 다시 센다 — 대기 · 휴식 · 제자리걸음도 머무는 것). 단계별 머무는 한도(wait_hours)를 넘기면 카나바로 1마리. 원문: 1일 차 약 1시간 · 3일 차 약 10분 · 10단계 약 3분 · 12시간 뒤 1단계 · 84시간 뒤 5단계 · 최고 10단계 — 그 사이는 임시값(source placeholder)",
    "zone": "f3_witch",
    "statuses": ["f3_disoriented", "f3_hallucination", "f3_auditory", "f3_pain"],
    "stages": [
        {"stage": 0, "after_hours": 0, "wait_hours": 1.0, "source": "original"},
        {"stage": 1, "after_hours": 12, "wait_hours": 0.5, "source": P},
        {"stage": 2, "after_hours": 30, "wait_hours": 0.3, "source": P},
        {"stage": 3, "after_hours": 48, "wait_hours": 0.1667, "source": "original", "_comment": "3일 차 약 10분"},
        {"stage": 4, "after_hours": 66, "wait_hours": 0.13, "source": P},
        {"stage": 5, "after_hours": 84, "wait_hours": 0.1, "source": P, "_comment": "84시간 — 원문(시점만)"},
        {"stage": 6, "after_hours": 96, "wait_hours": 0.085, "source": P},
        {"stage": 7, "after_hours": 108, "wait_hours": 0.075, "source": P},
        {"stage": 8, "after_hours": 120, "wait_hours": 0.065, "source": P},
        {"stage": 9, "after_hours": 132, "wait_hours": 0.057, "source": P},
        {"stage": 10, "after_hours": 144, "wait_hours": 0.05, "source": P, "_comment": "10단계 약 3분 — 원문(시점은 임시)"},
    ],
    "max_stage": 10,
    "dwell_radius": 6,
    "omen_at": 0.6,
    "hunter": "canavaro",
    "spawn_dist": [9, 14],
    "hunter_cooldown_hours": 1.0,
    "hunter_leash_hours": 0.5,
    "hunter_chase_hours": 6.0,
    "leave_resets_dwell": True,
    "phantoms": {"every_hours": [0.4, 0.9], "max": 3, "dist": [6, 11], "vanish_dist": 3.5, "last_hours": 1.5,
                 "monsters": ["fairy", "witch_wraith", "half_troll", "homunculus", "canavaro"], "false_tree_chance": 0.35},
    "whispers": {"every_hours": [0.15, 0.45], "sounds": ["f3_whisper", "f3_laugh", "f3_branch", "monster_alert", "f3_footsteps"]},
    "disorient": {"no_memory": True, "drift_every_hours": [0.3, 0.8], "drift_hours": 0.05},
    "pain": {"shake_mult": 2.5, "_comment": "통각강화: 원문 핵심은 '통증 체감이 몇 배' — 피해량은 그대로 두고 맞을 때 흔들림 · 붉은 번쩍임을 shake_mult배(CombatScreen). 피해까지 늘리려면 statuses.json f3_pain에 dmg_taken:all 수정자"},
    "lines": {"omen": "f3.witch_omen", "hunter": "f3.witch_hunter", "stage": "f3.witch_eye_stage", "first": "f3.witch_enter_first"},
}

WITCH_HUT = {
    "_comment": "마녀의 오두막(WitchHut — floor3.md §5): 숲 구간(hut_nodes)에 보랏빛 나무가 확률로 생긴다(check_every_hours마다 spawn_chance — 운이 나쁘면 며칠 없다). 나무는 open_hours 동안 남고, 들어가면 오두막도 open_hours 동안. 정원 capacity(파티가 넘치면 못 들어간다 · 찬 입구는 닫힌다). 모닥불에 시신(corpse_items 아이템)을 바치면 extend_hours 연장(한 번에 하나 · 시신마다 한 번). 시간이 다 되면 숲으로 밀려난다. [창작] 임시값 — 시점 · 확률은 원문에 없다",
    "check_every_hours": 6.0, "spawn_chance": 0.35, "max_open": 2, "open_hours": 8.0, "extend_hours": 8.0, "capacity": 5,
    "corpse_items": ["wrapped_corpse"],
    "hidden_piece": {"reward": [], "_comment": "히든 피스 보상은 원문에 없다 — 정하면 reward에 [{item, count}]. 비어 있으면 '무언가를 손에 넣었다'만 남고 기록(GameState.flags)만 한다"},
    "riakis_flag": "riakis_slain",
    "lines": {"enter": "f3.hut_enter", "full": "f3.hut_full", "closed": "f3.hut_closed", "expire": "f3.hut_expire", "offer": "f3.hut_offer",
              "offer_none": "f3.hut_offer_none", "left": "f3.hut_left", "hearth": "f3.hut_hearth", "hearth_cold": "f3.hut_hearth_cold",
              "hidden": "f3.hut_hidden", "winter": "f3.hut_winter"},
}

SKY = {
    "_comment": "강철바위 언덕 밤하늘(SkyLanterns — floor3.md §6): 3층에 든 뒤 after_hours가 지난 첫 밤(from~to 시각)에 한 번, 실제 duration_sec초 동안 땅에서 은빛 구체가 떠올라 천장에서 사라지고 하늘이 밝아졌다 돌아온다. 화면은 강철바위 언덕(zones)에서만 그린다(다른 곳에서는 빛 구체가 멀리 보이는 정도 — far_alpha). [창작] 시각은 임시값",
    "after_hours": 48, "from": 20, "to": 4, "duration_sec": 60.0, "zones": ["f3_steel", "f3_windpass"], "far_alpha": 0.25,
    "orbs": 90, "color": "#dce4ff", "brighten": 0.35,
}

ORC_ALTAR = {
    "_comment": "오크 군락지 제단(OrcAltar — floor3.md §3): 오크 대전사 마석(stone)을 바친다. 원작 777개 → 우리 게임 offer_count(임시값 — 사용자 결정 필요). 다 차면 오크 히어로(hero) 셋이 제단 앞에 선다, lord_chance로 대신 오크 로드. 한 원정에 한 번",
    "tile": "f3_orc_altar", "stone": "magic_stone_7", "offer_count": 777, "offer_count_source": "original",
    "hero": ["orc_hero", "orc_hero", "orc_hero"], "lord": ["orc_lord"], "lord_chance": 0.02, "lord_chance_source": P,
    "lines": {"look": "f3.altar_look", "offer": "f3.altar_offer", "rise": "f3.altar_rise", "rise_lord": "f3.altar_rise_lord"},
}


def main():
    d = floor_json()
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print("3층:", len(nodes), "구간", len(edges), "길 →", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
