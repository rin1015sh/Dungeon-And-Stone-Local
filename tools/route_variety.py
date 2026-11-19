#!/usr/bin/env python3
"""원정마다 바뀌는 자리(plans/expansion_f1_3_E §3 ② — 2026-11-19): 2층 층 JSON route_spots의 지키는 무리 · 요소 · 매복에
"any"(자리 후보 — 원정마다 하나) · "appear"(나올 확률)를 덧입힌다. RouteSpots.pick이 읽는다.

층 JSON은 레이아웃 도구(f2b · f2g · f2r_layout.py)와 f2_new_monsters.py가 만든다 — 그것들을 다시 돌렸으면 이것도 다시 돌린다.
같은 항목에 여러 번 돌려도 같다(덮어쓴다). 고칠 것은 아래 VARIETY 표만.

    python3 tools/route_variety.py
"""
import json
import os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")

# (층, 목록, 찾는 조건, 덧입힐 키). 찾는 조건 = 그 항목의 키 값이 모두 같으면(monsters는 첫 몬스터만 본다).
VARIETY = [
    # 짐승의 소굴: 바위 곁 위장 불카르는 원정마다 한두 마리만, 숨은 은닉처 자리는 곰굴 · 뼈 무덤 · 바깥 갈림목 중 하나
    ("f2_beast_den", "guards", {"mark": "bulkar_outer"}, {"appear": 0.67}),
    ("f2_beast_den", "guards", {"mark": "bulkar_wall"}, {"appear": 0.67}),
    ("f2_beast_den", "guards", {"mark": "bulkar_deep"}, {"appear": 0.67}),
    ("f2_beast_den", "features", {"mark": "bear_cave", "event": "hidden_cache"},
     {"any": [{"mark": "bear_cave", "at": [-3, -2]}, {"mark": "bone_pit", "at": [3, -2]}, {"mark": "outer_hub", "at": [4, -3]}]}),
    # 고블린 숲: 길가 고블린 매복은 어귀 · 덫 골짜기 · 바위턱 중 한 곳, 버섯 고리 매복은 버섯 고리 · 빈터 중, 말벌 둥지는 원정마다 둘쯤
    ("f2_goblin_forest", "ambush", {"mark": "root_b", "first": "goblin"},
     {"any": [{"mark": "root_b"}, {"mark": "gully_snared"}, {"mark": "outcrop", "at": [2, -3]}]}),
    ("f2_goblin_forest", "ambush", {"mark": "mush_ring", "first": "goblin_swordsman"},
     {"any": [{"mark": "mush_ring"}, {"mark": "glade"}]}),
    ("f2_goblin_forest", "ambush", {"mark": "glade", "first": "forest_wasp"}, {"appear": 0.67}),
    ("f2_goblin_forest", "ambush", {"mark": "grove", "first": "forest_wasp"}, {"appear": 0.67}),
    ("f2_goblin_forest", "ambush", {"mark": "valley_cache", "first": "forest_wasp"}, {"appear": 0.67}),
    # 망자의 땅: 길목 매복 다섯은 원정마다 넷쯤, 구울로드 매복은 폐허 길 · 망루 길 중 하나
    ("f2_land_of_dead", "ambush", {"edge": ["levee_bend", "chapel"]}, {"appear": 0.75}),
    ("f2_land_of_dead", "ambush", {"edge": ["ferry", "mire"]}, {"appear": 0.75}),
    ("f2_land_of_dead", "ambush", {"edge": ["chapel", "corridor"]}, {"appear": 0.75}),
    ("f2_land_of_dead", "ambush", {"edge": ["chapel", "graveyard"]}, {"appear": 0.75}),
    ("f2_land_of_dead", "ambush", {"edge": ["tomb_gate", "ossuary"]}, {"appear": 0.75}),
    ("f2_land_of_dead", "ambush", {"edge": ["crossroads", "dullahan_ruin"], "first": "ghoul_lord"},
     {"any": [{"edge": ["crossroads", "dullahan_ruin"], "t": 0.7}, {"edge": ["crossroads", "watchtower"], "t": 0.5}]}),
    # 바위사막: 모래 언덕 노움 매복은 원정마다 하나쯤 빠진다
    ("f2_rock_desert", "ambush", {"mark": "dune_w", "first": "gnome"}, {"appear": 0.75}),
    ("f2_rock_desert", "ambush", {"mark": "dune_e", "first": "corrupted_gnome"}, {"appear": 0.75}),
]


def _matches(item, cond):
    for k, v in cond.items():
        if k == "first":
            mons = item.get("monsters", [])
            if not mons or mons[0] != v:
                return False
        elif item.get(k) != v:
            return False
    return True


def main():
    by_floor = {}
    for fid, lst, cond, add in VARIETY:
        by_floor.setdefault(fid, []).append((lst, cond, add))
    for fid, rules in by_floor.items():
        path = os.path.join(ROOT, "data", "floors", fid + ".json")
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
        rs = d.get("route_spots", {})
        for lst, cond, add in rules:
            hits = [it for it in rs.get(lst, []) if _matches(it, cond)]
            if len(hits) != 1:
                raise SystemExit("%s %s %s: 맞는 항목 %d개(하나여야 한다)" % (fid, lst, cond, len(hits)))
            hits[0].update(add)
        with open(path, "w", encoding="utf-8") as f:
            f.write(json.dumps(d, ensure_ascii=False, indent=2) + "\n")
        print("%s: %d항목" % (fid, len(rules)))


if __name__ == "__main__":
    main()
