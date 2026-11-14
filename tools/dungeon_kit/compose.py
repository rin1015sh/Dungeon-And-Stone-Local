#!/usr/bin/env python3
"""던전 에셋 키트 — 테마 세트(sets.py)를 한 장으로 맞춰 본다(눈으로 확인 · 문서 그림). 게임 쪽 DungeonKit.build_set과 같은 규칙으로 쌓는다:
바닥 → 벽 윗면 → 벽면(남쪽이 바닥인 벽 칸에서 위로 2.5칸) → 바닥 자국 → 서 있는 것(발 y 순서 — 벽 부착물 포함) → 머리 위.

  python3 tools/dungeon_kit/compose.py [세트 이름 …] [--out=<폴더>] [--dark]     (--dark = 광원만 밝힌 어둠 맛보기)
"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402

U = kit.U
NORTH = 3     # 방 북쪽 벽 두께(칸) — 벽면(2.5칸)이 올라설 자리


def _img(id, variant=None, frame=0):
    a = kit.REG[id]
    variant = variant or next(iter(a.variants))
    params = dict(a.variants[variant])
    n = params.pop("frames", 0)
    if n:
        params["f"] = frame % n
    return kit.render(id, variant, (frame % n) if n else None, params)


def _paste(canvas, img, x, y, flip=False):
    if flip:
        img = img[:, ::-1]
    h, w = img.shape[:2]
    x, y = int(round(x)), int(round(y))
    x0, y0, x1, y1 = max(x, 0), max(y, 0), min(x + w, canvas.shape[1]), min(y + h, canvas.shape[0])
    if x0 >= x1 or y0 >= y1:
        return
    src = img[y0 - y:y1 - y, x0 - x:x1 - x].astype(np.float32) / 255.0
    dst = canvas[y0:y1, x0:x1]
    a = src[..., 3:4]
    dst[..., :3] = src[..., :3] * a + dst[..., :3] * (1 - a)
    dst[..., 3:4] = a + dst[..., 3:4] * (1 - a)


def layout(s):
    """세트 → (칸 폭, 칸 높이, 벽 칸 집합). 안쪽 바닥 (0, 0)은 격자 (1, NORTH)."""
    w, h = s["size"]
    gw, gh = w + 2, h + NORTH + 1
    walls = {(x, y) for x in range(gw) for y in range(gh) if not (1 <= x <= w and NORTH <= y < NORTH + h)}
    for x, y in s.get("pillars", []):      # 방 안의 벽 덩이
        walls.add((x + 1, y + NORTH))
    for x in s.get("exits_n", []):         # 북벽에 뚫린 통로(문 · 아치가 놓일 칸) — 벽면을 그리지 않는다
        pass
    return gw, gh, walls


def compose(name, s, dark=False):
    gw, gh, walls = layout(s)
    cv = np.zeros((gh * U, gw * U, 4), np.float32)
    cv[..., 3] = 1.0
    cv[..., :3] = np.array([0x0c, 0x0b, 0x0b], np.float32) / 255.0
    floor_of = {}
    for x in range(gw):
        for y in range(gh):
            if (x, y) not in walls:
                floor_of[(x, y)] = (s["floor"], s.get("floor_variant"))
    for p in s.get("floor_patches", []):
        x0, y0, pw, ph = p["rect"]
        for x in range(x0, x0 + pw):
            for y in range(y0, y0 + ph):
                if (x + 1, y + NORTH) in floor_of:
                    floor_of[(x + 1, y + NORTH)] = (p["id"], p.get("v"))
    for (x, y), (fid, fv) in floor_of.items():
        img, _ = _img(fid, fv)
        _paste(cv, img[(y % 4) * U:(y % 4 + 1) * U, (x % 4) * U:(x % 4 + 1) * U], x * U, y * U)
    kind = s.get("wall", "stone")
    top, _ = _img("wall_top", kind if kind in kit.REG["wall_top"].variants else "a")
    for (x, y) in walls:
        m = sum(bit for bit, (dx, dy) in ((1, (0, -1)), (2, (1, 0)), (4, (0, 1)), (8, (-1, 0))) if (x + dx, y + dy) in walls or not (0 <= x + dx < gw and 0 <= y + dy < gh))
        _paste(cv, top[(m // 4) * U:(m // 4 + 1) * U, (m % 4) * U:(m % 4 + 1) * U], x * U, y * U)
    states = s.get("wall_states", {})
    skip = set(s.get("exits_n", []))
    for (x, y) in sorted(walls, key=lambda c: c[1]):
        if (x, y + 1) in walls or y + 1 >= gh or (y == NORTH - 1 and (x - 1) in skip):
            continue
        st = states.get(str(x - 1), "clean") if y == NORTH - 1 else "clean"
        face, _ = _img("wall_" + kind, st)
        _paste(cv, face[:, (x % 4) * U:(x % 4 + 1) * U], x * U, (y + 1) * U - face.shape[0])
    items = []
    for it in s.get("items", []):
        a = kit.REG[it["id"]]
        img, (ox, oy) = _img(it["id"], it.get("v"), it.get("f", 0))
        px, py = (it["at"][0] + 1) * U, (it["at"][1] + NORTH) * U
        lift = it.get("up", 0.0) * U
        if it.get("flip"):
            ox = img.shape[1] - ox
        items.append((a.layer, py + it.get("z", 0), img, px - ox, py - oy - lift, it.get("flip", False), a, it))
    for layer, _, img, x, y, flip, _, _ in [i for i in items if i[0] == "decal"]:
        _paste(cv, img, x, y, flip)
    for layer, _, img, x, y, flip, _, _ in sorted([i for i in items if i[0] in ("stand", "wall_decal")], key=lambda i: (i[1], i[0] == "stand")):
        _paste(cv, img, x, y, flip)
    for layer, _, img, x, y, flip, _, _ in [i for i in items if i[0] == "over"]:
        _paste(cv, img, x, y, flip)
    if dark:   # 어둠 맛보기: 광원 둘레만 밝다(게임에서는 게임의 빛 계산이 한다)
        yy, xx = np.mgrid[0:cv.shape[0], 0:cv.shape[1]].astype(np.float32)
        lit = np.full(cv.shape[:2], 0.16, np.float32)
        tint = np.zeros(cv.shape[:2] + (3,), np.float32)
        for _, _, img, x, y, flip, a, it in items:
            lg = a.light
            if not lg or ("variants" in lg and (it.get("v") or next(iter(a.variants))) not in lg["variants"]):
                continue
            lx, ly = (it["at"][0] + 1) * U + lg["at"][0] * U, (it["at"][1] + NORTH) * U - (lg["at"][2] * 0.5 + kit.K * lg["at"][1]) * U
            f = np.clip(1.0 - np.hypot(xx - lx, (yy - ly) * 1.15) / (lg["radius"] * U), 0, 1) ** 1.6
            lit = np.maximum(lit, 0.16 + f * 0.95)
            tint += kit.hex_rgb(lg["color"])[None, None, :] * f[..., None] * 0.22
        cv[..., :3] = np.clip(cv[..., :3] * lit[..., None] * (1.0 + tint), 0, 1)
    return (np.clip(cv[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8)


def main():
    kit.load_all()
    import sets
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out = next((a[6:] for a in sys.argv if a.startswith("--out=")), os.path.join(kit.ROOT, "docs", "screens", "dungeon_kit"))
    dark = "--dark" in sys.argv
    os.makedirs(out, exist_ok=True)
    for name, s in sets.SETS.items():
        if args and name not in args:
            continue
        img = compose(name, s, dark)
        path = os.path.join(out, "set_%s%s.png" % (name, "_dark" if dark else ""))
        Image.fromarray(img, "RGB").save(path)
        print("세트:", path, img.shape[1], "x", img.shape[0])


if __name__ == "__main__":
    main()
