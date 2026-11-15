#!/usr/bin/env python3
"""에셋 라이브러리(도시) → 동네 지도 소품 갈아 끼우기(AM71 — 사용자 2026-11-15 "범용 에셋을 게임에 적용").

동네 소품은 assets/town/props/<종류>.webp 한 장씩(칸당 96px · 발 = 그림 아래 가운데 — TownProp)이다. 종류마다 키트 그림(SWAP)을 잘라
바닥 그림자 · 빛 무리를 빼고(아래 가운데가 발이라 그림자가 발 밑으로 내려가면 소품이 뜬다), 옛 그림 높이에 맞춰(폭은 옛 폭의 1.25배까지) 같은 이름으로 쓴다.
지도 칸 · 충돌 · 배치는 그대로. 표에 없는 종류 = 옛 그림 유지(성벽 · 성문 · 광장 돌 단 · 돌 고리 = 지도 꼴에 맞춘 구조물, 무덤 · 가게 걸이 간판 ·
벽 등불 · 부두 난간 = 키트에 같은 것이 없다, 깃발 = 동네의 검붉은 바탕 금 고리 깃발(키트 깃대는 다른 무늬), 좌판 = 동네 차양은 붉은 줄(CT105 — 키트 좌판은 노란 줄), 우물 = 키트 지붕 우물은 지붕이 판자처럼 보여 약하다).
  python3 tools/dungeon_kit/town_swap.py [--preview=<png>]   → 그 뒤 --import → 캡처(--screen=city)
옛 그림 백업 = assets/town/props_orig/(.gdignore — 처음 한 번 복사). 되돌리기 = --revert(백업을 다시 복사).
tools/town_hand_bake.py --props를 다시 돌리면 옛 그림으로 돌아가므로 이것도 다시 돌린다.
"""
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
PROPS = os.path.join(ROOT, "assets", "town", "props")
BACKUP = os.path.join(ROOT, "assets", "town", "props_orig")
WIDE = 1.25  ## 옛 폭보다 이만큼까지 넓어도 된다
RECOLOR = {"bush", "tree"}  ## 옛 그림 색 평균 · 퍼짐으로 다시 칠한다(키트 풀빛이 차분한 동네에서 너무 밝게 튀었다)
UP_MAX = 1.6  ## 키트 그림(칸당 64px)을 키우는 한도 — 동네는 칸당 96px라 1.5배가 제 크기, 더 키우면 흐려진다(물구유 · 장작더미가 2배로 뭉개졌다)

SWAP = {
    "barrel": "barrel.intact", "bench": "bench.base", "board": "notice_board.notices",
    "boat": "boat.oars", "bollard": "bollard.stone", "bush": "bush.wide", "cart": "cart.sacks", "crate": "crate.intact",
    "fountain": "fountain.running", "goods": "supply_pile.b", "household": "junk_pile.alley", "lamp": "street_lamp.lit",
    "laundry": "clothesline.laundry", "planter": "planter.flowers", "sacks": "sack.pile", "signpost": "signpost.two",
    "statue": "statue.intact", "tent": "market_awning.striped", "tree": "tree_broadleaf.a",
    "trough": "horse_trough.stone", "wagon": "cart.barrels", "woodpile": "firewood",
}


def body_of(kit, sheets, ref):
    aid, _, var = ref.partition(".")
    a = kit["assets"][aid]
    var = var or next(iter(a["variants"]))
    x, y, w, h, ox, oy = a["variants"][var]["frames"][0]
    if a["sheet"] not in sheets:
        sheets[a["sheet"]] = np.asarray(Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGBA"))
    img = sheets[a["sheet"]][int(y):int(y + h), int(x):int(x + w)].copy()
    body = img[..., 3] >= 200  # 그림자 · 빛 무리(반투명) 빼기 — game_props.py와 같은 방식
    near = body.copy()
    near[1:] |= body[:-1]
    near[:-1] |= body[1:]
    near[:, 1:] |= body[:, :-1]
    near[:, :-1] |= body[:, 1:]
    img[~near] = 0
    ys, xs = np.flatnonzero(near.any(1)), np.flatnonzero(near.any(0))
    # 발(ox, oy)을 가운데 아래로: 좌우를 발 x에 대해 대칭으로, 아래는 몸 끝(발 줄보다 아래면 몸 끝까지)
    bot = max(int(oy), ys[-1] + 1)
    half = max(ox - xs[0], xs[-1] + 1 - ox)
    x0, x1 = int(np.floor(ox - half)), int(np.ceil(ox + half))
    out = np.zeros((bot - ys[0], x1 - x0, 4), np.uint8)
    sx0, sx1 = max(0, x0), min(img.shape[1], x1)
    out[:, sx0 - x0:sx1 - x0] = img[ys[0]:bot, sx0:sx1]
    return out


def recolor(img, ref):
    out = img.astype(np.float32) / 255.0
    r = ref.astype(np.float32) / 255.0
    m, mr = out[..., 3] > 0.5, r[..., 3] > 0.5
    for c in range(3):
        k, o = out[..., c][m], r[..., c][mr]
        f = float(np.clip(o.std() / (k.std() + 1e-3), 0.85, 1.2))
        out[..., c] = np.where(m, (out[..., c] - k.mean()) * f + o.mean(), out[..., c])
    return (np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)


def resize(img, s):
    pm = img.astype(np.float32) / 255.0
    pm[..., :3] *= pm[..., 3:4]
    h, w = img.shape[:2]
    small = np.asarray(Image.fromarray((pm * 255 + 0.5).astype(np.uint8), "RGBA").resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)).astype(np.float32) / 255.0
    a = small[..., 3:4]
    small[..., :3] = np.where(a > 1e-3, small[..., :3] / np.maximum(a, 1e-3), 0)
    return (np.clip(small, 0, 1) * 255 + 0.5).astype(np.uint8)


def main():
    if not os.path.isdir(BACKUP):
        os.makedirs(BACKUP)
        for f in os.listdir(PROPS):
            if f.endswith(".webp"):
                shutil.copyfile(os.path.join(PROPS, f), os.path.join(BACKUP, f))
        open(os.path.join(BACKUP, ".gdignore"), "w").close()
    if "--revert" in sys.argv:
        for f in os.listdir(BACKUP):
            if f.endswith(".webp"):
                shutil.copyfile(os.path.join(BACKUP, f), os.path.join(PROPS, f))
        print("되돌림: 동네 소품 옛 그림")
        return
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    sheets = {}
    log = {}
    for kind, ref in SWAP.items():
        old = Image.open(os.path.join(BACKUP, kind + ".webp")).convert("RGBA")
        oa = np.asarray(old)[..., 3] > 8
        oh = np.flatnonzero(oa.any(1))
        ow = np.flatnonzero(oa.any(0))
        old_h, old_w = oh[-1] - oh[0] + 1, ow[-1] - ow[0] + 1
        img = body_of(kit, sheets, ref)
        s = min(old_h / img.shape[0], WIDE * old_w / img.shape[1], UP_MAX)
        img = resize(img, s)
        if kind in RECOLOR:
            img = recolor(img, np.asarray(old))
        Image.fromarray(img, "RGBA").save(os.path.join(PROPS, kind + ".webp"), lossless=True, quality=100, exact=True)
        log[kind] = {"kit": ref, "scale": round(s, 3), "size": [img.shape[1], img.shape[0]], "old": [int(old_w), int(old_h)]}
    json.dump({"_comment": "tools/dungeon_kit/town_swap.py가 바꾼 동네 소품(AM71) — 없는 종류는 옛 그림", "props": log},
              open(os.path.join(BACKUP, "swap.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("동네 소품: %d종 키트 · %d종 유지" % (len(log), len([f for f in os.listdir(BACKUP) if f.endswith(".webp")]) - len(log)))
    for a in sys.argv[1:]:
        if a.startswith("--preview="):
            fs = sorted(f for f in os.listdir(PROPS) if f.endswith(".webp"))
            C = 220
            sheet = Image.new("RGBA", (11 * C, -(-len(fs) // 11) * C), (60, 56, 50, 255))
            for k, f in enumerate(fs):
                im = Image.open(os.path.join(PROPS, f)).convert("RGBA")
                im.thumbnail((C - 10, C - 10))
                sheet.alpha_composite(im, ((k % 11) * C + 5, (k // 11) * C + 5))
            sheet.convert("RGB").save(a[len("--preview="):], quality=85)


if __name__ == "__main__":
    main()
