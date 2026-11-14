"""벽: 벽면 타일(가로로 이어지는 띠 256 × 160 = 4칸 × 벽 높이 2.5칸) · 벽 윗면 자동 연결 타일(16가지) · 벽 끝 · 구멍 · 무너진 벽 ·
감옥 철창 · 문틀과 문 · 아치 통로 · 수로 배수구.
벽면은 종류(stone · brick · sewer · ancient)마다 같은 돌 배치에 상태(clean · cracked · mossy · damaged)만 덧입힌다 —
같은 종류 안에서는 어느 칸을 어느 상태로 바꿔도 줄눈이 이어진다(칸 x를 4로 나눈 나머지 = 띠 안의 칸)."""
import numpy as np

import ground
import mats as M
import sdf
import surf
import tex
from kit import (F, WALL_H, box, cap, chip, cut_above, cyl, flat, hcyl, prop, rot_x, rot_y, rot_z, rough, smin, sphere, sub, v3)  # noqa: F401
from surf import W, fbm, hexc, pnoise

HF = 320   # 벽면 높이(칠하는 배율 2 × 160)
KINDS = {
    "stone": {"name": "석벽", "base": "#6b6962", "gap": "#191817", "mean": "#56544f", "rows": 8, "len": (84, 150), "wob": 2.2, "var": 0.13, "hue": 0.02},
    "brick": {"name": "벽돌벽", "base": "#64544b", "gap": "#1e1917", "mean": "#4c433d", "rows": 16, "len": (58, 74), "wob": 1.3, "var": 0.18, "hue": 0.03},
    "sewer": {"name": "지하수로 벽", "base": "#52534b", "gap": "#121412", "mean": "#3d3f3a", "rows": 16, "len": (64, 96), "wob": 1.6, "var": 0.18, "hue": 0.03},
    "ancient": {"name": "고대 유적 벽", "base": "#787060", "gap": "#1c1a16", "mean": "#5c574b", "rows": 4, "len": (150, 230), "wob": 1.4, "var": 0.08, "hue": 0.015},
    # 자연 암벽 · 지역 벽(에셋 라이브러리 — docs/asset_library): natural = 돌 쌓기 대신 암반 결. moss = "mossy" 상태에 덮이는 것의 색(이끼 · 눈 · 재 · 녹).
    "cave": {"name": "동굴 암벽", "base": "#62625e", "gap": "#141414", "mean": "#4a4a48", "var": 0.12, "hue": 0.012, "natural": "chunk"},
    "sandstone": {"name": "사암 절벽", "base": "#84705a", "gap": "#2a2018", "mean": "#5c4e3e", "var": 0.1, "hue": 0.02, "natural": "strata", "moss": ("#9a8a66", "#8a7a58", "#a89870", "#b4a47c")},
    "ice": {"name": "얼음벽", "base": "#6a88a0", "gap": "#d0e2ee", "mean": "#5c788e", "var": 0.1, "hue": 0.01, "natural": "ice", "moss": ("#aab8c6", "#98a8b8", "#b8c6d2", "#ccd8e2")},
    "basalt": {"name": "검은 현무암 절벽", "base": "#3a3634", "gap": "#0a0808", "mean": "#2c2a29", "var": 0.14, "hue": 0.01, "natural": "column", "moss": ("#5a5654", "#4a4644", "#666260", "#74706c")},
    "metal": {"name": "문양 새긴 금속 벽", "base": "#4e5258", "gap": "#101214", "mean": "#3c4046", "rows": 2, "len": (120, 136), "wob": 0.3, "var": 0.05, "hue": 0.008, "moss": ("#6a4630", "#5a3a28", "#7a5236", "#8a5e3c")},
    # 건물 실내 벽(도시 라이브러리 AM69): lining = 돌 쌓기 대신 안감(판자 · 회벽과 뼈대 · 새김 판벽). mossy 상태 = 눅눅한 물때 · 그을음. whole = 통째로 빠지는 조각이 없다.
    "wood": {"name": "목재 벽", "base": "#6a5038", "gap": "#17110d", "mean": "#4c3a2a", "var": 0.13, "hue": 0.025, "lining": "plank", "moss": ("#2c2620", "#241f1b", "#38302a", "#463c32")},
    "plaster": {"name": "회벽", "base": "#a39a84", "gap": "#1c1612", "mean": "#766d5c", "var": 0.04, "hue": 0.01, "lining": "plaster", "whole": True, "moss": ("#5e5644", "#4c4638", "#6c624e", "#3e3a30")},
    "panel": {"name": "장식 판벽", "base": "#5a4130", "gap": "#140e0b", "mean": "#43322a", "var": 0.06, "hue": 0.015, "lining": "panel", "whole": True, "moss": ("#2a2420", "#221d1a", "#342c26", "#3e342c")},
}
MOSS = ("#3a4628", "#36441f", "#48562c", "#5a6636")   # 덮개 바탕 + 붓 줄 셋
STATES = {"clean": {}, "cracked": {"state": "cracked"}, "mossy": {"state": "mossy"}, "damaged": {"state": "damaged"}}


def _natural(kind, seed):
    """자연 암벽의 조각 배치 → (조각 번호, 경계까지 거리, 그림, 틈, 높이). 가로로 이어진다(W 주기)."""
    kd = KINDS[kind]
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    how = kd["natural"]
    if how == "chunk":      # 동굴 · 협곡: 크고 작은 암괴가 불규칙하게
        cell, d1, edge = tex.voronoi(34, seed, 1.0)
        edge = edge + (fbm(30, seed + 2, 2) - 0.5) * 6.0
        img, gap, h = surf.stonework(cell, edge, hexc(kd["base"]), hexc(kd["gap"]), seed, 3.4, kd["var"], 1.3, kd["hue"], 0.9)
        img = img * (0.86 + fbm(5, seed + 3, 3)[..., None] * 0.3) * surf.relief(fbm(16, seed + 4, 3), 1.8)[..., None]
    elif how == "strata":   # 사암: 물결치는 가로 지층 + 드문 세로 틈, 바람에 패인 홈
        cell, edge, row = surf.courses(seed, 9, 190, 380, 7.0, True, 0.3)
        img, gap, h = surf.stonework(cell, edge, hexc(kd["base"]), hexc(kd["gap"]), seed, 2.4, kd["var"], 1.5, kd["hue"], 0.8)
        band = np.sin(yy / 5.5 + (fbm(4, seed + 2, 2) - 0.5) * 9.0)          # 가는 지층 줄
        img = img * (1.0 + band[..., None] * 0.07) * (0.9 + fbm(3, seed + 3, 3)[..., None] * 0.22)
        hollow = np.clip((fbm(9, seed + 5, 3) - 0.64) * 9.0, 0, 1)             # 풍화 구멍
        img = img * (1 - hollow[..., None] * 0.5) * (1.0 + np.clip(np.roll(hollow, (3, 3), (0, 1)) - hollow, -1, 0)[..., None] * 0.4)
    elif how == "column":   # 현무암: 세로로 쪼개진 기둥 다발, 군데군데 가로로 끊겼다
        wcol = 34.0
        shift = (fbm(3, seed + 1, 2)[0:1, :] - 0.5) * 0 + (pnoise(6, seed + 2)[:, 0:1] - 0.5) * 10.0
        u = (xx + shift) / wcol
        ci = np.floor(u).astype(np.int64) % int(round(W / wcol))
        rng = np.random.default_rng(seed + 3)
        nb = int(round(W / wcol))
        vshift = rng.random(nb).astype(F)[ci] * 130.0
        v = (yy + vshift) / 130.0
        cell = (ci + (np.floor(v).astype(np.int64) % 4) * nb).astype(np.int64)
        edge = np.minimum(np.minimum(u % 1.0, 1.0 - u % 1.0) * wcol, np.minimum(v % 1.0, 1.0 - v % 1.0) * 130.0 * 0.6)
        img, gap, h = surf.stonework(cell, edge, hexc(kd["base"]), hexc(kd["gap"]), seed, 2.6, kd["var"], 1.2, kd["hue"], 0.5)
        round_ = np.sin(np.clip(u % 1.0, 0, 1) * np.pi) ** 0.5                 # 기둥마다 둥근 배
        img = img * (0.72 + round_[..., None] * 0.36)
    else:                   # 얼음: 큰 덩이 몇 개, 흰 금과 속에 비치는 세로 결 · 공기층
        cell, d1, edge = tex.voronoi(12, seed, 1.0)
        edge = edge + (fbm(20, seed + 2, 2) - 0.5) * 8.0
        base = hexc(kd["base"])[None, None, :] * (0.7 + fbm(4, seed + 3, 3)[..., None] * 0.6)
        streak = np.clip((fbm(90, seed + 4, 1)[0:1, :] * 0.6 + fbm(40, seed + 5, 2) * 0.4 - 0.5) * 3.0, 0, 1)
        img = base * (1.0 + streak[..., None] * 0.22)
        deep = np.clip((fbm(6, seed + 6, 3) - 0.55) * 4.0, 0, 1)
        img = img * (1 - deep[..., None] * 0.35)
        gap = np.clip(1.0 - edge / 2.2, 0, 1)
        img = surf.mix(img, gap * 0.85, hexc(kd["gap"]))
        img = img + (np.clip(1.0 - edge / 9.0, 0, 1) * 0.1)[..., None]
        h = np.clip(edge / 9.0, 0, 1)
    return cell, edge, img, gap, h


def _aniso(cx, cy, seed):
    """한쪽으로 길게 늘인 이어지는 잡음 0~1(W × W, 격자 가로 cx · 세로 cy칸) — 나뭇결."""
    g = np.random.default_rng(seed).random((cy, cx)).astype(F)

    def ax(n):
        x = np.arange(W) * n / W
        i = np.floor(x).astype(int)
        f = (x - i).astype(F)
        return i % n, (i + 1) % n, f * f * (3 - 2 * f)
    x0, x1, fx = ax(cx)
    y0, y1, fy = ax(cy)
    a = g[y0][:, x0] * (1 - fx)[None, :] + g[y0][:, x1] * fx[None, :]
    b = g[y1][:, x0] * (1 - fx)[None, :] + g[y1][:, x1] * fx[None, :]
    return a * (1 - fy)[:, None] + b * fy[:, None]


def _lining(kind, seed):
    """실내 벽 안감 → (조각 번호, 경계까지 거리, 그림, 틈, 높이). 가로로 이어진다(W 주기)."""
    kd = KINDS[kind]
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    how = kd["lining"]
    base, gapc = hexc(kd["base"]), hexc(kd["gap"])
    vgrain = _aniso(150, 9, seed + 4) * 0.6 + _aniso(70, 5, seed + 5) * 0.4          # 세로 결
    hgrain = _aniso(9, 150, seed + 6) * 0.6 + _aniso(5, 70, seed + 7) * 0.4          # 가로 결
    if how == "plank":      # 세로 널판 + 허리 띠 + 걸레받이
        pw, nb = 32.0, 16
        u = (xx + (pnoise(5, seed + 1)[:, 0:1] - 0.5) * 2.0) / pw
        ci = np.floor(u).astype(np.int64) % nb
        rng = np.random.default_rng(seed + 3)
        vshift = rng.random(nb).astype(F)[ci] * 300.0
        v = (yy + vshift) / 300.0
        cell = (ci + (np.floor(v).astype(np.int64) % 3) * nb).astype(np.int64)
        edge = np.minimum(np.minimum(u % 1.0, 1.0 - u % 1.0) * pw, np.minimum(v % 1.0, 1.0 - v % 1.0) * 300.0)
        img, gap, h = surf.stonework(cell, edge, base, gapc, seed, 1.8, kd["var"], 0.7, kd["hue"], 0.15)
        img = img * (0.78 + vgrain[..., None] * 0.44)
        knot = np.clip((pnoise(40, seed + 8) - 0.93) * 30.0, 0, 1)
        img = img * (1 - knot[..., None] * 0.5)
        for y0, hh in ((HF * 0.55, 9.0), (HF - 30.0, 30.0), (0.0, 20.0)):   # 허리 띠 · 걸레받이 · 머리 띠(가로 널)
            band = (yy >= y0) & (yy < y0 + hh)
            col = base[None, None, :] * (0.72 if hh > 12 else 0.9) * (0.8 + hgrain[..., None] * 0.4)
            img = np.where(band[..., None], col, img)
            top = np.clip(1.0 - np.abs(yy - y0 - 1.5) / 1.5, 0, 1)
            bot = np.clip(1.0 - np.abs(yy - y0 - hh) / 2.0, 0, 1)
            img = img * (1 + top[..., None] * 0.3) * (1 - bot[..., None] * 0.6)
            gap = np.where(band, 0.0, gap)
            edge = np.where(band, 20.0, edge)
            cell = np.where(band, cell.max() + 1, cell)
        nail = np.clip(1.0 - np.hypot((xx % pw) - pw / 2, yy - HF * 0.55 - 4.5) / 2.2, 0, 1)
        img = img * (1 - nail[..., None] * 0.6)
    elif how == "plaster":  # 회반죽 + 나무 뼈대(머리 들보 · 밑 도리 · 두 칸마다 기둥 · 한 칸 건너 가새)
        trowel = fbm(7, seed + 2, 3)
        img = base[None, None, :] * (0.9 + trowel[..., None] * 0.2) * (1.0 + (fbm(3, seed + 3, 2) - 0.5)[..., None] * np.array([0.06, 0.0, -0.06], F))
        h = trowel * 0.5 + fbm(40, seed + 8, 2) * 0.2
        img = img * surf.relief(h, 1.1)[..., None]
        chipm = np.clip((fbm(11, seed + 9, 3) - 0.66) * 9.0, 0, 1) * 0.25                    # 살짝 뜬 자리
        img = img * (1 - chipm[..., None])
        lx = xx % 256.0
        bay = np.floor(xx / 256.0)
        ly = np.clip((yy - 22.0) / (HF - 50.0), 0, 1)
        d_post = np.abs(lx - 128.0 + (pnoise(4, seed + 1)[:, 0:1] - 0.5) * 3.0) - 11.0
        d_top, d_sill = yy - 22.0, (HF - 28.0) - yy
        bx = np.where(bay % 2 == 0, 256.0 - lx, lx)                                           # 기둥은 lx = 128, 가새는 칸 가운데를 가로지른다
        d_brace = np.where((lx > 139) | (lx < 117), np.abs(((bx - 128.0) % 256.0) - (20.0 + (1 - ly) * 96.0)) * 0.78 - 7.0, 99.0)
        d_brace = np.where(ly > 0.42, d_brace, 99.0)
        d = np.minimum.reduce([d_post, d_top, d_sill, d_brace])
        beam = d < 0
        horiz = (np.minimum(d_top, d_sill) < np.minimum(d_post, d_brace))
        wood = hexc("#4a382a")[None, None, :] * np.where(horiz[..., None], 0.75 + hgrain[..., None] * 0.5, 0.75 + vgrain[..., None] * 0.5)
        img = np.where(beam[..., None], wood, img)
        edge = np.abs(d)
        gap = np.clip(1.0 - edge / 2.0, 0, 1)
        img = img * (1 - np.clip(1.0 - np.maximum(d, 0) / 9.0, 0, 1)[..., None] * 0.22 * (~beam)[..., None])   # 뼈대 옆 그늘
        img = surf.mix(img, gap, gapc)
        cell = np.where(beam, 1, 0).astype(np.int64)
        h = h + beam * 0.5
    else:                   # 새김 판벽: 칸마다 위 큰 판(마름모 + 둥근 새김) · 아래 작은 판, 틀 · 허리 띠 · 걸레받이
        pw = 128.0
        lx = xx % pw
        mid, top, bot = HF * 0.6, 22.0, HF - 28.0
        upper = yy < mid
        y0 = np.where(upper, top + 9.0, mid + 9.0)
        y1 = np.where(upper, mid - 9.0, bot - 8.0)
        d = np.minimum(np.minimum(lx - 13.0, pw - 13.0 - lx), np.minimum(yy - y0, y1 - yy))  # 판 안쪽이 +
        field = d > 0
        cell = np.where(field, 1 + np.floor(xx / pw) + upper * 4, 0).astype(np.int64)
        edge = np.abs(d)
        img, gap, h = surf.stonework(cell, np.where(field, edge, 30.0), base, gapc, seed, 2.0, kd["var"], 0.5, kd["hue"], 0.1)
        frame_g = np.where((yy < top) | (yy > bot) | ((np.abs(yy - mid) < 9) & True), hgrain, vgrain)
        img = img * np.where(field[..., None], 0.8 + vgrain[..., None] * 0.36, (0.66 + frame_g[..., None] * 0.4))
        bev = np.clip(d / 9.0, 0, 1) * field                                                   # 판 둘레 빗면(돋움 판)
        img = img * surf.relief(bev * 1.4, 2.2)[..., None]
        gap = np.clip(1.0 - np.abs(d) / 1.6, 0, 1)
        img = surf.mix(img, gap * 0.8, gapc)
        cx_, cy_ = lx - pw / 2, yy - (top + 9.0 + mid - 9.0) / 2
        line = lambda dd, w=1.6: np.clip(1.0 - np.abs(dd) / w, 0, 1)
        r = np.hypot(cx_, cy_)
        dia = np.abs(cx_) / 34.0 + np.abs(cy_) / 58.0
        g = np.maximum.reduce([line((dia - 1.0) * 30.0), line(r - 17.0), line(r - 7.0, 1.3),
            line(np.abs(np.sin(np.arctan2(cy_, cx_) * 4.0)) * r, 1.4) * (r > 7.0) * (r < 17.0)]) * upper * (d > 12)
        lo = np.minimum(np.minimum(lx - 30.0, pw - 30.0 - lx), np.minimum(yy - mid - 22.0, bot - 21.0 - yy))
        g = np.maximum(g, line(lo, 1.5) * (~upper) * field)
        img = img * (1 - g[..., None] * 0.5) + np.clip(np.roll(g, (2, 2), (0, 1)) - g, 0, 1)[..., None] * 0.07
        img = img * (1.0 + np.clip(surf.relief(fbm(5, seed + 6, 2), 2.0) - 1.0, 0, 1)[..., None] * 0.12)   # 밀랍 먹인 윤
    return cell, edge, img, gap, h


def _face_base(kind, seed):
    kd = KINDS[kind]
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    t = yy / HF                                                    # 0 벽 머리 → 1 바닥
    if kd.get("lining"):
        cell, edge, img, gap, h = _lining(kind, seed)
        return img, gap, h, cell, edge, t
    if kd.get("natural"):
        cell, edge, img, gap, h = _natural(kind, seed)
        return img, gap, h, cell, edge, t
    cell, edge, row = surf.courses(seed, kd["rows"], kd["len"][0], kd["len"][1], kd["wob"], True, 0.0)
    img, gap, h = surf.stonework(cell, edge, hexc(kd["base"]), hexc(kd["gap"]), seed, 2.8, kd["var"], 1.0, kd["hue"], 0.6)
    if kind == "metal":     # 금속판: 판마다 벽화 같은 새김 문양(지어낸 도안) + 판 둘레 못 + 녹물
        pw, ph = 128.0, 160.0
        lx, ly = (xx % pw) / pw - 0.5, (yy % ph) / ph - 0.5
        gx, gy = np.floor(xx / pw), np.floor(yy / ph)
        hs = sdf._hash(gx, gy, gx * 0, seed + 3)
        r, ang = np.hypot(lx, ly * 1.25), np.arctan2(ly, lx)
        line = lambda d, w=0.012: np.clip(1.0 - np.abs(d) / w, 0, 1)
        g = np.maximum.reduce([
            line(np.maximum(np.abs(lx), np.abs(ly)) - 0.42), line(r - 0.3), line(r - 0.12, 0.016),
            line(np.abs(np.sin(ang * (3 + np.floor(hs * 3)))) * r, 0.014) * (r > 0.12) * (r < 0.3),
            line(np.abs(lx) - 0.36, 0.01) * (np.abs(ly) < 0.3) * (np.abs(((ly + 0.5) * 9.0) % 1.0 - 0.5) < 0.3),
        ])
        rivet = np.clip(1.0 - np.hypot(((xx + 8) % 32) - 16, ((yy + 8) % 32) - 16) / 3.2, 0, 1) * ((np.abs(lx) > 0.44) | (np.abs(ly) > 0.45))
        img = img * (1 - g[..., None] * 0.55) + np.clip(np.roll(g, (2, 2), (0, 1)) - g, 0, 1)[..., None] * 0.14
        img = img * (1 + rivet[..., None] * 0.5)
        sheen = np.clip(surf.relief(fbm(4, seed + 6, 2), 3.0) - 1.0, 0, 1)
        img = img + sheen[..., None] * 0.1
        rust = np.clip((fbm(70, seed + 7, 1)[0:1, :] - 0.55) * 4.0, 0, 1) * np.clip((fbm(5, seed + 8, 3) - 0.4) * 3, 0, 1) * np.clip(t * 1.4, 0, 1)
        img = surf.mix(img, rust * 0.55, hexc("#5a3826"))
    if kind == "ancient":   # 머리띠: 돋을새김 글줄(지어낸 글자) + 띠 아래위 홈
        band = (yy > 26) & (yy < 74)
        gx, gy = np.floor(xx / 21.0), np.floor((yy - 32) / 18.0)
        hs = sdf._hash(gx, gy, gx * 0, seed + 3)
        lx, ly = (xx / 21.0) % 1.0, ((yy - 32) / 18.0) % 1.0
        glyph = (((np.abs(lx - 0.5) < 0.09) & (hs > 0.3)) | ((np.abs(ly - 0.3 - hs * 0.4) < 0.1) & (lx > 0.15) & (lx < 0.85) & (hs < 0.75)) | ((np.abs(lx - ly) < 0.09) & (hs > 0.6))) & (ly > 0.1) & (ly < 0.9) & (lx > 0.12) & (lx < 0.88)
        glyph = (glyph & band & (yy > 32) & (yy < 68)).astype(F)
        plain = hexc(kd["base"])[None, None, :] * (0.92 + fbm(14, seed + 4, 3)[..., None] * 0.2)
        img = np.where(band[..., None], plain, img)
        img = img * (1 - glyph[..., None] * 0.5) + np.clip(np.roll(glyph, (2, 2), (0, 1)) - glyph, 0, 1)[..., None] * 0.1
        line = ((np.abs(yy - 26) < 2.2) | (np.abs(yy - 74) < 2.2)).astype(F)
        img = img * (1 - line[..., None] * 0.6)
        gap = np.where(band, 0.0, gap)
    if kind == "sewer":     # 물때: 아래 삼분의 일이 젖어 검푸르고, 물금 위로 물이끼 띠
        level = 0.66 + (fbm(5, seed + 5, 2)[0:1, :] - 0.5) * 0.08
        wet = np.clip((t - level) * 16.0, 0, 1)
        img = surf.mix(img, wet * 0.6, img * np.array([0.52, 0.57, 0.52], F) + hexc("#0c100e") * 0.3)
        algae = np.clip(1.0 - np.abs(t - level) / 0.045, 0, 1) * (0.5 + fbm(24, seed + 6, 2) * 0.7)
        img = surf.mix(img, np.clip(algae, 0, 1) * 0.6, hexc("#353f24"))
        streak = np.clip((fbm(64, seed + 7, 1)[0:1, :] - 0.6) * 5.0, 0, 1) * np.clip(t * 1.6, 0, 1) * np.clip((fbm(6, seed + 8, 2) - 0.3) * 2, 0, 1)
        img = surf.mix(img, streak * 0.5, hexc("#1c2416"))
    return img, gap, h, cell, edge, t


def _face_finish(kind, img, t, ref, seed):
    """벽면 마감: 머리 턱(밝은 띠 + 그 아래 그늘) · 아래로 갈수록 때 · 바닥 닿는 그늘 → 256 × 160 RGBA."""
    yy = np.mgrid[0:W, 0:W][0].astype(F)

    def shade(a):
        lip = np.clip(1.0 - yy / 9.0, 0, 1)
        a = a * (1.0 + lip[..., None] * 0.28)
        under = np.clip(1.0 - np.abs(yy - 13.0) / 5.0, 0, 1)
        a = a * (1.0 - under[..., None] * 0.34)
        a = a * (1.0 - np.clip((t - 0.25) * 0.3, 0, 0.3))[..., None]
        foot = np.clip((t - 0.86) / 0.14, 0, 1) ** 1.5
        return a * (1.0 - foot[..., None] * 0.55)
    out = surf.finish(shade(img), KINDS[kind]["mean"], seed, {"brick": 0.4, "sewer": 0.34}.get(kind, 0.18), ref=shade(ref))[:160]
    return np.concatenate([out, np.full((160, 256, 1), 255, np.uint8)], -1)


def _wall_cracks(ly, rng, n):
    """벽을 타고 내려오는 금: 위가 굵고 아래로 가늘어진다. 가끔 짧은 가지."""
    for _ in range(n):
        x, y = rng.random() * W, rng.uniform(8, HF * 0.45)
        a = np.pi / 2 + rng.uniform(-0.5, 0.5)
        pts = [(x, y)]
        for k in range(int(rng.uniform(90, 240) / 14)):
            a += rng.uniform(-0.45, 0.45) + (np.pi / 2 - a) * 0.2
            pts.append((pts[-1][0] + np.cos(a) * 14, min(pts[-1][1] + np.sin(a) * 14, HF - 8)))
        w0 = rng.uniform(3.2, 5.0)
        m = len(pts) - 1
        for i in range(m):
            w = max(1.2, w0 * (1 - i / m) ** 0.8)
            seg = [pts[i], pts[i + 1]]
            ly.line([(px + 1.6, py + 1.0) for px, py in seg], np.array([0.62, 0.59, 0.52], F), 0.25, w)
            ly.line(seg, tex.SHADOW, 0.96, w)
            if rng.random() < 0.1 and i < m - 1:
                b = a + rng.choice([-1, 1]) * rng.uniform(0.7, 1.1)
                ly.line([pts[i], (pts[i][0] + np.cos(b) * 16, pts[i][1] + np.sin(b) * 16), (pts[i][0] + np.cos(b + 0.3) * 30, pts[i][1] + np.sin(b + 0.3) * 30)], tex.SHADOW, 0.9, max(1.2, w * 0.5))


def _wall(kind):
    kd = KINDS[kind]

    @flat("wall_" + kind, "wall", layer="wall", cell=(256, 160), variants=STATES, name_ko=kd["name"], tags=["wall", kind],
        meta={"tile": [64, 160], "span": 4, "states": list(STATES), "sheet": "wall_faces"})
    def face(c, state="clean", seed=1):
        seed = 400 + list(KINDS).index(kind) * 17
        img, gap, h, cell, edge, t = _face_base(kind, seed)
        ref = img
        rng = np.random.default_rng(seed + 9)
        if state == "cracked":
            ly = tex.Layer()
            _wall_cracks(ly, rng, 5)
            loose = (rng.random(int(cell.max()) + 1) < 0.1)[cell].astype(F)        # 들뜬 돌 몇 장은 어긋나 어둡다
            img = ly.over(img * (1 - loose[..., None] * 0.2))
        elif state == "mossy":
            n = fbm(6, seed + 30, 4)
            moss = np.clip((n - 0.62) * 5.0 + np.clip((t - 0.55) * 1.6, 0, 1) + np.clip(0.12 - t, 0, 1) * 3.0 + gap * 0.5, 0, 1)
            tone = 0.65 + fbm(36, seed + 31, 2) * 0.7
            mc = kd.get("moss", MOSS)
            img = surf.mix(img, moss * 0.88, hexc(mc[0])[None, None, :] * tone[..., None])
            mold = np.clip((fbm(9, seed + 32, 3) - 0.6) * 7.0, 0, 1) * (1 - moss)
            drip = np.clip((fbm(80, seed + 33, 1)[0:1, :] - 0.62) * 6.0, 0, 1) * np.clip(n * 2 - 0.5, 0, 1) * np.clip(1 - t, 0, 1)
            if "moss" not in kd:   # 이끼 낀 벽에만 곰팡이 · 녹색 물줄기
                img = surf.mix(img, mold * 0.6, hexc("#1a1e16"))
                img = surf.mix(img, drip * 0.5, hexc("#2e3a22"))
            ly = tex.Layer()
            ground.strokes(ly, rng, 2400, 4, 9, [hexc(mc[1]), hexc(mc[2]), hexc(mc[3])], 3.14, 0.5, 1.6, 0.85, np.clip(moss * 1.3 - 0.4, 0, 1))
            img = ly.over(img)
        elif state == "damaged":
            n_cell = int(cell.max()) + 1
            gone = (rng.random(n_cell) < (0.09 if kind not in ("ancient", "metal", "ice") and not kd.get("whole") else 0.0))[cell].astype(F)
            hole = gone * np.clip((edge - 1.5 + (fbm(30, seed + 41, 2) - 0.5) * 5.0) * 1.2, 0, 1)   # 통째로 빠진 돌(가장자리가 또렷하다)
            pn = fbm(5, seed + 40, 3) + (fbm(26, seed + 43, 2) - 0.5) * 0.12
            hole = np.maximum(hole, np.clip((pn - (0.69 if kind != "ancient" else 0.64)) * 45.0, 0, 1))   # 뜯겨 나간 자리
            hole = hole * (t > 0.07) * (t < 0.93)
            inner = np.clip(tex.blur(hole, 6) * 1.4 - 0.35, 0, 1)
            back = hexc(kd["base"])[None, None, :] * (0.3 + fbm(30, seed + 42, 3)[..., None] * 0.3) * (1 - inner[..., None] * 0.7)
            lipm = np.roll(hole, (6, 4), (0, 1)) - hole
            img = surf.mix(img, hole, back)
            img = img * (1.0 + np.minimum(lipm, 0)[..., None] * 0.8) + np.clip(lipm, 0, 1)[..., None] * 0.07
            ly = tex.Layer()
            _wall_cracks(ly, rng, 2)
            img = ly.over(img)
        return _face_finish(kind, img, t, ref, seed)
    return face


for _k in KINDS:
    _wall(_k)


TOPS = {"cave": ("#2a2a2a", "#62625e", "#565654", "v"), "sandstone": ("#32291f", "#84705a", "#5e5040", "v"), "ice": ("#34465a", "#7e9cb2", "#647e92", "v"),
    "basalt": ("#1a1818", "#3a3634", "#343130", "v"), "metal": ("#202326", "#4e5258", "#44484e", "c")}   # 종류 → (속 · 테 돌 · 테 평균 색, 테 쌓기 v 암괴/c 줄)


@flat("wall_top", "wall", layer="wall", cell=(256, 256), variants=dict({"a": {"seed": 1}, "b": {"seed": 2}}, **{k: {"seed": 1, "kind": k} for k in TOPS}), name_ko="벽 윗면(자동 연결 16가지)", tags=["wall", "autotile"],
    meta={"tile": [64, 64], "autotile": "nesw4", "sheet": "wall_tops", "note": "칸 번호 = 이웃 벽 비트(북 1 · 동 2 · 남 4 · 서 8) → 열 = 번호 % 4, 줄 = 번호 // 4. 이웃이 없는 변에 테가 생긴다(모서리 · 끝 · T자 · 십자)."})
def wall_top(c, seed=1, kind=None):
    """벽 윗면: 어두운 돌 속 + 이웃 벽이 없는 변에 밝은 돌 테. 벽면 타일 위(벽 높이만큼 올린 층)에 깐다."""
    cell, d1, edge = tex.voronoi(60, seed + 500, 0.8)
    core_c, rim_c, rim_mean, lay = TOPS.get(kind, ("#34322f", "#6b6962", "#5e5c56", "c"))
    img, gap, h = surf.stonework(cell, edge, hexc(core_c), hexc("#0e0d0d"), seed, 3.0, 0.16, 0.8, 0.012, 0.5)
    core = surf.finish(img, "#262422" if kind is None else core_c, seed).astype(F) / 255.0
    if lay == "c":
        cell2, edge2, _ = surf.courses(seed + 510, 16, 50, 80, 1.5, True, 0.0)
    else:   # 자연 암벽: 테도 불규칙한 암괴
        cell2, _, edge2 = tex.voronoi(90, seed + 510, 1.0)
    rim_img, _, _ = surf.stonework(cell2, edge2, hexc(rim_c), hexc("#191817"), seed, 2.6, 0.14, 1.0)
    rimtex = surf.finish(rim_img, rim_mean, seed).astype(F) / 255.0
    out = np.zeros((256, 256, 4), F)
    yy, xx = np.mgrid[0:64, 0:64].astype(F)
    wob = lambda s: (surf.tex.pnoise(8, seed + s)[:64, :64] - 0.5) * 3.0
    for mask in range(16):
        ox, oy = (mask % 4) * 64, (mask // 4) * 64
        tile = core[oy:oy + 64, ox:ox + 64].copy()
        dist = np.full((64, 64), 99.0, F)
        if not mask & 1:
            dist = np.minimum(dist, yy + 0.5 + wob(1))
        if not mask & 2:
            dist = np.minimum(dist, 63.5 - xx + wob(2))
        if not mask & 4:
            dist = np.minimum(dist, 63.5 - yy + wob(3))
        if not mask & 8:
            dist = np.minimum(dist, xx + 0.5 + wob(4))
        for bit, cx, cy in ((1 | 2, 63.5, 0.5), (2 | 4, 63.5, 63.5), (4 | 8, 0.5, 63.5), (8 | 1, 0.5, 0.5)):   # 두 이웃은 있는데 대각이 비는 안쪽 모서리는 타일로는 알 수 없다 — 테 없이 둔다
            pass
        rim = np.clip((11.0 - dist) / 1.5, 0, 1)
        tile = tile * (1 - rim[..., None]) + rimtex[oy:oy + 64, ox:ox + 64] * rim[..., None]
        inner = np.clip(1.0 - np.abs(dist - 11.5) / 1.6, 0, 1)        # 테 안쪽 잉크 선
        tile = tile * (1 - inner[..., None] * 0.8)
        fall = np.clip((dist - 11.0) / 16.0, 0, 1)                    # 테에서 멀수록 어둠에 잠긴다
        tile = tile * (1.0 - fall[..., None] * 0.35 * (dist < 90)[..., None])
        outer = np.clip(1.0 - dist / 1.6, 0, 1)
        tile = tile * (1 - outer[..., None] * 0.7)
        out[oy:oy + 64, ox:ox + 64, :3] = tile
    out[..., 3] = 1.0
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


# ── 벽면에 덧붙이는 평면 조각(원점 = 벽 밑동 가운데) ────────────────────────────

def _quoin(c, side):
    """벽 끝 모서리돌 기둥: 크고 작은 돌이 번갈아 물린다."""
    rng = c.rng
    x_edge = 0.0 if side == "l" else c.w
    sgn = 1 if side == "l" else -1
    y = 0.0
    k = 0
    while y < c.h:
        hh = rng.uniform(19, 25)
        ww = (30 if k % 2 == 0 else 20) + rng.uniform(-2, 2)
        x0, x1 = sorted((x_edge, x_edge + sgn * ww))
        m = c.rect(x0 - 2, y + 1, x1, min(y + hh - 1, c.h))
        tone = rng.uniform(0.85, 1.12)
        col = hexc("#7a776e") * tone
        c.paint(m, col[None, None, :] * (0.9 + c.noise(9)[..., None] * 0.22))
        c.shade(c.rect(x0 - 2, y + hh - 4, x1, y + hh - 1), -0.3)
        c.shade(c.rect(x0 - 2, y + 1, x1, y + 3), 0.16)
        inner_x = x1 if side == "l" else x0
        c.paint(c.rect(inner_x - 1.2, y, inner_x + 1.2, y + hh), "#16100e", 0.85)
        c.paint(c.rect(x0 - 2, y + hh - 1.2, x1, y + hh + 0.6), "#16100e", 0.8)
        y += hh
        k += 1
    t = c.yy / c.h
    c.shade((t > 0.86) * ((t - 0.86) / 0.14), -0.5)
    c.shade(np.clip(1.0 - c.yy / 5.0, 0, 1), 0.2)


@flat("wall_end", "wall", layer="wall_decal", cell=(34, 160), name_ko="벽 끝(모서리돌)", tags=["wall", "connector"],
    variants={"l": {"side": "l"}, "r": {"side": "r"}}, meta={"mount": "face_edge", "note": "벽면 줄이 끝나는 칸의 바깥 가장자리에 맞춰 얹는다"})
def wall_end(c, side="l", seed=1):
    _quoin(c, side)
    c.origin = (0.0 if side == "l" else c.w, c.h)


@flat("wall_shadow", "wall", layer="wall_decal", cell=(48, 160), name_ko="안쪽 모서리 그늘", tags=["wall", "connector"],
    variants={"l": {"side": "l"}, "r": {"side": "r"}}, meta={"mount": "face_edge", "note": "벽면이 옆벽과 만나는 안쪽 모서리에 얹는 그늘"})
def wall_shadow(c, side="l", seed=1):
    d = c.xx if side == "l" else c.w - c.xx
    m = np.clip(1.0 - d / 46.0, 0, 1) ** 1.7 * (0.85 + c.noise(12) * 0.3)
    c.paint(np.clip(m, 0, 1), "#0c0a0a", 0.9)
    c.graded = False
    c.origin = (0.0 if side == "l" else c.w, c.h)


@flat("wall_hole", "wall", layer="wall_decal", cell=(72, 84), name_ko="벽의 구멍", tags=["wall", "damage"],
    variants={"a": {"seed": 1}, "b": {"seed": 2}, "c": {"seed": 3}, "high": {"seed": 4, "high": True}}, meta={"mount": "face"})
def wall_hole(c, seed=1, high=False):
    """뚫린 구멍: 들쭉날쭉한 검은 속 + 깨진 돌 테 + (밑동이면) 흘러내린 돌."""
    cx, cy = c.w * 0.5, (c.h * 0.5 if high else c.h * 0.58)
    rx, ry = c.w * (0.3 + c.rng.random() * 0.06), c.h * (0.26 if high else 0.36)
    outer = c.blob(cx, cy, rx * 1.28, ry * 1.25, 0.32, 9, 0.05)
    hole = c.blob(cx, cy + 1, rx, ry, 0.4, 7, 0.06)
    stone = hexc("#6f6c64")[None, None, :] * (0.7 + c.noise(5)[..., None] * 0.5)
    c.paint(outer, stone)
    c.shade(c.noise(3) > 0.55, -0.18)
    c.paint(c.rim(outer, 1.4), "#16100e", 0.9)
    c.paint(hole, "#0a0808")
    c.paint(np.clip(np.roll(hole, (5, 4), (0, 1)) - hole, 0, 1) * outer, "#2a2622", 0.55)   # 속으로 꺼지는 두께
    c.paint(c.rim(hole, 1.3), "#16100e", 0.95)
    for x, y, a, ln in ((cx - rx, cy - ry * 0.6, 3.6, 16), (cx + rx, cy - ry * 0.4, -0.4, 18), (cx, cy - ry, -1.5, 14)):
        c.paint(c.cracks([(x, y, a, ln)], 1.8), "#16100e", 0.9)
    if not high:
        for _ in range(7):
            x, y, r = cx + c.rng.uniform(-rx * 1.3, rx * 1.3), c.h - c.rng.uniform(4, 12), c.rng.uniform(3, 6.5)
            b = c.blob(x, y, r, r * 0.75, 0.3, 4, 0.12)
            c.paint(c.blob(x + 1.5, y + 2, r * 1.15, r * 0.8, 0.3, 4, 0.2), "#100c0c", 0.55)
            c.paint(b, hexc("#77746b") * c.rng.uniform(0.75, 1.1))
            c.paint(c.blob(x - r * 0.25, y - r * 0.25, r * 0.5, r * 0.36, 0.2, 3, 0.2) * b, "#9a968a", 0.6)
            c.paint(c.rim(b, 1.0), "#16100e", 0.85)
    c.origin = (c.w * 0.5, c.h if not high else c.h * 0.5)


@flat("wall_breach", "wall", layer="wall_decal", cell=(72, 166), name_ko="무너져 뚫린 벽", tags=["wall", "damage", "passage"],
    variants={"a": {"seed": 1}, "b": {"seed": 2}}, meta={"mount": "face", "passage": True})
def wall_breach(c, seed=1):
    """벽이 위에서 바닥까지 터져 지나갈 수 있는 틈: 검은 속 + 깨진 돌 테 + 밑에 쌓인 돌."""
    cx = c.w * 0.5
    half = 16 + (c.noise(26, seed + 3, 2) - 0.5) * 22 + (c.yy / c.h) * 6 - np.clip(1 - c.yy / 26.0, 0, 1) * 9
    d = np.abs(c.xx - cx - (c.noise(40, seed + 4, 2) - 0.5) * 14)
    hole = np.clip((half - d) / 0.8, 0, 1) * (c.yy > 5)
    outer = np.clip((half + 7 + (c.noise(8, seed + 5, 2) - 0.5) * 7 - d) / 0.8, 0, 1) * (c.yy > 2)
    c.paint(outer, hexc("#6f6c64")[None, None, :] * (0.65 + c.noise(5)[..., None] * 0.55))
    c.paint(c.rim(outer, 1.4), "#16100e", 0.9)
    c.paint(hole, "#080707")
    c.paint(np.clip(np.roll(hole, (0, 6), (0, 1)) - hole, 0, 1) * outer, "#2c2824", 0.6)
    c.paint(c.rim(hole, 1.3), "#16100e", 0.95)
    for _ in range(11):
        x, y, r = cx + c.rng.uniform(-30, 30), c.h - c.rng.uniform(4, 16), c.rng.uniform(3.5, 8)
        b = c.blob(x, y, r, r * 0.75, 0.3, 4, 0.12)
        c.paint(c.blob(x + 1.5, y + 2, r * 1.15, r * 0.8, 0.3, 4, 0.2), "#100c0c", 0.55)
        c.paint(b, hexc("#77746b") * c.rng.uniform(0.7, 1.1))
        c.paint(c.blob(x - r * 0.25, y - r * 0.25, r * 0.5, r * 0.36, 0.2, 3, 0.2) * b, "#9a968a", 0.6)
        c.paint(c.rim(b, 1.0), "#16100e", 0.85)
    c.origin = (cx, c.h - 6)


@flat("sewer_outlet", "wall", layer="wall_decal", cell=(64, 96), name_ko="수로 배수구", tags=["wall", "sewer"], fps=6,
    variants={"dry": {}, "grate": {"grate": True}, "flow": {"flow": True, "frames": 4}, "grate_flow": {"grate": True, "flow": True, "frames": 4}}, meta={"mount": "face"})
def sewer_outlet(c, grate=False, flow=False, f=0, seed=1):
    """벽돌 테를 두른 둥근 배수구(벽 밑동 위 한 뼘). flow = 물줄기가 흘러내려 밑에 고인다."""
    cx, cy, r = 32.0, 34.0, 17.0
    ringm = c.ring(cx, cy, r + 4.5, 9.5)
    ang = np.arctan2(c.yy - cy, c.xx - cx)
    seg = (np.floor(ang / (np.pi / 7) + 0.5) % 2)
    c.paint(ringm, hexc("#5a4c42")[None, None, :] * (0.78 + seg[..., None] * 0.2 + c.noise(6)[..., None] * 0.25))
    c.paint(ringm * np.clip(1.0 - np.abs(((ang / (np.pi / 7) + 0.5) % 1.0) - 0.5) * 2 / 0.14, 0, 1), "#16100e", 0.8)
    c.paint(c.ring(cx, cy, r + 9.2, 1.6), "#16100e", 0.9)
    inner = (c.dist(cx, cy, r) < 1.0).astype(F)
    c.paint(np.clip((1.0 - c.dist(cx, cy, r)) * r, 0, 1), "#070808")
    c.paint(inner * np.clip((c.yy - cy - 3) / 12.0, 0, 1) * 0.5, "#1c2a1e")       # 속에 고인 물빛
    c.paint(c.ring(cx, cy, r, 1.6), "#16100e", 0.95)
    if grate:
        for gx in (-9, -3, 3, 9):
            c.paint(c.rect(cx + gx - 1.3, cy - r, cx + gx + 1.3, cy + r) * inner, "#3a3432")
            c.paint(c.rect(cx + gx - 1.3, cy - r, cx + gx - 0.5, cy + r) * inner, "#6a5a4c", 0.6)
        c.paint(c.rect(cx - r, cy - 1.3, cx + r, cy + 1.3) * inner, "#3a3432")
    stain = np.clip(1.0 - np.abs(c.xx - cx) / (9 + (c.yy - cy) * 0.12), 0, 1) * (c.yy > cy + r - 2) * (0.5 + c.noise(5, seed + 2) * 0.6)
    c.paint(np.clip(stain, 0, 1) * 0.6, "#1e2a1a")
    if flow:
        wig = np.sin(c.yy * 0.5 + f * 1.6) * 0.8
        fall = np.clip(1.0 - np.abs(c.xx - cx - wig) / 3.6, 0, 1) * (c.yy > cy + r - 7) * (c.yy < c.h - 5)
        c.paint(fall * 0.8, "#5c7074")
        glint = np.clip(1.0 - np.abs(c.xx - cx - wig + 1.0) / 1.0, 0, 1) * (((c.yy * 0.25 + f * 0.9) % 2.0) < 1.0) * (fall > 0.2)
        c.paint(glint * 0.8, "#b8c8c8")
        c.paint(c.blob(cx, c.h - 5, 15 + f % 2, 4.5, 0.25, 6, 0.3, seed=seed + f) * 0.8, "#4c6064")
        c.paint(c.ring(cx, c.h - 5, 9 + f * 1.6, 1.1, ry=2.6 + f * 0.5) * 0.7, "#a8b8b8")
    c.origin = (cx, c.h - 2)


# ── 덩어리로 빚는 벽 조각(원점 = 벽 밑동 가운데, 벽면 = y 0) ─────────────────────

@prop("wall_pilaster", "wall", layer="wall_decal", cell=(2, 4), name_ko="벽기둥(버팀기둥)", tags=["wall", "connector"],
    variants={"plain": {}, "broken": {"state": "broken"}}, meta={"mount": "face", "note": "벽면 이음매 · T자 연결부를 가린다"})
def wall_pilaster(k, state="plain", seed=1):
    body = lambda p: np.minimum.reduce([box(p, v3(0, -0.07, WALL_H / 2), (0.2, 0.09, WALL_H / 2), 0.015), box(p, v3(0, -0.09, 0.14), (0.26, 0.12, 0.14), 0.02), box(p, v3(0, -0.09, WALL_H - 0.1), (0.26, 0.12, 0.1), 0.02)])
    if state == "broken":
        k.add(cut_above(rough(body, 0.025, 0.25, seed), 1.3, 0.4, 0.25, seed, 0.8), "masonry")
        k.rubble([(0.35, -0.3), (-0.3, -0.34), (0.1, -0.42)], "stone", 0.05, 0.1)
    else:
        k.add(rough(body, 0.02, 0.25, seed), "masonry")
    return {"foot": 0.9}


@prop("wall_ruin", "wall", cell=(3, 4), collide=(0.0 - 0.5, -0.05, 1.0, 0.45), name_ko="무너진 벽", tags=["wall", "damage", "ruin"],
    variants={"left": {"state": "left"}, "right": {"state": "right"}, "low": {"state": "low"}, "heap": {"state": "heap"}, "gap": {"state": "gap"}},
    meta={"note": "left · right = 그쪽에서 높게 서 있다가 무너져 내린 벽 한 칸(벽면 줄 끝에 잇는다) · low = 낮게 남은 밑동 · heap = 돌무더기(지나갈 수 없다) · gap = 양쪽이 남고 가운데가 터졌다"})
def wall_ruin(k, state="left", seed=1):
    wall = lambda p: box(p, v3(0, 0.2, WALL_H / 2), (0.5, 0.2, WALL_H / 2))
    n = lambda p: (sdf.fbm(p * np.array([1, 0.3, 1], F), 0.3, seed, 3) - 0.5)
    if state in ("left", "right"):
        s = 1.0 if state == "left" else -1.0
        top = lambda p: 1.35 - s * p[:, 0] * 2.5 + n(p) * 1.1
    elif state == "low":
        top = lambda p: 0.6 + n(p) * 0.8
    elif state == "gap":
        top = lambda p: 0.25 + np.abs(p[:, 0]) * 5.0 + n(p) * 1.0
    else:
        top = None
    if top is not None:
        k.add(rough(lambda p: np.maximum(wall(p), p[:, 2] - np.clip(top(p), 0.12, 9.0)), 0.035, 0.22, seed), "masonry")
    pts = k.scatter(9 if state != "heap" else 6, 0.62, 0.3, 0.0, -0.3)
    k.rubble(pts, "stone", 0.06, 0.13)
    if state == "heap":
        k.add(rough(lambda p: smin(sdf.ell(p, v3(0, 0.1, 0.0), (0.6, 0.38, 0.5)), sdf.ell(p, v3(0.25, 0.05, 0.0), (0.35, 0.3, 0.3)), 0.1), 0.2, 0.2, seed), "masonry")
        for i, (x, y, z, a) in enumerate(((-0.3, -0.25, 0.14, 0.4), (0.38, -0.2, 0.12, -0.5), (0.05, -0.05, 0.5, 0.9), (-0.2, 0.1, 0.4, 2.0))):
            k.add(rough(lambda p, x=x, y=y, z=z, a=a: box(rot_z(p, a, (x, y, z)), v3(x, y, z), (0.2, 0.13, 0.11), 0.03), 0.04, 0.15, seed + i), "stone")
    else:
        for i, (x, y, a) in enumerate(((0.3, -0.34, 0.5), (-0.36, -0.28, -0.3))):
            k.add(rough(lambda p, x=x, y=y, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.1), (0.19, 0.12, 0.1), 0.03), 0.04, 0.15, seed + i), "stone")
    return {"foot": 1.0}


def _bars(k, x0, x1, n, h, y=0.0, r=0.03, mat="iron", skip=(), bend=()):
    for i in range(n):
        if i in skip:
            continue
        x = x0 + (x1 - x0) * i / (n - 1)
        if i in bend:
            k.add(lambda p, x=x: np.minimum(cap(p, v3(x, y, 0.05), v3(x - 0.14, y - 0.12, h * 0.5), r), cap(p, v3(x - 0.14, y - 0.12, h * 0.5), v3(x, y, h), r)), mat)
        else:
            k.add(lambda p, x=x: cap(p, v3(x, y, 0.05), v3(x, y, h), r), mat)


@prop("bars", "wall", cell=(3, 4), collide=(-0.5, -0.12, 1.0, 0.24), name_ko="감옥 철창", tags=["wall", "prison", "iron"], interact="door",
    variants={"panel": {}, "rusty": {"state": "rusty"}, "bent": {"state": "bent"}, "door": {"state": "door"}, "door_open": {"state": "door_open"}, "post": {"state": "post"}},
    meta={"tile_w": 1, "states": {"closed": "door", "open": "door_open"}, "note": "한 칸 폭 — 옆으로 이어 붙인다. post = 칸 사이 돌기둥"})
def bars(k, state="panel", seed=1):
    h = 2.3
    mat = "rust" if state == "rusty" else "iron"
    if state == "post":
        k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, WALL_H / 2), (0.15, 0.15, WALL_H / 2), 0.02), np.minimum(box(p, v3(0, 0, 0.12), (0.2, 0.2, 0.12), 0.02), box(p, v3(0, 0, WALL_H - 0.08), (0.2, 0.2, 0.08), 0.02))), 0.02, 0.25, seed), "masonry")
        return {}
    k.add(rough(lambda p: box(p, v3(0, 0, 0.04), (0.5, 0.12, 0.04), 0.01), 0.015, 0.2, seed), "stone_d")
    k.add(rough(lambda p: box(p, v3(0, 0, h + 0.1), (0.5, 0.12, 0.1), 0.015), 0.015, 0.2, seed + 1), "stone_d")
    rail = lambda z, a=-0.5, b=0.5, y=0.0: (lambda p: box(p, v3((a + b) / 2, y, z), ((b - a) / 2, 0.022, 0.035)))
    if state in ("panel", "rusty", "bent"):
        _bars(k, -0.42, 0.42, 6, h, 0.0, 0.03, mat, (), (2, 3) if state == "bent" else ())
        for z in (0.45, 1.75):
            k.add(rail(z), mat)
        return {}
    # 문: 문틀 살 둘 + 문짝(살 넷 · 가로대 셋 · 자물쇠 판)
    for x in (-0.44, 0.44):
        k.add(lambda p, x=x: cap(p, v3(x, 0, 0.05), v3(x, 0, h), 0.045), mat)
    k.add(rail(2.0), mat)
    _bars(k, -0.44, 0.44, 7, h, 0.0, 0.026, mat, (1, 2, 3, 4, 5))
    for x in (-0.3, 0.3):
        k.add(lambda p, x=x: cap(p, v3(x, 0, 2.0), v3(x, 0, h), 0.026), mat)
    ang = 1.25 if state == "door_open" else 0.0
    hinge = (-0.4, 0.0, 0.0)
    door = lambda fn: (lambda p: fn(rot_z(p, -ang, hinge)))
    for i in range(4):
        x = -0.36 + i * 0.235
        k.add(door(lambda p, x=x: cap(p, v3(x, -0.03, 0.12), v3(x, -0.03, 1.9), 0.026)), mat)
    for z in (0.14, 1.0, 1.9):
        k.add(door(lambda p, z=z: box(p, v3(0, -0.03, z), (0.38, 0.02, 0.035))), mat)
    k.add(door(lambda p: box(p, v3(0.3, -0.05, 1.0), (0.08, 0.035, 0.11), 0.01)), "rust")
    return {"foot": 1.3 if state == "door_open" else 0.75}


def _door_leaf(k, x0, x1, z1, kind, fn_wrap, y=0.06, seed=1, arch_r=0.0):
    """문짝 한 장(x0~x1, 높이 z1). kind = wood · iron."""
    cx, hw = (x0 + x1) / 2, (x1 - x0) / 2
    if arch_r > 0:
        leaf = lambda p: np.maximum(box(p, v3(cx, y, z1 / 2), (hw, 0.035, z1 / 2), 0.005), np.hypot(p[:, 0], np.maximum(p[:, 2] - (z1 - arch_r), 0)) - arch_r)
    else:
        leaf = lambda p: box(p, v3(cx, y, z1 / 2), (hw, 0.035, z1 / 2), 0.005)
    if kind == "wood":
        k.add(fn_wrap(lambda p: leaf(p) + np.abs(np.sin((p[:, 0] - x0) * 3.14159 / 0.15)) * 0.006), k.mat("door_wood", M.wood("#4e3b2a", 0.15, 2, 7)))
        for z in (0.28, z1 - 0.42):
            k.add(fn_wrap(lambda p, z=z: box(p, v3(cx, y - 0.04, z), (hw - 0.01, 0.014, 0.045))), "iron")
            for sx in np.linspace(x0 + 0.07, x1 - 0.07, 3):
                k.add(fn_wrap(lambda p, z=z, sx=sx: sphere(p, v3(sx, y - 0.055, z), 0.022)), "steel")
    else:
        k.add(fn_wrap(leaf), k.mat("door_iron", M.metal("#45474c", "#6a4630", 13, 0.45)))
        for z in (0.12, z1 * 0.5, z1 - 0.3):
            k.add(fn_wrap(lambda p, z=z: box(p, v3(cx, y - 0.04, z), (hw - 0.01, 0.012, 0.05))), "iron")
            for sx in np.linspace(x0 + 0.06, x1 - 0.06, 4):
                k.add(fn_wrap(lambda p, z=z, sx=sx: sphere(p, v3(sx, y - 0.052, z), 0.02)), "steel")


@prop("doorway", "wall", cell=(3, 4), collide=[(-0.5, -0.05, 0.16, 0.45), (0.34, -0.05, 0.16, 0.45)], name_ko="문틀과 문", tags=["wall", "passage", "door"], interact="door",
    variants={"open": {}, "wood": {"state": "wood"}, "wood_ajar": {"state": "wood_ajar"}, "wood_broken": {"state": "wood_broken"}, "iron": {"state": "iron"}, "iron_ajar": {"state": "iron_ajar"},
        "portcullis": {"state": "portcullis"}, "portcullis_up": {"state": "portcullis_up"}, "bricked": {"state": "bricked"}},
    meta={"tile_w": 1, "passage": True, "states": {"closed": "wood", "open": "wood_ajar", "broken": "wood_broken"},
        "note": "벽면 줄의 한 칸을 대신한다(다듬은 돌 문틀이라 어느 벽 종류에도 맞는다). 닫힌 변형은 가운데도 막는다"})
def doorway(k, state="open", seed=1):
    ow, oh = 0.34, 1.72   # 문구멍 반폭 · 높이(둥근 머리 포함)
    hole = lambda p: np.maximum(np.maximum(np.abs(p[:, 0]) - ow, p[:, 2] - (oh - ow)), -1e9) * 0 + np.minimum(np.maximum(np.abs(p[:, 0]) - ow, p[:, 2] - (oh - ow)), np.hypot(p[:, 0], p[:, 2] - (oh - ow)) - ow)
    block = lambda p: box(p, v3(0, 0.2, WALL_H / 2), (0.5, 0.2, WALL_H / 2), 0.01)
    trim = lambda p: np.maximum(np.maximum(hole(p) - 0.11, -hole(p)), np.abs(p[:, 1] + 0.02) - 0.06)   # 문구멍을 두른 돋은 테
    k.add(rough(lambda p: sub(block(p), np.maximum(hole(p), p[:, 1] - 0.34)), 0.02, 0.25, seed), "masonry")
    k.add(rough(trim, 0.012, 0.2, seed + 1), "stone_l")
    k.add(lambda p: box(p, v3(0, 0.3, 0.9), (ow + 0.02, 0.02, 0.9)), "void")
    k.add(rough(lambda p: box(p, v3(0, 0.02, 0.025), (ow + 0.1, 0.1, 0.025), 0.01), 0.01, 0.2, seed + 2), "stone_d")
    ident = lambda fn: fn
    if state in ("wood", "iron"):
        _door_leaf(k, -ow, ow, oh, state, ident, 0.1, seed, ow)
        k.add(lambda p: sdf.length(np.stack([p[:, 0] - 0.2, (p[:, 1] - 0.04) * 2.0, p[:, 2] - 0.85], 1)) - 0.045, "brass")
    elif state in ("wood_ajar", "iron_ajar"):
        swing = lambda fn: (lambda p: fn(rot_z(p, -1.2, (-ow, 0.1, 0))))
        _door_leaf(k, -ow, ow, oh, state.split("_")[0], swing, 0.1, seed, ow)
    elif state == "wood_broken":
        for i, (x, z1, lean) in enumerate(((-0.27, 1.25, 0.05), (-0.13, 0.7, -0.08))):
            k.add(lambda p, x=x, z1=z1, lean=lean: box(rot_y(p, lean, (x, 0.1, 0)), v3(x, 0.1, z1 / 2), (0.065, 0.03, z1 / 2), 0.005) + sdf.noise(p, 0.05, seed + i) * 0.012 * (p[:, 2] > z1 - 0.2), k.mat("door_wood", M.wood("#4e3b2a", 0.15, 2, 7)))
        for i, (x, y, a) in enumerate(((0.1, -0.3, 0.5), (0.3, -0.42, -0.3), (-0.2, -0.45, 1.3))):
            k.add(lambda p, x=x, y=y, a=a: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.03), (0.22, 0.06, 0.025), 0.005), "door_wood")
        k.add(lambda p: box(rot_z(p, 0.3, (0.05, -0.35, 0)), v3(0.05, -0.35, 0.065), (0.2, 0.012, 0.03)), "iron")
    elif state in ("portcullis", "portcullis_up"):
        z0 = 0.0 if state == "portcullis" else 1.15
        for x in np.linspace(-ow + 0.06, ow - 0.06, 5):
            k.add(lambda p, x=x: np.minimum(cap(p, v3(x, 0.12, z0 + 0.1), v3(x, 0.12, oh), 0.026), sdf.cone(rot_x(p, np.pi, (x, 0.12, z0 + 0.1)), v3(x, 0.12, z0 + 0.1), 0.045, 0.1)), "iron")
        for z in np.arange(z0 + 0.3, oh, 0.32):
            k.add(lambda p, z=z: box(p, v3(0, 0.12, z), (ow, 0.02, 0.028)), "iron")
    elif state == "bricked":
        k.add(rough(lambda p: np.maximum(hole(p) + 0.01, np.abs(p[:, 1] - 0.14) - 0.06), 0.025, 0.12, seed + 5), "brick")
    return {"foot": 1.2}


@prop("gateway", "wall", cell=(4, 4), collide=[(-1.0, -0.05, 0.28, 0.45), (0.72, -0.05, 0.28, 0.45)], name_ko="아치형 통로", tags=["wall", "passage", "door"], interact="door",
    variants={"open": {}, "doors": {"state": "doors"}, "doors_open": {"state": "doors_open"}, "barred": {"state": "barred"}, "collapsed": {"state": "collapsed"}},
    meta={"tile_w": 2, "passage": True, "states": {"closed": "doors", "open": "doors_open"}, "note": "벽면 줄의 두 칸을 대신하는 큰 아치 통로"})
def gateway(k, state="open", seed=1):
    ow, spring = 0.7, 1.35
    hole = lambda p: np.minimum(np.maximum(np.abs(p[:, 0]) - ow, p[:, 2] - spring), np.hypot(p[:, 0], p[:, 2] - spring) - ow)
    block = lambda p: box(p, v3(0, 0.2, WALL_H / 2), (1.0, 0.2, WALL_H / 2), 0.01)
    k.add(rough(lambda p: sub(block(p), np.maximum(hole(p), p[:, 1] - 0.34)), 0.02, 0.25, seed), "masonry")
    ringm = k.mat("vous", M.masonry("#8a877d", 0.3, 0.3, None, 5))
    k.add(rough(lambda p: np.maximum(np.maximum(hole(p) - 0.15, -hole(p)), np.abs(p[:, 1] + 0.03) - 0.07), 0.015, 0.2, seed + 1), ringm)
    k.add(rough(lambda p: box(p, v3(0, -0.05, spring + ow + 0.1), (0.1, 0.1, 0.17), 0.02), 0.012, 0.2, seed + 2), "stone_l")
    k.add(lambda p: box(p, v3(0, 0.3, 1.1), (ow + 0.02, 0.02, 1.1)), "void")
    if state == "doors":
        for s in (-1, 1):
            _door_leaf(k, min(0, s * ow), max(0, s * ow), spring + ow, "wood", lambda fn: (lambda p: np.maximum(fn(p), hole(p) + 0.01)), 0.1, seed)
        k.add(lambda p: box(p, v3(0, 0.04, 0.95), (0.3, 0.03, 0.05), 0.01), "wood_d")
    elif state == "doors_open":
        for s in (-1, 1):
            hx = s * ow
            _door_leaf(k, min(0, s * ow), max(0, s * ow), spring + 0.25, "wood", lambda fn, s=s, hx=hx: (lambda p: fn(rot_z(p, s * 1.25, (hx, 0.1, 0)))), 0.1, seed)
    elif state == "barred":
        for x in np.linspace(-ow + 0.08, ow - 0.08, 8):
            k.add(lambda p, x=x: np.maximum(cap(p, v3(x, 0.12, 0.0), v3(x, 0.12, 2.2), 0.028), hole(p)), "iron")
        for z in (0.35, 1.0, 1.65):
            k.add(lambda p, z=z: np.maximum(box(p, v3(0, 0.12, z), (ow, 0.02, 0.03)), hole(p)), "iron")
    elif state == "collapsed":
        k.add(rough(lambda p: np.maximum(hole(p) + 0.02, np.maximum(np.abs(p[:, 1] - 0.1) - 0.3, p[:, 2] - 1.15 + np.abs(p[:, 0]) * 0.7 - sdf.fbm(p, 0.25, seed, 2) * 0.7)), 0.12, 0.16, seed + 4), "masonry")
        k.rubble(k.scatter(9, 0.8, 0.25, 0, -0.35), "stone", 0.06, 0.14)
    return {"foot": 1.3 if state == "doors_open" else 1.0}
