#!/usr/bin/env python3
"""2층 균열 넷 전용 바닥 · 벽(2026-11-21 — 사용자 "에셋 · 스프라이트 위주, 에셋팩에서 가져오고 없으면 그려 넣어라").

바닥 = 에셋 라이브러리(던전 키트) 바닥 그림(4 × 4칸 이어지는 넓은 그림)을 그 균열 색으로 다시 칠한다(ground_swap.py와 같은 방식 —
채널 평균을 목표 색에, 명암 대비는 0.85 ~ 1.2배 안에서). 벽 = 게임 벽은 동굴 꼴 윤곽 · 사방 면이라 키트 벽(북쪽 곧은 벽뿐)을 못 쓴다 →
1층 균열 벽 아틀라스(모양 · 문 그대로)를 다시 칠해 새 벽 타일로. → assets/floor/kit/r2_<이름>.webp + data/tiles.json에 타일(없으면 더하고
있으면 art만 갈아 끼움) + 탈출 포탈 타일(rift_gate_<바닥>).

    python3 tools/dungeon_kit/rift2_tiles.py [--preview=<png>]   → texture_compress.py → --import → 캡처
"""
import copy
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets", "dungeon_kit")
TILES = os.path.join(ROOT, "data", "tiles.json")
CONTRAST = (0.85, 1.2)

# 새 바닥: id → (키트 바닥, 목표 평균 색, 이름, 메모)
FLOORS = {
    "r2sg_flag": ("floor_old.a", "#4c524e", "물먹은 묘역 포석", "가라앉은 묘역 — 진흙물이 밴 옛 포석"),
    "r2sg_mud": ("ground_mud.a", "#3a3e3b", "묘역 진흙", "가라앉은 묘역 — 묘 구획 사이 진흙길"),
    "r2wd_rock": ("ground_rock.b", "#62584c", "바람굴 암반", "울부짖는 바람굴 — 바람에 닳은 협곡 바닥"),
    "r2wd_dirt": ("floor_dirt.a", "#584a3a", "바람굴 흙", "울부짖는 바람굴 — 흙먼지가 쌓인 굴 바닥"),
    "r2st_flag": ("floor_flag.a", "#9c825e", "사암 판석", "꺼진 태양의 신전 — 볕에 바랜 사암 판석"),
    "r2st_sand": ("floor_sand.a", "#b0915f", "신전 모래", "꺼진 태양의 신전 — 천장 틈으로 흘러내린 모래"),
    "r2td_dirt": ("floor_dirt.b", "#4a4030", "굴 흙바닥", "덫꾼의 굴 — 고블린이 다져 놓은 흙"),
    "r2td_root": ("ground_hardpan.a", "#3e3a2e", "굳은 굴 흙", "덫꾼의 굴 — 말라 갈라진 굴 바닥"),
    "r2wd_bones": ("ground_bones.a", "#6a5e4c", "뼈가 깔린 둥지 바닥", "울부짖는 바람굴 — 뼈 둥지에 깔린 뼈 부스러기"),
}
# 새 벽: id → (본보기 벽 타일, 목표 평균 색, 이름)
WALLS = {
    "r2sg_wall": ("fortress_wall", "#4a4f4a", "이끼 낀 묘역 석벽"),
    "r2wd_wall": ("ice_wall", "#5c5246", "바람굴 바위벽"),
    "r2st_wall": ("metal_wall", "#8a7254", "벽화가 새겨진 사암벽"),
    "r2td_wall": ("mine_wall", "#4a4234", "덫꾼 굴 흙벽"),
}
# 요소 칸(걸을 수 있다 — 동굴 요소 소품, 키트 그림 칸은 game_props.py): id → (본보기 타일, 소품 칸, 이름, 빛)
FEATURE_TILES = {
    "r2f_altar": ("f2d_offering", 34, "후회의 제단", {"radius_m": 3.0, "color": "#d8d0c0", "intensity": 0.6}),
    "r2f_spire": ("f2r_offering", 35, "모래에 묻힌 첨탑 끝", {"radius_m": 2.0, "color": "#ffc070", "intensity": 0.5}),
    "r2f_windgap": ("f2d_cairn", 36, "막힌 바람 틈", None),
}
GATES = ["r2sg_flag", "r2wd_rock", "r2st_flag", "r2td_dirt"]  # 탈출 포탈(수호자가 쓰러진 자리)이 서는 바닥


def hexrgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], np.float32) / 255.0


def recolor(img, target, mask=None):
    """img (H, W, 3) 0~1 → 채널 평균을 target에(mask가 있으면 그 칸만 재고 칠한다)."""
    px = img[mask] if mask is not None else img.reshape(-1, 3)
    out = img.copy()
    lum = px.mean(axis=1)
    lo, hi = np.percentile(lum, 5), np.percentile(lum, 95)
    r = float(np.clip(0.22 / max(hi - lo, 1e-3), *CONTRAST))
    for c in range(3):
        out[..., c] = (img[..., c] - px[:, c].mean()) * r + target[c]
    return np.clip(out, 0, 1)


def colorize(img, target, mask, keep=0.3):
    """벽: 밝기를 살려 target 색으로 물들인다(원래 색은 keep만큼 남긴다 — 줄눈 · 나무틀 결이 남게). 핏자국 같은 튀는 색도 가라앉는다."""
    lum = img @ np.array([0.299, 0.587, 0.114], np.float32)
    m = lum[mask].mean() if mask is not None else lum.mean()
    tint = np.clip(lum[..., None] / max(m, 1e-3) * target[None, None, :], 0, 1)
    return np.clip(tint * (1.0 - keep) + recolor(img, target, mask) * keep, 0, 1)


def kit_floor(kit, ref):
    aid, _, var = ref.partition(".")
    a = kit["assets"][aid]
    x, y, w, h, _ox, _oy = a["variants"][var]["frames"][0]
    sheet = Image.open(os.path.join(KIT, a["sheet"] + ".webp")).convert("RGB")
    return np.asarray(sheet.crop((int(x), int(y), int(x + w), int(y + h)))).astype(np.float32) / 255.0


def save(img, name, alpha=None):
    dst = os.path.join(ROOT, "assets", "floor", "kit", name + ".webp")
    arr = (img * 255 + 0.5).astype(np.uint8)
    if alpha is not None:
        Image.fromarray(np.dstack([arr, alpha]), "RGBA").save(dst, lossless=True, quality=100, exact=True)
    else:
        Image.fromarray(arr, "RGB").save(dst, lossless=True, quality=100, exact=True)
    return "res://assets/floor/kit/%s.webp" % name


def put(tiles, entry):
    """tiles.json 손 서식을 지키려고 글자로 다룬다(main): 없으면 끝에 붙이고, 있으면 그 한 줄(이 도구가 쓴 한 줄짜리 항목)을 갈아 끼운다."""
    if not any(t["id"] == entry["id"] for t in tiles):
        tiles.append(entry)
    NEW.append(entry)


NEW = []


def main():
    kit = json.load(open(os.path.join(KIT, "kit.json"), encoding="utf-8"))
    tiles = json.load(open(TILES, encoding="utf-8"))
    by_id = {t["id"]: t for t in tiles}
    prev = []
    for tid, (ref, col, name, note) in FLOORS.items():
        img = recolor(kit_floor(kit, ref), hexrgb(col))
        path = save(img, tid)
        put(tiles, {"id": tid, "name_ko": name, "kind": "floor", "walkable": True, "blocks_sight": False, "colors": {"floor": col},
                    "art": {"atlas": path, "variants": 6, "span": 4}, "source": "original",
                    "notes": "%s(tools/dungeon_kit/rift2_tiles.py — 키트 %s를 다시 칠함)" % (note, ref)})
        prev.append(img)
    for tid, (base, col, name) in WALLS.items():
        b = by_id[base]
        src = os.path.join(ROOT, b["art"]["atlas"].replace("res://", ""))
        im = np.asarray(Image.open(src).convert("RGBA")).astype(np.float32) / 255.0
        alpha = (im[..., 3] * 255 + 0.5).astype(np.uint8)
        TOP = 64  # 윗면 칸 줄(64px) · 아래는 앞면 — 줄마다 따로 물들인다(윗면은 어둡게)
        rgb, op = im[..., :3], im[..., 3] > 0.5
        img = np.concatenate([colorize(rgb[:TOP], hexrgb(col) * 0.45, op[:TOP]), colorize(rgb[TOP:], hexrgb(col), op[TOP:])], axis=0)
        path = save(img, tid, alpha)
        e = copy.deepcopy(b)
        e.update({"id": tid, "name_ko": name, "source": "original",
                  "notes": "2층 균열 벽(tools/dungeon_kit/rift2_tiles.py — %s 아틀라스를 다시 칠함, 모양 · 문 그대로)" % base})
        e["art"]["atlas"] = path
        e.pop("light", None)  # 얼음벽처럼 스스로 빛나는 본보기의 빛은 뺀다
        e["colors"] = {"top": "#1a1816", "face": col}
        if tid == "r2wd_wall":
            e["art"]["doors"] = ["rough", "cave", "rough"]  # 자연 협곡 — 바위 틈 · 굴 입구(얼음벽 본보기의 결을 바위색으로)
        put(tiles, e)
    for tid, (base, cell, name, light) in FEATURE_TILES.items():
        e = copy.deepcopy(by_id[base])
        e.update({"id": tid, "name_ko": name, "source": "original",
                  "notes": "2층 균열 · 군주 요소 칸(rift2_tiles.py — 바닥은 %s, 소품 = kit/props.webp 칸 %d, game_props.py)" % (base, cell)})
        e["art"]["prop"]["cell"] = cell
        if light:
            e["light"] = light
        put(tiles, e)
    gate = by_id["rift_gate_fortress_floor"]
    for fid in GATES:
        e = copy.deepcopy(gate)
        f = next(t for t in tiles if t["id"] == fid)
        e["id"] = "rift_gate_" + fid
        e["colors"]["floor"] = f["colors"]["floor"]
        e["art"]["atlas"] = f["art"]["atlas"]
        e["art"]["span"] = 4
        e["notes"] = "마지막 챕터에서 수호자가 쓰러진 자리에 서는 세로 차원문(RF21) — 바닥은 %s(rift2_tiles.py)" % fid
        put(tiles, e)
    if NEW:
        text = open(TILES, encoding="utf-8").read().rstrip()
        assert text.endswith("]")
        lines = text.split("\n")
        add = []
        for e in NEW:
            key = '{"id": "%s",' % e["id"]
            hit = [i for i, ln in enumerate(lines) if ln.strip().startswith(key)]
            if hit:
                comma = "," if lines[hit[0]].rstrip().endswith(",") else ""
                lines[hit[0]] = "  " + json.dumps(e, ensure_ascii=False) + comma
            else:
                add.append(e)
        text = "\n".join(lines)
        if add:
            body = ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in add)
            text = text[:-1].rstrip() + ",\n" + body + "\n]"
        text += "\n"
        json.loads(text)
        with open(TILES, "w", encoding="utf-8") as f:
            f.write(text)
    print("바닥 %d · 벽 %d · 포탈 %d" % (len(FLOORS), len(WALLS), len(GATES)))
    for a in sys.argv[1:]:
        if a.startswith("--preview="):
            T = 256
            sheet = Image.new("RGB", (T * 4, T * 2), (20, 20, 20))
            for k, img in enumerate(prev):
                sheet.paste(Image.fromarray((img * 255).astype(np.uint8)).resize((T, T)), ((k % 4) * T, (k // 4) * T))
            sheet.save(a[len("--preview="):])


if __name__ == "__main__":
    main()
