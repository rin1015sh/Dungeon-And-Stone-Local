"""정수 표(사용자 제공 CSV, 2026-10-21)를 우리 스탯 체계·규모로 바꾼다 — 스킬(passive·active)은 그대로 옮기고 나중에 따로 번역한다.

  python3 tools/essence_table_convert.py
    입력  docs/balance/source/essence_table_original.csv (원본 그대로)
    출력  docs/balance/essence_table_converted.csv     (우리 스탯 17종 + 생명력)

규칙(docs/balance/essence_table.md · ASSUMPTIONS J18):
  1) 스탯 이름 바꾸기 — 같은 스탯은 ×1, 지운 스탯은 가까운 주 스탯 ×0.5(ST2와 같은 규칙), 대응이 없는 것은 버린다.
  2) 규모 맞추기 — 등급마다 '바꾼 스탯 합의 가운데값'이 우리 정수의 등급별 합(TARGET_SUM)이 되도록 같은 배율을 곱한다.
     (그 등급 안의 강약 차이는 표 그대로 남는다 — 표의 수호자는 이미 같은 등급 일반보다 크므로 계급 배율을 따로 곱하지 않는다.)
     1~3등급은 표에 몇 줄뿐(1 · 1 · 3)이라 배율이 흔들린다 — 임시.
  3) 생명력 — 표의 내구력으로: 등급 기본값(HP_BASE) × (0.75 + 0.25 × 내구력 / 그 등급 내구력 가운데값), 0.75~1.5.
     내구력이 없으면 기본값 × 0.5(지금 우리 정수의 '몸이 약한 종' 규칙과 같다).
  반올림 후 0은 뺀다. 음수(표의 −10 등)는 그대로 줄여서 남긴다.
"""
import csv
import json
import os
import statistics

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs/balance/source/essence_table_original.csv")
OUT = os.path.join(ROOT, "docs/balance/essence_table_converted.csv")

# 표 스탯 → [(우리 스탯 id, 계수)]. 생명력(내구력)은 따로.
MAP = {
    "근력": [("str", 1.0)], "민첩": [("agi", 1.0)], "민첩성": [("agi", 1.0)],
    "물리내성": [("p_res", 1.0)], "항마력": [("m_res", 1.0)], "정신력": [("int", 1.0)],
    "골강도": [("p_res", 0.5)], "지구력": [("p_res", 0.5)],          # ST2: 물리내성 ← 골강도·지구력
    "투쟁심": [("m_res", 0.5)], "고통저항": [("m_res", 0.5)],        # ST2: 항마력 ← 투쟁심·고통내성
    "후각": [("int", 0.5)],                                          # ST2: 정신력 ← 후각
    "은신": [("agi", 0.5)],                                          # ST2: 민첩 ← 인식방해
    "감각": [("accuracy", 0.5)],                                     # 궁수·사수에 몰려 있다 — 명중률로
    "재생력": [("natural_regen", 1.0)],
    "화염감응": [("affinity_fire", 1.0)], "냉기감응": [("affinity_cold", 1.0)],
    "화염저항": [("resist_fire", 1.0)], "냉기저항": [("resist_cold", 1.0)],
    "독저항": [("resist_poison", 1.0)], "어둠저항": [("resist_dark", 1.0)],
}
DROP = ["영혼력", "행운", "수복력", "바람감응", "대지감응", "어둠감응", "번개저항", "바람저항", "물저항"]  # ST2·ST5에서 지운 것
OUR_STATS = ["str", "agi", "p_res", "m_res", "int", "accuracy", "natural_regen", "affinity_fire", "affinity_cold",
             "resist_fire", "resist_cold", "resist_poison", "resist_dark"]
OUR_NAMES = {"str": "근력", "agi": "민첩", "p_res": "물리내성", "m_res": "항마력", "int": "정신력", "accuracy": "명중률",
             "natural_regen": "자연재생력", "affinity_fire": "화염 감응도", "affinity_cold": "냉기 감응도",
             "resist_fire": "화염 내성", "resist_cold": "냉기 내성", "resist_poison": "독 내성", "resist_dark": "어둠 내성"}

# 우리 정수(2026-10-21, 일반 몬스터)의 등급별 스탯 합 가운데값: 9 = 13 · 8 = 19 · 7 = 25. 6등급부터는 ×1.3씩 늘린다.
TARGET_SUM = {9: 13, 8: 19, 7: 25, 6: 33, 5: 43, 4: 56, 3: 73, 2: 95, 1: 123}
# 생명력 기본값: 9 = 11 · 8 = 15 · 7 = 23 · 6 = 31 · 5 = 40(지금 정수), 그 위는 ×1.3.
HP_BASE = {9: 11, 8: 15, 7: 23, 6: 31, 5: 40, 4: 52, 3: 68, 2: 88, 1: 114}
# 계급(표에는 없다 — 우리 몬스터와 이름이 같으면 그 계급, 군주 셋은 lord). 표시만 하고 수치에는 곱하지 않는다.
LORD_NAMES = {"공포의 군주", "천공의 군주", "혼돈의 군주"}


def num(s: str) -> float:
    s = (s or "").strip()
    return float(s) if s else 0.0


def our_monsters() -> dict:
    out = {}
    d = os.path.join(ROOT, "data/monsters")
    for f in os.listdir(d):
        if f.endswith(".json") and not f.startswith("_"):
            m = json.load(open(os.path.join(d, f), encoding="utf-8"))
            out[m["name_ko"].replace(" ", "")] = m
    return out


def main() -> None:
    rows = list(csv.DictReader(open(SRC, encoding="utf-8-sig")))
    mons = our_monsters()
    conv = []
    for r in rows:
        g = int(r["등급"])
        st = {k: 0.0 for k in OUR_STATS}
        for col, targets in MAP.items():
            for sid, k in targets:
                st[sid] += num(r.get(col, "")) * k
        dropped = [f"{c} {r[c].strip()}" for c in DROP if (r.get(c) or "").strip()]
        m = mons.get(r["이름"].replace(" ", ""))
        rank = m.get("rank", "normal") if m else ("lord" if r["이름"] in LORD_NAMES else "normal")
        conv.append({"row": r, "grade": g, "stats": st, "dur": num(r.get("내구력", "")), "dropped": dropped, "mon": m, "rank": rank})
    # 등급별 배율 = 목표 합 / (그 등급 일반 몬스터의 바꾼 합 가운데값)
    scale = {}
    dur_mid = {}
    for g in TARGET_SUM:
        sums = [sum(c["stats"].values()) for c in conv if c["grade"] == g and c["rank"] == "normal" and sum(c["stats"].values()) > 0]
        if not sums:
            sums = [sum(c["stats"].values()) for c in conv if c["grade"] == g and sum(c["stats"].values()) > 0]
        scale[g] = TARGET_SUM[g] / statistics.median(sums) if sums else 1.0
        durs = [c["dur"] for c in conv if c["grade"] == g and c["dur"] > 0]
        dur_mid[g] = statistics.median(durs) if durs else 1.0
    head = ["등급", "이름", "우리 id", "계급", "정수드랍율"] + [OUR_NAMES[s] for s in OUR_STATS] + ["생명력", "스탯 합", "버린 스탯",
            "passive", "active1", "active2", "active3", "active4"]
    out = []
    for c in conv:
        g = c["grade"]
        k = scale[g]
        vals = {s: int(round(v * k)) if v >= 0 else -int(round(-v * k)) for s, v in c["stats"].items()}
        base = HP_BASE[g]
        hp = base * (min(1.5, max(0.75, 0.75 + 0.25 * c["dur"] / dur_mid[g])) if c["dur"] > 0 else 0.5)
        r = c["row"]
        out.append([g, r["이름"], c["mon"]["id"] if c["mon"] else "", c["rank"], r["정수드랍율"]]
                   + [vals[s] if vals[s] != 0 else "" for s in OUR_STATS]
                   + [int(round(hp)), sum(vals.values()), " · ".join(c["dropped"]),
                      r.get("passive", ""), r.get("active1", ""), r.get("active2", ""), r.get("active3", ""), r.get("active4", "")])
    with open(OUT, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(head)
        w.writerows(out)
    print("등급별 배율:", {g: round(v, 2) for g, v in scale.items()})
    print("행 %d개 → %s" % (len(out), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
