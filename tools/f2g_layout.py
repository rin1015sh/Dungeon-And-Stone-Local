#!/usr/bin/env python3
"""고블린 숲 손으로 짠 지도(사용자 2026-11-06 "레벨 디자인부터 다시 — 허허벌판 돌아다니는 느낌", floor2.md §15, FL25).

둥근 빈 터 + 빈 길(생성기 원) 대신 지도 전체를 이 스크립트가 칸 단위로 그린다: 좁게 굽는 뿌리 사이 길 · 곁방(알코브) · 높은 둔덕길과
낮은 개울 골짜기 · 개울을 건너는 나무 다리 · 말뚝 울타리 고블린 마을 고원. 8~10칸마다 볼 것(장면 · 살필 것 · 덫 밭 · 매복)이 오도록
자리(표시 marks)를 함께 정해 층 JSON(data/floors/f2_goblin_forest.json)의 gen.stamps · nodes · marks · landmarks와 route_spots에 써 넣는다.

  python3 tools/f2g_layout.py            # 층 JSON 갱신 + 미리보기 docs/plans/f2_goblin_forest_layout.png

글자: ' ' = 메움(덤불 둔덕 — 걷지 못함) · '.' 숲 바닥 · ',' 빈터 풀 · '=' 오솔길 · 'v' 마을 바닥(짓밟힌 진창) · 'b' 나무 다리(널빤지) ·
      'l' 낮은 숲 바닥 · 'w' 개울(낮은 땅 · 느림) · 'g' 여울 자갈(낮은 땅) · '/' 흙 비탈(높낮이 잇기).
"""
import json
import math
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FLOOR = os.path.join(ROOT, "data/floors/f2_goblin_forest.json")
W, H = 150, 182
LEGEND = {".": "f2g_floor", ",": "f2g_grass", "=": "f2g_path", "v": "f2g_village", "b": "f2g_plank",
          "l": "f2g_floor_low", "w": "f2g_brook", "g": "f2g_gravel_low", "/": "f2g_slope"}

rng = random.Random(7)
grid = [[" "] * W for _ in range(H)]
marks = {}        # 이름 → (x, y) 지도 칸
props = []        # (tile, x, y)
landmarks = []    # (kind, x, y, foot)


def put(x, y, ch, over=True):
    if 2 <= x < W - 2 and 2 <= y < H - 2 and (over or grid[y][x] == " "):
        grid[y][x] = ch


def disk(cx, cy, r, ch, rough=0.18, over=True):
    ph = rng.random() * 6.28
    for y in range(int(cy - r * 1.4) - 1, int(cy + r * 1.4) + 2):
        for x in range(int(cx - r * 1.4) - 1, int(cx + r * 1.4) + 2):
            a = math.atan2(y - cy, x - cx)
            rr = r * (1.0 + rough * (math.sin(a * 3 + ph) * 0.6 + math.sin(a * 7 + ph * 1.7) * 0.4))
            if math.hypot(x - cx, (y - cy) * 1.0) <= rr:
                put(x, y, ch, over)


def ellipse(cx, cy, rx, ry, ch, over=True):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                put(x, y, ch, over)


def path(pts, width, ch, wig=0.0, over=True):
    """점 목록을 잇는 굽은 길(폭 width). wig = 옆 흔들림."""
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        n = max(1, int(math.hypot(bx - ax, by - ay)))
        nx, ny = -(by - ay) / n, (bx - ax) / n
        for i in range(n + 1):
            u = i / n
            off = math.sin(u * math.pi * 2 + ax * 0.3) * wig * math.sin(u * math.pi)
            cx, cy = ax + (bx - ax) * u + nx * off, ay + (by - ay) * u + ny * off
            r = width / 2.0
            for y in range(int(cy - r) - 1, int(cy + r) + 2):
                for x in range(int(cx - r) - 1, int(cx + r) + 2):
                    if math.hypot(x - cx, y - cy) <= r:
                        put(x, y, ch, over)


def mark(name, x, y):
    marks[name] = (x, y)


# ── 숲 어귀(도착 — 남쪽 가운데) ──────────────────────────────────
EX, EY = 75, 160
disk(EX, EY, 9, ".")
disk(EX - 3, EY + 3, 4, ",")
mark("eaves", EX, EY)
props += [("f2g_bush", EX - 7, EY - 3), ("f2g_stump", EX + 6, EY + 4), ("f2g_mush", EX + 7, EY - 4), ("f2g_log", EX - 6, EY + 5)]

# ── 정면: 뿌리 사이 굽은 길 → 남문 → 마을 고원 → 북문 → 고목 ──────────────
path([(EX, EY - 8), (73, 150), (78, 141), (72, 132), (76, 124), (75, 114)], 3, "=")
disk(68, 145, 3, ".")               # 곁방 A: 올가미에 걸린 탐험가
mark("root_a", 68, 145)
disk(83, 135, 3, ".")               # 곁방 B: 이끼 통나무 · 버섯 — 매복
mark("root_b", 83, 135)
props += [("f2g_log", 85, 134), ("f2g_mush", 82, 137), ("f2g_mush", 84, 136)]
VX, VY = 75, 90
ellipse(VX, VY, 17, 14, "v")         # 마을 고원(빽빽하게 — 빈 터가 되지 않게)
disk(VX, VY - 1, 3, ",")             # 가운데 큰 나무 밑 풀
mark("village", VX, VY)
path([(75, 103), (75, 116)], 4, "=")  # 남문 — 뿌리 길과 잇는다
path([(75, 76), (75, 66)], 4, "=")    # 북문
path([(58, 90), (50, 90)], 3, "=")    # 서문
path([(92, 88), (100, 86)], 3, "=")   # 동문
for nm, x, y in [("gate_s", 75, 107), ("gate_n", 75, 70), ("gate_w", 53, 90), ("gate_e", 97, 87)]:
    mark(nm, x, y)
path([(75, 66), (73, 56), (78, 46), (75, 34)], 4, "=", 1.0)
disk(68, 50, 3, ",")                 # 곁방: 버섯 고리
mark("mush_ring", 68, 50)
props += [("f2g_mush", 66, 49), ("f2g_mush", 70, 49), ("f2g_mush", 68, 52), ("f2g_mush", 66, 52)]
GX, GY = 75, 22
disk(GX, GY, 12, ",")
disk(GX, GY + 9, 5, ".")
mark("grove", GX, GY)
landmarks.append(("bigtree", 75, 14, [3, 2]))
for k, dx, dy, f in [("hut", -10, -7, [4, 2]), ("hut", 10, -6, [4, 2]), ("hut", -9, 6, [4, 2]), ("tent", 11, 6, [3, 2]),
                     ("tent", -3, -10, [3, 2]), ("tent", 5, 10, [3, 2]), ("watch", -8, 12, [3, 2]), ("watch", 9, -11, [3, 2]),
                     ("bigtree", 0, -3, [3, 2])]:
    landmarks.append((k, VX + dx, VY + dy, f))
mark("watch_s", VX - 8, VY + 13)
mark("watch_n", VX + 9, VY - 10)
for dx, dy in [(-4, 3), (4, 3), (-13, -1), (13, 0), (-5, -5), (6, -3)]:
    props.append(("f2g_totem", VX + dx, VY + dy))

# ── 서쪽: 사냥꾼 쉼터 → 덫 골짜기(뿌리 미로) → 족장 움막 → 뒷길 ────────────
path([(EX - 8, EY), (60, 158), (44, 154), (30, 148)], 3, "=")
disk(28, 146, 8, ",")
mark("hunter", 28, 146)
landmarks.append(("tent", 33, 141, [3, 2]))
path([(26, 138), (22, 126), (30, 116), (24, 106), (16, 96), (22, 84), (30, 76), (26, 66), (32, 54)], 3, "=")
path([(29, 116), (36, 116)], 2, "=")   # 골짜기 → 곁방
disk(36, 116, 3, ".")               # 곁방: 덫에 걸린 짐승(경고)
mark("gully_snared", 36, 116)
disk(13, 92, 4, ",")                # 곁방: 버섯 고리 + 사냥꾼 궤짝
mark("gully_ring", 13, 92)
props += [("f2g_mush", 11, 90), ("f2g_mush", 15, 90), ("f2g_mush", 11, 94)]
disk(32, 84, 3, ".")                # 곁방: 탐험가 시체(보물)
mark("gully_corpse", 32, 84)
for nm, x, y in [("trap1", 22, 127), ("trap2", 19, 99), ("trap3", 29, 72)]:
    mark(nm, x, y)
for x, y in [(25, 133), (27, 133), (14, 104), (18, 104), (27, 79), (31, 79)]:
    props.append(("f2g_totem", x, y))   # 덫 밭 앞 경고(해골 토템)
path([(30, 92), (40, 91), (50, 90)], 3, "=")   # 서문 ↔ 골짜기 샛길
CX, CY = 34, 46
disk(CX, CY, 7, "v")
mark("chief", CX, CY)
landmarks.append(("hut", CX, CY - 3, [4, 2]))
landmarks.append(("tent", CX - 5, CY + 3, [3, 2]))
for dx, dy in [(-3, 4), (3, 4), (5, -1)]:
    props.append(("f2g_totem", CX + dx, CY + dy))
path([(CX + 9, CY), (52, 42), (64, 40), (75, 38)], 3, "=")   # 뒷길 → 고목 길

# ── 동쪽: 버섯 빈터 → 둔덕길(높은 길 — 골짜기를 내려다본다) · 개울 골짜기(낮은 땅) → 나무 다리 → 고목 ──
path([(EX + 8, EY), (92, 158), (108, 154), (122, 150)], 3, "=")
disk(124, 148, 8, ",")
mark("glade", 124, 148)
props += [("f2g_mush", 120, 144), ("f2g_mush", 128, 146), ("f2g_mush", 126, 151)]
# 골짜기(낮은 땅) — 개울이 굽어 흐른다
for y in range(70, 140):
    cx = 126 + int(6 * math.sin(y * 0.09))
    half = 9 + int(2 * math.sin(y * 0.21))
    for x in range(cx - half, cx + half + 1):
        put(x, y, "l")
    for x in range(cx - 2, cx + 2):
        put(x, y, "w")
for x, y, r in [(122, 128, 3), (131, 112, 2), (120, 96, 3), (130, 82, 3)]:
    disk(x, y, r, "g")
mark("valley_corpse", 122, 128)
mark("valley_cache", 131, 111)
mark("hunters_camp", 130, 82)
path([(124, 141), (124, 137)], 4, "/")          # 빈터 → 골짜기 비탈
path([(121, 72), (116, 64)], 4, "/")            # 골짜기 → 북쪽 비탈
# 둔덕길(높은 길) — 골짜기 서쪽 가장자리를 따라
path([(116, 146), (108, 138), (106, 120), (106, 100), (108, 80), (112, 66)], 3, "=")
path([(100, 86), (106, 92)], 3, "=")            # 동문 ↔ 둔덕길
mark("ridge_view", 106, 110)
# 나무 다리: 둔덕길에서 골짜기를 건너 동쪽 바위턱(전망 · 궤짝)
path([(108, 104), (144, 104)], 3, "b")
disk(144, 104, 3, ".")
mark("outcrop", 144, 104)
# 북쪽: 골짜기 · 둔덕길에서 고목으로
path([(116, 63), (104, 50), (90, 30), (84, 24)], 3, "=")
landmarks.append(("watch", 140, 101, [3, 2]))   # 바위턱 사냥꾼 발판

# 곁방 잇는 샛길(폭 2 — 길에서 살짝 비켜 들어간다)
path([(74, 147), (68, 145)], 2, "=")
path([(76, 138), (83, 135)], 2, "=")
path([(75, 53), (68, 50)], 2, "=")
path([(23, 85), (32, 84)], 2, "=")

# ── 걸어서 닿는지 확인(미리보기용) ──
walk = set(LEGEND)
seen = {(EX, EY)}
q = [(EX, EY)]
while q:
    x, y = q.pop()
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        n = (x + dx, y + dy)
        if 0 <= n[0] < W and 0 <= n[1] < H and n not in seen and grid[n[1]][n[0]] in walk:
            seen.add(n)
            q.append(n)
for nm in ["grove", "chief", "hunter", "glade", "outcrop", "hunters_camp", "valley_corpse", "gully_ring"]:
    if marks[nm] not in seen:
        print("닿지 않는다:", nm, marks[nm])

# ── 층 JSON에 써 넣기 ──
d = json.load(open(FLOOR))
g = d["gen"]
ex, ey = marks["eaves"]
rel = lambda x, y: [x - ex, y - ey]
g["size"] = [W, H]
zone_of = {"eaves": "f2g_eaves", "hunter": "f2g_gully", "gully_ring": "f2g_gully", "chief": "f2g_chief", "village": "f2g_village",
           "grove": "f2g_grove", "mush_ring": "f2g_grove", "glade": "f2g_brook", "hunters_camp": "f2g_brook", "valley_corpse": "f2g_brook",
           "outcrop": "f2g_brook"}
nodes = []
for nm, z in zone_of.items():
    x, y = marks[nm]
    nd = {"id": nm, "at": [x, y], "r": 1, "zone": z, "kind": "place"}
    if nm == "eaves":
        nd["kind"] = "arrival"
    if nm == "grove":
        nd["kind"] = "exit"
    nodes.append(nd)
nodes[0]["props"] = [{"tile": t, "at": [rel(x, y)]} for t, x, y in props]
g["nodes"] = nodes
g["edges"] = []
g["stamps"] = [{"node": "eaves", "at": [-ex, -ey], "legend": LEGEND, "rows": ["".join(r) for r in grid]}]
g["marks"] = [{"name": nm, "node": "eaves", "at": rel(x, y)} for nm, (x, y) in marks.items()]
g["landmarks"] = [{"node": "eaves", "at": rel(x, y), "kind": k, "foot": f} for k, x, y, f in landmarks]
g["fence"] = [{"node": "village", "tile": "f2g_stakes", "pad": 19, "along": "f2g_thicket"}, {"node": "chief", "tile": "f2g_stakes", "pad": 8, "along": "f2g_thicket"}]
g["props"] = []
g["_comment"] = "고블린 숲 손으로 짠 지도(tools/f2g_layout.py — floor2.md §15, FL25): 지도 전체 = stamps 하나, 자리 = marks. 다시 만들려면 스크립트를 고쳐 다시 돌린다. [창작] 임시값"
rs = d["route_spots"]
rs["guards"] = [{"mark": "chief", "at": [0, 3], "monsters": ["hobgoblin", "goblin", "goblin", "goblin_swordsman", "goblin_archer"]},
                {"mark": "hunters_camp", "monsters": ["hobgoblin", "goblin_archer", "goblin_archer"]}]
rs["features"] = [
    {"mark": "hunter", "event": "dead_campfire", "at": [-3, 2], "tile": "f2g_campfire"},
    {"mark": "hunter", "event": "hunter_cache", "at": [-5, -2], "tile": "f2g_cache"},
    {"mark": "root_a", "event": "explorer_corpse", "tile": "f2g_corpse_f"},
    {"mark": "gully_snared", "event": "explorer_corpse", "tile": "f2g_corpse_f"},
    {"mark": "gully_ring", "event": "hunter_cache", "tile": "f2g_cache"},
    {"mark": "gully_corpse", "event": "explorer_corpse", "tile": "f2g_corpse_f"},
    {"mark": "village", "event": "goblin_camp", "at": [-6, 1], "tile": "f2g_camp"},
    {"mark": "village", "event": "goblin_camp", "at": [7, 2], "tile": "f2g_camp"},
    {"mark": "village", "event": "goblin_camp", "at": [0, 8], "tile": "f2g_camp"},
    {"mark": "chief", "event": "chief_chest", "at": [4, 1], "tile": "f2g_cache_v"},
    {"mark": "glade", "event": "forest_mushroom", "at": [-3, 1]},
    {"mark": "glade", "event": "forest_mushroom", "at": [3, -3]},
    {"mark": "valley_corpse", "event": "explorer_corpse", "tile": "f2g_corpse_low"},
    {"mark": "valley_cache", "event": "hunter_cache", "tile": "f2g_cache_low"},
    {"mark": "outcrop", "event": "hunter_cache", "at": [1, 0], "tile": "f2g_cache_f"},
    {"mark": "grove", "event": "dead_campfire", "at": [-6, 6], "tile": "f2g_campfire"},
]
rs["hazards"] = [
    {"mark": "trap1", "r": 5, "on": "f2g_path", "event": "forest_snare", "count": 3, "gap": 2},
    {"mark": "trap1", "r": 5, "on": "f2g_path", "event": "forest_spike", "count": 2, "gap": 2},
    {"mark": "trap2", "r": 6, "on": "f2g_path", "event": "forest_pit", "count": 3, "gap": 2},
    {"mark": "trap2", "r": 6, "on": "f2g_path", "event": "forest_snare", "count": 2, "gap": 2},
    {"mark": "trap3", "r": 5, "on": "f2g_path", "event": "forest_spike", "count": 3, "gap": 2},
    {"mark": "trap3", "r": 5, "on": "f2g_path", "event": "forest_pit", "count": 2, "gap": 2},
    {"mark": "gate_s", "r": 4, "on": "f2g_path", "event": "forest_snare", "count": 2, "gap": 2},
    {"mark": "gate_n", "r": 4, "on": "f2g_path", "event": "forest_spike", "count": 2, "gap": 2},
]
rs["watch"] = [{"mark": "watch_s", "radius": 12, "archer": "goblin_archer"}, {"mark": "watch_n", "radius": 12, "archer": "goblin_archer"}]
rs["ambush"] = [
    {"mark": "root_b", "monsters": ["goblin", "goblin", "goblin_archer"], "radius": 3, "line": "field.ambush_goblin", "sound": "goblin_shout"},
    {"mark": "mush_ring", "monsters": ["goblin_swordsman", "goblin"], "radius": 3, "line": "field.ambush_goblin", "sound": "goblin_shout"},
    {"mark": "ridge_view", "monsters": ["goblin_archer", "goblin_archer"], "radius": 3, "line": "field.ambush_goblin", "sound": "goblin_shout"},
]
for o in g.get("outer_props", []):
    pass
json.dump(d, open(FLOOR, "w"), ensure_ascii=False, indent=2)
open(FLOOR, "a").write("\n")

# ── 미리보기 ──
try:
    from PIL import Image, ImageDraw
    col = {" ": (20, 30, 18), ".": (70, 100, 50), ",": (90, 130, 60), "=": (120, 100, 70), "v": (110, 85, 60), "b": (150, 110, 60),
           "l": (45, 70, 40), "w": (50, 90, 110), "g": (80, 85, 75), "/": (130, 120, 80)}
    S = 4
    im = Image.new("RGB", (W * S, H * S))
    dr = ImageDraw.Draw(im)
    for y in range(H):
        for x in range(W):
            dr.rectangle([x * S, y * S, x * S + S - 1, y * S + S - 1], fill=col[grid[y][x]])
    for nm, (x, y) in marks.items():
        dr.ellipse([x * S - 4, y * S - 4, x * S + 4, y * S + 4], outline=(255, 230, 120))
        dr.text((x * S + 6, y * S - 6), nm, fill=(255, 240, 200))
    im.save(os.path.join(ROOT, "docs/plans/f2_goblin_forest_layout.png"))
except ImportError:
    pass
print("지도 %d × %d, 표시 %d, 소품 %d, 큰 구조물 %d" % (W, H, len(marks), len(props), len(landmarks)))
