"""2층 소품 재질(tools/f2_art/props.py 전용): 닿은 점 p(N, 3) · 법선 n → (색 (N, 3), 조각 번호 (N,), 스스로 빛남 (N,)).
조각 번호가 바뀌는 곳에 가는 잉크 선이 생긴다(돌 하나 · 판자 하나 · 잎 무더기). 색은 채도 낮게(ART.md §2)."""
import numpy as np

import sdf

F = np.float32


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], F) / 255.0


def _out(c, ids=None, glow=None):
    n = len(c)
    return np.clip(c, 0, 1).astype(F), (np.zeros(n, F) if ids is None else ids.astype(F)), (np.zeros(n, F) if glow is None else glow.astype(F))


def _weather(p, n, c, moss, seed):
    """빗물 자국(세로 줄) + 아래쪽 때 + 이끼(위를 보는 면 · 아래쪽)."""
    streak = sdf.fbm(p * np.array([1, 1, 0.22], F), 0.16, seed + 3, 2)
    c = c * (0.86 + streak * 0.28)[:, None]
    c = c * (0.78 + 0.22 * np.clip(p[:, 2] / 0.5, 0, 1))[:, None]
    if moss is not None:
        m = np.clip((sdf.fbm(p, 0.45, seed + 5, 3) - 0.52) * 6.0 + np.clip(0.5 - p[:, 2], 0, 0.5) * 0.9 + np.clip(n[:, 2], 0, 1) * 0.25, 0, 1) * 0.85
        c = c * (1 - m[:, None]) + moss[None, :] * (m * (0.8 + sdf.noise(p, 0.05, seed + 6) * 0.4))[:, None]
    return c


def masonry(base, course=0.24, length=0.52, moss=None, seed=1):
    """쌓은 돌: 줄마다 엇갈린 마름돌 — 돌마다 밝기가 다르고 줄눈이 어둡다. 윗면은 넓은 판."""
    base, moss = hexc(base), (hexc(moss) if moss else None)

    def fn(p, n):
        top = n[:, 2] > 0.7
        row = np.floor(p[:, 2] / course)
        along = p[:, 0] + p[:, 1] * 0.9 + (row % 2) * length * 0.5 + sdf.noise(p, 0.9, seed) * 0.05
        col = np.floor(along / length)
        fz, fa = p[:, 2] / course - row, along / length - col
        tx, ty = np.floor(p[:, 0] / 0.7), np.floor(p[:, 1] / 0.6)
        ids = np.where(top, sdf._hash(tx, ty, tx * 0, seed), sdf._hash(row, col, row * 0, seed + 1))
        joint = np.where(top, 0.0, ((fz < 0.1) | (fa < 0.045)).astype(F))
        c = base[None, :] * (0.84 + ids * 0.3)[:, None] * (1 - joint * 0.42)[:, None]
        c = c + (sdf._hash(col, row, row * 0, seed + 2)[:, None] - 0.5) * np.array([0.03, 0.0, -0.03], F)
        return _out(_weather(p, n, c, moss, seed), np.floor(ids * 97))
    return fn


def stone(base, moss=None, seed=2, lines=0.0):
    """통돌(석상 · 비석 · 받침): 얼룩 + 빗물 자국. lines > 0이면 그 간격으로 새긴 글줄."""
    base, moss = hexc(base), (hexc(moss) if moss else None)

    def fn(p, n):
        c = base[None, :] * (0.88 + sdf.fbm(p, 0.3, seed, 3) * 0.24)[:, None]
        ids = np.zeros(len(p), F)
        if lines > 0.0:
            row = np.floor(p[:, 2] / lines)
            cut = ((p[:, 2] / lines - row) < 0.32) & (sdf._hash(np.floor(p[:, 0] / 0.07), row, row * 0, seed) > 0.25) & (n[:, 1] < -0.5)
            c = c * (1 - cut[:, None] * 0.45)
        return _out(_weather(p, n, c, moss, seed), ids)
    return fn


def bark(base, moss=None, seed=3, pale=False):
    """나무껍질: 줄기를 따라 세로로 갈라진 골. pale = 자작 · 흰 거목(가로 검은 눈)."""
    base, moss = hexc(base), (hexc(moss) if moss else None)

    def fn(p, n):
        q = p * np.array([1, 1, 0.12], F)
        ridge = sdf.fbm(q, 0.09, seed, 2)
        c = base[None, :] * (0.62 + ridge * 0.72)[:, None]
        ids = np.floor(ridge * 3.2)
        if pale:
            eye = (sdf.noise(p * np.array([0.25, 0.25, 1.6], F), 0.16, seed + 4) > 0.74)
            c = c * (1 - eye[:, None] * 0.7)
            ids = eye.astype(F)
        if moss is not None:
            m = np.clip((sdf.fbm(p, 0.5, seed + 5, 2) - 0.5) * 5.0 + np.clip(0.9 - p[:, 2], 0, 0.9) * 0.5 - n[:, 0] * 0.2, 0, 1) * 0.75
            c = c * (1 - m[:, None]) + moss[None, :] * (m * (0.8 + sdf.noise(p, 0.05, seed + 6) * 0.4))[:, None]
        return _out(c, ids)
    return fn


def wood(base, plank=0.2, axis=2, seed=4):
    """다듬은 나무(기둥 · 판자 · 들보): axis 방향 결, plank 폭마다 판자 하나."""
    base = hexc(base)

    def fn(p, n):
        s = np.ones(3, F)
        s[axis] = 0.1
        grain = sdf.fbm(p * s, 0.05, seed, 2)
        other = [k for k in range(3) if k != axis]
        idx = np.floor((p[:, other[0]] + p[:, other[1]] * 1.3) / plank)
        tone = sdf._hash(idx, idx * 0, idx * 0, seed)
        c = base[None, :] * (0.7 + grain * 0.4 + tone * 0.2)[:, None]
        return _out(c, np.floor(tone * 53))
    return fn


def thatch(base, row=0.2, seed=5):
    """짚 · 풀 지붕: 층층이 내려오는 단, 단 아래 끝이 어둡고 결이 아래로 흐른다."""
    base = hexc(base)

    def fn(p, n):
        z = p[:, 2] + sdf.noise(p, 0.3, seed) * 0.1
        r = np.floor(z / row)
        f = z / row - r
        strand = sdf.fbm(p * np.array([1, 1, 0.1], F), 0.035, seed + 1, 2)
        c = base[None, :] * (0.6 + f * 0.35 + strand * 0.4)[:, None]
        c = c * (0.9 + sdf._hash(r, r * 0, r * 0, seed)[:, None] * 0.2)
        return _out(c, r % 64)
    return fn


def hide(base, patch=0.8, seed=6):
    """기운 가죽(천막): 조각마다 색이 다르고 꿰맨 자리가 어둡다."""
    base = hexc(base)

    def fn(p, n):
        ang = np.arctan2(p[:, 1], p[:, 0])
        a = np.floor(ang / 0.9 + sdf.noise(p, 0.6, seed) * 0.8)
        b = np.floor(p[:, 2] / patch + a * 0.37)
        tone = sdf._hash(a, b, a * 0, seed)
        c = base[None, :] * (0.72 + tone * 0.4)[:, None] * (0.85 + sdf.fbm(p, 0.12, seed + 2, 2) * 0.3)[:, None]
        c = c + (tone[:, None] - 0.5) * np.array([0.05, 0.0, -0.04], F)
        return _out(c, np.floor(tone * 41))
    return fn


def leaf(base, clump=0.34, seed=7, warm=0.12):
    """잎 무더기: 덩이마다 밝기가 다르고 위쪽이 누렇게 밝다."""
    base = hexc(base)

    def fn(p, n):
        k = sdf.fbm(p, clump, seed, 2)
        fine = sdf.noise(p, 0.07, seed + 3)
        c = base[None, :] * (0.55 + k * 0.6 + fine * 0.3)[:, None]
        c = c + np.clip(n[:, 2], 0, 1)[:, None] * np.array([warm, warm * 0.8, -0.02], F) * (0.4 + fine[:, None])
        return _out(c, np.floor(k * 5.0) + np.floor(fine * 2.2) * 7)
    return fn


def metal(base, rust="#6a4630", seed=8, amount=0.5):
    """쇠(창살 · 종 · 등): 어두운 쇠 + 녹 얼룩."""
    base, rust = hexc(base), hexc(rust)

    def fn(p, n):
        r = np.clip((sdf.fbm(p, 0.16, seed, 3) - (1.0 - amount) * 0.62) * 4.0, 0, 1) * 0.8
        c = base[None, :] * (1 - r[:, None]) + rust[None, :] * r[:, None]
        return _out(c * (0.85 + sdf.noise(p, 0.04, seed + 1)[:, None] * 0.3))
    return fn


def plain(base, vary=0.25, scale=0.2, seed=9):
    """민무늬(흙 · 뼈 · 밧줄 · 살): 얼룩만."""
    base = hexc(base)

    def fn(p, n):
        return _out(base[None, :] * (1.0 - vary * 0.5 + sdf.fbm(p, scale, seed, 3) * vary)[:, None])
    return fn


def rings(base, dark, seed=10):
    """잘린 나무 단면(나이테)."""
    base, dark = hexc(base), hexc(dark)

    def fn(p, n):
        r = np.hypot(p[:, 0], p[:, 1]) + sdf.noise(p, 0.2, seed) * 0.04
        ring = (np.sin(r * 70.0) > 0.4)
        side = n[:, 2] < 0.6
        c = np.where(side[:, None], dark[None, :] * (0.7 + sdf.fbm(p * np.array([1, 1, 0.15], F), 0.08, seed, 2)[:, None] * 0.6), base[None, :] * (1 - ring[:, None] * 0.22))
        return _out(c, np.where(side, np.floor(sdf.fbm(p * np.array([1, 1, 0.15], F), 0.08, seed, 2) * 3), 9.0))
    return fn


def glow(color):
    """스스로 빛나는 것(등불 · 넋불 · 룬) — 그늘지지 않는다."""
    color = hexc(color)

    def fn(p, n):
        return _out(np.tile(color, (len(p), 1)), None, np.ones(len(p), F))
    return fn


def void():
    """어두운 속(문 안 · 창 안)."""
    def fn(p, n):
        return _out(np.tile(np.array([0.03, 0.025, 0.03], F), (len(p), 1)), None, np.ones(len(p), F))
    return fn
