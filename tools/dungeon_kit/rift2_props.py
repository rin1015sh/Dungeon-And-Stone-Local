#!/usr/bin/env python3
"""2층 균열 넷 전용 서 있는 소품(2026-11-21 — 사용자 "에셋팩에서 가져오고, 따로 그려야 하면 그려 넣어라").

에셋 라이브러리(던전 키트)의 소품 그림을 칸 4 × 3(256 × 192px · 발 (128, 160) — stand_swap.py와 같은 틀)짜리 시트
assets/floor/kit/r2_stand.webp 하나에 모으고, 돌 · 나무 소품은 그 균열 색으로 물들인다(tint — 빛나는 것 · 불은 그대로).
data/tiles.json에 서 있는 소품 타일 r2p_<이름>을 더한다(없는 것만 — 손 서식을 지키려고 글자로 끝에 붙인다).

    python3 tools/dungeon_kit/rift2_props.py [--preview=<png>]  → python3 tools/sheet_bounds.py → texture_compress.py → --import → 캡처
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from stand_swap import CH, COLS, CW, kit_cell, load_kit  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TILES = os.path.join(ROOT, "data", "tiles.json")
SHEET = "assets/floor/kit/r2_stand.webp"

# 타일 id → (키트 그림, 이름, 밑 바닥, 물들일 색(없으면 그대로), 빛 {color, radius_m}, 시야를 막는가)
PROPS = [
    ("r2p_sg_sarcophagus", "sarcophagus.closed", "가라앉은 석관", "r2sg_flag", "#5a605a", None, False),
    ("r2p_sg_sarcophagus_b", "sarcophagus.broken", "깨진 석관", "r2sg_flag", "#5a605a", None, False),
    ("r2p_sg_statue", "statue.mossy", "이끼 낀 기사상", "r2sg_flag", None, None, False),
    ("r2p_sg_candles", "candles.lit", "장례 촛불", "r2sg_flag", None, {"color": "#9ab4ff", "radius_m": 3.0}, False),
    ("r2p_sg_skeleton", "skeleton.sitting", "기대앉은 유골", "r2sg_mud", None, None, False),
    ("r2p_wd_column", "column_natural.a", "바람에 깎인 돌기둥", "r2wd_rock", "#6a5e50", None, True),
    ("r2p_wd_boulder", "boulder_mossy.a", "이끼 바위", "r2wd_rock", None, None, False),
    ("r2p_wd_nest", "nest.eggs", "짐승 둥지", "r2wd_dirt", None, None, False),
    ("r2p_wd_bone", "giant_bone.rib_single", "거대한 갈비뼈", "r2wd_dirt", None, None, False),
    ("r2p_wd_stalagmite", "stalagmite.tall", "석순", "r2wd_rock", "#6a5e50", None, False),
    ("r2p_st_pillar", "pillar.cracked", "금 간 사암 기둥", "r2st_flag", "#a88a62", None, True),
    ("r2p_st_statue", "statue_robed.intact", "해 사제상", "r2st_flag", "#a88a62", None, False),
    ("r2p_st_brazier", "brazier.lit", "타는 화로", "r2st_flag", None, {"color": "#ffb060", "radius_m": 4.0}, False),
    ("r2p_st_hoodoo", "rock_sandstone.hoodoo", "모래에 깎인 바위", "r2st_sand", None, None, False),
    ("r2p_st_pedestal", "pedestal.broken", "부서진 받침돌", "r2st_flag", "#a88a62", None, False),
    ("r2p_td_support", "mine_support.sagging", "처진 버팀목", "r2td_dirt", None, None, False),
    ("r2p_td_tent", "tent.hide", "가죽 천막", "r2td_dirt", None, None, False),
    ("r2p_td_fire", "firepit.lit", "고블린 모닥불", "r2td_dirt", None, {"color": "#ff9a50", "radius_m": 4.0}, False),
    ("r2p_td_spikes", "trap_remains.rusty_spikes", "녹슨 덫 더미", "r2td_root", None, None, False),
    ("r2p_td_crate", "crate.broken", "부서진 궤짝", "r2td_dirt", None, None, False),
]


def tint(img, col):
    a = np.asarray(img).astype(np.float32) / 255.0
    rgb, al = a[..., :3], a[..., 3]
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)
    m = lum[al > 0.5].mean() if (al > 0.5).any() else 0.5
    t = np.array([int(col[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255.0
    out = np.clip(lum[..., None] / max(m, 1e-3) * t * 0.7 + rgb * 0.3, 0, 1)
    return Image.fromarray((np.dstack([out, al]) * 255 + 0.5).astype(np.uint8), "RGBA")


def main():
    kit = load_kit()
    sheets = {}
    rows = -(-len(PROPS) // COLS)
    out = Image.new("RGBA", (COLS * CW, rows * CH), (0, 0, 0, 0))
    tiles = json.load(open(TILES, encoding="utf-8"))
    have = {t["id"] for t in tiles}
    new = []
    for k, (tid, ref, name, under, col, light, sight) in enumerate(PROPS):
        img, (px, py), _s = kit_cell(kit, sheets, ref)
        if col:
            img = tint(img, col)
        out.alpha_composite(img, ((k % COLS) * CW + px, (k // COLS) * CH + py))
        if tid in have:
            continue
        e = {"id": tid, "name_ko": name, "kind": "wall", "walkable": False, "blocks_sight": sight,
             "colors": {"top": "#2a2622", "face": col or "#6a6258"}, "face_px": 14, "source": "original",
             "art": {"stand": {"sheet": "res://" + SHEET, "cell": k, "cols": COLS, "rows": rows, "size": [4, 3], "under": under}},
             "notes": "2층 균열 소품(tools/dungeon_kit/rift2_props.py — 키트 %s)" % ref}
        if light:
            e["light"] = {"radius_m": light["radius_m"], "color": light["color"], "intensity": 0.8}
        new.append(e)
    out.save(os.path.join(ROOT, SHEET), lossless=True, quality=100, exact=True)
    if new:
        text = open(TILES, encoding="utf-8").read().rstrip()
        body = ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in new)
        text = text[:-1].rstrip() + ",\n" + body + "\n]\n"
        json.loads(text)
        open(TILES, "w", encoding="utf-8").write(text)
    print("소품 %d(새 타일 %d) · 시트 %d줄" % (len(PROPS), len(new), rows))
    for a in sys.argv[1:]:
        if a.startswith("--preview="):
            bg = Image.new("RGBA", out.size, (60, 56, 50, 255))
            bg.alpha_composite(out)
            bg.convert("RGB").save(a[len("--preview="):], quality=85)


if __name__ == "__main__":
    main()
