#!/usr/bin/env python3
"""야수의 소굴 손으로 짠 지도(1단계 — 사용자 2026-11-07 "다음 단계 진행", floor2.md §2 · §13-4, level_design_review.md B-2 C, LD11).

거대한 메사(솟은 외곽 f2d_rise — 걷지 못하는 협곡 벽) 사이를 폭 3~4칸 협곡이 잇는다. 고리 셋(바깥 협곡 → 두더지 벽 → 깊은 굴)을
갈림길 셋이 잇고, 갈림길마다 두 갈래 중 하나만 원정마다 열린다(RouteForks — 나머지는 끝에서 무너진 돌로 막힌다). 갈래 입구의 단서:
고리 1 = 바람, 고리 2 = 벽의 굴 수, 고리 3 = 발톱 자국의 방향. 갈림길마다 비탈로 오르는 바위턱(망루 요소 — 내려다보면 막힌 갈래가 보인다).
그림은 1단계라 망자의 땅 굳은 흙 · 바위 그림을 쓰고 층 색조로 붉은 사암빛을 준다(새 타일 그림 없음).

  python3 tools/f2b_layout.py            # data/floors/f2_beast_den.json 생성 + 미리보기 docs/plans/f2_beast_den_layout.png

글자: ' ' = 메사(솟은 외곽) · '.' 굳은 흙 · ':' 진흙(깊은 굴). (낮은 협곡 · 비탈 · 둔덕은 2단계 — 1단계에서 높낮이 경계가 돌무더기로 막혀 뺐다)
"""
import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOOR = os.path.join(ROOT, "data/floors/f2_beast_den.json")
W, H = 140, 132
LEGEND = {".": "f2d_hard", ":": "f2d_mud", "l": "f2d_hard_low", "/": "f2d_slope", "m": "f2d_mound"}

rng = random.Random(11)
grid = [[" "] * W for _ in range(H)]
marks = {}
props = []      # (tile, x, y)
landmarks = []  # (kind, x, y, foot)


def put(x, y, ch, over=True):
    if 2 <= x < W - 2 and 2 <= y < H - 2 and (over or grid[y][x] == " "):
        grid[y][x] = ch


def disk(cx, cy, r, ch, rough=0.2, over=True):
    ph = rng.random() * 6.28
    for y in range(int(cy - r * 1.4) - 1, int(cy + r * 1.4) + 2):
        for x in range(int(cx - r * 1.4) - 1, int(cx + r * 1.4) + 2):
            a = math.atan2(y - cy, x - cx)
            rr = r * (1.0 + rough * (math.sin(a * 3 + ph) * 0.6 + math.sin(a * 7 + ph * 1.7) * 0.4))
            if math.hypot(x - cx, y - cy) <= rr:
                put(x, y, ch, over)


def path(pts, width, ch, wig=1.2, over=True):
    """점을 잇는 굽은 협곡(폭 width — 구간마다 조금씩 넓어지고 좁아진다)."""
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(bx - ax, by - ay)))
        nx, ny = -(by - ay) / n, (bx - ax) / n
        for i in range(n + 1):
            u = i / n
            off = math.sin(u * math.pi * 2 + ax * 0.37) * wig * math.sin(u * math.pi)
            w = width + (1 if math.sin(u * 9 + ay) > 0.6 else 0)
            cx, cy = ax + (bx - ax) * u + nx * off, ay + (by - ay) * u + ny * off
            for dy in range(-w, w + 1):
                for dx in range(-w, w + 1):
                    if dx * dx + dy * dy <= (w * 0.5 + 0.6) ** 2 * 1.0:
                        put(int(round(cx + dx * 0.5)), int(round(cy + dy * 0.5)), ch, over)


def mark(name, x, y):
    marks[name] = (x, y)


# ── 고리 1: 바깥 협곡(남쪽 띠) ──
mark("arrival", 10, 114)
disk(10, 114, 5, ".")
path([(10, 114), (24, 118), (40, 112)], 4, ".")
disk(40, 110, 8, ".")                         # 바깥 협곡 터(늑대 무리 · 샘)
mark("outer_hub", 40, 110)
mark("outer_spring", 45, 105)
path([(40, 112), (58, 118), (77, 122)], 3, ".")  # 곁길 — 곰굴 자리(2단계 반달바위곰)
disk(76, 122, 5, ".")
mark("bear_cave", 77, 122)
path([(40, 110), (46, 106), (58, 103)], 3, ".")
disk(58, 103, 4, ".")
mark("fork1", 58, 103)
# 갈래 서: 북서로 크게 휘어 고리 2 입구로
path([(55, 100), (44, 92), (42, 82), (54, 74), (62, 70)], 3, ".")
mark("f1_w_mouth", 53, 99)
mark("f1_w_block", 47, 78)
# 갈래 동: 북동으로
path([(61, 100), (78, 96), (84, 86), (70, 74), (62, 70)], 3, ".")
mark("f1_e_mouth", 63, 99)
mark("f1_e_block", 77, 78)
# 바위턱 1: 터 서쪽에서 비탈로 올라 서쪽 갈래를 내려다본다
path([(38, 106), (34, 104), (28, 96), (26, 92)], 2, ".")
disk(26, 92, 4, ".")
mark("ledge1", 26, 92)

# ── 고리 2: 두더지 벽(가운데 띠, 동서로 긴 협곡) ──
disk(62, 70, 7, ".")
mark("wall_hub", 62, 70)
path([(28, 64), (62, 66), (108, 62)], 3, ".")
disk(28, 64, 5, ".")                          # 서쪽 끝 — 짐승 뼈 무덤
mark("bone_pit", 28, 64)
disk(108, 62, 7, ":")                         # 동쪽 끝 — 늑대 소굴(곁길)
mark("wolf_lair", 108, 62)
mark("lair_tracks", 92, 64)
path([(62, 70), (62, 54)], 3, ".")
disk(62, 54, 4, ".")
mark("fork2", 62, 54)
path([(59, 51), (46, 44), (48, 32), (60, 26), (62, 22)], 3, ".")
mark("f2_w_mouth", 58, 50)
mark("f2_w_block", 50, 31)
path([(65, 51), (80, 44), (78, 32), (66, 26), (62, 22)], 3, ".")
mark("f2_e_mouth", 66, 50)
mark("f2_e_block", 75, 31)
path([(62, 58), (70, 58), (82, 54), (86, 52)], 2, ".")
disk(86, 52, 3, ".")
mark("ledge2", 86, 52)

# ── 고리 3: 깊은 굴(북쪽 — 진흙 바닥) ──
disk(62, 22, 7, ":")
mark("deep_hub", 62, 22)
path([(62, 22), (80, 20)], 3, ":")
disk(80, 20, 4, ":")
mark("fork3", 80, 20)
path([(83, 17), (94, 10), (110, 9), (122, 14), (125, 14)], 3, ":")
mark("f3_n_mouth", 84, 16)
mark("f3_n_block", 112, 9)
path([(83, 23), (96, 28), (112, 26), (122, 16), (125, 14)], 3, ":")
mark("f3_s_mouth", 84, 24)
mark("f3_s_block", 113, 26)
disk(124, 14, 5, ".")
mark("exit", 125, 14)
path([(62, 22), (56, 18), (44, 12), (42, 10)], 2, ".")
disk(42, 10, 3, ".")
mark("ledge3", 42, 10)
path([(62, 22), (62, 34)], 2, ":")            # 깊은 굴 남쪽 주머니 — 탐험가 시체

# 바위 · 죽은 나무 · 돌무더기(협곡 안 — 길을 굽게 한다, 지나갈 틈은 남긴다)
for (x, y) in [(36, 107), (44, 113), (60, 66), (66, 73), (100, 63), (58, 20), (66, 24), (30, 66), (104, 60)]:
    if grid[y][x] in ".:":
        props.append(("f2d_rock", x, y))
for (x, y) in [(15, 112), (42, 116), (72, 120), (64, 69), (110, 65)]:
    if grid[y][x] in ".:":
        props.append(("f2d_deadtree", x, y))

# 불카르(바위에 붙은 위장 짐승) · 벽두더지 매복 자리와 그 앞 단서(흙이 흘러내리는 벽)
mark("bulkar_outer", 35, 108)
mark("bulkar_wall", 99, 62)
mark("bulkar_deep", 66, 25)
mark("mole_a", 42, 65)
mark("mole_a_sign", 48, 66)
mark("mole_b", 84, 64)
mark("mole_b_sign", 78, 65)
mark("mole_c", 62, 59)
mark("mole_c_sign", 62, 63)

# 갈래 입구 · 막는 자리는 협곡 칸 위로(흔들린 길에서 벗어나지 않게 — 가장 가까운 바닥 칸)
for nm in list(marks):
    if "mouth" in nm or "block" in nm or "ledge" in nm or "mole" in nm or "bulkar" in nm:
        x0, y0 = marks[nm]
        if grid[y0][x0] == " ":
            best = min(((x, y) for y in range(y0 - 6, y0 + 7) for x in range(x0 - 6, x0 + 7) if grid[y][x] != " "),
                       key=lambda c: (c[0] - x0) ** 2 + (c[1] - y0) ** 2)
            marks[nm] = best

# ── 층 JSON ──
ex, ey = marks["arrival"]
rel = lambda x, y: [x - ex, y - ey]
zone_of = {"arrival": "f2b_outer", "outer_hub": "f2b_outer", "bear_cave": "f2b_outer", "fork1": "f2b_outer", "ledge1": "f2b_outer",
           "wall_hub": "f2b_wall", "bone_pit": "f2b_wall", "wolf_lair": "f2b_wall", "fork2": "f2b_wall", "ledge2": "f2b_wall",
           "deep_hub": "f2b_deep", "fork3": "f2b_deep", "exit": "f2b_deep", "ledge3": "f2b_deep"}
nodes = []
for nm, z in zone_of.items():
    x, y = marks[nm]
    nd = {"id": nm, "at": [x, y], "r": 1, "zone": z, "kind": "place"}
    if nm == "arrival":
        nd["kind"] = "arrival"
    if nm == "exit":
        nd["kind"] = "exit"
    nodes.append(nd)
nodes[0]["props"] = [{"tile": t, "at": [rel(x, y)]} for t, x, y in props]
gen = {
    "_comment": "야수의 소굴 손으로 짠 지도(tools/f2b_layout.py — floor2.md §2, LD11): 지도 전체 = stamps 하나, 자리 = marks. 다시 만들려면 스크립트를 고쳐 다시 돌린다. [창작] 임시값",
    "grammar": "route", "size": [W, H], "seed": 3,
    "tiles": {"rise": "f2d_rise", "floor": "f2d_hard", "down": "f2_stone_down", "up": "f2_portal_up"},
    "zone_fill": {"f2b_outer": "f2d_rise", "f2b_wall": "f2d_rise", "f2b_deep": "f2d_rise"},
    "zone_floor": {"f2b_outer": "f2d_hard", "f2b_wall": "f2d_hard", "f2b_deep": "f2d_mud"},
    "zone_low": {"f2b_outer": "f2d_hard_low", "f2b_wall": "f2d_hard_low", "f2b_deep": "f2d_hard_low"},
    "levels": {"scree": "f2d_scree", "ramp": "f2d_slope"},
    "nodes": nodes, "edges": [], "props": [],
    "stamps": [{"node": "arrival", "at": [-ex, -ey], "legend": LEGEND, "rows": ["".join(r) for r in grid]}],
    "marks": [{"name": nm, "node": "arrival", "at": rel(x, y)} for nm, (x, y) in marks.items()],
}
fork_common = {"block_tile": "f2d_scree", "block_r": 2}
route_spots = {
    "_comment": "갈림길 셋(forks — RouteForks: 원정마다 바른 갈래 하나, 나머지는 끝이 무너진 돌로 막힘 · 입구 단서 요소) · 바위턱(망루 — 내려다보기) · 곁길 보상 · 지키는 무리 · 협곡 매복. [창작] 임시값",
    "forks": [
        dict(fork_common, branches=[{"mouth": "f1_w_mouth", "block": "f1_w_block"}, {"mouth": "f1_e_mouth", "block": "f1_e_block"}],
             right="den_draft", wrong="den_still"),
        dict(fork_common, branches=[{"mouth": "f2_w_mouth", "block": "f2_w_block"}, {"mouth": "f2_e_mouth", "block": "f2_e_block"}],
             right="den_quiet_wall", wrong="den_burrowed"),
        dict(fork_common, branches=[{"mouth": "f3_n_mouth", "block": "f3_n_block"}, {"mouth": "f3_s_mouth", "block": "f3_s_block"}],
             right="den_tracks_in", wrong="den_tracks_out"),
    ],
    "guards": [
        {"mark": "wolf_lair", "monsters": ["giant_blade_wolf", "blood_blade_wolf", "blade_wolf", "blade_wolf", "blade_wolf"]},
        {"mark": "deep_hub", "at": [0, -3], "monsters": ["werewolf", "blood_blade_wolf", "blood_blade_wolf", "giant_blade_wolf"]},
        {"mark": "bear_cave", "monsters": ["moon_rock_bear"]},
        {"mark": "bone_pit", "monsters": ["mole_queen", "wall_mole", "wall_mole"]},
        {"mark": "bulkar_outer", "monsters": ["bulkar"]},
        {"mark": "bulkar_wall", "monsters": ["bulkar"]},
        {"mark": "bulkar_deep", "monsters": ["bulkar"]},
    ],
    "features": [
        {"mark": "outer_spring", "event": "clear_spring", "tile": "f2d_cairn"},
        {"mark": "outer_hub", "event": "dead_campfire", "at": [-4, 3], "tile": "f2d_campfire"},
        {"mark": "bear_cave", "event": "explorer_corpse", "at": [3, 1], "tile": "f2d_corpse_g"},
        {"mark": "bear_cave", "event": "hidden_cache", "at": [-3, -2]},
        {"mark": "ledge1", "event": "watch_post", "tile": "f2d_cairn"},
        {"mark": "ledge2", "event": "watch_post", "tile": "f2d_cairn"},
        {"mark": "ledge3", "event": "watch_post", "tile": "f2d_cairn"},
        {"mark": "bone_pit", "event": "old_skeleton", "at": [1, 1], "tile": "f2d_skeleton"},
        {"mark": "bone_pit", "event": "explorer_corpse", "at": [-2, -1], "tile": "f2d_corpse_g"},
        {"mark": "wolf_lair", "event": "wolf_den", "at": [3, 0]},
        {"mark": "lair_tracks", "event": "wolf_tracks"},
        {"mark": "deep_hub", "event": "explorer_corpse", "at": [0, 11], "tile": "f2d_corpse_g"},
        {"mark": "deep_hub", "event": "hidden_cache", "at": [1, 12]},
        {"mark": "f1_w_block", "event": "explorer_corpse", "at": [0, 3], "tile": "f2d_corpse_g"},
        {"mark": "f2_e_block", "event": "old_skeleton", "at": [0, 3], "tile": "f2d_skeleton"},
        {"mark": "mole_a_sign", "event": "den_mole_holes"},
        {"mark": "mole_b_sign", "event": "den_mole_holes"},
        {"mark": "mole_c_sign", "event": "den_mole_holes"},
    ],
    "ambush": [
        {"mark": "mole_a", "monsters": ["wall_mole", "wall_mole"], "radius": 2, "line": "field.ambush_mole", "sound": "crumble", "stops_if_gone": "mole_queen"},
        {"mark": "mole_b", "monsters": ["wall_mole", "wall_mole"], "radius": 2, "line": "field.ambush_mole", "sound": "crumble", "stops_if_gone": "mole_queen"},
        {"mark": "mole_c", "monsters": ["wall_mole", "wall_mole", "wall_mole"], "radius": 2, "line": "field.ambush_mole", "sound": "crumble", "stops_if_gone": "mole_queen"},
        {"mark": "f1_w_mouth", "at": [-6, -6], "monsters": ["blade_wolf", "blade_wolf"], "radius": 3, "line": "field.ambush_wolf", "sound": "wolf_growl"},
        {"mark": "f2_e_mouth", "at": [8, -4], "monsters": ["blood_blade_wolf", "blade_wolf"], "radius": 3, "line": "field.ambush_wolf", "sound": "wolf_growl"},
        {"mark": "f3_s_mouth", "at": [8, 3], "monsters": ["sabertooth"], "radius": 3, "line": "field.ambush_wolf", "sound": "wolf_growl"},
    ],
}
d = {
    "_comment": "2층 야수의 소굴(docs/plans/floor2.md §2 · §13-4, level_design_review.md B-2 C — 1단계 LD11): 1층 동쪽 포탈(dest floor2_east)에서 온다. 메사 사이 협곡 고리 셋 · 갈림길 셋(원정마다 바른 갈래 — 바람 · 벽의 굴 · 발톱 자국) · 바위턱. 새 몬스터 다섯(LD12 — 2단계): 벽두더지(두더지 벽 무리 · 벽 매복) · 여왕(뼈 무덤 굴 — 쓰러뜨리면 매복이 멈춤) · 반달바위곰(곰굴) · 불카르(바위 곁 위장 셋) · 웨어울프(깊은 굴 우두머리) + 칼날늑대 무리 · 샤벨타이거. 그림은 망자의 땅 흙 · 바위 + 붉은 사암 색조. 수치는 모두 임시값",
    "id": "f2_beast_den", "name_ko": "짐승의 소굴", "floor": 2, "arrival": "floor2_east", "generator": "fields", "close_hours": 240,
    "visibility_cap_m": 9.5, "visibility_source": "placeholder", "ambient_light_m": 7.5, "ambient_source": "placeholder", "ambient_color": "#e0c8a8",
    "art": {
        "_comment": "1단계: 망자의 땅 바닥 · 외곽 그림(assets/floor/f2d)을 붉은 사암 색조로. 전투 뒷그림도 망자의 땅 것을 잠시 쓴다(2단계에서 협곡 그림). [창작] 임시값",
        "battleback": {"image": "res://assets/battle/f2_land_of_dead.webp", "half_width": 3.6},
        "palette": {"unexplored": "#000000", "near_black": "#2e241c", "tone": "#f4dcc0", "memory_tint": "#9a8670", "memory_brightness": 0.5, "memory_desat": 0.3, "keep_hue": True},
        "torch_color": "#ffc890",
        "post": {"saturation": 0.75, "vignette_strength": 0.45, "vignette_radius": 0.5, "grain_strength": 0.05},
        "particles": [{"id": "dust", "amount": 40, "lifetime": 10.0, "color": "#e8c8a0", "alpha": 0.25, "scale": [1.0, 2.0], "velocity": [6.0, 12.0], "direction": [1.0, 0.1], "spread": 20.0, "gravity": [0.0, 0.0]}],
        "ambience": {"loop": "f2_den"},
        "abyss": {"cliff": "res://assets/floor/f2d/chasm.webp", "cliff_tiles": 8, "cliff_depth": 2.25, "jag": 0.35, "abyss_color": "#1a1410", "mist_color": "#3e342a", "rim_color": "#b09a80",
                  "rise": {"face": "res://assets/floor/f2d/rise_face.webp", "top": "res://assets/floor/f2d/rise_top.webp", "face_tiles": 8, "face_depth": 3, "top_tiles": 8, "jag": 0.3, "fog": 6, "dark": "#241c16"},
                  "bank": {"depth_tiles": 1.3, "shadow_tiles": 0.9, "shadow_alpha": 0.6}},
        "decor": {"_comment": "바닥 잔해(1층 데칼 시트 — 실행 중 계산): 협곡 자갈 · 발톱 자국 · 뼈. [창작] 임시값", "sheet": "res://assets/floor/f1/decals.webp", "variants": 4,
                  "kinds": ["shore", "gravel", "moss", "wet", "crystal_bits", "claws", "mud", "rot", "trash", "bones"], "on_tiles": ["f2d_hard", "f2d_mud", "f2d_hard_low", "f2d_mound"],
                  "rules": [{"kind": "gravel", "wall_north": True, "dense": True, "chance": 0.35},
                            {"kind": "claws", "near_features": {"ids": ["wolf_den", "wolf_tracks"], "radius": 6}, "chance": 0.6},
                            {"kind": "bones", "near_features": {"ids": ["explorer_corpse", "old_skeleton", "wolf_den"], "radius": 5}, "chance": 0.5},
                            {"kind": "claws", "zones": ["f2b_deep"], "noise": {"key": "claws", "freq": 0.06, "above": 0.5}, "chance": 0.5},
                            {"kind": "mud", "zones": ["f2b_deep"], "chance": 0.12},
                            {"kind": "bones", "zones": ["f2b_wall"], "noise": {"key": "bones", "freq": 0.05, "above": 0.55}, "chance": 0.4},
                            {"kind": "gravel", "chance": 0.1}]},
    },
    "gen": gen,
    "regions": [
        {"id": "f2b_outer", "zone": "f2b_outer", "name_ko": "바깥 협곡", "monsters": ["blade_wolf", "giant_blade_wolf"], "weights": {"blade_wolf": 6, "giant_blade_wolf": 1}, "groups": [5, 6], "horde": True, "entry_dist": [30, 0]},
        {"id": "f2b_outer_lone", "zone": "f2b_outer", "name_ko": "바깥 협곡", "monsters": ["blade_wolf"], "weights": {"blade_wolf": 1}, "groups": [3, 4], "pack": [1, 1], "entry_dist": [10, 40]},
        {"id": "f2b_wall", "zone": "f2b_wall", "name_ko": "두더지 벽", "monsters": ["blade_wolf", "blood_blade_wolf", "sabertooth", "wall_mole"], "weights": {"blade_wolf": 4, "blood_blade_wolf": 2, "sabertooth": 1, "wall_mole": 3}, "groups": [4, 5]},
        {"id": "f2b_deep", "zone": "f2b_deep", "name_ko": "깊은 굴", "monsters": ["blood_blade_wolf", "giant_blade_wolf", "sabertooth", "chimera_wolf"], "weights": {"blood_blade_wolf": 3, "giant_blade_wolf": 2, "sabertooth": 1, "chimera_wolf": 1}, "groups": [4, 5]},
    ],
    "spawn": {"_comment": "망자의 땅과 같은 키(원정 날짜 10일). 바깥 협곡 늑대 큰 무리는 horde", "groups_per_region": [4, 5],
              "pack_by_day": [[4, 6], [4, 7], [5, 8], [6, 9], [6, 10], [7, 11], [8, 12], [9, 13], [10, 14], [12, 15]],
              "respawn_hours": 24, "growth_every_hours": 24, "max_extra_groups": 3},
    "features_gap": 6, "features": [], "landmarks": [],
    "portals": [{"id": "to_f3_den", "dir": "north", "to_floor": 3, "dest": "floor3_from_den"}],
    "source": "original",
    "route_spots": route_spots,
}
json.dump(d, open(FLOOR, "w"), ensure_ascii=False, indent=2)
open(FLOOR, "a").write("\n")

try:
    from PIL import Image, ImageDraw
    col = {" ": (60, 40, 30), ".": (170, 130, 95), ":": (110, 85, 65), "l": (130, 100, 75), "/": (190, 160, 110), "m": (200, 170, 120)}
    S = 4
    im = Image.new("RGB", (W * S, H * S))
    dr = ImageDraw.Draw(im)
    for y in range(H):
        for x in range(W):
            dr.rectangle([x * S, y * S, x * S + S - 1, y * S + S - 1], fill=col[grid[y][x]])
    for nm, (x, y) in marks.items():
        c = (255, 90, 70) if "block" in nm else (255, 230, 120)
        dr.ellipse([x * S - 4, y * S - 4, x * S + 4, y * S + 4], outline=c)
        dr.text((x * S + 6, y * S - 6), nm, fill=(255, 240, 200))
    im.save(os.path.join(ROOT, "docs/plans/f2_beast_den_layout.png"))
except ImportError:
    pass
print("지도 %d × %d, 표시 %d, 소품 %d" % (W, H, len(marks), len(props)))
