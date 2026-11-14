#!/usr/bin/env python3
"""3층 재질 그림(assets/floor/f3): 1 · 2층 손그림 재질을 지역 빛깔로 다시 칠한다(색상 · 채도 · 밝기만 — 붓결 · 모양은 그대로).
지역을 이름 없이도 알아보게(사용자 명세 — 갈대 = 마른 짚빛, 마녀의 숲 = 잿보랏빛, 황혼 = 붉은 노을빛 …).
  python3 tools/f3_art.py   (그 뒤 godot --headless --path . --import)
[창작]"""
import colorsys
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "assets", "floor")
OUT = os.path.join(SRC, "f3")

# 새 그림: (원본, 색상 목표(0~1, None = 그대로), 색상을 얼마나 그쪽으로(0~1), 채도 배율, 밝기 배율)
JOBS = {
    "reeds": ("f2g/undergrowth", 0.12, 0.85, 0.85, 1.25),      # 가시갈대 숲 — 마른 짚빛
    "reedground": ("f2g/clearing", 0.13, 0.8, 0.7, 1.1),       # 갈대 사이 땅
    "thorns": ("f2d/bank", 0.78, 0.55, 1.6, 0.85),             # 마녀의 숲 둔덕 — 잿보랏빛 흙
    "witchearth": ("f2d/graveearth", 0.76, 0.5, 1.5, 0.95),     # 마녀의 숲 바닥
    "duskearth": ("f2d/dryearth", 0.03, 0.7, 1.7, 1.08),       # 황혼의 비탈 — 노을빛 바위 땅
    "steelrock": ("f2d/dryearth", 0.6, 0.4, 0.8, 1.12),        # 강철바위 — 푸른 잿빛
    "marshfloor": ("f2g/forestfloor", 0.25, 0.4, 1.15, 1.05),  # 녹빛꼬리 습지 — 밝은 녹빛
    "reeds_floor": ("f2g/forestfloor", 0.12, 0.9, 0.8, 1.35),  # 성긴 갈대(헤치고 지나가는 땅 — 짚 · 줄기)
    "witchroot": ("f2g/forestfloor", 0.8, 0.6, 1.0, 0.85),     # 마녀의 숲 엉킨 뿌리
    "steelgrass": ("f2g/clearing", 0.28, 0.3, 0.9, 1.05),      # 언덕 풀밭
}


def recolor(img, hue, pull, sat, val):
    a = np.asarray(img.convert("RGBA")).astype(np.float32) / 255.0
    rgb, alpha = a[..., :3], a[..., 3:]
    hsv = np.zeros_like(rgb)
    flat = rgb.reshape(-1, 3)
    out = np.array([colorsys.rgb_to_hsv(*p) for p in flat]).reshape(rgb.shape)
    h, s, v = out[..., 0], out[..., 1], out[..., 2]
    if hue is not None:
        d = ((hue - h + 0.5) % 1.0) - 0.5
        h = (h + d * pull) % 1.0
    s = np.clip(s * sat, 0, 1)
    v = np.clip(v * val, 0, 1)
    back = np.array([colorsys.hsv_to_rgb(*p) for p in np.stack([h, s, v], -1).reshape(-1, 3)]).reshape(rgb.shape)
    res = np.concatenate([back, alpha], -1)
    return Image.fromarray((res * 255).round().astype(np.uint8), "RGBA")


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (src, hue, pull, sat, val) in JOBS.items():
        im = Image.open(os.path.join(SRC, src + ".webp"))
        mode = im.mode
        res = recolor(im, hue, pull, sat, val)
        if mode == "RGB":
            res = res.convert("RGB")
        path = os.path.join(OUT, name + ".webp")
        res.save(path, lossless=True, quality=100)
        print("그림:", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
