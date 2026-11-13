"""바닥 타일 — 4 × 4칸(256px)을 덮는, 사방으로 이어지는 넓은 그림(2층 바닥과 같은 방식 · 타일 art.span 4).
같은 돌 배치(판석 flag)에 상태만 덧입힌 변형(금 · 깨짐 · 이끼 · 얼룩 · 피 · 물 · 마력)은 돌 줄눈이 그대로 이어져서, 칸 단위로 바꿔 깔아도 이음매가 없다.
(자국을 한 군데만 놓고 싶으면 바닥 타일 대신 낱 자국 그림 — a_trace · a_nature의 decal — 을 얹는다.)"""
import numpy as np

import ground
import surf
from kit import flat
from surf import W, F, fbm, hexc, pnoise
import tex

STONE = hexc("#6c6961")
GAP = hexc("#1b1a1a")
MEAN = "#5c5a54"
TILE = {"tile": [64, 64], "span": 4}


def _rgba(rgb):
    return np.concatenate([rgb, np.full(rgb.shape[:2] + (1,), 255, np.uint8)], -1)


def _flag(seed=1):
    cell, edge, _ = surf.courses(seed, 5, 96, 150, 2.5)
    img, gap, h = surf.stonework(cell, edge, STONE, GAP, seed, 3.2, 0.13, 0.9)
    return img, gap, h, cell, edge


def _floor(id, name, variants=None, base=None, **meta):
    m = dict(TILE, **meta)
    if base:
        m["base"] = base
    return flat(id, "floor", layer="floor", cell=(256, 256), variants=variants or {"a": {"seed": 1}}, name_ko=name, meta=m, tags=["floor"])


@_floor("floor_flag", "석재 바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def floor_flag(c, seed=1):
    img, gap, h, _, _ = _flag(seed)
    rng = np.random.default_rng(seed + 50)
    ly = tex.Layer()
    ground.stones(ly, rng, 10, 1.6, 3.2, STONE * 1.1)
    return _rgba(surf.finish(ly.over(img), MEAN, seed))


@_floor("floor_old", "오래된 석재 바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def floor_old(c, seed=1):
    """닳아 둥글어진 큰 판석: 틈이 넓고 흙이 찼다. 모서리가 떨어져 나갔다."""
    cell, d1, edge = tex.voronoi(30, seed + 300, 0.75)
    img, gap, h = surf.stonework(cell, edge - 1.5, hexc("#646058"), hexc("#262320"), seed, 6.0, 0.17, 1.25, 0.03, 0.9)
    worn = np.clip((fbm(7, seed + 3, 3) - 0.45) * 3.0, 0, 1)
    img = img * (1 - worn[..., None] * 0.18)
    dirt = np.clip(gap * 1.5 + (fbm(9, seed + 8, 3) - 0.62) * 3.0, 0, 1) * 0.75
    img = surf.mix(img, dirt, hexc("#3c342a") * (0.8 + fbm(40, seed + 9, 2)[..., None] * 0.4))
    rng = np.random.default_rng(seed + 51)
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 5, 60, width=1.5, branch=0.2)
    ground.stones(ly, rng, 26, 1.6, 4.0, hexc("#6a665c"))
    return _rgba(surf.finish(ly.over(img), "#55524b", seed))


@_floor("floor_cracked", "금이 간 바닥", base="floor_flag")
def floor_cracked(c, seed=1):
    img, gap, h, _, _ = _flag(1)
    rng = np.random.default_rng(seed + 52)
    ly = tex.Layer()
    pts = surf.crack_lines(ly, rng, 9, 170, width=2.8, branch=0.2)
    for x, y in pts[::9]:   # 금 둘레에 떨어져 나온 부스러기
        ly.blob(x + rng.uniform(-6, 6), y + rng.uniform(-6, 6), rng.uniform(1.5, 3.5), rng.uniform(1.2, 2.5), STONE * rng.uniform(0.6, 1.2), 1.0, rng.uniform(0, 3), 6, 0.3, rng)
    return _rgba(surf.finish(ly.over(img), MEAN, 1, ref=img))


@_floor("floor_broken", "깨진 바닥", base="floor_flag")
def floor_broken(c, seed=1):
    """판석 몇 장이 빠지거나 조각났다: 빠진 자리는 꺼진 흙, 가장자리에 깨진 조각."""
    img, gap, h, cell, edge = _flag(1)
    img0 = img
    rng = np.random.default_rng(seed + 53)
    n = int(cell.max()) + 1
    gone = rng.random(n) < 0.24
    hole = gone[cell].astype(F)
    hole = np.clip(tex.blur(hole, 3) * 1.6 - 0.3 + (fbm(24, seed + 4, 2) - 0.5) * 0.7, 0, 1)
    hole = np.clip((hole - 0.45) * 8.0, 0, 1)
    inner = np.clip(tex.blur(hole, 9) * 1.3 - 0.3, 0, 1)
    soil, _ = ground.earth(hexc("#3a332b"), seed + 5, 0.3, 1.3)
    lip = np.clip(np.roll(hole, (5, 5), (0, 1)) - hole, -1, 1)      # 왼쪽 위 턱 그늘 / 오른쪽 아래 밝은 턱
    img = surf.mix(img, hole, soil * (0.55 + inner[..., None] * 0.6))
    img = img * (1.0 + np.minimum(lip, 0)[..., None] * 0.75)
    img = img * (1.0 - np.clip(-lip, 0, 1)[..., None] * 0.0) + np.clip(lip, 0, 1)[..., None] * 0.05
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 5, 90, width=2.2, branch=0.2)
    base_img = img0
    for _ in range(90):   # 깨진 조각 · 잔돌(구멍 둘레에 몰린다)
        x, y = rng.random() * W, rng.random() * W
        if hole[int(y), int(x)] < 0.5 and tex.blur(hole, 12)[int(y), int(x)] < 0.12:
            continue
        r = rng.uniform(2.5, 8.0)
        col = STONE * rng.uniform(0.75, 1.15)
        rot = rng.uniform(0, 3.14)
        ly.blob(x + 2, y + 2.5, r * 1.1, r * 0.8, tex.SHADOW, 0.6, rot, 6, 0.3, rng)
        ly.blob(x, y, r, r * 0.72, col, 1.0, rot, 6, 0.35, rng)
        ly.blob(x - r * 0.2, y - r * 0.2, r * 0.5, r * 0.34, np.minimum(col * 1.3, 1.0), 0.8, rot, 5, 0.2, rng)
    return _rgba(surf.finish(ly.over(img), MEAN, 1, ref=base_img))


@_floor("floor_cobble", "불규칙한 돌바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def floor_cobble(c, seed=1):
    cell, d1, edge = tex.voronoi(150, seed + 310, 1.0)
    img, gap, h = surf.stonework(cell, edge - 1.0, hexc("#6a675f"), hexc("#1e1c1a"), seed, 4.5, 0.15, 0.95, 0.03, 0.4)
    dome = np.clip(1.0 - d1 / 26.0, 0, 1) ** 0.5      # 돌마다 볼록하다
    img = img * surf.relief(dome, 0.55)[..., None]
    dirt = np.clip(gap * 1.2 - 0.2, 0, 1) * np.clip(fbm(8, seed + 3, 2) * 2 - 0.4, 0, 1)
    img = surf.mix(img, dirt, hexc("#3a3228"), 0.7)
    return _rgba(surf.finish(img, "#55534d", seed))


@_floor("floor_brick", "벽돌 바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def floor_brick(c, seed=1):
    cell, edge, row = surf.courses(seed + 320, 16, 56, 70, 1.4, True, 0.06)
    img, gap, h = surf.stonework(cell, edge, hexc("#6a5448"), hexc("#221c1a"), seed, 2.6, 0.2, 0.9, 0.05, 0.6)
    soot = np.clip((fbm(5, seed + 3, 3) - 0.5) * 2.4, 0, 1)
    img = img * (1 - soot[..., None] * 0.32)
    rng = np.random.default_rng(seed + 54)
    chipm = (rng.random(int(cell.max()) + 1) < 0.07)[cell].astype(F) * np.clip(fbm(30, seed + 6, 2) * 2 - 0.6, 0, 1)
    img = img * (1 - chipm[..., None] * 0.45)
    return _rgba(surf.finish(img, "#574a42", seed))


@_floor("floor_mossy", "이끼가 낀 바닥", base="floor_flag")
def floor_mossy(c, seed=1):
    img, gap, h, _, edge = _flag(1)
    img0 = img
    moss = np.clip((fbm(6, seed + 30, 4) - 0.5) * 4.5 + gap * 1.2 + np.clip(1 - edge / 16.0, 0, 1) * 0.35, 0, 1)
    tone = 0.7 + fbm(36, seed + 31, 2) * 0.6
    img = surf.mix(img, moss * 0.9, hexc("#3e4a2a")[None, None, :] * tone[..., None])
    img = img * (1.0 + (surf.relief(moss * 0.6 + fbm(48, seed + 32, 2) * 0.3 * moss, 1.4) - 1.0) * moss)[..., None]
    rng = np.random.default_rng(seed + 55)
    ly = tex.Layer()
    ground.strokes(ly, rng, 2600, 4, 9, [hexc("#3a4a26"), hexc("#4c5c30"), hexc("#5e6a3a")], 0.1, 0.9, 1.6, 0.85, np.clip(moss * 1.2 - 0.3, 0, 1))
    for _ in range(120):
        x, y = rng.random() * W, rng.random() * W
        if moss[int(y), int(x)] > 0.6:
            ly.blob(x, y, rng.uniform(2, 4.5), rng.uniform(1.6, 3.5), hexc("#6a7440") * rng.uniform(0.8, 1.15), 0.9, 0, 7, 0.3, rng)
    return _rgba(surf.finish(ly.over(img), MEAN, 1, ref=img0))


@_floor("floor_stained", "얼룩진 바닥", base="floor_flag")
def floor_stained(c, seed=1):
    """기름때 · 검댕 · 녹물 얼룩 + 마른 물 테."""
    img, gap, h, _, _ = _flag(1)
    img0 = img
    grime = np.clip((fbm(4, seed + 40, 4) - 0.45) * 3.2, 0, 1)
    img = surf.mix(img, grime * 0.5, hexc("#24211d"))
    rust = np.clip((fbm(7, seed + 41, 3) - 0.58) * 5.0, 0, 1)
    img = surf.mix(img, rust * 0.42, hexc("#5a3a26"))
    oiln = fbm(9, seed + 42, 4)
    oil = np.clip((oiln - 0.62) * 7.0, 0, 1)
    img = surf.mix(img, oil * 0.7, hexc("#161412"))
    img = img + (np.clip(surf.relief(h, 4.0) - 1.15, 0, 1) * oil)[..., None] * 0.2        # 기름 번들거림
    ringn = fbm(5, seed + 43, 3)                                                           # 마른 물 테(넓고 옅게)
    ring = np.clip(1.0 - np.abs(ringn - 0.6) / 0.03, 0, 1) * np.clip((ringn - 0.5) * 20, 0, 1) * np.clip(fbm(3, seed + 44, 2) * 3 - 1.0, 0, 1)
    img = surf.mix(img, ring * 0.16, hexc("#a09a88"))
    img = img * (1 - np.clip((ringn - 0.6) * 12, 0, 1)[..., None] * 0.12)
    return _rgba(surf.finish(img, MEAN, 1, ref=img0))


@_floor("floor_bloody", "피가 묻은 바닥", base="floor_flag")
def floor_bloody(c, seed=1):
    """마른 피 웅덩이가 줄눈을 따라 번졌다 + 튄 방울 + 끌린 자국."""
    img, gap, h, _, _ = _flag(1)
    img0 = img
    n = fbm(3, seed + 60, 4)
    pool = np.clip((n - 0.63) * 14.0, 0, 1)
    run = np.clip(gap * np.clip((tex.blur(pool, 14) - 0.08) * 6.0, 0, 1) * 1.4, 0, 1)      # 줄눈을 타고 흐른 피
    m = np.clip(np.maximum(pool, run), 0, 1)
    dry = hexc("#3a1210")[None, None, :] * (0.6 + fbm(30, seed + 61, 2) * 0.6)[..., None]
    img = surf.mix(img, m * 0.9, dry * 0.62 + img * dry * 1.3)
    rimm = np.clip(1.0 - np.abs(n - 0.635) / 0.012, 0, 1) * 0.55
    img = surf.mix(img, rimm, hexc("#240a0a"))
    img = img + (np.clip(surf.relief(h + n * 2.0, 3.0) - 1.2, 0, 1) * pool)[..., None] * np.array([0.16, 0.05, 0.04], F)
    rng = np.random.default_rng(seed + 56)
    ly = tex.Layer()
    for _ in range(170):   # 튄 방울(웅덩이 가까이에 몰린다)
        x, y = rng.random() * W, rng.random() * W
        if tex.blur(pool, 22)[int(y), int(x)] < 0.06 + rng.random() * 0.1:
            continue
        r = rng.uniform(1.0, 4.2)
        ly.blob(x, y, r, r * rng.uniform(0.6, 1.0), hexc("#40110f") * rng.uniform(0.8, 1.2), 0.92, rng.uniform(0, 3), 7, 0.35, rng)
    for _ in range(4):     # 끌린 자국
        x, y, a = rng.random() * W, rng.random() * W, rng.uniform(0, 6.28)
        for k in range(5):
            o = (k - 2) * 5.0
            pts = [(x + np.cos(a) * t * 22 - np.sin(a) * (o + rng.uniform(-2, 2)), y + np.sin(a) * t * 22 + np.cos(a) * (o + rng.uniform(-2, 2))) for t in range(6)]
            ly.line(pts, hexc("#451412"), 0.42, rng.uniform(2.0, 4.5))
    return _rgba(surf.finish(ly.over(img), MEAN, 1, 0.14, ref=img0))


@_floor("floor_wet", "물이 고인 바닥", base="floor_flag")
def floor_wet(c, seed=1):
    """젖은 돌 + 낮은 곳에 고인 얕은 물: 물속 돌은 어둡고 푸르게, 가장자리에 밝은 테와 번들거림."""
    img, gap, h, _, _ = _flag(1)
    img0 = img
    n = fbm(4, seed + 70, 4) + gap * 0.06
    pool = np.clip((n - 0.52) * 18.0, 0, 1)
    damp = np.clip((n - 0.4) * 5.0, 0, 1)
    img = img * (1 - damp[..., None] * 0.25)
    depth = np.clip((n - 0.52) * 6.0, 0, 1)
    water = img * np.array([0.5, 0.56, 0.6], F) * (1 - depth[..., None] * 0.45) + hexc("#0e1418") * 0.3
    img = surf.mix(img, pool * 0.94, water)
    rim = np.clip(1.0 - np.abs(n - 0.524) / 0.01, 0, 1)
    img = surf.mix(img, rim * 0.22, hexc("#aab4b8"))
    shine = np.clip((fbm(9, seed + 71, 2) * 0.6 + fbm(40, seed + 72, 2) * 0.4 - 0.6) * 7.0, 0, 1) * pool * depth   # 물낯에 비친 희미한 빛
    img = img + shine[..., None] * hexc("#7c8c98") * 0.3
    return _rgba(surf.finish(img, MEAN, 1, 0.14, ref=img0))


@_floor("floor_dirt", "흙바닥", {"a": {"seed": 1}, "b": {"seed": 2}})
def floor_dirt(c, seed=1):
    base = hexc("#51463a")
    img, h = ground.earth(base, seed + 330, 0.26, 1.2)
    rng = np.random.default_rng(seed + 57)
    ly = tex.Layer()
    ground.stones(ly, rng, 60, 1.8, 5.0, hexc("#6a655c"))
    ground.strokes(ly, rng, 30, 8, 16, [base * 0.5], 1.2, 1.5, 1.6, 0.7)
    return _rgba(surf.finish(ly.over(img), "#4a4036", seed))


@_floor("floor_sand", "모래 바닥", {"a": {"seed": 1}})
def floor_sand(c, seed=1):
    base = hexc("#7c6c50")
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    ph = 2 * np.pi * (4 * xx + 11 * yy) / W + (fbm(3, seed + 110, 3) - 0.5) * 8.0
    h = (np.sin(ph) * 0.5 + 0.5) ** 1.5 * 0.4 + fbm(5, seed + 111, 3) * 0.6
    img = base[None, None, :] * (1.0 + (fbm(3, seed + 112, 3) - 0.5) * 0.2)[..., None] * surf.relief(h, 2.0)[..., None]
    img = img * (1.0 + (pnoise(128, seed + 113) - 0.5) * 0.08)[..., None]
    rng = np.random.default_rng(seed + 58)
    ly = tex.Layer()
    ground.stones(ly, rng, 22, 1.8, 4.5, hexc("#6a665e"))
    return _rgba(surf.finish(ly.over(img), "#6c5e46", seed))


@_floor("floor_ritual", "의식용 문양 바닥", {"a": {"seed": 1}})
def floor_ritual(c, seed=1):
    """새김 판석: 2 × 2칸(128px)마다 한 장 — 테두리 홈 + 가운데 둥근 문양(고리 · 여덟 갈래 · 모서리 꺾쇠). 홈에는 검붉은 때."""
    cell, edge, u, v = surf.squares(2, 1.2, seed)
    img, gap, h = surf.stonework(cell, edge, hexc("#625f5a"), GAP, seed + 340, 3.5, 0.06, 1.0, 0.01, 0.5)
    r = np.hypot(u, v)
    ang = np.arctan2(v, u)
    wob = (fbm(30, seed + 2, 2) - 0.5) * 0.02
    groove = lambda d, w: np.clip(1.0 - np.abs(d + wob) / w, 0, 1)
    g = np.maximum.reduce([
        groove(np.maximum(np.abs(u), np.abs(v)) - 0.86, 0.022),                 # 테두리 홈
        groove(r - 0.62, 0.02), groove(r - 0.5, 0.014), groove(r - 0.2, 0.016),  # 고리 셋
        groove(np.abs(np.sin(ang * 4.0)) * r - 0.0, 0.016) * (r > 0.2) * (r < 0.5),          # 여덟 갈래 살
        groove(np.abs((ang * 8 / np.pi) % 1.0 - 0.5) * r * 0.39, 0.018) * (r > 0.5) * (r < 0.62),   # 눈금
        groove(np.minimum(np.abs(np.abs(u) - 0.74), np.abs(np.abs(v) - 0.74)), 0.016) * (np.abs(u) > 0.62) * (np.abs(v) > 0.62),  # 모서리 꺾쇠
    ])
    lit = np.roll(g, (2, 2), (0, 1))
    img = img * (1 - g[..., None] * 0.62) + (np.clip(lit - g, 0, 1) * 0.1)[..., None]
    stain = g * np.clip(fbm(6, seed + 3, 3) * 2.4 - 0.7, 0, 1)
    img = surf.mix(img, stain * 0.6, hexc("#3a1614"))
    worn = np.clip((fbm(8, seed + 4, 3) - 0.5) * 3.0, 0, 1)
    img = img * (1 - worn[..., None] * 0.14)
    return _rgba(surf.finish(img, "#54524e", seed))


@_floor("floor_corrupt", "마법에 오염된 바닥", base="floor_flag", glow="#8a5ad0")
def floor_corrupt(c, seed=1):
    """판석이 검보라로 물들고, 줄눈과 금을 따라 보랏빛 마력이 샌다(빛나는 맥은 색 정리 뒤에 얹는다)."""
    img, gap, h, _, _ = _flag(1)
    img0 = img
    taint = np.clip((fbm(4, seed + 80, 4) - 0.36) * 4.0, 0, 1)
    img = surf.mix(img, taint * 0.72, img * np.array([0.5, 0.36, 0.62], F) + hexc("#150d1c") * 0.35)
    blot = np.clip((fbm(11, seed + 81, 3) - 0.6) * 9.0, 0, 1) * taint
    img = surf.mix(img, blot * 0.85, hexc("#0e0a12"))
    rng = np.random.default_rng(seed + 59)
    ly = tex.Layer()
    surf.crack_lines(ly, rng, 9, 150, np.array([0.05, 0.03, 0.08], F), 2.8, 0.3)
    vein = tex.Layer()
    surf.crack_lines(vein, np.random.default_rng(seed + 59), 9, 150, np.array([1, 1, 1], F), 1.6, 0.3)
    out = surf.finish(ly.over(img), MEAN, 1, 0.08, ref=img0).astype(F) / 255.0
    core = vein.alpha() * taint
    core = np.clip(core + gap * np.clip(taint * 2.4 - 1.3, 0, 1) * 0.7, 0, 1)
    halo = np.clip(tex.blur(core, 6) * 2.4, 0, 1)
    small = lambda a: np.asarray(__import__("PIL.Image", fromlist=["x"]).fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).resize((256, 256), 1)).astype(F) / 255.0
    core, halo = small(core), small(halo)
    out = out + hexc("#6a3ab8")[None, None, :] * halo[..., None] * 0.55 + hexc("#c8a0ff")[None, None, :] * core[..., None] * 0.75
    return _rgba((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8))
