"""던전 에셋 키트 — 평면 그림 판(바닥 자국 · 벽 부착물). 마스크(0~1 배열)를 잡음 · 거리장으로 만들고 색을 얹는다.
좌표는 낼 그림의 px(왼쪽 위 0, 0). 안에서는 SS배로 칠해 줄인다(선이 부드럽다). 색 정리는 ART.md §2 그대로."""
import numpy as np
from PIL import Image, ImageFilter

F = np.float32
SS = 2
INK = np.array([0x16, 0x10, 0x0e], F) / 255.0
DARK = np.array([0x1a, 0x14, 0x12], F) / 255.0
HIGH = np.array([0xe0, 0xd2, 0xb0], F) / 255.0
LUM = np.array([0.3, 0.59, 0.11], F)


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], F) / 255.0


def sstep(x, a=0.0, b=1.0):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def vnoise(h, w, scale, seed):
    """값 잡음 0~1(scale px 격자)."""
    scale = max(1.0, float(scale))
    g = np.random.default_rng(seed).random((int(h / scale) + 3, int(w / scale) + 3)).astype(F)
    im = Image.fromarray((g * 255).astype(np.uint8)).resize((int(g.shape[1] * scale), int(g.shape[0] * scale)), Image.BICUBIC)
    return np.asarray(im).astype(F)[:h, :w] / 255.0


def gblur(a, r):
    return np.asarray(Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(r))).astype(F) / 255.0


def crack_paths(rng, x, y, ang, length, step=7.0, wander=0.5, branch=0.25, depth=2):
    """금 한 줄기(가지 포함) → [(점 목록, 굵기 배율)]."""
    out, pts, n = [], [(x, y)], max(2, int(length / step))
    for k in range(n):
        ang += rng.uniform(-wander, wander)
        x, y = x + np.cos(ang) * step, y + np.sin(ang) * step
        pts.append((x, y))
        if depth > 0 and rng.random() < branch:
            out += crack_paths(rng, x, y, ang + rng.choice([-1, 1]) * rng.uniform(0.5, 1.1), length * (1 - k / n) * rng.uniform(0.3, 0.6), step, wander, branch, depth - 1)
    return [(pts, 1.0 if depth == 2 else 0.6)] + out


class Canvas:
    def __init__(self, w, h, seed=1):
        self.w, self.h, self.seed = w, h, seed
        self.W, self.H = w * SS, h * SS
        self.rgb = np.zeros((self.H, self.W, 3), F)
        self.a = np.zeros((self.H, self.W), F)
        yy, xx = np.mgrid[0:self.H, 0:self.W]
        self.xx, self.yy = ((xx + 0.5) / SS).astype(F), ((yy + 0.5) / SS).astype(F)
        self.origin = (w * 0.5, h * 0.5)
        self.rng = np.random.default_rng(seed)
        self.graded = True
        self._n = 0

    # ── 마스크 만들기 ──
    def noise(self, scale, seed=None, octaves=3):
        if seed is None:
            self._n += 1
            seed = self.seed * 131 + self._n
        out, amp, tot = 0.0, 1.0, 0.0
        for o in range(octaves):
            out = out + vnoise(self.H, self.W, scale * SS / (2 ** o), seed + o * 7) * amp
            tot += amp
            amp *= 0.5
        return out / tot

    def dist(self, cx, cy, rx=1.0, ry=None, rot=0.0):
        """타원 거리(1 = 가장자리)."""
        ry = rx if ry is None else ry
        dx, dy = self.xx - cx, self.yy - cy
        if rot:
            c, s = np.cos(rot), np.sin(rot)
            dx, dy = dx * c + dy * s, -dx * s + dy * c
        return np.hypot(dx / rx, dy / ry)

    def blob(self, cx, cy, rx, ry=None, rough=0.3, scale=None, soft=0.08, rot=0.0, seed=None):
        """울퉁불퉁한 덩이 마스크(얼룩 · 웅덩이)."""
        d = self.dist(cx, cy, rx, ry, rot)
        n = self.noise(scale or max(rx, ry or rx) * 0.6, seed, 3)
        return sstep(1.0 + (n - 0.5) * 2 * rough - d, 0, soft)

    def seg(self, pts, width, taper=True, soft=0.7):
        """꺾은 선 마스크(굵기 width px, taper = 끝으로 갈수록 가늘게)."""
        m = np.zeros((self.H, self.W), F)
        n = len(pts) - 1
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            w0 = width * ((1 - i / n) ** 0.7 if taper else 1.0)
            w1 = width * ((1 - (i + 1) / n) ** 0.7 if taper else 1.0)
            pad = width + 2
            xa, xb = int((min(x0, x1) - pad) * SS), int((max(x0, x1) + pad) * SS) + 1
            ya, yb = int((min(y0, y1) - pad) * SS), int((max(y0, y1) + pad) * SS) + 1
            xa, ya, xb, yb = max(xa, 0), max(ya, 0), min(xb, self.W), min(yb, self.H)
            if xa >= xb or ya >= yb:
                continue
            px, py = self.xx[ya:yb, xa:xb] - x0, self.yy[ya:yb, xa:xb] - y0
            dx, dy = x1 - x0, y1 - y0
            t = np.clip((px * dx + py * dy) / max(dx * dx + dy * dy, 1e-6), 0, 1)
            d = np.hypot(px - t * dx, py - t * dy)
            ww = (w0 + (w1 - w0) * t) * 0.5
            m[ya:yb, xa:xb] = np.maximum(m[ya:yb, xa:xb], np.clip((ww - d) / soft + 0.5, 0, 1))
        return m

    def ring(self, cx, cy, r, width, soft=0.7, ry=None):
        d = np.abs(self.dist(cx, cy, r, ry) - 1.0) * (r if ry is None else min(r, ry))
        return np.clip((width * 0.5 - d) / soft + 0.5, 0, 1)

    def rect(self, x0, y0, x1, y1, soft=0.6):
        d = np.maximum(np.maximum(x0 - self.xx, self.xx - x1), np.maximum(y0 - self.yy, self.yy - y1))
        return np.clip(-d / soft + 0.5, 0, 1)

    def poly(self, pts):
        from PIL import ImageDraw
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([(x * SS, y * SS) for x, y in pts], fill=255)
        return np.asarray(im).astype(F) / 255.0

    def cracks(self, starts, width=2.2):
        """금 마스크: starts = [(x, y, 각도, 길이)]."""
        m = np.zeros((self.H, self.W), F)
        for x, y, ang, ln in starts:
            for pts, k in crack_paths(self.rng, x, y, ang, ln):
                m = np.maximum(m, self.seg(pts, width * k))
        return m

    def rim(self, mask, width=1.5):
        """마스크 가장자리 띠(잉크 테)."""
        b = gblur(mask, width * SS * 0.6)
        return np.clip(1.0 - np.abs(b - 0.5) * 2.6, 0, 1) * (mask > 0.02)

    # ── 칠하기 ──
    def paint(self, mask, color, alpha=1.0):
        """마스크 자리에 색을 얹는다(color = "#rrggbb" · (3,) · (H, W, 3))."""
        c = hexc(color) if isinstance(color, str) else np.asarray(color, F)
        m = np.clip(mask * alpha, 0, 1)
        na = m + self.a * (1 - m)
        if c.ndim == 1:
            c = c[None, None, :]
        self.rgb = (c * m[..., None] + self.rgb * (self.a * (1 - m))[..., None]) / np.maximum(na, 1e-4)[..., None]
        self.a = na

    def shade(self, mask, k):
        """이미 칠한 곳의 밝기를 바꾼다(k < 0 어둡게 · > 0 밝게)."""
        self.rgb = np.clip(self.rgb * (1.0 + mask[..., None] * k), 0, 1)

    def add(self, mask, color, strength=1.0):
        """더하기 빛(빛나는 룬 · 균열): 색을 더하고, 투명한 곳은 그 빛만큼 보이게."""
        c = hexc(color) if isinstance(color, str) else np.asarray(color, F)
        m = np.clip(mask * strength, 0, 1)
        na = np.maximum(self.a, m)
        self.rgb = np.clip((self.rgb * self.a[..., None] + c[None, None, :] * m[..., None]) / np.maximum(na, 1e-4)[..., None], 0, 1)
        self.a = na

    def glow(self, mask, color, radius, strength=0.6):
        self.add(gblur(mask, radius * SS) * 1.6, color, strength)

    def relief(self, height, k=2.0):
        """높이장을 왼쪽 위 빛으로 본 밝기 배율을 지금 그림에 곱한다."""
        gx = np.roll(height, -1, 1) - np.roll(height, 1, 1)
        gy = np.roll(height, -1, 0) - np.roll(height, 1, 0)
        self.rgb = np.clip(self.rgb * np.clip(1.0 - (gx * 0.7 + gy * 0.75) * k * SS, 0.4, 1.7)[..., None], 0, 1)

    def result(self):
        rgb = self.rgb
        if self.graded:   # 색 정리(ART.md §2)
            lum = (rgb @ LUM)[..., None]
            rgb = rgb * 0.82 + lum * 0.18
            rgb = (rgb - 0.5) * 1.08 + 0.5
            rgb = rgb + (DARK - rgb) * np.clip(0.3 - lum, 0, 1) * 0.4 + (HIGH - rgb) * np.clip(lum - 0.62, 0, 1) * 0.12
            rgb = rgb * (1.0 + (vnoise(self.H, self.W, 1, self.seed + 8)[..., None] - 0.5) * 0.05)
        out = np.concatenate([np.clip(rgb, 0, 1), np.clip(self.a, 0, 1)[..., None]], -1)
        im = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGBA")
        # 줄일 때 투명한 곳의 색이 번지지 않게 미리 곱한 알파로
        pm = np.asarray(im).astype(F) / 255.0
        pm[..., :3] *= pm[..., 3:4]
        small = np.asarray(Image.fromarray((pm * 255 + 0.5).astype(np.uint8), "RGBA").resize((self.w, self.h), Image.LANCZOS)).astype(F) / 255.0
        a = small[..., 3:4]
        small[..., :3] = np.where(a > 1e-3, small[..., :3] / np.maximum(a, 1e-3), 0)
        return (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)
