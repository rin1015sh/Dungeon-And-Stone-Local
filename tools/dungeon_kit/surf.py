"""던전 에셋 키트 — 이어지는 면 그림 부품(바닥 · 벽면). tools/f2_art/tex.py(사방으로 이어지는 잡음 · 돌 조각 · 낱 조각 찍기) 위에
돌 쌓기 배치(마름돌 줄 · 벽돌 · 판석)와 돌 칠하기를 더한다. 모든 배열은 tex.W × tex.W(= 낼 256px의 2배), 사방으로 이어진다."""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "f2_art"))
import tex  # noqa: E402
from tex import W, fbm, hexc, pnoise, relief  # noqa: E402,F401

F = np.float32


def courses(seed, rows, lmin, lmax, wob=2.5, bond=True, yjit=0.12):
    """줄 쌓기 배치(마름돌 · 벽돌 · 판석 줄): rows 줄, 돌 길이 lmin~lmax(W px). → (돌 번호, 가장자리까지 거리 px, 줄 번호).
    줄 높이 · 돌 길이가 조금씩 다르고 경계가 손으로 깎은 듯 흔들린다. 사방으로 이어진다."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    wx = (xx + (fbm(20, seed + 1, 2) - 0.5) * wob * 2) % W
    wy = (yy + (fbm(20, seed + 2, 2) - 0.5) * wob * 2) % W
    hs = 1.0 + rng.uniform(-yjit, yjit, rows)
    ycut = np.concatenate([[0.0], np.cumsum(hs / hs.sum() * W)])
    ycut[-1] = W
    row = np.clip(np.searchsorted(ycut, wy, side="right") - 1, 0, rows - 1)
    cell = np.zeros((W, W), np.int32)
    edge = np.zeros((W, W), F)
    nid = 0
    for r in range(rows):
        n = max(2, int(round(W / rng.uniform(lmin, lmax))))
        ws = 1.0 + rng.uniform(-0.3, 0.3, n)
        cuts = np.concatenate([[0.0], np.cumsum(ws / ws.sum() * W)])
        cuts[-1] = W
        off = (r % 2) * (W / n) * 0.5 if bond else 0.0
        off += rng.uniform(0, W / n * 0.35)
        m = row == r
        rel = (wx[m] - off) % W
        i = np.clip(np.searchsorted(cuts, rel, side="right") - 1, 0, n - 1)
        cell[m] = nid + i
        edge[m] = np.minimum(np.minimum(rel - cuts[i], cuts[i + 1] - rel), np.minimum(wy[m] - ycut[r], ycut[r + 1] - wy[m]))
        nid += n
    return cell, edge, row


def squares(n, wob=1.5, seed=1):
    """n × n 정사각 판(의식용 바닥) → (돌 번호, 가장자리까지 거리, 판 안 좌표 u · v −1~1)."""
    yy, xx = np.mgrid[0:W, 0:W].astype(F)
    wx = (xx + (fbm(16, seed + 1, 2) - 0.5) * wob * 2) % W
    wy = (yy + (fbm(16, seed + 2, 2) - 0.5) * wob * 2) % W
    s = W / n
    ix, iy = np.floor(wx / s), np.floor(wy / s)
    fx, fy = wx / s - ix, wy / s - iy
    edge = np.minimum(np.minimum(fx, 1 - fx), np.minimum(fy, 1 - fy)) * s
    return (ix + iy * n).astype(np.int32), edge, fx * 2 - 1, fy * 2 - 1


def stonework(cell, edge, base, gap_col, seed, gap_w=3.0, var=0.14, bevel=1.0, hue=0.022, pit=0.5):
    """돌 칠하기: 돌마다 밝기 · 색이 조금 다르고, 틈은 어둡고, 왼쪽 위 모서리가 빛을 받는다 → (그림 W × W × 3, 틈 마스크, 높이장)."""
    edge = edge + (fbm(40, seed + 2, 2) - 0.5) * gap_w * 1.4
    rng = np.random.default_rng(seed + 1)
    n = int(cell.max()) + 1
    tone = 1.0 + (rng.random(n).astype(F) - 0.5) * 2 * var
    hues = (rng.random((n, 3)).astype(F) - 0.5) * hue
    img = base[None, None, :] * tone[cell][..., None] + hues[cell]
    img = img * (1.0 + (fbm(10, seed + 4, 3) - 0.5) * 0.24)[..., None]
    img = img * (1.0 + (fbm(3, seed + 5, 2) - 0.5)[..., None] * np.array([0.07, 0.0, -0.07], F))   # 따뜻하고 찬 번짐
    h = np.clip(edge / (gap_w * 3.0), 0, 1) ** 0.6 + fbm(28, seed + 6, 2) * 0.22
    pits = np.clip((pnoise(96, seed + 7) - 0.86) * 8.0, 0, 1) * pit                                # 곰보 자국
    h = h - pits * 0.25
    img = img * relief(h, 1.6 * bevel)[..., None] * (1 - pits[..., None] * 0.35)
    gap = np.clip(1.0 - edge / gap_w, 0, 1)
    img = img * (1 - gap[..., None]) + gap_col[None, None, :] * gap[..., None]
    return img, gap, h


def crack_lines(ly, rng, n, length, col=tex.SHADOW, width=2.4, branch=0.16, step=13.0):
    """금(가지 치는 꺾은 선)을 판에 찍는다 — 어두운 금 + 오른쪽 아래 밝은 턱. → 금이 지난 점 목록."""
    pts_all = []

    def run(x, y, a, ln, w, depth):
        pts = [(x, y)]
        for k in range(max(2, int(ln / step))):
            a += rng.uniform(-0.42, 0.42)
            x, y = x + np.cos(a) * step, y + np.sin(a) * step
            pts.append((x, y))
            if depth > 0 and rng.random() < branch:
                run(x, y, a + rng.choice([-1, 1]) * rng.uniform(0.5, 1.2), ln * rng.uniform(0.25, 0.5), w * 0.6, depth - 1)
        ly.line([(px + 1.4, py + 1.6) for px, py in pts], np.array([0.62, 0.58, 0.5], F), 0.22, w)
        ly.line(pts, col, 0.92, w)
        pts_all.extend(pts)
    for _ in range(n):
        run(rng.random() * W, rng.random() * W, rng.uniform(0, 6.28), length * rng.uniform(0.6, 1.3), width * rng.uniform(0.8, 1.4), 1)
    return pts_all


def mix(img, mask, color, k=1.0):
    return img * (1 - mask[..., None] * k) + (color[None, None, :] if color.ndim == 1 else color) * (mask * k)[..., None]


def _grade(img, desat, seed):
    from PIL import Image
    lum = (img @ np.array([0.3, 0.59, 0.11], F))[..., None]
    img = img * (1 - desat) + lum * desat
    img = (img - 0.5) * 1.08 + 0.5
    img = img + (tex.SHADOW - img) * np.clip(0.35 - lum, 0, 1) * 0.35 + (tex.HIGH - img) * np.clip(lum - 0.6, 0, 1) * 0.12
    img = img * (1.0 + (pnoise(128, seed)[..., None] - 0.5) * 0.05)
    return np.asarray(Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((tex.S, tex.S), Image.LANCZOS)).astype(F) / 255.0


def finish(img, mean_hex, seed=1, desat=0.18, ref=None):
    """색 정리(ART.md §2) → 256 × 256 RGB uint8. 평균 밝기를 mean_hex에 맞춘다.
    ref(덧입히기 전 바탕 그림)를 주면 그 바탕의 보정값을 그대로 쓴다 — 같은 돌 배치의 변형끼리 돌 색이 똑같아 이음매가 없다."""
    small = _grade(np.clip(img, 0, 1), desat, seed)
    base = small if ref is None else _grade(np.clip(ref, 0, 1), desat, seed)
    lw = np.array([0.3, 0.59, 0.11], F)
    gl = float(hexc(mean_hex) @ lw) / max(float(base.reshape(-1, 3).mean(0) @ lw), 0.01)
    return (np.clip(small * gl, 0, 1) * 255 + 0.5).astype(np.uint8)
