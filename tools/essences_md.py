"""정수 표를 데이터에서 만든다 — data/essences/*.json + 정수판 스킬 data/skills/ess_*.json → docs/balance/essences.md.
    python3 tools/essences_md.py
정수·정수 스킬을 바꿨으면 다시 돌린다(손으로 고치지 않는다 — 데이터가 정본).
"""
import glob
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "balance", "essences.md")


def load(path: str):
    with open(os.path.join(ROOT, path), encoding="utf-8") as f:
        return json.load(f)


TAGS = load("data/tags.json")
NAME = {}
for key in ("damage_types", "essence_colors", "skill_targets", "monster_ranks"):
    for row in TAGS[key]:
        NAME[(key, row["id"])] = row["name_ko"]
STAT = {s["id"]: s["name_ko"] for s in load("data/stats.json")}
STATUS = {s["id"]: s["name_ko"] for s in load("data/statuses.json")}
RES = {r["id"]: r["name_ko"] for r in load("data/resources.json")}
MAIN = ["str", "agi", "p_res", "m_res", "int"]
RIFTS = [(r, load("data/rifts/%s.json" % r)) for r in ("rift_blood_fortress", "rift_glacier_cave", "rift_green_mine", "rift_iron_tomb")]
REGION_ORDER = ["1층 필드"] + [r[1]["name_ko"] for r in RIFTS] + ["계층정수"]


def num(v) -> str:
    if isinstance(v, str):  # 수식 — "floor({max_hp} * 0.25)" → "최대 생명력 × 0.25"
        v = re.sub(r"floor\((.*)\)", r"\1", v).replace("*", "×")
        return re.sub(r"\{(\w+)\}", lambda m: "최대 생명력" if m.group(1) == "max_hp" else STAT.get(m.group(1), m.group(1)), v)
    return ("%g" % round(float(v), 3)) if isinstance(v, (int, float)) else str(v)


def pct(v) -> str:
    return "%g%%" % round(float(v) * 100, 1)


def statuses(v) -> str:
    return "/".join(STATUS.get(s, s) for s in (v if isinstance(v, list) else [v]))


def damage(e: dict) -> str:
    kind = "마법" if e.get("scaling") == "magic" else "물리"
    out = "%s 위력 %s %s" % (kind, num(e.get("power", 1.0)), NAME.get(("damage_types", e.get("damage_type", "")), e.get("damage_type", "")))
    if e.get("base"):
        out += " · 기본 %s" % num(e["base"])
    if "accuracy" in e:
        out += " · 명중 %s" % num(e["accuracy"])
    if e.get("crit_bonus"):
        out += " · 치명 +%s" % pct(e["crit_bonus"])
    if e.get("defense_ignore"):
        out += " · 방어 %s 무시" % pct(e["defense_ignore"])
    if e.get("drain"):
        out += " · 흡수 %s" % pct(e["drain"])
    if e.get("ranged"):
        out += " (원거리)"
    if "power_if_hp_below" in e:
        p = e["power_if_hp_below"]
        out += " · 생명력 %s 이하면 ×%s" % (pct(p["ratio"]), num(p.get("mult", p.get("power", 1))))
    if "power_if_status" in e:
        p = e["power_if_status"]
        out += " · %s면 위력 %s" % (statuses(p["status"]), num(p["power"]))
    if "power_per_summon" in e:
        out += " · 소환수마다 +%s" % num(e["power_per_summon"])
    if "rider" in e:
        r = e["rider"]
        dt = NAME.get(("damage_types", r["damage_type"]), r["damage_type"])
        out += " · %s 추가 %s" % (dt, pct(r["ratio"]) if "ratio" in r else num(r.get("flat")))
    return out


def effect(e: dict) -> str:
    t = e.get("type")
    if t == "damage":
        return damage(e)
    if t == "apply_status":
        out = "%s %s" % ("자신에게" if e.get("to") == "self" else "", STATUS.get(e["status"], e["status"]))
        if "chance" in e:
            out += " %s" % pct(e["chance"])
        if "duration" in e:
            out += " %s차례" % num(e["duration"])
        if "if_target_status" in e:
            out += "(%s면)" % statuses(e["if_target_status"])
        if "unless_target_status" in e:
            out += "(%s 아니면)" % statuses(e["unless_target_status"])
        return out.strip()
    if t == "delayed":
        return "%s차례 뒤 %s" % (num(e.get("rounds", 1)), "; ".join(effect(x) for x in e.get("effects", [])))
    if t == "summon":
        ids = [e["monster"]] if "monster" in e else e.get("pick", [])
        return "소환 %s" % "/".join(load("data/monsters/%s.json" % m)["name_ko"] for m in ids)
    if t == "consume_status":
        return "%s 터뜨리기(중첩마다 위력 +%s)" % (STATUS.get(e["status"], e["status"]), num(e.get("power_per_stack", 0)))
    if t == "restore_resource":
        return "%s 회복 %s" % (RES.get(e["resource"], e["resource"]), num(e["amount"]))
    if t == "remove_status":
        return "해로운 상태 %s개 풀기" % num(e.get("count", 1)) if e.get("kind") == "debuff" else "%s 풀기" % statuses(e.get("status", ""))
    if t == "gauge":
        return "%s 게이지 %+d" % ("자신" if e.get("to") == "self" else "대상", int(e["amount"]))
    if t == "push_back":
        return "게이지 −%s" % num(e["amount"])
    if t == "cover":
        return "감싸기 %s차례" % num(e["duration"])
    if t == "barrier":
        return "보호막 %s" % num(e["amount"])
    if t == "soul_slash":
        return "영혼력 %s 베기(%s면 ×%s)" % (pct(e["soul_ratio"]), statuses(e["mult_if_status"]["status"]), num(e["mult_if_status"]["mult"]))
    if t == "seal_skill":
        return "스킬 봉인 %s차례" % num(e["rounds"])
    if t == "absorb_ally":
        return "동료 흡수(생명력 %s)" % pct(e["heal_ratio"])
    if t == "shuffle_rows":
        return "대열 섞기"
    return t


def skill_row(color: str, sid: str) -> str:
    s = load("data/skills/%s.json" % sid)
    parts = ["%s %s" % ("영혼" if k == "soul" else RES.get(k, k), num(v)) for k, v in s.get("cost", {}).items()]
    if s.get("cooldown"):
        parts.append("재사용 %s" % num(s["cooldown"]))
    if s.get("uses_per_battle"):
        parts.append("전투당 %s번" % num(s["uses_per_battle"]))
    cost = " · ".join(parts) or "-"
    eff = "; ".join(effect(e) for e in s.get("effects", []))
    if s.get("field_stealth"):
        eff += "; 탐험 은신"
    name = re.sub(r"\(정수\)$", "", s["name_ko"])
    return "| %s | %s | %s | %s | %s |" % (NAME.get(("essence_colors", color), color), name, NAME.get(("skill_targets", s.get("target")), s.get("target")), cost, eff)


FIELD = json.dumps([load("data/floors/" + f) for f in os.listdir(os.path.join(ROOT, "data", "floors")) if f.endswith(".json") and not f.startswith("_")])


def region(monster: str) -> str:
    if load("data/monsters/%s.json" % monster).get("rank") == "lord":
        return "계층정수"
    if re.search(r'"%s"' % re.escape(monster), FIELD):
        return "1층 필드"
    for _, r in RIFTS:
        if re.search(r'"%s"' % re.escape(monster), json.dumps(r)):
            return r["name_ko"]
    return "1층 필드"


def main() -> None:
    rows = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "data", "essences", "*.json"))):
        if os.path.basename(f).startswith("_"):
            continue
        e = load(os.path.relpath(f, ROOT))
        rows.setdefault(region(e["source_monster"]), []).append(e)
    total = sum(len(v) for v in rows.values())
    w = ["# 정수 표 — 스탯 · 생명력 · 색깔별 스킬 (%d종 — 필드·균열 50 + 계층정수)" % total, "",
         "> `python3 tools/essences_md.py`가 `data/essences/*.json`과 정수판 스킬 `data/skills/ess_*.json`에서 만든다 — **손으로 고치지 않는다**(정수를 바꿨으면 다시 돌린다).",
         "> 등급별 기준(주 스탯 합·생명력)은 `docs/balance/curve.md`, 공식은 `docs/balance/stats.md`. 정수 스킬의 위력은 몬스터판보다 낮추지 않는다(C15).",
         "", "- 스탯·생명력은 정수마다 고정값(굴림 없음 — J13). 수호자 정수는 무지갯빛 = 액티브 전부 + 스탯·생명력 ×1.5.",
         "- 일반 정수는 표의 색 중 하나로 떨어지고 그 색의 스킬 하나만 얻는다. 위력 = 공격력(물리 = 무기 + 근력×2, 마법 = 기본 + 마력 + 정신력×2)에 곱하는 값.", ""]
    for reg in REGION_ORDER:
        if reg not in rows:
            continue
        w.append("## %s (%d종)" % (reg, len(rows[reg])))
        w.append("")
        for e in sorted(rows[reg], key=lambda x: (-int(x.get("grade", 9)), x["id"])):
            st = e.get("stats", {})
            main = sum(v for k, v in st.items() if k in MAIN)
            stats = " · ".join("%s %+g" % (STAT.get(k, k), v) for k, v in st.items())
            hp = e.get("resources", {}).get("hp", 0)
            w.append("### %s — %s등급" % (e["name_ko"], e.get("grade")))
            w.append("- **스탯**: %s (주 스탯 합 %g) · **생명력** +%g" % (stats or "-", main, hp))
            p = e.get("passive", {})
            w.append("- **패시브**: %s — %s" % (p.get("name_ko", "-"), p.get("desc_ko", "")))
            w.append("")
            w.append("| 색 | 스킬 | 대상 | 비용 | 효과 |")
            w.append("|---|---|---|---|---|")
            for a in e.get("actives", []):
                w.append(skill_row(a["color"], a["skill"]))
            w.append("")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(w))
    print("essences.md: %d종" % total)


if __name__ == "__main__":
    main()
