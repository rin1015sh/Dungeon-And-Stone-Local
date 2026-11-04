"""동네 바닥 굽기 보탬(CT111 — 2026-11-04 사용자 "보도블록은 위에서 본 사각형 · 너무 일정해서 현실감이 떨어진다 · 건물 단과 맞물리지 않는다 ·
계단이 비현실적이고 입체감이 없다 · 마을 외곽은 성벽으로 · 길 · 성벽 텍스처가 깨진 부분"). tools/town_ground_bake.py가 부른다.
  pavers       = 위에서 본 네모 보도블록(돌마다 크기 · 색 · 닳음이 다르고, 가끔 두 장 · 네 장 붙은 큰 판 · 빠진 돌 · 금 간 돌 · 모서리 빛)
  house_walks  = 집 둘레 보도를 그 집 벽 방향으로 깐다(기운 집도 벽에 줄이 맞는다) + 바깥 연석 한 줄
  treads       = 계단 디딤판(단마다 긴 돌 · 앞 모서리 밝게 · 뒤 그늘)
  stair_walls  = 계단 양옆 난간 벽(경사 따라 올라가는 갓돌 · 아래 끝 기둥)
  border_wall  = 지도 둘레 빈 칸(북 · 동 · 서)과 성벽 칸을 성벽으로(걷는 길 판석 + 바깥 성가퀴 — 3/4로 올리면 성가퀴마다 앞면이 생긴다)
"""
import numpy as np

import town_ground_bake as gb  # 무늬 붓(hash2 · noise · fbm · stone_fill · mortar · ink_line) — 부를 때 쓴다(순환 import 피하기)


def hash2(*a):
    return gb.hash2(*a)


def noise(*a):
    return gb.noise(*a)


def fbm(*a):
    return gb.fbm(*a)


def stone_fill(*a):
    return gb.stone_fill(*a)


def mortar(*a):
    return gb.mortar(*a)


def ink_line(*a, **k):
    return gb.ink_line(*a, **k)

STONES = (np.array([1.0, 1.0, 1.0], np.float32), np.array([1.04, 1.0, 0.94], np.float32), np.array([0.95, 0.98, 1.02], np.float32),
          np.array([0.9, 0.89, 0.87], np.float32))


def pavers(xs, ys, base, size, seed, var=0.1, moss=0.08, big=0.1, pair=0.16):
    """네모 보도블록(위에서 본 것): size px 격자 — 2×2 큰 판(big) · 가로 두 장(pair) · 빠진 돌 · 금 · 돌 종류 넷 · 모서리 빛과 그늘."""
    gx = np.floor(xs / size).astype(np.int64)
    gy = np.floor(ys / size).astype(np.int64)
    bx, by = gx // 2, gy // 2
    is_big = hash2(bx, by, seed + 1) < big
    px_ = gx // 2
    is_pair = ~is_big & (hash2(px_, gy, seed + 2) < pair)
    x0 = np.where(is_big | is_pair, (gx // 2) * 2, gx).astype(np.float32) * size
    w = np.where(is_big | is_pair, 2.0, 1.0).astype(np.float32) * size
    y0 = np.where(is_big, (gy // 2) * 2, gy).astype(np.float32) * size
    h = np.where(is_big, 2.0, 1.0).astype(np.float32) * size
    cid = np.where(is_big, bx * 7919 + by * 104729 + 3, np.where(is_pair, px_ * 7919 + gy * 104729 + 1, gx * 7919 + gy * 104729))
    fu = (xs - x0) / w
    fv = (ys - y0) / h
    jit = (noise(xs, ys, 5, seed + 4) - 0.5) * 1.2
    edge = np.minimum(np.minimum(fu, 1 - fu) * w, np.minimum(fv, 1 - fv) * h) + jit
    lit = np.clip(-((fu - 0.5) + (fv - 0.5)) * 0.9, -1, 1)
    col = stone_fill(xs, ys, base, cid, lit * 0.35, seed, var)
    kind = np.floor(hash2(cid, cid * 5, seed + 6) * 10).astype(np.int64)
    tint = np.where(kind < 6, 0, np.where(kind < 8, 1, np.where(kind < 9, 2, 3)))
    col = col * np.stack(STONES)[tint]
    col = col * (0.86 + 0.22 * fbm(xs, ys, 260, seed + 40, 2))[..., None]  # 넓은 얼룩(젖은 곳 · 마른 곳)
    tl = (np.minimum(fu * w, fv * h) < 2.6) & (edge > 0.6)  # 왼쪽 위 모서리 빛 · 오른쪽 아래 그늘(돌이 도드라진다)
    br = (np.minimum((1 - fu) * w, (1 - fv) * h) < 3.0) & (edge > 0.6)
    col[tl] *= 1.14
    col[br] *= 0.74
    m = edge < 0.75 + 0.5 * noise(xs, ys, 7, seed + 8)
    col[m] = mortar(xs, ys, seed, moss)[m]
    ink = ink_line(xs, ys, edge, 0.85, seed + 30, 0.5)
    gone = hash2(cid, cid * 11, seed + 12) < 0.012  # 빠진 돌(흙 · 잔돌)
    if gone.any():
        dirt = np.array([0.24, 0.2, 0.15], np.float32) * (0.8 + 0.4 * noise(xs, ys, 2.5, seed + 13))[..., None]
        col[gone] = dirt[gone]
        ink[gone] = np.where(edge[gone] < 1.4, 0.6, 0.0)
    crack = (hash2(cid, cid * 13, seed + 14) < 0.06) & (np.abs((fu - 0.5) * 1.3 - (fv - 0.5) + (noise(xs, ys, 6, seed + 15) - 0.5) * 0.25) < 0.018)
    ink[crack] = np.maximum(ink[crack], 0.65)
    return col, ink


def treads(xs, ys, base, q, seed):
    """계단 디딤판: q = 높이 / 턱(정수 = 단 번호, 소수 = 단 안 자리 — 0 쪽이 앞(남) 모서리). 단마다 길이가 다른 긴 돌."""
    row = np.floor(q).astype(np.int64)
    t = (q - row).astype(np.float32)
    L = 40.0 + hash2(row, row * 3, seed + 1) * 36.0
    off = hash2(row, row, seed) * L
    u = (xs + off) / L
    ci = np.floor(u).astype(np.int64)
    cid = row * 100003 + ci
    fu = u - ci
    jit = (noise(xs, ys, 6, seed + 4) - 0.5) * 1.0
    edge = np.minimum(fu, 1 - fu) * L + jit
    col = stone_fill(xs, ys, base, cid, np.zeros_like(xs), seed, 0.1)
    col = col * (1.0 + 0.2 * np.clip(0.16 - t, 0, 0.16) / 0.16)[..., None]  # 앞 모서리(닳아 밝다)
    col = col * (1.0 - 0.38 * np.clip(t - 0.62, 0, 0.38) / 0.38)[..., None]  # 뒤(다음 단 밑 그늘)
    m = edge < 0.8
    col[m] = mortar(xs, ys, seed, 0.06)[m]
    ink = ink_line(xs, ys, edge, 0.8, seed + 30, 0.45)
    nose = t < 0.06
    ink[nose] = np.maximum(ink[nose], 0.75)
    return col, ink


def stair_walls(st, hv, kind, K, step):
    """계단 양옆 난간: 계단 칸 가장자리 PW px를 경사 따라 높인다(+0.32칸 — 갓돌) · 아래 끝 기둥(+0.55칸). (높이, 난간 마스크) 를 돌려준다."""
    PW = 12
    left = np.zeros_like(st)
    right = np.zeros_like(st)
    for d in range(1, PW + 1):
        left[:, d:] |= ~st[:, :-d]
        right[:, :-d] |= ~st[:, d:]
    side = st & (left | right)
    bottom = np.zeros_like(st)
    for d in range(1, 15):
        bottom[:-d] |= ~st[d:]
    add = np.where(side, 0.32, 0.0) + np.where(side & bottom, 0.23, 0.0)
    return add.astype(np.float32), side


def border_wall(kind, K, cw, ch, PX, hmap):
    """둘레 성벽: 지도 가장자리 2칸 안의 빈 칸(void) · 성벽 칸 → 성벽(걷는 길 +1.5칸, 바깥 끝 성가퀴 +0.45칸 — 44px 마다 26px).
    성문 칸(gate)은 성벽보다 0.5칸 높은 문루. 남쪽 성벽(지도 아래 소품 citywall)이 선 곳은 성벽 밑 둑(흙 — 높이 그대로)."""
    H, W = kind.shape
    ys, xs = np.mgrid[0:H, 0:W]
    edge = (xs < 2 * PX) | (xs >= (cw - 2) * PX) | (ys < 2 * PX)
    wall = edge & np.isin(kind, [K["void"], K["wall"]])
    gate = edge & (kind == K["gate"])
    # 탑: 성벽 따라 12칸마다 2칸 — 0.8칸 더 높고 둘레에 성가퀴(벽 높이가 고르지 않게)
    tower = wall & ((((ys < 2 * PX) & ((xs // PX) % 12 >= 5) & ((xs // PX) % 12 < 7))) |
                    ((ys >= 2 * PX) & ((ys // PX) % 12 >= 5) & ((ys // PX) % 12 < 7)))
    merlon = np.zeros_like(wall)
    out_w = 22
    merlon |= wall & (ys < out_w) & ((xs % 44) < 26)
    merlon |= wall & (xs < out_w) & ((ys % 44) < 26) & (ys >= out_w)
    merlon |= wall & (xs >= W - out_w) & ((ys % 44) < 26) & (ys >= out_w)
    tring = tower & ~edge_shrink(tower, 16) & (((xs + ys) % 40) < 24)
    merlon |= tring
    inner = wall & ~edge_shrink(wall, 6)  # 안쪽 가장자리(갓돌 띠)
    add = np.where(wall, 2.0, 0.0) + np.where(tower, 0.8, 0.0) + np.where(merlon, 0.45, 0.0) + np.where(gate, 2.6, 0.0)
    gate_merlon = gate & (((xs % 40) < 22) & ((ys < 2 * PX) | (xs < 2 * PX)))
    add = add + np.where(gate_merlon & (ys < 18) | gate_merlon & (xs < 18), 0.4, 0.0)
    return add.astype(np.float32), wall, merlon, gate, inner


def shrink_x(m, n):
    """가로로만 n px 깎는다(성문 앞면 아치 — 기둥 폭)."""
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[:, 1:] &= out[:, :-1]
        g[:, :-1] &= out[:, 1:]
        out = g
    return out


def edge_shrink(m, n):
    out = m.copy()
    for _ in range(n):
        g = out.copy()
        g[1:] &= out[:-1]
        g[:-1] &= out[1:]
        g[:, 1:] &= out[:, :-1]
        g[:, :-1] &= out[:, 1:]
        out = g
    return out
