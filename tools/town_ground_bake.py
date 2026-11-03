"""동네 바닥을 한 장으로 굽는다(CT99 → CT101 사용자 2026-11-03 "도시랑 건물 텍스처가 부조화 — 바닥 · 배경 텍스처 다시, 조금 더 어둡게,
건물 그림체처럼 세밀하게, 도시에 있을 법한 장식 요소도").
  godot --headless --path . --script res://tools/town_cells.gd   (칸 정보 → user://town_cells.json)
  python3 tools/town_ground_bake.py [--preview]                   (→ assets/town/ground/g<cx>_<cy>.webp + index.json)
칸마다 같은 무늬를 찍지 않는다 — data/town 지도의 곡선 · 다각형을 칸당 32px로 그려 재질을 입힌다. 집 그림(손그림 집 키트)과 같은 그림체로:
  돌마다 먹선(굵기가 흔들리고 가끔 끊긴다) · 왼쪽 위가 밝고 오른쪽 아래가 어두운 돌 · 어두운 곳은 펜 빗금(town_handdrawn.finish) · 줄눈에 흙 · 이끼.
  자갈길 = 크기가 제각각인 둥근 돌 · 큰길 · 시설 앞 · 계단 · 다리 = 엇갈려 깐 네모 판석 · 광장 = 동심원 판석 · 흙마당 = 얼룩 흙 + 잔돌 · 지푸라기 ·
  정원 = 풀 붓질 + 덤불(먹선) + 꽃 · 물 = 어두운 물 + 물결 줄.
  바닥 장식: 집 · 옹벽 밑 그늘과 때 · 벽 밑 잡초 · 큰길 가운데 배수 도랑과 쇠살대 · 하수도 맨홀(입구 자리) · 웅덩이 · 금 · 지푸라기 · 낙엽.
  그다음 단 높이만큼 3/4로 올려(화면 y = 남쪽 깊이 − 높이) 옹벽 · 둑 앞면에 마름돌(먹선 줄눈)을 쌓고, 손그림 마감을 한 뒤 512px 조각으로 자른다.
색은 render.json city.town.colors를 더 어둡게(SHADE) — 집 그림의 어두운 갈색 지붕 · 바랜 회벽과 어울리게.
"""
import json
import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_handdrawn as th  # noqa: E402
from town_hand_bake import user_dir  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "town", "ground")
PX = 32
CHUNK = 512
KINDS = ["void", "street", "avenue", "paving", "plaza", "stairs", "bridge", "yard", "court", "water", "retain", "wall", "gate", "dais", "house", "prop"]
K = {k: i for i, k in enumerate(KINDS)}
STEP = 0.2  # 계단 턱 높이(칸 — 6px 남짓, CT102)
WALK_W = 18  # 집 둘레 판석 보도 폭(px, CT102)

SUN = (0.8, -0.47)  # 높이 1칸당 그림자가 뻗는 쪽(동 · 북 — 집 그림 해가 서남쪽 위)
SHADE = 0.8  # 바닥 전체 밝기(예전 1.1 언저리 → 어둡게, CT101)
MORTAR = np.array([0.15, 0.13, 0.11], np.float32)
MOSS = np.array([0.24, 0.27, 0.16], np.float32)


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def hash2(i, j, seed):
    """정수 격자 → 0~1(같은 자리는 늘 같은 값)."""
    h = (np.asarray(i).astype(np.int64) * 374761393 + np.asarray(j).astype(np.int64) * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF).astype(np.float32) / 65535.0


def voronoi(xs, ys, cell, seed, jitter=0.85):
    """흔들린 격자점 보로노이: (가까운 점까지, 줄눈까지(근사), 돌 번호, 돌 가운데에서 본 x · y)."""
    gx, gy = xs / cell, ys / cell
    ix, iy = np.floor(gx).astype(np.int64), np.floor(gy).astype(np.int64)
    f1 = np.full(xs.shape, 1e9, np.float32)
    f2 = np.full(xs.shape, 1e9, np.float32)
    cid = np.zeros(xs.shape, np.int64)
    ox = np.zeros(xs.shape, np.float32)
    oy = np.zeros(xs.shape, np.float32)
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx, cy = ix + dx, iy + dy
            px = cx + 0.5 + (hash2(cx, cy, seed) - 0.5) * jitter
            py = cy + 0.5 + (hash2(cx, cy, seed + 7) - 0.5) * jitter
            d = np.hypot(gx - px, gy - py).astype(np.float32)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            cid = np.where(closer, cx * 100003 + cy, cid)
            ox = np.where(closer, (gx - px) * cell, ox)
            oy = np.where(closer, (gy - py) * cell, oy)
            f1 = np.where(closer, d, f1)
    return f1 * cell, (f2 - f1) * cell * 0.5, cid, ox, oy


def noise(xs, ys, scale, seed):
    """값 잡음(쌍선형) 0~1."""
    gx, gy = xs / scale, ys / scale
    ix, iy = np.floor(gx).astype(np.int64), np.floor(gy).astype(np.int64)
    fx, fy = gx - ix, gy - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, seed), hash2(ix + 1, iy, seed)
    c, d = hash2(ix, iy + 1, seed), hash2(ix + 1, iy + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fbm(xs, ys, scale, seed, oct=3):
    v, a, t = 0.0, 1.0, 0.0
    for o in range(oct):
        v = v + noise(xs, ys, scale / (2 ** o), seed + o * 31) * a
        t += a
        a *= 0.5
    return v / t


def ink_line(xs, ys, edge, width, seed, strength=0.7):
    """줄눈 · 테두리 먹선: 굵기가 흔들리고(펜 눌림) 가끔 끊긴다."""
    w = width * (0.7 + 0.6 * noise(xs, ys, 9, seed))
    a = np.clip((w - edge) / 0.7, 0, 1)
    gaps = noise(xs, ys, 13, seed + 1) > 0.18
    return a * strength * (0.75 + 0.25 * noise(xs, ys, 5, seed + 2)) * gaps


def stone_fill(xs, ys, base, cid, lit, seed, var):
    """돌 한 장의 색: 돌마다 밝기 · 따뜻함, 왼쪽 위 밝게, 잔 구멍 · 얼룩."""
    tone = 1.0 + (hash2(cid, cid * 7, seed + 3) - 0.5) * 2 * var
    warm = (hash2(cid, cid * 3, seed + 5) - 0.5) * 0.07
    col = base[None, None, :] * tone[..., None]
    col[..., 0] += warm
    col[..., 2] -= warm * 0.8
    col = col * (1.0 + 0.2 * lit)[..., None]
    pits = noise(xs, ys, 2.2, seed + 9) < 0.06
    col[pits] *= 0.84
    stain = fbm(xs, ys, 30, seed + 13, 3)
    col = col * (0.93 + 0.12 * stain)[..., None]  # 얼룩을 덜(도로 잡음 줄이기 — CT103)
    return col


def mortar(xs, ys, seed, moss):
    m = np.broadcast_to(MORTAR, xs.shape + (3,)).copy()
    green = fbm(xs, ys, 26, seed + 17, 2) > 0.8 - moss
    m[green] = MOSS
    return m


def cobbles(xs, ys, base, cell, seed, moss=0.06, var=0.12):
    """자갈길: 크기가 제각각인 둥근 돌 · 먹선 줄눈 · 줄눈에 흙 · 이끼."""
    f1, edge, cid, ox, oy = voronoi(xs, ys, cell, seed)
    r = cell * 0.55
    lit = np.clip(-(ox + oy) * 0.7 / r, -1, 1)
    col = stone_fill(xs, ys, base, cid, lit, seed, var)
    rim = np.clip(1.0 - edge / 2.6, 0, 1) * (lit < 0.2)  # 아래 · 오른쪽 둘레 그늘
    col = col * (1.0 - 0.3 * rim)[..., None]
    gap = 0.7 + 0.5 * noise(xs, ys, 7, seed + 21)
    m = edge < gap
    col[m] = mortar(xs, ys, seed, moss)[m]
    ink = ink_line(xs, ys, edge, 0.8, seed + 30, 0.5)
    return col, ink


def slabs(xs, ys, base, rh, lmin, lmax, seed, var=0.12, moss=0.1):
    """판석: 엇갈려 깐 네모 돌(줄마다 길이가 다르다) — 귀퉁이가 조금 닳고 금이 간다."""
    row = np.floor(ys / rh).astype(np.int64)
    L = lmin + hash2(row, row * 3, seed + 1) * (lmax - lmin)
    off = hash2(row, row, seed) * L
    u = (xs + off) / L
    ci = np.floor(u).astype(np.int64)
    cid = row * 100003 + ci
    fu, fv = u - ci, ys / rh - row
    jit = (noise(xs, ys, 6, seed + 4) - 0.5) * 1.4
    edge = np.minimum(np.minimum(fu, 1 - fu) * L, np.minimum(fv, 1 - fv) * rh) + jit
    lit = np.clip(-((fu - 0.5) * 1.2 + (fv - 0.5) * 1.2), -1, 1)
    col = stone_fill(xs, ys, base, cid, lit * 0.6, seed, var)
    rim = np.clip(1.0 - edge / 2.4, 0, 1) * ((fu > 0.5) | (fv > 0.5))
    col = col * (1.0 - 0.28 * rim)[..., None]
    m = edge < 0.7
    col[m] = mortar(xs, ys, seed, moss)[m]
    ink = ink_line(xs, ys, edge, 0.85, seed + 30, 0.48)
    return col, ink


def plaza_stones(xs, ys, cx, cy, base):
    """광장: 가운데를 둘러 동심원으로 깐 판석(먹선 줄눈)."""
    r = np.hypot(xs - cx, ys - cy)
    ring = np.floor(r / 22.0)
    a = np.arctan2(ys - cy, xs - cx)
    n = np.maximum(6, np.floor(2 * np.pi * (ring + 0.5) * 22.0 / 30.0))
    t = (a + np.pi + ring * 0.37) / (2 * np.pi) * n
    seg = np.floor(t)
    cid = (ring * 1000 + seg).astype(np.int64)
    er = np.minimum(r - ring * 22.0, (ring + 1) * 22.0 - r)
    ea = (0.5 - np.abs(t - seg - 0.5)) * 2 * np.pi * np.maximum(r, 1) / n
    e = np.minimum(er, ea) + (noise(xs, ys, 6, 44) - 0.5) * 1.2
    lit = np.clip(-((xs - cx) + (ys - cy)) / np.maximum(r, 1) * 0.3, -1, 1)
    col = stone_fill(xs, ys, base, cid, lit, 41, 0.13)
    band = (ring % 5 == 4)  # 다섯 줄마다 짙은 돌 띠
    col[band] *= 0.8
    m = e < 0.7
    col[m] = mortar(xs, ys, 41, 0.05)[m]
    return col, ink_line(xs, ys, e, 0.85, 45, 0.48)


def dirt(xs, ys, base, seed):
    """흙마당: 얼룩 흙 · 다져진 길 · 먹선 잔돌 · 지푸라기 · 마른 풀."""
    v = fbm(xs, ys, 40, seed, 4)
    col = base[None, None, :] * (0.78 + 0.4 * v[..., None])
    damp = fbm(xs, ys, 70, seed + 2, 3) > 0.62
    col[damp] *= 0.8
    f1, _e, cid, ox, oy = voronoi(xs, ys, 9, seed + 3, 0.9)
    peb = (f1 < 1.8) & (hash2(cid, cid, seed + 5) < 0.4)
    col[peb] = col[peb] * 1.18 + 0.02
    ink = np.where((f1 > 1.4) & (f1 < 2.3) & (hash2(cid, cid, seed + 5) < 0.4) & (oy > -0.3), 0.55, 0.0)
    # 지푸라기 · 잔가지: 짧은 비스듬한 획
    _f, _e2, sid, sx, sy = voronoi(xs, ys, 11, seed + 7, 0.9)
    ang = hash2(sid, sid, seed + 8) * np.pi
    along = sx * np.cos(ang) + sy * np.sin(ang)
    across = -sx * np.sin(ang) + sy * np.cos(ang)
    straw = (np.abs(across) < 0.6) & (np.abs(along) < 3.5) & (hash2(sid, sid, seed + 9) < 0.35)
    col[straw] = np.array([0.62, 0.53, 0.33], np.float32) * SHADE
    grass = fbm(xs, ys, 18, seed + 9, 3) > 0.68
    col[grass] = col[grass] * np.array([0.82, 0.95, 0.7], np.float32)
    return col, ink


def garden(xs, ys, base, seed):
    """정원(안뜰): 풀 붓질 + 덤불(먹선 · 왼쪽 위 밝게) + 꽃."""
    v = fbm(xs, ys, 22, seed, 4)
    col = base[None, None, :] * (0.75 + 0.4 * v[..., None])
    _f, _e, sid, sx, sy = voronoi(xs, ys, 4.5, seed + 1, 0.95)
    blade = (np.abs(sx + sy * 0.25) < 0.55) & (sy < 0.2) & (sy > -2.6)  # 위로 선 풀잎 획
    tone = hash2(sid, sid, seed + 2)
    col[blade & (tone < 0.5)] *= 0.72
    col[blade & (tone >= 0.5)] *= 1.18
    f1, edge, cid, ox, oy = voronoi(xs, ys, 24, seed + 3, 0.8)
    rad = 7.0 + hash2(cid, cid, seed + 6) * 4.0
    bush = (f1 < rad) & (hash2(cid, cid, seed + 5) < 0.55)
    lit = np.clip(-(ox + oy) * 0.7 / rad, -1, 1)
    leaf = noise(xs, ys, 2.5, seed + 7)
    bc = np.array([0.2, 0.25, 0.14], np.float32)[None, None, :] * (1.0 + 0.45 * lit[..., None]) * (0.85 + 0.3 * leaf[..., None])
    col[bush] = bc[bush]
    flower = bush & (leaf > 0.86) & (hash2(cid, cid, seed + 8) < 0.4)
    fc = np.where((hash2(cid, cid, seed + 10) < 0.5)[..., None], np.array([0.62, 0.36, 0.3], np.float32), np.array([0.7, 0.64, 0.42], np.float32))
    col[flower] = fc[flower]
    ink = np.where(bush, 0.0, ink_line(xs, ys, np.abs(f1 - rad), 1.0, seed + 30, 0.7) * (hash2(cid, cid, seed + 5) < 0.55))
    return col, ink


def water(xs, ys, base):
    v = fbm(xs * 0.4, ys * 1.6, 14, 51, 3)
    col = base[None, None, :] * (0.78 + 0.3 * v[..., None])
    wave = np.sin(xs * 0.09 + fbm(xs, ys, 30, 53, 2) * 7 + ys * 0.02)
    hi = (wave > 0.96) & (noise(xs, ys, 11, 55) > 0.55)
    col[hi] = col[hi] * 1.3 + 0.02
    ink = np.where((wave < -0.96) & (noise(xs, ys, 11, 57) > 0.45), 0.35, 0.0)
    return col, ink


def diag(xs, ys, base, size, seed):
    """광장 · 시장: 45° 돌린 네모 판석(길과 다른 포장 — CT103)."""
    u = (xs + ys) * 0.7071
    v = (xs - ys) * 0.7071
    iu, iv = np.floor(u / size), np.floor(v / size)
    cid = (iu * 100003 + iv).astype(np.int64)
    fu, fv = u / size - iu, v / size - iv
    edge = np.minimum(np.minimum(fu, 1 - fu), np.minimum(fv, 1 - fv)) * size + (noise(xs, ys, 7, seed) - 0.5) * 0.8
    lit = np.clip(-((fu - 0.5) + (fv - 0.5)) * 0.8, -1, 1)
    col = stone_fill(xs, ys, base, cid, lit * 0.4, seed, 0.08)
    m = edge < 0.8
    col[m] = MORTAR * 1.3
    return col, ink_line(xs, ys, edge, 0.8, seed + 30, 0.4)


def planks(xs, ys, base, seed):
    """나무 부두: 가로로 깐 널(엇갈린 이음 · 못 자국 · 먹선)."""
    rh = 7.0
    row = np.floor(ys / rh).astype(np.int64)
    L = 40.0 + hash2(row, row, seed) * 30.0
    off = hash2(row, row * 3, seed + 1) * L
    u = (xs + off) / L
    ci = np.floor(u).astype(np.int64)
    tone = 1.0 + (hash2(row, ci, seed + 2) - 0.5) * 0.22
    grain = (noise(xs * 0.2, ys * 2.0, 6, seed + 3) - 0.5) * 0.18
    col = base[None, None, :] * (tone + grain)[..., None]
    fv = ys / rh - row
    edge = np.minimum(np.minimum(fv, 1 - fv) * rh, np.minimum(u - ci, 1 - (u - ci)) * L)
    nail = (np.abs((u - ci) * L - 3.0) < 0.9) & (np.abs(fv - 0.5) < 0.18)
    col[nail] *= 0.55
    return col, ink_line(xs, ys, edge, 0.9, seed + 30, 0.55)


# ---------- 집 밑(장난감처럼 얹힌 느낌을 없앤다 — CT102) ----------

def footprints(town):
    """집 · 시설 바닥 다각형(칸)과 높이(칸 — 층 × 1.2 + 지붕)."""
    out = []
    for h in town["houses"]:
        (cx, cy), (w, d), a = h["center"], h["size"], math.radians(h["angle"])
        ax, ay = (math.cos(a), math.sin(a)), (-math.sin(a), math.cos(a))
        poly = [(cx + ax[0] * w * sx / 2 + ay[0] * d * sy / 2, cy + ax[1] * w * sx / 2 + ay[1] * d * sy / 2) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        out.append((poly, h.get("floors", 2) * 1.2 + 1.6))
    for b in town["buildings"]:
        if "rect" in b:
            x0, y0, x1, y1 = b["rect"]
            poly = [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]
        else:
            cx, cy, r = b["circle"]
            poly = [(cx + math.cos(t) * r, cy + math.sin(t) * r) for t in np.linspace(0, 2 * math.pi, 25)[:-1]]
        out.append((poly, b.get("floors", 3) * 1.2 + 2.2))
    return out


def _hull(pts):
    pts = sorted(set(pts))
    if len(pts) < 3:
        return pts
    def half(seq):
        h = []
        for p in seq:
            while len(h) >= 2 and (h[-1][0] - h[-2][0]) * (p[1] - h[-2][1]) - (h[-1][1] - h[-2][1]) * (p[0] - h[-2][0]) <= 0:
                h.pop()
            h.append(p)
        return h
    lo, up = half(pts), half(reversed(pts))
    return lo[:-1] + up[:-1]


def _grow_mask(m, n):
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:] |= out[:-1]
        g[:-1] |= out[1:]
        g[:, 1:] |= out[:, :-1]
        g[:, :-1] |= out[:, 1:]
        out = g
    return out


def footing(town, kind, col, ink, W, H):
    """집 · 시설 둘레 판석 보도(연석 먹선 · 그 바깥 도랑 그늘) · 벽 밑 젖은 그늘 · 해 반대쪽(동 · 북)으로 드리운 그림자."""
    fp = footprints(town)
    hm = Image.new("L", (W, H), 0)
    sh = Image.new("L", (W, H), 0)
    dh, ds = ImageDraw.Draw(hm), ImageDraw.Draw(sh)
    for poly, top in fp:
        q = [(x * PX, y * PX) for x, y in poly]
        dh.polygon(q, fill=255)
        v = (SUN[0] * top * PX, SUN[1] * top * PX)
        ds.polygon(_hull(q + [(x + v[0], y + v[1]) for x, y in q]), fill=255)
    house = np.asarray(hm) > 0
    road = np.isin(kind, [K["street"], K["avenue"]])
    # 보도: 집에서 WALK_W px 안의 돌길 → 줄지어 깐 밝은 판석
    walk = _grow_mask(house, WALK_W) & ~house & road
    ys, xs = np.nonzero(walk)
    if len(ys):
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        yy, xx = np.mgrid[y0:y1, x0:x1].astype(np.float32)
        c, k = slabs(xx, yy, hexc("#6e675a") * SHADE * 1.12, 14.0, 18.0, 30.0, 77, var=0.1, moss=0.05)
        m = walk[y0:y1, x0:x1]
        col[y0:y1, x0:x1][m] = c[m]
        ink[y0:y1, x0:x1][m] = k[m]
    # 연석: 보도 바깥 가장자리 먹선 + 그 바깥 2px 도랑 그늘
    rim = _grow_mask(walk, 1) & ~walk & road
    ink[rim] = np.maximum(ink[rim], 0.7)
    gutter = _grow_mask(walk, 4) & ~walk & road
    col[gutter] *= 0.72
    # 벽 밑 젖은 그늘(6px)
    near = _grow_mask(house, 6) & ~house
    col[near] *= 0.62
    near2 = _grow_mask(house, 2) & ~house
    ink[near2] = np.maximum(ink[near2], 0.55)
    # 드리운 그림자(살짝 흐리게 — 손그림 빗금이 어두운 곳에 들어간다)
    shade = np.asarray(sh.filter(ImageFilter.GaussianBlur(3))).astype(np.float32) / 255.0
    shade = shade * ~house * (kind != K["water"])
    col *= (1.0 - 0.42 * shade)[..., None]


# ---------- 바닥 장식(위에서 본 그림 위에 그린다) ----------

def decorate(town, kind, cell_kind, col, ink, W, H):
    """집 · 옹벽 밑 그늘 · 벽 밑 잡초 · 배수 도랑 · 쇠살대 · 맨홀 · 웅덩이 · 금 · 낙엽(CT101)."""
    rnd = random.Random(101)
    hard = np.isin(kind, [K["street"], K["avenue"], K["paving"], K["plaza"], K["bridge"], K["stairs"]])
    ground = np.isin(kind, [K["street"], K["avenue"], K["paving"], K["plaza"], K["bridge"], K["yard"], K["court"]])
    # 1) 집 · 옹벽 밑 그늘과 때(벽에 가까울수록 어둡고, 남쪽보다 북쪽(집 앞 그늘)을 더)
    solid = np.isin(cell_kind, [K["house"], K["retain"]]).astype(np.uint8) * 255
    near = np.asarray(Image.fromarray(solid).filter(ImageFilter.GaussianBlur(10))).astype(np.float32) / 255.0
    grime = np.clip(near * 1.6, 0, 1) * (cell_kind != K["house"])
    col *= (1.0 - 0.32 * grime)[..., None]
    # 2) 벽 밑 잡초 · 이끼 덤불(벽에서 0~8px)
    ring = (np.asarray(Image.fromarray(solid).filter(ImageFilter.MaxFilter(13))) > 0) & (solid == 0) & ground
    ys, xs = np.nonzero(ring)
    sel = np.random.default_rng(3).random(len(ys)) < 0.012
    weeds = Image.new("L", (W, H), 0)
    wd = ImageDraw.Draw(weeds)
    for y, x in zip(ys[sel], xs[sel]):
        for k in range(rnd.randint(3, 6)):
            a = rnd.uniform(-2.4, -0.7)
            L = rnd.uniform(3, 7)
            wd.line([(x, y), (x + math.cos(a) * L, y + math.sin(a) * L)], fill=255, width=1)
    wm = np.asarray(weeds) > 0
    col[wm] = MOSS * 1.2
    ink[wm] = np.maximum(ink[wm], 0.25)
    dec = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    dd = ImageDraw.Draw(dec)
    il = Image.new("L", (W, H), 0)
    idr = ImageDraw.Draw(il)

    def P(q):
        return (q[0] * PX, q[1] * PX)

    # 3) 큰길 가운데 배수 도랑(작은 네모 돌 두 줄) + 쇠살대
    for a in town["areas"]:
        if a["kind"] != "avenue" or "line" not in a:
            continue
        pts = [P(q) for q in a["line"]]
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            L = math.hypot(bx - ax, by - ay)
            ux, uy = (bx - ax) / L, (by - ay) / L
            nx, ny = -uy, ux
            s = 0.0
            while s < L:
                cx, cy = ax + ux * s, ay + uy * s
                for side in (-1, 1):
                    q = [(cx + nx * side * 1 + ux * 0, cy + ny * side * 1), (cx + nx * side * 6, cy + ny * side * 6),
                         (cx + nx * side * 6 + ux * 7, cy + ny * side * 6 + uy * 7), (cx + nx * side * 1 + ux * 7, cy + ny * side * 1 + uy * 7)]
                    t = rnd.randint(70, 92)
                    dd.polygon(q, fill=(t, t - 6, t - 12, 255))
                    idr.polygon(q, outline=150)
                dd.line([(cx, cy), (cx + ux * 8, cy + uy * 8)], fill=(34, 30, 26, 255), width=2)
                s += 8.0
            s = 3 * PX
            while s < L - PX:
                cx, cy = ax + ux * s, ay + uy * s
                g = [(cx + nx * 7 - ux * 9, cy + ny * 7 - uy * 9), (cx + nx * 7 + ux * 9, cy + ny * 7 + uy * 9),
                     (cx - nx * 7 + ux * 9, cy - ny * 7 + uy * 9), (cx - nx * 7 - ux * 9, cy - ny * 7 - uy * 9)]
                dd.polygon(g, fill=(40, 36, 32, 255))
                for k in range(-6, 7, 3):
                    dd.line([(cx + nx * 6 + ux * k, cy + ny * 6 + uy * k), (cx - nx * 6 + ux * k, cy - ny * 6 + uy * k)], fill=(78, 72, 64, 255), width=1)
                idr.polygon(g, outline=230)
                s += 6 * PX
    # 4) 하수도 맨홀(입구 자리 — 걷는 돌길 위만)
    for x, y in town.get("sewer", {}).get("entrances", []):
        cx, cy = x * PX, y * PX
        if not (0 <= int(cy) < H and 0 <= int(cx) < W and hard[int(cy), int(cx)]):
            continue
        R = 13
        dd.ellipse([cx - R, cy - R, cx + R, cy + R], fill=(52, 46, 40, 255))
        dd.ellipse([cx - R + 3, cy - R + 3, cx + R - 3, cy + R - 3], fill=(66, 58, 50, 255))
        for k in range(-8, 9, 4):
            dd.line([(cx - 9, cy + k), (cx + 9, cy + k)], fill=(44, 38, 34, 255), width=1)
            dd.line([(cx + k, cy - 9), (cx + k, cy + 9)], fill=(44, 38, 34, 255), width=1)
        dd.arc([cx - R + 2, cy - R + 2, cx + R - 2, cy + R - 2], 200, 330, fill=(110, 96, 80, 255), width=1)
        idr.ellipse([cx - R, cy - R, cx + R, cy + R], outline=240, width=2)
        idr.ellipse([cx - R + 3, cy - R + 3, cx + R - 3, cy + R - 3], outline=170)
    # 5) 웅덩이 · 금 · 낙엽 · 지푸라기(걷는 돌길 위에 흩는다)
    hy, hx = np.nonzero(hard[::8, ::8])
    order = np.random.default_rng(11).permutation(len(hy))
    n_pud, n_crack, n_leaf = 0, 0, 0
    for k in order:
        y, x = int(hy[k]) * 8, int(hx[k]) * 8
        roll = rnd.random()
        if roll < 0.006 and n_pud < 26:
            rx, ry = rnd.uniform(10, 22), rnd.uniform(5, 10)
            blob = [(x + math.cos(t) * rx * rnd.uniform(0.75, 1.1), y + math.sin(t) * ry * rnd.uniform(0.75, 1.1)) for t in np.linspace(0, 2 * math.pi, 14)[:-1]]
            dd.polygon(blob, fill=(46, 52, 56, 200))
            dd.line([(x - rx * 0.5, y - ry * 0.3), (x + rx * 0.1, y - ry * 0.45)], fill=(120, 126, 124, 220), width=1)
            idr.polygon(blob, outline=120)
            n_pud += 1
        elif roll < 0.02 and n_crack < 120:
            px_, py_ = float(x), float(y)
            a = rnd.uniform(0, 2 * math.pi)
            seg = [(px_, py_)]
            for _ in range(rnd.randint(3, 6)):
                a += rnd.uniform(-0.9, 0.9)
                px_ += math.cos(a) * rnd.uniform(4, 9)
                py_ += math.sin(a) * rnd.uniform(4, 9)
                seg.append((px_, py_))
            idr.line(seg, fill=190, width=1)
            n_crack += 1
        elif roll < 0.06 and n_leaf < 700:
            for _ in range(rnd.randint(1, 4)):
                lx, ly = x + rnd.uniform(-10, 10), y + rnd.uniform(-10, 10)
                if rnd.random() < 0.5:  # 낙엽
                    c = rnd.choice([(118, 78, 40), (96, 70, 36), (130, 96, 46)])
                    dd.ellipse([lx - 2.2, ly - 1.4, lx + 2.2, ly + 1.4], fill=c + (255,))
                    idr.point((lx + 2, ly + 1), fill=140)
                else:  # 지푸라기
                    a = rnd.uniform(0, math.pi)
                    dd.line([(lx, ly), (lx + math.cos(a) * 5, ly + math.sin(a) * 5)], fill=(150, 128, 78, 255), width=1)
            n_leaf += 1
    da = np.asarray(dec).astype(np.float32) / 255.0
    a = da[..., 3:4] * ground[..., None]
    col[:] = col * (1 - a) + da[..., :3] * a
    ink[:] = np.maximum(ink, np.asarray(il).astype(np.float32) / 255.0 * 0.7 * ground)


def road(xs, ys, kk, main, h, C):
    """돌길: 큰길 = 줄지어 깐 반듯한 돌(밝고 일정 — 윗단 행정 구역은 큰 마름돌), 골목 = 작은 자갈(어둡게)."""
    alley = cobbles(xs, ys, C("street", 1.0), 11.0, 3)
    setts = slabs(xs, ys, C("avenue", 1.18), 15.0, 20.0, 32.0, 31, var=0.07, moss=0.03)
    civic = slabs(xs, ys, C("paving", 1.22), 20.0, 30.0, 44.0, 37, var=0.07, moss=0.02)
    hi = (h > 1.0)
    col = np.where(main[..., None], np.where(hi[..., None], civic[0], setts[0]), alley[0])
    ink = np.where(main, np.where(hi, civic[1], setts[1]), alley[1])
    return col, ink


def entries(kind, diag_m, col, ink):
    """광장 · 시장 진입부: 길이 포장으로 들어오는 곳에 짙은 화강암 띠(먹선 둘) — 들머리가 또렷하게(CT103)."""
    road_m = np.isin(kind, [K["street"], K["avenue"]])
    band = diag_m & _grow_mask(road_m, 12)
    col[band] = col[band] * 0.62 + np.array([0.04, 0.035, 0.03], np.float32)
    edge = band & ~_grow_mask(~band, 1)
    edge |= band & _grow_mask(road_m, 1)
    ink[edge] = np.maximum(ink[edge], 0.6)


def lamp_light(town, col, W, H):
    """가로등 · 벽 등불 밑 따뜻한 빛 웅덩이(창 · 등불의 따뜻한 빛 강조 — CT103)."""
    pts = []
    for p in town["props"]:
        if p["kind"] not in ("lamp", "walllamp"):
            continue
        if "rect" in p:
            x0, y0, x1, y1 = p["rect"]
            pts.append(((x0 + x1) / 2 * PX, y1 * PX - 6))
        elif "ring" in p:
            cx, cy, r, n = p["ring"]
            for i in range(int(n)):
                a = 2 * math.pi * (i + 0.5) / n
                pts.append(((math.floor(cx + math.cos(a) * r) + 0.5) * PX, (math.floor(cy + math.sin(a) * r) + 1) * PX - 6))
    glow = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(glow)
    for x, y in pts:
        for rr, v in ((70, 40), (48, 80), (28, 130)):
            gd.ellipse([x - rr, y - rr * 0.8, x + rr, y + rr * 0.8], fill=v)
    g = np.asarray(glow.filter(ImageFilter.GaussianBlur(14))).astype(np.float32) / 255.0
    col += (g[..., None] * np.array([0.16, 0.1, 0.02], np.float32)) * (col.sum(-1, keepdims=True) > 0)


def main():
    town = json.load(open(os.path.join(ROOT, "data", "town", "district7.json"), encoding="utf-8"))
    cells = json.load(open(os.path.join(user_dir(), "town_cells.json")))
    render = json.load(open(os.path.join(ROOT, "data", "render.json"), encoding="utf-8"))
    colors = render["city"]["town"]["colors"]
    cw, ch = cells["width"], cells["height"]
    W, H = cw * PX, ch * PX
    # 1) 종류(지도 영역을 순서대로 — 곡선 그대로)
    kim = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(kim)

    def P(q):
        return (q[0] * PX, q[1] * PX)

    for a in town["areas"]:
        k = K.get(a["kind"], K["street"])
        if "poly" in a:
            d.polygon([P(q) for q in a["poly"]], fill=k)
        elif "line" in a:
            pts = [P(q) for q in a["line"]]
            w = a["width"] * PX
            d.line(pts, fill=k, width=int(w))
            for x, y in pts:
                d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=k)
        elif "circle" in a:
            cx, cy, r = a["circle"]
            d.ellipse([(cx - r) * PX, (cy - r) * PX, (cx + r) * PX, (cy + r) * PX], fill=k)
        elif "rect" in a:
            x0, y0, x1, y1 = a["rect"]
            d.rectangle([x0 * PX, y0 * PX, x1 * PX - 1, y1 * PX - 1], fill=k)
    kind = np.array(kim)
    ck = np.array([K.get(s, 0) for s in cells["kinds"]], np.uint8).reshape(ch, cw)
    cell_kind = np.repeat(np.repeat(ck, PX, 0), PX, 1)
    # 정원 · 계단은 칸 정보대로(정원은 가장자리를 흐리게 섞는다), 집 밑은 둘레 땅 그대로
    court = Image.fromarray(((cell_kind == K["court"]) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    court = np.array(court) > 140
    kind[court & (kind != K["void"])] = K["court"]
    kind[cell_kind == K["stairs"]] = K["stairs"]
    # 포장 무늬 · 나무 부두 · 큰길과 골목(CT103): 광장 · 시장은 비스듬한 판석, 부두는 널, 블록 사이 길은 폭 2.5칸 넘으면 큰길(반듯한 돌) · 좁으면 골목(자갈)
    pim = Image.new("L", (W, H), 0)
    pd = ImageDraw.Draw(pim)
    for a in town["areas"]:
        if "poly" in a and (a.get("pattern") == "diag" or a.get("wood")):
            pd.polygon([P(q) for q in a["poly"]], fill=1 if a.get("wood") else 2)
    mim = Image.new("L", (W, H), 0)
    md = ImageDraw.Draw(mim)
    for a in town["areas"]:
        if a.get("main") and "line" in a:
            md.line([P(q) for q in a["line"]], fill=1, width=int(a["width"] * PX))
    pat = np.asarray(pim)
    wood_m = (pat == 1) & (kind == K["bridge"])
    diag_m = (pat == 2) & np.isin(kind, [K["paving"]])
    main_m = (np.asarray(mim) > 0) & (kind == K["street"])
    # 2) 높이: 단 경계선(곡선) · 계단 · 물(칸 정보)
    xs1 = (np.arange(W) + 0.5) / PX
    hmap = np.full((H, W), float(town["bands"][-1]["h"]), np.float32)
    ys1 = (np.arange(H)[:, None] + 0.5) / PX
    for b in reversed(town["bands"][:-1]):
        line = np.array(b["line"], np.float32)
        zb = np.interp(xs1, line[:, 0], line[:, 1])
        hmap[ys1 < zb[None, :]] = b["h"]
    chs = np.array(cells["heights"], np.float32).reshape(ch, cw)
    # 계단: 칸 가운데 높이를 세로로 이어 잘게(STEP칸 턱) — 칸마다 큰 턱 하나가 아니게(CT102)
    cy = (np.arange(H) + 0.5) / PX - 0.5
    c0 = np.clip(np.floor(cy).astype(np.int64), 0, ch - 1)
    c1 = np.clip(c0 + 1, 0, ch - 1)
    f = (cy - np.floor(cy)).astype(np.float32)[:, None]
    hv = np.repeat(chs[c0] * (1 - f) + chs[c1] * f, PX, 1)
    st = kind == K["stairs"]
    hmap[st] = np.floor(hv[st] / STEP + 0.5) * STEP
    for a in town["areas"]:
        if "h" in a:
            hmap[kind == K[a["kind"]]] = a["h"]
    # 3) 재질(위에서 본 그림) + 먹선
    col = np.zeros((H, W, 3), np.float32)
    ink = np.zeros((H, W), np.float32)
    plaza_c = None
    for a in town["areas"]:
        if a["kind"] == "plaza":
            plaza_c = (a["circle"][0] * PX, a["circle"][1] * PX)

    def C(name, k=1.0):
        return hexc(colors[name]) * SHADE * k

    for y0 in range(0, H, CHUNK):
        for x0 in range(0, W, CHUNK):
            y1, x1 = min(H, y0 + CHUNK), min(W, x0 + CHUNK)
            ys, xs = np.mgrid[y0:y1, x0:x1].astype(np.float32)
            kk = kind[y0:y1, x0:x1]
            out = np.zeros((y1 - y0, x1 - x0, 3), np.float32)
            oink = np.zeros((y1 - y0, x1 - x0), np.float32)
            todo = {
                "street": lambda: road(xs, ys, kk, main_m[y0:y1, x0:x1], hmap[y0:y1, x0:x1], C),
                "avenue": lambda: slabs(xs, ys, C("avenue", 1.06), 22.0, 30.0, 52.0, 5),
                "paving": lambda: slabs(xs, ys, C("paving", 1.06), 24.0, 26.0, 46.0, 7),
                "bridge": lambda: slabs(xs, ys, C("bridge", 1.08), 18.0, 34.0, 50.0, 9),
                "stairs": lambda: slabs(xs, ys, C("stairs", 1.08), 16.0, 30.0, 46.0, 13),
                "retain": lambda: slabs(xs, ys, C("retain", 1.1), 14.0, 26.0, 36.0, 15),
                "plaza": lambda: plaza_stones(xs, ys, plaza_c[0], plaza_c[1], C("plaza", 1.06)) if plaza_c else None,
                "dais": lambda: plaza_stones(xs, ys, plaza_c[0], plaza_c[1], C("plaza", 1.06)) if plaza_c else None,
                "yard": lambda: dirt(xs, ys, C("yard", 1.06), 17),
                "court": lambda: garden(xs, ys, C("court", 1.12), 19),
                "water": lambda: water(xs, ys, C("water", 1.1)),
            }
            for name, fn in todo.items():
                m = kk == K[name]
                if m.any():
                    r = fn()
                    if r is not None:
                        out[m] = r[0][m]
                        oink[m] = r[1][m]
            dm = diag_m[y0:y1, x0:x1]
            if dm.any():
                c, k2 = diag(xs, ys, C("plaza", 1.0), 26.0, 23)
                out[dm] = c[dm]
                oink[dm] = k2[dm]
            wm = wood_m[y0:y1, x0:x1]
            if wm.any():
                c, k2 = planks(xs, ys, hexc("#5e4632") * SHADE * 1.1, 29)
                out[wm] = c[wm]
                oink[wm] = k2[wm]
            rest = (kk != K["void"]) & (out.sum(-1) == 0)  # 집 밑 · 소품 칸 등 남은 곳 = 흙
            if rest.any():
                out[rest] = dirt(xs, ys, C("yard", 1.06), 17)[0][rest]
            col[y0:y1, x0:x1] = out
            ink[y0:y1, x0:x1] = oink
    # 길 가장자리 연석(돌길과 흙 · 정원이 만나는 곳: 어두운 돌 한 줄 + 먹선)
    hard = np.isin(kind, [K["street"], K["avenue"], K["paving"], K["plaza"], K["bridge"]])
    soft = np.isin(kind, [K["yard"], K["court"]])
    near = np.zeros_like(hard)
    for sh in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (0, 2), (-2, 0), (0, -2), (3, 0), (0, 3), (-3, 0), (0, -3)):
        near |= np.roll(np.roll(soft, sh[0], 0), sh[1], 1)
    curb = hard & near
    col[curb] = col[curb] * 0.7
    ink[curb & ~np.roll(near, 1, 0)] = 0.6
    entries(kind, diag_m, col, ink)
    footing(town, kind, col, ink, W, H)
    lamp_light(town, col, W, H)
    decorate(town, kind, cell_kind, col, ink, W, H)
    # 4) 3/4로 올린다(남쪽부터 북쪽으로 — 높은 땅이 앞의 낮은 땅 위로, 높이 차는 앞면)
    top = int(math.ceil(float(cells["max_h"]) * PX)) + 4
    SH = H + top
    scr = np.zeros((SH, W, 3), np.float32)
    sink = np.zeros((SH, W), np.float32)
    code = np.zeros((SH, W), np.int64)
    ylim = np.full(W, SH, np.int64)
    prev_h = hmap[H - 1].copy()
    cols_i = np.arange(W)
    face_stone = hexc(colors["retain"]) * SHADE * 1.05
    for i in range(H - 1, -1, -1):
        h = hmap[i]
        k = kind[i]
        sy = (i + top - np.round(h * PX)).astype(np.int64)
        vis = (sy < ylim) & (k != K["void"])
        if vis.any():
            span = np.where(vis, ylim - sy, 0)
            wall = vis & (h - prev_h > 0.05) & (span > 1)
            ys_ = sy[vis]
            scr[ys_, cols_i[vis]] = col[i, vis]
            sink[ys_, cols_i[vis]] = ink[i, vis]
            code[ys_, cols_i[vis]] = k[vis] + 1
            # 앞면(옹벽 · 계단 단 · 둑): 마름돌 — 화면 좌표로 줄눈(먹선), 돌마다 밝기 · 위가 밝고 아래가 어둡다
            mx = int(span[wall].max()) if wall.any() else 0
            for dd in range(1, mx):
                m = wall & (span > dd)
                yy = sy[m] + dd
                xx = cols_i[m]
                row = yy // 11
                bx = (xx + (row % 2) * 13) // 26
                joint = ((xx + (row % 2) * 13) % 26 < 1) | (yy % 11 == 0)
                tone = 1.0 + (hash2(row, bx, 61) - 0.5) * 0.26
                c = face_stone[None, :] * (tone * (0.95 - 0.35 * (dd / max(mx, 1))))[:, None]
                c[(yy % 11) == 1] *= 1.12  # 돌 윗변 빛
                stair = k[m] == K["stairs"]
                c[stair] = c[stair] * 0.8
                scr[yy, xx] = c
                sink[yy, xx] = np.where(joint, 0.65, np.where(dd == 1, 0.8, 0.0))  # 줄눈 · 윗단 모서리
                code[yy, xx] = 50 + (k[m] == K["stairs"])
            fill = vis & ~wall & (span > 1)
            for dd in range(1, int(span[fill].max()) if fill.any() else 0):
                m = fill & (span > dd)
                scr[sy[m] + dd, cols_i[m]] = col[i, m]
                sink[sy[m] + dd, cols_i[m]] = ink[i, m]
                code[sy[m] + dd, cols_i[m]] = k[m] + 1
            ylim = np.where(vis, sy, ylim)
        prev_h = np.where(k != K["void"], h, prev_h)
    # 5) 손그림 마감(집과 같은 finish — 어두운 곳 펜 빗금 · 종이 결 · 재질 경계 먹선) + 돌 먹선 · 조각
    os.makedirs(OUT, exist_ok=True)
    for f in os.listdir(OUT):
        if f.startswith("g") and (f.endswith(".webp") or f.endswith(".import")):
            os.remove(os.path.join(OUT, f))
    pad = 16
    chunks = []
    preview = Image.new("RGB", (W, SH)) if "--preview" in sys.argv else None
    for y0 in range(0, SH, CHUNK):
        for x0 in range(0, W, CHUNK):
            y1, x1 = min(SH, y0 + CHUNK), min(W, x0 + CHUNK)
            ya, xa, yb, xb = max(0, y0 - pad), max(0, x0 - pad), min(SH, y1 + pad), min(W, x1 + pad)
            cc = code[ya:yb, xa:xb]
            if not (cc != 0).any():
                continue
            img, alpha = th.finish(np.clip(scr[ya:yb, xa:xb], 0, 1).astype(np.float64), cc, sprite=True)
            a = sink[ya:yb, xa:xb][..., None].astype(np.float64)
            img = img * (1 - a) + th.INK[None, None, :] * a
            alpha = np.where(cc != 0, 1.0, 0.0)  # 바닥은 바깥 먹선 없이(빈곳 = 검은 바깥)
            rgba = np.dstack([img, alpha])[y0 - ya:y0 - ya + (y1 - y0), x0 - xa:x0 - xa + (x1 - x0)]
            name = "g%d_%d" % (x0 // CHUNK, y0 // CHUNK)
            im = Image.fromarray((rgba * 255).astype(np.uint8), "RGBA")
            im.save(os.path.join(OUT, name + ".webp"), quality=90)
            if preview is not None:
                preview.paste(im.convert("RGB"), (x0, y0))
            chunks.append({"file": name, "rect": [x0, y0 - top, x1 - x0, y1 - y0]})
    json.dump({"_comment": "tools/town_ground_bake.py가 만든다(손으로 고치지 않는다). 바닥 조각 그림: rect = [x, y, w, h] 게임 px(칸당 32 — 화면 y = 남쪽 깊이 − 높이, 높은 단은 0보다 위).",
               "tile": PX, "chunks": chunks}, open(os.path.join(OUT, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    if preview is not None:
        preview.save(os.path.join(user_dir(), "ground_preview.png"))
    print("바닥: %d×%d px → 조각 %d장" % (W, SH, len(chunks)))


if __name__ == "__main__":
    main()
