#!/usr/bin/env python3
"""던전 에셋 키트 → 게임 소품 시트(AM66): 탐험 화면의 동굴 요소 소품(타일 art.prop — 시체 · 해골 · 모닥불 · 석순 · 버섯 · 궤짝 …)을 키트 그림으로 바꾼다.
게임은 칸 크기가 같은 시트(8열 · 칸 128px)에서 칸 번호로 소품을 그린다(DecorChunk) — 그 틀은 그대로 두고,
옛 시트(assets/floor/f1/props.webp — 건드리지 않는다)를 바탕으로 PROPS에 적은 칸만 키트 그림으로 갈아 끼운 새 시트를 만든다.
  python3 tools/dungeon_kit/game_props.py [--preview=<png>]   → assets/floor/kit/props.webp  (그 뒤 texture_compress.py → --import → 캡처)
타일이 가리키는 시트 경로 · 칸 번호는 data/tiles.json art.prop(되돌리려면 sheet를 f1/props.webp로). 칸 32부터는 키트로 새로 생긴 칸.
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import compose  # noqa: E402
import kit  # noqa: E402

CELL, COLS, ROWS = 128, 8, 5
OLD = os.path.join(kit.ROOT, "assets", "floor", "f1", "props.webp")
OUT = os.path.join(kit.ROOT, "assets", "floor", "kit", "props.webp")
# 칸 번호 → (키트 id, 변형, 프레임, 칸에 맞출 가장 큰 폭 px) — 옛 그림과 같은 뜻의 것만 바꾼다(포탈 · 덫 · 노움 물건 · 발자국은 옛 그림 그대로)
PROPS = {
    # 0 탐험가의 시체 · 1 갉아먹힌 시체 더미 = 옛 그림(사용자 2026-11-13 "시체는 원래 거로 롤백해")
    3: ("firepit", "cold", 0, 84),              # 꺼진 모닥불 자리
    4: ("broken_weapon", "pile", 0, 96),        # 부서진 장비 더미
    8: ("stalagmite", "cluster", 0, 96),        # 석순 숲
    9: ("toadstool", "glow_a", 0, 64),          # 수정 버섯
    10: ("nest", "base", 0, 90),                # 뼈와 털 무더기
    13: ("firepit", "lit", 0, 100),             # 고블린 모닥불
    15: ("skeleton", "lying", 0, 116),          # 오래된 해골
    32: ("chest", "closed", 0, 76),             # 궤짝(2층 — 옛 시트는 1층 돌무더기 그림을 같이 썼다)
    33: ("chest", "locked", 0, 76),             # 족장 궤짝
}


def cell_image(id, variant, frame, max_w):
    img, _ = compose._img(id, variant, frame)
    # 바닥 그림자 · 빛 무리(반투명)는 뺀다 — 게임이 살필 수 있는 소품에 두르는 검은 테두리(Outline)가 그림자까지 감싸 덩어리로 보인다
    body = img[..., 3] >= 200
    near = body.copy()
    near[1:] |= body[:-1]
    near[:-1] |= body[1:]
    near[:, 1:] |= body[:, :-1]
    near[:, :-1] |= body[:, 1:]
    img = img.copy()
    img[~near] = 0
    ys, xs = np.flatnonzero(near.any(1)), np.flatnonzero(near.any(0))
    img = img[ys[0]:ys[-1] + 1, xs[0]:xs[-1] + 1]
    h, w = img.shape[:2]
    k = min(1.0, max_w / w, (CELL - 6) / h)
    if k < 1.0:
        pm = img.astype(np.float32) / 255.0
        pm[..., :3] *= pm[..., 3:4]
        small = np.asarray(Image.fromarray((pm * 255 + 0.5).astype(np.uint8), "RGBA").resize((max(1, round(w * k)), max(1, round(h * k))), Image.LANCZOS)).astype(np.float32) / 255.0
        a = small[..., 3:4]
        small[..., :3] = np.where(a > 1e-3, small[..., :3] / np.maximum(a, 1e-3), 0)
        img = (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)
    h, w = img.shape[:2]
    out = np.zeros((CELL, CELL, 4), np.uint8)
    x = (CELL - w) // 2
    y = min(CELL - 3 - h, max(0, 88 - h // 2))   # 옛 그림처럼 칸 가운데보다 조금 아래에 놓인다
    out[y:y + h, x:x + w] = img
    return out


def main():
    kit.load_all()
    old = np.asarray(Image.open(OLD).convert("RGBA"))
    sheet = np.zeros((ROWS * CELL, COLS * CELL, 4), np.uint8)
    sheet[:old.shape[0], :old.shape[1]] = old
    for cell, (id, variant, frame, max_w) in PROPS.items():
        y, x = (cell // COLS) * CELL, (cell % COLS) * CELL
        sheet[y:y + CELL, x:x + CELL] = cell_image(id, variant, frame, max_w)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    Image.fromarray(sheet, "RGBA").save(OUT, lossless=True, quality=100, exact=True)
    print("소품 시트:", os.path.relpath(OUT, kit.ROOT), "— 키트 칸", sorted(PROPS))
    preview = next((a[10:] for a in sys.argv if a.startswith("--preview=")), None)
    if preview:
        bg = Image.new("RGB", (sheet.shape[1], sheet.shape[0]), (70, 66, 60))
        im = Image.fromarray(sheet, "RGBA")
        bg.paste(im, (0, 0), im)
        bg.save(preview)


if __name__ == "__main__":
    main()
