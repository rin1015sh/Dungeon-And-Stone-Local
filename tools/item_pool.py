"""아이템 풀 문서 만들기: 게임 데이터(data/materials.json·item_types.json·balance.json items·items/)를 읽어
docs/balance/item_pool.md·item_pool.csv를 다시 만든다. 계산은 src/items/ItemForge.gd와 같다(공식의 정본은 데이터 + ItemForge).
    python3 tools/item_pool.py
소재·종류·등급 배율을 바꿨으면 다시 돌린다(문서가 낡지 않게).
"""
import csv
import glob
import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DATA = os.path.join(ROOT, "data")


def _load(name: str):
    with open(os.path.join(DATA, name), encoding="utf-8") as f:
        return json.load(f)


CFG = _load("balance.json")["items"]
GROW = {i + 1: v for i, v in enumerate(CFG["grow_by_tier"])}
ATK = {i + 1: v for i, v in enumerate(CFG.get("attack_by_tier", CFG["grow_by_tier"]))}
UNSCALED = CFG.get("unscaled", [])


def unscaled(stat: str) -> bool:
    """ItemForge.unscaled와 같다: 이름 또는 "resist_" 꼴 접두사."""
    return any(stat == u or (u.endswith("_") and stat.startswith(u)) for u in UNSCALED)
PRICE = {i + 1: v for i, v in enumerate(CFG["price_by_tier"])}
BASE_PRICE = CFG["base_price"]
SELL_RATIO = _load("city.json")["shop"]["sell_ratio"]
KIND_PRICE = CFG["kind_price"]
KIND_KO = {"metal": "금속", "leather": "가죽", "wood": "목재", "cloth": "천", "bone": "뼈", "gem": "보석"}
WHERE = {1: "대장간", 2: "대장간 주문(4층 탐험가급)", 3: "시중 거래", 4: "시중 거래", 5: "주문 제작(억 단위 — 원작)", 6: "시중에 거의 없음"}
STAT_KO = {**{s["id"]: s["name_ko"] for s in _load("stats.json")}, "magic": "마력"}
STAT_KO.update({"max:hp": "생명력", "max:soul": "영혼력", "dmg_dealt:slash": "주는 참격 피해", "dmg_dealt:pierce": "주는 관통 피해",
                "dmg_dealt:blunt": "주는 타격 피해", "dmg_taken:physical": "받는 물리 피해", "dmg_taken:magical": "받는 마법 피해"})
MATERIALS = []
for m in _load("materials.json"):
    MATERIALS.append({"id": m["id"], "name": m["name_ko"], "tier": m["tier"], "kind": m["kind"], "trait": m.get("trait", {}),
                      "price_mult": m.get("price_mult", 1.0), "source": m["notes"].split(" — ")[0], "note": m["notes"].split(" — ", 1)[-1]})
TYPES = []
for t in _load("item_types.json"):
    w = t.get("weapon")
    TYPES.append({"id": t["id"], "name": t["name_ko"], "slot": t["slot"], "category": t["category"], "kinds": t["kinds"],
                  "weapon": ({"type": w["damage_type"], "atk": w["attack"], "magic": w.get("magic"), "two_handed": t.get("two_handed", False), "ranged": w.get("ranged", False)} if w else None),
                  "grow": t["grow"], "penalty": t["penalty"], "price_mult": t["price_mult"], "size": t["size"], "note": t.get("notes", "")})
RES_KO = {r["id"]: r["name_ko"] for r in _load("resources.json")}
STATUS_KO = {x["id"]: x["name_ko"] for x in _load("statuses.json")}


def _fx(e: dict) -> str:
    t = e.get("type")
    if t == "restore_resource":
        return "%s %+d" % (RES_KO.get(e.get("resource"), e.get("resource")), e.get("amount", 0)) if isinstance(e.get("amount"), (int, float)) else RES_KO.get(e.get("resource"), "")
    if t == "remove_status":
        return "%s 풀기" % STATUS_KO.get(e.get("status"), e.get("status"))
    if t == "apply_status":
        return ("%s(%d%%)" % (STATUS_KO.get(e["status"]), e["chance"] * 100)) if "chance" in e else STATUS_KO.get(e.get("status"), "")
    if t == "light_source":
        return "빛 %gm · %d시간" % (e["radius_m"], e["hours"])
    return t


EXPLICIT = {}  # (종류, 소재) -> (id, 이름) — 지금 장비(forge)
PLAIN = []
for f in sorted(glob.glob(os.path.join(DATA, "items", "*.json"))):
    if os.path.basename(f).startswith("_"):
        continue
    d = json.load(open(f, encoding="utf-8"))
    if "forge" in d:
        EXPLICIT[(d["forge"]["type"], d["forge"]["material"])] = (d["id"], d["name_ko"])
    elif d.get("category") in ("light", "food", "potion", "tool") and d.get("price", 0) > 0:
        fx = " · ".join(_fx(x) for x in d.get("use_effects", []))
        PLAIN.append((d["id"], d["name_ko"], d["category"], d["price"], fx, False))


def grow_mult(tier: int) -> float:
    return GROW[tier]


def rnd(x: float) -> int:
    return int(math.floor(x + 0.5))  # GDScript roundf와 같게(반올림 — 파이썬 round는 짝수 쪽)


def nice(v: float) -> int:
    """ItemForge.nice: 유효숫자 두 자리(100 미만은 5 단위)."""
    if v < 100:
        return max(5, rnd(v / 5.0) * 5)
    unit = 10 ** (len(str(int(v))) - 2)
    return int(math.floor(v / unit + 0.5) * unit)


def build(t: dict, m: dict) -> dict:
    """ItemForge.build와 같은 계산."""
    tier = m["tier"]
    tr = m["trait"]
    g = grow_mult(tier)
    smult = tr.get("stat_mult", {})
    flat: dict = {}
    for k, v in t["grow"].items():
        flat[k] = flat.get(k, 0) + max(1, rnd(v * (1.0 if unscaled(k) else g) * smult.get(k, 1.0)))
    for k, v in t["penalty"].items():
        if k == "agi" and "agi_pen" in tr:
            ap = tr["agi_pen"]
            v = -math.floor(abs(v) * ap + (0.5 if ap > 1 else 0))
        flat[k] = flat.get(k, 0) + v
    extra = list(tr.get("mods", [])) + list(tr.get("weapon_mods" if t["weapon"] else "armor_mods", []))
    pct: dict = {}
    for md in extra:
        target = md["target"].replace(":weapon", ":" + (t["weapon"]["type"] if t["weapon"] else ""))
        if "percent" in md:
            pct[target] = md["percent"]
        else:
            flat[target] = flat.get(target, 0) + md["flat"]
    stats = {k: v for k, v in flat.items() if v != 0}
    out = {"type": t, "mat": m, "stats": stats, "pct": pct}
    if t["weapon"]:
        out["atk"] = rnd(t["weapon"]["atk"] * ATK[tier] * tr.get("atk", 1.0))
        if t["weapon"].get("magic"):
            out["stats"] = {"magic": rnd(t["weapon"]["magic"] * ATK[tier] * tr.get("atk", 1.0)), **out["stats"]}
    price = BASE_PRICE * t["price_mult"] * KIND_PRICE[m["kind"]] * PRICE[tier] * m["price_mult"]
    out["buy"] = nice(price)
    out["sell"] = rnd(out["buy"] * SELL_RATIO)
    ex = EXPLICIT.get((t["id"], m["id"]))
    out["id"] = ex[0] if ex else "%s_%s" % (m["id"], t["id"])
    out["name"] = ex[1] if ex else "%s %s" % (m["name"], t["name"])
    return out


def fmt_stats(st: dict, pct: dict = None) -> str:
    parts = ["%s %+d" % (STAT_KO.get(k, k), v) for k, v in st.items() if v != 0]
    parts += ["%s %+d%%" % (STAT_KO.get(k, k), rnd(v * 100)) for k, v in (pct or {}).items()]
    return " · ".join(parts)


def won(v: int) -> str:
    return "{:,}".format(v)


def main() -> None:
    rows = []
    for t in TYPES:
        for m in MATERIALS:
            if m["kind"] in t["kinds"]:
                rows.append(build(t, m))
    md = []
    md.append("# 아이템 풀 — 종류 × 소재 공식 (2026-10-23 적용)\n")
    md.append("> 생성: `python3 tools/item_pool.py` — 게임 데이터(`data/materials.json`·`item_types.json`·`balance.json items`)를 읽어 `ItemForge`와 같은 계산으로 만든다. 이 파일은 손으로 고치지 않는다(데이터를 고치고 다시 만든다). 같은 내용 CSV: `docs/balance/item_pool.csv`.")
    md.append("> 사용자 요청: \"아이템 종류(검·철퇴·창)와 소재 등급(강철·미스티움 …)으로 스탯이 오르게, 종류마다 특색(창 = 공격력↑ 민첩↓), 높은 소재일수록 증가율만 커지게, 감소는 알아서\".\n")
    md.append("## 1. 공식\n")
    md.append("| 값 | 공식 |\n|---|---|")
    md.append("| 공격력·마력 | 종류 기본값 × 공격력 배율(아래) — 반올림 |")
    md.append("| **증가** 스탯 | 종류 기본값 × 증가 배율(아래) — 반올림, 최소 1. 명중률·시각·속성 내성/감응도(%% 값)는 배율 없이 |")
    md.append("| **감소** 스탯 | 종류 값 그대로(등급과 무관) — 소재 특성 '가벼움'(라이티늄·미스릴 ×0.5)·'무거움'(아다만티움 ×1.5)만 바꾼다 |")
    md.append("| 소재 특성 | 소재마다 고정 효과(등급 배율을 받지 않는다) |")
    md.append("| 구입가 | %s × 종류 가격 계수 × 소재 종류 계수 × 등급 가격 배율 × 소재 개별 계수 → 유효숫자 두 자리 |" % won(BASE_PRICE))
    md.append("| 판매가 | 구입가 × %.1f(상점 `sell_ratio`) |\n" % SELL_RATIO)
    md.append("| 등급 | 1 | 2 | 3 | 4 | 5 | 6 |\n|---|---|---|---|---|---|---|")
    md.append("| 공격력 배율 | " + " | ".join("×%g" % ATK[i] for i in range(1, 7)) + " |")
    md.append("| 증가 배율 | " + " | ".join("×%g" % GROW[i] for i in range(1, 7)) + " |")
    md.append("| 가격 배율 | " + " | ".join("×%s" % won(PRICE[i]) for i in range(1, 7)) + " |")
    md.append("| 희귀도 | " + " | ".join(CFG["rarity_by_tier"]) + " |")
    md.append("| 구하는 곳 | " + " | ".join(WHERE[i] for i in range(1, 7)) + " |\n")
    md.append("소재 종류 가격 계수: " + " · ".join("%s ×%.1f" % (KIND_KO[k], v) for k, v in KIND_PRICE.items()) + ".\n")
    md.append("**돈 단위**: 지금 게임 돈(CT43 — 원작 시세 ÷ 25). 기준점: 강철 장검 2,000(지금 값 그대로) · 아이릴제(3단계) 장검 480,000(원작 1,200만 ÷ 25) · "
              "5단계 장검 5,000,000(원작 1억 2,500만 — '억 단위로 시작') · 6단계는 그 6배. 원작 시세로 쓰려면 모든 가격 ×25.\n")
    md.append("**규모 감각**: 1층 원정 한 번 벌이 약 36,000(`tools/sim_income.gd`). 2단계 장검(50,000)은 원정 한두 번, 3단계는 1층에서는 사실상 못 산다 — 원작처럼 '4층 탐험가쯤 돼야 2단계'에 가깝다.\n")
    md.append("## 2. 소재 (원작 = 사용자가 준 설정, 창작 = 빈 등급을 채운 것)\n")
    md.append("| 등급 | 소재 | 종류 | 출처 | 특성 |\n|---|---|---|---|---|")
    for m in sorted(MATERIALS, key=lambda x: (x["tier"], list(KIND_KO).index(x["kind"]))):
        md.append("| %d | %s | %s | %s | %s |" % (m["tier"], m["name"], KIND_KO[m["kind"]], m["source"], m["note"]))
    md.append("\n## 3. 종류 (1단계 기준 값 — 증가는 등급 배율을 받고, 감소는 고정)\n")
    md.append("| 종류 | 칸 | 쓰는 소재 | 피해·공격력 | 증가 | 감소 | 가격 계수 | 특색 |\n|---|---|---|---|---|---|---|---|")
    for t in TYPES:
        w = t["weapon"]
        wtxt = ""
        if w:
            wtxt = "%s %d%s%s" % ({"slash": "참격", "pierce": "관통", "blunt": "타격"}[w["type"]], w["atk"], " 양손" if w.get("two_handed") else "",
                                  " 원거리" if w.get("ranged") else "")
        md.append("| %s | %s | %s | %s | %s | %s | ×%.2f | %s |" % (t["name"], t["slot"], "·".join(KIND_KO[k] for k in t["kinds"]), wtxt,
                                                                  fmt_stats(t["grow"]), fmt_stats(t["penalty"]) or "없음", t["price_mult"], t["note"]))
    md.append("\n## 4. 전체 목록 (종류 × 소재)\n")
    md.append("이름 = 소재 + 종류(예: 라이티늄 창). 같은 등급에 금속이 둘이면 둘 다 있다.\n")
    for t in TYPES:
        md.append("### %s\n" % t["name"])
        md.append("| 등급 | 이름 | %s스탯 | 구입가 | 판매가 |\n|---|---|%s---|---:|---:|" % (("공격력 | ", "---:|") if t["weapon"] else ("", "")))
        for r in [x for x in rows if x["type"] is t]:
            m = r["mat"]
            atk = ("%d | " % r["atk"]) if t["weapon"] else ""
            buy = won(r["buy"]) + ("(살 수 없음)" if m["id"] == "ark" else "")
            md.append("| %d | %s `%s` | %s%s | %s | %s |" % (m["tier"], r["name"], r["id"], atk, fmt_stats(r["stats"], r["pct"]), buy, won(r["sell"])))
        md.append("")
    md.append("## 5. 소재를 쓰지 않는 아이템\n")
    md.append("| 이름 | id | 분류 | 효과 | 구입가 | 판매가 |\n|---|---|---|---|---:|---:|")
    for p in PLAIN:
        md.append("| %s | `%s` | %s | %s | %s | %s |" % (p[1], p[0], p[2], p[4], won(p[3]), won(rnd(p[3] * SELL_RATIO))))
    md.append("\n그 밖에 값이 정해진 것(이 공식 밖): 마석(화폐처럼 제값 — 9등급 80 … 5등급 4,000), 균열 히든 피스·넘버스(초록 보석 120,000·네크로노미콘 160,000 — 팔 물건, "
              "여신의 눈물·폭약·뿔피리 — 균열 밖 반출 불가, 팔지 못함), 계층보구(뼈 대검 — 팔지 못함). 넘버스·계층보구는 공식보다 강하다(소재 6단계 위).\n")
    md.append("## 6. 게임에서\n")
    md.append("- `ItemForge`(src/items)가 데이터를 읽은 직후 종류 × 소재 조합을 모두 아이템으로 만든다 — id `<소재>_<종류>`, 이름 `<소재> <종류>`. 공식·소재·종류를 바꾸면 모든 장비가 따라 바뀐다.")
    md.append("- 2026-10-23 전부터 있던 장비 14개는 아이템 JSON의 `forge`로 같은 조합을 맡는다 — id·이름·크기는 그대로(저장 호환), 수치·가격만 공식(위 목록에서 이름이 다른 것: 사냥용 단검·철퇴·사냥 활 …).")
    md.append("- 대장간 진열(`activities/smithy_trade` stock): 종류마다 1단계 기본 소재 + 2단계 4개(라이티늄 장검·창, 와이번 가죽 갑옷, 레드우드 활). 3단계 이상은 진열하지 않는다(지금 1층만).")
    md.append("- 공식 밖: 넘버스·계층보구·균열 히든 피스·반지/목걸이 옛것(구리 반지·뼈 목걸이)은 손으로 쓴 수치.")
    md.append("- 원작에 있는 내구도(월광석)는 규칙이 없어 특성을 어둠 내성으로 대신했다. 아크는 상점에 없다(`buyable: false`).\n")
    with open(os.path.join(ROOT, "docs", "balance", "item_pool.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(md) + "\n")
    with open(os.path.join(ROOT, "docs", "balance", "item_pool.csv"), "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["종류", "소재", "등급", "칸", "피해 유형", "공격력", "스탯", "구입가", "판매가"])
        for r in rows:
            t = r["type"]
            w.writerow([t["name"], r["mat"]["name"], r["mat"]["tier"], t["slot"], t["weapon"]["type"] if t["weapon"] else "", r.get("atk", ""),
                        fmt_stats(r["stats"], r["pct"]), r["buy"], r["sell"]])
        for p in PLAIN:
            w.writerow([p[1], "", "", p[2], "", "", p[4], p[3], rnd(p[3] * SELL_RATIO)])
    print("종류 %d × 소재 → 장비 %d개 + 일반 %d개" % (len(TYPES), len(rows), len(PLAIN)))


if __name__ == "__main__":
    main()
