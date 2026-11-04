"""실내 그림 굽기 바탕(CT106 — tools/interior_bake.py 전용): 3/4 시점(화면 = (x, y − z) × 칸 px) 그림판.
면마다 날 색(raw) · 면 번호(code — town_handdrawn.finish가 번호가 바뀌는 곳에 먹선을 긋는다) · 빛 받기(lit)를 칠한다.
재질(tex)은 칸 좌표를 받아 색과 작은 면 번호(판자 · 돌 하나하나)를 돌려주는 함수 — 먹선이 돌 · 판자마다 생긴다.
"""
import math

import numpy as np
from PIL import Image, ImageDraw

P = 48  # 그림 px / 칸 (게임에서 32px 칸으로 줄여 그린다 — index.json tile)


def hexc(s):
    s = s.lstrip("#")
    return np.array([int(s[i:i + 2], 16) for i in (0, 2, 4)], np.float32) / 255.0


def hash2(i, j, seed):
    h = (np.asarray(i).astype(np.int64) * 374761393 + np.asarray(j).astype(np.int64) * 668265263 + seed * 2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF).astype(np.float32) / 65535.0


def vnoise(x, y, scale, seed):
    """값 잡음 0~1(쌍선형, 칸 좌표 x · y 배열)."""
    gx, gy = x / scale, y / scale
    ix, iy = np.floor(gx).astype(np.int64), np.floor(gy).astype(np.int64)
    fx, fy = gx - ix, gy - iy
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    a = hash2(ix, iy, seed)
    b = hash2(ix + 1, iy, seed)
    c = hash2(ix, iy + 1, seed)
    d = hash2(ix + 1, iy + 1, seed)
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


class Canvas:
    """origin = 그림 왼쪽 위의 칸 좌표(x, 화면 y). 그리는 함수는 모두 칸 좌표(세계 x, y, 높이 z)."""

    def __init__(self, ox, oy, w_tiles, h_tiles, seed=1):
        self.ox, self.oy = ox, oy
        self.W, self.H = int(math.ceil(w_tiles * P)), int(math.ceil(h_tiles * P))
        self.raw = np.zeros((self.H, self.W, 3), np.float32)
        self.code = np.zeros((self.H, self.W), np.int64)
        self.lit = np.ones((self.H, self.W), np.float32)  # 빛을 받는 정도(0 = 늘 어두움 — 문 너머 어둠)
        self.glow = np.zeros((self.H, self.W), np.float32)  # 스스로 빛남(불 · 유리 — 어둡게 내리지 않는다)
        self.seed = seed
        self._next = 1

    def new_id(self, n=1):
        i = self._next
        self._next += n
        return i

    def to_px(self, x, y, z=0.0):
        return ((x - self.ox) * P, (y - z - self.oy) * P)

    def _mask(self, pts):
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        x0, y0 = max(0, int(math.floor(min(xs)))), max(0, int(math.floor(min(ys))))
        x1, y1 = min(self.W, int(math.ceil(max(xs))) + 1), min(self.H, int(math.ceil(max(ys))) + 1)
        if x1 <= x0 or y1 <= y0:
            return None
        im = Image.new("L", (x1 - x0, y1 - y0), 0)
        ImageDraw.Draw(im).polygon([(p[0] - x0, p[1] - y0) for p in pts], fill=255)
        m = np.asarray(im) > 127
        if not m.any():
            return None
        return (slice(y0, y1), slice(x0, x1)), m

    def fill(self, pts_px, color, cid=None, tex=None, shade=None, lit=1.0, glow=0.0, keep_code=False):
        """화면 px 다각형 하나. color = (3,) 또는 tex(u, v → (rgb, sub_id|None)) — u · v = 칸 좌표(화면). shade = (위, 아래) 밝기 배율."""
        mk = self._mask(pts_px)
        if mk is None:
            return None
        sl, m = mk
        if cid is None:
            cid = self.new_id()
        ys, xs = np.mgrid[sl[0], sl[1]]
        u = xs / P + self.ox
        v = ys / P + self.oy
        sub = None
        if tex is not None:
            rgb, sub = tex(u, v)
        else:
            rgb = np.broadcast_to(np.asarray(color, np.float32), u.shape + (3,))
        if shade is not None:
            top = min(p[1] for p in pts_px)
            bot = max(p[1] for p in pts_px)
            k = np.clip((ys - top) / max(1.0, bot - top), 0, 1)
            rgb = rgb * (shade[0] + (shade[1] - shade[0]) * k)[..., None]
        reg = self.raw[sl]
        reg[m] = rgb[m]
        if not keep_code:
            c = self.code[sl]
            c[m] = (cid * 4096 + (sub[m] % 4096)) if sub is not None else cid * 4096
        self.lit[sl][m] = lit
        self.glow[sl][m] = glow
        return cid

    # 세계 좌표 도형 -------------------------------------------------------

    def ground(self, x0, y0, x1, y1, color=None, tex=None, z=0.0, **kw):
        """바닥에 누운 네모(높이 z)."""
        pts = [self.to_px(x0, y0, z), self.to_px(x1, y0, z), self.to_px(x1, y1, z), self.to_px(x0, y1, z)]
        return self.fill(pts, color, tex=tex, **kw)

    def front(self, x0, x1, y, z0, z1, color=None, tex=None, shade=(0.82, 0.62), **kw):
        """남쪽을 보는 세운 면(y = 그 면의 땅 자리)."""
        pts = [self.to_px(x0, y, z1), self.to_px(x1, y, z1), self.to_px(x1, y, z0), self.to_px(x0, y, z0)]
        return self.fill(pts, color, tex=tex, shade=shade, **kw)

    def box(self, x0, y0, x1, y1, z0, z1, top, side=None, tex_top=None, tex_side=None, shade=(0.8, 0.58)):
        """상자: 앞면(남) + 윗면. top · side = 색."""
        side = top * 0.72 if side is None else side
        self.front(x0, x1, y1, z0, z1, side, tex=tex_side, shade=shade)
        self.ground(x0, y0, x1, y1, top, tex=tex_top, z=z1)
        e = min(0.035, (y1 - y0) * 0.25)  # 윗면 앞 모서리 빛(두께가 보이게 — CT112)
        if e > 0.004:
            self.edge_light(x0, x1, y1, z1, e)

    def edge_light(self, x0, x1, y, z, e=0.03, k=1.28):
        """윗면 앞 모서리(y) 띠를 밝게 — 면 번호는 그대로(먹선이 생기지 않게)."""
        pts = [self.to_px(x0, y - e, z), self.to_px(x1, y - e, z), self.to_px(x1, y, z), self.to_px(x0, y, z)]
        mk = self._mask(pts)
        if mk is None:
            return
        sl, m = mk
        reg = self.raw[sl]
        reg[m] = np.clip(reg[m] * k, 0, 1)

    def ellipse_pts(self, cx, cy, rx, ry, z, n=28, a0=0.0, a1=math.tau):
        return [self.to_px(cx + rx * math.cos(a0 + (a1 - a0) * i / n), cy + ry * math.sin(a0 + (a1 - a0) * i / n), z) for i in range(n + 1)]

    def cyl(self, cx, cy, r, z0, z1, top, side=None, ry=None, tex_side=None, tex_top=None):
        """기둥 · 통: 아래 반 둘레(옆면) + 윗면 원(땅에 누운 원은 화면에서도 원 — 3/4)."""
        ry = r if ry is None else ry
        side = top * 0.72 if side is None else side
        lo = self.ellipse_pts(cx, cy, r, ry, z0, 20, 0, math.pi)
        hi = self.ellipse_pts(cx, cy, r, ry, z1, 20, math.pi, 0)
        pts = lo + hi
        self.fill(pts, side, tex=tex_side, shade=None)
        self._cyl_shade(cx, r, pts)
        cid = self.fill(self.ellipse_pts(cx, cy, r, ry, z1), top, tex=tex_top)
        if r > 0.08:  # 윗면 앞쪽 테 빛(CT112)
            ring = self.ellipse_pts(cx, cy, r, ry, z1, 20, 0.15, math.pi - 0.15) + self.ellipse_pts(cx, cy - 0.04, r * 0.93, ry * 0.93, z1, 20, math.pi - 0.15, 0.15)
            mk = self._mask(ring)
            if mk is not None:
                sl, m = mk
                reg = self.raw[sl]
                reg[m] = np.clip(reg[m] * 1.22, 0, 1)
        return cid

    def _cyl_shade(self, cx, r, pts):
        """둥근 옆면: 왼쪽이 밝고 오른쪽이 어둡다(빛 = 왼쪽 위)."""
        mk = self._mask(pts)
        if mk is None:
            return
        sl, m = mk
        xs = np.mgrid[sl[0], sl[1]][1] / P + self.ox
        k = np.clip((xs - (cx - r)) / max(1e-3, 2 * r), 0, 1)
        f = 1.08 - 0.5 * k ** 1.3
        reg = self.raw[sl]
        reg[m] = reg[m] * f[m][:, None]

    def shadow(self, cx, cy, rx, ry, a=0.45):
        """바닥 접지 그늘(부드러운 타원 — 먹선 없음: 면 번호를 바꾸지 않는다)."""
        x0, y0 = self.to_px(cx - rx * 1.3, cy - ry * 1.3)
        x1, y1 = self.to_px(cx + rx * 1.3, cy + ry * 1.3)
        xa, ya, xb, yb = max(0, int(x0)), max(0, int(y0)), min(self.W, int(x1) + 1), min(self.H, int(y1) + 1)
        if xb <= xa or yb <= ya:
            return
        ys, xs = np.mgrid[ya:yb, xa:xb]
        u = (xs / P + self.ox - cx) / rx
        v = (ys / P + self.oy - cy) / ry
        d = np.sqrt(u * u + v * v)
        k = np.clip(1.0 - d, 0, 1) ** 0.8 * a
        reg = self.raw[ya:yb, xa:xb]
        has = self.code[ya:yb, xa:xb] != 0
        reg[has] *= (1 - k[has])[:, None]

    def darken_rect(self, x0, y0, x1, y1, a_top, a_bot, z=0.0):
        """바닥 그늘 띠(위→아래로 a_top → a_bot)."""
        px0, py0 = self.to_px(x0, y0, z)
        px1, py1 = self.to_px(x1, y1, z)
        xa, ya, xb, yb = max(0, int(px0)), max(0, int(py0)), min(self.W, int(px1)), min(self.H, int(py1))
        if xb <= xa or yb <= ya:
            return
        k = np.linspace(a_top, a_bot, yb - ya, dtype=np.float32)[:, None]
        reg = self.raw[ya:yb, xa:xb]
        has = (self.code[ya:yb, xa:xb] != 0)[..., None]
        reg[:] = np.where(has, reg * (1 - k[..., None]), reg)

    def darken_cols(self, x0, y0, x1, y1, a_left, a_right, z=0.0):
        px0, py0 = self.to_px(x0, y0, z)
        px1, py1 = self.to_px(x1, y1, z)
        xa, ya, xb, yb = max(0, int(px0)), max(0, int(py0)), min(self.W, int(px1)), min(self.H, int(py1))
        if xb <= xa or yb <= ya:
            return
        k = np.linspace(a_left, a_right, xb - xa, dtype=np.float32)[None, :]
        reg = self.raw[ya:yb, xa:xb]
        has = (self.code[ya:yb, xa:xb] != 0)[..., None]
        reg[:] = np.where(has, reg * (1 - k[..., None]), reg)

    def line(self, a, b, width, color, cid=None):
        """두께 있는 선(칸 좌표 화면 점 a · b — 세계 점은 to_px로 바꿔 넘긴다)."""
        (x0, y0), (x1, y1) = a, b
        dx, dy = x1 - x0, y1 - y0
        L = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / L * width * 0.5, dx / L * width * 0.5
        return self.fill([(x0 + nx, y0 + ny), (x1 + nx, y1 + ny), (x1 - nx, y1 - ny), (x0 - nx, y0 - ny)], color, cid=cid)

    # 빛 ---------------------------------------------------------------

    def light(self, ambient, lights):
        """빛 배율: ambient + 빛마다 (1 − d)² × 세기(빛 색을 띤다). lights = [(x, 화면 y(칸), 반지름, 색, 세기)]."""
        ys, xs = np.mgrid[0:self.H, 0:self.W]
        u = xs / P + self.ox
        v = ys / P + self.oy
        f = np.full((self.H, self.W, 3), ambient, np.float32)
        for (lx, ly, r, col, pw) in lights:
            d = np.sqrt((u - lx) ** 2 + ((v - ly) * 1.15) ** 2) / r
            k = np.clip(1 - d, 0, 1) ** 2 * pw
            f += k[..., None] * (0.55 + 0.45 * np.asarray(col, np.float32) / max(1e-3, float(np.max(col))))
        f = np.minimum(f, 1.35)
        k = self.lit[..., None]
        f = f * k + (1 - k) * np.minimum(f, ambient * 0.5)
        self.raw = self.raw * f
        self.raw = self.raw * (1 - self.glow[..., None]) + self.raw / np.maximum(f, 1e-3) * self.glow[..., None]
