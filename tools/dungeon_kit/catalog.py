#!/usr/bin/env python3
"""던전 에셋 키트 — 에셋 라이브러리 문서 만들기 · 중복 검사(docs/asset_library).
구운 목록(assets/dungeon_kit/kit.json)과 지역 표(regions.py) · 아직 없는 에셋 표(아래 BACKLOG)에서 문서 두 장을 쓴다 — 손으로 고치지 않는다.

  python3 tools/dungeon_kit/catalog.py            → docs/asset_library/ASSET_CATALOG.md · REGIONAL_ASSET_PLAN.md
  python3 tools/dungeon_kit/catalog.py --check    중복 검사만: 같은 이름 · 픽셀까지 같은 그림 · 지역에서 안 쓰는 새 에셋 (문제가 있으면 exit 1)
  python3 tools/dungeon_kit/catalog.py --sheets   새 분류의 이름표 붙은 모음 그림 + 지역 세트를 docs/screens/asset_library/에(jpg)
"""
import hashlib
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
OUT = os.path.join(ROOT, "docs", "asset_library")
SHOTS = os.path.join(ROOT, "docs", "screens", "asset_library")

CAT_KO = {"floor": "바닥", "wall": "벽 · 절벽", "terrain": "지형", "flora": "식생", "nature": "자연물", "structure": "구조물", "furniture": "가구 · 생활", "light": "조명",
    "trace": "환경 흔적", "special": "특수 · 기믹", "trap": "함정", "fx": "환경 연출"}
REUSE_KO = {"common": "공용", "ext": "지역 확장형", "region": "지역 전용"}
LORE_KO = {"specific": "구체적", "partial": "일부", "none": "없음(확장 후보)"}
GROUP = {"A. 공용 기본 · 지형": ["floor", "wall", "terrain", "nature"], "B. 식생": ["flora"], "C. 건축 · 구조물": ["structure"], "D. 장식 · 환경 흔적": ["furniture", "trace", "light"],
    "E. 상호작용 · 기믹": ["special", "trap"], "F. 환경 연출": ["fx"]}

# 아직 없는 에셋(기획) — (이름, 분류, 쓸 지역, 형태, 기능, 재사용성, 제작 방식, 우선순위)
BACKLOG = [
    ("곡선 책장 · 200단 계단", "가구 · 구조물", "도서관섬", "원형 방 둘레에 맞는 굽은 책장 조각, 거대한 존재용 넓은 계단", "이동 방해 · 통로", "지역 전용", "조합형", "낮음"),
    ("유령선 · 선착장", "구조물", "유령섬 · 대해", "섬 둘레를 지나는 배(원경), 배를 대는 잔교", "장식", "지역 전용", "개별 제작", "낮음"),
    ("저택 복도 · 살덩이 공간", "바닥 · 벽", "영혼의 요새 2 · 3페이즈", "고풍스러운 저택 벽 · 마루, 꿈틀거리는 물컹한 바닥과 산성액", "타일", "지역 전용", "코드 생성(타일)", "낮음"),
    ("거대한 기둥 고리 · 푸른 알", "구조물", "아틀란테 중심부", "빌딩만 한 기둥이 원형으로 선 공터(원경), 가운데 큰 알", "랜드마크", "지역 전용", "개별 제작", "낮음"),
    ("나선 샛길 · 원형 계단", "지형", "빙하의 눈 · 녹색 탄광 3챕터", "원기둥 벽을 따라 도는 좁은 길", "이동 통로", "지역 전용", "조합형", "낮음"),
    ("오크 거주 구조물", "구조물", "3층 오크 군락지", "문서에 생김새가 없다 — 원문을 받으면 만든다(키트는 울타리 · 천막으로 대신 · 게임 3층에는 따로 그린 천막 · 토템이 있다)", "—", "지역 전용", "—", "낮음"),
    ("동 · 서 · 남쪽을 보는 벽면", "벽", "모든 실내", "지금은 북쪽 벽면만 — 옆 · 아래 벽과 옆으로 난 문", "이동 방해", "공용", "코드 생성(타일)", "중간"),
]


def load():
    with open(os.path.join(ROOT, "assets", "dungeon_kit", "kit.json"), encoding="utf-8") as f:
        return json.load(f)


def used_by(kit):
    """에셋 id → 그 에셋을 쓰는 지역 id 목록."""
    out = {}
    for rid, r in kit.get("regions", {}).items():
        for ref in r["floor"] + r["assets"] + ["wall_" + r["wall"]]:
            out.setdefault(ref.partition(".")[0], [])
            if rid not in out[ref.partition(".")[0]]:
                out[ref.partition(".")[0]].append(rid)
    return out


def role(a):
    out = []
    if a["layer"] in ("floor", "wall"):
        out.append("타일")
    if (a.get("meta") or {}).get("hazard"):
        out.append("위험 바닥")
    if a.get("collide"):
        out.append("이동 방해")
    if a.get("interact"):
        out.append("상호작용(%s)" % a["interact"])
    if a.get("light"):
        out.append("광원")
    if any(len(v["frames"]) > 1 for v in a["variants"].values()):
        out.append("애니메이션")
    if (a.get("meta") or {}).get("cover"):
        out.append("시야 덮개")
    return " · ".join(out) or ("바닥 장식" if a["layer"] == "decal" else "벽 장식" if a["layer"] == "wall_decal" else "머리 위 전경" if a["layer"] == "over" else "장식")


def how(a):
    m = a.get("meta") or {}
    base = "넓은 타일 그림" if a["layer"] in ("floor", "wall") else "코드 생성"
    return base + (" · 조합형" if m.get("module") or m.get("tile_w") or m.get("autotile") else "")


def priority(n):
    return "높음" if n >= 4 else "중간" if n >= 2 else "낮음"


def write_catalog(kit):
    use = used_by(kit)
    regions = kit.get("regions", {})
    A = kit["assets"]
    n_var = sum(len(a["variants"]) for a in A.values())
    n_img = sum(len(v["frames"]) for a in A.values() for v in a["variants"].values())
    reuse_n = {k: sum(1 for a in A.values() if a.get("reuse", "common") == k) for k in REUSE_KO}
    L = ["# ASSET_CATALOG — 에셋 목록", "",
        "> `python3 tools/dungeon_kit/catalog.py`가 `assets/dungeon_kit/kit.json`에서 만든다 — **손으로 고치지 않는다**. 쓰는 법은 `GENERATION_GUIDE.md`, 지역별 묶음은 `REGIONAL_ASSET_PLAN.md`, 그림은 `docs/screens/asset_library/` · `docs/screens/dungeon_kit/`.", "",
        "에셋 **%d종** · 변형 %d개 · 그림 %d장 — 공용 %d · 지역 확장형 %d · 지역 전용 %d. 지역 %d곳." % (len(A), n_var, n_img, reuse_n["common"], reuse_n["ext"], reuse_n["region"], len(regions)), "",
        "- **재사용성**: 공용 = 어느 지역에나 · 지역 확장형 = 공용 에셋의 틀(`base`)을 지역 재질 · 형태로 넓힌 것 · 지역 전용 = 그 장소의 정체성.",
        "- **우선순위**: 쓰는 지역 수로 매긴다(4곳 이상 높음 · 2~3곳 중간 · 그 밖 낮음) — 모두 만들어진 에셋이다. 아직 없는 것은 맨 아래 표.",
        "- **기능**: 이동 방해 = `collide`가 있다 · 상호작용 = `interact` 귀띔 · 광원 = `light` · 애니메이션 = 여러 프레임.", ""]
    for title, cats in GROUP.items():
        L += ["## " + title, ""]
        for cat in cats:
            ids = [i for i, a in A.items() if a["cat"] == cat]
            if not ids:
                continue
            L += ["### %s (`%s`) — %d종" % (CAT_KO[cat], cat, len(ids)), "", "| 에셋 이름 | id | 형태(변형) | 기능 | 재사용성 | 제작 방식 | 쓰는 지역 | 우선순위 |", "|---|---|---|---|---|---|---|---|"]
            for i in sorted(ids, key=lambda i: (-len(use.get(i, [])), i)):
                a = A[i]
                vs = list(a["variants"])
                shape = " · ".join(vs[:7]) + (" … (%d)" % len(vs) if len(vs) > 7 else "")
                reuse = REUSE_KO[a.get("reuse", "common")] + (" ← `%s`" % a["base"] if a.get("base") else "")
                us = use.get(i, [])
                where = ", ".join(regions[r]["name_ko"].split(" · ")[0] for r in us[:3]) + (" 외 %d" % (len(us) - 3) if len(us) > 3 else "") if us else "—"
                L.append("| %s | `%s` | %s | %s | %s | %s | %s | %s |" % (a.get("name_ko", i), i, shape, role(a), reuse, how(a), where, priority(len(us))))
            L.append("")
    L += ["## 아직 없는 에셋(기획)", "", "설정 문서에 나오지만 아직 만들지 않은 것 · 여러 지역에 필요한 기반. 다음 제작 단계는 위에서부터.", "",
        "| 에셋 이름 | 분류 | 사용 지역 | 형태 | 기능 | 재사용성 | 제작 방식 | 우선순위 |", "|---|---|---|---|---|---|---|---|"]
    order = {"높음": 0, "중간": 1, "낮음": 2}
    for row in sorted(BACKLOG, key=lambda r: order[r[7]]):
        L.append("| " + " | ".join(row) + " |")
    L.append("")
    _write("ASSET_CATALOG.md", L)


def write_regions(kit):
    A = kit["assets"]
    R = kit.get("regions", {})
    L = ["# REGIONAL_ASSET_PLAN — 지역별 에셋 묶음", "",
        "> `python3 tools/dungeon_kit/catalog.py`가 `tools/dungeon_kit/regions.py`에서 만든다 — **손으로 고치지 않는다**(지역을 더하거나 고치려면 regions.py).", "",
        "미궁 설정 문서(사용자 2026-11-14 「겜바바 미궁 설정」)의 장소마다 쓸 수 있는 키트 에셋. 게임 코드는 `DungeonKit.region_assets(지역 id, 분류)`.", "",
        "- **묘사 정도**: 구체적 = 문서에 생김새가 적혀 있다 · 일부 = 몇 가지만 · **없음(확장 후보)** = 이름 · 규칙뿐 — 그 지역의 에셋은 임시 후보이고 확정 설정이 아니다(원문을 받으면 고친다).",
        "- 문서에 없는 생김새를 지어낸 곳은 '남은 것' 칸에 적었다. 우리 게임의 기획(`docs/CANON.md`)과 어긋나면 우리 쪽이 이긴다(FL2).", "",
        "| 묘사 정도 | 지역 수 |", "|---|---|"]
    for k, name in LORE_KO.items():
        L.append("| %s | %d |" % (name, sum(1 for r in R.values() if r["lore"] == k)))
    L.append("")
    last = None
    for rid, r in R.items():
        head = rid.split("_")[0]
        group = {"f1": "1층", "f2": "2층", "f3": "3층", "f4": "4층", "f5": "5층", "f6": "6층", "f7": "7층", "f8": "8층", "f9": "9층", "f10": "10층", "b1": "지하 1층", "rift": "균열", "hidden": "히든 필드", "common": "미궁 공통"}[head]
        if group != last:
            L += ["## " + group, ""]
            last = group
        own = [x for x in r["assets"] if A[x.partition(".")[0]].get("reuse", "common") != "common"]
        common = [x for x in r["assets"] if x not in own]
        L += ["### %s (`%s`) — %s" % (r["name_ko"], rid, r["where"]), "",
            "- 묘사 정도: **%s** — %s" % (LORE_KO[r["lore"]], r["src"]),
            "- 바닥: %s · 벽: `wall_%s`" % (" ".join("`%s`" % f for f in r["floor"]), r["wall"]),
            "- 지역 확장 · 전용: %s" % (" ".join("`%s`" % x for x in own) or "—"),
            "- 공용: %s" % (" ".join("`%s`" % x for x in common) or "—")]
        if r.get("todo"):
            L.append("- 남은 것: " + r["todo"])
        L.append("")
    _write("REGIONAL_ASSET_PLAN.md", L)


def _write(name, lines):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("문서:", os.path.relpath(path, ROOT), "%.0fKB" % (os.path.getsize(path) / 1024))


def check(kit):
    """중복 검사 → 문제 목록."""
    import numpy as np
    from PIL import Image
    A = kit["assets"]
    bad = []
    names = {}
    for i, a in A.items():
        names.setdefault(a.get("name_ko", i), []).append(i)
    bad += ["같은 이름 '%s': %s" % (n, ", ".join(v)) for n, v in names.items() if len(v) > 1]
    sheets = {k: np.asarray(Image.open(os.path.join(ROOT, v["path"].replace("res://", ""))).convert("RGBA")) for k, v in kit["sheets"].items()}
    seen = {}
    for i, a in A.items():
        for vn, v in a["variants"].items():
            x, y, w, h = [int(t) for t in v["frames"][0][:4]]
            key = hashlib.sha1(sheets[a["sheet"]][y:y + h, x:x + w].tobytes()).hexdigest()
            if key in seen and seen[key][0] != i:      # 같은 에셋 안의 프레임은 같을 수 있다
                bad.append("픽셀까지 같은 그림: %s.%s = %s.%s" % (i, vn, seen[key][0], seen[key][1]))
            seen.setdefault(key, (i, vn))
            if w < 4 or h < 4:
                bad.append("빈 그림: %s.%s" % (i, vn))
    use = used_by(kit)
    bad += ["어느 지역에도 안 쓰는 지역 확장 · 전용 에셋: " + i for i, a in A.items() if a.get("reuse", "common") != "common" and i not in use]
    return bad


def sheets():
    from PIL import Image
    os.makedirs(SHOTS, exist_ok=True)
    tmp = os.path.join(HERE, ".cache", "_sheet.png")
    for name, sel in (("ground", ["ground_"]), ("wall_nature", ["wall_cave", "wall_sandstone", "wall_ice", "wall_basalt", "wall_metal", "wall_top", "sealed_door"]), ("terrain", ["terrain"]), ("flora", ["flora"]),
            ("structure", ["ruin_wall", "portal_stele", "monument", "pillar_white", "palisade", "tent", "mine_", "great_mirror"]), ("fx", ["drift", "mist", "light_orb", "collapse_crack", "red_beam", "lightning", "death_tile"]),
            ("site", ["ledge", "ramp", "reef", "boat", "stairs_ice", "overhead_rail", "drone_wreck", "drawbridge", "powder_keg", "cracked_wall", "statue_gem", "bookshelf_tall", "burnt_", "pyramid_temple", "crows", "flotsam", "ground_beach"]),
            ("edge", ["fringe_grass", "fringe_snow", "fringe_sand", "fringe_mud", "shore_rim", "cliff_", "bridge", "waterfall", "fireplace", "carpet"])):
        subprocess.run([sys.executable, os.path.join(HERE, "build.py")] + sel + ["--sheet=" + tmp], check=True, stdout=subprocess.DEVNULL)
        Image.open(tmp).convert("RGB").save(os.path.join(SHOTS, "sheet_%s.jpg" % name), quality=84)
        print("모음 그림: docs/screens/asset_library/sheet_%s.jpg" % name)
    import sets_wild
    subprocess.run([sys.executable, os.path.join(HERE, "compose.py")] + list(sets_wild.WILD) + ["--out=" + os.path.join(HERE, ".cache", "_sets")], check=True, stdout=subprocess.DEVNULL)
    for s in sets_wild.WILD:
        Image.open(os.path.join(HERE, ".cache", "_sets", "set_%s.png" % s)).convert("RGB").save(os.path.join(SHOTS, "set_%s.jpg" % s), quality=84)
    print("세트 그림 %d장: docs/screens/asset_library/set_*.jpg" % len(sets_wild.WILD))


def main():
    kit = load()
    if "--sheets" in sys.argv:
        return sheets()
    bad = check(kit)
    for b in bad:
        print("문제:", b)
    if "--check" in sys.argv:
        print("중복 검사: %s" % ("문제 %d개" % len(bad) if bad else "통과 — 에셋 %d종" % len(kit["assets"])))
        raise SystemExit(1 if bad else 0)
    write_catalog(kit)
    write_regions(kit)


if __name__ == "__main__":
    main()
