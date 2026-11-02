"""10층 밸런스 곡선(기획 — docs/plans/balance_10floors.md): 층마다 '기준 탐험가'를 세우고, 목표(몇 대에 쓰러지나 ·
한 대가 생명력 몇 %)에서 기준 몬스터·보스 수치를 거꾸로 푼다 → docs/balance/curve.md.
    python3 tools/balance_curve.py
게임 데이터는 읽지도 바꾸지도 않는다 — 맨 위 가정(층 표·정수·장비 배율·목표)을 고치고 다시 돌려 본다.
공식은 기획안의 새 공식이다(방어 = 공격력 비례, 아래 hit()). 지금 게임 공식과 다르다.
"""
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "balance", "curve.md")
OUT_JSON = os.path.join(ROOT, "docs", "balance", "curve.json")  # 층별 기준 탐험가(tools/sim_party.gd --curve=<층>이 읽는다)

# ── 가정: 층마다 (필드 등급, 그 층을 도는 레벨, 흡수한 정수 수, 장비 단계, 파티 인원)
FLOOR = {
    1: (9, 1, 1, 1, 1), 2: (8, 4, 3, 1, 2), 3: (7, 4, 4, 2, 5), 4: (7, 5, 5, 2, 5), 5: (6, 6, 6, 3, 5),
    6: (5, 7, 7, 3, 5), 7: (5, 7, 7, 4, 5), 8: (4, 8, 8, 4, 5), 9: (4, 9, 9, 5, 5), 10: (3, 10, 10, 6, 5),  # 필드 등급 = 그 층 잡몹(10층 = 3등급, 원작 묘사)
}
# 층마다 필드에 나오는 등급(사용자 2026-10-25 — 1·2등급이 자연재해인 건 중견 탐험가 기준, 9·10층에는 당연히 있다).
# 드문 등급은 그 층 파티에게 엘리트~중간 보스급 싸움(등급표 §4 기준값 그대로).
FIELD_MIX = {1: "9", 2: "8 · 7 드묾", 3: "7 · 6 드묾", 4: "7 · 6", 5: "6 · 5 드묾", 6: "5 · 4 드묾", 7: "5 · 4", 8: "4 · 3 드묾",
             9: "4 · 3 · 2 드묾", 10: "3 · 2 · 1 드묾"}
# 정수 한 개: 등급 → 주 스탯 합 · 생명력 · 이능 위력(평타 1.0 대비) · 영혼력 비용
ESS_SUM = {9: 12, 8: 18, 7: 27, 6: 38, 5: 52, 4: 70, 3: 95, 2: 130, 1: 180}
ESS_HP = {9: 11, 8: 16, 7: 24, 6: 34, 5: 48, 4: 68, 3: 95, 2: 130, 1: 180}
ESS_POWER = {9: "1.2~1.5", 8: "1.3~1.6", 7: "1.4~1.8", 6: "1.5~2.0", 5: "1.6~2.2", 4: "1.8~2.4", 3: "1.9~2.6", 2: "2.1~2.9", 1: "2.3~3.2"}
ESS_COST = {9: 5, 8: 6, 7: 8, 6: 11, 5: 14, 4: 18, 3: 24, 2: 30, 1: 40}
RAINBOW = 1.5  # 수호자 정수(무지갯빛) 배율 — 지금과 같다
# 장비 단계 배율: 무기 공격력(마력) · 증가 스탯. 감소 스탯은 지금처럼 고정
# 소재 장비는 범용(사용자 2026-10-25) — 10층에서도 힘의 약 4분의 1까지만, 그 위는 넘버스(균열 수호자 보상) 몫으로 비워 둔다
W_MULT = [1.0, 3.5, 7.5, 13, 20, 30]
GROW = [1.0, 2.2, 4.0, 6.5, 9.5, 13]
# 넘버스 = 균열 수호자에게서만(사용자 2026-10-25). 깊은 층 균열일수록 작은 번호. 수치는 사용자가 나중에 정한다(곡선에 넣지 않는다)
NUMBER_BAND = {1: "No.9999~7000", 2: "No.6999~4000", 3: "No.6999~4000", 4: "No.3999~1500", 5: "No.3999~1500",
               6: "No.1499~300", 7: "No.1499~300", 8: "No.299~1", 9: "No.299~1", 10: "No.299~1"}
# 생명력 = 50 + 레벨×10 + 물리내성×3 + 정수 생명력(지금 공식 그대로)
HP_BASE, HP_LV, HP_PRES = 50, 10, 3
# 목표: 일반 몬스터 = 딜러 평타 몇 대 · 한 대가 딜러 생명력의 몇 %
HITS = {1: 1.4, 2: 2.0, 3: 2.5, 4: 2.5, 5: 2.5, 6: 2.5, 7: 3, 8: 3, 9: 3, 10: 3}
TAKE = {1: .10, 2: .12, 3: .16, 4: .16, 5: .16, 6: .16, 7: .17, 8: .17, 9: .17, 10: .17}  # 1~2층은 혼자(회복 없음)라 낮게
SKILL_AVG = 1.3  # 파티가 한 바퀴에 쓰는 평균 위력(평타·이능 섞어서)
# 등급(rank): (몇 층 위 기준, 스탯 배율, 생명력 = 몇 바퀴 / 엘리트는 딜러 몇 대, 속도 배율, 이름)
# 배율·바퀴는 균열 파티 시뮬레이터로 맞췄다(sim_party --curve=<층>, 2026-10-25): 수호자 ×1.0·8바퀴 = 3층 파티가 예고에 방어하면 77~100%,
# 변이 수호자 ×0.85 = 회복·광폭 패턴 때문에 4층 파티 0% · 5층 파티 80~100%(사실상 4층 위 파티용).
# 계층군주 ×1.0·10바퀴 = 드레드피어(구더기·공포·페이즈)는 4층 파티 약 7% · 5층 파티 약 60~70% — 포션만 든 단순한 시뮬 파티 기준이다.
RANKS = [
    ("elite", 0, 1.1, ("hits", 10), 1.1, "엘리트"),
    ("midboss", 1, 1.0, ("rounds", 5), 1.15, "중간 보스"),
    ("guardian", 2, 1.0, ("rounds", 6.4), 1.25, "균열 수호자"),  # 8 → 6.4 = 생명력 −20%(사용자 2026-11-02 — 전투가 80~116차례로 길었다, docs/balance/rev_check.md)
    ("variant_guardian", 3, 0.85, ("rounds", 8), 1.3, "변이 수호자"),
    ("lord", 3, 1.0, ("rounds", 10), 1.4, "계층군주"),
]
OVER_STAT, OVER_ROUNDS = 1.2, 1.1  # 10층을 넘는 기준(깊은 층 보스)은 10층 기준에 넘친 층마다 곱한다
# 역할별 정수 스탯 나눔 · 1단계 장비의 물리내성/항마력 증가 합
SHARE = {"dps": {"str": .45, "agi": .25, "p_res": .2, "m_res": .05, "int": .05},
         "tank": {"str": .2, "agi": .1, "p_res": .5, "m_res": .15, "int": .05},
         "mage": {"str": .05, "agi": .2, "p_res": .15, "m_res": .15, "int": .45}}
BASE = {"str": 12, "agi": 10, "p_res": 8, "m_res": 6, "int": 8}
ARMOR = {"dps": (7, 1), "tank": (24, 1), "mage": (0, 5)}  # 딜러 가죽 갑옷·투구·장갑… / 탱커 판금·대방패… / 마법 로브·장신구
STATS = ["str", "agi", "p_res", "m_res", "int"]
STAT_KO = {"str": "근력", "agi": "민첩", "p_res": "물리내성", "m_res": "항마력", "int": "정신력"}
GRADE_PL = {9: 1, 8: 2, 7: 3.5, 6: 5, 5: 6.5, 4: 8.5, 3: 10, 2: 11.5, 1: 13}  # 등급 → 기준 층(2·1등급은 10층 너머 — 보스만)


def hit(a: float, d: float) -> float:
    """새 피해 공식(방어 = 공격력 비례): 공격력 × 공격력 / (공격력 + 방어 × 2)."""
    return a * a / (a + 2 * d)


def atk_for(target: float, d: float) -> float:
    return (target + math.sqrt(target * target + 8 * target * d)) / 2


def essences(f: int) -> tuple:
    g, _lv, n, _t, _p = FLOOR[f]
    gs = [min(9, g + (i % 2)) for i in range(n)]  # 반은 지금 층 등급, 반은 한 단계 아래
    s = sum(ESS_SUM[x] for x in gs)
    hp = sum(ESS_HP[x] for x in gs)
    if f >= 3 and gs:  # 앞 층 균열 수호자 정수 하나(무지갯빛)
        rg = max(1, FLOOR[f - 1][0] - 2)
        s += ESS_SUM[rg] * RAINBOW - ESS_SUM[gs[-1]]
        hp += ESS_HP[rg] * RAINBOW - ESS_HP[gs[-1]]
    return s, hp


def explorer(f: int, role: str) -> dict:
    _g, lv, _n, t, _p = FLOOR[f]
    s, ehp = essences(f)
    st = {k: BASE[k] + s * SHARE[role][k] for k in STATS}
    st["p_res"] += ARMOR[role][0] * GROW[t - 1]
    st["m_res"] += ARMOR[role][1] * GROW[t - 1]
    if role == "mage":
        st["int"] += 3 * GROW[t - 1]  # 지팡이 정신력
        atk = 10 * W_MULT[t - 1] + st["int"] * 2  # 지팡이 마력(새 키) + 정신력×2
    else:
        atk = 10 * W_MULT[t - 1] + st["str"] * 2  # 장검 공격력 10 기준
    st["hp"] = HP_BASE + lv * HP_LV + st["p_res"] * HP_PRES + ehp
    st["atk"] = atk
    return st


def normal(f: int) -> dict:
    d = explorer(f, "dps")
    pres = d["atk"] / 3  # 딜러 평타가 60% 들어간다
    a = atk_for(TAKE[f] * d["hp"], d["p_res"])
    return {"str": a * 0.35, "agi": d["agi"] * 0.9, "p_res": pres, "m_res": pres * 0.6, "int": a * 0.2,
            "hp": HITS[f] * hit(d["atk"], pres), "w": a * 0.3, "atk": a}


def normal_at(pl: float) -> dict:
    """기준 층이 소수·10 너머여도: 층 사이는 기하 보간, 10 너머는 9→10 비율로 늘린다."""
    if pl <= 10 and pl == int(pl):
        return normal(int(pl))
    lo = min(9, int(pl)) if pl > 10 else int(pl)
    a, b = normal(lo), normal(lo + 1)
    k = pl - lo
    return {key: a[key] * (b[key] / a[key]) ** k for key in a}


def party_round(f: int, pres: float, mres: float) -> float:
    """그 층 파티 한 바퀴 피해(5인 = 딜러 3 · 탱커 1 · 마법 1, 인원이 적으면 그만큼 줄인다)."""
    d, t, m = explorer(f, "dps"), explorer(f, "tank"), explorer(f, "mage")
    return SKILL_AVG * (3 * hit(d["atk"], pres) + hit(t["atk"], pres) + hit(m["atk"], mres)) * FLOOR[f][4] / 5


def boss(n: int, rank: tuple) -> dict:
    key, plus, mult, (kind, amount), spd, _ko = rank
    over = max(0, n + plus - 10)
    p = min(10, n + plus)
    b = normal(p)
    mult *= OVER_STAT ** over
    out = {k: b[k] * mult for k in ("str", "p_res", "m_res", "int", "atk", "w")}
    out["agi"] = b["agi"] * mult ** 0.5
    if kind == "hits":
        out["hp"] = amount * hit(explorer(p, "dps")["atk"], out["p_res"])
    else:
        out["hp"] = amount * OVER_ROUNDS ** over * party_round(p, out["p_res"], out["m_res"])
    t = explorer(p, "tank")
    out["vs_tank"] = hit(out["atk"], t["p_res"]) / t["hp"]
    out["pl"] = n + plus
    out["grade"] = max(1, FLOOR[p][0] - (1 if key in ("guardian", "variant_guardian", "lord") else 0) - over)
    return out


def speed(agi: float, rank_mult: float = 1.0) -> float:
    """새 CTB 속도 = (민첩 + 5)^0.75 × 등급 배율 — 민첩 3배여도 행동은 약 2.3배."""
    return (agi + 5) ** 0.75 * rank_mult


def r(x: float) -> str:
    if x >= 10000:
        return f"{round(x, -2):,.0f}"
    if x >= 1000:
        return f"{round(x, -1):,.0f}"
    return f"{x:,.0f}"


def build() -> str:
    L = []
    w = L.append
    w("# 10층 밸런스 곡선 (기획안 — 게임 데이터에는 아직 적용 안 함)\n")
    w("`python3 tools/balance_curve.py`가 만든다. 가정과 공식은 그 파일 맨 위, 기획 설명은 `docs/plans/balance_10floors.md`.")
    w("수치는 '이 층을 도는 기준 탐험가'에 맞춘 **기준값**이다 — 몬스터마다 성격(아래 §5)에 따라 ±30% 흔든다.\n")
    w("## 1. 층 개요\n")
    w("| 층 | 잡몹 등급(기준) | 나오는 등급 | 레벨 | 정수 | 장비 단계 | 파티 | 일반 몬스터 = 딜러 평타 | 한 대 = 딜러 생명력 |")
    w("|---|---|---|---|---|---|---|---|---|")
    for f, (g, lv, n, t, p) in FLOOR.items():
        w(f"| {f} | {g}등급 | {FIELD_MIX[f]} | {lv} | {n}개 | {t}단계 | {p}명 | {HITS[f]}대 | {TAKE[f] * 100:.0f}% |")
    w("\n- 드문 등급(한 단계 위)은 그 층 파티에게 엘리트~중간 보스급 싸움 — 수치는 §4 등급표 그대로. 1·2등급이 자연재해인 건 중견 탐험가 기준이고, 9·10층에는 필드에 있다.")
    w("\n## 2. 기준 탐험가 (그 층을 도는 평균 — 정수 반은 그 층 등급·반은 한 단계 아래, 3층부터 앞 층 수호자 정수 하나)\n")
    w("| 층 | 딜러 근력 · 민첩 · 물내 · 생명력 · 공격력 | 탱커 근력 · 물내 · 항마 · 생명력 | 마법 정신력 · 항마 · 생명력 · 마법 공격력 |")
    w("|---|---|---|---|")
    for f in FLOOR:
        d, t, m = explorer(f, "dps"), explorer(f, "tank"), explorer(f, "mage")
        w(f"| {f} | {r(d['str'])} · {r(d['agi'])} · {r(d['p_res'])} · {r(d['hp'])} · {r(d['atk'])} | {r(t['str'])} · {r(t['p_res'])} · {r(t['m_res'])} · {r(t['hp'])} | {r(m['int'])} · {r(m['m_res'])} · {r(m['hp'])} · {r(m['atk'])} |")
    w("\n## 3. 기준 일반 몬스터 (층마다)\n")
    w("| 층 | 등급 | 근력 | 민첩 | 물리내성 | 항마력 | 정신력 | 생명력 | 자연 무기 | 한 대 → 딜러 · 탱커 |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for f in FLOOR:
        m = normal(f)
        d, t = explorer(f, "dps"), explorer(f, "tank")
        w(f"| {f} | {FLOOR[f][0]} | {r(m['str'])} | {r(m['agi'])} | {r(m['p_res'])} | {r(m['m_res'])} | {r(m['int'])} | {r(m['hp'])} | {r(m['w'])} | {hit(m['atk'], d['p_res']) / d['hp'] * 100:.0f}% · {hit(m['atk'], t['p_res']) / t['hp'] * 100:.0f}% |")
    w("\n## 4. 등급표 (몬스터를 만들 때 — 등급의 기준 층에서 푼 일반 몬스터)\n")
    w("| 등급 | 기준 층 | 근력 | 민첩 | 물리내성 | 항마력 | 정신력 | 생명력 | 자연 무기 | 정수 스탯 합 · 생명력 |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    for g, pl in GRADE_PL.items():
        m = normal_at(pl)
        w(f"| {g} | {pl:g}{' (10층 너머)' if pl > 10 else ''} | {r(m['str'])} | {r(m['agi'])} | {r(m['p_res'])} | {r(m['m_res'])} | {r(m['int'])} | {r(m['hp'])} | {r(m['w'])} | {ESS_SUM[g]} · {ESS_HP[g]} |")
    w("\n## 5. 성격 배율 (같은 등급 안에서 흔들기 — 기준값에 곱한다)\n")
    w("| 성격 | 근력·정신력 | 민첩 | 물리내성 | 항마력 | 생명력 |")
    w("|---|---|---|---|---|---|")
    for row in (("힘(오우거·골렘 팔)", "×1.3", "×0.8", "×1.0", "×0.8", "×1.2"), ("날램(늑대·고블린 검사)", "×0.9", "×1.35", "×0.7", "×0.8", "×0.8"),
                ("단단함(골렘·갑각)", "×0.8", "×0.7", "×1.6", "×1.0", "×1.3"), ("주술(주술사·유령)", "정신력 주", "×1.0", "×0.6", "×1.6", "×0.8"),
                ("무리(구울·쥐 — 여럿이 나온다)", "×0.7", "×1.1", "×0.7", "×0.7", "×0.5")):
        w("| " + " | ".join(row) + " |")
    w("\n## 6. 보스·엘리트 (n층에 나오는 것 — 기준은 n+몇 층의 파티, 3층부터 5인)\n")
    w("10층을 넘는 기준(8~10층 보스)은 10층 파티를 상대로 넘친 층마다 스탯 ×{} · 바퀴 ×{}. 방어가 같이 올라 생명력 숫자는 비슷해도 더 오래·더 아프게 싸운다.\n".format(OVER_STAT, OVER_ROUNDS))
    for rank in RANKS:
        key, plus, mult, (kind, amount), spd, ko = rank
        unit = "딜러 평타 {}대".format(amount) if kind == "hits" else "그 층 파티 {}바퀴".format(amount)
        w(f"### {ko} — 기준 n+{plus}층 · 스탯 ×{mult} · 생명력 = {unit} · 속도 ×{spd}\n")
        w("| 나오는 층 | 기준 층 | 등급 | 근력 | 민첩 | 물리내성 | 항마력 | 생명력 | 평타 → 탱커 | 큰 기술(×2.5) → 탱커 |")
        w("|---|---|---|---|---|---|---|---|---|---|")
        for n in FLOOR:
            b = boss(n, rank)
            w(f"| {n} | {b['pl']} | {b['grade']} | {r(b['str'])} | {r(b['agi'])} | {r(b['p_res'])} | {r(b['m_res'])} | {r(b['hp'])} | {b['vs_tank'] * 100:.0f}% | {min(999, b['vs_tank'] * 250):.0f}% |")
        w("")
    w("## 7. 정수 (등급별 — 한 개)\n")
    w("| 등급 | 주 스탯 합 | 생명력 | 무지갯빛(수호자 ×1.5) | 이능 위력 | 영혼력 비용 |")
    w("|---|---|---|---|---|---|")
    for g in ESS_SUM:
        w(f"| {g} | {ESS_SUM[g]} | {ESS_HP[g]} | {ESS_SUM[g] * RAINBOW:.0f} · {ESS_HP[g] * RAINBOW:.0f} | {ESS_POWER[g]} | {ESS_COST[g]} |")
    w("\n## 8. 장비 단계\n")
    w("| 단계 | 쓰는 층 | 무기 배율 | 증가 스탯 배율 | 장검 공격력 | 대검 공격력 | 지팡이 마력 | 판금 물리내성 · 생명력 | 가죽 갑옷 물리내성 | 지금 배율(참고) |")
    w("|---|---|---|---|---|---|---|---|---|---|")
    old = [1.0, 1.6, 2.3, 3.1, 4.0, 5.0]
    where = {1: "1~2", 2: "3~4", 3: "5~6", 4: "7~8", 5: "9", 6: "10"}
    for t in range(1, 7):
        wm, gm = W_MULT[t - 1], GROW[t - 1]
        w(f"| {t} | {where[t]} | ×{wm:g} | ×{gm:g} | {r(10 * wm)} | {r(17 * wm)} | {r(10 * wm)} | {r(10 * gm)} · {r(10 * gm)} | {r(3 * gm)} | ×{old[t - 1]:g} |")
    d1, d10 = explorer(1, "dps"), explorer(10, "dps")
    w(f"\n- 소재 장비는 **범용** — 이 곡선(몬스터 수치)은 소재 장비만 든 탐험가를 기준으로 푼다. 넘버스는 기준에 넣지 않는다(수치는 사용자가 정한다 — 얻으면 그만큼 앞서간다).")
    w(f"- 소재 장비가 차지하는 몫(10층 딜러): 무기 {10 * W_MULT[5] / d10['atk'] * 100:.0f}% of 공격력, 방어구 {ARMOR['dps'][0] * GROW[5] / d10['p_res'] * 100:.0f}% of 물리내성 · 탱커 {ARMOR['tank'][0] * GROW[5] / explorer(10, 'tank')['p_res'] * 100:.0f}%.")
    m1 = normal(1)
    w(f"- 5단계(미스릴) 장검을 1층에서 들면: 공격력 {r(10 * W_MULT[4] + d1['str'] * 2)} → 1층 일반 몬스터(생명력 {r(m1['hp'])})에게 한 대 {r(hit(10 * W_MULT[4] + d1['str'] * 2, m1['p_res']))} — 무쌍.")
    w("\n## 8-2. 넘버스 — 균열 수호자에게서만, 수치는 사용자가 정한다\n")
    w("| 균열이 있는 층 | 번호대 |")
    w("|---|---|")
    for n in FLOOR:
        w(f"| {n} | {NUMBER_BAND[n]} |")
    w("\n## 9. 새 CTB 속도 (민첩 + 5)^0.75 × 등급 배율\n")
    w("| 상황 | 민첩 | 속도 | 상대 대비 행동 |")
    w("|---|---|---|---|")
    for label, a, b, mult in (("1층: 탐험가 10 vs 칼날늑대 18", 10, 18, 1.0), ("탐험가 민첩 2배", 100, 200, 1.0), ("탐험가 민첩 3배", 100, 300, 1.0),
                              ("10층 딜러 vs 일반 몬스터", normal(10)["agi"], explorer(10, "dps")["agi"], 1.0)):
        sa, sb = speed(a), speed(b, mult)
        w(f"| {label} | {a:.0f} → {b:.0f} | {sa:.1f} → {sb:.1f} | ×{sb / sa:.2f} (지금 공식 ×{(b + 5) / (a + 5):.2f}) |")
    for rank in RANKS:
        n = 4
        b = boss(n, rank)
        p = min(10, b["pl"])
        d = explorer(p, "dps")
        w(f"| {n}층 {rank[5]} vs {p}층 딜러 | {d['agi']:.0f} vs {b['agi']:.0f} | {speed(d['agi']):.1f} vs {speed(b['agi'], rank[4]):.1f} | 보스 ×{speed(b['agi'], rank[4]) / speed(d['agi']):.2f} |")
    return "\n".join(L) + "\n"


if __name__ == "__main__":
    text = build()
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(text)
    refs = {str(f): {"level": FLOOR[f][1], **{role: {k: round(v, 1) for k, v in explorer(f, role).items()} for role in ("dps", "tank", "mage")}} for f in FLOOR}
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(refs, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"→ {OUT}")
