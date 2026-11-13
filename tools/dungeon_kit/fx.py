"""던전 에셋 키트 — 덩어리 그림 위에 얹는 평면 효과(불꽃 · 연기 · 가스 · 반짝임). 색 정리 뒤에 얹는다(ART.md §5 — 앞에 칠하면 누렇게 죽는다).
모두 (img RGBA uint8, …) → img. 좌표는 그림 px. f = 애니메이션 프레임 번호(같은 seed에서 f만 바꾸면 이어지는 일렁임)."""
import numpy as np

from paint2d import gblur, hexc, sstep, vnoise

F = np.float32
PAL = {
    "fire": ("#b83a14", "#ee8a2a", "#ffe6a0", "#f0a040"),
    "blue": ("#2a4aa8", "#58a0e8", "#dcf2ff", "#60a0f0"),
    "red": ("#7a1020", "#d83a48", "#ffd2cc", "#e04050"),
    "green": ("#2a5a22", "#6ab848", "#e2f8b8", "#70c050"),
    "violet": ("#4a2a88", "#9a68e0", "#ecdcff", "#a070e0"),
}


def _over(img, mask, color):
    rgb, a = img[..., :3].astype(F) / 255.0, img[..., 3].astype(F) / 255.0
    m = np.clip(mask, 0, 1)
    na = m + a * (1 - m)
    rgb = (color[None, None, :] * m[..., None] + rgb * (a * (1 - m))[..., None]) / np.maximum(na, 1e-4)[..., None]
    return (np.concatenate([np.clip(rgb, 0, 1), na[..., None]], -1) * 255 + 0.5).astype(np.uint8)


def halo(img, cx, cy, r, color, strength=0.6):
    import solid
    return solid.add_glow(img, cx, cy, r, hexc(color) if isinstance(color, str) else color, strength)


def flame(img, cx, cy, h, seed=1, f=0, pal="fire", width=0.42, glow=2.6, strength=0.55):
    """불꽃: 밑 (cx, cy)에서 위로 h px. 세 겹(바깥 · 가운데 · 속심) + 빛 무리."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    t = (cy - yy) / h                                    # 0 밑 → 1 끝
    ph = seed * 1.7 + f * 1.9
    sway = (np.sin(t * 5.0 + ph) * 0.10 + np.sin(t * 11.0 + ph * 1.7) * 0.05) * h * t
    edge = (vnoise(hh, ww, max(2.0, h * 0.14), seed * 13 + f * 5) - 0.5) * 0.36
    out = img
    cols = PAL[pal]
    for k, (sc, top) in enumerate(((1.0, 1.0), (0.66, 0.74), (0.34, 0.46))):
        tt = t / top
        prof = np.where((tt > -0.08) & (tt < 1), np.clip(np.sin(np.pi * np.clip(tt + 0.08, 0, 1.08) ** 0.62 / 1.08 ** 0.62), 0, 1) ** 0.9, 0.0)
        half = prof * h * width * sc * (1.0 + edge * (1.5 - k * 0.4))
        m = np.clip((half - np.abs(xx - cx - sway * (1.0 - k * 0.2))) / 1.2 + 0.5, 0, 1) * (tt > -0.08) * (tt < 1)
        out = _over(out, m * (0.92 if k == 0 else 1.0), hexc(cols[k]))
    rng = np.random.default_rng(seed * 7 + f)
    for _ in range(3):                                   # 튀는 불티
        sx, sy = cx + rng.uniform(-0.4, 0.4) * h, cy - h * rng.uniform(0.9, 1.5)
        out = _over(out, np.clip(1.6 - np.hypot(xx - sx, yy - sy), 0, 1), hexc(cols[1]))
    return halo(out, cx, cy - h * 0.45, h * glow, cols[3], strength)


def embers(img, cx, cy, rx, ry, seed=1, f=0, pal="fire"):
    """달아오른 숯불 바닥(화로 속): 얼룩진 붉은 빛."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    d = np.hypot((xx - cx) / rx, (yy - cy) / ry)
    n = vnoise(hh, ww, 3.0, seed * 3 + f)
    out = _over(img, sstep(1.0 - d, 0, 0.3) * (0.55 + n * 0.45), hexc(PAL[pal][0]))
    return _over(out, sstep(n - 0.55 - d * 0.2, 0, 0.2) * (d < 0.9), hexc(PAL[pal][1]))


def puff(img, cx, cy, r, color="#8a8a80", alpha=0.5, seed=1, f=0, rise=0.0, n=6):
    """연기 · 가스 뭉치: 부드러운 덩이 여러 개가 위로 퍼진다(rise = 위로 번지는 높이 px)."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    rng = np.random.default_rng(seed * 11 + f * 3)
    m = np.zeros((hh, ww), F)
    for i in range(n):
        t = (i + rng.random()) / n
        px, py = cx + rng.uniform(-0.6, 0.6) * r * (0.5 + t), cy - rise * t + rng.uniform(-0.2, 0.2) * r
        rr = r * (0.45 + 0.55 * t) * rng.uniform(0.7, 1.1)
        m = np.maximum(m, sstep(1.0 - np.hypot(xx - px, yy - py) / rr, 0, 0.7) * (1.0 - t * 0.55))
    m = m * (0.7 + vnoise(hh, ww, max(2.0, r * 0.3), seed + f) * 0.5)
    return _over(img, gblur(m, 1.0) * alpha, hexc(color))


def sparkle(img, pts, color="#dcefff", size=2.2):
    """반짝이는 점(수정 · 마력): 작은 십자 빛."""
    hh, ww = img.shape[:2]
    yy, xx = np.mgrid[0:hh, 0:ww].astype(F)
    m = np.zeros((hh, ww), F)
    for x, y in pts:
        dx, dy = np.abs(xx - x), np.abs(yy - y)
        m = np.maximum(m, np.maximum(np.clip(1 - dx / (size * 2.2), 0, 1) * np.clip(1 - dy / 0.9, 0, 1), np.clip(1 - dy / (size * 2.2), 0, 1) * np.clip(1 - dx / 0.9, 0, 1)))
    return _over(img, m, hexc(color))


def tint(img, color, amount=0.3, where=None):
    """칠한 곳에 색 빛을 입힌다(마력에 물든 돌)."""
    rgb, a = img[..., :3].astype(F) / 255.0, img[..., 3:4].astype(F) / 255.0
    k = amount * (a[..., 0] > 0.5) * (1.0 if where is None else where)
    rgb = rgb + (hexc(color)[None, None, :] - rgb) * k[..., None]
    return (np.concatenate([np.clip(rgb, 0, 1), a], -1) * 255 + 0.5).astype(np.uint8)
