"""가구 · 생활 물건: 책상 · 탁자 · 의자 · 침대 · 책장 · 선반 · 서랍장 · 상자 · 보물상자 · 나무통 · 바구니 · 무기 · 갑옷 거치대 ·
작업대 · 모루 · 책 · 문서 · 두루마리 · 병 · 식기 · 음식 잔해 · 솥 · 자루 · 배낭 · 보급품 더미."""
import numpy as np

import sdf
from kit import (F, box, cap, chip, cone, cut_above, cyl, disc_x, ell, hcyl, pool, prop, ring_x, rot_x, rot_y, rot_z, rough, smin, sphere, sub, torus, v3)  # noqa: F401
import mats as M

PI = np.pi
BOOKHEX = ("#6a2e2a", "#34425a", "#3e4a36", "#5a3e28", "#3a2a20", "#2a2628", "#7a6a4a")
BOOKMAT = ("cloth_r", "cloth_b", "cloth_g", "leather", "leather_d", "cloth_k", "cloth")


class _X:
    """덩어리 묶음을 통째로 옮기고 돌려 넣는다: T(p) = 세계 점 → 물건 좌표."""

    def __init__(self, k, T):
        self.k, self.T, self.rng, self.mats = k, T, k.rng, k.mats

    def add(self, fn, mat):
        self.k.add(lambda p, fn=fn, T=self.T: fn(T(p)), mat)
        return self

    def mat(self, name, fn):
        return self.k.mat(name, fn)


def _move(k, dx=0.0, dy=0.0, dz=0.0, yaw=0.0):
    return _X(k, lambda p: rot_z(p - v3(dx, dy, dz), yaw))


def _frustum(p, c, r0, r1, h):
    """세운 원뿔대(밑 반지름 r0 → 위 r1)."""
    z = p[:, 2] - c[2]
    r = r0 + (r1 - r0) * np.clip(z / h, 0, 1)
    return np.maximum(np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) - r, np.abs(z - h / 2) - h / 2)


def _page_mat(k):
    base = M.hexc("#b8ac8c")

    def fn(p, n):
        row = np.floor(p[:, 1] / 0.022)
        ink = ((p[:, 1] / 0.022 - row) < 0.4) & (sdf._hash(np.floor(p[:, 0] / 0.03), row, row * 0, 3) > 0.3) & (n[:, 2] > 0.6)
        c = base[None, :] * (0.9 + sdf.noise(p, 0.08, 5)[:, None] * 0.2) * (1 - ink[:, None] * 0.4)
        return c.astype(F), np.zeros(len(p), F), np.zeros(len(p), F)
    return k.mat("page", fn)


def _table(t, w, d, h, seed=1, top="plank_x", leg="wood_d", th=0.04, lr=0.045, apron=True):
    t.add(rough(lambda p: box(p, v3(0, 0, h - th), (w, d, th), 0.012), 0.012, 0.2, seed), top)
    hl = (h - 2 * th) / 2
    for sx in (-1, 1):
        for sy in (-1, 1):
            t.add(lambda p, sx=sx, sy=sy: box(p, v3(sx * (w - 0.08), sy * (d - 0.07), hl), (lr, lr, hl), 0.008), leg)
    if apron:
        t.add(lambda p: np.minimum(box(p, v3(0, -d + 0.07, h - 2 * th - 0.045), (w - 0.1, 0.018, 0.045)), box(p, v3(0, d - 0.07, h - 2 * th - 0.045), (w - 0.1, 0.018, 0.045))), leg)


def _planks(k, pts, mat="plank_x", ln=0.3, seed=1):
    """바닥에 흩어진 부서진 판자."""
    for i, (x, y, a) in enumerate(pts):
        l2 = ln * (0.6 + 0.5 * ((i * 37 + seed) % 5) / 5.0)
        k.add(rough(lambda p, x=x, y=y, a=a, l2=l2: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.025), (l2, 0.05, 0.02), 0.006), 0.012, 0.1, seed + i), mat)


# ── 책상 · 탁자 · 의자 ────────────────────────────────────────────────────────

def _book(t, c, w, d, th, a=0.0, mat="leather"):
    """누운 책 한 권(표지 + 앞 · 오른쪽으로 보이는 종이 단면)."""
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: np.minimum.reduce([box(T(p), v3(c[0], c[1], c[2] + 0.006), (w, d, 0.006)), box(T(p), v3(c[0], c[1], c[2] + 2 * th - 0.006), (w, d, 0.006)),
        box(T(p), v3(c[0] - w + 0.008, c[1], c[2] + th), (0.008, d, th))]), mat)
    t.add(lambda p: box(T(p), v3(c[0] + 0.004, c[1], c[2] + th), (w - 0.012, d - 0.008, th - 0.008)), "paper")


def _open_book(t, c, s=1.0, a=0.0, mat="leather_d"):
    _page_mat(t)
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: box(T(p), v3(c[0], c[1], c[2] + 0.008), (0.17 * s, 0.11 * s, 0.008), 0.004), mat)
    for sx in (-1, 1):
        t.add(lambda p, sx=sx: box(rot_y(T(p), sx * 0.13, (c[0], c[1], c[2] + 0.02)), v3(c[0] + sx * 0.08 * s, c[1], c[2] + 0.03), (0.075 * s, 0.1 * s, 0.014), 0.008), "page")


def _candle(t, x, y, z, h=0.1, r=0.022):
    t.add(lambda p: smin(cyl(p, v3(x, y, z), r, h, 0.006), cyl(p, v3(x, y, z), r * 1.7, 0.012), 0.015), "wax")
    t.add(lambda p: cap(p, v3(x, y, z + h), v3(x, y, z + h + 0.02), 0.004), "coal")


def _bottle(t, x, y, z, r=0.04, h=0.12, mat="glass", neck=0.09):
    t.add(lambda p: smin(cyl(p, v3(x, y, z), r, h, r * 0.4), cap(p, v3(x, y, z + h), v3(x, y, z + h + neck), r * 0.45, r * 0.36), 0.015), mat)
    t.add(lambda p: cyl(p, v3(x, y, z + h + neck), r * 0.34, 0.022), "wood_l")


def _flask(t, x, y, z, r=0.07, mat="glass_r"):
    t.add(lambda p: smin(sphere(p, v3(x, y, z + r * 0.9), r), cap(p, v3(x, y, z + r * 1.6), v3(x, y, z + r * 2.5), r * 0.3, r * 0.26), 0.02), mat)
    t.add(lambda p: torus(p, v3(x, y, z + r * 2.5), r * 0.32, 0.009), mat)
    t.add(lambda p: cyl(p, v3(x, y, z + r * 2.5), r * 0.25, 0.03), "wood_l")


def _plate(t, x, y, z, r=0.09, mat="steel"):
    t.add(lambda p: sub(_frustum(p, v3(x, y, z), r * 0.7, r, 0.022), _frustum(p, v3(x, y, z + 0.01), r * 0.6, r * 0.9, 0.03)), mat)


def _cup(t, x, y, z, r=0.035, h=0.075, mat="steel", handle=True):
    t.add(lambda p: sub(_frustum(p, v3(x, y, z), r * 0.85, r, h), cyl(p, v3(x, y, z + 0.015), r * 0.75, h)), mat)
    if handle:
        t.add(lambda p: np.maximum(ring_x(p, v3(x + r, y, z + h * 0.5), h * 0.3, 0.008), x + r * 0.8 - p[:, 0]), mat)


@prop("desk", "furniture", cell=(3, 3), collide=(1.5, 0.75), tags=["wood", "study"], name_ko="책상",
    variants={"intact": {}, "cluttered": {"state": "cluttered"}, "broken": {"state": "broken"}})
def desk(k, state="intact", seed=1):
    w, d, h = 0.74, 0.34, 0.54
    if state == "broken":   # 왼쪽 다리가 꺾여 상판이 기울고 갈라졌다
        t = _X(k, lambda p: rot_y(p, 0.33, (0.66, 0, 0.0)))
        t.add(rough(lambda p: np.maximum(box(p, v3(0, 0, h - 0.04), (w, d, 0.04), 0.012), -(p[:, 0] + 0.42 + p[:, 1] * 0.4 + sdf.noise(p, 0.08, seed) * 0.08)), 0.015, 0.2, seed), "plank_x")
        for sy in (-1, 1):
            t.add(lambda p, sy=sy: box(p, v3(w - 0.08, sy * (d - 0.07), 0.23), (0.045, 0.045, 0.23), 0.008), "wood_d")
        t.add(lambda p: box(p, v3(0.42, 0, 0.36), (0.24, d - 0.04, 0.12), 0.01), "wood_d")
        k.add(rough(lambda p: box(rot_z(p, 0.3, (-0.62, -0.2, 0)), v3(-0.62, -0.2, 0.04), (0.2, 0.3, 0.035), 0.01), 0.02, 0.15, seed), "plank_x")
        k.add(lambda p: np.minimum(cap(p, v3(-0.9, 0.1, 0.04), v3(-0.5, 0.3, 0.04), 0.04), cap(p, v3(-0.3, -0.5, 0.04), v3(0.05, -0.42, 0.04), 0.04)), "wood_d")
        _planks(k, [(0.1, -0.6, 0.4), (-0.95, -0.45, -0.5)], "plank_x", 0.16, seed)
        return {}
    _table(k, w, d, h, seed)
    k.add(lambda p: box(p, v3(0.42, 0, 0.36), (0.24, d - 0.04, 0.12), 0.01), "wood_d")          # 서랍 통
    k.add(lambda p: np.minimum(box(p, v3(0.42, -d + 0.03, 0.42), (0.2, 0.012, 0.045), 0.005), box(p, v3(0.42, -d + 0.03, 0.3), (0.2, 0.012, 0.045), 0.005)), "wood")
    k.add(lambda p: np.minimum(sphere(p, v3(0.42, -d + 0.005, 0.42), 0.018), sphere(p, v3(0.42, -d + 0.005, 0.3), 0.018)), "brass")
    if state == "cluttered":
        _page_mat(k)
        for i, (x, y, a) in enumerate(((-0.42, -0.08, 0.3), (-0.2, 0.1, -0.5), (-0.5, 0.14, 1.0), (0.5, -0.12, 0.15))):
            k.add(lambda p, x=x, y=y, a=a, i=i: box(rot_z(p, a, (x, y, 0)), v3(x, y, h + 0.004 + i * 0.003), (0.1, 0.07, 0.004)), "page")
        _open_book(k, v3(0.05, -0.05, h), 0.9, 0.1)
        _book(k, v3(0.52, 0.12, h), 0.09, 0.065, 0.022, 0.2, "cloth_r")
        _book(k, v3(0.51, 0.13, h + 0.044), 0.08, 0.06, 0.018, -0.25, "cloth_b")
        k.add(lambda p: cyl(p, v3(-0.6, -0.2, h), 0.035, 0.05, 0.01), "glass_b")                  # 잉크병 + 깃펜
        k.add(lambda p: cap(p, v3(-0.6, -0.2, h + 0.04), v3(-0.5, -0.14, h + 0.26), 0.006, 0.02), "linen")
        _candle(k, -0.25, 0.2, h, 0.07)
    return {}


@prop("table", "furniture", cell=(4, 4), collide=(1.6, 1.0), tags=["wood"], name_ko="탁자",
    variants={"intact": {}, "set": {"state": "set"}, "toppled": {"state": "toppled"}, "broken": {"state": "broken"}})
def table(k, state="intact", seed=1):
    w, d, h = 0.8, 0.46, 0.5
    if state == "toppled":   # 옆으로 넘어져 상판이 앞을 본다(바리케이드)
        t = _X(k, lambda p: rot_x(rot_z(p, -0.08) - v3(0, 0.05, d - 0.04), PI / 2 - 0.42))
        _table(t, w, d, h, seed)
        k.add(lambda p: sub(_frustum(p, v3(0.95, -0.5, 0), 0.03, 0.035, 0.07), cyl(p, v3(0.95, -0.5, 0.015), 0.027, 0.1)), "steel")
        _plate(k, -0.7, -0.62, 0.0)
        return {}
    if state == "broken":    # 가운데가 부러져 양쪽이 주저앉았다
        for s in (-1, 1):
            t = _X(k, lambda p, s=s: rot_y(p, s * 0.42, (s * 0.74, 0, 0.0)))
            cut = (lambda p, s=s: -s * p[:, 0] - 0.03 + sdf.noise(p, 0.07, seed + s) * 0.12)
            t.add(rough(lambda p, cut=cut: np.maximum(box(p, v3(0, 0, h - 0.04), (w, d, 0.04), 0.012), cut(p)), 0.015, 0.2, seed), "plank_x")
            for sy in (-1, 1):
                t.add(lambda p, s=s, sy=sy: box(p, v3(s * (w - 0.08), sy * (d - 0.07), 0.21), (0.045, 0.045, 0.21), 0.008), "wood_d")
        _planks(k, [(0.1, -0.7, 0.3), (-0.5, -0.75, -0.2), (0.75, -0.68, 1.1)], "plank_x", 0.15, seed)
        return {}
    _table(k, w, d, h, seed)
    if state == "set":
        _plate(k, -0.45, -0.18, h)
        _plate(k, 0.4, -0.2, h)
        _plate(k, 0.0, 0.2, h, 0.12, "wood_l")
        k.add(rough(lambda p: ell(p, v3(0.0, 0.2, h + 0.06), (0.1, 0.07, 0.05)), 0.02, 0.05, seed), "food")
        k.add(lambda p: ell(p, v3(-0.45, -0.18, h + 0.03), (0.05, 0.04, 0.02)), "food")
        _cup(k, -0.2, -0.05, h)
        _cup(k, 0.62, 0.05, h)
        _bottle(k, 0.3, 0.22, h, 0.04, 0.13, "glass")
        _candle(k, -0.55, 0.22, h, 0.12)
        k.add(lambda p: box(rot_z(p, 0.5, (0.42, -0.2, 0)), v3(0.42, -0.2, h + 0.028), (0.008, 0.07, 0.004)), "steel")
    return {}


def _chair(t, seed=1, back=True):
    t.add(rough(lambda p: box(p, v3(0, 0, 0.3), (0.19, 0.18, 0.022), 0.008), 0.008, 0.2, seed), "plank_y")
    for sx in (-1, 1):
        t.add(lambda p, sx=sx: box(p, v3(sx * 0.16, -0.15, 0.14), (0.024, 0.024, 0.14), 0.006), "wood_d")
        t.add(lambda p, sx=sx: box(p, v3(sx * 0.16, 0.16, 0.39 if back else 0.14), (0.024, 0.024, 0.39 if back else 0.14), 0.006), "wood_d")
    t.add(lambda p: box(p, v3(0, -0.15, 0.12), (0.15, 0.012, 0.014)), "wood_d")
    if back:
        t.add(lambda p: np.minimum(box(p, v3(0, 0.16, 0.7), (0.15, 0.014, 0.05), 0.006), box(p, v3(0, 0.16, 0.52), (0.15, 0.012, 0.03), 0.006)), "wood")


@prop("chair", "furniture", cell=(2, 3), collide=(0.45, 0.45), tags=["wood"], name_ko="의자",
    variants={"s": {}, "e": {"yaw": PI / 2}, "w": {"yaw": -PI / 2}, "n": {"yaw": PI}, "toppled": {"state": "toppled"}, "broken": {"state": "broken"}})
def chair(k, state="s", seed=1):
    if state == "toppled":
        _chair(_X(k, lambda p: rot_y(rot_z(p, 0.35) - v3(0.1, 0, 0.2), PI / 2)), seed)
    elif state == "broken":   # 앞다리 하나와 등받이가 부러졌다
        t = _X(k, lambda p: rot_y(rot_x(p, -0.3, (0, 0.16, 0)), 0.2))
        _chair(t, seed, False)
        k.add(lambda p: np.minimum(box(rot_z(p, 0.5, (0.35, -0.3, 0)), v3(0.35, -0.3, 0.02), (0.15, 0.05, 0.014), 0.006), cap(p, v3(-0.4, -0.25, 0.025), v3(-0.3, 0.1, 0.025), 0.024)), "wood")
        k.add(lambda p: cap(p, v3(0.3, 0.05, 0.025), v3(0.52, -0.1, 0.025), 0.024), "wood_d")
    else:
        _chair(k, seed)
    return {}


@prop("stool", "furniture", cell=(2, 2), collide=(0.36, 0.36), tags=["wood"], name_ko="걸상", variants={"base": {}, "toppled": {"state": "toppled"}})
def stool(k, state="base", seed=1):
    t = k if state == "base" else _X(k, lambda p: rot_y(p - v3(0, 0, 0.17), PI / 2 - 0.1))
    t.add(rough(lambda p: cyl(p, v3(0, 0, 0.27), 0.17, 0.045, 0.012), 0.008, 0.15, seed), k.mat("seat", M.rings("#6a5238", "#4a3828")))
    for a in (PI / 2, PI * 7 / 6, PI * 11 / 6):
        t.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.16, np.sin(a) * 0.14, 0), v3(np.cos(a) * 0.09, np.sin(a) * 0.08, 0.28), 0.024), "wood_d")
    return {}


@prop("bench", "furniture", cell=(3, 2), collide=(1.5, 0.4), tags=["wood"], name_ko="긴 의자", variants={"base": {}, "broken": {"state": "broken"}})
def bench(k, state="base", seed=1):
    t = k if state == "base" else _X(k, lambda p: rot_y(p, -0.3, (-0.6, 0, 0)))
    cut = (lambda p: p[:, 0] - 0.4 - sdf.noise(p, 0.08, seed) * 0.1) if state == "broken" else (lambda p: np.full(len(p), -1.0, F))
    t.add(rough(lambda p: np.maximum(box(p, v3(0, 0, 0.27), (0.75, 0.16, 0.025), 0.008), cut(p)), 0.01, 0.2, seed), "plank_x")
    for sx in ((-1, 1) if state == "base" else (-1,)):
        t.add(lambda p, sx=sx: box(p, v3(sx * 0.6, 0, 0.12), (0.03, 0.14, 0.12), 0.008), "wood_d")
    t.add(lambda p: np.maximum(box(p, v3(0, 0, 0.12), (0.6, 0.015, 0.02)), cut(p)), "wood_d")
    if state == "broken":
        k.add(lambda p: box(rot_z(p, 0.3, (0.7, -0.15, 0)), v3(0.7, -0.15, 0.03), (0.2, 0.14, 0.022), 0.008), "plank_x")
        k.add(lambda p: box(rot_z(p, -0.4, (0.95, 0.15, 0)), v3(0.95, 0.15, 0.03), (0.03, 0.14, 0.03)), "wood_d")
    return {}


# ── 잠자리 ────────────────────────────────────────────────────────────────────

@prop("bed", "furniture", cell=(4, 3), collide=(1.8, 0.9), tags=["wood", "camp", "prison"], name_ko="침대",
    variants={"made": {}, "messy": {"state": "messy"}, "bare": {"state": "bare"}, "broken": {"state": "broken"}})
def bed(k, state="made", seed=1):
    L, W = 0.85, 0.4
    post = lambda p, x, hh: np.minimum(box(p, v3(x, -W, hh / 2), (0.045, 0.045, hh / 2), 0.01), box(p, v3(x, W, hh / 2), (0.045, 0.045, hh / 2), 0.01))
    head = lambda p: np.minimum(post(p, -L, 0.72), box(p, v3(-L, 0, 0.45), (0.025, W, 0.2), 0.008))
    foot = lambda p: np.minimum(post(p, L, 0.42), box(p, v3(L, 0, 0.28), (0.025, W, 0.1), 0.008))
    rails = lambda p: np.minimum(box(p, v3(0, -W, 0.2), (L, 0.025, 0.05), 0.008), box(p, v3(0, W, 0.2), (L, 0.025, 0.05), 0.008))
    if state == "broken":   # 가운데가 꺾여 주저앉았다
        k.add(rough(head, 0.012, 0.2, seed), "wood_d")
        k.add(rough(lambda p: foot(rot_y(p, -0.25, (L, 0, 0))), 0.012, 0.2, seed), "wood_d")
        for s in (-1, 1):
            k.add(rough(lambda p, s=s: np.maximum(rails(rot_y(p, s * 0.2, (s * L, 0, 0.2))), -s * p[:, 0] - 0.02 - sdf.noise(p, 0.06, seed) * 0.08), 0.012, 0.2, seed), "wood")
            k.add(rough(lambda p, s=s: np.maximum(box(rot_y(p, s * 0.2, (s * L, 0, 0.2)), v3(0, 0, 0.19), (L - 0.04, W - 0.03, 0.015)), -s * p[:, 0] - 0.06 - sdf.noise(p, 0.06, seed + 3) * 0.14), 0.012, 0.15, seed), "plank_y")
        k.add(rough(lambda p: ell(p, v3(0.1, -0.05, 0.08), (0.45, 0.3, 0.1)), 0.09, 0.08, seed), k.mat("straw", M.thatch("#8a7440", 0.06)))
        k.add(rough(lambda p: ell(p, v3(-0.45, 0.05, 0.2), (0.3, 0.26, 0.07)), 0.04, 0.1, seed + 1), "cloth")
        _planks(k, [(0.4, -0.62, 0.2), (-0.3, -0.66, -0.3)], "plank_x", 0.14, seed)
        return {}
    k.add(rough(lambda p: np.minimum(np.minimum(head(p), foot(p)), rails(p)), 0.012, 0.2, seed), "wood_d")
    k.add(lambda p: box(p, v3(0, 0, 0.19), (L - 0.03, W - 0.03, 0.015)), "plank_y")
    if state == "bare":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.26), (L - 0.05, W - 0.03, 0.055), 0.04), 0.03, 0.12, seed), k.mat("tick", M.hide("#7a7058", 0.3)))
        return {}
    k.add(rough(lambda p: box(p, v3(0, 0, 0.27), (L - 0.04, W - 0.02, 0.065), 0.04), 0.015, 0.2, seed), "linen")
    if state == "made":
        k.add(rough(lambda p: box(p, v3(-0.58, 0, 0.36), (0.16, 0.26, 0.04), 0.04), 0.015, 0.1, seed), k.mat("pillow", M.plain("#aaa28c", 0.2, 0.1, 3)))
        k.add(rough(lambda p: box(p, v3(0.2, 0, 0.3), (0.6, W + 0.015, 0.06), 0.035) + np.sin(p[:, 0] * 14.0 + p[:, 1] * 5.0) * 0.006, 0.015, 0.15, seed), "cloth_r")
        k.add(lambda p: box(p, v3(-0.36, 0, 0.345), (0.05, W + 0.02, 0.022), 0.02), "linen")
    else:
        k.add(rough(lambda p: box(rot_z(p, 0.5, (-0.5, -0.1, 0)), v3(-0.5, -0.1, 0.36), (0.16, 0.24, 0.04), 0.04), 0.02, 0.1, seed), k.mat("pillow", M.plain("#aaa28c", 0.2, 0.1, 3)))
        k.add(rough(lambda p: smin(box(rot_z(p, 0.18, (0.3, 0, 0)), v3(0.32, 0.06, 0.33), (0.42, 0.3, 0.035), 0.03), box(rot_x(p, 0.5, (0.45, -0.4, 0.3)), v3(0.45, -0.42, 0.2), (0.3, 0.03, 0.16), 0.03), 0.08) + np.sin(p[:, 0] * 16.0 + p[:, 1] * 9.0) * 0.012, 0.04, 0.12, seed), "cloth_r")
        k.add(rough(lambda p: box(p, v3(0.45, -0.56, 0.03), (0.28, 0.1, 0.03), 0.03) + np.sin(p[:, 0] * 20.0) * 0.01, 0.03, 0.1, seed), "cloth_r")
    return {}


@prop("bedroll", "furniture", layer="stand", cell=(3, 2), tags=["camp", "cloth"], name_ko="침낭",
    variants={"out": {}, "rolled": {"state": "rolled"}, "used": {"state": "used"}})
def bedroll(k, state="out", seed=1):
    if state == "rolled":
        k.add(rough(lambda p: hcyl(p, v3(-0.26, 0, 0.12), v3(0.26, 0, 0.12), 0.12) + np.sin(np.arctan2(p[:, 2] - 0.12, p[:, 1]) * 3.0 + np.hypot(p[:, 2] - 0.12, p[:, 1]) * 60.0) * 0.004, 0.012, 0.1, seed), "cloth_g")
        for x in (-0.14, 0.14):
            k.add(lambda p, x=x: hcyl(p, v3(x - 0.015, 0, 0.12), v3(x + 0.015, 0, 0.12), 0.128), "leather")
        return {}
    k.add(rough(lambda p: box(p, v3(0.06, 0, 0.025), (0.66, 0.27, 0.025), 0.02), 0.012, 0.15, seed), "leather_d")
    k.add(rough(lambda p: box(p, v3(0.16, 0, 0.055), (0.52, 0.25, 0.03), 0.03) + np.sin(p[:, 0] * 18.0) * 0.004, 0.012, 0.15, seed), "cloth_g")
    k.add(rough(lambda p: hcyl(p, v3(-0.64, -0.24, 0.085), v3(-0.64, 0.24, 0.085), 0.085), 0.012, 0.1, seed), "cloth")
    if state == "used":   # 젖혀진 덮개
        k.add(rough(lambda p: ell(p, v3(0.45, -0.1, 0.1), (0.25, 0.24, 0.07)), 0.05, 0.1, seed), "cloth_g")
    return {}


@prop("straw_pile", "furniture", cell=(3, 2), tags=["prison", "camp"], name_ko="짚 더미", variants={"a": {}, "b": {"seed": 77, "big": True}})
def straw_pile(k, big=False, seed=1):
    s = 1.3 if big else 1.0
    straw = k.mat("straw", M.thatch("#8a7440", 0.06, seed))
    k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.04), (0.6 * s, 0.34 * s, 0.14 * s)), ell(p, v3(-0.2 * s, 0.05, 0.1), (0.3 * s, 0.24 * s, 0.14 * s)), 0.1), 0.1, 0.07, seed), straw)
    for i in range(7):
        a, r = k.rng.uniform(0, 2 * PI), k.rng.uniform(0.3, 0.62) * s
        x, y, b = np.cos(a) * r, np.sin(a) * r * 0.55, k.rng.uniform(0, PI)
        k.add(lambda p, x=x, y=y, b=b: cap(p, v3(x, y, 0.012), v3(x + np.cos(b) * 0.13, y + np.sin(b) * 0.1, 0.014), 0.008), straw)
    return {}


# ── 책장 · 선반 · 서랍장 ──────────────────────────────────────────────────────

def _book_row(t, x0, x1, yf, dpt, z, hmax, fill, seed):
    """꽂힌 책 한 줄(덩어리 하나 — 칸마다 높이 · 색이 다르다). yf = 앞면 y."""
    cols = np.stack([M.hexc(c) for c in BOOKHEX])
    cell = lambda p: np.floor((p[:, 0] + 0.012 * np.sin(p[:, 0] * 37.0 + seed)) / 0.056)

    def fn(p):
        c = cell(p)
        hh = hmax * (0.62 + 0.36 * sdf._hash(c, c * 0 + 1, c * 0, seed))
        hh = np.where(sdf._hash(c, c * 0, c * 0, seed) < fill, hh, -1.0)
        return np.maximum(box(p, v3((x0 + x1) / 2, yf + dpt, z + hmax / 2), ((x1 - x0) / 2, dpt, hmax / 2)), p[:, 2] - z - hh)

    def mat(p, n):
        c = cell(p)
        i = (sdf._hash(c, c * 0 + 2, c * 0, seed) * len(cols)).astype(int) % len(cols)
        col = cols[i] * (0.85 + 0.35 * sdf._hash(c, c * 0 + 3, c * 0, seed))[:, None]
        band = (np.abs(p[:, 2] - z - hmax * 0.45) < 0.012) & (sdf._hash(c, c * 0 + 4, c * 0, seed) > 0.5) & (n[:, 1] < -0.5)
        col = np.where(band[:, None], M.hexc("#9a8450")[None, :], col)
        col = np.where((n[:, 2] > 0.7)[:, None], M.hexc("#a89c80")[None, :], col)
        return col.astype(F), (c % 50 + 1).astype(F), np.zeros(len(p), F)
    t.add(fn, t.mat("books%d" % seed, mat))


def _case(t, w, d, h, shelves, seed=1, mat="wood_d", inner="wood"):
    """앞이 트인 장(옆판 · 윗판 · 뒷판 · 선반)."""
    shell = lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.012), box(p, v3(0, -0.05, h / 2 + 0.02), (w - 0.04, d, h / 2 - 0.06)))
    t.add(rough(shell, 0.01, 0.25, seed), mat)
    for z in shelves:
        t.add(lambda p, z=z: box(p, v3(0, 0.0, z), (w - 0.035, d - 0.015, 0.015)), inner)


@prop("bookshelf", "furniture", cell=(3, 4), collide=(1.1, 0.45), tags=["wood", "study", "library"], name_ko="책장", interact="container",
    variants={"full": {}, "half": {"state": "half"}, "empty": {"state": "empty"}, "broken": {"state": "broken"}})
def bookshelf(k, state="full", seed=1):
    w, d, h = 0.52, 0.17, 1.78
    zs = (0.08, 0.5, 0.92, 1.34)
    if state == "broken":   # 위쪽이 부서지고 선반이 내려앉았다
        shell = lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.012), box(p, v3(0, -0.05, h / 2 + 0.02), (w - 0.04, d, h / 2 - 0.06)))
        k.add(cut_above(rough(shell, 0.012, 0.25, seed), 1.15, 0.5, 0.25, seed, 0.6), "wood_d")
        k.add(lambda p: box(p, v3(0, 0, zs[0]), (w - 0.035, d - 0.015, 0.015)), "wood")
        k.add(lambda p: box(rot_y(p, 0.3, (w - 0.04, 0, zs[1])), v3(0, 0, zs[1]), (w - 0.035, d - 0.015, 0.015)), "wood")
        _book_row(k, -w + 0.05, 0.1, -d + 0.02, d - 0.03, zs[0] + 0.015, 0.34, 0.6, seed)
        for i, (x, y, a) in enumerate(((-0.3, -0.5, 0.4), (0.25, -0.45, -0.7), (0.6, -0.62, 1.2), (-0.65, -0.35, 2.0), (0.0, -0.68, 0.1))):
            _book(k, v3(x, y, 0.0), 0.09, 0.065, 0.02, a, BOOKMAT[(i * 3 + seed) % 7])
        _book(k, v3(0.27, -0.44, 0.04), 0.085, 0.06, 0.018, 0.3, "cloth_b")
        _planks(k, [(-0.75, -0.6, 0.9), (0.85, -0.3, 0.2)], "plank_xd", 0.15, seed)
        return {}
    _case(k, w, d, h, zs, seed)
    if state == "empty":
        return {}
    for i, z in enumerate(zs):
        if state == "full":
            _book_row(k, -w + 0.05, w - 0.05, -d + 0.02, d - 0.03, z + 0.015, 0.34, 0.93, seed + i * 7)
        else:
            x1 = (0.05, w - 0.05, -0.2, 0.2)[i]
            if i != 2:
                _book_row(k, -w + 0.05, x1, -d + 0.02, d - 0.03, z + 0.015, 0.34, 0.72, seed + i * 7)
    if state == "half":
        _book(k, v3(0.2, -0.03, zs[0] + 0.015), 0.1, 0.07, 0.022, 0.1, "cloth_r")
        _book(k, v3(0.2, -0.03, zs[0] + 0.06), 0.09, 0.065, 0.02, -0.15, "leather")
        k.add(lambda p: smin(sphere(p, v3(-0.1, -0.03, zs[2] + 0.1), 0.085), box(p, v3(-0.1, -0.09, zs[2] + 0.05), (0.05, 0.04, 0.03), 0.015), 0.02), "bone")
        k.add(lambda p: np.minimum(sphere(p, v3(-0.13, -0.11, zs[2] + 0.11), 0.022), sphere(p, v3(-0.07, -0.11, zs[2] + 0.11), 0.022)), "void")
        _bottle(k, 0.3, -0.04, zs[2] + 0.015, 0.035, 0.1, "glass")
    return {}


@prop("wall_shelf", "furniture", layer="wall_decal", cell=(3, 2), tags=["wood", "study", "lab"], name_ko="벽 선반",
    variants={"bottles": {}, "books": {"state": "books"}, "empty": {"state": "empty"}, "skull": {"state": "skull"}})
def wall_shelf(k, state="bottles", seed=1):
    """벽에 거는 선반 — 원점 = 까치발 아래 끝(벽면에 붙여 놓는다)."""
    zb = 0.16
    k.add(rough(lambda p: box(p, v3(0, -0.09, zb), (0.6, 0.1, 0.018), 0.005), 0.008, 0.2, seed), "plank_x")
    for x in (-0.45, 0.45):
        k.add(lambda p, x=x: np.minimum(box(p, v3(x, -0.01, 0.08), (0.02, 0.012, 0.08)), cap(p, v3(x, -0.02, 0.01), v3(x, -0.16, zb - 0.02), 0.014)), "wood_d")
    z = zb + 0.018
    if state == "bottles":
        _bottle(k, -0.45, -0.09, z, 0.04, 0.12, "glass")
        _flask(k, -0.24, -0.09, z, 0.06, "glass_r")
        _bottle(k, -0.04, -0.09, z, 0.03, 0.08, "glass_b", 0.07)
        k.add(lambda p: cyl(p, v3(0.18, -0.09, z), 0.06, 0.11, 0.015), k.mat("jar", M.plain("#7a6a54", 0.25, 0.08)))
        k.add(lambda p: cyl(p, v3(0.18, -0.09, z + 0.11), 0.065, 0.02, 0.006), "cloth")
        _flask(k, 0.42, -0.09, z, 0.05, "glass_b")
    elif state == "books":
        _book_row(k, -0.55, 0.12, -0.17, 0.07, z, 0.26, 0.95, seed)
        _book(k, v3(0.36, -0.09, z), 0.1, 0.065, 0.02, 0.05, "cloth_r")
        _book(k, v3(0.36, -0.09, z + 0.04), 0.09, 0.06, 0.018, -0.1, "leather")
    elif state == "skull":
        k.add(lambda p: smin(sphere(p, v3(-0.2, -0.09, z + 0.09), 0.085), box(p, v3(-0.2, -0.15, z + 0.04), (0.05, 0.04, 0.03), 0.015), 0.02), "bone")
        k.add(lambda p: np.minimum(sphere(p, v3(-0.23, -0.17, z + 0.1), 0.022), sphere(p, v3(-0.17, -0.17, z + 0.1), 0.022)), "void")
        _candle(k, 0.1, -0.09, z, 0.1)
        _candle(k, 0.22, -0.11, z, 0.05)
        _book(k, v3(0.42, -0.09, z), 0.09, 0.065, 0.022, 0.1, "cloth_k")
    return {"shadow": 0.0}


@prop("dresser", "furniture", cell=(2, 3), collide=(0.95, 0.5), tags=["wood"], name_ko="서랍장", interact="container",
    variants={"closed": {}, "open": {"state": "open"}})
def dresser(k, state="closed", seed=1):
    w, d, h = 0.45, 0.22, 0.68
    k.add(rough(lambda p: np.minimum(box(p, v3(0, 0, 0.06 + (h - 0.06) / 2), (w, d, (h - 0.06) / 2), 0.012), box(p, v3(0, 0, h), (w + 0.03, d + 0.02, 0.02), 0.008)), 0.01, 0.2, seed), "wood_d")
    for sx in (-1, 1):
        k.add(lambda p, sx=sx: np.minimum(box(p, v3(sx * (w - 0.05), -d + 0.05, 0.03), (0.04, 0.04, 0.03)), box(p, v3(sx * (w - 0.05), d - 0.05, 0.03), (0.04, 0.04, 0.03))), "wood_d")
    for i, z in enumerate((0.18, 0.36, 0.54)):
        out = 0.17 if (state == "open" and i == 1) else 0.0
        k.add(lambda p, z=z, out=out: box(p, v3(0, -d - out + 0.004, z), (w - 0.05, 0.014, 0.07), 0.006), "wood")
        k.add(lambda p, z=z, out=out: np.minimum(sphere(p, v3(-0.2, -d - out - 0.014, z), 0.02), sphere(p, v3(0.2, -d - out - 0.014, z), 0.02)), "brass")
        if out:
            k.add(lambda p, z=z: sub(box(p, v3(0, -d - out / 2, z - 0.01), (w - 0.06, out / 2, 0.06)), box(p, v3(0, -d - out / 2, z + 0.02), (w - 0.08, out / 2 - 0.015, 0.07))), "plank_y")
            k.add(rough(lambda p, z=z: ell(p, v3(0.05, -d - out / 2, z + 0.03), (0.3, 0.06, 0.045)), 0.03, 0.06, seed), "cloth_b")
    return {}


@prop("cabinet", "furniture", cell=(3, 4), collide=(0.95, 0.5), tags=["wood", "lab"], name_ko="캐비닛", interact="container",
    variants={"closed": {}, "open": {"state": "open"}, "broken": {"state": "broken"}})
def cabinet(k, state="closed", seed=1):
    w, d, h = 0.44, 0.22, 1.36
    door = lambda p, s: sub(box(p, v3(s * (w / 2 - 0.005), -d - 0.012, h / 2 + 0.03), (w / 2 - 0.02, 0.016, h / 2 - 0.07), 0.006),
        box(p, v3(s * (w / 2 - 0.005), -d - 0.03, h / 2 + 0.03), (w / 2 - 0.08, 0.012, h / 2 - 0.15), 0.01))
    knob = lambda p, s: sphere(p, v3(s * 0.05, -d - 0.04, h / 2 + 0.03), 0.022)
    k.add(rough(lambda p: box(p, v3(0, 0, h + 0.02), (w + 0.03, d + 0.02, 0.025), 0.008), 0.01, 0.2, seed), "wood_d")
    k.add(lambda p: box(p, v3(0, 0, 0.03), (w - 0.02, d - 0.02, 0.03)), "wood_d")
    if state == "closed":
        k.add(rough(lambda p: box(p, v3(0, 0, h / 2 + 0.03), (w, d, h / 2 - 0.03), 0.012), 0.01, 0.25, seed), "wood_d")
        k.add(lambda p: np.minimum(door(p, -1), door(p, 1)), "wood")
        k.add(lambda p: np.minimum(knob(p, -1), knob(p, 1)), "brass")
        return {}
    t = _move(k, 0, 0, 0.03)
    _case(t, w, d, h - 0.03, (0.04, 0.46, 0.88), seed)
    if state == "open":
        k.add(lambda p: door(p, 1), "wood")
        k.add(lambda p: knob(p, 1), "brass")
        k.add(lambda p: door(rot_z(p, -1.9, (-w, -d, 0)), -1), "wood")           # 왼쪽 문은 활짝
        _bottle(k, -0.25, -0.05, 0.94, 0.04, 0.12, "glass")
        _flask(k, -0.08, -0.05, 0.94, 0.055, "glass_r")
        _bottle(k, -0.28, -0.05, 0.52, 0.035, 0.09, "glass_b")
        k.add(lambda p: cyl(p, v3(-0.1, -0.05, 0.52), 0.07, 0.13, 0.015), k.mat("jar", M.plain("#7a6a54", 0.25, 0.08)))
        k.add(rough(lambda p: box(p, v3(-0.18, -0.05, 0.13), (0.16, 0.12, 0.05), 0.03), 0.02, 0.1, seed), "linen")
    else:   # broken: 문 한 짝은 떨어져 바닥에, 한 짝은 경첩 하나로 매달렸다
        k.add(lambda p: door(rot_y(rot_z(p, 0.5, (w, -d, 0)), 0.14, (w, -d, h)), 1), "wood")
        k.add(lambda p: box(rot_z(p, 0.3, (-0.3, -0.62, 0)), v3(-0.3, -0.62, 0.02), (0.2, 0.34, 0.016), 0.006), "wood")
        k.add(lambda p: box(rot_z(p, 0.3, (-0.3, -0.62, 0)), v3(-0.3, -0.62, 0.04), (0.13, 0.25, 0.008), 0.006), "wood_d")
        k.add(lambda p: hcyl(p, v3(0.1, -0.4, 0.04), v3(0.26, -0.46, 0.04), 0.04), "glass")
        k.add(lambda p: pool(p, v3(0.32, -0.5, 0.004), 0.16, 0.09, 0.004) + (sdf.noise(p, 0.07, seed) - 0.5) * 0.05, "glass_b")
        _bottle(k, -0.2, -0.05, 0.52, 0.035, 0.09, "glass_b")
    return {}


# ── 상자 · 통 ─────────────────────────────────────────────────────────────────

def _crate(t, s=0.28, seed=1, lid=True, mat="plank_x"):
    body = lambda p: box(p, v3(0, 0, s), (s, s, s), 0.008)
    if not lid:
        t.add(rough(lambda p: sub(body(p), box(p, v3(0, 0, s + 0.06), (s - 0.035, s - 0.035, s))), 0.01, 0.2, seed), mat)
        t.add(lambda p: box(p, v3(0, 0, s * 0.5), (s - 0.035, s - 0.035, 0.01)), "void")
    else:
        t.add(rough(body, 0.01, 0.2, seed), mat)
    e = 0.03
    frame = lambda p: np.minimum.reduce([box(p, v3(0, -s, e), (s + 0.008, 0.012, e)), box(p, v3(0, -s, 2 * s - e), (s + 0.008, 0.012, e)),
        box(p, v3(-s + e, -s, s), (e, 0.012, s)), box(p, v3(s - e, -s, s), (e, 0.012, s)), box(rot_y(p, PI / 4, (0, -s, s)), v3(0, -s, s), (s * 1.3, 0.01, e * 0.8))])
    t.add(lambda p: np.maximum(frame(p), np.abs(p[:, 0]) - s - 0.008), "wood_d")
    if lid:
        t.add(lambda p: np.minimum(box(p, v3(-s + e, 0, 2 * s), (e, s + 0.006, 0.01)), box(p, v3(s - e, 0, 2 * s), (e, s + 0.006, 0.01))), "wood_d")


@prop("crate", "furniture", cell=(3, 3), collide=(0.62, 0.62), tags=["wood", "storage", "camp"], name_ko="나무 상자", interact="container",
    variants={"intact": {}, "open": {"state": "open"}, "broken": {"state": "broken"}, "stack": {"state": "stack"}})
def crate(k, state="intact", seed=1):
    s = 0.28
    if state == "intact":
        _crate(k, s, seed)
    elif state == "open":
        _crate(k, s, seed, False)
        k.add(rough(lambda p: ell(p, v3(0, 0, s * 1.5), (s - 0.05, s - 0.05, 0.1)), 0.05, 0.05, seed), k.mat("straw", M.thatch("#8a7440", 0.05)))
        k.add(rough(lambda p: box(rot_x(p - v3(0.12, -0.42, 0.26), -1.15), v3(0, 0, 0), (s, s, 0.014), 0.006), 0.01, 0.2, seed), "plank_x")
    elif state == "broken":
        t = _X(k, lambda p: p)
        t.add(chip(rough(lambda p: np.maximum(sub(box(p, v3(0, 0, s), (s, s, s), 0.008), box(p, v3(0, -0.04, s + 0.04), (s - 0.03, s - 0.03, s))), p[:, 2] - 0.3 - p[:, 0] * 0.6 - sdf.noise(p, 0.1, seed) * 0.25), 0.012, 0.2, seed), 0.42, 0.2, seed, 0.06), "plank_x")
        k.add(lambda p: box(p, v3(0, 0, 0.02), (s - 0.03, s - 0.03, 0.01)), "void")
        _planks(k, [(0.5, -0.3, 0.3), (-0.5, -0.25, -0.5), (0.1, -0.55, 0.1), (0.7, 0.1, 1.2), (-0.62, 0.2, 0.8)], "plank_x", 0.17, seed)
    else:
        _crate(_move(k, -0.3, 0.05, 0, 0.06), s, seed)
        _crate(_move(k, 0.34, -0.02, 0, -0.1), s * 0.9, seed + 1, True, "plank_xd")
        _crate(_move(k, -0.05, 0.08, 2 * s, 0.25), s * 0.82, seed + 2)
        return {"cell": (3, 4)}
    return {}


def _chest_body(t, w, d, hb, mat="wood", band="iron", seed=1, bands=(-0.24, 0.24)):
    t.add(rough(lambda p: box(p, v3(0, 0, hb / 2), (w, d, hb / 2), 0.012), 0.01, 0.2, seed), mat)
    t.add(lambda p: np.minimum.reduce([np.maximum(box(p, v3(0, 0, hb / 2), (w + 0.01, d + 0.01, hb / 2 + 0.002), 0.012), np.abs(p[:, 0] - x) - 0.028) for x in bands]), band)


def _chest_lid(t, w, d, mat="wood", band="iron", seed=1, bands=(-0.24, 0.24), hollow=False):
    """뚜껑(반원통) — 원점 = 뒤쪽 경첩 선(y = d, z = 0)에서 앞으로 y: −2d~0."""
    lid = lambda p, e=0.0: np.maximum(np.maximum(np.hypot(p[:, 1] + d, p[:, 2] * 1.25) - d - e, -p[:, 2]), np.abs(p[:, 0]) - w - e)
    if hollow:
        t.add(rough(lambda p: sub(lid(p), np.maximum(np.hypot(p[:, 1] + d, p[:, 2] * 1.25) - d + 0.03, np.abs(p[:, 0]) - w + 0.03)), 0.01, 0.2, seed), mat)
    else:
        t.add(rough(lid, 0.01, 0.2, seed), mat)
    t.add(lambda p: np.minimum.reduce([np.maximum(lid(p, 0.01), np.abs(p[:, 0] - x) - 0.028) for x in bands]), band)


@prop("chest", "furniture", cell=(3, 3), collide=(0.8, 0.5), tags=["wood", "treasure"], name_ko="보물상자", interact="container",
    variants={"closed": {}, "open": {"state": "open"}, "empty": {"state": "empty"}, "locked": {"state": "locked"}, "broken": {"state": "broken"}})
def chest(k, state="closed", seed=1):
    import fx
    w, d, hb = 0.36, 0.22, 0.26
    locked = state == "locked"
    mat, band = ("wood_d", "iron") if locked else ("wood", "brass" if state in ("open", "closed") else "iron")
    bands = (-0.3, -0.1, 0.1, 0.3) if locked else (-0.24, 0.24)
    extra = {}
    if state == "broken":
        k.add(chip(rough(lambda p: sub(box(p, v3(0, 0, hb / 2), (w, d, hb / 2), 0.012), box(p, v3(0, 0, hb / 2 + 0.04), (w - 0.03, d - 0.03, hb / 2))), 0.012, 0.2, seed), 0.45, 0.2, seed, 0.07), mat)
        k.add(lambda p: box(p, v3(0, 0, 0.05), (w - 0.03, d - 0.03, 0.01)), "void")
        _chest_lid(_X(k, lambda p: rot_x(rot_z(p - v3(0.5, -0.5, 0.0), 0.5), PI) - v3(0, d, 0)), w, d, mat, band, seed, bands, True)
        _planks(k, [(-0.55, -0.3, 0.6), (-0.2, -0.5, -0.2)], "plank_x", 0.1, seed)
        return {}
    if state in ("closed", "locked"):
        _chest_body(k, w, d, hb, mat, band, seed, bands)
        _chest_lid(_X(k, lambda p: p - v3(0, d, hb)), w, d, mat, band, seed, bands)
        k.add(lambda p: box(p, v3(0, -d - 0.012, hb - 0.01), (0.05, 0.016, 0.06), 0.01), "brass" if not locked else "iron")
        k.add(lambda p: sphere(p, v3(0, -d - 0.03, hb - 0.03), 0.014), "void")
        if locked:
            k.add(lambda p: np.minimum(box(p, v3(0, -d - 0.04, hb - 0.1), (0.045, 0.02, 0.04), 0.008), np.maximum(ring_x(p, v3(0, -d - 0.04, hb - 0.05), 0.03, 0.01), hb - 0.06 - p[:, 2])), "rust")
        return {}
    k.add(rough(lambda p: sub(box(p, v3(0, 0, hb / 2), (w, d, hb / 2), 0.012), box(p, v3(0, 0, hb / 2 + 0.04), (w - 0.03, d - 0.03, hb / 2))), 0.01, 0.2, seed), mat)
    k.add(lambda p: np.minimum.reduce([np.maximum(sub(box(p, v3(0, 0, hb / 2), (w + 0.01, d + 0.01, hb / 2 + 0.002), 0.012), box(p, v3(0, 0, hb / 2 + 0.04), (w - 0.03, d - 0.03, hb / 2))), np.abs(p[:, 0] - x) - 0.028) for x in bands]), band)
    _chest_lid(_X(k, lambda p: rot_x(p - v3(0, d, hb), 1.75)), w, d, mat, band, seed, bands, True)
    if state == "open":
        k.add(rough(lambda p: np.maximum(ell(p, v3(0, 0, hb - 0.1), (w - 0.04, d - 0.04, 0.14)), np.maximum(np.abs(p[:, 0]) - w + 0.03, np.abs(p[:, 1]) - d + 0.03)), 0.04, 0.03, seed), "gold")
        k.add(lambda p: np.minimum(sphere(p, v3(0.12, -0.05, hb + 0.04), 0.035), sphere(p, v3(-0.15, 0.03, hb + 0.035), 0.028)), "glass_r")
        k.add(lambda p: cyl(p, v3(0.5, -0.32, 0), 0.03, 0.008), "gold")
        extra["post"] = [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, -0.05, hb + 0.02), 20, "#e8c868", 0.3), [vw.px(-0.2, -0.1, hb + 0.05), vw.px(0.18, 0.0, hb + 0.07), vw.px(0.02, -0.12, hb + 0.04)], "#fff0b8", 2.0)]
    else:
        k.add(lambda p: box(p, v3(0, 0, 0.06), (w - 0.03, d - 0.03, 0.01)), "void")
    return extra


def _barrel(t, r=0.24, h=0.74, seed=1, top=True, mat="wood", hoop="iron"):
    rad = lambda p: np.hypot(p[:, 0], p[:, 1]) - (r + 0.05 * np.sin(PI * np.clip(p[:, 2] / h, 0, 1)))
    body = lambda p: np.maximum(rad(p), np.abs(p[:, 2] - h / 2) - h / 2)
    t.add(rough(lambda p: sub(body(p), cyl(p, v3(0, 0, h - (0.03 if top else 0.14)), r - 0.02, 0.3)), 0.01, 0.2, seed), mat)
    t.add(lambda p: np.minimum.reduce([np.maximum(rad(p) - 0.01, np.abs(p[:, 2] - z) - 0.022) for z in (h * 0.14, h * 0.4, h * 0.62, h * 0.88)]), hoop)
    return body


@prop("barrel", "furniture", cell=(3, 3), collide=(0.58, 0.58), tags=["wood", "storage", "camp"], name_ko="나무통", interact="container",
    variants={"intact": {}, "water": {"state": "water"}, "broken": {"state": "broken"}, "toppled": {"state": "toppled"}, "stack": {"state": "stack"}})
def barrel(k, state="intact", seed=1):
    r, h = 0.24, 0.74
    if state == "intact":
        _barrel(k, r, h, seed)
        k.add(lambda p: cyl(p, v3(0, 0, h - 0.045), r - 0.02, 0.015), "plank_x")
    elif state == "water":
        _barrel(k, r, h, seed, False)
        k.add(lambda p: cyl(p, v3(0, 0, h - 0.11), r - 0.02, 0.012), k.mat("water", M.plain("#2a3a44", 0.5, 0.1, 4)))
        k.add(lambda p: np.minimum(_frustum(p, v3(0.08, -0.05, h - 0.1), 0.04, 0.05, 0.07), cap(p, v3(0.1, -0.03, h - 0.04), v3(0.26, 0.1, h + 0.08), 0.012)), "wood_l")   # 국자
    elif state == "broken":
        rad = lambda p: np.hypot(p[:, 0], p[:, 1]) - (r + 0.05 * np.sin(PI * np.clip(p[:, 2] / h, 0, 1)))
        shell = lambda p: sub(np.maximum(rad(p), np.abs(p[:, 2] - h / 2) - h / 2), cyl(p, v3(0, 0, 0.04), r - 0.01, 1.0))
        k.add(rough(lambda p: np.maximum(shell(p), p[:, 2] - 0.3 - p[:, 0] * 0.8 - sdf.fbm(p, 0.09, seed, 2) * 0.35), 0.012, 0.2, seed), "wood")
        k.add(lambda p: np.maximum(rad(p) - 0.01, np.abs(p[:, 2] - h * 0.14) - 0.022), "iron")
        k.add(lambda p: cyl(p, v3(0, 0, 0.03), r, 0.012), "void")
        k.add(lambda p: torus(rot_y(p, 0.25, (0.55, -0.25, 0.02)), v3(0.55, -0.25, 0.04), 0.24, 0.016), "iron")
        _planks(k, [(-0.5, -0.3, 0.4), (0.3, -0.5, -0.2), (-0.3, -0.55, 1.4), (0.75, 0.1, 0.9)], "plank_y", 0.2, seed)
    elif state == "toppled":
        t = _X(k, lambda p: rot_y(rot_z(p, 0.2) - v3(0.37, 0, r + 0.04), PI / 2))
        _barrel(t, r, h, seed)
        t.add(lambda p: cyl(p, v3(0, 0, h - 0.045), r - 0.02, 0.015), "plank_x")
        k.add(lambda p: pool(p, v3(-0.55, -0.18, 0.004), 0.3, 0.2, 0.004) + (sdf.noise(p, 0.1, seed) - 0.5) * 0.08, k.mat("water", M.plain("#2a3a44", 0.5, 0.1, 4)))
    else:
        for i, (x, y) in enumerate(((-0.27, 0.12), (0.27, 0.1))):
            t = _move(k, x, y)
            _barrel(t, r, h, seed + i)
            t.add(lambda p: cyl(p, v3(0, 0, h - 0.045), r - 0.02, 0.015), "plank_x")
        t = _X(k, lambda p: rot_y(p - v3(0.37, -0.02, h + r + 0.03), PI / 2))
        _barrel(t, r, h, seed + 2, True, "wood_d")
        t.add(lambda p: cyl(p, v3(0, 0, h - 0.045), r - 0.02, 0.015), "plank_x")
        return {"cell": (3, 4)}
    return {}


@prop("basket", "furniture", cell=(2, 2), collide=(0.4, 0.4), tags=["storage", "camp"], name_ko="바구니", interact="container",
    variants={"empty": {}, "food": {"state": "food"}, "toppled": {"state": "toppled"}})
def basket(k, state="empty", seed=1):
    wick = k.mat("wicker", M.thatch("#7a6440", 0.045, seed))
    t = k if state != "toppled" else _X(k, lambda p: rot_y(p - v3(0.1, 0, 0.2), PI / 2 - 0.15))
    weave = lambda p: np.sin(p[:, 2] * 110.0) * 0.004
    t.add(rough(lambda p: sub(_frustum(p, v3(0, 0, 0), 0.15, 0.2, 0.24) + weave(p), _frustum(p, v3(0, 0, 0.03), 0.13, 0.18, 0.3)), 0.008, 0.1, seed), wick)
    t.add(lambda p: torus(p, v3(0, 0, 0.24), 0.2, 0.016), wick)
    if state != "toppled":
        k.add(lambda p: np.maximum(ring_x(p, v3(0, 0, 0.24), 0.19, 0.013), 0.24 - p[:, 2]), wick)
    if state == "empty":
        k.add(lambda p: cyl(p, v3(0, 0, 0.06), 0.14, 0.01), "void")
    elif state == "food":
        for i, (x, y, m) in enumerate(((-0.07, -0.04, "shroom_r"), (0.06, -0.06, "food"), (0.0, 0.06, "shroom_r"), (0.1, 0.04, "leaf"), (-0.1, 0.06, "food"))):
            k.add(rough(lambda p, x=x, y=y: sphere(p, v3(x, y, 0.23), 0.06), 0.015, 0.05, seed + i), m)
        k.add(rough(lambda p: ell(rot_z(p, 0.6), v3(0.02, 0.0, 0.29), (0.1, 0.05, 0.04)), 0.015, 0.05, seed), "food")
    else:
        for i, (x, y) in enumerate(((-0.3, -0.12), (-0.42, 0.05), (-0.2, 0.12))):
            k.add(rough(lambda p, x=x, y=y: sphere(p, v3(x, y, 0.055), 0.055), 0.015, 0.05, seed + i), "shroom_r" if i != 1 else "food")
    return {}


# ── 무기 · 갑옷 거치대 ────────────────────────────────────────────────────────

def _sword(t, x, y, z0, ln=0.75, lean=0.0, mat="steel"):
    """끝을 아래로 세운 칼: 손잡이가 위."""
    T = lambda p: rot_y(p, lean, (x, y, z0))
    t.add(lambda p: np.minimum(box(T(p), v3(x, y, z0 + ln * 0.5), (0.028, 0.008, ln * 0.5)), cone(-(T(p) - v3(x, y, z0)) * v3(1, 1, 1) + v3(x, y, z0), v3(x, y, z0), 0.028, 0.06)), mat)
    t.add(lambda p: box(T(p), v3(x, y, z0 + ln + 0.012), (0.085, 0.016, 0.014), 0.006), "brass")
    t.add(lambda p: np.minimum(cap(T(p), v3(x, y, z0 + ln + 0.02), v3(x, y, z0 + ln + 0.15), 0.018), sphere(T(p), v3(x, y, z0 + ln + 0.17), 0.026)), "leather_d")


def _spear(t, x, y, z0, ln=1.6, lean=0.0):
    T = lambda p: rot_y(p, lean, (x, y, z0))
    t.add(lambda p: cap(T(p), v3(x, y, z0), v3(x, y, z0 + ln), 0.018), "wood_l")
    t.add(lambda p: np.maximum(ell(T(p), v3(x, y, z0 + ln + 0.1), (0.04, 0.012, 0.13)), z0 + ln - 0.01 - T(p)[:, 2]), "steel")


def _axe(t, x, y, z0, ln=0.8, lean=0.0):
    T = lambda p: rot_y(p, lean, (x, y, z0))
    t.add(lambda p: cap(T(p), v3(x, y, z0), v3(x, y, z0 + ln), 0.02), "wood")
    blade = lambda p: np.maximum(np.maximum(disc_x(p, v3(x + 0.03, y, z0 + ln - 0.1), 0.15, 0.012), x + 0.02 - p[:, 0]), -disc_x(p, v3(x - 0.07, y, z0 + ln - 0.1), 0.1, 0.1))
    t.add(lambda p: np.minimum(blade(T(p)), box(T(p), v3(x, y, z0 + ln - 0.1), (0.03, 0.022, 0.05), 0.008)), "steel")


@prop("weapon_rack", "furniture", cell=(3, 4), collide=(1.4, 0.45), tags=["wood", "armory"], name_ko="무기 거치대", interact="container",
    variants={"full": {}, "half": {"state": "half"}, "empty": {"state": "empty"}, "broken": {"state": "broken"}})
def weapon_rack(k, state="full", seed=1):
    w, h = 0.62, 1.12
    post = lambda p, s, hh=h: np.minimum(box(p, v3(s * w, 0.04, hh / 2), (0.04, 0.04, hh / 2), 0.008), box(p, v3(s * w, 0, 0.035), (0.05, 0.2, 0.035), 0.01))
    rail = lambda p, z: box(p, v3(0, 0.04, z), (w, 0.022, 0.035), 0.006)
    notch = lambda p, z: np.minimum.reduce([box(p, v3(x, -0.02, z), (0.05, 0.035, 0.014), 0.004) for x in (-0.42, -0.2, 0.02, 0.24, 0.44)])
    if state == "broken":
        k.add(rough(lambda p: post(p, -1), 0.01, 0.2, seed), "wood_d")
        k.add(cut_above(rough(lambda p: post(p, 1), 0.01, 0.2, seed), 0.42, 0.2, 0.1, seed), "wood_d")
        k.add(rough(lambda p: rail(rot_y(p, -0.5, (-w, 0, 0.98)), 0.98), 0.01, 0.2, seed), "wood")
        k.add(rough(lambda p: box(rot_z(p, 0.15, (0.2, -0.3, 0)), v3(0.2, -0.3, 0.035), (w * 0.8, 0.022, 0.035), 0.006), 0.01, 0.2, seed), "wood")
        _sword(_X(k, lambda p: rot_x(rot_z(p - v3(-0.2, -0.55, 0.02), 1.2), PI / 2)), 0, 0, -0.4, 0.7)
        k.add(lambda p: cap(p, v3(0.3, -0.6, 0.02), v3(0.95, -0.42, 0.02), 0.018), "wood_l")
        return {}
    k.add(rough(lambda p: np.minimum(post(p, -1), post(p, 1)), 0.01, 0.2, seed), "wood_d")
    k.add(rough(lambda p: np.minimum(rail(p, 0.98), rail(p, 0.2)), 0.01, 0.2, seed), "wood")
    k.add(lambda p: notch(p, 0.98), "wood_d")
    k.add(lambda p: box(p, v3(0, -0.04, 0.05), (w - 0.05, 0.08, 0.02), 0.006), "wood_d")
    if state in ("full", "half"):
        _sword(k, -0.42, -0.07, 0.08, 0.78, 0.0)
        _spear(k, 0.02, -0.07, 0.07, 1.55, 0.0)
        if state == "full":
            _sword(k, -0.2, -0.07, 0.08, 0.7, 0.0, "rust")
            _axe(k, 0.24, -0.07, 0.07, 0.95)
            _spear(k, 0.44, -0.07, 0.07, 1.4, 0.03)
    return {}


@prop("armor_stand", "furniture", cell=(3, 3), collide=(0.5, 0.45), tags=["armory"], name_ko="갑옷 거치대", interact="container",
    variants={"armor": {}, "empty": {"state": "empty"}, "fallen": {"state": "fallen"}})
def armor_stand(k, state="armor", seed=1):
    t = k if state != "fallen" else _X(k, lambda p: rot_y(rot_z(p, -0.2) - v3(-0.25, 0, 0.16), -PI / 2 + 0.06))
    t.add(lambda p: np.minimum(box(p, v3(0, 0, 0.025), (0.2, 0.04, 0.025), 0.008), box(p, v3(0, 0, 0.025), (0.04, 0.18, 0.025), 0.008)), "wood_d")
    t.add(rough(lambda p: np.minimum(cap(p, v3(0, 0, 0), v3(0, 0, 1.2), 0.03), box(p, v3(0, 0, 1.0), (0.24, 0.025, 0.025), 0.01)), 0.008, 0.2, seed), "wood")
    if state == "empty":
        t.add(lambda p: sphere(p, v3(0, 0, 1.24), 0.07), "wood_l")
        return {}
    plate_m = t.mat("plate", M.metal("#5e646a", "#5a4638", 10, 0.22))
    chest_ = lambda p: smin(box(p, v3(0, -0.01, 0.94), (0.17, 0.1, 0.1), 0.08), cap(p, v3(0, 0, 0.66), v3(0, 0, 0.88), 0.13, 0.16), 0.06)
    plate = lambda p: np.maximum(chest_(p) - np.clip(0.02 - np.abs(p[:, 0]), 0, 1) * 0.3, 0.64 - p[:, 2])        # 가운데 능선
    t.add(plate, plate_m)
    t.add(lambda p: np.maximum(np.maximum(cap(p, v3(0, 0, 0.5), v3(0, 0, 0.66), 0.2, 0.15), 0.5 - p[:, 2]), -cap(p, v3(0, 0, 0.4), v3(0, 0, 0.7), 0.17, 0.12)) + np.abs(np.sin(p[:, 2] * 60.0)) * 0.006, "leather_d")   # 허리 아래 가죽 치마
    t.add(lambda p: np.maximum(chest_(p) - 0.012, np.abs(p[:, 2] - 0.68) - 0.025), "leather")
    for s in (-1, 1):
        t.add(lambda p, s=s: np.maximum(ell(p, v3(s * 0.22, 0, 1.02), (0.085, 0.1, 0.06)), 1.0 - p[:, 2] + np.abs(p[:, 0] - s * 0.22) * 0.5), plate_m)
    if state == "armor":
        helm = lambda p: smin(sphere(p, v3(0, 0, 1.3), 0.115), cyl(p, v3(0, 0, 1.19), 0.1, 0.1, 0.02), 0.03)
        t.add(helm, plate_m)
        t.add(lambda p: np.minimum(box(p, v3(0, -0.1, 1.3), (0.07, 0.03, 0.012)), box(p, v3(0, -0.1, 1.24), (0.01, 0.03, 0.05))), "void")
        t.add(lambda p: box(p, v3(0, 0, 1.36), (0.012, 0.12, 0.06), 0.008), "brass")
    else:   # fallen: 투구는 굴러갔다
        k.add(lambda p: smin(sphere(p, v3(0.55, -0.35, 0.115), 0.115), cyl(rot_y(p, 1.2, (0.55, -0.35, 0.115)), v3(0.55, -0.35, 0.0), 0.1, 0.1, 0.02), 0.03), plate_m)
        k.add(lambda p: box(p, v3(0.63, -0.45, 0.13), (0.03, 0.02, 0.06)), "void")
        return {"cell": (4, 2), "dx": 0.5}
    return {}


# ── 작업 도구 ─────────────────────────────────────────────────────────────────

def _hammer(t, c, a=0.0, ln=0.3):
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: hcyl(T(p), v3(c[0] - ln / 2, c[1], c[2] + 0.02), v3(c[0] + ln / 2, c[1], c[2] + 0.02), 0.016), "wood_l")
    t.add(lambda p: box(T(p), v3(c[0] + ln / 2, c[1], c[2] + 0.03), (0.032, 0.07, 0.03), 0.008), "iron")


@prop("workbench", "furniture", cell=(4, 3), collide=(1.7, 0.8), tags=["wood", "workshop", "lab"], name_ko="작업대",
    variants={"tools": {}, "empty": {"state": "empty"}})
def workbench(k, state="tools", seed=1):
    w, d, h = 0.82, 0.36, 0.56
    k.add(rough(lambda p: box(p, v3(0, 0, h - 0.055), (w, d, 0.055), 0.012), 0.015, 0.2, seed), "plank_x")
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.add(lambda p, sx=sx, sy=sy: box(p, v3(sx * (w - 0.1), sy * (d - 0.08), 0.225), (0.06, 0.06, 0.225), 0.01), "wood_d")
    k.add(lambda p: box(p, v3(0, 0, 0.14), (w - 0.08, d - 0.06, 0.018)), "plank_xd")
    k.add(lambda p: np.minimum(box(p, v3(0.5, -d - 0.04, h - 0.04), (0.1, 0.045, 0.07), 0.01), np.minimum(box(p, v3(0.5, -d - 0.13, h - 0.04), (0.1, 0.02, 0.07), 0.01),
        hcyl(p, v3(0.5, -d - 0.26, h - 0.05), v3(0.5, -d, h - 0.05), 0.014))), "iron")                       # 바이스
    k.add(lambda p: hcyl(p, v3(0.4, -d - 0.26, h - 0.05), v3(0.6, -d - 0.26, h - 0.05), 0.01), "iron")
    if state == "tools":
        _hammer(k, v3(-0.45, -0.1, h), 0.5)
        k.add(lambda p: box(rot_z(p, -0.2, (0.0, 0.1, 0)), v3(0.0, 0.1, h + 0.006), (0.2, 0.05, 0.005)), "steel")                     # 톱
        k.add(lambda p: box(rot_z(p, -0.2, (0.0, 0.1, 0)), v3(0.25, 0.1, h + 0.015), (0.06, 0.055, 0.014), 0.01), "wood_l")
        k.add(lambda p: np.minimum(hcyl(p, v3(-0.2, -0.24, h + 0.014), v3(-0.05, -0.22, h + 0.014), 0.014), hcyl(p, v3(-0.05, -0.22, h + 0.012), v3(0.08, -0.2, h + 0.012), 0.007)), "wood_d")   # 끌
        k.add(lambda p: box(p, v3(-0.62, 0.18, h + 0.05), (0.12, 0.1, 0.05), 0.008), "plank_xd")                                    # 못 상자
        k.add(lambda p: box(p, v3(0.5, 0.2, h + 0.03), (0.15, 0.06, 0.03), 0.01), "plank_x")                                      # 깎던 나무
        k.add(lambda p: np.minimum(box(p, v3(-0.4, 0, 0.21), (0.2, 0.2, 0.05), 0.01), cyl(p, v3(0.3, 0, 0.16), 0.11, 0.16, 0.02)), "wood")
    return {}


@prop("anvil", "furniture", cell=(2, 2), collide=(0.75, 0.5), tags=["workshop", "armory"], name_ko="모루", variants={"base": {}, "hammer": {"state": "hammer"}})
def anvil(k, state="base", seed=1):
    k.add(rough(lambda p: cyl(p, v3(0, 0, 0), 0.21, 0.3, 0.02), 0.02, 0.15, seed), k.mat("stump", M.rings("#6a5238", "#3e2e22")))
    body = lambda p: np.minimum.reduce([box(p, v3(0, 0, 0.33), (0.15, 0.1, 0.03), 0.008), box(p, v3(0, 0, 0.41), (0.08, 0.06, 0.06), 0.01), box(p, v3(0.02, 0, 0.5), (0.2, 0.09, 0.04), 0.008),
        cap(p, v3(-0.17, 0, 0.5), v3(-0.38, 0, 0.52), 0.045, 0.012)])
    k.add(body, "iron")
    if state == "hammer":
        _hammer(k, v3(0.05, -0.02, 0.54), 0.3, 0.28)
        k.add(lambda p: np.minimum(hcyl(p, v3(0.3, -0.3, 0.012), v3(0.62, -0.38, 0.012), 0.012), hcyl(p, v3(0.3, -0.34, 0.012), v3(0.62, -0.3, 0.012), 0.012)), "iron")   # 집게
    return {}


@prop("toolbox", "furniture", cell=(2, 2), tags=["workshop"], name_ko="연장통", interact="container", variants={"full": {}, "empty": {"state": "empty"}})
def toolbox(k, state="full", seed=1):
    w, d, h = 0.26, 0.12, 0.14
    k.add(rough(lambda p: sub(box(p, v3(0, 0, h / 2), (w, d, h / 2), 0.008), box(p, v3(0, 0, h / 2 + 0.03), (w - 0.022, d - 0.022, h / 2))), 0.008, 0.15, seed), "plank_x")
    for s in (-1, 1):
        k.add(lambda p, s=s: np.maximum(box(p, v3(s * (w - 0.011), 0, 0.17), (0.011, d, 0.17)), (p[:, 2] - 0.14) * 0.5 + np.abs(p[:, 1]) - d), "plank_y")
    k.add(lambda p: hcyl(p, v3(-w, 0, 0.3), v3(w, 0, 0.3), 0.018), "wood_d")
    if state == "full":
        k.add(lambda p: np.minimum(cap(p, v3(-0.12, -0.03, 0.04), v3(-0.16, -0.05, 0.27), 0.014), box(p, v3(-0.16, -0.05, 0.27), (0.04, 0.02, 0.025), 0.006)), "iron")
        k.add(lambda p: cap(p, v3(0.02, 0.03, 0.04), v3(0.05, 0.04, 0.24), 0.012), "wood_l")
        k.add(lambda p: box(rot_y(p, 0.15, (0.14, -0.02, 0.05)), v3(0.14, -0.02, 0.14), (0.035, 0.005, 0.1)), "steel")
    else:
        k.add(lambda p: box(p, v3(0, 0, 0.035), (w - 0.022, d - 0.022, 0.006)), "void")
    return {}


@prop("grindstone", "furniture", cell=(2, 2), collide=(0.7, 0.4), tags=["workshop", "armory"], name_ko="숫돌 바퀴", variants={"base": {}})
def grindstone(k, seed=1):
    for sy in (-0.11, 0.11):
        k.add(lambda p, sy=sy: np.minimum.reduce([cap(p, v3(-0.3, sy, 0), v3(-0.08, sy, 0.44), 0.028), cap(p, v3(0.3, sy, 0), v3(0.08, sy, 0.44), 0.028), hcyl(p, v3(-0.3, sy, 0.05), v3(0.3, sy, 0.05), 0.022)]), "wood_d")
    k.add(rough(lambda p: disc_x(p, v3(0, 0, 0.42), 0.26, 0.05), 0.012, 0.1, seed), "stone_l")
    k.add(lambda p: hcyl(p, v3(0, -0.18, 0.42), v3(0, 0.14, 0.42), 0.022), "iron")
    k.add(lambda p: np.minimum(cap(p, v3(0, -0.18, 0.42), v3(0.1, -0.18, 0.34), 0.014), hcyl(p, v3(0.1, -0.26, 0.34), v3(0.1, -0.17, 0.34), 0.016)), "iron")
    k.add(lambda p: sub(box(p, v3(0, 0, 0.09), (0.2, 0.09, 0.05), 0.01), box(p, v3(0, 0, 0.13), (0.18, 0.07, 0.05))), "plank_x")
    return {}


# ── 책 · 문서 · 두루마리 ──────────────────────────────────────────────────────

@prop("books", "furniture", cell=(2, 2), tags=["study", "library", "paper"], name_ko="책",
    variants={"stack": {}, "open": {"state": "open"}, "scattered": {"state": "scattered"}, "tall": {"state": "tall"}})
def books(k, state="stack", seed=1):
    if state == "open":
        _open_book(k, v3(0, 0, 0), 1.0, k.rng.uniform(-0.3, 0.3))
    elif state in ("stack", "tall"):
        n, z = (4 if state == "stack" else 8), 0.0
        for i in range(n):
            th = k.rng.uniform(0.016, 0.026)
            _book(k, v3(k.rng.uniform(-0.02, 0.02), k.rng.uniform(-0.015, 0.015), z), k.rng.uniform(0.085, 0.11), k.rng.uniform(0.06, 0.075), th, k.rng.uniform(-0.3, 0.3), BOOKMAT[int(k.rng.integers(7))])
            z += th * 2
    else:
        for i, (x, y) in enumerate(((-0.3, 0.05), (0.02, 0.12), (0.3, -0.02), (-0.1, -0.2), (0.22, -0.26))):
            _book(k, v3(x, y, 0.0), 0.095, 0.068, 0.02, k.rng.uniform(0, PI), BOOKMAT[(i * 2 + seed) % 7])
        _book(k, v3(0.04, 0.13, 0.04), 0.085, 0.06, 0.018, k.rng.uniform(0, PI), "cloth_b")
        for s in (-1, 1):   # 엎어진 채 펼쳐진 책
            k.add(lambda p, s=s: box(rot_y(p, s * 0.6, (-0.42, -0.3, 0.07)), v3(-0.42 + s * 0.06, -0.3, 0.07), (0.07, 0.07, 0.01), 0.004), "leather")
        return {"cell": (3, 2)}
    return {}


@prop("papers", "furniture", layer="decal", cell=(2, 2), tags=["study", "paper"], name_ko="흩어진 문서",
    variants={"a": {}, "b": {"seed": 31}, "stack": {"state": "stack"}})
def papers(k, state="a", seed=1):
    _page_mat(k)
    if state == "stack":
        k.add(rough(lambda p: box(p, v3(0, 0, 0.03), (0.11, 0.08, 0.03), 0.004), 0.008, 0.03, seed), "paper")
        k.add(lambda p: box(rot_z(p, 0.2), v3(0, 0, 0.064), (0.105, 0.075, 0.004)), "page")
        k.add(lambda p: box(p, v3(0.05, -0.02, 0.085), (0.035, 0.035, 0.018), 0.008), "stone_d")
        return {}
    for i in range(6):
        x, y, a = k.rng.uniform(-0.38, 0.38), k.rng.uniform(-0.28, 0.28), k.rng.uniform(0, PI)
        k.add(lambda p, x=x, y=y, a=a, i=i: box(rot_z(p, a, (x, y, 0)), v3(x, y, 0.004 + i * 0.003), (0.1, 0.07, 0.004)), "page" if i % 3 else "paper")
    return {"shadow": 0.25}


def _scroll(t, c, ln=0.22, a=0.0, r=0.028, mat="paper"):
    T = lambda p: rot_z(p, a, c)
    t.add(lambda p: hcyl(T(p), v3(c[0] - ln / 2, c[1], c[2] + r), v3(c[0] + ln / 2, c[1], c[2] + r), r), mat)
    t.add(lambda p: np.minimum(sphere(T(p), v3(c[0] - ln / 2 - 0.012, c[1], c[2] + r), 0.02), sphere(T(p), v3(c[0] + ln / 2 + 0.012, c[1], c[2] + r), 0.02)), "wood_d")
    t.add(lambda p: hcyl(T(p), v3(c[0] - 0.012, c[1], c[2] + r), v3(c[0] + 0.012, c[1], c[2] + r), r + 0.004), "cloth_r")


@prop("scrolls", "furniture", cell=(2, 2), tags=["study", "library", "paper"], name_ko="두루마리",
    variants={"pile": {}, "open": {"state": "open"}, "case": {"state": "case"}})
def scrolls(k, state="pile", seed=1):
    if state == "pile":
        for i, (x, y, z, a) in enumerate(((-0.07, 0.03, 0, 0.1), (0.0, -0.04, 0, -0.08), (0.08, 0.04, 0, 0.2), (-0.03, 0.0, 0.05, 0.02), (0.06, 0.0, 0.05, -0.2))):
            _scroll(k, v3(x * 0.9, y + i * 0.0, z), 0.22, a + PI / 2 * 0 + 0.0, 0.028)
        _scroll(k, v3(0.24, -0.16, 0), 0.2, 0.9)
    elif state == "open":
        _page_mat(k)
        k.add(lambda p: box(p, v3(0, 0, 0.005), (0.11, 0.17, 0.005)), "page")
        for sy in (-1, 1):
            k.add(lambda p, sy=sy: hcyl(p, v3(-0.11, sy * 0.18, 0.025), v3(0.11, sy * 0.18, 0.025), 0.025), "paper")
            k.add(lambda p, sy=sy: np.minimum(sphere(p, v3(-0.125, sy * 0.18, 0.025), 0.02), sphere(p, v3(0.125, sy * 0.18, 0.025), 0.02)), "wood_d")
    else:   # 가죽 통에 든 두루마리
        k.add(lambda p: cap(p, v3(0, 0, 0.045), v3(0.0, 0.0, 0.34), 0.045), "leather")
        k.add(lambda p: np.minimum(cyl(p, v3(0, 0, 0.3), 0.05, 0.03), cyl(p, v3(0, 0, 0.08), 0.05, 0.03)), "leather_d")
        k.add(lambda p: np.minimum(cyl(p, v3(-0.012, 0, 0.36), 0.02, 0.07), cyl(p, v3(0.018, 0.01, 0.36), 0.018, 0.05)), "paper")
        _scroll(k, v3(0.2, -0.1, 0), 0.2, 0.4)
    return {}


# ── 병 · 식기 · 음식 ──────────────────────────────────────────────────────────

@prop("bottles", "furniture", cell=(2, 2), tags=["lab", "tavern", "glass"], name_ko="병",
    variants={"group": {}, "potion_red": {"state": "potion", "col": "r"}, "potion_blue": {"state": "potion", "col": "b"}, "fallen": {"state": "fallen"}, "wine": {"state": "wine"}})
def bottles(k, state="group", col="r", seed=1):
    import fx
    if state == "group":
        _bottle(k, -0.14, 0.04, 0, 0.05, 0.15, "glass")
        _bottle(k, 0.0, -0.05, 0, 0.035, 0.09, "glass_b", 0.07)
        _flask(k, 0.14, 0.03, 0, 0.065, "glass_r")
        k.add(lambda p: smin(cyl(p, v3(-0.02, 0.13, 0), 0.07, 0.14, 0.03), cyl(p, v3(-0.02, 0.13, 0.14), 0.04, 0.05, 0.01), 0.02), k.mat("jug", M.plain("#7a6a54", 0.25, 0.08)))
        k.add(lambda p: np.maximum(ring_x(p, v3(0.05, 0.13, 0.12), 0.045, 0.012), 0.03 - p[:, 0]), "jug")
    elif state == "potion":
        _flask(k, 0, 0, 0, 0.075, "glass_r" if col == "r" else "glass_b")
        c = "#e05050" if col == "r" else "#6aa8f0"
        return {"post": [lambda img, vw: fx.sparkle(fx.halo(img, *vw.px(0, 0, 0.07), 8, c, 0.5), [vw.px(-0.03, -0.06, 0.1)], "#ffffff", 1.6)]}
    elif state == "wine":
        _bottle(k, 0, 0, 0, 0.045, 0.16, "glass", 0.1)
        k.add(lambda p: box(p, v3(0, -0.045, 0.08), (0.03, 0.006, 0.035)), "paper")
    else:
        t = _X(k, lambda p: rot_y(rot_z(p, 0.4) - v3(0.02, 0, 0.045), PI / 2))
        _bottle(t, 0, 0, 0, 0.045, 0.14, "glass")
        k.add(lambda p: pool(p, v3(-0.26, -0.1, 0.004), 0.13, 0.08, 0.004) + (sdf.noise(p, 0.06, seed) - 0.5) * 0.05, k.mat("wine", M.plain("#3a1a20", 0.3, 0.1)))
        _bottle(k, 0.2, 0.1, 0, 0.035, 0.1, "glass_b", 0.07)
    return {}


@prop("dishes", "furniture", cell=(2, 2), tags=["tavern", "camp"], name_ko="식기",
    variants={"set": {}, "bowls": {"state": "bowls"}, "dirty": {"state": "dirty"}})
def dishes(k, state="set", seed=1):
    if state == "bowls":
        for i in range(3):
            k.add(lambda p, i=i: sub(_frustum(p, v3(0, 0, i * 0.03), 0.06, 0.11, 0.06), _frustum(p, v3(0, 0, i * 0.03 + 0.015), 0.05, 0.1, 0.07)), "wood_l" if i % 2 == 0 else "wood")
        k.add(lambda p: cap(p, v3(0.16, -0.08, 0.008), v3(0.3, 0.0, 0.008), 0.008, 0.018), "wood_l")
        return {}
    _plate(k, 0, 0, 0, 0.11)
    _cup(k, 0.2, 0.06, 0)
    k.add(lambda p: np.minimum(cap(p, v3(-0.17, -0.08, 0.006), v3(-0.17, 0.02, 0.006), 0.006), ell(p, v3(-0.17, 0.05, 0.006), (0.016, 0.026, 0.006))), "steel")
    if state == "dirty":
        k.add(rough(lambda p: ell(p, v3(0.01, 0.0, 0.03), (0.06, 0.045, 0.022)), 0.02, 0.04, seed), "food")
        k.add(lambda p: cap(p, v3(-0.05, -0.04, 0.03), v3(0.06, -0.06, 0.035), 0.01), "bone")
        _plate(k, -0.05, 0.22, 0, 0.09, "wood_l")
    return {}


@prop("food_scraps", "furniture", layer="decal", cell=(2, 2), tags=["camp", "tavern", "trace"], name_ko="음식 잔해", variants={"a": {}, "b": {"state": "b"}})
def food_scraps(k, state="a", seed=1):
    bone = lambda p, a, b: np.minimum(cap(p, a, b, 0.012), np.minimum(sphere(p, a, 0.022), sphere(p, b, 0.022)))
    k.add(lambda p: np.minimum(bone(p, v3(-0.25, -0.05, 0.02), v3(-0.08, 0.02, 0.02)), bone(p, v3(-0.18, 0.12, 0.02), v3(-0.3, 0.2, 0.02))), "bone")
    k.add(rough(lambda p: np.maximum(ell(p, v3(0.12, 0.1, 0.03), (0.1, 0.07, 0.05)), p[:, 0] - 0.16 - sdf.noise(p, 0.04, seed) * 0.05), 0.02, 0.04, seed), "food")
    if state == "a":   # 엎질러진 잔
        k.add(lambda p: sub(hcyl(p, v3(0.1, -0.2, 0.04), v3(0.2, -0.16, 0.04), 0.04), hcyl(p, v3(0.07, -0.21, 0.04), v3(0.18, -0.17, 0.04), 0.032)), "wood_l")
        k.add(lambda p: pool(p, v3(-0.03, -0.24, 0.004), 0.13, 0.07, 0.004) + (sdf.noise(p, 0.06, seed) - 0.5) * 0.05, k.mat("wine", M.plain("#3a1a20", 0.3, 0.1)))
    else:
        _plate(k, 0.05, -0.18, 0, 0.1, "wood_l")
        k.add(lambda p: bone(p, v3(0.0, -0.2, 0.035), v3(0.12, -0.15, 0.035)), "bone")
        k.add(rough(lambda p: sphere(p, v3(0.3, 0.0, 0.035), 0.04), 0.02, 0.03, seed), "rot")
    return {"shadow": 0.3}


@prop("cooking_pot", "furniture", cell=(2, 3), collide=(0.5, 0.45), tags=["camp", "tavern"], name_ko="솥",
    variants={"cold": {}, "stew": {"state": "stew"}, "ground": {"state": "ground"}})
def cooking_pot(k, state="cold", seed=1):
    import fx
    zc = 0.4 if state != "ground" else 0.18
    pot = lambda p: sub(np.maximum(sphere(p, v3(0, 0, zc), 0.2), p[:, 2] - zc - 0.08), np.maximum(sphere(p, v3(0, 0, zc), 0.175), zc - 0.12 - p[:, 2]) * 1.0)
    potm = k.mat("pot", M.metal("#55555a", "#6a4a34", 8, 0.45))
    k.add(pot, potm)
    k.add(lambda p: torus(p, v3(0, 0, zc + 0.08), 0.185, 0.02), potm)
    k.add(lambda p: cyl(p, v3(0, 0, zc + 0.02), 0.17, 0.012), "void" if state != "stew" else k.mat("stew", M.plain("#6a4a2a", 0.5, 0.04)))
    if state != "ground":
        top = v3(0, 0, 1.02)
        for a in (PI / 2, PI * 7 / 6, PI * 11 / 6):
            k.add(lambda p, a=a: cap(p, v3(np.cos(a) * 0.4, np.sin(a) * 0.34, 0), top, 0.016), "rust")
        k.add(lambda p: np.minimum(cap(p, top, v3(0, 0, zc + 0.3), 0.008), np.maximum(ring_x(p, v3(0, 0, zc + 0.12), 0.19, 0.01), zc + 0.08 - p[:, 2])), "iron")
        k.rubble([(-0.1, -0.05), (0.08, 0.04), (0.0, -0.1), (0.1, -0.06)], "coal", 0.03, 0.05)
        k.add(lambda p: np.minimum(cap(p, v3(-0.2, -0.1, 0.02), v3(0.12, 0.05, 0.03), 0.022), cap(p, v3(0.18, -0.12, 0.02), v3(-0.08, 0.08, 0.03), 0.022)), "wood_d")
        k.add(lambda p: pool(p, v3(0, 0, 0.004), 0.2, 0.15, 0.004) + (sdf.noise(p, 0.06, seed) - 0.5) * 0.06, k.mat("ash_l", M.plain("#6a665e", 0.4, 0.05, 15)))
    else:
        for s in (-1, 1):
            k.add(lambda p, s=s: np.maximum(ring_x(p, v3(s * 0.21, 0, zc + 0.03), 0.04, 0.01), 0.2 - s * p[:, 0]), "iron")
    if state == "stew":
        k.add(lambda p: cap(p, v3(0.05, 0, zc + 0.03), v3(0.2, 0.05, zc + 0.26), 0.012), "wood_l")
        return {"shadow": 0.22, "post": [lambda img, vw: fx.puff(img, *vw.px(0, 0, zc + 0.2), 9, "#b8b4a8", 0.3, seed, 0, 22, 5)]}
    return {"shadow": 0.22}


# ── 자루 · 배낭 · 보급품 ──────────────────────────────────────────────────────

def _sack(t, c, s=1.0, seed=1, mat="cloth", lean=0.0):
    T = lambda p: rot_y(p, lean, c)
    body = lambda p: smin(ell(T(p), v3(c[0], c[1], c[2] + 0.19 * s), (0.19 * s, 0.16 * s, 0.22 * s)), ell(T(p), v3(c[0], c[1], c[2] + 0.08 * s), (0.21 * s, 0.18 * s, 0.1 * s)), 0.06)
    neck = lambda p: smin(cap(T(p), v3(c[0], c[1], c[2] + 0.36 * s), v3(c[0], c[1], c[2] + 0.44 * s), 0.05 * s, 0.035 * s), cone(-(T(p) - v3(c[0], c[1], c[2] + 0.52 * s)) + v3(c[0], c[1], c[2] + 0.52 * s) * 0 + 0, v3(0, 0, 0), 0.08 * s, 0.1 * s), 0.02)
    t.add(rough(lambda p: smin(body(p), neck(p), 0.04) + np.sin(np.arctan2(T(p)[:, 1] - c[1], T(p)[:, 0] - c[0]) * 7.0) * 0.006, 0.03, 0.12, seed), mat)
    t.add(lambda p: torus(T(p), v3(c[0], c[1], c[2] + 0.42 * s), 0.045 * s, 0.012), "rope")


@prop("sack", "furniture", cell=(2, 2), collide=(0.42, 0.38), tags=["storage", "camp", "cloth"], name_ko="자루", interact="container",
    variants={"full": {}, "slumped": {"state": "slumped"}, "open": {"state": "open"}, "pile": {"state": "pile"}})
def sack(k, state="full", seed=1):
    if state == "full":
        _sack(k, v3(0, 0, 0), 1.0, seed)
    elif state == "slumped":
        k.add(rough(lambda p: smin(ell(p, v3(0, 0, 0.1), (0.3, 0.2, 0.13)), ell(p, v3(0.26, -0.03, 0.07), (0.12, 0.09, 0.07)), 0.08) + np.sin(p[:, 0] * 22.0) * 0.005, 0.035, 0.1, seed), "cloth")
        k.add(lambda p: torus(rot_y(p, PI / 2, (0.3, -0.03, 0.07)), v3(0.3, -0.03, 0.07), 0.06, 0.012), "rope")
    elif state == "open":
        body = lambda p: smin(ell(p, v3(0, 0, 0.17), (0.2, 0.17, 0.2)), ell(p, v3(0, 0, 0.07), (0.22, 0.19, 0.09)), 0.06)
        k.add(rough(lambda p: sub(np.maximum(body(p), p[:, 2] - 0.3), cyl(p, v3(0, 0, 0.24), 0.14, 0.2)), 0.025, 0.1, seed), "cloth")
        k.add(lambda p: torus(p, v3(0, 0, 0.3), 0.155, 0.022) + np.sin(np.arctan2(p[:, 1], p[:, 0]) * 6.0) * 0.008, "cloth")
        k.add(rough(lambda p: ell(p, v3(0, 0, 0.24), (0.14, 0.12, 0.05)), 0.02, 0.02, seed), "sand")
        k.add(lambda p: pool(p, v3(0.26, -0.18, 0.006), 0.12, 0.08, 0.006) + (sdf.noise(p, 0.03, seed) - 0.5) * 0.05, "sand")
    else:
        _sack(k, v3(-0.2, 0.08, 0), 1.0, seed)
        _sack(k, v3(0.2, 0.05, 0), 0.95, seed + 1, "linen")
        k.add(rough(lambda p: ell(p, v3(0.02, -0.2, 0.1), (0.3, 0.17, 0.12)) + np.sin(p[:, 0] * 22.0) * 0.005, 0.035, 0.1, seed + 2), "cloth")
        return {"cell": (3, 2)}
    return {}


@prop("backpack", "furniture", cell=(2, 2), tags=["camp", "explorer", "leather"], name_ko="배낭", interact="container",
    variants={"standing": {}, "opened": {"state": "opened"}})
def backpack(k, state="standing", seed=1):
    k.add(rough(lambda p: box(p, v3(0, 0, 0.2), (0.17, 0.11, 0.2), 0.07), 0.02, 0.12, seed), "leather")
    k.add(lambda p: box(p, v3(0, -0.12, 0.13), (0.1, 0.035, 0.07), 0.03), "leather_d")                              # 앞주머니
    k.add(lambda p: np.minimum(box(p, v3(-0.1, -0.115, 0.26), (0.014, 0.012, 0.13)), box(p, v3(0.1, -0.115, 0.26), (0.014, 0.012, 0.13))), "leather_d")
    if state == "standing":
        k.add(rough(lambda p: box(p, v3(0, -0.03, 0.37), (0.18, 0.13, 0.05), 0.045), 0.015, 0.1, seed), "leather_d")   # 덮개
        k.add(lambda p: np.minimum(box(p, v3(-0.1, -0.135, 0.3), (0.022, 0.01, 0.022), 0.004), box(p, v3(0.1, -0.135, 0.3), (0.022, 0.01, 0.022), 0.004)), "brass")
        k.add(rough(lambda p: hcyl(p, v3(-0.2, 0, 0.47), v3(0.2, 0, 0.47), 0.07), 0.01, 0.1, seed), "cloth_g")           # 위에 묶은 침낭
        k.add(lambda p: np.minimum(hcyl(p, v3(-0.12, 0, 0.47), v3(-0.09, 0, 0.47), 0.076), hcyl(p, v3(0.09, 0, 0.47), v3(0.12, 0, 0.47), 0.076)), "rope")
    else:
        k.add(rough(lambda p: box(rot_x(p, 0.9, (0, 0.11, 0.38)), v3(0, 0.02, 0.4), (0.17, 0.12, 0.02), 0.015), 0.012, 0.1, seed), "leather_d")
        k.add(rough(lambda p: ell(p, v3(0.02, -0.02, 0.4), (0.12, 0.08, 0.05)), 0.03, 0.05, seed), "linen")
        k.add(lambda p: np.minimum(torus(p, v3(0.36, -0.12, 0.02), 0.09, 0.02), torus(p, v3(0.36, -0.12, 0.05), 0.08, 0.02)), "rope")
        _flask(k, -0.32, -0.14, 0, 0.05, "glass_r")
        k.add(lambda p: box(rot_z(p, 0.4, (-0.3, 0.08, 0)), v3(-0.3, 0.08, 0.02), (0.08, 0.06, 0.02), 0.01), "food")
        return {"cell": (3, 2)}
    return {}


@prop("supply_pile", "furniture", cell=(4, 3), collide=(1.4, 0.8), tags=["camp", "explorer", "storage"], name_ko="보급품 더미", interact="container",
    variants={"a": {}, "b": {"state": "b"}})
def supply_pile(k, state="a", seed=1):
    _crate(_move(k, -0.32, 0.12, 0, 0.1), 0.26, seed)
    _sack(k, v3(0.22, 0.14, 0), 1.0, seed, "cloth", 0.12)
    k.add(lambda p: np.minimum.reduce([torus(p, v3(0.5, -0.25, 0.022 + i * 0.035), 0.11 - i * 0.008, 0.022) for i in range(3)]), "rope")
    k.add(rough(lambda p: hcyl(p, v3(-0.52, -0.3, 0.1), v3(-0.1, -0.24, 0.1), 0.1), 0.012, 0.1, seed), "cloth_g")
    k.add(lambda p: np.minimum(hcyl(p, v3(-0.44, -0.29, 0.1), v3(-0.41, -0.285, 0.1), 0.106), hcyl(p, v3(-0.22, -0.26, 0.1), v3(-0.19, -0.255, 0.1), 0.106)), "leather")
    if state == "a":
        t = _move(k, -0.3, 0.1, 0.52, -0.2)
        _barrel(t, 0.13, 0.3, seed + 3)
        t.add(lambda p: cyl(p, v3(0, 0, 0.3 - 0.04), 0.11, 0.012), "plank_x")
        _bottle(k, 0.1, -0.32, 0, 0.035, 0.1, "glass")
    else:
        _crate(_move(k, -0.3, 0.1, 0.52, 0.3), 0.2, seed + 3, True, "plank_xd")
        k.add(rough(lambda p: ell(p, v3(0.72, 0.1, 0.1), (0.26, 0.18, 0.12)) + np.sin(p[:, 0] * 22.0) * 0.005, 0.035, 0.1, seed + 2), "linen")
        k.add(lambda p: cap(p, v3(0.05, -0.36, 0.02), v3(0.3, -0.52, 0.02), 0.018), "wood_l")
    return {}
