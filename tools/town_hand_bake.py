"""게임 동네 집 그림 손그림 마감(CT97): tools/paint_town_hand.gd가 찍은 user://town_hand/<id>_raw.png · _id.png · .json을
tools/town_handdrawn.finish(sprite=True)로 마감해 배경을 투명하게 → user://town_bake/<id>.png · .json(off · key)
— 그다음 paint_town_houses.gd --pack이 그림판(assets/town/houses/p<k>.webp + index.json)으로 묶는다.
  python3 tools/town_hand_bake.py [h3 h7 …]
"""
import json
import os
import re
import shutil
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import town_handdrawn as th  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def user_dir() -> str:
    """Godot user:// (리눅스 ~/.local/share/godot/app_userdata/<프로젝트 이름>)."""
    name = re.search(r'config/name="([^"]+)"', open(os.path.join(ROOT, "project.godot"), encoding="utf-8").read()).group(1)
    base = os.environ.get("XDG_DATA_HOME", os.path.join(os.path.expanduser("~"), ".local", "share"))
    if sys.platform.startswith("win"):
        base = os.environ.get("APPDATA", base)
        return os.path.join(base, "Godot", "app_userdata", name)
    return os.path.join(base, "godot", "app_userdata", name)


def props():
    """--props: user://town_props/<kind>_raw · _id → assets/town/props/<kind>.webp(투명 배경 · 손그림 — CT99)."""
    src = os.path.join(user_dir(), "town_props")
    dst = os.path.join(ROOT, "assets", "town", "props")
    os.makedirs(dst, exist_ok=True)
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.endswith("_raw.png"):
            continue
        kind = f[:-len("_raw.png")]
        raw = np.asarray(Image.open(os.path.join(src, f)).convert("RGB")).astype(float) / 255.0
        ids = np.asarray(Image.open(os.path.join(src, kind + "_id.png")).convert("RGB")).astype(np.int64)
        code = ids[..., 0] * 65536 + ids[..., 1] * 256 + ids[..., 2]
        img, alpha = th.finish(raw, code, sprite=True)
        Image.fromarray((np.dstack([img, alpha]) * 255).astype(np.uint8), "RGBA").save(os.path.join(dst, kind + ".webp"), lossless=True)
        n += 1
    print("소품 손그림: %d → %s" % (n, dst))


def main():
    if "--props" in sys.argv:
        props()
        return
    src = os.path.join(user_dir(), "town_hand")
    dst = os.path.join(user_dir(), "town_bake")
    os.makedirs(dst, exist_ok=True)
    want = set(a for a in sys.argv[1:] if not a.startswith("--"))
    n = 0
    for f in sorted(os.listdir(src)):
        if not f.endswith("_raw.png"):
            continue
        hid = f[:-len("_raw.png")]
        if want and hid not in want:
            continue
        raw = np.asarray(Image.open(os.path.join(src, f)).convert("RGB")).astype(float) / 255.0
        ids = np.asarray(Image.open(os.path.join(src, hid + "_id.png")).convert("RGB")).astype(np.int64)
        code = ids[..., 0] * 65536 + ids[..., 1] * 256 + ids[..., 2]
        img, alpha = th.finish(raw, code, sprite=True)
        rgba = np.dstack([img, alpha])
        Image.fromarray((rgba * 255).astype(np.uint8), "RGBA").save(os.path.join(dst, hid + ".png"))
        shutil.copyfile(os.path.join(src, hid + ".json"), os.path.join(dst, hid + ".json"))
        n += 1
    print("손그림 마감: 집 %d채 → %s" % (n, dst))


if __name__ == "__main__":
    main()
