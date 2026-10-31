"""층 찍어내기 점검표: 1~10층마다 "층 하나의 부품"(docs/plans/floors_2_10.md §1)이 얼마나 갖춰졌는지 데이터·파일을 읽어 표로 만든다.
    python3 tools/floor_status.py            → docs/balance/floor_status.md 다시 쓰기 + 요약 출력
    python3 tools/floor_status.py --floor=2  → 그 층의 빠진 것만 자세히(파일을 쓰지 않는다)
Godot 없이 돈다(파일 존재·JSON 참조만 본다 — 스키마 검사는 validate_data.gd, 그림 확인은 캡처).
층 데이터·몬스터·정수·균열·서적을 더했으면 다시 돌린다.
"""
import glob
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "data")
OUT = os.path.join(ROOT, "docs", "balance", "floor_status.md")

# 층 표(balance_curve.py FLOOR와 같다 — 필드 등급 · 기준 레벨 · 파티) — 바꾸면 둘 다
FIELD_GRADE = {1: 9, 2: 8, 3: 7, 4: 7, 5: 6, 6: 5, 7: 5, 8: 4, 9: 4, 10: 3}
PARTY = {1: 1, 2: 2, 3: 5, 4: 5, 5: 5, 6: 5, 7: 5, 8: 5, 9: 5, 10: 5}
BOOKS_PER_FIELD = 1  # 층마다 서적 분야당 최소 권수(CT52 — "새 층이면 floor n 항목을 더한다")


def load(path: str):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def collection(name: str) -> dict:
    out = {}
    for p in sorted(glob.glob(os.path.join(DATA, name, "*.json"))):
        if os.path.basename(p).startswith("_"):
            continue
        d = load(p)
        for e in d if isinstance(d, list) else [d]:
            out[e["id"]] = e
    return out


def res(path: str) -> bool:
    """res://… 경로가 저장소에 있는가."""
    return bool(path) and os.path.exists(os.path.join(ROOT, path.replace("res://", "")))


FLOORS = collection("floors")
MONSTERS = collection("monsters")
ESSENCES = collection("essences")
RIFTS = collection("rifts")
BOOKS = collection("city_info")
EVENTS = collection("events")
LIB_FIELDS = [f["id"] for f in load(os.path.join(DATA, "city.json"))["library"]["fields"]]
AUDIO = load(os.path.join(DATA, "audio.json"))
KO = load(os.path.join(DATA, "strings", "ko.json"))


def has_string(key: str) -> bool:
    node = KO
    for part in key.split("."):
        if not isinstance(node, dict) or part not in node:
            return False
        node = node[part]
    return True


def check(n: int) -> list:
    """(부품, 상태 ok|part|none, 설명) 목록."""
    rows = []
    fdefs = [f for f in FLOORS.values() if int(f.get("floor", 0)) == n]
    fd = fdefs[0] if fdefs else {}
    add = lambda name, state, note="": rows.append((name, state, note))
    if not fd:
        add("층 정의 data/floors", "none", "f%d_<id>.json 없음" % n)
    else:
        add("층 정의 data/floors", "ok", fd["id"])
        gen = fd.get("generator", "")
        add("생성기 src/explore/generators", "ok" if os.path.exists(os.path.join(ROOT, "src/explore/generators", gen + ".gd")) else "none", gen)
        fixed = fd.get("fixed_map", {}).get("file", "")
        add("고정 지도(bake_floor)", "ok" if res(fixed) else ("none" if fixed else "part"), fixed or "fixed_map 없음 — 입장마다 생성")
        art = fd.get("art", {})
        decor = art.get("decor", {})
        add("데칼 시트·굽기(bake_decor)", "ok" if res(decor.get("sheet", "")) and res(decor.get("baked", "")) else "none",
            decor.get("sheet", "art.decor 없음"))
        add("전투 뒷그림", "ok" if res(art.get("battleback", {}).get("image", "")) else "none", art.get("battleback", {}).get("image", ""))
        loop = art.get("ambience", {}).get("loop", "")
        add("환경음 audio.ambience", "ok" if loop in AUDIO.get("ambience", {}) else "none", loop)
        regions = fd.get("regions", [])
        bad = sorted({m for r in regions for m in r.get("monsters", []) if m not in MONSTERS})
        add("지역 스폰 regions", "ok" if regions and not bad else ("part" if regions else "none"),
            "%d지역" % len(regions) + (" · 없는 몬스터 " + ", ".join(bad) if bad else ""))
        feats = fd.get("features", [])
        badf = sorted({s.get("event") for s in feats if s.get("event") not in EVENTS})
        add("동굴 요소 features", "ok" if feats and not badf else ("part" if feats else "none"),
            "%d종 %d곳" % (len(feats), sum(int(s.get("count", 0)) for s in feats)) + (" · 없는 이벤트 " + ", ".join(badf) if badf else ""))
        add("다른 탐험가 explorers", "ok" if fd.get("explorers") else "none")
        portals = fd.get("portals", [])
        add("위층 포탈 portals", "ok" if portals or n == 10 else "none", "%d개" % len(portals))
        lord = fd.get("lord", {}).get("monster", "")
        lm = MONSTERS.get(lord, {})
        pat = lm.get("pattern", "")
        lord_ok = bool(lm) and (not pat or os.path.exists(os.path.join(ROOT, "src/combat/patterns", pat + ".gd")))
        add("계층군주 lord(+패턴)", "ok" if lord_ok else "none", lord + (" · 패턴 " + pat if pat else ""))
        if lord:
            own = has_string("explore.boss_notice." + lord)
            add("군주 등장 문구 explore.boss_notice", "ok" if own else "part", lord + ("" if own else " — 전용 문구 없음(any를 씀)"))
    mons = [m for m in MONSTERS.values() if int(m.get("floor", 0)) == n and m.get("rank") not in ("human", "token")]
    field = [m for m in mons if any("_rift_" not in t and not t.endswith("_lord") for t in m.get("floor_tags", []))]
    add("필드 몬스터", "ok" if field else "none", "%d종 · 등급 %s (목표 %d)" % (len(field), sorted({int(m.get("grade", 0)) for m in field}), FIELD_GRADE[n]))
    noart = sorted(m["id"] for m in mons if not os.path.exists(os.path.join(ROOT, "assets/monsters", m["id"] + ".webp")))
    add("몬스터 그림 assets/monsters", "ok" if mons and not noart else ("part" if mons else "none"), ("빠짐 " + ", ".join(noart)) if noart else "%d장" % len(mons))
    ess = [e for e in ESSENCES.values() if int(MONSTERS.get(e.get("source_monster", ""), {}).get("floor", 0)) == n]
    add("정수 data/essences", "ok" if ess else "none", "%d종" % len(ess))
    rifts = [r for r in RIFTS.values() if int(r.get("host_floor", 0)) == n]
    rnote = []
    rstate = "ok" if rifts else "none"
    for r in rifts:
        chs = r.get("chapters", [])
        missing = [c["id"] for c in chs if not res(c.get("map", {}).get("blueprint", ""))]
        if r.get("guardian") not in MONSTERS or missing:
            rstate = "part"
        rnote.append("%s %d챕터%s" % (r["name_ko"], len(chs), (" · 지도 빠짐 " + ",".join(missing)) if missing else ""))
    add("균열 data/rifts", rstate, " / ".join(rnote))
    by_field = {f: sum(1 for b in BOOKS.values() if b.get("field") == f and int(b.get("floor", 1)) == n) for f in LIB_FIELDS}
    short = [f for f, c in by_field.items() if c < BOOKS_PER_FIELD]
    total = sum(by_field.values())
    add("도서관 서적(floor n)", "ok" if not short else ("part" if total else "none"),
        "%d권" % total + ((" · 빠진 분야 " + ", ".join(short)) if short else ""))
    return rows


MARK = {"ok": "●", "part": "◐", "none": "○"}


def summary_table() -> str:
    names = [r[0] for r in check(1)]
    head = "| 부품 | " + " | ".join("%d층" % n for n in range(1, 11)) + " |\n|---|" + "---|" * 10 + "\n"
    grid = {n: {r[0]: r[1] for r in check(n)} for n in range(1, 11)}
    lines = []
    for name in names:
        lines.append("| %s | " % name + " | ".join(MARK[grid[n].get(name, "none")] for n in range(1, 11)) + " |")
    return head + "\n".join(lines)


def detail(n: int) -> str:
    out = ["## %d층 (필드 등급 %d · 파티 %d)" % (n, FIELD_GRADE[n], PARTY[n])]
    for name, state, note in check(n):
        out.append("- %s %s%s" % (MARK[state], name, (" — " + note) if note else ""))
    return "\n".join(out)


def main() -> None:
    args = dict(a.lstrip("-").split("=", 1) for a in sys.argv[1:] if "=" in a)
    if "floor" in args:
        n = int(args["floor"])
        print(detail(n))
        return
    md = ["# 층 찍어내기 점검표 (도구가 만든 것 — 손으로 고치지 않는다)", "",
          "`python3 tools/floor_status.py`가 데이터·파일을 읽어 만든다. ● 갖춤 · ◐ 일부 · ○ 없음. "
          "부품 목록과 만드는 법은 `docs/plans/floors_2_10.md` §1. 한 층의 빠진 것만 보려면 `--floor=<n>`.", "",
          summary_table(), ""]
    for n in range(1, 11):
        md += [detail(n), ""]
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("\n".join(md))
    print(summary_table())
    print("\n→ " + os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
