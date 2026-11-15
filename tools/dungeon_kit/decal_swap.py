#!/usr/bin/env python3
"""에셋 라이브러리 → 탐험 바닥 자국(데칼) 갈아 끼우기(AM71 — 사용자 2026-11-15 "범용 에셋을 게임에 적용").

데칼 시트(art.decor — 4열(변형) × 종류 줄 · 칸 64px = 한 칸)는 층 · 균열의 decor.kinds 순서로 줄을 쓴다(구운 자리 _decor.json은 종류 · 변형 번호만 안다).
줄마다 키트 바닥 자국 넷(SWAP)을 칸에 맞춰 줄여 새 시트(assets/floor/kit/decals_<이름>.webp)를 굽고, 그 시트를 쓰던 층 · 균열 JSON의 decor.sheet를 새 것으로 고친다.
표에 없는 줄 = 옛 그림 그대로(물가 · 수정 부스러기 · 숲의 잡초 · 고사리 · 뿌리 · 꽃 · 햇빛 — 키트에 같은 것이 없다).
  python3 tools/dungeon_kit/decal_swap.py [--preview=<폴더>] | --revert   → 그 뒤 texture_compress.py → --import → 캡처
"""
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
CELL = 64
FILL = 0.92  # 칸에 차는 정도(가장자리 여유)

# 옛 시트 → (새 이름, {종류 줄 번호: [키트 자국 넷]})
SWAP = {
    "f1/decals.webp": ("decals_cave", {  # shore · gravel · moss · wet · crystal_bits · claws · mud · rot · trash · bones
        # 1 자갈 = 키트 자갈은 칸(64px)에서 잔 점이 되어 지저분하다 → 옛 조약돌 유지
        2: ["moss_patch.a", "moss_patch.b", "moss_patch.c", "moss_patch.d"],
        3: ["puddle.small", "water_stain.a", "water_stain.b", "puddle.medium"],
        5: ["scratches.a", "scratches.b", "scratches.c", "scratches.deep"],
        6: ["mud_stain.a", "mud_stain.b", "mud_stain.smear", "mud_stain.wet"],
        # 7 썩은 자국 = 키트 것이 짐승 꼴 얼룩처럼 보여 유지, 8 쓰레기 = 키트 유리 조각 · 음식 잔해의 검은 그늘이 무거워 유지
        9: ["bones.scatter_a", "bones.scatter_b", "bones.crossed", "bones.spine"],
    }),
    "f2g/decals.webp": ("decals_forest", {  # weeds · fern · stones · roots · litter · flowers · moss · mud · bones · sunpatch
        # 2 돌 = 위 자갈과 같은 까닭으로 유지, 4 낙엽 = 키트 낙엽이 밝은 가을 주황이라 어두운 고블린 숲과 안 맞아 유지
        6: ["moss_patch.a", "moss_patch.b", "moss_patch.c", "moss_patch.d"],
        7: ["mud_stain.a", "mud_stain.b", "mud_stain.smear", "mud_stain.wet"],
        8: ["bones.scatter_a", "bones.scatter_b", "bones.crossed", "bones.spine"],
    }),
}


def kit_decal(kit, sheets, ref):
    aid, _, var = ref.partition(".")
    a = kit["assets"][aid]
    if var not in a["variants"]:
        raise SystemExit("변형 없음: %s (%s)" % (ref, ", ".join(a["variants"])))
    x, y, w, h, _ox, _oy = a["variants"][var]["frames"][0]
    if a["sheet"] not in sheets:
        sheets[a["sheet"]] = Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGBA")
    img = sheets[a["sheet"]].crop((int(x), int(y), int(x + w), int(y + h)))
    if a.get("layer") == "stand":  # 서 있는 것(뼈)의 바닥 그림자 = 칸에서 검은 얼룩이 된다 → 뺀다
        arr = np.asarray(img).copy()
        body = arr[..., 3] >= 200
        near = body.copy()
        near[1:] |= body[:-1]
        near[:-1] |= body[1:]
        near[:, 1:] |= body[:, :-1]
        near[:, :-1] |= body[:, 1:]
        arr[~near] = 0
        img = Image.fromarray(arr, "RGBA")
    al = np.asarray(img)[..., 3] > 6
    ys, xs = np.flatnonzero(al.any(1)), np.flatnonzero(al.any(0))
    img = img.crop((xs[0], ys[0], xs[-1] + 1, ys[-1] + 1))
    s = min(1.0, CELL * FILL / img.width, CELL * FILL / img.height)
    img = img.resize((max(1, round(img.width * s)), max(1, round(img.height * s))), Image.LANCZOS)
    cell = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    cell.alpha_composite(img, ((CELL - img.width) // 2, (CELL - img.height) // 2))
    return cell


def users(rel):
    """그 시트를 decor.sheet로 쓰는 층 · 균열 JSON 경로."""
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "floors", "*.json")) + glob.glob(os.path.join(ROOT, "data", "rifts", "*.json"))):
        if '"res://assets/floor/%s"' % rel in open(f, encoding="utf-8").read():
            out.append(f)
    return out


def retarget(old, new):
    n = 0
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "floors", "*.json")) + glob.glob(os.path.join(ROOT, "data", "rifts", "*.json"))):
        if os.path.basename(f).startswith("_"):
            continue
        t = open(f, encoding="utf-8").read()
        key = '"sheet": "res://assets/floor/%s"' % old
        if key in t:
            open(f, "w", encoding="utf-8").write(t.replace(key, '"sheet": "res://assets/floor/%s"' % new))
            n += 1
    return n


def main():
    revert = "--revert" in sys.argv
    preview = next((a[len("--preview="):] for a in sys.argv if a.startswith("--preview=")), None)
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    sheets = {}
    for rel, (name, rows) in SWAP.items():
        new = "kit/%s.webp" % name
        if revert:
            print("%s ← %s: JSON %d개" % (rel, new, retarget(new, rel)))
            continue
        old = Image.open(os.path.join(ROOT, "assets", "floor", rel)).convert("RGBA")
        out = old.copy()
        for r, refs in rows.items():
            for c, ref in enumerate(refs):
                out.paste((0, 0, 0, 0), (c * CELL, r * CELL, (c + 1) * CELL, (r + 1) * CELL))
                out.alpha_composite(kit_decal(kit, sheets, ref), (c * CELL, r * CELL))
        dst = os.path.join(ROOT, "assets", "floor", new)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        out.save(dst, lossless=True, quality=100, exact=True)
        print("%s → %s: 줄 %d 중 키트 %d, JSON %d개" % (rel, new, old.height // CELL, len(rows), retarget(rel, new)))
        if preview:
            os.makedirs(preview, exist_ok=True)
            for tag, im in (("old", old), ("new", out)):
                bg = Image.new("RGBA", im.size, (70, 64, 58, 255))
                bg.alpha_composite(im)
                bg.resize((im.width * 3, im.height * 3), Image.NEAREST).convert("RGB").save(os.path.join(preview, "%s_%s.png" % (name, tag)))


if __name__ == "__main__":
    main()
