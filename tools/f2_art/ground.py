"""2층 바닥 재질 다시 그리기(사용자 2026-11-11 "2층 이미지가 각지고 타일 같다 — 갈아엎고 다시 그려도 돼", AM64).
칸(64px)마다 같은 바탕이 되풀이되던 아틀라스(한 줄 변형 6칸) 대신, 4 × 4칸을 덮는 이어지는 넓은 그림(256 × 256 — 타일 art.span 4)을
재질마다 한 장 칠한다. 평균 색은 그 타일 data 색(× dim)에 맞춘다(빛은 게임이 곱한다).
  python3 tools/f2_art/ground.py [<재질 이름> …] [--preview <png>]     → assets/floor/<장소>/<재질>.webp
번짐 띠 모양 · 덧그림(올가미 · 금) = tools/f2_art/ground_extra.py. 부품 = tex.py.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import tex  # noqa: E402
from tex import W, Layer, fbm, hexc, pnoise, relief  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# 재질 → (장소, 색을 맞출 타일 id, 평균 색 배율)
MATS = {
    "forestfloor": ("f2g", "f2g_floor", 1.0), "clearing": ("f2g", "f2g_grass", 1.0), "dirtpath": ("f2g", "f2g_path", 1.0),
    "trampled": ("f2g", "f2g_village", 1.0), "pebbles": ("f2g", "f2g_gravel_low", 1.0),
    "dryearth": ("f2d", "f2d_hard", 1.0), "graveearth": ("f2d", "f2d_grass", 1.0), "mudroad": ("f2d", "f2d_mud", 1.0),
    "rubble": ("f2d", "f2d_mound", 1.0), "flagstone": ("f2d", "f2d_bridge", 1.0),
    "hardpan": ("f2r", "f2r_hardpan", 1.0), "dunesand": ("f2r", "f2r_sand", 1.0), "sandflag": ("f2r", "f2r_flag", 1.0),
}


def earth(base, seed, mottle=0.22, rough=1.0, warm=0.08):
    """흙 바탕: 넓은 얼룩 + 따뜻하고 찬 색 번짐 + 빛 받은 결 → (그림, 높이장)."""
    n1, n2, n3 = fbm(6, seed, 3), fbm(11, seed + 5, 3), fbm(28, seed + 9, 3)
    img = base[None, None, :] * (1.0 + (n1 - 0.5) * mottle * 1.3 + (n2 - 0.5) * mottle * 0.8)[..., None]
    img = img * (1.0 + (fbm(4, seed + 3, 2) - 0.5)[..., None] * np.array([warm, 0.0, -warm], np.float32))
    h = n2 * 0.55 + n3 * 0.45
    img = img * relief(h, 2.4 * rough)[..., None]
    return tex.kuwahara(img, 4), h


def stones(ly, rng, n, r0, r1, col, squash=0.75):
    """잔돌(그림자 → 잉크 테 → 몸 → 왼쪽 위 밝은 면)."""
    for _ in range(n):
        x, y, r = rng.random() * W, rng.random() * W, rng.uniform(r0, r1)
        c = col * rng.uniform(0.8, 1.15)
        rot = rng.uniform(0, 3.14)
        ly.blob(x + r * 0.35, y + r * 0.4, r * 1.1, r * squash, tex.SHADOW, 0.45, rot, 9, 0.2, rng)
        ly.blob(x, y, r * 1.12, r * squash * 1.15, tex.SHADOW, 0.8, rot, 9, 0.25, rng)
        ly.blob(x, y, r, r * squash, c, 1.0, rot, 9, 0.25, rng)
        ly.blob(x - r * 0.25, y - r * 0.22, r * 0.5, r * squash * 0.45, np.minimum(c * 1.35, 1.0), 0.8, rot, 7, 0.2, rng)


def strokes(ly, rng, n, l0, l1, cols, lean=0.0, spread=0.6, width=2.0, alpha=0.9, mask=None, curve=0.25):
    """짧은 붓 줄(풀잎 · 짚 · 잔가지): 아래 → 위로, lean ± spread 라디안 기울기. mask(W, W)가 있으면 그 값이 클수록 잘 난다."""
    for _ in range(n):
        x, y = rng.random() * W, rng.random() * W
        if mask is not None and rng.random() > mask[int(y) % W, int(x) % W]:
            continue
        a = lean + rng.uniform(-spread, spread)
        ln = rng.uniform(l0, l1)
        dx, dy = np.sin(a) * ln, -np.cos(a) * ln
        bend = rng.uniform(-curve, curve) * ln
        c = cols[rng.integers(len(cols))] * rng.uniform(0.85, 1.15)
        ly.line([(x, y), (x + dx * 0.5 + bend * 0.5, y + dy * 0.5), (x + dx + bend, y + dy)], np.clip(c, 0, 1), alpha, width)


def leaves(ly, rng, n, cols, r0=4.0, r1=8.0, mask=None):
    """낙엽(어두운 테 + 잎 + 잎맥)."""
    for _ in range(n):
        x, y = rng.random() * W, rng.random() * W
        if mask is not None and rng.random() > mask[int(y), int(x)]:
            continue
        r, rot = rng.uniform(r0, r1), rng.uniform(0, 6.28)
        c = np.clip(cols[rng.integers(len(cols))] * rng.uniform(0.8, 1.2), 0, 1)
        ly.blob(x + 1.5, y + 1.5, r * 1.1, r * 0.55, tex.SHADOW, 0.5, rot, 8, 0.15, rng)
        ly.blob(x, y, r, r * 0.45, c, 1.0, rot, 8, 0.2, rng)
        ly.line([(x - np.cos(rot) * r * 0.8, y - np.sin(rot) * r * 0.8), (x + np.cos(rot) * r * 0.8, y + np.sin(rot) * r * 0.8)], c * 0.55, 0.7, 1.0)


def slabs(seed, n, jitter, base, gap_col, gap_w=3.0, var=0.16, bevel=1.0):
    """돌 조각 바닥(판석 · 자갈 · 갈라진 흙판): 조각마다 밝기가 다르고, 틈은 어둡고, 왼쪽 위 모서리가 밝다 → (그림, 틈 마스크)."""
    cell, d1, edge = tex.voronoi(n, seed, jitter)
    edge = edge + (fbm(40, seed + 2, 2) - 0.5) * gap_w * 1.6  # 틈이 들쭉날쭉
    rng = np.random.default_rng(seed + 1)
    tone = 1.0 + (rng.random(cell.max() + 1).astype(np.float32) - 0.5) * 2 * var
    hue = (rng.random((cell.max() + 1, 3)).astype(np.float32) - 0.5) * 0.022
    img = base[None, None, :] * tone[cell][..., None] + hue[cell]
    img = img * (1.0 + (fbm(12, seed + 4, 3) - 0.5) * 0.22)[..., None]
    h = np.clip(edge / (gap_w * 3.0), 0, 1) ** 0.6 + fbm(30, seed + 6, 2) * 0.25  # 틈으로 갈수록 낮다
    img = img * relief(h, 1.6 * bevel)[..., None]
    gap = np.clip(1.0 - edge / gap_w, 0, 1)
    img = img * (1 - gap[..., None]) + gap_col[None, None, :] * gap[..., None]
    return img, gap


def paint(name, base, seed):
    rng = np.random.default_rng(seed)
    ly = Layer()
    if name == "clearing":  # 빈터 풀밭: 어두운 흙 위에 풀잎이 겹겹 — 밝은 무더기와 어두운 무더기
        img, _ = earth(base * 0.55, seed, 0.25, 0.6)
        patch = np.clip(fbm(5, seed + 20, 3) * 1.6 - 0.25, 0.15, 1.0)
        g = [base * 0.7, base * 0.9, base * 1.1, base * np.array([1.25, 1.2, 0.8], np.float32)]
        strokes(ly, rng, 9000, 8, 16, g[:2], 0.1, 0.7, 3.0, 0.95)
        strokes(ly, rng, 9000, 8, 18, g[1:3], 0.1, 0.6, 2.0, 0.95, patch)
        strokes(ly, rng, 3500, 10, 20, g[2:], 0.15, 0.5, 1.6, 0.9, patch ** 2)
        for _ in range(26):  # 토끼풀 · 잔꽃
            x, y = rng.random() * W, rng.random() * W
            for k in range(3):
                ly.blob(x + np.cos(k * 2.1) * 3, y + np.sin(k * 2.1) * 3, 2.6, 2.6, base * np.array([0.8, 1.15, 0.7], np.float32), 0.9, 0, 7, 0.1, rng)
    elif name == "forestfloor":  # 숲 바닥: 검은 흙 + 이끼 얼룩 + 낙엽 + 잔가지 + 드문 풀
        soil = hexc("#40372a")
        img, _ = earth(soil, seed, 0.3, 1.0)
        moss = np.clip((fbm(11, seed + 30, 3) - 0.42) * 3.0, 0, 1)
        img = img * (1 - moss[..., None] * 0.6) + (hexc("#3c5628") * 0.85)[None, None, :] * (moss * 0.6 * (0.8 + fbm(40, seed + 31, 2) * 0.4))[..., None]
        leaves(ly, rng, 520, [hexc("#6a4a26"), hexc("#7a5c2a"), hexc("#4e4a22"), hexc("#5a3a20")], 4.5, 8.5, 1.0 - moss * 0.6)
        strokes(ly, rng, 60, 14, 30, [hexc("#2a2018"), hexc("#4a3826")], 1.2, 1.5, 2.0, 0.9)  # 잔가지
        strokes(ly, rng, 3200, 7, 14, [hexc("#2e4a22"), hexc("#3a5826"), hexc("#4a6a30")], 0.1, 0.7, 2.0, 0.8, np.clip(moss + 0.12, 0, 1))
    elif name == "dirtpath":  # 오솔길: 다져진 흙 + 바퀴 · 발자국 결 + 잔돌 + 잔가지
        img, _ = earth(base, seed, 0.2, 0.9)
        rut = (fbm(2, seed + 40, 2) * 0.6 + pnoise(3, seed + 41) * 0.4)
        img = img * (0.9 + rut * 0.2)[..., None]
        stones(ly, rng, 70, 2.0, 5.0, base * 1.25)
        strokes(ly, rng, 40, 8, 18, [base * 0.45], 1.3, 1.5, 1.6, 0.8)
        strokes(ly, rng, 260, 5, 10, [hexc("#4a5a2c"), hexc("#5a5a30")], 0.0, 0.6, 1.6, 0.75)
    elif name == "trampled":  # 고블린 마을 진창: 짓밟힌 흙 + 짚 + 물 고인 자국 + 뼛조각
        img, _ = earth(base, seed, 0.3, 1.2)
        wet = np.clip((fbm(7, seed + 50, 3) - 0.56) * 4.0, 0, 1)
        img = img * (1 - wet[..., None] * 0.3)
        strokes(ly, rng, 900, 10, 22, [hexc("#8a7440"), hexc("#a08a4c"), hexc("#6a5630")], 1.57, 1.57, 1.8, 0.85, 1.0 - wet)
        stones(ly, rng, 30, 2.0, 4.5, base * 1.2)
        strokes(ly, rng, 26, 8, 14, [hexc("#c8c0a8")], 1.0, 1.5, 2.6, 0.9)
    elif name == "pebbles":  # 개울가 자갈
        img, gap = slabs(seed, 520, 1.0, base * 1.12, base * 0.4, 3.0, 0.18, 0.9)
    elif name == "dryearth":  # 망자의 땅 굳은 흙: 잿빛 흙 + 마른 풀 + 잔돌
        img, _ = earth(base, seed, 0.2, 1.1, 0.04)
        dry = np.clip(fbm(6, seed + 60, 3) * 1.8 - 0.5, 0.0, 1.0)
        strokes(ly, rng, 1500, 6, 13, [base * 1.3, base * 1.5, hexc("#77705c")], 0.1, 0.7, 1.6, 0.8, dry)
        stones(ly, rng, 55, 2.0, 5.0, base * 1.35)
    elif name == "graveearth":  # 묘지 풀밭: 어두운 흙 + 잿빛 풀 무더기 + 삭은 낙엽
        img, _ = earth(base * 0.8, seed, 0.25, 1.0, 0.04)
        grass = np.clip(fbm(5, seed + 70, 3) * 2.0 - 0.5, 0.05, 1.0)
        g = [base * np.array([0.9, 1.0, 0.85], np.float32), base * np.array([1.15, 1.25, 1.0], np.float32), base * 1.45]
        strokes(ly, rng, 6500, 7, 15, g[:2], 0.1, 0.7, 2.0, 0.9, grass)
        strokes(ly, rng, 1600, 9, 17, g[1:], 0.15, 0.5, 1.5, 0.85, grass ** 2)
        leaves(ly, rng, 90, [hexc("#4a4438"), hexc("#585040")], 4.0, 7.0)
        stones(ly, rng, 18, 2.0, 4.5, base * 1.3)
    elif name == "mudroad":  # 검은 진창: 젖은 흙 + 고인 물 + 은빛 번들거림 + 바퀴 자국
        img, h = earth(base, seed, 0.3, 1.5, 0.03)
        pool = np.clip((fbm(4, seed + 80, 2) - 0.56) * 10.0, 0, 1)
        img = img * (1 - pool[..., None] * 0.5) + hexc("#2a2c30")[None, None, :] * pool[..., None] * 0.5
        sheen = np.clip((relief(h + pool * 0.0, 5.0) - 1.18) * 3.0, 0, 1) * (0.4 + pool * 0.6)
        img = img + hexc("#aab4c0")[None, None, :] * sheen[..., None] * 0.55
        strokes(ly, rng, 14, 30, 60, [base * 0.7], 1.45, 0.2, 4.0, 0.3)
        stones(ly, rng, 20, 2.0, 4.0, base * 1.3)
    elif name == "rubble":  # 돌 둔덕: 크고 작은 돌 + 사이 흙
        img, gap = slabs(seed, 150, 1.0, base * 1.15, base * 0.35, 5.0, 0.2, 1.1)
        stones(ly, rng, 120, 3.0, 8.0, base * 1.25)
    elif name == "flagstone":  # 깨진 판석: 큰 돌판 + 틈의 이끼 + 금
        img, gap = slabs(seed, 40, 0.55, base * 1.08, hexc("#1c1d1e"), 4.0, 0.12, 0.8)
        moss = gap * np.clip(fbm(6, seed + 90, 2) * 2.2 - 0.6, 0, 1)
        img = img * (1 - moss[..., None] * 0.7) + hexc("#4a5238")[None, None, :] * moss[..., None] * 0.7
        for _ in range(22):
            x, y, a = rng.random() * W, rng.random() * W, rng.uniform(0, 6.28)
            pts = [(x, y)]
            for _k in range(4):
                a += rng.uniform(-0.6, 0.6)
                pts.append((pts[-1][0] + np.cos(a) * 12, pts[-1][1] + np.sin(a) * 12))
            ly.line(pts, tex.SHADOW, 0.75, 1.6)
        strokes(ly, rng, 900, 5, 10, [hexc("#5a6048"), hexc("#6a705a")], 0.0, 0.6, 1.5, 0.8, np.clip(gap * 3.0, 0, 1))
    elif name == "hardpan":  # 볕에 갈라진 흙판: 넓은 판 + 가는 금 + 말려 올라간 가장자리
        img, gap = slabs(seed, 64, 0.95, base * 1.03, base * 0.5, 1.7, 0.045, 0.22)
        img = img * (1.0 + (fbm(6, seed + 100, 3) - 0.5) * 0.26)[..., None] * relief(fbm(20, seed + 101, 3), 1.2)[..., None]
        stones(ly, rng, 40, 2.0, 4.5, base * 0.85)
    elif name == "dunesand":  # 모래 바다: 바람 결 물결 + 잔돌
        yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
        ph = 2 * np.pi * (5 * xx + 13 * yy) / W + (fbm(3, seed + 110, 3) - 0.5) * 9.0
        h = np.sin(ph) * 0.5 + 0.5
        h = h ** 1.6 * 0.5 + fbm(5, seed + 111, 2) * 0.5
        img = base[None, None, :] * (1.0 + (fbm(3, seed + 112, 3) - 0.5) * 0.16)[..., None] * relief(h, 2.2)[..., None]
        img = img * (1.0 + (pnoise(128, seed + 113) - 0.5) * 0.06)[..., None]
        stones(ly, rng, 14, 2.0, 4.0, base * 0.7)
    elif name == "sandflag":  # 모래에 반쯤 묻힌 옛 판석
        img, gap = slabs(seed, 64, 0.85, base * 0.92, base * 0.5, 3.0, 0.1, 0.6)
        sand = np.clip((fbm(4, seed + 120, 3) - 0.46) * 6.0 + gap * 0.8, 0, 1)
        img = img * (1 - sand[..., None]) + (base * 1.18)[None, None, :] * (sand * (0.92 + fbm(30, seed + 121, 2) * 0.16))[..., None]
        stones(ly, rng, 24, 2.0, 4.0, base * 0.8)
    else:
        raise SystemExit("모르는 재질: " + name)
    return ly.over(np.clip(img, 0, 1))


def main():
    tiles = {t["id"]: t for t in json.load(open(os.path.join(ROOT, "data", "tiles.json"), encoding="utf-8"))}
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    preview = "--preview" in sys.argv
    if preview:
        args = args[:-1] if len(args) > 1 else []
    names = [a for a in args if a in MATS] or list(MATS)
    for k, name in enumerate(names):
        place, tile, dim = MATS[name]
        target = hexc(tiles[tile]["colors"]["floor"]) * dim
        img = tex.finish(paint(name, target, 100 + list(MATS).index(name) * 13), target, grain_seed=k + 3)
        path = os.path.join(ROOT, "assets", "floor", place, name + ".webp")
        Image.fromarray(img, "RGB").save(path, lossless=True, quality=100)
        print("바닥:", os.path.relpath(path, ROOT))
        if preview:  # 3 × 2로 이어 붙인 판(이음매 · 되풀이 확인)
            Image.fromarray(np.tile(img, (2, 3, 1)), "RGB").save(sys.argv[-1].replace(".png", "_%s.png" % name))


if __name__ == "__main__":
    main()
