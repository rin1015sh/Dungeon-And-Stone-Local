"""2층 소품 · 큰 구조물 다시 그리기(사용자 2026-11-11 "건물 · 상호작용 요소가 ppt 도형 같다 — 갈아엎고 다시 그려도 돼", AM64).
평면 도형에 그늘을 덧칠하던 그림 대신, 덩어리를 빚어(sdf.py) 탐험 맵 3/4 시점으로 찍고 손그림으로 마감한다(solid.py).
시트 칸 순서 · 크기는 tools/floor_art/rift/specs.json(places.<장소>.stands · bigs)을 그대로 읽는다 — 타일 데이터는 바뀌지 않는다.
  python3 tools/f2_art/props.py [f2d|f2g][:stand|big] [--only=<이름,…>] [--preview=<폴더>]
    → assets/floor/<장소>/stand.webp · big.webp   (--only = 시트에서 그 칸만 다시 · --preview = 시트를 쓰지 않고 낱장 png만)
"""
import json
import os
import sys
import time

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import models_dead  # noqa: E402
import solid  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
U = 64  # 그림 px / 칸(view.floor_tile_px × art_scale)
MODELS = {"f2d": models_dead}
try:
    import models_forest  # noqa: E402
    MODELS["f2g"] = models_forest
except ImportError:
    pass
import models_f3  # noqa: E402  — 3층 소품(시트 칸 순서 = models_f3.STAND 순서, specs.json에 없다)
MODELS["f3"] = models_f3


def paint(fn, cw, ch, seed):
    """모델 하나 → RGBA(ch, cw, 4). 발 = 칸 아래쪽 가운데 칸의 가운데."""
    sc, mats, extra = fn()
    ox, oy = cw * 0.5, ch - U * 0.5
    u = U * extra.get("scale", 1.0)   # scale = 모델을 키워 찍는다(석상 · 큰 나무)
    img = solid.render(sc, mats, cw, ch, u, ox, oy, seed, extra.get("shadow", 0.5), -3.0, extra.get("far", 8.0))
    for gx, gy, gz, r, color, strength in extra.get("glow", []):
        c = np.array([int(color[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255.0
        img = solid.add_glow(img, ox + gx * u, oy - (gz + solid.K * gy) * u, r, c, strength)
    return img


def main():
    spec = json.load(open(os.path.join(ROOT, "tools", "floor_art", "rift", "specs.json"), encoding="utf-8"))
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    only = next((a[7:].split(",") for a in sys.argv if a.startswith("--only=")), None)
    preview = next((a[10:] for a in sys.argv if a.startswith("--preview=")), None)
    for place, mod in MODELS.items():
        pd = spec["places"].get(place) or {"stands": list(mod.STAND), "stand_cols": 10, "bigs": {"order": [], "cell": [8, 10], "cols": 6}}
        for part in ("stand", "big"):
            if args and not any(a == place or a == place + ":" + part for a in args):
                continue
            if part == "big" and not mod.BIG:
                continue
            if part == "stand":
                names, table = pd["stands"], mod.STAND
                cw, ch, cols = spec["stand_cell"][0] * U, spec["stand_cell"][1] * U, int(pd.get("stand_cols", spec["stand_cols"]))
            else:
                names, table = pd["bigs"]["order"], mod.BIG
                cw, ch, cols = pd["bigs"]["cell"][0] * U, pd["bigs"]["cell"][1] * U, int(pd["bigs"]["cols"])
            rows = -(-len(names) // cols)
            path = os.path.join(ROOT, "assets", "floor", place, part + ".webp")
            sheet = np.zeros((rows * ch, cols * cw, 4), np.uint8)
            if only and os.path.exists(path):   # --only: 있는 시트에서 그 칸만 다시 그린다
                old = np.asarray(Image.open(path).convert("RGBA"))
                if old.shape == sheet.shape:
                    sheet = old.copy()
            for k, name in enumerate(names):
                if name not in table or (only and name not in only):
                    continue
                t0 = time.time()
                img = paint(table[name], cw, ch, 7000 + k * 31)
                sheet[(k // cols) * ch:(k // cols + 1) * ch, (k % cols) * cw:(k % cols + 1) * cw] = img
                print("%s %s %s  %.1fs" % (place, part, name, time.time() - t0), flush=True)
                if preview:
                    os.makedirs(preview, exist_ok=True)
                    Image.fromarray(img, "RGBA").save(os.path.join(preview, "%s_%s.png" % (place, name)))
            if not preview and (not only or any(n in table for n in only if n in names)):
                Image.fromarray(sheet, "RGBA").save(path, lossless=True, quality=100, exact=True)
                print("시트:", os.path.relpath(path, ROOT))


if __name__ == "__main__":
    main()
    if not any(a.startswith("--preview=") for a in sys.argv):   # 칸마다 그림이 있는 네모를 다시 잰다(게임이 그 네모만 그린다)
        sys.path.insert(0, os.path.join(ROOT, "tools"))
        import sheet_bounds
        sheet_bounds.main()
