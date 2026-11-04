"""실내 가구(CT106 — tools/interior_bake.py 전용): 가구 덩어리 하나 = 그림 하나. 좌표 = 덩어리 왼쪽 위 땅이 (0, 0), 폭 w · 깊이 d(칸).
윗면 + 앞면(남)만 보인다(3/4). 빛나는 것(촛불 · 불)은 glow. HEIGHT = 그림판 높이를 정할 때 쓰는 가장 높은 곳(칸).
"""
import math

import numpy as np

import interior_mats as M
from interior_canvas import hexc
from interior_walldeco import candle, flame
import interior_fine as IF

WOOD_D, WOOD, WOOD_L = hexc("#3a2a1c"), hexc("#5a4030"), hexc("#7a5a3c")
IRON, BRASS, PAPER = hexc("#38383a"), hexc("#9a7e48"), hexc("#c4b48e")
STONE, CLOTH_R, CLOTH_G = hexc("#8a8274"), hexc("#6a2e26"), hexc("#3e4a34")

HEIGHT = {"pillar": 2.7, "wardrobe": 2.1, "bookcase": 2.2, "candelabra": 1.95, "specimen_shelf": 2.1, "mannequin": 1.7, "bars": 1.9,
          "teller_window": 1.9, "crates": 1.4, "workbench": 1.1, "barrels": 1.0, "bed": 1.0, "weapon_rack": 1.5, "chained_lectern": 1.4, "basin": 1.2, "font": 1.2}


def legs(cv, x0, y0, x1, y1, h, col, t=0.08):
    """다리 넷(뒤 둘은 어둡게 먼저 — 위로 보인다) + 아래 가로대(CT112 — 앞 다리 둘만이라 납작했다)."""
    for (lx, ly) in ((x0 + 0.04, y0 + 0.1), (x1 - 0.04 - t, y0 + 0.1)):
        cv.front(lx, lx + t, ly, 0, h, col * 0.62, shade=(0.7, 0.5))
    cv.front(x0 + 0.04, x1 - 0.04, y0 + 0.1, h * 0.22, h * 0.22 + 0.05, col * 0.55, shade=(0.8, 0.6))
    cv.front(x0 + 0.04, x1 - 0.04, y1 - 0.06, h * 0.22, h * 0.22 + 0.05, col * 0.8, shade=(0.9, 0.7))
    for (lx, ly) in ((x0 + 0.04, y1 - 0.06), (x1 - 0.04 - t, y1 - 0.06)):
        cv.front(lx, lx + t, ly, 0, h, col)


def table(cv, x0, y0, x1, y1, h, col=None, tex=None, legs_col=None):
    col = WOOD if col is None else col
    legs(cv, x0 + 0.05, y0, x1 - 0.05, y1, h, legs_col if legs_col is not None else col * 0.7)
    cv.box(x0, y0, x1, y1, h - 0.08, h, col, tex_top=tex or M.wood("#6a4c34", 7), tex_side=M.wood("#4a3424", 8))
    cv.front(x0 + 0.06, x1 - 0.06, y1 - 0.05, h - 0.22, h - 0.08, col * 0.55, shade=(0.6, 0.9))  # 판 밑 앞 띠(그늘 — CT112)


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
    """세 다리 걸상(앉는 높이 0.53칸 ≈ 0.45m · 지름 0.44칸 — CT113): 뒤 다리(어둡게) · 앞 두 다리(벌어진다) · 가로대 · 두께 있는 둥근 앉을 판."""
    h = 0.53
    cv.front(x - 0.03, x + 0.03, y - 0.12, 0, h - 0.06, WOOD_D * 0.6, shade=(0.7, 0.5))
    for s in (-1, 1):
        pts = [cv.to_px(x + s * 0.09, y + 0.1, h - 0.06), cv.to_px(x + s * 0.09 + s * 0.06, y + 0.1, h - 0.06), cv.to_px(x + s * 0.2, y + 0.14, 0.0), cv.to_px(x + s * 0.14, y + 0.14, 0.0)]
        cv.fill(pts, WOOD_D, shade=(0.95, 0.7))
    cv.front(x - 0.14, x + 0.14, y + 0.12, 0.17, 0.21, WOOD_D * 0.85)
    cv.cyl(x, y, 0.22, h - 0.07, h, WOOD_L * 0.9, side=WOOD * 0.8, tex_top=M.wood("#7a5a3c", int(x * 31 + y * 17)))


def chair(cv, x, y, back=True):
    """의자: 뒤 다리 · 등받이(살 셋) · 앉을 판(두께) · 앞 다리 · 가로대."""
    for s in (-1, 1):
        cv.front(x + s * 0.15 - 0.03, x + s * 0.15 + 0.03, y - 0.1, 0, 0.44 + (0.52 if back else 0.0), WOOD_D * 0.7, shade=(0.85, 0.55))
    if back:
        cv.front(x - 0.16, x + 0.16, y - 0.1, 0.86, 0.96, WOOD, shade=(1.0, 0.8))
        for k in (-0.07, 0.0, 0.07):
            cv.front(x + k - 0.015, x + k + 0.015, y - 0.1, 0.5, 0.86, WOOD_D * 0.85)
    cv.box(x - 0.18, y - 0.14, x + 0.18, y + 0.14, 0.4, 0.45, WOOD, side=WOOD_D, tex_top=M.wood("#6a4c34", int(x * 13 + y * 7)))
    for s in (-1, 1):
        cv.front(x + s * 0.15 - 0.03, x + s * 0.15 + 0.03, y + 0.13, 0, 0.4, WOOD_D)
    cv.front(x - 0.15, x + 0.15, y + 0.13, 0.12, 0.16, WOOD_D * 0.8)


def draw(cv, art, w, d, seed):
    cx = w / 2
    if art in ("counter", "bar", "shop_counter"):
        h = 1.0
        cv.front(0, w, d, 0, h - 0.08, WOOD, tex=M.planks("#5a4030", 0.22, seed), shade=(0.85, 0.6))
        cv.front(0.02, w - 0.02, d + 0.004, 0.0, 0.12, WOOD_D * 0.7)  # 발 차는 굽
        for k in range(int(w)):
            IF.panel(cv, k + 0.1, k + 0.9, d, 0.18, h - 0.2, WOOD * 0.95, 0.07)
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
        if art == "reading_table":  # 읽는 탁자: 둥근 판 + 의자(CT113) · 펼친 책 · 촛불
            IF.dining(cv, w, d, seed, oval=True)
            cy = d / 2
            for (bx, by) in ((cx - 0.6, cy - 0.12), (cx + 0.3, cy + 0.05)):
                cv.ground(bx, by, bx + 0.25, by + 0.32, PAPER, z=IF.TOP + 0.005)
                cv.ground(bx + 0.25, by, bx + 0.5, by + 0.32, PAPER * 0.92, z=IF.TOP + 0.005)
            cv.cyl(cx - 0.05, cy - 0.25, 0.06, IF.TOP, IF.TOP + 0.03, BRASS)
            cv.front(cx - 0.08, cx - 0.02, cy - 0.24, IF.TOP + 0.03, IF.TOP + 0.2, hexc("#e4d8bc"))
            flame(cv, cy - 0.23, cx - 0.05, IF.TOP + 0.2, 0.45)
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
        IF.round_table(cv, w, d, cx, seed)
        mug(cv, cx + 0.18, 0.5, 0.78)
        cv.fill(cv.ellipse_pts(cx - 0.18, 0.35, 0.16, 0.12, 0.785), hexc("#8a7a60"))
    elif art == "lute_chair":
        chair(cv, 0.5, 0.5)
        pts = [cv.to_px(0.62 + 0.2 * math.cos(a), 0.72, 0.5 + 0.24 * math.sin(a)) for a in np.linspace(0, math.tau, 20)]
        cv.fill(pts, hexc("#8a5a2e"))
        cv.line(cv.to_px(0.62, 0.73, 0.6), cv.to_px(0.85, 0.73, 1.2), 4, WOOD_D)
    elif art == "bed":
        IF.bed(cv, w, d, seed, CLOTH_R)  # CT112
    elif art == "chest":
        IF.chest(cv, 0.1, 0.3, 0.9, 0.85, 0.45, WOOD, seed)
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
        IF.cabinet(cv, 0.05, 0.2, w - 0.05, d - 0.05, 2.2, WOOD_D * 1.15, tex_side=M.wood("#3a2a1c", seed, False))
        for k in range(5):
            z = 0.2 + k * 0.38
            cv.front(0.12, w - 0.12, d - 0.06, z, z + 0.33, hexc("#120d09"))  # 칸 안(깊다)
            cv.front(0.15, w - 0.15, d - 0.1, z, z + 0.3, None, tex=M.books(seed + k), shade=(0.75, 1.0))  # 책은 안으로 들어가 앉는다
            cv.box(0.1, d - 0.18, w - 0.1, d - 0.05, z - 0.04, z, WOOD_L * 0.9)  # 칸 판(앞 모서리 빛)
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
        cv.box(-0.06, 0, w + 0.06, d + 0.04, 0, 0.08, hexc("#8a8270"), tex_side=M.slabs("#8a8270", 0.6, 0.08, seed, 0.1))  # 두 단(아래가 넓다)
        cv.box(0.04, 0.02, w - 0.04, d - 0.18, 0.08, 0.2, hexc("#aaa290"), tex_side=M.slabs("#9a9280", 0.6, 0.12, seed + 1, 0.1), tex_top=M.slabs("#b4ac98", 1.2, 0.9, seed, 0.1))
    elif art == "pew":
        IF.pew(cv, w, d, seed)
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
        IF.cabinet(cv, 0.05, 0.25, w - 0.05, d - 0.05, 2.1, WOOD_D * 1.3, tex_side=M.wood("#3e2c1e", seed, False))
        for s in (-1, 1):  # 문짝 둘(판 위아래)
            a, b = (0.14, cx - 0.03) if s < 0 else (cx + 0.03, w - 0.14)
            IF.panel(cv, a, b, d - 0.05, 0.22, 1.05, WOOD_D * 1.35)
            IF.panel(cv, a, b, d - 0.05, 1.12, 1.9, WOOD_D * 1.35)
            cv.front(cx + s * 0.1 - 0.025, cx + s * 0.1 + 0.025, d - 0.04, 0.95, 1.12, BRASS)
        cv.front(cx - 0.015, cx + 0.015, d - 0.045, 0.15, 1.95, hexc("#140e09"))
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
        IF.pew(cv, w, d, seed)
    elif art == "table":  # 집 식탁(CT110 → CT113: 의자가 둘러앉는다)
        IF.dining(cv, w, d, seed)
    elif art == "cot":  # 짚 침대: 낮은 나무 틀 + 짚 요 + 거친 담요
        cv.box(0.05, 0.1, w - 0.05, d - 0.05, 0, 0.28, WOOD, tex_side=M.wood("#5a4030", seed))
        cv.ground(0.12, 0.16, w - 0.12, d - 0.1, None, z=0.34, tex=M.grainy("#a08a5a", seed, 0.25, 9))
        cv.ground(0.4, 0.2, w - 0.12, d - 0.1, None, z=0.38, tex=M.grainy("#5a4a3a", seed + 1, 0.15, 5))
        cv.front(0.4, w - 0.12, d - 0.1, 0.28, 0.38, hexc("#4a3a2e"))
        cv.box(0.16, 0.22, 0.42, d - 0.2, 0.34, 0.44, hexc("#b8ac8a"))
    elif art == "crates":  # 궤짝 더미(쌓인 나무 상자 · 쇠띠)
        rng = np.random.default_rng(seed)
        for (x0, y0, z0, s_) in ((0.1, 0.35, 0, 0.75), (min(w - 0.8, 0.95), 0.3, 0, 0.7), (0.3, 0.38, 0.75, 0.55)):
            if x0 + s_ > w + 0.05:
                continue
            IF.crate(cv, x0, y0, x0 + s_, y0 + s_ * 0.8, z0, z0 + s_ * 0.9, seed + int(x0 * 10))
    elif art == "workbench":  # 작업대: 두꺼운 판 · 다리 · 바이스 · 연장 · 대팻밥
        table(cv, 0.05, 0.15, w - 0.05, d - 0.05, 0.9, col=hexc("#6a4a30"))
        cv.box(0.2, d - 0.3, 0.45, d - 0.02, 0.9, 1.05, IRON * 1.3)
        cv.line(cv.to_px(w * 0.45, 0.4, 0.92), cv.to_px(w * 0.65, 0.45, 0.92), 4, WOOD_L)
        cv.box(w * 0.45 - 0.06, 0.36, w * 0.45 + 0.06, 0.5, 0.91, 0.98, IRON)
        cv.box(w * 0.75, 0.3, w * 0.75 + 0.4, 0.5, 0.91, 0.99, hexc("#8a6a3a"))
        for k in range(6):
            cv.fill(cv.ellipse_pts(0.6 + k * 0.32, d * 0.8 + (k % 2) * 0.08, 0.06, 0.03, 0.0), hexc("#c8a46a"))
    elif art == "lumber":  # 목재 더미(가로로 쌓은 각목 · 통나무 끝)
        for row in range(3):
            for k in range(int(w * 2) - row):
                x = 0.2 + k * 0.45 + row * 0.22
                z = row * 0.22
                cv.cyl(x, d * 0.6, 0.12, z, z + 0.22, hexc("#8a6a42"), ry=0.12)
        cv.box(0.05, 0.2, w - 0.05, d * 0.6, 0.0, 0.1, hexc("#6a5038"))
    elif art == "strongbox":  # 쇠 금고(쇠띠 · 큰 자물쇠 · 둥근 뚜껑)
        IF.chest(cv, 0.12, 0.3, 0.88, 0.85, 0.5, IRON * 1.6, seed, hexc("#22201e"))
    else:
        cv.box(0.1, 0.1, w - 0.1, d - 0.1, 0, 0.6, WOOD)
