"""2층 소품 · 구조물 그리기(tools/f2_art/props.py 전용): 거리장 덩어리(sdf.Scene)를 탐험 맵 3/4 시점으로 찍어
손그림으로 마감한다 — ART.md §2 "칠하는 순서": 덩어리 빚기 → 면 방향 3~4단 칠(적갈색 그늘) → 골은 어둡게 → 굵기가 바뀌는 잉크 윤곽
→ 그늘 펜 빗금 → 때 · 색 정리. 빛은 왼쪽 위 앞. 화면 = (x, −(z + K·y)) × U px — 바닥 깊이는 K배로 눌린다."""
import numpy as np
from PIL import Image, ImageFilter

import sdf

F = np.float32
K = 0.72                                   # 바닥 깊이가 화면에서 눌리는 비율
LIGHT = np.array([-0.52, -0.5, 0.69], F)    # 빛이 오는 쪽(왼쪽 · 앞 · 위)
LIGHT /= np.sqrt((LIGHT * LIGHT).sum())
INK = np.array([0x16, 0x10, 0x0e], F) / 255.0
SHADOW = np.array([0x2a, 0x1a, 0x16], F) / 255.0   # 적갈색 그늘
DARK, HIGH = np.array([0x1a, 0x14, 0x12], F) / 255.0, np.array([0xe0, 0xd2, 0xb0], F) / 255.0
LUM = np.array([0.3, 0.59, 0.11], F)


def _noise2(h, w, scale, seed):
    g = np.random.default_rng(seed).random((h // scale + 2, w // scale + 2))
    return np.asarray(Image.fromarray((g * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)).astype(F) / 255.0


def _dilate(m, n=1):
    for _ in range(n):   # 가장자리를 넘어 반대쪽으로 번지지 않게 한 칸 덧대고
        p = np.pad(m, 1)
        m = p[1:-1, 1:-1] | p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    return m


def trace(scene, w, h, u, ox, oy, y0=-2.5, y1=7.0):
    """픽셀마다 시선을 쏘아 닿은 점 · 덩어리 번호를 찾는다 → (닿았나 (h, w), 점 (h, w, 3), 덩어리 번호, 바닥 점)."""
    py, px = np.mgrid[0:h, 0:w]
    x = ((px + 0.5 - ox) / u).astype(F).ravel()
    v = ((oy - (py + 0.5)) / u).astype(F).ravel()            # = z + K·y
    p0 = np.stack([x, np.full_like(x, y0), v - K * y0], 1)
    d_ray = np.array([0.0, 1.0, -K], F)
    dn = float(np.sqrt(1 + K * K))
    t = np.zeros(len(x), F)
    t_max = np.minimum((y1 - y0), (p0[:, 2] + 0.02) / K).astype(F)   # 바닥(z = 0) 아래로는 가지 않는다
    live = np.flatnonzero((t_max > 0) & _coarse(scene, w, h, u, ox, oy, y0, y1).ravel())
    hit = np.zeros(len(x), bool)
    for _ in range(110):
        if len(live) == 0:
            break
        d = scene.dist(p0[live] + t[live, None] * d_ray)
        done = d < 0.004
        hit[live[done]] = True
        t[live] += np.maximum(d, 0.004) * (0.85 / dn)
        live = live[~done & (t[live] < t_max[live])]
    pts = p0 + t[:, None] * d_ray
    part = np.zeros(len(x), np.int32)
    if hit.any():
        _, part[hit] = scene.dist_id(pts[hit])
    ground = p0 + (p0[:, 2] / K)[:, None] * d_ray              # z = 0에 닿는 점
    return hit.reshape(h, w), pts.reshape(h, w, 3), part.reshape(h, w), ground.reshape(h, w, 3)


def _coarse(scene, w, h, u, ox, oy, y0, y1, blk=8):
    """8px 뭉치마다 시선 하나로 "이 근처에 덩어리가 있나"를 먼저 본다(빈 곳은 건너뛴다) → 픽셀 마스크."""
    bh, bw = (h + blk - 1) // blk, (w + blk - 1) // blk
    by, bx = np.mgrid[0:bh, 0:bw]
    x = ((bx * blk + blk * 0.5 - ox) / u).astype(F).ravel()
    v = ((oy - (by * blk + blk * 0.5)) / u).astype(F).ravel()
    p0 = np.stack([x, np.full_like(x, y0), v - K * y0], 1)
    d_ray = np.array([0.0, 1.0, -K], F)
    dn = float(np.sqrt(1 + K * K))
    t = np.zeros(len(x), F)
    t_max = np.minimum((y1 - y0), (p0[:, 2] + 0.15) / K).astype(F)
    near = np.full(len(x), 1e9, F)
    live = np.flatnonzero(t_max > 0)
    reach = blk * 0.75 / u + 0.02
    for _ in range(160):
        if len(live) == 0:
            break
        d = scene.dist(p0[live] + t[live, None] * d_ray)
        near[live] = np.minimum(near[live], d)
        t[live] += np.maximum(d, reach * 0.6) * (0.9 / dn)
        live = live[(near[live] > reach) & (t[live] < t_max[live])]
    occ = (near <= reach).reshape(bh, bw)
    occ = _dilate(occ, 1)
    return np.repeat(np.repeat(occ, blk, 0), blk, 1)[:h, :w]


def normals(scene, p, e=0.006):
    n = np.zeros_like(p)
    for k in range(3):
        o = np.zeros(3, F)
        o[k] = e
        n[:, k] = scene.dist(p + o) - scene.dist(p - o)
    return n / np.maximum(np.sqrt((n * n).sum(-1, keepdims=True)), 1e-6)


def shadow(scene, p, steps=22, k=7.0, far=5.0):
    """p에서 빛 쪽으로 가려진 정도(1 = 빛을 다 받음)."""
    res = np.ones(len(p), F)
    t = np.full(len(p), 0.03, F)
    live = np.arange(len(p))
    for _ in range(steps):
        if len(live) == 0:
            break
        d = scene.dist(p[live] + t[live, None] * LIGHT)
        res[live] = np.minimum(res[live], np.clip(k * d / t[live], 0.0, 1.0))
        t[live] += np.clip(d, 0.03, 0.4)
        live = live[(res[live] > 0.02) & (t[live] < far)]
    return res


def occlusion(scene, p, n):
    ao = np.ones(len(p), F)
    for hgt in (0.05, 0.14, 0.32):
        ao *= np.clip(0.35 + 0.65 * scene.dist(p + n * hgt) / hgt, 0.0, 1.0)
    return ao


def render(scene, mats, w, h, u, ox, oy, seed=1, ground_shadow=0.5, y0=-2.5, y1=7.0):
    """→ 손그림으로 마감한 RGBA(h, w, 4 · uint8)."""
    hit, pts, part, ground = trace(scene, w, h, u, ox, oy, y0, y1)
    p = pts[hit]
    n = normals(scene, p)
    lam = np.clip(n @ LIGHT, 0, 1) * shadow(scene, p + n * 0.02)
    ao = occlusion(scene, p, n)
    tone = (lam * 0.82 + 0.18 * (n[:, 2] * 0.5 + 0.5)) * (0.5 + 0.5 * ao)
    base = np.zeros((len(p), 3), F)
    cid = np.zeros(len(p), F)
    glow = np.zeros(len(p), F)
    pk = part[hit]
    for i, (_, mat) in enumerate(scene.parts):
        sel = pk == i
        if sel.any():
            c, ids, g = mats[mat](p[sel], n[sel])
            base[sel], cid[sel], glow[sel] = c, ids + i * 10.0, g
    # 3~4단 붓 칠: 밝기를 단으로 끊되 경계를 잡음으로 흔든다
    yy, xx = np.nonzero(hit)
    jit = (_noise2(h, w, 7, seed)[yy, xx] - 0.5) * 0.11 + (_noise2(h, w, 2, seed + 1)[yy, xx] - 0.5) * 0.04
    q = tone + jit
    level = 0.36 + 0.26 * np.clip((q - 0.20) / 0.05, 0, 1) + 0.24 * np.clip((q - 0.42) / 0.05, 0, 1) + 0.2 * np.clip((q - 0.68) / 0.06, 0, 1)
    col = base * level[:, None]
    lum = (base @ LUM)[:, None]
    col = col + (SHADOW * lum * 1.6 - col) * (np.clip(0.62 - level, 0, 1) * 0.55)[:, None]   # 그늘은 적갈색으로
    col = col * (1 - glow[:, None]) + base * glow[:, None]                                      # 스스로 빛나는 것
    rgb = np.zeros((h, w, 3), F)
    rgb[hit] = np.clip(col, 0, 1)
    depth = np.full((h, w), 1e3, F)
    depth[hit] = p[:, 1]
    ids = np.full((h, w), -1.0, F)
    ids[hit] = cid
    lv = np.zeros((h, w), F)
    lv[hit] = level
    alpha = hit.astype(F)
    shade = np.zeros((h, w), F)
    if ground_shadow > 0.0:   # 바닥 그림자 + 접지 그늘(물건이 바닥 위에 서 있게)
        gsel = ~hit & (ground[..., 1] > y0 + 0.2) & (ground[..., 1] < y1)
        gp = ground[gsel]
        gp[:, 2] = 0.012
        near = scene.dist(gp)
        sel2 = near < 1.2
        sh = np.ones(len(gp), F)
        sh[sel2] = shadow(scene, gp[sel2], 18, 4.0, 1.6)   # 짧은 그림자만(멀리 드리운 그림자는 칸 밖으로 잘린다)
        fade = np.clip(1.0 - near / 1.2, 0, 1)
        shade[gsel] = np.maximum((1 - sh) * ground_shadow * fade, (1 - np.clip(near / 0.2, 0, 1)) * 0.6)
    return finish(rgb, alpha, depth, ids, part, lv, shade, seed)


def finish(rgb, mask_f, depth, ids, part, level, shade, seed):
    """손그림 마감: 잉크 윤곽(바깥 굵게 · 안쪽 가늘게, 떨리고 끊긴다) · 그늘 빗금 · 때 · 색 정리."""
    h, w = mask_f.shape
    mask = mask_f > 0.5
    yy, xx = np.mgrid[0:h, 0:w]
    # 붓결: 비스듬히 늘인 잡음으로 밝기를 흔든다
    stroke = np.asarray(Image.fromarray((_noise2(h, w, 3, seed + 2) * 255).astype(np.uint8)).resize((w, h * 4), Image.BICUBIC).rotate(24, resample=Image.BICUBIC).crop((0, 0, w, h))).astype(F) / 255.0
    rgb = rgb * (1.0 + (stroke[..., None] - 0.5) * 0.12)
    # 그늘 빗금
    wob = _noise2(h, w, 20, seed + 3) * 5.0
    dark = np.clip((0.50 - level) / 0.14, 0, 1) * mask
    hatch = (((xx * 0.6 + yy * 0.8 + wob) % 4.6) < 1.1) * dark * (_noise2(h, w, 8, seed + 4) > 0.3) * 0.32
    rgb = rgb * (1 - hatch[..., None]) + INK * hatch[..., None]
    # 잉크 윤곽
    thick = _noise2(h, w, 15, seed + 5)
    edge = np.zeros((h, w), bool)
    faint = np.zeros((h, w), bool)
    for sy, sx in ((1, 0), (0, 1)):
        d2, p2, i2, m2 = (np.roll(a, (sy, sx), (0, 1)) for a in (depth, part, ids, mask))
        both = mask & m2
        edge |= both & ((np.abs(depth - d2) > 0.07) | (part != p2))
        faint |= both & (ids != i2)
    edge = edge | (_dilate(edge, 1) & (thick > 0.5) & mask)
    sil = (_dilate(mask, 1) & ~mask) | (_dilate(mask, 2) & ~mask & (thick > 0.42))
    brk = np.where(_noise2(h, w, 26, seed + 6) > 0.12, 1.0, 0.45)
    a_ink = np.maximum(np.where(edge, 0.8, 0.0), np.where(faint & ~edge, 0.38, 0.0)) * brk * (0.75 + _noise2(h, w, 12, seed + 7) * 0.25)
    a_ink = np.maximum(a_ink, np.where(sil, 0.92, 0.0))
    a_ink = np.asarray(Image.fromarray((a_ink * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.45))).astype(F) / 255.0
    a_ink = np.clip(a_ink * 1.25, 0, 1)
    rgb = rgb * (1 - a_ink[..., None]) + INK * a_ink[..., None]
    # 색 정리(ART.md §2): 채도 0.18 빼기 · 대비 1.08 · 그늘 #1a1412 · 밝은 쪽 #e0d2b0
    lum = (rgb @ LUM)[..., None]
    rgb = rgb * 0.82 + lum * 0.18
    rgb = (rgb - 0.5) * 1.08 + 0.5
    rgb = rgb + (DARK - rgb) * np.clip(0.3 - lum, 0, 1) * 0.4 + (HIGH - rgb) * np.clip(lum - 0.62, 0, 1) * 0.12
    rgb = rgb * (1.0 + (_noise2(h, w, 1, seed + 8)[..., None] - 0.5) * 0.05)
    alpha = np.maximum(mask_f, np.where(sil, a_ink, 0.0))
    body = alpha > 0.01
    rgb = np.where(body[..., None], rgb, DARK * 0.4)
    alpha = np.where(body, alpha, np.clip(shade, 0, 0.75))
    out = np.concatenate([np.clip(rgb, 0, 1), alpha[..., None]], -1)
    return (out * 255 + 0.5).astype(np.uint8)


def add_glow(img, cx, cy, r, color, strength=0.6):
    """빛 번짐(등불 · 넋불 · 룬): 칠한 곳은 더하기 빛, 투명한 둘레는 옅은 빛 무리."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    f = np.clip(1.0 - np.hypot(xx - cx, yy - cy) / r, 0, 1) ** 2 * strength
    a = img[..., 3].astype(F) / 255.0
    rgb = img[..., :3].astype(F) / 255.0
    c = np.asarray(color, F)
    lit = np.clip(rgb + c * f[..., None], 0, 1)
    halo_a = f * 0.5
    new_a = np.maximum(a, halo_a)
    mix = np.where((a > 0.5)[..., None], lit, (rgb * a[..., None] + c * halo_a[..., None] * (1 - a[..., None])) / np.maximum(new_a[..., None], 1e-3))
    out = np.concatenate([np.clip(mix, 0, 1), new_a[..., None]], -1)
    return (out * 255 + 0.5).astype(np.uint8)
