"""실내 가구(CT106 — tools/interior_bake.py 전용): 가구 덩어리 하나 = 그림 하나. 좌표 = 덩어리 왼쪽 위 땅이 (0, 0), 폭 w · 깊이 d(칸).
윗면 + 앞면(남)만 보인다(3/4). 빛나는 것(촛불 · 불)은 glow. HEIGHT = 그림판 높이를 정할 때 쓰는 가장 높은 곳(칸).
"""
import math

import numpy as np

import interior_mats as M
from interior_canvas import hexc
from interior_walldeco import candle, flame

WOOD_D, WOOD, WOOD_L = hexc("#3a2a1c"), hexc("#5a4030"), hexc("#7a5a3c")
IRON, BRASS, PAPER = hexc("#38383a"), hexc("#9a7e48"), hexc("#c4b48e")
STONE, CLOTH_R, CLOTH_G = hexc("#8a8274"), hexc("#6a2e26"), hexc("#3e4a34")

HEIGHT = {"pillar": 2.7, "wardrobe": 2.1, "bookcase": 2.2, "candelabra": 1.95, "specimen_shelf": 2.1, "mannequin": 1.7, "bars": 1.9,
          "teller_window": 1.9, "barrels": 1.0, "bed": 1.0, "weapon_rack": 1.5, "chained_lectern": 1.4, "basin": 1.2, "font": 1.2}


def legs(cv, x0, y0, x1, y1, h, col, t=0.08):
    for (lx, ly) in ((x0 + 0.04, y1 - 0.06), (x1 - 0.04 - t, y1 - 0.06)):
        cv.front(lx, lx + t, ly, 0, h, col)


def table(cv, x0, y0, x1, y1, h, col=None, tex=None, legs_col=None):
    col = WOOD if col is None else col
    legs(cv, x0 + 0.05, y0, x1 - 0.05, y1, h, legs_col if legs_col is not None else col * 0.7)
    cv.box(x0, y0, x1, y1, h - 0.08, h, col, tex_top=tex or M.wood("#6a4c34", 7), tex_side=M.wood("#4a3424", 8))


def papers(cv, x0, y0, x1, y1, z, n, seed):
    rng = np.random.default_rng(seed)
    for _ in range(n):
        px, py = rng.uniform(x0, x1 - 0.3), rng.uniform(y0, y1 - 0.25)
        cv.ground(px, py, px + 0.3, py + 0.24, PAPER * rng.uniform(0.85, 1.05), z=z)


def mug(cv, x, y, z):
    cv.cyl(x, y, 0.07, z, z + 0.15, hexc("#7a5a3a"), tex_top=None)
    cv.fill(cv.ellipse_pts(x, y, 0.05, 0.05, z + 0.15), hexc("#c8b080"))


def bottle(cv, x, y, z, col, h=0.26):
    cv.cyl(x, y, 0.05, z, z + h, col)
    cv.cyl(x, y, 0.025, z + h, z + h + 0.08, col * 0.8)


def stool(cv, x, y):
    cv.front(x - 0.12, x - 0.06, y + 0.1, 0, 0.42, WOOD_D)
    cv.front(x + 0.06, x + 0.12, y + 0.1, 0, 0.42, WOOD_D)
    cv.cyl(x, y, 0.2, 0.38, 0.45, WOOD_L * 0.9)


def chair(cv, x, y, back=True):
    cv.front(x - 0.16, x + 0.16, y + 0.14, 0, 0.42, WOOD_D)
    cv.ground(x - 0.18, y - 0.14, x + 0.18, y + 0.14, WOOD, z=0.44)
    if back:
        cv.front(x - 0.18, x + 0.18, y - 0.12, 0.44, 0.95, WOOD_D)


def draw(cv, art, w, d, seed):
    cx = w / 2
    if art in ("counter", "bar", "shop_counter"):
        h = 1.0
        cv.front(0, w, d, 0, h - 0.08, WOOD, tex=M.planks("#5a4030", 0.22, seed), shade=(0.78, 0.55))
        for k in range(int(w)):
            cv.front(k + 0.12, k + 0.88, d + 0.005, 0.15, h - 0.22, None, tex=M.wood("#4e3828", seed + k), shade=(0.7, 0.55))
        cv.box(-0.05, 0, w + 0.05, d + 0.06, h - 0.08, h, WOOD_L, tex_top=M.wood("#7a5a3c", seed + 3))
        if art == "counter":
            papers(cv, 0.4, 0.15, w - 0.4, d - 0.1, h + 0.005, int(w), seed)
            cv.box(w * 0.6, 0.2, w * 0.6 + 0.45, 0.5, h, h + 0.12, hexc("#5a2a22"))
            cv.cyl(w * 0.3, 0.4, 0.06, h, h + 0.1, hexc("#1a1a1a"))
        elif art == "bar":
            for k in range(int(w * 0.6)):
                mug(cv, 0.5 + k * (w - 1.0) / max(1, int(w * 0.6) - 1) + (k % 2) * 0.15, 0.45 + (k % 2) * 0.15, h)
            cv.cyl(w - 0.6, 0.45, 0.2, h, h + 0.45, hexc("#6a4a2e"), tex_side=M.wood("#6a4a2e", seed, False))
        else:
            cv.front(w * 0.3 - 0.03, w * 0.3 + 0.03, 0.5, h, h + 0.55, BRASS)
            cv.line(cv.to_px(w * 0.3 - 0.32, 0.5, h + 0.52), cv.to_px(w * 0.3 + 0.32, 0.5, h + 0.52), 4, BRASS)
            for s in (-1, 1):
                cv.cyl(w * 0.3 + s * 0.3, 0.5, 0.14, h + 0.22, h + 0.26, BRASS * 0.9)
            for k in range(5):
                cv.cyl(w * 0.65 + k * 0.09, 0.45 + (k % 2) * 0.08, 0.05, h, h + 0.03 + k * 0.01, hexc("#b89a50"))
    elif art == "specimen_shelf":
        cv.box(0.05, 0.1, w - 0.05, d - 0.15, 0, 2.05, WOOD_D, tex_side=M.wood("#3a2a1c", seed, False))
        pal = [hexc(c) for c in ("#5a6a4a", "#7a6a3a", "#4a5a6a", "#8a7a5a")]
        for row in range(4):
            z = 0.15 + row * 0.48
            cv.front(0.12, w - 0.12, d - 0.149, z, z + 0.4, hexc("#1e1712"), shade=(0.6, 1.0))
            for k in range(int(w * 2.5)):
                xx = 0.3 + k * (w - 0.6) / max(1, int(w * 2.5) - 1)
                if (k + row) % 4 == 3:
                    cv.cyl(xx, d - 0.2, 0.1, z, z + 0.16, hexc("#c8bca0"))
                else:
                    bottle(cv, xx, d - 0.2, z, pal[(k + row) % 4], 0.22)
    elif art == "records_desk" or art == "librarian_desk":
        table(cv, 0, 0.1, w, d, 0.82)
        papers(cv, 0.3, 0.2, w * 0.6, d - 0.1, 0.83, 4, seed)
        for k in range(3):
            cv.box(w - 0.9, 0.25 + k * 0.0, w - 0.4, 0.6, 0.82 + k * 0.08, 0.9 + k * 0.08, hexc(["#5a2a22", "#2e3e52", "#5a4a2a"][k]))
        cv.cyl(w * 0.7, 0.35, 0.08, 0.82, 0.86, BRASS)
        cv.front(w * 0.7 - 0.03, w * 0.7 + 0.03, 0.36, 0.86, 1.02, hexc("#e4d8bc"))
        flame(cv, 0.36, w * 0.7, 1.02, 0.45)
    elif art == "barrels":
        for (bx, by) in ((0.55, 0.6), (1.45, 0.6), (1.0, 1.45)):
            cv.shadow(bx, by + 0.1, 0.4, 0.25, 0.4)
            cv.cyl(bx, by, 0.42, 0, 0.95, hexc("#6a4a2e"), tex_side=M.wood("#6a4a2e", seed + int(bx * 10), False))
            for z in (0.18, 0.75):
                cv.fill(cv.ellipse_pts(bx, by, 0.43, 0.43, z, 20, 0, math.pi) + cv.ellipse_pts(bx, by, 0.43, 0.43, z + 0.06, 20, math.pi, 0), IRON)
            cv.fill(cv.ellipse_pts(bx, by, 0.3, 0.3, 0.95), hexc("#5a3e26"))
    elif art == "map_table" or art == "reading_table":
        if art == "reading_table":
            legs(cv, 0.6, 0, w - 0.6, d - 0.3, 0.8, WOOD_D)
            cv.fill(cv.ellipse_pts(cx, d / 2, cx - 0.05, d / 2 - 0.08, 0.72, 30, 0, math.pi) + cv.ellipse_pts(cx, d / 2, cx - 0.05, d / 2 - 0.08, 0.8, 30, math.pi, 0), WOOD_D)
            cv.fill(cv.ellipse_pts(cx, d / 2, cx - 0.05, d / 2 - 0.08, 0.8), None, tex=M.wood("#6a4c34", seed))
            for (bx, by) in ((cx - 0.6, d / 2 - 0.1), (cx + 0.3, d / 2 + 0.2)):
                cv.ground(bx, by, bx + 0.25, by + 0.32, PAPER, z=0.81)
                cv.ground(bx + 0.25, by, bx + 0.5, by + 0.32, PAPER * 0.92, z=0.81)
            for k in range(2):
                x = cx - 0.15 + k * 0.4
                cv.cyl(x, d / 2 - 0.3, 0.07, 0.8, 0.84, BRASS)
                cv.front(x - 0.03, x + 0.03, d / 2 - 0.29, 0.84, 1.02, hexc("#e4d8bc"))
                flame(cv, d / 2 - 0.29, x, 1.02, 0.45)
        else:
            table(cv, 0.05, 0.05, w - 0.05, d - 0.05, 0.85)
            cv.ground(0.35, 0.25, w - 0.35, d - 0.3, hexc("#b8a47c"), z=0.86, tex=M.grainy("#b8a47c", seed, 0.12, 4))
            for k in range(5):
                cv.line(cv.to_px(0.5 + k * 0.4, 0.4, 0.86), cv.to_px(0.8 + k * 0.3, d - 0.45, 0.86), 2, hexc("#5a4030"))
            cv.cyl(w - 0.6, 0.5, 0.07, 0.86, 0.9, BRASS)
            cv.front(w - 0.63, w - 0.57, 0.51, 0.9, 1.08, hexc("#e4d8bc"))
            flame(cv, 0.51, w - 0.6, 1.08, 0.45)
    elif art == "stool":
        for k in range(int(round(w))):
            stool(cv, k + 0.5, d / 2)
    elif art == "round_table":
        stool(cv, 0.22, 0.55)
        stool(cv, w - 0.22, 0.55)
        cv.front(cx - 0.07, cx + 0.07, 0.62, 0, 0.72, WOOD_D)
        cv.cyl(cx, 0.62, 0.3, 0, 0.05, WOOD_D)
        cv.cyl(cx, 0.45, 0.52, 0.68, 0.78, WOOD, tex_top=M.wood("#6a4c34", seed), tex_side=M.wood("#4a3424", seed + 1))
        mug(cv, cx + 0.18, 0.5, 0.78)
        cv.fill(cv.ellipse_pts(cx - 0.18, 0.35, 0.16, 0.12, 0.785), hexc("#8a7a60"))
    elif art == "lute_chair":
        chair(cv, 0.5, 0.5)
        pts = [cv.to_px(0.62 + 0.2 * math.cos(a), 0.72, 0.5 + 0.24 * math.sin(a)) for a in np.linspace(0, math.tau, 20)]
        cv.fill(pts, hexc("#8a5a2e"))
        cv.line(cv.to_px(0.62, 0.73, 0.6), cv.to_px(0.85, 0.73, 1.2), 4, WOOD_D)
    elif art == "bed":
        cv.box(0.05, 0.05, w - 0.05, d - 0.05, 0, 0.45, WOOD, tex_side=M.wood("#5a4030", seed))
        cv.front(0.05, w - 0.05, 0.12, 0.45, 0.95, WOOD_D)
        cv.ground(0.15, 0.15, w - 0.15, d - 0.15, hexc("#6a4a3a"), z=0.55, tex=M.grainy("#6a4e3a", seed, 0.14, 5))
        cv.ground(0.15, 0.6, w - 0.15, d - 0.12, CLOTH_R, z=0.6, tex=M.grainy("#5e2e26", seed + 1, 0.12, 6))
        cv.front(0.15, w - 0.15, d - 0.12, 0.45, 0.6, CLOTH_R * 0.75)
        cv.box(0.35, 0.18, w - 0.35, 0.52, 0.55, 0.68, hexc("#c8bca0"))
    elif art == "chest":
        cv.box(0.12, 0.25, 0.88, 0.85, 0, 0.5, WOOD, tex_side=M.wood("#5a4030", seed))
        cv.front(0.12, 0.88, 0.851, 0.1, 0.16, IRON)
        cv.front(0.45, 0.55, 0.852, 0.25, 0.38, BRASS)
    elif art in ("washstand", "candle_table"):
        table(cv, 0.12, 0.2, 0.88, 0.8, 0.75, WOOD)
        if art == "washstand":
            cv.cyl(0.42, 0.5, 0.22, 0.75, 0.86, hexc("#8a8a84"))
            cv.fill(cv.ellipse_pts(0.42, 0.5, 0.16, 0.16, 0.86), hexc("#4a5a64"))
            cv.cyl(0.72, 0.45, 0.07, 0.75, 1.0, hexc("#c8bca0"))
        else:
            cv.cyl(0.5, 0.5, 0.08, 0.75, 0.8, BRASS)
            cv.front(0.47, 0.53, 0.51, 0.8, 1.0, hexc("#e4d8bc"))
            flame(cv, 0.51, 0.5, 1.0, 0.5)
    elif art == "bookcase":
        cv.box(0.05, 0.2, w - 0.05, d - 0.05, 0, 2.15, WOOD_D, tex_side=M.wood("#3a2a1c", seed, False))
        for k in range(5):
            z = 0.12 + k * 0.4
            cv.front(0.14, w - 0.14, d - 0.049, z, z + 0.33, None, tex=M.books(seed + k), shade=(0.7, 1.0))
    elif art == "chained_lectern":
        cv.front(cx - 0.1, cx + 0.1, 0.6, 0, 0.95, WOOD_D)
        cv.box(cx - 0.35, 0.45, cx + 0.35, 0.65, 0, 0.08, WOOD_D)
        pts = [cv.to_px(cx - 0.5, 0.25, 1.0), cv.to_px(cx + 0.5, 0.25, 1.0), cv.to_px(cx + 0.5, 0.6, 0.88), cv.to_px(cx - 0.5, 0.6, 0.88)]
        cv.fill(pts, WOOD)
        pts = [cv.to_px(cx - 0.42, 0.3, 1.03), cv.to_px(cx + 0.42, 0.3, 1.03), cv.to_px(cx + 0.42, 0.56, 0.93), cv.to_px(cx - 0.42, 0.56, 0.93)]
        cv.fill(pts, PAPER)
        cv.line(cv.to_px(cx, 0.3, 1.04), cv.to_px(cx, 0.56, 0.94), 2, WOOD_D)
        for k in range(6):
            cv.cyl(cx + 0.45 + k * 0.02, 0.6, 0.035, 0.85 - k * 0.15, 0.88 - k * 0.15, IRON * 1.5)
    elif art == "candelabra":
        cv.shadow(0.5, 0.6, 0.25, 0.14, 0.4)
        cv.cyl(0.5, 0.55, 0.18, 0, 0.06, IRON)
        cv.front(0.47, 0.53, 0.55, 0.06, 1.6, IRON)
        cv.line(cv.to_px(0.22, 0.55, 1.6), cv.to_px(0.78, 0.55, 1.6), 4, IRON)
        for x in (0.22, 0.5, 0.78):
            candle(cv, 0.56, x, 1.6 + (0.1 if x == 0.5 else 0.0), 0.2)
    elif art == "altar":
        cv.box(0.05, 0.15, w - 0.05, d - 0.05, 0, 0.95, STONE, tex_side=M.slabs("#8a8274", 0.6, 0.32, seed, 0.12), tex_top=M.slabs("#9a9284", 0.8, 0.8, seed + 1, 0.05))
        cv.front(0.25, w - 0.25, d - 0.04, 0.82, 0.95, hexc("#6a5a3a"))
        cv.front(cx - 0.45, cx + 0.45, d - 0.035, 0.25, 0.95, hexc("#7a2a24"), shade=(1.0, 0.7))
        cv.front(cx - 0.12, cx + 0.12, d - 0.03, 0.4, 0.75, hexc("#b8964a"))
        cv.ground(cx - 0.45, 0.15, cx + 0.45, d - 0.05, hexc("#7a2a24"), z=0.955)
        for k in range(6):
            x = 0.3 + k * (w - 0.6) / 5
            if abs(x - cx) > 0.5:
                candle(cv, 0.4 + (k % 2) * 0.2, x, 0.955, 0.16 + (k % 3) * 0.1)
        cv.box(cx - 0.25, 0.35, cx + 0.25, 0.7, 0.96, 1.04, hexc("#4a2a1e"))
        cv.ground(cx - 0.22, 0.38, cx + 0.22, 0.66, PAPER, z=1.045)
    elif art == "dais":
        cv.box(-0.02, 0, w + 0.02, d, 0, 0.14, hexc("#aaa290"), tex_top=M.slabs("#b4ac98", 1.2, 0.9, seed, 0.1))
    elif art == "pew":
        cv.front(0.15, 0.3, d - 0.2, 0, 0.45, WOOD_D)
        cv.front(w - 0.3, w - 0.15, d - 0.2, 0, 0.45, WOOD_D)
        cv.box(0.05, 0.35, w - 0.05, d - 0.2, 0.4, 0.48, WOOD, tex_top=M.wood("#5e4430", seed))
        cv.box(0.05, 0.1, w - 0.05, 0.28, 0.2, 1.0, WOOD_D, tex_side=M.wood("#4a3424", seed + 1))
    elif art == "offering_candles":
        cv.box(0.1, 0.3, w - 0.1, 0.8, 0, 0.75, IRON, tex_side=M.grainy("#3a3a3a", seed, 0.2))
        cv.box(0.05, 0.25, w - 0.05, 0.85, 0.75, 0.8, hexc("#4a4844"))
        rng = np.random.default_rng(seed)
        for k in range(9):
            candle(cv, 0.4 + (k % 3) * 0.15, 0.25 + k * (w - 0.5) / 8, 0.8, rng.uniform(0.06, 0.2))
    elif art == "offering_box":
        cv.box(0.2, 0.3, 0.8, 0.8, 0, 0.7, WOOD, tex_side=M.wood("#5a4030", seed))
        cv.ground(0.35, 0.5, 0.65, 0.56, hexc("#120e0a"), z=0.701)
        cv.front(0.2, 0.8, 0.801, 0.3, 0.36, IRON)
    elif art in ("font", "basin"):
        col = STONE if art == "font" else hexc("#8a6a3a")
        cv.cyl(0.5, 0.55, 0.12, 0, 0.75, col * 0.85)
        cv.cyl(0.5, 0.55, 0.38, 0.75, 0.98, col)
        cv.fill(cv.ellipse_pts(0.5, 0.55, 0.3, 0.3, 0.98), hexc("#4a5a62") if art == "font" else hexc("#5a6a6a"))
    elif art == "wardrobe":
        cv.box(0.05, 0.25, w - 0.05, d - 0.05, 0, 2.0, WOOD_D, tex_side=M.wood("#3e2c1e", seed, False))
        cv.front(cx - 0.02, cx + 0.02, d - 0.049, 0.1, 1.9, hexc("#1a120c"))
        for s in (-1, 1):
            cv.front(cx + s * 0.1 - 0.025, cx + s * 0.1 + 0.025, d - 0.048, 0.95, 1.1, BRASS)
    elif art == "peddler_stall":
        cv.ground(0.05, 0.1, w - 0.05, d - 0.05, hexc("#5a4a3a"), z=0.03, tex=M.grainy("#6a5038", seed, 0.15, 5))
        cv.box(0.15, 0.15, 0.85, 0.75, 0, 0.5, WOOD, tex_side=M.wood("#5a4030", seed))
        cv.cyl(w - 0.55, 0.5, 0.32, 0, 0.55, hexc("#8a7a58"))
        for k in range(4):
            bottle(cv, 1.1 + k * 0.22, 0.45 + (k % 2) * 0.15, 0.03, hexc(["#6a2a2a", "#2e5a4a", "#8a6a2a", "#4a3a6a"][k]), 0.2)
    elif art == "display_table":
        table(cv, 0.05, 0.05, w - 0.05, d - 0.05, 0.8)
        cv.fill([cv.to_px(0.6 + 0.25 * math.cos(a), 0.6 + 0.25 * math.sin(a), 0.81) for a in np.linspace(0, math.tau, 20)], hexc("#9a8458"))
        cv.fill([cv.to_px(0.6 + 0.12 * math.cos(a), 0.6 + 0.12 * math.sin(a), 0.82) for a in np.linspace(0, math.tau, 16)], hexc("#5a4a30"))
        cv.box(1.1, 0.4, 1.7, 0.9, 0.8, 1.05, hexc("#6a5236"))
        for k in range(4):
            bottle(cv, 0.4 + k * 0.3, 1.4, 0.8, hexc(["#6a2a2a", "#2e5a4a", "#8a6a2a", "#4a3a6a"][k]))
    elif art == "sack":
        cv.shadow(0.5, 0.7, 0.35, 0.2, 0.4)
        cv.cyl(0.5, 0.6, 0.32, 0, 0.5, hexc("#8a7a58"), tex_side=M.grainy("#8a7a58", seed, 0.18, 8))
        cv.cyl(0.5, 0.6, 0.12, 0.5, 0.62, hexc("#7a6a48"))
    elif art == "bellows":
        cv.box(0.15, 0.3, 0.85, 0.8, 0, 0.3, WOOD_D)
        pts = [cv.to_px(0.15, 0.55, 0.3), cv.to_px(0.85, 0.55, 0.3), cv.to_px(0.7, 0.55, 0.62), cv.to_px(0.3, 0.55, 0.62)]
        cv.fill(pts, hexc("#5a3a28"))
        cv.line(cv.to_px(0.5, 0.55, 0.62), cv.to_px(0.5, 0.4, 1.0), 4, WOOD_D)
    elif art == "quench_tub":
        cv.cyl(0.5, 0.55, 0.4, 0, 0.55, hexc("#5a4030"), tex_side=M.wood("#5a4030", seed, False))
        cv.fill(cv.ellipse_pts(0.5, 0.55, 0.33, 0.33, 0.55), hexc("#2a3438"))
        for z in (0.12, 0.42):
            cv.fill(cv.ellipse_pts(0.5, 0.55, 0.41, 0.41, z, 20, 0, math.pi) + cv.ellipse_pts(0.5, 0.55, 0.41, 0.41, z + 0.05, 20, math.pi, 0), IRON)
    elif art == "anvil":
        cv.shadow(0.5, 0.78, 0.4, 0.18, 0.5)
        cv.cyl(0.5, 0.62, 0.28, 0, 0.42, hexc("#4a3424"), tex_side=M.wood("#4a3424", seed, False), tex_top=M.grainy("#5a4030", seed, 0.2, 6))
        cv.box(0.34, 0.5, 0.66, 0.72, 0.42, 0.58, hexc("#2e2e32"), side=hexc("#222226"))
        cv.front(0.12, 0.88, 0.76, 0.58, 0.76, hexc("#2a2a2e"), shade=(1.0, 0.75))
        cv.ground(0.12, 0.5, 0.88, 0.76, hexc("#4a4a50"), z=0.76, tex=M.grainy("#4a4a50", seed, 0.12, 8))
        pts = [cv.to_px(0.12, 0.52, 0.76), cv.to_px(-0.22, 0.63, 0.72), cv.to_px(0.12, 0.74, 0.76)]
        cv.fill(pts, hexc("#3e3e44"))
        cv.line(cv.to_px(0.55, 0.6, 0.78), cv.to_px(0.85, 0.56, 0.82), 4, WOOD_L)
        cv.box(0.45, 0.55, 0.6, 0.66, 0.76, 0.84, hexc("#3a3a3e"))
    elif art == "mannequin":
        for k in range(int(round(w))):
            x = k + 0.5
            cv.cyl(x, 0.6, 0.2, 0, 0.05, WOOD_D)
            cv.front(x - 0.03, x + 0.03, 0.6, 0.05, 0.75, WOOD_D)
            cv.front(x - 0.26, x + 0.26, 0.62, 0.75, 1.45, hexc("#6a6a6e") if k % 2 == 0 else hexc("#5a4a3a"), shade=(1.0, 0.7))
            cv.front(x - 0.32, x + 0.32, 0.621, 1.35, 1.48, hexc("#7a7a7e"))
            cv.cyl(x, 0.6, 0.12, 1.48, 1.65, hexc("#5a5a5e"))
    elif art == "grindstone":
        cv.box(0.1, 0.4, 0.9, 0.75, 0, 0.35, WOOD_D)
        pts = [cv.to_px(0.5 + 0.38 * math.cos(a), 0.58, 0.72 + 0.38 * math.sin(a)) for a in np.linspace(0, math.tau, 26)]
        cv.fill(pts, hexc("#8a8478"), tex=M.grainy("#8a8478", seed, 0.2, 10))
        cv.fill([cv.to_px(0.5 + 0.08 * math.cos(a), 0.59, 0.72 + 0.08 * math.sin(a)) for a in np.linspace(0, math.tau, 12)], IRON)
    elif art == "weapon_rack":
        cv.front(0.1, 0.2, 0.7, 0, 1.3, WOOD_D)
        cv.front(w - 0.2, w - 0.1, 0.7, 0, 1.3, WOOD_D)
        cv.front(0.1, w - 0.1, 0.71, 1.15, 1.25, WOOD)
        cv.front(0.1, w - 0.1, 0.71, 0.25, 0.33, WOOD)
        for k in range(int(w * 2)):
            x = 0.4 + k * (w - 0.8) / max(1, int(w * 2) - 1)
            if k % 3 == 2:
                cv.line(cv.to_px(x, 0.6, 0.05), cv.to_px(x, 0.6, 1.5), 4, WOOD_L)
                cv.fill([cv.to_px(x - 0.05, 0.6, 1.5), cv.to_px(x, 0.6, 1.68), cv.to_px(x + 0.05, 0.6, 1.5)], hexc("#9a988e"))
            else:
                cv.front(x - 0.03, x + 0.03, 0.6, 0.1, 1.2, hexc("#9a988e"))
                cv.front(x - 0.12, x + 0.12, 0.6, 0.28, 0.33, BRASS * 0.8)
    elif art in ("bars", "teller_window"):
        h = 1.0
        cv.front(0, w, d, 0, h, None, tex=M.slabs("#c2b8a2", 0.8, 0.5, seed, 0.06, vein=0.12), shade=(0.85, 0.6))
        cv.box(-0.04, 0.1, w + 0.04, d + 0.05, h - 0.06, h, hexc("#7a6a52"), tex_top=M.wood("#6a4c34", seed))
        cv.front(0, w, 0.5, h, h + 0.06, BRASS)
        if art == "bars":
            for k in range(int(w * 6)):
                x = 0.08 + k * (w - 0.16) / max(1, int(w * 6) - 1)
                cv.front(x - 0.018, x + 0.018, 0.5, h, 1.85, BRASS * 0.9)
            cv.front(0, w, 0.5, 1.8, 1.86, BRASS)
        else:
            for x in (0.06, w - 0.06):
                cv.front(x - 0.03, x + 0.03, 0.5, h, 1.85, BRASS)
            pts = [cv.to_px(0.06, 0.5, 1.86), cv.to_px(w - 0.06, 0.5, 1.86), cv.to_px(w - 0.06, 0.5, 1.6), cv.to_px(cx, 0.5, 1.75), cv.to_px(0.06, 0.5, 1.6)]
            cv.fill(pts, BRASS)
            cv.cyl(cx + 0.2, 0.7, 0.07, h, h + 0.08, BRASS * 1.2)
            papers(cv, 0.1, 0.55, w - 0.3, d, h + 0.002, 1, seed)
    elif art == "pillar":
        cv.shadow(0.5, 0.65, 0.42, 0.2, 0.45)
        cv.box(0.1, 0.2, 0.9, 0.9, 0, 0.22, hexc("#b8ae98"))
        cv.cyl(0.5, 0.55, 0.3, 0.22, 2.45, hexc("#cec4ae"), tex_side=M.slabs("#cec4ae", 3.0, 3.0, seed, 0.02, vein=0.2))
        cv.box(0.08, 0.18, 0.92, 0.92, 2.45, 2.65, hexc("#b8ae98"))
    elif art == "bench":
        for x in (0.25, w - 0.35):
            cv.front(x, x + 0.1, d - 0.25, 0, 0.42, WOOD_D)
        cv.box(0.05, 0.3, w - 0.05, d - 0.25, 0.38, 0.46, WOOD, tex_top=M.wood("#5e4430", seed))
        cv.box(0.05, 0.12, w - 0.05, 0.26, 0.46, 0.95, WOOD_D)
    else:
        cv.box(0.1, 0.1, w - 0.1, d - 0.1, 0, 0.6, WOOD)
