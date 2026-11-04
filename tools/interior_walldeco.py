"""실내 벽 장식(CT106 — tools/interior_bake.py 전용): 북벽 앞면(남쪽을 보는 면)에 붙은 것. 면 좌표 = (x, 높이 z), 면의 땅 자리 = yf.
몇몇은 벽에서 조금 나온다(벽난로 · 화덕 · 선반 — 세계 좌표 상자). glow = 스스로 빛나는 곳(불 · 유리 — 어둡게 내리지 않는다).
"""
import math

import numpy as np

import interior_mats as M
from interior_canvas import hexc

WOOD_D, WOOD, WOOD_L = hexc("#3a2a1c"), hexc("#5a4030"), hexc("#7a5a3c")
IRON, BRASS, PAPER = hexc("#38383a"), hexc("#9a7e48"), hexc("#c4b48e")
STONE, DARK, FLAME = hexc("#8a8274"), hexc("#140f0c"), hexc("#ffb050")


def rect(cv, yf, x0, x1, z0, z1, color=None, tex=None, shade=(1.0, 0.86), **kw):
    return cv.front(x0, x1, yf, z0, z1, color, tex=tex, shade=shade, **kw)


def arch(cv, yf, x0, x1, z0, z1, color=None, tex=None, pointed=False, **kw):
    """아치 문 · 창(pointed = 뾰족 아치 — 반지름 = 폭인 두 호, 꼭대기가 z1)."""
    cx, r = (x0 + x1) / 2, (x1 - x0) / 2
    rise = r * math.sqrt(3) if pointed else r
    spring = z1 - rise
    pts = [cv.to_px(x0, yf, z0)]
    for i in range(25):
        d = -r + 2 * r * i / 24  # 가운데에서 본 x
        if pointed:
            h = math.sqrt(max(0.0, 4 * r * r - (abs(d) + r) ** 2))
        else:
            h = math.sqrt(max(0.0, r * r - d * d))
        pts.append(cv.to_px(cx + d, yf, spring + h))
    pts.append(cv.to_px(x1, yf, z0))
    return cv.fill(pts, color, tex=tex, **kw)


def flame(cv, yf, x, z, s=1.0, dy=0.04):
    for k, col in enumerate(("#c25a1e", "#f0a040", "#ffe6a8")):
        h = (0.32 - k * 0.09) * s
        w = (0.1 - k * 0.025) * s
        pts = [cv.to_px(x - w, yf + dy, z), cv.to_px(x, yf + dy, z + h), cv.to_px(x + w, yf + dy, z), cv.to_px(x, yf + dy, z - w * 0.5)]
        cv.fill(pts, hexc(col), glow=1.0)


def candle(cv, yf, x, z, h=0.18):
    rect(cv, yf + 0.02, x - 0.035, x + 0.035, z, z + h, hexc("#e4d8bc"))
    flame(cv, yf, x, z + h, 0.45)


def draw(cv, art, x0, x1, yf, H, seed):
    w = x1 - x0
    cx = (x0 + x1) / 2
    if art == "window":
        arch(cv, yf, x0 + 0.2, x1 - 0.2, 0.9, 2.05, STONE * 0.8)
        arch(cv, yf, x0 + 0.3, x1 - 0.3, 1.0, 1.95, hexc("#5a6a78"), glow=0.35)
        for k in range(1, 3):
            xx = x0 + 0.3 + (w - 0.6) * k / 3
            rect(cv, yf, xx - 0.02, xx + 0.02, 1.0, 1.9, IRON)
        rect(cv, yf, x0 + 0.3, x1 - 0.3, 1.42, 1.46, IRON)
        cv.box(x0 + 0.15, yf, x1 - 0.15, yf + 0.12, 0.9, 0.98, STONE)
    elif art in ("notice_board", "tax_notice"):
        rect(cv, yf, x0 + 0.12, x1 - 0.12, 0.85, 2.0, WOOD_D)
        rect(cv, yf, x0 + 0.2, x1 - 0.2, 0.93, 1.92, hexc("#6a5236"))
        rng = np.random.default_rng(seed)
        n = max(2, int(w * 2.2))
        for k in range(n):
            px = x0 + 0.26 + (w - 0.8) * k / max(1, n - 1) + rng.uniform(-0.04, 0.04)
            pz = 1.05 + (k % 2) * 0.4 + rng.uniform(0, 0.12)
            rect(cv, yf + 0.01, px, px + 0.3, pz, pz + 0.36, PAPER * rng.uniform(0.85, 1.05))
            rect(cv, yf + 0.02, px + 0.12, px + 0.18, pz + 0.3, pz + 0.36, hexc("#7a2219"))
    elif art == "rank_chart":
        rect(cv, yf, x0 + 0.15, x1 - 0.15, 0.8, 2.1, WOOD_D)
        rect(cv, yf, x0 + 0.22, x1 - 0.22, 0.87, 2.03, PAPER * 0.9)
        for k in range(9):
            z = 1.92 - k * 0.12
            rect(cv, yf + 0.01, x0 + 0.3, x0 + 0.3 + (w - 0.6) * (0.35 + k * 0.07), z - 0.05, z, hexc("#5a2a1a") * (1 - k * 0.04))
    elif art == "banner":
        rect(cv, yf, cx - 0.4, cx + 0.4, 2.12, 2.18, WOOD_D)
        pts = [cv.to_px(cx - 0.34, yf, 2.12), cv.to_px(cx + 0.34, yf, 2.12), cv.to_px(cx + 0.34, yf, 0.95), cv.to_px(cx, yf, 0.72), cv.to_px(cx - 0.34, yf, 0.95)]
        cv.fill(pts, hexc("#6a2420"), tex=M.grainy("#6a2420", seed, 0.12, 6))
        rect(cv, yf + 0.01, cx - 0.13, cx + 0.13, 1.35, 1.7, BRASS)
    elif art == "trophy":
        for i, hx in enumerate(np.linspace(x0 + 0.5, x1 - 0.5, max(1, int(round(w / 1.0))))):
            arch(cv, yf, hx - 0.26, hx + 0.26, 1.2, 1.75, WOOD_D)
            pts = [cv.to_px(hx - 0.16, yf + 0.05, 1.62), cv.to_px(hx + 0.16, yf + 0.05, 1.62), cv.to_px(hx + 0.07, yf + 0.05, 1.18), cv.to_px(hx - 0.07, yf + 0.05, 1.18)]
            cv.fill(pts, hexc("#5a5048"))
            for s in (-1, 1):
                cv.line(cv.to_px(hx + s * 0.12, yf + 0.06, 1.6), cv.to_px(hx + s * 0.34, yf + 0.06, 1.95), 4, hexc("#c8bca0"))
    elif art in ("door_shut", "door_closed"):
        arch(cv, yf, x0 + 0.1, x1 - 0.1, 0.0, 1.95, STONE * 0.75)
        arch(cv, yf, x0 + 0.16, x1 - 0.16, 0.0, 1.88, tex=M.plank_door(seed))
        for z in (0.45, 1.35):
            rect(cv, yf + 0.01, x0 + 0.18, x1 - 0.18, z, z + 0.07, IRON)
        rect(cv, yf + 0.02, x1 - 0.38, x1 - 0.3, 0.9, 0.98, BRASS)
    elif art == "doc_wall":
        rect(cv, yf, x0 + 0.05, x1 - 0.05, 0.25, 2.15, WOOD_D)
        for zr in range(5):
            z = 0.35 + zr * 0.36
            for k in range(int(w * 3)):
                xx = x0 + 0.1 + k * (w - 0.2) / int(w * 3)
                rect(cv, yf + 0.01, xx + 0.02, xx + (w - 0.2) / int(w * 3) - 0.02, z, z + 0.3, PAPER * (0.7 + 0.25 * ((k * 7 + zr) % 3) / 2))
    elif art == "barrel_shelf":
        cv.box(x0 + 0.05, yf, x1 - 0.05, yf + 0.3, 0.0, 2.2, WOOD_D * 0.8)
        n = max(1, int(w / 0.68))
        for row in range(2):
            z = 0.4 + row * 0.95
            cv.box(x0 + 0.05, yf + 0.3, x1 - 0.05, yf + 0.42, z - 0.4, z - 0.32, WOOD)
            for k in range(n):
                bx = x0 + 0.38 + k * (w - 0.76) / max(1, n - 1)
                ring = [cv.to_px(bx + 0.3 * math.cos(a), yf + 0.36, z + 0.3 * math.sin(a)) for a in np.linspace(0, math.tau, 26)]
                cv.fill(ring, IRON * 1.2)
                head = [cv.to_px(bx + 0.25 * math.cos(a), yf + 0.37, z + 0.25 * math.sin(a)) for a in np.linspace(0, math.tau, 24)]
                cv.fill(head, None, tex=M.plank_door(seed + k * 3 + row))
                rect(cv, yf + 0.38, bx - 0.03, bx + 0.03, z - 0.18, z - 0.06, BRASS)
    elif art == "hatch":
        rect(cv, yf, x0 + 0.15, x1 - 0.15, 0.9, 1.7, WOOD_D)
        rect(cv, yf, x0 + 0.22, x1 - 0.22, 0.97, 1.63, DARK, lit=0.0)
        cv.box(x0 + 0.1, yf, x1 - 0.1, yf + 0.18, 0.86, 0.94, WOOD_L)
        rect(cv, yf + 0.05, cx - 0.2, cx + 0.1, 0.94, 1.08, hexc("#8a7a60"))
    elif art == "fireplace":
        cv.box(x0 + 0.05, yf, x1 - 0.05, yf + 0.3, 0.0, 1.55, STONE, tex_side=M.slabs("#7a7266", 0.5, 0.3, seed, 0.2))
        cv.front(x0 + 0.05, x1 - 0.05, yf + 0.3, 1.55, 1.72, hexc("#4a3a2a"))
        cv.ground(x0, yf + 0.0, x1, yf + 0.42, hexc("#4a3a2a"), z=1.72)
        arch(cv, yf + 0.31, x0 + 0.42, x1 - 0.42, 0.0, 1.05, DARK * 1.3, lit=0.0)
        for k in range(3):
            flame(cv, yf + 0.31, cx - 0.32 + k * 0.32, 0.12, 1.5 - abs(k - 1) * 0.4, dy=0.02)
        cv.ground(x0 + 0.5, yf + 0.31, x1 - 0.5, yf + 0.55, hexc("#3a2a20"), z=0.06)
    elif art == "stained_glass":
        pw = w / 3
        cols = [("#7a2a26", "#a84a32"), ("#a88a3a", "#d4b25a"), ("#2e5a3a", "#4a7a4a")]
        for k in range(3):
            a, b = x0 + k * pw + 0.55, x0 + (k + 1) * pw - 0.55
            top = 2.78 if k == 1 else 2.6
            arch(cv, yf, a - 0.1, b + 0.1, 0.45, top + 0.1, STONE * 0.7, pointed=True)
            arch(cv, yf, a, b, 0.55, top, tex=M.glass(cols[k], seed + k), pointed=True, glow=0.75)
            fx = (a + b) / 2
            pts = [cv.to_px(fx - 0.14, yf + 0.01, 0.75), cv.to_px(fx - 0.1, yf + 0.01, top - 0.8), cv.to_px(fx, yf + 0.01, top - 0.55),
                   cv.to_px(fx + 0.1, yf + 0.01, top - 0.8), cv.to_px(fx + 0.14, yf + 0.01, 0.75)]
            cv.fill(pts, hexc(cols[k][1]) * 1.15, glow=0.8)
            cv.box(a - 0.14, yf, b + 0.14, yf + 0.1, 0.37, 0.45, STONE)
    elif art == "niche_urn":
        arch(cv, yf, x0 + 0.25, x1 - 0.25, 0.35, 1.9, DARK * 1.6, lit=0.6)
        cv.cyl(cx, yf + 0.12, 0.26, 0.4, 0.95, hexc("#7a4a32"), tex_side=M.grainy("#7a4a32", seed, 0.15, 5))
        cv.cyl(cx, yf + 0.12, 0.16, 0.95, 1.1, hexc("#7a4a32"))
    elif art in ("bookshelf", "sealed_shelf"):
        rect(cv, yf, x0 + 0.04, x1 - 0.04, 0.0, 2.25, WOOD_D, tex=M.wood("#3a2a1c", seed, False))
        for k in range(5):
            z = 0.12 + k * 0.42
            rect(cv, yf + 0.01, x0 + 0.14, x1 - 0.14, z, z + 0.34, tex=M.books(seed + k), shade=(0.7, 1.0))
            rect(cv, yf + 0.02, x0 + 0.1, x1 - 0.1, z - 0.04, z, WOOD_L)
        cv.ground(x0, yf, x1, yf + 0.2, WOOD, z=2.28)
        if art == "sealed_shelf":
            for k in range(3):
                cv.line(cv.to_px(x0 + 0.1, yf + 0.04, 0.4 + k * 0.7), cv.to_px(x1 - 0.1, yf + 0.04, 0.55 + k * 0.7), 5, IRON)
            rect(cv, yf + 0.05, cx - 0.12, cx + 0.12, 1.0, 1.3, BRASS)
    elif art == "potion_shelf":
        rect(cv, yf, x0 + 0.05, x1 - 0.05, 0.6, 2.15, WOOD_D)
        rng = np.random.default_rng(seed)
        pal = ["#6a2a2a", "#2e5a4a", "#4a3a6a", "#8a6a2a", "#3a5a2a"]
        for row in range(3):
            z = 0.7 + row * 0.48
            rect(cv, yf + 0.02, x0 + 0.05, x1 - 0.05, z - 0.05, z, WOOD_L)
            xx = x0 + 0.18
            while xx < x1 - 0.2:
                bw = rng.uniform(0.1, 0.16)
                bh = rng.uniform(0.18, 0.32)
                col = hexc(pal[rng.integers(len(pal))])
                rect(cv, yf + 0.03, xx, xx + bw, z, z + bh, col, glow=0.15)
                rect(cv, yf + 0.03, xx + bw * 0.3, xx + bw * 0.7, z + bh, z + bh + 0.06, hexc("#8a7a60"))
                xx += bw + rng.uniform(0.04, 0.1)
    elif art == "torch_bundle":
        for k in range(int(w * 3)):
            xx = x0 + 0.2 + k * (w - 0.4) / max(1, int(w * 3) - 1)
            cv.line(cv.to_px(xx, yf + 0.03, 0.75), cv.to_px(xx + 0.05, yf + 0.03, 1.6), 6, WOOD_L)
            rect(cv, yf + 0.04, xx - 0.05, xx + 0.08, 1.5, 1.72, hexc("#3a2a1a"))
        rect(cv, yf + 0.05, x0 + 0.1, x1 - 0.1, 1.05, 1.12, hexc("#8a6a3a"))
    elif art == "rope_hooks":
        for k in range(int(w * 2)):
            xx = x0 + 0.3 + k * (w - 0.6) / max(1, int(w * 2) - 1)
            rect(cv, yf + 0.02, xx - 0.03, xx + 0.03, 1.85, 1.95, IRON)
            if k % 2 == 0:
                cv.fill([cv.to_px(xx + 0.22 * math.cos(a), yf + 0.03, 1.55 + 0.3 * math.sin(a)) for a in np.linspace(0, math.tau, 18)], hexc("#9a8458"))
                cv.fill([cv.to_px(xx + 0.13 * math.cos(a), yf + 0.04, 1.55 + 0.2 * math.sin(a)) for a in np.linspace(0, math.tau, 14)], hexc("#5a4a30"))
            else:
                rect(cv, yf + 0.03, xx - 0.2, xx + 0.2, 1.2, 1.8, hexc("#6a5236"))
                rect(cv, yf + 0.04, xx - 0.16, xx + 0.16, 1.55, 1.62, WOOD_D)
    elif art in ("weapon_wall", "shield_wall"):
        rect(cv, yf, x0 + 0.08, x1 - 0.08, 0.7, 2.1, WOOD_D * 0.9)
        for k in range(max(1, int(w * 1.2))):
            xx = x0 + 0.45 + k * (w - 0.9) / max(1, int(w * 1.2) - 1)
            if art == "shield_wall":
                pts = [cv.to_px(xx - 0.3, yf + 0.03, 1.85), cv.to_px(xx + 0.3, yf + 0.03, 1.85), cv.to_px(xx + 0.26, yf + 0.03, 1.25), cv.to_px(xx, yf + 0.03, 0.98), cv.to_px(xx - 0.26, yf + 0.03, 1.25)]
                cv.fill(pts, hexc(["#5a2a22", "#2e3e52", "#5a4a2a"][k % 3]))
                rect(cv, yf + 0.04, xx - 0.05, xx + 0.05, 1.05, 1.8, IRON * 1.4)
            else:
                cv.line(cv.to_px(xx - 0.28, yf + 0.03, 0.85), cv.to_px(xx + 0.28, yf + 0.03, 1.95), 5, hexc("#9a988e"))
                cv.line(cv.to_px(xx + 0.28, yf + 0.03, 0.85), cv.to_px(xx - 0.28, yf + 0.03, 1.95), 5, hexc("#8a8a84"))
                rect(cv, yf + 0.04, xx - 0.12, xx + 0.12, 1.35, 1.45, WOOD_D)
    elif art == "forge":
        cv.box(x0 + 0.05, yf, x1 - 0.05, yf + 0.6, 0.0, 0.9, hexc("#5a4e44"), tex_side=M.wall("brick_soot", seed, yf + 0.6))
        pts = [cv.to_px(x0 + 0.35, yf, 2.6), cv.to_px(x1 - 0.35, yf, 2.6), cv.to_px(x1 - 0.05, yf + 0.6, 1.3), cv.to_px(x0 + 0.05, yf + 0.6, 1.3)]
        cv.fill(pts, None, tex=M.wall("brick_soot", seed + 1, yf + 0.6))
        cv.front(x0 + 0.05, x1 - 0.05, yf + 0.6, 1.22, 1.32, hexc("#2a221c"))
        cv.ground(x0 + 0.05, yf, x1 - 0.05, yf + 0.6, hexc("#2a201a"), z=0.91)
        cv.ground(x0 + 0.35, yf + 0.08, x1 - 0.35, yf + 0.5, None, z=0.92, tex=M.coals(seed), glow=1.0)
        arch(cv, yf + 0.61, cx - 0.45, cx + 0.45, 0.2, 0.75, DARK, lit=0.0)
        cv.ground(cx - 0.4, yf + 0.61, cx + 0.4, yf + 0.62, hexc("#ff8a3a"), z=0.25, glow=1.0)
        for k in range(3):
            flame(cv, yf + 0.3, cx - 0.4 + k * 0.4, 0.95, 0.8 - abs(k - 1) * 0.2)
    elif art == "vault_door":
        rect(cv, yf, x0 + 0.1, x1 - 0.1, 0.0, 2.15, IRON * 0.9)
        cv.fill([cv.to_px(cx + 0.78 * math.cos(a), yf + 0.01, 1.0 + 0.85 * math.sin(a)) for a in np.linspace(0, math.tau, 40)], hexc("#6a6a66"))
        cv.fill([cv.to_px(cx + 0.6 * math.cos(a), yf + 0.02, 1.0 + 0.66 * math.sin(a)) for a in np.linspace(0, math.tau, 36)], hexc("#7e7c74"))
        for k in range(6):
            a = k * math.tau / 6
            cv.line(cv.to_px(cx, yf + 0.03, 1.0), cv.to_px(cx + 0.4 * math.cos(a), yf + 0.03, 1.0 + 0.44 * math.sin(a)), 5, BRASS)
        for k in range(8):
            xx = x0 + 0.2 + k * (w - 0.4) / 7
            rect(cv, yf + 0.04, xx - 0.025, xx + 0.025, 0.0, 2.1, IRON * 0.6)  # 창살(앞에 선다)
    elif art == "clock":
        rect(cv, yf, cx - 0.28, cx + 0.28, 0.9, 2.1, WOOD_D)
        cv.fill([cv.to_px(cx + 0.22 * math.cos(a), yf + 0.01, 1.8 + 0.22 * math.sin(a)) for a in np.linspace(0, math.tau, 24)], hexc("#c8b890"))
        cv.line(cv.to_px(cx, yf + 0.02, 1.8), cv.to_px(cx, yf + 0.02, 1.95), 3, DARK)
        cv.line(cv.to_px(cx, yf + 0.02, 1.8), cv.to_px(cx + 0.12, yf + 0.02, 1.8), 3, DARK)
        rect(cv, yf + 0.01, cx - 0.06, cx + 0.06, 1.05, 1.5, BRASS)
