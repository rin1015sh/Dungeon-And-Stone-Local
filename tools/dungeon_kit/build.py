#!/usr/bin/env python3
"""던전 에셋 키트 굽기 — 에셋 모듈(a_*.py)을 모두 그려 assets/dungeon_kit/에 묶음 그림(분류마다 한 장) + kit.json을 쓴다.

  python3 tools/dungeon_kit/build.py                      전부 그리고 묶는다(바뀐 것만 다시 그린다 — .cache)
  python3 tools/dungeon_kit/build.py <분류|id 앞머리> …     그것만 그린다(묶지 않는다) — 보통 --sheet와 함께
      --sheet=<png>   그린 것을 이름표 붙은 모음 그림 한 장으로(눈으로 확인)
      --singles=<폴더> 낱장 png로도 내보낸다
      --force         캐시를 무시하고 다시 그린다      --jobs=N  동시에 그릴 수(기본 4)
묶은 뒤: python3 tools/texture_compress.py → godot --headless --path . --import
"""
import json
import os
import sys
import time
from multiprocessing import Pool

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import kit  # noqa: E402

PAD = 2
MAX_W = 2048


def _init():
    kit.load_all()


def _job(j):
    id, vname, frame, params, force = j
    t0 = time.time()
    try:
        img, origin = kit.render(id, vname, frame, params, force)
    except Exception as e:  # 한 장이 깨져도 나머지는 그린다
        import traceback
        return id, vname, frame, None, traceback.format_exc(), 0.0
    return id, vname, frame, img, origin, time.time() - t0


def render_all(ids, force, jobs):
    todo = [(i, v, f, p, force) for i in ids for v, f, p in kit.REG[i].jobs()]
    out = {}
    bad = []
    with Pool(jobs, _init) as pool:
        for id, vname, frame, img, origin, dt in pool.imap_unordered(_job, todo):
            if img is None:
                bad.append((id, vname, origin))
                print("실패 %s.%s\n%s" % (id, vname, origin), flush=True)
                continue
            out[(id, vname, frame)] = (img, origin)
            if dt > 0.05:
                print("%-34s %4dx%-4d %.1fs" % ("%s.%s%s" % (id, vname, "" if frame is None else "#%d" % frame), img.shape[1], img.shape[0], dt), flush=True)
    return out, bad


def pack(items, pad):
    """선반 쌓기: [(key, img)] → (판, {key: (x, y, w, h)}). 높이순으로 줄을 채운다."""
    order = sorted(items, key=lambda kv: (-kv[1].shape[0], -kv[1].shape[1]))
    x = y = row_h = 0
    width = 0
    pos = {}
    for key, img in order:
        h, w = img.shape[:2]
        if x + w + pad > MAX_W and x > 0:
            x, y, row_h = 0, y + row_h + pad, 0
        pos[key] = (x, y, w, h)
        x += w + pad
        row_h = max(row_h, h)
        width = max(width, x)
    sheet = np.zeros((y + row_h, max(width - pad, 1), 4), np.uint8)
    for key, img in order:
        px, py, w, h = pos[key]
        sheet[py:py + h, px:px + w] = img
    return sheet, pos


def contact(done, path, cols_w=1500, bg=(58, 54, 50)):
    """이름표 붙은 모음 그림."""
    keys = sorted(done)
    cells = []
    for k in keys:
        img = done[k][0]
        label = "%s.%s%s" % (k[0], k[1], "" if k[2] is None else "#%d" % k[2])
        cells.append((label, img))
    x = y = row_h = 0
    place = []
    for label, img in cells:
        w, h = max(img.shape[1], len(label) * 6 + 6) + 10, img.shape[0] + 22
        if x + w > cols_w and x > 0:
            x, y, row_h = 0, y + row_h, 0
        place.append((x, y))
        x += w
        row_h = max(row_h, h)
    sheet = Image.new("RGB", (cols_w, y + row_h), bg)
    d = ImageDraw.Draw(sheet)
    for (label, img), (px, py) in zip(cells, place):
        sheet.paste(Image.fromarray(img, "RGBA"), (px + 5, py + 4), Image.fromarray(img, "RGBA"))
        d.text((px + 4, py + img.shape[0] + 7), label, fill=(210, 200, 180))
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    sheet.save(path)
    print("모음 그림:", path)


def write_pack(done):
    os.makedirs(kit.OUT, exist_ok=True)
    manifest = {"_comment": "tools/dungeon_kit/build.py가 만든다 — 손으로 고치지 않는다. 쓰는 법 docs/DUNGEON_KIT.md", "version": 1,
        "px_per_tile": kit.U, "depth_k": round(float(kit.K), 3), "wall_h": kit.WALL_H, "sheets": {}, "assets": {}}
    groups = {}
    for (id, vname, frame), (img, origin) in done.items():
        a = kit.REG[id]
        sheet = (a.meta or {}).get("sheet") or ("floors" if a.layer == "floor" else a.cat)
        groups.setdefault(sheet, []).append(((id, vname, frame), img))
    for sheet, items in sorted(groups.items()):
        tiles = sheet in ("floors", "wall_faces", "wall_tops", "fringes", "cliff_drops")
        img, pos = pack(items, 0 if tiles else PAD)
        path = os.path.join(kit.OUT, sheet + ".webp")
        Image.fromarray(img, "RGBA").save(path, lossless=True, quality=100, exact=True)
        manifest["sheets"][sheet] = {"path": "res://assets/dungeon_kit/%s.webp" % sheet, "size": [img.shape[1], img.shape[0]]}
        print("묶음: %s  %dx%d  %d장  %.0fKB" % (os.path.relpath(path, kit.ROOT), img.shape[1], img.shape[0], len(items), os.path.getsize(path) / 1024))
        for (id, vname, frame), _ in items:
            a = kit.REG[id]
            e = manifest["assets"].setdefault(id, {"cat": a.cat, "layer": a.layer, "name_ko": a.name_ko, "sheet": sheet, "variants": {}})
            if a.tags:
                e["tags"] = a.tags
            if a.collide is not None:
                rects = a.collide if isinstance(a.collide[0], (tuple, list)) else [a.collide]
                e["collide"] = [[round(v, 3) for v in (c if len(c) == 4 else (-c[0] / 2, -c[1] / 2, c[0], c[1]))] for c in rects]
            if a.light:
                e["light"] = a.light
            if a.interact:
                e["interact"] = a.interact
            if a.meta:
                e["meta"] = a.meta
            if a.reuse != "common":
                e["reuse"] = a.reuse
            if a.base:
                e["base"] = a.base
            v = e["variants"].setdefault(vname, {"frames": []})
            x, y, w, h = pos[(id, vname, frame)]
            ox, oy = done[(id, vname, frame)][1]
            v["frames"].append((frame or 0, [x, y, w, h, round(ox, 1), round(oy, 1)]))
            if frame is not None:
                v["fps"] = a.fps
    for e in manifest["assets"].values():
        for v in e["variants"].values():
            v["frames"] = [f for _, f in sorted(v["frames"])]
    sets_path = os.path.join(HERE, "sets.py")
    if os.path.exists(sets_path):
        import sets
        manifest["sets"] = sets.export(manifest)
    import a_edge
    manifest["fringe"] = {"rank": a_edge.RANK, "liquid": a_edge.LIQUID, "default_rank": 1}
    import regions
    manifest["regions"] = regions.export(manifest)
    text = (json.dumps(manifest, ensure_ascii=False, separators=(",", ":"), default=lambda o: o.item()).replace('},"', '},\n"'))
    with open(os.path.join(kit.OUT, "kit.json"), "w", encoding="utf-8") as f:   # 다 만든 뒤에 쓴다(중간에 깨져도 옛 파일이 남게)
        f.write(text)
    n_img = sum(len(v["frames"]) for e in manifest["assets"].values() for v in e["variants"].values())
    print("kit.json: 에셋 %d종 · 변형 %d개 · 그림 %d장" % (len(manifest["assets"]), sum(len(e["variants"]) for e in manifest["assets"].values()), n_img))
    return manifest


def main():
    kit.load_all()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opt = {a[2:].split("=")[0]: (a.split("=", 1)[1] if "=" in a else True) for a in sys.argv[1:] if a.startswith("--")}
    ids = [i for i, a in kit.REG.items() if not args or any(a.cat == f or i.startswith(f) for f in args)]
    if not ids:
        raise SystemExit("그릴 것이 없다: %s" % args)
    t0 = time.time()
    done, bad = render_all(ids, bool(opt.get("force")), int(opt.get("jobs", 4)))
    print("그림 %d장  %.0fs" % (len(done), time.time() - t0))
    if opt.get("sheet"):
        contact(done, opt["sheet"])
    if opt.get("singles"):
        os.makedirs(opt["singles"], exist_ok=True)
        for (id, vname, frame), (img, _) in done.items():
            Image.fromarray(img, "RGBA").save(os.path.join(opt["singles"], "%s.%s%s.png" % (id, vname, "" if frame is None else ".%d" % frame)))
    if not args and not bad:
        write_pack(done)
    if bad:
        raise SystemExit("실패 %d개: %s" % (len(bad), ", ".join("%s.%s" % (i, v) for i, v, _ in bad)))


if __name__ == "__main__":
    main()
