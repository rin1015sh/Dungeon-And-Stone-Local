"""밸런스 총정리 — 몬스터·보스·정수·상태이상·아이템·플레이어 기준을 한 파일에 모은다.
    python3 tools/balance_sheet.py
→ docs/balance/all_stats.md(읽기용) + all_stats.html(종류별 탭 화면 — 브라우저로 연다) + all_stats.xlsx(정렬·필터용, 같은 표를 시트마다).
--artifact=<경로>: Artifact 게시용 조각(문서 껍데기 없는 html)도 쓴다. 저장소의 all_stats.html은 바로 열 수 있는 완전한 문서.
쓰는 부분은 tools/balance_sheet_out.py, 화면 틀은 tools/balance_sheet_view.html.
데이터(data/*.json)가 정본이다 — 이 파일들은 손으로 고치지 않고, 데이터를 바꿨으면 다시 돌린다.
곡선 기준값은 tools/balance_curve.py, 장비 계산은 tools/item_pool.py(= ItemForge), 스킬 효과 글은 tools/essences_md.py를 그대로 쓴다.
"""
import glob
import json
import os
import re
import sys

sys.dont_write_bytecode = True  # tools/__pycache__는 저장소에 들어 있다 — 건드리지 않게
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import balance_curve as BC  # noqa: E402
import essences_md as EM  # noqa: E402
import item_pool as IP  # noqa: E402
import restat_monsters as RS  # noqa: E402
import balance_sheet_out as OUT  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAIN = ["str", "agi", "p_res", "m_res", "int"]
MAIN_KO = ["근력", "민첩", "물내", "항마", "정신"]


def load(path: str):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return json.load(f)


def load_dir(name: str) -> list:
    out = []
    for f in sorted(glob.glob(os.path.join(ROOT, "data", name, "*.json"))):
        if not os.path.basename(f).startswith("_"):
            out.append(load(os.path.relpath(f, ROOT)))
    return out


BAL = load("data/balance.json")
COMBAT = BAL["combat"]
PROG = load("data/progression.json")
CURVE = load("docs/balance/curve.json")
STAT_KO = dict(IP.STAT_KO)
STAT_KO.update({"dmg_dealt:all": "주는 피해", "dmg_taken:all": "받는 피해", "dmg_dealt:physical": "주는 물리 피해", "regen:hp": "생명력 재생",
                "regen:soul": "영혼력 재생", "dmg_taken:cold": "받는 냉기 피해", "dmg_taken:blunt": "받는 타격 피해", "magic": "마력"})
RANK_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["monster_ranks"]}
DTYPE_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["damage_types"]}
SLOT_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["equip_slots"]}
RARITY_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["rarities"]}
CAT_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["item_categories"]}
FAMILY_KO = {r["id"]: r["name_ko"] for r in load("data/tags.json")["families"]}
ROLE_KO = {"tank": "탱커", "melee": "근접", "ranged": "원거리", "mage": "마법"}
BOSS_RANKS = ["elite", "midboss", "guardian", "variant_guardian", "lord"]
RANK_ORDER = ["ungraded", "token", "human", "normal"] + BOSS_RANKS
CURVE_RANK = {r[0]: r for r in BC.RANKS}
FLAG_KO = {"skip_turn": "차례 거름", "may_skip_turn": "가끔 차례 거름", "no_skills": "스킬 못 씀", "no_flee": "도주 불가", "untargetable": "노릴 수 없음",
           "no_ally_single": "아군 단일 대상 불가", "no_regen": "재생 없음", "always_hit": "반드시 맞힘", "draws_attacks": "공격 끌어들임", "no_split": "분열 없음"}
REGION_TAG = {"f1_north": "1층 필드", "f1_east": "1층 필드", "f1_south": "1층 필드", "f1_west": "1층 필드", "f1_lord": "1층 계층군주", "f1_raiders": "1층 약탈자"}
for _rid, _r in EM.RIFTS:
    REGION_TAG["f1_" + _rid] = "균열 " + _r["name_ko"]
REGION_ORDER = ["1층 필드", "1층 약탈자", "1층 계층군주"] + ["균열 " + r["name_ko"] for _, r in EM.RIFTS] + ["기타"]


# ── 작은 도우미 ──────────────────────────────────────────────
class Table:
    def __init__(self, title: str, headers: list, rows: list, note: str = "", sheet: str = ""):
        self.title, self.headers, self.rows, self.note, self.sheet = title, headers, rows, note, sheet


def r0(x) -> int:
    return IP.rnd(float(x))


def avg(xs: list) -> float:
    return sum(xs) / len(xs) if xs else 0.0


def pct_of(v: float, ref: float) -> str:
    return "%d%%" % r0(100.0 * v / ref) if ref else "-"


def speed(agi: float, rank: str) -> float:
    return (agi + COMBAT["speed_base"]) ** COMBAT["speed_exp"] * COMBAT["rank_speed"].get(rank, 1.0)


def mon_atk(m: dict) -> float:
    return m["stats"]["str"] * COMBAT["phys_atk_per_str"] + m["natural_weapon"].get("attack", 0)


def hit(atk: float, defense: float) -> float:
    return atk * atk / (atk + defense * COMBAT["defense_ratio"]) if atk > 0 else 0.0


def mods_text(mods: list) -> str:
    out = []
    for md in mods or []:
        name = STAT_KO.get(md.get("target"), md.get("target"))
        if isinstance(md.get("percent", md.get("flat")), str):
            out.append("%s %s(%s)" % (name, "×" if "percent" in md else "+", EM.num(md.get("percent", md.get("flat")))))
        elif "percent" in md:
            out.append("%s %+d%%" % (name, r0(md["percent"] * 100)))
        elif "flat" in md:
            out.append("%s %+g" % (name, md["flat"]))
    return " · ".join(out)


def bal_expr(v) -> str:
    """'-{bal.status.bleed_per_turn}' → '-3' (balance.json 값으로 푼다)."""
    if not isinstance(v, str):
        return "%g" % v

    def sub(m):
        cur = BAL
        for k in m.group(1).split(".")[1:]:
            cur = cur[k]
        return "%g" % cur
    return EM.num(re.sub(r"\{(bal\.[\w.]+)\}", sub, v))


def stats_text(st: dict) -> str:
    return " · ".join("%s %+g" % (STAT_KO.get(k, k), v) for k, v in st.items())


def skill_cost(s: dict) -> str:
    parts = ["%s %s" % ("영혼" if k == "soul" else EM.RES.get(k, k), EM.num(v)) for k, v in s.get("cost", {}).items()]
    if s.get("cooldown"):
        parts.append("재사용 %s" % EM.num(s["cooldown"]))
    if s.get("uses_per_battle"):
        parts.append("전투당 %s번" % EM.num(s["uses_per_battle"]))
    return " · ".join(parts) or "-"


def effect_text(e: dict) -> str:
    t = e.get("type")
    if t == "flee":
        return "도주"
    if t == "split":
        return "분열(남은 생명력 반으로)"
    if t == "meter_damage":
        return "게이지(%s) × %g 피해(막을 수 없음)" % (e.get("meter", ""), e.get("mult", 1))
    return EM.effect(e).replace(" weapon", " 무기 유형")


def skill_effects(s: dict) -> str:
    return "; ".join(effect_text(e) for e in s.get("effects", [])) or "-"


SKILLS = {s["id"]: s for s in load_dir("skills")}
MONSTERS = load_dir("monsters")
MON_BY_ID = {m["id"]: m for m in MONSTERS}
ESSENCES = load_dir("essences")
STATUSES = load("data/statuses.json")
ITEMS = load_dir("items")


def region(m: dict) -> str:
    for t in m.get("floor_tags", []):
        if t in REGION_TAG:
            return REGION_TAG[t]
    return "기타"


def rank(m: dict) -> str:
    return m.get("rank") or "ungraded"


# ── 0. 공식 ─────────────────────────────────────────────────
def formulas() -> list:
    c, st, hp, soul = COMBAT, BAL["status"], BAL["hp"], BAL["soul"]
    return [
        "피해 = 공격력 × 위력 × 공격력/(공격력 + 방어×%g) × 상성·내성 × 피해 수정자 × 편차 ±%d%% (치명 ×%g, 최소 %d)" % (
            c["defense_ratio"], r0(c["damage_variance"] * 100), c["crit_mult"], c["min_damage"]),
        "물리 공격력 = 근력×%g + 무기 공격력(맨손 %d) · 마법 공격력 = 정신력×%g + 스킬 기본 + 마력 · 방어 = 물리내성(물리)/항마력(마법)" % (
            c["phys_atk_per_str"], c["unarmed_atk"], c["mag_atk_per_int"]),
        "명중 = (스킬 명중(기본 %d) + 명중률)%% × ((공격 민첩+%d)/(대상 민첩+%d))^%g, %d~%d%% · 치명 = %g + %g × 공격 민첩/(공격+대상 민첩)" % (
            c["default_accuracy"], c["agi_offset"], c["agi_offset"], c["hit_agi_exp"], r0(c["hit_min"] * 100), r0(c["hit_max"] * 100),
            c["crit_base"], c["crit_agi_share"]),
        "CTB 속도 = (민첩 + %g)^%g × 등급 배율(%s) · 게이지 %d에 행동 · 연속 최대 %d번" % (
            c["speed_base"], c["speed_exp"], " · ".join("%s ×%g" % (RANK_KO.get(k, k), v) for k, v in c["rank_speed"].items()),
            c["gauge_threshold"], c["max_streak"]),
        "광폭화: 보스 자기 차례 %s 뒤부터 차례마다 주는 피해 +%d%%(쌓임)" % (
            " · ".join("%s %d번째" % (RANK_KO[k], v) for k, v in c["enrage"]["after_turns"].items()), r0(c["enrage"]["per_turn"] * 100)),
        "도주 = %g + %g × (아군 평균 민첩 − 적 평균)/(합), %d~%d%% · 도주 불가: %s" % (
            c["flee_base"], c["flee_agi_share"], r0(c["flee_min"] * 100), r0(c["flee_max"] * 100), " · ".join(RANK_KO[k] for k in c["no_flee_ranks"])),
        "속성: 대상 내성 1점당 −%d%%(최대 %d%%) · 공격자 감응도 1점당 +%d%%" % (
            r0(c["element_resist_per_point"] * 100), r0(c["element_resist_max"] * 100), r0(c["affinity_per_point"] * 100)),
        "상태이상 저항(적이 건 것) = %g × 저항 스탯 / (저항 스탯 + 거는 쪽 근력·정신력 중 큰 값) — 같으면 %d%%" % (st["resist_max"], r0(st["resist_max"] * 50)),
        "주기 피해(차례마다): 출혈 %g · 중독 %g · 화상 %g · 부패 %g · 덫 %g · 아사 시간당 %g" % (
            st["bleed_per_turn"], st["poison_per_turn"], st["burn_per_turn"], st["rot_per_turn"], st["trap_damage"], BAL["hunger"]["starvation_hp_per_hour"]),
        "플레이어 최대 생명력 = %d + 레벨×%d + 물리내성×%g + 정수 생명력 · 최대 영혼력 = %d + %d레벨까지 레벨당 %d, 그 뒤 %d" % (
            hp["base"], hp["per_level"], hp["per_p_res"], soul["base"], soul["early_level_cap"], soul["per_level_early"], soul["per_level_late"]),
        "정수 드롭: 등급별 %s · 구분별 %s · 균열 ×%g · 수호자 정수 스탯·생명력 ×%g" % (
            " · ".join("%s등급 %g%%" % (k, v * 100) for k, v in BAL["essence"]["drop_chance_by_grade"].items()),
            " · ".join("%s %g%%" % (RANK_KO.get(k, k), v * 100) for k, v in BAL["essence"]["drop_chance_by_rank"].items()),
            BAL["essence"]["rift_mult"], BAL["essence"]["guardian_stat_mult"]),
        "몬스터 평타 피해(아래 표) = 공격력(근력×2 + 자연 무기) × 공격력/(공격력 + 상대 물리내성×2), 위력 1 · 편차·치명 빼고",
    ]


# ── 1. 플레이어 ─────────────────────────────────────────────
def player_tables() -> list:
    races = [[r["name_ko"], r["id"], "켬" if r.get("enabled") else "끔"] +
             ["%d~%d" % tuple(r["stat_ranges"].get(k, [0, 0])) for k in MAIN] +
             [sum(avg(r["stat_ranges"].get(k, [0, 0])) for k in MAIN)] for r in load("data/races.json")]
    classes = [[c["name_ko"], c["id"], ROLE_KO.get(c.get("role", ""), c.get("role", "")), "켬" if c.get("enabled") else "끔",
                " · ".join("%s +%d~%d" % (STAT_KO.get(k, k), v[0], v[1]) for k, v in c.get("stat_bonus_ranges", {}).items()),
                DTYPE_KO.get(c.get("attack_type", ""), ""), ", ".join(c.get("start_equipment", []))] for c in load("data/classes.json")]
    hp, soul, lv = BAL["hp"], BAL["soul"], PROG["level"]
    levels = []
    for n in range(lv["min"], lv["max"] + 1):
        s = soul["base"] + sum(soul["per_level_early"] if i <= soul["early_level_cap"] else soul["per_level_late"] for i in range(2, n + 1))
        levels.append([n, lv["exp_table"][n - 1], hp["base"] + hp["per_level"] * n, s, n * lv.get("essence_slots_per_level", 1)])
    refs = []
    for f in sorted(CURVE, key=int):
        d = CURVE[f]
        for role, ko in (("dps", "딜러"), ("tank", "탱커"), ("mage", "마법")):
            x = d[role]
            refs.append([int(f), d["level"], ko] + [r0(x[k]) for k in MAIN] + [r0(x["hp"]), r0(x["atk"])])
    return [
        Table("1-1. 종족 시작 스탯(굴림 범위)", ["종족", "id", "사용", *MAIN_KO, "평균 합"], races, sheet="종족"),
        Table("1-2. 직업", ["직업", "id", "역할", "사용", "스탯 보너스", "공격 유형", "시작 장비"], classes, sheet="직업"),
        Table("1-3. 레벨", ["레벨", "누적 경험치", "생명력(물내·정수 0)", "최대 영혼력", "정수 칸"], levels,
              note="실제 생명력 = 이 값 + 물리내성×%g + 정수 생명력. 경험치 = 종별 첫 처치 %d − 등급." % (hp["per_p_res"], PROG["exp"]["grade_base"]), sheet="레벨"),
        Table("1-4. 기준 탐험가(층별 — balance_curve.py 가정)", ["층", "레벨", "역할", *MAIN_KO, "생명력", "공격력"], refs,
              note="몬스터 표의 '한 대 %'·'몇 대'가 이 값을 쓴다. 실제 캐릭터가 아니라 그 층을 도는 평균을 가정한 값.", sheet="기준 탐험가"),
    ]


# ── 2. 몬스터 ───────────────────────────────────────────────
def curve_ref(m: dict) -> dict:
    """그 몬스터가 맞춰야 할 곡선 값 = restat_monsters.target(몬스터 수치를 매길 때 쓴 기준 그대로).
    pl = 그 기준을 푼 층(보스는 상대하는 파티의 층)."""
    ref = dict(RS.target(m))
    ref.setdefault("pl", BC.GRADE_PL.get(int(m["grade"]), 1))
    return ref


def ref_party(m: dict) -> dict:
    return CURVE[str(max(1, min(10, int(round(curve_ref(m)["pl"])))))]


def mon_row(m: dict) -> list:
    st, res, w = m["stats"], m["resources"], m["natural_weapon"]
    ref = curve_ref(m)
    main_ratio = avg([st[k] / ref[k] for k in MAIN if ref.get(k)])
    atk = mon_atk(m)
    f1 = CURVE["1"]
    fr = ref_party(m)
    dps1, tank1 = f1["dps"], f1["tank"]
    dpsr = fr["dps"]
    weak = " ".join("%s×%g" % (DTYPE_KO.get(k, k), v) for k, v in m.get("weaknesses", {}).items())
    immune = " ".join(DTYPE_KO.get(k, k) for k in m.get("immunities", []))
    sim = " ".join(EM.STATUS.get(k, k) for k in m.get("status_immune", []))
    return [m["name_ko"], m["id"], region(m), int(m["grade"]), RANK_KO.get(rank(m), rank(m))] + [st[k] for k in MAIN] + [
        sum(st[k] for k in MAIN), res.get("hp", 0), res.get("soul", 0), "%d %s%s" % (w.get("attack", 0), DTYPE_KO.get(w.get("damage_type"), ""), " 원거리" if w.get("ranged") else ""),
        r0(atk), round(speed(st["agi"], rank(m)), 1), weak, immune, sim,
        pct_of(res.get("hp", 0), ref["hp"]), "%d%%" % r0(main_ratio * 100),
        pct_of(hit(atk, dps1["p_res"]), dps1["hp"]), pct_of(hit(atk, tank1["p_res"]), tank1["hp"]),
        round(res.get("hp", 0) / max(1.0, hit(dpsr["atk"], st["p_res"])), 1),
        "%d" % m.get("magic_stone_grade", 0) if m.get("magic_stone_grade") else "-",
        "있음" if any(e["source_monster"] == m["id"] for e in ESSENCES) else "-",
        len(m.get("skills", [])), len(m.get("phases", [])) or "-"]


MON_HEAD = ["이름", "id", "지역", "등급", "구분", *MAIN_KO, "주스탯 합", "생명력", "영혼력", "자연 무기", "공격력", "CTB 속도", "약점", "피해 면역", "상태 면역",
            "곡선比 생명력", "곡선比 주스탯", "한 대→1층 딜러", "한 대→1층 탱커", "기준층 딜러 평타 몇 대", "마석", "정수", "스킬 수", "페이즈"]


def monster_tables() -> list:
    out = []
    # 2-1 등급 × 구분 평균
    groups = {}
    for m in MONSTERS:
        groups.setdefault((int(m["grade"]), rank(m)), []).append(m)
    rows = []
    for (g, rk) in sorted(groups, key=lambda k: (-k[0], RANK_ORDER.index(k[1]) if k[1] in RANK_ORDER else 99)):
        ms = groups[(g, rk)]
        a = {k: avg([m["stats"][k] for m in ms]) for k in MAIN}
        hps = [m["resources"].get("hp", 0) for m in ms]
        ws = avg([m["natural_weapon"].get("attack", 0) for m in ms])
        refs = [curve_ref(m) for m in ms]
        ref = {k: avg([x[k] for x in refs]) for k in MAIN + ["hp"]}
        rows.append([g, RANK_KO.get(rk, rk), len(ms)] + [r0(a[k]) for k in MAIN] + [r0(avg(hps)), "%d~%d" % (min(hps), max(hps)),
                    r0(avg([m["resources"].get("soul", 0) for m in ms])), r0(ws), r0(avg([speed(m["stats"]["agi"], rk) for m in ms]) * 10) / 10.0] +
                    [r0(ref[k]) for k in MAIN] + [r0(ref["hp"]), pct_of(avg(hps), ref["hp"]), "%d%%" % r0(100 * avg([a[k] / ref[k] for k in MAIN]))])
    out.append(Table("2-1. 등급 × 구분별 평균 스탯", ["등급", "구분", "수", *("평균 " + k for k in MAIN_KO), "평균 생명력", "생명력 범위", "평균 영혼력", "평균 무기",
                     "평균 속도", *("기준 " + k for k in MAIN_KO), "기준 생명력", "생명력 곡선比", "주스탯 곡선比"], rows,
                     note="기준 = 몬스터 수치를 매길 때 쓴 곡선 목표(`tools/restat_monsters.py` target — 일반 = curve.md §4 등급표, 정예 = 그 등급 ×1.2·딜러 평타 10대, 중간 보스 = 층+1 기준, 수호자·군주 = §6). 곡선比 100% = 계획대로. 몬스터마다 성격(늑대 = 빠름 등)으로 ±30% 흔든 것은 의도.", sheet="등급별 평균"))
    # 2-2 등급별(구분 무시 — 일반·사람·무등급만)
    rows = []
    for g in sorted({int(m["grade"]) for m in MONSTERS}, reverse=True):
        ms = [m for m in MONSTERS if int(m["grade"]) == g and rank(m) in ("normal", "human", "ungraded")]
        if not ms:
            continue
        ref = BC.normal_at(BC.GRADE_PL.get(g, 1))
        rows.append([g, len(ms)] + ["%d (%d~%d)" % (r0(avg([m["stats"][k] for m in ms])), min(m["stats"][k] for m in ms), max(m["stats"][k] for m in ms)) for k in MAIN] +
                    ["%d (%d~%d)" % (r0(avg([m["resources"]["hp"] for m in ms])), min(m["resources"]["hp"] for m in ms), max(m["resources"]["hp"] for m in ms)),
                     r0(avg([mon_atk(m) for m in ms])), r0(ref["hp"]), r0(ref["atk"])])
    out.append(Table("2-2. 등급별 잡몹(일반·사람·무등급) 평균 (최소~최대)", ["등급", "수", *MAIN_KO, "생명력", "평균 공격력", "기준 생명력", "기준 공격력"], rows, sheet="등급별 잡몹"))
    # 2-3 보스·정예
    rows = []
    for m in sorted([m for m in MONSTERS if rank(m) in BOSS_RANKS], key=lambda m: (BOSS_RANKS.index(rank(m)), -int(m["grade"]))):
        ref = curve_ref(m)
        phases = " / ".join("%s %d%%↑" % (p["id"], r0(p.get("hp_above", 0) * 100)) for p in m.get("phases", []))
        enr = COMBAT["enrage"]["after_turns"].get(rank(m), "-")
        tank = ref_party(m)["tank"]
        rows.append([m["name_ko"], m["id"], region(m), int(m["grade"]), RANK_KO[rank(m)]] + [m["stats"][k] for k in MAIN] +
                    [m["resources"]["hp"], m["resources"].get("soul", 0), m["natural_weapon"].get("attack", 0), r0(mon_atk(m)),
                     round(speed(m["stats"]["agi"], rank(m)), 1), enr, phases or "-", " ".join(EM.STATUS.get(k, k) for k in m.get("status_immune", [])) or "-",
                     " ".join("%s×%g" % (DTYPE_KO.get(k, k), v) for k, v in m.get("weaknesses", {}).items()) or "-",
                     "%g층" % ref["pl"], r0(ref["hp"]), pct_of(m["resources"]["hp"], ref["hp"]), "%d%%" % r0(100 * avg([m["stats"][k] / ref[k] for k in MAIN])),
                     pct_of(hit(mon_atk(m), CURVE["1"]["tank"]["p_res"]), CURVE["1"]["tank"]["hp"]), pct_of(hit(mon_atk(m), tank["p_res"]), tank["hp"]),
                     ", ".join(SKILLS[s]["name_ko"] if s in SKILLS else s for s in m.get("skills", []))])
    out.append(Table("2-3. 보스·정예 (정예 · 중간 보스 · 수호자 · 변종 수호자 · 계층군주)",
                     ["이름", "id", "지역", "등급", "구분", *MAIN_KO, "생명력", "영혼력", "무기", "공격력", "CTB 속도", "광폭화(차례)", "페이즈(생명력 경계)", "상태 면역", "약점",
                      "기준 파티 층", "기준 생명력", "생명력 곡선比", "주스탯 곡선比", "평타→1층 탱커", "평타→기준층 탱커", "스킬"], rows,
                     note="기준 파티 층 = 이 보스를 잡으라고 둔 파티의 층(curve.md §6 · restat_monsters). 1층 혼자 탐험가에게는 균열 보스·군주가 원래 버겁다(1층 파티 0%).", sheet="보스"))
    # 2-4 전체(지역별)
    for reg in REGION_ORDER:
        ms = [m for m in MONSTERS if region(m) == reg]
        if ms:
            ms.sort(key=lambda m: (-int(m["grade"]), RANK_ORDER.index(rank(m)) if rank(m) in RANK_ORDER else 99, m["id"]))
            out.append(Table("2-4. 몬스터 전체 — %s (%d종)" % (reg, len(ms)), MON_HEAD, [mon_row(m) for m in ms], sheet="몬스터"))
    # 2-5 스킬 · 2-6 패시브
    rows, prow = [], []
    for m in sorted(MONSTERS, key=lambda m: (REGION_ORDER.index(region(m)), -int(m["grade"]), m["id"])):
        for sid in m.get("skills", []):
            s = SKILLS.get(sid)
            if s:
                rows.append([m["name_ko"], s["name_ko"], sid, EM.NAME.get(("skill_targets", s.get("target")), s.get("target", "")), skill_cost(s), skill_effects(s)])
            else:
                rows.append([m["name_ko"], "(없는 스킬)", sid, "", "", ""])
        for p in m.get("passives", []):
            prow.append([m["name_ko"], p.get("name_ko", p.get("id")), p.get("desc_ko", "")])
    out.append(Table("2-5. 몬스터 스킬 전체", ["몬스터", "스킬", "id", "대상", "비용", "효과"], rows, note="위력 = 공격력에 곱하는 값(물리: 근력×2 + 무기).", sheet="몬스터 스킬"))
    out.append(Table("2-6. 몬스터 패시브", ["몬스터", "패시브", "설명"], prow, sheet="몬스터 패시브"))
    boss_names = {m["name_ko"] for m in MONSTERS if rank(m) in BOSS_RANKS}
    out.append(Table("2-7. 보스·정예 스킬", ["몬스터", "스킬", "id", "대상", "비용", "효과"], [r for r in rows if r[0] in boss_names],
                     note="2-5에서 보스·정예만 뽑은 것. 페이즈·패턴(예고 기술·게이지)은 BossHooks/patterns 코드에 있어 여기 다 나오지 않는다.", sheet="보스 스킬"))
    return out


# ── 3. 정수 ─────────────────────────────────────────────────
def essence_tables() -> list:
    def main_sum(e):
        return sum(v for k, v in e.get("stats", {}).items() if k in MAIN)
    rows = []
    for g in sorted({int(e["grade"]) for e in ESSENCES}, reverse=True):
        es = [e for e in ESSENCES if int(e["grade"]) == g]
        sums = [main_sum(e) for e in es]
        allsum = [sum(e.get("stats", {}).values()) for e in es]
        hps = [e.get("resources", {}).get("hp", 0) for e in es]
        rows.append([g, len(es), round(avg(sums), 1), "%g~%g" % (min(sums), max(sums)), BC.ESS_SUM.get(g, "-"), pct_of(avg(sums), BC.ESS_SUM.get(g, 0)),
                     round(avg(allsum), 1), round(avg(hps), 1), "%g~%g" % (min(hps), max(hps)), BC.ESS_HP.get(g, "-"), BC.ESS_POWER.get(g, "-"), BC.ESS_COST.get(g, "-")])
    t1 = Table("3-1. 등급별 정수 평균", ["등급", "수", "주스탯 합 평균", "범위", "기준 합", "곡선比", "전체 스탯 합(세부 포함)", "생명력 평균", "생명력 범위", "기준 생명력",
                                    "기준 이능 위력", "기준 영혼력 비용"], rows,
               note="기준 = balance_curve.py ESS_SUM·ESS_HP·ESS_POWER·ESS_COST. 수호자 정수(무지갯빛)는 표 값 ×%g로 얻는다." % BAL["essence"]["guardian_stat_mult"], sheet="정수 등급별")
    rows, srows = [], []
    for e in sorted(ESSENCES, key=lambda e: (EM.REGION_ORDER.index(EM.region(e["source_monster"])), -int(e["grade"]), e["id"])):
        g = int(e["grade"])
        src = MON_BY_ID.get(e["source_monster"], {})
        acts = e.get("actives", [])
        rows.append([e["name_ko"], e["id"], EM.region(e["source_monster"]), g, RANK_KO.get(rank(src), "") if src else ""] +
                    [e.get("stats", {}).get(k, 0) for k in MAIN] +
                    [main_sum(e), pct_of(main_sum(e), BC.ESS_SUM.get(g, 0)),
                     stats_text({k: v for k, v in e.get("stats", {}).items() if k not in MAIN}) or "-", e.get("resources", {}).get("hp", 0),
                     e.get("passive", {}).get("name_ko", "-"), e.get("passive", {}).get("desc_ko", ""),
                     " / ".join("%s:%s" % (EM.NAME.get(("essence_colors", a["color"]), a["color"]), re.sub(r"\(정수\)$", "", SKILLS.get(a["skill"], {}).get("name_ko", a["skill"]))) for a in acts)])
        for a in acts:
            s = SKILLS.get(a["skill"], {})
            srows.append([e["name_ko"], g, EM.NAME.get(("essence_colors", a["color"]), a["color"]), re.sub(r"\(정수\)$", "", s.get("name_ko", a["skill"])),
                          EM.NAME.get(("skill_targets", s.get("target")), s.get("target", "")), skill_cost(s), skill_effects(s)])
    t2 = Table("3-2. 정수 전체", ["정수", "id", "지역", "등급", "몬스터 구분", *MAIN_KO, "주스탯 합", "곡선比", "세부 스탯", "생명력", "패시브", "패시브 설명", "색:스킬"], rows, sheet="정수")
    t3 = Table("3-3. 정수 스킬 전체", ["정수", "등급", "색", "스킬", "대상", "비용", "효과"], srows,
               note="일반 정수는 색 하나로 떨어져 그 스킬 하나만 얻는다. 위력 하한은 tests/test_skill_value.gd(C15).", sheet="정수 스킬")
    return [t1, t2, t3]


# ── 4. 상태이상 ─────────────────────────────────────────────
def status_tables() -> list:
    users = {}
    blobs = [("스킬", s) for s in SKILLS.values()] + [("몬스터", m) for m in MONSTERS] + [("정수", e) for e in ESSENCES] + [("아이템", i) for i in ITEMS]
    for kind, obj in blobs:
        text = json.dumps(obj, ensure_ascii=False)
        found = set()
        for one, many in re.findall(r'"(?:status|statuses|self_statuses|foe_statuses|veil_status|groggy_status|extra_status)"\s*:\s*(?:"(\w+)"|\[([^\]]*)\])', text):
            found.update([one] if one else re.findall(r'"(\w+)"', many))
        for sid in found:
            users.setdefault(sid, {}).setdefault(kind, 0)
            users[sid][kind] += 1
    rows = []
    for s in STATUSES:
        d = s.get("duration")
        dur = "%g%s" % (d["amount"], "차례" if d["unit"] == "turn" else "시간") if d else "계속"
        stack = ("최대 %d" % s["max_stacks"] if s.get("max_stacks") else "쌓임") if s.get("stackable") else "-"
        per = " · ".join("%s %s%s/%s" % (EM.RES.get(p["resource"], p["resource"]), bal_expr(p["amount"]),
                                          "(%s)" % DTYPE_KO.get(p["damage_type"], "") if p.get("damage_type") else "", "차례" if p["trigger"] == "turn" else "시간")
                         for p in s.get("periodic", []))
        extra = [FLAG_KO.get(f, f) for f in s.get("flags", []) if not (f == "may_skip_turn" and s.get("skip_chance"))]
        if s.get("skip_chance"):
            extra.append("차례 거름 %d%%" % r0(s["skip_chance"] * 100))
        if s.get("heal_mult"):
            extra.append("회복 ×%g" % s["heal_mult"])
        if s.get("misdirect"):
            extra.append("엉뚱한 대상 %d%%(위력 ×%g%s)" % (r0(s["misdirect"]["chance"] * 100), s["misdirect"].get("power_mult", 1), ", 방어 무시" if s["misdirect"].get("ignore_defense") else ""))
        if s.get("lifesteal"):
            extra.append("흡혈 %d%%" % r0(s["lifesteal"] * 100))
        if s.get("crit_bonus"):
            extra.append("치명 +%s" % EM.pct(s["crit_bonus"]) if isinstance(s["crit_bonus"], (int, float)) else "치명 보너스")
        if s.get("hit_taken"):
            extra.append("받는 명중 +%d" % s["hit_taken"])
        if s.get("crit_taken"):
            extra.append("받는 치명 +%d%%" % r0(s["crit_taken"] * 100))
        if s.get("counter"):
            extra.append("반격 위력 %g" % s["counter"]["power"])
        if s.get("on_max_stacks"):
            extra.append("최대 중첩 → %s" % EM.STATUS.get(s["on_max_stacks"]["status"], s["on_max_stacks"]["status"]))
        if s.get("immune_if"):
            extra.append("%s %d 이상 면역" % (STAT_KO.get(s["immune_if"]["stat"]), s["immune_if"]["at_least"]))
        if s.get("on_act"):
            extra.append("행동할 때 %s %+g" % (EM.RES.get(s["on_act"]["resource"]), s["on_act"]["amount"]))
        if s.get("break_on_damage"):
            extra.append("맞으면 풀림")
        if s.get("consume_on_attack"):
            extra.append("공격하면 사라짐")
        if s.get("after_immune"):
            extra.append("풀린 뒤 %d차례 면역" % s["after_immune"])
        if s.get("on_hit"):
            extra.append("적중 시 " + "; ".join(EM.effect(x) for x in s["on_hit"]))
        if s.get("barrier"):
            extra.append("보호막")
        if s.get("flee_bonus"):
            extra.append("도주 보너스")
        if s.get("mental"):
            extra.append("정신계")
        resist = "/".join(STAT_KO.get(x, x) for x in s.get("resist", {}).get("stats", [])) or "-"
        u = users.get(s["id"], {})
        rows.append([s["name_ko"], s["id"], {"debuff": "해로움", "buff": "이로움"}.get(s.get("kind"), s.get("kind", "")), dur, stack, per or "-",
                     mods_text(s.get("modifiers", [])) or "-", " · ".join(extra) or "-", resist, "전투만" if s.get("battle_only") else "",
                     "남음" if s.get("lingers") else "", " · ".join("%s %d" % (k, v) for k, v in u.items()) or "-", s.get("source", "")])
    return [Table("4. 상태이상 전체 (%d종)" % len(STATUSES), ["이름", "id", "종류", "지속", "중첩", "주기 피해", "스탯 변화", "특수", "저항 스탯", "전투 한정", "전투 뒤 남음", "쓰는 곳(파일 수)", "출처"],
                  rows, note="저항 스탯이 있는 상태만 걸릴 때 저항 굴림(공식은 §0). '남음' = 전투가 끝나도 탐험 중 %g시간을 한 차례로 흐른다." % BAL["status"]["linger_hours_per_turn"], sheet="상태이상")]


# ── 5. 아이템 ───────────────────────────────────────────────
def use_fx(e: dict) -> str:
    t = e.get("type")
    if t == "restore_resource":
        return "%s %s" % (EM.RES.get(e.get("resource"), e.get("resource")), EM.num(e.get("amount", 0)) if isinstance(e.get("amount"), str) else "%+g" % e.get("amount", 0))
    if t in ("apply_status", "remove_status", "light_source"):
        return IP._fx(e)
    if t == "fatigue":
        return "피로 %+g" % e["amount"]
    if t == "permanent_stat":
        return "%s 영구 %+g(최대 %d번)" % (STAT_KO.get(e["stat"], e["stat"]), e["amount"], e.get("max_times", 1))
    if t == "smite":
        out = "%s %s %g" % ("하나" if e.get("single") else "전체", DTYPE_KO.get(e.get("damage_type"), "고정") if e.get("damage_type") else "고정", e["amount"])
        out += "(%s)" % "·".join(FAMILY_KO.get(f, f) for f in e.get("families", []))
        if e.get("status"):
            out += " + %s" % EM.STATUS.get(e["status"], e["status"])
        if e.get("heal"):
            out += " · 회복 %g" % e["heal"]
        return out
    return EM.effect(e)


def item_tables() -> list:
    out = []
    t = [["공격력 배율"] + ["×%g" % IP.ATK[i] for i in range(1, 7)], ["증가 스탯 배율"] + ["×%g" % IP.GROW[i] for i in range(1, 7)],
         ["가격 배율"] + ["×%s" % IP.won(IP.PRICE[i]) for i in range(1, 7)], ["희귀도"] + list(IP.CFG["rarity_by_tier"]), ["구하는 곳"] + [IP.WHERE[i] for i in range(1, 7)]]
    out.append(Table("5-1. 장비 단계 배율", ["값", "1단계", "2단계", "3단계", "4단계", "5단계", "6단계"], t,
                     note="장비 수치 = 종류 기본값 × 단계 배율 × 소재 특성(ItemForge). 장비는 스탯을 깎지 않는다(IT13). 자세한 공식 = `docs/balance/item_pool.md`.", sheet="장비 배율"))
    built = [IP.build(ty, m) for ty in IP.TYPES for m in IP.MATERIALS if m["kind"] in ty["kinds"]]
    weapons = [ty for ty in IP.TYPES if ty["weapon"]]
    # 무기 단계별 공격력 피벗
    piv = []
    for ty in weapons:
        cells = []
        for tier in range(1, 7):
            xs = [b.get("atk", 0) for b in built if b["type"] is ty and b["mat"]["tier"] == tier]
            cells.append("/".join(str(x) for x in sorted(set(xs))) if xs else "-")
        w = ty["weapon"]
        piv.append([ty["name"], DTYPE_KO.get(w["type"], w["type"]) + (" 양손" if w.get("two_handed") else "") + (" 원거리" if w.get("ranged") else ""), *cells])
    out.append(Table("5-2. 무기 공격력 — 종류 × 단계 (소재가 둘이면 /)", ["종류", "피해", "1단계", "2단계", "3단계", "4단계", "5단계", "6단계"], piv, sheet="무기 단계"))
    # 방어구 단계별 물리내성 합
    piv = []
    for ty in [x for x in IP.TYPES if not x["weapon"]]:
        cells = []
        for tier in range(1, 7):
            xs = [IP.fmt_stats(b["stats"], b["pct"]) for b in built if b["type"] is ty and b["mat"]["tier"] == tier]
            cells.append(" / ".join(dict.fromkeys(xs)) if xs else "-")
        piv.append([ty["name"], SLOT_KO.get(ty["slot"], ty["slot"]), *cells])
    out.append(Table("5-3. 방어구·장신구 스탯 — 종류 × 단계", ["종류", "칸", "1단계", "2단계", "3단계", "4단계", "5단계", "6단계"], piv, sheet="방어구 단계"))
    rows = [[b["name"], b["id"], b["type"]["name"], SLOT_KO.get(b["type"]["slot"], b["type"]["slot"]), b["mat"]["name"], b["mat"]["tier"], b.get("atk", ""),
             IP.fmt_stats(b["stats"], b["pct"]), b["buy"], b["sell"]] for b in built]
    out.append(Table("5-4. 장비 전체 (종류 × 소재 %d개)" % len(rows), ["이름", "id", "종류", "칸", "소재", "단계", "공격력", "스탯", "구입가", "판매가"], rows, sheet="장비 전체"))
    hand = []
    for it in ITEMS:
        eq = it.get("equip")
        if eq and "forge" not in it:
            w = eq.get("weapon", {})
            hand.append([it["name_ko"], it["id"], SLOT_KO.get(eq.get("slot", ""), eq.get("slot", "")), RARITY_KO.get(it.get("rarity", ""), it.get("rarity", "")), "%s %s" % (w.get("attack", ""), DTYPE_KO.get(w.get("damage_type"), "")) if w else "-",
                         mods_text(eq.get("modifiers", [])) or "-", it.get("price", 0)])
    out.append(Table("5-5. 공식 밖 장비(손으로 쓴 수치 — 계층보구·넘버스·장신구)", ["이름", "id", "칸", "희귀도", "무기", "스탯", "값"], hand, sheet="공식 밖 장비"))
    cons, misc = [], []
    for it in sorted(ITEMS, key=lambda x: (x.get("category", ""), x.get("price", 0))):
        if it.get("equip") or "forge" in it:
            continue
        if it.get("use_effects"):
            cons.append([it["name_ko"], it["id"], CAT_KO.get(it.get("category", ""), it.get("category", "")), " · ".join(use_fx(e) for e in it["use_effects"]), "O" if it.get("combat_usable") else "",
                         it.get("stack", 1), it.get("price", 0), r0(it.get("price", 0) * IP.SELL_RATIO)])
        else:
            misc.append([it["name_ko"], it["id"], CAT_KO.get(it.get("category", ""), it.get("category", "")), RARITY_KO.get(it.get("rarity", ""), it.get("rarity", "")), it.get("stack", 1), it.get("price", 0),
                         "반출 불가" if it.get("rift_bound") else ""])
    out.append(Table("5-6. 쓰는 아이템(포션·음식·빛·도구)", ["이름", "id", "분류", "효과", "전투 중", "겹침", "구입가", "판매가"], cons, sheet="쓰는 아이템"))
    out.append(Table("5-7. 그 밖의 아이템(재료·마석·잡동사니·히든 피스)", ["이름", "id", "분류", "희귀도", "겹침", "값", "비고"], misc, sheet="그 밖의 아이템"))
    return out


# ── 6. 자동 점검 ────────────────────────────────────────────
def checks() -> list:
    lines = []
    for m in MONSTERS:
        if rank(m) == "token":
            continue
        ref = curve_ref(m)
        hp_r = m["resources"]["hp"] / ref["hp"]
        st_r = avg([m["stats"][k] / ref[k] for k in MAIN])
        if not (0.6 <= hp_r <= 1.4) or not (0.7 <= st_r <= 1.3):
            lines.append("몬스터 **%s**(%s등급 %s): 생명력 곡선比 %d%% · 주스탯 %d%%" % (m["name_ko"], m["grade"], RANK_KO.get(rank(m)), r0(hp_r * 100), r0(st_r * 100)))
    for e in ESSENCES:
        g = int(e["grade"])
        s = sum(v for k, v in e.get("stats", {}).items() if k in MAIN)
        hp = e.get("resources", {}).get("hp", 0)
        if g in BC.ESS_SUM and not (0.75 <= s / BC.ESS_SUM[g] <= 1.25):
            lines.append("정수 **%s**(%d등급): 주스탯 합 %g — 기준 %d의 %d%% (세부 스탯까지 합 %g)" % (
                e["name_ko"], g, s, BC.ESS_SUM[g], r0(100 * s / BC.ESS_SUM[g]), sum(e.get("stats", {}).values())))
        if g in BC.ESS_HP and hp and not (0.75 <= hp / BC.ESS_HP[g] <= 1.25):
            lines.append("정수 **%s**(%d등급): 생명력 %g — 기준 %d" % (e["name_ko"], g, hp, BC.ESS_HP[g]))
    for m in MONSTERS:
        for sid in m.get("skills", []):
            if sid not in SKILLS:
                lines.append("몬스터 **%s**: 없는 스킬 `%s`" % (m["name_ko"], sid))
    return lines or ["눈에 띄게 어긋난 것 없음."]


def main() -> None:
    sections = [("1. 플레이어 기준", player_tables()), ("2. 몬스터", monster_tables()), ("3. 정수", essence_tables()),
                ("4. 상태이상", status_tables()), ("5. 아이템", item_tables())]
    chk = checks()
    OUT.write_md(sections, formulas(), chk)
    ok = OUT.write_xlsx(sections, formulas(), chk)
    frag = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--artifact=")), "")
    OUT.write_html(sections, formulas(), chk, frag)
    n = sum(len(t.rows) for _h, ts in sections for t in ts)
    print("all_stats.md + .html%s: 표 %d개 · %d줄 · 점검 %d건 (몬스터 %d · 정수 %d · 상태 %d · 스킬 %d · 아이템 %d)" % (
        " + .xlsx" if ok else "", sum(len(ts) for _h, ts in sections), n, len(chk), len(MONSTERS), len(ESSENCES), len(STATUSES), len(SKILLS), len(ITEMS)))


if __name__ == "__main__":
    main()
