"""2층 바닥 그림 바탕(tools/f2_art/ground.py 전용): 사방으로 이어지는 넓은 재질 판을 칠하는 부품.
잡음 · 돌 조각(보로노이) · 빛 받은 결 · 붓 자국 · 낱 조각 찍기(이어지게 감아 찍는다) · 색 정리.
그림은 W × W(= 낼 크기의 2배)로 칠해 줄인다 — 선이 부드럽다."""
import numpy as np
from PIL import Image, ImageDraw

S = 256   # 낼 크기(px) = 4칸 × 64
SS = 2    # 칠하는 배율
W = S * SS
SHADOW = np.array([0x1a, 0x14, 0x12], np.float32) / 255.0
HIGH = np.array([0xe0, 0xd2, 0xb0], np.float32) / 255.0


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def pnoise(cells, seed):
    """사방으로 이어지는 값 잡음 0~1(W × W, 격자 cells × cells)."""
    g = np.random.default_rng(seed).random((cells, cells)).astype(np.float32)
    x = np.arange(W) * cells / W
    i = np.floor(x).astype(int)
    f = x - i
    f = f * f * (3 - 2 * f)
    i1 = (i + 1) % cells
    a = g[i][:, i] * (1 - f)[None, :] + g[i][:, i1] * f[None, :]
    b = g[i1][:, i] * (1 - f)[None, :] + g[i1][:, i1] * f[None, :]
    return a * (1 - f)[:, None] + b * f[:, None]


def fbm(cells, seed, octaves=4, gain=0.5):
    out = np.zeros((W, W), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        out += pnoise(cells * (2 ** o), seed + o * 17) * amp
        tot += amp
        amp *= gain
    return out / tot


def relief(h, k):
    """높이장 h를 왼쪽 위 빛으로 본 밝기 배율(1 = 평지)."""
    gx = np.roll(h, -1, 1) - np.roll(h, 1, 1)
    gy = np.roll(h, -1, 0) - np.roll(h, 1, 0)
    return np.clip(1.0 - (gx * 0.7 + gy * 0.75) * k, 0.35, 1.7)


def blur(a, r):
    """이어지는 상자 흐림(두 번 — 거의 가우스)."""
    for _ in range(2):
        for ax in (0, 1):
            c = np.cumsum(np.concatenate([a.take(range(-r, 0), ax), a, a.take(range(0, r + 1), ax)], ax), ax)
            a = (c.take(range(2 * r + 1, 2 * r + 1 + a.shape[ax]), ax) - c.take(range(0, a.shape[ax]), ax)) / (2 * r + 1)
    return a


def voronoi(n, seed, jitter=1.0):
    """이어지는 돌 조각: 점 n개 → (조각 번호, 가장 가까운 거리, 경계까지 거리 d2 − d1) — 모두 W × W."""
    rng = np.random.default_rng(seed)
    side = int(np.ceil(np.sqrt(n)))
    gx, gy = np.meshgrid(np.arange(side), np.arange(side))
    pts = (np.stack([gx.ravel(), gy.ravel()], 1) + 0.5 + (rng.random((side * side, 2)) - 0.5) * jitter) * (W / side)
    all_pts = np.concatenate([pts + np.array([dx, dy]) * W for dx in (-1, 0, 1) for dy in (-1, 0, 1)])
    ids = np.tile(np.arange(len(pts)), 9)
    yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
    best = np.full((W, W), 1e9, np.float32)
    second = np.full((W, W), 1e9, np.float32)
    cell = np.zeros((W, W), np.int32)
    for k in range(len(all_pts)):
        px, py = all_pts[k]
        if px < -W * 0.3 or px > W * 1.3 or py < -W * 0.3 or py > W * 1.3:
            continue
        x0, x1 = max(0, int(px - W * 0.3)), min(W, int(px + W * 0.3))
        y0, y1 = max(0, int(py - W * 0.3)), min(W, int(py + W * 0.3))
        d = np.hypot(xx[y0:y1, x0:x1] - px, yy[y0:y1, x0:x1] - py)
        b = best[y0:y1, x0:x1]
        s = second[y0:y1, x0:x1]
        closer = d < b
        s[:] = np.where(closer, b, np.minimum(s, d))
        cell[y0:y1, x0:x1][closer] = ids[k]
        b[closer] = d[closer]
    return cell, best, second - best


class Layer:
    """낱 조각을 찍는 투명 판(PIL — 가장자리를 넘는 조각은 반대쪽에도 찍어 이어지게)."""

    def __init__(self):
        self.im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    @staticmethod
    def _rgba(c, a):
        return (int(c[0] * 255), int(c[1] * 255), int(c[2] * 255), int(a * 255))

    def _wrap(self, box):
        x0, y0, x1, y1 = box
        for dx in (-W, 0, W):
            for dy in (-W, 0, W):
                if x1 + dx >= 0 and x0 + dx < W and y1 + dy >= 0 and y0 + dy < W:
                    yield dx, dy

    def line(self, pts, c, a=1.0, width=2.0):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        for dx, dy in self._wrap((min(xs) - width, min(ys) - width, max(xs) + width, max(ys) + width)):
            self.d.line([(x + dx, y + dy) for x, y in pts], fill=self._rgba(c, a), width=max(1, int(round(width))), joint="curve")

    def blob(self, x, y, rx, ry, c, a=1.0, rot=0.0, n=10, rough=0.25, rng=None):
        """울퉁불퉁한 덩어리(돌 · 잎 · 얼룩)."""
        ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
        rr = 1.0 + ((rng.random(n) - 0.5) * 2 * rough if rng is not None else 0.0)
        px = np.cos(ang) * rx * rr
        py = np.sin(ang) * ry * rr
        cr, sr = np.cos(rot), np.sin(rot)
        pts = [(x + px[i] * cr - py[i] * sr, y + px[i] * sr + py[i] * cr) for i in range(n)]
        m = max(rx, ry) * 1.4
        for dx, dy in self._wrap((x - m, y - m, x + m, y + m)):
            self.d.polygon([(a_ + dx, b_ + dy) for a_, b_ in pts], fill=self._rgba(c, a))

    def over(self, img):
        """판을 그림(W, W, 3 · 0~1) 위에 얹는다."""
        o = np.asarray(self.im).astype(np.float32) / 255.0
        return img * (1 - o[..., 3:4]) + o[..., :3] * o[..., 3:4]

    def alpha(self):
        return np.asarray(self.im).astype(np.float32)[..., 3] / 255.0


def kuwahara(img, r):
    """붓 자국 뭉개기(이어지게) — 네 갈래 평균 가운데 밝기 흩어짐이 가장 작은 쪽."""
    lum = img @ np.array([0.3, 0.59, 0.11], np.float32)
    best_var = None
    out = None
    for dy, dx in ((-1, -1), (-1, 1), (1, -1), (1, 1)):
        sh = (dy * (r // 2 + 1), dx * (r // 2 + 1))
        m = np.stack([blur(np.roll(img[..., k], sh, (0, 1)), max(1, r // 2)) for k in range(3)], -1)
        lm = blur(np.roll(lum, sh, (0, 1)), max(1, r // 2))
        var = blur(np.roll(lum * lum, sh, (0, 1)), max(1, r // 2)) - lm * lm
        if out is None:
            out, best_var = m, var
        else:
            pick = var < best_var
            out = np.where(pick[..., None], m, out)
            best_var = np.where(pick, var, best_var)
    return out


def finish(img, target, desat=0.18, contrast=1.08, grain_seed=1):
    """색 정리(ART.md §2 — 채도 조금 빼고, 그늘은 적갈색 · 밝은 쪽은 누런빛) → 줄이기 → 평균을 타일 색에 맞춤 → uint8."""
    lum = (img @ np.array([0.3, 0.59, 0.11], np.float32))[..., None]
    img = img * (1 - desat) + lum * desat
    img = (img - 0.5) * contrast + 0.5
    img = img + (SHADOW - img) * np.clip(0.35 - lum, 0, 1) * 0.35 + (HIGH - img) * np.clip(lum - 0.6, 0, 1) * 0.12
    img = img * (1.0 + (pnoise(128, grain_seed)[..., None] - 0.5) * 0.05)
    small = np.asarray(Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8)).resize((S, S), Image.LANCZOS)).astype(np.float32) / 255.0
    mean = small.reshape(-1, 3).mean(0)
    gain = target / np.maximum(mean, 0.01)
    gl = float(target @ np.array([0.3, 0.59, 0.11])) / max(float(mean @ np.array([0.3, 0.59, 0.11])), 0.01)
    small = small * gl * np.clip(gain / gl, 0.85, 1.18)  # 밝기는 꼭 맞추고, 색은 조금만 당긴다(낙엽 · 돌이 바탕색에 물들지 않게)
    return (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)
