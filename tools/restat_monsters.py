"""몬스터 수치를 10층 곡선(tools/balance_curve.py)에 맞춰 다시 매긴다 — data/monsters/*.json의 주 스탯 5종·생명력·자연 무기 공격력만 고친다.
    python3 tools/restat_monsters.py [--dry]
규칙(docs/plans/balance_10floors.md §3·§4):
  - 기준 = 등급(rank)과 등급(grade)으로 고른 기준 몬스터(곡선의 normal/보스 규칙).
      일반·사람·무등급·토큰 → 등급표(GRADE_PL)의 일반 몬스터 / 엘리트 → 그 등급 기준 ×1.2, 딜러 평타 10대
      중간 보스 → 그 층 균열(= 층+2 파티)의 중간 보스 / 균열 수호자·변이 수호자·계층군주 → 곡선의 보스 규칙(나오는 층 = 몬스터 floor)
  - 성격은 조정 전 몬스터(git BASE_REV의 data/monsters)에서 가져온다: 스탯마다(주 스탯 5종·생명력·자연 무기) 같은 묶음
    (일반은 등급, 보스는 rank) 평균 대비 비율을 기준에 곱한다 — 늑대는 묶음보다 빠른 만큼 기준보다 빠르다. 주 스탯은 비율을
    SHAPE_EXP 제곱으로 누그러뜨린다(새 방어 공식은 방어 차이가 더 크게 먹어 — 노움 물리내성이 묶음의 두 배면 한 대가 절반 이하).
    늘 조정 전 값에서 계산하므로 다시 돌려도 결과가 같다. 새 몬스터는 BASE_REV에 없으면 지금 값을 성격으로 쓴다.
"""
import glob
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import balance_curve as C  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN = ["str", "agi", "p_res", "m_res", "int"]
BASE_REV = "da64e9e"  # 10층 조정(2026-10-25) 전 main
SHAPE_EXP = 0.7
# 손으로 더 흔드는 몬스터(곡선 결과에 곱한다): 문지기는 근력·정신력이 둘 다 높아 평타·주문 모두 목표의 1.5배였다
# 수호자는 균열 파티 시뮬레이터(3층 곡선 파티 — sim_party --curve=3)로 맞춘 것: 타룬바스(빙하굴 — 저체온증이 겹친다)·일디움(자석·과열 패턴)은 같은 규칙이면 너무 셌다
TWEAK = {"riddle_gatekeeper": {"str": 0.75, "int": 0.75}, "tarunbas": {"str": 0.85, "p_res": 0.85}, "ildium": {"str": 0.85, "p_res": 0.8}}
BOSS_RANKS = {"midboss", "guardian", "variant_guardian", "lord", "elite"}
RANK_ROW = {r[0]: r for r in C.RANKS}


def target(m: dict) -> dict:
    """그 몬스터의 기준 {스탯…, hp, w}."""
    rank = m.get("rank", "normal")
    g = int(m.get("grade", 9))
    n = int(m.get("floor", 1))
    if rank == "elite":
        pl = C.GRADE_PL[g]
        base = C.normal_at(pl)
        out = {k: base[k] * 1.2 for k in MAIN + ["w", "atk"]}
        out["hp"] = RANK_ROW["elite"][3][1] * C.hit(C.explorer(max(1, min(10, round(pl))), "dps")["atk"], out["p_res"])
        return out
    if rank == "midboss":
        return C.boss(n + 1, RANK_ROW["midboss"])  # 균열(층+2 파티용) 안의 중간 보스
    if rank in RANK_ROW:
        return C.boss(n, RANK_ROW[rank])
    return C.normal_at(C.GRADE_PL[g])


def group(m: dict) -> str:
    rank = m.get("rank", "normal")
    return rank if rank in BOSS_RANKS else "g%s" % m.get("grade", 9)


def _set_in_block(text: str, block: str, key: str, value: int) -> str:
    """"block": { … "key": 값 … } 안의 값을 바꾼다(형식은 그대로)."""
    mb = re.search(r'"%s"\s*:\s*\{' % re.escape(block), text)
    if mb is None:
        return text
    depth, i = 0, mb.end() - 1
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                break
        i += 1
    inner = text[mb.end():i]
    new_inner, k = re.subn(r'("%s"\s*:\s*)-?[0-9.]+' % re.escape(key), r"\g<1>%d" % value, inner, count=1)
    return text[:mb.end()] + new_inner + text[i:] if k else text


def main() -> None:
    dry = "--dry" in sys.argv
    files = sorted(glob.glob(os.path.join(ROOT, "data", "monsters", "*.json")))
    mons = {}
    for f in files:
        if os.path.basename(f).startswith("_"):
            continue
        rel = os.path.relpath(f, ROOT)
        try:
            mons[f] = json.loads(subprocess.run(["git", "show", "%s:%s" % (BASE_REV, rel)], cwd=ROOT, capture_output=True, check=True, text=True).stdout)
        except subprocess.CalledProcessError:
            with open(f, encoding="utf-8") as fh:
                mons[f] = json.load(fh)
    avg = {}
    for m in mons.values():
        gk = group(m)
        a = avg.setdefault(gk, {"hp": [], "w": [], **{k: [] for k in MAIN}})
        for k in MAIN:
            a[k].append(max(0.0, float(m.get("stats", {}).get(k, 0))))
        a["hp"].append(float(m.get("resources", {}).get("hp", 0)))
        a["w"].append(float((m.get("natural_weapon") or {}).get("attack", 0)))
    avg = {k: {kk: sum(v) / max(1, len(v)) for kk, v in d.items()} for k, d in avg.items()}
    rows = []
    for f, m in mons.items():
        t = target(m)
        st = m.get("stats", {})
        a = avg[group(m)]
        tw = TWEAK.get(m["id"], {})
        new = {k: max(0, round(t[k] * tw.get(k, 1.0) * (max(0.0, float(st.get(k, 0))) / a[k]) ** SHAPE_EXP)) if a[k] > 0 else round(t[k]) for k in MAIN}
        hp_old = float(m.get("resources", {}).get("hp", 0))
        new["hp"] = max(1, round(t["hp"] * (hp_old / a["hp"] if a["hp"] > 0 else 1.0)))
        w_old = float((m.get("natural_weapon") or {}).get("attack", 0))
        new["w"] = max(1, round(t["w"] * (w_old / a["w"] if a["w"] > 0 else 1.0))) if w_old > 0 else 0
        rows.append((m.get("grade"), m.get("rank"), m["id"], {k: st.get(k) for k in MAIN}, hp_old, w_old, new))
        if dry:
            continue
        with open(f, encoding="utf-8") as fh:
            text = fh.read()
        for k in MAIN:
            if k in st:
                text = _set_in_block(text, "stats", k, new[k])
        text = _set_in_block(text, "resources", "hp", new["hp"])
        if w_old > 0:
            text = _set_in_block(text, "natural_weapon", "attack", new["w"])
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(text)
    rows.sort(key=lambda r: (-int(r[0] or 9), str(r[1]), r[2]))
    for g, rank, mid, old, hp, w, new in rows:
        print(f"{g} {rank:16} {mid:20} {old} hp {hp:.0f} w {w:.0f}  →  {[new[k] for k in MAIN]} hp {new['hp']} w {new['w']}")


if __name__ == "__main__":
    main()
