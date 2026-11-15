#!/usr/bin/env python3
"""던전 에셋 키트 — 도시 · 건물 실내 라이브러리(AM69)의 분류 표 · 카탈로그.
같은 키트(assets/dungeon_kit)에 더한 도시 외부 · 공통 실내 · 시설(대장간 · 여관 · 신전 · 상점 · 은행) · 흔적 · 상호작용 · 효과 · 아이템 · 아이콘을
갤러리(tools/kit_gallery.tscn)와 카탈로그 문서가 같은 묶음으로 보게 한다. build.py가 kit.json `library`에 싣는다.

  python3 tools/dungeon_kit/library.py            → docs/asset_library/CITY_LIBRARY.md · city_library.json (kit.json에서 — 손으로 고치지 않는다)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))

# 이번 라이브러리에서 새로 만든 에셋의 모듈(앞머리) · 다른 모듈에 더한 id
NEW_MODULES = ("a_city", "a_interior", "a_smithy", "a_inn", "a_shrine", "a_shop", "a_bank", "a_env_", "a_item", "a_icon")
NEW_IDS = ("wall_wood", "wall_plaster", "wall_panel")
BROKEN = ("broken", "ruin", "collapsed", "toppled", "wreck", "damaged", "fallen", "torn", "shattered", "cracked", "burnt", "bent", "pried", "rotten")

# 시설이 공용 에셋에서 그대로 꺼내 쓰는 것(다시 만들지 않았다)
REUSED = {
    "city_exterior": ["floor_flag", "floor_old", "floor_cracked", "floor_broken", "floor_cobble", "floor_dirt", "floor_mossy", "ground_mud", "puddle", "ground_crack", "moss_patch", "weeds", "gravel",
        "palisade", "barrel", "crate", "sack", "basket", "bench", "bush", "tree_broadleaf", "flowers", "lantern_hanging", "torch_wall", "arch", "railing"],
    "interior_common": ["floor_flag", "floor_brick", "wall_stone", "wall_brick", "doorway", "pillar", "stairs_up", "stairs_down", "carpet", "table", "desk", "chair", "stool", "bench", "bed", "bookshelf", "wall_shelf",
        "cabinet", "dresser", "crate", "chest", "barrel", "basket", "sack", "bottles", "dishes", "books", "papers", "scrolls", "candles", "candlestick", "candelabra", "lantern", "torch_wall", "chandelier", "fireplace"],
    "smithy": ["anvil", "workbench", "grindstone", "toolbox", "weapon_rack", "armor_stand", "scorch", "brazier", "barrel"],
    "inn": ["table", "chair", "bench", "stool", "bed", "fireplace", "cooking_pot", "dishes", "bottles", "barrel", "candlestick", "chandelier", "carpet"],
    "shrine": ["altar", "statue", "statue_robed", "pedestal", "pillar_white", "candlestick", "candelabra", "candles", "carpet", "books"],
    "shop": ["crate", "barrel", "sack", "basket", "bottles", "backpack", "lantern", "wall_shelf", "supply_pile", "toolbox"],
    "bank": ["chest", "papers", "books", "scrolls", "chained_lock", "candlestick", "desk", "chair", "carpet"],
}
GROUPS = [   # (id, 이름, 고르는 규칙)
    ("city_exterior", "도시 외부", lambda i, a: a["cat"] == "city" or i.startswith("street_")),
    ("interior_common", "공통 실내", lambda i, a: a["cat"] == "interior" or i.startswith("room_") or i in NEW_IDS),
    ("smithy", "대장간", lambda i, a: a["cat"] == "smithy"),
    ("inn", "여관", lambda i, a: a["cat"] == "inn"),
    ("shrine", "신전", lambda i, a: a["cat"] == "shrine"),
    ("shop", "상점", lambda i, a: a["cat"] == "shop"),
    ("bank", "은행", lambda i, a: a["cat"] == "bank"),
    ("traces", "환경 흔적", lambda i, a: a["cat"] == "trace" and not _damaged(i, a)),
    ("damaged", "파손 · 폐허", lambda i, a: _damaged(i, a)),
    ("interactive", "상호작용 오브젝트", lambda i, a: bool(a.get("interact")) and a["cat"] in ("special", "furniture", "structure", "wall")),   # 시설 가구(계산대 · 금고 …)는 각 시설 쪽에
    ("magic_fx", "마법 · 환경 효과", lambda i, a: a["cat"] == "fx" or (a["cat"] in ("special", "light") and "magic" in a.get("tags", []) and not a.get("interact")) or a.get("lib") == "fx"),
    ("items", "아이템", lambda i, a: a["cat"] == "item"),
    ("icons", "UI 아이콘", lambda i, a: a["cat"] == "icon"),
]
TESTS = ["city_street", "smithy_room", "inn_room", "shrine_room", "shop_room", "bank_room"]   # 배치 시험 세트(sets_city.py)

CAT_USE = {
    "city": ("도시 거리 · 광장 · 건물 겉을 짓고 꾸민다", "도시 7구역 동네 · 다른 구역 · 미궁 안 마을 · 폐허가 된 거리"),
    "floor": ("바닥 타일(4 × 4칸 이어지는 그림)", "도시 거리 · 건물 실내 · 미궁의 지은 공간"),
    "wall": ("벽 타일(윗면 자동 연결 + 벽면)", "건물 실내 · 미궁의 지은 공간"),
    "interior": ("건물 안을 채우는 공용 가구 · 살림 · 장식", "모든 시설 · 일반 집 · 미궁 안 거처 · 균열의 방"),
    "smithy": ("대장간의 정체성 — 불 · 쇠 · 연장", "대장간 · 광산 막사 · 야영지 작업장 · 성채 병기고"),
    "inn": ("여관의 정체성 — 술 · 부엌 · 잠자리", "여관 · 선술집 · 일반 집 부엌 · 성채 식당"),
    "shrine": ("신전의 정체성 — 제단 · 봉헌 · 기도", "신전 · 묘지 예배실 · 미궁 안 버려진 성소"),
    "shop": ("상점의 정체성 — 진열 · 계산", "잡화점 · 시장 좌판 · 떠돌이 상인 · 창고"),
    "bank": ("은행의 정체성 — 금고 · 창살 · 서류", "은행 · 길드 금고실 · 성채 보물고 · 세금 창구"),
    "trace": ("누가 지나갔고 무슨 일이 있었는지 보이는 흔적", "도시 뒷골목 · 폐가 · 미궁 어디든"),
    "special": ("살피고 다루는 것 · 마법 장치", "미궁 기믹 방 · 도시 하수도 · 숨은 방"),
    "light": ("빛을 내는 것", "어디든"),
    "fx": ("화면에 얹는 가벼운 연출(4프레임)", "불 · 물 · 마법이 있는 곳 어디든"),
    "structure": ("이동을 막는 큰 구조물", "미궁 · 도시"), "furniture": ("가구 · 생활 물건", "실내 어디든"), "nature": ("자연물", "야외 · 동굴"),
    "item": ("가방 · 상점 · 드롭에 쓰는 아이템 그림(80 × 80) — 게임 데이터에는 올리지 않았다", "Tab 메뉴 가방 · 상점 카드 · 전투 드롭"),
    "icon": ("시설 · 표식 아이콘(96 × 96 — 상태이상 아이콘과 같은 판)", "지도 표식 · 시설 카드 · 안내"),
}


def is_new(id, fn_module):
    return fn_module.startswith(NEW_MODULES) or id in NEW_IDS or id.startswith(("street_", "room_"))


def _damaged(i, a):
    if a["cat"] in ("item", "icon", "fx", "trap", "floor", "wall"):
        return False
    return "ruin" in a.get("tags", []) and a["cat"] not in ("special", "light")


def export(manifest):
    """kit.json에 실을 분류 표: 새 에셋 먼저, 그 뒤에 그대로 꺼내 쓰는 공용 에셋."""
    A = manifest["assets"]
    groups = []
    for gid, name, rule in GROUPS:
        new = [i for i, a in A.items() if a.get("lib") and rule(i, a)]
        old = [i for i in REUSED.get(gid, []) if i in A and i not in new]
        if gid in ("traces", "interactive", "magic_fx", "damaged"):      # 기존 분류를 넓힌 묶음: 옛 에셋도 같은 규칙으로
            old = [i for i, a in A.items() if not a.get("lib") and (rule(i, a) or (gid == "damaged" and _old_damaged(i, a)))]
        groups.append({"id": gid, "name_ko": name, "ids": new + old, "new": len(new)})
    return {"groups": groups, "tests": [t for t in TESTS if t in manifest.get("sets", {})]}


def _old_damaged(i, a):
    return a["cat"] in ("furniture", "structure") and any(any(w in v for w in ("broken", "ruin", "collapsed", "wreck", "fallen")) for v in a["variants"])


def _role(a):
    out = []
    if a.get("collide"):
        out.append("이동 방해")
    if a.get("interact"):
        out.append("상호작용(%s)" % a["interact"])
    if a.get("light"):
        out.append("광원")
    return " · ".join(out) or {"decal": "바닥 장식", "wall_decal": "벽 장식", "over": "머리 위 전경", "floor": "타일", "wall": "타일"}.get(a["layer"], "장식")


def rows(kit):
    """→ [(묶음 이름, [에셋 dict])] — 카탈로그 한 줄 = 에셋 하나."""
    A = kit["assets"]
    out = []
    for g in kit["library"]["groups"]:
        items = []
        for k, i in enumerate(g["ids"]):
            a = A[i]
            v0 = next(iter(a["variants"].values()))["frames"][0]
            use, places = CAT_USE.get(a["cat"], ("", ""))
            items.append({"id": i, "name_ko": a.get("name_ko", i), "group": g["id"], "cat": a["cat"], "layer": a["layer"], "new": k < g["new"],
                "path": kit["sheets"][a["sheet"]]["path"], "region": v0[:4], "size_px": [v0[2], v0[3]], "size_tiles": [round(v0[2] / kit["px_per_tile"], 2), round(v0[3] / kit["px_per_tile"], 2)],
                "use": use + " — " + _role(a), "places": places, "variants": list(a["variants"]), "collide": bool(a.get("collide")),
                "animated": sorted(v for v, d in a["variants"].items() if len(d["frames"]) > 1), "tags": a.get("tags", [])})
        out.append((g["name_ko"], items))
    return out


def main():
    with open(os.path.join(ROOT, "assets", "dungeon_kit", "kit.json"), encoding="utf-8") as f:
        kit = json.load(f)
    R = rows(kit)
    A = kit["assets"]
    new = {i: a for i, a in A.items() if a.get("lib")}
    n_var = sum(len(a["variants"]) for a in new.values())
    n_img = sum(len(v["frames"]) for a in new.values() for v in a["variants"].values())
    L = ["# CITY_LIBRARY — 도시 · 건물 실내 에셋 라이브러리 카탈로그 (AM69)", "",
        "> `python3 tools/dungeon_kit/library.py`가 `assets/dungeon_kit/kit.json`에서 만든다 — **손으로 고치지 않는다**. 같은 내용의 JSON = `city_library.json`. 쓰는 법 `docs/DUNGEON_KIT.md` §3, 갤러리 `tools/kit_gallery.tscn`.", "",
        "이번에 새로 만든 에셋 **%d종** · 변형 %d개 · 그림 %d장(키트 전체 %d종). 아래 표에서 **새** 표시가 없는 줄은 원래 있던 공용 에셋을 그 자리에 그대로 꺼내 쓰는 것이다(다시 만들지 않았다)." % (len(new), n_var, n_img, len(A)), "",
        "- **파일 경로**: 그림은 분류마다 묶음 한 장(`assets/dungeon_kit/<분류>.webp`)이고 낱 그림의 자리 · 원점은 `kit.json`에 있다. 게임에서는 `DungeonKit.open().make(id, 변형)`(노드) · `.texture(id, 변형)`(AtlasTexture 낱장)로 하나씩 꺼낸다.",
        "- **크기**: 첫 변형의 그림 px(칸 = 64px로 나눈 값). 게임 세계에 놓을 때는 0.5배(한 칸 32px).",
        "- **충돌**: ○ = `collide` 네모가 있다(`make`가 StaticBody2D를 단다). **애니**: 여러 프레임인 변형 이름.", ""]
    L += ["| 분류 | 새 에셋 | 꺼내 쓰는 공용 | 변형(새) |", "|---|---|---|---|"]
    for name, items in R:
        nw = [x for x in items if x["new"]]
        L.append("| %s | %d | %d | %d |" % (name, len(nw), len(items) - len(nw), sum(len(x["variants"]) for x in nw)))
    L.append("")
    for name, items in R:
        use, places = "", ""
        L += ["## %s — %d종" % (name, len(items)), "", "| 에셋 이름 | id | 새 | 분류 · 층 | 묶음 파일 | 크기 px(칸) | 사용 목적 | 다시 쓸 곳 | 변형 | 충돌 | 애니 |", "|---|---|---|---|---|---|---|---|---|---|---|"]
        for x in items:
            vs = " · ".join(x["variants"][:8]) + (" … (%d)" % len(x["variants"]) if len(x["variants"]) > 8 else "")
            L.append("| %s | `%s` | %s | %s · %s | `%s` | %d×%d (%.1f×%.1f) | %s | %s | %s | %s | %s |" % (x["name_ko"], x["id"], "새" if x["new"] else "", x["cat"], x["layer"], x["path"].replace("res://assets/dungeon_kit/", ""),
                x["size_px"][0], x["size_px"][1], x["size_tiles"][0], x["size_tiles"][1], x["use"], x["places"], vs, "○" if x["collide"] else "", " · ".join(x["animated"])))
        L.append("")
    out = os.path.join(ROOT, "docs", "asset_library")
    with open(os.path.join(out, "CITY_LIBRARY.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    with open(os.path.join(out, "city_library.json"), "w", encoding="utf-8") as f:
        json.dump({"_comment": "tools/dungeon_kit/library.py가 만든다", "new_assets": len(new), "groups": [{"name_ko": n, "assets": items} for n, items in R]}, f, ensure_ascii=False, indent=1)
    print("문서: docs/asset_library/CITY_LIBRARY.md · city_library.json — 새 에셋 %d종 · 변형 %d · 그림 %d장" % (len(new), n_var, n_img))
    for name, items in R:
        print("  %-14s 새 %3d · 공용 %3d" % (name, sum(x["new"] for x in items), sum(not x["new"] for x in items)))


if __name__ == "__main__":
    sys.exit(main())
