#!/usr/bin/env python3
"""에셋 라이브러리 아이템 그림 → 게임 아이템 그림(2026-11-21 — 사용자 "에셋팩에서 가져와 쓰고, 따로 그려야 하면 그려 넣어라").

키트 아이템 그림(item_* — 80px 칸, 손그림 마감)이 paint_items의 그림(일반 꼴 — 꼬리표 · 주머니 …)보다 그 물건답게 보이는 것만 옮긴다.
가방 칸(80px × 칸 수)에 가운데 맞춰 놓고, 색이 필요하면 물들인다. → assets/items/<id>.webp(paint_items가 다시 그리면 덮어쓰므로
paint_items는 assets/items/kit_items.json에 적힌 id를 건너뛴다 — 이 도구가 그 목록을 쓴다).

    python3 tools/dungeon_kit/item_kit.py  → texture_compress.py → --import
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
CELL = 80

# 아이템 id → (키트 그림, 물들일 색 또는 None) — 2층 균열 히든 피스 · 군주 보상
ITEMS = {
    "rusted_trap_key": ("item_key_old.rusty", None),
    "silver_mane_pelt": ("item_hide.pelt", "#c8ccd4"),
    "alpha_fang_necklace": ("item_bone.fang", None),
    "chief_tooth_charm": ("item_trinket.necklace", "#d8c8a0"),
    "trap_king_bundle": ("item_hide.roll", "#6a5a3a"),
    "sun_disc": ("item_relic.disc", "#d8b060"),
    "squire_signet": ("item_trinket.ring", "#8a98a8"),
    "knight_oath_scroll": ("item_scroll.sealed", None),
    "crypt_reliquary": ("item_treasure_box.jeweled", None),
}


def tint(img, col):
    a = np.asarray(img).astype(np.float32) / 255.0
    rgb, al = a[..., :3], a[..., 3]
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    m = lum[al > 0.5].mean() if (al > 0.5).any() else 0.5
    t = np.array([int(col[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255.0
    out = np.clip(lum[..., None] / max(m, 1e-3) * t * 0.65 + rgb * 0.35, 0, 1)
    return Image.fromarray((np.dstack([out, al]) * 255 + 0.5).astype(np.uint8), "RGBA")


def main():
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    sheets = {}
    for iid, (ref, col) in ITEMS.items():
        item = json.load(open(os.path.join(ROOT, "data", "items", iid + ".json"), encoding="utf-8"))
        w, h = item.get("size", [1, 1])
        aid, _, var = ref.partition(".")
        a = kit["assets"][aid]
        x, y, fw, fh, _ox, _oy = a["variants"][var]["frames"][0]
        if a["sheet"] not in sheets:
            sheets[a["sheet"]] = Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGBA")
        img = sheets[a["sheet"]].crop((int(x), int(y), int(x + fw), int(y + fh)))
        bb = img.getbbox()
        if bb:
            img = img.crop(bb)
        W, H = CELL * int(w), CELL * int(h)
        s = min((W - 8) / img.width, (H - 8) / img.height)
        img = img.resize((max(1, int(img.width * s)), max(1, int(img.height * s))), Image.LANCZOS)
        if col:
            img = tint(img, col)
        out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        out.alpha_composite(img, ((W - img.width) // 2, (H - img.height) // 2))
        out.save(os.path.join(ROOT, "assets", "items", iid + ".webp"), lossless=True, quality=100, exact=True)
        print(iid, "←", ref)
    with open(os.path.join(ROOT, "assets", "items", "kit_items.json"), "w", encoding="utf-8") as f:
        f.write(json.dumps(sorted(ITEMS), ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
