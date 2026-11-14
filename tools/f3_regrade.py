#!/usr/bin/env python3
"""3층 필드 몬스터를 7등급으로(사용자 2026-11-14 "3층은 7등급 몬스터들이 주로 등장 — 2층은 8등급", ASSUMPTIONS F3-12).
원작 등급(8 · 9)은 notes에 남기고, 주 스탯 · 생명력 · 자연 무기를 10층 곡선(balance_curve.normal_at)의 등급 기준 비율만큼 올린다.
마석 등급도 7. 몇 번 돌려도 같다 — 원래 값은 git BASE의 파일(아래 BASE)에서 읽는다.
  python3 tools/f3_regrade.py [--dry]
[창작] 임시값."""
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import balance_curve as C  # noqa: E402
from restat_monsters import _set_in_block  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = "6a1d24f"  # 7등급으로 올리기 전(원작 등급 그대로)
IDS = ["dirouter", "dryad", "frogman", "homunculus", "iron_falcon", "lizardman", "mutant_spirit", "orc_archer", "orc_shaman", "orc_warrior",
       "snetree", "steel_hill_guard", "fairy", "witch_lamp", "witch_wraith", "woodman"]
MAIN = ["str", "agi", "p_res", "m_res", "int"]
TO = 7


def ratio(g):
    """원래 등급 → 7등급 배율. 9등급은 곡선 그대로면 3~4배라 너무 커서 8 → 7 배율 × 1.15(9등급이 8등급보다 조금 약한 만큼)."""
    a, b = C.normal_at(C.GRADE_PL[min(g, 8)]), C.normal_at(C.GRADE_PL[TO])
    extra = 1.15 if g >= 9 else 1.0
    return {k: b[k] / a[k] * extra for k in MAIN + ["hp", "w"]}


def main():
    dry = "--dry" in sys.argv
    for mid in IDS:
        rel = "data/monsters/%s.json" % mid
        base = json.loads(subprocess.run(["git", "show", "%s:%s" % (BASE, rel)], cwd=ROOT, capture_output=True, check=True, text=True).stdout)
        g0 = int(base["grade"])
        r = ratio(g0)
        path = os.path.join(ROOT, rel)
        text = open(path, encoding="utf-8").read()
        new = {k: round(float(base["stats"].get(k, 0)) * r[k]) for k in MAIN}
        hp = round(float(base["resources"]["hp"]) * r["hp"])
        w = round(float((base.get("natural_weapon") or {}).get("attack", 0)) * r["w"])
        print("%-16s %d→%d  %s hp %s→%d w →%d" % (mid, g0, TO, new, base["resources"]["hp"], hp, w))
        if dry:
            continue
        for k in MAIN:
            if k in base["stats"]:
                text = _set_in_block(text, "stats", k, new[k])
        text = _set_in_block(text, "resources", "hp", hp)
        if w > 0:
            text = _set_in_block(text, "natural_weapon", "attack", w)
        text = re.sub(r'("grade"\s*:\s*)\d+', r"\g<1>%d" % TO, text, count=1)
        text = re.sub(r'("magic_stone_grade"\s*:\s*)\d+', r"\g<1>%d" % TO, text, count=1)
        d = json.loads(text)
        note = "원작 %d등급 — 3층 필드는 7등급으로(사용자 2026-11-14, F3-12 · tools/f3_regrade.py)" % g0
        if note not in d.get("notes", ""):
            d["notes"] = (d.get("notes", "") + " · " if d.get("notes") else "") + note
            text = json.dumps(d, ensure_ascii=False, indent=2) + "\n"
        open(path, "w", encoding="utf-8").write(text)


if __name__ == "__main__":
    main()
