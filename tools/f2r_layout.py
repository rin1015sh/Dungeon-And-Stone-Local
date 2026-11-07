#!/usr/bin/env python3
"""바위사막 손으로 짠 지도(1단계 — floor2.md §4 · §13-5, level_design_review.md B-2 D, LD14).

검은 바위산(솟은 외곽) 사이 모래 평원. 본길 = 서쪽 도착 비석에서 남쪽으로 크게 도는 **횃불 옛길**(돌 화로가 줄지어 — 빛 · 그늘 · 쉼),
지름길 = 가운데 **모래 바다**(걸으면 진동 — 샌드웜, DesertRules). 옛길 위 장소: 무너진 열주(석조 잔해 — 그늘) → 돌 거인 광장(관문 —
서 있는 석상 병사) → 바위틈 샘(남쪽 곁길 — 그늘 · 물) → 신전 앞뜰(3층 포탈, 북동). 곁길: 코볼트 굴(북서 바위산 — 2단계 코볼트, 지금 타락한 노움).
모래 언덕(흙 둔덕 — 시야만 가림)이 남쪽에 흩어져 있다. 그림은 1단계라 망자의 땅 흙 · 잔해 · 화로 + 빙하굴 눈밭(모래 바다)을 층 색조로.

  python3 tools/f2r_layout.py            # data/floors/f2_rock_desert.json 생성 + 미리보기 docs/plans/f2_rock_desert_layout.png

글자: ' ' 바위산 · '.' 굳은 흙(옛길 · 평원) · '~' 모래 바다 · 'n' 모래 언덕(둔덕) · 'R' 석조 잔해(벽) · 'F' 돌 화로 · 'S' 무너진 석상.
"""
import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOOR = os.path.join(ROOT, "data/floors/f2_rock_desert.json")
W, H = 150, 120
LEGEND = {".": "f2d_hard", "~": "f2r_sand", "n": "f2d_mound", "R": "f2d_ruin", "F": "f2d_fire", "S": "f2d_statue"}

rng = random.Random(23)
grid = [[" "] * W for _ in range(H)]
marks = {}


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


def path(pts, width, ch, wig=1.5, over=True):
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(bx - ax, by - ay)))
        nx, ny = -(by - ay) / n, (bx - ax) / n
        for i in range(n + 1):
            u = i / n
            off = math.sin(u * math.pi * 2 + ax * 0.31) * wig * math.sin(u * math.pi)
            cx, cy = ax + (bx - ax) * u + nx * off, ay + (by - ay) * u + ny * off
            r = width * 0.5 + 0.3
            for dy in range(-width, width + 1):
                for dx in range(-width, width + 1):
                    if dx * dx + dy * dy <= r * r:
                        put(int(round(cx + dx)), int(round(cy + dy)), ch, over)


def mark(name, x, y):
    marks[name] = (x, y)


# ── 모래 바다(가운데 — 지름길): 넓게 먼저 깔고, 옛길 · 장소를 그 위에 ──
for (cx, cy, r) in [(62, 42, 16), (80, 36, 18), (98, 32, 16), (114, 30, 12), (48, 48, 10)]:
    disk(cx, cy, r, "~", rough=0.25)
mark("sea_mid", 80, 36)

# ── 본길: 횃불 옛길(남쪽으로 크게 돈다) ──
road = [(8, 62), (22, 66), (38, 62), (52, 76), (70, 84), (88, 80), (104, 70), (118, 56), (128, 42), (134, 30)]
path(road, 4, ".")
mark("arrival", 8, 62)
disk(8, 62, 5, ".")
disk(38, 62, 8, ".")            # 무너진 열주(석조 잔해 — 그늘)
mark("colonnade", 38, 62)
disk(70, 84, 9, ".")            # 돌 거인 광장(관문)
mark("plaza", 70, 84)
disk(134, 28, 7, ".")           # 신전 앞뜰(3층 포탈)
mark("exit", 135, 27)
disk(104, 70, 5, ".")
mark("road_east", 104, 70)
# 바위틈 샘(남쪽 곁길 — 바위산 그늘)
path([(88, 80), (92, 96), (86, 104)], 3, ".")
disk(85, 105, 4, ".")
mark("seep", 85, 106)
# 코볼트 굴(북서 곁길)
path([(38, 62), (30, 44), (24, 28)], 3, ".")
disk(22, 24, 6, ".")
mark("cave", 22, 24)
# 모래 바다로 들어서는 어귀 둘(열주 북동 · 옛길 동쪽) — 바다를 건너면 앞뜰 곧장
path([(44, 56), (50, 50)], 3, ".")
path([(118, 56), (114, 42)], 3, ".")
path([(122, 30), (130, 28)], 3, ".")

# 석조 잔해(열주 — 기둥 줄 · 무너진 벽) · 돌 화로(옛길 따라 12칸마다) · 무너진 석상
for k in range(5):
    for s in (-1, 1):
        put(32 + k * 3, 62 + s * 5, "R")
for x, y in [(44, 66), (45, 66), (31, 58)]:
    put(x, y, "R")
fires = []
acc = 0.0
for (ax, ay), (bx, by) in zip(road, road[1:]):
    n = int(math.hypot(bx - ax, by - ay))
    for i in range(n):
        acc += 1
        if acc >= 10:
            acc = 0
            u = i / n
            x, y = int(ax + (bx - ax) * u), int(ay + (by - ay) * u)
            nx, ny = -(by - ay) / n, (bx - ax) / n
            for k in (3, -3, 2, -2):  # 길 가장자리(둘 중 바닥인 쪽 — 길을 막지 않게 가운데는 비운다)
                fx, fy = int(round(x + nx * k)), int(round(y + ny * k))
                if 2 < fx < W - 3 and 2 < fy < H - 3 and grid[fy][fx] == "." and all(abs(fx - a) + abs(fy - b) > 6 for a, b in fires):
                    put(fx, fy, "F")
                    fires.append((fx, fy))
                    break
for x, y in [(62, 80), (78, 80), (66, 90), (74, 90)]:   # 광장 둘레 무너진 석상
    put(x, y, "S")
# 모래 언덕(남쪽 평원 — 둔덕): 옛길 남쪽에 몇 덩이
for (cx, cy) in [(24, 76), (40, 84), (100, 90), (116, 74)]:
    disk(cx, cy, 5, ".", over=False)
    disk(cx, cy, 2.5, "n")
path([(22, 66), (24, 76)], 2, ".")
path([(52, 76), (40, 84)], 2, ".")
path([(104, 70), (100, 90)], 2, ".")
path([(118, 56), (116, 74)], 2, ".")
mark("dune_w", 24, 79)
mark("dune_e", 100, 93)
# 모래에 묻힌 짐(바다 한가운데 — 위험한 곳의 보상) · 잔해 그늘 자리
mark("buried_a", 72, 38)
mark("buried_b", 104, 30)

for nm in list(marks):
    x0, y0 = marks[nm]
    if grid[y0][x0] not in ".~":
        best = min(((x, y) for y in range(y0 - 6, y0 + 7) for x in range(x0 - 6, x0 + 7) if grid[y][x] in ".~"),
                   key=lambda c: (c[0] - x0) ** 2 + (c[1] - y0) ** 2)
        marks[nm] = best

ex, ey = marks["arrival"]
rel = lambda x, y: [x - ex, y - ey]
zone_of = {"arrival": "f2r_road", "colonnade": "f2r_road", "plaza": "f2r_road", "road_east": "f2r_road", "seep": "f2r_road",
           "dune_w": "f2r_road", "dune_e": "f2r_road", "exit": "f2r_road", "sea_mid": "f2r_sea", "buried_a": "f2r_sea", "buried_b": "f2r_sea",
           "cave": "f2r_cave"}
nodes = []
for nm, z in zone_of.items():
    x, y = marks[nm]
    nd = {"id": nm, "at": [x, y], "r": 1, "zone": z, "kind": "place"}
    if nm == "arrival":
        nd["kind"] = "arrival"
    if nm == "exit":
        nd["kind"] = "exit"
    nodes.append(nd)
gen = {
    "_comment": "바위사막 손으로 짠 지도(tools/f2r_layout.py — floor2.md §4, LD14): 지도 전체 = stamps 하나, 자리 = marks. [창작] 임시값",
    "grammar": "route", "size": [W, H], "seed": 4,
    "tiles": {"rise": "f2d_rise", "floor": "f2d_hard", "down": "f2_stone_down", "up": "f2_portal_up"},
    "zone_fill": {"f2r_road": "f2d_rise", "f2r_sea": "f2d_rise", "f2r_cave": "f2d_rise"},
    "zone_floor": {"f2r_road": "f2d_hard", "f2r_sea": "f2r_sand", "f2r_cave": "f2d_hard"},
    "levels": {"scree": "f2d_scree", "ramp": "f2d_slope"},
    "nodes": nodes, "edges": [], "props": [],
    "stamps": [{"node": "arrival", "at": [-ex, -ey], "legend": LEGEND, "rows": ["".join(r) for r in grid]}],
    "marks": [{"name": nm, "node": "arrival", "at": rel(x, y)} for nm, (x, y) in marks.items()],
}
route_spots = {
    "_comment": "관문(돌 거인 광장 — 서 있는 석상 병사) · 곁길 보상 · 모래에 묻힌 짐(위험한 바다 한가운데) · 매복. [창작] 임시값",
    "guards": [
        {"mark": "plaza", "at": [-4, 2], "monsters": ["gargoyle_statue"]},
        {"mark": "plaza", "at": [4, 2], "monsters": ["gargoyle_statue"]},
        {"mark": "cave", "monsters": ["corrupted_gnome", "gnome", "gnome", "gnome"]},
    ],
    "features": [
        {"mark": "seep", "event": "clear_spring", "tile": "f2d_cairn"},
        {"mark": "colonnade", "event": "dead_campfire", "at": [0, 2], "tile": "f2d_campfire"},
        {"mark": "colonnade", "event": "explorer_corpse", "at": [4, -2], "tile": "f2d_corpse_g"},
        {"mark": "plaza", "event": "offering_pile", "at": [0, -4], "tile": "f2d_offering"},
        {"mark": "cave", "event": "hidden_cache", "at": [3, -2]},
        {"mark": "cave", "event": "explorer_corpse", "at": [-3, 2], "tile": "f2d_corpse_g"},
        {"mark": "buried_a", "event": "buried_pack"},
        {"mark": "buried_b", "event": "buried_pack"},
        {"mark": "dune_w", "event": "explorer_corpse", "tile": "f2d_corpse_g"},
        {"mark": "dune_e", "event": "hidden_cache"},
        {"mark": "exit", "event": "dead_campfire", "at": [-4, 4], "tile": "f2d_campfire"},
    ],
    "ambush": [
        {"mark": "dune_w", "at": [3, -3], "monsters": ["gnome", "gnome"], "radius": 3, "line": "field.ambush_gnome", "sound": "gnome_alarm"},
        {"mark": "dune_e", "at": [-3, -3], "monsters": ["corrupted_gnome", "gnome"], "radius": 3, "line": "field.ambush_gnome", "sound": "gnome_alarm"},
    ],
}
d = {
    "_comment": "2층 바위사막(docs/plans/floor2.md §4 · §13-5, level_design_review.md B-2 D — 1단계 LD14): 1층 서쪽 포탈(dest floor2_west)에서 온다. 횃불 옛길(돌 화로 — 빛 · 그늘)은 멀고 안전, 모래 바다(진동 — 샌드웜)는 곧다. 낮 열기(그늘 밖 — 허기 · 피로, 샘물로 식힌다) · 오후 모래 폭풍(시야). 새 몬스터(코볼트 셋 · 스톤 골렘 · 거석병 · 샌드맨 · 샌드웜 · 데쓰웜)는 2단계 — 지금은 노움 · 타락한 노움 · 석상 가고일(거석병 자리) · 웜스톤(샌드웜 자리). 수치는 모두 임시값",
    "id": "f2_rock_desert", "name_ko": "바위사막", "floor": 2, "arrival": "floor2_west", "generator": "fields", "close_hours": 240,
    "visibility_cap_m": 9.5, "visibility_source": "placeholder", "ambient_light_m": 8.0, "ambient_source": "placeholder", "ambient_color": "#f0dcb4",
    "art": {
        "_comment": "1단계: 바닥 = 망자의 땅 흙 · 빙하굴 눈밭(모래 바다) 그림 + 모래빛 색조(macro), 외곽 = 검은 바위산(assets/floor/f2r — RiseMesa 검은 색), 화로 = 핏빛성채 화로, 전투 뒷그림 = tools/battle_art/SceneDesert.gd. [창작] 임시값",
        "battleback": {"image": "res://assets/battle/f2_rock_desert.webp", "half_width": 3.6},
        "palette": {"unexplored": "#000000", "near_black": "#2a2218", "tone": "#fae6c4", "memory_tint": "#a08c6c", "memory_brightness": 0.5, "memory_desat": 0.3, "keep_hue": True},
        "torch_color": "#ffd090",
        "post": {"saturation": 0.8, "vignette_strength": 0.4, "vignette_radius": 0.5, "grain_strength": 0.05},
        "particles": [{"id": "dust", "amount": 60, "lifetime": 9.0, "color": "#f0d8a8", "alpha": 0.3, "scale": [1.0, 2.4], "velocity": [10.0, 18.0], "direction": [1.0, 0.15], "spread": 15.0, "gravity": [0.0, 0.0]}],
        "ambience": {"loop": "f2_desert"},
        "macro": {"_comment": "바닥 색조: 흙 · 눈밭 그림을 모래빛으로. [창작] 임시값", "zones": {"f2r_road": "#f4d8a8", "f2r_sea": "#f0c888", "f2r_cave": "#c8b090"}, "noise": {"freq": 0.025, "amount": 0.1}},
        "abyss": {"cliff": "res://assets/floor/f2d/chasm.webp", "cliff_tiles": 8, "cliff_depth": 2.25, "jag": 0.35, "abyss_color": "#141010", "mist_color": "#3a3028", "rim_color": "#a09078",
                  "rise": {"face": "res://assets/floor/f2r/rise_face.webp", "top": "res://assets/floor/f2r/rise_top.webp", "face_tiles": 8, "face_depth": 3, "top_tiles": 8, "jag": 0.3, "fog": 6, "dark": "#1a1612"},
                  "bank": {"depth_tiles": 1.3, "shadow_tiles": 0.9, "shadow_alpha": 0.6}},
        "decor": {"_comment": "바닥 잔해(1층 데칼 시트): 잔해 둘레 자갈 · 뼈. [창작] 임시값", "sheet": "res://assets/floor/f1/decals.webp", "variants": 4,
                  "kinds": ["shore", "gravel", "moss", "wet", "crystal_bits", "claws", "mud", "rot", "trash", "bones"], "on_tiles": ["f2d_hard", "f2d_mound"],
                  "rules": [{"kind": "gravel", "near_tiles": {"tiles": ["f2d_ruin", "f2d_statue"], "radius": 2}, "dense": True, "chance": 0.5},
                            {"kind": "bones", "near_features": {"ids": ["explorer_corpse", "buried_pack"], "radius": 4}, "chance": 0.5},
                            {"kind": "gravel", "wall_north": True, "dense": True, "chance": 0.3},
                            {"kind": "bones", "chance": 0.02}, {"kind": "gravel", "chance": 0.08}]},
    },
    "gen": gen,
    "regions": [
        {"id": "f2r_road", "zone": "f2r_road", "name_ko": "횃불 옛길", "monsters": ["gnome", "corrupted_gnome"], "weights": {"gnome": 5, "corrupted_gnome": 1}, "groups": [5, 6], "horde": True, "entry_dist": [25, 0]},
        {"id": "f2r_road_lone", "zone": "f2r_road", "name_ko": "횃불 옛길", "monsters": ["gnome"], "weights": {"gnome": 1}, "groups": [3, 4], "pack": [1, 1], "entry_dist": [8, 35]},
        {"id": "f2r_cave", "zone": "f2r_cave", "name_ko": "코볼트 굴", "monsters": ["corrupted_gnome", "gnome"], "weights": {"corrupted_gnome": 2, "gnome": 3}, "groups": [2, 3]},
    ],
    "spawn": {"_comment": "망자의 땅과 같은 키. 모래 바다엔 지역 무리가 없다(샌드웜 매복만)", "groups_per_region": [4, 5],
              "pack_by_day": [[4, 6], [4, 7], [5, 8], [6, 9], [6, 10], [7, 11], [8, 12], [9, 13], [10, 14], [12, 15]],
              "respawn_hours": 24, "growth_every_hours": 24, "max_extra_groups": 3},
    "terrain": {"_comment": "모래 폭풍(FieldTerrain night_fog를 오후로): 13~16시 옛길 · 바다 시야 4m. [창작] 임시값", "night_fog": {"zones": ["f2r_road", "f2r_sea"], "from": 13, "to": 16, "cap_m": 4.0}},
    "desert": {
        "_comment": "DesertRules(LD14): 낮 열기 · 모래 바다 진동. [창작] 임시값",
        "heat": {"zones": ["f2r_road", "f2r_sea"], "from": 8, "to": 18, "status": "heat", "fatigue_per_hour": 2.0, "shade_tiles": ["f2d_fire", "f2d_ruin", "f2d_statue"], "shade_radius": 2, "cool_status": "refreshed"},
        "sand_sea": {"tiles": ["f2r_sand"], "per_step": 1.0, "decay_per_hour": 25.0, "threshold": 14.0, "warn_at": 0.6, "monsters": ["wormstone"],
                     "line": "field.sandworm", "warn_line": "field.sand_tremor", "sound": "crumble", "warn_sound": "crumble"},
    },
    "features_gap": 6, "features": [], "landmarks": [],
    "portals": [{"id": "to_f3_desert", "dir": "north", "to_floor": 3, "dest": "floor3_from_desert"}],
    "source": "original",
    "route_spots": route_spots,
}
json.dump(d, open(FLOOR, "w"), ensure_ascii=False, indent=2)
open(FLOOR, "a").write("\n")

try:
    from PIL import Image, ImageDraw
    col = {" ": (40, 34, 30), ".": (200, 170, 120), "~": (230, 200, 130), "n": (170, 140, 100), "R": (110, 100, 90), "F": (255, 150, 60), "S": (140, 130, 120)}
    S = 4
    im = Image.new("RGB", (W * S, H * S))
    dr = ImageDraw.Draw(im)
    for y in range(H):
        for x in range(W):
            dr.rectangle([x * S, y * S, x * S + S - 1, y * S + S - 1], fill=col[grid[y][x]])
    for nm, (x, y) in marks.items():
        dr.ellipse([x * S - 4, y * S - 4, x * S + 4, y * S + 4], outline=(255, 230, 120))
        dr.text((x * S + 6, y * S - 6), nm, fill=(40, 20, 10))
    im.save(os.path.join(ROOT, "docs/plans/f2_rock_desert_layout.png"))
except ImportError:
    pass
print("지도 %d × %d, 표시 %d, 화로 %d" % (W, H, len(marks), len(fires)))
