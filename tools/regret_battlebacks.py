#!/usr/bin/env python3
"""후회의 군주 전투 뒷그림(plans/expansion_f1_3_B §6-2 "그 길의 뒷그림 위에 잿빛 안개 — 어느 제단에서 불렀는지 보인다", AM72).
2층 네 길의 전투 뒷그림(assets/battle/f2_*.webp)을 잿빛으로 바래게 하고, 바닥에서 피어오르는 안개 띠 · 가장자리 어둠을 얹는다.
→ assets/battle/regret_<길>.webp. 층 JSON lord.battleback이 가리킨다(tools/floor_rift_gates.py LORDS).

    python3 tools/regret_battlebacks.py  → texture_compress.py → --import
"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ROADS = ["f2_beast_den", "f2_land_of_dead", "f2_rock_desert", "f2_goblin_forest"]
ASH = np.array([0.36, 0.36, 0.35], np.float32)


def noise(h, w, seed, scale):
    rng = np.random.default_rng(seed)
    small = rng.random((h // scale + 2, w // scale + 2)).astype(np.float32)
    img = Image.fromarray((small * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC)
    return np.asarray(img).astype(np.float32) / 255.0


def main():
    for k, road in enumerate(ROADS):
        src = os.path.join(ROOT, "assets", "battle", road + ".webp")
        a = np.asarray(Image.open(src).convert("RGB")).astype(np.float32) / 255.0
        h, w, _ = a.shape
        lum = a @ np.array([0.299, 0.587, 0.114], np.float32)
        grey = lum[..., None] * np.array([1.0, 1.0, 0.97], np.float32)
        out = a * 0.25 + grey * 0.75  # 색이 바랜다
        y = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None]
        n = noise(h, w, 31 + k, 48) * 0.6 + noise(h, w, 77 + k, 16) * 0.4
        fog = np.clip((y - 0.45) * 1.8, 0.0, 1.0) * (0.35 + 0.65 * n)  # 바닥에서 피어오르는 안개
        out = out * 0.82 * (1.0 - fog[..., None] * 0.5) + ASH * fog[..., None] * 0.5
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        r = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
        out *= (1.0 - np.clip(r - 0.75, 0.0, 1.0) * 0.6)[..., None]  # 가장자리 어둠
        dst = os.path.join(ROOT, "assets", "battle", "regret_" + road[3:] + ".webp")
        Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(dst, quality=90)
        print(road, "→", os.path.basename(dst))


if __name__ == "__main__":
    main()
