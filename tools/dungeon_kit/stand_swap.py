#!/usr/bin/env python3
"""에셋 라이브러리 → 게임 서 있는 소품 갈아 끼우기(AM71 — 사용자 2026-11-15 "범용 에셋을 게임에 적용 — 기존 에셋을 갈아엎고 대체,
대체할 것이 없거나 기존이 입체감 · 분위기에서 월등하면 유지. 1~3층 · 균열 · 도시 외관 · 내부 전부").

옛 서 있는 소품 시트(art.stand — 칸 2 × 3, 128 × 192px)마다 칸 번호 → 키트 그림 표(SWAP)를 두고, 칸 4 × 3(256 × 192px · 발 (128, 160) — 키트 그림이
줄지 않게, 3층 키트 시트 f3_stand.py와 같은 틀)짜리 새 시트 <곳>/stand_kit.webp를 굽는다. 표에 없는 칸 = 옛 그림을 같은 픽셀 크기로 옮겨 놓는다(유지).
그다음 data/tiles.json에서 옛 시트를 가리키던 art.stand를 새 시트(cols 8 · size [4, 3])로 고친다(칸 번호는 그대로 — 옛 시트 · 옛 표는 건드리지 않는다).
  python3 tools/dungeon_kit/stand_swap.py [--preview=<폴더>]   → 그 뒤 python3 tools/sheet_bounds.py → texture_compress.py → --import → 캡처
되돌리기 = --revert(tiles.json을 옛 시트로). f3_tiles.py · f2_art/props.py를 다시 돌렸으면 이것도 다시 돌린다.
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
CW, CH, COLS, FOOT = 256, 192, 8, (128, 160)
OLD_FOOT = (64, 160)  # 옛 칸(128 × 192) 발

# 곳 → (옛 시트, 옛 열, 옛 줄, {칸: "키트 id.변형"}) — 표에 없는 칸은 유지(이유는 줄 끝 주석).
SWAP = {
    # 균열 핏빛성채(+ 2층 바위사막 · 3층이 빌려 쓴다) — 옛 그림은 납작한 2D 그림이라 키트(3D 덩어리 · 손그림 마감)가 낫다
    "bf": ("bf/stand.webp", 8, 4, {
        0: "palisade.spiked", 1: "bars.rusty", 2: "table.set", 3: "weapon_rack.full", 4: "armor_stand.armor", 5: "barrel.intact",
        6: "crate.stack", 7: "cart.empty", 8: "tent.canvas",  # 9 바리케이드 = 키트 없음
        10: "brazier.lit",  # 11 교수대 = 키트 없음(gibbet은 매단 우리 — 19에 씀)
        12: "well.plain", 13: "market_stall.empty",  # 14 고문 기구 = 키트 없음
        15: "statue_robed.intact", 16: "altar.bloody", 17: "bookshelf.full", 18: "pew.facing_s", 19: "gibbet.skeleton",
        20: "tree_thorn.c", 21: "bed.messy", 22: "candelabra.lit", 23: "rock.large_a",  # 24 꿰인 말뚝 · 25 무덤 = 키트 없음
        26: "flag_pole.tattered", 27: "sack.pile",  # 28 묶는 기둥 = 키트 없음
        29: "fountain.dry", 30: "bookshelf_tall.full"}),
    # 균열 빙하굴
    "gc": ("gc/stand.webp", 8, 2, {
        # 0 고드름 · 2 눈 덮인 전나무 = 옛 그림이 크고 또렷해 유지(키트는 낮고 작다), 1 길잡이 얼음 기둥 = 이 균열만의 표지(유지)
        3: "rock_ice.snowcap", 4: "rock_ice.pillar_frozen",  # 5 오크 토템 = 키트 없음
        6: "crystal.blue_large", 7: "tent.canvas_b",  # 8 썰매 = 키트 없음
        9: "crate.intact", 10: "snow_drift.a", 11: "firepit.cold"}),  # 12 얼음 못 · 13 금 간 얼음 기둥 = 키트 없음
    # 균열 녹색 탄광
    "gm": ("gm/stand.webp", 8, 3, {
        0: "mine_support.intact",  # 1 초록 결정 = 키트에 초록 수정 없음
        2: "mine_cart.ore", 3: "barrel.intact", 4: "crate.stack",  # 5 갱도 등 기둥 · 6 비계 = 키트 없음
        7: "mushroom.big", 8: "powder_keg.intact", 9: "workbench.tools",  # 10 연장 걸이 = 키트 없음(벽 부착물뿐)
        11: "ore_vein.green_b", 12: "rock.large_a", 13: "tent.canvas_b", 14: "firepit.lit",  # 15 기중기 = 키트 없음
        16: "powder_keg.cluster"}),
    # 균열 강철의 묘
    "it": ("it/stand.webp", 8, 2, {
        0: "railing.straight", 1: "rubble.large", 2: "candelabra.lit", 3: "statue.intact", 4: "sarcophagus.closed",
        5: "armor_stand.armor", 6: "chandelier_fallen.base", 7: "brazier.lit", 8: "storage_jar.amphora", 9: "coin_piles.heap"}),
    # 2층 망자의 땅 — AM64 3D 소품(키트와 같은 기법) · 이곳만의 것(비문 · 묘실 문 · 넋불 · 힘줄 · 종 · 철문)은 유지
    "f2d": ("f2d/stand.webp", 10, 1, {2: "bush.dry"}),
    # 2층 고블린 숲 — 나무 · 덤불 · 그루터기 · 통나무 · 버섯 · 비석은 키트에 같은 것(고블린 숲용 포탈 비석)이 있다. 토템 = 유지
    "f2g": ("f2g/stand.webp", 10, 1, {
        0: "tree_broadleaf.a", 1: "bush.a", 2: "stump.a", 3: "log.mossy", 4: "mushroom.pale", 6: "portal_stele.active",
        7: "portal_stele.dead", 8: "palisade.spiked"}),
    # 3층 — 가시갈대 · 덩굴 나무 · 오크 천막 · 꽂은 머리 · 머리 없는 석상 · 쓰러진 기둥은 키트(3층 지역 표)에 있다. 덩굴 · 토템 · 가죽 걸이 = 유지
    "f3": ("f3/stand.webp", 10, 1, {
        0: "reed_thorn.dense", 1: "reed_thorn.sparse", 3: "tree_thorn.vined", 4: "tent.hide", 7: "skull.pike",
        8: "statue.headless", 9: "pillar.fallen"}),
}


def load_kit():
    return json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))


def kit_cell(kit, sheets, ref):
    aid, _, var = ref.partition(".")
    a = kit["assets"][aid]
    if var not in a["variants"]:
        raise SystemExit("변형 없음: %s (있는 것 %s)" % (ref, ", ".join(a["variants"])))
    x, y, w, h, ox, oy = a["variants"][var]["frames"][0]
    if a["sheet"] not in sheets:
        sheets[a["sheet"]] = Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGBA")
    img = sheets[a["sheet"]].crop((int(x), int(y), int(x + w), int(y + h)))
    s = min(1.0, FOOT[0] / max(1.0, ox), (CW - FOOT[0]) / max(1.0, w - ox), FOOT[1] / max(1.0, oy), (CH - FOOT[1]) / max(1.0, h - oy))
    if s < 1.0:
        img = img.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
    return img, (int(round(FOOT[0] - ox * s)), int(round(FOOT[1] - oy * s))), s


def build(place, spec, kit, sheets, preview=None):
    rel, ocols, orows, table = spec
    old = Image.open(os.path.join(ROOT, "assets", "floor", rel)).convert("RGBA")
    ocw, och = old.width // ocols, old.height // orows
    n = ocols * orows
    rows = -(-n // COLS)
    out = Image.new("RGBA", (COLS * CW, rows * CH), (0, 0, 0, 0))
    log = []
    for k in range(n):
        cx, cy = (k % COLS) * CW, (k // COLS) * CH
        if k in table:
            img, (px, py), s = kit_cell(kit, sheets, table[k])
            out.alpha_composite(img, (cx + px, cy + py))
            log.append({"cell": k, "kit": table[k], "scale": round(s, 3)})
        else:
            cell = old.crop(((k % ocols) * ocw, (k // ocols) * och, (k % ocols + 1) * ocw, (k // ocols + 1) * och))
            out.alpha_composite(cell, (cx + FOOT[0] - OLD_FOOT[0], cy + FOOT[1] - OLD_FOOT[1] + (CH - och)))
            log.append({"cell": k, "kept": True})
    dst = os.path.join(ROOT, "assets", "floor", os.path.dirname(rel), "stand_kit.webp")
    out.save(dst, lossless=True, quality=100, exact=True)
    json.dump({"_comment": "tools/dungeon_kit/stand_swap.py가 만든 칸 표(AM71) — kit = 키트 그림, kept = 옛 그림 유지", "from": rel, "cells": log},
              open(dst.replace(".webp", "_items.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    if preview:
        bg = Image.new("RGBA", out.size, (60, 56, 50, 255))
        bg.alpha_composite(out)
        bg.convert("RGB").save(os.path.join(preview, place + ".jpg"), quality=85)
    return rows, sum(1 for c in log if "kit" in c), n


def retarget(rows_of, revert=False):
    text = open(TILES, encoding="utf-8").read()
    total = 0
    for place, (rel, ocols, orows, _t) in SWAP.items():
        old = '"sheet": "res://assets/floor/%s", "cell": (\\d+), "cols": %d, "rows": %d, "size": \\[2, 3\\]' % (re.escape(rel), ocols, orows)
        new_rel = os.path.dirname(rel) + "/stand_kit.webp"
        new = '"sheet": "res://assets/floor/%s", "cell": (\\d+), "cols": %d, "rows": \\d+, "size": \\[4, 3\\]' % (re.escape(new_rel), COLS)
        if revert:
            text, c = re.subn(new, lambda m: '"sheet": "res://assets/floor/%s", "cell": %s, "cols": %d, "rows": %d, "size": [2, 3]' % (rel, m.group(1), ocols, orows), text)
        else:
            text, c = re.subn(old, lambda m: '"sheet": "res://assets/floor/%s", "cell": %s, "cols": %d, "rows": %d, "size": [4, 3]' % (new_rel, m.group(1), COLS, rows_of[place]), text)
        total += c
    open(TILES, "w", encoding="utf-8").write(text)
    return total


def main():
    if "--revert" in sys.argv:
        rows = {p: -(-(s[1] * s[2]) // COLS) for p, s in SWAP.items()}
        print("되돌림: 타일 %d개" % retarget(rows, revert=True))
        return
    preview = None
    for a in sys.argv[1:]:
        if a.startswith("--preview="):
            preview = a[len("--preview="):]
            os.makedirs(preview, exist_ok=True)
    kit = load_kit()
    sheets = {}
    rows = {}
    for place, spec in SWAP.items():
        r, nk, n = build(place, spec, kit, sheets, preview)
        rows[place] = r
        print("%s: 칸 %d 중 키트 %d · 유지 %d" % (place, n, nk, n - nk))
    print("타일 고침: %d개" % retarget(rows))


if __name__ == "__main__":
    main()
