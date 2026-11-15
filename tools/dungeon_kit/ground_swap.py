#!/usr/bin/env python3
"""에셋 라이브러리 → 탐험 바닥 재질 갈아 끼우기(AM71 — 사용자 2026-11-15 "범용 에셋을 게임에 적용").

1층 · 균열의 바닥은 64px 칸 변형 띠(칸마다 무작위 변형 — 칸 격자가 보인다)다. 키트 바닥(4 × 4칸 이어지는 그림 · 돌마다 입체)이 월등한 곳만
키트 그림으로 바꾸되, 곳마다 색이 그곳의 분위기(핏빛성채 검붉음 · 빙하 푸름)라 옛 재질의 채널 평균 · 퍼짐에 맞춰 다시 칠한다
(키트의 명암 대비는 0.85 ~ 1.2배 안에서만 바꾼다 — 입체가 남게). → assets/floor/kit/<이름>.webp, tiles.json의 art.atlas를 그 그림 + span 4로.
유지(옛 것이 낫거나 키트에 없다): 2 · 3층 바닥(키트 바닥과 같은 생성기로 그린 넓은 그림 — 색만 다르다) · 묘지 흙(풀 결) · 눈밭(키트 눈이 밋밋) ·
탄광 흙 · 성채 흙(옛 것이 더 세밀) · 강철판(키트에 쇠 바닥 없음) · 벽(게임 벽은 동굴 꼴 윤곽 · 사방 면 — 키트는 북쪽 곧은 벽뿐).
  python3 tools/dungeon_kit/ground_swap.py [--preview=<png>] | --revert   → texture_compress.py → --import → 캡처
"""
import json
import os
import re
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
TILES = os.path.join(ROOT, "data", "tiles.json")
CONTRAST = (0.85, 1.2)

# 옛 아틀라스 → (키트 바닥, 새 이름)
SWAP = {
    # 1층 수정동굴 바닥(f1/limestone) = 사용자 요청으로 옛 그림 유지(2026-11-15 "1층 수정동굴 바닥만 롤백해")
    "bf/cobble.webp": ("floor_cobble.a", "ground_fortress"),    # 핏빛성채 돌바닥
    "gc/ice.webp": ("ground_ice.a", "ground_glacier"),          # 빙하굴 얼음
    "it/flagstone.webp": ("floor_flag.b", "ground_tomb"),       # 강철의 묘 판석
}


def recolor(kit_rgb, old_rgb):
    k = kit_rgb.reshape(-1, 3)
    o = old_rgb.reshape(-1, 3)
    out = np.empty_like(kit_rgb)
    for c in range(3):
        mk, sk = k[:, c].mean(), k[:, c].std() + 1e-3
        mo, so = o[:, c].mean(), o[:, c].std()
        r = float(np.clip(so / sk, *CONTRAST))
        out[..., c] = (kit_rgb[..., c] - mk) * r + mo
    return np.clip(out, 0, 1)


def main():
    revert = "--revert" in sys.argv
    text = open(TILES, encoding="utf-8").read()
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    previews = []
    for old, (ref, name) in SWAP.items():
        new = "kit/%s.webp" % name
        if revert:
            text, n = re.subn(r'"atlas": "res://assets/floor/%s", "variants": (\d+), "span": 4' % re.escape(new),
                              lambda m: '"atlas": "res://assets/floor/%s", "variants": %s' % (old, m.group(1)), text)
            print("%s ← %s: 타일 %d" % (old, new, n))
            continue
        aid, _, var = ref.partition(".")
        a = kit["assets"][aid]
        x, y, w, h, _ox, _oy = a["variants"][var]["frames"][0]
        sheet = Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGB")
        kimg = np.asarray(sheet.crop((int(x), int(y), int(x + w), int(y + h)))).astype(np.float32) / 255.0
        oimg = np.asarray(Image.open(os.path.join(ROOT, "assets", "floor", old)).convert("RGB")).astype(np.float32) / 255.0
        img = recolor(kimg, oimg)
        dst = os.path.join(ROOT, "assets", "floor", new)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        Image.fromarray((img * 255 + 0.5).astype(np.uint8), "RGB").save(dst, lossless=True, quality=100, exact=True)
        text, n = re.subn(r'"atlas": "res://assets/floor/%s", "variants": (\d+)(?!, "span")' % re.escape(old),
                          lambda m: '"atlas": "res://assets/floor/%s", "variants": %s, "span": 4' % (new, m.group(1)), text)
        print("%s → %s(%s): 타일 %d" % (old, new, ref, n))
        previews.append((oimg, img))
    open(TILES, "w", encoding="utf-8").write(text)
    for a in sys.argv[1:]:
        if a.startswith("--preview=") and previews:
            T = 64
            sheet = Image.new("RGB", (2 * 512 + 16, len(previews) * 272), (20, 20, 20))
            for k, (o, n) in enumerate(previews):
                nv = o.shape[1] // T
                for i in range(8):
                    for j in range(4):
                        v = (i * 7 + j * 13 + i * j) % nv
                        sheet.paste(Image.fromarray((o[:, v * T:(v + 1) * T] * 255).astype(np.uint8)), (i * T, k * 272 + j * T))
                tile = Image.fromarray((n * 255).astype(np.uint8))
                sheet.paste(tile, (528, k * 272))
                sheet.paste(tile, (784, k * 272))
            sheet.save(a[len("--preview="):])


if __name__ == "__main__":
    main()
