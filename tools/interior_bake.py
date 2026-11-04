"""도시 건물 실내 그림 굽기(CT106 — 사용자 2026-11-04 "외부 도시나 건물 형태 분위기랑 비교해서 이질감 안 느껴지게 · 입체감 벽"):
  python3 tools/interior_bake.py [inn temple …] [--preview]
data/interiors/<id>.json → assets/city/interiors/<id>/ r<방>_bg.webp · r<방>_f<줄>.webp · w_<x>_<y>.webp · f_<x>_<y>.webp + index.json(InteriorWorld가 읽는다).
방마다 따로 굽는다(지금 방만 보이므로 방 사이 벽을 방마다 다르게 그린다): 방 바닥 · 북벽은 높이 WALL_H칸으로 세운 앞면(재질 · 벽 장식 · 문) + 윗면,
옆벽은 높이만큼 올라간 윗면(두께가 보인다), 남벽은 LOW칸으로 낮게 잘라(사람을 가리지 않게) 따로 — 발 높이로 앞뒤를 정한다.
가구는 덩어리마다 한 그림(윗면 + 앞면 — 3/4). 빛 = 방 밝기 + 광원(불 · 창 · 색유리 · 입구 낮빛). 마감 = 동네 집과 같은 손그림(town_handdrawn.finish — 쿠와하라 · 먹선 · 빗금 · 종이 결).
--preview: 방마다 바닥 + 가구 + 남벽을 한 장에 겹친 미리보기(docs/plans/interiors/bake/<id>_r<방>.png — 커밋하지 않는다).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import interior_furn as F  # noqa: E402
import interior_mats as M  # noqa: E402
import interior_walldeco as W  # noqa: E402
import town_handdrawn as th  # noqa: E402
from interior_canvas import Canvas, P, hexc  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WALL_H = 3.0  # 북벽 · 옆벽 높이(칸 — 사람 키의 1.5배쯤)
CAP_IN = 0.5  # 벽 윗면 두께(칸 — 바깥쪽 반은 비운다, 벽이 덩어리처럼 무겁지 않게)
LOW = 0.42  # 남벽(잘라 낸 낮은 벽) 높이(칸)
SPLIT = ("wall", "wallart", "door", "exit", "void")
CAP = hexc("#2c2520")
RIM = hexc("#7a6c5a")
COOL = (0.62, 0.7, 0.8)


def cell_kind(legend, ch):
    return {"#": "wall", ".": "floor", "D": "exit"}.get(ch) or legend.get(ch, {}).get("kind", "void")


class Plan:
    def __init__(self, d):
        self.d = d
        self.rows = d["rows"]
        self.h, self.w = len(self.rows), max(len(r) for r in self.rows)
        self.legend = d.get("legend", {})

    def ch(self, x, y):
        if 0 <= y < self.h and 0 <= x < len(self.rows[y]):
            return self.rows[y][x]
        return " "

    def kind(self, x, y):
        return cell_kind(self.legend, self.ch(x, y))

    def rooms(self):
        seen, out = set(), []
        for y in range(self.h):
            for x in range(self.w):
                if (x, y) in seen or self.kind(x, y) in SPLIT:
                    continue
                cells, todo = [], [(x, y)]
                seen.add((x, y))
                while todo:
                    c = todo.pop()
                    cells.append(c)
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        n = (c[0] + dx, c[1] + dy)
                        if n not in seen and self.kind(*n) not in SPLIT:
                            seen.add(n)
                            todo.append(n)
                out.append(cells)
        return out

    def groups(self, kinds):
        seen, out = set(), []
        for y in range(self.h):
            for x in range(self.w):
                c = self.ch(x, y)
                if (x, y) in seen or self.kind(x, y) not in kinds:
                    continue
                cells, todo = [], [(x, y)]
                seen.add((x, y))
                while todo:
                    p = todo.pop()
                    cells.append(p)
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        n = (p[0] + dx, p[1] + dy)
                        if n not in seen and self.ch(*n) == c:
                            seen.add(n)
                            todo.append(n)
                xs, ys = [p[0] for p in cells], [p[1] for p in cells]
                out.append({"char": c, "x0": min(xs), "y0": min(ys), "x1": max(xs) + 1, "y1": max(ys) + 1, "cells": cells})
        return out

    def spot_chars(self):
        out = set()
        for s in self.d.get("spots", []):
            if s.get("char"):
                out.add(s["char"])
            elif s.get("at"):
                out.add(self.ch(*s["at"]))
        return out


def role(R, x, y):
    """방 R 둘레 벽 칸의 쓰임: north(앞면이 보인다 — 방이 남쪽) · south(낮게 자른다 — 방이 북쪽) · side(옆벽)."""
    if (x, y + 1) in R:
        return "north"
    if (x, y - 1) in R:
        return "south"
    if (x - 1, y) in R or (x + 1, y) in R:
        return "side"
    if (x - 1, y - 1) in R or (x + 1, y - 1) in R:
        return "south"
    return "north"


def lights_of(plan, R, ring, groups):
    """방 R의 광원 [(x, y, 반지름, 색, 세기)] — 가구(방 안) · 벽 장식(둘레) · 바깥 문 낮빛."""
    out = []
    for g in groups:
        if not any(c in R or c in ring for c in g["cells"]):
            continue
        L = plan.legend.get(g["char"], {}).get("light")
        if not L:
            continue
        cx = (g["x0"] + g["x1"]) / 2
        wallish = plan.legend[g["char"]]["kind"] == "wallart"
        cy = g["y1"] + 1.2 if wallish else (g["y0"] + g["y1"]) / 2
        col = tuple(hexc(L["color"]))
        if plan.legend[g["char"]].get("art") == "stained_glass":
            pw = (g["x1"] - g["x0"]) / 3
            for k, c in enumerate(("#c04a36", "#e8c060", "#4a9a5a")):
                out.append((g["x0"] + pw * (k + 0.5), g["y1"] + 3.4 + abs(k - 1) * 0.4, 3.6, tuple(hexc(c)), 0.6))
        out.append((cx, cy, float(L["radius"]), col, float(L["power"])))
    exits = [c for c in ring if plan.kind(*c) == "exit"]
    if exits:
        ex = sum(c[0] for c in exits) / len(exits) + 0.5
        out.append((ex, exits[0][1] - 0.2, 3.6, COOL, 0.38))
    return out


def finish(cv, path):
    img, alpha = th.finish(np.clip(cv.raw, 0, 1), cv.code, sprite=True, fine=True)
    rgba = (np.dstack([img, alpha]) * 255).astype(np.uint8)
    Image.fromarray(rgba, "RGBA").save(path, quality=92, alpha_quality=100, method=5)
    return rgba


def bake_room(plan, i, R, groups, out_dir, seed, index):
    rd = next((r for r in plan.d.get("rooms", []) if tuple(r["at"]) in R), {})
    xs, ys = [c[0] for c in R], [c[1] for c in R]
    bx0, bx1, by0, by1 = min(xs), max(xs), min(ys), max(ys)
    ring = set()
    for (x, y) in R:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                n = (x + dx, y + dy)
                if n not in R and plan.kind(*n) in SPLIT:
                    ring.add(n)
    cv = Canvas(bx0 - 1.3, by0 - 1 - WALL_H - 0.35, bx1 - bx0 + 3.6, by1 - by0 + 3 + WALL_H + 0.7, seed)
    ftex = M.floor(rd.get("floor", "oak"), seed)
    fid = cv.new_id()
    for (x, y) in sorted(R):
        cv.ground(x, y, x + 1, y + 1, tex=ftex, cid=fid)
    for (x, y) in ring:
        k = plan.kind(x, y)
        if k in ("door", "exit"):
            cv.ground(x, y, x + 1, y + 1, None, tex=M.slabs("#7a7266", 1.0, 1.0, seed + x, 0.05))
            if k == "exit":
                cv.ground(x - 0.4, y + 1, x + 1.4, y + 1.8, None, tex=M.slabs("#6a727a", 0.45, 0.4, seed + 3, 0.2), lit=1.0)
    # 벽 밑 그늘(북 · 서 · 동벽 곁) · 가구 접지 그늘
    for (x, y) in R:
        if (x, y - 1) in ring:
            cv.darken_rect(x, y, x + 1, y + 1.0, 0.55, 0.0)
        if (x - 1, y) in ring:
            cv.darken_cols(x, y, x + 0.5, y + 1, 0.38, 0.0)
        if (x + 1, y) in ring:
            cv.darken_cols(x + 0.5, y, x + 1, y + 1, 0.0, 0.34)
        if (x, y + 1) in ring and plan.kind(x, y + 1) != "exit":
            cv.darken_rect(x, y + 0.7, x + 1, y + 1, 0.0, 0.35)
    for g in groups:
        if plan.legend[g["char"]]["kind"] in ("furniture",) and g["cells"][0] in R and not plan.legend[g["char"]].get("needs"):
            gw = g["x1"] - g["x0"]
            cv.shadow((g["x0"] + g["x1"]) / 2, g["y1"] - 0.25, gw * 0.55 + 0.1, 0.42, 0.42)
    # 높은 벽(북벽 앞면 · 옆벽 윗면) — 북쪽 줄부터
    wname = rd.get("wall", "ashlar")
    cap_id = cv.new_id()
    hot = plan.spot_chars()
    full = {c for c in ring if role(R, *c) != "south"}
    face_rows = {}
    inside = R | ring
    for (x, y) in sorted(full, key=lambda c: (c[1], c[0])):
        r = role(R, x, y)
        # 윗면 네모: 바깥(방도 둘레 벽도 아닌 칸) 쪽 변은 CAP_IN만 남기고 비운다
        cx0 = x + (1 - CAP_IN if (x - 1, y) not in inside else 0)
        cx1 = x + 1 - (1 - CAP_IN if (x + 1, y) not in inside else 0)
        cy0 = y + (1 - CAP_IN if (x, y - 1) not in inside else 0)
        if r == "north" or (x, y + 1) not in full:
            fy = y + 1
            if fy not in face_rows:
                face_rows[fy] = (cv.new_id(), cv.new_id(), cv.new_id())
            fid_w, fid_b, fid_c = face_rows[fy]
            if r == "north":
                cv.front(x, x + 1, fy, 0, WALL_H, None, tex=M.wall(wname, seed + fy, fy), cid=fid_w, shade=(0.92, 0.66))
                cv.front(x, x + 1, fy, 0, 0.2, M.base_color(wname), cid=fid_b, shade=(0.8, 0.55))  # 걸레받이
                cv.front(x, x + 1, fy, WALL_H - 0.16, WALL_H, M.base_color(wname) * 1.15, cid=fid_c, shade=(1.0, 0.8))  # 처마 띠
            else:  # 옆벽 끝 = 잘린 단면(어두운 돌 — 벽 두께만큼)
                cv.front(cx0, cx1, fy, 0, WALL_H, CAP * 1.5, cid=cap_id, tex=M.grainy("#3a322a", seed, 0.3, 5), shade=(1.0, 0.7))
        cv.ground(cx0, cy0, cx1, y + 1, CAP, z=WALL_H, cid=cap_id, tex=M.grainy("#2e2721", seed, 0.25, 6))
        for (dx, dy) in ((0, 1), (-1, 0), (1, 0)):  # 방 쪽 가장자리 = 밝은 테(빛 받는 모서리)
            if (x + dx, y + dy) in R or ((x + dx, y + dy) not in full and (x + dx, y + dy) in ring and dy == 1):
                if dy == 1:
                    cv.ground(cx0, y + 0.86, cx1, y + 1, RIM, z=WALL_H, cid=cap_id)
                elif dx < 0:
                    cv.ground(x, cy0, x + 0.1, y + 1, RIM * 0.85, z=WALL_H, cid=cap_id)
                else:
                    cv.ground(x + 0.9, cy0, x + 1, y + 1, RIM * 0.8, z=WALL_H, cid=cap_id)
    for g in groups:  # 방 사이 문(북벽 — 붙은 문 칸은 아치 하나): 문틀 · 어두운 너머 · 문턱 · 안쪽으로 연 문짝
        if plan.legend[g["char"]]["kind"] != "door" or not all(c in full and role(R, *c) == "north" for c in g["cells"]):
            continue
        x0, x1, yf = g["x0"], g["x1"], g["y1"]
        W.arch(cv, yf, x0 + 0.06, x1 - 0.06, 0.0, 2.3 + (x1 - x0 - 1) * 0.3, hexc("#4e463c"))
        W.arch(cv, yf, x0 + 0.16, x1 - 0.16, 0.0, 2.2 + (x1 - x0 - 1) * 0.3, W.DARK, lit=0.0)
        cv.ground(x0 + 0.16, yf - 0.65, x1 - 0.16, yf, None, tex=M.slabs("#6a6258", 1.0, 1.0, seed, 0.05), lit=0.55)
        cv.front(x0 + 0.16, x0 + 0.28, yf - 0.4, 0.0, 2.0, None, tex=M.plank_door(seed + x0), shade=(0.5, 0.35))
        if x1 - x0 > 1:
            cv.front(x1 - 0.28, x1 - 0.16, yf - 0.4, 0.0, 2.0, None, tex=M.plank_door(seed + x1), shade=(0.5, 0.35))
    for g in groups:
        if plan.legend[g["char"]]["kind"] != "wallart" or not all(c in full and role(R, *c) == "north" for c in g["cells"]):
            continue
        art = plan.legend[g["char"]].get("art", "")
        if g["char"] in hot:
            continue  # 활동 자리(책장 …)는 따로(검은 테두리)
        W.draw(cv, art, g["x0"], g["x1"], g["y1"], WALL_H, seed + g["x0"] * 7)
    lights = lights_of(plan, R, ring, groups)
    amb = float(rd.get("ambient", 0.65))
    cv.light(amb, lights)
    os.makedirs(out_dir, exist_ok=True)
    entry = {"bg": {"file": "r%d_bg.webp" % i, "origin": [cv.ox, cv.oy]}, "front": []}
    finish(cv, os.path.join(out_dir, entry["bg"]["file"]))
    # 활동 자리 벽 장식(책장) · 사건 순에만 열리는 문의 닫힌 그림 — 따로
    for g in groups:
        k = plan.legend[g["char"]]["kind"]
        if k not in ("wallart", "door") or not all(c in full and role(R, *c) == "north" for c in g["cells"]):
            continue
        is_closed = k == "door" and plan.legend[g["char"]].get("opens")
        if not (g["char"] in hot and k == "wallart") and not is_closed:
            continue
        wc = Canvas(g["x0"] - 0.2, g["y1"] - WALL_H - 0.2, g["x1"] - g["x0"] + 0.4, WALL_H + 0.5, seed)
        W.draw(wc, "door_closed" if is_closed else plan.legend[g["char"]].get("art", ""), g["x0"], g["x1"], g["y1"], WALL_H, seed + g["x0"])
        wc.light(amb, lights)
        name = "w_%d_%d.webp" % (g["x0"], g["y0"])
        finish(wc, os.path.join(out_dir, name))
        e = {"file": name, "origin": [wc.ox, wc.oy], "cell": [g["x0"], g["y0"]], "room": i}
        if is_closed:
            e["closed_door"] = True
        index["wallart"].append(e)
    # 낮게 자른 남벽(줄마다 한 장 — 발 높이로 앞뒤)
    south = sorted(c for c in ring if role(R, *c) == "south" and plan.kind(*c) not in ("door", "exit"))
    for yy in sorted({c[1] for c in south}):
        row = [c for c in south if c[1] == yy]
        x0, x1 = min(c[0] for c in row), max(c[0] for c in row) + 1
        fc = Canvas(x0 - 0.1, yy - LOW - 0.15, x1 - x0 + 0.2, LOW + 1.3, seed + yy)
        sid, cid2 = fc.new_id(), fc.new_id()
        for (x, y) in row:
            fc.front(x, x + 1, y + 1, 0, LOW, None, tex=M.wall(wname, seed + 5, y + 1), cid=sid, shade=(0.9, 0.62))
            fc.ground(x, y, x + 1, y + 1, CAP, z=LOW, cid=cid2, tex=M.grainy("#2c2520", seed, 0.25, 6))
            fc.ground(x, y, x + 1, y + 0.12, RIM, z=LOW, cid=cid2)
        fc.light(amb, lights)
        name = "r%d_f%d.webp" % (i, yy)
        finish(fc, os.path.join(out_dir, name))
        entry["front"].append({"file": name, "origin": [fc.ox, fc.oy], "foot": yy + 0.5})
    # 가구(이 방 것)
    for g in groups:
        if plan.legend[g["char"]]["kind"] not in ("furniture", "low") or g["cells"][0] not in R:
            continue
        art = plan.legend[g["char"]].get("art", "")
        gw, gd = g["x1"] - g["x0"], g["y1"] - g["y0"]
        zmax = F.HEIGHT.get(art, 1.3)
        fc = Canvas(-0.45, -zmax - 0.45, gw + 0.9, gd + zmax + 0.9, seed + g["x0"] * 31 + g["y0"])
        F.draw(fc, art, gw, gd, seed + g["x0"] * 13 + g["y0"])
        fc.light(amb, [(lx - g["x0"], ly - g["y0"], r, c, pw) for (lx, ly, r, c, pw) in lights])
        name = "f_%d_%d.webp" % (g["x0"], g["y0"])
        finish(fc, os.path.join(out_dir, name))
        index["furniture"]["%d,%d" % (g["x0"], g["y0"])] = {"file": name, "origin": [g["x0"] + fc.ox, g["y0"] + fc.oy], "foot": g["y1"], "room": i}
    return entry


def preview(out_dir, index, pid):
    pdir = os.path.join(ROOT, "docs", "plans", "interiors", "bake")
    os.makedirs(pdir, exist_ok=True)
    for i, r in enumerate(index["rooms"]):
        bg = Image.open(os.path.join(out_dir, r["bg"]["file"])).convert("RGBA")
        ox, oy = r["bg"]["origin"]
        sheet = Image.new("RGBA", bg.size, (10, 9, 8, 255))
        sheet.alpha_composite(bg)
        items = []
        for e in index["wallart"]:
            if e["room"] == i and not e.get("closed_door"):
                items.append((-999, e))
        for e in index["furniture"].values():
            if e["room"] == i:
                items.append((e["foot"], e))
        for e in r["front"]:
            items.append((e["foot"], e))
        for _f, e in sorted(items, key=lambda t: t[0]):
            im = Image.open(os.path.join(out_dir, e["file"])).convert("RGBA")
            px, py = int(round((e["origin"][0] - ox) * P)), int(round((e["origin"][1] - oy) * P))
            if 0 <= px < sheet.width and 0 <= py < sheet.height:
                sheet.alpha_composite(im, (max(0, px), max(0, py)))
        sheet.convert("RGB").save(os.path.join(pdir, "%s_r%d.png" % (pid, i)))


def bake(pid, want_preview):
    d = json.load(open(os.path.join(ROOT, "data", "interiors", pid + ".json"), encoding="utf-8"))
    plan = Plan(d)
    out_dir = os.path.join(ROOT, d["art_dir"].replace("res://", ""))
    if os.path.isdir(out_dir):
        for f in os.listdir(out_dir):
            if f.endswith(".webp") or f == "index.json":
                os.remove(os.path.join(out_dir, f))
    groups = plan.groups(("furniture", "low", "wallart", "door"))
    index = {"tile": P, "wall_h": WALL_H, "rooms": [], "wallart": [], "furniture": {}}
    seed = 1000 + sum(map(ord, pid))
    for i, cells in enumerate(plan.rooms()):
        index["rooms"].append(bake_room(plan, i, set(cells), groups, out_dir, seed + i * 17, index))
    json.dump(index, open(os.path.join(out_dir, "index.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    for f in os.listdir(out_dir):  # 없어진 그림의 Godot 가져오기 파일
        if f.endswith(".webp.import") and not os.path.exists(os.path.join(out_dir, f[:-len(".import")])):
            os.remove(os.path.join(out_dir, f))
    if want_preview:
        preview(out_dir, index, pid)
    print("실내 %s: 방 %d · 가구 %d · 벽 장식 %d" % (pid, len(index["rooms"]), len(index["furniture"]), len(index["wallart"])))


def main():
    want = [a for a in sys.argv[1:] if not a.startswith("--")]
    ids = sorted(f[:-5] for f in os.listdir(os.path.join(ROOT, "data", "interiors")) if f.endswith(".json") and not f.startswith("_"))
    for pid in ids:
        if not want or pid in want:
            bake(pid, "--preview" in sys.argv)


if __name__ == "__main__":
    main()
