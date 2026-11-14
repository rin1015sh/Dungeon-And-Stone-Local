#!/usr/bin/env python3
"""던전 에셋 키트 → 3층 서 있는 소품 시트(사용자 2026-11-14 "예전에 개발한 에셋 모음집 참고해서 맵 채워봐" — 키트 = docs/DUNGEON_KIT.md).
게임의 서 있는 소품(타일 art.stand — 칸 4 × 3, 256 × 192px, 발 = 아래 줄 가운데 (128, 160))으로 구운 키트 그림(assets/dungeon_kit/*.webp)을 옮긴다.
다시 그리지 않고 kit.json의 첫 프레임 네모를 잘라 붙인다(칸보다 크면 줄인다). 칸 순서 = ITEMS 순서 → assets/floor/f3/kit_stand.webp + kit_stand_items.json(타일 표 — kit_stand.json은 sheet_bounds가 쓰는 그림 네모).
  python3 tools/dungeon_kit/f3_stand.py   (그 뒤 python3 tools/f3_tiles.py → tools/sheet_bounds.py → texture_compress.py → --import)
"""
import json
import os

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
OUT = os.path.join(ROOT, "assets", "floor", "f3", "kit_stand.webp")
CW, CH, COLS, FOOT = 256, 192, 8, (128, 160)  # 칸 4 × 3(타일 art.stand size [4, 3] — 쓰러진 기둥 · 석관처럼 넓은 것도 줄이지 않게)

# (키트 id, 변형, 3층 이름(없으면 키트 이름), 시야 가림, 엄폐, 쓰는 바닥 약자들)
ORC = ["og", "oe"]
TEMPLE = ["tg", "tf"]
CAMP = ["hg", "dg", "eb", "rb"]
ITEMS = [
    ("weapon_rack", "full", "무기 거치대", False, True, ORC), ("armor_stand", "armor", "갑옷 거치대", False, True, ORC),
    ("anvil", "hammer", "모루", False, True, ORC), ("workbench", "tools", "작업대", False, True, ORC), ("grindstone", "base", "숫돌", False, True, ORC),
    ("cooking_pot", "stew", "끓는 솥", False, False, ORC), ("supply_pile", "a", "약탈품 더미", False, True, ORC), ("straw_pile", "a", "짚더미 잠자리", False, False, ORC),
    ("barrel", "stack", "쌓은 통", False, True, ORC), ("crate", "stack", "쌓은 상자", True, True, ORC), ("torch_stand", "lit", "세운 횃불", False, False, ORC),
    ("brazier", "lit", "화로", False, False, ORC), ("skull", "pike", "창에 꽂은 해골", False, False, ORC + ["wf"]), ("gibbet", "skeleton", "매달린 우리", False, False, ORC + ["wf"]),
    ("broken_weapon", "pile", "부서진 무기 더미", False, False, ORC + CAMP),
    ("pillar", "broken", "부러진 기둥", False, True, TEMPLE), ("pillar", "fallen", "쓰러진 기둥", False, True, TEMPLE), ("pillar", "stump", "기둥 밑동", False, True, TEMPLE),
    ("pillar", "mossy", "이끼 낀 기둥", True, True, TEMPLE), ("statue", "headless", "머리 없는 석상", False, True, TEMPLE + ["rp"]), ("statue", "ruined", "무너진 석상", False, True, TEMPLE),
    ("statue_robed", "weeping", "피눈물 흘리는 석상", False, True, TEMPLE), ("altar", "ritual", "의식 제단", False, False, TEMPLE + ["wf"]),
    ("sarcophagus", "ajar", "비껴 열린 석관", False, True, TEMPLE), ("pedestal", "broken", "깨진 받침대", False, True, TEMPLE), ("stone_tablet", "mossy", "이끼 낀 석판", False, True, TEMPLE + ["dg"]),
    ("rune_stone", "dormant", "룬 돌", False, True, TEMPLE + ["dg", "hr"]), ("arch", "ruined", "무너진 아치", True, True, TEMPLE),
    ("ritual_remains", "candle_ring", "촛불 고리", False, False, ["wf"]), ("ritual_remains", "bone_circle", "뼈 배열", False, False, ["wf", "rp"]),
    ("ritual_remains", "offering", "바친 제물", False, False, ["wf"]), ("candles", "lit", "녹아내린 양초", False, False, ["wf", "hu"]),
    ("magic_lamp", "violet", "보랏빛 등", False, False, ["wf", "hf"]), ("rune_stone", "violet_c", "보랏빛 룬 돌", False, True, ["wf"]),
    ("web_cocoon", "standing", "선 고치", False, True, ["wf"]), ("nest", "eggs", "알 둥지", False, False, ["wf", "mf"]), ("toadstool", "glow_violet", "보랏빛 독버섯", False, False, ["wf"]),
    ("roots", "knot", "엉킨 뿌리", False, True, ["wf", "mf", "eb"]), ("crystal", "violet_small", "보랏빛 결정", False, False, ["wf"]), ("skull", "heap", "해골 무더기", False, False, ["wf", "rp"]),
    ("rock", "large_a", "큰 바위", True, True, ["hr", "hg", "dg", "rb"]), ("rock", "medium_a", "바위", False, True, ["hr", "hg", "dg", "rb", "mf"]),
    ("boulder_mossy", "a", "이끼 바위", True, True, ["hg", "mf"]), ("rubble", "large", "돌무더기", False, True, ["hr", "dg", "tg"]),
    ("column_natural", "a", "돌기둥", True, True, ["hr", "dg"]), ("weeds", "dead_bush", "마른 덤불", False, True, ["dg", "rp", "hg"]),
    ("roots", "a", "드러난 뿌리", False, False, ["mf", "eb"]), ("mushroom", "big", "커다란 버섯", False, True, ["mf", "eb"]), ("weeds", "fern", "고사리", False, True, ["mf", "hg"]),
    ("weeds", "bramble", "가시덤불", False, True, ["eb", "mf", "rp"]), ("debris_wood", "planks", "썩은 널빤지", False, False, ["eb", "rb"]), ("toadstool", "red_a", "붉은 독버섯", False, False, ["mf", "eb"]),
    ("bedroll", "out", "펼친 침낭", False, False, CAMP), ("backpack", "standing", "버려진 배낭", False, False, CAMP), ("firepit", "lit", "모닥불", False, False, CAMP),
    ("supply_pile", "b", "보급품 더미", False, True, CAMP), ("lantern", "lit", "랜턴", False, False, CAMP),
    ("bed", "made", "침대", False, True, ["hu"]), ("bookshelf", "full", "책장", True, True, ["hu"]), ("table", "set", "차린 식탁", False, True, ["hu"]),
    ("chair", "s", "의자", False, False, ["hu"]), ("cabinet", "closed", "찬장", True, True, ["hu"]), ("books", "stack", "쌓인 책", False, False, ["hu"]),
    ("bottles", "potion_blue", "약병", False, False, ["hu"]), ("candelabra", "lit", "가지 촛대", False, False, ["hu", "hf"]),
]


def main():
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    sheets = {}
    rows = -(-len(ITEMS) // COLS)
    out = np.zeros((rows * CH, COLS * CW, 4), np.uint8)
    table = []
    for k, (aid, var, name, sight, cover, grounds) in enumerate(ITEMS):
        a = kit["assets"][aid]
        x, y, w, h, ox, oy = a["variants"][var]["frames"][0]
        sh = a["sheet"]
        if sh not in sheets:
            sheets[sh] = Image.open(os.path.join(KIT, sh + ".webp")).convert("RGBA")
        img = sheets[sh].crop((int(x), int(y), int(x + w), int(y + h)))
        # 칸 안에 들게 줄인다(발이 (64, 160)에 오도록 — 왼쪽 · 오른쪽 · 위 · 아래 여유 중 가장 빠듯한 쪽에 맞춘다)
        s = min(1.0, FOOT[0] / max(1.0, ox), (CW - FOOT[0]) / max(1.0, w - ox), FOOT[1] / max(1.0, oy), (CH - FOOT[1]) / max(1.0, h - oy))
        if s < 1.0:
            img = img.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
        cx, cy = (k % COLS) * CW, (k // COLS) * CH
        px, py = int(round(cx + FOOT[0] - ox * s)), int(round(cy + FOOT[1] - oy * s))
        cell = Image.fromarray(out)
        cell.alpha_composite(img, (px, py))
        out = np.asarray(cell).copy()
        light = a.get("light")
        if light and var not in light.get("variants", [var]):
            light = None  # 꺼진 변형
        table.append({"cell": k, "id": aid, "variant": var, "name_ko": name or a.get("name_ko", aid), "sight": sight, "cover": cover,
                      "grounds": grounds, "light": light, "scale": round(s, 3)})
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    Image.fromarray(out, "RGBA").save(OUT, lossless=True, quality=100, exact=True)
    json.dump({"cols": COLS, "rows": rows, "items": table}, open(OUT.replace(".webp", "_items.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("3층 키트 소품 %d칸 → %s" % (len(ITEMS), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
