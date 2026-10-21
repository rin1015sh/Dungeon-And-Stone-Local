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
  4) 우리 게임 몬스터 52종은 전부 지금 게임 값(사용자 결정 2026-10-21 "원래 표 내용 반영하지 말고 우리 게임 기준으로 전부"):
     등급·계급·정수 스탯·생명력·드랍율(지금 규칙)·패시브·스킬 이름·몬스터 전투 스탯. 원래 표 수치는 쓰지 않는다.
     위 1)~3) 변환은 우리 게임에 없는 표 몬스터 185종에만 쓴다(우리 데이터가 없다) — 드랍율도 지금 규칙(등급별)으로.
  "생명력" 칸 = 정수를 흡수하면 늘어나는 최대 생명력(정수 resources.hp — J13). 몬스터 자신의 생명력은 "몬스터 생명력" 칸.
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
MON_STATS = ["str", "agi", "p_res", "m_res", "int"]
STAT_KO = {"sight": "시각", "appetite": "식욕", "digestion": "소화력", "soul_regen": "영혼 재생력"}


def num(s: str) -> float:
    s = (s or "").strip()
    return float(s) if s else 0.0


def load(rel: str) -> dict:
    p = os.path.join(ROOT, rel)
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else {}


def mon_cols(m: dict) -> list:
    """우리 몬스터의 전투 스탯 칸(없으면 빈칸)."""
    if not m:
        return [""] * 9
    st = m.get("stats", {})
    res = m.get("resources", {})
    wp = m.get("natural_weapon") or {}
    return [m.get("grade", "")] + [st.get(k, "") for k in MON_STATS] + [res.get("hp", ""), res.get("soul", ""),
            ("%s %s" % (wp.get("attack", ""), wp.get("damage_type", ""))).strip()]


def current_rate(m: dict) -> str:
    """지금 게임의 정수 드랍율(EssenceDrop.drop_chance — 계급별 값이 있으면 그것, 없으면 등급별). 정수가 없으면 ""."""
    if not m or not load("data/essences/%s.json" % m["id"]):
        return "" if not m else "0%"
    ess = load("data/balance.json").get("essence", {})
    by_rank = ess.get("drop_chance_by_rank", {})
    rank = m.get("rank", "normal")
    p = by_rank[rank] if rank in by_rank else ess.get("drop_chance_by_grade", {}).get(str(m.get("grade", 9)), 0.0)
    return ("%g%%" % (p * 100))


def grade_rate(rank: str, grade: int) -> str:
    """지금 게임 규칙의 정수 드랍율(계급별 값이 있으면 그것, 없으면 등급별)."""
    ess = load("data/balance.json").get("essence", {})
    by_rank = ess.get("drop_chance_by_rank", {})
    p = by_rank[rank] if rank in by_rank else ess.get("drop_chance_by_grade", {}).get(str(grade), 0.0)
    return "%g%%" % (p * 100)


def essence_text(mid: str) -> str:
    """지금 정수의 스탯·생명력(글)."""
    e = load("data/essences/%s.json" % mid)
    if not e:
        return "정수 없음"
    parts = ["%s %s" % (OUR_NAMES.get(k, STAT_KO.get(k, k)), v) for k, v in e.get("stats", {}).items()]
    parts += ["생명력 %s" % v for k, v in e.get("resources", {}).items() if k == "hp"]
    return " · ".join(parts)


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
    head = (["출처", "등급", "이름", "우리 id", "계급", "정수드랍율(지금 규칙)"] + [OUR_NAMES[s] for s in OUR_STATS]
            + ["생명력(흡수 시 최대 생명력 +)", "스탯 합", "그 밖의 스탯", "passive", "active1", "active2", "active3", "active4"]
            + ["몬스터 근력", "몬스터 민첩", "몬스터 물리내성", "몬스터 항마력", "몬스터 정신력", "몬스터 생명력", "몬스터 영혼력", "몬스터 무기"])
    rows_out = []  # (등급, 순서, 행)
    # 우리 게임 몬스터 52종 = 전부 지금 게임 값(정수·드랍율·스킬 이름·전투 스탯) — 원래 표 수치는 쓰지 않는다(사용자 결정 2026-10-21)
    for m in mons.values():
        e = load("data/essences/%s.json" % m["id"])
        st = e.get("stats", {})
        g = m.get("grade")
        skills = [load("data/skills/%s.json" % a.get("skill", "")).get("name_ko", a.get("skill", "")) for a in e.get("actives", [])]
        rows_out.append((int(g or 0), 0, m["name_ko"], ["우리 게임", g if g is not None else "", m["name_ko"], m["id"], m.get("rank", "normal"),
                current_rate(m) or "0%"]
               + [st.get(k, "") for k in OUR_STATS]
               + [e.get("resources", {}).get("hp", "") if e else "", sum(v for k, v in st.items() if k in OUR_STATS) if e else "",
                  " · ".join("%s %s" % (STAT_KO[k], v) for k, v in st.items() if k in STAT_KO) if e else "정수 없음",
                  e.get("passive", {}).get("name_ko", ""), *(skills + ["", "", "", ""])[:4]]
               + mon_cols(m)[1:]))
    # 우리 게임에 없는 표 몬스터 = 우리 데이터가 없어 표 수치를 우리 스탯·규모로 바꾼 값(스킬은 원본 문장 — 번역은 나중)
    for c in conv:
        if c["mon"]:
            continue
        g = c["grade"]
        k = scale[g]
        vals = {s: int(round(v * k)) if v >= 0 else -int(round(-v * k)) for s, v in c["stats"].items()}
        hp = HP_BASE[g] * (min(1.5, max(0.75, 0.75 + 0.25 * c["dur"] / dur_mid[g])) if c["dur"] > 0 else 0.5)
        r = c["row"]
        rows_out.append((g, 1, r["이름"], ["표 변환", g, r["이름"], "", c["rank"], grade_rate(c["rank"], g)]
               + [vals[s] if vals[s] != 0 else "" for s in OUR_STATS]
               + [int(round(hp)), sum(vals.values()), ("버림: " + " · ".join(c["dropped"])) if c["dropped"] else "",
                  r.get("passive", ""), r.get("active1", ""), r.get("active2", ""), r.get("active3", ""), r.get("active4", "")]
               + [""] * 8))
    rows_out.sort(key=lambda t: (-t[0], t[1], t[2]))
    out = [t[3] for t in rows_out]
    with open(OUT, "w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(head)
        w.writerows(out)
    print("등급별 배율:", {g: round(v, 2) for g, v in scale.items()})
    print("행 %d개(우리 게임 %d + 표 변환 %d) → %s" % (len(out), len(mons), len(out) - len(mons), os.path.relpath(OUT, ROOT)))


if __name__ == "__main__":
    main()
