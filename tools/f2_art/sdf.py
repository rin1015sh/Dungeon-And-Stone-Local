"""2층 소품 · 구조물 빚기 부품(tools/f2_art/props.py 전용): 거리장(SDF) 덩어리.
좌표는 칸 단위(1 = 바닥 한 칸) — x 오른쪽, y 깊이(화면 위쪽 = 먼 쪽), z 높이. 점 배열 p = (N, 3) float32 → 거리 (N,).
덩어리를 min(합치기) · smin(녹여 합치기) · sub(파내기)로 엮고, 표면을 잡음으로 흔들어 손으로 빚은 듯 울퉁불퉁하게 한다."""
import numpy as np

F = np.float32


def v3(x, y, z):
    return np.array([x, y, z], F)


def length(a):
    return np.sqrt((a * a).sum(-1))


def sphere(p, c, r):
    return length(p - c) - r


def ell(p, c, r):
    """타원체(가까운 값 — 걸음을 조금 줄여 쓴다)."""
    r = np.asarray(r, F)
    q = p - c
    k0 = length(q / r)
    k1 = length(q / (r * r))
    return np.where(k1 > 1e-6, k0 * (k0 - 1.0) / np.maximum(k1, 1e-6), -r.min())


def box(p, c, b, rnd=0.0):
    """상자: 가운데 c, 반 크기 b, 모서리 둥글림 rnd."""
    q = np.abs(p - c) - (np.asarray(b, F) - rnd)
    return length(np.maximum(q, 0)) + np.minimum(q.max(-1), 0) - rnd


def cyl(p, c, r, h, rnd=0.0):
    """세운 원통: 밑면 가운데 c, 반지름 r, 높이 h."""
    dx = np.hypot(p[:, 0] - c[0], p[:, 1] - c[1]) - (r - rnd)
    dz = np.abs(p[:, 2] - c[2] - h * 0.5) - (h * 0.5 - rnd)
    return np.hypot(np.maximum(dx, 0), np.maximum(dz, 0)) + np.minimum(np.maximum(dx, dz), 0) - rnd


def cap(p, a, b, ra, rb=None):
    """두 점 사이 굵기가 변하는 막대(줄기 · 가지 · 팔다리)."""
    rb = ra if rb is None else rb
    ab = b - a
    t = np.clip(((p - a) @ ab) / max(float(ab @ ab), 1e-9), 0.0, 1.0)
    return length(p - a - t[:, None] * ab) - (ra + (rb - ra) * t)


def cone(p, c, r, h):
    """세운 원뿔: 밑면 가운데 c, 밑 반지름 r, 높이 h."""
    q = np.hypot(p[:, 0] - c[0], p[:, 1] - c[1])
    z = p[:, 2] - c[2]
    return np.maximum((q * h + z * r - r * h) / np.hypot(h, r), -z)


def gable(p, c, half_len, half_w, h, axis=0):
    """박공지붕(삼각 기둥): 밑면 가운데 c, 용마루가 axis(0 = x, 1 = y)를 따라 half_len, 폭 반 half_w, 높이 h."""
    along = np.abs(p[:, axis] - c[axis]) - half_len
    across = np.abs(p[:, 1 - axis] - c[1 - axis])
    z = p[:, 2] - c[2]
    return np.maximum(np.maximum((across * h + z * half_w - half_w * h) / np.hypot(h, half_w), -z), along)


def smin(a, b, k):
    """녹여 합치기(k = 녹는 폭)."""
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def sub(a, b):
    """a에서 b를 파낸다."""
    return np.maximum(a, -b)


def _hash(ix, iy, iz, seed):
    h = (ix.astype(np.int64) * 374761393 + iy.astype(np.int64) * 668265263 + iz.astype(np.int64) * 1274126177 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF).astype(F) / 65535.0


def noise(p, scale, seed=0):
    """3D 값 잡음 0~1(p / scale 격자)."""
    g = p / scale
    i = np.floor(g)
    f = g - i
    f = f * f * (3 - 2 * f)
    ix, iy, iz = i[:, 0], i[:, 1], i[:, 2]
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + w * _hash(ix + dx, iy + dy, iz + dz, seed)
    return out


def fbm(p, scale, seed=0, octaves=3):
    out, amp, tot = 0.0, 1.0, 0.0
    for o in range(octaves):
        out = out + noise(p, scale / (2 ** o), seed + o * 7) * amp
        tot += amp
        amp *= 0.5
    return out / tot


def cells(p, size, seed=0):
    """칸 번호 잡음: 칸(size — 축마다)마다 같은 0~1 값(돌 하나 · 판자 하나의 밝기)."""
    g = np.floor(p / np.asarray(size, F))
    return _hash(g[:, 0], g[:, 1], g[:, 2], seed)


class Scene:
    """덩어리 묶음: add(거리 함수, 재질 이름). 가장 가까운 덩어리의 재질로 칠한다."""

    def __init__(self):
        self.parts = []

    def add(self, fn, mat):
        self.parts.append((fn, mat))
        return self

    def dist(self, p):
        d = None
        for fn, _ in self.parts:
            di = fn(p)
            d = di if d is None else np.minimum(d, di)
        return d

    def dist_id(self, p):
        d = np.full(len(p), 1e9, F)
        k = np.zeros(len(p), np.int32)
        for i, (fn, _) in enumerate(self.parts):
            di = fn(p)
            near = di < d
            k[near] = i
            d = np.where(near, di, d)
        return d, k
